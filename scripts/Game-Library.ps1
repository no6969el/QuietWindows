<#
    Game-Library.ps1  -  which games QuietWindows looks after        v1.0.0
    ================================================================
    SINGLE SOURCE OF TRUTH for "what counts as a game on this PC".
    Dot-source:  . (Join-Path $PSScriptRoot 'Game-Library.ps1')

    One list (instead of the same game name typed into many scripts).
    Stored at %APPDATA%\QuietWindows\games.json. No admin; changes no
    Windows settings - safe for read-only scripts to load.

    Main entry points: Get-GameList / Get-GameExeNames / Get-GameFolders /
    Get-RunningGame / Test-IsGameProcess / Find-InstalledGames /
    Add-GameEntry / Remove-GameEntry / Save-GameList / Reset-GameList.
#>

$script:GameSchemaVersion = 1
$script:GameConfigDir     = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'QuietWindows'
$script:GameConfigFile    = Join-Path $script:GameConfigDir 'games.json'
$script:GameListCache     = $null

# ================================================================
#  Programs that live in game folders but are not the game.
#  Matching any of these means "don't offer this as a game".
# ================================================================
$script:NotAGamePattern = @(
    # installers and runtimes shipped alongside the game
    'unins', 'setup', 'installer', 'redist', 'vcredist', 'directx', 'dxsetup',
    'dotnet', 'oalinst', 'openal', 'physx', 'rapture3d', 'ffdshow',
    # crash, dump and error reporting
    'crash', 'createdump', 'dumper', 'minidump', 'bugreport', 'errorreport',
    'sndrpt', 'uploader', 'reporter', 'telemetryd',
    # launchers, updaters, downloaders
    'launcher', 'updater', 'update', 'patcher', 'downloader', 'repair',
    'cleanup', 'cleaner', 'quickboot', 'touchup',
    # anti-cheat and DRM shims
    'anticheat', 'easyanticheat', 'battleye', 'beservice', '_be$',
    'start_protected', 'eac_', 'denuvo',
    # tools that live in game folders but are not the game
    'benchmark', '^config', 'settings', 'editor', 'server', 'dedicated',
    'diag', 'viewer', '_info$', 'vulkaninfo', 'helper', 'webhelper',
    'overlay', 'handler', 'uninstall', 'support', 'service', 'host$',
    'epiconlineservices', 'steamvr', '^vr', 'openvr', 'eosoverlay'
) -join '|'

# ================================================================
#  Folders that sit in a game library but are not games. These are
#  runtimes, shared components and store plumbing that every library
#  has, and none of them are worth an antivirus exclusion.
# ================================================================
$script:NotAGameFolder = @(
    'steamvr', 'steamworks shared', 'steam linux runtime', 'proton',
    'epic online services', 'directx', '_commonredist', 'redist',
    'soundtrack', 'artbook', 'wallpaper', 'bonus content',
    'ubisoft game launcher', 'ea desktop', 'origin', 'battle.net',
    'nvidia corporation', 'amd', 'crossplay'
) -join '|'

# A real game's main program is rarely tiny. Below this we assume it is a
# helper of some kind.
#
# Deliberately low. Games built in Unity and Unreal put a small stub in the
# top folder that launches the real thing, and that stub is often only a few
# hundred kilobytes. Set this to a megabyte and half your library disappears.
$script:MinGameExeBytes = 200KB

