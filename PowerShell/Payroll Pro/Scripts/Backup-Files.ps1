Function Backup-Files {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$BackupDirectory
    )

    #Checks backup path does not already exist
    If($False -eq (Test-Path -Path $BackupDirectory)) {
        #Create the directory
        New-Item -Path $BackupDirectory -ItemType Directory -Force

        #Backup the required files
    }
    #Else the backup location does exist
    Else {
        #Check to see if the backup directory has an existing backup
        $BackupContents = Get-ChildItem -Path $BackupDirectory -Depth 1 | Select-Object -ExpandProperty Name
    }
}


    Else {
        #Bakup the access database files
        foreach($File in $Data.gen.AccessDBFileNames) {
            Copy-Item -Path ($Data.staging.AccessDBFiles + '\' + $File) -Destination $BackupDir -Verbose
        }

        #Backup the Star program directory
        Copy-Item -Path $Data.Staging.ProgDir -Destination "$BackupDir\Star\" -Recurse -Verbose

        If($null -eq ( Get-ChildItem -Path $BackupDir ) ) {
            #Something has went wrong as the backup directory is empty
        }
        Else {
            #Everything is fine as the backup directory is populated   
        }
    }
}
#If deployment type is production, backup production files
ElseIf('Production' -eq $DeploymentType) {
    #This is a Prod deployment, therefore we backup the Production files into the appropriate backup directory
    $BackupDir = $Data.prod.Backup

    #Check to see if the backup directory has an existing backup for todays date
    If( Test-Path -Path ($backupDir + "\$DeploymentNumber")) {
        #Don't carry out a backup if one already exists
    }
    Else {
        #Bakup the access database files
        foreach($File in $Data.gen.AccessDBFileNames) {
            Copy-Item -Path ($Data.prod.AccessDBFiles + '\' + $File) -Destination $BackupDir -Verbose
        }

        #Backup the Star program directory
        Copy-Item -Path $Data.prod.ProgDir -Destination "$BackupDir\Star\" -Recurse -Verbose

        If($null -eq ( Get-ChildItem -Path $BackupDir ) ) {
            #Something has went wrong as the backup directory is empty
        }
        Else {
            #Everything is fine as the backup directory is populated   
        }
    }
}
Else {
    #Wrong Deployment typoe passed in, something is fundamentally wrong, quit execution
}