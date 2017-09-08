function Initialize-PSNeo4jConfiguration {
    <#
    .SYNOPSIS
       Initializes PSNeo4j configuration values

    .DESCRIPTION
       Initializes PSNeo4j configuration values

       In cases where we've updated configuration schema, this will bring new values in line with the defaults
    
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
        Whether to initialize Credential back to [System.Management.Automation.PSCredential]::Empty

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

    if($CheckExisting) {
        foreach($Property in $ConfigSchema.PSObject.Properties.Name) {
            if($Script:PSNeo4jConfig.$Property -isnot $ConfigSchema.$Property.Type) {
                $Script:PSNeo4jConfig.$Property = $ConfigSchema.$Property.Default
            }
        }
    }

    Switch ($PSBoundParameters.Keys)
    {
        'Credential'     { $Script:PSNeo4jConfig.Credential = [System.Management.Automation.PSCredential]::Empty }
        'BaseUri'        { $Script:PSNeo4jConfig.BaseUri = 'http://127.0.0.1:7474' }
        'Streaming'      { $Script:PSNeo4jConfig.Streaming = $True }
        'As'             { $Script:PSNeo4jConfig.As = 'Parsed' }
        'MetaProperties' { $Script:PSNeo4jConfig.MetaProperties = @('Type') }
        'MergePrefix'    { $Script:PSNeo4jConfig.MergePrefix = 'Neo4j' }
    }
    if($UpdateConfig) {
        $Script:PSNeo4jConfig | Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
    }
    if($Passthru) {
        [pscustomobject]$Script:PSNeo4jConfig | Select $ConfigSchema.PSObject.Properties.Name
    }
}