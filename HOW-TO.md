# How to use QuietWindows

No jargon. If you can double-click a file, you can do this.

QuietWindows tells Windows to hold off (updates, search, background noise)
while you play. When you're done, you hand everything back.

For the short version of what it does: see [README.md](README.md).

---

## Step 1 - Open it

Double-click **`QuietWindows.bat`**.

A dark window opens. At the top it already knows your processor and graphics
card - you don't need to do anything with that.

> **If Windows says "this file might be harmful"** - click *More info*, then
> *Run anyway*. That's Windows being cautious about downloads.

---

## Step 2 - Press the green button

Press **1) QUIET MY PC DOWN (start here)**.

### Orange part (only some PCs)

Shows up only on certain AMD "X3D" processors. If you see it, follow the
on-screen clicks in Process Lasso. **If there's no orange part, skip it.**
You can also skip Process Lasso for now - everything else still works.

### Green button on that page

Press **Do the rest for me now**. Say **Yes** when Windows asks permission.
A black window runs the fixes (~30 seconds) and closes itself.

---

## Step 3 - Restart

Restart normally. **Setup is done.** You never repeat steps 1-3.

---

## Step 4 - Every time you play

Open `QuietWindows.bat` -> **2) BEFORE & AFTER PLAYING**.

| When | Button |
|---|---|
| Before you play | **1) Quiet Windows down** |
| After you play | **2) Wake Windows back up** |
| Not sure which state you're in? | **3) Am I game ready right now?** |

### Why button 2 matters

> Button 1 doesn't just pause Windows Update - it switches it off properly.
> Windows has a repair service that turns Update back on about every ten
> minutes if you only pause it. So while you're quieted, your PC genuinely
> has no Windows Update and no fresh antivirus definitions.
>
> An evening is fine. A month is not. **Press button 2 when you're done.**

### Worried you'll forget? (`-Deadman`)

There's a switch called `-Deadman` that puts everything back automatically
at your next restart. Most people never need it - just use button 2.

To use it by hand (PowerShell in the `scripts` folder):

```
.\Start-Quiet.ps1 -Deadman
```

Other optional switches (`-KeepSearch`, `-SkipDefender`, `-CloseApps`,
`-Verify`) are listed at the bottom of this file.

---

## It still stutters

Press **3) FIND A STUTTER**. Do these **in order**.

1. **Turn on the background-task log** (section 2 -> Run). Say Yes to
   Windows. Do this once, *before* you record, or step 3 has nothing to read.

2. **Record a session** (section 1 -> Run). Play until you feel a stutter,
   then press **Ctrl+C** in the black window. A spreadsheet lands on your
   Desktop.

   > Don't click inside the black window while it records - clicking pauses
   > it and fakes a gap that looks like a stutter.

3. **Ask what happened** (section 3 -> Run). It writes **`stutter-events.txt`**
   to your Desktop with the program (and often the file) that interrupted you.

Optional: "Run with disk detail" needs permission and the free Windows
Performance Toolkit - without those it behaves like the plain Run.

---

## The other buttons (when you need them)

**My Games** - the list QuietWindows protects. Add a missing `.exe` with
*Add a game*. After adding, run *Stop the virus scanner re-scanning your
games* again from Advanced. *Look again* rebuilds from store scanners and
clears hand-added games.

**Advanced** - every fix alone, with Undo. You already have these if you
pressed the green button. Worth knowing:

- *Move network and USB interrupts off core 0* - not in the green button;
  try it if you have lots of USB devices.
- *Test whether your CPU is stable* - only if you undervolted/overclocked.
- *Repair Windows performance counters* - if the recorder is empty.

**Extras** - one-game-only fixes. Ignore games you don't play.

**Your CPU** - only if detection got it wrong (rare).

---

## Optional switches (PowerShell, not the menu)

Most people never need these. Run from the `scripts` folder:

| Switch | What it does |
|---|---|
| `-Deadman` | Auto-restore at next restart if you forget button 2 |
| `-KeepSearch` | Leave Windows Search alone |
| `-SkipDefender` | Leave antivirus completely untouched |
| `-CloseApps` | Also close chat apps like Discord / Telegram |
| `-Verify` | Wait a few minutes afterwards and report anything that crept back |
| `-NoUnlock` | Don't take ownership of the Windows Update Medic key |
| `-KeepTouchKeyboard` | Leave the touch keyboard service alone (VR) |
| `-KeepStore` | Leave Store auto-download policy alone |
| `-NoSystem` | Don't retry as SYSTEM when Windows refuses to switch off a task; those tasks stay on |

```
.\Start-Quiet.ps1 -Deadman
```

---

## When something goes wrong

| Problem | Fix |
|---|---|
| Forgot to wake Windows up | Before & after -> button 2 |
| "File is missing" | Unzip again; keep `scripts\` next to the menu |
| Nothing happens on a button | You said No to the permission box, or it's behind another window |
| "Some steps reported a problem" | Each fix is independent - scroll up for the red lines, or run one at a time from Advanced |
| Empty recording columns | Advanced -> *Repair Windows performance counters*, then restart |
| Undo everything | Advanced -> every **UNDO** button, then Wake Windows back up, then restart |

---

## One sentence

Press the green button once, restart, quiet down before you play, wake up
after. Everything else is for the day something goes wrong.
