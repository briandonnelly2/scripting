

Get-RDRemoteApp -CollectionName 'CCH Suite Applications (UAT)' -Alias 'MapCCHTrustAccountsDrive' | Set-RDRemoteApp -ShowInWebAccess 1

$Output = ( Get-RDRemoteApp -CollectionName 'CCH Suite Applications (UAT)' -Alias 'MapCCHTrustAccountsDrive' | `
            Select-Object -Property ShowInWebAccess ).ShowInWebAccess

If ( $Output = 'False' ) {
    Return 'Success'
} Else {
    Return 'Failed'
}