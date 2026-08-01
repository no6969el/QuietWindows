# How to use QuietWindows

No jargon. No assumptions. If you can double-click a file, you can do this.

---

## Before we start: what's actually going on

Your PC is doing a lot of things you never asked it to. Right now, while
you're reading this, Windows is probably checking for updates, indexing
files so search works, and letting some app you installed two years ago
check whether it needs updating.

None of that matters when you're browsing. It matters a lot when you're
playing, because your game needs the machine's full attention every
sixteenth of a second. When Windows grabs some of that attention at the
wrong moment, you get a stutter.

QuietWindows tells Windows to hold off while you play. That's all it is.

---

## Step 1 — Open it

Double-click **`QuietWindows.bat`** in this folder.

A dark window opens with some buttons in it. At the top it tells you what
processor and graphics card you have. It worked that out by itself — you
don't need to do anything with it.

> **If Windows says "this file might be harmful"** — that's Windows being
> cautious about anything downloaded from the internet. Click *More info*,
> then *Run anyway*.

---

## Step 2 — Press the green button

The big green button says **QUIET MY PC DOWN**. Press it.

The next page has two parts.

### The orange part at the top

This only shows up if you have a particular kind of AMD processor — one of
the "X3D" ones. If you see it, there are a couple of clicks to do by hand
in a free app called Process Lasso, and the page tells you exactly which
clicks.

**If you don't see an orange part, you don't have that kind of processor
and there's nothing to do here.** Skip straight to the green button.

If you do see it and you don't want to bother with Process Lasso right now,
that's fine too. Everything else still works. You can come back to it.

### The green button

**Do the rest for me now.** Press it.

Windows will pop up a blue box asking if you want to allow changes. **Say
Yes.** This is normal — anything that changes a Windows setting makes
Windows ask first. If you said No, nothing at all would happen.

A black window opens and works through the fixes one by one. It closes
itself when it's finished. Takes maybe half a minute.

---

## Step 3 — Restart your PC

Some of the fixes only take effect after a restart. Restart normally, the
usual way.

**You're done with setup.** You never have to do steps 1–3 again.

---

## Step 4 — What to do every time you play

Open `QuietWindows.bat` again and press **BEFORE & AFTER PLAYING**.

**Before you play**, press button 1: *Quiet Windows down*.

Windows asks permission again. Say Yes. A window shows you what it's
switching off, then finishes with **"Quiet. Game time."**

Now go play.

**When you've finished playing**, come back and press button 2: *Wake
Windows back up*.

### Why button 2 matters

Button 1 doesn't just pause Windows Update — it switches it off properly.
It has to, because Windows has a repair service whose entire job is to turn
Windows Update back on if it notices it's off, and it checks every ten
minutes. Just pausing it doesn't hold.

So while you're in the quiet state, your PC genuinely has no Windows Update
and no fresh antivirus definitions. For an evening, that's fine. For a
month, it's not.

**Press button 2 when you're done.** Button 3 tells you which state you're
in if you're not sure.

> **Worried you'll forget?** There's a setting called `-Deadman` that puts
> everything back automatically at your next restart. It's covered further
> down.

---

## "It still stutters"

Press **FIND A STUTTER** in the menu. Do these in order.

### First, turn on the log

Open section 2, *Turn on the background-task log*, and press Run. Say Yes to
Windows.

This tells Windows to write down every background job it starts. It's off
by default. You only ever need to do this once, but you need to do it
**before** you record, or step 3 has nothing to read.

### Then record a session

Open section 1 and press **Run**. A black window opens and starts writing a
line every second.

Go play. Play until you feel the stutter at least once.

Then come back to the black window and press **Ctrl+C** — hold Ctrl and
press C. That stops it and saves a spreadsheet to your Desktop.

> **Don't click inside the black window while it's recording.** Clicking
> pauses it, which puts a fake gap in the recording that looks exactly like
> a real stutter. The tool tries to prevent this, and warns you if it
> couldn't.

