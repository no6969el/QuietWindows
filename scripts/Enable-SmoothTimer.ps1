<#
    Enable-SmoothTimer.ps1
    ---------------------------------------------------------------
    Fixes the "it stutters until I click your game's window" problem.

    Windows 11 only honors a game's high-resolution timer request while
    that game owns FOREGROUND focus. In VR, the compositor constantly
    steals focus from your game's window, so Windows drops the system timer
    from ~1 ms to its 15.625 ms default mid-game -> periodic frame-pacing
    hitches that stop the moment you click your game's window (focus returns,
    the timer snaps back). That click-to-fix pattern is the signature.
    (Confirm it first with Watch-TimerResolution.ps1 if you like.)

    This restores the pre-Windows-11 behavior: high-resolution timer
    requests are honored globally, whether or not the requester has focus.

    RUN AS ADMINISTRATOR. REBOOT for it to take effect.
    Reversible with Undo-SmoothTimer.ps1.
#>

$common = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (-not (Test-Path $common)) {
    Write-Host "ERROR: scripts\Kit-Common.ps1 is missing - re-unzip the kit." -ForegroundColor Red
    exit 1
}
. $common
if (Request-AdminRelaunch) { return }

$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'

Write-Host ""
Write-Host "Enabling global high-resolution timer requests..." -ForegroundColor Cyan
try {
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -Path $key -Name 'GlobalTimerResolutionRequests' -PropertyType DWord -Value 1 -Force | Out-Null
    $v = (Get-ItemProperty -Path $key -Name 'GlobalTimerResolutionRequests').GlobalTimerResolutionRequests
    if ($v -eq 1) {
        Write-Host "  GlobalTimerResolutionRequests = 1  (set)" -ForegroundColor Green
    } else {
        Write-Host "  ! value reads back as $v - expected 1" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  ERROR writing registry: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done. REBOOT for it to take effect." -ForegroundColor Yellow
Write-Host "After the reboot, Watch-TimerResolution.ps1 should show ~1 ms or better" -ForegroundColor DarkGray
Write-Host "while your game runs, even when your game's window doesn't have focus." -ForegroundColor DarkGray
