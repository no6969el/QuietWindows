<#
    Undo-SmoothTimer.ps1
    ---------------------------------------------------------------
    Reverts Enable-SmoothTimer.ps1: removes the
    GlobalTimerResolutionRequests value so Windows 11 goes back to its
    default focus-dependent timer behavior.
    RUN AS ADMINISTRATOR. REBOOT for it to take effect.
#>

$common = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (-not (Test-Path $common)) {
    Write-Host "ERROR: scripts\Kit-Common.ps1 is missing - re-unzip the kit." -ForegroundColor Red
    return
}
. $common
if (Request-AdminRelaunch) { return }

$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'

if (Get-ItemProperty -Path $key -Name 'GlobalTimerResolutionRequests' -ErrorAction SilentlyContinue) {
    Remove-ItemProperty -Path $key -Name 'GlobalTimerResolutionRequests' -Force
    Write-Host "Removed GlobalTimerResolutionRequests - default behavior restored." -ForegroundColor Green
} else {
    Write-Host "GlobalTimerResolutionRequests not set - nothing to undo." -ForegroundColor DarkGray
}

Write-Host "Done. Reboot for it to take effect." -ForegroundColor Yellow
