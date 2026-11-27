---
id: interrupt-steering
title: Interrupt steering (GPU, NIC and USB)
kind: feature
summary: Moves graphics-card, network and USB interrupts off the game's cores using the Windows interrupt-affinity policy; reversible.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/Set-GPU-IRQ-Affinity.ps1, scripts/Undo-GPU-IRQ-Affinity.ps1, scripts/Set-NIC-USB-IRQ-Affinity.ps1, scripts/Undo-NIC-USB-IRQ-Affinity.ps1, scripts/CPU-Profile.ps1]
---

This doc covers the scripts that move device interrupts away from the cores a game uses.

## What the user sees

- GPU steering runs as part of the green button on X3D chips.
- **Advanced**: *Move network and USB interrupts off core 0* (not in the green button)
  and an Undo for each.
- A restart is needed for either to take effect. The scripts suggest LatencyMon to check.

## How it works

1. Resolve the target core with `Resolve-CpuTarget`. Abort, changing nothing, if the
   core is not usable or the topology is unknown.
2. GPU: find display adapters by PCI vendor ID (NVIDIA `VEN_10DE`, AMD `VEN_1002`,
   Intel `VEN_8086`) and write the interrupt-affinity policy (`DevicePolicy` and an
   8-byte `AssignmentSetOverride` mask) under each adapter's `Affinity Policy` key.
   Dual-CCD: first CPU of the second CCD. Single-CCD: half the thread count.
3. NIC and USB: same mechanism for physical network adapters and USB host controllers,
   onto `IrqTargets` (background cores, off CPU 0 and off the GPU target).
4. Undo removes `DevicePolicy`, `AssignmentSetOverride` and the empty key.

## Code

`scripts/Set-GPU-IRQ-Affinity.ps1`, `scripts/Undo-GPU-IRQ-Affinity.ps1`,
`scripts/Set-NIC-USB-IRQ-Affinity.ps1`, `scripts/Undo-NIC-USB-IRQ-Affinity.ps1`.

## Settings and flags

`QW_FREQ_FIRST_CORE`, `QW_SIMULATED`, `QW_FORCE_PROFILE` (dry run). See
[cpu-detection.md](cpu-detection.md).

## Data

Registry under each device's `Device Parameters\Interrupt Management\Affinity Policy`
in `HKLM:\SYSTEM\CurrentControlSet\Enum`.

## Tests

`tests/test-integration.ps1` checks the targets and masks for every catalog chip. The
registry writes are not tested automatically.

## Edge cases and limits

- A GPU with an unlisted vendor ID is not steered; the script asks the user to report
  the ID.
- Masks are group 0 only (cores below 64).
- With more than one dedicated GPU, all are steered.

## Related

- [one-time-setup.md](one-time-setup.md), [cpu-detection.md](cpu-detection.md)
- Glossary: **Interrupt steering**, **Target core**, **Dry run**
