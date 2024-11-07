param($Mode = $null)

$ErrorActionPreference = "Stop"

$serverConfigFileLocation = $PSScriptRoot + "\WorkflowServers.environmentConfig"
$packageConfigFileLocation = $PSScriptRoot + "\WorkflowPackages.environmentConfig"

$processStopped = $false
$processStarted = $false

Try {
	if ($Mode -ne "Stop" -and $Mode -ne "Start") {
		throw "A '-Mode' parameter of 'Stop' or 'Start' is required."
	}

	$stopping = $true
	if ($mode -ne "Stop") {
		$stopping = $false
	}

	if (-Not (Test-Path $serverConfigFileLocation)) {
		throw "A " + $serverConfigFileLocation + " file is required"
	}

	if (-Not (Test-Path $packageConfigFileLocation)) {
		throw "A " + $packageConfigFileLocation + " file is required"
	}

	$serverConfigLines = Get-Content (Get-Item $serverConfigFileLocation).PSPath
	$packageConfigLines = Get-Content (Get-Item $packageConfigFileLocation).PSPath

	$serverConfigs = @()
	$packageConfigs = @()

	foreach ($serverConfigLine in $serverConfigLines) {
		$split = $serverConfigLine.Split("|")
		if (($split | Measure-Object).Count -gt 3) {
			$servers += $split[1];
		}
	}

	$serverProperties = @{ServerType=''; Server=''; DeploymentLocation=''; RootPath=''; ScriptPath=''}
	$serverTemplate = New-Object -TypeName PSObject -Property $serverProperties

	$packageProperties = @{ServerType=''; PackageName=''; PackageType=''; Copied=$false; FullName=''; FileName=''}
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
			$packageConfigs += $packageConfig
		}
	}

	$processStarted = $true
	
	# Stopping order
	$areas = "Windows Services","Background Runtime Services","Web Applications","Scheduled Tasks","Web Services"
	if ($stopping -eq $false) {
		# Reverse the order if starting
		[array]::Reverse($areas)
	}
	
	foreach ($area in $areas) {
		foreach ($serverConfig in $serverConfigs) {
			Try {
			
				Write-Output ""
				Write-Output "-------------------------------------------------------------------------------"
				if ($stopping -eq $true) { Write-Output ("Stopping Workflow " + $area + " on " + $serverConfig.Server) } else { Write-Output ("Starting Workflow " + $area + " on " + $serverConfig.Server) }
				Write-Output "-------------------------------------------------------------------------------"
				Write-Output ""
				
				$serverPackages = @()
				foreach($packageConfig in $packageConfigs) {
					if ($packageConfig.ServerType -eq $serverConfig.ServerType) {
						$serverPackages += $packageConfig
					}
				}
				
				invoke-command -ComputerName $serverConfig.Server {
					param($serverConfig,$serverPackages,$stopping,$area)
					Try {
					
						# -- This code is running remotely
						$ErrorActionPreference = "Stop"
						
						$environmentFileLocation = "WorkflowEnvironment.deploymentConfig"
						$windowsServicePrefix = "Workflow.WindowsService."
						$scheduledTaskPrefix = "ScheduledTask."
						$webServicePrefix = "ExternalServices."
						$scheduledTaskFileLocation = "ScheduledTasks.deploymentConfig"
						$appOffline = "app_offline.htm"
						$iisRoot = "IIS:\Sites\"
						$flowtimeSiteName = "Flowtime"
						$brsServiceName = "Background Runtime Service"
						
						$doneSomething = $false
						
						Import-Module WebAdministration
						
						if (-Not (test-path $serverConfig.RootPath)) { 
							throw "A valid script location is required for this server."
						}
						
						Set-Location -Path $serverConfig.RootPath | Out-Null
					
						if (-Not (test-path $environmentFileLocation)) {
							throw "An " + $environmentFileLocation + " file is required."
						}
						
						$environmentVariables = Get-Content (Get-Item $environmentFileLocation).PSPath
						if (($environmentVariables | Measure-Object).Count -ne 3) {
							throw "3 lines are required in " + $environmentFileLocation + " being the environment, deployment and package locations."
						}
						
						if (-Not (test-path $appOffline)) {
							throw "An " + $appOffline + " file is required in the script location for this server."
						}

						$environment = $environmentVariables[0]
						$deploymentLocation = $environmentVariables[1]
						$packageLocation = $environmentVariables[2]
						
						# BRS Start ---------------------------------------------------------------
						
						if ($area -eq "Background Runtime Services") {
							$brsServices = Get-Service * | Where-Object {$_.Name -eq $brsServiceName}

							if (($brsServices | Measure-Object).Count -eq 1) {
								$doneSomething = $true
								if ($stopping -eq $true) {
									# BRS Stopping
									if ($brsServices[0].Status -eq "Running") {
										Write-Output ("Stopping " + $brsServiceName + " on " + $serverConfig.Server + "...")
										Stop-Service $brsServices[0].Name
										Write-Output ("    " + $brsServiceName + " is stopped.")
									} elseif ($brsServices[0].Status -eq "Stopped") {
										Write-Output ($brsServiceName + " is stopped.")
									} else {
										Write-Output ($brsServiceName + " is not in an an expected 'Running' state on - the current state is " + $brsServices[0].Status)
									}
								} else {
									# BRS Starting
									if ($brsServices[0].Status -eq "Stopped") {
										Write-Output ("Starting " + $brsServiceName + " on " + $serverConfig.Server + "...")
										Start-Service $brsServices[0].Name
										Write-Output ("    " + $brsServiceName + " is running.")
									} elseif ($brsServices[0].Status -eq "Running") {
										Write-Output ($brsServiceName + " is running.")
									} else {
										Write-Output ($brsServiceName + " is not in an expected 'Stopped' state on - the current state is " + $brsServices[0].Status)
									}
								}
							}
						}
						
						# BRS End ---------------------------------------------------------------
						
						# Flowtime Start ---------------------------------------------------------------
						
						if ($area -eq "Web Applications") {
							if (test-path ($iisRoot + $flowtimeSiteName)) {
								$doneSomething = $true
								$iisSite = get-item ($iisRoot + $flowtimeSiteName)
								if ($stopping -eq $true) {
									if (test-path ($iisSite.PhysicalPath + "\" + $appOffline)) {
										Write-Output ($flowtimeSiteName + " is offline.")
									} else {
										Write-Output ("Copying " + $appOffline + " to " + $flowtimeSiteName + "...")
										Copy-Item $appOffline $iisSite.PhysicalPath -force
										Write-Output ("    " + $flowtimeSiteName + " is offline.")
									}
								} else {
									if ($iisSite.State -ne "Started") {
										Write-Output ("Starting the web site for " + $flowtimeSiteName + "...")
										Start-Website -Name $iisSite.Name
									}
								
									if (test-path ($iisSite.PhysicalPath + "\" + $appOffline)) {
										Write-Output ("Removing " + $appOffline + " from " + $flowtimeSiteName + "...")
										Remove-Item ($iisSite.PhysicalPath + "\" + $appOffline) -force
										Write-Output ("    " + $flowtimeSiteName + " is online.")
									} else {
										Write-Output ($flowtimeSiteName + " is online.")
									}
								}
							}
						}
						
						# Flowtime End ---------------------------------------------------------------
						
						foreach($package in $serverPackages) {
						
							$isWindowsService = $package.PackageName.StartsWith($windowsServicePrefix)
							$isScheduledTask = $package.PackageName.StartsWith($scheduledTaskPrefix)
							$isWebService = $package.PackageName.StartsWith($webServicePrefix)
						
							# Windows Services Start ---------------------------------------------------------------
							if ($area -eq "Windows Services") {
								if ($isWindowsService -eq $true) {
									$windowsServices = Get-Service * | Where-Object {$_.Name.StartsWith($package.PackageName)}
									foreach($windowsService in $windowsServices) {
										$doneSomething = $true
										if ($stopping -eq $true) {
											# Service Stopping
											if ($windowsService.Status -eq "Running") {
												Write-Output ("Stopping " + $windowsService.Name +"...")
												Stop-Service $windowsService.Name
												Write-Output ("    " + $windowsService.Name + " is stopped.")
											} elseif ($windowsService.Status -eq "Stopped") {
												Write-Output ($windowsService.Name + " is stopped.")
											} else {
												Write-Output ($windowsService.Name + " is not in an an expected 'Running' state - the current state is " + $brsServices[0].Status)
											}
										} else {
											# Service Starting
											if ($windowsService.Status -eq "Stopped") {
												Write-Output ("Starting " + $windowsService.Name + "...")
												Start-Service $windowsService.Name
												Write-Output ("    " + $windowsService.Name + " is running.")
											} elseif ($windowsService.Status -eq "Running") {
												Write-Output ($windowsService.Name + " is running.")
											} else {
												Write-Output ($windowsService.Name + " is not in an expected 'Stopped' state on - the current state is " + $brsServices[0].Status)
											}
										}
									}
								}
							}
						
							# Windows Services End ---------------------------------------------------------------
							
							# Web Applications / Services Start ---------------------------------------------------------------
							
							if (($area -eq "Web Applications" -and $isWebService -eq $false) -or ($area -eq "Web Services" -and $isWebService -eq $true)) {
								if ($isWindowsService -eq $false -and $isScheduledTask -eq $false) {
									
									$packageDeploymentLocation = $deploymentLocation + "\" + $package.PackageName
									
									if (-Not (test-path $packageDeploymentLocation)) {
										Write-Output ("*** A package deployment location cannot be found for " + $package.PackageName + " ***")
									} elseif (-Not (test-path ($iisRoot + $package.PackageName))) {
										Write-Output ("*** An IIS site has not been set up for " + $package.PackageName + " ***")
									} else {
										$doneSomething = $true
										
										$iisSite = Get-Item ($iisRoot + $package.PackageName)
										
										if ($stopping -eq $true) {
											if (test-path ($packageDeploymentLocation + "\" + $appOffline)) {
												Write-Output ($package.PackageName + " is offline.")
											} else {
												Write-Output ("Copying " + $appOffline + " to " + $package.PackageName + "...")
												Copy-Item $appOffline $packageDeploymentLocation -force
												Write-Output ("    " + $package.PackageName + " is offline.")
											}
										} else {
											if ($iisSite.State -ne "Started") {
												Write-Output ("Starting the web site for " + $package.PackageName + "...")
												Start-Website -Name $iisSite.Name
											}
										
											if (test-path ($packageDeploymentLocation + "\" + $appOffline)) {
												Write-Output ("Removing " + $appOffline + " from " + $package.PackageName + "...")
												Remove-Item ($packageDeploymentLocation + "\" + $appOffline) -force
												Write-Output ("    " + $package.PackageName + " is online.")
											} else {
												Write-Output ($package.PackageName + " is online.")
											}
										}
									}
								}
							}
							
							# Web Applications / Services End ---------------------------------------------------------------
						}
						
						# Scheduled Tasks Start ---------------------------------------------------------------
							
						if ($area -eq "Scheduled Tasks") {
							if (Test-Path $scheduledTaskFileLocation) {
								$scheduledTaskDefinitions = Get-Content (Get-Item $scheduledTaskFileLocation).PSPath
								($TaskScheduler = New-Object -ComObject Schedule.Service).Connect("localhost")
								foreach ($scheduledTaskDefinition in $scheduledTaskDefinitions) {
									$doneSomething = $true
									$folderDefinition = $scheduledTaskDefinition.Split("|")
									if (($folderDefinition | Measure-Object).Count -eq 2) {
										$nextTask = $TaskScheduler.GetFolder(('\' + $folderDefinition[0])).GetTask($folderDefinition[1])
										$nextTaskName = $folderDefinition[0] + "/" + $folderDefinition[1]
										if ($stopping -eq $true) {
											if ($nextTask.State -eq 1) {
												Write-Output ("Scheduled task '" + $nextTaskName + "' is disabled.")
											} else {
												While ($nextTask.State -eq 4) {
													Write-Warning ("Waiting for scheduled task '" + $nextTaskName + "' to finish running...")
													Start-Sleep 2
												}
												Write-Output ("Disabling scheduled task '" + $nextTaskName + "'")
												$nextTask.Enabled = $false
												Write-Output ("    " + "Scheduled task '" + $nextTaskName + "' is disabled.")
											}
										} else {
											if ($nextTask.State -ne 1) {
												Write-Output ("Scheduled task '" + $nextTaskName + "' is enabled.")
											} else {
												Write-Output ("Enabling scheduled task '" + $nextTaskName + "'...")
												$nextTask.Enabled = $true
												Write-Output ("    " + "Scheduled task '" + $nextTaskName + "' is enabled.")
											}
										}
									}
								}
							}
						}
						
						# Scheduled Tasks End ---------------------------------------------------------------
						
						if ($doneSomething -eq $false) {
							Write-Output ("No " + $area.ToLower() + " are set up on " + $serverConfig.Server + ".")
						}
						
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

				} -ArgumentList $serverConfig,$serverPackages,$stopping,$area
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
		
		if ($processStopped -eq $true) {
			break
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
		if ($stopping -eq- $true) {
			Write-Output ("Process complete. Not all servers have had their services stopped; please check and fix any logged exceptions where necessary and run this script again when resolved.")
		} else {
			Write-Output ("Process complete. Not all servers have had their services started; please check and fix any logged exceptions where necessary and run this script again when resolved.")
		}
	} else {
		Write-Output ("Process complete.");
	}
}
Write-Output ""
Start-Sleep 2