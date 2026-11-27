---
id: known-issues
title: Known issues and open questions
kind: known-issues
summary: Doc and code mismatches, limits, small debts, and the questions the code could not answer.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [README.md, CLAUDE.md, CHANGELOG.md, scripts/Start-Quiet.ps1, scripts/Game-Library.ps1, tests/]
---

This doc lists what is known to be wrong, limited or undecided.

## Issues

| Issue | Kind | Severity | Where |
| --- | --- | --- | --- |
| CHANGELOG.md 1.0.3 section and its lineage note show garbled dashes (`â€”`), UTF-8 read as Windows-1252 | debt | low | `CHANGELOG.md` |
| `-NoSystem` switch is not in HOW-TO.md or scripts/README.txt | debt (docs) | low | `scripts/Start-Quiet.ps1` |
| README.md lists six stores; the scan also covers Battle.net and Riot | debt (docs) | low | `README.md`, `scripts/Game-Library.ps1` |
| Banners differ: Game-Library says v1.0.0, Record-Session says v3, Test-UndervoltStability says v2, Kit-Common says 1.0.4 | debt | low | script headers |
| No automated test for Start-Quiet, Stop-Quiet or any registry fix; they are tested by hand | limit | medium | `tests/` |
| No test runner or CI; tests are run one by one | limit | low | `tests/` |
| Three tests set `APPDATA` to `/tmp/appdata`, a Linux-style path; on Windows it lands in `\tmp\appdata` on the current drive | debt | low | `tests/test-integration.ps1`, `tests/test-profiles.ps1`, `tests/bench-startup.ps1` |
| Defender real-time cannot be paused while Tamper Protection is on | limit | low | `scripts/Start-Quiet.ps1` |
| Interrupt masks cover cores 0 to 63 only (processor group 0) | limit | low | `scripts/Set-*-IRQ-Affinity.ps1` |
| The menu's green button does not wait for its child, so it cannot report per-step failures | limit | low | `QuietWindows-Menu.ps1` |

## TODO and FIXME comments

None found.

## Open questions

Answer any of these and the next run turns the answer into docs.

1. Where does the v4.0.0 spec live, and should the docs point to it? Owner.
2. Is the iRacing X3D Tuning Kit retired in favour of QuietWindows? Owner.
3. Is `-NoSystem` meant for players, or a developer switch only? Owner.
