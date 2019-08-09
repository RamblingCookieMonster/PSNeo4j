[pscustomobject]@{
    BaseUri = @{
        Type = [string]
        Default = 'http://127.0.0.1:7474'
    }
    Credential = @{
        Type = [System.Management.Automation.PSCredential]
        Default = New-Object System.Management.Automation.PSCredential('neo4j',$(ConvertTo-SecureString 'neo4j' -asPlainText -Force))
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
    ParseDate = @{
        Type = [string]
        Default = 'NoParse'
    }
    ParseDatePatterns = @{
        Type = [string[]]
        Default = 'DateTimeO', 'DateWithEpochMs'
    }
    ParseDateInput = @{
        Type = [System.Boolean]
        Default = $True
    }
}