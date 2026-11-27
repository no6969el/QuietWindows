---
id: extras
title: Extras (per-game fixes)
kind: feature
summary: Drop a folder into extras/ and each .ps1 in it becomes a button on the Extras page; iRacing ships as the first one.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [extras/, QuietWindows-Menu.ps1]
---

This doc covers the Extras page and the per-game folders under `extras/`.

## What the user sees

The menu's **Extras** page shows one expandable section per game folder, with the
folder's `README.txt` as its description and one button per script. Scripts named
`Admin-*.ps1` show "(permission needed)" and run elevated.

## How it works

1. `Build-ExtrasPage` in `QuietWindows-Menu.ps1` lists folders under `extras/` each time
   the page opens.
2. Each `.ps1` becomes a button; the label is the file name with `Admin-` dropped and
   dashes turned into spaces.
3. Pressing a button runs the script like any other kit script.

Shipped: `extras/iRacing/`
- `Add-iRacing-To-My-Games.ps1`: adds iRacing's three programs and its
  `Documents\iRacing` folder to the games list.
- `Check-iRacing-Setup.ps1`: checks the games list, the Defender exclusion on
  `Documents\iRacing`, a Process Lasso CPU Set rule (and no hard affinity, which
  iRacing's anti-cheat rejects), and which wheel and telemetry apps are running.

## Code

`QuietWindows-Menu.ps1` (`Build-ExtrasPage`), `extras/README.txt`, `extras/iRacing/`.

## Settings and flags

The `Admin-` file-name prefix. Nothing else.

## Data

iRacing scripts read and write `games.json` and read Process Lasso's config.

## Tests

None.

## Edge cases and limits

- A folder with no `.ps1` files is skipped.
- No QuietWindows file needs editing to add a game.

## Related

- [how-to/add-an-extras-folder.md](../how-to/add-an-extras-folder.md)
- [game-library.md](game-library.md)
- Glossary: **Extras**
