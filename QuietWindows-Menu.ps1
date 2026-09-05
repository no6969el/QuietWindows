<#
    QuietWindows  -  the dashboard
    ---------------------------------------------------------------
    Quiet Windows down so your games get the whole PC.

    Everything here is a button. Nothing runs until you press one,
    every change has an Undo, and each button says in plain words what
    it is about to do.

    Pages:
      Main            the three things most people need
      Quiet my PC     the one-press setup
      Each session    before you play / after you play
      Find a stutter  record, then find out what caused it
      My games        what QuietWindows protects
      Advanced        run or undo any single fix
      Extras          fixes that only apply to one particular game
      Help            what all of it means
#>

# 1. WPF needs a single-threaded apartment. Relaunch ourselves if we are not in one.
if ($host.Runspace.ApartmentState -ne "STA") {
    Start-Process powershell.exe -ArgumentList "-NoProfile -Sta -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -WindowStyle Hidden
    return
}

# 2. Hide the black console window behind us so this looks like an app.
try {
    $sig = '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);'
    $win = Add-Type -MemberDefinition $sig -Name Win -Namespace QuietWin -PassThru
    $win::ShowWindow($win::GetConsoleWindow(), 0) | Out-Null
} catch { }

$ErrorActionPreference = 'SilentlyContinue'
$Root       = $PSScriptRoot
$ScriptsDir = Join-Path $Root 'scripts'
$ExtrasDir  = Join-Path $Root 'extras'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ---------------------------------------------------------------- CPU
# Everything we know about this processor lives in scripts\CPU-Profile.ps1:
# which chip it is, where the cache sits, and which core is safe to send
# interrupts to. Nothing here guesses.
$ProfileModule = Join-Path $ScriptsDir 'CPU-Profile.ps1'
if (-not (Test-Path $ProfileModule)) {
    [System.Windows.MessageBox]::Show("scripts\CPU-Profile.ps1 is missing.`n`nUnzip the QuietWindows folder again so the 'scripts' folder sits next to this file.","Missing file") | Out-Null
    return
}
. $ProfileModule

# ---------------------------------------------------------------- games
$GameModule = Join-Path $ScriptsDir 'Game-Library.ps1'
if (Test-Path $GameModule) { . $GameModule }

$cfg      = Get-CpuProfile
$CanSteer = ($cfg.TopologyKnown -and $cfg.HasBigCache -and $cfg.FreqFirst -ge 1 -and $cfg.FreqFirst -lt $cfg.ActualLogical)

# ---------------------------------------------------------------- GUI
$xamlPath = Join-Path $Root 'ui\MainWindow.xaml'
if (-not (Test-Path $xamlPath)) {
    [System.Windows.MessageBox]::Show("ui\MainWindow.xaml is missing.`n`nUnzip the QuietWindows folder again so the 'ui' folder sits next to this file.","Missing file") | Out-Null
    return
}
$XAML = Get-Content -Path $xamlPath -Raw

try {
    $Window = [Windows.Markup.XamlReader]::Parse($XAML)
    $XAML   = $null      # the markup string has done its job; let it go
} catch {
    [System.Windows.MessageBox]::Show("The window failed to load.`n`n$($_.Exception.Message)","Startup error") | Out-Null
    return
}

# ================================================================
#  PAGES AND NAVIGATION
# ================================================================
$PageNames = 'PageMain','PageOptimize','PageSession','PageTroubleshoot','PageGames','PageExtras','PageAdvanced','PageChip','PageHelp'
$pages = @{}
foreach ($p in $PageNames) { $pages[$p] = $Window.FindName($p) }

