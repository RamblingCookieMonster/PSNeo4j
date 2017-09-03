function Invoke-Neo4jApi {
    [cmdletbinding()]
    param(
        [string]$Method = 'Get',
        [string]$RelativeUri,
        [hashtable]$Body,
        
        [switch]$Raw,
        [switch]$ExpandResults,
        [switch]$ExpandRow,
        [validateset('id', 'type', 'deleted')]
        [string]$MetaProperties,
        [string]$MergePrefix = 'Neo4j',

        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential  
    )
    $Params = @{
        Headers = Get-Neo4jHeader -Credential $Credential
        Method = $Method
        Uri = "$BaseUri/$RelativeUri"
        Body = $Body
        ErrorAction = 'Stop'
    }
    Write-Verbose "$($Params | Format-List | Out-String)"
    $Response = Invoke-RestMethod @Params
    Write-Verbose "Params is $($ConvertParams | Format-List | Out-String)"
    $ConvertParams = . Get-ParameterValues -Properties Raw, ExpandResults, ExpandRow, MetaProperties, MergePrefix
    ConvertFrom-Neo4jResponse @ConvertParams -Response $Response 
}