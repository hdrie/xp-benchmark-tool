# X-Plane Benchmark - Automated PowerShell script
# X-Plane 12 only!

# -------------------------------------------------------------------------------------------
# IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
# -------------------------------------------------------------------------------------------

# CONFIGURATION / PARAMETERS
#   Input/Output files
#   Benchmark options

# Set $true to prompt between benchmarks, otherwise set $false
$configPromptUser = $false 

# File paths. You shouldn't need to change these
$execPath='./x-plane.exe'
$replayPath='Output/replays/test_flight_737.fps'
$logPath='./Log.txt'
$txtOutPath='./ZZ_BenchResults.txt'

# Command line arguments (besides --fps_test) to run the executable with
$launchArguments="--load_smo=$replayPath --weather_seed=1 --time_seed=1"

# Specify benchmark presets to run, for more info, see https://www.x-plane.com/kb/frame-rate-test/
$benchCodes=1,3,5,41,43,45

# -------------------------------------------------------------------------------------------
# IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
# -------------------------------------------------------------------------------------------

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

#   Read System Configuration
function getSysConf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile
    )
    # Software
    #   X-Plane Version
    $xpVer=$(Get-Content $logFile -First 1).Split(' ')[3]
    #   Zink setting
    $zinkOn=$(Get-Content $logFile | Select-String -Pattern 'OpenGL Render' | Out-String) -match 'zink'
    
    # Hardware
    #   CPU Device
    #$cpu=$(Get-CimInstance -ClassName Win32_Processor)[0].Name # We could also get the cpu name from the system, instead of Log.txt
    (Get-Content $logFile | Out-String) -match 'CPU 0: (.+)\s+Speed.+' | out-null
    $cpu=$matches[1]
    #   GPU Device
    (Get-Content $logFile | Out-String) -match 'Vulkan Device\s+: (.+)' | out-null
    $gpu=$matches[1]
    #   RAM amount
    (Get-Content $logFile | Out-String) -match 'Physical Memory \(total for computer\): (\d+)' | out-null
    $ram=([float]$matches[1]/(1024*1024*1024)).tostring("#.#")

    return "X-Plane Version: $xpVer`nZink: $zinkOn`nCPU: $cpu`nGPU: $gpu`nRAM: $ram GB"
}

# Prompt user between benchmark runs
function promptUser{
    # takes user input as yes or no and stores in $choice var
    $userChoice = Read-Host "Hit any key to move onto next benchmark. To cancel, type 'n'"
    
    # switch statemnent to determine behavior based on user input
    switch ($userChoice) {
        "n" {
            Write-Host "Exiting."
            return $false
        }
        "no" {
            Write-Host "Exiting."
            return $false
        }
        default {
            Write-Host "Continuing on with next benchmark."
            return $true
        }
    }
}

# -------------------------------------------------------------------------------------------
# IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
# -------------------------------------------------------------------------------------------

# SCRIPT EXECUTION
#   Loop benchmark runs as configured
#   Read and write system config and benchmark results

# Read the system configuration once every session
$readConfig=$true

# Create results .txt file if not exists
if (!(Test-Path $txtOutPath -PathType Leaf)) {
    New-Item ./ZZ_BenchResults.txt -ItemType File | out-null
}

# Create header line
Add-Content -Path $txtOutPath -Value "-------------------------`nBEGIN SESSION: $(Get-Date -UFormat "%m/%d/%Y %R")`n-------------------------"
# Switch to read the system configuration once every session (switch will turn false after first bench run)
$readConfig=$true

# Run the benchmarks, looping through the specified bench presets
foreach ($code in $benchCodes) {

    # Run x-plane.exe
    runExec -exec $execPath -args "--fps_test=$code $launchArguments"
    
    if ($readConfig) {
        # Read and write the system configuration once every session
        $sysConfig = getSysConf -logFile $logPath
        Add-Content -Path $txtOutPath -Value $sysConfig
        $readConfig=$false
    }
    # Get results from Log.txt, specifying benchmark code
    Add-Content -Path $txtOutPath -Value "`nBenchmark Preset: $code" 
    $results = getResults -logFile $logPath
    # Write config and results to File
    Add-Content -Path $txtOutPath -Value $results

    # Prompts the user by calling promptUser function. If they choose to continue, loop moves to next iteration. if not, loop breaks.
    if ($configPromptUser){
        if(promptUser){
    }
    else{
        break 
    }
  }
}
Add-Content -Path $txtOutPath -Value "-------------------------`nEND SESSION: $(Get-Date -UFormat "%m/%d/%Y %R")"
