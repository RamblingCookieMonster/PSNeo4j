function Set-Neo4jPassword {
    <#
    .SYNOPSIS
       Set password for current Neo4j user

    .DESCRIPTION
       Set password for current Neo4j user

    .EXAMPLE
        $c = Get-Credential
        Set-Neo4jPassword -Password $c.Password

        # Set current user's password to the password specified via Get-Credential

    .EXAMPLE
        # Install neo4j -we want to change the initial neo4j account password
        $c = Get-Credential -UserName neo4j -Message 'Set new neo4j password'

        # PSNeo4j defaults to using the neo4j initial install creds: neo4j:neo4j
        # So this command auth's with neo4j:neo4j and changes password to what you specified in $c
        Set-Neo4jPassword -Password $c.Password

        # Set the PSNeo4j configuration to use this new credential
        Set-PSNeo4jConfiguration -Credential $c

    .PARAMETER BaseUri
        BaseUri to build REST endpoint Uris from

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, 'http://127.0.0.1:7474')

    .PARAMETER Credential
        PSCredential to use for auth

        We default to the value specified by Set-PSNeo4jConfiguration (Initially, neo4j:neo4j)

    .FUNCTIONALITY
        Neo4j
    #>
    [cmdletbinding()]
    param(
        [string]$BaseUri = $PSNeo4jConfig.BaseUri,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential =  $PSNeo4jConfig.Credential,

        [SecureString]$Password
    )
    $pw = $( New-Object PSCredential("user",$Password) ).GetNetworkCredential().Password
    $PasswordBody = "{`"password`":`"$pw`"}"
    write-verbose "pw=$pw;password=$Password;pwb=$PasswordBody"
    $Params = @{
        Method = 'Post'
        RelativeUri  ='user/neo4j/password'
        BaseUri = $BaseUri
        Credential = $Credential
        Body = $PasswordBody
    }
    Write-Verbose "$($Params | Format-List | Out-String)"
    Invoke-Neo4jApi @Params
}