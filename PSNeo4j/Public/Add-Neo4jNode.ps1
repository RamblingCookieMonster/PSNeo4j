function Add-Neo4jNode {
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
            Add-Neo4jNode -Label Server -Passthru

        # Create three nodes with the label 'Server', and specified properties from the pipeline, and return the resulting nodes

    .EXAMPLE
        Add-Neo4jNode -Label Service -InputObject @{
            Name = 'Active Directory'
            Engineer = 'Warren Frame'
        }

        # Create a node with the label 'Service' and the specified properties

    .PARAMETER Label
        Create node with this label

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

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, not specified)

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [string]$Label,
        [parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [switch]$Passthru,

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
    begin {
        $Objects = [System.Collections.ArrayList]@()
    }
    process {
        foreach($Object in $InputObject) {
            [void]$Objects.add($Object)
        }
    }
    end {
        $Statements = ConvertTo-Neo4jNodesStatement -InputObject $Objects -Label $Label -Passthru:$Passthru
        $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
        Write-Verbose "$($Params | Format-List | Out-String)"
        Invoke-Neo4jQuery @Params -Statements $Statements
    }
}