<#
    .SYNOPSIS
        Allows a user to request access to to the hosted infrastructure of KPMG tax applications.
    .DESCRIPTION
        Users will be able to request access to servers and databases for applications hosted
        internally at KPMG.  Once approved by the relevant product owner, the user will be able to trigger 
        getting access on their own via this, with the details of their access being logged in the evemt viewer 
        of the server it runs on.  
    .PARAMETER Param1
        
    .PARAMETER Param2
        
    .INPUTS
        
    .OUTPUTS
    .EXAMPLE
        
    .EXAMPLE
        
    .NOTES
        Name UserAccessController.ps1
        Creator Brian Donnelly
        Date 19/08/2020
        Updated N/A
        #requires -Module KPMGUserAccessManagement
#>

    [CmdletBinding()]
    Param()

    # Adds the presentation framework/PresentationCore, allowing us to display the GUI components
    Add-Type -AssemblyName PresentationFramework, PresentationCore

    #Import the KPMGUserAccessManagement module
    Import-Module -Name KPMGUserAccessManagement

    #Sets error prefrence to silently continue
    $ErrorActionPreference = "SilentlyContinue"

    #$VerbosePreference = "Continue"

    #region Variables

    [string]$Username = $env:UserName #grabs the username from the PS environment variables
    [string]$Env #This stores the environment the user wants access to
    [string]$Infra #This stores the infrastructure the user wants access to
    [string]$App #This stores the infrastructure the user wants access to
    [string]$BusJust #This stores the business justification the user puts in
    [string[]]$UserMessage = @() #Store messages to be displayed to the user for error handling
    [String]$Message #To store messages that are written to the event logs
    [string]$LogName = "User Access Management" #Name of the Event log we are writing to
    [string]$LogSource = $MyInvocation.MyCommand #This is the log source and is simply the name of the calling script of method
    [string]$XAMLFile = $PSScriptRoot + "\MainWindow.xaml" #Path to XAML file for production
    #[string]$XAMLFile = "C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\ps-kpmg\UserAccessControl\MainWindow.xaml" #Path to XAML file for testing
    [string]$ApprovalHistoryFilePath = (Split-Path $script:MyInvocation.MyCommand.Path) + "\Config\ApprovalHistory.csv"
    [string]$SecurityGroupFilePath = (Split-Path $script:MyInvocation.MyCommand.Path) + "\Config\SecurityGroups.psd1"
    [string]$AppSupportRequestURL = "https://kpmgtechsolutions.service-now.com/tsportal?id=ts_sc_item&sys_id=b4290827db989b8038269a24db961945"

    #endregion Variables

    #Write an entry into the event logs stating who is running the script
    $Message = "This script was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + " at " + (Get-Date -Format HH-mm-ss)
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message
    
    #region Create GUI

    #creates the window 
    $inputXML = Get-Content $xamlFile -Raw
    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    [XML]$XAML = $inputXML

    #Reads the XAML
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        $window = [Windows.Markup.XamlReader]::Load( $reader )
    } 
    catch {
        Write-Warning $_.Exception
        throw
    }

    #Create variables dynamically based on form control names.
    #Variables will be named as 'var_<control name>'
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        #"trying item $($_.Name)"
        try {
            Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
        } catch {
            throw
        }
    }

    #endregion Create GUI

    #region submit button

    $var_btnSubmit.Add_Click( {
        #Grabs whatever is the selected item in the drop down and sets the app name from the content value 
        $SelectedApp = $var_cbAppPicker.SelectedItem
        $App = $SelectedApp.Content
        $Message = ("Selected application is: " + $App)
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 1 -Message $Message
        Write-Verbose $Message

        #Gets the content value of the checked radio button using the group box for selecting the environemnt
        $Env = $var_gbEnvPicker.Content.Children | Where-Object -Property IsChecked -eq $true | Select-Object -ExpandProperty Content
        $Message = "Selected environment is: " + $Env
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 2 -Message $Message
        Write-Verbose $Message
    
        #Gets the content value of the checked radio button using the group box for selecting the infrastructure
        $infra = $var_gbinfraPicker.Content.Children | Where-Object -Property IsChecked -eq $true | Select-Object -ExpandProperty Content
        $Message = "Selected infrastructure is: " + $Infra
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 3 -Message $Message
        Write-Verbose $Message

        #Gets whatever was entered as a bsuiness justification for the access
        $BusJust = $var_tbBusJust.text
        $Message = "The business justification was as follows: " + $BusJust
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 4 -Message $Message
        Write-Verbose $Message

        $UserMessage.Clear()

        switch ($true) {
            ("Select Application..." -eq $App) {
                $UserMessage += "You have not selected an application from the dropdown`r"
            }
            ($null -eq $Env) {
                $UserMessage += "You have not selected an environment option`r"
            }
            ($null -eq $Infra) {
                $UserMessage += "You have not selected an infrastructure option`r"
            }
            (("" -eq $BusJust) -or ("Please enter a business justification for the access you are requesting..." -eq $BusJust)){
                $UserMessage += "You have not entered a business justification`r"
            }
            (!("" -eq $UserMessage)) {
                [System.Windows.MessageBox]::Show($UserMessage)
                break
            }
            (("" -eq $UserMessage)) {
                $UserMessage = @()
                $UserMessage += "The following options have been selected:`r`r"
                $UserMessage += "User to be added is: " + $Username + "`r"
                $UserMessage += "Selected application is: " + $App + "`r"
                $UserMessage += "Selected environment is: " + $Env + "`r"
                $UserMessage += "Selected infrastructure is: " + $Infra + "`r"
                $UserMessage += "Please review and confirm by clicking OK to`r"
                $UserMessage += "proceed, or Cancel to go back `r"

                $UserResult = [System.Windows.MessageBox]::Show($UserMessage, 'Please Confirm', 'OKCancel', 'Warning')

                #Hide the submit buttons...
                $var_btnSubmit.Visibility = "Hidden"

                #Get the result from the message box by using submit/cancel buttons
                If('Cancel' -eq $UserResult) {
                    #Hide the cancel/submit buttons...
                    $var_btnSubmit.Visibility = "Visible"
                    $var_btnCancel.Visibility = "Visible"
                    break
                }
                ElseIf('OK' -eq $UserResult) {
                    #this is where I will start calling other methods etc to actually carry out any work

                    #Write a message to the event logs indicating what the user chose
                    $Message = $Username + " has requested access to the " + $App + " application " + $Infra + " in the " + $Env + " environment"
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 1 -Message $Message
                    Write-Verbose $Message

                    #Write a message to the event logs recording what the business justification was
                    $Message = "The business justification" + $Username + " provided was as follows: `r`r" + $BusJust
                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 2 -Message $Message
                    Write-Verbose $Message

                    #Check if the user is pre-approved
                    $IsApproved = Get-KPMGPriorApproval -Username $Username -App $App -Env $Env -Infra $Infra -FilePath $ApprovalHistoryFilePath
                    Write-Verbose "This is where the tool will check if the user has prior approval"
                    Write-Verbose $IsApproved

                    If(1 -eq $IsApproved) {
                        #Display a message to the user informing them they have no prior approval for this access
                        #They will need to raise a case with App support for product owner approval.
                        $UserMessage = @()
                        $UserMessage += "You do not have prior approval for this`r"
                        $UserMessage += "access and will need to raise a case with`r"
                        $UserMessage += "app support. Please standby while we open`r"
                        $UserMessage += "a browser up at the correct service now form.`r"
                        $UserMessage += "Once you have dismissed this message, press`r"
                        $UserMessage += "Cancel to exit."
            
                        [System.Windows.MessageBox]::Show($UserMessage)
            
                        $Message = "The user: "+ $Username + "did not have an prior approval for access to the " + $App + " appplication " + $Infra + " in the " + $Env + " environment."
                        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 3 -Message $Message
                        Write-Verbose $Message
            
                        #Use code to open a web browser and navigate to an application support request for the user
                        $Browser=new-object -com internetexplorer.application
                        $Browser.navigate2($AppSupportRequestURL)
                        $Browser.visible=$true
            
                        #Display only the cancel button that will allow the user to exit the tool completely
                        $var_btnSubmit.Visibility = "Hidden"
                        $var_btnCancel.Visibility = "Visible"
                    }
                    Else {
                        #execute code that will display a message to the user informing them they have prior approval for this access
                        $UserMessage = @()
                        $UserMessage += "You have prior approval for this access and`r"
                        $UserMessage += "will now be added to the relevant security`r"
                        $UserMessage += "group.  Please standby.`r"
            
                        [System.Windows.MessageBox]::Show($UserMessage)
                        
                        #Call a method that will return the name of the security group we need to add the user to
                        $SecGroup = Get-KPMGSecurityGroupName -Username $Username -App $App -Env $Env -Infra $Infra -FilePath $SecurityGroupFilePath 
                        Write-Verbose "This is where the tool will attempt to find out what security group the user needs access to"
                        Write-verbose $SecGroup
            
                        #Check that a security group was returned
                        If(1 -eq $SecGroup) {
                            #Display a message to the user informing them a security group does not exist based on what has been supplied
                            #This is a highly unlikely scenario and would likely be as the result of some other issue.
                            #They will need to raise a case with App support to assist.
                            $UserMessage = @()
                            $UserMessage += "The security group required to grant you`r"
                            $UserMessage += "access does not exist, or something `r"
                            $UserMessage += "else has went wrong.  A browser window`r"
                            $UserMessage += "will now open to a support form. Please`r"
                            $UserMessage += "fill this out and someone from the app support`r"
                            $UserMessage += "team will be in touch to assist`r"
                            $UserMessage += "You can press the cancel button to finish`r"
            
                            [System.Windows.MessageBox]::Show($UserMessage)
            
                            $Message = "Something has went wrong when trying to add " + $Username + "to the " + $SecGroup + " security group. This will need to be investigated."
                            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 4 -Message $Message
                            Write-Verbose $Message
            
                            #Opens a web browser and navigate to an application support request for the user
                            $Browser=new-object -com internetexplorer.application
                            $Browser.navigate2($AppSupportRequestURL)
                            $Browser.visible=$true
            
                            $var_btnSubmit.Visibility = "Hidden"
                            $var_btnCancel.Visibility = "Visible"
                        }
                        Else {
                            #We need to call the AD cmdlets I built, but these require runasadmin to work
                            #I need to figure out a way of ensuring that a service account, and not the user
                            #calls these so they work....
                            $AddUserResult = Add-KPMGGroupMember -Username $Username -GroupName $SecGroup
                            Write-Verbose "This is where the tool will attempt to add the user to the required security group"
                            Write-Verbose $AddUserResult
            
                            switch ($true) {
                                (0 -eq $AddUserResult) { 
                                    $Message = "An unknown error has occured, please contact app support using the SNow form and press cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 5 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)

                                    #Opens a web browser and navigate to an application support request for the user
                                    $Browser=new-object -com internetexplorer.application
                                    $Browser.navigate2($AppSupportRequestURL)
                                    $Browser.visible=$true
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                (1 -eq $AddUserResult) { 
                                    $Message = "The username and group name supplied do not exist in Active Directory, please contact app support using the SNow form and press Cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 6 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)

                                    #Opens a web browser and navigate to an application support request for the user
                                    $Browser=new-object -com internetexplorer.application
                                    $Browser.navigate2($AppSupportRequestURL)
                                    $Browser.visible=$true
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                (2 -eq $AddUserResult) { 
                                    $Message = "The username supplied does not exist in Active Directory, please contact app support using the SNow form and press Cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 7 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)

                                    #Opens a web browser and navigate to an application support request for the user
                                    $Browser=new-object -com internetexplorer.application
                                    $Browser.navigate2($AppSupportRequestURL)
                                    $Browser.visible=$true
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                (3 -eq $AddUserResult) { 
                                    $Message = "The group name supplied does not exist in Active Directory, please contact app support using the SNow form and press Cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 8 -Message $Message
                                    Write-Verbose $Message 

                                    [System.Windows.MessageBox]::Show($Message)

                                    #Opens a web browser and navigate to an application support request for the user
                                    $Browser=new-object -com internetexplorer.application
                                    $Browser.navigate2($AppSupportRequestURL)
                                    $Browser.visible=$true
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                (4 -eq $AddUserResult) { 
                                    $Message = "The user is already a member of this security group, Press Cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 9 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                (5 -eq $AddUserResult) { 
                                    $Message = "Adding the user to the group has failed, please contact app support using the SNow form and press Cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 10 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)

                                    #Opens a web browser and navigate to an application support request for the user
                                    $Browser=new-object -com internetexplorer.application
                                    $Browser.navigate2($AppSupportRequestURL)
                                    $Browser.visible=$true
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                (6 -eq $AddUserResult) { 
                                    $Message = "User was added successfully. Press Cancel on the main form to exit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 11 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                                Default {
                                    $Message = "An unhandled error has occured, please contact app support using the SNow form and press Cancel on the main form to quit"
                                    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 12 -Message $Message
                                    Write-Verbose $Message

                                    [System.Windows.MessageBox]::Show($Message)

                                    #Opens a web browser and navigate to an application support request for the user
                                    $Browser=new-object -com internetexplorer.application
                                    $Browser.navigate2($AppSupportRequestURL)
                                    $Browser.visible=$true
                    
                                    $var_btnSubmit.Visibility = "Hidden"
                                    $var_btnCancel.Visibility = "Visible"
                                }
                            }
                        }
                    }
                }
            }
            Default {

            }
        }
    } )

    #endregion submit button

    #region cancel button

    $var_btnCancel.Add_Click( {
        #have a final piece of code to dispose of the variables once I am complete and close the window as well as the PS console
        Get-Variable var_* | Remove-Variable
        $Window.Close()
        Exit
    } )

    #endregion cancel button

    #Show form - no code can appear after this.
    $Null = $window.ShowDialog()