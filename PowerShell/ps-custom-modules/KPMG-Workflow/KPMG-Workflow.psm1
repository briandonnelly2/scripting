Function Stop-WorkflowEnvironment {
    <#
        .SYNOPSIS
            Stops the Sequence Workflow Environment
        .DESCRIPTION
            This function will stop an entire Sequence Workflow environment given an environment name.
        .PARAMETER Environment <String>
            The environment you are stopping, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Stop-WorkflowEnvironment -Environment DEV
        .EXAMPLE
            Stop-WorkflowEnvironment -Environment UAT
        .NOTES
            Name Stop-WorkflowEnvironment
            Creator Brian Donnelly
            Date 05/11/2024
            Updated N/A
    #>

    #requires -runasadministrator

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An environment name is needed")]
        [ValidateSet("DEV", "UAT", "PROD")]
        [string]$Environment
    )

    #Log Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "Sequence Environement Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #PROD servers:
    [string[]]$ProdAppServers = 'UKAZRSAPPP0019',
                                'UKAZRSAPPP0020',
                                'UKAZRSAPPP0021',
                                'UKAZRSAPPP0022',
                                'UKAZRSAPPP0023'

    [string[]]$ProdWebServers = 'UKAZRSWEBP0003',
                                'UKAZRSWEBP0004',
                                'UKAZRSWEBP0005',
                                'UKAZRSWEBP0006'

    #UAT Servers
    [string[]]$UATAppServers  = 'UKAZRAPP1007',
                                'UKAZRAPP1008',
                                'UKAZRAPP1009'

    [string[]]$UATWebServers  = 'UKAZRWEB1002',
                                'UKAZRWEB1008'

    #DEV Servers
    [string[]]$DevAppServers  = 'UKAZRSAPPD0001',
                                'UKAZRSAPPD0002',
                                'UKAZRSAPPD0003'

    [string[]]$DevWebServers  = 'UKAZRSWEBD0001'

    #Sequence App Service names
    [string[]]$WinServices    = 'Background Runtime Service',
                                'KPMG.TaxConnect.Workflow.Service',
                                'Job Execution Service',
                                'Active Directory Synchronization Service'

    #IIS Service Name
    [string]$WebService       = 'W3SVC'

    New-EventLog -LogName $LogName -Source $LogSource -ComputerName $ENV:COMPUTERNAME -ErrorAction SilentlyContinue

    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + `
    " at " + (Get-Date -Format HH-mm-ss) + " on the " + $Environment + " environment."
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Use a switch statement to test the value of the $Environment variable and apply the actions to that environment
    switch ($Environment) {
        #For the DEV environment
        "DEV" {
            try {
                #Stop Sequence windows services
                Foreach($AppServer in $DevAppServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to manual, stop services
                            Get-Service -Name $WinService -ComputerName $AppServer | Set-Service -StartupType Manual -PassThru
                            Get-Service -Name $WinService -ComputerName $AppServer | Stop-Service -Force -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Stop the web server(s).  Done through stopping the W3SVC service.
                foreach($WebServer in $DevWebServers) {
                    #change startup type to manual, stop service
                    Get-Service -Name $WebService -ComputerName $WebServer | Set-Service -StartupType Disabled -PassThru
                    Get-Service -Name $WebService -ComputerName $WebServer | Stop-Service -Force -PassThru

                    #Check status of service
                    $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                    #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                    $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                    + $ServiceStatus.StartType + " on " + $WebServer
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                    Write-Verbose $Message
                }

                #Write a message to the event log stating the environment has been stopped and print to the terminal.
                $Message = "The Sequence services on " + $DevAppServers + " have now been stopped and set to manual. "`
                + "The web server(s) on " + $DevWebServers + " have also been stopped." `
                + " This means the " + $Environment + " environment is now offline" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                Write-Output $Message
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }
        #For the UAT environment
        "UAT" {
            try {
                #Stop Sequence windows services
                Foreach($AppServer in $UATAppServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to manual, stop services
                            Get-Service -Name $WinService -ComputerName $AppServer | Set-Service -StartupType Manual -PassThru
                            Get-Service -Name $WinService -ComputerName $AppServer | Stop-Service -Force -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Stop the web server(s).  Done through stopping the W3SVC service.
                foreach($WebServer in $UATWebServers) {
                    #change startup type to manual, stop service
                    Get-Service -Name $WebService -ComputerName $WebServer | Set-Service -StartupType Disabled -PassThru
                    Get-Service -Name $WebService -ComputerName $WebServer | Stop-Service -Force -PassThru

                    #Check status of service
                    $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                    #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                    $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                    + $ServiceStatus.StartType + " on " + $WebServer
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                    Write-Verbose $Message
                }

                #Write a message to the event log stating the environment has been stopped and print to the terminal.
                $Message = "The Sequence services on " + $UATAppServers + " have now been stopped and set to manual. "`
                + "The web server(s) on " + $UATWebServers + " have also been stopped." `
                + " This means the " + $Environment + " environment is now offline" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                Write-Output $Message
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }
        #For the PROD environment
        "PROD" {
            try {
                #Stop Sequence windows services
                Foreach($AppServer in $ProdAppServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to manual, stop services
                            Get-Service -Name $WinService -ComputerName $AppServer | Set-Service -StartupType Manual -PassThru
                            Get-Service -Name $WinService -ComputerName $AppServer | Stop-Service -Force -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Stop the web server(s).  Done through stopping the W3SVC service.
                foreach($WebServer in $ProdWebServers) {
                    #change startup type to manual, stop service
                    Get-Service -Name $WebService -ComputerName $WebServer | Set-Service -StartupType Disabled -PassThru
                    Get-Service -Name $WebService -ComputerName $WebServer | Stop-Service -Force -PassThru

                    #Check status of service
                    $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                    #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                    $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                    + $ServiceStatus.StartType + " on " + $WebServer
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                    Write-Verbose $Message
                }

                #Write a message to the event log stating the environment has been stopped and print to the terminal.
                $Message = "The Sequence services on " + $ProdAppServers + " have now been stopped and set to manual. "`
                + "The web server(s) on " + $ProdWebServers + " have also been stopped." `
                + " This means the " + $Environment + " environment is now offline" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                Write-Output $Message
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }
    }
}

Function Start-WorkflowEnvironment {
    <#
        .SYNOPSIS
            Starts the Sequence Workflow Environment
        .DESCRIPTION
            This function will start an entire Sequence Workflow environment given an environment name.
        .PARAMETER Environment <String>
            The environment you are starting, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Start-WorkflowEnvironment -Environment 'DEV'
        .EXAMPLE
            Start-WorkflowEnvironment -Environment 'UAT'
        .NOTES
            Name Start-WorkflowEnvironment
            Creator Brian Donnelly
            Date 05/11/2024
            Updated N/A
    #>
    
    #requires -runasadministrator
    
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An environment name is needed")]
        [ValidateSet("DEV", "UAT", "PROD")]
        [string]$Environment
    )

    #Log Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "Sequence Environement Management"
    [string]$LogSource = $MyInvocation.MyCommand
    
    #PROD servers:
    [string[]]$ProdAppServers = 'UKAZRSAPPP0019',
                                'UKAZRSAPPP0020',
                                'UKAZRSAPPP0021',
                                'UKAZRSAPPP0022',
                                'UKAZRSAPPP0023'
    
    [string[]]$ProdWebServers = 'UKAZRSWEBP0003',
                                'UKAZRSWEBP0004',
                                'UKAZRSWEBP0005',
                                'UKAZRSWEBP0006'
    
    #UAT Servers
    [string[]]$UATAppServers  = 'UKAZRAPP1007',
                                'UKAZRAPP1008',
                                'UKAZRAPP1009'
    
    [string[]]$UATWebServers  = 'UKAZRWEB1002',
                                'UKAZRWEB1008'
    
    #DEV Servers
    [string[]]$DevAppServers  = 'UKAZRSAPPD0001',
                                'UKAZRSAPPD0002',
                                'UKAZRSAPPD0003'
    
    [string[]]$DevWebServers  = 'UKAZRSWEBD0001'
    
    #Sequence App Service names
    [hashtable]$WinServices   = [ordered]@{
                    'first'   = 'Active Directory Synchronization Service'
                    'second'  = 'Background Runtime Service'
                    'third'   = 'Job Execution Service'
                    'fourth'  = 'KPMG.TaxConnect.Workflow.Service'
                            }
    
    #IIS Service Name
    [string]$WebService       = 'W3SVC'

    New-EventLog -LogName $LogName -Source $LogSource -ComputerName $ENV:COMPUTERNAME -ErrorAction SilentlyContinue
    
    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + `
    " at " + (Get-Date -Format HH-mm-ss) + " on the " + $Environment + " environment."
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Use a switch statement to test the value of the $Environment variable and apply the actions to that environment
    switch ($Environment) {
        #For the DEV environment
        "DEV" {
            try {
                #Start Sequence windows services
                foreach($WinService in $WinServices.Keys) {
                    foreach($AppServer in $DevAppServers) {
                        $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType
                        
                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to Automatic, Start services
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Set-Service -StartupType Automatic -PassThru
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Start-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Start the web server(s).  Done through starting the W3SVC service.
                foreach($WebServer in $DevWebServers) {
                    #change startup type to Automatic, start service
                    Get-Service -Name $WebService -ComputerName $WebServer | Set-Service -StartupType Automatic -PassThru
                    Get-Service -Name $WebService -ComputerName $WebServer | Start-Service -PassThru

                    #Check status of service
                    $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                    #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                    $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                    + $ServiceStatus.StartType + " on " + $WebServer
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                    Write-Verbose $Message
                }

                #Write a message to the event log stating the environment has been started and print to the terminal.
                $Message = "The Sequence services on " + $DevAppServers + " have now been started and set to automatic start. "`
                + "The web server(s) on " + $DevWebServers + " have also been started." `
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                Write-Output $Message
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }

        #For the UAT environment
        "UAT" {
            try {
                #Start Sequence windows services
                foreach($WinService in $WinServices.Keys) {
                    foreach($AppServer in $UATAppServers) {
                        $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType
                        
                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to Automatic, Start services
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Set-Service -StartupType Automatic -PassThru
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Start-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Start the web server(s).  Done through starting the W3SVC service.
                foreach($WebServer in $UATWebServers) {
                    #change startup type to Automatic, start service
                    Get-Service -Name $WebService -ComputerName $WebServer | Set-Service -StartupType Automatic -PassThru
                    Get-Service -Name $WebService -ComputerName $WebServer | Start-Service -PassThru

                    #Check status of service
                    $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                    #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                    $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                    + $ServiceStatus.StartType + " on " + $WebServer
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                    Write-Verbose $Message
                }

                #Write a message to the event log stating the environment has been started and print to the terminal.
                $Message = "The Sequence services on " + $UATAppServers + " have now been started and set to automatic start. "`
                + "The web server(s) on " + $UATWebServers + " have also been started." `
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                Write-Output $Message
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }

        #For the PROD environment
        "PROD" {
            try {
                #Start Sequence windows services
                foreach($WinService in $WinServices.Keys) {
                    foreach($AppServer in $ProdAppServers) {
                        $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType
                        
                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to Automatic, Start services
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Set-Service -StartupType Automatic -PassThru
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Start-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Start the web server(s).  Done through starting the W3SVC service.
                foreach($WebServer in $ProdWebServers) {
                    #change startup type to Automatic, start service
                    Get-Service -Name $WebService -ComputerName $WebServer | Set-Service -StartupType Automatic -PassThru
                    Get-Service -Name $WebService -ComputerName $WebServer | Start-Service -PassThru

                    #Check status of service
                    $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                    #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                    $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                    + $ServiceStatus.StartType + " on " + $WebServer
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                    Write-Verbose $Message
                }

                #Write a message to the event log stating the environment has been started and print to the terminal.
                $Message = "The Sequence services on " + $ProdAppServers + " have now been started and set to automatic start. "`
                + "The web server(s) on " + $ProdWebServers + " have also been started." `
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                Write-Output $Message
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }
    }
}

Function Restart-WorkflowEnvironment {
    <#
        .SYNOPSIS
            Restarts the Sequence Workflow Environment
        .DESCRIPTION
            This function will restart an entire Sequence Workflow environment given an environment name.
        .PARAMETER Environment <String>
            The environment you are restarting, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Restart-WorkflowEnvironment -Environment 'DEV'
        .EXAMPLE
            Restart-WorkflowEnvironment -Environment 'UAT'
        .NOTES
            Name Restart-WorkflowEnvironment
            Creator Brian Donnelly
            Date 05/11/2024
            Updated N/A
    #>

    #requires -runasadministrator
    
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An environment name is needed")]
        [ValidateSet("DEV", "UAT", "PROD")]
        [string]$Environment
    )

    #Log Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "Sequence Environement Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #PROD servers:
    [string[]]$ProdAppServers = 'UKAZRSAPPP0019',
                                'UKAZRSAPPP0020',
                                'UKAZRSAPPP0021',
                                'UKAZRSAPPP0022',
                                'UKAZRSAPPP0023'

    [string[]]$ProdWebServers = 'UKAZRSWEBP0003',
                                'UKAZRSWEBP0004',
                                'UKAZRSWEBP0005',
                                'UKAZRSWEBP0006'

    #UAT Servers
    [string[]]$UATAppServers  = 'UKAZRAPP1007',
                                'UKAZRAPP1008',
                                'UKAZRAPP1009'

    [string[]]$UATWebServers  = 'UKAZRWEB1002',
                                'UKAZRWEB1008'

    #DEV Servers
    [string[]]$DevAppServers  = 'UKAZRSAPPD0001',
                                'UKAZRSAPPD0002',
                                'UKAZRSAPPD0003'

    [string[]]$DevWebServers  = 'UKAZRSWEBD0001'

    #Sequence App Service names
    [hashtable]$WinServices   = [ordered]@{
                    'first'   = 'Active Directory Synchronization Service'
                    'second'  = 'Background Runtime Service'
                    'third'   = 'Job Execution Service'
                    'fourth'  = 'KPMG.TaxConnect.Workflow.Service'
    }

    #IIS Service Name
    [string]$WebService       = 'W3SVC'

    New-EventLog -LogName $LogName -Source $LogSource -ComputerName $ENV:COMPUTERNAME -ErrorAction SilentlyContinue

    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + `
    " at " + (Get-Date -Format HH-mm-ss) + " on the " + $Environment + " environment."
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Use a switch statement to test the value of the $Environment variable and apply the actions to that environment
    switch($Environment) {
        #For the DEV environment
        "DEV" {
            try {
                #Restart Sequence windows services
                foreach($WinService in $WinServices.Keys) {
                    foreach($AppServer in $DevAppServers) {
                        $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #Restart services
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " has been restarted on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }

                        #Restart the web server(s).  Done through restarting the W3SVC service.
                        foreach($WebServer in $DevWebServers) {
                            #Restart service
                            Get-Service -Name $WebService -ComputerName $WebServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " has been restarted on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }

                        #Write a message to the event log stating the environment has been restarted and print to the terminal.
                        $Message = "The Sequence services on " + $DevAppServers + " have now been restarted"`
                        + "The web server(s) on " + $DevWebServers + " have also been restarted." `
                        + " This means the " + $Environment + " environment is back online" 
                        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                        Write-Output $Message
                        
                        #Prints a message telling the user how to check the envuironment is currently.
                        $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                        Write-Output $Message
                    }
                }
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }

        #For the UAT environment
        "UAT" {
            try {
                #Restart Sequence windows services
                foreach($WinService in $WinServices.Keys) {
                    foreach($AppServer in $UATAppServers) {
                        $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #Restart services
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " has been restarted on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }

                        #Restart the web server(s).  Done through restarting the W3SVC service.
                        foreach($WebServer in $UATWebServers) {
                            #Restart service
                            Get-Service -Name $WebService -ComputerName $WebServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " has been restarted on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }

                        #Write a message to the event log stating the environment has been restarted and print to the terminal.
                        $Message = "The Sequence services on " + $UATAppServers + " have now been restarted"`
                        + "The web server(s) on " + $UATWebServers + " have also been restarted." `
                        + " This means the " + $Environment + " environment is back online" 
                        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                        Write-Output $Message
                        
                        #Prints a message telling the user how to check the envuironment is currently.
                        $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                        Write-Output $Message
                    }
                }
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }

        #For the PROD environment
        "PROD" {
            try {
                #Restart Sequence windows services
                foreach($WinService in $WinServices.Keys) {
                    foreach($AppServer in $ProdAppServers) {
                        $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the AD Sync services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #Restart services
                            Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name "${$WinService}$($WinServices[$WinService])" -ComputerName $AppServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " has been restarted on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }

                        #Restart the web server(s).  Done through restarting the W3SVC service.
                        foreach($WebServer in $ProdWebServers) {
                            #Restart service
                            Get-Service -Name $WebService -ComputerName $WebServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " has been restarted on " + $AppServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }

                        #Write a message to the event log stating the environment has been restarted and print to the terminal.
                        $Message = "The Sequence services on " + $ProdAppServers + " have now been restarted"`
                        + "The web server(s) on " + $ProdWebServers + " have also been restarted." `
                        + " This means the " + $Environment + " environment is back online" 
                        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                        Write-Output $Message
                        
                        #Prints a message telling the user how to check the envuironment is currently.
                        $Message = "To check this, run Assert-SequenceEnvironment -Environment " + "'" + $Environment + "'"
                        Write-Output $Message
                    }
                }
            }
            catch {
                #Writes a message to the event log and the terminal detailing the error
                $Message = "The following error occurred: " + $_.Exception.Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Verbose $Message
            }
        }
    }
}

Function Assert-WorkflowEnvironment {
    <#
    .SYNOPSIS
        Checks the sequence services and the service that runs IIS the Sequence Workflow Environment
    .DESCRIPTION
        This function will check an entire Sequence Workflow environment given an environment name.
    .PARAMETER Environment <String>
        The environment you are checking, DEV, UAT or PROD
    .INPUTS
        [String]
    .EXAMPLE
        Assert-WorkflowEnvironment -Environment 'DEV'
    .EXAMPLE
        Assert-WorkflowEnvironment -Environment 'UAT'
    .NOTES
        Name Assert-WorkflowEnvironment
        Creator Brian Donnelly
        Date 05/11/2024
        Updated N/A
#>
    #requires -runasadministrator

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An environment name is needed")]
        [ValidateSet("DEV", "UAT", "PROD")]
        [string]$Environment
    )

    #PROD servers:
    [string[]]$ProdAppServers = 'UKAZRSAPPP0019',
                                'UKAZRSAPPP0020',
                                'UKAZRSAPPP0021',
                                'UKAZRSAPPP0022',
                                'UKAZRSAPPP0023'

    [string[]]$ProdWebServers = 'UKAZRSWEBP0003',
                                'UKAZRSWEBP0004',
                                'UKAZRSWEBP0005',
                                'UKAZRSWEBP0006'

    #UAT Servers
    [string[]]$UATAppServers  = 'UKAZRAPP1007',
                                'UKAZRAPP1008',
                                'UKAZRAPP1009'

    [string[]]$UATWebServers  = 'UKAZRWEB1002',
                                'UKAZRWEB1008'

    #DEV Servers
    [string[]]$DevAppServers  = 'UKAZRSAPPD0001',
                                'UKAZRSAPPD0002',
                                'UKAZRSAPPD0003'

    [string[]]$DevWebServers  = 'UKAZRSWEBD0001'

    #Sequence App Service names
    [string[]]$WinServices    = 'Background Runtime Service',
                                'KPMG.TaxConnect.Workflow.Service',
                                'Job Execution Service',
                                'Active Directory Synchronization Service'

    #IIS Service Name
    [string]$WebService       = 'W3SVC'

    switch ($Environment) {
        "DEV" {
            Foreach($AppServer in $DevAppServers) {
                foreach($WinService in $WinServices) {
                    #Check Sequence windows services
                    $SequenceServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                    #Print a message
                    Write-Host $SequenceServiceStatus.MachineName" `nService Name:"$SequenceServiceStatus.Name "`nStatus:"$SequenceServiceStatus.Status "`ntartup Type:"$SequenceServiceStatus.StartType"`n"
                }
            }

            Foreach($WebServer in $DevWebServers) {
                #Check W3SVC service status
                $WebServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                #Print a message
                Write-Host $WebServiceStatus.MachineName" `nService Name:"$WebServiceStatus.Name "`nStatus:"$WebServiceStatus.Status "`nStartup Type:"$WebServiceStatus.StartType"`n"
            }
        }

        "UAT" {
            Foreach($AppServer in $UATAppServers) {
                foreach($WinService in $WinServices) {
                    #Check Sequence windows services
                    $SequenceServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                    #Print a message
                    Write-Host $SequenceServiceStatus.MachineName" `nService Name:"$SequenceServiceStatus.Name "`nStatus:"$SequenceServiceStatus.Status "`ntartup Type:"$SequenceServiceStatus.StartType"`n"
                }
            }

            Foreach($WebServer in $UATWebServers) {
                #Check W3SVC service status
                $WebServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                #Print a message
                Write-Host $WebServiceStatus.MachineName" `nService Name:"$WebServiceStatus.Name "`nStatus:"$WebServiceStatus.Status "`nStartup Type:"$WebServiceStatus.StartType"`n"
            }
        }

        "PROD" {
            Foreach($AppServer in $ProdAppServers) {
                foreach($WinService in $WinServices) {
                    #Check Sequence windows services
                    $SequenceServiceStatus = Get-Service -Name $WinService -ComputerName $AppServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                    #Print a message
                    Write-Host $SequenceServiceStatus.MachineName" `nService Name:"$SequenceServiceStatus.Name "`nStatus:"$SequenceServiceStatus.Status "`ntartup Type:"$SequenceServiceStatus.StartType"`n"
                }
            }

            Foreach($WebServer in $ProdWebServers) {
                #Check W3SVC service status
                $WebServiceStatus = Get-Service -Name $WebService -ComputerName $WebServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                #Print a message
                Write-Host $WebServiceStatus.MachineName" `nService Name:"$WebServiceStatus.Name "`nStatus:"$WebServiceStatus.Status "`nStartup Type:"$WebServiceStatus.StartType"`n"
            }
        }
    }
}

Function Find-WorkflowLogs {
    <#
        .SYNOPSIS
            Queries the event viewer for workflow logs.
        .DESCRIPTION
            This function will query the logs for a workflow environment. 
            The log queried is Panam, which is what Sequence logs to on app and web servers.

        .PARAMETER Environment <String>
            The environment you are checking, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Assert-WorkflowEnvironment -Environment 'DEV'
        .EXAMPLE
            Assert-WorkflowEnvironment -Environment 'UAT'
        .NOTES
            Name Find-WorkflowLogs
            Creator Brian Donnelly
            Date 07/11/2024
            Updated N/A
    #>

    #VARIABLES

    #logname (will be static as panam, only log that workflow uses)
    #source
    #FromTime
    #ToTime
    #newest
    #Message

    #Use switch to determing what kind of search is done

    #Get-EventLog -ComputerName UKAZRAPP1007 -LogName panam -source BRS -After "06/11/2024 08:00:00" -Before "06/11/2024 09:00:00" -EntryType Error

    #requires -runasadministrator
    
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An environment name is needed")]
        [ValidateSet("DEV", "UAT", "PROD")]
        [string]$Environment
    )
}