# From Joel Bennett with minor modifications (filtering) - https://gist.githubusercontent.com/Jaykul/72f30dce2cca55e8cd73e97670db0b09/raw/96e47232ecabdf4c469e9df47fdd48ca560d3163/Get-ParameterValues.ps1
function Get-ParameterValues {
    <#
        .Synopsis
            Get the actual values of parameters which have manually set (non-null) default values or values passed in the call
        .Description
            Unlike $PSBoundParameters, the hashtable returned from Get-ParameterValues includes non-empty default parameter values.
            NOTE: Default values that are the same as the implied values are ignored (e.g.: empty strings, zero numbers, nulls).
        .Example
            function Test-Parameters {
                [CmdletBinding()]
                param(
                    $Name = $Env:UserName,
                    $Age
                )
                $Parameters = . Get-ParameterValues

                # This WILL ALWAYS have a value...
                Write-Host $Parameters["Name"]

                # But this will NOT always have a value...
                Write-Host $PSBoundParameters["Name"]
            }
    #>
    [CmdletBinding()]
    param(
        # The $MyInvocation for the caller -- DO NOT pass this (dot-source Get-ParameterValues instead)
        $Invocation = $MyInvocation,
        # The $PSBoundParameters for the caller -- DO NOT pass this (dot-source Get-ParameterValues instead)
        $BoundParameters = $PSBoundParameters,
        [string[]]$Properties
    )
    if($MyInvocation.Line[($MyInvocation.OffsetInLine - 1)] -ne '.') {
        throw "Get-ParameterValues must be dot-sourced, like this: . Get-ParameterValues"
    }
    $ParameterValues = @{}
    foreach($parameter in $Invocation.MyCommand.Parameters.GetEnumerator()) {
        # gm -in $parameter.Value | Out-Default
        try {
            $key = $parameter.Key
            if($Properties -like $Key) {
                if($null -ne ($value = Get-Variable -Name $key -ValueOnly -ErrorAction Ignore)) {
                    if($value -ne ($null -as $parameter.Value.ParameterType)) {
                        $ParameterValues[$key] = $value
                    }
                }
                if($BoundParameters.ContainsKey($key)) {
                    $ParameterValues[$key] = $BoundParameters[$key]
                }
            }
        } finally {}
    }
    $ParameterValues
}