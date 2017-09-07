function Remove-Neo4jIndex {
    <#
    .SYNOPSIS
       Remove indexes on Neo4j properties

    .DESCRIPTION
       Remove indexes on Neo4j properties

    .EXAMPLE
        Remove-Neo4jIndex -Label Server -Property computername, domain -Composite
        
        # Drop a composite index on the 'computername' and 'domain' properties for nodes labeled 'Server'

    .EXAMPLE
        Remove-Neo4jIndex -Label Server -Property computername, domain
        
        # Drop individual indexes on the 'computername' and 'domain' properties for nodes labeled 'Server'

    .PARAMETER Label
        Label containing the property we want to drop the index from

        Warning: susceptible to query injection

    .PARAMETER Property
        One or more properties to drop the index from

        The 'Composite' parameter specifies whether to drop an index per property, or a composite index on multiple properties

        Warning: susceptible to query injection

    .PARAMETER Composite
        If specified and more than one property is specified, drop a composite index

        If *not* specified and more than one property is specified, an index is dropped per property

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
        [string]$Label, # Injection alert
        [string[]]$Property, # Injection alert
        [switch]$Composite,

        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential  
    )

    $InvokeParams = @{}
    if($Composite) {
        $Query = "DROP INDEX ON :$Label($($Property -join ', '))"
    }
    else {
        $Query = foreach($Prop in $Property) {
            "DROP INDEX ON :$Label($Prop)"
        }
    }
    $InvokeParams.add('Query', $Query)
    Write-Verbose "Query: [$Query]"
    $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Invoke-Neo4jQuery @Params @InvokeParams
}