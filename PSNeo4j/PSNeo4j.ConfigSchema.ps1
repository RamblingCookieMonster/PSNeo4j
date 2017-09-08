[pscustomobject]@{
    BaseUri = @{
        Type = [string]
        Default = 'http://127.0.0.1:7474'
    }
    Credential = @{
        Type = [System.Management.Automation.PSCredential]
        Default = [System.Management.Automation.PSCredential]::Empty
    }
    Streaming = @{
        Type = [System.Boolean]
        Default = $True
    }
    As = @{
        Type = [string]
        Default = 'Parsed'
    }
    MetaProperties = @{
        Type = [System.String[]]
        Default = 'type'
    }
    MergePrefix = @{
        Type = [string]
        Default = 'Neo4j'
    }
}