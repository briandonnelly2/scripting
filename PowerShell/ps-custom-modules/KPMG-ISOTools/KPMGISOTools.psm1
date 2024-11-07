Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
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
        [switch]$SaveOutput#,

        <# [Parameter( ValueFromPipelineByPropertyName, Position = 2,
        HelpMessage = "Set to true to return information about group members'" )]
        [switch]$MembersInfo,

        [Parameter( ValueFromPipelineByPropertyName, Position = 3,
        HelpMessage = "Set to true to return information about group membership'" )]
        [switch]$MembershipInfo #>
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
                    <# $MembersInfo {
                        #Write-Verbose "Querying Active Directory for group members information."
                        #Get-KPMGADUser -Identities $FinalMembers -SaveOutput:$SaveOutput
                    }
                    $MembershipInfo {
                        #Write-Verbose "Querying Active Directory for group membership information."
                        #Get-KPMGADUser -Identities $FinalMembership -SaveOutput:$SaveOutput
                    } #>
                    $SaveOutput {
                        $GroupInfo = [Ordered] @{}
                        $GroupInfo.Name                 =   $CurrentGroup.Name
                        $GroupInfo.Description          =   $CurrentGroup.Description
                        $GroupInfo.Category             =   $CurrentGroup.GroupCategory
                        $GroupInfo.Scope                =   $CurrentGroup.GroupScope
                        $GroupInfo.Info                 =   $CurrentGroup | Select-Object -ExpandProperty Info
                        $GroupInfo.ManagedBy            =   If(!($null -eq $CurrentGroup.ManagedBy)) { (($CurrentGroup.ManagedBy.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
                        $GroupInfo.Created              =   $CurrentGroup.Created
                        $GroupInfo.Modified             =   $CurrentGroup.Modified
                        $GroupInfo.Members              =   $FinalMembers.Split
                        $GroupInfo.Membership           =   $FinalMembership.Split

                        New-Object -TypeName PSObject -Property $GroupInfo | Write-Output

                    }
                    Default {
                        $GroupInfo = [Ordered] @{}
                        $GroupInfo.Name                 =   $CurrentGroup.Name
                        $GroupInfo.Description          =   $CurrentGroup.Description
                        $GroupInfo.Category             =   $CurrentGroup.GroupCategory
                        $GroupInfo.Scope                =   $CurrentGroup.GroupScope
                        $GroupInfo.Info                 =   $CurrentGroup | Select-Object -ExpandProperty Info
                        $GroupInfo.ManagedBy            =   If(!($null -eq $CurrentGroup.ManagedBy)) { (($CurrentGroup.ManagedBy.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
                        $GroupInfo.Created              =   $CurrentGroup.Created
                        $GroupInfo.Modified             =   $CurrentGroup.Modified
                        $GroupInfo.Members              =   $FinalMembers.Split
                        $GroupInfo.Membership           =   $FinalMembership.Split

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
Function Get-KPMGLocalGroupInfo {
    <#
    .SYNOPSIS
        Invokes command that returns all local security group information from a system.
    .PARAMETER Sessions
        PowerShell sessions are passed for the function to query against (mandatory)
    .PARAMETER LocalSGReportPath
        Full path (including file name & extension) must be provided for the output file (mandatory)
    .PARAMETER LogFilePath
        Path to the logging file. 
    .EXAMPLE
        Get-KPMGLocalGroupInfo -Sessions $Sess -LocalSGReportPath $HOME\LSGR.csv
#>

    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true )]
        [System.Object[]]$Sessions,
        [Parameter( Mandatory = $true )]
        [string]$LocalSGReportPath
        <# [Parameter( Mandatory = $true )]
        [string]$LogFilePath #>
    )

    <# This script block is executed on each PS Session passed in. #>
    $SB1 = {
        <# Decalres a return object variable #>
        [System.Object]$LSGReturnInfo = @()

        Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Gets a list of the local groups using the current session (CIM Session is better.  WMI works with older systems)"
        #[System.Object[]]$LocalGroups = Get-CimInstance -ClassName Win32_Group -filter "LocalAccount=1" | Select-Object -ExpandProperty Name
        [System.Object[]]$LocalGroups = Get-WmiObject -Query "SELECT * FROM Win32_Group WHERE LocalAccount=1" | Select-Object -ExpandProperty Name

        Start-Sleep -Milliseconds 250
        
        Try {
            foreach($GroupName IN $LocalGroups) {
                Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Filters groups based on them being local and not AD groups (CIM Session is better.  WMI works with older systems)"
                #Get-CimInstance -ClassName Win32_GroupUser -Filter "GroupComponent=Win32_Group.Domain='$($Session.Name)',Name='$($GroupName)'"
                $LocalGroupMembersWMI = Get-WmiObject -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$env:COMPUTERNAME',Name='$GroupName'`""
                
                Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Checks for null, builds a suitable hashtable. We still want the group even though it's empty."

                If( $null -eq $LocalGroupMembersWMI ) {
                    $LSGInfo            =   @{}
                    $LSGInfo.Server     =   $env:COMPUTERNAME
                    $LSGInfo.GroupName  =   $GroupName
                    $LSGInfo.Type       =   "N/A"
                    $LSGInfo.MemberName =   "No Members"

                    $LSGReturnInfo += New-Object -TypeName PSObject -Property $LSGInfo
                }

                Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Builds a hashtable and adds the info to the variable"

                If( !( $null -eq $LocalGroupMembersWMI ) ) {
                    foreach ($LocalGroupWMI in $LocalGroupMembersWMI) {
                        Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Performing string operations to format the outpit"
                        $data   = $LocalGroupWMI.PartComponent -split "\," 
                        $name   = (($data[1] -split "=")[1] -replace """","").TrimStart("-")
                        $type   = ($data[0] -split "_|\.")[1]  -replace "Account"
                        $arr    += ("$domain\$name").Replace("""","") 
    
                        $LSGInfo            =   @{}
                        $LSGInfo.Server     =   $env:COMPUTERNAME
                        $LSGInfo.GroupName  =   $GroupName
                        $LSGInfo.Type       =   $type
                        $LSGInfo.MemberName =   $name
    
                        Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Creates a new object and apends the group data above to it"
                        $LSGReturnInfo += New-Object -TypeName PSObject -Property $LSGInfo
                    }
                }
            }
            return $LSGReturnInfo
        }
        Catch {
            Write-Warning "[$env:COMPUTERNAME][$(Get-Date -format T)]Gathering group info on this device has failed.  Please check the logs."
        }
    }

    foreach( $Session IN $Sessions ) {
        Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Gathering local group information from $($Session.Name)"
        Try {
            Invoke-Command -Session $Session -ScriptBlock $SB1 | Select-Object -Property Server, GroupName, Type, MemberName | Write-Output
                    #Export-Csv -Path $LocalSGReportPath -Append -Force -NoTypeInformation
        }
        Catch {
            Write-Error "[$env:COMPUTERNAME][$(Get-Date -format T)]There was an issue gathering group names on $($Session.Name)"
        }
    } 
}