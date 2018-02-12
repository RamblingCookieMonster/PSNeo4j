function Initialize-PSNeo4jConfiguration {
    <#
    .SYNOPSIS
       Initializes PSNeo4j configuration values

    .DESCRIPTION
       Initializes PSNeo4j configuration values

       In cases where we've updated configuration schema, this will bring new values in line with the defaults

       Default types and values are stored in PSNeo4j.ConfigSchema.ps1 in the module root

    .PARAMETER Streaming
        Whether to initialize Streaming back to $True

    .PARAMETER As
        Whether to initialize As back to 'Parsed'

    .PARAMETER MetaProperties
        Whether to initialize MetaProperties back to 'type'

    .PARAMETER MergePrefix
        Whether to initialize MergePrefix back to 'Neo4j'

    .PARAMETER BaseUri
        Whether to initialize BaseUri back to 'http://127.0.0.1:7474'

    .PARAMETER Credential
        Whether to initialize Credential back to username: neo4j password: neo4j

    .PARAMETER CheckExisting
        If specified, check existing configuration types and reset anything that doesn't make sense

    .PARAMETER Passthru
        If specified, return configuration

    .PARAMETER Scope
        Which scope to serialize configuration to, when UpdateConfig is $True (default).

        Defaults to 'User', allowing us to serialize credentials

    .PARAMETER UpdateConfig
        Whether to update the configuration file on top of the live module values

        Defaults to $True

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [switch]$Credential,
        [switch]$BaseUri,
        [switch]$Streaming,
        [switch]$As,
        [switch]$MetaProperties,
        [switch]$MergePrefix,
        [bool]$CheckExisting = $True,
        [object]$ConfigSchema = $Script:ConfigSchema,
        [switch]$Passthru,
        [string]$Scope = 'User',
        [bool]$UpdateConfig = $True
    )

    if($UpdateConfig -and $SkipConfig) {
        Write-Warning "Configuration module not available. Config will not be updated"
        $UpdateConfig = $False
    }

    $ConfigKeys = $ConfigSchema.PSObject.Properties.Name
    if($CheckExisting) {
        foreach($Property in $ConfigKeys) {
            if($Script:PSNeo4jConfig.$Property -isnot $ConfigSchema.$Property.Type) {
                $Script:PSNeo4jConfig.$Property = $ConfigSchema.$Property.Default
            }
        }
    }
    foreach($Key in $PSBoundParameters.Keys) {
        if($ConfigKeys -contains $Key) {
            $Script:PSNeo4jConfig.$Key = $ConfigSchema.$Key.Default
        }
    }

    if($UpdateConfig) {
        if($SkipCred) {
            $Script:PSNeo4jConfig |
                Select-Object -Property * -ExcludeProperty Credential |
                Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
        }
        else {
            $Script:PSNeo4jConfig | Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
        }
    }
    if($Passthru) {
        [pscustomobject]$Script:PSNeo4jConfig | Select-Object $ConfigSchema.PSObject.Properties.Name
    }
}