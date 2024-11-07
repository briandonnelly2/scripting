$ErrorActionPreference = "Stop"

$serverConfigFileLocation = $PSScriptRoot + "\WorkflowServers.environmentConfig"
$packageConfigFileLocation = $PSScriptRoot + "\WorkflowPackages.environmentConfig"
$deploymentScriptFileName = "WorkflowPackageDeployment.ps1"

$packagesDeployed = $false
$processStopped = $false
$packageNotDeployed = $false

Try {

	$packageLocation = $PSScriptRoot + "\..\Packages"

	$deploymentDate = (Get-Date -format "yyyy-MM-dd")

	$deployedPackageLocation = $packageLocation + "\Deployed\" + $deploymentDate
	$notDeployedPackageLocation = $packageLocation + "\NotDeployed\" + $deploymentDate

	if (-Not (Test-Path $serverConfigFileLocation)) {
		throw "A " + $serverConfigFileLocation + " file is required"
	}

	if (-Not (Test-Path $packageConfigFileLocation)) {
		throw "A " + $packageConfigFileLocation + " file is required"
	}

	if (-Not (Test-Path $packageLocation)) {
		throw "A package location cannot be found"
	}

	if (-Not (Test-Path $packageLocation)) {
		throw "A package location cannot be found"
	}

	$serverConfigLines = Get-Content (Get-Item $serverConfigFileLocation).PSPath
	$packageConfigLines = Get-Content (Get-Item $packageConfigFileLocation).PSPath

	$serverConfigs = @()
	$packageConfigs = @()

	$serverProperties = @{ServerType=''; Server=''; DeploymentLocation=''; RootPath=''; ScriptPath=''}
	$serverTemplate = New-Object -TypeName PSObject -Property $serverProperties

	$packageProperties = @{ServerType=''; PackageName=''; Copied=$false; FullName=''; FileName=''}
	$packageTemplate = New-Object -TypeName PSObject -Property $packageProperties

	foreach ($serverConfigLine in $serverConfigLines) {
		$split = $serverConfigLine.Split("|")
		if (($split | Measure-Object).Count -ge 4) {
			$serverConfig = $serverTemplate.PSObject.Copy()
			$serverConfig.ServerType = $split[0]
			$serverConfig.Server = $split[1]
			$serverConfig.DeploymentLocation = $split[2]
			$serverConfig.RootPath = $split[3]
			$serverConfig.ScriptPath = $split[3] + "\" + $deploymentScriptFileName
			$serverConfigs += $serverConfig
		}
	}

	foreach ($packageConfigLine in $packageConfigLines) {
		$split = $packageConfigLine.Split("|")
		if (($split | Measure-Object).Count -ge 2) {
			$packageConfig = $packageTemplate.PSObject.Copy()
			$packageConfig.ServerType = $split[0]
			$packageConfig.PackageName = $split[1]

			$packages = Get-ChildItem -Path $packageLocation -Filter ($packageConfig.PackageName + " *.zip")
			if (($packages | Measure-Object).Count -eq 0) {
				continue
			}

			if (($packages | Measure-Object).Count -ne 1) {
				throw "Multiple package versions were found for " + $packageConfig.PackageName
			}

			$packageConfig.FullName = $packages[0].FullName
			$packageConfig.FileName = $packages[0].Name

			$packageConfigs += $packageConfig
		}
	}

	if (($serverConfigs | Measure-Object).Count -eq 0) {
		throw "No servers are configured to deploy to"
	}

	if (($packageConfigs | Measure-Object).Count -ne 0) {
		foreach ($serverConfig in $serverConfigs) {
			Write-Output ""
			Write-Output "----------------------------------------------"

			if (-Not (Test-Path $serverConfig.DeploymentLocation)) {
				throw "The deployment location of '" + $serverConfig.DeploymentLocation + "' cannot be found on " + $serverConfig.Server
			}
			
			# Clearing Deployment Location Start ---------------------------------------------------------------

			Write-Output ("Clearing the deployment location for " + $serverConfig.Server + "...")
			Get-ChildItem -Path $serverConfig.DeploymentLocation -Filter "*.zip" | foreach ($_) { Remove-Item $_.FullName -Force }
		}
		
		foreach ($serverConfig in $serverConfigs) {
			Write-Output ""
			Write-Output "----------------------------------------------"
			Write-Output ""
			Write-Output ("Copying '" + $serverConfig.ServerType +"' packages to " + $serverConfig.Server + " for deployment...")
			
			# Copying Packages To Servers Start ---------------------------------------------------------------
			
			foreach($packageConfig in $packageConfigs) {
				if (-Not ($packageConfig.ServerType -eq $serverConfig.ServerType)) {
					continue
				}
				Write-Output ("Copying '" + $packageConfig.FileName + "' to '" + $serverConfig.DeploymentLocation + "'...")
				Copy-Item $packageConfig.FullName $serverConfig.DeploymentLocation
				Write-Output ($packageConfig.FullName + " To " + $serverConfig.DeploymentLocation)

				$packageConfig.Copied = $true
			}
			
			# Copying Packages To Servers End ---------------------------------------------------------------
		}
		
		Write-Output ""
		Write-Output "----------------------------------------------"
		Write-Output ""
		
		# Copying Packages To Deployed Locations Start ---------------------------------------------------------------
		
		foreach($packageConfig in $packageConfigs) {
			if ($packageConfig.Copied -eq $true) {
				if (-Not (Test-Path ($deployedPackageLocation))) {
					New-Item -ItemType directory -Path $deployedPackageLocation | Out-Null
				}
				Move-Item $packageConfig.FullName $deployedPackageLocation -force
			} else {
				$packageNotDeployed = $true
				if (-Not (Test-Path ($notDeployedPackageLocation))) {
					New-Item -ItemType directory -Path $notDeployedPackageLocation | Out-Null
				}
				Move-Item $packageConfig.FullName $notDeployedPackageLocation -force
			}
		}
		
		# Copying Packages To Deployed Locations End ---------------------------------------------------------------
	}

	foreach ($serverConfig in $serverConfigs) {
		$packages = Get-ChildItem -Path $serverConfig.DeploymentLocation -Filter "*.zip"
		if (($packages | Measure-Object).Count -ne 0) {
			$packagesDeployed = $true
			Try {
				Write-Output ""
				Write-Output "-------------------------------------------------------------------------------"
				Write-Output ("Running Package Installation Script on " + $serverConfig.Server)
				Write-Output "-------------------------------------------------------------------------------"
				invoke-command -ComputerName $serverConfig.Server { 
					param($scriptPath,$rootPath)
					
					# -- Running remotely start
					
					$ErrorActionPreference = "Stop"
					
					& $scriptPath -Path $rootPath -ThrowDeploymentFailedException $true
					
					# -- Running remotely end
				} -ArgumentList $serverConfig.ScriptPath,$serverConfig.RootPath
			} Catch {
				$processStopped = $true
				Write-Warning ("An exception was thrown when deploying to " + $serverConfig.Server + " - stopping the deployment process.")
				if ($_.Exception.Message -ne "This deployment was not successful.") {
					Write-Output ""
					Write-Output "************************************"
					Write-Output ("EXCEPTION THROWN AT SCRIPT LINE " + $_.InvocationInfo.ScriptLineNumber + ":")
					Write-Output $_.Exception.ToString()
					Write-Output "************************************"
				}
				Write-Output ""
				Write-Output "Re-running this script can solve a number of deployment issues (e.g. locked files) - please try again before attempting to restore a backup."
				Write-Output ""
				break
			}
		}
	}

} Catch {
	Write-Warning ("A general exception was thrown.")
	Write-Output ""
	Write-Output "************************************"
	Write-Output ("EXCEPTION THROWN AT SCRIPT LINE " + $_.InvocationInfo.ScriptLineNumber + ":")
	Write-Output $_.Exception.ToString()
	Write-Output "************************************"
	Write-Output ""

}

Write-Output ""
if ($packagesDeployed -eq $false) {
	Write-Output "No packages were found to deploy in this environment."
} elseif ($processStopped -eq $true) {
	Write-Output "-------------------------------------------------------------------------------"
	Write-Warning "Process complete. This deployment was stopped part way through - please check any errors and run this script once more if a file system error occurred (e.g. access denied to a file). Otherwise, please log in to the affected server to resolve the issue, or to restore a backup."
} elseif ($packageNotDeployed -eq $true) {
	Write-Output "-------------------------------------------------------------------------------"
	Write-Warning ("Process complete. Some packages have been deployed, but at least 1 has not been configured for deployment using this script. Please update the " + $packageConfigFileLocation + " configuration file and ensure each server is set up for the new application.")
} else {
	Write-Output "-------------------------------------------------------------------------------"
	Write-Output "Process complete. All packages have been deployed."
}
Write-Output ""
Start-Sleep -s 2