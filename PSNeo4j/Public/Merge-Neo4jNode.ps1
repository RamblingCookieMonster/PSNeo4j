function Merge-Neo4jNode {
    <#
    .SYNOPSIS
       Add Neo4j nodes

    .DESCRIPTION
       Add Neo4j nodes

    .EXAMPLE
        [pscustomobject]@{
            ComputerName = 'dc01'
            Domain = 'some.domain'
        },
        [pscustomobject]@{
            ComputerName = 'dc02'
            Domain = 'some.domain'
        },
        [pscustomobject]@{
            ComputerName = 'web01'
            Domain = 'some.domain'
        } |
            New-Neo4jNode -Label Server -Passthru

        # Create three nodes with the label 'Server', and specified properties from the pipeline, and return the resulting nodes

    .EXAMPLE
        New-Neo4jNode -Label Service -InputObject @{
            Name = 'Active Directory'
            Engineer = 'Warren Frame'
        }

        # Create a node with the label 'Service' and the specified properties

    .PARAMETER Label
        Create node with this label

        If more than one label is provided, create node with multiple labels

        Warning: susceptible to query injection

    .PARAMETER InputObject
        One or more objects containing properties and values to add to this node.

        If more than one object is specified, we create multiple nodes

    .PARAMETER Passthru
        If specified, we return the resulting nodes

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
        [string]$Label,
        [string[]]$Identifiers,
        [parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [switch]$NoCreate,
        [switch]$Passthru,

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
    begin {
        $Params = @{            
            Hash = ($Object | Select-Object $Identifiers | ConvertTo-Hash);
            InputObject = ($Object | ConvertTo-Hash);
            Label = $Label
        }            
            
        #Add the rest params for splat
        if ($As) { $Params.add("As", $As) }
        if ($MetaProperties) { $Params.add("MetaProperties", $MetaProperties) }
        if ($MergePrefix) { $Params.add("MergePrefix", $MergePrefix) }
        if ($BaseUri) { $Params.add("BaseUri", $BaseUri) }
        if ($Credential) { $Params.add("Credential", $Credential) }
        if ($Verbose) { $Params.add("Verbose") }
        if ($NoCreate) { $Params.add("NoCreate") }
        if ($Passthru) { $Params.add("Passthru") }
    }
    process {
        foreach($Object in $InputObject) {
            Set-Neo4jNode @Params
        }
    }
}