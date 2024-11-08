Function Stop-DigitaWorkerServices {
    <#
        .SYNOPSIS
            Stops the Digita Worker Services
        .DESCRIPTION
            This function will stop all Digita Worker Services given an environment name.
        .PARAMETER Environment <String>
            The environment you are stopping, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Stop-DigitaWorkerServices -Environment DEV
        .EXAMPLE
            Stop-DigitaWorkerServices -Environment UAT
        .NOTES
            Name Stop-DigitaWorkerServices
            Creator Brian Donnelly
            Date 08/11/2024
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
    [string]$LogName = "Digita Environement Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #PROD servers:
    [string[]]$ProdServers = 'UKAZRSAPPP0083',
                             'UKAZRSAPPP0084',
                             'UKAZRSAPPP0085',
                             'UKAZRSAPPP0086'

    #UAT Servers
    [string[]]$UATServers  = 'UKAZRAPP1022',
                             'UKAZRAPP1023'

    #DEV Servers
    [string]$DevServers    = 'UKAZRSAPPD0004'

    #Digita Service names
    [string[]]$WinServices = 'KPMG Tax Connect Digita Service',
                             'KPMG Tax Connect Digita Polling Service'

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
                #Stop Digita windows services
                foreach($DevServer in $DevServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to manual, stop services
                            Get-Service -Name $WinService -ComputerName $DevServer | Set-Service -StartupType Manual -PassThru
                            Get-Service -Name $WinService -ComputerName $DevServer | Stop-Service -Force -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $DevServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been stopped and print to the terminal.
                $Message = "The Digita services on " + $DevServers + " have now been stopped and set to manual. "`
                + " This means the " + $Environment + " environment is now offline" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Check-Sequence -Environment " + "'" + $Environment + "'"
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
                #Stop Digita windows services
                foreach($UATServer in $UATServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to manual, stop services
                            Get-Service -Name $WinService -ComputerName $UATServer | Set-Service -StartupType Manual -PassThru
                            Get-Service -Name $WinService -ComputerName $UATServer | Stop-Service -Force -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $UATServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been stopped and print to the terminal.
                $Message = "The Digita services on " + $UATServer + " have now been stopped and set to manual. "`
                + " This means the " + $Environment + " environment is now offline" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Check-Sequence -Environment " + "'" + $Environment + "'"
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
                #Stop Digita windows services
                foreach($PRODServer in $PRODServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $PRODServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to manual, stop services
                            Get-Service -Name $WinService -ComputerName $PRODServer | Set-Service -StartupType Manual -PassThru
                            Get-Service -Name $WinService -ComputerName $PRODServer | Stop-Service -Force -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $PRODServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $PRODServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been stopped and print to the terminal.
                $Message = "The Digita services on " + $PRODServer + " have now been stopped and set to manual. "`
                + " This means the " + $Environment + " environment is now offline" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the envuironment is stopped.
                $Message = "To check this, run Check-Sequence -Environment " + "'" + $Environment + "'"
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

Function Start-DigitaWorkerServices {
    <#
        .SYNOPSIS
            Starts the Digita Worker Services
        .DESCRIPTION
            This function will start all Digita Worker Services given an environment name.
        .PARAMETER Environment <String>
            The environment you are starting, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Start-DigitaWorkerServices -Environment DEV
        .EXAMPLE
            Start-DigitaWorkerServices -Environment UAT
        .NOTES
            Name Start-DigitaWorkerServices
            Creator Brian Donnelly
            Date 08/11/2024
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
    [string]$LogName = "Digita Environement Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #PROD servers:
    [string[]]$ProdServers = 'UKAZRSAPPP0083',
                             'UKAZRSAPPP0084',
                             'UKAZRSAPPP0085',
                             'UKAZRSAPPP0086'

    #UAT Servers
    [string[]]$UATServers  = 'UKAZRAPP1022',
                             'UKAZRAPP1023'

    #DEV Servers
    [string]$DevServers    = 'UKAZRSAPPD0004'

    #Digita Service names
    [string[]]$WinServices = 'KPMG Tax Connect Digita Service',
                             'KPMG Tax Connect Digita Polling Service'

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
                #Start Digita windows services
                foreach($DevServer in $DevServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to Automatic, Start services
                            Get-Service -Name $WinService -ComputerName $DevServer | Set-Service -StartupType Automatic -PassThru
                            Get-Service -Name $WinService -ComputerName $DevServer | Start-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $DevServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been started and print to the terminal.
                $Message = "The Digita services on " + $DevServers + " have now been started and set to automatic. "`
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the environment is started.
                $Message = "To check this, run Assert-DigitaWorkerServices -Environment " + "'" + $Environment + "'"
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
                #Start Digita windows services
                foreach($UATServer in $UATServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to automatic, start services
                            Get-Service -Name $WinService -ComputerName $UATServer | Set-Service -StartupType Automatic -PassThru
                            Get-Service -Name $WinService -ComputerName $UATServer | Start-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $UATServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been started and print to the terminal.
                $Message = "The Digita services on " + $UATServer + " have now been started and set to automatic. "`
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the environment is started.
                $Message = "To check this, run Assert-DigitaWindowsServices -Environment " + "'" + $Environment + "'"
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
                #Start Digita windows services
                foreach($PRODServer in $PRODServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $PRODServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #change startup type to automatic, start services
                            Get-Service -Name $WinService -ComputerName $PRODServer | Set-Service -StartupType Automatic -PassThru
                            Get-Service -Name $WinService -ComputerName $PRODServer | Start-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $PRODServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state. The startup type is set to " `
                            + $ServiceStatus.StartType + " on " + $PRODServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been started and print to the terminal.
                $Message = "The Digita services on " + $PRODServer + " have now been started and set to manual. "`
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the environment is started.
                $Message = "To check this, run Assert-DigitaWindowsServices -Environment " + "'" + $Environment + "'"
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

Function Restart-DigitaWorkerServices {
   <#
        .SYNOPSIS
            Restarts the Digita Worker Services
        .DESCRIPTION
            This function will restart all Digita Worker Services given an environment name.
        .PARAMETER Environment <String>
            The environment you are restarting, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Restart-DigitaWorkerServices -Environment DEV
        .EXAMPLE
            Restart-DigitaWorkerServices -Environment UAT
        .NOTES
            Name Restart-DigitaWorkerServices
            Creator Brian Donnelly
            Date 08/11/2024
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
    [string]$LogName = "Digita Environement Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #PROD servers:
    [string[]]$ProdServers = 'UKAZRSAPPP0083',
                             'UKAZRSAPPP0084',
                             'UKAZRSAPPP0085',
                             'UKAZRSAPPP0086'

    #UAT Servers
    [string[]]$UATServers  = 'UKAZRAPP1022',
                             'UKAZRAPP1023'

    #DEV Servers
    [string]$DevServers    = 'UKAZRSAPPD0004'

    #Digita Service names
    [string[]]$WinServices = 'KPMG Tax Connect Digita Service',
                             'KPMG Tax Connect Digita Polling Service'

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
                #Restart Digita windows services
                foreach($DevServer in $DevServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #Restart services
                            Get-Service -Name $WinService -ComputerName $DevServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state on " + $DEVServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been restarted and print to the terminal.
                $Message = "The Digita services on " + $DevServers + " have now been restarted. "`
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the environment is started.
                $Message = "To check this, run Assert-DigitaWorkerServices -Environment " + "'" + $Environment + "'"
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
                #Restart Digita windows services
                foreach($UATServer in $UATServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #Restart services
                            Get-Service -Name $WinService -ComputerName $UATServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state on " + $UATServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been restarted and print to the terminal.
                $Message = "The Digita services on " + $UATServer + " have now been restarted"`
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the environment is started.
                $Message = "To check this, run Assert-DigitaWindowsServices -Environment " + "'" + $Environment + "'"
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
                #Restart Digita windows services
                foreach($PRODServer in $PRODServers) {
                    foreach($WinService in $WinServices) {
                        #Check status of service
                        $ServiceStatus = Get-Service -Name $WinService -ComputerName $PRODServer | Select-Object -Property Status, Name, StartType

                        #Checks if the service is disabled (indicating it is one of the Polling services that do not run). These services will be skipped.
                        if ($ServiceStatus.StartType -eq 'Disabled') {
                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " on " + $ServiceStatus.MachineName + " is in the " + $ServiceStatus.StartType + " state. This service will be ignored."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                        else {
                            #Restart services
                            Get-Service -Name $WinService -ComputerName $PRODServer | Restart-Service -PassThru

                            #Check status of service
                            $ServiceStatus = Get-Service -Name $WinService -ComputerName $PRODServer | Select-Object -Property Status, Name, StartType

                            #Write a message containing the status of the services to the event log and print to the terminal in verbose mode
                            $Message = "The " + $ServiceStatus.Name + " is now in the " + $ServiceStatus.Status + " state on " + $PRODServer
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                            Write-Verbose $Message
                        }
                    }
                }

                #Write a message to the event log stating the environment has been restarted and print to the terminal.
                $Message = "The Digita services on " + $PRODServer + " have now been restarted."`
                + " This means the " + $Environment + " environment is now online" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
                Write-Output $Message
                
                #Prints a message telling the user how to check the environment is started.
                $Message = "To check this, run Assert-DigitaWindowsServices -Environment " + "'" + $Environment + "'"
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

Function Assert-DigitaWorkerServices {
   <#
        .SYNOPSIS
            Checks the Digita Worker Services
        .DESCRIPTION
            This function will check all Digita Worker Services given an environment name.
        .PARAMETER Environment <String>
            The environment you are checking, DEV, UAT or PROD
        .INPUTS
            [String]
        .EXAMPLE
            Assert-DigitaWorkerServices -Environment DEV
        .EXAMPLE
            Assert-DigitaWorkerServices -Environment UAT
        .NOTES
            Name Assert-DigitaWorkerServices
            Creator Brian Donnelly
            Date 08/11/2024
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
    [string[]]$ProdServers = 'UKAZRSAPPP0083',
                             'UKAZRSAPPP0084',
                             'UKAZRSAPPP0085',
                             'UKAZRSAPPP0086'

    #UAT Servers
    [string[]]$UATServers  = 'UKAZRAPP1022',
                             'UKAZRAPP1023'

    #DEV Servers
    [string]$DevServers    = 'UKAZRSAPPD0004'

    #Digita Service names
    [string[]]$WinServices = 'KPMG Tax Connect Digita Service',
                             'KPMG Tax Connect Digita Polling Service'

    switch ($Environment) {
        "DEV" {
            Foreach($DevServer in $DevServers) {
                foreach($WinService in $WinServices) {
                    #Check Digita windows services
                    $DigitaServiceStatus = Get-Service -Name $WinService -ComputerName $DevServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                    #Print a message
                    Write-Host $DigitaServiceStatus.MachineName" `nService Name:"$DigitaServiceStatus.Name "`nStatus:"$DigitaServiceStatus.Status "`ntartup Type:"$DigitaServiceStatus.StartType"`n"
                }
            }
        }

        "UAT" {
            Foreach($UATServer in $UATServers) {
                foreach($WinService in $WinServices) {
                    #Check Digita windows services
                    $DigitaServiceStatus = Get-Service -Name $WinService -ComputerName $UATServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                    #Print a message
                    Write-Host $DigitaServiceStatus.MachineName" `nService Name:"$DigitaServiceStatus.Name "`nStatus:"$DigitaServiceStatus.Status "`ntartup Type:"$DigitaServiceStatus.StartType"`n"
                }
            }
        }

        "PROD" {
            Foreach($ProdServer in $ProdServers) {
                foreach($WinService in $WinServices) {
                    #Check Digita windows services
                    $DigitaServiceStatus = Get-Service -Name $WinService -ComputerName $ProdServer | Select-Object -Property MachineName, Status, Name, DisplayName, StartType

                    #Print a message
                    Write-Host $DigitaServiceStatus.MachineName" `nService Name:"$DigitaServiceStatus.Name "`nStatus:"$DigitaServiceStatus.Status "`ntartup Type:"$DigitaServiceStatus.StartType"`n"
                }
            }
        }
    }
}