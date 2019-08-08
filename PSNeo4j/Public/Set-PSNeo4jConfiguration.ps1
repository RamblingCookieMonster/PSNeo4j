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
            Parsed:        We attempt to parse the output into friendlier PowerShell objects...
                           for cases where Response.results includes data with rows of objects
            ParsedColumns: We attempt to parse the output into friendlier PowerShell objects...
                           for cases where Response.Results includes Columns and Data independently
            Raw:           We don't touch the response                           ($Response)
            Results:       We expand the 'results' property on the response      ($Response.results)
            Row:           We expand the 'row' property on the responses results ($Response.results.data.row)

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

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, neo4j:neo4j)

    .PARAMETER ParseDate
        On Windows PowerShell, whether to inspect objects and attempt to parse properties that look like dates (e.g. '/Date(1526867499647)/')

        NoParse:   Don't parse.  Faster
        ByKeyword: Parse properties with 'Date' or 'Time' in their name
        ByValue:   Parse properties with value matching something like '/Date(1526867499647)/'

    .PARAMETER ParseDatePatterns
        How to parse properties that might be dates, if ParseDate is configured

        DateTimeO:       Parse properties with value in a format consistent with Get-Date -Format o (e.g. 2019-08-07T23:50:03.1734728-04:00)
        DateWithEpochMs: Parse properties with value in a format consistent with '/Date(1526867499647)/'

        Defaults to DateTimeO, DateWithEpochMS.  Not parsing, or parsing a single pattern may offer a small improvement to performance

    .PARAMETER ParseDateInput
        If specified, convert any datetime property on every object (nodes, relationships) to the format consistent with Get-Date -Format o

        This allows Neo4j to parse the string as a DateTime in queries

        Defaults to $True

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
        [validateset('Raw', 'Results', 'Row', 'Parsed', 'ParsedColumns')]
        [string]$As,
        [validateset('id', 'type', 'deleted')]
        [string[]]$MetaProperties,
        [string]$MergePrefix,
        [validateset('NoParse', 'ByKeyword', 'ByValue')]
        [string]$ParseDate,
        [validateset('DateWithEpochMs', 'DateTimeO')]
        [string[]]$ParseDatePatterns,
        [bool]$ParseDateInput,

        [ValidateSet("User", "Machine", "Enterprise")]
        [string]$Scope = "User",
        [bool]$UpdateConfig = $True
    )
    if($UpdateConfig -and $SkipConfig) {
        Write-Warning "Configuration module not available. Config will not be updated"
        $UpdateConfig = $False
    }
    Switch ($PSBoundParameters.Keys)
    {
        'Credential' { $Script:PSNeo4jConfig.Credential = $Credential }
        'BaseUri' { $Script:PSNeo4jConfig.BaseUri = $BaseUri }
        'Streaming' { $Script:PSNeo4jConfig.Streaming = $Streaming }
        'As' { $Script:PSNeo4jConfig.As = $As }
        'MetaProperties' { $Script:PSNeo4jConfig.MetaProperties = $MetaProperties }
        'MergePrefix' { $Script:PSNeo4jConfig.MergePrefix = $MergePrefix }
        'ParseDate' { $Script:PSNeo4jConfig.ParseDate = $ParseDate }
        'ParseDateInput' { $Script:PSNeo4jConfig.ParseDateInput = $ParseDateInput }
        'ParseDatePatterns' { $Script:PSNeo4jConfig.ParseDatePatterns = $ParseDatePatterns }
    }

    if($UpdateConfig)
    {
        if($SkipCred) {
            $Script:PSNeo4jConfig |
                Select-Object -Property * -ExcludeProperty Credential |
                Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
        }
        else {
            $Script:PSNeo4jConfig | Export-Configuration -Scope $Scope -CompanyName 'NA' -Name 'NA'
        }
    }
}
