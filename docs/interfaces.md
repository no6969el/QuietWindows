---
id: interfaces
title: Interfaces
kind: interfaces
summary: Every script's switches, the library functions other scripts call, the environment variables, and the files it writes for people.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/, extras/, QuietWindows-Menu.ps1, Optimize-My-PC.ps1]
---

This doc lists what QuietWindows exposes: script command lines, library functions and
the files people open.

## Start-Quiet.ps1

Inputs: `-Deadman`, `-Verify`, `-VerifyDelay <s>` (180), `-KeepSearch`,
`-KeepTouchKeyboard`, `-KeepStore`, `-SkipDefender`, `-CloseApps`, `-NoUnlock`,
`-NoSystem` (do not retry refused tasks as SYSTEM; a player switch, in HOW-TO.md), `-Force`.
Outputs: `state.json`, log lines, console report. Self-elevates.
Errors: a missing `Kit-Common.ps1` stops the run; unstoppable services are reported.
Called by: the menu (`BtnPreGame`), people by hand.

## Stop-Quiet.ps1

Inputs: `-Verify`, `-VerifyDelay <s>` (30). Outputs: restored settings, the snapshot
deleted. Self-elevates. Called by: the menu (`BtnPostGame`), the deadman task, people.

## Record-Session.ps1

Inputs: `-NoHardFaultTrace`. Outputs: Desktop CSVs. Stops on Ctrl+C.

## Watch-For-Reverts.ps1

Inputs: `-Hours <n>`, `-Export`. Output: console timeline, optional Desktop `.txt`.

## Test-UndervoltStability.ps1

Inputs: `-Preset`, `-Mode`, `-Cores`, `-SecondsPerCore`, `-Cycles`, `-ThreadsPerCore`,
`-BurstMs`, `-IdleMs`, `-Shuffle`, `-StopOnError`, `-NoClocks`, `-LogPath`, `-ReportPath`,
`-NoAvx512`. `-WorkerMode` and the parameters after it are internal (used for its child
processes).

## Other scripts

Every other script in `scripts/` and `extras/` takes no switches. Fix scripts exit 0 on
success or a legitimate skip and non-zero on failure.

## Libraries (dot-sourced)

- `Kit-Common.ps1`: `$KitVersion`, `$ServicesToQuiet`, `$TasksToDisable`,
  `$ServiceDefaults`, `$StateDir`, `$StateFile`, `$LogFile`, `$SvcRoot`; `Write-Log`,
  `Initialize-Privileges`, `Test-IsAdmin`, `Request-AdminRelaunch`, `Invoke-SystemHop`,
  `Find-Xperf`, `Test-HardFaultTraceRunning`, `Disable-ConsoleQuickEdit`,
  `Restore-ConsoleQuickEdit`, `Invoke-HardFaultAnalysis`, `Invoke-HardFaultRecovery`,
  `Get-QuietTaskPathPattern`.
- `CPU-Profile.ps1`: `Get-CpuProfile [-NoCache] [-Assume]`, `Get-CpuClasses`,
  `Get-CpuCatalog`, `Get-CpuPinningAdvice`, `Get-CpuTopologySummary`,
  `Write-CpuWarnings`, `Import-CpuConfig`, `Export-CpuConfig`, `Clear-CpuConfig`,
  `Get-CpuConfigPath`, `Resolve-CpuTarget`.
- `Game-Library.ps1`: `Get-GameList`, `Get-GameExeNames`, `Get-GameFolders`,
  `Get-RunningGame`, `Test-IsGameProcess`, `Get-GameProcessRegex`, `Find-InstalledGames`,
  `Add-GameEntry`, `Remove-GameEntry`, `Save-GameList`, `Reset-GameList`,
  `Test-DefenderExclusion`, `Write-GameListSummary`.

## Extras contract

A folder under `extras/` named after the game; each `.ps1` is a button; `Admin-` prefix
means it runs elevated; optional `README.txt` is the description.

## Environment variables

`QW_FORCE_PROFILE`, `QW_FREQ_FIRST_CORE`, `QW_SIMULATED`. See [operations.md](operations.md).

## Files people open

- `QuietWindows-Session-<stamp>.csv`: one row per second (header defined in
  `Record-Session.ps1`); with disk detail adds `game_hardfaults_s`, `top_fault_proc`,
  `top_fault_file`.
- `QuietWindows-HardFaults-<stamp>.csv`: every hard-fault event.
- `stutter-events.txt`: incidents and what was happening around each.
