function Get-PSNeo4jConfiguration {
    param(
        [validateset('Variable','Config')]
        [string]$Source = "Variable"
    )
    if($Source -eq 'Config') {
        $Config = Import-Configuration -CompanyName 'NA' -Name 'NA'
        [pscustomobject]$Config | Select BaseUri, Credential, As, MetaProperties, MergePrefix
    }
    if($Source -eq 'Variable') {
        $Script:PSNeo4jConfig
    }
}