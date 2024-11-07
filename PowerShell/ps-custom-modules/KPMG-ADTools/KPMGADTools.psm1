Set-StrictMode -Version 1.0
Function Get-KPMGADUser {
<# 
    .SYNOPSIS
        Queries KPMG Active Directory (AD) for user account information.
    .DESCRIPTION
        This function will return information about KPMG Active Directory (AD) user accounts. A
        single identity or an array of identities can be passed in, but only as an exact username
        at present. Data returned can either be all AD attributes or a useful selection by specifyin
        'Full' or 'Format' for the DataFormat parameter
    .PARAMETER Identities
        MANDATORY An array of UK Usernames to search for using the 'Identity' parameter.
    .PARAMETER DataFormat
        OPTIONAL: Full returns all AD attributes. Format returns a selection (default).  
    .PARAMETER SaveOutput
        OPTIONAL: If true, saves output to a CSV file.
    .INPUTS
        [String[]]
        [String]
        [switch]
    .OUTPUTS
        [System.Object]
        [ADUser]
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          29 March 2019
        Modified Date:          N/A
        Revfiew Date:           29 June 2019
        Future Enhancements:    1. Add functionality to use Distinguised name as a query option
                                2. Add functionality to use a filter to search with
                                3. 
#>
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, ValueFromPipelineByPropertyName, Position = 0,
        HelpMessage = "An array of identities to search for" )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Identities,

        [Parameter( ValueFromPipelineByPropertyName, Position = 1,
        HelpMessage = "Set to 'Full' for all AD attributes or 'Format' for a selection" )]
        [ValidateSet('Full', 'Format')]
        [string]$DataFormat,

        [Parameter( ValueFromPipelineByPropertyName, Position = 2,
        HelpMessage = "If true, saves output to a CSV file" )]
        [switch]$SaveOutput
    )
    
    Process {
        foreach ( $Identity IN $Identities ) {
            Try {
                Write-Verbose "Searching AD for [$($Identity)]"
                [System.Object]$CurrentUser = Get-ADUser -Identity $Identity -Properties * -ErrorAction SilentlyContinue
    
                If ( $null -eq $CurrentUser ) {
                    Throw "An account was not found for [$($Identity)]"
                }

                Write-Verbose "Found [$($CurrentUser.DisplayName)]."

                switch ( $DataFormat ) {
                    "Full" {
                        If ( $SaveOutput -eq $true ) {
                            $CurrentUser | Export-Csv -Path "$HOME\Documents\$(Get-Date -Format HHmmss)-AD-group-report" -Append -Force
                        } Else { 
                             Write-Output $CurrentUser
                        }
                    }
                    "Format" {
                        Write-Verbose "Expanding group membership for [$($CurrentUser.DisplayName)]."
                        [System.Object]$CurrentMembership = $CurrentUser | Select-Object -ExpandProperty MemberOf

                        If ( !( $null -eq $CurrentMembership ) ) {
                            foreach( $GroupMembership IN $CurrentMembership ) { [string[]]$FormattedMembership += (($GroupMembership.Split(','))[0]).TrimStart('CN=') }
                        }

                        $UserInfo = [Ordered] @{}
                        $UserInfo.SamAccountname            = $CurrentUser.SamAccountName.TrimStart('-')
                        $UserInfo.UserPrincipalName         = $CurrentUser.UserPrincipalName.TrimStart('-')
                        $Userinfo.DisplayName               = $CurrentUser.DisplayName.TrimStart('-')
                        $userInfo.Manager                   = If(!($null -eq $CurrentUser.Manager)) { (($CurrentUser.Manager.Split(','))[0]).TrimStart('CN=') } Else { $null }
                        $UserInfo.Office                    = $CurrentUser.Office
                        $UserInfo.Department                = $CurrentUser.Department
                        $userInfo.JobTitle                  = $CurrentUser.extensionAttribute12
                        $userInfo.Grade                     = $CurrentUser.extensionAttribute4
                        $userInfo.BusinessStream            = $CurrentUser.extensionAttribute5
                        $userInfo.Title                     = $CurrentUser.Title
                        $Userinfo.Enabled                   = $CurrentUser.Enabled
                        $userinfo.LastLogonDate             = $CurrentUser.LastLogonDate
                        $UserInfo.LockedOut                 = $CurrentUser.LockedOut
                        $UserInfo.SID                       = $CurrentUser.SID
                        $UserInfo.PasswordLastSet           = $CurrentUser.PasswordLastSet
                        $UserInfo.GroupMembership           = If(!($null -eq $FormattedMembership)) { $FormattedMembership } Else { $null }

                        If ( $SaveOutput -eq $true ) {
                            New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path "$HOME\Documents\$(Get-Date -Format HHmmss)-AD-group-report" -Append -Force
                        } Else { 
                            New-Object -TypeName PSObject -Property $UserInfo | Write-Output 
                        }
                    }
                    Default {
                        Write-Verbose "Expanding group membership for [$($CurrentUser.DisplayName)]."
                        [System.Object]$CurrentMembership = $CurrentUser | Select-Object -ExpandProperty MemberOf

                        If ( !( $null -eq $CurrentMembership ) ) {
                            foreach( $GroupMembership IN $CurrentMembership ) { [string[]]$FormattedMembership += (($GroupMembership.Split(','))[0]).TrimStart('CN=') }
                        }

                        $UserInfo = [Ordered] @{}
                        $UserInfo.SamAccountname            = $CurrentUser.SamAccountName.TrimStart('-')
                        $UserInfo.UserPrincipalName         = $CurrentUser.UserPrincipalName.TrimStart('-')
                        $Userinfo.DisplayName               = $CurrentUser.DisplayName.TrimStart('-')
                        $userInfo.Manager                   = If(!($null -eq $CurrentUser.Manager)) { (($CurrentUser.Manager.Split(','))[0]).TrimStart('CN=') } Else { $null }
                        $UserInfo.Office                    = $CurrentUser.Office
                        $UserInfo.Department                = $CurrentUser.Department
                        $userInfo.JobTitle                  = $CurrentUser.extensionAttribute12
                        $userInfo.Grade                     = $CurrentUser.extensionAttribute4
                        $userInfo.BusinessStream            = $CurrentUser.extensionAttribute5
                        $userInfo.Title                     = $CurrentUser.Title
                        $Userinfo.Enabled                   = $CurrentUser.Enabled
                        $userinfo.LastLogonDate             = $CurrentUser.LastLogonDate
                        $UserInfo.LockedOut                 = $CurrentUser.LockedOut
                        $UserInfo.SID                       = $CurrentUser.SID
                        $UserInfo.PasswordLastSet           = $CurrentUser.PasswordLastSet
                        $UserInfo.GroupMembership           = If(!($null -eq $FormattedMembership)) { $FormattedMembership } Else { $null }

                        If ( $SaveOutput -eq $true ) {
                            New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path "$HOME\Documents\$(Get-Date -Format HHmmss)-AD-group-report" -Append -Force
                        } Else { 
                            New-Object -TypeName PSObject -Property $UserInfo | Write-Output 
                        }
                    }
                }
            } Catch {
                Write-Error ($_.Exception.ToString())
                Continue
            }
        }        
    }
}
Function Get-KPMGADGroup {
<#
    .SYNOPSIS
        Queries KPMG Active Directory for security groups.
    .DESCRIPTION
        Will return formatted security group details given a valid AD Identity.
    .PARAMETER Identity 
        MANDATORY A UK group name to search for using the 'Identity' parameter. 
    .PARAMETER SaveOutput
        OPTIONAL: Set to 'true' to save output to a CSV file
    .PARAMETER LogFilePath
        MANDATORY: The log file path.
    .EXAMPLE
        An example
#>

    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, ValueFromPipelineByPropertyName, Position = 0,
        HelpMessage = "An array of identities to search for" )]
        [string[]]$Identities,

        [Parameter( ValueFromPipelineByPropertyName, Position = 1,
        HelpMessage = "Set to true to save output to a CSV file" )]
        [switch]$SaveOutput,

        [Parameter( ValueFromPipelineByPropertyName, Position = 2,
        HelpMessage = "Set to true to return information about group members'" )]
        [switch]$MembersInfo,

        [Parameter( ValueFromPipelineByPropertyName, Position = 3,
        HelpMessage = "Set to true to return information about group membership'" )]
        [switch]$MembershipInfo
    )

    $ErrorActionPreference = "SilentlyContinue"

    Process {

        foreach ( $Identity IN $Identities ) {
            Try {
                Write-Verbose "Searching AD for [$($Identity)]"
                [System.Object]$CurrentGroup = Get-ADGroup -Identity $Identity -Properties *
    
                If ( $null -eq $CurrentGroup ) {
                    Throw "An account was not found for [$($Identity)]"
                }

                Write-Verbose "[$($CurrentGroup.DisplayName)]. Expanding the 'Members' field"
                [System.Object[]]$CurrentMembers = $CurrentGroup | Select-Object -ExpandProperty Members
                If ( $null -eq $CurrentMembers ) {
                    Write-Warning "No one is a member of this group. Members info will not be output"
                    $global:MembersInfo = $false
                } Else {
                    foreach( $GroupMember IN $CurrentMembers ) { $FinalMembers += (($GroupMember.Split(','))[0]).TrimStart('CN=') }
                }

                Write-Verbose "[$($CurrentGroup.DisplayName)]. Expanding the 'Memberof' field"
                [System.Object]$CurrentMembership = $CurrentGroup | Select-Object -ExpandProperty MemberOf
                If ( $null -eq $CurrentMembership ) {
                    Write-Warning "This group is not a member of another group. Membership info will not be output"
                    $global:MembershipInfo = $false
                } Else {
                    foreach( $GroupMembership IN $CurrentMembership ) { $FinalMembership += (($GroupMembership.Split(','))[0]).TrimStart('CN=') }
                }

                Write-Verbose "SaveOutput is set to $SaveOutput"
                Write-Verbose "MembersInfo is set to $MembersInfo"
                Write-Verbose "MembershipInfo is set to $MembershipInfo"

                switch ( $true ) {
                    $MembersInfo {
                        Write-Verbose "Querying Active Directory for group members information."
                        Get-KPMGADUser -Identities $FinalMembers -SaveOutput:$SaveOutput
                    }
                    $MembershipInfo {
                        Write-Verbose "Querying Active Directory for group membership information."
                        Get-KPMGADUser -Identities $FinalMembership -SaveOutput:$SaveOutput
                    }
                    $SaveOutput {
                        $GroupInfo = [Ordered] @{}
                        $GroupInfo.Name                =   $CurrentGroup.Name
                        $GroupInfo.Description         =   $CurrentGroup.Description
                        $GroupInfo.Category            =   $CurrentGroup.GroupCategory
                        $GroupInfo.Scope               =   $CurrentGroup.GroupScope
                        $GroupInfo.Info                =   $CurrentGroup | Select-Object -ExpandProperty Info
                        $GroupInfo.ManagedBy           =   If(!($null -eq $CurrentGroup.ManagedBy)) { (($CurrentGroup.ManagedBy.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
                        $GroupInfo.Created             =   $CurrentGroup.Created
                        $GroupInfo.Modified            =   $CurrentGroup.Modified

                        New-Object -TypeName PSObject -Property $GroupInfo | Export-Csv

                    }
                    Default {
                        $GroupInfo = [Ordered] @{}
                        $GroupInfo.Name                =   $CurrentGroup.Name
                        $GroupInfo.Description         =   $CurrentGroup.Description
                        $GroupInfo.Category            =   $CurrentGroup.GroupCategory
                        $GroupInfo.Scope               =   $CurrentGroup.GroupScope
                        $GroupInfo.Info                =   $CurrentGroup | Select-Object -ExpandProperty Info
                        $GroupInfo.ManagedBy           =   If(!($null -eq $CurrentGroup.ManagedBy)) { (($CurrentGroup.ManagedBy.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
                        $GroupInfo.Created             =   $CurrentGroup.Created
                        $GroupInfo.Modified            =   $CurrentGroup.Modified

                        New-Object -TypeName PSObject -Property $GroupInfo | Write-Output
                    }
                }
            } Catch {
                Write-Warning "A general exception was thrown."
                Write-Error ($_.Exception.ToString())
                Continue
            }
        }
    }
}

Function Add-KPMGADUser {
<# 
    .SYNOPSIS
        Adds a user to a security group.
    .DESCRIPTION
        This function allows for someone to be added to an Active Directory (AD) security group,
        provided the user executing it has the relevant access and permissions for it.  
        The function will check if the security group exists, check if the user being added exists,
        and then attempt to add the user to the security group.
    .PARAMETER UserName
        MANDATORY: The username (SamAccountName) of the user to be added.
    .PARAMETER GroupName
        MANDATORY: The group name (SamAccountName) of the group this user has to be added to. 
    .PARAMETER Credentials
        MANDATORY: The credentials used to make the changes in Acvtive Directory
    .INPUTS
        [String]
    .OUTPUTS

    .EXAMPLE
        $Credentials = Get-Credential -Message "Please enter your credntials"
        $Username = "briandonnelly2"
        $GroupName = "UK-SG PR-DA UAT ACE"

        Add-KPMGADUser -UserName $Username -GroupName $GroupName -Credentials $Credentials
        
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          13 August 2020
        Modified Date:          N/A
        Revfiew Date:           13 November 2020
        Future Enhancements:    1. 
                                2. 
                                3. 
#>

    [CmdletBinding()]
    Param(
        [Parameter( Mandatory, ValueFromPipelineByPropertyName, Position = 0,
        HelpMessage = "A username that exists in the KPMG Active Directory" )]
        [string]$UserName,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName, Position = 1,
        HelpMessage = "A group name that exists in the KPMG Active Directory" )]
        [string]$GroupName,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName, Position = 1,
        HelpMessage = "Please supply credentials to make chnages in AD" )]
        [PSObject]$Credentials
    )

    Try {
        # Searches for the supplied username and stores the ADUser object in a variable if found
        $ADUser = Get-ADUser -Identity $UserName
        
        # Searches for the supplied group name and stores the ADGroup object in a variable if found
        $ADGroup = Get-ADGroup -Identity $GroupName

        # Checks if the AD user object is null
        If ($null -eq $ADUser) { 
            # Checks if AD Group object is null
            If ($null -eq $ADGroup) {
                #Throws an error because reaching this point means both objects where null
                Throw "Both the username: '$Username' and the group name: $GroupName cannot be found..."
            }
            #This error is thrown because reaching this point means only the user object is null
            Throw "Supplied AD username '$Username' cannot be found..."
        }
        # Checks if AD Group object is null
        ElseIf ($null -eq $ADGroup) {
            #This error is thrown because reaching this point means only the group object is null
            Throw "Supplied AD group name: $GroupName cannot be found..."
        }
        Else {
            # If both the user and group exist, we attempt to add the user to the security group.
            Add-ADGroupMember -Identity $ADGroup -Members $ADUser -Credential $Credentials
        }
    }
    Catch {
        $_.Exception
    }
}