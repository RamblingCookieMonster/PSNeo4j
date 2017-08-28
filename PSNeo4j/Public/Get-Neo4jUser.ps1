function Get-Neo4jUser {
[cmdletbinding()]
    param (
        $User = 'neo4j',

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential
    )
    $Params = @{
        Headers = Get-Neo4jHeader -Credential $Credential
        Uri = Join-Parts -Parts $BaseUri, user, $User
    }
    Write-Verbose "$($Params | Format-List | Out-String)"
    Invoke-RestMethod @Params -Method Get
}