# xp-benchmark-tool
X-Plane 12 Benchmarking for Windows - Configurable Powershell script
using the 'canned' benchmark https://www.x-plane.com/kb/frame-rate-test/

## Functionality
- Automatically launch a preconfigured series of X-Plane built-in benchmark runs using command line arguments
- After every run read the Log.txt file and parse relevant info:
    - Benchmark results
    - X-Plane version and 'zink' status
    - Hardware configuration (CPU, GPU, RAM)
- Write a neatly formatted summary of the obtained info to an output .txt file

## Using the script
- Download 'run-benchmark.ps1' and move it to your X-Plane 12 root folder next to the game executable.
- Open 'run-benchmark.ps1' in a text editor
- set the variables in the config section (line 8 and below) to your liking:
    - configPromptUser: Set to true, if you want a to be prompted to continue after every run
    - benchCodes: Set a list of benchmark codes to run.
    - Path variables: These are already configured correctly
- Open a Powershell commmand line prompt and type: 'powershell ./run-benchmark.ps1'

## Notes
- Running PS scripts may be blocked by default. For changing the execution policy see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.3
- Make sure you understand what this implies before you make such a change
- I recommend changing the policy (temporarily) to *Unrestricted* for the *CurrentUser* *Scope*
