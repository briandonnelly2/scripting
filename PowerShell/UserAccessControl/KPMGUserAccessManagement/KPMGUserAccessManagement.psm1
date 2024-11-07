Function Add-KPMGGroupMember {
<#
    .SYNOPSIS
        Adds a user to an Active Directory security group.
    .DESCRIPTION
        This script will add a user to an Active Directory security group.
    .PARAMETER Username <String>
        The username of the user to be added
    .PARAMETER GroupName <String>
        The group name we are adding the user to.
    .INPUTS
        [String]
    .OUTPUTS
    .EXAMPLE
        Add-KPMGGroupMember -Username 'testuser4' -GroupName 'testgroup4'
    .EXAMPLE
        Add-KPMGGroupMember -Username 'testuser1' -GroupName 'testgroup2'
    .NOTES
        Name Add-KPMGGroupMember
        Creator Brian Donnelly
        Date 18/08/2020
        Updated N/A
#>
    #requires -modules ActiveDirectory
    #requires -runasadministrator

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An AD username is needed")]
        [String]$Username,

        [Parameter(Mandatory, HelpMessage="An AD group name is needed")]
        [String]$GroupName
    )

    #Sets error prefrence to silently continue
    $ErrorActionPreference = "SilentlyContinue"

    #Imports the ActiveDirectory PowerShell module
    Import-Module -Name ActiveDirectory

    #Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "User Access Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + " at " + (Get-Date -Format HH-mm-ss)
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Get the AD user account and store in a variable
    $ADUser = Get-ADUser -Identity $Username

    #Get the AD security group and store in a variable
    $ADgroup = Get-ADGroup -Identity $GroupName

    #Checks to see whether our user is already a member of the group we are trying to add them to and stores in a variable
    $ADGroupMember = Get-ADGroupMember -Identity $GroupName | Where-Object -Property SamAccountName -eq $Username

    #Condition where both the supplied user AND the supplied group are not returned
    If(($null -eq $ADUser) -AND ($null -eq $ADgroup)) {
        $Message = "The username, " + $Username + " and group name, " + $GroupName + " cannot be found."
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 1 -Message $Message
        Write-Verbose $Message
        return 1
    }
    #Condition where the supplied user is not returned
    ElseIf($null -eq $ADUser) {
        $Message = "The username, " + $Username + " cannot be found."
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 2 -Message $Message
        Write-Verbose $Message
        return 2
    }
    #Condition where the supplied group is not returned
    ElseIf($null -eq $ADgroup) {
        $Message = "The group name, " + $GroupName + " cannot be found."
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 3 -Message $Message
        Write-Verbose $Message
        return 3
    }
    #Condition where the user is already in the security group
    ElseIf(!($null -eq $ADGroupMember)) {
        $Message = "The user, " + $ADUser.Name + " is already a member of " + $ADGroup.Name + " so no further action is required"
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 4 -Message $Message
        Write-Verbose $Message
        return 4
    }
    #If execution gets this far, the supplied user and group was returned, so we can attempt to add the user to the group.
    Else {
        Try {
            #Add the supplied user to the AD group
            Add-ADGroupMember -Identity $ADgroup -Members $ADUser
            
            #Checks to see whether our user is in the group we tried to add them to above and stores in a variable
            $ADGroupMember = Get-ADGroupMember -Identity $ADgroup | Where-Object -Property SamAccountName -eq $Username

            #Condition where the result of the above is null and therefore, our user has not been added for some reason
            If($null -eq $ADGroupMember) {
                $Message = "Adding the user " + $ADUser.Name + " to the security group " + $ADGroup.Name + " has failed."
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 5 -Message $Message
                Write-Verbose $Message
                return 5
            }
            #This means our user was added and we can notify the calling script this is the case
            Else {
                $Message = "The user " + $ADUser.Name + " was added to the security group " + $ADGroup.Name + " successfully"
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 6 -Message $Message
                Write-Verbose $Message
                return 6
            }
        }
        Catch {
            $Message = "An unhandled error has occured"
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 7 -Message $Message
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 8 -Message $_.exception.message
            Write-Verbose $Message + $_.exception.message
            return 0
        }
    }
}

