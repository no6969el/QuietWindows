<#
    Optimize-My-PC.ps1  -  one-shot setup (no menu)
    ---------------------------------------------------------------
    Same one-time setup as the big green "QUIET MY PC DOWN" button,
    without the guided menu. One Windows permission prompt, then
    restart when it tells you to.

    Double-click Optimize-My-PC.bat (or right-click this file ->
    Run with PowerShell).

    Prefer buttons and Undo for each piece? Use QuietWindows.bat
    instead - START-HERE.txt has the short path.

    Detects your CPU and skips interrupt steering when it does not
    apply (non-X3D, unknown topology) rather than guessing.
#>

# Cosmetic only: keeps probe noise out of a window aimed at non-readers.
# Anything that must be heard uses -ErrorAction Stop explicitly, which
# overrides this per call. Do not rely on this line to hide real failures.
$ErrorActionPreference = 'SilentlyContinue'
$Root       = $PSScriptRoot
$ScriptsDir = Join-Path $Root 'scripts'

$H='Cyan'; $T='White'; $Go='Green'; $Warn='Yellow'; $Bad='Red'; $Dim='DarkGray'; $Sim='Magenta'
function Write-C { param([string]$Text,[string]$Color=$T) Write-Host $Text -ForegroundColor $Color }
function Bar  { Write-Host "  ============================================================" -ForegroundColor $H }
function Rule { Write-Host "  ------------------------------------------------------------" -ForegroundColor $Dim }

if (-not (Test-Path $ScriptsDir)) {
    Bar; Write-C "  Can't find the 'scripts' folder next to this file." $Bad
    Write-C "  Keep this file in the QuietWindows folder as unzipped." $Dim
    [void](Read-Host "  Press Enter to close"); return
}

$mod = Join-Path $ScriptsDir 'CPU-Profile.ps1'
if (-not (Test-Path $mod)) {
    Bar; Write-C "  scripts\CPU-Profile.ps1 is missing - unzip the folder again." $Bad
    [void](Read-Host "  Press Enter to close"); return
}
. $mod

# ---- identify the chip ------------------------------------------
$P = Get-CpuProfile

function Show-ChipPicker {
    Clear-Host; Bar; Write-C "        QuietWindows   -   OPTIMIZE MY PC" $H; Bar
    Write-C "  Which chip do you have?" $T
    Write-Host ""
    foreach ($c in Get-CpuClasses) {
        Write-C ("    [{0}] {1}" -f $c.Key, $c.Label) $T
        Write-C ("        {0}" -f $c.Examples) $Dim
    }
    Write-Host ""
    Write-C "    [A] Let it detect my CPU automatically" $Dim
    Write-Host ""
    $keys = @(@(Get-CpuClasses | ForEach-Object { $_.Key }) + 'A' + 'a')
    do { $sel = Read-Host "  Choose" } while ($sel -notin $keys)
    if ($sel -match '^[Aa]$') { return (Get-CpuProfile -NoCache) }
    $cls = Get-CpuClasses | Where-Object { $_.Key -eq $sel } | Select-Object -First 1
    if ($cls.Cores -lt 1) { return (Get-CpuProfile -NoCache) }   # "something else" = plain detection
    return (Get-CpuProfile -NoCache -Assume $cls)
}

# Ask only when detection is not confident; otherwise show and let them change it.
if (-not $P.Known -or -not $P.TopologyKnown) {
    $P = Show-ChipPicker
}

# ---- what can we actually apply on this chip? -------------------
$CanSteer = ($P.TopologyKnown -and $P.HasBigCache -and $P.FreqFirst -ge 1 -and $P.FreqFirst -lt $P.ActualLogical)

$fixes = @(
    @{ title='Stop the virus scanner re-scanning your games';   script='Add-Defender-Exclusions.ps1' },
    @{ title='Turn off USB power saving and the Xbox Game Bar'; script='Apply-Extra-Tweaks.ps1' },
    @{ title='Turn on the log the stutter finder reads';        script='Enable-DiagnosticLogs.ps1' },
    @{ title='Steady the system clock (smoother frame pacing)'; script='Enable-SmoothTimer.ps1' }
)
if ($CanSteer) {
    $fixes += @{ title="GPU interrupts off your game's core (-> CPU $($P.FreqFirst))"; script='Set-GPU-IRQ-Affinity.ps1' }
}

# ---- advisory ----------------------------------------------------
Clear-Host; Bar; Write-C "        QuietWindows   -   OPTIMIZE MY PC" $H; Bar
Write-C ("  Detected: {0}" -f $P.Model) $Go
Write-C ("            {0}" -f $P.Profile) $Dim
Write-C ("            {0}" -f (Get-CpuTopologySummary $P)) $Dim
if ($P.Simulated) { Write-Host ""; Write-C "  SIMULATED PROFILE ACTIVE (QW_FORCE_PROFILE) - fixes will DRY-RUN only." $Sim }
Write-Host ""
Write-C "  Here is everything it will do, in one go:" $T
Write-Host ""
foreach ($f in $fixes) { Write-C ("    * " + $f.title) $Dim }
if (-not $CanSteer) {
    Write-C "    (GPU interrupt steering skipped - not applicable on this CPU)" $Dim
}
Write-Host ""

