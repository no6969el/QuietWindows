---
id: how-to-add-an-extras-folder
title: Add an Extras folder for a game
kind: how-to
summary: Give one game its own buttons without editing any QuietWindows file.
status: current
updated: 2026-11-27
verified_commit: 51ef0b7
sources: [extras/, QuietWindows-Menu.ps1]
---

This recipe adds per-game buttons to the Extras page.

1. Make a folder named after the game: `extras\My Game\`.
2. Add `.ps1` files. Each becomes a button; dashes turn into spaces
   (`Check-Settings.ps1` shows as "Check Settings").
3. Start a file name with `Admin-` if it needs permission
   (`Admin-Fix-Something.ps1` shows as "Fix Something (permission needed)").
4. Optionally add `README.txt`; its text shows under the heading.
5. Make each script exit non-zero on failure and change nothing it can't undo.
6. Reopen Extras. If the game needs its own folders on the games list, copy the pattern
   in `extras/iRacing/Add-iRacing-To-My-Games.ps1`.
