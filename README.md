# QuietWindows

**Quiet Windows down so your games get the whole PC.**

A console runs one thing at a time. Your Windows PC does not - updates,
search, virus scans, and a dozen background apps all take little bites while
you play. One bite at the wrong moment is a stutter. QuietWindows puts those
interruptions on hold while you play, and hands everything back when you're
done.

---

## Start here

1. Double-click **`QuietWindows.bat`**
2. Press the big green button (**QUIET MY PC DOWN**)
3. Restart your PC when it says to

**Before each session:** press **Quiet Windows down**.
**After each session:** press **Wake Windows back up**.

No menu? Use **`Optimize-My-PC.bat`** for the same one-time setup.

Step-by-step walkthrough (written for normal people): **[HOW-TO.md](HOW-TO.md)**

---

## Safety (read this)

- Nothing runs until you press a button. Every change has an Undo.
- Your antivirus stays on. It just stops re-scanning your game folders.
- **You must press Wake Windows back up after playing.** Until you do,
  Windows Update is off (and fresh antivirus definitions ride the same
  services). Forgetful? Use `-Deadman` so the next restart puts everything
  back automatically - see HOW-TO.

---

## What it does

| What | Why it helps |
|---|---|
| Puts Windows Update, Search and app updates on hold while you play | Number one cause of a mid-game freeze |
| Tells your antivirus to skip your game folders | Stops re-scanning the same files thousands of times. Still guards everything else |
| Turns off USB power saving and the Xbox Game Bar | Two Windows habits that quietly cost frames |
| Steadies the system clock | Fixes "it stutters until I click on the game" |
| Moves graphics-card and USB interrupts off your game's cores | Hardware taps the CPU thousands of times a second - this moves the taps |
| Keeps your game on the fast half of an AMD X3D processor | Only some AMD chips. It detects yours and skips if not |

---

## Still stuttering?

Open **FIND A STUTTER** in the menu. It records what your PC does every
second while you play, then names what interrupted you - the actual program,
often the actual file.

Usually it isn't the game and it isn't your hard drive. On one measured
session the PC waited on disk 4,712 times; fourteen were the game. The rest
was Store updates, Edge, Search, and the touch keyboard.

Full ordered steps: **[HOW-TO.md](HOW-TO.md)** (section "It still stutters").

---

## Games

QuietWindows keeps a list of games it looks after. First run scans Steam,
Epic, Xbox, GOG, EA and Ubisoft. Missed one? Open **My Games** and point it
at the game's `.exe`.

That list drives antivirus exclusions and stutter hunting ("which program is
the game?").

---

## Extras

Fixes that only make sense for one game live under **Extras** (iRacing to
start with). Drop a folder into `extras\` to add another - see
[extras/README.txt](extras/README.txt).

---

## Requirements

- **Windows 10 or 11.** PowerShell is already built in.
- **Process Lasso** (free, bitsum.com) - *only* for AMD X3D chips. The menu
  tells you if you have one.
- **Windows Performance Toolkit** - optional, only for the deepest stutter
  hunting.

These scripts change Windows settings (power, registry, services, antivirus
exclusions). All reversible; nothing happens without your say-so. Review and
run at your own risk.

---

MIT licensed. Share it freely.

Built on the stutter-hunting work of the sim-racing community.
