---
id: stutter-finder
title: Stutter finder (record, then find the cause)
kind: feature
summary: Records what the PC does every second while you play, then names the program and often the file behind each stall.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Record-Session.ps1, scripts/Find-Stutter-Cause.ps1, scripts/Enable-DiagnosticLogs.ps1, scripts/Repair-PerfCounters.ps1, scripts/Kit-Common.ps1, tests/test-locale.ps1]
---

This doc covers the **FIND A STUTTER** page: the task log, the session recorder and the
cause finder.

## What the user sees

In order:
1. **Turn on the background-task log** (once, needs permission).
2. **Record a session**: play until a stutter, press Ctrl+C. A CSV lands on the Desktop.
   **Run with disk detail** adds per-process, per-file hard-fault data when run elevated
   with the Windows Performance Toolkit installed.
3. **Ask what happened**: writes `stutter-events.txt` to the Desktop.

## How it works

1. `Enable-DiagnosticLogs.ps1` enables TaskScheduler/Operational and the
   Kernel-Processor-Power logs with `wevtutil`, checking its exit code.
2. `Record-Session.ps1` creates performance counters once and samples them every second:
   power plan, per-CCD load, CPU 0 and target-core interrupt and DPC time, GPU load,
   power, clocks, temperature and limiter (nvidia-smi, MSI Afterburner when running),
   the game's CPU use (from the games list), system hard faults, free RAM.
   It turns console QuickEdit off so a click cannot pause the loop and fake a gap.
3. When elevated and xperf is found, it also runs a kernel HARD_FAULTS+FILENAME trace and,
   on Ctrl+C, adds `game_hardfaults_s`, `top_fault_proc` and `top_fault_file` to the CSV
   and writes a second CSV with every fault event.
4. `Find-Stutter-Cause.ps1` reads the newest recording, treats timestamp gaps and
   hard-fault bursts as incidents, and lists the scheduled tasks, events and (with
   disk detail) the faulting process and file around each one.

## Code

- `scripts/Record-Session.ps1`, `scripts/Find-Stutter-Cause.ps1`
- `scripts/Enable-DiagnosticLogs.ps1`, `scripts/Repair-PerfCounters.ps1`
- `scripts/Kit-Common.ps1`: `Find-Xperf`, `Test-HardFaultTraceRunning`,
  `Invoke-HardFaultAnalysis`, `Invoke-HardFaultRecovery`, QuickEdit helpers
- Menu buttons `BtnEnableLogs`, `BtnRecord`, `BtnRecordHF`, `BtnScan`

## Settings and flags

`Record-Session.ps1 -NoHardFaultTrace`. Optional tools: Windows Performance Toolkit
(xperf), MSI Afterburner, nvidia-smi.

## Data

Writes to the Desktop: `QuietWindows-Session-<stamp>.csv`,
`QuietWindows-HardFaults-<stamp>.csv`, `stutter-events.txt`. A temporary `.etl` in
`%TEMP%`. Reads the games list and CPU profile. All numbers are written with the
invariant culture so the CSV is valid in every locale.

## Tests

`tests/test-locale.ps1`: every CSV row has exactly as many fields as the header in
every culture. It reads the header literal from `Record-Session.ps1`.

## Edge cases and limits

- `hardfaults_s` is the whole PC, not the game. On one measured session the game was 14
  of 4,712. Use `game_hardfaults_s`.
- A single skipped second is not always a stall; the surrounding rows must agree.
- Empty counter columns mean corrupt performance counters: run
  `Repair-PerfCounters.ps1` and restart.
- If the recorder is killed without cleanup, a kernel trace can stay running; clear it
  with `xperf -stop`.
- Find-Stutter-Cause needs the task log enabled before the recording.

## Related

- [health-checks.md](health-checks.md), [game-library.md](game-library.md)
- Glossary: **Hard fault**, **Disk detail**, **Incident**, **Gap**, **QuickEdit**
