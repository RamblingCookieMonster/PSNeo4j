function Get-Neo4jUser {
    <#
    .SYNOPSIS
       Get details on a Neo4j user

    .DESCRIPTION
       Get details on a Neo4j user

    .EXAMPLE
        Get-Neo4jUser -User wframe

    .EXAMPLE
        Get-Neo4jUser

    .PARAMETER User
        User to query for.  Defaults to 'Neo4j'

        Warning: susceptible to URI injection

    .PARAMETER BaseUri
        BaseUri to build REST endpoint Uris from

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'http://127.0.0.1:7474')

    .PARAMETER Credential
        PSCredential to use for auth

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, not specified)

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param (
        [string]$User = 'neo4j',

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