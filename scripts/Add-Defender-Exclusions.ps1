<#
    Add-Defender-Exclusions.ps1
    ---------------------------------------------------------------
    Tells Windows Defender to leave your games alone.

    Defender scans files as they are read. A game reading textures,
    audio and level data mid-session gives it a lot to scan, and each
    scan is a tiny pause. Dozens a second add up to a stutter you can
    feel. Excluding the game folders stops that. Defender still guards
    everything else on the PC exactly as before.

    The folder list comes from Game-Library.ps1, so it covers every
    game QuietWindows knows about - the ones it found on Steam, Epic,
    Xbox, GOG, EA and Ubisoft, plus anything you added yourself on the
    My Games screen.

    RUN AS ADMINISTRATOR. No reboot needed. It sticks.
    (To undo one later: Remove-MpPreference -ExclusionPath "<folder>")
#>

. (Join-Path $PSScriptRoot 'Game-Library.ps1')

$common = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (-not (Test-Path $common)) {
    Write-Host "ERROR: scripts\Kit-Common.ps1 is missing - re-unzip the kit." -ForegroundColor Red
    exit 1
}
. $common
if (Request-AdminRelaunch) { return }

if (-not (Get-Command Add-MpPreference -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: the Windows Defender commands are not available here (another antivirus installed?)." -ForegroundColor Red
    Write-Host "Add the same folders as exclusions in that product instead." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Working out which folders to leave alone..." -ForegroundColor Cyan

$paths = New-Object System.Collections.Generic.List[string]
$procs = New-Object System.Collections.Generic.List[string]

# 1) every game folder QuietWindows knows about
foreach ($f in (Get-GameFolders)) { if (Test-Path -LiteralPath $f) { $paths.Add($f) } }
foreach ($e in (Get-GameExeNames)) { $procs.Add("$e.exe") }

# 2) the folder a game is running from right now, even if it is new
$live = Get-RunningGame -Quiet
if ($live) {
    try {
        if ($live.Path) {
            $paths.Add((Split-Path $live.Path))
            $procs.Add("$($live.ProcessName).exe")
            Write-Host "  $($live.ProcessName) is running - including its folder too" -ForegroundColor DarkGray
        }
    } catch { }
}

# 3) save-game and settings folders, which games write to constantly
$docs = [Environment]::GetFolderPath('MyDocuments')
foreach ($sub in 'My Games', 'Saved Games') {
    $c = Join-Path $docs $sub
    if (Test-Path -LiteralPath $c) { $paths.Add($c) }
}
$sg = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Saved Games'
if (Test-Path -LiteralPath $sg) { $paths.Add($sg) }

$paths = @($paths | Sort-Object -Unique)
$procs = @($procs | Sort-Object -Unique)

if ($paths.Count -eq 0) {
    Write-Host ""
    Write-Host "No game folders found yet." -ForegroundColor Yellow
    Write-Host "Open the QuietWindows menu -> My Games -> Add a game, point it at your" -ForegroundColor Yellow
    Write-Host "game's folder, then run this again." -ForegroundColor Yellow
    return   # nothing to do is not a failure - leave the exit code at 0
}

# --- folders ---
Write-Host ""
Write-Host "Folders Defender will now skip:" -ForegroundColor Cyan
foreach ($p in $paths) {
    try { Add-MpPreference -ExclusionPath $p -ErrorAction Stop; Write-Host "  + $p" -ForegroundColor Green }
    catch { Write-Host "  ! could not add: $p ($($_.Exception.Message))" -ForegroundColor Yellow }
}

# --- programs ---
if ($procs.Count) {
    Write-Host ""
    Write-Host "Programs Defender will now skip:" -ForegroundColor Cyan
    foreach ($ex in $procs) {
        try { Add-MpPreference -ExclusionProcess $ex -ErrorAction Stop; Write-Host "  + $ex" -ForegroundColor Green }
        catch { Write-Host "  ! could not add: $ex" -ForegroundColor Yellow }
    }
}

# --- show the result ---
Write-Host ""
Write-Host "Everything Defender is skipping now:" -ForegroundColor Cyan
$prefs = Get-MpPreference
Write-Host "  Folders:" -ForegroundColor Gray
$prefs.ExclusionPath | ForEach-Object { Write-Host "    $_" }
Write-Host "  Programs:" -ForegroundColor Gray
$prefs.ExclusionProcess | ForEach-Object { Write-Host "    $_" }

Write-Host ""
Write-Host "Done. Defender still protects the rest of your PC - it just stops" -ForegroundColor Green
Write-Host "re-scanning your games while you are playing them." -ForegroundColor Green
