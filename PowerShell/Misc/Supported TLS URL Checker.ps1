<#
Created by: whall
Date Created: 3/25/2020

Product Area Tags: Connectivity

Technology Tags: SSL TLS

Use Case: 
Shows which version(s) of TLS is supported for a URL

Description: 
When you run this, it checks each TLS type connection to see if it is supported.
Updated 4/2/2021 to still show TLS status when there is an HTTP error response, and simplified calls
Updated 4/9/2021 to show redirects it follows. This allows for better troubleshooting of the source of a TLS error.

Parameters:
-url this is the URL of the site you are testing against

Keywords: sockets secure https

Code Example Disclaimer:
Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED 'AS IS'
-This is intended as a sample of how code might be written for a similar purpose and you will need to make changes to fit to your requirements. 
-This code has not been tested.  This code is also not to be considered best practices or prescriptive guidance.  
-No debugging or error handling has been implemented.
-It is highly recommended that you FULLY understand what this code is doing  and use this code at your own risk.

#>

#TLS check
param([Parameter(Mandatory=$true)][string]$url,[switch]$followRedirect)

function followRedirects([string] $redirectUrl){
    $resp3 = $null
    try{
        $resp3 = Invoke-WebRequest -uri $redirectUrl -Method GET -MaximumRedirection 0 -ErrorAction SilentlyContinue -ErrorVariable curError  -DisableKeepAlive
        $redirectURI = [uri]::new($redirectUrl)
        if($resp3.StatusCode -eq 302 -or $resp3.StatusCode -eq 301){
            if($followRedirect){
                $redirLocation = $resp3.Headers["Location"]
                Write-Host "Redirected to:" $($redirLocation)
                if($redirLocation.IndexOf(https://) -eq -1){   
                    $redirLocation = "{0}://{1}{2}" -f $redirectUri.Scheme, $redirectURI.Host,[System.Net.WebUtility]::UrlDecode($redirLocation)
                }
                followRedirects $redirLocation
            }else{ Write-Host "TLS/SSL $TLSversion supported" -ForegroundColor green }
        }else{
            Write-Host "TLS/SSL $TLSversion supported" -ForegroundColor green
    }
    }catch [System.Net.WebException]{
            [System.Net.WebException]$e =  $_.exception
            if($_.Exception.Response -eq $null -and $_.Exception.InnerException -ne $null){
                Write-Host "TLS/SSL $TLSversion not supported" -ForegroundColor Red

            }else{
                $statCode = [int]$e.response.statusCode
                Write-Host "TLS/SSL $TLSversion supported (response code: $statCode)" -ForegroundColor Green
            }
    }
}

function testTLS([string]$TLSversion){
        $secprotVer = ""
        switch($TLSversion){
            "1.0" {$secprotVer = "Tls"}
            "1.1" {$secprotVer = "Tls11"}
            "1.2" {$secprotVer = "Tls12"}
            "1.3" {$secprotVer = "Tls13"}
            Default { Write-Host "Not supported version: $TLSversion" -ForegroundColor Red; return }

        }

        [System.Net.ServicePointManager]::SecurityProtocol = $secprotVer
        followRedirects $url
}

function TLSAvailable([string]$url){

    Write-Host =======================
    Write-Host $url
    Write-Host =======================
    
    $TLSversions2test = "1.0","1.1","1.2","1.3"

    $TLSversions2test |%{testTLS -TLSversion $_}
    Write-Host =======================

}

$savedSetting = [System.Net.ServicePointManager]::SecurityProtocol

TLSAvailable -url $url

[System.Net.ServicePointManager]::SecurityProtocol = $savedSetting 
Write-Host
Write-Host ".NET TLS setting:" $savedSetting

#these URLs can be used to test against TLS versions
#$urls = @(https://tls-v1-0.badssl.com:1010/, https://tls-v1-1.badssl.com:1011/, https://tls-v1-2.badssl.com:1012/)
#$urls|%{ TLSAvailable -url $_; }
