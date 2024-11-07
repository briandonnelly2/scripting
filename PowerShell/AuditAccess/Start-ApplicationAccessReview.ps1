Set-StrictMode -Version 1.0
Function Start-ApplicationAccessReview {
<#
    .SYNOPSIS
        Reviews access rights for an application.
    .DESCRIPTION
        This is the main controller script that manages the entire execution process.
        When completed, I would like this to be able to do the following:

        Functionality
        -------------
        -   Gather information in scope at a server level, such as local groups & shares access.
        -   Gather information in scope at the database level, to determine who has what access.
        -   Gather information at an application level, such as the users/employees tables and access roles.
        -   Process the gathered information to identify any unknown Ative Directory users or groups.
        -   Check the remaining information against an approved an restricted list for users & groups

        Reporting
        ---------
        -   Any datasets that are returned throughout will be output to CSV files for auditing purposes.
        -   A final HTML report will be produced as a summary of compliance versus the supplied baseline.
        -   Logging:

    .PARAMETER Credentials
        Credentials object must be passed into the script otherwise user will be prompted to provide these.
    .PARAMETER ConsoleInfo
        Set to $true for output to be printed on the console.
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          01 February 2019
        Modified Date:          N/A
        Revfiew Date:           01 May 2019
        Future Enhancements:
    .EXAMPLE
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
    .EXAMPLE
        Example of a way in which this command can be used.
    .EXAMPLE
    Example of a way in which this command can be used.
#>

<#     #requires -modules ActiveDirectory, ScriptMethods, ADQueryMethods, KPMGLogging
    #requires -version 5.0
 #>
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Please enter operator level credentials" )]
        [pscredential]$Credentials,

        [Parameter( ValueFromPipelineByPropertyName,
        HelpMessage = "Set to true for output to be printed on the console." )]
        [switch]$ConsoleInfo
    )
    Import-Module -Name KPMGLogging
    Import-Module -Name ScriptMethods

    $ErrorActionPreference = "Stop"

    Write-Verbose "Setting current directory to $($PSScriptRoot)"
    Set-Location -Path $PSScriptRoot

    Write-Verbose "Script running using $env:USERDOMAIN\$env:USERNAME credentials."

    Try {
        Write-Verbose "Creating GUID and timestamp variables. Allows folder and file names to be unique for each run"
        New-Variable -Name UniqueRunGUID -Value ([guid]::NewGuid()) -Description "KPMG-GUID" -Scope global
        New-Variable -Name StaticTimeStamp -Value ( (Get-Date -Format yyyyMMddhhmmss) ) -Description "KPMG-TIMESTAMP" -Scope global

        Write-Verbose "Creating variables for the report output logfile directory"
        New-Variable -Name FileExportPath -Value "$HOME\Documents\reports\$UniqueRunGUID" -Description "KPMG-REPORTPATH" -Scope global
        New-Variable -Name LogFileDir -Value "$HOME\Documents\logs\$UniqueRunGUID" -Description "KPMG-LOGPATH" -Scope global

        Write-Verbose "Creating output & logfile directories"
        New-Item -Path $FileExportPath -ItemType Directory -Force | Out-Null
        New-Item -Path $LogFileDir -ItemType Directory -Force | Out-Null

        If ( !( Test-Path -Path $FileExportPath ) ) {
            Throw "$FileExportPath does not exist and therefore was not created.  Please check your permissions and try again."
        }
        If ( !( Test-Path -Path $LogFileDir ) ) {
            Throw "$LogFileDir does not exist and therefore was not created.  Please check your permissions and try again."
        }

        Write-Verbose "Creating logfile"
        New-KPMGLog -LogFileDir $LogFileDir -LogFileName "$StaticTimeStamp.log" -LogFilePurpose "Application Audit Log" | Tee-Object -Variable "LogFilePath" | Out-Null

        If ( !( Test-Path -Path $LogFilePath ) ) {
            Throw "The logfile at $LogFileDir does not exist and therefore was not created.  Please check your permissions and try again."
        }

        Write-KPMGLogInfo -LogFilePath $LogFilePath -Message "This logfile was created at $($LogFileDir.FullName) on $env:COMPUTERNAME" -ToConsole:$ConsoleInfo

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Attempting to import the data files from the $($PSScriptRoot) directory" -ToConsole:$ConsoleInfo
        [System.Object]$EnvData = Import-PowerShellDataFile .\*.psd1
        [System.Object]$UsrData = Import-Csv -Path .\*.csv

        If ( ( $null -EQ $EnvData ) -AND ( $null -EQ $UsrData ) ) {
            Throw "The $PSScriptRoot directory does not contain the data files needed for this script to execute succesfully. Please make sure these files exist in this directory."
        }
        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "User and environment data successfully imported." -ToConsole:$ConsoleInfo

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Separating environment data." -ToConsole:$ConsoleInfo
        <# Separate the Environment Data into variables. Allows a choice to be made on which environment to audit. #>
        [int16]$ProdEnvCount = 0
        [int16]$EnvCount = 0

        foreach ( $Key IN $EnvData.Keys ) {
            switch ( $true ) {
                <# Case: Key is equal to global #>
                ($Key -eq "global") { 
                    #Write-KPMGLogObject -Object 
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Storing $Key data" -ToConsole:$ConsoleInfo
                    New-Variable -Name $EnvData.$Key.envname -Value $EnvData.$Key -Force -Scope global 
                }
                <# Case: Key is like prod #>
                ($Key -like "prod*") {
                    #Write-KPMGLogObject -Object 
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Storing $Key data" -ToConsole:$ConsoleInfo
                    $ProdEnvCount++
                    [string[]]$EnvNames += $EnvData.$Key.envname
                    [string[]]$DisplayNames += "$($EnvData.$Key.name) $ApplicationName"
                    New-Variable -Name $EnvData.$Key.envname -Value $EnvData.$Key -Force
                    $EnvCount++
                }
                <# Case: All other environments found #>
                Default {
                    #Write-KPMGLogObject -Object 
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Storing $Key data" -ToConsole:$ConsoleInfo
                    [string[]]$EnvNames += $EnvData.$Key.envname
                    [string[]]$DisplayNames += "$($EnvData.$Key.name) $ApplicationName"
                    New-Variable -Name $EnvData.$Key.envname -Value $EnvData.$Key -Force
                    $EnvCount++
                }
            }
        }
        If ( $null -IN ( $EnvNames ) ) {
            Throw "A problem was encountered separating environment data.  Please check the env-data.psd1 file data"
        }

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "$($EnvData.Count-1) environments have been defined. There are $ProdEnvCount production environments defined." -ToConsole:$ConsoleInfo
        [string]$ApplicationName = $EnvData.global.name

        [System.Management.Automation.Host.ChoiceDescription[]]$EnvChoices = @()
        [string[]]$EnvIndices = 0..($EnvCount-1) ##Used to assign an index to each environment
        [int16]$Counter = 0
        foreach ( $EnvName IN $EnvNames ) {
            $EnvChoices += New-Object "System.Management.Automation.Host.ChoiceDescription" "&$EnvName", $DisplayNames[$Counter]
            $Counter++
        } ##Builds choices of environments for user to select below
        [int16]$EnvScope = $host.UI.PromptForChoice("Please choose an environment to audit by typing the first letter of the relevant environment","$DisplayNames", $EnvChoices, 1)

        <# This section dynamically builds the switch block #>
        $switchBlockTemplate = "
        switch( $EnvScope ) {

        "
        $ActionStatementTemplate = "$"
        $SwitchBlockContent = [String]::Empty
        foreach ($index in $EnvIndices) {
            $actionStatement = $actionStatementTemplate + $EnvNames[$index]
            $switchBlockContent += $index + " { " + '$EnvInfo = ' + $actionStatement + " }`r`n"
        }
        $switchBlockContent += 'Default { $EnvInfo = ' + $actionStatementTemplate + 'uat' + " }`r`n"
        $switchBlock = [scriptblock]::Create($switchBlockTemplate + $switchBlockContent + '}')
        Invoke-Command -ScriptBlock $switchBlock -ArgumentList @($EnvScope) -NoNewScope

        [string]$AppEnv = $DisplayNames[$EnvScope]

        If( !( $EnvNames[$EnvScope] -EQ $EnvInfo.envname ) ) {
            #Write-KPMGLogObject -Object $EnvInfo
            Throw "The environment will be set to the default UAT, as the supplied environment value does not match the data."
        }
        
        #Write-KPMGLogObject -Object $EnvInfo
        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "This script will be auditing the $ApplicationName application in the $AppEnv environment" -ToConsole:$ConsoleInfo

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Importing SQL scripts" -ToConsole:$ConsoleInfo

        Get-ChildItem -Path ".\scripts\sql" -Filter "*.sql" | Tee-Object -Variable "SQLScripts" | Out-Null

        If ( $null -eq $SQLScripts ) {
            Write-KPMGLogWarning -LogFilePath $LogFilePath.FullName -Message "There looks to be no SQL scripts in the required directory. Ignore if this is by design." -ToConsole:$ConsoleInfo
        } 
        ElseIf ( !( $null -eq $SQLScripts ) ) {
            Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Stored the following database scripts: $SQLScripts" -ToConsole:$ConsoleInfo
        }

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Testing that a connection is available to the " -ToConsole:$ConsoleInfo

        foreach( $Server IN $EnvInfo.servers ) {
            If ( !( Test-Connection -ComputerName $Server -Quiet ) ) {
                Write-KPMGLogWarning -LogFilePath $LogFilePath.FullName -Message "Ping to $($Server) has failed. This could be a transient issue" -ToConsole:$ConsoleInfo
            }
        }
        If( !( Test-Connection -ComputerName $EnvInfo.dbinstance.Split('\')[0] -Quiet ) ) {
            Write-KPMGLogWarning -LogFilePath $LogFilePath.FullName -Message "Ping test to database cluster $($EnvInfo.dbinstance) has failed" -ToConsole:$ConsoleInfo
        }

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Removing any existing PSSessions" -ToConsole:$ConsoleInfo

        Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue

        [string]$LocalSGReport = Join-Path -Path $FileExportPath -ChildPath ("local-sg-report.csv" )

        If( !( $null -eq $EnvInfo.servers ) ) {
            [System.Object[]]$Sessions = New-KPMGPSSessions -Credentials $Credentials -ServerNames $EnvInfo.servers -LogFilePath $LogFilePath

            If ( !( $null -eq $Sessions ) -and !( "Closed" -in $Sessions.State ) ) {
                Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Powershell sessions created. Proceeding to gather local group info" -ToConsole:$ConsoleInfo
                Get-KPMGLocalGroupInfo -Sessions $Sessions -LocalSGReportPath $LocalSGReport -LogFilePath $LogFilePath
    
                If( !( $null -eq ( Get-Content -Path $LocalSGReport ) ) ) {
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Local group info has been gathered. Removing PS Sessions." -ToConsole:$ConsoleInfo
                    Get-PSSession | Remove-PSSession
                } Else {
                    Throw "There was an issue when gathering local group info. Removing PS Sessions." 
                }
            } Else {
                Throw "There was an issue while creating PS Sessions.  Please check logs for details. Removing any PS Sessions that might exist."
            }
        } Else {
            Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "No servers are defined for his environment. Continuing execution" -ToConsole:$ConsoleInfo
            Continue
        }

        [System.Object[]]$ProdOnly = @()
        [System.Object[]]$DevOnly = @()
        [System.Object[]]$DualRole = @()
        [System.Object[]]$NoAccess = @()

        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "Splitting supplied user data on segregation of duties lines." -ToConsole:$ConsoleInfo
        foreach( $User IN $UsrData ) {
            switch ( $User.segregation ) {
                "Production" { 
                    $ProdOnly += $User
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "$($User.name) is a production user" -ToConsole:$ConsoleInfo 
                }
                "Development" { 
                    $DevOnly += $User
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "$($User.name) is a development user" -ToConsole:$ConsoleInfo 
                }
                "Both" { 
                    $DualRole += $User
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "$($User.name) is a dual role user" -ToConsole:$ConsoleInfo 
                }
                "None" { 
                    $NoAccess += $User
                    Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "$($User.name) should have no privileged access" -ToConsole:$ConsoleInfo 
                }
                Default { 
                    $NoAccess += $User
                    Write-KPMGLogWarning -LogFilePath $LogFilePath.FullName -Message "$($User.name) does not seem to have a segregation value assigned. Please check this on the UserData file" -ToConsole:$ConsoleInfo 
                }
            }
        }

    } Catch {
        Write-KPMGLogWarning -LogFilePath $LogFilePath.FullName -Message "A general exception was thrown." -ToConsole:$true
        Write-KPMGLogInfo -LogFilePath $LogFilePath.FullName -Message "EXCEPTION THROWN AT SCRIPT LINE $($_.InvocationInfo.ScriptLineNumber):" -ToConsole:$true
        Write-KPMGLogError -LogFilePath $LogFilePath.FullName -Message ($_.Exception.ToString()) -ToConsole$true -ExitGracefully:$true
    } Finally {
        Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue
        Get-Variable | Remove-Variable -ErrorAction SilentlyContinue
    }
}




<# Stores service accounts #>
[string[]]$SvcAccounts = @()

<# Checks UsrData is not null first #>
If( !( $null -eq $UsrData ) -and ( !( $null -eq $EnvInfo )) ) {
    Write-Verbose "Storing variables for later use"
    <# Splits out users based on the 'segregation' value in the user data csv file #

    <# Pulls relevant information from the  #>
    foreach( $Key IN $EnvInfo.Keys ) {
        <#  #>
        switch ( $true ) {
            <# Case:  #>
            ( "" -eq $($EnvInfo.$Key) ) { Write-Verbose "$($Key) are/is empty value(s) in the $($AppEnv) environment" | Out-Null }
            <# Case: Key ends in 'group' and is not null' #>
            ( $Key.EndsWith( "group" ) -and !( "" -eq $($EnvInfo.$Key) ) ) { 
                $AppGroupNames += $($EnvInfo.$Key) 
                Write-Verbose "$($EnvInfo.$Key) are/is value(s) for $($Key) in the supplied baseline for $($AppEnv)" | Out-Null
            }
            <# Case: Key is service accounts and is not null #>
            (( "svcaccounts" -eq $Key ) -and !( "" -eq $($EnvInfo.$Key))) { 
                $SvcAccounts = $($EnvInfo.$Key) 
                Write-Verbose "$($EnvInfo.$Key) are/is value(s) for $($Key) in the supplied baseline for $($AppEnv)" | Out-Null
            }
            <# Case: Anything else #>
            Default { Write-Verbose "$($EnvInfo.$Key) are/is value(s) for $($Key) in the supplied baseline for $($AppEnv)" | Out-Null }
        }
    }
    Write-Verbose "Storing variables complete"
}
Else {
    Write-Verbose "There does not seem to be any user data.  Quitting script."
}
#region Review Information

<#
    Local Security Group Checks

        1. Users
           (a) Flag as exempt if any user matches $global.exemptusers (Exempt)
           (b) Flag as breach if any developers have access to any local security groups (Breach) ($DevOnly)
           (c) Flag as compliant  any -svc- accounts found that also appear in the config (Compliant) ($Current -like '*svc*' ) -and ( ("-" + $Current ) -in $SvcAccounts )
           (d) Flag as non compliant  any -svc- accounts found that do NOT appear in the config (Non-Compliant) ($Current -like '*svc*' ) -and !("-" + $Current ) -in $SvcAccounts )
           (e) Flag as non-compliant if individual user accounts are members of any local security groups (Non-Compliant)
        
        2. Groups
           (a) Flag as exempt if any group matches $global.exemptgroups (Exempt)

           (b) Local group member is a member of 'Administrators'
                (i) Flag as breach if read-only AD application or user groups are members of local admins (Breach)
               (ii) Flag as compliant if defined as the application admin sec group
              (iii) Anything else is non-compliant

           (c) Local group member is a member of either 'Remote Desktop Users' or 'Event Log Readers'
                (i) Flag as compliant if a member of 'Remote Desktop Users' or 'Event Log Readers' (Compliant)
               (ii) Anything else is non-compliant

           (d) Flag as non-compliant if a member of any other groups (Non-Compliant)

        3. System accounts - all exempt

        4. N/A - Empty local groups

        5. Anything else - non-compliant
#>

<# Import the local security group report #>
If ( !( $null -eq ( Get-Content -Path $LocalSGReport ) ) ) { 
    [System.Object]$LocalSGInfo = Import-Csv -Path $LocalSGReport 
    Write-Verbose "Local Security Group report has been imported successfully"
}
Else { Write-Verbose "Local Security Group report is not at the required location" ; Pause }

<# Defines variables to hold users and groups based on compliance #>
[System.Array]$ExemptUsers = @()
[System.Array]$InBreachUsers = @()
[System.Array]$NonCompliantUsers = @()
[System.Array]$ExemptSysAccounts = @()
[System.Array]$CompliantSvcAcc = @()
[System.Array]$NonCompliantSvcAcc = @()
[System.Array]$ExemptGroups = @()
[System.Array]$InBreachGroups = @()
[System.Array]$NonCompliantGroups = @()
[System.Array]$CompliantGroups = @()
[System.Array]$EmptyGroups = @()

<# 
$ExemptUsers.Count #Actual 0, expected 0
$InBreachUsers.Count #Actual 0, expected 0
$NonCompliantUsers.Count #Actual 0, expected 0
$ExemptSysAccounts.Count #Actual 0, expected 0
$CompliantSvcAcc.Count #Actual 0, expected 0
$NonCompliantSvcAcc.Count #Actual 0, expected 0
$ExemptGroups.Count #Actual 0, expected 0
$InBreachGroups.Count #Actual 0, expected 0
$NonCompliantGroups.Count #Actual 0, expected 0
$CompliantGroups.Count #Actual 0, expected 0
$EmptyGroups.Count #Actual 0, expected 0

$AllSepAccounts = (
$ExemptUsers,
$InBreachUsers,
$NonCompliantUsers,
$ExemptSysAccounts,
$CompliantSvcAcc,
$NonCompliantSvcAcc,
$ExemptGroups,
$InBreachGroups,
$NonCompliantGroups,
$CompliantGroups,
$EmptyGroups
)

$LocalSGInfo.MemberName | Select-Object -Unique | Sort-Object
$AllSepAccounts.MemberName | Select-Object -Unique | Sort-Object

($LocalSGInfo.MemberName | Select-Object -Unique).Count
($AllSepAccounts.MemberName | Select-Object -Unique).Count

$TotCount=$Null
foreach($SepAcc IN $AllSepAccounts) { $TotCount += $SepAcc.Count }
$LocalSGInfo.Count
$TotCount #>

Write-Verbose "Local Security Group report has been imported. Checking membership for compliance..."

<# Checks every group member in the report based on the rules defined above #>
foreach( $Member in $LocalSGInfo ) {
    $Current = $Member.MemberName
    <# Switch block which uses the account type to define rules #>
    switch ( $Member.Type ) {
        <# (1) Case: Local group member is a user #>
        "User" {
            <# Switch block which tests various 'user' conditions for truth #>
            switch ( $True ) {
                <# (a) Member is defined in $global.exemptusers #>
                ( $Current -in $global.exemptusers ) { 
                    $ExemptUsers += $Member 
                    Write-Verbose "$Current is an exempt user as it is a member of the exempt users defined in the config" | Out-Null
                    
                }
                <# (b) Local group member is a developer account #>
                ( $Current -in $DevOnly.uk_un ) {
                    $InBreachUsers += $Member
                    Write-Verbose "$Current is a developer and therefore in breach due to it being a member of $($Member.GroupName) on $($Member.Server)" | Out-Null
                    
                }
                <# (c) Local group member is an authorised service account #>
                ( ( $Current -like 'svc*' ) -and ( ("-" + $Current ) -in $SvcAccounts ) ) {
                    $CompliantSvcAcc += $Member
                    Write-Verbose "$Current is a service account and also specified in the config so is a compliant service account on $($Member.Server)" | Out-Null
                }
                ( ( $Current -like '*svc*' ) -and ( ( $Current ) -in $SvcAccounts ) ) {
                    $CompliantSvcAcc += $Member
                    Write-Verbose "$Current is a service account and also specified in the config so is a compliant service account on $($Member.Server)" | Out-Null
                }
                <# (d) Local group member is NOT an authorised service account #>
                ( ( $Current -like '*svc*' ) -and !( ("-" + $Current ) -in $SvcAccounts ) ) {
                    $NonCompliantSvcAcc += $Member
                    Write-Verbose "$Current is a service account and NOT specified in the config so is a non-compliant service account on $($Member.Server)" | Out-Null
                    
                }
                <# (e) All other user accounts are non-compliant #>
                Default {
                    $NonCompliantUsers += $Member
                    Write-Verbose "$Current is a non-compliant user account and should not be a direct member of $($Member.GroupName) on $($Member.Server))" | Out-Null
                    
                }
            }  
        }
        <# (2) Case: Local group member is a group #>
        "Group" {
            <# Switch block which tests various 'group' conditions for truth #>
            switch ( $true ) {
                <# (a) Case: Local group member is defined in exempt groups #>
                ( $Current -in ($global.exemptgroups) ) {
                    $ExemptGroups += $Member 
                    Write-Verbose "$Current is an exempt group as it is a member of the exempt groups defined in the config" | Out-Null
                }
                <# (b) Case: Local group member is a member of 'Administrators' #>
                ( $Member.GroupName -eq "Administrators" ) {
                    <# (i) If this is one of the read-only group it is in breach #>
                    If( $Current -like ( "UK-SG RO-*" ) ) {
                        $InBreachGroups += $Member
                        Write-Verbose "$Current is an read-only group and should never be a member of $($Member.GroupName)" | Out-Null
                    }
                    <# (ii) If this is the application admin ops group, it is compliant #>
                    ElseIf( $Current -in $EnvInfo.adminopsgroup ) {
                        $CompliantGroups += $Member
                        Write-Verbose "$Current is an admin ops group and should never be a member of $($Member.GroupName)" | Out-Null
                    }
                }
                <# (c) Case: Local group member is a member of either 'Remote Desktop Users' or 'Event Log Readers'... #>
                ( $Member.GroupName -in ( "Remote Desktop Users", "Event Log Readers" ) ) {
                    <# (i)...and is one of the read-only security groups #>
                    If( $Current -in (( $EnvInfo.roopsgroup), ($EnvInfo.rodatagroup)) ) {
                        $CompliantGroups += $Member
                        Write-Verbose "$Current is an read-only group and is permitted to be a member of $($Member.GroupName)" | Out-Null
                    }
                }
                Default {
                    <# Anything else is non-compliant #>
                    $NonCompliantGroups += $Member
                    Write-Verbose "$Current is not defined anywhere and is non-compliant as a member of $($Member.GroupName)" | Out-Null    
                }
            }
        }
        <# (3) Case: System - All exempt #>
        "System" {
            $ExemptSysAccounts += $Member
            Write-Verbose "$Current is a system account and is exempt as a member of $($Member.GroupName)" | Out-Null
            
        }
        <# (4) Case: N/A - Empty local groups - go into an empty groups variable #>
        "N/A" {
            $EmptyGroups += $Member
            Write-Verbose "$($Member.GroupName) is an empty group and had been recorded separately" | Out-Null
            
        }
        Default {
            $NonCompliantGroups += $Member
            Write-Verbose "$Current does not match any rule and is non-compliant by default as a member of $($Member.GroupName)" | Out-Null
            
        }
    }
}
Write-Verbose "Local Security Group membership compliance check complete"
<#
    Active Directory Security Group Checks

        Privileged User Group ($global.adusrsecgroup)

            -   Flag as breach if it contains ANY developer accounts (Breach) ($DevOnly)
            -   Flag as breach if it contains ANY regular UK accounts (Breach)
            -   Flag as compliant if it contains ONLY the -oper- accounts defined in $global.envadmins (Compliant)
            -   Flag as non-compliant if it contains ANY other -oper- accounts (Non-Compliant)

        Read-Only User Groups ($global.rousrsecgroup)

            -   Flag as compliant if it contains ONLY the developer accounts defined in $global.envreadonly (Compliant)
            -   Flag as breach if they contain any other developer accounts (Breach) ($DevOnly)
            -   Flag as non-compliant if it contains ANY other accounts or groups (Non-Compliant)

        Privileged Application Server/Database Groups ($EnvInfo.adminopsgroup & $EnvInfo.admindatagroup)

            -   Flag as breach if they contain any read-only security groups (UK-SG RO*) (Breach)
            -   Flag as non-compliant if they contain ANY other accounts or groups (Non-Compliant)
            -   Flag as compliant if they only contain the Privileged User Group $global.adusrsecgroup (Compliant)

        Read-Only Application Server/Database Groups ($EnvInfo.roopsgroup & $EnvInfo.rodatagroup)

            -   Flag as breach if it contains ANY developer accounts (Breach) ($DevOnly)
            -   Flag as compliant if they only contain the Read-Only User Group $global.rousrsecgroup (Compliant)
            -   Flag as non-compliant if they contain ANY other accounts or groups (Non-Compliant)
#>

<#
    Database Checks

        -   Flag as breach if any developer accounts have production access at server or database level (Breach) ($DevOnly)
        -   Flag as breach if the $EnvInfo.rodatagroup has anything greater than db_datareader permissions (Breach)
        -   Flag as breach if ANY regular UK accounts have any access to databases (Breach)
        -   Flag as non-compliant if any -oper- accounts have production access at server or database level (Non-Compliant)
#>

<#
    Operator Account Checks

        -   Define list of security groups AMS operator accounts should have and flag as non-compliant if there is any deviation (Non-Compliant)

    Regular Account Checks

        -   Define list of security groups AMS developer accounts should NOT have and flag as breach if there is any deviation (Breach)

#>


#endregion Review Information
Start-Sleep -Seconds 3
#region Output final report

#endregion Output final report
Start-Sleep -Seconds 3
#region Kill Open Sessions and Vars
#Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue
#Get-Variable | Remove-Variable -ErrorAction SilentlyContinue
#endregion Kill Open Sessions and Vars
Start-Sleep -Seconds 3