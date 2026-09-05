# Changelog

All notable changes to QuietWindows are recorded here.

Versions follow `MAJOR.MINOR.PATCH`. The authoritative version is
`$KitVersion` in `scripts/Kit-Common.ps1`; the banner at the top of each
script is stamped to match at release time.

### A note on version lineage

QuietWindows is a **1.x** product. It was rebased from the *iRacing X3D
Tuning Kit*, which had its own **3.x** line, and several scripts still
carried inherited `v3.3.0` banners after the rebrand â€” even though the
published releases were `v1.0.0`, `v1.0.1`, and `v1.0.2`. Those stamps are
corrected in 1.0.3.

References to `v3.x` in the *body* of a script are deliberately left alone.
They are accurate history of the tuning kit â€” which services an `xperf`
session justified adding, what v3.2.5 missed â€” and renumbering them would
falsify the record. Only the version stamps were wrong, not the history.

---

## [Unreleased]

---

## [1.0.4] — 2026-09-04

Cleanup for clarity and maintainability. **Quiet lists and snapshot format
are unchanged.** Maintainer tested Start/Stop before release — drop-in
upgrade; wake Windows with Stop-Quiet when you finish, same as always.

### Shared helpers (`scripts/Kit-Common.ps1`)

Kit-Common is no longer data-only. It now holds the helpers Start and Stop
both need, so behaviour lives in one place:

- **`Write-Log`** — timestamped log line to the shared QuietWindows log,
  optional host echo
- **`Initialize-Privileges`** — enable take-ownership / restore privileges
- **`Test-IsAdmin`** — boolean elevated check (soft warnings)
- **`Request-AdminRelaunch`** — UAC-relaunch when not admin; no-op when
  already elevated (so the menu does not double-prompt)
- **`Invoke-SystemHop`** — shared schtasks SYSTEM/HIGHEST create-run-wait-
  delete pattern
- **Shared state paths** — `$StateDir`, `$StateFile`, `$LogFile`, `$SvcRoot`

### Scripts thinned to use them

- **Start-Quiet / Stop-Quiet** call the shared helpers instead of carrying
  duplicate copies. Medic dual-edition header confusion removed — one clear
  story for Medic unlock (on by default; `-NoUnlock` to skip).
- **Tweak / Undo scripts** use `Request-AdminRelaunch` instead of inline
  `IsInRole` + hard `exit 1`. Standalone/CLI runs get a UAC prompt;
  menu launches with `-Admin` stay single-prompt.
- **Watch-For-Reverts** uses `Test-IsAdmin` for its soft warning only
  (still runs without elevation).

### Menu / UI

- Deleted the duplicate `QuietWindows-Menu.ps1.txt` file.
- Menu layout extracted to **`ui/MainWindow.xaml`** so the dashboard markup
  is editable without digging through the PowerShell host script.

### Docs

Rewrote the path for new users and contributors:

- **START-HERE.txt**, **README.md**, **HOW-TO.md** — clearer first steps,
  safety called out early (always wake Windows after quiet)
- **extras/README.txt** and **scripts/README.txt** — aligned with the same
  story

### Tests

- **`tests/test-kitcommon.ps1`** — covers the new shared helpers
- **`tests/test-xaml.ps1`** — updated for the extracted MainWindow.xaml

### Notes

No change to which services/tasks get quieted, how snapshots are written,
or restore behaviour. If a quiet session is active when you upgrade,
restoring with the old build first is unnecessary but harmless.

---
## [1.0.3] â€” 2026-08-21

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
  job â€” not running as admin, Defender commands unavailable, no supported
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
  not check `schtasks` exit codes â€” unlike the deadman path, which already
  did â€” so a refused task engine burned the full 30-second poll before
  giving up. Exit codes are now checked and the run bails immediately with a
  message distinguishing a refused scheduler from a helper that never
  reported back. (`Start-Quiet.ps1`)

- **Inherited version stamps.** `$KitVersion` and five script banners read
  `v3.3.0`, carried over from the iRacing X3D Tuning Kit, while the product
  shipped as `v1.0.x`. All stamps now read `1.0.3`.

### Changed

- `HOW-TO.md`: troubleshooting entry added for the "some steps reported a
  problem" message, and the "nothing happens" entry now notes that a
  declined prompt is reported rather than passing silently.

### Notes for maintainers

- `Optimize-My-PC.ps1` keeps `$ErrorActionPreference = 'SilentlyContinue'`
  at file scope. It is cosmetic â€” it keeps probe noise out of a window aimed
  at people who do not want to read anything â€” and per-call
  `-ErrorAction Stop` overrides it where it matters. A comment above the
  line says not to lean on it. Removing it entirely would spray red text at
  exactly the wrong audience.
- The menu's one-click button stays fire-and-forget with no exit-code check.
  Waiting on it would block the WPF UI thread and freeze the window. It
  reports launch failures only; `Optimize-My-PC.bat` is the path that gives
  a full per-step summary.
- `$?` after `& script.ps1` detects `exit 1` but **not** a non-terminating
  error the script swallowed internally. That is why the fix scripts had to
  be given exit codes â€” no amount of wrapper-side checking substitutes for
  the callee reporting its own status.

### Upgrading

Drop-in replacement. If a quiet session is currently active, restoring with
the old version before upgrading is unnecessary but harmless.

---

## [1.0.2] and earlier

Not tracked in this file; see the GitHub releases page. Engineering history
for the 3.x tuning-kit lineage this was rebased from lives in the `WHAT
CHANGED` sections at the top of `scripts/Start-Quiet.ps1` and
`scripts/Kit-Common.ps1`.