# ================================================================
#  Where the stores put things. Used both to find games and to decide
#  "that running program lives in a game folder, so it is probably a
#  game" when the program itself is not on the list yet.
# ================================================================
function Get-GameLibraryRoots {
    <#
        Every folder on this PC that games are likely to be installed
        under. Cheap - it only looks at folders that already exist.
    #>
    $roots = New-Object System.Collections.Generic.List[string]

    function Add-Root([string]$p) {
        if ($p -and (Test-Path -LiteralPath $p)) {
            $full = (Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue).Path
            if ($full -and -not ($roots -contains $full)) { $roots.Add($full) }
        }
    }

    # ---- Steam ---------------------------------------------------
    $steam = $null
    foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
        try {
            $v = (Get-ItemProperty -Path $k -ErrorAction Stop)
            if ($v.SteamPath)   { $steam = $v.SteamPath }
            elseif ($v.InstallPath) { $steam = $v.InstallPath }
            if ($steam) { break }
        } catch { }
    }
    if ($steam) {
        Add-Root (Join-Path $steam 'steamapps\common')
        # Extra Steam libraries are listed in libraryfolders.vdf.
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            try {
                foreach ($line in (Get-Content -LiteralPath $vdf -ErrorAction Stop)) {
                    if ($line -match '"path"\s*"([^"]+)"') {
                        Add-Root (Join-Path ($matches[1] -replace '\\\\', '\') 'steamapps\common')
                    }
                }
            } catch { }
        }
    }

    # ---- Epic ----------------------------------------------------
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'Epic Games')
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Epic Games')

    # ---- Xbox / Microsoft Store ----------------------------------
    foreach ($d in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        Add-Root (Join-Path $d.Root 'XboxGames')
    }

    # ---- GOG -----------------------------------------------------
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'GOG Galaxy\Games')
    Add-Root "$env:SystemDrive\GOG Games"

    # ---- EA / Origin ---------------------------------------------
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'EA Games')
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'EA Games')
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Origin Games')

    # ---- Ubisoft -------------------------------------------------
    try {
        $u = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Ubisoft\Launcher' -ErrorAction Stop).InstallDir
        if ($u) { Add-Root (Join-Path $u 'games') }
    } catch { }
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Ubisoft\Ubisoft Game Launcher\games')

    # ---- Battle.net ----------------------------------------------
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Battle.net')
    Add-Root (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Blizzard')

    # ---- Riot ----------------------------------------------------
    Add-Root "$env:SystemDrive\Riot Games"

    return $roots.ToArray()
}

# ================================================================
#  Reading and writing the saved list
# ================================================================
function Get-GameConfigPath { return $script:GameConfigFile }

function Import-GameList {
    if (-not (Test-Path -LiteralPath $script:GameConfigFile)) { return $null }
    try {
        $c = Get-Content -LiteralPath $script:GameConfigFile -Raw -ErrorAction Stop | ConvertFrom-Json
        if (-not $c.SchemaVersion -or [int]$c.SchemaVersion -lt $script:GameSchemaVersion) { return $null }
        return $c
    } catch { return $null }
}

function Save-GameList {
    param([Parameter(Mandatory)]$List)
    try {
        if (-not (Test-Path -LiteralPath $script:GameConfigDir)) {
            New-Item -ItemType Directory -Path $script:GameConfigDir -Force | Out-Null
        }
        $List.SchemaVersion = $script:GameSchemaVersion
        $List | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $script:GameConfigFile -Encoding utf8
        $script:GameListCache = $List
        return $true
    } catch { return $false }
}

function Reset-GameList {
    $script:GameListCache = $null
    if (Test-Path -LiteralPath $script:GameConfigFile) {
        Remove-Item -LiteralPath $script:GameConfigFile -Force -ErrorAction SilentlyContinue
    }
}

# ================================================================
#  Finding installed games
# ================================================================
function Test-LooksLikeGameExe {
    param([string]$Name)
    if (-not $Name) { return $false }
    return -not ($Name -match "(?i)($script:NotAGamePattern)")
}

