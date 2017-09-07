#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
    $ModuleRoot = $PSScriptRoot

#Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Foreach ($Module in (Get-ChildItem $ModuleRoot\Private\Modules -Directory)) {
    Import-Module $Module.FullName -Force
}

try {
    $Config = Import-Config -ErrorAction Stop
    $PSNeo4jConfig = [pscustomobject]$Config | Select-Object BaseUri, Credential, As, MetaProperties, MergePrefix
}
catch {
    $PSNeo4jConfig = [pscustomobject]@{
        Credential = [System.Management.Automation.PSCredential]::Empty
        BaseUri = 'http://127.0.0.1:7474'
        As = 'Parsed'
        MetaProperties = @('Type')
        MergePrefix = 'Neo4j'
    }
}

Export-ModuleMember -Function $Public.Basename