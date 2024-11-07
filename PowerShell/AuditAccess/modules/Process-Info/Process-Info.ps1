Function Get-ServerCompliance {
<#
    .SYNOPSIS
        Checks server compliance for application
    .DESCRIPTION
        Uses the local groups report to check for compliance against supplied application data.
    .PARAMETER LocalSGReportPath
        Parameter that defines the path to the local security group report. 
    .PARAMETER ADAccountReportPath
        Parameter that defines the path to the AD Account Report. 
    .PARAMETER ADUserGroupReportPath
        Parameter that defines the path to the AD User Security Group Membership Report. 
    .NOTES
        Version:                1.0
        Author:                 Brian Donnelly
        Creation Date:          20 February 2019
        Modified Date:          N/A
        Revfiew Date:           20 May 2019
        Future Enhancements:    
#>
    #region Parameters
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory                       =   $True,
            ValueFromPipeline               =   $True,
            ValueFromPipelineByPropertyName =   $true,
            HelpMessage                     =   "Please specify the path to the local SG report." )]
        [string]$LocalSGReport,

        [Parameter(
            Mandatory                       =   $True,
            ValueFromPipeline               =   $True,
            ValueFromPipelineByPropertyName =   $true,
            HelpMessage                     =   "Please specify the path to the AD User Accounts report." )]
        [string]$ADAccountReport,

        [Parameter(
            Mandatory                       =   $True,
            ValueFromPipeline               =   $True,
            ValueFromPipelineByPropertyName =   $true,
            HelpMessage                     =   "Please specify the path to the AD User SG Membership report." )]
        [string]$ADUserGroupReport,

        [Parameter( 
            Mandatory                       =   $true, 
            ValueFromPipeline               =   $true,
            ValueFromPipelineByPropertyName =   $true,
            HelpMessage                     =   "An array of user info hashtables" )]
        [System.Object[]]$CurrentUsers,

        [Parameter( 
            Mandatory                       =   $true, 
            ValueFromPipeline               =   $true,
            ValueFromPipelineByPropertyName =   $true,
            HelpMessage                     =   "Please specify the log file path." )]
        [string]$LogFilePath
    )
    #endregion Parameters

    #region Variables
    <# Imported information #>
    [System.Object]$LocalGroupInfo
    [System.Object]$ADUserAccInfo
    [System.Object]$ADUserGroupInfo

    <# Initial sort #>
    [System.Object]$OperAccounts = @()
    [System.Object]$SvcAccounts = @()
    [System.Object]$AdmAccounts = @()
    [System.Object]$SysAccounts = @()
    [System.Object]$RegAccounts = @()
    [System.Object]$EmptyGroups = @()
    [System.Object]$SecurityGroups = @()

    <# The main categories for evaluating what is found #>
    [System.Object]$InBreach = @()
    [System.Object]$NonCompliant = @()
    [System.Object]$Compliant = @()
    [System.Object]$Exempt = @()

    [string[]]$Fragments = @()
    #endregion Variables

    #region Import Data
    If( (Test-Path -Path $LocalSGReport) -and (Test-Path -Path $ADAccountReport) -and (Test-Path -Path $ADUserGroupReport) ) {
        Try {
            $LocalGroupInfo = Import-Csv -Path $LocalSGReport
            $ADUserAccInfo = Import-Csv -Path $ADAccountReport
            $ADUserGroupInfo = Import-Csv -Path $ADUserGroupReport

            switch ( $true ) {
                ( $null -in $LocalGroupInfo ) {
                    Write-Verbose "The LocalGroupInfo has not been imported."
                }
                ( $null -in $ADUserAccInfo ) {
                    Write-Verbose "The ADUserAccInfo has not been imported."
                }
                ( $null -in $ADUserGroupInfo ) {
                    Write-Verbose "The ADUserGroupInfo has not been imported."
                }
                Default {
                    Write-Verbose "The data has been imported."
                }
            }
        }
        Catch {
            Write-Verbose "There was an issue importing the info files. "
        }
    }
    Else {
        Write-Verbose "Some files do not exist at the supplied path. "
    }
    #endregion Import Data

    #region Full Sort
    foreach( $Member IN $LocalGroupInfo ) {
        <# Stores the comparison values as variables to make life easier. #>
        [string]$AccType = $Member.Type
        [string]$GrpName = $Member.GroupName
        [string]$AccName = $Member.MemberName

        <#
            This is the main comparison switch statement that filters the supplied
            local security group data from the appications hosting servers. I have
            annotated each test case to show what it is checking for. This should 
            allow someone to add/remove test cases as necessary to add funtionality
            or compensate for new requirements. The main split is based on the 'Type'
            field, which specifies the type of account the current member is.
            Enhancements: 
                1. Add in check for -test- accounts
        #>
        switch ( $AccType ) {
            <# Evaluated when member account type is 'User' #>
            "User" {
                <# Nested switch in which the supplied test case must evaluate to true. #>
                switch ( $True ) {
                    <# Stores any Operator accounts found #>
                    ( $AccName -like "*oper-*" ) {
                        $OperAccounts += $Member
                    }
                    <# Stores any Service accounts found #>
                    ( $AccName -like "*svc-*" ) {
                        $SvcAccounts += $Member
                        <# 
                            Records this service account as compliant with baseline if it is 
                            one of the service accounts specified in the baseline.
                        #>
                        If( $AccName -in $EnvInfo.svcaccounts ) {
                            $Compliant += $Member 
                        }
                    }
                    <# Stores any Admin accounts found #>
                    ( $AccName -like "*adm-*" ) {
                        $AdmAccounts += $Member
                    }
                    <# Records user account as exempt from the audit if found in the baseline #>
                    ( $AccName -in $global.exemptusers ) {
                        $Exempt += $Member          
                    }
                    <#
                        This case checks a list of 
                    #>
                    ( ($AccName -in $global.envreadonly) -and ($GrpName -eq "Administrators") ) {
                        $InBreach += $Member                      
                    }

                    ( ($AccName -in $global.envreadonly) -and !($GrpName -eq "Administrators") ) {
                        $NonCompliant += $Member
                        
                    }

                    Default {
                        $RegAccounts += $Member
                        $NonCompliant += $Member
                    }
                }
            }

            "Group" {
                $SecurityGroups += $Member

                If( $AccName -in $global.exemptgroups ) {
                    $Exempt += $Member
                    
                }
                ElseIf( $AccName -in ($EnvInfo.admindatagroup, $EnvInfo.rodatagroup) ) {
                    $NonCompliant += $Member
                    
                }
                switch ( $GrpName ) {
                    "Administrators" {
                        If( $AccName -like "UK-SG RO*" ) {
                            $InBreach += $Member
                            
                        }
                        ElseIf( $AccName -eq $EnvInfo.adminopsgroup ) {
                            $Compliant += $Member
                            
                        }
                        Else { 
                            $NonCompliant += $Member
                            
                        }
                    }

                    "Remote Desktop Users" {
                        If( $AccName -eq $EnvInfo.roopsgroup ) {
                            $Compliant += $Member
                            
                        }
                        Else { 
                            $NonCompliant += $Member
                            
                        }
                    }

                    "Event Log Viewers" {
                        If( $AccName -eq $EnvInfo.roopsgroup ) {
                            $Compliant += $Member
                            
                        }
                        Else { 
                            $NonCompliant += $Member
                            
                        }
                    }

                    Default                 {
                        $NonCompliant += $Member
                        
                    }
                }
            }

            "System" {
                $SysAccounts += $Member
                $Exempt += $Member
            }

            "N/A" {
                $EmptyGroups += $Member
            }

            Default {
                $NonCompliant += $Member
            }   
        }
    }
    #endregion Full Sort

    #region Return Values

    <# Account Variables #>
    $OperFrag = $OperAccounts | Group-Object -Property Server
    $SvcFrag = $SvcAccounts | Group-Object -Property Server

    <# Compliance Variables #>
    $InBreachFrag = $InBreach | Group-Object -Property Server
    $NonCompliantFrag = $NonCompliant | Group-Object -Property Server
    $CompliantFrag = $Compliant | Group-Object -Property Server
    $ExemptFrag = $Exempt | Group-Object -Property Server

    
    #$Fragments= @()
    ForEach ( $Server in $EnvInfo.servers ) {
    
        $CurrentSrv = $NonCompliantFrag | Where-Object -Property Name -EQ $Server | Select-Object -ExpandProperty Group

        $fragments+="<H3>$($Server)</H3>"
    
        $fragments+="<p>The following user accounts should not be in the respective groups</p>"
        
        #define a collection of Users from the group object
        $CurrentSrvUsrs = $CurrentSrv | Where-Object -Property Type -eq "User"
        
        #create an html fragment
        $html = $CurrentSrvUsrs  | Select-Object @{Name="Local Group";Expression={$_.GroupName}}, `
                                                @{Name="Account Name";Expression={$_.MemberName}} | `
                            ConvertTo-Html -Fragment 
            
        #add to fragments
        $Fragments += $html
        
        #insert a return between each computer
        $fragments += "<br>"
        
    } #foreach computer
    #endregion Return Values

}

Function Get-DatabaseCompliance {

}

Function Get-ActiveDirectoryCompliance {

}