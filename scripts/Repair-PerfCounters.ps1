<#
    Repair-PerfCounters.ps1
    ---------------------------------------------------------------
    If every counter-based column in a Record-Session comes back empty
    (per-core load, interrupt/DPC time, pagefaults), your Windows
    performance counters are corrupt - a surprisingly common Windows
    fault. This rebuilds them so the trace can measure the CCD split,
    confirm the GPU-interrupt move, and expose periodic hitches.

    RUN AS ADMINISTRATOR, then REBOOT.
#>

$common = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (-not (Test-Path $common)) {
    Write-Host "ERROR: scripts\Kit-Common.ps1 is missing - re-unzip the kit." -ForegroundColor Red
    return
}
. $common
if (Request-AdminRelaunch) { return }

Write-Host "Rebuilding performance counter registry (64-bit)..." -ForegroundColor Cyan
& "$env:windir\system32\lodctr.exe" /R

Write-Host "Rebuilding performance counter registry (32-bit)..." -ForegroundColor Cyan
& "$env:windir\syswow64\lodctr.exe" /R

Write-Host "Refreshing WMI performance classes (WMIADAP)..." -ForegroundColor Cyan
$wmiadap = "$env:windir\system32\wbem\wmiadap.exe"
if (Test-Path $wmiadap) {
    & $wmiadap /f
    Write-Host "  wmiadap /f done" -ForegroundColor Green
} else {
    Write-Host "  wmiadap.exe not found - skipping (the lodctr /R above is the main fix)" -ForegroundColor DarkGray
}
# best-effort WMI perf resync if the command is available on PATH
$wm = Get-Command winmgmt -ErrorAction SilentlyContinue
if ($wm) { try { & winmgmt /resyncperf } catch { } }

Write-Host ""
Write-Host "Done. REBOOT, then re-run Ready-Check - the per-core columns should populate." -ForegroundColor Green
Write-Host "If they still don't populate, the deeper fix is rebuilding the WMI repository (search 'winmgmt salvagerepository')." -ForegroundColor DarkGray
