$BackupRoot =   "\\UKVMPAPP1094\TPLBackupShare\CCHSuite\Prod"
$SourceFiles =  "\\UKVMPAPP1094\TPLDeploymentShare\CCHSuite\UAT",
                "\\UKVMPAPP1094\TPLScriptsShare\SQL"
$DeployNum = 1

New-KPMGBackup -SourceFolders $SourceFiles -DeploymentNumber $DeployNum -Verbose


$SourceDirectory = "\\UKVMPAPP1094\TPLDeploymentShare\CCHSuite\UAT"
$DestinationDirectory = "\\UKVMURDS1002\deploy$"

Copy-KPMGFiles -SourceFolder $SourceDirectory -DestinationFolder $DestinationDirectory -DeploymentNumber 1

$Info = Get-KPMGSysInformation -ServerNames UKVMURDS1002