$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleName = $ENV:BHProjectName

# Verbose output for non-master builds on appveyor
# Handy for troubleshooting.
# Splat @Verbose against commands as needed (here or in pester tests)
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }

$TestDataPath = "$PSScriptRoot\Data"
Import-Module $PSScriptRoot\..\$ModuleName -Force

#get-command -Module psneo4j | sort Noun | Select -ExpandProperty Name | %{"Describe `"$_ `$PSVersion`" {`n    It 'Should' {`n`n    }`n}`n"}
Describe "$ModuleName PS$PSVersion" {
    It 'Should load' {
        $Module = @( Get-Module $ModuleName )
        $Module.Name -contains $ModuleName | Should be $True
        $Commands = $Module.ExportedCommands.Keys
        $Commands -contains 'Get-PSNeo4jConfiguration' | Should Be $True
        }
}

Describe "Get-PSNeo4jConfiguration $PSVersion" {
    It 'Should return expected properties' {
        $ConfigProperties = ( Get-PSNeo4jConfiguration ).psobject.properties.name
        $ConfigProperties -contains 'BaseUri' | Should Be $True
        $ConfigProperties -contains 'Credential' | Should Be $True
        $ConfigProperties -contains 'Streaming' | Should Be $True
        $ConfigProperties -contains 'As' | Should Be $True
        $ConfigProperties -contains 'MetaProperties' | Should Be $True
        $ConfigProperties -contains 'MergePrefix' | Should Be $True
    }
}

Describe "Invoke-Neo4jQuery $PSVersion" {
    InModuleScope PSNeo4j {
        $TestDataPath = "$PSScriptRoot\Data"
        Mock New-Neo4jStatements {}
        Mock Get-Neo4jHeader {}
        Mock Invoke-RestMethod {}
        Mock ConvertFrom-Neo4jResponse {}
        It 'Should call appropriate commands internally' {
            $Response = Invoke-Neo4jQuery -Query 'ONE', 'TWO' -Parameters @{a=1;b=2} -as Raw
            Assert-MockCalled -CommandName New-Neo4jStatements -Times 1 -Exactly
            Assert-MockCalled -CommandName Get-Neo4jHeader -Times 1 -Exactly
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly
            Assert-MockCalled -CommandName ConvertFrom-Neo4jResponse -Times 1 -Exactly
        }
        
    }
}

<#
Describe "Set-PSNeo4jConfiguration $PSVersion" {
    It 'Should' {
        
        
    }
}
#>
Describe "Get-Neo4jActiveConfig $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call dbms.listConfig()' {
        Get-Neo4jActiveConfig
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL dbms.listConfig()'
        }
    }
}
<#
Describe "Invoke-Neo4jApi $PSVersion" {
    It 'Should' {

    }
}
#>

Describe "Get-Neo4jConstraint $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call db.constraints()' {
        Get-Neo4jConstraint
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL db.constraints()'
        }
    }
}

Describe "Remove-Neo4jConstraint $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Drop unique constraints on multiple properties' {
        Remove-Neo4jConstraint -Label a -Property b, c -Unique
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -contains 'DROP CONSTRAINT ON (l:a) ASSERT l.b IS UNIQUE' -and
            $Query -contains 'DROP CONSTRAINT ON (l:a) ASSERT l.c IS UNIQUE'
        }
    }
}

Describe "New-Neo4jConstraint $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Create unique constraints on multiple properties' {
        New-Neo4jConstraint -Label a -Property b, c -Unique
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -contains 'CREATE CONSTRAINT ON (l:a) ASSERT l.b IS UNIQUE' -and
            $Query -contains 'CREATE CONSTRAINT ON (l:a) ASSERT l.c IS UNIQUE'
        }
    }
}

Describe "Get-Neo4jFunction $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call dbms.functions()' {
        Get-Neo4jFunction
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL dbms.functions()'
        }
    }
}
<#
Describe "Get-Neo4jHeader $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call db.constraints()' {
        Get-Neo4jConstraint
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL db.constraints()'
        }
    }
}
#>
Describe "Remove-Neo4jIndex $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Drop individual indexes on multiple properties' {
        Remove-Neo4jIndex -Label a -Property b, c
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -contains 'DROP INDEX ON :a(b)' -and
            $Query -contains 'DROP INDEX ON :a(c)'
        }
    }
    It 'Drop composite indexes on multiple properties' {
        Remove-Neo4jIndex -Label a -Property b, c -Composite
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'DROP INDEX ON :a(b, c)'
        }
    }
}

