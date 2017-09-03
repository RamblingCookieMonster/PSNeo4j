function Set-PSNeo4jConfiguration {
    [cmdletbinding()]
    param(
        $Credential,
        $BaseUri,
        [ValidateSet("User", "Machine", "Enterprise")]
        [string]$Scope = "User",
        [bool]$UpdateConfig = $True
    )

    Switch ($PSBoundParameters.Keys)
    {
        'Credential' { $Script:PSNeo4jConfig.Credential = $Credential }
        'BaseUri' { $Script:PSNeo4jConfig.BaseUri = $BaseUri }
    }

    if($UpdateConfig)
    {
        $Script:PSNeo4jConfig | Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
    }
}