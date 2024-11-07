# Load WinSCP .NET assembly 
Set-Location -Path PSScriptRoot
Unblock-File -Path ".\WinSCP.exe"
Unblock-File -Path ".\WinSCPnet.dll"
Add-Type -Path ".\WinSCPnet.dll"

# Setup session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = "delivery.interactivedata.com"
    UserName = "cch00033"
    Password = "p9q4w3Y0"
}

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Download files
    $session.GetFiles("/*", "C:\Users\briandonnelly2\OneDrive - KPMG\Working Folder\CCH\EXSHARE Data Feed Updates\Exshare Data Feed Files\*").Check()
}
finally
{
    # Disconnect, clean up
    $session.Dispose()
}

# Event handling function
function FileTransferred {
    param($e)
 
    if ($e.Error -eq $Null)
    {
        Write-Host "Transfer of $($e.FileName) succeeded"
    }
    else
    {
        Write-Host "Transfer of $($e.FileName) failed: $($e.Error)"
    }
}
 
# Subscribe to the event
$session.add_FileTransferred( { FileTransferred($_) } )

#There is a third-party PowerShell module, WinSCP PowerShell Wrapper, that provides a cmdlet interface on top of the .NET assembly. 
# Set credentials to a PSCredential Object.
$credential = Get-Credential
# Create a WinSCP Session.
$session = New-WinSCPSession -Hostname "example.com" -Credential $credential -SshHostKeyFingerprint "ssh-rsa 2048 xxxxxxxxxxx...="
# Using the WinSCPSession, download the file from the remote host to the local host.
Receive-WinSCPItem -WinSCPSession $session -Path "/home/user/file.txt" -Destination "C:\download\"
# Remove the WinSCPSession after completion.
Remove-WinSCPSession -WinSCPSession $session

#Accomplish the same task with one line of code: 
# Piping the WinSCPSession into the Receive-WinSCPItem auto disposes the WinSCP.Session object after completion.
New-WinSCPSession -Hostname "example.com" -Credential (Get-Credential) -SshHostKeyFingerprint "ssh-rsa 2048 xxxxxxxxxxx...=" | 
     Receive-WinSCPItem -Path "/home/user/file.txt" -Destination "C:\download\"

try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = "example.com"
        UserName = "user"
        Password = "mypassword"
        SshHostKeyFingerprint = "ssh-rsa 2048 xxxxxxxxxxx...="
    }
 
    $session = New-Object WinSCP.Session
 
    try
    {
        # Connect
        $session.Open($sessionOptions)
 
        # Upload files
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
 
        $transferResult =
            $session.PutFiles("d:\toupload\*", "/home/user/", $False, $transferOptions)
 
        # Throw on any error
        $transferResult.Check()
 
        # Print results
        foreach ($transfer in $transferResult.Transfers)
        {
            Write-Host "Upload of $($transfer.FileName) succeeded"
        }
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }
 
    exit 0
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}