function Get-GameExesInFolder {
    <#
        Pick the programs in a game folder that are most likely to BE
        the game.

        Three signals, and they matter in this order:

          1. Depth. A game's main program usually sits in the game's own
             top folder. Crash handlers, tools and redistributables hide
             in subfolders. So we look at the top level first and only
             go deeper if we found nothing there.
          2. Size. A game is big. Anything under a megabyte is almost
             certainly a helper.
          3. Name. An explicit list of words that mean "not the game" -
             uninstallers, updaters, crash reporters and so on.

        Getting this wrong is not dangerous. A missed game means a
        missing antivirus exclusion, and a wrong guess means one extra
        harmless name on a list. Either way the My Games page lets the
        user fix it by hand.
    #>
    param(
        [Parameter(Mandatory)][string]$Folder,
        [int]$Max = 2
    )

    function Pick($items) {
        @($items |
          Where-Object { Test-LooksLikeGameExe $_.BaseName } |
          Where-Object { $_.Length -ge $script:MinGameExeBytes } |
          Sort-Object Length -Descending |
          Select-Object -First $Max |
          ForEach-Object { $_.BaseName })
    }

    $found = @()
    try {
        # 1) top level of the game's own folder
        $top   = Get-ChildItem -LiteralPath $Folder -Filter *.exe -File -ErrorAction SilentlyContinue
        $found = @(Pick $top)

        # 2) Unreal Engine games put a small stub in the top folder and the
        #    real program in Binaries\Win64, named "<Game>-Win64-Shipping.exe".
        #    That second one is what actually shows up in Task Manager, so we
        #    want both. Same filters apply - an overlay renderer is not a game.
        $ship = @(Get-ChildItem -LiteralPath $Folder -Filter *-Shipping.exe -File -Recurse -Depth 4 -ErrorAction SilentlyContinue |
                  Where-Object { Test-LooksLikeGameExe $_.BaseName } |
                  Where-Object { $_.Length -ge $script:MinGameExeBytes } |
                  Sort-Object Length -Descending | Select-Object -First 1)
        if ($ship.Count -and ($found -notcontains $ship[0].BaseName)) { $found = @($found) + $ship[0].BaseName }

        # 3) nothing found yet - some games hide everything in a Bin folder,
        #    so go two levels down before giving up
        if ($found.Count -eq 0) {
            $deep  = Get-ChildItem -LiteralPath $Folder -Filter *.exe -File -Recurse -Depth 2 -ErrorAction SilentlyContinue
            $found = @(Pick $deep)
        }
    } catch { }
    # A game can ship the same program name in two places (a launcher copy
    # and the real one). Listing it twice is harmless but looks broken.
    return @($found | Select-Object -Unique)
}

