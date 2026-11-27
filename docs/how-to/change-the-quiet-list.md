---
id: how-to-change-the-quiet-list
title: Add or remove a quieted service or task
kind: how-to
summary: Change what Start-Quiet turns off, in the one place that controls it.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Kit-Common.ps1, tests/test-kitcommon.ps1]
---

This recipe changes the quiet list safely.

1. Open `scripts/Kit-Common.ps1`.
2. For a service: add it to `$ServicesToQuiet` with a comment saying what it is and the
   evidence for adding it (a trace, a measured session). Keep `WaaSMedicSvc` first.
3. Add the same service to `$ServiceDefaults` with its Windows default start type
   (2 Automatic, 3 Manual). Stop-Quiet needs it when there is no snapshot.
4. For a task: add `@{ Path='\...\'; Name='...' }` to `$TasksToDisable`.
5. Do not copy the list anywhere else.
6. Run `pwsh -File tests/test-kitcommon.ps1`.
7. Test Start-Quiet, Check-Quiet-Status and Stop-Quiet on a real PC.
8. Note the change in `CHANGELOG.md` under Unreleased, and update
   `docs/features/quiet-session.md` if behaviour changed.