function Update-Header {
    <# Top-of-window summary: what we detected, in words. #>
    $sim = if ($cfg.Simulated) { "  [PRETENDING - test mode]" } else { "" }
    $Window.FindName("TxtSysInfo").Text = "$($cfg.Model)  |  $($cfg.GpuName)$sim"
    $Window.FindName("TxtTopo").Text    = (Get-CpuTopologySummary $cfg)
    $Window.FindName("TxtOptManual").Text = (Get-CpuPinningAdvice $cfg).Trim()

    # The "do this by hand first" heading only makes sense when there IS
    # something to do by hand. A CPU without the extra cache has no
    # Process Lasso step at all, so the heading would just confuse.
    $optHead = $Window.FindName("TxtOptHeading")
    if (-not $cfg.HasBigCache) {
        $optHead.Visibility = 'Collapsed'
    } elseif ($cfg.Topology -eq 'single') {
        $optHead.Visibility = 'Visible'
        $optHead.Text = "First, one click by hand in Process Lasso (free, from bitsum.com):"
    } else {
        $optHead.Visibility = 'Visible'
        $optHead.Text = "First, a couple of clicks by hand in Process Lasso (free, from bitsum.com):"
    }

    if (-not $cfg.HasBigCache) {
        $Window.FindName("TxtHelpReq").Text = "Your processor does not have AMD's extra game cache, so there is nothing to pin your game to. Everything else in QuietWindows still applies and still helps. Process Lasso is optional for you."
    } elseif ($cfg.Topology -eq 'single') {
        $Window.FindName("TxtHelpReq").Text = "You need one free app: Process Lasso, from bitsum.com. On your chip it is only used to set a power plan that keeps all your cores awake."
    } else {
        $Window.FindName("TxtHelpReq").Text = "You need one free app: Process Lasso, from bitsum.com. It keeps your game on the half of your processor with the extra cache, and sets a power plan that keeps all your cores awake."
    }

    $Window.FindName("TxtChipNow").Text    = "Detected: $($cfg.Model)"
    $Window.FindName("TxtChipDetail").Text = "$($cfg.Profile)  |  $($cfg.LogicalCores) cores as Windows sees them  |  interrupts sent to core $($cfg.FreqFirst)  |  worked out from: $($cfg.DetectSource)"
    $warn = ''
    if ($cfg.Warnings -and $cfg.Warnings.Count) { $warn = ($cfg.Warnings -join "`n`n") }
    $Window.FindName("TxtChipWarn").Text = $warn
    $Window.FindName("TxtChipWarn").Visibility = if ($warn) { 'Visible' } else { 'Collapsed' }
}
Update-Header

# Moving interrupts around only makes sense when we genuinely understand
# the processor. When we do not, grey the button out and say why.
if (-not $CanSteer) {
    $b = $Window.FindName("BtnGPUIRQ")
    if ($b) { $b.IsEnabled = $false; $b.ToolTip = "Not applicable on this processor - QuietWindows could not work out a safe core to move them to." }
}

$MainScroll = $Window.FindName('MainScroll')

function Resize-ToPage {
    <#
        Make the window exactly as tall as the page that is showing.

        Two things fight this by default:
         * Show-Page only toggles Visibility, which does not make the
           window re-measure, so it keeps whatever height the first page
           needed at startup.
         * A ScrollViewer reports a tiny desired height (it can always
           scroll), so SizeToContent never grows the window past that.

        Turning the scrollbar off makes the ScrollViewer report the page's
        real height, so SizeToContent can do its job. Only if the result
        is taller than the screen do we clamp and put the scrollbar back.
    #>
    if (-not $MainScroll) { return }
    try {
        $Window.SizeToContent = 'Manual'
        $MainScroll.VerticalScrollBarVisibility = 'Disabled'
        $Window.SizeToContent = 'Height'
        $Window.UpdateLayout()

        $wa  = [System.Windows.SystemParameters]::WorkArea
        $max = [Math]::Max(320, $wa.Height - 60)

        if ($Window.ActualHeight -gt $max) {
            $Window.SizeToContent = 'Manual'
            $Window.Height = $max
            $MainScroll.VerticalScrollBarVisibility = 'Auto'
            $Window.UpdateLayout()
        }

        $top = $wa.Top + (($wa.Height - $Window.ActualHeight) / 2)
        if ($top -lt $wa.Top) { $top = $wa.Top }
        $Window.Top = $top
    } catch { }
}

function Show-Page($name) {
    foreach ($k in $pages.Keys) { $pages[$k].Visibility = 'Collapsed' }
    $pages[$name].Visibility = 'Visible'
    try { $MainScroll.ScrollToTop() } catch { }
    Resize-ToPage
}

