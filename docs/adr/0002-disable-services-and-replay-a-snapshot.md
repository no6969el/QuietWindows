---
id: adr-0002
title: "ADR 0002: Disable services and restore from a snapshot"
kind: adr
summary: Start-Quiet disables (not just stops) the quiet list and records the original state first; Stop-Quiet replays that record.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Start-Quiet.ps1, scripts/Stop-Quiet.ps1, scripts/README.txt]
adr_status: accepted
date: 2026-08-01
---

This ADR records why a quiet session disables services and needs an explicit wake.
Decided in the tuning kit (v3.0.0); dated here to the first QuietWindows release.

## Context

Stopping a service never held. A stopped service keeps its startup setting, so the
first thing that asks for it starts it again, and Windows Update Medic repairs a
tampered update system on a roughly ten-minute cycle. Players got a stutter the moment
it came back mid-session.

## Decision

- Set each service to Disabled, clear its recovery actions, then stop it. Take ownership
  of the Medic key when needed.
- Before changing anything, write the original state to `state.json`. A second run keeps
  that snapshot.
- Stop-Quiet replays the snapshot exactly, so things the player had already turned off
  stay off. Without a snapshot it falls back to Windows defaults and warns.

## Consequences

- Quiet holds for the whole session.
- Nothing fixes itself on restart: until Stop-Quiet runs the PC has no Windows Update and
  no fresh Defender definitions. Every doc repeats the warning, and `-Deadman` exists for
  people who forget.
- `-Force` is dangerous: it discards the originals.

## Considered options

- Windows Update's own pause: undone by Medic.
- Stop only: did not hold (see Context).