Function Remove-KPMGGroupMember {
<#
    .SYNOPSIS
        Removes a single user from an Active Directory security group or empties the group of all users.
    .DESCRIPTION
        This script will remove a given user from a given Active Directory security group or will empty all users
        from the group if the EmptyGroup porameter is set to $true.  Nested groups remain in place to maintain app
        support access.
    .PARAMETER Username <String>
        The username of the user to be removed
    .PARAMETER GroupName <String>
        The group name we are removing the user from.
    .PARAMETER EmptyGroup <switch>
        Set to $false by default, but if set to $true, will remove all user accounts from the supplied group.
    .INPUTS
        [String], [Switch]
    .OUTPUTS
        [string]
    .EXAMPLE
        Example of how to use this cmdlet
    .EXAMPLE
        Another example of how to use this cmdlet
    .NOTES
        Name Remove-KPMGGroupMember
        Creator Brian Donnelly
        Date 19/08/2020
        Updated N/A
#>
    #requires -modules ActiveDirectory
    #requires -runasadministrator

    [CmdletBinding()]
    Param (
        [Parameter(HelpMessage="An AD username is needed")]
        [String]$Username,

        [Parameter(Mandatory, HelpMessage="An AD group name is needed")]
        [String]$GroupName,

        [Parameter(HelpMessage="If set to true, this will empty the whole group of users")]
        [switch]$EmptyGroup = $false
    )
    
    #Sets error prefrence to silently continue
    $ErrorActionPreference = "SilentlyContinue"

    #Imports the ActiveDirectory PowerShell module
    Import-Module -Name ActiveDirectory

    #Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "User Access Management"
    [string]$LogSource = $MyInvocation.MyCommand

    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + " at " + (Get-Date -Format HH-mm-ss)
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Condition where the EmptyGroup parameter is $true
    If($true -eq $EmptyGroup) {
        $ADGroupMemberPre = Get-ADGroupMember -Identity $GroupName -Recursive
        Get-ADGroupMember -Identity $GroupName -Recursive | ForEach-Object -Process {Remove-ADPrincipalGroupMembership -MemberOf $GroupName -Identity $($_.SamAccountName) -Confirm:$false }
        $ADGroupMember = Get-ADGroupMember -Identity $GroupName -Recursive

        #Condition where the value of $ADGroupMember is null and the value of $ADGroupMemberPre is not null (meaning users were in the group before)
        If(($null -eq $ADGroupMember) -and !($null -eq $ADGroupMemberPre)) {
            $Message = "The following " + $ADGroupMemberPre.Count + " users were removed from the security group " + $GroupName + " : " + $ADGroupMemberPre.Name
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 1 -Message $Message
            Write-Verbose $Message
            return 1
        }
        #Condition where the value of $ADGroupMember is null and the value of $ADGroupMemberPre is null (meaning the group was empty of users before)
        ElseIf(($null -eq $ADGroupMember) -and ($null -eq $ADGroupMemberPre)) {
            $Message = "The security group " + $GroupName + " did not contain any users at this time.  Nothing has been modified."
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 2 -Message $Message
            Write-Verbose $Message
            return 2
        }
        #This means our group still contains users so emptying the group has failed
        Else {
            $Message = "The security group " + $GroupName + " still contains users, so the command has failed."
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 3 -Message $Message
            Write-Verbose $Message
            return 3
        }
    }
    #Condition where EmptyGroup is $false, but no username has been supplied
    ElseIf(($false -eq $EmptyGroup) -and ("" -eq $Username)) {
        $Message = "A username was not supplied and the EmptyGroup parameter was false, therefore the command cannot continue"
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 4 -Message $Message
        Write-Verbose $Message
        return 4
    }
    #EmptyGroup is false, so we are removing a single user.
    Else {
        #Get the AD user account and store in a variable
        $ADUser = Get-ADUser -Identity $Username

        #Get the AD security group and store in a variable
        $ADgroup = Get-ADGroup -Identity $GroupName

        #Checks to see whether our user is actually a member of the group we are trying to remove them from and stores in a variable
        $ADGroupMember = Get-ADGroupMember -Identity $ADgroup | Where-Object -Property SamAccountName -eq $Username

        #Condition where both the supplied user AND the supplied group are not returned
        If(($null -eq $ADUser) -AND ($null -eq $ADgroup)) {
            $Message = "The username, " + $Username + " and group name, " + $GroupName + " cannot be found."
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 5 -Message $Message
            Write-Verbose $Message
            return 5
        }
        #Condition where the supplied user is not returned
        ElseIf($null -eq $ADUser) {
            $Message = "The username, " + $Username + " cannot be found."
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 6 -Message $Message
            Write-Verbose $Message
            return 6
        }
        #Condition where the supplied group is not returned
        ElseIf($null -eq $ADgroup) {
            $Message = "The group name, " + $GroupName + " cannot be found."
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 7 -Message $Message
            Write-Verbose $Message
            return 7
        }
        #Condition where the user is not actually in the security group
        ElseIf($null -eq $ADGroupMember) {
            $Message = "The username, " + $Username + " is not currently a member of " + $GroupName + " so no further action is required"
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning -EventId 8 -Message $Message
            Write-Verbose $Message
            return 8
        }
        #If execution gets this far, the supplied user and group were returned and they are a member of this group, so we can attempt to remove the user from the group.
        Else {
            Try {
            #Remove the supplied user to the AD group
            Remove-ADGroupMember -Identity $ADgroup -Members $ADUser -Confirm:$false
            
            #Checks to see whether our user is in the group we tried to remove them from above and stores in a variable
            $ADGroupMember = $null
            $ADGroupMember = Get-ADGroupMember -Identity $ADgroup | Where-Object -Property SamAccountName -eq $Username

            #Condition where the result of the above is null and therefore, our user is no longer in the security group
            If($null -eq $ADGroupMember) {
                $Message = "The user " + $ADUser.Name + " was removed from the security group " + $ADGroup.Name + " successfully"
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 9 -Message $Message
                Write-Verbose $Message
                return 9
            }
            #This means our user was not removed from the security group because they are still a member
            Else {
                $Message = "Removing the user " + $ADUser.Name + " from the security group " + $ADGroup.Name + " has failed."
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 10 -Message $Message
                Write-Verbose $Message
                return 10
            }
            }
            Catch {
                $Message = "An unhandled error has occured"
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 7 -Message $Message
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 8 -Message $_.exception.message
                Write-Verbose $Message + $_.exception.message
                return 0
            }
        }
    }
}

