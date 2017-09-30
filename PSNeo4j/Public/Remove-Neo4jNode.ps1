function Remove-Neo4jNode {
    <#
    .SYNOPSIS
       Remove Neo4j nodes

    .DESCRIPTION
       Remove Neo4j nodes

    .EXAMPLE
        @{ComputerName = 'web01'} | Remove-Neo4jNode -Label Server

        # Remove a node with the label 'Server' and ComputerName 'web01'

    .EXAMPLE
        Remove-Neo4jNode -Label Server -Detach -Hash @{
            ComputerName = 'web01'
        }

        # Remove a node with the label 'Server' and ComputerName 'web01', and any relationships to or from it.

    .PARAMETER Label
        Remove nodes with this label

        Warning: susceptible to query injection

    .PARAMETER Hash
        One or more hashtables containing properties and values corresponding to nodes we will delete

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER Where
        Filter matching nodes with this.  Use 'delete' as the matched item

        Example:
            WHERE delete.something = 'blah'

        Warning: susceptible to query injection

    .PARAMETER Detach
        If specified, remove any relationships to or from the nodes being deleted

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
        [string]$Where,
        [switch]$Detach,

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
        $DetachString = $null
        if($Detach) {$DetachString = 'DETACH '}
        write-verbose "$Detach and [$DetachString]"
        $Queries = [System.Collections.ArrayList]@()
        $Count = 0
    }
    process {
        foreach($PropHash in $Hash)
        {
            $InvokeParams = @{}
            $SQLParams = @{}
            $PropString = $null
            if($Hash.keys.count -gt 0) {
                $Props = foreach($Property in $PropHash.keys) {
                    "$Property`: `$delete$Count$Property"
                    $SQLParams.Add("delete$Count$Property", $PropHash[$Property])
                }
                $PropString = $Props -join ', '
                $PropString = "{$PropString}"
            }
            $Query = "MATCH (delete:$Label $PropString)"
            if($Where){
                $Query = "$Query`n$Where"
            }
            $Count++

            [void]$Queries.Add("$Query $DetachString DELETE delete")
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