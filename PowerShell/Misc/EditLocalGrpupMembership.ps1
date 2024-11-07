#Credentials
$Credentials = Get-Credential -Message "Enter your oper account details..."

#UAT Servers
$UATServers = @("UKVMSWEB064", "UKVMUWEB1005")

#Live Servers
$LiveServers = @("UKVMSWEB065", "UKVMSWEB066")

$Sessions = New-PSSession -ComputerName $UATServers -Credential $Credentials

$Sessions | Remove-PSSession

$Sessions = $null

#Get group membership
$CurrentAdminGroupMembers = Invoke-Command -Session $Sessions -ScriptBlock { Get-LocalGroupMember -Name "Administrators" }
$CurrentRDSGroupMembers = Invoke-Command -Session $Sessions -ScriptBlock { Get-LocalGroupMember -Name "Remote Desktop Users" }
$CurrentEVTGroupMembers = Invoke-Command -Session $Sessions -ScriptBlock { Get-LocalGroupMember -Name "Event Log Readers" }

$CurrentAdminGroupMembers | ft
$CurrentRDSGroupMembers | ft
$CurrentEVTGroupMembers | ft
#Add group members
Invoke-Command -Session $Sessions -ScriptBlock { Add-LocalGroupMember -Member "UK-SG PR-OP PROD-ACE" -Name Administrators }

Invoke-Command -Session $Sessions -ScriptBlock { Add-LocalGroupMember -Member "UK-SG RO-OP PROD-ACE" -Name "Remote Desktop Users" }

Invoke-Command -Session $Sessions -ScriptBlock { Add-LocalGroupMember -Member "UK-SG RO-OP PROD-ACE" -Name "Event Log Readers" }


#Remove group members
Invoke-Command -Session $Sessions -ScriptBlock { Remove-LocalGroupMember -Member "-oper-pmulcare" -Name Administrators }

Invoke-Command -Session $Sessions -ScriptBlock { Remove-LocalGroupMember -Member "UK-SG_TTG_ADMIN" -Name Administrators }

Function Edit-LocalGroupMembers {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string[]]$ServerNames,

        [Parameter()]
        [string[]]$GroupNames,

        [Parameter(Mandatory)]
        [ValidateRange(1,5)]
        [int]$Function,

        [Parameter()]
        [pscredential]$Credentials
    )



    #Resolve server names passed in and verify these are available
    foreach($Server in $ServerNames) {
       If($true -eq ( ( Test-NetConnection -ComputerName $Server).PingSucceeded) ) {
        $Sessions = New-PSSession -ComputerName $LiveServers -Credential $Credentials
            Write-Information -MessageData ("Ping Successful against " + $Server)
        }
    }

    #Switch statement to see if new grouos need added 
    switch ($Function) {
        1 { }
        2 { #Add new security groups
            foreach($Server in $ServerNames) {
                $Session | Remove-PSSession
                $Session = New-PSSession -ComputerName $Server -Credential $Credentials
                
                foreach($Group in $GroupNames) {
                    If($Group -like '*-RO-*') { 
                        Invoke-Command -Session $Sessions -ScriptBlock { Add-LocalGroupMember -Member "UK\$Group" -Name "Remote Desktop Users" }
                        Invoke-Command -Session $Sessions -ScriptBlock { Add-LocalGroupMember -Member "UK\$Group" -Name "Event Log Viewers" }
                     }
                    Elseif($Group -like '*-PR-*') { 
                        Invoke-Command -Session $Sessions -ScriptBlock { Add-LocalGroupMember -Member "UK\$Group" -Name "Administrators" }
                     }
                    Else { throw "Do Nothing" }
                }
            }
         }
        3 { }
        4 { }
        5 { }
        Default { }
    }
}