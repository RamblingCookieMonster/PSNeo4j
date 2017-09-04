function Set-PSNeo4jConfiguration {
    [cmdletbinding()]
    param(
        $Credential,
        $BaseUri,
        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties,
        [string]$MergePrefix,

        [ValidateSet("User", "Machine", "Enterprise")]
        [string]$Scope = "User",
        [bool]$UpdateConfig = $True
    )

    Switch ($PSBoundParameters.Keys)
    {
        'Credential' { $Script:PSNeo4jConfig.Credential = $Credential }
        'BaseUri' { $Script:PSNeo4jConfig.BaseUri = $BaseUri }
        'As' { $Script:PSNeo4jConfig.As = $As }
        'MetaProperties' { $Script:PSNeo4jConfig.MetaProperties = $MetaProperties }
        'MergePrefix' { $Script:PSNeo4jConfig.MergePrefix = $MergePrefix }
    }

    if($UpdateConfig)
    {
        $Script:PSNeo4jConfig | Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
    }
}