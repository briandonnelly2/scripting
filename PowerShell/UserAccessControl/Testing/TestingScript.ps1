Import-Module -Name KPMGUserAccessManagement

#region Tests for Add-KPMGGroupMember

$Username = '-oper-briandonnelly2'
$BadUsername = '-oper-briandonnel'
$GroupName = 'UK-SG PR-DA UAT ACE'
$BadGroupName = 'UK-SG PR-DA UAT'

    #tests when user and group names do not exist
    Add-KPMGGroupMember -Username $Username -GroupName $BadGroupName
    #expected result: The username, $BadUsername and group name, $BadGroupName cannot be found.

    #tests when user does not exist
    Add-KPMGGroupMember -Username $BadUsername -GroupName $GroupName
    #expected result: The username, $BadUsername cannot be found.

    #tests when group does not exist
    Add-KPMGGroupMember -Username $Username -GroupName $BadGroupName
    #expected result: The group name, $BadGroupName cannot be found.

    #tests when the user is successfully added as a member of the group
    Add-KPMGGroupMember -Username $Username  -GroupName $GroupName
    #expected result: The user $Username was added to the security group $GroupName successfully

    #tests when the user is already a member of the group
    Add-KPMGGroupMember -Username $Username -GroupName $GroupName
    #expected result: The user, $Username is already a member of $GroupName so no further action is required

#endregion Tests for Add-KPMGGroupMember

#region Tests for Remove-KPMGGroupMember

    $Username = '-oper-briandonnelly2'
    $BadUsername = '-oper-briandonnel'
    $GroupName = 'UK-SG PR-DA UAT ACE'
    $BadGroupName = 'UK-SG PR-DA UAT'

    #tests when user and group names do not exist
    Remove-KPMGGroupMember -Username $BadUsername  -GroupName $BadGroupName 
    #expected result: The username, $BadUsername and group name, $BadGroupName cannot be found.

    #tests when user does not exist
    Remove-KPMGGroupMember -Username $BadUsername -GroupName $GroupName
    #expected result: The username, $BadUsername cannot be found.

    #tests when group does not exist
    Remove-KPMGGroupMember -Username $Username -GroupName $BadGroupName 
    #expected result: The group name, $BadGroupName cannot be found.

    #tests when the user is not a member of the group already
    Remove-KPMGGroupMember -Username $Username -GroupName $GroupName
    #expected result: The username, $Username is not currently a member of $GroupName so no further action is required

    #tests when the user is successfully removed as a member of the group
    Remove-KPMGGroupMember -Username $Username -GroupName $GroupName
    #expected result: The user $Username was removed from the security group $GroupName successfully

    #tests when the 'EmptyGroup' switch is used to empty all users from a group (should leave nested groups intact)
    Remove-KPMGGroupMember -GroupName $GroupName -EmptyGroup:$true
    #expected result: The following 3 users were removed from the security group $GroupName : Test User 1 Test User 2 Test User 3

    #tests when the 'EmptyGroup' switch is used on a group with no members at all
    Remove-KPMGGroupMember -GroupName $GroupName -EmptyGroup:$true
    #expected result: The security group $GroupName did not contain any users at this time.  Nothing has been modified.

    #tests when the 'EmptyGroup' switch is False, but a username has also not been supplied
    Remove-KPMGGroupMember -GroupName $GroupName -EmptyGroup:$false
    #expected result: A username was not supplied and the EmptyGroup parameter was false, therefore the command cannot continue

#endregion Tests for Remove-KPMGGroupMember

#region Tests for Get-KPMGPriorApproval

#Where the user has no prior approval
$Username = 'briandonnelly2'
$App = 'Digita'
$Env = 'UAT'
$Infra = 'Databases'
$Path = 'C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\ps-kpmg\UserAccessControl\Config\ApprovalHistory.csv'

Get-KPMGPriorApproval -Username $Username -App $App -Env $Env -Infra $Infra -FilePath $Path -Verbose

#Where the user has prior approval
$Username = 'briandonnelly2'
$App = 'ACE'
$Env = 'UAT'
$Infra = 'Databases'
$Path = 'C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\ps-kpmg\UserAccessControl\Config\ApprovalHistory.csv'

Get-KPMGPriorApproval -Username $Username -App $App -Env $Env -Infra $Infra -FilePath $Path -Verbose

#endregion Tests for Get-KPMGPriorApproval

#region Tests for Get-KPMGSecurityGroupName

$Username = 'briandonnelly2'
$App = 'Digita'
$Env = 'UAT'
$Infra = 'Databases'
$Path = 'C:\Users\briandonnelly2\OneDrive - KPMG\Scripts\ps-kpmg\UserAccessControl\Config\ApprovalHistory.csv'

#endregion Tests for Get-KPMGSecurityGroupName

Remove-Module -Name KPMGUserAccessManagement