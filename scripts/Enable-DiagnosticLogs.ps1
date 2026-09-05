<#
    Enable-DiagnosticLogs.ps1
    ---------------------------------------------------------------
    Turns on the logs needed to catch periodic stutters:
      * TaskScheduler/Operational  - so we can see which task fired
      * Kernel-Processor-Power/... - power/parking state changes
    Read-mostly: only enables event logs, changes nothing else.
    RUN AS ADMINISTRATOR. No reboot needed.
#>

$common = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (-not (Test-Path $common)) {
    Write-Host "ERROR: scripts\Kit-Common.ps1 is missing - re-unzip the kit." -ForegroundColor Red
    exit 1
}
. $common
if (Request-AdminRelaunch) { return }

$failed = 0

$logs = @(
    'Microsoft-Windows-TaskScheduler/Operational',
    'Microsoft-Windows-Kernel-Processor-Power/Diagnostic'
)

foreach ($log in $logs) {
    try {
        # /q:true auto-confirms the "analytic/debug logs will be cleared" prompt
        & wevtutil sl "$log" /enabled:true /q:true
        if ($LASTEXITCODE -ne 0) { throw "wevtutil exited $LASTEXITCODE" }
        Write-Host "Enabled: $log" -ForegroundColor Green
    } catch {
        $failed++
        Write-Host "Could not enable $log : $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done. These now record - re-run your test session, then Find-Stutter-Cause.ps1." -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
