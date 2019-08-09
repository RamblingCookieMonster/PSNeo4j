﻿function New-Neo4jRelationship {
    <#
    .SYNOPSIS
       Add Neo4j relationships

    .DESCRIPTION
       Add Neo4j relationships

       'Left' implies the node a relationship starts from, and 'Right' implies the node a relationship points to

       You can use either LeftLabel/LeftHash, or LeftQuery to determine the nodes on the left, ditto for nodes on the right
       You can't mix and match label/hash and query node selection between the left and right (yet)

    .EXAMPLE
        New-Neo4jRelationship -LeftLabel Server -LeftHash @{ComputerName = 'web01'} `
                      -RightLabel Service -RightHash @{Name = 'Active Directory'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          Identity = $True
                          Management = $True
                      }
        # Add a relationship between:
          # A 'Server' on the left with 'ComputerName' web01
          # A 'Service' on the right, with Name 'Active Directory'
          # With relationship Type 'DependsOn', and a few relationship properties

        # Essentially:  Web01 DependsOn Active Directory

    .EXAMPLE
        New-Neo4jRelationship -LeftQuery "MATCH (left:Service { Name: 'Active Directory'})" `
                      -RightQuery "MATCH (right:Server) WHERE right.ComputerName =~ 'dc.*'" `
                      -Type 'DependsOn' `
                      -Properties @{
                          ServiceHost = $True
                          LoadBalanced = $True
                      }
        # Add a relationship between:
          # Any nodes returned by LeftQuery on the left
          # Any nodes returned by RightQuery on the right
          # With relationship type 'DependsOn', and a few relationship properties

        # IMPORTANT: the 'left' and 'right' variables in the respective LeftQuery and RightQuery are required

    .PARAMETER LeftLabel
        Determines label of node(s) the relationships start from

        Use in conjunction with LeftHash, if needed

        Warning: susceptible to query injection

    .PARAMETER LeftHash
        Filter nodes the relationship starts from to only nodes containing these keys and values

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER LeftWhere
        When using LeftLabel, filter matching nodes with this.  Use 'left' as the matched item

        Example:
            WHERE left.something = 'blah'

        Warning: susceptible to query injection

    .PARAMETER RightLabel
        Determines label of node(s) the relationships point to

        Use in conjunction with RightHash, if needed

        Warning: susceptible to query injection

    .PARAMETER RightHash
        Filter nodes the relationship points to to only nodes containing these keys and values

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER RightWhere
        When using RightLabel, filter matching nodes with this.  Use 'right' as the matched item

        Example:
            WHERE right.something = 'blah'

        Warning: susceptible to query injection

    .PARAMETER LeftQuery
        Query to determine which node(s) the relationships start from

        IMPORTANT: This must assign the 'left' variable to the resulting nodes, for example:
                   "MATCH (left:Service)"

    .PARAMETER RightQuery
        Query to determine which node(s) the relationships point to

        IMPORTANT: This must assign the 'right' variable to the resulting nodes, for example:
                   "MATCH (right:Service)"

    .PARAMETER Type
        The relationship type (similar to a label)

        Warning: susceptible to query injection

    .PARAMETER Properties
        Relationship properties to include

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER Statement
        Whether to use MERGE or CREATE when creating the relationship.  Defaults to MERGE

    .PARAMETER Parameters
        Other query parameters to add.  You can use these in a query as {key} or $key

        Note: these can clash with Properties, which start 'relationship'

    .PARAMETER Passthru
        If specified, we return the resulting relationships

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
    [cmdletbinding(DefaultParameterSetName = 'LabelHash')]
    param(
        [parameter( ParameterSetName = 'LabelHash',
                    Mandatory = $True )]
        [string]$LeftLabel,
        [parameter( ParameterSetName = 'LabelHash' )]
        $LeftHash,
        [parameter( ParameterSetName = 'LabelHash')]
        $LeftWhere,

        [parameter( ParameterSetName = 'LabelHash',
                    Mandatory = $True )]
        [string]$RightLabel,
        [parameter( ParameterSetName = 'LabelHash')]
        $RightHash,
        [parameter( ParameterSetName = 'LabelHash')]
        $RightWhere,

        [parameter( ParameterSetName = 'Query',
                    Mandatory = $True )]
        $LeftQuery,
        [parameter( ParameterSetName = 'Query',
                    Mandatory = $True )]
        $RightQuery,
        [parameter( ParameterSetName = 'Query')]
        [hashtable]$Parameters,

        $Type,
        [hashtable]$Properties,

        [validateset('CREATE', 'MERGE')]
        [string]$Statement = 'MERGE',

        [switch]$Passthru,

        [validateset('Raw', 'Results', 'Row', 'Parsed', 'ParsedColumns')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential,

        [switch]$ParseDateInput = $PSNeo4jConfig.ParseDateInput
    )
    $SQLParams = @{}

    if($PSCmdlet.ParameterSetName -eq 'LabelHash') {
        $LeftPropString = $null
        if($LeftHash.keys.count -gt 0) {
            $LeftHash = ConvertTo-Neo4jDateTime $LeftHash -ParseDateInput $ParseDateInput
            $Props = foreach($Property in $LeftHash.keys) {
                "$Property`: `$left$Property"
                $SQLParams.Add("left$Property", $LeftHash[$Property])
            }
            $LeftPropString = $Props -join ', '
            $LeftPropString = "{$LeftPropString}"
        }
        $LeftQuery = "MATCH (left:$LeftLabel $LeftPropString)"
        if($LeftWhere) {
            $LeftQuery = "$LeftQuery`n$LeftWhere"
        }

        $RightPropString = $null
        if($RightHash.keys.count -gt 0) {
            $RightHash = ConvertTo-Neo4jDateTime $RightHash -ParseDateInput $ParseDateInput
            $Props = foreach($Property in $RightHash.keys) {
                "$Property`: `$right$Property"
                $SQLParams.Add("right$Property", $RightHash[$Property])
            }
            $RightPropString = $Props -join ', '
            $RightPropString = "{$RightPropString}"
        }
        $RightQuery = "MATCH (right:$RightLabel $RightPropString)"
        if($RightWhere) {
            $RightQuery = "$RightQuery`n$RightWhere"
        }
    }

    if($Passthru) {
        $Return = 'RETURN relationship'
    }

    $InvokeParams = @{}
    $PropString = $null
    if($Properties) {
        $Properties = ConvertTo-Neo4jDateTime $Properties -ParseDateInput $ParseDateInput
        $Props = foreach($Property in $Properties.keys) {
            "$Property`: `$relationship$Property"
            $SQLParams.Add("relationship$Property", $Properties[$Property])
        }
        $PropString = $Props -join ', '
        $PropString = "{$PropString}"
    }
    if($PSBoundParameters.ContainsKey('Parameters')) {
        $Parameters = ConvertTo-Neo4jDateTime $Parameters -ParseDateInput $ParseDateInput
        foreach($Property in $Parameters.keys) {
            $SQLParams.Add("$Property", $Parameters[$Property])
        }
    }
    if($SQLParams.Keys.count -gt 0) {
        $InvokeParams.add('Parameters', $SQLParams)
    }

    $Query = @"
$LeftQuery
$RightQuery
$Statement (left)-[relationship:$Type $PropString]->(right)
$Return
"@
    $Params = . Get-ParameterValues -BoundParameters $PSBoundParameters -Invocation $MyInvocation -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Write-Verbose "$($Params | Format-List | Out-String)"
    Invoke-Neo4jQuery @Params @InvokeParams -Query $Query
}