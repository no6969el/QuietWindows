<#
    Find-Stutter-Cause.ps1
    ---------------------------------------------------------------
    Finds the cause of stutters - with ZERO manual editing.
    It automatically reads your most recent Record-Session CSV from the
    Desktop, finds the moments you stuttered (gaps in the timestamps),
    then lists the scheduled tasks and Windows events around each one.

    Before this can help you: record a session first (so there is a
    spreadsheet to read), and turn on the task log BEFORE that session
    (so there is something in it). Both are buttons in the menu.
    It changes nothing. It writes stutter-events.txt to your Desktop.

    ---------------------------------------------------------------
    v3.3.0 - IT NOW READS THE FAULT COLUMNS
    ---------------------------------------------------------------
    If the trace came from an elevated Record-Session run with the Windows
    Performance Toolkit present, the CSV carries three extra columns:
    game_hardfaults_s, top_fault_proc and top_fault_file. This script
    uses them for two things.

    First, attribution: every incident now names the process and file
    that faulted at that second, instead of leaving you to guess from a
    list of scheduled tasks.

    Second - and this is the part that finds stutters the old version
    could not - a fault burst is now an incident in its own right. The
    old logic triggered only on a gap in the timestamps, but a burst of
    hard faults can stall a frame without the logger ever missing a
    second. Those stutters were invisible here.

    A reminder the report repeats, because it is the mistake this whole
    release exists to prevent: hardfaults_s counts the WHOLE PC. On a
    recorded session the game caused 14 of 4,712. Judge your game by
    game_hardfaults_s, never by hardfaults_s.
#>

$desktop = [Environment]::GetFolderPath('Desktop')

# Kit-Common owns the filename patterns and the fault-column names, so
# this script cannot disagree with Record-Session about what was written.
$KitCommon = Join-Path $PSScriptRoot 'Kit-Common.ps1'
if (Test-Path -LiteralPath $KitCommon) { . $KitCommon }
if (-not $SessionCsvPattern) { $SessionCsvPattern = 'QuietWindows-Session-*.csv' }
if (-not $HardFaultColumns)    { $HardFaultColumns = @('game_hardfaults_s','top_fault_proc','top_fault_file') }

# Game-Library decides which of the program names in the log is your
# game. No games on the list yet just means nothing gets highlighted.
$GameRx = $null
try {
    $gl = Join-Path $PSScriptRoot 'Game-Library.ps1'
    if (Test-Path -LiteralPath $gl) { . $gl; $GameRx = Get-GameProcessRegex -Quiet }
} catch { }

# --- find the newest Record-Session CSV on the Desktop ---
$csv = Get-ChildItem -Path $desktop -Filter $SessionCsvPattern -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $csv) {
    Write-Host ""
    Write-Host "  No Record-Session CSV found on your Desktop." -ForegroundColor Yellow
    Write-Host "  Run 'Log a game (Record-Session)' first, then run this again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter to close" | Out-Null
    return
}

Write-Host ""
Write-Host "  Using latest trace: $($csv.Name)" -ForegroundColor Cyan
$day = $csv.LastWriteTime.Date

# --- parse the CSV properly (Import-Csv, not index-0 splitting) ------
# The old code took field [0] of a raw split. That worked, but it could
# not see any other column, and the v3 fault columns are quoted - which
# a naive split would mangle anyway.
$rows = @()
try { $rows = @(Import-Csv -LiteralPath $csv.FullName) } catch { }
if ($rows.Count -lt 2) {
    Write-Host "  That trace has no usable rows." -ForegroundColor Yellow
    Read-Host "  Press Enter to close" | Out-Null; return
}

$cols     = $rows[0].PSObject.Properties.Name
$HasFault = @($HardFaultColumns | Where-Object { $_ -in $cols }).Count -eq $HardFaultColumns.Count

$times = @($rows | ForEach-Object { $_.timestamp } | Where-Object { $_ -match '^\d{1,2}:\d{2}:\d{2}$' })
if ($times.Count -lt 2) {
    Write-Host "  That trace has no usable timestamps." -ForegroundColor Yellow
    Read-Host "  Press Enter to close" | Out-Null; return
}

function DT([string]$hms) { $day + [TimeSpan]::Parse($hms) }
function AsInt($v) { $n = 0; [void][int]::TryParse(("$v").Trim(), [ref]$n); $n }

