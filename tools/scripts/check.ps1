<#
.SYNOPSIS
Imports all resources and runs every headless test (unit, integration, smoke, guards).

.DESCRIPTION
Run before every commit (docs/01-architecture.md section 11.2, docs/11-milestones.md 11-D08).
Any engine or script error in the output fails the check (docs/01-architecture.md 01-D16),
and so does a run that does not finish in time.
Logs go to artifacts/check/. Exit code 0 means everything passed.

.PARAMETER Godot
Path to the Godot 4.7.2 console executable. Defaults to $env:GODOT_BIN, then D:\godot.

.PARAMETER TimeoutSeconds
Longest each Godot run may take. Defaults to 900.
#>
[CmdletBinding()]
param(
    [string]$Godot = '',
    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'godot_run.ps1')
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir 'check'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$artifactsIgnore = Join-Path $artifactsDir '.gdignore'
if (-not (Test-Path $artifactsIgnore)) {
    New-Item -ItemType File -Path $artifactsIgnore | Out-Null
}
$Godot = Resolve-Godot $Godot
$failures = @()

Write-Host '== import =='
$import = Invoke-Godot -Godot $Godot -Arguments @('--headless', '--path', $projectRoot, '--import') -LogPath (Join-Path $logDir 'import.log') -TimeoutSeconds $TimeoutSeconds -Tolerated $ImportExitLeaks
if ($import.TimedOut) { $failures += "import did not finish in $TimeoutSeconds s" }
elseif ($import.ExitCode -ne 0) { $failures += "import exited with code $($import.ExitCode)" }
if ($import.Errors.Count -gt 0) { $failures += "import printed $($import.Errors.Count) error line(s)" }

Write-Host '== tests =='
$tests = Invoke-Godot -Godot $Godot -Arguments @('--headless', '--path', $projectRoot, '-s', 'res://addons/gut/gut_cmdln.gd') -LogPath (Join-Path $logDir 'tests.log') -TimeoutSeconds $TimeoutSeconds
foreach ($line in @($tests.Output | Where-Object { $_ -match '^\s*(Scripts|Tests|Passing Tests|Failing Tests|Pending|Asserts|Time)\b' })) {
    Write-Host "  $line"
}
if ($tests.TimedOut) { $failures += "tests did not finish in $TimeoutSeconds s" }
elseif ($tests.ExitCode -ne 0) { $failures += "tests exited with code $($tests.ExitCode)" }
if ($tests.Errors.Count -gt 0) { $failures += "tests printed $($tests.Errors.Count) error line(s)" }
if (-not ($tests.Output | Where-Object { $_ -match 'All tests passed' })) {
    $failures += 'test run did not report "All tests passed"'
}

if ($failures.Count -gt 0) {
    Write-Host 'check: FAIL'
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    Write-Host "Logs: $logDir"
    exit 1
}

Write-Host 'check: PASS'
exit 0
