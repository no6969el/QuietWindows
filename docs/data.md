---
id: data
title: Data and state
kind: data
summary: The small JSON and text files QuietWindows keeps, where they live, and which Windows settings it changes.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Kit-Common.ps1, scripts/Start-Quiet.ps1, scripts/Stop-Quiet.ps1, scripts/CPU-Profile.ps1, scripts/Game-Library.ps1]
---

This doc covers what QuietWindows stores and the Windows state it changes.

## Entities

| File | Written by | Key fields |
| --- | --- | --- |
| `C:\ProgramData\QuietWindows\state.json` | Start-Quiet | `SchemaVersion` (1), `Tool`, `CreatedUtc`, `Machine`, `Services` (name and original start type), `Tasks` (path, name, original state), `DefenderWasOn`, `KeptSearch`, `SkippedDefender`, `Deadman`, `UnlockedKeys` |
| `C:\ProgramData\QuietWindows\storepolicy.json` | Start-Quiet | `KeyExisted`, `Value` (original `AutoDownload`) |
| `C:\ProgramData\QuietWindows\<service>.sddl` | Start-Quiet (Medic unlock) | line 1 original owner, line 2 original SDDL |
| `C:\ProgramData\QuietWindows\QuietWindows.log` | every Kit-Common user | timestamped lines, phase timings |
| `%APPDATA%\QuietWindows\config.json` | CPU-Profile | the CPU profile, `SchemaVersion` 3 |
| `%APPDATA%\QuietWindows\games.json` | Game-Library | `SchemaVersion` 1, `Games[]` with `Name`, `Exes`, `Folders`, `Source` |

## Relationships

`state.json`, `storepolicy.json` and the `.sddl` files together describe one quiet
session and are consumed by Stop-Quiet. `games.json` feeds Defender exclusions and the
recorder. `config.json` feeds every CPU-aware script.

## Storage

Plain files, UTF-8. Machine-wide state under ProgramData (needs admin); per-user
settings under AppData.

Windows state changed (all reversible):
- Service `Start` values and recovery actions, scheduled task state, Defender real-time,
  `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore\AutoDownload` (per session).
- Defender exclusion paths, USB selective suspend, Game Mode/Bar/DVR values,
  `GlobalTimerResolutionRequests`, interrupt-affinity policy under device keys, event
  log enablement, the `QuietWindows-Deadman` task (lasting until undone).

## Migrations

None. Each file carries a schema version. An older `config.json` or `games.json` is
discarded and rebuilt. Bump `$script:CpuSchemaVersion` or `$script:GameSchemaVersion`
when the shape changes. The snapshot format has been unchanged since 1.0.3.
