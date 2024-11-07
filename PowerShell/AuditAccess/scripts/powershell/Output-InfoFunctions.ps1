Param(
    # Parameter help description
    [Parameter(required = $true)]
    [string]$ReportName,

    # Parameter help description
    [Parameter(required = $true)]
    [string]$ReportPath
)

#region head
$Head = @"
<style>
body { 
    background-color:#FFFFCC;
    font-family:Tahoma;
    font-size:10pt; 
}

td, th 
{ 
    border:1px solid #000033; 
    border-collapse:collapse; 
}
th 
{ 
    color:white;
    background-color:#000033; 
}
table, tr, td, th 
{ 
    padding: 0px; margin: 0px 
}
table 
{ 
    margin-left:8px; 
}
</style>
<Title>$Title</Title>
"@ 
#endregion head

#define an array for html fragments
$Fragments = @()
$Fragments += "<H2>Local Groups Compliance</H2>"

#get the drive data
$OperAccounts

$SvcAccounts

$AdmAccounts

$NonCompliant

$Compliant

$Exempt

$SequenceGlobalAdmins

$PortalGlobalAdmins

$UserData = $OperAccounts
#$GroupData = $SvcAccounts


#group data by computername
$Groups = $UserData | Group-Object -Property ComputerName

#create html fragments for each computer
#iterate through each group object
        
ForEach ($computer in $groups) {
    
    $fragments+="<H3>$($computer.Name)</H3>"

    $fragments+="<p>The following user accounts should not be in the respective groups</p>"
    
    #define a collection of Users from the group object
    $Users=$computer.group
    
    #create an html fragment
    $html = $Users | Select-Object @{Name="Local Group";Expression={$_.GroupName}},
                        @{Name="Account Type";Expression={$_.Type}},
                        @{Name="Account Name";Expression={$_.Name}} | `
                        ConvertTo-Html -Fragment 
        
    #add to fragments
    $Fragments += $html
    
    #insert a return between each computer
    $fragments += "<br>"
    
} #foreach computer

#add a footer
$footer=("<br><I>Report run {0} by {1}\{2}<I>" -f (Get-Date -displayhint date),$env:userdomain,$env:username)
$fragments+=$footer

#write the result to a file
ConvertTo-Html -head $head -body $fragments  | Out-File .\test.htm -Encoding ascii

Invoke-Item .\test.htm


$TCGroup = "UK\UK-SG PR-OP PROD-WorkflowTC"
$PAGroup = "UK\UK-SG PR-OP PROD-WorkflowPA"
$UATGroup = "UK\UK-SG PR-OP UAT-Workflow"

$credential = Get-Credential -UserName "UK\-oper-briandonnelly2" -Message "Password please..."

$session = New-PSSession -ComputerName "UKVMSAPP031" -Credential $credential


$SB={Add-LocalGroupMember -Group "Administrators" -Member $UATGroup}

Invoke-Command -Session $session -ScriptBlock $SB -Verbose

Get-PSSession | Remove-PSSession