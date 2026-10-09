<#
.SYNOPSIS
Builds the white-box maps: ground texture, terrain, block buildings, markers and
navigation meshes (docs/11 M1-a, docs/08).

.DESCRIPTION
Runs tools/maps/build_whitebox.gd twice with an import in between, because the
terrain needs the generated texture imported first. Rewrites maps/<id>/ for the
chosen maps. Logs go to artifacts/whitebox/. Exit code 0 means success.

.PARAMETER Map
A map id, or all (default).

.PARAMETER Godot
Path to the Godot 4.7.2 console executable. Defaults to $env:GODOT_BIN, then D:\godot.
#>
[CmdletBinding()]
param(
    [string]$Map = 'all',
    [string]$Godot = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'godot_run.ps1')
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir 'whitebox'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if (-not (Test-Path (Join-Path $artifactsDir '.gdignore'))) {
    New-Item -ItemType File -Path (Join-Path $artifactsDir '.gdignore') | Out-Null
}
$Godot = Resolve-Godot $Godot

function Invoke-Step {
    param([string]$Name, [string[]]$Arguments)
    Write-Host "== $Name =="
    $run = Invoke-Godot -Godot $Godot -Arguments $Arguments -LogPath (Join-Path $logDir "$Name.log") -Tolerated $ImportExitLeaks
    foreach ($line in @($run.Output | Where-Object { $_ -match '^whitebox:' })) { Write-Host "  $line" }
    if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Errors.Count -gt 0) {
        Write-Host "build_whitebox: FAIL at $Name (exit $($run.ExitCode), timed out $($run.TimedOut), $($run.Errors.Count) error line(s))"
        exit 1
    }
}

# Registers new class names before any script runs.
Invoke-Step -Name 'scan' -Arguments @('--headless', '--path', $projectRoot, '--import')
Invoke-Step -Name 'textures' -Arguments @('--headless', '--path', $projectRoot, '-s', 'res://tools/maps/build_whitebox.gd', '++', '--stage=textures')
Invoke-Step -Name 'import' -Arguments @('--headless', '--path', $projectRoot, '--import')
Invoke-Step -Name 'maps' -Arguments @('--headless', '--path', $projectRoot, '-s', 'res://tools/maps/build_whitebox.gd', '++', '--stage=maps', "--map=$Map")
Invoke-Step -Name 'reimport' -Arguments @('--headless', '--path', $projectRoot, '--import')
Write-Host 'build_whitebox: PASS'
exit 0