Describe "Get-Neo4jIndex $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call db.indexes()' {
        Get-Neo4jIndex
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL db.indexes()'
        }
    }
}

Describe "New-Neo4jIndex $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Create individual indexes on multiple properties' {
        New-Neo4jIndex -Label a -Property b, c
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -contains 'CREATE INDEX ON :a(b)' -and
            $Query -contains 'CREATE INDEX ON :a(c)'
        }
    }
    It 'Create composite indexes on multiple properties' {
        New-Neo4jIndex -Label a -Property b, c -Composite
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CREATE INDEX ON :a(b, c)'
        }
    }
}

Describe "Get-Neo4jLabel $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call db.labels()' {
        Get-Neo4jLabel
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL db.labels()'
        }
    }
}

Describe "New-Neo4jNode $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should create a new node' {
        New-Neo4jNode -Label Service -PassThru -InputObject @{
            Name = 'Active Directory'
            Engineer = 'Warren Frame'
        }
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Statements[0].Statement -eq 'UNWIND {props} AS properties CREATE (node:Service) SET node = properties RETURN node' -and
            $Statements[0].Parameters.props[0].keys -contains 'Name' -and
            $Statements[0].Parameters.props[0].keys -contains 'Engineer' -and
            $Statements[0].Parameters.props[0]['Name'] -eq 'Active Directory' -and
            $Statements[0].Parameters.props[0]['Engineer'] -eq 'Warren Frame'
        }
    }
}

Describe "Set-Neo4jNode $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should create a well formed MERGE query by default' {
        Set-Neo4jNode -Label Server -Hash @{ Name = 'Server01'} -InputObject @{ Description = 'Some description!' }
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'MERGE (set:Server {Name: $merge0Name}) ON CREATE SET set = {Name: $merge0Name, Description: $extra0Description} ON MATCH SET set += {Description: $extra0Description}' -and
            $Parameters.keys -contains 'merge0Name' -and
            $Parameters.keys -contains 'extra0Description' -and
            $Parameters['merge0Name'] -eq 'Server01' -and
            $Parameters['extra0Description'] -eq 'Some description!'
        }
    }
    It 'Should create a well formed MATCH query if NoCreate is specified' {
        Set-Neo4jNode -Label Server -Hash @{ Name = 'Server01'} -InputObject @{ Description = 'Some description!' } -NoCreate
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'MATCH (set:Server {Name: $merge0Name}) SET set += {Description: $extra0Description}' -and
            $Parameters.keys -contains 'merge0Name' -and
            $Parameters.keys -contains 'extra0Description' -and
            $Parameters['merge0Name'] -eq 'Server01' -and
            $Parameters['extra0Description'] -eq 'Some description!'
        }
    }
}


<#

Describe "Remove-Neo4jNode $PSVersion" {
    It 'Should' {

    }
}

Describe "ConvertTo-Neo4jNodesStatement $PSVersion" {
    It 'Should' {

    }
}

Describe "ConvertTo-Neo4jNodeStatement $PSVersion" {
    It 'Should' {

    }
}
#>
Describe "Get-Neo4jProcedure $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call dbms.procedures()' {
        Get-Neo4jProcedure
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL dbms.procedures()'
        }
    }
}

Describe "Get-Neo4jPropertyKey $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call db.propertyKeys()' {
        Get-Neo4jPropertyKey
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL db.propertyKeys()'
        }
    }
}
<#
Describe "Remove-Neo4jRelationship $PSVersion" {
    It 'Should' {

    }
}

Describe "New-Neo4jRelationship $PSVersion" {
    It 'Should' {

    }
}
#>
Describe "Get-Neo4jRelationshipType $PSVersion" {
    Mock Invoke-Neo4jQuery -ModuleName PSNeo4j
    It 'Should call db.relationshipTypes()' {
        Get-Neo4jRelationshipType
        Assert-MockCalled Invoke-Neo4jQuery -ModuleName PSNeo4j -Exactly 1 -Scope It -ParameterFilter {
            $Query -eq 'CALL db.relationshipTypes()'
        }
    }
}

