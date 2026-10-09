<#
.SYNOPSIS
Runs the screenshot mode with a shot script and checks that it finished cleanly.

.DESCRIPTION
docs/01-architecture.md section 11.3: loads the scene or map of the shot script,
visits every observation point, saves PNGs and performance numbers to
artifacts/shots/<script>/<driver>[_<label>]/. Needs a GPU, so it opens a window.

.PARAMETER Script
Name of a file in tools/shots/scripts/ without .json, for example benchmark.

.PARAMETER Driver
d3d12 or vulkan; empty uses the project setting.

.PARAMETER Label
Extra name for the output folder, for example cold or warm.

.PARAMETER ColdCache
Deletes the shader and pipeline caches first, to measure first-run stutter.

.PARAMETER Godot
Path to the Godot 4.7.2 console executable. Defaults to $env:GODOT_BIN, then D:\godot.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Script,
    [ValidateSet('', 'd3d12', 'vulkan')][string]$Driver = '',
    [string]$Label = '',
    [switch]$ColdCache,
    [string]$Godot = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir (Join-Path 'shots' $Script)
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

if ($ColdCache) {
    $caches = @(
        (Join-Path $projectRoot '.godot\shader_cache'),
        (Join-Path $env:APPDATA 'RagnarokChange\shader_cache'),
        (Join-Path $env:APPDATA 'RagnarokChange\vulkan'),
        (Join-Path $env:APPDATA 'RagnarokChange\d3d12')
    )
    foreach ($cache in $caches) {
        if (Test-Path $cache) {
            Remove-Item -Recurse -Force $cache
            Write-Host "  cleared $cache"
        }
    }
}

$arguments = @('--path', $projectRoot)
if ($Driver) {
    $arguments += @('--rendering-driver', $Driver)
}
# "++" marks the user arguments; PowerShell may swallow a bare "--".
$arguments += @('++', "--shots=$Script")
if ($Label) {
    $arguments += "--shots-label=$Label"
}

$name = if ($Driver) { $Driver } else { 'default' }
if ($Label) { $name = "$name`_$Label" }
Write-Host "== shots $Script ($name) =="
$previousPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$output = @(& $Godot @arguments 2>&1 | ForEach-Object { "$_" })
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $previousPreference
$logPath = Join-Path $logDir "$name.log"
$output | Set-Content -Path $logPath -Encoding UTF8

$failures = @()
$errorLines = @($output | Where-Object { $_ -match '^\s*(SCRIPT ERROR|USER ERROR|ERROR):' })
foreach ($line in $errorLines) {
    Write-Host "  $line"
}
foreach ($line in @($output | Where-Object { $_ -match '\[shots\]' })) {
    Write-Host "  $line"
}
if ($exitCode -ne 0) { $failures += "exited with code $exitCode" }
if ($errorLines.Count -gt 0) { $failures += "printed $($errorLines.Count) error line(s)" }
if (-not ($output | Where-Object { $_ -match '\[shots\] INFO done:' })) { $failures += 'the run did not finish' }

if ($failures.Count -gt 0) {
    Write-Host 'shots: FAIL'
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    Write-Host "Log: $logPath"
    exit 1
}

Write-Host 'shots: PASS'
exit 0
