<#
    Check-iRacing-Setup.ps1
    ---------------------------------------------------------------
    A checklist for the parts of an iRacing rig the general
    QuietWindows Ready Check cannot know about.

    It looks at:
      * whether iRacing is on your QuietWindows games list at all
      * whether your Documents\iRacing folder is being skipped by the
        virus scanner (it is the busiest folder on a sim rig)
      * whether Process Lasso has a CPU Set rule for the sim, and no
        hard-affinity rule (iRacing's anti-cheat rejects hard affinity)
      * which wheel, pedal and telemetry apps are running

    Changes nothing. No permission needed.
#>

$QwRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$lib    = Join-Path $QwRoot 'scripts\Game-Library.ps1'
$cpu    = Join-Path $QwRoot 'scripts\CPU-Profile.ps1'

function OK   { param($m) Write-Host "  [OK]   $m" -ForegroundColor Green }
function WARN { param($m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function INFO { param($m) Write-Host "  [ .. ] $m" -ForegroundColor Gray }

Write-Host ""
Write-Host "==============  iRACING SETUP CHECK  ==============" -ForegroundColor Cyan
Write-Host ""

$issues = 0

# ---- 1. on the games list? --------------------------------------
Write-Host "1. QuietWindows games list"
if (Test-Path -LiteralPath $lib) {
    . $lib
    $names = @()
    try { $names = @(Get-GameExeNames -Quiet) } catch { }
    if ($names -contains 'iRacingSim64DX11') { OK "iRacing is on the list" }
    else { WARN "iRacing is not on the list - run 'Add iRacing To My Games' in this same Extras folder"; $issues++ }
} else {
    WARN "could not load scripts\Game-Library.ps1"; $issues++
}

# ---- 2. Documents\iRacing excluded from Defender? ---------------
Write-Host ""
Write-Host "2. Virus scanner"
$docs = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'iRacing'
if (-not (Test-Path -LiteralPath $docs)) {
    INFO "no Documents\iRacing folder on this PC - nothing to check"
} else {
    switch (Test-DefenderExclusion -Folder $docs) {
        'covered'    { OK   "$docs is being skipped" }
        'not'        { WARN "$docs is NOT being skipped - run the Defender step from Advanced"; $issues++ }
        'noaccess'   { INFO "cannot read the exclusion list without permission - right-click this file and Run as administrator if you want it checked" }
        'nodefender' { INFO "Windows Defender is not the antivirus here - check the exclusions in whatever you use instead" }
    }
    # The folder only gets excluded if it is on the games list in the first
    # place, and the automatic scan never finds it - it is nowhere near
    # where the game is installed.
    $onList = $false
    try { $onList = @(Get-GameFolders -Quiet) -contains $docs } catch { }
    if (-not $onList) {
        WARN "$docs is not on your games list, so the Defender step will never cover it - run 'Add iRacing To My Games' first"
        $issues++
    }
}

# ---- 3. Process Lasso rules -------------------------------------
Write-Host ""
Write-Host "3. Process Lasso"
$needPin = $false
if (Test-Path -LiteralPath $cpu) {
    . $cpu
    $P = Get-CpuProfile
    $needPin = ($P.HasBigCache -and $P.Topology -ne 'single')
    if (-not $needPin) {
        INFO "nothing to pin on this processor - skipping"
    }
}
if ($needPin) {
    $range = $P.VCacheRange
    if (Get-Process ProcessGovernor -ErrorAction SilentlyContinue) { OK "Process Lasso is running" }
    else { WARN "Process Lasso is not running - its rules will not apply"; $issues++ }

    $ini = (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'ProcessLasso\config\prolasso.ini')
    if (Test-Path -LiteralPath $ini) {
        try {
            $t = [System.IO.File]::ReadAllText($ini, [System.Text.Encoding]::Unicode).ToLowerInvariant()

            if ($t.Contains("iracingsim64dx11.exe,($range)")) { OK "CPU Set $range is set for the sim" }
            else { WARN "no CPU Set of $range for iRacingSim64DX11.exe - add one (CPU Sets, not Affinity)"; $issues++ }

            # A hard-affinity rule looks like "<exe>,0,<range>" on the
            # DefaultAffinitiesEx line. Whether it is a problem depends
            # entirely on whether it AGREES with the CPU Set:
            #
            #   * different range  -> the two rules fight, and which one
            #                         wins is a coin toss. Real problem.
            #   * same range       -> redundant, not harmful. Anti-cheat
            #                         may quietly drop it, but the CPU Set
            #                         is doing the work anyway.
            #
            # The old wording warned about both, which meant nagging people
            # whose setup was working perfectly well.
            $m = [regex]::Match($t, 'iracingsim64dx11\.exe,0,([0-9]+-[0-9]+)')
            if (-not $m.Success) {
                OK "no hard-affinity rule (the CPU Set is doing the work on its own)"
            } elseif ($m.Groups[1].Value -eq $range.ToLowerInvariant()) {
                INFO "there is also a hard-affinity rule for $range (prolasso.ini, DefaultAffinitiesEx)"
                INFO "  it agrees with the CPU Set, so it is redundant rather than harmful - anti-cheat may ignore it, and the CPU Set still applies"
            } else {
                WARN ("hard-affinity rule is {0} but the CPU Set is {1} - they disagree. Remove the affinity rule (prolasso.ini, DefaultAffinitiesEx)" -f $m.Groups[1].Value, $range)
                $issues++
            }
        } catch { WARN "could not read prolasso.ini"; $issues++ }
    } else {
        INFO "prolasso.ini not in the default place - check where you installed it"
    }
}

# ---- 4. sim-racing peripherals -----------------------------------
Write-Host ""
Write-Host "4. Wheel, pedal and telemetry apps running"
$rigApps = @(
    @{ Name='MOZA Pit House'; Why='wheelbase software - holds your force-feedback profile' },
    @{ Name='FanaLab';        Why='wheelbase software - holds your force-feedback profile' },
    @{ Name='TrueDrive';      Why='wheelbase software - holds your force-feedback profile' },
    @{ Name='SimPro Manager'; Why='wheelbase software - holds your force-feedback profile' },
    @{ Name='RaceHub';        Why='wheelbase software - holds your force-feedback profile' },
    @{ Name='Trading Paints'; Why='downloads car liveries in the background' },
    @{ Name='MarvinsAIRARefactored'; Why='telemetry overlay' },
    @{ Name='iOverlay';       Why='telemetry overlay' },
    @{ Name='CrewChiefV4';    Why='voice spotter' },
    @{ Name='SimHubWPF';      Why='dashboards and effects' }
)
$found = 0
foreach ($a in $rigApps) {
    if (Get-Process $a.Name -ErrorAction SilentlyContinue) {
        INFO ("{0,-24} running  -  {1}" -f $a.Name, $a.Why)
        $found++
    }
}
if ($found -eq 0) { OK "none of the usual rig apps are running" }
else {
    Write-Host ""
    Write-Host "  These are not a problem by themselves. But if you are chasing a stutter," -ForegroundColor DarkGray
    Write-Host "  close them one at a time and see whether it goes away. Do NOT close your" -ForegroundColor DarkGray
    Write-Host "  wheelbase software mid-session - it can take your force feedback with it." -ForegroundColor DarkGray
}

# ---- verdict -----------------------------------------------------
Write-Host ""
if ($issues -eq 0) {
    Write-Host "  iRacing side of things looks good." -ForegroundColor Green
} else {
    Write-Host ("  {0} thing(s) worth sorting out above." -f $issues) -ForegroundColor Yellow
}
Write-Host ""
Read-Host "Press Enter to close" | Out-Null
