---
id: glossary
title: Glossary
kind: glossary
summary: The words QuietWindows uses for its own ideas, so code, docs and conversations mean the same thing.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [scripts/, README.md, HOW-TO.md, scripts/README.txt]
---

This glossary defines terms specific to QuietWindows. General Windows and programming
terms are left out unless the project uses them in a particular way.

**CCD**
One chiplet of CPU cores on an AMD processor. Dual-CCD X3D chips usually have **V-Cache**
on only one of them, which is why **Process Lasso** pinning matters there.

**Deadman**
The `-Deadman` switch on Start-Quiet: an at-startup SYSTEM task that runs Stop-Quiet at
the next restart, in case the player forgets to **Wake**.

**Defender exclusion**
A folder Windows Defender skips when scanning. QuietWindows adds one per folder on the
**Games list**. Unlike the session pause of real-time scanning, exclusions last until
removed.

**Disk detail**
A recorder run with admin rights and xperf present, which attributes every **Hard fault**
to a process and a file.
_Avoid:_ hard-fault trace (code name for the same thing)

**Dry run**
What a registry-writing fix does under a **Forced profile**: prints what it would change
and changes nothing.

**Extras**
Per-game folders under `extras/`; each script in one becomes a button on the Extras page.

**Fix**
One script that makes one lasting change and has a matching Undo (for example
Set-GPU-IRQ-Affinity and Undo-GPU-IRQ-Affinity).

**Focus stutter**
Hitching that stops when you click the game window, caused by Windows 11 honouring a
high-resolution timer only for the foreground window. Fixed by Enable-SmoothTimer.

**Forced profile**
A pretend CPU set with `QW_FORCE_PROFILE`, for testing on hardware you don't own. Makes
fixes **Dry run**.

**Games list**
The one saved list of games on this PC (`games.json`), shown as My Games.

**Gap**
A missing second in a recording's timestamps; a candidate **Incident** when the
surrounding rows agree.

**Hard fault**
A page the PC had to read from disk. The `hardfaults_s` column counts the whole PC, not
the game; `game_hardfaults_s` counts the game.

**Incident**
A moment Find-Stutter-Cause reports: a **Gap** or a hard-fault burst.

**Interrupt steering**
Moving a device's interrupts to a chosen **Target core** with the Windows
interrupt-affinity policy.

**Kit**
The whole QuietWindows folder. Scripts say "the kit" for historical reasons (it was
rebased from the iRacing X3D Tuning Kit).
_Avoid:_ tuning kit (the iRacing X3D Tuning Kit, still a separate project of its own)

**Medic unlock**
Taking ownership of the Windows Update Medic service's registry key so its start type
can be set. On by default; `-NoUnlock` skips it. Ownership is handed back on **Wake**.

**One-time setup**
The lasting **Fixes** applied once by the green button or Optimize-My-PC, followed by a
restart.

**Process Lasso**
A free third-party tool (Bitsum) the player sets up by hand on X3D chips to keep the
game on the **V-Cache** cores.

**Profile**
What CPU-Profile.ps1 knows about the processor: model, topology, cache placement and
target cores. Saved as `config.json`.

**Quiet**
To put Windows Update, Search, Store updates and background jobs on hold for a session
(Start-Quiet). Services are disabled, not just stopped.
_Avoid:_ pause (Windows Update's own pause is weaker and is undone by Medic)

**Quiet list**
`$ServicesToQuiet` and `$TasksToDisable` in Kit-Common.ps1: everything **Quiet** touches.

**Re-quiet**
Running Start-Quiet while a **Snapshot** already exists: the originals are kept and the
quiet is re-applied.

**READY**
Ready-Check's verdict that every **One-time setup** fix is live.

**Revert**
Something Windows switched back on during a quiet session. Found by `-Verify` and
explained by Watch-For-Reverts.

**Snapshot**
`state.json`: the original state Start-Quiet records before changing anything, which
Stop-Quiet replays.

**SYSTEM hop**
Retrying a scheduled-task change through a one-shot task that runs as SYSTEM, for tasks
an admin token cannot change (`Invoke-SystemHop`).

**Target core**
The core a device's interrupts are moved to. `FreqFirst` for the GPU, `IrqTargets` for
network and USB.

**V-Cache**
AMD's stacked extra L3 cache on X3D chips. Games run best on the cores that have it.

**Wake**
To put everything back after a session by replaying the **Snapshot** (Stop-Quiet).
Required: quiet does not undo itself on restart.

**X3D**
AMD Ryzen processors with **V-Cache**. QuietWindows' pinning and steering apply only to
them.