function Find-Expanders($parent) {
    # Logical tree, not visual - this works before the window has drawn.
    $found = @()
    try {
        foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($parent)) {
            if ($child -is [System.Windows.Controls.Expander]) { $found += $child }
            if ($child -is [System.Windows.DependencyObject])  { $found += (Find-Expanders $child) }
        }
    } catch { }
    return $found
}

# ================================================================
#  RUNNING THINGS
# ================================================================
function Launch-Script {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Admin,
        [string]$Friendly
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        $name = if ($Friendly) { $Friendly } else { Split-Path $Path -Leaf }
        [System.Windows.MessageBox]::Show("Cannot find $name.`n`nUnzip the QuietWindows folder again - a file is missing.","File missing")
        return
    }
    # Hand the CPU answer down so the script does not have to work it out again.
    $env:QW_FREQ_FIRST_CORE = "$($cfg.FreqFirst)"
    $env:QW_SIMULATED       = $(if ($cfg.Simulated) { '1' } else { '0' })
    $argStr = "-NoExit -ExecutionPolicy Bypass -File `"$Path`""
    try {
        # -ErrorAction Stop: a declined UAC prompt is non-terminating, so
        # without it the catch below never runs and the failure is invisible.
        if ($Admin) { Start-Process 'powershell.exe' -Verb RunAs -ArgumentList $argStr -ErrorAction Stop }
        else        { Start-Process 'powershell.exe'           -ArgumentList $argStr -ErrorAction Stop }
    } catch {
        [System.Windows.MessageBox]::Show("That did not start - either something went wrong, or you said No to the Windows permission prompt.","Nothing ran")
    }
}

function Launch-KitScript {
    param([Parameter(Mandatory)][string]$FileName, [switch]$Admin)
    Launch-Script -Path (Join-Path $ScriptsDir $FileName) -Admin:$Admin -Friendly $FileName
}

# ---- navigation -------------------------------------------------
$Window.FindName("BtnOptimize").Add_Click({ Show-Page 'PageOptimize' })
$Window.FindName("BtnEachSession").Add_Click({ Show-Page 'PageSession' })
$Window.FindName("BtnTroubleshoot").Add_Click({ Show-Page 'PageTroubleshoot' })
$Window.FindName("BtnGames").Add_Click({ Refresh-GameList; Show-Page 'PageGames' })
$Window.FindName("BtnExtras").Add_Click({ Build-ExtrasPage; Show-Page 'PageExtras' })
$Window.FindName("BtnAdvanced").Add_Click({ Show-Page 'PageAdvanced' })
$Window.FindName("BtnHelp").Add_Click({ Show-Page 'PageHelp' })
$Window.FindName("BtnChip").Add_Click({ Show-Page 'PageChip' })

foreach ($b in 'BtnBackFromOptimize','BtnBackFromSession','BtnBackFromTroubleshoot','BtnBackFromGames','BtnBackFromExtras','BtnBackFromAdvanced','BtnBackFromChip','BtnBackFromHelp') {
    $Window.FindName($b).Add_Click({ Show-Page 'PageMain' })
}
$Window.FindName("BtnExit").Add_Click({ $Window.Close() })

# ---- the tools --------------------------------------------------
$Window.FindName("BtnRecord").Add_Click({          Launch-KitScript 'Record-Session.ps1' })
# Same script, with permission. It starts the extra disk trace only when it
# sees it has permission and the toolkit installed, so -Admin is the whole switch.
$Window.FindName("BtnRecordHF").Add_Click({        Launch-KitScript 'Record-Session.ps1' -Admin })
$Window.FindName("BtnEnableLogs").Add_Click({      Launch-KitScript 'Enable-DiagnosticLogs.ps1' -Admin })
$Window.FindName("BtnScan").Add_Click({            Launch-KitScript 'Find-Stutter-Cause.ps1' })
$Window.FindName("BtnReady").Add_Click({           Launch-KitScript 'Ready-Check.ps1' })
$Window.FindName("BtnWatchTimer").Add_Click({      Launch-KitScript 'Watch-TimerResolution.ps1' })
$Window.FindName("BtnCheckQuiet1").Add_Click({     Launch-KitScript 'Check-Quiet-Status.ps1' })
$Window.FindName("BtnCheckQuiet2").Add_Click({     Launch-KitScript 'Check-Quiet-Status.ps1' })
$Window.FindName("BtnPreGame").Add_Click({         Launch-KitScript 'Start-Quiet.ps1' -Admin })
$Window.FindName("BtnPostGame").Add_Click({        Launch-KitScript 'Stop-Quiet.ps1' -Admin })
$Window.FindName("BtnCreateLaunchers").Add_Click({ Launch-KitScript 'Create-Launchers.ps1' })
$Window.FindName("BtnRepair").Add_Click({          Launch-KitScript 'Repair-PerfCounters.ps1' -Admin })
$Window.FindName("BtnGPUIRQ").Add_Click({          Launch-KitScript 'Set-GPU-IRQ-Affinity.ps1' -Admin })
$Window.FindName("BtnNicIRQ").Add_Click({          Launch-KitScript 'Set-NIC-USB-IRQ-Affinity.ps1' -Admin })
$Window.FindName("BtnTimerFix").Add_Click({        Launch-KitScript 'Enable-SmoothTimer.ps1' -Admin })
$Window.FindName("BtnDefender").Add_Click({        Launch-KitScript 'Add-Defender-Exclusions.ps1' -Admin })
$Window.FindName("BtnTweaks").Add_Click({          Launch-KitScript 'Apply-Extra-Tweaks.ps1' -Admin })
$Window.FindName("BtnWatchRevert").Add_Click({     Launch-KitScript 'Watch-For-Reverts.ps1' -Admin })
$Window.FindName("BtnUndervolt").Add_Click({       Launch-KitScript 'Test-UndervoltStability.ps1' })
$Window.FindName("BtnUndoGPU").Add_Click({         Launch-KitScript 'Undo-GPU-IRQ-Affinity.ps1' -Admin })
$Window.FindName("BtnUndoNic").Add_Click({         Launch-KitScript 'Undo-NIC-USB-IRQ-Affinity.ps1' -Admin })
$Window.FindName("BtnUndoTimer").Add_Click({       Launch-KitScript 'Undo-SmoothTimer.ps1' -Admin })
$Window.FindName("BtnUndoTweaks").Add_Click({      Launch-KitScript 'Undo-Extra-Tweaks.ps1' -Admin })

# ================================================================
#  MY GAMES
# ================================================================
function Refresh-GameList {
    $lst = $Window.FindName('LstGames')
    $cnt = $Window.FindName('TxtGamesCount')
    $lst.Items.Clear()
    $list = $null
    try { $list = Get-GameList -Quiet } catch { }
    $games = @()
    if ($list) { $games = @($list.Games) }

    if ($games.Count -eq 0) {
        $cnt.Text = "Nothing on the list yet."
        $lst.Items.Add("(press 'Look again' to scan, or 'Add a game' to point at one)") | Out-Null
        return
    }
    $cnt.Text = "$($games.Count) game(s) on the list."
    foreach ($g in $games) {
        $tag = if ($g.Source -eq 'manual') { '  [you added this]' } else { '' }
        $lst.Items.Add(("{0}   -   {1}{2}" -f $g.Name, ($g.Exes -join ', '), $tag)) | Out-Null
    }
}

$Window.FindName('BtnGameAdd').Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title  = "Find your game's program file"
    $dlg.Filter = "Programs (*.exe)|*.exe|All files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            if (Add-GameEntry -Path $dlg.FileName) {
                Refresh-GameList
                [System.Windows.MessageBox]::Show("Added.`n`nNow go to Advanced and run 'Stop the virus scanner re-scanning your games' so this folder gets covered.","Game added")
            } else {
                [System.Windows.MessageBox]::Show("That did not look like a game program. Try picking the main .exe from the game's own folder.","Not added")
            }
        } catch {
            [System.Windows.MessageBox]::Show("Could not add that.`n`n$($_.Exception.Message)","Not added")
        }
    }
})

$Window.FindName('BtnGameRemove').Add_Click({
    $lst = $Window.FindName('LstGames')
    if ($null -eq $lst.SelectedItem) {
        [System.Windows.MessageBox]::Show("Click a game in the list first, then press Remove.","Nothing selected")
        return
    }
    $name = ("$($lst.SelectedItem)" -split '   -   ')[0]
    try { Remove-GameEntry -Name $name | Out-Null } catch { }
    Refresh-GameList
})

$Window.FindName('BtnGameRescan').Add_Click({
    $r = [System.Windows.MessageBox]::Show(
        "This scans Steam, Epic, Xbox, GOG, EA and Ubisoft again and rebuilds the list from scratch.`n`nAnything you added by hand will be cleared. Carry on?",
        "Look for games again", [System.Windows.MessageBoxButton]::YesNo)
    if ($r -ne 'Yes') { return }
    try {
        Get-GameList -Rescan -Quiet | Out-Null
        Refresh-GameList
    } catch {
        [System.Windows.MessageBox]::Show("The scan did not finish.`n`n$($_.Exception.Message)","Scan failed")
    }
})

# ================================================================
#  EXTRAS  -  one folder per game, built from what is on disk
# ================================================================
function Build-ExtrasPage {
    <#
        Each subfolder of 'extras' is one game. Every .ps1 in it becomes
        a button. A file named Admin-Something.ps1 is launched with a
        permission prompt; anything else is not.

        Built from disk rather than hard-coded, so adding a game later
        is a matter of dropping a folder in - no editing this file.
    #>
    $panel = $Window.FindName('PanelExtras')
    $empty = $Window.FindName('TxtExtrasEmpty')
    $panel.Children.Clear()

    $dirs = @()
    if (Test-Path -LiteralPath $ExtrasDir) {
        $dirs = @(Get-ChildItem -LiteralPath $ExtrasDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    }
    if ($dirs.Count -eq 0) { $empty.Visibility = 'Visible'; return }
    $empty.Visibility = 'Collapsed'

    foreach ($d in $dirs) {
        $scripts = @(Get-ChildItem -LiteralPath $d.FullName -Filter *.ps1 -File -ErrorAction SilentlyContinue | Sort-Object Name)
        if ($scripts.Count -eq 0) { continue }

        $exp = New-Object System.Windows.Controls.Expander
        $exp.Header     = $d.Name
        $exp.Foreground = 'White'

        $inner = New-Object System.Windows.Controls.StackPanel
        $inner.Margin = '26,2,4,8'

        # A README.txt in the folder becomes the description line.
        $readme = Join-Path $d.FullName 'README.txt'
        if (Test-Path -LiteralPath $readme) {
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text         = (Get-Content -LiteralPath $readme -Raw).Trim()
            $tb.Foreground   = '#CCCCCC'
            $tb.FontSize     = 12
            $tb.TextWrapping = 'Wrap'
            $tb.Margin       = '0,0,0,8'
            $inner.Children.Add($tb) | Out-Null
        }

        foreach ($s in $scripts) {
            $needsAdmin = $s.BaseName -like 'Admin-*'
            $label = ($s.BaseName -replace '^Admin-', '') -replace '-', ' '
            if ($needsAdmin) { $label += '   (permission needed)' }

            $btn = New-Object System.Windows.Controls.Button
            $btn.Content             = $label
            $btn.Background          = '#1E1E1E'
            $btn.Foreground          = 'White'
            $btn.BorderBrush         = '#3F3F46'
            $btn.Padding             = '16,5'
            $btn.Margin              = '0,3,0,3'
            $btn.FontSize            = 13
            $btn.Cursor              = 'Hand'
            $btn.HorizontalAlignment = 'Left'
            # Capture this script's own path - without .GetNewClosure() every
            # button would end up pointing at the last file in the loop.
            $path  = $s.FullName
            $admin = $needsAdmin
            $btn.Add_Click({ Launch-Script -Path $path -Admin:$admin }.GetNewClosure())
            $inner.Children.Add($btn) | Out-Null
        }

        $exp.Content = $inner
        $exp.Add_Expanded({  Resize-ToPage })
        $exp.Add_Collapsed({ Resize-ToPage })
        $panel.Children.Add($exp) | Out-Null
    }
}

# ================================================================
#  CPU PICKER
# ================================================================
function Set-ChipClass($key) {
    Clear-CpuConfig
    if ($key -eq 'AUTO') {
        $script:cfg = Get-CpuProfile -NoCache
    } else {
        $cls = Get-CpuClasses | Where-Object { $_.Key -eq $key } | Select-Object -First 1
        if ($cls -and $cls.Cores -ge 1) { $script:cfg = Get-CpuProfile -NoCache -Assume $cls }
        else                            { $script:cfg = Get-CpuProfile -NoCache }
    }
    Export-CpuConfig $script:cfg
    Update-Header
    [System.Windows.MessageBox]::Show(
        "Now set to:`n$($script:cfg.Model)`n$($script:cfg.Profile)`n`nInterrupts will go to core $($script:cfg.FreqFirst).`n`nClose and reopen QuietWindows so every page picks up the new numbers.",
        "CPU updated")
}

$Window.FindName("BtnChip1").Add_Click({ Set-ChipClass '1' })
$Window.FindName("BtnChip2").Add_Click({ Set-ChipClass '2' })
$Window.FindName("BtnChip3").Add_Click({ Set-ChipClass '3' })
$Window.FindName("BtnChip4").Add_Click({ Set-ChipClass '4' })
$Window.FindName("BtnChip5").Add_Click({ Set-ChipClass '5' })
$Window.FindName("BtnChip6").Add_Click({ Set-ChipClass '6' })
$Window.FindName("BtnChipAuto").Add_Click({ Set-ChipClass 'AUTO' })

# ================================================================
#  THE ONE-PRESS SETUP
# ================================================================
$Window.FindName("BtnRunAuto").Add_Click({
    # No Process Lasso step on a processor without the extra cache, so do
    # not ask about one. The Windows permission prompt is confirmation enough.
    $result = 'Yes'
    if ($cfg.HasBigCache) {
        $prereq = if ($cfg.Topology -eq 'single') {
            "Have you set the Process Lasso power plan shown above? Carry on?"
        } else {
            "Have you done the Process Lasso steps shown above? Carry on?"
        }
        $result = [System.Windows.MessageBox]::Show(
            "This runs all the automatic fixes in one window, which closes itself when it is done.`n`n$prereq",
            "Quiet my PC down", [System.Windows.MessageBoxButton]::YesNo)
    }
    if ($result -ne 'Yes') { return }

    $auto = @(
        'Add-Defender-Exclusions.ps1',
        'Apply-Extra-Tweaks.ps1',
        'Enable-DiagnosticLogs.ps1',
        'Enable-SmoothTimer.ps1'
    )
    if ($CanSteer) { $auto += 'Set-GPU-IRQ-Affinity.ps1' }

    $simFlag = $(if ($cfg.Simulated) { '1' } else { '0' })
    $sb = "`$env:QW_FREQ_FIRST_CORE='$($cfg.FreqFirst)'; `$env:QW_SIMULATED='$simFlag'; `$Host.UI.RawUI.WindowTitle='QuietWindows - working';"
    if ($cfg.Simulated) { $sb += " `$env:QW_FORCE_PROFILE='$($env:QW_FORCE_PROFILE)';" }
    foreach ($script in $auto) {
        $pth = Join-Path $ScriptsDir $script
        if (Test-Path $pth) {
            $esc = $pth -replace "'","''"
            $sb += " Write-Host ''; Write-Host 'Running $script...' -ForegroundColor Cyan; & '$esc';"
        }
    }
    $sb += " Write-Host ''; Write-Host 'ALL DONE - restart your PC once. This window closes in 6 seconds...' -ForegroundColor Green; Start-Sleep 6"
    try {
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($sb))
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc" -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("You said No to the Windows prompt, so nothing was changed.","Nothing ran")
    }
})

# Refit whenever a section is opened or closed - those change the page height.
try {
    foreach ($ex in (Find-Expanders $Window)) {
        $ex.Add_Expanded({  Resize-ToPage })
        $ex.Add_Collapsed({ Resize-ToPage })
    }
} catch { }

# Size to the first page once the window has actually drawn.
$Window.Add_Loaded({ Resize-ToPage })

$Window.ShowDialog() | Out-Null
