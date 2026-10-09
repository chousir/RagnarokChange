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
    [string]$Godot = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'godot_run.ps1')
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactsDir = Join-Path $projectRoot 'artifacts'
$logDir = Join-Path $artifactsDir (Join-Path 'shots' $Script)
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if (-not (Test-Path (Join-Path $artifactsDir '.gdignore'))) {
    New-Item -ItemType File -Path (Join-Path $artifactsDir '.gdignore') | Out-Null
}
$Godot = Resolve-Godot $Godot

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
$run = Invoke-Godot -Godot $Godot -Arguments $arguments -LogPath (Join-Path $logDir "$name.log") -TimeoutSeconds 600
foreach ($line in @($run.Output | Where-Object { $_ -match '\[shots\]' })) {
    Write-Host "  $line"
}

$failures = @()
if ($run.TimedOut) { $failures += 'the run did not finish in time' }
elseif ($run.ExitCode -ne 0) { $failures += "exited with code $($run.ExitCode)" }
if ($run.Errors.Count -gt 0) { $failures += "printed $($run.Errors.Count) error line(s)" }
if (-not ($run.Output | Where-Object { $_ -match '\[shots\] INFO done:' })) { $failures += 'the run did not finish' }

if ($failures.Count -gt 0) {
    Write-Host 'shots: FAIL'
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    Write-Host "Log: $(Join-Path $logDir "$name.log")"
    exit 1
}

Write-Host 'shots: PASS'
exit 0
