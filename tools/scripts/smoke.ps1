<#
.SYNOPSIS
Runs single-player headless for a while and checks that it stayed healthy.

.DESCRIPTION
The M0 acceptance run (docs/01-architecture.md section 17 item 3, docs/02 section 16
M0 item 6): the local server ticks, the client enters the map and keeps receiving
snapshots, and nothing prints an error. Run for every batch acceptance.
Saves and settings go to a fresh folder under artifacts/smoke/, never the player's
own (docs/03 section 9.1). Exit code 0 means the run passed.

.PARAMETER Seconds
How long to run. Defaults to 60.

.PARAMETER Godot
Path to the Godot 4.7.2 console executable. Defaults to $env:GODOT_BIN, then D:\godot.
#>
[CmdletBinding()]
param(
    [double]$Seconds = 60,
    [string]$Godot = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'godot_run.ps1')
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir 'smoke'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if (-not (Test-Path (Join-Path $artifactsDir '.gdignore'))) {
    New-Item -ItemType File -Path (Join-Path $artifactsDir '.gdignore') | Out-Null
}
$Godot = Resolve-Godot $Godot
$dataDir = Join-Path $logDir 'data'
if (Test-Path $dataDir) {
    Remove-Item -Recurse -Force $dataDir
}
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

Write-Host "== single-player for $Seconds s =="
# "++" marks the user arguments; PowerShell may swallow a bare "--".
$arguments = @('--headless', '--path', $projectRoot, '++', "--run-seconds=$Seconds", "--data-dir=$dataDir")
$run = Invoke-Godot -Godot $Godot -Arguments $arguments -LogPath (Join-Path $logDir 'single_player.log') -TimeoutSeconds ([int]$Seconds + 120)
foreach ($line in @($run.Output | Where-Object { $_ -match '^\s*WARNING:' })) {
    Write-Host "  $line"
}

$failures = @()
if ($run.TimedOut) { $failures += 'the run did not finish in time' }
elseif ($run.ExitCode -ne 0) { $failures += "exited with code $($run.ExitCode)" }
if ($run.Errors.Count -gt 0) { $failures += "printed $($run.Errors.Count) error line(s)" }

$pattern = 'smoke: ticks=(\d+) snapshots_sent=(\d+) snapshots_received=(\d+) in_game=(\w+) map=(\S*)'
$summary = $run.Output | Where-Object { $_ -match $pattern } | Select-Object -Last 1
if (-not $summary) {
    $failures += 'no smoke summary line'
} else {
    Write-Host "  $summary"
    $null = $summary -match $pattern
    $ticks = [int]$Matches[1]
    $received = [int]$Matches[3]
    # The server ticks at 30 Hz; allow for start-up and the last partial second.
    $expected = [int](30 * $Seconds)
    if ($ticks -lt [int]($expected * 0.95)) { $failures += "only $ticks ticks, expected about $expected" }
    if ($received -lt [int]($expected * 0.9)) { $failures += "only $received snapshots received, expected about $expected" }
    if ($Matches[4] -ne 'true') { $failures += 'the client never entered the map' }
}

if ($failures.Count -gt 0) {
    Write-Host 'smoke: FAIL'
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    Write-Host "Log: $(Join-Path $logDir 'single_player.log')"
    exit 1
}

Write-Host 'smoke: PASS'
exit 0
