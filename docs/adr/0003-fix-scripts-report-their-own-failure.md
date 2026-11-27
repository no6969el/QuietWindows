---
id: adr-0003
title: "ADR 0003: Fix scripts report their own failure"
kind: adr
summary: Every fix exits non-zero on a real failure and every elevation uses -ErrorAction Stop, so callers can tell success from failure.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [Optimize-My-PC.ps1, QuietWindows-Menu.ps1, scripts/Add-Defender-Exclusions.ps1, scripts/Apply-Extra-Tweaks.ps1, scripts/Enable-DiagnosticLogs.ps1, scripts/Enable-SmoothTimer.ps1, scripts/Set-GPU-IRQ-Affinity.ps1, scripts/Start-Quiet.ps1]
adr_status: accepted
date: 2026-08-21
---

This ADR records the error-reporting rules from release 1.0.3.

## Context

The kit could not hear its own failures. A declined UAC prompt is a non-terminating
error, so `try/catch` missed it and the runner showed ALL DONE. Fix scripts caught their
own errors and returned normally. `wevtutil` never throws. `Stop-Service -Force` has no
timeout and could hang a half-quieted session.

## Decision

- `Start-Process -Verb RunAs` always uses `-ErrorAction Stop`.
- Fix scripts exit non-zero on a genuine failure; a legitimate skip (no games yet) exits 0.
- Native tools have their exit codes checked.
- Services stop through `Stop-ServiceBounded` (20 seconds), and a service that won't stop
  is reported.
- `Optimize-My-PC.ps1` waits for its elevated child and counts failed steps.

## Consequences

- The one-shot setup reports an honest failure count.
- The menu's green button still does not wait (waiting would freeze the WPF window), so
  it reports launch failures only.
- `$ErrorActionPreference = 'SilentlyContinue'` stays at file scope in the player-facing
  front ends to keep noise out; per-call `-ErrorAction Stop` overrides it where it matters.
