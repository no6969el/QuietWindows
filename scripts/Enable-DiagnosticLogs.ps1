<#
    Enable-DiagnosticLogs.ps1
    ---------------------------------------------------------------
    Turns on the logs needed to catch periodic stutters:
      * TaskScheduler/Operational  - so we can see which task fired
      * Kernel-Processor-Power/... - power/parking state changes
    Read-mostly: only enables event logs, changes nothing else.
    RUN AS ADMINISTRATOR. No reboot needed.
#>

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Host "ERROR: Run as Administrator." -ForegroundColor Red; exit 1 }

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
