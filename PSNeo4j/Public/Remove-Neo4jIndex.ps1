function Remove-Neo4jIndex {
    [cmdletbinding()]
    param(
        [string]$Label, # Injection alert
        [string[]]$Property, # Injection alert
        [switch]$Composite,

        [switch]$Raw,
        [switch]$ExpandResults,
        [switch]$ExpandRow,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties,
        [string]$MergePrefix = 'Neo4j',

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential  
    )

    $InvokeParams = @{}
    if($Composite) {
        $Query = "DROP INDEX ON :$Label($($Property -join ', '))"
    }
    else {
        $Query = foreach($Prop in $Property) {
            "DROP INDEX ON :$Label($Prop)"
        }
    }
    $InvokeParams.add('Query', $Query)
    Write-Verbose "Query: [$Query]"
    $Params = . Get-ParameterValues -Properties Raw, ExpandResults, ExpandRow, MetaProperties, MergePrefix
    Invoke-Neo4jQuery @Params @InvokeParams
}