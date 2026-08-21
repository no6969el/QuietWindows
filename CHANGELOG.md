# Changelog

All notable changes to QuietWindows are recorded here.

Versions follow `MAJOR.MINOR.PATCH`. The authoritative version is
`$KitVersion` in `scripts/Kit-Common.ps1`; the banner at the top of each
script is stamped to match at release time.

---

## [3.3.1] — 2026-08-21

Error-reporting fixes. **No change to what gets disabled, restored, or
written.** No new settings, no snapshot format change, no migration.

The theme of this release: the kit could not hear its own failures. Three
separate layers were swallowing errors, and the one-click runner reported
success regardless.

### Fixed

- **A declined admin prompt reported success.** Declining UAC raises a
  *non-terminating* error, which `try/catch` ignores by default. Every
  elevation path relied on that catch, so pressing **No** still produced a
  green `ALL DONE` and the "you said No" message was unreachable. All three
  `Start-Process -Verb RunAs` calls now use `-ErrorAction Stop`.
  (`Optimize-My-PC.ps1`, `QuietWindows-Menu.ps1`)

- **Failing fix scripts looked like successes.** The individual scripts
  caught their own errors and returned normally when they could not do their
  job — not running as admin, Defender commands unavailable, no supported
  display adapter, registry write refused. Nothing upstream could detect
  this. They now exit non-zero on genuine failure.
  (`Add-Defender-Exclusions.ps1`, `Apply-Extra-Tweaks.ps1`,
  `Enable-DiagnosticLogs.ps1`, `Enable-SmoothTimer.ps1`,
  `Set-GPU-IRQ-Affinity.ps1`)

  Note: "no games added yet" is a legitimate skip, not a failure, and still
  exits 0.

- **The one-click runner now verifies its work.** `Optimize-My-PC.ps1` waits
  for the elevated child, reads its exit code, counts failed steps, and
  reports the count. Previously it tracked only whether a process launched.

- **`wevtutil` failures were invisible.** It is a native executable, so it
  never threw and the surrounding `catch` never fired. Its exit code is now
  checked. (`Enable-DiagnosticLogs.ps1`)

- **A wedged service could park the whole run.** `Stop-Service -Force` has
  no timeout, so one stuck service (WSearch mid-index being the usual one)
  could hang an elevated session with services already half-disabled.
  Replaced with `Stop-ServiceBounded`, a 20-second bounded stop that walks
  dependent services first to preserve the previous `-Force` behaviour. A
  service that will not stop is now reported rather than waited on forever.
  (`Start-Quiet.ps1`)

- **Scheduler failures were slow to surface.** The SYSTEM helper path did
  not check `schtasks` exit codes — unlike the deadman path, which already
  did — so a refused task engine burned the full 30-second poll before
  giving up. Exit codes are now checked and the run bails immediately with a
  message distinguishing a refused scheduler from a helper that never
  reported back. (`Start-Quiet.ps1`)

### Changed

- Version stamps bumped to 3.3.1 across script banners and `$KitVersion`.
- `HOW-TO.md`: troubleshooting entry added for the "some steps reported a
  problem" message, and the "nothing happens" entry now notes that a
  declined prompt is reported rather than passing silently.

### Notes for maintainers

- `Optimize-My-PC.ps1` keeps `$ErrorActionPreference = 'SilentlyContinue'`
  at file scope. It is cosmetic — it keeps probe noise out of a window aimed
  at people who do not want to read anything — and per-call
  `-ErrorAction Stop` overrides it where it matters. A comment above the
  line says not to lean on it. Removing it entirely would spray red text at
  exactly the wrong audience.
- The menu's one-click button stays fire-and-forget with no exit-code check.
  Waiting on it would block the WPF UI thread and freeze the window. It
  reports launch failures only; `Optimize-My-PC.bat` is the path that gives
  a full per-step summary.
- `$?` after `& script.ps1` detects `exit 1` but **not** a non-terminating
  error the script swallowed internally. That is why the fix scripts had to
  be given exit codes — no amount of wrapper-side checking substitutes for
  the callee reporting its own status.

### Upgrading

Drop-in replacement. If a quiet session is currently active, restoring with
the old version before upgrading is unnecessary but harmless.

---

## [3.3.0] and earlier

Not tracked in this file. See the commit history and the `WHAT CHANGED`
sections in the headers of `scripts/Start-Quiet.ps1` and
`scripts/Kit-Common.ps1`, which record the v3.3.0 service and task
additions derived from recorded `xperf` sessions.
