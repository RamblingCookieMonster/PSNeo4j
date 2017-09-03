function Get-Neo4jHeader {
    [cmdletbinding()]
    param(
        $Credential = $PSNeo4jConfig.Credential,
        [string]$ContentType = 'application/json',
        [string]$Accept = 'application/json; charset=UTF-8'
    )
    # Thanks to Bloodhound authors, borrowed their code!
    $Base64UserPass = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes( $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password ) ) )
    $Headers = @{ Authorization = "Basic $Base64UserPass" }
    if($ContentType) {
        $Headers.Add('Content-Type', $ContentType)
    }
    if($Accept) {
        $Headers.Add('Accept', $Accept)
    }
    $Headers
}
