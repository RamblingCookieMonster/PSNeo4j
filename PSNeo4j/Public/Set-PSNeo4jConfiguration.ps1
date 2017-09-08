function Set-PSNeo4jConfiguration {
    <#
    .SYNOPSIS
       Set PSNeo4j configuration values

    .DESCRIPTION
       Set PSNeo4j configuration values

    .EXAMPLE
        Set-PSNeo4jConfiguration -Credential $Credential

        # Specify a default credential to use for PSNeo4j commands

    .PARAMETER Scope
        Which scope to serialize configuration to, when UpdateConfig is $True (default).

        Defaults to 'User', allowing us to serialize credentials
    
    .PARAMETER UpdateConfig
        Whether to update the configuration file on top of the live module values

        Defaults to $True
    
    .PARAMETER Streaming
        Transmits responses from HTTP API as JSON streams (better performance, lower memory overhead on the server)

        Defaults to $True

    .PARAMETER As
        Parse the Neo4j response as...
            Parsed:  We attempt to parse the output into friendlier PowerShell objects
                     Please open an issue if you see unexpected output with this
            Raw:     We don't touch the response                           ($Response)
            Results: We expand the 'results' property on the response      ($Response.results)
            Row:     We expand the 'row' property on the responses results ($Response.results.data.row)

        We default to 'Parsed' initially

        See ConvertFrom-Neo4jResponse for implementation details
    
    .PARAMETER MetaProperties
        Merge zero or any combination of these corresponding meta properties in the results: 'id', 'type', 'deleted'

        We default to 'type' initially
    
    .PARAMETER MergePrefix
        If any MetaProperties are specified, we add this prefix to avoid clobbering existing neo4j properties

        We default to 'Neo4j' initially
    
    .PARAMETER BaseUri
        BaseUri to build REST endpoint Uris from

        We default to 'http://127.0.0.1:7474' initially
    
    .PARAMETER Credential
        PSCredential to use for auth

        No initial default ([System.Management.Automation.PSCredential]::Empty)
    
    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
        $BaseUri,
        [bool]$Streaming,
        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As,
        [validateset('id', 'type', 'deleted')]
        [string[]]$MetaProperties,
        [string]$MergePrefix,

        [ValidateSet("User", "Machine", "Enterprise")]
        [string]$Scope = "User",
        [bool]$UpdateConfig = $True
    )

    Switch ($PSBoundParameters.Keys)
    {
        'Credential' { $Script:PSNeo4jConfig.Credential = $Credential }
        'BaseUri' { $Script:PSNeo4jConfig.BaseUri = $BaseUri }
        'Streaming' { $Script:PSNeo4jConfig.Streaming = $Streaming }
        'As' { $Script:PSNeo4jConfig.As = $As }
        'MetaProperties' { $Script:PSNeo4jConfig.MetaProperties = $MetaProperties }
        'MergePrefix' { $Script:PSNeo4jConfig.MergePrefix = $MergePrefix }
    }

    if($UpdateConfig)
    {
        $Script:PSNeo4jConfig | Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
    }
}