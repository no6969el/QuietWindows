---
id: overview
title: Overview
kind: overview
summary: Windows PowerShell scripts with a click-through menu that put background Windows work on hold while you play, then hand it all back.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [README.md, HOW-TO.md, CHANGELOG.md, scripts/Kit-Common.ps1]
---

This doc says what QuietWindows is, who it is for and where to read next.

## What it does

QuietWindows puts Windows Update, Search, Store updates, scheduled maintenance and
other background work on hold while you play, and restores everything exactly when you
finish. It also applies lasting fixes for common stutter causes (Defender re-scanning
game folders, USB power saving, the focus timer, interrupts on the game's core) and
includes a recorder that names what interrupted a game.

## Who uses it

- PC gamers on Windows 10 or 11 who get stutters, written for people who "can
  double-click a file" (HOW-TO.md). Sim racers and VR players are the original audience,
  and AMD X3D owners get extra steps.
- Contributors who change the scripts. They start here and in `AGENTS.md`.

## Status

Active. Latest release v1.0.4 (2026-09-04) on GitHub. Rebased from the iRacing X3D
Tuning Kit, whose 3.x history is still quoted in script comments. The Tuning Kit is
still its own project, not retired; changes to it don't belong in this repo.

## Tech stack

- Windows PowerShell 5.1 scripts (`.ps1`), launched from `.bat` files
- WPF menu defined in XAML (`ui/MainWindow.xaml`)
- Windows tools: services and Task Scheduler cmdlets, Defender cmdlets, `powercfg`,
  `wevtutil`, `schtasks`; optional xperf, MSI Afterburner, nvidia-smi
- Tests in PowerShell 7 (`pwsh`), standalone scripts
- MIT licence

## Quick start

```
QuietWindows.bat
```

Press **QUIET MY PC DOWN**, restart, then use **Quiet Windows down** before each game and
**Wake Windows back up** after it.

## Where to go next

- [architecture.md](architecture.md): the parts and how they connect
- [map.md](map.md): where things are in the folder
- Features: [quiet session](features/quiet-session.md),
  [one-time setup](features/one-time-setup.md), [CPU detection](features/cpu-detection.md),
  [interrupt steering](features/interrupt-steering.md), [games list](features/game-library.md),
  [stutter finder](features/stutter-finder.md), [checks](features/health-checks.md),
  [menu](features/menu.md), [extras](features/extras.md)
- [operations.md](operations.md): run, test, release, configure
- [interfaces.md](interfaces.md) and [data.md](data.md)
- [GLOSSARY.md](GLOSSARY.md), [known-issues.md](known-issues.md), [adr/](adr/)
- For players: [README.md](../README.md), [HOW-TO.md](../HOW-TO.md),
  [START-HERE.txt](../START-HERE.txt), [scripts/README.txt](../scripts/README.txt)
