---
id: game-library
title: Games list (My Games)
kind: feature
summary: One saved list of the games on this PC, found from store folders or added by hand, used for Defender exclusions and stutter hunting.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Game-Library.ps1, scripts/Add-Defender-Exclusions.ps1, QuietWindows-Menu.ps1, extras/iRacing/Add-iRacing-To-My-Games.ps1]
---

This doc covers `scripts/Game-Library.ps1`, the single answer to "which programs and
folders are games on this PC".

## What the user sees

- Menu page **My Games**: the list, **Add a game** (pick an `.exe`), **Remove selected**,
  **Look again** (rescan; clears hand-added games).
- After adding a game they re-run *Stop the virus scanner re-scanning your games* from
  Advanced.

## How it works

1. `Get-GameList` returns the cached or saved list, or scans on first use.
2. `Find-InstalledGames` walks the library roots from `Get-GameLibraryRoots`: Steam
   (registry plus `libraryfolders.vdf`), Epic, Xbox (`XboxGames` on every drive), GOG,
   EA and Origin, Ubisoft, Battle.net and Riot.
3. In each game folder, `Get-GameExesInFolder` keeps programs that look like the game:
   not matching `$script:NotAGamePattern` (installers, crash reporters, launchers,
   anti-cheat, tools) and at least `$script:MinGameExeBytes` (200 KB). Folders matching
   `$script:NotAGameFolder` (runtimes, redistributables) are skipped.
4. `Add-GameEntry -Path` takes an `.exe` or a folder; `Remove-GameEntry -Name` drops one.
5. Consumers ask `Get-GameExeNames`, `Get-GameFolders`, `Test-IsGameProcess`,
   `Get-RunningGame` or `Get-GameProcessRegex`.

## Code

- `scripts/Game-Library.ps1`
- `scripts/Add-Defender-Exclusions.ps1` (folders to exclude)
- `QuietWindows-Menu.ps1` (`Refresh-GameList`, `BtnGameAdd`, `BtnGameRemove`, `BtnGameRescan`)
- `extras/iRacing/Add-iRacing-To-My-Games.ps1` (adds iRacing's three programs and its
  Documents folder)

## Settings and flags

`Get-GameList -Rescan | -NoScan | -Quiet`. No environment variables.

## Data

`%APPDATA%\QuietWindows\games.json`: `SchemaVersion` (1) and `Games`, each with `Name`,
`Exes`, `Folders` and `Source` (`auto` for scanned entries). No admin needed; changes no
Windows setting.

## Tests

No dedicated test. Covered indirectly by manual runs.

## Edge cases and limits

- Unity and Unreal games often have a small launcher stub, which is why the size floor
  is only 200 KB.
- **Look again** discards hand-added games.
- README.md lists six stores; the code also scans Battle.net and Riot.

## Related

- [one-time-setup.md](one-time-setup.md), [stutter-finder.md](stutter-finder.md), [extras.md](extras.md)
- Glossary: **Games list**, **Defender exclusion**
