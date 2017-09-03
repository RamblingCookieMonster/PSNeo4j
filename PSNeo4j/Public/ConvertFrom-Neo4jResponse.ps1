function ConvertFrom-Neo4jResponse {
    [cmdletbinding()]
    param(
        $Response,
        [switch]$Raw,
        [switch]$ExpandResults,
        [switch]$ExpandRow,
        [string]$MergePrefix = 'Neo4j',
        [validateset('id', 'type', 'deleted')]
        [string[]]$MetaProperties = 'Type'
    )
    if($Raw) {
        return $Response
    }
    if($Response.Errors.count -gt 0) {
        foreach($err in $Response.Errors) {
            Write-Error -ErrorId $err.code -Message $err.message
        }
    }
    if($Response.psobject.properties.name -contains 'results') {
        #return
    }

    If($ExpandResults) {
        return $Response.results
    }
    If($ExpandRow) {
        return $Response.results.data.row
    }
    Else {
        # The following merges columns+rows, and rows+meta

        # Is results always an array of 1?
        $Columns = $Response.results.columns
        $Data = @($Response.results.data)
        for ($DataIndex = 0; $DataIndex -lt $Data.count; $DataIndex++)
        { 
            for ($ColumnIndex = 0; $ColumnIndex -lt $Columns.Count; $ColumnIndex++)
            {
                $Column = $Columns[$ColumnIndex]
                $Datum = $Data[$DataIndex].row[$ColumnIndex].psobject.Copy()
                $Meta = $Data[$DataIndex].meta[$ColumnIndex]
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
}