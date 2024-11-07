$LocalTempDir = $env:TEMP; 

$ChromeInstaller = "ChromeInstaller.exe"; 

$URI = "http://dl.google.com/chrome/install/375.126/chrome_installer.exe"

$DefaultProxy=[System.Net.WebRequest]::DefaultWebProxy;

$securityProtocol=@();

$securityProtocol+=[Net.ServicePointManager]::SecurityProtocol;

$securityProtocol+=[Net.SecurityProtocolType]::Tls12;

[Net.ServicePointManager]::SecurityProtocol=$securityProtocol;

$WebClient=New-Object Net.WebClient; 

if($DefaultProxy -and (-not $DefaultProxy.IsBypassed($URI))){$WebClient.Proxy= New-Object Net.WebProxy($DefaultProxy.GetProxy($URI).OriginalString, $True);};

$WebClient.DownloadFile($Uri, "$LocalTempDir\$ChromeInstaller");

& "$LocalTempDir\$ChromeInstaller" /silent /install; 

$Process2Monitor = "ChromeInstaller"; 

Do { 
    $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | `
        Select-Object -ExpandProperty Name; 
        
        If ($ProcessesFound) { 
            "Still running: $($ProcessesFound -join ', ')" | `
            Write-Host; Start-Sleep -Seconds 2 
        } 
        
        else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } 
    } 
    Until (!$ProcessesFound)