# xp-benchmark-tool
X-Plane 12 Benchmarking for Windows
using https://www.x-plane.com/kb/frame-rate-test/

## Scope
Attempt to match https://github.com/hdrie/x-plane-utility-scripts/blob/master/Linux%20benchmarking/X-Plane12_Bench.sh
- Configurable Powershell script
- Launch series of X-Plane built-in benchmarks using command line arguments
- Read system configuration info
- Planned feature: write structured results to .csv

## Notes
- Running PS scripts may be blocked by default. For changing the execution policy see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.3
- Make sure you understand what this implies before you make such a change
- I recommend changing the policy (temporarily) to *Unrestricted* for the *CurrentUser* *Scope*
