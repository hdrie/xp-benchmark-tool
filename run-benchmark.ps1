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

$writeCsv=$false # Set to true, if you want to create entries to a .csv file
$csvOutPath='./ZZZ_BenchResults.csv'
$usrComment='' # Enter an optional user comment to recognize your benchmark session later

# Command line arguments (besides --fps_test) to run the executable with
$launchArguments="--load_smo=$replayPath --weather_seed=1 --time_seed=1"

# Specify benchmark presets to run, for more info, see https://www.x-plane.com/kb/frame-rate-test/
$benchCodes=1,3,5,41,43,45

#Regex strings for Log.txt parsing, do not change
$cpuRegex='CPU type: (.+) - Speed.+'
$gpuRegex='Vulkan Device\s+: (.+)'
$ramRegex='Physical Memory \(total for computer\): (\d+)'
$resultsRegex='FRAMERATE TEST:(?:,?\s[a-zA-Z]+=[0-9]*(?:\.[0-9]+)?%?)+.*(?:\r\n)?.*GPU LOAD:(?:,?\s[a-zA-Z]+=[0-9]*(?:\.[0-9]+)?%?)+'
$captResultsRegex='FRAMERATE TEST: time=([0-9]*(?:\.[0-9]+)?), frames=([0-9]*(?:\.[0-9]+)?), fps=([0-9]*(?:\.[0-9]+)?).* .*GPU LOAD: time=([0-9]*(?:\.[0-9]+)?), wait=([0-9]*(?:\.[0-9]+)?), load=([0-9]*(?:\.[0-9]+)?)%'

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
    if ((Get-Content $logFile | Out-String) -match $resultsRegex) {
        return $matches[0]
    }
    else {
        Write-Host 'Could not obtain results string'
        return 'No matches for string pattern in Log.txt'
    }
}

#   Read System Configuration
function getSysConf {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $logFile,
        [Parameter(Mandatory=$false, Position=1)]
        [string] $outputType
    )
    # Software
    #   X-Plane Version
    $xpVer=$(Get-Content $logFile -First 1).Split(' ')[3]
    #   Zink setting
    $zinkOn=$(Get-Content $logFile | Select-String -Pattern 'OpenGL Render' | Out-String) -match 'zink'
    # If outputType 'csv' is requested, only return software props hashtable
    if ($outputType -eq 'csv') {
        return @{xpVersion = $xpver ; zink = $zinkOn}
    }
    # Hardware
    #   CPU Device
    #$cpu=$(Get-CimInstance -ClassName Win32_Processor)[0].Name # We could also get the cpu name from the system, instead of Log.txt
    (Get-Content $logFile | Out-String) -match $cpuRegex | out-null
    $cpu=$matches[1]
    #   GPU Device
    (Get-Content $logFile | Out-String) -match $gpuRegex | out-null
    $gpu=$matches[1]
    #   RAM amount
    (Get-Content $logFile | Out-String) -match $ramRegex | out-null
    $ram=([float]$matches[1]/(1024*1024*1024)).tostring("#.#")

    return "X-Plane Version: $xpVer`nZink: $zinkOn`nCPU: $cpu`nGPU: $gpu`nRAM: $ram GB"
}

# Function to create hastable from benchmark results String
function getResultsCsvItems {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $resultsStr
    )
    $parseStr = $resultsStr -replace "`r`n" , " " # create single line string
    if ($parseStr -match $captResultsRegex) {
        $resultsHT = @{
            time = $matches[1]
            frames = $matches[2]
            fps = $matches[3]
            gpu_time = $matches[4]
            gpu_wait = $matches[5]
            gpu_load = $matches[6]
        }
        return $resultsHT
    }
    else {
        Write-Host "Unexpected results string:`r`n$resultsStr"
        $resultsHT = @{
            time = 'NaN'
            frames = 'NaN'
            fps = 'NaN'
            gpu_time = 'NaN'
            gpu_wait = 'NaN'
            gpu_load = 'NaN'
        }
        return $resultsHT
    }
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
    # Get results from Log.txt, specifying benchmark preset
    Add-Content -Path $txtOutPath -Value "`nBenchmark Preset: $code" 
    $results = getResults -logFile $logPath
    # Write config and results to File
    Add-Content -Path $txtOutPath -Value $results

    # Optionally create hashtable with relevant items and write to specified .csv file path
    if ($writeCsv) {
        $csvOutput = $(getResultsCsvItems -resultsStr $results) + $(getSysConf -logFile $logPath -outputType 'csv')
        $csvOutput.add('date' , $(Get-Date -Format "yyyy-MM-dd'T'HH:mmK")) # add a timestamp in ISO 8601 format
        $csvOutput.add('comment' , $usrComment)
        $csvOutput.add('benchPreset' , $code)
        # Convert hashtable to object and pipe to export-csv, creating the file or appending to it
        $csvOutput | ForEach-Object{ [pscustomobject]$_ } | Export-CSV -Path $csvOutPath -NoTypeInformation -Append
    }

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
