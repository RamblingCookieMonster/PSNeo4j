function Invoke-Neo4jApi {
    [cmdletbinding()]
    param(
        [string]$Method = 'Get',
        [string]$RelativeUri,
        [hashtable]$Body,
        
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
    $ConvertParams = . Get-ParameterValues -Properties MetaProperties, MergePrefix, As
    ConvertFrom-Neo4jResponse @ConvertParams -Response $Response 
}