# --- incident detection --------------------------------------------
# Two independent triggers, tagged so the report can say which fired.
#   GAP   - a second missing from the log. A lead, not a verdict (v3.2.0).
#   FAULT - a burst of disk waiting attributed to YOUR GAME. This one can
#           stall a frame without ever producing a gap, so before v3.3.0
#           it was invisible here.
$FAULT_BURST = 50     # game_hardfaults_s in one second. Your game's median
                      # on a healthy machine is 0; a traced 25-minute
                      # session produced 14 times the game waited on disk, in total.

$incidents = @{}      # timestamp -> list of reasons
function Add-Incident([string]$ts, [string]$why) {
    if (-not $incidents.ContainsKey($ts)) { $incidents[$ts] = @() }
    if ($why -notin $incidents[$ts]) { $incidents[$ts] += $why }
}

$prev = $null
foreach ($t in $times) {
    $cur = [TimeSpan]::Parse($t).TotalSeconds
    if ($null -ne $prev -and ($cur - $prev) -gt 1) { Add-Incident $t 'GAP' }
    $prev = $cur
}

$simTotal = 0; $simPeak = 0; $procTally = @{}
if ($HasFault) {
    foreach ($r in $rows) {
        $sim = AsInt $r.game_hardfaults_s
        $simTotal += $sim
        if ($sim -gt $simPeak) { $simPeak = $sim }
        if ($sim -ge $FAULT_BURST) { Add-Incident $r.timestamp 'FAULT' }
        $p = ("$($r.top_fault_proc)").Trim()
        if ($p) { if (-not $procTally.ContainsKey($p)) { $procTally[$p] = 0 }; $procTally[$p]++ }
    }
}

$ordered = @($incidents.Keys | Sort-Object { [TimeSpan]::Parse($_) })
$Start = DT $times[0]
$End   = DT $times[-1]

$gapN   = @($incidents.Values | Where-Object { $_ -contains 'GAP' }).Count
$faultN = @($incidents.Values | Where-Object { $_ -contains 'FAULT' }).Count

