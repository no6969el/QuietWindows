---
id: health-checks
title: Checks and diagnostics
kind: feature
summary: Read-only tools that say whether setup took, whether you are quieted, what reverted, timer behaviour, and CPU undervolt stability.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Ready-Check.ps1, scripts/Check-Quiet-Status.ps1, scripts/Watch-For-Reverts.ps1, scripts/Watch-TimerResolution.ps1, scripts/Test-UndervoltStability.ps1, scripts/Create-Launchers.ps1]
---

This doc covers the tools that report and change nothing (plus the shortcut maker).

## What the user sees

| Tool | Where in the menu | Output |
| --- | --- | --- |
| `Ready-Check.ps1` | Find a stutter | Checklist ending READY or NOT READY |
| `Check-Quiet-Status.ps1` | Before & after (button 3), Find a stutter | Quiet or normal, with anything still live listed |
| `Watch-For-Reverts.ps1` | Advanced | Timeline of what switched services back on |
| `Watch-TimerResolution.ps1` | Find a stutter | Timer resolution each second, plus a Desktop CSV |
| `Test-UndervoltStability.ps1` | Advanced | Per-core pass or error, CSV report |
| `Create-Launchers.ps1` | Advanced | A `.lnk` next to every script |

## How it works

- **Ready-Check** confirms each one-time fix is live after a restart; pinning and
  interrupt checks are skipped on chips they don't apply to.
- **Check-Quiet-Status** reports each quieted service's running state and startup type,
  each task, the Store policy, and whether an unrestored snapshot exists. The verdict
  needs every visible task off. Run elevated: some Medic tasks are hidden otherwise.
- **Watch-For-Reverts** reads `QuietWindows.log`, System events 7040 and 7036, the
  WaaSMedic and TaskScheduler operational logs and WindowsUpdateClient, and lines them up.
- **Watch-TimerResolution** prints the live timer resolution, the foreground window and
  whether the game runs. Near 1 ms is good; jumps to about 15.6 ms on focus loss mean the
  focus stutter, fixed by Enable-SmoothTimer.
- **Test-UndervoltStability** runs deterministic, hashed work per core in child
  processes (Light bursts and Heavy load), captures WHEA errors, and remembers which
  core a crash died on.

## Code

The six scripts above, launched from `QuietWindows-Menu.ps1`.

## Settings and flags

- `Watch-For-Reverts.ps1 -Hours <n> -Export`
- `Test-UndervoltStability.ps1 -Preset <name> -Mode <Light|Heavy|Both> -Cores <list> -SecondsPerCore <n> -Cycles <n> -Shuffle -StopOnError -NoClocks -LogPath -ReportPath -NoAvx512` (AVX-512 needs PowerShell 7)

## Data

Read-only, apart from Desktop reports (`-Export`, timer CSV, stability CSV and log) and
the shortcuts Create-Launchers makes.

## Tests

None automated.

## Edge cases and limits

- Several logs and tasks are invisible without elevation, so run Check-Quiet-Status and
  Watch-For-Reverts as admin.
- The undervolt test works on any x86 CPU.

## Related

- [quiet-session.md](quiet-session.md), [stutter-finder.md](stutter-finder.md)
- Glossary: **READY**, **Revert**, **Focus stutter**
