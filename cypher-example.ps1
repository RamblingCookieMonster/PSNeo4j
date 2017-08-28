# Import DLLs
$SPath = 'C:\Users\wframeDA\Documents\github\code-glennsarti.github.io'
Add-Type -Path "$SPath\nuget\Neo4j.Driver.1.0.2\lib\dotnet\Neo4j.Driver.dll"
Add-Type -Path "$SPath\nuget\rda.SocketsForPCL.1.2.2\lib\net45\Sockets.Plugin.Abstractions.dll"
Add-Type -Path "$SPath\nuget\rda.SocketsForPCL.1.2.2\lib\net45\Sockets.Plugin.dll"

Function Invoke-Cypher($query) {
  $session.Run($query)
}

$authToken = [Neo4j.Driver.V1.AuthTokens]::Basic('neo4j','myneo4jpassword!')

$dbDriver = [Neo4j.Driver.V1.GraphDatabase]::Driver("bolt://localhost:7687",$authToken)
$session = $dbDriver.Session()

Invoke-Cypher -query "CREATE (:Service { name:'DomainServices'})"

Invoke-Cypher @"
MATCH (n)
RETURN n;
"@