# ================================================================
#  IS THIS FOLDER BEING SKIPPED BY THE VIRUS SCANNER?
# ================================================================
function Test-DefenderExclusion {
    <#
        Answers "is Windows Defender leaving this folder alone?"

        Returns one of:
            'covered'    yes - this folder, or a folder above it, is excluded
            'not'        no
            'noaccess'   cannot tell without permission (see below)
            'nodefender' Defender is not the antivirus here

        TWO THINGS THIS EXISTS TO GET RIGHT
        -----------------------------------
        1. Get-MpPreference run WITHOUT permission does not fail and does
           not return an empty list. It returns a single fake entry reading
           "N/A: Must be an administrator to view exclusions". Compare that
           against a real path and you get "not excluded" every single time,
           for everybody, forever - a warning that can never be satisfied.
           So we detect that placeholder and say "cannot tell" instead.

        2. Defender exclusions cascade downwards. Excluding
           C:\Games also excludes C:\Games\Whatever. A plain equality test
           reports a correctly-protected folder as unprotected, so we check
           whether any exclusion IS the folder or sits above it, and ignore
           trailing slashes and capitalisation while doing it.
    #>
    param([Parameter(Mandatory)][string]$Folder)

    if (-not (Get-Command Get-MpPreference -ErrorAction SilentlyContinue)) { return 'nodefender' }

    $ex = @()
    try { $ex = @((Get-MpPreference -ErrorAction Stop).ExclusionPath) } catch { return 'nodefender' }

    # the "you are not an administrator" placeholder
    if ($ex.Count -eq 1 -and "$($ex[0])" -match '^N/A:') { return 'noaccess' }

    $target = $Folder.TrimEnd('\')
    foreach ($e in $ex) {
        if (-not $e) { continue }
        $n = "$e".TrimEnd('\')
        if ($target -ieq $n) { return 'covered' }
        if ($target.StartsWith($n + '\', [StringComparison]::OrdinalIgnoreCase)) { return 'covered' }
    }
    return 'not'
}

function Find-InstalledGames {
    <#
        Walk every library root and turn each game folder into an
        entry. Deliberately shallow and forgiving: a missed game is a
        missing Defender exclusion, not a broken PC, and anything it
        gets wrong the user can fix on the My Games screen.
    #>
    param([switch]$Quiet)

    $games = @()
    $roots = Get-GameLibraryRoots

    foreach ($root in $roots) {
        if (-not $Quiet) { Write-Host "  looking in $root" -ForegroundColor DarkGray }
        try {
            $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
        } catch { continue }

        foreach ($d in $dirs) {
            if ($d.Name -match "(?i)($script:NotAGameFolder)") { continue }
            $exes = Get-GameExesInFolder -Folder $d.FullName
            if ($exes.Count -eq 0) { continue }
            $games += [PSCustomObject]@{
                Name    = $d.Name
                Exes    = $exes
                Folders = @($d.FullName)
                Source  = 'auto'
            }
        }
    }

    # ---- Epic keeps a manifest per game; it names the program for us
    $epicManifests = (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Epic\EpicGamesLauncher\Data\Manifests')
    if (Test-Path -LiteralPath $epicManifests) {
        foreach ($m in (Get-ChildItem -LiteralPath $epicManifests -Filter *.item -ErrorAction SilentlyContinue)) {
            try {
                $j = Get-Content -LiteralPath $m.FullName -Raw | ConvertFrom-Json
                if (-not $j.InstallLocation) { continue }
                $exe = if ($j.LaunchExecutable) { [IO.Path]::GetFileNameWithoutExtension($j.LaunchExecutable) } else { $null }
                if (-not (Test-LooksLikeGameExe $exe)) { continue }
                $games += [PSCustomObject]@{
                    Name    = if ($j.DisplayName) { $j.DisplayName } else { $j.AppName }
                    Exes    = @($exe)
                    Folders = @($j.InstallLocation)
                    Source  = 'auto'
                }
            } catch { }
        }
    }

    # ---- fold duplicates together (same folder found twice)
    $seen  = @{}
    $final = @()
    foreach ($g in $games) {
        $key = ($g.Folders[0]).ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $final += $g
    }
    return $final
}

# ================================================================
#  The list everything else uses
# ================================================================
function Get-GameList {
    <#
        Returns the saved list. First time out it scans for games and
        saves what it finds, so nothing has to ask the user anything
        before it can work.

        -Rescan  throw the saved list away and look again
        -NoScan  return whatever is saved, even if that is nothing
    #>
    param([switch]$Rescan, [switch]$NoScan, [switch]$Quiet)

    if ($Rescan) { $script:GameListCache = $null }
    if ($script:GameListCache -and -not $Rescan) { return $script:GameListCache }

    $saved = if ($Rescan) { $null } else { Import-GameList }
    if ($saved) { $script:GameListCache = $saved; return $saved }

    if ($NoScan) {
        return [PSCustomObject]@{
            SchemaVersion = $script:GameSchemaVersion
            ScannedOn     = $null
            Games         = @()
        }
    }

    if (-not $Quiet) { Write-Host "Looking for installed games (first run only)..." -ForegroundColor Cyan }
    $list = [PSCustomObject]@{
        SchemaVersion = $script:GameSchemaVersion
        ScannedOn     = (Get-Date).ToString('s')
        Games         = @(Find-InstalledGames -Quiet:$Quiet)
    }
    Save-GameList $list | Out-Null
    $script:GameListCache = $list
    return $list
}

function Get-GameExeNames {
    <# Every program name we treat as a game, without the .exe. #>
    param([switch]$Quiet)
    $l = Get-GameList -Quiet:$Quiet
    $names = @()
    foreach ($g in $l.Games) { foreach ($e in $g.Exes) { if ($e) { $names += $e } } }
    return ($names | Sort-Object -Unique)
}

function Get-GameFolders {
    <# Every folder we treat as a game folder. #>
    param([switch]$Quiet)
    $l = Get-GameList -Quiet:$Quiet
    $f = @()
    foreach ($g in $l.Games) { foreach ($p in $g.Folders) { if ($p) { $f += $p } } }
    return ($f | Sort-Object -Unique)
}

function Test-IsGameProcess {
    <#
        Is this process name one of our games? Accepts "Game.exe" or
        just "Game". Case does not matter.
    #>
    param([string]$Name, [switch]$Quiet)
    if (-not $Name) { return $false }
    $bare = $Name -replace '\.exe$', ''
    foreach ($n in (Get-GameExeNames -Quiet:$Quiet)) {
        if ($bare -ieq $n) { return $true }
    }
    return $false
}

function Get-RunningGame {
    <#
        Which of our games is running right now, if any. Returns the
        process object, or $null.

        Two passes: the saved list first, then anything running out of
        a known game library folder. The second pass is what catches a
        game installed after the last scan.
    #>
    param([switch]$Quiet)

    $procs = @(Get-Process -ErrorAction SilentlyContinue)

    $names = Get-GameExeNames -Quiet:$Quiet
    if ($names.Count) {
        $hit = $procs | Where-Object { $names -contains $_.ProcessName } |
               Sort-Object WorkingSet64 -Descending | Select-Object -First 1
        if ($hit) { return $hit }
    }

    $roots = Get-GameLibraryRoots
    if ($roots.Count) {
        $hit = $procs | Where-Object {
            $p = $null
            try { $p = $_.Path } catch { }
            if (-not $p) { return $false }
            foreach ($r in $roots) { if ($p.StartsWith($r, [StringComparison]::OrdinalIgnoreCase)) { return $true } }
            return $false
        } | Sort-Object WorkingSet64 -Descending | Select-Object -First 1
        if ($hit) { return $hit }
    }

    return $null
}

function Get-GameProcessRegex {
    <#
        A single regex that matches any of our game program names, for
        the scripts that scan a log full of process names. Returns
        $null when we do not know about any games yet, and callers
        treat that as "match nothing".

        Trace logs write a process as "Game.exe (1234)", so the
        pattern allows an optional .exe and anything after it, but
        still refuses to let "Game" match "GameLauncher".
    #>
    param([switch]$Quiet)
    $names = Get-GameExeNames -Quiet:$Quiet
    if (-not $names -or $names.Count -eq 0) { return $null }
    $escaped = $names | ForEach-Object { [regex]::Escape($_) }
    return ('(?i)^(' + ($escaped -join '|') + ')(\.exe)?([^A-Za-z0-9_]|$)')
}

# ================================================================
#  Adding and removing by hand
# ================================================================
function Add-GameEntry {
    <#
        Point this at a game's program file OR its folder and it works
        the rest out.

            Add-GameEntry -Path 'D:\Games\Cool Game\CoolGame.exe'
            Add-GameEntry -Path 'D:\Games\Cool Game'
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "That path does not exist: $Path" -ForegroundColor Yellow
        return $false
    }

    $item = Get-Item -LiteralPath $Path
    if ($item.PSIsContainer) {
        $folder = $item.FullName
        $exes   = Get-GameExesInFolder -Folder $folder
        if (-not $Name) { $Name = $item.Name }
    } else {
        $folder = $item.DirectoryName
        $exes   = @($item.BaseName)
        if (-not $Name) { $Name = $item.BaseName }
    }

    if ($exes.Count -eq 0) {
        Write-Host "Could not find a program to watch in that folder." -ForegroundColor Yellow
        return $false
    }

    $list = Get-GameList -Quiet
    $keep = @($list.Games | Where-Object { $_.Folders -and $_.Folders[0] -ine $folder })
    $keep += [PSCustomObject]@{
        Name    = $Name
        Exes    = $exes
        Folders = @($folder)
        Source  = 'manual'
    }
    $list.Games = $keep
    Save-GameList $list | Out-Null
    Write-Host "Added: $Name  ($($exes -join ', '))" -ForegroundColor Green
    return $true
}

function Remove-GameEntry {
    param([Parameter(Mandatory)][string]$Name)
    $list = Get-GameList -Quiet
    $before = @($list.Games).Count
    $list.Games = @($list.Games | Where-Object { $_.Name -ine $Name })
    Save-GameList $list | Out-Null
    $gone = $before - @($list.Games).Count
    if ($gone -gt 0) { Write-Host "Removed: $Name" -ForegroundColor Green; return $true }
    Write-Host "Nothing on the list is called '$Name'." -ForegroundColor Yellow
    return $false
}

function Write-GameListSummary {
    <# Friendly one-screen rundown, used by the menu and the docs. #>
    param([switch]$Quiet)
    $l = Get-GameList -Quiet:$Quiet
    $n = @($l.Games).Count
    if ($n -eq 0) {
        Write-Host "No games on the list yet." -ForegroundColor Yellow
        Write-Host "Use 'My Games' in the QuietWindows menu to add one." -ForegroundColor Gray
        return
    }
    Write-Host "$n game(s) on the list:" -ForegroundColor Cyan
    foreach ($g in $l.Games) {
        $tag = if ($g.Source -eq 'manual') { ' (added by you)' } else { '' }
        Write-Host ("   {0,-38} {1}{2}" -f $g.Name, ($g.Exes -join ', '), $tag) -ForegroundColor Gray
    }
}
