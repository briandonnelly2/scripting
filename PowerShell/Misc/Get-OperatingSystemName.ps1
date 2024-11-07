$Credentials = Get-Credential -UserName "UK\-oper-briandonnelly2" -Message "p"

$ComputerNames = Get-Content -Path C:\Users\-oper-briandonnelly2\Desktop\servers.txt

foreach($Computer IN $ComputerNames) { 
    $servers += @($Computer.Trim('.uk.kworld.kpmg.com'))

}

$servers
foreach($server IN $servers) { 
    Invoke-Command -ComputerName $server `
        -ScriptBlock { `
            $OSVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName

            $returnObj = New-Object System.Object
            $returnObj | Add-Member -Type NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
            $returnObj | Add-Member -Type NoteProperty -Name GroupName -Value $OSVersion

            Write-Output $returnObj
        } | Export-Csv -Path C:\Users\-oper-briandonnelly2\Desktop\OS.csv -Append -Force
 }