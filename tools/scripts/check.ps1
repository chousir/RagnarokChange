<#
.SYNOPSIS
Imports all resources and runs every headless test (unit, integration, smoke, guards).

.DESCRIPTION
Run before every commit (docs/01-architecture.md section 11.2, docs/11-milestones.md 11-D08).
Any engine or script error in the output fails the check (docs/01-architecture.md 01-D16).
Logs go to artifacts/check/. Exit code 0 means everything passed.

.PARAMETER Godot
Path to the Godot 4.7.2 console executable. Defaults to $env:GODOT_BIN, then D:\godot.
#>
[CmdletBinding()]
param(
    [string]$Godot = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir 'check'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$artifactsIgnore = Join-Path $artifactsDir '.gdignore'
if (-not (Test-Path $artifactsIgnore)) {
    New-Item -ItemType File -Path $artifactsIgnore | Out-Null
}

if (-not $Godot) {
    $defaultGodot = 'D:\godot\Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path $defaultGodot) {
        $Godot = $defaultGodot
    } else {
        $Godot = 'godot'
    }
}

function Invoke-GodotStep {
    param(
        [string]$Name,
        [string[]]$Arguments
    )
    Write-Host "== $Name =="
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = @(& $Godot @Arguments 2>&1 | ForEach-Object { "$_" })
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference

    $output | Set-Content -Path (Join-Path $logDir "$Name.log") -Encoding UTF8
    $errorLines = @($output | Where-Object { $_ -match '^\s*(SCRIPT ERROR|USER ERROR|ERROR):' })
    foreach ($line in $errorLines) {
        Write-Host "  $line"
    }
    return [pscustomobject]@{
        Name = $Name
        ExitCode = $exitCode
        ErrorCount = $errorLines.Count
        Output = $output
    }
}

$failures = @()

$import = Invoke-GodotStep -Name 'import' -Arguments @('--headless', '--path', $projectRoot, '--import')
if ($import.ExitCode -ne 0) { $failures += "import exited with code $($import.ExitCode)" }
if ($import.ErrorCount -gt 0) { $failures += "import printed $($import.ErrorCount) error line(s)" }

$tests = Invoke-GodotStep -Name 'tests' -Arguments @('--headless', '--path', $projectRoot, '-s', 'res://addons/gut/gut_cmdln.gd')
$summary = @($tests.Output | Where-Object { $_ -match '^\s*(Scripts|Tests|Passing Tests|Failing Tests|Pending|Asserts|Time)\b' })
foreach ($line in $summary) {
    Write-Host "  $line"
}
if ($tests.ExitCode -ne 0) { $failures += "tests exited with code $($tests.ExitCode)" }
if ($tests.ErrorCount -gt 0) { $failures += "tests printed $($tests.ErrorCount) error line(s)" }
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
