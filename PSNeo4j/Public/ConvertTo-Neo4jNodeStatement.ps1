function ConvertTo-Neo4jNodeStatement {
    <#
    .SYNOPSIS
       Generate a Neo4j statement to create a node

    .DESCRIPTION
       Generate a Neo4j statement to create a node

       Uses the following syntax:
           https://neo4j.com/docs/rest-docs/3.2/#rest-api-create-a-node

    .EXAMPLE
        ConvertTo-Neo4jNodeStatements -Label Server -Props @{
            ComputerName = 'dc01'
        }

    .PARAMETER Label
        Label for the nodes to create

    .PARAMETER Props
        Create node with these properties/values

    .PARAMETER Passthru
        Whether to return node upon creation

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [string]$Label,
        [object]$Props,
        [switch]$Passthru
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