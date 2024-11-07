param($ServerType = $null)

$ErrorActionPreference = "Stop"

$serverConfigFileLocation = $PSScriptRoot + "\WorkflowServers.environmentConfig"

$processStopped = $false
$processStarted = $false

Try {
	
	if (-Not (Test-Path $serverConfigFileLocation)) {
		throw "A " + $serverConfigFileLocation + " file is required"
	}
	
	$serverConfigLines = Get-Content (Get-Item $serverConfigFileLocation).PSPath
	
	$serverConfigs = @()
	
	foreach ($serverConfigLine in $serverConfigLines) {
		$split = $serverConfigLine.Split("|")
		if (($split | Measure-Object).Count -gt 3) {
			$servers += $split[1];
		}
	}

	$serverProperties = @{ServerType=''; Server=''; DeploymentLocation=''; RootPath=''; ScriptPath=''}
	$serverTemplate = New-Object -TypeName PSObject -Property $serverProperties
	
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
	
	$processStarted = $true
	
	foreach ($serverConfig in $serverConfigs) {
		if ($ServerType -eq $null -or $ServerType -eq $serverConfig.ServerType) {
			Try {
		
				Write-Output ""
				Write-Output "-------------------------------------------------------------------------------"
				Write-Output ("Performing an IIS reset on " + $serverConfig.Server)
				Write-Output "-------------------------------------------------------------------------------"
				Write-Output ""
			
				invoke-command -ComputerName $serverConfig.Server {
					param($serverConfig)
					Try {
					
						# -- This code is running remotely
						$ErrorActionPreference = "Stop"
						
						iisreset
						
						# -- Running remotely end
					} Catch {
						Write-Warning ("An exception was thrown on " + $serverConfig.Server + ".")
						Write-Output ""
						Write-Output "************************************"
						Write-Output ("EXCEPTION THROWN AT SCRIPT LINE " + $_.InvocationInfo.ScriptLineNumber + ":")
						Write-Output $_.Exception.ToString()
						Write-Output "************************************"
						Write-Output ""
						
						# Throwing to the try/catch on the calling server to stop the process.
						throw "This process was not successful."
					}

				} -ArgumentList $serverConfig
				
			} Catch {
				$processStopped = $true
				Write-Warning ("An exception was thrown on " + $serverConfig.Server + " - stopping this process.")
				if ($_.Exception.Message -ne "This process was not successful.") {
					Write-Output ""
					Write-Output "************************************"
					Write-Output ("EXCEPTION THROWN AT SCRIPT LINE " + $_.InvocationInfo.ScriptLineNumber + ":")
					Write-Output $_.Exception.ToString()
					Write-Output "************************************"
					Write-Output ""
				}
				break
			}
		}
	}
	
} Catch {
	Write-Warning ("A general exception was thrown.")
	Write-Output ""
	Write-Output "******************"
	Write-Output ("EXCEPTION THROWN AT LINE " + $_.InvocationInfo.ScriptLineNumber + ":")
	Write-Output $_.Exception.ToString()
	Write-Output "******************"
	Write-Output ""
	throw $_.Exception
}

Write-Output ""
Write-Output "-------------------------------------------------------------------------------"
if ($processStarted -eq $true) {
	if ($processStopped -eq $true) {
		Write-Output ("Process complete. Not all servers have had IIS reset performed; please check and fix any logged exceptions where necessary and run this script again when resolved.")
	} else {
		Write-Output ("Process complete.");
	}
}
Write-Output ""
Start-Sleep 2