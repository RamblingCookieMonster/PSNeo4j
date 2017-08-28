function Add-Neo4jNode {
    [cmdletbinding()]
    param(
        [string]$Label,
        [parameter(ValueFromPipeline=$True)]
        [object[]]$InputObject,
        [switch]$Passthru,
        [switch]$Compress,

        [switch]$Raw,
        [switch]$ExpandResults,
        [switch]$ExpandRow,

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
        $Statements = ConvertTo-Neo4jNodesStatement -InputObject $Objects -Label $Label -Passthru:$Passthru -Compress:$Compress
        $Params = . Get-ParameterValues -Properties Raw, DontExpandData, ExpandRow, MergeMeta, Credential
        Write-Verbose "$($Params | Format-List | Out-String)"
        Invoke-Neo4jQuery @Params -Statements $Statements
    }
}