# X-Plane Benchmark - Automated PowerShell script
# X-Plane 12 only!
#
# CONFIGURATION / PARAMETERS
#   Input/Output files
#   Benchmark options
$replayFile="Output/replays/test_flight_737.fps"
$benchCode="1"
$args="--fps_test=$benchCode --load_smo=$replayFile"


# FUNCTION DEFINITIONS
#   Start executable
#   Read system config
#   Read benchmark results from Log.txt
#   Write/append output csv file
function startBench {Start-Process -FilePath "./x-plane.exe" -ArgumentList $args}



# SCRIPT EXECUTION
#   Loop benchmark runs as configured
#   Read and write system config and benchmark results
startBench
