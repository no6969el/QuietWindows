---
id: cpu-detection
title: CPU detection
kind: feature
summary: Works out which AMD X3D chip (if any) the PC has, where its big cache is, and which cores are safe for interrupts; never guesses.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/CPU-Profile.ps1, QuietWindows-Menu.ps1, Optimize-My-PC.ps1, tests/test-profiles.ps1, tests/test-integration.ps1, tests/bench-startup.ps1]
---

This doc covers `scripts/CPU-Profile.ps1`, the one place that knows about the processor.

## What the user sees

- The menu header names the processor and graphics card on launch.
- **Your CPU** lets them pick a chip class by hand if detection is wrong.
- On chips that are not X3D, the X3D-only steps (Process Lasso, interrupt steering)
  are skipped, not failed.

## How it works

1. `Get-CpuProfile` returns the saved `config.json` profile if it is still valid (same
   schema version, same logical core count, a target core that exists).
2. Otherwise it detects, most reliable first:
   1. the CPU name against `$script:CpuCatalog` (every X3D AMD has shipped, 17 entries);
   2. the real L3 cache layout, which finds CCD boundaries even on chips newer than the
      catalog;
   3. total L3 size (has it got the extra cache?);
   4. core count, as a last resort.
3. The answer is checked against the processors Windows reports, so a target core can
   never be out of range.
4. The profile is saved with `Export-CpuConfig`.
5. Helpers turn it into advice: `Get-CpuPinningAdvice` (Process Lasso steps),
   `Get-CpuTopologySummary`, `Write-CpuWarnings`. `Resolve-CpuTarget` gives fix scripts
   their target core.

The profile carries, among others: `Model`, `Topology` (single or dual CCD),
`HasBigCache`, `VCacheScope`, `VCacheRange`, `BackgroundRange`, `FreqFirst` (the GPU
interrupt target), `IrqTargets` (NIC and USB targets), `Known`, `TopologyKnown`,
`DetectSource`, `Simulated`.

## Code

- `scripts/CPU-Profile.ps1`
- Callers: `QuietWindows-Menu.ps1`, `Optimize-My-PC.ps1`, `Ready-Check.ps1`,
  `Set-GPU-IRQ-Affinity.ps1`, `Set-NIC-USB-IRQ-Affinity.ps1`, `Record-Session.ps1`

## Settings and flags

| Variable | Effect |
| --- | --- |
| `QW_FORCE_PROFILE` | Pretend to be a catalog chip (for example `5600X3D`). Registry-writing fixes dry-run. |
| `QW_FREQ_FIRST_CORE` | Target core handed from the menu to fix scripts; rejected if not a real core. |
| `QW_SIMULATED` | `1` when that target came from a forced profile, so the fix dry-runs. |

The manual picker (`Get-CpuClasses`) offers six classes: 6-core and 8-core single-CCD,
12-core and 16-core dual-CCD, 16-core with cache on both CCDs (9950X3D2), and "something
else". A picked class is not a simulation; fixes still write.

## Data

Reads WMI/CIM and the cache topology. Writes `%APPDATA%\QuietWindows\config.json`
(`$script:CpuSchemaVersion = 3`; older files are discarded and re-detected).

## Tests

- `tests/test-profiles.ps1`: prints the resolved profile for every catalog chip, plus
  advice, warnings, the non-X3D fallback, a bad force value and an impossible override.
- `tests/test-integration.ps1`: for every catalog chip, GPU and NIC targets are inside
  the core range and the affinity mask is valid.
- `tests/bench-startup.ps1`: timing of config reads at startup.

## Edge cases and limits

- AMD X3D only for steering and pinning; every other CPU gets the general fixes.
- Mobile HX3D parts print a warning (see `Write-CpuWarnings`).
- A CPU swap invalidates the saved profile automatically.
- The GPU name prefers an NVIDIA adapter when several are present (display only).

## Related

- [ADR 0004](../adr/0004-detect-the-cpu-most-reliable-first-and-never-guess.md)
- [interrupt-steering.md](interrupt-steering.md)
- Glossary: **X3D**, **CCD**, **V-Cache**, **Profile**, **Forced profile**, **Dry run**
