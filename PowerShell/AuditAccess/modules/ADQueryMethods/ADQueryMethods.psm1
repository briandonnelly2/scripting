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
        Get-LocalGroupInfo -Sessions $Sessions -LocalSGReportPath $LocalSGReport
#>

    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true )]
        [System.Object[]]$Sessions,
        [Parameter( Mandatory = $true )]
        [string]$LocalSGReportPath,
        [Parameter( Mandatory = $true )]
        [string]$LogFilePath
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
                ElseIf( !( $null -eq $LocalGroupMembersWMI ) ) {
                    Try {
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
                    Catch {
                        Write-Warning "[$env:COMPUTERNAME][$(Get-Date -format T)]Gathering group info on this device has failed.  Please check the logs."
                    }
                }
                Else {
                    Write-Warning "[$env:COMPUTERNAME][$(Get-Date -format T)]Gathering group info on this device has failed.  Please check the logs."
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

Function Get-KPMGADUser {
<# 
    .SYNOPSIS
        Queries KPMG Active Directory for User Accounts
    .DESCRIPTION
        Will return a single formatted user account details given a valid AD Identity.
    .PARAMETER Identity 
        MANDATORY 'Identity' Parameter Set (Default): A complete UK Identity to search for 
        using the 'Identity' parameter. 
    .PARAMETER Filter
        OPTIONAL 'Filter' Parameter Set: A partial UK Identity to search for using the 'Filter' 
        parameter. The wildcard operator '*' should be included at the left, right or both ends of the 
        string depending on preference. Filter will be constructed as: 
        "-Filter { 'Name' -like 'THIS_PARAMETER' }"
    .PARAMETER OutputPath
        OPTIONAL: A path can be passed in that will be used to save any required output. A default path
        will be used if this is empty.
    .PARAMETER LogFilePath
        MANDATORY: The log file path.
#>
    [CmdletBinding( DefaultParameterSetName = "Identity" )]
    Param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Identity", Position = 0,
        HelpMessage = "Enter an Active Directory Identity to Search For" )]
        [string]$Identity,

        [Parameter( ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Filter", Position = 0,
        HelpMessage = "Enter PART of an Active Directory Identity to Search For (Include '*' wildcard accordingly)" )]
        [string]$Filter,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 1,
        HelpMessage = "Provide full logfile path" )]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$LogFilePath,

        [Parameter( ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 2,
        HelpMessage = "Set to 'true' to save output to a CSV file" )]
        [bool]$SaveOutput
    )
    $WarningPreference = “continue”
    $VerbosePreference = “SilentlyContinue”
    If( $PSCmdlet.ParameterSetName -eq "Identity" ) {
        Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]You're using the Identity Parameter Set"

        Try {
            Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Searching AD for [$($Identity)]"
            [System.Object]$CurrentUser = Get-ADUser -Identity $Identity -Properties * -ErrorAction SilentlyContinue

            If( !( $null -eq $CurrentUser ) ) {

                Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Found [$($CurrentUser.DisplayName)]. Expanding the 'MemberOf' field"
                [string[]]$Groups = $CurrentUser | Select-Object -ExpandProperty MemberOf

                If( !( $null -eq $Groups ) ) { 
                    Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Found $($Groups.Count) groups [$($CurrentUser.DisplayName)] is a member of. Obtaining identities by formatting the fully distinguished name."
                    foreach( $Group IN $Groups ) { 
                        [string[]]$FormattedIdentities += ( ( $Group.Split( ',' ))[0]).TrimStart( 'CN=' )
                    }
                }
                ElseIf( $null -eq $Groups ) {
                    Write-Warning "User is not a member of any security groups"
                    break
                }
            }
            ElseIf( $null -eq $CurrentUser ) {
                Write-Warning "An account was not found for [$($Identity)]"
                break
            }
            throw "There was an issue while searching for this user. Please check the logs for details."
        }
        Catch {
            Write-Error ($_.Exception.message)
        }
    }
    ElseIF( $PSCmdlet.ParameterSetName -eq "Filter" ) {
        Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]You're using the Filter Parameter Set by using the Filter parameter [$($Filter)]"  
    }
    Else { 
        Write-Error "Something has gone wrong here. Check the log at $($LogFilePath) for further details"
    }

    <# Checks if custom properties are being used #>
    If( !( $null -eq $Properties ) ) { $CustomProperties = $true } Else { $CustomProperties = $false }
    
    <# Builds a hashtable that returns the default values  #>
    If( $CustomProperties -eq $false ) {

        # Create a userinfo HT which chooses, formats and organises the data as we want it
        $UserInfo = [Ordered] @{}
        $UserInfo.SamAccountname            = $CurrentUser.SamAccountName.TrimStart('-')
        $Userinfo.Name                      = $CurrentUser.Name.TrimStart('-')
        $UserInfo.UserPrincipalName         = $CurrentUser.UserPrincipalName.TrimStart('-')
        $Userinfo.DisplayName               = $CurrentUser.DisplayName.TrimStart('-')
        $userInfo.Manager                   = If(!($null -eq $CurrentUser.Manager)) { (($CurrentUser.Manager.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
        $Userinfo.Enabled                   = $CurrentUser.Enabled
        $userinfo.LastLogonDate             = $CurrentUser.LastLogonDate
        $UserInfo.Department                = $CurrentUser.Department
        $UserInfo.Created                   = $CurrentUser.Created
        $UserInfo.accountExpires            = $CurrentUser.accountExpires
        $UserInfo.LastBadPasswordAttempt    = $CurrentUser.LastBadPasswordAttempt
        $UserInfo.LockedOut                 = $CurrentUser.LockedOut
        $UserInfo.Modified                  = $CurrentUser.Modified
        $UserInfo.SID                       = $CurrentUser.SID
        $UserInfo.PasswordLastSet           = $CurrentUser.PasswordLastSet
        $UserInfo.GroupMembership           = $FormattedMembership

        Write-Verbose "$($UserInfo.SamAccountname) was returned."

        New-Object -TypeName PSObject -Property $UserInfo
    }

    <# Builds a hashtable based on custom values passed to the script
    ElseIf( $CustomProperties = $true ) {
        Write-Verbose "Custom values section not coded yet."
        #$CustomInfo = $Properties

        #New-Object -TypeName PSObject -Property $CustomInfo
    }

    <# Script Variables
    [System.Object]$CurrentUser
    [System.Object]$FormattedMembership = @()
    [string]$SearchType
    [bool]$CustomProperties = $false

    [Parameter( ValueFromPipeline, ValueFromPipelineByPropertyName,
        HelpMessage = "Specifiy a hashtable of user properties to tbe returned" )]
        #[ValidateSet( AD Properties should be validated )]
        [hashtable]$Properties,

    <# Decide what to do based on input.
    switch ( $true ) {
        <# Case where Identity is specified
        ( !( $null -eq $Identity ) -and  ( $null -eq $Filter ) ) { 
            $SearchType = "Identity" }
        <# Case where filter is specified  
        (  ( $null -eq $Identity ) -and !( $null -eq $Filter ) ) { 
            $SearchType = "Filter" }
        <# Case where both specified  
        ( !( $null -eq $Identity ) -and !( $null -eq $Filter ) ) { 
            $SearchType = "Identity" }
        Default { $SearchType = "Default" }
    }#>
}

Function Get-KPMGADGroup {
    <# 
        .SYNOPSIS
            Queries KPMG Active DIrectory for Security Groups
        .DESCRIPTION
            Will return formatted security group details given a valid security group name.
        .PARAMETER GroupName 
            A valid UK Identity
        .PARAMETER Properties
            A hashtable specifying valid AD properties to be returned.
        .PARAMETER LogFilePath
            The log file path,
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = "Specifiy a group name to return group information" )]
        [string]$GroupName,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = "Specifies a filter to search Active Directory with.  Format would be 'Property:Value'" )]
        #[ValidatePattern( Filter pattern should be validated )]
        [string]$Filter,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = "Specifiy a hashtable of group properties to tbe returned" )]
        #[ValidateSet( AD Properties should be validated )]
        [hashtable]$Properties,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = "Specify the log file path" )]
        [string]$LogFilePath
    )

    <# Script Variables #>
    [System.Object]$CurrentGroup
    [System.Object]$FormattedMembers = @()
    [System.Object]$FormattedMemberships = @()
    [string]$SearchType
    [bool]$CustomProperties = $false

    <# Decide what to do based on input. #>
    switch ( $true ) {
        <# Case where GroupName is specified #>
        ( !( $null -eq $GroupName ) -and  ( $null -eq $Filter ) ) { 
            $SearchType = "Identity" }
        <# Case where filter is specified #>    
        (  ( $null -eq $GroupName ) -and !( $null -eq $Filter ) ) { 
            $SearchType = "Filter" }
        <# Case where both specified #>    
        ( !( $null -eq $GroupName ) -and !( $null -eq $Filter ) ) { 
            $SearchType = "Identity" }
        Default { $SearchType = "Default" }
    }


    <# Queries AD based on $SearchType variable defined above #>
    switch ( $SearchType ) {
        <# Prompts user for input or asks to quit #>
        "Default" {
            Write-Verbose "Default section not coded yet"
        }
        <# Performs an exact match search looking for a supplied Identity #>
        "Identity" {
            <# Tries a search using the supplied Identity #>
            Try{ [System.Object]$CurrentGroup = Get-ADGroup -Identity $GroupName -Properties *
                <# Checks if anything was returned #>
                If( !( $null -eq $CurrentGroup ) ) {
                    <# Expands the 'MemberOf' field #>
                    [System.Object]$CurrentMembers = $CurrentGroup | Select-Object -ExpandProperty Members -ErrorAction SilentlyContinue
                    [System.Object]$CurrentMemberships = $CurrentGroup | Select-Object -ExpandProperty MemberOf -ErrorAction SilentlyContinue
                    <# Formats the 'Fully Distinguished Name' to get the actual group name within. #>
                    If( !( $null -eq $CurrentMembers ) ) { 
                        foreach( $CurrentMember IN $CurrentMembers ) { 
                            $FormattedMembers += If(!($null -eq $CurrentMember)) { (($CurrentMember.Split(','))[0]).TrimStart('CN=-') } Else { 'NULL' } 
                        } 
                    }
                    If( !( $null -eq $CurrentMemberships ) ) { 
                        foreach( $CurrentMembership IN $CurrentMemberships ) { 
                            $FormattedMemberships +=  If(!($null -eq $CurrentMembership)) { (($CurrentMembership.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' } 
                        } 
                    }
                } Else { Write-Verbose "The security group was not found in Active Directory" -ErrorValue $Error -LogFilePath $LogFilePath | Write-Host -ForegroundColor DarkMagenta }
                <# Error Handling #>
            } Catch { Write-Verbose "There was an issue while searching for this security group. Please check the logs for details." }  
        }
        <# Builds an query filter to search AD with #>
        "Filter" {
            Write-Verbose "Default section not coded yet"
        }
        <#  #>
        Default {
            Write-Verbose "You have provided incorrect or no values to the Cmdlet"
        }
    }
    
    <# Checks if custom properties are being used #>
    If( !( $null -eq $Properties ) ) { $CustomProperties = $true } Else { $CustomProperties = $false }

    <# Builds a hashtable that returns the default values  #>
    If( $CustomProperties -eq $false ) {

        # Create a groupinfo HT which chooses, formats and organises the data as we want it
        $GroupInfo = [Ordered] @{}
        $GroupInfo.Name                =   $CurrentGroup.Name
        $GroupInfo.Description         =   $CurrentGroup.Description
        $GroupInfo.Category            =   $CurrentGroup.GroupCategory
        $GroupInfo.Scope               =   $CurrentGroup.GroupScope
        $GroupInfo.Info                =   $CurrentGroup | Select-Object -ExpandProperty Info
        $GroupInfo.ManagedBy           =   If(!($null -eq $CurrentGroup.ManagedBy)) { (($CurrentGroup.ManagedBy.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
        $GroupInfo.Created             =   $CurrentGroup.Created
        $GroupInfo.Modified            =   $CurrentGroup.Modified
        $GroupInfo.GroupMembers        =   $FormattedMembers
        $GroupInfo.GroupMemberships    =   $FormattedMemberships

        #Creates a new object using the ordered hashtable above
        New-Object -TypeName PSObject -Property $GroupInfo
    }

    <# Builds a hashtable based on custom values passed to the script #>
    ElseIf( $CustomProperties = $true ) {
        Write-Verbose "Custom values section not coded yet."
        #$CustomInfo = $Properties

        #New-Object -TypeName PSObject -Property $CustomInfo
    }
}

Function Get-KPMGSQLServerDatabaseInfo {
    <#
        .SYNOPSIS
            Invokes SQL scripts to return application database information.
        .PARAMETER DatabaseNames
            The names of the databases the scripts should be run against
        .PARAMETER DatabaseInstances
            The names of the database instances the scripts are rto be invoked against
        .PARAMETER SqlScripts
            The scripts that should be executed
        .PARAMETER LogFilePath
            Path to the logging file. 
        .EXAMPLE
    #>
        [CmdletBinding()]
        param(
            [Parameter( Mandatory )]
            [string]$DatabaseInstance,
            #$DatabaseInstance = "UKXVMSSQL015\DB02"
            [Parameter( Mandatory )]
            [string]$SqlScript,
            #$SqlScript = "C:\Users\-oper-briandonnelly2\Documents\testquery.sql"
            [Parameter( Mandatory )]
            [string]$LogFilePath
            #$LogFilePath="C:\Users\-oper-briandonnelly2\Documents\log.log"
        )                                    
        
        process {
            If ( Test-Connection -ComputerName $DatabaseInstance.Split('\')[0] -Quiet ) {
                Write-Verbose "[$env:COMPUTERNAME][$(Get-Date -format T)]Executing $($SQLScript.Name) against $DatabaseInstance"
                
                Try {
                    Invoke-Sqlcmd -ServerInstance $DatabaseInstance -InputFile $SQLScript -AbortOnError
    
                    #throw "Execution of the following SQL script has failed: $($SQLScript.Name)"
                } 
                Catch {
                    Write-Error ($_.Exception.message)
                }
            }
            Else { 
                Write-Error "Error when contacting the $DatabaseInstance database server. Please check details and retry."
    
                Start-Sleep -Milliseconds 250
            }
        }
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
                $Userinfo.Enabled=$null
                $UserInfo.Office=$null
                $UserInfo.Department=$null
                $userInfo.JobTitle=$null
                $userInfo.Grade=$null
                $userInfo.BusinessStream=$null
                $userInfo.Title=$null

                #[string[]]$FormattedUserInfo += New-Object -TypeName PSObject -Property $UserInfo
                New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $HOME\AlphataxGroupReport.csv -Append -NoTypeInformation
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
                    $Userinfo.Enabled                   = $CurrentUser.Enabled
                    $UserInfo.Office                    = $CurrentUser.Office
                    $UserInfo.Department                = $CurrentUser.Department
                    $userInfo.JobTitle                  = $CurrentUser.extensionAttribute12
                    $userInfo.Grade                     = $CurrentUser.extensionAttribute4
                    $userInfo.BusinessStream            = $CurrentUser.extensionAttribute5
                    $userInfo.Title                     = $CurrentUser.Title

                    #[string[]]$FormattedUserInfo += New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $HOME\AlphataxGroupReport.csv -Append -NoTypeInformation
                    New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $HOME\AlphataxGroupReport.csv -Append -NoTypeInformation
                    throw "Error"
                }
                Catch {
                    Out-Null
                }
            }
        }
    }
}

Function New-SQLServerQuery {
<#

#>

    [CmdletBinding()]
    Param(
        [string]$Query,
        [string[]]$DPMDatabaseNames,
        [string]$SQLCluster
    )

    foreach($Database IN $DatabaseNames) {
        [system.object[]]$Results = Invoke-Sqlcmd -AbortOnError -Database $Database -Query $Query -ServerInstance $SQLCluster
        foreach($Result IN $Results) {
            $Result | Select-Object -Property @{Name = "Database";Expression={$Database}}, WindowsLogin, Active, UserRoleName | `
                Export-Csv -Path "$HOME\Documents\result-$(Get-Date -Format HHmmss).csv" -Append -Force -NoTypeInformation
        }
    }
}

<#
Function Get-KPMGActiveDirectoryUserInfo {
<#
    .SYNOPSIS
        Method to return user information for a given list of usernames.
    .PARAMETER Usernames
        A list of usernames (SAM Account Names) must be passed in (mandatory)
    .PARAMETER userReportPath
        Full path (including file name & extension) must be provided for the user output file (mandatory)
    .PARAMETER UserGroupReportPath
        Full path (including file name & extension) must be provided for the user groups output file (mandatory)
    .PARAMETER LogFilePath
        Path to the logging file. 
    .EXAMPLE
        Get-ActiveDirectoryUserInfo -Usernames $AllAccountsToSearch -userReportPath $ADAccountReport -UserGroupReportPath $ADUserGroupReport

[CmdletBinding()]
param(
    [Parameter( Mandatory = $true )]
    [string[]]$Usernames,
    [Parameter( Mandatory = $true )]
    [string]$userReportPath,
    [Parameter( Mandatory = $true )]
    [string]$UserGroupReportPath,
    [Parameter( Mandatory = $true )]
    [string]$LogFilePath
)

Write-Verbose "Gathering information about the following accounts: $UserNames"
Start-Sleep -Seconds 5

Write-Verbose "Starting search of Active Directory."

foreach($Identity IN $Usernames) {
    Start-Sleep -Milliseconds 250 #Ensures AD queries are executed slower to avoid jamming up the DC with queries

    Try { 
        #Searches AD for the current user in the loop
        $CurrentUser = Get-ADUser -Identity $Identity -Properties *
            
        # Create a userinfo HT which chooses, formats and organises the data as we want it
        $UserInfo = [Ordered] @{}
        $UserInfo.SamAccountname            = $CurrentUser.SamAccountName.TrimStart('-')
        $Userinfo.Name                      = $CurrentUser.Name.TrimStart('-')
        $UserInfo.UserPrincipalName         = $CurrentUser.UserPrincipalName.TrimStart('-')
        $Userinfo.DisplayName               = $CurrentUser.DisplayName.TrimStart('-')
        $userInfo.Manager                   = If(!($null -eq $CurrentUser.Manager)) { (($CurrentUser.Manager.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
        $Userinfo.Enabled                   = $CurrentUser.Enabled
        $userinfo.LastLogonDate             = $CurrentUser.LastLogonDate
        $UserInfo.Department                = $CurrentUser.Department
        $UserInfo.Created                   = $CurrentUser.Created
        $UserInfo.accountExpires            = $CurrentUser.accountExpires
        $UserInfo.LastBadPasswordAttempt    = $CurrentUser.LastBadPasswordAttempt
        $UserInfo.LockedOut                 = $CurrentUser.LockedOut
        $UserInfo.Modified                  = $CurrentUser.Modified
        $UserInfo.SID                       = $CurrentUser.SID
        $UserInfo.PasswordLastSet           = $CurrentUser.PasswordLastSet

        #Creates a new object using the ordered hashtable above
        New-Object -TypeName PSObject -Property $UserInfo | Export-Csv -Path $UserReportPath -Force -Append

        #Expands the MemberOf field foir the current user and stores any groups in a variable
        $Groups = $CurrentUser | Select-Object -ExpandProperty MemberOf

        ForEach($Group IN $Groups) {
            # Create a groupinfo HT which chooses, formats and organises the data as we want it
            $GroupInfo = [Ordered] @{}
            $GroupInfo.Name                     = $CurrentUser.Name.TrimStart('-')
            $GroupInfo.Group                    = (($Group.Split(','))[0]).TrimStart('CN=')

            #Creates a new object using the ordered hashtable above
            New-Object -TypeName PSObject -Property $GroupInfo | Export-Csv -Path $UserGroupReportPath -Force -Append
        }

        Write-Verbose "Found an account for $($UserInfo.DisplayName) Adding it to the report"
        
        Start-Sleep -Milliseconds 250
    }
    Catch {
        Write-Verbose "Couldn't find any account for Identity $Identity"
    }
}
}

Function Get-KPMGActiveDirectoryGroupInfo {
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


[CmdletBinding()]
param (  
    [Parameter( Mandatory = $true )]
    [System.Object]$GroupNames,
    [Parameter()]
    [string]$GroupReportPath = "$HOME\GroupReport.csv",
    [Parameter()]
    [string]$GroupMemberReportPath = "$HOME\GroupMemberReport.csv",
    [Parameter()]
    [string]$GroupMembershipReportPath = "$HOME\GroupMembershipReport.csv"
)


    foreach( $GroupName IN $GroupNames ) {
        Start-Sleep -Milliseconds 250 #Ensures AD queries are executed slower to avoid jamming up the DC with queries

        Try {
            #Searches AD for the current group in the loop
            $CurrentGroup = Get-ADGroup -Identity $GroupName -Properties *

            # Create a groupinfo HT which chooses, formats and organises the data as we want it
            $GroupInfo = [Ordered] @{}
            $GroupInfo.Name             =   $CurrentGroup.Name
            $GroupInfo.Description      =   $CurrentGroup.Description
            $GroupInfo.Category         =   $CurrentGroup.GroupCategory
            $GroupInfo.Scope            =   $CurrentGroup.GroupScope
            $GroupInfo.Info             =   $CurrentGroup.Info
            $GroupInfo.ManagedBy        =   $CurrentGroup.ManagedBy
            $GroupInfo.Created          =   $CurrentGroup.Created
            $GroupInfo.Modified         =   $CurrentGroup.Modified
            $GroupInfo.Notes            =   $CurrentGroup.Notes
    
            #Creates a new object using the ordered hashtable above
            New-Object -TypeName PSObject -Property $GroupInfo | Export-Csv -Path $GroupReportPath -NoTypeInformation -Append -Force
    
            $CurrentMembers = $CurrentGroup | Select-Object -ExpandProperty Members
    
            foreach( $GroupMember IN $CurrentMembers ) {
                # Create a GroupMember HT which chooses, formats and organises the data as we want it
                $GroupMembersInfo = [ordered] @{}
                $GroupMembersInfo.GroupName =  $GroupInfo.Name
                $GroupMembersInfo.Member    =  If(!($null -eq $GroupMember)) { (($GroupMember.Split(','))[0]).TrimStart('CN=-') } Else { 'NULL' }
    
                #Creates a new object using the ordered hashtable above
                New-Object -TypeName PSObject -Property $GroupMembersInfo | Export-Csv -Path $GroupMemberReportPath -NoTypeInformation -Append -Force
            }
    
            $CurrentMembership = $CurrentGroup | Select-Object -ExpandProperty MemberOf
    
            foreach( $GroupMemberOf IN $CurrentMembership ) { 
                # Create a GroupMembership HT which chooses, formats and organises the data as we want it
                $GroupMembershipInfo = [ordered] @{}
                $GroupMembershipInfo.GroupName =  $GroupInfo.Name
                $GroupMembershipInfo.Member    =  If(!($null -eq $GroupMemberOf)) { (($GroupMemberOf.Split(','))[0]).TrimStart('CN=') } Else { 'NULL' }
    
                #Creates a new object using the ordered hashtable above
                New-Object -TypeName PSObject -Property $GroupMembershipInfo | Export-Csv -Path $GroupMembershipReportPath -NoTypeInformation -Append -Force
            }
        }
        Catch { 

        }
    }
}

$Query = 
"
SELECT u.Username AS 'WindowsLogin'
	  ,pu.IsActive AS 'Active'
	  ,r.[Name] AS 'UserRoleName'
  FROM [User] AS u
  FULL JOIN PracticeUser AS pu ON u.PracticeUserID = pu.PracticeUserID
  INNER JOIN [Role] AS r ON u.RoleID = r.RoleID
  WHERE Username LIKE '%svc%'
"

$SQLQuery2 = 
"
SELECT 'UK\' + [UserId] AS 'WindowsLogin'
      ,[bActive] AS 'Active'
      ,[strUserRoleName] AS 'UserRoleName'
  FROM [User]
  WHERE UserId LIKE '%svc%'
"

[string[]]$DatabaseNames = ('PracticeManagement_TaxAid','PracticeManagement1','PracticeManagementCoE','PracticeManagementFarringdonSecure',
'PracticeManagementSecure1','PracticeManagementTraining','PracticeManagement_TaxAid_Release','PracticeManagement1_Release','PracticeManagementCoE_Staging',
'PracticeManagementFarringdonSecure_Release','PracticeManagementSecure1_Release','PracticeManagementTraining_Release')

[string[]]$DPTDatabaseNames = ('TaxyWin_TaxAid','TaxyWin1','TaxyWinCOE','TaxyWinFarringdonSecure',
'TaxyWinSecure1','TaxyWinTraining','TaxyWin_TaxAid_Release','TaxyWin1_Release','TaxyWinCOE_Staging',
'TaxyWinFarringdonSecure_Release','TaxyWinSecure1_Release','TaxyWinTraining_Release')

[string]$SQLCluster = "UKIXESQL023\DB01"

#>