# X-Plane Benchmark - Automated PowerShell script
# X-Plane 12 only!
#
# CONFIGURATION / PARAMETERS
#   Input/Output files
#   Benchmark options
$execPath='./x-plane.exe'
$replayPath='Output/replays/test_flight_737.fps'
$logPath='./Log.txt'
$resultsPath='./ZZ_BenchResults.txt'
$benchCodes=1,2,3,4,5

# FUNCTION DEFINITIONS

#   Start executable
function runExec {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $exec,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $args
    )
    Start-Process -FilePath $exec -ArgumentList $args -Wait
}

#   Read benchmark results from Log.txt, does nothing yet
function getResults {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return "ExampleResults"
}

#   Read hardware config, does nothing yet
function getHWconf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return "ExampleHWconf"
}

#   Read software config, does nothing yet
function getSWconf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return "ExampleSWconf"
}

# SCRIPT EXECUTION
#   Loop benchmark runs as configured
#   Read and write system config and benchmark results

# Read the system configuration once every session
$readConfig=$true

# Create results file if not exists
if (!(Test-Path $resultsPath -PathType Leaf)) {
    New-Item ./ZZ_BenchResults.txt -ItemType File -Value "This is the results file"
}

# Run the benchmarks, looping through the specified bench codes
foreach ($code in $benchCodes) {
    runExec -exec $execPath -args "--fps_test=$code --load_smo=$replayPath"
    if ($readConfig) {
        # Read and write the system configuration once every session
        $HWconfig = getHWconf -logFile $logPath
        $SWconfig = getSWconf -logFile $logPath
        Add-Content -Path $resultsPath -Value "$HWconfig`n$SWconfig"
        $readConfig=$false
    }
    # Get results from Log.txt
    $results = getResults -logFile $logPath
    # Write config and results to File
    Add-Content -Path $resultsPath -Value $results
}
