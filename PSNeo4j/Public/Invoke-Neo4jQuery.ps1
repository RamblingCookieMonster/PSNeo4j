function Invoke-Neo4jQuery {
    <#
    .SYNOPSIS
       Invoke Neo4j Cypher queries

    .DESCRIPTION
       Invoke Neo4j Cypher queries

       Simplifies queries against the transactional Cypher HTTP endpoint.
       Begins and commits a transaction in one request via $BaseUri/db/data/transaction/commit

    .EXAMPLE
        Invoke-Neo4jQuery -Query "MATCH (n) RETURN n"

        # A simple query

    .EXAMPLE
        Invoke-Neo4jQuery -Query "MATCH (n:Server) WHERE n.ComputerName = `$ComputerName RETURN n" -Parameters @{ComputerName = 'dc01'}

        # A simple query with parameters

    .PARAMETER Statements
        One or more statements (hashtable or objects work) to invoke in a single 'Statements' call

        Generally, the Query/Parameters parameters are simpler to use

        Details: http://neo4j.com/docs/developer-manual/current/http-api/#rest-api-execute-multiple-statements

    .PARAMETER Query
        One or more Cypher queries to invoke

        Be sure to escape any $ signs used for parameters

    .PARAMETER Parameters
        Parameters to pass for the specified Cypher query

        Example:
            -Query "... blah.Something = `$Whatever..."
            -Parameters @{
                Whatever = 'This replaces $Whatever'
            }

    .PARAMETER As
        Parse the Neo4j response as...
            Parsed:        We attempt to parse the output into friendlier PowerShell objects...
                           for cases where Response.results includes data with rows of objects
            ParsedColumns: We attempt to parse the output into friendlier PowerShell objects...
                           for cases where Response.Results includes Columns and Data independently
            Raw:           We don't touch the response                           ($Response)
            Results:       We expand the 'results' property on the response      ($Response.results)
            Row:           We expand the 'row' property on the responses results ($Response.results.data.row)

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'Parsed')

        See ConvertFrom-Neo4jResponse for implementation details

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
    [cmdletbinding(DefaultParameterSetName = 'Query')]
    param(
        [parameter(ParameterSetName='Statements',
                   Position = 0,
                   Mandatory = $true)]
        [object[]]$Statements,

        [parameter(ParameterSetName='Query',
                   Position = 0,
                   Mandatory = $true)]
        [string[]]$Query,
        [parameter(ParameterSetName='Query',
                   Position = 1)]
        [hashtable]$Parameters,

        [validateset('Raw', 'Results', 'Row', 'Parsed', 'ParsedColumns')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential
    )
    begin {
        if($PSCmdlet.ParameterSetName -eq 'Query') {
            $AllStatements = [System.Collections.ArrayList]@()
        }
        else {
            $AllStatements = $Statements
        }
    }
    process {
        if($PSCmdlet.ParameterSetName -eq 'Query') {
            foreach($QueryString in $Query) {
                $Statement = [pscustomobject]@{
                    statement = $QueryString
                }
                if($PSBoundParameters.ContainsKey('Parameters')) {
                    Add-Member -InputObject $Statement -Name 'parameters' -Value $Parameters -MemberType NoteProperty
                }
                [void]$AllStatements.add($Statement)
            }
        }
    }
    end {
        $StatementsObject = New-Neo4jStatements -Statements $AllStatements
        $Params = @{
            Headers = Get-Neo4jHeader -Credential $Credential
            Method = 'Post'
            Uri = Join-Parts -Parts $BaseUri, 'db/data/transaction/commit'
            Body = ConvertTo-Json -InputObject $StatementsObject -Depth 10
            ErrorAction = 'Stop'
        }
        Write-Verbose "$($Params | Format-List | Out-String)"
        $Response = Invoke-RestMethod @Params
        $ConvertParams = . Get-ParameterValues -BoundParameters $PSBoundParameters -Invocation $MyInvocation -Properties MetaProperties, MergePrefix, As
        Write-Verbose "Params is $($ConvertParams | Format-List | Out-String)"
        ConvertFrom-Neo4jResponse @ConvertParams -Response $Response
    }
}