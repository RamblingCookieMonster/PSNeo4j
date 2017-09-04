function Add-Neo4jRelationship {
    [cmdletbinding(DefaultParameterSetName = 'LabelHash')]
    param(
        [parameter( ParameterSetName = 'LabelHash',
                    Mandatory = $True )]
        $LeftLabel,
        [parameter( ParameterSetName = 'LabelHash' )]
        $LeftHash,
        [parameter( ParameterSetName = 'LabelHash',
                    Mandatory = $True )]
        $RightLabel,
        [parameter( ParameterSetName = 'LabelHash')]
        $RightHash,

        [parameter( ParameterSetName = 'Query',
                    Mandatory = $True )]
        $LeftQuery,
        [parameter( ParameterSetName = 'Query',
                    Mandatory = $True )]
        $RightQuery,

        $Type,
        [hashtable]$Properties,

        [validateset('CREATE', 'MERGE')]
        [string]$Statement = 'MERGE',

        [switch]$Passthru,

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
    $SQLParams = @{}

    if($PSCmdlet.ParameterSetName -eq 'LabelHash') {
        $LeftPropString = $null
        if($LeftHash.keys.count -gt 0) {
            $Props = foreach($Property in $LeftHash.keys) {
                "$Property`: `$left$Property"
                $SQLParams.Add("left$Property", $LeftHash[$Property])
            }
            $LeftPropString = $Props -join ', '
            $LeftPropString = "{$LeftPropString}"
        }
        $LeftQuery = "MATCH (left:$LeftLabel $LeftPropString)"

        $RightPropString = $null
        if($RightHash.keys.count -gt 0) {
            $Props = foreach($Property in $RightHash.keys) {
                "$Property`: `$right$Property"
                $SQLParams.Add("right$Property", $RightHash[$Property])
            }
            $RightPropString = $Props -join ', '
            $RightPropString = "{$RightPropString}"
        }
        $RightQuery = "MATCH (right:$RightLabel $RightPropString)"
    }

    if($Passthru) {
        $Return = 'RETURN relationship'
    }
    $InvokeParams = @{}
    $PropString = $null
    if($Properties) {
        $Props = foreach($Property in $Properties.keys) {
            "$Property`: `$relationship$Property"
            $SQLParams.Add("relationship$Property", $Properties[$Property])
        }
        $PropString = $Props -join ', '
        $PropString = "{$PropString}"
    }
    
    if($SQLParams.Keys.count -gt 0) {
        $InvokeParams.add('Parameters', $SQLParams)
    }

    $Query = @"
$LeftQuery
$RightQuery
$Statement (left)-[relationship:$Type $PropString]->(right)
$Return
"@
    $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Write-Verbose "$($Params | Format-List | Out-String)"
    Invoke-Neo4jQuery @Params @InvokeParams -Query $Query
}