Describe "ConvertFrom-Neo4jResponse $PSVersion" {
    # Import response each time in case we mistakenly modify it in the convertfrom function
    It 'Should return raw output if specified' {
        $Response = Import-Clixml "$TestDataPath\Nodes.xml"
        $Parsed = ConvertFrom-Neo4jResponse -Response $Response -As Raw
        $Parsed | Should be $Response
    }
    It 'Should return results if specified' {
        $Response = Import-Clixml "$TestDataPath\Nodes.xml"
        $Parsed = ConvertFrom-Neo4jResponse -Response $Response -As Results
        $Parsed | Should be $Response.results
    }
    It 'Should return row output if specified' {
        $Response = Import-Clixml "$TestDataPath\Nodes.xml"
        $Parsed = ConvertFrom-Neo4jResponse -Response $Response -As Row
        $Parsed | Should be $Response.results.data.row
    }
    It 'Should return parsed output if specified' {
        $Response = Import-Clixml "$TestDataPath\Nodes.xml"
        $Parsed = @(ConvertFrom-Neo4jResponse -Response $Response -As Parsed)
        $Parsed.Count | Should Be 3
        $Parsed[0].ComputerName | Should Be 'dc01'
        $Parsed[0].Domain | Should Be 'some.domain'
        $Parsed[0].Neo4jType | Should Be 'node'
        $Parsed[0].Neo4jColumn | Should Be 'n'
        $Parsed[0].PSObject.Properties.Name.Count | Should be 4
        $Parsed[1].ComputerName | Should Be 'dc02'
        $Parsed[1].Domain | Should Be 'some.domain'
        $Parsed[1].Neo4jType | Should Be 'node'
        $Parsed[1].Neo4jColumn | Should Be 'n'
        $Parsed[1].PSObject.Properties.Name.Count | Should be 4
        $Parsed[2].ComputerName | Should Be 'web01'
        $Parsed[2].Domain | Should Be 'some.domain'
        $Parsed[2].Neo4jType | Should Be 'node'
        $Parsed[2].Neo4jColumn | Should Be 'n'
        $Parsed[2].PSObject.Properties.Name.Count | Should be 4
    }
    It 'Should parse cases where columns are returned with no data' {
        $Response = Import-Clixml "$TestDataPath\Function.ColumnsOnly.xml"
        $Parsed = @(ConvertFrom-Neo4jResponse -Response $Response -As Parsed)
        $Parsed.count | Should Be 3
        $Parsed[0].Neo4jColumn | Should be 'Name'
        $Parsed[0].Neo4jData | Should BeNullOrEmpty
        $Parsed[0].PSObject.Properties.Name.Count | Should Be 2
        $Parsed[1].Neo4jColumn | Should be 'Signature'
        $Parsed[1].Neo4jData | Should BeNullOrEmpty
        $Parsed[1].PSObject.Properties.Name.Count | Should Be 2
        $Parsed[2].Neo4jColumn | Should be 'Description'
        $Parsed[2].Neo4jData | Should BeNullOrEmpty
        $Parsed[2].PSObject.Properties.Name.Count | Should Be 2
    }
    It 'SHould parse errors' {
        $Response = Import-Clixml "$TestDataPath\Error.xml"
        $e = $null
        $Parsed = ConvertFrom-Neo4jResponse -Response $Response -As Parsed -ErrorVariable e -ErrorAction SilentlyContinue
        $e.Count | Should Be 1
        $e[0].FullyQualifiedErrorId | Should BeLike 'Neo.ClientError.Statement.SyntaxError,ConvertFrom-Neo4j*'
        $e[0].Exception.Message | Should BeLike 'Query cannot conclude with MATCH (must be RETURN or an update clause) (line 1, column 1 (offset: 0))*'
    }
}
<#
Describe "New-Neo4jStatements $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jUser $PSVersion" {
    It 'Should' {

    }
}
#>