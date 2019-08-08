function Parse-Neo4jDate {
    [cmdletbinding()]
    param(
        $DateString,
        [validateset('DateWithEpochMs', 'DateTimeO')]
        [string[]]$ParseDatePatterns = $PSNeo4jConfig.ParseDatePatterns
    )
    # Get-Date -Format o should return a compatible string for this
    # This should be the preferred method, given that this string allows datatime use in Neo4j
    if($ParseDatePatterns -contains 'DateTimeO' -and $DateString -match "^\d{4}-\d{2}-\d{2}t\d{2}" ){
        try {
            Get-Date $DateString -ErrorAction Stop
        }
        catch {
            return $DateString
        }
    }
    # Try to avoid this.  Instead of ingesting output from Get-Date, use Get-Date -Format o
    elseif($ParseDatePatterns -contains 'DateWithEpochMs' -and $DateString -match '/Date\(\d+\)/'){
        $UnixDate = $DateString -replace '\D+'
        if($UnixDate){
            try {
                $UnixTime = [int]$UnixDate
            }
            catch {
                $UnixTime = [int]$($UnixDate -replace ".{3}$") # Replace last 3 chars, milliseconds
            }
            try {
                return [timezone]::CurrentTimeZone.ToLocalTime( ([datetime]'1/1/1970').AddSeconds($UnixTime) )
            }
            catch {
                $UnixTime
            }
        }
        else {
            return $DateString
        }
    }
    else {
        return $DateString
    }
}