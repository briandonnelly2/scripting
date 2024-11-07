$OfflineDeployment_OfflineVariablePrefix = "TTGOFFLINE_"
$OfflineDeployment_TfBuildVariable = "TF_BUILD"
$OfflineDeployment_LineBreak = "``br``"
$OfflineDeployment_OfflineDeploymentEnabledParam = "OfflineDeploymentEnabled"
$OfflineDeployment_OfflineTaskScriptParam = "OfflineTaskScript"

Function Get-OfflineDeploymentParameter {

    <#

    .SYNOPSIS
    Gets an offline deployment parameter

    .PARAMETER Name
    The name of the parameter to get

    #>

    [CmdletBinding()]
    param(
        [string]$Name
    )

    $variableName = "$OfflineDeployment_OfflineVariablePrefix$Name"

    $value = [System.Environment]::GetEnvironmentVariable($variableName)

    if ($value -ne $null) {
        return $value.Replace($OfflineDeployment_LineBreak,"`n")
    }

    return $value
}

Function Get-OfflineDeploymentEnabled {

    <#

    .SYNOPSIS
    Gets whether an offline deployment is enabled

    #>

    [CmdletBinding()]
    param()

    return ((Get-OfflineDeploymentParameter -Name $OfflineDeployment_OfflineDeploymentEnabledParam) -eq 'true')

}

Function Set-OfflineDeploymentParameter {

    <#

    .SYNOPSIS
    Sets an offline deployment parameter

    .PARAMETER Name
    The name of the parameter to set

    .PARAMETER Value
    The string value to set

    .PARAMETER Append
    If set, the value will be appended to any existing value, with a line break

    .PARAMETER ReturnOfflineDeploymentEnabled
    If set, return a flag to identify whether offline deployments are enabled

    #>

    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Value,
        [switch]$Append,
        [switch]$ReturnOfflineDeploymentEnabled
    )

    $variableName = "$OfflineDeployment_OfflineVariablePrefix$Name"

    $valueToSet = [System.Environment]::GetEnvironmentVariable($variableName)

    if ($valueToSet -eq $null -or !$Append) {
        $valueToSet = $Value
    } else {
        $valueToSet = ("$valueToSet$OfflineDeployment_LineBreak$Value")
    }

    # If in Team Foundation build, set the VSO variable to allow sharing between tasks
    if ([System.Environment]::GetEnvironmentVariable($OfflineDeployment_TfBuildVariable) -eq 'True') {
        Write-Host "##vso[task.setvariable variable=$variableName;]$valueToSet"
    }

    [System.Environment]::SetEnvironmentVariable($variableName, $valueToSet)

    if ($ReturnOfflineDeploymentEnabled) {
        return (Get-OfflineDeploymentEnabled)
    }

    return $null
}

Function Clear-OfflineDeploymentVariables {

    <#

    .SYNOPSIS
    Clears all offline deployment variables

    #>

    [CmdletBinding()]
    param()

    Get-ChildItem env: | Where-Object { $_.Name.StartsWith($OfflineDeployment_OfflineVariablePrefix) } | ForEach-Object { Set-OfflineDeploymentParameter -Name ($_.Name.Substring($OfflineDeployment_OfflineVariablePrefix.Length)) }

}

Function Set-OfflineDeploymentTaskScript {

    <#

    .SYNOPSIS
    Sets a new line on an offline deployment task script. Returns a flag identifying if offline deployments are enabled.

    .PARAMETER Script
    A script line to append to the offline deployment task script

    .PARAMETER TaskName
    A task name, used in conjunction with InvocationName to write out the parameters required to run the script

    .PARAMETER InvocationName
    The invocation name, the name of the function or script (as '.\Script.ps1'). Using $MyInvocation.InvocationName is much easier!

    .PARAMETER ParameterReplacements
    A hashtable of parameters to act as replacements for sensitive variables. Null values will not write the parameter.

    .PARAMETER RequiredParameterReplacements
    An array of parameter replacements that are required. The value will then always be included whether or not it's been provided in the invocation.

    .PARAMETER ReturnOfflineDeploymentEnabled
    If set, a boolean value will be returned to identify if offline deployments are enabled or not.

    #>

    [CmdletBinding()]
    param(
        [string]$Script,
        [string]$TaskName,
        [string]$InvocationName = $MyInvocation.PSCommandPath,
        [hashtable]$ParameterReplacements = @{},
        [string[]]$RequiredParameterReplacements = @(),
        [switch]$ReturnOfflineDeploymentEnabled
    )

    if (![string]::IsNullOrEmpty($Script)) { 
        Set-OfflineDeploymentParameter -Name $OfflineDeployment_OfflineTaskScriptParam -Value $Script -Append
    }

    if (![string]::IsNullOrWhiteSpace($TaskName) -and ![string]::IsNullOrWhiteSpace($InvocationName)) {
        if ($InvocationName.Contains('\')) {
            $scriptLine = '& "$TtgReleaseTasksExtensionPath\' + "$TaskName$($InvocationName.Substring($InvocationName.LastIndexOf('\')))" + '"'
        } else {
            $scriptLine = $InvocationName
        }

        $ParameterList = (Get-Command -Name $InvocationName).Parameters;
        foreach ($key in $ParameterList.Keys)
        {
            $parameterRequired = $RequiredParameterReplacements.Contains($key)
            $replacementExists = $ParameterReplacements.ContainsKey($key)
            if ($replacementExists -and $ParameterReplacements[$key] -eq $null) {
                # This parameter is hidden
                continue
            }

            $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
            $value = $null

            if($var -eq $null -or $var.Value -eq $null -or $var.Value -eq "") {
                if (!$parameterRequired -or !$replacementExists) {
                    continue
                }
            } else {
                $value = $var.Value.ToString()
            }

            if ($replacementExists)
            {
                $value = $ParameterReplacements[$key].ToString()
            }

            if ($value -notmatch '^\S+$') {
                $value = '"' + $value.Replace("`n",'`n') + '"'
            }

            $scriptLine += " -$($key) $value"
        }

        Set-OfflineDeploymentParameter -Name $OfflineDeployment_OfflineTaskScriptParam -Value $scriptLine -Append
    }

    if ($ReturnOfflineDeploymentEnabled) {
        return Get-OfflineDeploymentEnabled
    }
}

Function Get-OfflineDeploymentTaskScript {

    <#

    .SYNOPSIS
    Gets the current offline deployment task script 

    #>

    return Get-OfflineDeploymentParameter -Name $OfflineDeployment_OfflineTaskScriptParam

}