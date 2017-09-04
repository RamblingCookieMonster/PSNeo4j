#https://neo4j.com/docs/rest-docs/3.2/#rest-api-create-a-node-with-multiple-properties
function ConvertTo-Neo4jNodeStatement {
    [cmdletbinding()]
    param(
        [string]$Label,
        [object]$Props,
        [switch]$Passthru,
        [switch]$Compress
    )
    $Query = "CREATE (node:$Label { props } )"
    if($Passthru) {$Query = "$Query RETURN node"}
    [pscustomobject]@{
        statement = $Query
        parameters = @{
            props = $Props
        }
    }
}