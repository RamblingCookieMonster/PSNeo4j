# https://neo4j.com/docs/rest-docs/3.2/#rest-api-create-multiple-nodes-with-properties
function ConvertTo-Neo4jNodesStatement {
    <#
    .SYNOPSIS
       Generate a Neo4j statement to create multiple nodes

    .DESCRIPTION
       Generate a Neo4j statement to create multiple nodes

       Uses the following syntax:
           https://neo4j.com/docs/rest-docs/3.2/#rest-api-create-multiple-nodes-with-properties

    .EXAMPLE
        @{
            ComputerName = 'dc01'
        },
        @{
            ComputerName = 'dc01'
            OtherProp    = 1
        } |
            ConvertTo-Neo4jNodesStatements -Label Server

    .PARAMETER Label
        Label for the nodes to create

        If more than one label is provided, create node with multiple labels

        Warning: susceptible to query injection

    .PARAMETER InputObject
        Create nodes with these properties/values

    .PARAMETER Passthru
        Whether to return nodes upon creation

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [string[]]$Label,
        [parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [switch]$Passthru
    )
    begin {
        $LabelString = $Label -join ':'
        $Query = "UNWIND {props} AS properties CREATE (node:$LabelString) SET node = properties"
        if($Passthru) {$Query = "$Query RETURN node"}
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