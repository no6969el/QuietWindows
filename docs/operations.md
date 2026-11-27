---
id: operations
title: Operations
kind: operations
summary: What you need, how to run it, how to run the tests, how a release is made, and the settings it reads.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [QuietWindows.bat, Optimize-My-PC.bat, scripts/Kit-Common.ps1, scripts/CPU-Profile.ps1, tests/, CHANGELOG.md]
---

This doc covers running, testing, releasing and configuring QuietWindows.

## Prerequisites

- Windows 10 or 11 with Windows PowerShell 5.1 (built in). The menu needs WPF, which
  Windows has.
- Admin rights for any fix and for Start-Quiet and Stop-Quiet (each script asks).
- Tamper Protection off, only for Start-Quiet's Defender step.
- Optional: Process Lasso (X3D chips), Windows Performance Toolkit (xperf, for disk
  detail), MSI Afterburner and nvidia-smi (GPU sensors), LatencyMon (checking
  interrupt moves), PowerShell 7 (`pwsh`, for AVX-512 in the undervolt test).
- For the tests: PowerShell 7 (`pwsh`) on Windows. The tests are run on Windows only.
  `test-integration.ps1`, `test-profiles.ps1` and `bench-startup.ps1` set `APPDATA`
  to `/tmp/appdata`, which on Windows is `\tmp\appdata` on the current drive.

## Set up

Download or clone the folder and keep `scripts/`, `ui/` and `extras/` next to the two
`.bat` files. Nothing to install or build.

## Run

```
QuietWindows.bat
```

Or `Optimize-My-PC.bat` for setup without the menu. Any single script:

```
powershell -ExecutionPolicy Bypass -File scripts\Start-Quiet.ps1 -Deadman
```

## Test and lint

Run these on Windows, from the repo root. Each test is a standalone script that prints
`ok` and `FAIL` lines and exits 1 on any failure. There is no runner and no CI.

```
pwsh -File tests/test-kitcommon.ps1
pwsh -File tests/test-quiet.ps1
pwsh -File tests/test-xaml.ps1
pwsh -File tests/test-locale.ps1
pwsh -File tests/test-integration.ps1
pwsh -File tests/test-profiles.ps1
pwsh -File tests/bench-startup.ps1
```

`test-profiles.ps1` and `bench-startup.ps1` print tables for a person to read rather
than asserting. No linter is configured.

Start-Quiet and Stop-Quiet are tested by hand on a real PC before a release.

## Build

Nothing to build. Scripts run as they are.

## Deploy

Not deployed. Releases are published on GitHub (v1.0.0 to v1.0.4 so far). From
`CHANGELOG.md`:

1. Bump `$KitVersion` in `scripts/Kit-Common.ps1`; it is the authoritative version.
2. Stamp the banner at the top of each script to match.
3. Add the release to `CHANGELOG.md`.
4. Zip the player files by hand as `QuietWindows-vX.Y.Z.zip`. Leave out `docs/`,
   `tests/`, `AGENTS.md` and `CLAUDE.md`; players don't need them.
5. Publish the GitHub release with that zip attached.

There is no packaging script; the zip is made by hand.

## Configuration

| Variable | Purpose | Default | Required |
| --- | --- | --- | --- |
| `QW_FORCE_PROFILE` | Pretend to be a catalog chip, for example `5600X3D`; registry writers dry-run | unset | no |
| `QW_FREQ_FIRST_CORE` | Target core passed from the menu to fix scripts | set by the menu | no |
| `QW_SIMULATED` | `1` when the target came from a forced profile | set by the menu | no |

Script switches are listed in [interfaces.md](interfaces.md). Saved state is in
[data.md](data.md).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Forgot to wake Windows up | Before & after, button 2 (Stop-Quiet) |
| "File is missing" | Unzip again; keep `scripts\` and `ui\` next to the menu |
| Nothing happens on a button | UAC was declined, or the window is behind another |
| "Some steps reported a problem" | Scroll up for red lines, or run each fix from Advanced |
| Defender step says still ON | Turn Tamper Protection off, or use `-SkipDefender` |
| Empty recorder columns | Advanced, Repair Windows performance counters, then restart |
| A kernel trace left running | `xperf -stop` |
| Undo everything | Advanced, every UNDO, then Wake Windows back up, then restart |
