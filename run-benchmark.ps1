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
$benchCodes=41
$launchArguments="--weather_seed=1 --time_seed=1"

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

#   Read benchmark results from Log.txt
function getResults {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return (Get-Content $logFile | Select-String -Pattern 'FRAMERATE TEST:','GPU LOAD:' | Out-String).trim()
}

#   Read hardware config, does nothing yet
function getHWconf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return "ExampleHWconf"
}

#   Read software config, only X-Plane version atm
function getSWconf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return (Get-Content Log.txt -First 1).Split(' ')[3]
}

# SCRIPT EXECUTION
#   Loop benchmark runs as configured
#   Read and write system config and benchmark results

# Read the system configuration once every session
$readConfig=$true

# Create results file if not exists
if (!(Test-Path $resultsPath -PathType Leaf)) {
    New-Item ./ZZ_BenchResults.txt -ItemType File
}

# Create header line
Add-Content -Path $resultsPath -Value "BEGIN SESSION: $(Get-Date -UFormat "%m/%d/%Y %R")"

# Run the benchmarks, looping through the specified bench codes
foreach ($code in $benchCodes) {
    runExec -exec $execPath -args "--fps_test=$code --load_smo=$replayPath $launchArguments"
    if ($readConfig) {
        # Read and write the system configuration once every session
        $HWconfig = getHWconf -logFile $logPath
        $SWconfig = getSWconf -logFile $logPath
        Add-Content -Path $resultsPath -Value "$HWconfig`n$SWconfig"
        $readConfig=$false
    }
    # Get results from Log.txt, specifying benchmark code
    Add-Content -Path $resultsPath -Value "`nBenchmark Code: $code" 
    $results = getResults -logFile $logPath
    # Write config and results to File
    Add-Content -Path $resultsPath -Value $results
}

Add-Content -Path $resultsPath -Value "END SESSION: $(Get-Date -UFormat "%m/%d/%Y %R")`n-------------------------"
