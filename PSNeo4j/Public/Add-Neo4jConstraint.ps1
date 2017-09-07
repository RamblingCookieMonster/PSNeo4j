function Add-Neo4jConstraint {
    <#
    .SYNOPSIS
       Add constraints to Neo4j properties

    .DESCRIPTION
       Add constraints to Neo4j properties

    .EXAMPLE
        Add-Neo4jConstraint -Label Server -Property computername -Unique

        # Ensure the 'computername' property on nodes with the 'Server' label are unique

    .PARAMETER Label
        Label that contains properties to create constraints on

        Warning: susceptible to query injection

    .PARAMETER Relationship
        Relationship that contains properties to create constraints on

        Warning: susceptible to query injection

    .PARAMETER Property
        One or more properties to apply constraints on

        Warning: susceptible to query injection

    .PARAMETER Unique
        Add a unique constraint on specified properties

    .PARAMETER Exists
        Add an exists constraint on specified properties

        This requires Neo4j Enterprise

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
    [cmdletbinding(DefaultParameterSetName = 'Node')]
    param(
        [parameter(ParameterSetName = 'Node')]
        [string]$Label, # Injection alert
        [parameter(ParameterSetName = 'Relationship')]
        [string]$Relationship, # Injection alert
        [string[]]$Property, # Injection alert
        
        [parameter(ParameterSetName = 'Node')]
        [switch]$Unique,
        [parameter(ParameterSetName = 'Node')]
        [switch]$Exists,

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
    $Query = [System.Collections.ArrayList]@()
    if($PSCmdlet.ParameterSetName -eq 'Node') {
        write-verbose 'NODE'
        if($Unique) {
            Foreach($Prop in $Property) {
                write-verbose $prop
                [void]$Query.add("CREATE CONSTRAINT ON (l:$Label) ASSERT l.$Prop IS UNIQUE")
            }            
        }
        If($Exists) {
            Foreach($Prop in $Property) {
                # Requires enterprise. Interesting
                write-verbose $prop
                [void]$Query.add("CREATE CONSTRAINT ON (l:$Label) ASSERT exists(l.$Prop)")
            }
        }
    }
    if($PSCmdlet.ParameterSetName -eq 'Relationship') {
        write-verboe 'relationship'
        Foreach($Prop in $Property) {
            # Requires enterprise. Interesting
            [void]$Query.add("CREATE CONSTRAINT ON ()-[l:$Relationship]-() ASSERT exists(l.$Prop)")
        }
    }
    # TOOO: http://neo4j.com/docs/developer-manual/current/cypher/schema/constraints/#constraints-drop-a-node-key

    Write-Verbose "Query: [$Query]"
    $Params = . Get-ParameterValues -Properties As, MetaProperties, MergePrefix, Credential, BaseUri
    Invoke-Neo4jQuery @Params -Query $Query
}