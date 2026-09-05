<#
    Undo-Extra-Tweaks.ps1
    ---------------------------------------------------------------
    Reverts Apply-Extra-Tweaks.ps1: USB Selective Suspend back ON,
    Game Mode / Game Bar / Game DVR back ON. RUN AS ADMINISTRATOR.
#>

$common = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (-not (Test-Path $common)) {
    Write-Host "ERROR: scripts\Kit-Common.ps1 is missing - re-unzip the kit." -ForegroundColor Red
    return
}
. $common
if (Request-AdminRelaunch) { return }

Write-Host ""
Write-Host "1) USB Selective Suspend -> ON (default)" -ForegroundColor Cyan
$usbSub     = '2a737441-1930-4402-8d77-b2bebba308a3'
$usbSetting = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
try {
    powercfg /setacvalueindex SCHEME_CURRENT $usbSub $usbSetting 1 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT $usbSub $usbSetting 1 | Out-Null
    powercfg /setactive SCHEME_CURRENT | Out-Null
    Write-Host "   restored" -ForegroundColor Green
} catch { Write-Host "   ! failed: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host ""
Write-Host "2) Game Mode / Game Bar / Game DVR -> ON (default)" -ForegroundColor Cyan
function Set-Reg($path, $name, $value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null
}
try {
    Set-Reg 'HKCU:\System\GameConfigStore'     'GameDVR_Enabled'     1
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode'   1
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -ErrorAction SilentlyContinue
    Write-Host "   restored" -ForegroundColor Green
} catch { Write-Host "   ! failed: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host ""
Write-Host "Done." -ForegroundColor Yellow
