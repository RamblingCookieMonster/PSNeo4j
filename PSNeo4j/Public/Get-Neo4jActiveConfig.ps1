function Get-Neo4jActiveConfig {
    <#
    .SYNOPSIS
       Get active configuration for Neo4j

    .DESCRIPTION
       Get active configuration for Neo4j

    .EXAMPLE
        Get-Neo4jActiveConfig

    .PARAMETER As
        Parse the Neo4j response as...
            Parsed:  We attempt to parse the output into friendlier PowerShell objects
                     Please open an issue if you see unexpected output with this
            Raw:     We don't touch the response                           ($Response)
            Results: We expand the 'results' property on the response      ($Response.results)
            Row:     We expand the 'row' property on the responses results ($Response.results.data.row)

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'Parsed')

        See ConvertFrom-Neo4jResponse for implementation details

    .PARAMETER MetaProperties
        Merge zero or any combination of these corresponding meta properties in the results: 'id', 'type', 'deleted'

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'type')

    .PARAMETER MergePrefix
        If any MetaProperties are specified, we add this prefix to avoid clobbering existing neo4j properties

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'Neo4j')

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
    param(
        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential  
    )
    $InvokeParams = @{}
    $Query = "CALL dbms.listConfig()"
    $InvokeParams.add('Query', $Query)
    Write-Verbose "Query: [$Query]"

    $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Invoke-Neo4jQuery @Params @InvokeParams
}