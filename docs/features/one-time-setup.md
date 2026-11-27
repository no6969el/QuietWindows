---
id: one-time-setup
title: One-time setup (the green button and Optimize-My-PC)
kind: feature
summary: Applies the lasting fixes once (Defender exclusions, USB and Game Bar, task log, smooth timer, GPU interrupts), then asks for a restart.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [Optimize-My-PC.ps1, Optimize-My-PC.bat, QuietWindows-Menu.ps1, scripts/Add-Defender-Exclusions.ps1, scripts/Apply-Extra-Tweaks.ps1, scripts/Undo-Extra-Tweaks.ps1, scripts/Enable-DiagnosticLogs.ps1, scripts/Enable-SmoothTimer.ps1, scripts/Undo-SmoothTimer.ps1]
---

This doc covers the setup a player does once: **1) QUIET MY PC DOWN** in the menu, or
`Optimize-My-PC.bat` with no menu.

## What the user sees

1. Menu page **Quiet my PC**. On an X3D chip an orange section explains the Process
   Lasso steps to do by hand: a power plan on single-CCD chips, CPU Sets on dual-CCD
   chips. Chips without the extra cache skip it and get no confirmation box.
2. **Do the rest for me now** asks for permission once and runs the fixes in one black
   window (about 30 seconds).
3. A restart. Setup does not need repeating.

`Optimize-My-PC.ps1` does the same with a text chip picker and a summary that counts
failed steps.

## How it works

1. Detect the CPU with `Get-CpuProfile` (see [cpu-detection.md](cpu-detection.md)).
2. Build the fix list:
   - `Add-Defender-Exclusions.ps1`: Defender skips every folder on the games list.
   - `Apply-Extra-Tweaks.ps1`: USB selective suspend off on the active power plan; Game
     Mode, Game Bar and Game DVR off.
   - `Enable-DiagnosticLogs.ps1`: TaskScheduler/Operational and processor power logs on.
   - `Enable-SmoothTimer.ps1`: `GlobalTimerResolutionRequests = 1` under
     `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`.
   - `Set-GPU-IRQ-Affinity.ps1`, only on an X3D chip whose topology is known and that
     has a safe target core (`$CanSteer`; see [interrupt-steering.md](interrupt-steering.md)).
3. Run them in one elevated child PowerShell. Optimize-My-PC waits for it, reads each
   step's success, and reports how many failed. The menu's button does not wait (it
   would freeze the window) and only reports launch failures.

## Code

- `Optimize-My-PC.ps1` (`$fixes` list, child script builder)
- `QuietWindows-Menu.ps1` (`BtnRunAuto` handler)
- The fix scripts listed above, each with an Undo where the change is lasting

## Settings and flags

No switches. The chip can be picked by hand in **Your CPU** (menu). Optimize-My-PC shows
its text chip picker only when detection is not confident. `QW_FREQ_FIRST_CORE` and `QW_SIMULATED` are passed to the child.

## Data

Changes Defender exclusions, power plan USB setting, Game Bar registry values, event log
enablement, the kernel timer value and the GPU interrupt policy. Reads `games.json` and
`config.json`.

## Tests

No automated test runs the fixes. `tests/test-integration.ps1` checks the GPU and NIC
target cores every catalog chip would get.

## Edge cases and limits

- "No games added yet" is a skip, not a failure; Defender exclusions exit 0.
- Each fix exits non-zero on a real failure (since 1.0.3), so the summary is honest.
- Declining UAC is reported, not shown as success.
- Process Lasso setup stays manual.

## Related

- [ADR 0003](../adr/0003-fix-scripts-report-their-own-failure.md)
- [game-library.md](game-library.md), [interrupt-steering.md](interrupt-steering.md)
- Glossary: **Fix**, **One-time setup**, **Process Lasso**
