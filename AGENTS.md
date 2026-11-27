# AGENTS.md

QuietWindows: Windows PowerShell scripts and a WPF menu that put background Windows work
on hold while you game, then restore it. Start at [docs/overview.md](docs/overview.md).

## Commands

- Install: none. Keep `scripts/`, `ui/` and `extras/` next to the `.bat` files.
- Run: `QuietWindows.bat` (menu) or `Optimize-My-PC.bat` (no menu), on Windows.
- Test: `pwsh -File tests/<name>.ps1` for each `tests/test-*.ps1`; each exits 1 on failure.
- Lint: none configured.
- Build: none.

## Code style and conventions

- Target Windows PowerShell 5.1; tests run under PowerShell 7, on Windows only.
- Shared lists and helpers live in `scripts/Kit-Common.ps1`; CPU answers in
  `scripts/CPU-Profile.ps1`; games in `scripts/Game-Library.ps1`. Dot-source them; never
  copy their lists or helpers into another script.
- Every lasting change has an Undo script or is restored by Stop-Quiet.
- Fix scripts exit non-zero on real failure. Elevation calls use `-ErrorAction Stop`.
- Format numbers with the invariant culture in anything written to CSV.
- User-facing text is plain language for non-technical players.
- Version: `$KitVersion` in Kit-Common is authoritative; banners are stamped at release.

## Never touch

- Real Windows settings on your own machine while developing: use
  `QW_FORCE_PROFILE` to dry-run registry writers.
- Do not run Start-Quiet, Stop-Quiet or any fix on a machine you do not own.
- No secrets in this repo; none are needed.
- `LICENSE`.

## Docs

Read docs/index.json first, then the doc for the area you're changing. Use the terms in
docs/GLOSSARY.md. Update the affected docs in the same change as the code, and record
non-obvious choices as an ADR.

Player-facing docs (README.md, HOW-TO.md, START-HERE.txt, scripts/README.txt,
extras/README.txt) ship with the scripts; keep them in step with behaviour too.
