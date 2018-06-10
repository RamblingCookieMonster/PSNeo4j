function Set-Neo4jRelationship {
    <#
    .SYNOPSIS
        Update or create Neo4j relationships

    .DESCRIPTION
        Update or create Neo4j relationships

        Creates a new relationship if type/hash don't match anything.  Use NoCreate parameter to avoid creating new nodes

    .EXAMPLE
        Set-Neo4jRelationship -Label Server -Hash @{ Name = 'Server01'} -InputObject @{ Description = 'Some description!' }

        # Look for a node with the label 'Server' and Name 'Server01.
        #   If we find any, update the Description to 'Some description!'
        #   If we don't find any, create a note with the specific Label, Name, and Description

    .EXAMPLE
        @{ Name = 'Server01'}, @{ Name = 'Server02'} | Set-Neo4jNode -Label Server -InputObject @{ Description = 'Some description!' }

        # Look for a node with the label 'Server' and Name 'Server01.
        #   If we find any, update the Description to 'Some description!'
        #   If we don't find any, create a note with the specific Label, Name, and Description
        # Repeat, for nodes with label Server, Name 'Server02'

    .EXAMPLE
        Set-Neo4jNode -Label Server -Hash @{ SomeProperty = 'OldValue'} -InputObject @{ SomeProperty = 'NewValue' } -NoCreate

        # Look for a node with label 'Server' and SomeProperty 'OldValue' and switch SomeProperty to 'NewValue'
        # Do not create a new node if we don't find a node with Label Server, SomeProperty 'OldValue'

    .PARAMETER Type
        Set relationship with this type

        Warning: susceptible to query injection

    .PARAMETER Hash
        One or more hashtables containing properties and values corresponding to relationships we will set

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER InputObject
        One or more objects containing properties and values to add to matched relationships

        Warning: susceptible to query injection (keys/property names only. values are parameterized)

    .PARAMETER NoCreate
        If specified, do not create a new relationship if the type and hash do not find any relationships

        By default, we create a new relationship if nothing is found

    .PARAMETER Passthru
        If specified, we return the resulting relationship

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


        [string]$Type,
        [parameter(ValueFromPipeline=$True)]
        [hashtable]$Hash,
        [hashtable]$Properties,

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
        $Queries = [System.Collections.ArrayList]@()
        $SQLParams = @{}
        $InvokeParams = @{}
        if($InputObject -is [hashtable]) {
            $PropsToUpdate = $InputObject.Keys
        }
        else {
            [string[]]$PropsToUpdate = $InputObject.psobject.Properties.Name
        }
        $Count = 0
    }
    process {
        if($PSCmdlet.ParameterSetName -eq 'LabelHash') {
            $LeftPropString = $null
            if($LeftHash.keys.count -gt 0) {
                $Props = foreach($Property in $LeftHash.keys) {
                    "$Property`: `$left$Count$Property"
                    $SQLParams.Add("left$Count$Property", $LeftHash[$Property])
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
                $Props = foreach($Property in $RightHash.keys) {
                    "$Property`: `$right$Count$Property"
                    $SQLParams.Add("right$Count$Property", $RightHash[$Property])
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

        $RelationshipKeys = @()
        if($Hash.keys.count -gt 0) {
            [string[]]$RelationshipKeys = foreach($Property in $Hash.Keys) {
              "${Property}: `$key$Count$Property"
              $SQLParams.Add("key$Count$Property", $Hash[$Property])
            }
            $RelationshipKeyString = $RelationshipKeys -join ','
            $RelationshipKeyString = "{$RelationshipKeyString}"
        }

        $RelationshipProperties = $null
        if($Properties) {
            [string[]]$RelationshipProperties = foreach($Property in $Properties.keys) {
                "${Property}: `$relationship$Property"
                $SQLParams.Add("relationship$Property", $Properties[$Property])
            }
            $SetRelationshipString = $RelationshipProperties -join ','
            $SetRelationshipString = "ON MATCH SET relationship += {$SetRelationshipString}"

            $AllProperties = $RelationshipProperties + $RelationshipKeys
            $AllRelationshipString = $AllProperties -join ","
            $AllRelationshipString = "ON CREATE SET relationship = {$AllRelationshipString}"
        }

        if($NoCreate) {
            $Query = @"
$LeftQuery
$RightQuery
MATCH (left)-[relationship:$Type $RelationshipKeyString]->(right)
SET relationship += $SetRelationshipString
"@
        }
        else {
            $Query = @"
$LeftQuery
$RightQuery
MERGE (left)-[relationship:$Type $RelationshipKeyString]->(right)
$AllRelationshipString
$SetRelationshipString
"@
        }

        if($Passthru) {$Query = "$Query RETURN relationship"}
        $Count++
        [void]$Queries.Add($Query)
    }
    end {
        if($SQLParams.Keys.count -gt 0) {
            $InvokeParams.add('Parameters', $SQLParams)
        }
        $InvokeParams.add('Query', $Queries)

        $Params = . Get-ParameterValues -BoundParameters $PSBoundParameters -Invocation $MyInvocation -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
        Write-Verbose "$($Params | Format-List | Out-String)"
        Invoke-Neo4jQuery @Params @InvokeParams
    }
}