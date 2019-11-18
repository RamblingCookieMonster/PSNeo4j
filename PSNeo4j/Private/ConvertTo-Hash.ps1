Function ConvertTo-Hash()
{
    <#
    .SYNOPSIS
       Convert PSObject to a Hash Table for use with internal object

    .DESCRIPTION
       Convert PSObject to a Hash Table for use with internal object

    .EXAMPLE
        $SomePSObject | Select-Object name | ConvertTo-Hash
    #>
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True)]
        [pscustomobject]$PSCustomObject
    )
    process {
        $PSCustomObject.psobject.properties | % { $HashTable = @{} } { $HashTable[$_.Name] = $_.Value } { $HashTable }
    }
}