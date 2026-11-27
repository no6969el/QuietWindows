---
id: adr-0006
title: "ADR 0006: Pause Defender real-time scanning during a quiet session"
kind: adr
summary: Start-Quiet pauses Defender real-time protection for the session and Stop-Quiet turns it back on; -SkipDefender leaves it alone.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Start-Quiet.ps1, scripts/Stop-Quiet.ps1, README.md]
adr_status: accepted
date: 2026-11-27
---

This ADR records that pausing Defender during a quiet session is intended. The code
already did this; the owner confirmed it on 2026-11-27 when README.md and the code
disagreed.

## Context

Defender scans files as a game reads them, and each scan is a small pause. Folder
exclusions (Add-Defender-Exclusions) cover the game's own folders but not everything
else that runs during a session. README.md said "Your antivirus stays on", while
Start-Quiet section 4 turns real-time monitoring off.

## Decision

- Start-Quiet pauses Defender real-time protection for the session, records whether it
  was on, and Stop-Quiet turns it back on only if it was on before.
- `-SkipDefender` leaves Defender completely alone.
- Player docs say plainly that live scanning is paused until Windows is woken up.

## Consequences

- Waking Windows matters for antivirus as well as Windows Update; `-Deadman` covers
  people who forget.
- Needs Tamper Protection off; with it on, the step reports that Defender is still on.
- README.md was corrected to match.
