function Remove-Neo4jNodeProperty {
    <#
    .SYNOPSIS
        Remove properties from Neo4j nodes

    .DESCRIPTION
        Remove properties from Neo4j nodes

        Use the 'remove' variable in Cypher parameters like Where and Match

    .EXAMPLE
        Remove-Neo4jNodeProperty -Label Server -Property BadProp, OldProp

        # Remove BadProp and OldProp properties from every node labeled Server

    .EXAMPLE
        Remove-Neo4jNodeProperty -Label Server -Hash @{ osfamily = 'windows' } -Property BadProp, OldProp

        # Remove BadProp and OldProp properties from nodes labeled Server that have osfamily property = windows

    .EXAMPLE
        Remove-Neo4jNodeProperty -Match "MATCH (remove:Server) WHERE remove.operatingsystem =~ '.*windows.*'" -Property BadProp, OldProp

        # Remove BadProp and OldProp properties from nodes labeled Server that have operatingsystem property regex matching .*windows.*

    .PARAMETER Property
        Properties to remove from any matching nodes

        Warning: susceptible to query injection

    .PARAMETER Match
        If specified, remove properties from nodes returned from this MATCH statement.
        You must use variable 'remove'

        Example: MATCH (remove:SomeLabel) WHERE some =~ 'comparison'

    .PARAMETER Label
        Remove properties from nodes with this label

        Warning: susceptible to query injection

    .PARAMETER Hash
        One or more hashtables containing properties and values corresponding to nodes we will delete properties on

        Warning: susceptible to query injection (keys only. values are parameterized)

    .PARAMETER Where
        Filter matching nodes with this.  Use 'remove' as the matched item

        Example:
            WHERE remove.something = 'blah'

        Warning: susceptible to query injection

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
        [parameter( ParameterSetName = 'Match',
                    Position = 1,
                    Mandatory = $True)]
        [string]$Match,

        [parameter(ParameterSetName = 'LabelHash',
                   Position = 1,
                   Mandatory = $True)]
        [string]$Label,

        [parameter( ParameterSetName = 'LabelHash',
                    ValueFromPipeline=$True)]
        [hashtable[]]$Hash,

        [parameter( Mandatory = $True )]
        [string[]]$Property,

        [string]$Where,

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
        $Count = 0
        $Var = 'remove'
        $InvokeParams = @{}
        $SQLParams = @{}
        function Get-RemoveString {
            param([string[]]$Property, $Var) 
            [string[]]$ToDeleteArray = foreach($Prop in $Property) {
                "$Var.$Prop"
            }
            $ToDeleteString = $ToDeleteArray -join ', '
            if($ToDeleteString) {
                "REMOVE $ToDeleteString"
            }
        }
    }
    process {
        if($PSCmdlet.ParameterSetName -like 'LabelHash')
        {
            foreach($PropHash in $Hash)
            {
                $PropString = $null
                if($Hash.keys.count -gt 0) {
                    $Props = foreach($Prop in $PropHash.keys) {
                        "$Prop`: `$$Var$Count$Prop"
                        $SQLParams.Add("$Var$Count$Prop", $PropHash[$Prop])
                    }
                    $PropString = $Props -join ', '
                    $PropString = "{$PropString}"
                }
                $Query = "MATCH ($Var`:$Label $PropString)"
                if($Where){
                    $Query = "$Query`n$Where`n"
                }
                $Count++
                $Remove = Get-RemoveString -Var $Var -Property $Property
                [void]$Queries.Add("$Query $Remove")
            }
            if($Label -and -not $Hash) {
                $Queries.Add("MATCH ($Var`:$Label) $(Get-RemoveString -Var $Var -Property $Property)")
            }
        }
        else {
            $Query = $Match
            if($Where){
                $Query = "$Query`n$Where`n"
            }
            $Queries.Add("$Query $(Get-RemoveString -Var $Var -Property $Property)")
        }
    }
    end {
        if($Queries.count -eq 0) {
            return
        }
        if($SQLParams.Keys.count -gt 0) {
            $InvokeParams.add('Parameters', $SQLParams)
        }
        $InvokeParams.add('Query', $Queries)
        $Params = . Get-ParameterValues -BoundParameters $PSBoundParameters -Invocation $MyInvocation -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
        Write-Verbose "$($Params | Format-List | Out-String)"
        Invoke-Neo4jQuery @Params @InvokeParams
    }
}