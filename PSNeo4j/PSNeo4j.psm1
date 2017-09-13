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

# Deal with non-Windows...
try {
    $SkipCred = $False
    $SkipConfig = $False
    $ConfigModule = Join-Path $ModuleRoot "Private\Modules\Configuration"
    $ImportParams = @{
        Name = $ConfigModule
        Force = $True
        ErrorAction = 'Stop'
    }
    if($IsLinux -or $IsOSX) {
        $SkipCred = $True
        $Data = "~/.local/share"
        $EvaluatedPath  = Join-Path $Data WindowsPowerShell
        if(-not (Test-Path $EvaluatedPath)) {
            New-Item -ItemType Directory -Path $EvaluatedPath -Force
        }
        $ImportParams.Add('ArgumentList', @(@{}, "$Data", "$Data", "$Data"))
    }
    Import-Module @ImportParams
}
catch {
    $SkipConfig = $True
    Write-Error $_
    Write-Warning "Failed to load Configuration module, Set-PSNeo4jConfiguration will not write to a config file"
}

try {
    $ConfigSchema = . "$PSScriptRoot\PSNeo4j.ConfigSchema.ps1"
    if(-not $SkipConfig) {
        $Config = Import-Config -ErrorAction Stop
        $PSNeo4jConfig = [pscustomobject]$Config | Select-Object $ConfigSchema.PSObject.Properties.Name
    }
}
catch {
    $PSNeo4jConfig = [pscustomobject]@{}
    Foreach($Property in $ConfigSchema.PSObject.Properties.Name) {
        Add-Member -MemberType NoteProperty -InputObject $PSNeo4jConfig -Name $Property -Value $null -Force
    }
    Write-Warning $_
}
finally {
    $PSNeo4jConfig = Initialize-PSNeo4jConfiguration -Passthru -ConfigSchema $ConfigSchema -UpdateConfig $False
}

Export-ModuleMember -Function $Public.Basename