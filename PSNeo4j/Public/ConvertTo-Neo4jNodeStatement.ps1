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

        If more than one label is provided, create node with multiple labels

        Warning: susceptible to query injection

    .PARAMETER Props
        Create node with these properties/values

    .PARAMETER Passthru
        Whether to return node upon creation

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [string[]]$Label,
        [object]$Props,
        [switch]$Passthru,

        [switch]$ParseDateInput = $PSNeo4jConfig.ParseDateInput
    )
    $Props = ConvertTo-Neo4jDateTime $Props -ParseDateInput $ParseDateInput
    $LabelString = $Label -join ':'
    $Query = "CREATE (node:$LabelString { props } )"
    if($Passthru) {$Query = "$Query RETURN node"}
    [pscustomobject]@{
        statement = $Query
        parameters = @{
            props = $Props
        }
    }
}