Write-Host ("  Session {0} -> {1}   |   {2} incident(s): {3} gap, {4} fault burst" -f `
    $Start.ToString('HH:mm:ss'), $End.ToString('HH:mm:ss'), $ordered.Count, $gapN, $faultN) -ForegroundColor Cyan
if ($HasFault) {
    Write-Host ("  Per-program disk data present - your game waited {0} time(s), peak {1}/sec" -f $simTotal, $simPeak) -ForegroundColor Green
} else {
    Write-Host "  No per-process fault data in this trace." -ForegroundColor DarkGray
    Write-Host "  Re-run Record-Session via the menu's 'Hard faults (Admin)' button to get it." -ForegroundColor DarkGray
}

# --- write report ---
$out = Join-Path $desktop 'stutter-events.txt'
"STUTTER EVENT SCAN"                                   | Out-File $out -Encoding utf8
"Trace  : $($csv.Name)"                                | Out-File $out -Append -Encoding utf8
"Window : $Start  ->  $End"                            | Out-File $out -Append -Encoding utf8
"Incidents: $($ordered.Count)   ($gapN timestamp gap, $faultN game disk-wait burst)" | Out-File $out -Append -Encoding utf8
if ($ordered.Count) {
    foreach ($ts in $ordered) { "  $ts  [$($incidents[$ts] -join '+')]" | Out-File $out -Append -Encoding utf8 }
}

# --- per-process fault attribution ---------------------------------
"" | Out-File $out -Append -Encoding utf8
"=== WHO WAS FAULTING ===" | Out-File $out -Append -Encoding utf8
if (-not $HasFault) {
@"
This trace has no per-process fault data, so the question "which process
caused it" cannot be answered from it.

To get it: menu -> Troubleshoot -> 1) Record a game -> "Hard faults (Admin)".
That runs the same trace with a kernel HARD_FAULTS capture attached and
adds game_hardfaults_s / top_fault_proc / top_fault_file to the CSV.
Needs the Windows Performance Toolkit (Windows ADK) installed.
"@ | Out-File $out -Append -Encoding utf8
} else {
@"
READ THIS BEFORE BLAMING YOUR STORAGE
-------------------------------------
The hardfaults_s column in the spreadsheet counts the WHOLE PC, not your
game, and it is the single most misleading number in the recording. On a
reference 25-minute session it recorded 4,712 of them, of which the game
caused 14 - 0.3%. The rest were Windows' own filesystem bookkeeping, the
Microsoft Store updating apps, Edge Update, Windows Search and the touch
keyboard.

Judge your game by the game_hardfaults_s column below. Judge everything
else by which program keeps showing up in top_fault_proc.
"@ | Out-File $out -Append -Encoding utf8
    "" | Out-File $out -Append -Encoding utf8
    "Your game's own disk waits this session : $simTotal   (peak $simPeak/sec)" | Out-File $out -Append -Encoding utf8
    "" | Out-File $out -Append -Encoding utf8
    "Seconds in which each program was the worst offender:" | Out-File $out -Append -Encoding utf8
    $procTally.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object {
        $mark = if ($GameRx -and $_.Key -match $GameRx) { '  <-- your game' } else { '' }
        "  {0,6} sec   {1}{2}" -f $_.Value, $_.Key, $mark | Out-File $out -Append -Encoding utf8
    }
    if ($simTotal -eq 0) {
        "" | Out-File $out -Append -Encoding utf8
        "Your game never once waited on the disk. Whatever is stuttering, it is not your game." | Out-File $out -Append -Encoding utf8
    }
}

# 1) scheduled tasks that fired during the whole session (a repeating cadence is the prime suspect)
"" | Out-File $out -Append -Encoding utf8
"=== SCHEDULED TASKS THAT RAN THIS SESSION (Id 100/200) ===" | Out-File $out -Append -Encoding utf8
try {
    $t = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TaskScheduler/Operational'; Id=100,200; StartTime=$Start; EndTime=$End } -ErrorAction Stop | Sort-Object TimeCreated
    if (-not $t) { "(none)" | Out-File $out -Append -Encoding utf8 }
    foreach ($e in $t) { $m=($e.Message -replace '\s+',' '); "{0:HH:mm:ss}  {1}" -f $e.TimeCreated, $m.Substring(0,[Math]::Min(150,$m.Length)) | Out-File $out -Append -Encoding utf8 }
} catch {
    "(TaskScheduler Operational log is off - run Enable-DiagnosticLogs BEFORE your next game to capture this.)" | Out-File $out -Append -Encoding utf8
}

# 2) System events within +/-20s of each detected stutter
"" | Out-File $out -Append -Encoding utf8
"=== EACH INCIDENT: WHAT FAULTED, AND WHAT WINDOWS LOGGED (+/-20s) ===" | Out-File $out -Append -Encoding utf8
if (-not $ordered.Count) {
    "(No incidents detected in this trace - nice and smooth!)" | Out-File $out -Append -Encoding utf8
}

# index rows by timestamp so each incident can report its own fault data
$byTime = @{}
foreach ($r in $rows) { if ($r.timestamp) { $byTime[$r.timestamp] = $r } }

foreach ($ts in $ordered) {
    $c = DT $ts
    "" | Out-File $out -Append -Encoding utf8
    "--- $ts   [$($incidents[$ts] -join '+')] ---" | Out-File $out -Append -Encoding utf8

    if ($HasFault -and $byTime.ContainsKey($ts)) {
        $r    = $byTime[$ts]
        $sim  = AsInt $r.game_hardfaults_s
        $proc = ("$($r.top_fault_proc)").Trim()
        $file = ("$($r.top_fault_file)").Trim()
        if ($proc) {
            "  top faulter : $proc" | Out-File $out -Append -Encoding utf8
            if ($file) { "  reading     : $file" | Out-File $out -Append -Encoding utf8 }
        }
        "  your game    : $sim   (whole PC that second: $($r.hardfaults_s))" | Out-File $out -Append -Encoding utf8
        if ($sim -eq 0 -and $proc -and (-not $GameRx -or $proc -notmatch $GameRx)) {
            "  -> your game did not wait on the disk at all here. This was $proc." | Out-File $out -Append -Encoding utf8
        }
    }
    try {
        $ev = Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$c.AddSeconds(-20); EndTime=$c.AddSeconds(20); Level=1,2,3 } -ErrorAction Stop | Sort-Object TimeCreated
        if (-not $ev) { "  (no warnings/errors logged - typical for a pure DPC/scheduler blip)" | Out-File $out -Append -Encoding utf8 }
        foreach ($e in $ev) { $m=($e.Message -replace '\s+',' '); "  [{0:HH:mm:ss}] Id={1} {2}: {3}" -f $e.TimeCreated,$e.Id,$e.ProviderName,$m.Substring(0,[Math]::Min(150,$m.Length)) | Out-File $out -Append -Encoding utf8 }
    } catch {
        "  (no matching System events)" | Out-File $out -Append -Encoding utf8
    }
}

Write-Host "  Done -> $out" -ForegroundColor Green
Start-Process notepad.exe $out
