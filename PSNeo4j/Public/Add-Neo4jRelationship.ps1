function Add-Neo4jRelationship {
    [cmdletbinding()]
    param(
        $LeftMatch,
        $RightMatch,

        $LeftLabel,
        $LeftHash,
        $RightLabel,
        $RightHash,

        $Type,
        [hashtable]$Properties,

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

    $Statements = ConvertTo-Neo4jNodesStatement -InputObject $Objects -Label $Label -Passthru:$Passthru -Compress:$Compress
    $Params = . Get-ParameterValues -Properties Raw, ExpandRow, ExpandResults, Credential
    Write-Verbose "$($Params | Format-List | Out-String)"
    Invoke-Neo4jQuery @Params -Statements $Statements
}