EXTRAS  -  fixes that only apply to one particular game
=======================================================

Everything on the main QuietWindows pages helps any game. The stuff in
here does not. Each folder below is named after one game, and what is
inside it only makes sense if you play that game. If you do not, ignore
the folder - nothing in here runs on its own.

These show up automatically in the QuietWindows menu under EXTRAS.


ADDING YOUR OWN
---------------
1. Make a folder in here named after the game.
      extras\My Game\

2. Put your PowerShell files (.ps1) in it. Each one becomes a button,
   and the button's name is the file name with the dashes turned into
   spaces. So:
      Check-Settings.ps1     ->  a button reading "Check Settings"

3. If a file needs Windows to ask permission first, start its name with
   "Admin-":
      Admin-Fix-Something.ps1  ->  "Fix Something   (permission needed)"

4. Optional: put a README.txt in the folder. Its text appears under the
   folder's heading in the menu, so you can explain what the buttons do.

Reopen the EXTRAS page and your folder is there. No editing of any
QuietWindows file is needed.
