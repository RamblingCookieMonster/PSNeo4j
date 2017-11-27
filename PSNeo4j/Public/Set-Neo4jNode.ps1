function Set-Neo4jNode {
    <#
    .SYNOPSIS
        Update or create Neo4j nodes

    .DESCRIPTION
        Update or create Neo4j nodes

        Creates a new node if label/hash don't match anything.  Use NoCreate parameter to avoid creating new nodes

    .EXAMPLE
        Set-Neo4jNode -Label Server -Hash @{ Name = 'Server01'} -InputObject @{ Description = 'Some description!' }

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

    .PARAMETER Label
        Set nodes with this label

        Warning: susceptible to query injection

    .PARAMETER Hash
        One or more hashtables containing properties and values corresponding to nodes we will set

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER InputObject
        One or more objects containing properties and values to add to matched nodes

        Warning: susceptible to query injection (keys/property names only. values are parameterized)

    .PARAMETER NoCreate
        If specified, do not create a new node if the label and hash do not find any nodes

        By default, we create a new node if nothing is found

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
        [hashtable[]]$Hash,

        $InputObject,
        [switch]$NoCreate,
        [switch]$Passthru,

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
        write-verbose "InputObject is $($InputObject.GetType()), PropsToUpdate is $($PropsToUpdate)"
        $Count = 0
    }
    process {
        # We only pass in one parameter hash table, to avoid duplicates and collisions, we use a count and differentiate by merge-vs-set properties
        # We need three parameterized property strings: for MERGE (the identifying bits), ON CREATE SET (all the bits), ON MATCH SET (the bits to update)
        foreach($PropHash in $Hash) {
            $MergePropString = $null
            if($Hash.keys.count -gt 0) {
                [string[]]$MergeProps = foreach($Property in $PropHash.keys) {
                    "$Property`: `$merge$Count$Property"
                    $SQLParams.Add("merge$Count$Property", $PropHash[$Property])
                }
                $MergePropString = $MergeProps -join ', '
                $MergePropString = "{$MergePropString}"
            }
            $SetPropString = $null
            if($PropsToUpdate.count -gt 0) {
                [string[]]$ExtraProps = foreach($Property in $PropsToUpdate) {
                    Write-Verbose "Setting $Property with value $($InputObject.$Property)"
                    "$Property`: `$extra$Count$Property"
                    $SQLParams.Add("extra$Count$Property", $InputObject.$Property)
                }
                $SetPropString = $ExtraProps -join ', '
                $SetPropString = "{$SetPropString}"

                $AllProps = $MergeProps + $ExtraProps
                $AllPropString = $AllProps -join ', '
                $AllPropString = "{$AllPropString}"
            }
            if($NoCreate) {
                $Query = "MATCH (set:$Label $MergePropString) SET set += $SetPropString"
            }
            else {
                $Query = "MERGE (set:$Label $MergePropString) ON CREATE SET set = $AllPropString ON MATCH SET set += $SetPropString"
            }
            if($Passthru) {$Query = "$Query RETURN set"}
            $Count++
            [void]$Queries.Add($Query)
        }
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