function Clear-Neo4j {
    <#
    .SYNOPSIS
       Remove all nodes, relationships, constraints, and indexes

    .DESCRIPTION
       Remove all nodes, relationships, constraints, and indexes

    .EXAMPLE
        Clear-Neo4j

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

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, neo4j:neo4j)

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [validateset('Raw', 'Results', 'Row', 'Parsed', 'ParsedColumns')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential
    )
    $SchemaQuery = [System.Collections.ArrayList]@()
    $Constraints = @( Get-Neo4jConstraint )
    foreach($Constraint in $Constraints) {
        $Prop = @($Constraint.psobject.properties.name)
        if($Prop.count -eq 1 -and $Prop -like 'd' -and $Constraint.d) {
            [void]$SchemaQuery.add("DROP $($Constraint.$Prop)")
        }
    }
    $Indices = @( Get-Neo4jIndex )
    foreach($Index in $Indices) {
        $Prop = @($Index.psobject.properties.name)
        if($Prop -contains 'description' -and $Index.type) {
            [void]$SchemaQuery.add("DROP $($Index.description)")
        }
    }

    Write-Verbose "SchemaQuery: [$SchemaQuery]"
    $Params = . Get-ParameterValues -BoundParameters $PSBoundParameters -Invocation $MyInvocation -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Invoke-Neo4jQuery @Params -Query 'MATCH (n) DETACH DELETE n'
    if($SchemaQuery.count -gt 0) {
        Invoke-Neo4jQuery @Params -Query $SchemaQuery
    }
}