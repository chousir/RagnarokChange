<#
.SYNOPSIS
Runs single-player headless for a while and checks that it stayed healthy.

.DESCRIPTION
The M0 acceptance run (docs/01-architecture.md section 17 item 3, docs/02 section 16
M0 item 6): the local server ticks, the client enters the map and keeps receiving
snapshots, and nothing prints an error. Run for every batch acceptance.
The log goes to artifacts/smoke/. Exit code 0 means the run passed.

.PARAMETER Seconds
How long to run. Defaults to 60.

.PARAMETER Godot
Path to the Godot 4.7.2 console executable. Defaults to $env:GODOT_BIN, then D:\godot.
#>
[CmdletBinding()]
param(
    [double]$Seconds = 60,
    [string]$Godot = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir 'smoke'
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

Write-Host "== single-player for $Seconds s =="
# "++" marks the user arguments; PowerShell may swallow a bare "--".
$arguments = @('--headless', '--path', $projectRoot, '++', "--run-seconds=$Seconds")
$previousPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$output = @(& $Godot @arguments 2>&1 | ForEach-Object { "$_" })
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $previousPreference
$logPath = Join-Path $logDir 'single_player.log'
$output | Set-Content -Path $logPath -Encoding UTF8

$failures = @()
$errorLines = @($output | Where-Object { $_ -match '^\s*(SCRIPT ERROR|USER ERROR|ERROR):' })
foreach ($line in $errorLines) {
    Write-Host "  $line"
}
$warningLines = @($output | Where-Object { $_ -match '^\s*WARNING:' })
foreach ($line in $warningLines) {
    Write-Host "  $line"
}
if ($exitCode -ne 0) { $failures += "exited with code $exitCode" }
if ($errorLines.Count -gt 0) { $failures += "printed $($errorLines.Count) error line(s)" }

$summary = $output | Where-Object { $_ -match 'smoke: ticks=(\d+) snapshots_sent=(\d+) snapshots_received=(\d+) in_game=(\w+) map=(\S*)' } | Select-Object -Last 1
if (-not $summary) {
    $failures += 'no smoke summary line'
} else {
    Write-Host "  $summary"
    $null = $summary -match 'smoke: ticks=(\d+) snapshots_sent=(\d+) snapshots_received=(\d+) in_game=(\w+) map=(\S*)'
    $ticks = [int]$Matches[1]
    $received = [int]$Matches[3]
    $inGame = $Matches[4]
    # The server ticks at 30 Hz; allow for start-up and the last partial second.
    $expected = [int](30 * $Seconds)
    if ($ticks -lt [int]($expected * 0.95)) { $failures += "only $ticks ticks, expected about $expected" }
    if ($received -lt [int]($expected * 0.9)) { $failures += "only $received snapshots received, expected about $expected" }
    if ($inGame -ne 'true') { $failures += 'the client never entered the map' }
}

if ($failures.Count -gt 0) {
    Write-Host 'smoke: FAIL'
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    Write-Host "Log: $logPath"
    exit 1
}

Write-Host 'smoke: PASS'
exit 0
