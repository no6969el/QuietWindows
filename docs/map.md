---
id: map
title: Code map
kind: map
summary: Where every script, page and test lives, and where to look to change something.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [QuietWindows.bat, QuietWindows-Menu.ps1, Optimize-My-PC.bat, Optimize-My-PC.ps1, scripts/, ui/, extras/, tests/]
---

This doc says where things live in the QuietWindows folder and where to look before changing something.

## Folder tree

```text
QuietWindows.bat            double-click launcher for the menu
QuietWindows-Menu.ps1       the WPF dashboard (loads ui/MainWindow.xaml)
Optimize-My-PC.bat          double-click launcher for the no-menu setup
Optimize-My-PC.ps1          one-shot setup: same fixes as the green button
START-HERE.txt              shortest path for end users
README.md                   what it does and why (end users)
HOW-TO.md                   step-by-step walkthrough (end users)
CHANGELOG.md                release history from 1.0.3 on
CLAUDE.md, AGENTS.md        rules for coding agents
LICENSE                     MIT
ui/
  MainWindow.xaml           every page and button of the dashboard
scripts/
  README.txt                what each script does, for people running them by hand
  Kit-Common.ps1            version, quiet lists, shared paths and helpers
  CPU-Profile.ps1           CPU detection and the X3D catalog
  Game-Library.ps1          the games list (games.json)
  Start-Quiet.ps1           quiet Windows for a session
  Stop-Quiet.ps1            wake Windows back up (replays the snapshot)
  Check-Quiet-Status.ps1    am I quieted right now?
  Watch-For-Reverts.ps1     who switched Windows Update back on?
  Ready-Check.ps1           READY / NOT READY checklist after setup
  Record-Session.ps1        per-second recorder, writes a CSV to the Desktop
  Find-Stutter-Cause.ps1    reads the newest recording, writes stutter-events.txt
  Enable-DiagnosticLogs.ps1 turns on the event logs Find-Stutter-Cause reads
  Watch-TimerResolution.ps1 live timer resolution, for the focus stutter
  Add-Defender-Exclusions.ps1   Defender skips the game folders
  Apply-Extra-Tweaks.ps1 / Undo-Extra-Tweaks.ps1        USB suspend, Game Bar
  Enable-SmoothTimer.ps1 / Undo-SmoothTimer.ps1          global timer requests
  Set-GPU-IRQ-Affinity.ps1 / Undo-GPU-IRQ-Affinity.ps1   GPU interrupt steering
  Set-NIC-USB-IRQ-Affinity.ps1 / Undo-NIC-USB-IRQ-Affinity.ps1  NIC and USB steering
  Repair-PerfCounters.ps1   rebuilds Windows performance counters
  Test-UndervoltStability.ps1   per-core stress and correctness test
  Create-Launchers.ps1      makes a .lnk next to every script
extras/
  README.txt                how to add a per-game folder
  iRacing/                  iRacing-only checks and games-list helper
tests/
  test-*.ps1                standalone test scripts (see operations.md)
  bench-startup.ps1         startup timing benchmark
docs/                       this documentation set
```

## Entry points

- `QuietWindows.bat` runs `QuietWindows-Menu.ps1` in an STA PowerShell (WPF needs it).
- `Optimize-My-PC.bat` runs `Optimize-My-PC.ps1`.
- Every script in `scripts/` can also be run by hand:
  `powershell -ExecutionPolicy Bypass -File scripts\<name>.ps1`.
- `Kit-Common.ps1`, `CPU-Profile.ps1` and `Game-Library.ps1` are libraries. They are
  dot-sourced by other scripts and are not run directly.

## Leave alone

- `LICENSE`.
- Nothing in the repo is generated or vendored. User state lives outside the repo
  (see [data.md](data.md)).

## To change X, look in Y

| To change | Look in |
| --- | --- |
| Which services or scheduled tasks get quieted | `$ServicesToQuiet`, `$TasksToDisable`, `$ServiceDefaults` in `scripts/Kit-Common.ps1` |
| The version number | `$KitVersion` in `scripts/Kit-Common.ps1`, then the banners |
| What Start-Quiet does, step by step | `scripts/Start-Quiet.ps1` (numbered sections 1 to 6) |
| How a session is restored | `scripts/Stop-Quiet.ps1` |
| Button layout or labels | `ui/MainWindow.xaml` |
| What a button does | `QuietWindows-Menu.ps1` (the `Add_Click` handlers) |
| Which fixes the green button and Optimize-My-PC apply | `$fixes` in `Optimize-My-PC.ps1` and the matching code in `QuietWindows-Menu.ps1` |
| Supported CPUs | `$script:CpuCatalog` in `scripts/CPU-Profile.ps1` |
| How games are found | `Get-GameLibraryRoots` and `$script:NotAGamePattern` in `scripts/Game-Library.ps1` |
| The recorder's CSV columns | the header literal in `scripts/Record-Session.ps1` (guarded by `tests/test-locale.ps1`) |
| A per-game fix | a new folder under `extras/` |
