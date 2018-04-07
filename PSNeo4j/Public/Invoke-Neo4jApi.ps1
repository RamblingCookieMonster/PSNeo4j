function Invoke-Neo4jApi {
    <#
    .SYNOPSIS
       Simple wrapper to invoke Neo4j API queries

    .DESCRIPTION
       Simple wrapper to invoke Neo4j API queries

    .EXAMPLE
        Invoke-Neo4jApi -RelativeUri user/neo4j

        # Query the user endpoint for the neo4j user

    .PARAMETER RelativeUri
        Relative endpoint for the API, we append this to BaseUri

        Example to hit http://127.0.0.1:7474/user/neo4j
          -BaseUri     http://127.0.0.1:7474
          -RelativeUri user/neo4j

    .PARAMETER Method
        Specifies the method used for the web request. Defaults to Get.

        The acceptable values for this parameter are:

        - Default
        - Delete
        - Get
        - Head
        - Merge
        - Options
        - Patch
        - Post
        - Put
        - Trace

    .PARAMETER Body
        Specifies the body of the request. The body is the content of the request that follows the headers.

        The Body parameter can be used to specify a list of query parameters or specify the content of the response.

        When the input is a GET request, and the body is an IDictionary (typically, a hash table), the body is added to the URI as query parameters. For other request
        types (such as POST), the body is set as the value of the request body in the standard name=value format.

    .PARAMETER As
        Parse the Neo4j response as...
            Parsed:  We attempt to parse the output into friendlier PowerShell objects
                     Please open an issue if you see unexpected output with this
            Raw:     We don't touch the response                           ($Response)
            Results: We expand the 'results' property on the response      ($Response.results)
            Row:     We expand the 'row' property on the responses results ($Response.results.data.row)

        We default 'Raw'

        See ConvertFrom-Neo4jResponse for implementation details for 'Parsed'

    .PARAMETER MetaProperties
        Merge zero or any combination of these corresponding meta properties in the results: 'id', 'type', 'deleted'

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'type')

    .PARAMETER MergePrefix
        If any MetaProperties are specified, we add this prefix to avoid clobbering existing neo4j properties

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'Neo4j')

    .PARAMETER BaseUri
        BaseUri to build REST endpoint Uris from

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'http://127.0.0.1:7474')

    .PARAMETER Credential
        PSCredential to use for auth

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, neo4j:neo4j)

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'Get',
        [string]$RelativeUri,
        [object]$Body,

        [validateset('Raw', 'Results', 'Row', 'Parsed', 'ParsedColumns')]
        [string]$As = 'Raw',
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential
    )
    $Params = @{
        Headers = Get-Neo4jHeader -Credential $Credential
        Method = $Method
        Uri = Join-Parts -Parts $BaseUri, $RelativeUri -DontTrimSeparator
        Body = $Body
        ErrorAction = 'Stop'
    }
    Write-Verbose "$($Params | Format-List | Out-String)"
    $Response = $null
    $Response = Invoke-RestMethod @Params
    Write-Verbose "Params is $($ConvertParams | Format-List | Out-String)"
    $ConvertParams = . Get-ParameterValues -BoundParameters $PSBoundParameters -Invocation $MyInvocation -Properties MetaProperties, MergePrefix, As
    ConvertFrom-Neo4jResponse @ConvertParams -Response $Response
}