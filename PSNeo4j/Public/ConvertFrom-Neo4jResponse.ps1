function ConvertFrom-Neo4jResponse {
    <#
    .SYNOPSIS
       Parse the response from Neo4j

    .DESCRIPTION
       Parse the response from Neo4j

       Generally only useful and used in PSNeo4j commands

       Details: http://neo4j.com/docs/developer-manual/current/http-api/

    .EXAMPLE
        $Response = Invoke-RestMethod @SomeNeo4jParams
        ConvertFrom-Neo4jResponse -Response $Response

    .PARAMETER Response
        Output from Invoke-RestMethod

    .PARAMETER As
        Parse the Neo4j response as...
            Parsed:  We attempt to parse the output into friendlier PowerShell objects
                     Please open an issue if you see unexpected output with this
            Raw:     We don't touch the response                           ($Response)
            Results: We expand the 'results' property on the response      ($Response.results)
            Row:     We expand the 'row' property on the responses results ($Response.results.data.row)
            Graph:   We expand the 'nodes' and 'relationships' properties and remove...
                     duplicates on the responses results                   ($Response.results.data.graph)

        -As Parsed does a few things:
          * Merges specified 'Meta' information about each item returned
          * Merges 'column' name for each item returned

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'Parsed')

        See ConvertFrom-Neo4jResponse for implementation details

    .PARAMETER MetaProperties
        Merge zero or any combination of these corresponding meta properties in the results: 'id', 'type', 'deleted'

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'type')

    .PARAMETER MergePrefix
        If any MetaProperties are specified, we add this prefix to avoid clobbering existing neo4j properties

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'Neo4j')

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        $Response,
        [validateset('Raw', 'Results', 'Row', 'Parsed', 'ParsedColumns', 'Graph')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,
        [validateset('NoParse', 'ByKeyword', 'ByValue')]
        [string]$ParseDate = $PSNeo4jConfig.ParseDate
    )
    if($As -eq 'Raw') {
        return $Response
    }
    if($Response -is [system.string] -and $Response.length -gt 3) {
        try {
            $Response = ConvertFrom-Json $Response -AsHashtable -ErrorAction Stop
            $Response = [pscustomobject]$Response
        }
        catch {
            Write-Error "Failed to parse Neo4j response:`n$($Response | Out-String)"
            throw $_
        }
    }
    if($Response.Errors.count -gt 0) {
        foreach($err in $Response.Errors) {
            Write-Error -ErrorId $err.code -Message $err.message
        }
    }
    if($Response.psobject.properties.name -contains 'results') {
        #return
    }
    If($As -eq 'Graph') {
        $tmp_nodes = @{}
        $tmp_relationships = @{}

        foreach ($node in $Response.results.data.graph.nodes)
        {
            if (-not $tmp_nodes.ContainsKey($node.id))
            {
                $tmp_nodes.Add($node.id,$node)
            }
        }

        foreach ($relationship in $Response.results.data.graph.relationships)
        {
            if (-not $tmp_relationships.ContainsKey($relationship.id))
            {
                $tmp_relationships.Add($relationship.id,$relationship)
            }
        }

        return [PSCustomObject][Ordered]@{
            nodes = [object[]]$tmp_nodes.Values
            relationships = [object[]]$tmp_relationships.Values
        }
    }
    If($As -eq 'Results') {
        return $Response.results
    }
    If($As -eq 'Row') {
        return $Response.results.data.row
    }
    If($As -eq 'Parsed') {
        # The following merges columns+rows, and rows+meta

        # Is results always an array of 1?
        $Columns = $Response.results.columns
        $Data = @($Response.results.data)
        for ($DataIndex = 0; $DataIndex -lt $Data.count; $DataIndex++)
        {
            for ($ColumnIndex = 0; $ColumnIndex -lt $Columns.Count; $ColumnIndex++)
            {
                $Column = $Columns[$ColumnIndex]
                $Datum = $null

                # Neo4j likes to return columns with no data - wat?
                if(-not $Data) {
                    $Meta = $null
                }
                else {
                    if($null -ne $Data[$DataIndex].row[$ColumnIndex]) {
                        $Datum = $Data[$DataIndex].row[$ColumnIndex].psobject.Copy()
                        if($Datum -is [hashtable]) {
                            $Datum = [pscustomobject]$Datum
                        }
                        if(-not $Script:DatesConverted -and 'ByKeyword', 'ByValue' -contains $ParseDate) {

                            if($ParseDate -eq 'ByKeyword') {
                                $ParseProps = $Datum.psobject.properties.name.where({$_ -match 'Date|Time'})
                            }
                            if($ParseDate -eq 'ByValue') {
                                $ParseProps = $Datum.psobject.properties.name
                            }
                            if($ParseProps.count -gt 0) {
                                foreach($ParseProp in $ParseProps){
                                    $Datum.$ParseProp = Parse-Neo4jDate -DateString $Datum.$ParseProp
                                }
                            }
                        }
                    }
                    $Meta = $Data[$DataIndex].meta[$ColumnIndex]
                }
                # Consider just looping properties...
                # Is row always an array of 1?
                foreach($prop in $MetaProperties) {
                    if($null -ne $Meta -and $Meta[0].psobject.properties.name -contains $prop) {
                        Add-Member -InputObject $Datum -Name "$MergePrefix$Prop" -Value $Meta.$Prop -MemberType NoteProperty -Force
                    }
                }
                if($null -ne $Meta) {
                    Add-Member -InputObject $Datum -Name "$MergePrefix`Column" -Value $Column -MemberType NoteProperty -Force
                }
                else
                {
                    if($Datum -is [Object[]] -and $Datum.count -eq 1) {$Datum = $Datum[0]}
                    $Datum = [pscustomobject]@{
                        "$MergePrefix`Column" = $Column
                        "$MergePrefix`Data" = $Datum
                    }
                }
                $Datum
            }
        }
    }
    If($As -eq 'ParsedColumns') {
        # The following merges columns+rows, and rows+meta

        # Is results always an array of 1?
        $Columns = $Response.results.columns
        $Data = @($Response.results.data)
        for ($DataIndex = 0; $DataIndex -lt $Data.count; $DataIndex++)
        {
            $Output = [pscustomobject]@{}
            for ($ColumnIndex = 0; $ColumnIndex -lt $Columns.Count; $ColumnIndex++)
            {
                $Column = $Columns[$ColumnIndex]
                $Datum = $null

                # Neo4j likes to return columns with no data - wat?
                if(-not $Data) {
                    $Meta = $null
                }
                else {
                    if($null -ne $Data[$DataIndex].row[$ColumnIndex]) {
                        $Datum = $Data[$DataIndex].row[$ColumnIndex].psobject.Copy()
                        if($Datum -is [hashtable]) {
                            $Datum = [pscustomobject]$Datum
                        }
                        if(-not $Script:DatesConverted -and 'ByKeyword', 'ByValue' -contains $ParseDate) {

                            if($ParseDate -eq 'ByKeyword') {
                                $ParseProps = $Datum.psobject.properties.name.where({$_ -match 'Date|Time'})
                            }
                            if($ParseDate -eq 'ByValue') {
                                $ParseProps = $Datum.psobject.properties.name
                            }
                            if($ParseProps.count -gt 0) {
                                foreach($ParseProp in $ParseProps){
                                    $Datum.$ParseProp = Parse-Neo4jDate -DateString $Datum.$ParseProp
                                }
                            }
                        }
                    }
                    $Meta = $Data[$DataIndex].meta[$ColumnIndex]
                }
                # Consider just looping properties...
                # Is row always an array of 1?
                foreach($prop in $MetaProperties) {
                    if($null -ne $Meta -and $Meta[0].psobject.properties.name -contains $prop) {
                        Write-Verbose "Adding $MergePrefix$Prop Value $($Meta.$Prop)"
                        Add-Member -InputObject $Output -Name "$MergePrefix$Prop" -Value $Meta.$Prop -MemberType NoteProperty -Force
                    }
                }
                if($null -ne $Meta) {
                    Write-Verbose "Adding $MergePrefix`Column Value $($Column)"
                    Add-Member -InputObject $Datum -Name "$MergePrefix`Column" -Value $Column -MemberType NoteProperty -Force
                }
                else
                {
                    Write-Verbose "Adding $Column Value $Datum"
                    if($Datum -is [Object[]] -and $Datum.count -eq 1) {$Datum = $Datum[0]}
                    Add-Member -InputObject $Output -Name $Column -Value $Datum -MemberType NoteProperty -Force
                }
            }
            $Output
        }
    }
}