-- Create cleanup table log
IF OBJECT_ID('dbo.__CleanupLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.__CleanupLog 
    (
        Id BIGINT IDENTITY(1,1),
        ExecutionId UNIQUEIDENTIFIER NOT NULL,
        TableName NVARCHAR(128) NULL,
        DeletedRowsCount INT NULL,
        ExecutionTimeUtc DATETIME NOT NULL CONSTRAINT DF_CleanupLog_ExecutionTimeUtc DEFAULT (GETUTCDATE()),
        Message NVARCHAR(MAX) NOT NULL,
        IsError BIT NOT NULL CONSTRAINT DF_CleanupLog_IsError DEFAULT (0),
        Query NVARCHAR(MAX) NULL,
        CONSTRAINT PK___CleanupLog PRIMARY KEY (Id)
    );
END
GO

IF OBJECT_ID('dbo.GetOrCreateArchiveTable') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.GetOrCreateArchiveTable;
END
GO

CREATE PROCEDURE dbo.GetOrCreateArchiveTable (
    @tableName NVARCHAR(128), 
    @executionId UNIQUEIDENTIFIER, 
    @archiveDatabaseName NVARCHAR(128) = 'OrchestratorArchive', 
    @archiveTableName NVARCHAR(128) OUTPUT)
AS
BEGIN
    DECLARE @tableSchemaXml NVARCHAR(MAX) = 
    (SELECT 
        c.name,
        c.system_type_id,
        c.is_nullable,
        c.max_length
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    WHERE t.name = @tableName
    FOR XML AUTO);

    -- Generate a SHA-256 hash, extract first 10 characters and append to table name.
    DECLARE @hash NVARCHAR(64) = CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', @tableSchemaXml), 2);
    SET @archiveTableName = @tableName + '_' + SUBSTRING(@hash, 1, 10);
    
    IF (@archiveTableName IS NULL)
    BEGIN
        DECLARE @error NVARCHAR(MAX) = N'Could not get archive table name for ' + @tableName;
        THROW 61000, @error, 1;
        RETURN;
    END
    
    DECLARE @tableExistsQuery NVARCHAR(MAX) = 'SELECT TOP 1 @tableExists = 1 FROM ' + @archiveDatabaseName + '.sys.tables WHERE name = ''' + @archiveTableName + '''';     
    DECLARE @tableExists BIT = 0;
    EXECUTE sp_executesql @tableExistsQuery, N'@tableExists BIT OUTPUT', @tableExists = @tableExists OUTPUT;
    
    IF (@tableExists = 0)
    BEGIN
        BEGIN TRY
            BEGIN TRAN
                DECLARE @copySchema NVARCHAR(MAX) = CONCAT('SELECT * INTO ', @archiveDatabaseName, '.[dbo].', QUOTENAME(@archiveTableName), 
                                                           ' FROM ', @tableName, 
                                                           ' WHERE 1 = 2',
                                                           ' UNION SELECT * FROM ', @tableName, ' WHERE 1 = 2');
                EXEC sp_executesql @copySchema;

                DECLARE @timestampColumnName NVARCHAR(128) = 
                    (SELECT TOP 1 [name] from sys.columns 
                     WHERE object_id = OBJECT_ID('[dbo].' + @tableName) AND system_type_id = 189);

                IF @timestampColumnName IS NOT NULL
                BEGIN
                    DECLARE @dropTimestampColumn NVARCHAR(MAX) = CONCAT('ALTER TABLE ', @archiveDatabaseName, '.[dbo].', QUOTENAME(@archiveTableName), 
                                                                        ' DROP COLUMN ', QUOTENAME(@timestampColumnName));
                    EXEC sp_executesql @dropTimestampColumn;
                END

                INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) VALUES (@executionId, @tableName, CONCAT('Created archive table ', @archiveTableName, '.'));
            COMMIT TRAN
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRAN;
            END
            
            INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message], IsError) 
            VALUES (@executionId, @tableName, CONCAT('Unable to create archive table ', @archiveTableName, '. ', ERROR_MESSAGE()), 1);
        END CATCH
    END;
END;
GO 


IF OBJECT_ID('dbo.RunOrchestratorCleanup') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.RunOrchestratorCleanup;
END
GO

CREATE PROCEDURE dbo.RunOrchestratorCleanup (@cleanupConfigXml XML, @archiveDatabaseName NVARCHAR(128) = 'OrchestratorArchive')
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @archiveDatabaseName)
    BEGIN
        EXECUTE('CREATE DATABASE ' + @archiveDatabaseName);
    END

    DECLARE @tableName NVARCHAR(128), @runMaxMinutes INT, @idColumn NVARCHAR(128), @dateTimeColumn NVARCHAR(128), @additionalFilter NVARCHAR(4000), @batchSize INT, @daysOld INT, @forceCascade BIT, @shouldArchive BIT;

    DECLARE @rowsToDeleteCount INT, @totalDeletedRows INT, @currentTime TIME, @endTimeUtc DATETIME;
    DECLARE @dynamicSql NVARCHAR(MAX), @errorMessage NVARCHAR(MAX);
    DECLARE @totalRunMaxMinutes INT;
    DECLARE @tableCleanupEndTimeReached BIT = 0;
    
    SELECT @totalRunMaxMinutes = @cleanupConfigXml.value('CleanupConfig[1]/@totalRunMaxMinutes', 'INT');
    IF (@totalRunMaxMinutes IS NULL OR @totalRunMaxMinutes < 1)
    BEGIN;
        THROW 61050, N'Please check @cleanupConfigXml parameter - attribute totalRunMaxMinutes must be greater than 1.', 1;
    END

    DECLARE @executionId UNIQUEIDENTIFIER = NEWID();
    DECLARE @executionEndTimeUtc DATETIME = DATEADD(MINUTE, @totalRunMaxMinutes, GETUTCDATE());    

    PRINT CONCAT('Execution started, execution id : ', @executionId);
    PRINT CONCAT('At the end of the execution you can view all logs of the execution using the following SQL: SELECT * FROM dbo.__CleanupLog WHERE ExecutionId = ''', @executionId, ''' ORDER BY Id', CHAR(13));

    -- XML is case-sensitive
    DECLARE ConfigCursor CURSOR LOCAL FOR
    SELECT
        t.n.value('@name', 'NVARCHAR(128)') AS TableName,
        t.n.value('@runMaxMinutes', 'INT') AS RunMaxMinutes,
        t.n.value('@idColumn', 'NVARCHAR(128)') AS IdColumn,
        t.n.value('@dateTimeColumn', 'NVARCHAR(128)') AS DateTimeColumn,
        t.n.value('@additionalFilter', 'NVARCHAR(4000)') AS AdditionalFilter,
        t.n.value('@batchSize', 'INT') AS BatchSize,
        t.n.value('@daysOld', 'INT') AS DaysOld,
        t.n.value('@forceCascade', 'BIT') AS ForceCascade,
        t.n.value('@shouldArchive', 'BIT') AS ShouldArchive
    FROM
        @cleanupConfigXml.nodes('CleanupConfig/Table') AS t(n);

    OPEN ConfigCursor;

    FETCH NEXT FROM ConfigCursor 
    INTO @tableName, @runMaxMinutes, @idColumn, @dateTimeColumn, @additionalFilter, @batchSize, @daysOld, @forceCascade, @shouldArchive;

    INSERT INTO dbo.__CleanupLog (ExecutionId, [Message]) VALUES (@executionId, 'Starting cleanup');

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            IF (@tableName IS NULL) OR (@runMaxMinutes IS NULL) OR 
               (@idColumn IS NULL)  OR (@idColumn = '') OR (@dateTimeColumn IS NULL) OR (@dateTimeColumn = '') OR 
               (@batchSize IS NULL) OR (@daysOld IS NULL) OR (@forceCascade IS NULL) OR (@shouldArchive IS NULL)
            BEGIN;
                THROW 61010, N'Please check @cleanupConfigXml parameter. At least one of the following attributes could not be read: name, runMaxMinutes, idColumn, dateTimeColumn, batchSize, daysOld, forceCascade, shouldArchive.', 1;
            END

            IF (@runMaxMinutes < -1)
            BEGIN;
                THROW 61020, N'Please check @cleanupConfigXml parameter - attribute runMaxMinutes must be -1 (no limit imposed), 0 (skipped) or greater than 0 (will run for the limited time).', 1;
            END

            IF (@batchSize <= 1)
            BEGIN;
                THROW 61030, N'Please check @cleanupConfigXml parameter - attribute batchSize must be greater than 1.', 1;
            END

            IF (@daysOld <= 1)
            BEGIN;
                THROW 61040, N'Please check @cleanupConfigXml parameter - attribute daysOld must be greater than 1.', 1;
            END

            IF NOT EXISTS (SELECT TOP 1 1 FROM sys.tables WHERE name = @tableName AND schema_id = SCHEMA_ID('dbo'))
            BEGIN
                INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) VALUES (@executionId, @tableName, 'Table does not exist in dbo schema. Cleanup skipped.');
                
                FETCH NEXT FROM ConfigCursor 
                INTO @tableName, @runMaxMinutes, @idColumn, @dateTimeColumn, @additionalFilter, @batchSize, @daysOld, @forceCascade, @shouldArchive;
                
                CONTINUE; -- Go to next table
            END

            IF OBJECT_ID('tempdb..#tempDeletedIds') IS NOT NULL
            BEGIN
                DROP TABLE #tempDeletedIds;
            END

            CREATE TABLE #tempDeletedIds (Id1 BIGINT, Id2 UNIQUEIDENTIFIER);

            DECLARE @idColumnType INT;
            SELECT @idColumnType = system_type_id FROM sys.columns WHERE object_id = OBJECT_ID(@tableName) AND name = @idColumn;
            IF (@idColumnType = 127) -- bigint 127
            BEGIN
                ALTER TABLE #tempDeletedIds DROP COLUMN Id2;
                EXEC tempdb.sys.sp_rename '#tempDeletedIds.Id1', 'IdToDelete', 'COLUMN';
            END
            ELSE IF (@idColumnType = 36) -- uniqueidentifier 36
            BEGIN
                ALTER TABLE #tempDeletedIds DROP COLUMN Id1;
                EXEC tempdb.sys.sp_rename '#tempDeletedIds.Id2', 'IdToDelete', 'COLUMN';
            END
            ELSE
            BEGIN
                RAISERROR ('Id column should be of type bigint or uniqueidentitifer.', 16, 1);
            END

            SET @rowsToDeleteCount = -1;
            SET @totalDeletedRows = 0;
            SET @tableCleanupEndTimeReached = 0;

            IF (@runMaxMinutes = 0)
            BEGIN
                INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) VALUES (@executionId, @tableName, 'RunMaxMinutes is 0. Cleanup skipped.');
                SET @rowsToDeleteCount = 0; -- skip
            END
            ELSE IF (@runMaxMinutes = -1)
            BEGIN
                SET @endTimeUtc = DATEADD(YEAR, 1, GETUTCDATE());
            END
            ELSE
            BEGIN
                SET @endTimeUtc = DATEADD(MINUTE, @runMaxMinutes, GETUTCDATE());
            END
            
            IF (@runMaxMinutes != 0)
            BEGIN
                INSERT INTO dbo.__CleanupLog (ExecutionId, [Message]) VALUES (@executionId, CONCAT('Starting to clean table ', @tableName));
            END
            
            WHILE @rowsToDeleteCount != 0
            BEGIN

                IF (GETUTCDATE() >= @executionEndTimeUtc)
                BEGIN
                    INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message], DeletedRowsCount) VALUES (@executionId, @tableName, 'Execution end time reached.', @totalDeletedRows);
                    PRINT CONCAT('Deleted ', @totalDeletedRows, ' ', @tableName, CHAR(13));
                    RETURN; -- stop execution for all cleanups, execution time reached
                END
                
                IF (GETUTCDATE() >= @endTimeUtc)
                BEGIN
                    SET @tableCleanupEndTimeReached = 1;
                    INSERT INTO dbo.__CleanupLog (ExecutionId,TableName, [Message], DeletedRowsCount) VALUES (@executionId, @tableName, 'Table cleanup finished. Reached table cleanup end time.', @totalDeletedRows);
                    PRINT CONCAT('Deleted ', @totalDeletedRows, ' ', @tableName, CHAR(13));
                    BREAK; -- exit while loop for current table, try to clean next table
                END

                BEGIN TRANSACTION

                /*
                 *  Get batch of ids to be deleted (store the batch inside #tempDeletedIds). 
                 *  Apply filter by date and additional filter.
                 *  An ORDER BY is applied only if the id column is of type BIGINT, since UNIQUEIDENTIFIER may not be sequential.
                 */
 
                /* Inside the transaction we execute the following steps:
                 *   - select a batch of ids to archive/delete (store this batch inside #tempDeletedIds)
                 *   - archive/delete this batch from tables referenced by foreign keys (depends on the shouldArchive and forceCascade configured in @cleanupConfigXml)
                 *   - archive/delete this batch (depends on the shouldArchive configured @cleanupConfigXml)
                 */

                TRUNCATE TABLE #tempDeletedIds;
                DECLARE @olderThan DATE = DATEADD(DAY, (-1) * @daysOld, GETDATE());
                SET @dynamicSql = CONCAT(N'INSERT INTO #tempDeletedIds',
                                         ' SELECT TOP (@batchSize) ', @idColumn, ' AS IdToDelete',
                                         ' FROM ', @tableName, 
                                         ' WHERE 1 = 1 AND ', @dateTimeColumn, ' < @olderThan');
                IF (@additionalFilter IS NOT NULL AND @additionalFilter != '')
                BEGIN
                    SET @dynamicSql = @dynamicSql + ' AND ' + @additionalFilter;
                END
                IF (@idColumnType = 127) -- bigint 127
                BEGIN
                    SET @dynamicSql = @dynamicSql + ' ORDER BY ' + @idColumn;
                END

                EXEC sp_executesql @dynamicSql, N'@batchSize INT, @olderThan DATE', @batchSize = @batchSize, @olderThan = @olderThan;
                SET @rowsToDeleteCount = @@ROWCOUNT;
                    
                INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message], Query) 
                VALUES (@executionId, @tableName, CONCAT('Found ', @rowsToDeleteCount, ' rows to delete older than ', @olderThan, '. Batch size used ', @batchSize, '.'), @dynamicSql);

                IF @rowsToDeleteCount > 0
                BEGIN
                    IF @forceCascade = 1
                    BEGIN
                        INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                        VALUES (@executionId, @tableName, 'Starting cleanup of foreign key tables (ForceCascade is true) for the current batch.');

                        DECLARE @fkColumnName NVARCHAR(255);
                        DECLARE @fkTableName NVARCHAR(255);
                        DECLARE @fkArchiveTableName NVARCHAR(128);
                        DECLARE @fkRowCount INT;

                        DECLARE ReferenceCursor CURSOR LOCAL FOR
                        SELECT 
                            c_parent.name AS FKColumnName,
                            t_parent.name AS FKTableName
                        FROM
                            sys.foreign_keys fk
                            INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
                            INNER JOIN sys.tables t_parent ON t_parent.object_id = fk.parent_object_id
                            INNER JOIN sys.columns c_parent ON fkc.parent_column_id = c_parent.column_id AND c_parent.object_id = t_parent.object_id
                            INNER JOIN sys.tables t_child ON t_child.object_id = fk.referenced_object_id
                        WHERE 
                            t_child.name = @tableName;

                        OPEN ReferenceCursor;

                        FETCH NEXT FROM ReferenceCursor INTO @fkColumnName, @fkTableName;

                        WHILE @@FETCH_STATUS = 0
                        BEGIN
                            IF @shouldArchive = 1
                            BEGIN
                                EXEC dbo.GetOrCreateArchiveTable @tableName = @fkTableName, @executionId = @executionId, @archiveDatabaseName = @archiveDatabaseName, @archiveTableName = @fkArchiveTableName OUTPUT;

                                SET @dynamicSql = CONCAT('INSERT INTO ', @archiveDatabaseName, '.[dbo].', QUOTENAME(@fkArchiveTableName), 
                                                         ' SELECT * FROM ', @fkTableName,
                                                         ' WHERE ', @fkColumnName, ' IN (SELECT IdToDelete FROM #tempDeletedIds)');
                                                         
                                EXEC sp_executesql @dynamicSql;
                                SET @fkRowCount = @@ROWCOUNT;

                                IF (@fkRowCount > 0)
                                BEGIN
                                    INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                                    VALUES (@executionId, @fkTableName, CONCAT('Archived a batch of size ', @fkRowCount, ' to ', @fkArchiveTableName));
                                END
                                ELSE
                                BEGIN
                                    INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                                    VALUES (@executionId, @fkTableName, CONCAT('Nothing to archive for ', @fkArchiveTableName));
                                END
                            END;

                            SET @dynamicSql = CONCAT('DELETE FROM ', @fkTableName, ' WHERE ', @fkColumnName, ' IN (SELECT IdToDelete FROM #tempDeletedIds)');

                            EXEC sp_executesql @dynamicSql;
                            SET @fkRowCount = @@ROWCOUNT;

                            IF (@fkRowCount > 0)
                            BEGIN
                                INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                                VALUES (@executionId, @fkTableName, CONCAT('Deleted a batch of size ', @fkRowCount, ' from ', @fkTableName));
                            END
                            ELSE
                            BEGIN
                                INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                                VALUES (@executionId, @fkTableName, CONCAT('Nothing to delete for ', @fkArchiveTableName));
                            END

                            FETCH NEXT FROM ReferenceCursor INTO @fkColumnName, @fkTableName;
                        END; -- End for CURSOR over foreign key tables @fkTableName

                        INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                        VALUES (@executionId, @tableName, 'Finished cleanup foreign key tables for current batch.');

                        CLOSE ReferenceCursor;
                        DEALLOCATE ReferenceCursor;
                    END -- End for @forceCascade = 1 and @tableName

                    IF @shouldArchive = 1
                    BEGIN
                        DECLARE @archiveTableName NVARCHAR(128);
                        DECLARE @commaSeparatedColumnNames NVARCHAR(MAX);
                        SET @commaSeparatedColumnNames = NULL;
                        SET @archiveTableName = NULL;

                        EXEC dbo.GetOrCreateArchiveTable @tableName = @tableName, @executionId = @executionId, @archiveDatabaseName = @archiveDatabaseName, @archiveTableName = @archiveTableName OUTPUT;

                        SELECT @commaSeparatedColumnNames = COALESCE(@commaSeparatedColumnNames + ', ', '') + QUOTENAME(c.name) 
                        FROM   sys.columns c 
                        WHERE  c.object_id = OBJECT_ID('[dbo].' + QUOTENAME(@tableName))
                                AND c.system_type_id <> 189 -- we don't archive timestamp columns
                        ORDER BY column_id ASC

                        IF (@commaSeparatedColumnNames IS NULL)
                        BEGIN;
                            THROW 61050, N'Could not determine the schema for current table.', 1;
                        END

                        SET @dynamicSql = 
                            ' INSERT INTO ' + @archiveDatabaseName + '.[dbo].' + QUOTENAME(@archiveTableName) + 
                            ' SELECT ' + @commaSeparatedColumnNames + 
                            ' FROM '   + @tableName + 
                            ' WHERE '  + @idColumn + N' IN (SELECT IdToDelete FROM #tempDeletedIds)';

                        EXEC sp_executesql @dynamicSql;

                        INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                        VALUES (@executionId, @tableName, CONCAT('Archived a batch of size ', @@ROWCOUNT, ' to ', @archiveTableName));
                    END; -- End for @shouldArchive = 1 and @tableName
                        
                    SET @dynamicSql = CONCAT('DELETE FROM ', @tableName, ' WHERE ', @idColumn, ' IN (SELECT IdToDelete FROM #tempDeletedIds)');
                    EXEC sp_executesql @dynamicSql;

                    INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message]) 
                    VALUES (@executionId, @tableName, CONCAT('Deleted a batch of size ', @@ROWCOUNT, ' from ', @tableName));
                END

                COMMIT TRANSACTION
                
                IF @rowsToDeleteCount > 0
                BEGIN
                    SET @totalDeletedRows = @totalDeletedRows + @rowsToDeleteCount;
                END
            END -- End for while time not elasped
            
            IF @tableCleanupEndTimeReached = 0
            BEGIN
                 INSERT INTO dbo.__CleanupLog (ExecutionId,TableName, DeletedRowsCount, [Message]) VALUES (@executionId, @tableName, @totalDeletedRows,'Table cleanup finished.');
                 PRINT CONCAT('Deleted ', @totalDeletedRows, ' ', @tableName, CHAR(13));
            END
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRAN;
            END

            SET @errorMessage = ERROR_MESSAGE();
            INSERT INTO dbo.__CleanupLog (ExecutionId, TableName, [Message], IsError) VALUES (@executionId, @tableName, @errorMessage, 1);
            PRINT CONCAT('Error while processing table ', @tableName, '. Encountered the following error: ', @errorMessage, CHAR(13));
        END CATCH;

        FETCH NEXT FROM ConfigCursor 
        INTO @tableName, @runMaxMinutes, @idColumn, @dateTimeColumn, @additionalFilter, @batchSize, @daysOld, @forceCascade, @shouldArchive;

    END

    CLOSE ConfigCursor;
    DEALLOCATE ConfigCursor;
    
    INSERT INTO dbo.__CleanupLog (ExecutionId, [Message]) VALUES (@executionId, 'Cleanup finished');
    
    DECLARE @executionFirstErrorMessage NVARCHAR(MAX);
    SELECT TOP 1 @executionFirstErrorMessage = [Message] FROM dbo.__CleanupLog WHERE IsError = 1 AND ExecutionId = @executionId;

    IF (@executionFirstErrorMessage IS NOT NULL)
    BEGIN;
        DECLARE @finalExcepionToThrow NVARCHAR(MAX);
        SET @finalExcepionToThrow = CONCAT(N'Execution finished with error(s). Please execute the following SQL to see all errors: SELECT * FROM dbo.__CleanupLog WHERE IsError = 1 AND ExecutionId = ''', @executionId, ''' . First error is: ', @executionFirstErrorMessage);
        THROW 71000, @finalExcepionToThrow, 1;
    END
END;
GO