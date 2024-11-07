<#
.SYNOPSIS
    Helper methods to process and compare all gathered information
.DESCRIPTION
    These methods are used to process the data that has been output 
    from the gathering information phase of execution.
.NOTES
    Version:                1.0
    Author:                 Brian Donnelly
    Creation Date:          20 February 2019
    Modified Date:          N/A
    Revfiew Date:           20 May 2019
    Future Enhancements:    
#>

<# Import all reports that were produced #>
[System.Object]$LocalGroupInfo = Import-Csv -Path "C:\Users\briandonnelly2\Documents\Reports\19-03-01\csv\UKDomain-01-03-2019-briandonnelly2-TC-Workflow-Local-SG-Report.csv"
[System.Object]$SequenceUsers = Import-Csv -Path ".\output\sequence-user-tables-permissions.csv"
[System.Object]$PortalUsers = Import-Csv -Path ".\output\portal-user-tables-permissions.csv"


$Groups = $LocalGroupInfo | Where-Object -Property GroupName -IN ('Administrators','Remote Desktop Users','Event Log Readers')
[System.Object]$OperAccounts = @()
[System.Object]$SvcAccounts = @()
[System.Object]$AdmAccounts = @()
[System.Object]$NonCompliant = @()
[System.Object]$Compliant = @()
[System.Object]$Exempt = @()

[System.Object]$SequenceGlobalAdmins = @()
[System.Object]$PortalGlobalAdmins = @()
#$SequenceUsers.Count
#$PortalUsers.Count

<# Validates local group data against what is specified in the config files. #>
foreach( $Member IN $Groups ) {
    # users/groups who have exemptions in the config
    If( ( $Member.Name -IN $global.exemptgroups ) -or ( $Member.Name -IN $global.exemptusers ) ) { $Exempt += $Member }
    #user account -  no exemption - non-compliant
    ElseIf( $Member.Type -eq 'User' ) {
        #Pulls out privileged accounts
        If( $Member.Name -like 'oper*' ) { $OperAccounts += $Member }
        #Pulls out privileged accounts
        ElseIf( $Member.Name -like 'adm-*' ) { $AdmAccounts += $Member }
        #Pulls out service accounts
        ElseIf( $Member.Name -like '*svc-*' ) { $SvcAccounts += $Member }
        #anything else is non-compliant
        Else { $NonCompliant += $Member }
    }
    #If this is a group...
    ElseIf ( $Member.Type -eq 'Group' ) {
        #If the group is a member of the local admins group...
        If( ( $Member.GroupName -eq 'Administrators' ) ) { 
            #Validates privileged application group is a member of local admins
            If( $Member.Name -eq $EnvInfo.srvadminsg ) { $Compliant += $Member }
            #Validates read-only & database priivileged application groups are a member of local admins
            ElseIf( $Member.Name -IN ( $EnvInfo.srvreadonlysg, $EnvInfo.dbadminsg, $EnvInfo.dbreadonlysg ) ) { $NonCompliant += $Member }
            #anything else is non-compliant
            Else { $NonCompliant += $Member }
        }
        #If the group is a member of the Remote Desktop Users group...
        ElseIf( ( $Member.GroupName -eq 'Remote Desktop Users' ) ) {
            #Validates read-only application group is a member of remote desktop users
            If( $Member.Name -eq $global.srvreadonlysg ) { $Compliant += $Member }
            #anything else is non-compliant
            Else { $NonCompliant += $Member }
        }
        #If the group is a member of the Event Log Readers group...
        ElseIf( $Member.Type -eq 'Event Log Readers' ) {
            #Validates read-only application group is a member of Event Log Readers
            If( $Member.Name -eq $global.srvreadonlysg ) { $Compliant += $Member }
            #anything else is non-compliant
            Else { $NonCompliant += $Member }
        }
        #anything else is non-compliant
        Else { $NonCompliant += $Member }
    }
    #anything else is non-compliant
    Else { $NonCompliant += $Member }
}
<# Validates database data against what is specified in the config files. #>
foreach( $SequenceUser IN $SequenceUsers ) {
    If( ( $SequenceUser | Select-Object -ExpandProperty fldGlobalAdmin ) -eq 1 ) {
        $SequenceGlobalAdmins += $SequenceUser
    }
    Else {  }
}

foreach( $PortalUser IN $PortalUsers ) {
    If( ( $PortalUser | Select-Object -ExpandProperty RoleName ) -eq "Global Admin" ) {
        $PortalGlobalAdmins += $PortalUser
    }
    Else {  }
}


<# 
#$Roles
#$PortalUsers | Select-Object -ExpandProperty RoleName -Unique | ForEach-Object -Process {  } 

$PortalGlobalAdmins | Export-Csv -Path ($FileExportPath + "\" + $CsvPrefix + "-" + $EnvInfo.name + "-PortalGlobalAdmins.csv")
$SequenceGlobalAdmins | Export-Csv -Path ($FileExportPath + "\" + $CsvPrefix + "-" + $EnvInfo.name + "-SequenceGlobalAdmins.csv")
$OperAccounts | Select-Object -Property GroupName, ComputerName, Name, Type | `
    Export-Csv -Path ($FileExportPath + "\" + $CsvPrefix + "-" + $EnvInfo.name + "-OperAccounts.csv")
$SvcAccounts | Select-Object -Property GroupName, ComputerName, Name, Type | `
    Export-Csv -Path ($FileExportPath + "\" + $CsvPrefix + "-" + $EnvInfo.name + "-SvcAccounts.csv")

$NonCompliant | Select-Object -Property GroupName, ComputerName, Name, Type | Export-Csv -Path ($FileExportPath + "\" + $CsvPrefix + "-" + $EnvInfo.name + "-non-compliant.csv")

$Compliant | Format-Table

$Exempt | Select-Object -Property GroupName, ComputerName, Name, Type | `
Export-Csv -Path ($FileExportPath + "\" + $CsvPrefix + "-" + $EnvInfo.name + "-ExemptAccounts.csv") #>