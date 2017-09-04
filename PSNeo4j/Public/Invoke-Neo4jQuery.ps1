function Invoke-Neo4jQuery {
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

        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As = $PSNeo4jConfig.As,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties = $PSNeo4jConfig.MetaProperties,
        [string]$MergePrefix = $PSNeo4jConfig.MergePrefix,

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
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
        $ConvertParams = . Get-ParameterValues -Properties MetaProperties, MergePrefix, As
        Write-Verbose "Params is $($ConvertParams | Format-List | Out-String)"
        ConvertFrom-Neo4jResponse @ConvertParams -Response $Response 
    }
}