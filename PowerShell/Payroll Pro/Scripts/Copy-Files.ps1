#This is the env we are working in
$DeploymentType = 'Staging'

#Import the psd1 file with the data paths
#Import-PowerShellDataFile -Path "$PSScriptRoot\config\*.psd1" # Live
$Data = Import-PowerShellDataFile -Path ".\config\*.psd1" # test

#Check to see if more than one package folder exists (exclude ZIP's and the 'Extracted' folder)
$ExtractedFilesDir = Get-ChildItem -Path $Data.gen.PackageDir -Exclude ('Extracted','*.zip')

#If deployment type is Staging, deploy production files
If('Staging' -eq $DeploymentType) {
    If(1 -lt $ExtractedFilesDir.Count) {
        #There are more than one set of application files, abort...
    }
    ElseIf(0 -eq $ExtractedFilesDir.Count) {
        #There are no application files, abort...
    }
    else {
        #This means thdere is only one folder with app files, proceed...
    
        #Store the locations of the folders from the applications files that were extracted and found....
        $CopyFolders = Get-ChildItem -Path (Join-Path -Path $Data.gen.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip')
    
        #Switch statement that checks if each source location exists, if they do, it copies the required files to those locations...
        switch ($true) {
            ($CopyFolders.Name -contains 'ApplicationFilesPath') { 
                #Grabs the source location of the files
                $AppFiles = Get-ChildItem -Path (Join-Path -Path $Data.gen.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') -Recurse | Where-Object -Property Name -eq 'ApplicationFilesPath'
    
                #Copies files across to the relevant location
                Copy-Item -Path $AppFiles -Destination $Data.staging.AccessDBFiles -Recurse -Force
            }
            ($CopyFolders.Name -contains 'ProgramDirectory') { 
                #Grabs the source location of the files
                $ProgFiles = Get-ChildItem -Path (Join-Path -Path $Data.gen.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'ProgramDirectory'
    
                #Copies files across to the relevant location
                Copy-Item -Path $ProgFiles -Destination $Data.staging.ProgDir -Recurse -Force
            }
            ($CopyFolders.Name -contains 'Reports') { 
                #Grabs the source location of the files
                $RptFiles = Get-ChildItem -Path (Join-Path -Path $Data.gen.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'Reports'
    
                #Copies files across to the relevant location
                Copy-Item -Path $RptFiles -Destination $Data.staging.Reports -Recurse -Force
            }
            ($CopyFolders.Name -contains 'Schemas') { 
                #Grabs the source location of the files
                $ScmFiles = Get-ChildItem -Path (Join-Path -Path $Data.gen.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'Schemas'
    
                #Copies files across to the relevant location
                Copy-Item -Path $ScmFiles -Destination $Data.staging.Schemas -Recurse -Force
            }
            Default { 
    
            }
        }
    }
}
#If deployment type is production, deploy production files
ElseIf('Prod' -eq $DeploymentType) {
    If(1 -lt $ExtractedFilesDir.Count) {
        #There are more than one set of application files, abort...
    }
    ElseIf(0 -eq $ExtractedFilesDir.Count) {
        #There are no application files, abort...
    }
    else {
        #This means thdere is only one folder with app files, proceed...
    
        #Store the locations of the folders from the applications files that were extracted and found....
        $CopyFolders = Get-ChildItem -Path (Join-Path -Path $Data.gen.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip')
    
        #Switch statement that checks if each source location exists, if they do, it copies the required files to those locations...
        switch ($true) {
            ($CopyFolders.Name -contains 'ApplicationFilesPath') { 
                #Grabs the source location of the files
                $AppFiles = Get-ChildItem -Path (Join-Path -Path $Data.prod.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'ApplicationFilesPath'
    
                #Copies files across to the relevant location
                Copy-Item -Path $AppFiles -Destination $Data.prod.AccessDBFiles -Recurse -Force
            }
            ($CopyFolders.Name -contains 'ProgramDirectory') { 
                #Grabs the source location of the files
                $ProgFiles = Get-ChildItem -Path (Join-Path -Path $Data.prod.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'ProgramDirectory'
    
                #Copies files across to the relevant location
                Copy-Item -Path $ProgFiles -Destination $Data.prod.ProgDir -Recurse -Force
            }
            ($CopyFolders.Name -contains 'Reports') { 
                #Grabs the source location of the files
                $RptFiles = Get-ChildItem -Path (Join-Path -Path $Data.prod.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'Reports'
    
                #Copies files across to the relevant location
                Copy-Item -Path $RptFiles -Destination $Data.prod.Reports -Recurse -Force
            }
            ($CopyFolders.Name -contains 'Schemas') { 
                #Grabs the source location of the files
                $ScmFiles = Get-ChildItem -Path (Join-Path -Path $Data.prod.PackageDir -ChildPath .\*) -Exclude ('Extracted','*.zip') | Where-Object -Property Name -eq 'Schemas'
    
                #Copies files across to the relevant location
                Copy-Item -Path $ScmFiles -Destination $Data.prod.Schemas -Recurse -Force
            }
            Default { 
    
            }
        }
    }
}
Else {

}