QUIETWINDOWS  -  what each file in here does
=============================================================

YOU PROBABLY DON'T NEED THIS FILE.

Double-click QuietWindows.bat (one folder up) and use the menu. It runs
everything below for you, in the right order, with an explanation on
every button. In a hurry? Optimize-My-PC.bat does the lot in one go.

This file is for people who want to run things by hand.

To run one by hand:
   powershell -ExecutionPolicy Bypass -File "<path to the .ps1>"

Or run Create-Launchers.ps1 once to get a double-clickable shortcut
next to each of these.

Anything marked (PERMISSION) changes a Windows setting, so Windows will
ask you to allow it. Run those from a PowerShell you opened with
"Run as administrator", or just use the menu, which handles it.


-------------------------------------------------------------
WHAT'S A GAME?          (nothing to edit)
-------------------------------------------------------------
Game-Library.ps1
      The one list of "which games live on this PC". Everything else
      reads it. First time it runs it scans Steam, Epic, Xbox, GOG, EA
      and Ubisoft and saves what it finds to:
            %APPDATA%\QuietWindows\games.json
      Add or remove games from the menu's My Games page rather than by
      editing that file. Not run directly - other scripts load it.

CPU-Profile.ps1
      The one place that knows about your processor: which chip it is,
      where the cache sits, and which core is safe to send interrupts
      to. It identifies your chip four ways, most reliable first:
         1. the CPU's own name, against a list of every AMD X3D made
         2. the cache layout, which finds the real boundaries even on
            chips that didn't exist when this was written
         3. total cache size - has it got the extra game cache or not
         4. core count, as a last resort
      Then it checks the answer against the processors Windows actually
      reports, so it can never point at a core that isn't there.
      Not run directly. Don't delete it.

Kit-Common.ps1
      The one list of what gets quieted: which Windows services and
      which scheduled jobs. Four scripts read it, so this is the single
      place to edit if you want to trim the list. Not run directly.


-------------------------------------------------------------
LOOKING AT THINGS          (changes nothing)
-------------------------------------------------------------
Record-Session.ps1
      THE MAIN ONE. Start it, play, press Ctrl+C. You get a spreadsheet
      on your Desktop with a line for every second: processor load per
      half, interrupt time, graphics card load/power/clocks/temperature,
      your game's CPU use, how often the PC waited on the disk, free
      memory, and which power plan was active.
      Gaps in the timestamps are where your PC stalled.        (no permission)

      Run it WITH permission (or press "Run with disk detail" in the
      menu) and, if you have the free Windows Performance Toolkit
      installed, it also records WHICH program was hitting the disk
      each second, and which file. That adds three columns plus a
      second spreadsheet listing every event.            (PERMISSION, optional)

      IMPORTANT: the plain "hardfaults_s" column counts the WHOLE PC.
      It is not your game. On a measured 25-minute session the game
      accounted for 14 of 4,712; the rest was the Microsoft Store, Edge
      Update, Windows Search and Windows' own filesystem bookkeeping.
      Don't read that column as your game hammering the disk. Use the
      permission run to find out who really is.

Find-Stutter-Cause.ps1
      Reads your most recent recording from the Desktop, finds the
      moments things stalled, and lists what Windows was doing around
      each one. Writes stutter-events.txt to your Desktop. Turn the
      task log on first (Enable-DiagnosticLogs).             (no permission)

      If the recording came from a "disk detail" run it also names the
      program and file behind each incident, and treats a burst of disk
      waiting as a stutter in its own right - those can freeze a frame
      without leaving a gap in the log, so they used to be invisible.

Ready-Check.ps1
      A checklist confirming every fix is actually live after your
      restart. Ends in READY or NOT READY. Adapts to your processor:
      the pinning and interrupt checks are skipped rather than failed
      on a chip they don't apply to.                        (no permission*)

Check-Quiet-Status.ps1
      Are you currently quieted, or back to normal? Run it WITH
      permission - some of Windows' repair jobs are invisible to a
      normal user, so they look absent when they aren't.

Watch-TimerResolution.ps1
      For the "it stutters until I click on the game window" problem.
      Prints the system clock's resolution once a second. Near 1 is
      good; a jump to about 15.6 is the problem.             (no permission)

Test-UndervoltStability.ps1
      A stress test for anyone who has undervolted or overclocked. If
      your PC only crashes in games, this tells you whether those
      settings are to blame. Works on any x86 CPU.            (no permission)


-------------------------------------------------------------
CHANGING THINGS
-------------------------------------------------------------
Start-Quiet.ps1
      BEFORE YOU PLAY. Switches off the Windows Update services (including
      the repair service that undoes this), clears their restart
      instructions, disables the background scan jobs, and turns off
      real-time antivirus scanning. Saves a snapshot of how everything
      was first. Asks for permission itself.                  (PERMISSION)

Stop-Quiet.ps1
      AFTER YOU PLAY. REQUIRED. Replays that snapshot so everything
      goes back exactly as it was.                            (PERMISSION)

Add-Defender-Exclusions.ps1
      Tells Windows Defender to skip your game folders, so it stops
      re-scanning the same files while you play. The folder list comes
      from your My Games list. Run it again after adding a game. (PERMISSION)

Apply-Extra-Tweaks.ps1
      Turns off USB power saving and the Xbox Game Bar.        (PERMISSION)
