---
id: menu
title: The dashboard (QuietWindows-Menu)
kind: feature
summary: A WPF window of plain-language buttons that runs every script in its own window, elevated only when needed.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [QuietWindows.bat, QuietWindows-Menu.ps1, ui/MainWindow.xaml, tests/test-xaml.ps1]
---

This doc covers the menu, the main way people use QuietWindows.

## What the user sees

Pages, from `ui/MainWindow.xaml`:

| Page | Purpose |
| --- | --- |
| Main (`PageMain`) | Quiet my PC down, Before & after playing, Find a stutter, My Games, Advanced, Extras, Help, Your CPU, Exit |
| Quiet my PC (`PageOptimize`) | The one-time setup and the X3D Process Lasso steps |
| Each session (`PageSession`) | Quiet down, wake up, am I game ready |
| Find a stutter (`PageTroubleshoot`) | Recorder, task log, cause finder, Ready Check, timer watch, quiet status |
| My games (`PageGames`) | Games list with add, remove, look again |
| Extras (`PageExtras`) | Per-game buttons built from `extras/` |
| Advanced (`PageAdvanced`) | Every fix alone, each with Undo |
| Your CPU (`PageChip`) | Pick the chip class by hand or go back to auto |
| Help (`PageHelp`) | What it all means |

The header shows the detected CPU and GPU.

## How it works

1. `QuietWindows.bat` starts PowerShell with `-Sta` (WPF needs a single-threaded
   apartment; the script relaunches itself if not).
2. The console window is hidden so it looks like an app.
3. `CPU-Profile.ps1` and `Game-Library.ps1` are loaded; `Get-CpuProfile` runs once.
4. `ui/MainWindow.xaml` is parsed with `XamlReader`. Missing files show a message box.
5. `Show-Page` toggles page visibility and `Resize-ToPage` fits the window.
6. Buttons call `Launch-KitScript`, which starts `powershell.exe -NoExit` for the script,
   with `-Verb RunAs` when it needs admin, and passes `QW_FREQ_FIRST_CORE` and
   `QW_SIMULATED`. A declined UAC prompt shows "Nothing ran".

## Code

`QuietWindows.bat`, `QuietWindows-Menu.ps1`, `ui/MainWindow.xaml`.

## Settings and flags

None. `QW_FORCE_PROFILE` set before launch makes the whole menu behave as that chip.

## Data

Reads `config.json` and `games.json`; writes them through the CPU picker and My Games.

## Tests

`tests/test-xaml.ps1`: the menu loads the external XAML (no inline here-string), the
XAML is well-formed, and every name the script looks up exists in the markup.

## Edge cases and limits

- The green button does not wait for its child window (it would freeze the UI), so it
  reports launch failures only. `Optimize-My-PC.bat` gives the per-step summary.
- `$ErrorActionPreference = 'SilentlyContinue'` at file scope; calls that matter use
  `-ErrorAction Stop`.

## Related

- [ADR 0005](../adr/0005-menu-layout-in-its-own-xaml-file.md)
- [one-time-setup.md](one-time-setup.md), [extras.md](extras.md)
