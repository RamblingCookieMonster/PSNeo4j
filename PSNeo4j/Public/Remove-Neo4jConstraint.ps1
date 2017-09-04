function Remove-Neo4jConstraint {
    [cmdletbinding(DefaultParameterSetName = 'Node')]
    param(
        [parameter(ParameterSetName = 'Node')]
        [string]$Label, # Injection alert
        [parameter(ParameterSetName = 'Relationship')]
        [string]$Relationship, # Injection alert
        [string[]]$Property, # Injection alert
        
        [parameter(ParameterSetName = 'Node')]
        [switch]$Unique,
        [parameter(ParameterSetName = 'Node')]
        [switch]$Exists,

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
    $Query = [System.Collections.ArrayList]@()
    if($PSCmdlet.ParameterSetName -eq 'Node') {
        if($Unique) {
            Foreach($Prop in $Property) {
                [void]$Query.add("DROP CONSTRAINT ON (l:$Label) ASSERT l.$Prop IS UNIQUE")
            }            
        }
        If($Exists) {
            Foreach($Prop in $Property) {
                # Requires enterprise. Interesting
                [void]$Query.add("DROP CONSTRAINT ON (l:$Label) ASSERT exists(l.$Prop)")
            }
        }
    }
    if($PSCmdlet.ParameterSetName -eq 'Relationship') {
        Foreach($Prop in $Property) {
            # Requires enterprise. Interesting
            [void]$Query.add("DROP CONSTRAINT ON ()-[l:$Relationship]-() ASSERT exists(l.$Prop)")
        }
    }

    Write-Verbose "Query: [$Query]"
    $Params = . Get-ParameterValues -Properties MetaProperties, MergePrefix, Credential, BaseUri, As
    Invoke-Neo4jQuery @Params -Query $Query
}