Undo-Extra-Tweaks.ps1
      Turns both back on.                                     (PERMISSION)

Enable-SmoothTimer.ps1
      Keeps the system clock steady even when your game isn't the front
      window. Restart afterwards.                             (PERMISSION)
Undo-SmoothTimer.ps1
      Back to the Windows default. Restart afterwards.        (PERMISSION)

Set-GPU-IRQ-Affinity.ps1
      Moves your graphics card's interrupts off the core your game runs
      on. Restart afterwards.                                 (PERMISSION)
Undo-GPU-IRQ-Affinity.ps1
      Hands them back to Windows. Restart afterwards.         (PERMISSION)

Set-NIC-USB-IRQ-Affinity.ps1
      Same idea for your network adapter and USB controllers. Restart
      afterwards.                                             (PERMISSION)
Undo-NIC-USB-IRQ-Affinity.ps1
      Hands those back too. Restart afterwards.               (PERMISSION)

Enable-DiagnosticLogs.ps1
      Turns on the Windows task log that Find-Stutter-Cause reads. Do
      this before you record.                                 (PERMISSION)

Repair-PerfCounters.ps1
      Rebuilds Windows' performance counters. Only needed if the
      recorder refuses to run or gives you empty columns. Restart
      afterwards.                                             (PERMISSION)

Watch-For-Reverts.ps1
      Watches for Windows' repair service switching Windows Update back
      on behind your back, and tells you when it does.        (PERMISSION)

Create-Launchers.ps1
      Makes a double-clickable shortcut next to every script here. The
      ones needing permission ask for it automatically.       (no permission)


-------------------------------------------------------------
IF YOU'RE DOING IT ALL BY HAND, THIS ORDER
-------------------------------------------------------------
1) Repair-PerfCounters, but only if Record-Session gives you empty
   columns.  Restart.
2) Power plan: on a two-halves AMD X3D chip, use an all-cores-unparked
   plan. On anything else, Balanced is fine.
3) Two-halves AMD X3D chips only - in Process Lasso, give your game a
   CPU Set covering the cache half, and send background work to the
   other half.
4) Set-GPU-IRQ-Affinity, then Set-NIC-USB-IRQ-Affinity.  Restart.
5) Add-Defender-Exclusions and Apply-Extra-Tweaks. Once each.
6) Your in-game graphics settings, last, with the game closed.
7) Ready-Check, then record a session and confirm there are no gaps in
   the timestamps.


-------------------------------------------------------------
EVERY SESSION - READ THIS ONE
-------------------------------------------------------------
Before: Start-Quiet          After: Stop-Quiet

   Start-Quiet SWITCHES OFF the update services rather than just
   stopping them. Stopping never held: a stopped service keeps its
   startup setting, so the first thing that asks for it starts it again,
   and Windows has a repair service whose whole job is to fix a
   tampered-with update system, on a roughly ten-minute cycle. People
   were getting a stutter the moment it came back mid-session.

   Because it switches things off rather than stopping them, NOTHING
   FIXES ITSELF WHEN YOU RESTART. Stop-Quiet is REQUIRED. Skip it and
   your PC has no Windows Update - and no fresh antivirus definitions,
   because those arrive through the same services.

   Start-Quiet saves your real settings to
      C:\ProgramData\QuietWindows\state.json
   first, and Stop-Quiet replays exactly that - so anything you had
   already switched off stays off. Your antivirus is left off on
   restore if it was already off before you started.

   Useful switches:
      -Verify              wait 3 minutes afterwards, report anything
                           that crept back
      -KeepSearch          leave Windows Search alone, so Start-menu
                           search keeps working
      -KeepTouchKeyboard   leave the touch keyboard alone (useful in VR)
      -KeepStore           leave the Store's auto-download setting alone
      -SkipDefender        leave your antivirus completely alone
      -CloseApps           also close chat apps like Discord and Telegram
      -Deadman             put everything back automatically at your
                           next restart, in case you forget
      -Force               start fresh over a leftover snapshot from a
                           session you never restored

   Check-Quiet-Status tells you which state you're in, including the
   awkward middle case where a service is stopped but still set to
   start on demand - which is how it used to come back mid-session.


-------------------------------------------------------------
TESTING ON HARDWARE YOU DON'T OWN
-------------------------------------------------------------
Set QW_FORCE_PROFILE to any supported model and the whole thing behaves
as if it were running on that chip:

   $env:QW_FORCE_PROFILE = '5600X3D'
   .\QuietWindows.bat

Scripts that write to the registry notice the pretend profile and run in
dry-run mode instead - they print what they would have done and change
nothing. Close the window (or run Remove-Item Env:QW_FORCE_PROFILE) to
go back to real detection.


-------------------------------------------------------------
WHERE SETTINGS ARE KEPT
-------------------------------------------------------------
   %APPDATA%\QuietWindows\config.json    what processor you have
   %APPDATA%\QuietWindows\games.json     your games list
   C:\ProgramData\QuietWindows\          the before-and-after snapshot
                                         and the log

The processor profile is worked out again automatically if the number of
cores Windows reports stops matching, so swapping a CPU can't leave a
stale answer behind.


These scripts change Windows, registry and power settings. Every one is
reversible, but read before you run them on somebody else's PC.
