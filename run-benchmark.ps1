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
$benchCodes=1,3,5,41,43,45
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

#   Read benchmark results from Log.txt, returns a string
function getResults {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    return (Get-Content $logFile | Select-String -Pattern 'FRAMERATE TEST:','GPU LOAD:' | Out-String).trim()
}

#   Read hardware config from Log.txt, returns a string
function getHWconf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    # $cpu=$(Get-CimInstance -ClassName Win32_Processor)[0].Name # We could also get the cpu name from the system, instead of Log.txt
    (Get-Content $logFile | Out-String) -match 'CPU 0: (.+)\s+Speed.+' | out-null
    $cpu=$matches[1]
    (Get-Content $logFile | Out-String) -match 'Vulkan Device\s+: (.+)' | out-null
    $gpu=$matches[1]
    (Get-Content $logFile | Out-String) -match 'Physical Memory \(total for computer\): (\d+)' | out-null
    $ram=([float]$matches[1]/(1024*1024*1024).tostring("#.#"))
    return "CPU: $cpu`nGPU: $gpu`nSystem Memory: $ram GB"
}

#   Read software config:
#   - X-Plane Version
#   - Zink setting
function getSWconf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    $xpVer=$(Get-Content $logFile -First 1).Split(' ')[3]
    $zinkOn=$(Get-Content $logFile | Select-String -Pattern 'OpenGL Render' | Out-String) -match 'zink'
    return "X-Plane Version: $xpVer`nZink: $zinkOn"
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
