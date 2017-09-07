function New-Neo4jStatements {
    <#
    .SYNOPSIS
       Generate a 'Statements' block from the specified statements

    .DESCRIPTION
       Generate a 'Statements' block from the specified statements

       Generally only useful and used in PSNeo4j commands

       Details: http://neo4j.com/docs/developer-manual/current/http-api/

    .EXAMPLE
        @{Statement = 'SOME CYPHER QUERY'} | New-Neo4jStatements

    .PARAMETER Statements
        One or more statements to add.  Typically this will be either:
            @{Statement = 'SOME CYPHER QUERY'}
            @{
                Statement = 'SOME CYPHER QUERY WITH $Some PARAMETERS'
                Parameters = @{
                    Some='Parameters'
                }
            }

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True)]
        [object[]]$Statements
    )
    begin {
        $s = [System.Collections.ArrayList]@()
    }
    process {
        foreach($Statement in $Statements) {
            [void]$s.add($Statement)
        }
    }
    end {
        [pscustomobject]@{
            statements = $s
        }
    }
}