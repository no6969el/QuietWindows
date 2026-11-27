---
id: quiet-session
title: Quiet session (Start-Quiet and Stop-Quiet)
kind: feature
summary: Puts Windows Update, Search, Store updates and background jobs on hold for a game, then puts everything back from a snapshot.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Start-Quiet.ps1, scripts/Stop-Quiet.ps1, scripts/Kit-Common.ps1, scripts/Check-Quiet-Status.ps1, scripts/Watch-For-Reverts.ps1]
---

This doc covers the per-session pair: **quiet** before a game and **wake** after it.

## What the user sees

- Menu, **Before & after playing**: **1) Quiet Windows down**, **2) Wake Windows back up**,
  **3) Am I game ready right now?**
- One UAC prompt, a console window that runs for a few seconds, and a closing banner
  that says to run Stop-Quiet afterwards.
- Until they wake Windows, the PC has no Windows Update and no fresh Defender
  definitions. This survives a restart unless `-Deadman` was used.

## How it works

Start-Quiet (`scripts/Start-Quiet.ps1`), numbered as in the script:

1. **Snapshot.** If `state.json` already exists, it is a **re-quiet**: the saved
   originals are kept and only re-applied. Otherwise it records each service's startup
   type, each task's state and whether Defender real-time was on, and writes
   `C:\ProgramData\QuietWindows\state.json` before touching anything.
2. **Scheduled tasks.** Disables every task in `$TasksToDisable`. Tasks the admin token
   cannot change are retried through the **SYSTEM hop** (a one-shot SYSTEM scheduled
   task), unless `-NoSystem` is given.
3. **Services.** For each service in `$ServicesToQuiet` (Update Medic first): takes
   ownership of the Medic registry key when needed (on by default, `-NoUnlock` skips it,
   original owner and SDDL saved to `<service>.sddl`), sets Start to Disabled, clears
   recovery actions, then stops it with `Stop-ServiceBounded` (20-second limit).
4. **Defender.** Turns real-time monitoring off for the session with
   `Set-MpPreference`, unless `-SkipDefender` or it was already off. Fails when Tamper
   Protection is on, and says so. This is intended (see
   [ADR 0006](../adr/0006-pause-defender-real-time-during-a-quiet-session.md)).
   4b. **Store auto-download.** Sets the `AutoDownload = 2` policy under
   `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`; the original goes to
   `storepolicy.json`. `-KeepStore` skips it.
   4c. **Noisy apps.** Reports chat, overlay and peripheral apps that are running.
   `-CloseApps` closes only the ones marked safe (chat clients, touch keyboard hosts);
   controller, wheel and monitoring software is never closed.
5. **Deadman** (`-Deadman`). Registers `QuietWindows-Deadman`, an at-startup SYSTEM task
   that runs Stop-Quiet.
6. **Verify** (`-Verify`). Waits `-VerifyDelay` seconds (default 180) and reports any
   service or task that came back.

Stop-Quiet (`scripts/Stop-Quiet.ps1`):

1. Reads the snapshot. With no snapshot it falls back to `$ServiceDefaults` and warns.
2. Restores service startup types, then registry ownership and permissions from the
   snapshot and any `.sddl` files.
3. Re-enables the tasks that were enabled before, restores Defender and the Store policy.
4. Deletes the deadman task and the snapshot. It keeps the snapshot if any key is still
   unrestored.
5. `-Verify` re-checks after `-VerifyDelay` seconds (default 30).

Every step is logged to `C:\ProgramData\QuietWindows\QuietWindows.log`, including
per-phase timings.

## Code

- `scripts/Start-Quiet.ps1`, `scripts/Stop-Quiet.ps1`
- `scripts/Kit-Common.ps1`: lists, paths, `Write-Log`, `Initialize-Privileges`,
  `Request-AdminRelaunch`, `Invoke-SystemHop`
- `scripts/Check-Quiet-Status.ps1`: read-only state report (button 3)
- `scripts/Watch-For-Reverts.ps1`: event-log timeline of what turned things back on
- Menu buttons `BtnPreGame`, `BtnPostGame`, `BtnCheckQuiet2` in `QuietWindows-Menu.ps1`

## Settings and flags

Start-Quiet: `-Deadman`, `-Verify`, `-VerifyDelay <s>`, `-KeepSearch`,
`-KeepTouchKeyboard`, `-KeepStore`, `-SkipDefender`, `-CloseApps`, `-NoUnlock`,
`-NoSystem`, `-Force` (discards an existing snapshot; originals are lost).
Stop-Quiet: `-Verify`, `-VerifyDelay <s>`. Full list in [interfaces.md](../interfaces.md).

## Data

Writes `state.json`, `storepolicy.json`, `<service>.sddl` and the log under
`C:\ProgramData\QuietWindows\`. Changes service Start values, task state, Defender
real-time, the Store policy and, with `-Deadman`, one scheduled task. See
[data.md](../data.md).

## Tests

- `tests/test-kitcommon.ps1`: one list only, every quieted service has a restore
  default, no duplicates, consumers load Kit-Common, Start/Stop keep no private helpers.
- `tests/test-quiet.ps1`: SYSTEM-hop script generation (quoting) and a snapshot
  round-trip.
- Start and Stop themselves are tested by hand on a real PC before release (CHANGELOG 1.0.4).

## Edge cases and limits

- Running Start-Quiet twice keeps the first snapshot, so originals are never lost.
- `-Force` throws the snapshot away; Stop-Quiet then uses Windows defaults.
- Defender real-time cannot be paused while Tamper Protection is on.
- `TabletInputService` does not exist on Windows 11 24H2 and later; it is skipped.
- Update Medic can re-enable services about every ten minutes; that is why services
  are disabled rather than stopped. See [ADR 0002](../adr/0002-disable-services-and-replay-a-snapshot.md).

## Related

- [ADR 0001](../adr/0001-one-shared-quiet-list.md), [ADR 0002](../adr/0002-disable-services-and-replay-a-snapshot.md), [ADR 0006](../adr/0006-pause-defender-real-time-during-a-quiet-session.md)
- Glossary: **Quiet**, **Wake**, **Snapshot**, **Re-quiet**, **Deadman**, **Medic unlock**, **SYSTEM hop**
- [health-checks.md](health-checks.md)
