function New-Neo4jStatements {
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