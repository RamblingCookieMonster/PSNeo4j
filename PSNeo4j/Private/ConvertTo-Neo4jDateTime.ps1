# I dont do much validation.  I expect a hash, or an object with settable properties
# Converts any key/property value that is a datetime into an iso8601/neo4j datetime string
function ConvertTo-Neo4jDateTime {
    param(
        $InputObject,
        [switch]$ParseDateInput = $PSNeo4jConfig.ParseDateInput
    )
    if(-not $ParseDateInput){
        return $InputObject
    }
    if($InputObject -is [hashtable]){
        $Properties = $($InputObject.Keys)
    }
    else{
        $Properties = $InputObject.PSObject.Properties.Name
    }
    foreach($Property in $Properties){
        if($InputObject.$Property -is [datetime]) {
            $InputObject.$Property = $InputObject.$Property.ToString('o')
        }
    }
    $InputObject
}