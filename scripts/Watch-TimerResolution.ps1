<#
    Watch-TimerResolution.ps1
    ---------------------------------------------------------------
    Diagnostic for the focus/timer stutter ("it stutters until I click
    on the game window"). Once a second, prints the live system timer
    resolution, which window is in front, and whether your game is
    running. Also saves a spreadsheet to your Desktop.

    What to look for: with your game running, the current resolution
    should sit near 1 ms (often 0.5 ms). If it jumps to ~15.6 ms
    whenever your game loses focus (VR compositor, overlay, alt-tab) and
    that's when you feel the hitching, you have the focus/timer
    problem -> run Enable-SmoothTimer.ps1 (admin) + reboot.

    Read-only, no admin needed. Ctrl+C to stop.
#>

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class TimerRes {
    [DllImport("ntdll.dll")]
    public static extern int NtQueryTimerResolution(out uint min, out uint max, out uint cur);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
}
"@

. (Join-Path $PSScriptRoot 'Game-Library.ps1')

$stamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss', [Globalization.CultureInfo]::InvariantCulture)
$Csv = Join-Path ([Environment]::GetFolderPath('Desktop')) "QuietWindows-TimerWatch-$stamp.csv"
'timestamp,timer_ms,foreground_process,game_running' | Out-File $Csv -Encoding utf8

Write-Host ""
Write-Host "Timer watch -> $Csv" -ForegroundColor Cyan
Write-Host "GOOD = ~1 ms or lower while your game runs. BAD = jumps to ~15.6 ms when your game loses focus." -ForegroundColor Cyan
Write-Host "Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

while ($true) {
    $min = [uint32]0; $max = [uint32]0; $cur = [uint32]0
    [void][TimerRes]::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$cur)
    $curMs = [math]::Round($cur / 10000.0, 2)   # 100-ns units -> ms

    $fg = '?'
    try {
        $h = [TimerRes]::GetForegroundWindow(); $fpid = [uint32]0
        [void][TimerRes]::GetWindowThreadProcessId($h, [ref]$fpid)
        if ($fpid) { $p = Get-Process -Id $fpid -ErrorAction SilentlyContinue; if ($p) { $fg = $p.ProcessName } }
    } catch {}

    $sim = if (Get-RunningGame -Quiet) { 1 } else { 0 }
    $now = Get-Date

    # Invariant formatting: on a comma-decimal locale a timer reading of
    # 0.49 ms would otherwise be written "0,49" and split into two fields.
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    (@(
        $now.ToString('HH:mm:ss', $inv)
        ([double]$curMs).ToString('0.####', $inv)
        ('"' + ("$fg" -replace '"','""') + '"')
        ([int]$sim).ToString($inv)
    ) -join ',') | Out-File $Csv -Append -Encoding utf8

    $color = 'Green'
    if ($curMs -gt 2) { $color = if ($sim -eq 1) { 'Red' } else { 'Yellow' } }
    $simTxt = if ($sim -eq 1) { 'game RUNNING' } else { 'game not running' }
    Write-Host ("{0:HH:mm:ss}  timer {1,6:N2} ms   focus: {2,-24} {3}" -f $now, $curMs, $fg, $simTxt) -ForegroundColor $color

    Start-Sleep -Seconds 1
}
