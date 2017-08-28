function Get-Neo4jHeader {
    [cmdletbinding()]
    param($Credential)
    # Thanks to Bloodhound authors, borrowed their code!
    $Base64UserPass = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes( $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password ) ) )
    @{
        Authorization = "Basic $Base64UserPass"
        'Content-Type' = 'application/json'
        Accept = 'application/json; charset=UTF-8'
    }
}
