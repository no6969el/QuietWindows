---
id: adr-0004
title: "ADR 0004: Detect the CPU most reliable first, and never guess"
kind: adr
summary: CPU-Profile uses the name catalog, then cache layout, then cache size, then core count, validates against Windows, and skips X3D-only steps when unsure.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/CPU-Profile.ps1, scripts/Set-GPU-IRQ-Affinity.ps1, scripts/Set-NIC-USB-IRQ-Affinity.ps1]
adr_status: accepted
date: 2026-08-01
---

This ADR records how the processor is identified. Dated to the first QuietWindows
release; the exact date it was decided is not recorded.

## Context

Interrupt steering and Process Lasso advice depend on where the V-Cache sits and how many
cores exist. A wrong guess points interrupts at a busy core or at a core that does not
exist.

## Decision

- One module, `CPU-Profile.ps1`, answers every CPU question.
- Order: catalog name match, L3 cache topology, total L3 size, core count.
- Always validate against the processors Windows reports; reject any target outside it.
- When topology is unknown or the chip is not X3D, skip steering and pinning rather than
  guess. The rest of the kit still runs.
- A forced test profile makes registry writers dry-run.

## Consequences

- Safe on any CPU; X3D owners get the extra steps.
- New X3D chips are often handled by the cache-layout layer before the catalog is updated.
- The catalog must be extended by hand for each new chip.