Function Get-KPMGPriorApproval {
<#
    .SYNOPSIS
        A brief description of the function or script. This keyword can be used
        only once in each topic.
    .DESCRIPTION
        A detailed description of the function or script. This keyword can be
        used only once in each topic.
    .PARAMETER Name
        The description of a parameter. Add a .PARAMETER keyword for
        each parameter in the function or script syntax.
        
        Type the parameter name on the same line as the .PARAMETER keyword.
        Type the parameter description on the lines following the .PARAMETER
        keyword. Windows PowerShell interprets all text between the .PARAMETER
        line and the next keyword or the end of the comment block as part of
        the parameter description. The description can include paragraph breaks.
        
        The Parameter keywords can appear in any order in the comment block, but
        the function or script syntax determines the order in which the parameters
        (and their descriptions) appear in help topic. To change the order,
                                        change the syntax.
        
        You can also specify a parameter description by placing a comment in the
        function or script syntax immediately before the parameter variable name.
        If you use both a syntax comment and a Parameter keyword, the description
        associated with the Parameter keyword is used, and the syntax comment is
        ignored.
    .EXAMPLE
        PS> Get-VirtualMachine -Name 'MYVM'
        
        This example retrieves the virtual machine with the name of MYVM from whatever virtualization system
        it's supposed to work with.
    .INPUTS
        None.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Requirements: This requires
    .LINK
        http://www.google.com
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$App,
        [Parameter(Mandatory)]
        [ValidateSet('Dev', 'UAT', 'Prod')]
        [string]$Env,
        [Parameter(Mandatory)]
        [ValidateSet('Databases', 'Servers')]
        [string]$Infra,
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    #Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "User Access Management"
    [string]$LogSource = $MyInvocation.MyCommand
    $MatchingValues

    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + " at " + (Get-Date -Format HH-mm-ss)
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Imports the approvals csv file and stores in a variable
    $PriorAppCSV = Import-Csv -Path $FilePath

    #Take the csv and pipe it to where-object to find any matches for the user on 4 conditions.  
    #We store this in a variable as it will be used to determine whether the user needs approval or not.
    $MatchingValues = $PriorAppCSV | Where-Object {
        ($_.Username -eq $Username) -and ` #first conditon matches the username
        ($_.Application -eq $App) -and ` #Second conditon matches the app name
        ($_.Environment -eq $Env) -and ` #Third conditon matches the environment
        ($_.Infrastructure -eq $Infra) #Fourth condition matches the infrastructure
    }
    
    #if no matching values are found, this means there is no in-place approval for what the user has requested
    If($null -eq $MatchingValues) {
        #Writes a message to the event logs stating the user was not found to have approval for what they asked for
        $Message = "No prior approval was found for the user " + $Username + " for the " + $App + " application in the " + $Env + " environment."
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 1 -Message $Message
        Write-Verbose $Message
        return 1
    }
    Else {
        #Writes a message to the event logs stating the user was found to have approval and what for
        $Message = "Prior approval was found for " + $Username + " to get access to the " + $App + " " + $Infra + " in " + $Env
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 2 -Message $Message
        Write-Verbose $Message
<# 
        $MatchNo = 1
        [string[]]$MatchMsg = @()
        #For each matching value, a event log entry is contructed to show what the prior approval was
        foreach($Value in $MatchingValues) {
            $MatchMsg += ("Match number: " + $MatchNo)
            $MatchMsg += ("Username: " + $Value.Username)
            $MatchMsg += ("Application: " + $Value.Application)
            $MatchMsg += ("Environment: " + $Value.Environment)
            $MatchMsg += ("Infrastructure: " + $Value.Infrastructure)
            $MatchMsg += ("Product Owner: " + $Value.ProductOwner)
            $MatchMsg += ("SNow Ticket No: " + $Value.SNowNumber)
            $MatchMsg += ("Date of Approval: " + $Value.Date)

            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 3 -Message $MatchMsg
            #Write-Verbose $MatchMsg

            #Increment the MatchNo value by 1
            $MatchNo ++
            #Clear the message so the next match can be built
            $MatchMsg.Clear() 
        }#>
        return 2
    }
}

Function Get-KPMGSecurityGroupName {
<#
    .SYNOPSIS
        A brief description of the function or script. This keyword can be used
        only once in each topic.
    .DESCRIPTION
        A detailed description of the function or script. This keyword can be
        used only once in each topic.
    .PARAMETER Name
        The description of a parameter. Add a .PARAMETER keyword for
        each parameter in the function or script syntax.
        
        Type the parameter name on the same line as the .PARAMETER keyword.
        Type the parameter description on the lines following the .PARAMETER
        keyword. Windows PowerShell interprets all text between the .PARAMETER
        line and the next keyword or the end of the comment block as part of
        the parameter description. The description can include paragraph breaks.
        
        The Parameter keywords can appear in any order in the comment block, but
        the function or script syntax determines the order in which the parameters
        (and their descriptions) appear in help topic. To change the order,
                                        change the syntax.
        
        You can also specify a parameter description by placing a comment in the
        function or script syntax immediately before the parameter variable name.
        If you use both a syntax comment and a Parameter keyword, the description
        associated with the Parameter keyword is used, and the syntax comment is
        ignored.
    .EXAMPLE
        PS> Get-VirtualMachine -Name 'MYVM'
        
        This example retrieves the virtual machine with the name of MYVM from whatever virtualization system
        it's supposed to work with.
    .INPUTS
        None.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Requirements: This requires
    .LINK
        http://www.google.com
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$App,
        [Parameter(Mandatory)]
        [ValidateSet('Dev','UAT', 'Prod')]
        [string]$Env,
        [Parameter(Mandatory)]
        [ValidateSet('Databases', 'Servers')]
        [string]$Infra,
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    #Variables
    [String]$Message = "" #To store messages to be written to the event logs
    [string]$LogName = "User Access Management"
    [string]$LogSource = $MyInvocation.MyCommand
    [string]$SecurityGroup

    #Write an entry into the event logs stating who is running the script
    $Message = "This function was executed by " + $Username + " on " + (Get-Date -Format dd-MM-yyyy) + " at " + (Get-Date -Format HH-mm-ss)
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 0 -Message $Message
    Write-Verbose $Message

    #Imports a PowerShell data file (.psd1) containing the names of the security groups
    #that give access to the various applications and their assocated infrastructure.
    #The supplied parameters will be used to determine what group is required.
    $SecGroupsFile = Import-PowerShellDataFile -Path $FilePath

    #We will use a try block in case anything goes wrong as this method will be dependent on the supplied variables being 
    #exactly correct (which they should be :-) )
    Try {
        If('Prod' -eq $Env) {
            #Uses the variables suppied and dot sourcing to locate the correct security group
            $SecurityGroup = $SecGroupsFile.$Env.$Infra.$App.readonly

            If(($null -eq $SecurityGroup) -or ("" -eq $SecurityGroup) -or ($SecurityGroup.Count -gt 1)) {
                #Writes a message to the event logs to indicate that no group was found, prehaps indicating it has not been created 
                $Message = "The following security group was obtained using the supplied variables, '" + $SecurityGroup + "'" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 1 -Message $Message
                Write-Verbose $Message
                return '1'
            }
            Else {
                #Writes a message to the event logs to say what group was retrieved
                $Message = "The following security group was obtained using the supplied variables, '" + $SecurityGroup + "'" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 3 -Message $Message
                Write-Verbose $Message
                return $SecurityGroup
            }
        }
        ElseIf('UAT' -eq $Env) {
            $SecurityGroup = $SecGroupsFile.$Env.$Infra.$App.privileged

            If($null -eq $SecurityGroup) {
                #Writes a message to the event logs to indicate that no group was found, prehaps indicating it has not been created 
                $Message = "The following security group was obtained using the supplied variables, '" + $SecurityGroup + "'" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 4 -Message $Message
                Write-Verbose $Message
                return '1'
            }
<#             ElseIf($SecurityGroup.Count -gt 1) {
                #Writes a message to the event logs to say more than one group was found
                $Message = "The following security group was obtained using the supplied variables, '" + $SecurityGroup + "'" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 5 -Message $Message
                Write-Verbose $Message
                return 2
            } #>
            Else {
                #Writes a message to the event logs to say what group was retrieved
                $Message = "The following security group was obtained using the supplied variables, '" + $SecurityGroup + "'" 
                Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 6 -Message $Message
                Write-Verbose $Message
                return $($SecurityGroup)
            }
        }
        Else {
            #if we get this far, either the 'Dev' environment was passed through (which cannot have its Active Directory updated from the UK domain)
            #Or some sort of rubbish was somehow passed so we print a message and return to the calling script1 with a 0 
            $Message = "The wrong ennvironment name seems to have been passed through, or something else has went wrong. Stopping execution"
            Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 7 -Message $Message
            Write-Verbose $Message
            return 0
        }
    }
    Catch {
        $Message = "An unhandled error has occured"
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 7 -Message $Message
        Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 8 -Message $_.exception.message
        Write-Verbose $Message + $_.exception.message
        return 0
    }
}

Function Add-KPMGEventLogAndOrSource { #Not finished yet
<#
    .SYNOPSIS
        This script will create a new event log and register a source
    .DESCRIPTION
        This method is needed for when non privileged users trigger the controller script
        as they will be unable to creat an event log or source without running as admin.
    .PARAMETER LogName <String>
        
    .PARAMETER LogSource <String>
        
    .PARAMETER ComputerName <String>
        
    .INPUTS
        [String]
    .OUTPUTS
        [string]
    .EXAMPLE
        Example of how to use this cmdlet
    .EXAMPLE
        Another example of how to use this cmdlet
    .NOTES
        Name Add-NewEventLogAndOrSource
        Creator Brian Donnelly
        Date 20/08/2020
        Updated N/A
#>
    #requires -runasadministrator

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, HelpMessage="An Logname is needed")]
        [string]$LogName,

        [Parameter(Mandatory, HelpMessage="An event source should also be specified")]
        [string]$LogSource,

        [Parameter(MHelpMessage="Localhost will be used if no name is supplied")]
        [string]$ComputerName
    )

    If($null -eq $ComputerName) {
        $ComputerName = "Localhost"
    }

    Try {
        #Create an event log and register this script as a source
        New-EventLog -LogName $LogName -Source $LogSource -ComputerName $ComputerName -ErrorAction SilentlyContinue
    }
    Catch {
        Throw $($_.exception.message)
    }
}

Function Add-KPMGADGroupToLocalGroup { #Not started yet
<#
    .SYNOPSIS
        A brief description of the function or script. This keyword can be used
        only once in each topic.
    .DESCRIPTION
        A detailed description of the function or script. This keyword can be
        used only once in each topic.
    .PARAMETER Name
        The description of a parameter. Add a .PARAMETER keyword for
        each parameter in the function or script syntax.
        
        Type the parameter name on the same line as the .PARAMETER keyword.
        Type the parameter description on the lines following the .PARAMETER
        keyword. Windows PowerShell interprets all text between the .PARAMETER
        line and the next keyword or the end of the comment block as part of
        the parameter description. The description can include paragraph breaks.
        
        The Parameter keywords can appear in any order in the comment block, but
        the function or script syntax determines the order in which the parameters
        (and their descriptions) appear in help topic. To change the order,
                                        change the syntax.
        
        You can also specify a parameter description by placing a comment in the
        function or script syntax immediately before the parameter variable name.
        If you use both a syntax comment and a Parameter keyword, the description
        associated with the Parameter keyword is used, and the syntax comment is
        ignored.
    .EXAMPLE
        PS> Get-VirtualMachine -Name 'MYVM'
        
        This example retrieves the virtual machine with the name of MYVM from whatever virtualization system
        it's supposed to work with.
    .INPUTS
        None.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Requirements: This requires
    .LINK
        http://www.google.com
#>

}

Function Remove-KPMGADGroupFromLocalGroup { #Not started yet
<#
    .SYNOPSIS
        A brief description of the function or script. This keyword can be used
        only once in each topic.
    .DESCRIPTION
        A detailed description of the function or script. This keyword can be
        used only once in each topic.
    .PARAMETER Name
        The description of a parameter. Add a .PARAMETER keyword for
        each parameter in the function or script syntax.
        
        Type the parameter name on the same line as the .PARAMETER keyword.
        Type the parameter description on the lines following the .PARAMETER
        keyword. Windows PowerShell interprets all text between the .PARAMETER
        line and the next keyword or the end of the comment block as part of
        the parameter description. The description can include paragraph breaks.
        
        The Parameter keywords can appear in any order in the comment block, but
        the function or script syntax determines the order in which the parameters
        (and their descriptions) appear in help topic. To change the order,
                                        change the syntax.
        
        You can also specify a parameter description by placing a comment in the
        function or script syntax immediately before the parameter variable name.
        If you use both a syntax comment and a Parameter keyword, the description
        associated with the Parameter keyword is used, and the syntax comment is
        ignored.
    .EXAMPLE
        PS> Get-VirtualMachine -Name 'MYVM'
        
        This example retrieves the virtual machine with the name of MYVM from whatever virtualization system
        it's supposed to work with.
    .INPUTS
        None.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Requirements: This requires
    .LINK
        http://www.google.com
#>
}

Function Get-KPMGPrivilegedSGReview { #Not started yet
<#
    .SYNOPSIS
        A brief description of the function or script. This keyword can be used
        only once in each topic.
    .DESCRIPTION
        A detailed description of the function or script. This keyword can be
        used only once in each topic.
    .PARAMETER Name
        The description of a parameter. Add a .PARAMETER keyword for
        each parameter in the function or script syntax.
        
        Type the parameter name on the same line as the .PARAMETER keyword.
        Type the parameter description on the lines following the .PARAMETER
        keyword. Windows PowerShell interprets all text between the .PARAMETER
        line and the next keyword or the end of the comment block as part of
        the parameter description. The description can include paragraph breaks.
        
        The Parameter keywords can appear in any order in the comment block, but
        the function or script syntax determines the order in which the parameters
        (and their descriptions) appear in help topic. To change the order,
                                        change the syntax.
        
        You can also specify a parameter description by placing a comment in the
        function or script syntax immediately before the parameter variable name.
        If you use both a syntax comment and a Parameter keyword, the description
        associated with the Parameter keyword is used, and the syntax comment is
        ignored.
    .EXAMPLE
        PS> Get-VirtualMachine -Name 'MYVM'
        
        This example retrieves the virtual machine with the name of MYVM from whatever virtualization system
        it's supposed to work with.
    .INPUTS
        None.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Requirements: This requires
    .LINK
        http://www.google.com
#>
}

Function Get-KPMGGroupMemberInfo {
<#
    .SYNOPSIS
        Method to return group information for a given list of security group names.
    .PARAMETER GroupNames
        A list of group names must be passed in (mandatory)
    .PARAMETER GroupReportPath
        Full path (including file name & extension) must be provided for the group output file (mandatory)
    .PARAMETER GroupMemberReportPath
        Full path (including file name & extension) must be provided for the group member output file (mandatory)
    .PARAMETER GroupMembershipReportPath
        Full path (including file name & extension) must be provided for the group membership (nesting) output file (mandatory)
    .PARAMETER LogFilePath
        Path to the logging file. 
    .EXAMPLE
        Get-ActiveDirectoryGroupInfo -GroupNames $GroupNames -GroupReportPath $ADAppSecurityGroupReport `
            -GroupMemberReportPath $ADAppSGMembersReport -GroupMembershipReportPath $ADAppSGMembershipReport
#>
        
    [CmdletBinding()]
    param (  
        [Parameter( Mandatory = $true )]
        [string[]]$GroupNames
    )

    [string]$DateStamp = Get-Date -Format dd-MM-yy_HH-mm-ss
    [string]$ReportOutput = "$HOME\Documents\$DateStamp" + "AMSGroupReport.csv"
        
    foreach( $GroupName IN $GroupNames ) {
        Start-Sleep -Milliseconds 250 #Ensures AD queries are executed slower to avoid jamming up the DC with queries

        #Searches AD for the current group in the loop
        $CurrentGroup = Get-ADGroup -Identity $GroupName -Properties * -ErrorAction SilentlyContinue
        $CurrentMembers = $CurrentGroup | Select-Object -ExpandProperty Members

        foreach( $GroupMember IN $CurrentMembers ) {
            $FormattedUsername = (($GroupMember.Split(','))[0]).TrimStart('CN=')

            If( ($GroupMember -like '*OU=UK Groups*') -or ($GroupMember -like '*BotOPS*') -or ( $GroupMember -like 'UK*' ) ) {
                $UserInfo = [Ordered] @{}
                $UserInfo.GroupName                 = $CurrentGroup.Name
                $UserInfo.SamAccountname            = "$($FormattedUsername) is not a user account"
                $UserInfo.UserPrincipalName=$null
                $Userinfo.DisplayName=$null
                $userInfo.Manager=$null
                $UserInfo.Office=$null
                $UserInfo.Department=$null
                $userInfo.JobTitle=$null
                $userInfo.Grade=$null
                $userInfo.BusinessStream=$null
                $userInfo.Title=$null

                #New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $HOME\AMSGroupMembersReport.csv -Append -NoTypeInformation
                New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $ReportOutput -Append -NoTypeInformation
            }
            
            Else {
                Try {
                    $CurrentUser = Get-ADUser -Identity $FormattedUsername -Properties * -ErrorAction SilentlyContinue

                    # Create a userinfo HT which chooses, formats and organises the data as we want it
                    $UserInfo = [Ordered] @{}
                    $UserInfo.GroupName                 = $CurrentGroup.Name
                    $UserInfo.SamAccountname            = $CurrentUser.SamAccountName.TrimStart('-')
                    $UserInfo.UserPrincipalName         = $CurrentUser.UserPrincipalName.TrimStart('-')
                    $Userinfo.DisplayName               = $CurrentUser.DisplayName.TrimStart('-')
                    $userInfo.Manager                   = If(!($null -eq $CurrentUser.Manager)) { (($CurrentUser.Manager.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
                    $UserInfo.Office                    = $CurrentUser.Office
                    $UserInfo.Department                = $CurrentUser.Department
                    $userInfo.JobTitle                  = $CurrentUser.extensionAttribute12
                    $userInfo.Grade                     = $CurrentUser.extensionAttribute4
                    $userInfo.BusinessStream            = $CurrentUser.extensionAttribute5
                    $userInfo.Title                     = $CurrentUser.Title

                    #New-Object -TypeName PSObject -Property $UserInfo | Write-Host
                    New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $ReportOutput -Append -NoTypeInformation
                    
                    throw "Error"
                }
                Catch {
                    Out-Null
                }
            }
        }
    }
}