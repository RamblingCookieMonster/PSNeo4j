[![Build status](https://ci.appveyor.com/api/projects/status/lk3bj4da52dv472x/branch/master?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psneo4j/branch/master)

# PSNeo4j

PSNeo4j is a simple Neo4j PowerShell module, allowing you to quickly build up graph data from any of the technologies PowerShell can interface with.

IMPORTANT:

* This has had minimal testing, and the default response conversion (`-As Parsed`) currently misses some common cases
* Some commands are susceptible to injection.  See `Get-Help about_PSNeo4j` and parameter help for more details

## Getting Started

Install Neo4j, and configure the `neo4j` user's password via `http://127.0.0.1:7474` ([example](https://glennsarti.github.io/blog/graph-all-the-powershell-things/#installing-neo4j))

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSNeo4j folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)
# Or, with PowerShell 5 or later or PowerShellGet:
    Install-Module PSNeo4j

# Import the module.
    Import-Module PSNeo4j    #Alternatively, Import-Module \\Path\To\PSNeo4j

# Get commands in the module
    Get-Command -Module PSNeo4j

# Get help
    Get-Help Invoke-Neo4jQuery -Full
    Get-Help about_PSNeo4j
```

## Examples

We'll create a super simple database of systems and services - this could be extended to cover a wide variety of things for a custom CMDB

### Set up defaults

```powershell
# Set a password ahead of time, and maybe use an actual password generator : )
$Password = ConvertTo-SecureString -String "myneo4jpassword!" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList neo4j, $password
Set-PSNeo4jConfiguration -Credential $Cred -BaseUri 'http://127.0.0.1:7474'

# Did we connect?
Get-Neo4jUser
```

### Add some nodes

```powershell
# Add some servers
[pscustomobject]@{
    ComputerName = 'dc01'
    Domain = 'some.domain'
},
[pscustomobject]@{
    ComputerName = 'dc02'
    Domain = 'some.domain'
},
[pscustomobject]@{
    ComputerName = 'web01'
    Domain = 'some.domain'
} |
    New-Neo4jNode -Label Server -Passthru

# Add a service
[pscustomobject]@{
    Name = 'Active Directory'
    Engineer = 'Warren Frame'
} |
    New-Neo4jNode -Label Service -Passthru
```

### List everything in the database

```powershell
# See what we have
Invoke-Neo4jQuery -Query @"
MATCH (n)
RETURN n;
"@ | Format-List -Property * -Force
```

### Add some relationships

```powershell
# web01 relies on AD for identity and management
New-Neo4jRelationship -LeftLabel Server -LeftHash @{ComputerName = 'web01'} `
                      -RightLabel Service -RightHash @{Name = 'Active Directory'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          Identity = $True
                          Management = $True
                      }

# Active Directory relies on dc01 and dc02
New-Neo4jRelationship -LeftQuery "MATCH (left:Server) WHERE left.ComputerName =~ 'dc.*'" `
                      -RightQuery "MATCH (right:Service { Name: 'Active Directory'})" `
                      -Type 'DependsOn' `
                      -Properties @{
                          ServiceHost = $True
                          LoadBalanced = $True
                      }

# Oops! Wrong direction.  Remove the DC relationships
Remove-Neo4jRelationship -LeftQuery "MATCH (left:Server) WHERE left.ComputerName =~ 'dc.*'" `
                         -Type 'DependsOn' `
                         -Properties @{
                             ServiceHost = $True
                             LoadBalanced = $True
                         }


# Add the DC relationships back with the right direction (AD depends on DCs)
New-Neo4jRelationship -LeftQuery "MATCH (left:Service { Name: 'Active Directory'})" `
                      -RightQuery "MATCH (right:Server) WHERE right.ComputerName =~ 'dc.*'" `
                      -Type 'DependsOn' `
                      -Properties @{
                          ServiceHost = $True
                          LoadBalanced = $True
                      }

```

This is just an example.  There are better ways to represent the relationship properties

### Check things out

* Browse to `http://127.0.0.1:7474`
* Select the `Database Information` icon
* Pick a query (e.g. Node Label `Server` or `*`)

[![Neo4j Browser](/Media/psneo4j.example.gif)](/Media/psneo4j.example.gif)

### Add some indexes

```powershell
# Add a composite index, and individual indexes
New-Neo4jIndex -Label Server -Property computername, domain -Composite
New-Neo4jIndex -Label Server -Property computername, domain

# Look at the indexes we created
Invoke-Neo4jQuery -Query "CALL db.indexes();"

# Maybe we only need a constraint.  Drop some indexes, add a constraint
Remove-Neo4jIndex -Label Server -Property computername, domain -Composite
Remove-Neo4jIndex -Label Server -Property computername, domain
```

### Add a constraint

```powershell
# Add some constraints on properties
New-Neo4jConstraint -Label Server -Property computername -Unique
```

### Remove a node

```powershell
# Remove a server
@{ComputerName = 'web01'} | Remove-Neo4jNode -Label Server
# Error! Can't delete if a node if it has a relationship... unless we detach it
@{ComputerName = 'web01'} | Remove-Neo4jNode -Label Server -Detach
```

### Delete everything!

```powershell
# Bah, let's just delete everything
Invoke-Neo4jQuery -Query @"
MATCH (n)
DETACH DELETE n;
"@
```

## Notes

* Thanks to @Jaykul for the `Configuration` module that we embed and rely on
* Thanks to @GlennSarti for his various articles and presentations on Neo4j, and maintaining the neo4j-community Chocolatey package
* Thanks to the folks behind [BloodHound](https://github.com/BloodHoundAD/BloodHound) for some in-the-wild examples
* Using the neo4j-community Chocolatey package and want to know what's actually happening?  Read the install script (e.g. [install for 3.2.3](https://github.com/glennsarti/neo4j-community-chocolatey/blob/master/neo4j-community-3.2.3/tools/chocolateyInstall.ps1))
* We use the [transactional Cypher HTTP endpoint](http://neo4j.com/docs/developer-manual/current/http-api/), doing most work with Cypher queries rather than the REST endpoints or Bolt (currently)
* Fun blog post pending!