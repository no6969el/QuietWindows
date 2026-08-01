<#
    Add-iRacing-To-My-Games.ps1
    ---------------------------------------------------------------
    Finds iRacing on this PC and puts it on your QuietWindows games
    list, including the bits the normal scan would miss.

    Why iRacing needs its own version of this:

      * It runs three programs, not one - the sim itself, the launcher
        UI, and a background service. All three want to be left alone
        by the virus scanner.
      * Its settings, setups, replays and telemetry live in your
        Documents folder, nowhere near where the game is installed,
        and it writes to them constantly while you drive. A normal
        scan would only ever find the install folder.

    Changes nothing else. Safe to run more than once.
#>

$lib = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'scripts\Game-Library.ps1'
if (-not (Test-Path -LiteralPath $lib)) {
    Write-Host "Could not find scripts\Game-Library.ps1 - keep this folder inside QuietWindows." -ForegroundColor Red
    Read-Host "Press Enter to close" | Out-Null
    return
}
. $lib

Write-Host ""
Write-Host "Looking for iRacing..." -ForegroundColor Cyan

$folders = New-Object System.Collections.Generic.List[string]

# 1) the Documents folder - almost always there, and the busiest one
$docs = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'iRacing'
if (Test-Path -LiteralPath $docs) { $folders.Add($docs); Write-Host "  found  $docs" -ForegroundColor Green }

# 2) wherever it is running from, if it happens to be open
$proc = Get-Process iRacingSim64DX11, iRacingUI, iRacingService64 -ErrorAction SilentlyContinue |
        Where-Object { $_.Path } | Select-Object -First 1
if ($proc) {
    $p = Split-Path $proc.Path
    $folders.Add($p); Write-Host "  found  $p  (it is running right now)" -ForegroundColor Green
}

# 3) the usual install spots, on every drive
$subs = @(
    'SteamLibrary\steamapps\common\iRacing',
    'Steam\steamapps\common\iRacing',
    'Program Files (x86)\Steam\steamapps\common\iRacing',
    'Program Files (x86)\iRacing',
    'Program Files\iRacing',
    'iRacing'
)
foreach ($root in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue).Root) {
    foreach ($sub in $subs) {
        $c = Join-Path $root $sub
        if (Test-Path -LiteralPath $c) { $folders.Add($c); Write-Host "  found  $c" -ForegroundColor Green }
    }
}

$folders = @($folders | Sort-Object -Unique)

if ($folders.Count -eq 0) {
    Write-Host ""
    Write-Host "Could not find iRacing anywhere obvious." -ForegroundColor Yellow
    Write-Host "Use My Games -> Add a game in the QuietWindows menu and point it at" -ForegroundColor Yellow
    Write-Host "iRacingSim64DX11.exe by hand." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
    return
}

# Put it on the list with all three programs and every folder we found.
$list = Get-GameList -Quiet
$keep = @($list.Games | Where-Object { $_.Name -ine 'iRacing' })
$keep += [PSCustomObject]@{
    Name    = 'iRacing'
    Exes    = @('iRacingSim64DX11','iRacingUI','iRacingService64')
    Folders = $folders
    Source  = 'manual'
}
$list.Games = $keep

if (Save-GameList $list) {
    Write-Host ""
    Write-Host "iRacing is on your games list." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next: open the QuietWindows menu -> Advanced -> 'Stop the virus scanner" -ForegroundColor Cyan
    Write-Host "re-scanning your games' so these folders actually get skipped." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Could not save the games list." -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close" | Out-Null
