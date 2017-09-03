function New-Neo4jIndex {
    [cmdletbinding()]
    param(
        [string]$Label, # Injection alert
        [string[]]$Property, # Injection alert
        [switch]$Composite,

        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As = 'Parsed',
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
        $Query = "CREATE INDEX ON :$Label($($Property -join ', '))"
    }
    else {
        $Query = foreach($Prop in $Property) {
            "CREATE INDEX ON :$Label($Prop)"
        }
    }
    $InvokeParams.add('Query', $Query)
    Write-Verbose "Query: [$Query]"
    $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Invoke-Neo4jQuery @Params @InvokeParams
}