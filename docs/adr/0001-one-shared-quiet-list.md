---
id: adr-0001
title: "ADR 0001: One shared quiet list in Kit-Common"
kind: adr
summary: The services and tasks to quiet are declared once, in Kit-Common.ps1, and every script reads that list.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Kit-Common.ps1, tests/test-kitcommon.ps1]
adr_status: accepted
date: 2026-08-21
---

This ADR records why the quiet list lives in one file. Decided in the tuning-kit v3.3.0
line and carried into QuietWindows; dated here to the first QuietWindows release that
documents it (1.0.3).

## Context

The service list used to live in four scripts and the task list in four more, each with
a "must mirror Start-Quiet" comment. They drifted: in v3.2.5 Start-Quiet gained services
the status screen did not know about, so it reported "game ready" while they were still
running.

## Decision

Declare `$ServicesToQuiet`, `$TasksToDisable` and `$ServiceDefaults` only in
`scripts/Kit-Common.ps1`. Start-Quiet, Stop-Quiet, Check-Quiet-Status and
Watch-For-Reverts dot-source it.

## Consequences

- Editing the list updates every script at once.
- `tests/test-kitcommon.ps1` fails if another script declares its own copy, or if a
  quieted service has no restore default.
- Kit-Common became a dependency of every session script; if it is missing they stop.
