function Get-Neo4jHeader {
    <#
    .SYNOPSIS
       Generate a header for the Neo4j API call

    .DESCRIPTION
       Generate a header for the Neo4j API call

    .EXAMPLE
        Get-Neo4jHeader -Credential $Credential

    .PARAMETER Credential
        Credential to use in the header.  Note that the output is insecure (base64 based)

    .PARAMETER ContentType
        Content-Type for the header.  Defaults to 'application/json'

    .PARAMETER Accept
        Accept for the header.  Defaults to 'application/json; charset=UTF-8'

    .PARAMETER Streaming
        Transmits responses from HTTP API as JSON streams (better performance, lower memory overhead on the server)

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = $PSNeo4jConfig.Credential,
        [string]$ContentType = 'application/json',
        [string]$Accept = 'application/json; charset=UTF-8',
        [bool]$Streaming = $PSNeo4jConfig.Streaming
    )
    # Thanks to Bloodhound authors, borrowed their code!
    $Headers = @{}
    if($Credential -ne [System.Management.Automation.PSCredential]::Empty)
    {
        $Base64UserPass = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes( $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password ) ) )
        $Headers.add('Authorization', "Basic $Base64UserPass")
    }
    if($ContentType) {
        $Headers.Add('Content-Type', $ContentType)
    }
    if($Accept) {
        $Headers.Add('Accept', $Accept)
    }
    if($Streaming) {
        $Headers.Add('X-Stream', $True)
    }
    $Headers
}
