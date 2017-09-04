function Remove-Neo4jRelationship {
    [cmdletbinding(DefaultParameterSetName = 'LabelHash')]
    param(
        [parameter( ParameterSetName = 'LabelHash')]
        $LeftLabel,
        [parameter( ParameterSetName = 'LabelHash')]
        $LeftHash,
        [parameter( ParameterSetName = 'LabelHash')]
        $RightLabel,
        [parameter( ParameterSetName = 'LabelHash')]
        $RightHash,

        [parameter( ParameterSetName = 'Query' )]
        $LeftQuery,
        [parameter( ParameterSetName = 'Query' )]
        $RightQuery,

        $Type,
        [hashtable]$Properties,

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
    $LeftVar = $null
    $RightVar = $null
    if($PSCmdlet.ParameterSetName -eq 'LabelHash') {
        $LeftQuery = $null
        if($LeftLabel) {
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
        }

        $RightQuery = $null
        if($RightLabel) {
            $RightPropString = $null
            if($RightHash.keys.count -gt 0 -and $RightLabel) {
                $Props = foreach($Property in $RightHash.keys) {
                    "$Property`: `$right$Property"
                    $SQLParams.Add("right$Property", $RightHash[$Property])
                }
                $RightPropString = $Props -join ', '
                $RightPropString = "{$RightPropString}"
            }
            $RightQuery = "MATCH (right:$RightLabel $RightPropString)"
        }
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

    if($LeftQuery) {$LeftVar = 'left'}
    if($RightQuery) {$RightVar = 'right'}
    $Query = @"
$LeftQuery
$RightQuery
MATCH ($LeftVar)-[relationship:$Type $PropString]->($RightVar)
DELETE relationship
"@
    $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Write-Verbose "$($Params | Format-List | Out-String)"
    Invoke-Neo4jQuery @Params @InvokeParams -Query $Query
}