function Add-Neo4jNode {
    [cmdletbinding()]
    param(
        [string]$Label,
        [parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [switch]$Passthru,

        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential  
    )
    begin {
        $Objects = [System.Collections.ArrayList]@()
    }
    process {
        foreach($Object in $InputObject) {
            [void]$Objects.add($Object)
        }
    }
    end {
        $Statements = ConvertTo-Neo4jNodesStatement -InputObject $Objects -Label $Label -Passthru:$Passthru
        $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
        Write-Verbose "$($Params | Format-List | Out-String)"
        Invoke-Neo4jQuery @Params -Statements $Statements
    }
}