### Then ask it what happened

Open section 3 and press **Run**. It reads your most recent recording, finds
the moments your PC stalled, and writes a file called **`stutter-events.txt`**
to your Desktop.

Open that file. It reads like this:

```
--- 21:14:07   [GAP] ---
  top faulter : backgroundTaskHost.exe
  reading     : WinStore.App.dll
  your game    : 0   (whole PC that second: 812)
  -> your game did not wait on the disk at all here. This was backgroundTaskHost.exe.
```

Translated: at 7 seconds past 9:14pm, your PC stalled. The Microsoft Store
was loading a 16-megabyte file to update an app in the background. Your game
was doing nothing wrong at all.

That's the kind of answer you get. Not "your PC is slow" — the actual
program, at the actual moment.

---

## The other buttons

### My games

The list of games QuietWindows looks after. It found these by scanning
Steam, Epic, Xbox, GOG, EA and Ubisoft.

Two things use this list:

- Telling your antivirus which folders to skip
- Knowing which program on your PC is "the game" when it's hunting a stutter

**If your game isn't on the list**, press *Add a game* and find its `.exe`
file. Usually it's in the game's own folder, and it's the biggest file in
there.

After adding one, go to **Advanced** and run *Stop the virus scanner
re-scanning your games* again, so your new folder actually gets covered.

*Look again* rebuilds the whole list from scratch — which also wipes
anything you added by hand, so only use it if the list has gone wrong.

### Advanced

Every fix on its own, with an Undo for each. If you pressed the green button
in step 2 you already have all of these. This page is for changing your mind
about one of them.

Worth knowing about:

- **Move network and USB interrupts off core 0** — not included in the
  green button, because it helps some PCs and does nothing on others. Worth
  trying if you have a lot of USB devices plugged in.
- **Test whether your CPU is stable** — only relevant if you've undervolted
  or overclocked. If your PC crashes only in games, run this.
- **Repair Windows performance counters** — only if the recorder refuses to
  run or gives you empty columns.

### Extras

Fixes that only apply to one specific game. Ignore any game you don't play.

### Your CPU

QuietWindows worked out what processor you have on its own. This page is
only for when it got it wrong — which is rare. If your PC seems fine, don't
touch it.

---

## The switches (only if you want them)

These are for the *Quiet Windows down* step, and you'd only use them from a
PowerShell window rather than the menu. Most people never need any of this.

| Switch | What it does |
|---|---|
| `-Deadman` | Puts everything back automatically at your next restart, in case you forget |
| `-KeepSearch` | Leaves Windows Search alone, so Start-menu search keeps working |
| `-SkipDefender` | Leaves your antivirus completely untouched |
| `-CloseApps` | Also closes chat apps like Discord and Telegram |
| `-Verify` | Waits three minutes afterwards and reports anything that crept back |

To use one, open the `scripts` folder, hold Shift, right-click in the empty
space, choose *Open PowerShell window here*, and type:

```
.\Start-Quiet.ps1 -Deadman
```

---

## When something goes wrong

**"I forgot to wake Windows back up, and now Windows Update doesn't work."**
Open QuietWindows, press *Before & after playing*, press button 2. It fixes
itself. Nothing was lost.

**"A script says a file is missing."**
Unzip the QuietWindows folder again. The `scripts` folder has to sit right
next to `QuietWindows-Menu.ps1` — moving one file out on its own breaks it.

**"Nothing happens when I press a button."**
You probably said No to the Windows permission box, or it appeared behind
another window. Check your taskbar for a flashing blue shield.

**"The recording has empty columns."**
Go to Advanced and run *Repair Windows performance counters*, then restart.

**"I want to undo everything."**
Advanced page, then every button under the red **UNDO** heading, then
restart. Also press *Wake Windows back up*. Your PC is back to exactly how
it was.

---

## The one sentence version

Press the green button once, restart, then quiet it down before you play
and wake it up after. Everything else on the menu is there for the day
something goes wrong.
