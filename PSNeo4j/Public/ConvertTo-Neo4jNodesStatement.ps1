# https://neo4j.com/docs/rest-docs/3.2/#rest-api-create-multiple-nodes-with-properties
function ConvertTo-Neo4jNodesStatement {
    [cmdletbinding()]
    param(
        [string]$Label,
        [parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [switch]$Passthru,
        [switch]$Compress
    )
    begin {
        $Query = "UNWIND {props} AS properties CREATE (n:$Label) SET n = properties"
        if($Passthru) {$Query = "$Query RETURN n"}
        $Props = [System.Collections.ArrayList]@()
    }
    process {
        foreach($Item in $InputObject) {
            [void]$Props.add($Item)
        }
    }
    end {
        [pscustomobject]@{
            statement = $Query
            parameters = @{
                props = $Props
            }
        }
    }
}