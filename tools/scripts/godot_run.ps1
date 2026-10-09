<#
.SYNOPSIS
Shared helpers for the tool scripts: find Godot, run it with a time limit, and
sort its output into error lines (dot-source this file).

.DESCRIPTION
A Godot run that hangs (for example GUT aborting without exiting) is killed
after the time limit and reported, so a check can never wait forever.
#>

function Resolve-Godot {
    param([string]$Godot)
    if ($Godot) { return $Godot }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    $default = 'D:\godot\Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path $default) { return $default }
    return 'godot'
}

function Invoke-Godot {
    <#
    Runs Godot with the arguments, writes the output to $LogPath, and returns
    ExitCode, TimedOut, Output (lines) and Errors (error lines not tolerated).
    #>
    param(
        [string]$Godot,
        [string[]]$Arguments,
        [string]$LogPath,
        [int]$TimeoutSeconds = 900,
        [string[]]$Tolerated = @()
    )
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Godot
    $info.Arguments = ($Arguments | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }) -join ' '
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $info.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $process = [System.Diagnostics.Process]::Start($info)
    # Both streams are read in the background so a full pipe never blocks Godot.
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $finished) {
        $process.Kill()
        $process.WaitForExit()
    }
    $text = $stdout.Result + "`n" + $stderr.Result
    $output = @($text -split "`r?`n")
    $output | Set-Content -Path $LogPath -Encoding UTF8
    $errors = @()
    foreach ($line in @($output | Where-Object { $_ -match '^\s*(SCRIPT ERROR|USER ERROR|ERROR):' })) {
        $known = $false
        foreach ($pattern in $Tolerated) {
            if ($line -match $pattern) { $known = $true }
        }
        if ($known) {
            Write-Host "  (tolerated) $line"
        } else {
            $errors += $line
            Write-Host "  $line"
        }
    }
    return [pscustomobject]@{
        ExitCode = if ($finished) { $process.ExitCode } else { -1 }
        TimedOut = -not $finished
        Output = $output
        Errors = $errors
    }
}

# Editor plugins (Terrain3D 1.0.2) leak a dock at exit when the editor imports
# headless. Only these exit-time leak reports are tolerated, and only while
# importing.
$ImportExitLeaks = @(
    '^\s*ERROR: \d+ RID allocations of type .+ were leaked at exit\.$',
    '^\s*ERROR: \d+ resources still in use at exit'
)
