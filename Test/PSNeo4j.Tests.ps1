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

Describe "Get-Neo4jActiveConfig $PSVersion" {
    It 'Should' {

    }
}

Describe "Invoke-Neo4jApi $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jConstraint $PSVersion" {
    It 'Should' {

    }
}

Describe "Remove-Neo4jConstraint $PSVersion" {
    It 'Should' {

    }
}

Describe "New-Neo4jConstraint $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jFunction $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jHeader $PSVersion" {
    It 'Should' {

    }
}

Describe "Remove-Neo4jIndex $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jIndex $PSVersion" {
    It 'Should' {

    }
}

Describe "New-Neo4jIndex $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jLabel $PSVersion" {
    It 'Should' {

    }
}

Describe "New-Neo4jNode $PSVersion" {
    It 'Should' {

    }
}

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

Describe "Get-Neo4jProcedure $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jPropertyKey $PSVersion" {
    It 'Should' {

    }
}

Describe "Remove-Neo4jRelationship $PSVersion" {
    It 'Should' {

    }
}

Describe "New-Neo4jRelationship $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jRelationshipType $PSVersion" {
    It 'Should' {

    }
}

Describe "ConvertFrom-Neo4jResponse $PSVersion" {
    It 'Should' {

    }
}

Describe "New-Neo4jStatements $PSVersion" {
    It 'Should' {

    }
}

Describe "Get-Neo4jUser $PSVersion" {
    It 'Should' {

    }
}
#>