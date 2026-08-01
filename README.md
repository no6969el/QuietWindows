# QuietWindows

**Quiet Windows down so your games get the whole PC.**

A console runs one thing at a time. Your game gets the whole machine, every
second, and nothing interrupts it. That's why a console that's years old and
much weaker than your PC can still feel perfectly smooth.

A Windows PC doesn't work like that. While you're playing, Windows is also
checking for updates, indexing your files, scanning for viruses, updating
apps you forgot you installed, and letting a dozen background programs wake
up whenever they feel like it. Each of those is a tiny interruption. Most of
them you'd never notice. But one landing at the wrong moment is a stutter,
that half-second hitch where the picture freezes and you miss the shot, the
corner, the jump.

QuietWindows puts those interruptions on hold while you play, and hands
everything back when you're done.

---

## Start here

1. Double-click **`QuietWindows.bat`**
2. Press the big green button
3. Restart your PC when it says to

Then before each session press **Quiet Windows down**, and after each session
press **Wake Windows back up**.

That's the whole thing. If you want it explained step by step, open
[HOW-TO.md](HOW-TO.md) — it's written for people who don't want to learn what
any of this means.

---

## What it actually does

| What | Why it helps |
|---|---|
| Puts Windows Update, Search and app updates on hold while you play | These are the number one cause of a mid-game freeze |
| Tells your antivirus to skip your game folders | It re-scans the same files thousands of times while you play. It still guards everything else |
| Turns off USB power saving and the Xbox Game Bar | Two Windows habits that quietly cost frames |
| Steadies the system clock | Windows slows its internal clock when your game isn't the front window. That's the "it stutters until I click on the game" problem |
| Moves graphics-card and USB interrupts off your game's cores | Your hardware taps the processor thousands of times a second. This moves the taps somewhere your game isn't |
| Keeps your game on the fast half of an AMD X3D processor | Only applies to some AMD chips. It works out whether yours is one, and skips it if not |

Everything is reversible. Every single change has an Undo button on the
Advanced page, and it saves a snapshot of your real settings before it
touches anything so it can put them back exactly as they were.

---

## When something still stutters

There's a whole page for that. It records what your PC does every second
while you play, then reads the recording back and names what interrupted
you. Not a guess — the actual program, and often the actual file it was
reading at that moment.

The most useful thing it tells people is that **it usually isn't the game
and it usually isn't your hard drive.** On one measured 25-minute session,
the PC waited on the disk 4,712 times. Fourteen of those were the game. The
other 4,698 were the Microsoft Store updating apps, Edge updating itself,
Windows Search indexing, and the touch keyboard.

That's the whole idea behind this tool. Your hardware is almost certainly
fine. Windows is just busy.

---

## Your games

QuietWindows keeps a list of the games it looks after. First time you run
it, it scans Steam, Epic, Xbox, GOG, EA and Ubisoft and builds that list on
its own. If it misses one — an older game, something installed somewhere
unusual — open **My Games** and point it at the game's `.exe` file.

That list is what it uses to tell your antivirus what to leave alone, and to
recognise which program on your PC is "the game" when it's hunting a stutter.

---

## Extras

Some fixes only make sense for one specific game. Those live in the
**Extras** page rather than cluttering up the main menu. iRacing is in there
to start with. Adding another game is a matter of dropping a folder into
`extras\` — see [extras/README.txt](extras/README.txt).

---

## What you need

- **Windows 10 or 11.** Nothing else to install — the PowerShell it uses is
  already built into Windows.
- **Process Lasso** (free, from bitsum.com) — *only* if you have an AMD X3D
  processor. QuietWindows tells you on screen whether you do. If you don't,
  skip it.
- **Windows Performance Toolkit** — optional, only for the deepest level of
  stutter hunting. Everything else works without it.

---

## Is this safe?

Read this bit if nothing else:

- Nothing runs until you press a button.
- Every button says what it's about to do, before it does it.
- Every change has an Undo.
- Your antivirus stays on. It just stops re-scanning your games.
- **The one thing you must do:** after playing, press *Wake Windows back
  up*. Until you do, Windows Update is switched off, which also means no
  fresh antivirus definitions. There's a `-Deadman` option that puts
  everything back automatically at your next restart if you're the
  forgetful type.

These scripts change Windows settings — power, registry, services,
antivirus exclusions. All reversible, nothing happens without your say-so,
but they're yours to review and run at your own risk.

---

MIT licensed. Share it freely.

Built on the stutter-hunting work of the sim-racing community, who spent a
lot of hours measuring this properly instead of guessing.
