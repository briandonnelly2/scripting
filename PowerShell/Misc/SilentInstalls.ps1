#Path to Azure CLI installer
$AzureCLI = 'E:\Shares\TPL Deployment Share\Useful Files\Azure CLI v2.19.1\azure-cli-2.19.1.msi'
#Path to .NET Hosting bundle installer
$NETCore = 'E:\Shares\TPL Deployment Share\Useful Files\.NET Hosting Bundle v5.0.3\dotnet-hosting-5.0.3-win.exe'
#Path to .NET Framework Installer
#$NETFW = 'E:\Shares\TPL Deployment Share\Useful Files\.NET 4.8\ndp48-x86-x64-allos-enu.exe'

#An array of servers to install the software on
$Computers = 'UKVMPAPP1106', 'UKVMPAPP1107', 'UKVMPAPP1108'

#Scriptblock that will install the Azure CLI
$AzureCLIScriptBlock = { Start-Process -FilePath Msiexec.exe -Wait -ArgumentList '/i "C:\TEMP\azure-cli-2.19.1.msi" /qn' }
#Scriptblock that will install the .NET Hosting bundle
$DotnetHostingScriptBlock = { Start-Process -FilePath 'C:\TEMP\dotnet-hosting-5.0.3-win.exe' -Wait -ArgumentList '/passive' }
#Scriptblock that will install the .NET Framework
#$DotnetFWScriptBlock = { Start-Process -FilePath 'C:\TEMP\ndp48-x86-x64-allos-enu.exe'  -Wait -ArgumentList '/q, /norestart' }

#Foreach loop
foreach($Computer in $Computers) {
    Copy-Item -Path $AzureCLI -Destination "\\$Computer\C$\TEMP\" -Force

    Write-Host 'Copied Azure CLI installer to '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    Invoke-Command -ScriptBlock $AzureCLIScriptBlock -ComputerName $Computer

    Write-Host 'Installed Azure CLI on '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    Remove-Item -Path "\\$Computer\C$\TEMP\azure-cli-2.19.1.msi" -Force

    Write-Host 'Removed Azure CLI installer '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    Copy-Item -Path $NETCore -Destination "\\$Computer\C$\TEMP\" -Force

    Write-Host 'Copied .NET Hosting installer to '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    Invoke-Command -ScriptBlock $DotnetHostingScriptBlock -ComputerName $Computer

    Write-Host 'Installed .NET Hosting bundle on '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    Remove-Item -Path "\\$Computer\C$\TEMP\dotnet-hosting-5.0.3-win.exe" -Force

    Write-Host 'Removed Azure CLI installer '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    Write-Host 'Checking for ADO Agent on '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 

    If($null -eq (Get-Service -ComputerName $Computer | Where-Object -Property 'Name' -like 'vstsagent*')) {
        'Agent not installed on ' + $Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 
    }
    Else {
        'Agent is installed on ' + $Computer | Out-File -FilePath $HOME/Desktop/agentinstalled.txt -Append -Force 
    }

    Write-Host 'Process complete for '$Computer | Out-File -FilePath $HOME/Desktop/SIlentInstallLog.txt -Append -Force 
}
<#
    Copy-Item -Path $NETFW -Destination "\\$Computer\C$\TEMP\" -Force

    Invoke-Command -ScriptBlock $DotnetFWScriptBlock -ComputerName $Computer

    Remove-Item -Path "\\$Computer\C$\TEMP\ndp48-x86-x64-allos-enu.exe" -Force
#>