if ($P.HasBigCache -and $P.Topology -ne 'single') {
    Write-C "  Did you do the Process Lasso part first? (free, bitsum.com)" $Warn
    foreach ($line in ((Get-CpuPinningAdvice $P) -split "`n")) { Write-C ("    " + $line.TrimEnd()) $T }
    Write-C "    The HOW-TO file in this folder walks through the clicks." $Dim
} elseif ($P.HasBigCache) {
    Write-C "  Single-CCD chip: nothing to set up first." $Go
    Write-C "    (No core pinning - every core already has the V-Cache.)" $Dim
    Write-C "    * No core pinning - all your cores have the V-Cache." $T
    Write-C "    * Keep your normal Balanced power plan (do NOT force" $T
    Write-C "      all-cores-unparked - that's a dual-CCD-only fix)." $T
} else {
    Write-C "  No 3D V-Cache detected on this CPU." $Warn
    Write-C "    * The general fixes below still apply and still help." $T
    Write-C "    * Core pinning and interrupt steering are skipped." $T
}

if ($P.Warnings -and $P.Warnings.Count) {
    Write-Host ""
    Write-CpuWarnings $P '  '
}

Write-Host ""
Write-C "  Good to know:" $H
Write-C "    * These change Windows settings (registry, power, Defender)." $T
Write-C "    * Every change has an Undo (QuietWindows menu > Advanced)." $T
Write-C "    * ONE blue admin prompt will appear - choose Yes." $T
Write-C "    * A window shows each fix as it runs, then closes itself." $T
Write-C "    * REBOOT afterward to make everything live." $T
Write-Host ""
Rule
$go = Read-Host "  [Enter] quiet my PC down    [C] change CPU    [Q] quit"
if ($go -match '^[Qq]') { return }
if ($go -match '^[Cc]') {
    $P = Show-ChipPicker
    Export-CpuConfig $P
    Write-C "  Chip profile updated - re-run Optimize-My-PC to continue." $Go
    Start-Sleep -Seconds 2
    return
}

# ---- run every fix in one elevated window, no typing -------------
$items = @()
foreach ($f in $fixes) {
    $p = Join-Path $ScriptsDir $f.script
    if (Test-Path $p) { $items += [pscustomobject]@{ Title=$f.title; Path=$p } }
    else { Write-C ("  ! missing: {0} (skipped)" -f $f.script) $Warn }
}
$sb = ("`$qwFail=0; `$env:QW_FREQ_FIRST_CORE='{0}'; `$env:QW_SIMULATED='{1}'; `$Host.UI.RawUI.WindowTitle='QuietWindows - applying baseline';" -f $P.FreqFirst, $(if ($P.Simulated) { '1' } else { '0' }))
if ($P.Simulated) { $sb += (" `$env:QW_FORCE_PROFILE='{0}';" -f $env:QW_FORCE_PROFILE) }
$n = 0
foreach ($it in $items) {
    $n++
    $ttl = $it.Title -replace "'","''"    # NB: not $t - would clobber the $T color var (PS vars are case-insensitive)
    $pth = $it.Path  -replace "'","''"
    $sb += (" Write-Host ''; Write-Host ('=' * 60) -ForegroundColor DarkCyan; Write-Host '[{0}/{1}]  {2}' -ForegroundColor Cyan; try {{ & '{3}'; if (-not `$?) {{ `$qwFail++ }} }} catch {{ `$qwFail++; Write-Host ('   FAILED: ' + `$_.Exception.Message) -ForegroundColor Red }};" -f $n,$items.Count,$ttl,$pth)
}
$sb += " Write-Host '';"
$sb += " if (`$qwFail -gt 0) { Write-Host ('{0} of $($items.Count) step(s) reported a problem - scroll up for the red lines.' -f `$qwFail) -ForegroundColor Yellow }"
$sb += " else { Write-Host 'ALL DONE - this window closes in 5 seconds...' -ForegroundColor Green };"
$sb += " Start-Sleep 5; exit `$qwFail"
$ok  = $true
$why = "  You said No to the Windows prompt - nothing was changed."
try {
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($sb))
    # -ErrorAction Stop is load-bearing. Declining UAC raises a NON-terminating
    # error, which try/catch ignores by default - so this block used to report
    # success after the user pressed No.
    $proc = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ErrorAction Stop `
                          -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"
    if ($proc -and $proc.ExitCode -gt 0) {
        $ok  = $false
        $why = "  {0} step(s) did not finish. Nothing is broken - re-run this, or" -f $proc.ExitCode
    }
} catch { $ok = $false }

Clear-Host; Bar
if (-not $ok) {
    Write-C $why $Warn
    Write-C "  use QuietWindows.bat to run the steps one at a time." $Dim
    Bar; [void](Read-Host "  Press Enter to close"); return
}
Write-C "  ALL DONE." $Go
Write-Host ""
if ($CanSteer) {
    Write-C "  1) REBOOT now - the GPU-interrupt and timer fixes need it." $H
} else {
    Write-C "  1) REBOOT now - the timer fix needs it." $H
}
Write-C "  2) After the reboot, prove it worked (optional): run this" $T
Write-C "     again and press T, or use QuietWindows menu > Find a stutter." $T
Write-C "     It records your session to a spreadsheet - no skipped seconds" $T
Write-C "     in the timestamps means nothing stalled." $T
Write-C "  3) Once it's smooth, do your graphics settings last -" $T
Write-C "     in the game itself and in your graphics driver panel." $T
Write-Host ""
Rule
$a = Read-Host "  [Enter] finish    [T] record a session now (play, then Ctrl+C)"
if ($a -match '^[Tt]') {
    $ft = Join-Path $ScriptsDir 'Record-Session.ps1'
    if (Test-Path $ft) {
        Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$ft`""
        Write-C "  Recorder opened in its own window. Start your game, then Ctrl+C." $Go
        Write-C "  (Best AFTER the reboot - fixes aren't fully live until then.)" $Warn
        Start-Sleep -Seconds 3
    } else {
        Write-C "  Couldn't find scripts\Record-Session.ps1" $Bad; Start-Sleep -Seconds 2
    }
}
Write-C "  You are game ready. Go enjoy it." $Go
Start-Sleep -Seconds 1
