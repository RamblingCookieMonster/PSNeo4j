function Parse-Neo4jDate {
    param($DateString)
    if($DateString -notmatch '/Date\(\d+\)/') {
        return $DateString
    }
    $UnixDate = $DateString -replace '\D+'
    if($UnixDate){
        try {
            $UnixTime = [int]$UnixDate
        }
        catch {
            $UnixTime = [int]$($UnixDate -replace ".{3}$") # Replace last 3 chars, milliseconds
        }
        try {
            [timezone]::CurrentTimeZone.ToLocalTime( ([datetime]'1/1/1970').AddSeconds($UnixTime) )
        }
        catch {
            $UnixTime
        }
    }
    else {
        $DateString
    }
}