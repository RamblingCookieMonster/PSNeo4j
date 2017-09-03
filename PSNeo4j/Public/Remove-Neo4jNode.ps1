function Remove-Neo4jNode {
    [cmdletbinding()]
    param(
        [string]$Label,
        [parameter(ValueFromPipeline=$True)]
        [hashtable[]]$Hash,
        [switch]$Detach,
        [switch]$Passthru,

        [validateset('Raw', 'Results', 'Row', 'Parsed')]
        [string]$As = 'Parsed',
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties,
        [string]$MergePrefix = 'Neo4j',

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential  
    )
    begin {
        $DetachString = $null
        if($Detach) {$DetachString = 'DETACH '}
        write-verbose "$Detach and [$DetachString]"
        $Queries = [System.Collections.ArrayList]@()
        $Count = 0
    }
    process {
        foreach($PropHash in $Hash)
        {
            $InvokeParams = @{}
            $SQLParams = @{}
            $PropString = $null
            if($Hash.keys.count -gt 0) {
                $Props = foreach($Property in $PropHash.keys) {
                    "$Property`: `$delete$Count$Property"
                    $SQLParams.Add("delete$Count$Property", $PropHash[$Property])
                }
                $PropString = $Props -join ', '
                $PropString = "{$PropString}"
            }
            $Query = "MATCH (delete:$Label $PropString)"
            $Count++

            [void]$Queries.Add("$Query $DetachString DELETE delete")
        }
    }
    end {
        if($SQLParams.Keys.count -gt 0) {
            $InvokeParams.add('Parameters', $SQLParams)
        }
        $InvokeParams.add('Query', $Queries)

        $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
        Write-Verbose "$($Params | Format-List | Out-String)"
        Invoke-Neo4jQuery @Params @InvokeParams
    }
}