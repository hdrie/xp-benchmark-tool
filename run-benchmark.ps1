# X-Plane Benchmark - Automated PowerShell script
# X-Plane 12 only!
#
# CONFIGURATION / PARAMETERS
#   Input/Output files
#   Benchmark options
$execPath='x-plane.exe'
$replayPath='Output/replays/test_flight_737.fps'
$logPath='Log.txt'
$benchCodes=1,2,3,4,5

# FUNCTION DEFINITIONS
#   Start executable
#   Read system config
#   Read benchmark results from Log.txt
#   Write/append output csv file
function runExec {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $exec
        [Parameter(Mandatory=$true, Position=1)]
        [string] $args
    )
    Start-Process -FilePath $exec -ArgumentList $args -Wait
}


# SCRIPT EXECUTION
#   Loop benchmark runs as configured
#   Read and write system config and benchmark results

foreach ($code in $benchCodes) {
    runExec -exec $execPath -args "--fps_test=$code --load_smo=$replayPath"
}
