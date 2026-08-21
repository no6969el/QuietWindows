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
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="QuietWindows" Width="680" SizeToContent="Height"
        MinHeight="300" WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        Background="#121212" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,7"/>
            <Setter Property="Margin" Value="0,4,0,4"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
        </Style>
        <Style TargetType="TextBlock" x:Key="Hint">
            <Setter Property="Foreground" Value="#888888"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="6,0,0,8"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
        </Style>
        <Style TargetType="Expander">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,3,0,3"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="Background" Value="#1A1A1A"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style TargetType="TextBlock" x:Key="ExpText">
            <Setter Property="Foreground" Value="#CCCCCC"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
            <Setter Property="Margin" Value="0,0,0,8"/>
        </Style>
        <Style TargetType="Button" x:Key="RunBtn">
            <Setter Property="Background" Value="#1E1E1E"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="16,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="HorizontalAlignment" Value="Left"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel>
            <TextBlock Text="QUIETWINDOWS" FontSize="24" FontWeight="Bold" Foreground="#4CAF50" HorizontalAlignment="Center"/>
            <TextBlock Text="quiet Windows down so your games get the whole PC" FontSize="12" Foreground="#777777" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>

        <Border Grid.Row="1" BorderBrush="#333333" BorderThickness="0,0,0,1" Margin="0,10,0,15" Padding="0,0,0,10">
            <StackPanel>
                <TextBlock x:Name="TxtSysInfo" Text="CPU | GPU" Foreground="#CCCCCC" FontSize="13" HorizontalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>
                <TextBlock x:Name="TxtTopo" Text="" Foreground="#888888" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0" TextAlignment="Center" TextWrapping="Wrap"/>
            </StackPanel>
        </Border>

        <ScrollViewer x:Name="MainScroll" Grid.Row="2" VerticalScrollBarVisibility="Auto">
        <Grid>

            <!-- ================= MAIN ================= -->
            <StackPanel x:Name="PageMain" Visibility="Visible">
                <Button x:Name="BtnOptimize" Content="1) QUIET MY PC DOWN  (start here)" Background="#1E4620" BorderBrush="#4CAF50" FontWeight="Bold" Height="46" ToolTip="The one-press setup. Shows anything you need to do by hand first, then applies the rest."/>
                <TextBlock Style="{StaticResource Hint}" Text="One press. Applies every safe fix, and explains each one first."/>

                <Button x:Name="BtnEachSession" Content="2) BEFORE &amp; AFTER PLAYING"/>
                <TextBlock Style="{StaticResource Hint}" Text="Do this around each play session. Two buttons: quiet it down, then wake it back up."/>

                <Button x:Name="BtnTroubleshoot" Content="3) FIND A STUTTER"/>
                <TextBlock Style="{StaticResource Hint}" Text="If something still hitches, this names the thing that did it."/>

                <Button x:Name="BtnGames" Content="MY GAMES" ToolTip="The games QuietWindows looks after. Add your own here."/>
                <Button x:Name="BtnAdvanced" Content="ADVANCED TOOLS / UNDO" ToolTip="Run or undo any single fix on its own. Most people never need this."/>
                <Button x:Name="BtnExtras" Content="EXTRAS  -  fixes for one particular game" Background="#2A1F3D" BorderBrush="#9575CD"/>
                <Button x:Name="BtnHelp" Content="HELP  /  WHAT DOES ALL THIS MEAN" Background="#15303A" BorderBrush="#3EA6FF"/>

                <Grid Margin="0,15,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button x:Name="BtnChip" Content="Your CPU" Grid.Column="0" Margin="0,0,4,0" Background="#1E1E1E" HorizontalContentAlignment="Center" ToolTip="See the processor that was detected, or set it yourself."/>
                    <Button x:Name="BtnExit" Content="Exit" Grid.Column="1" Margin="4,0,0,0" Background="#4A1919" BorderBrush="#FF5252" HorizontalContentAlignment="Center"/>
                </Grid>
            </StackPanel>

            <!-- ================= QUIET MY PC ================= -->
            <StackPanel x:Name="PageOptimize" Visibility="Collapsed">
                <TextBlock Text="QUIET MY PC DOWN" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,8"/>
                <TextBlock Text="This is the whole setup. Read the short bit at the top, then press the green button." Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,10"/>

                <TextBlock x:Name="TxtOptHeading" Text="First, a couple of clicks by hand in Process Lasso (free, from bitsum.com):" Foreground="#FFB74D" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,6"/>
                <TextBlock x:Name="TxtOptManual" Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="6,0,0,12"/>

                <Button x:Name="BtnRunAuto" Content="Do the rest for me now  (Windows will ask permission)" Background="#1E4620" BorderBrush="#4CAF50" FontWeight="Bold" Height="44"/>
                <TextBlock Style="{StaticResource Hint}" Text="A window opens, shows each fix as it runs, then closes itself. Say Yes to the blue Windows prompt."/>

                <TextBlock Text="Then restart your PC once. Some of the fixes only take effect after a restart." Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"/>
                <TextBlock Text="Last of all, set your graphics options - in the game, and in your graphics driver panel. Do that after everything above, not before." Foreground="#888888" FontSize="12" TextWrapping="Wrap" Margin="0,6,0,0"/>

                <Button x:Name="BtnBackFromOptimize" Content="Back" Background="#1E1E1E" Margin="0,15,0,0"/>
            </StackPanel>

            <!-- ================= EACH SESSION ================= -->
            <StackPanel x:Name="PageSession" Visibility="Collapsed">
                <TextBlock Text="BEFORE &amp; AFTER PLAYING" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock Style="{StaticResource Hint}" Text="Windows Update, Windows Search and the virus scanner are the usual culprits. These buttons put them on hold while you play, then hand everything back."/>

                <Button x:Name="BtnPreGame" Content="1) Quiet Windows down  -  I am about to play" Foreground="#FFB74D"/>
                <TextBlock Style="{StaticResource Hint}" Text="Press this before you start your game."/>

                <Button x:Name="BtnPostGame" Content="2) Wake Windows back up  -  I have finished" Foreground="#FFB74D"/>
                <TextBlock Style="{StaticResource Hint}" Text="Important: run this when you are done. Until you do, your PC has no Windows Update and no fresh virus definitions."/>

                <Button x:Name="BtnCheckQuiet2" Content="3) Am I game ready right now?"/>
                <TextBlock Style="{StaticResource Hint}" Text="Not sure whether you already quieted it, or already put it back? This tells you."/>

                <Button x:Name="BtnBackFromSession" Content="Back" Background="#1E1E1E" Margin="0,15,0,0"/>
            </StackPanel>

            <!-- ================= FIND A STUTTER ================= -->
            <StackPanel x:Name="PageTroubleshoot" Visibility="Collapsed">
                <TextBlock Text="FIND A STUTTER" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock Style="{StaticResource Hint}" Text="Do these in order. Nothing here changes a setting except step 2."/>

                <Expander Header="1) Record what your PC does while you play" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Press Run, play your game, then press Ctrl+C in the black window to stop. You get a spreadsheet on your Desktop with one line per second."/>
                        <TextBlock Style="{StaticResource ExpText}" Text="The second button does the same thing and also records WHICH program was hitting the disk each second. It needs permission from Windows and the free Windows Performance Toolkit installed. Without those it behaves like the first button and says so."/>
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="BtnRecord" Content="Run" Style="{StaticResource RunBtn}"/>
                            <Button x:Name="BtnRecordHF" Content="Run with disk detail (permission needed)" Style="{StaticResource RunBtn}" Margin="8,0,0,0"/>
                        </StackPanel>
                    </StackPanel>
                </Expander>

                <Expander Header="2) Turn on the background-task log (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Windows can keep a log of every background job it starts. It is off by default. Turn it on BEFORE you record, or step 3 has nothing to read."/>
                        <Button x:Name="BtnEnableLogs" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="3) Tell me what caused it" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Reads your most recent recording, finds the moments your PC stalled, and names what was running at each one. Writes stutter-events.txt to your Desktop."/>
                        <Button x:Name="BtnScan" Content="Run" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="4) Check the fixes are actually live" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="A checklist that ends in READY or NOT READY. Worth running after your restart to prove everything stuck."/>
                        <Button x:Name="BtnReady" Content="Run" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="5) Watch the system clock live" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="For the specific problem where things stutter until you click on the game window. Watch the number: near 1 is good, a jump to about 15.6 is the problem."/>
                        <Button x:Name="BtnWatchTimer" Content="Run" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="6) Am I game ready right now?" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Shows whether Windows is currently quieted or back to normal."/>
                        <Button x:Name="BtnCheckQuiet1" Content="Run" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Button x:Name="BtnBackFromTroubleshoot" Content="Back" Background="#1E1E1E" Margin="0,15,0,0"/>
            </StackPanel>

            <!-- ================= MY GAMES ================= -->
            <StackPanel x:Name="PageGames" Visibility="Collapsed">
                <TextBlock Text="MY GAMES" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock Style="{StaticResource Hint}" Text="These are the games QuietWindows looks after. It uses the list to tell your virus scanner what to leave alone, and to know which program on your PC counts as 'the game' when it is hunting a stutter."/>
                <TextBlock x:Name="TxtGamesCount" Foreground="#4CAF50" FontSize="13" Margin="0,0,0,6"/>
                <ListBox x:Name="LstGames" Height="190" Background="#1A1A1A" Foreground="#DDDDDD" BorderBrush="#3F3F46" FontSize="13"/>
                <Grid Margin="0,8,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button x:Name="BtnGameAdd"    Content="Add a game"      Grid.Column="0" Margin="0,0,4,0" Background="#1E4620" BorderBrush="#4CAF50" HorizontalContentAlignment="Center"/>
                    <Button x:Name="BtnGameRemove" Content="Remove selected" Grid.Column="1" Margin="4,0,4,0" Background="#1E1E1E" HorizontalContentAlignment="Center"/>
                    <Button x:Name="BtnGameRescan" Content="Look again"      Grid.Column="2" Margin="4,0,0,0" Background="#15303A" BorderBrush="#3EA6FF" HorizontalContentAlignment="Center"/>
                </Grid>
                <TextBlock Style="{StaticResource Hint}" Margin="6,10,0,0" Text="Add a game asks you to pick the game's program file (the one ending in .exe). Look again re-scans Steam, Epic, Xbox, GOG, EA and Ubisoft from scratch - which also clears anything you added by hand."/>
                <TextBlock Style="{StaticResource Hint}" Text="After changing this list, go to Advanced and run 'Stop the virus scanner re-scanning your games' again so the new folders are covered."/>
                <Button x:Name="BtnBackFromGames" Content="Back" Background="#1E1E1E" Margin="0,10,0,0"/>
            </StackPanel>

            <!-- ================= EXTRAS ================= -->
            <StackPanel x:Name="PageExtras" Visibility="Collapsed">
                <TextBlock Text="EXTRAS  -  fixes for one particular game" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock Style="{StaticResource Hint}" Text="Everything on the other pages helps any game. What is in here does not - each item only makes sense for the single game it names. Ignore anything you do not play."/>
                <TextBlock x:Name="TxtExtrasEmpty" Foreground="#888888" FontSize="13" TextWrapping="Wrap" Margin="0,4,0,8" Visibility="Collapsed"
                           Text="Nothing is installed in the extras folder yet."/>
                <StackPanel x:Name="PanelExtras"/>
                <TextBlock Style="{StaticResource Hint}" Margin="6,12,0,0" Text="Adding your own: make a folder inside 'extras' named after the game, put your .ps1 files in it, and they appear here next time you open this page. A file whose name starts with Admin- is run with permission."/>
                <Button x:Name="BtnBackFromExtras" Content="Back" Background="#1E1E1E" Margin="0,10,0,0"/>
            </StackPanel>

            <!-- ================= ADVANCED ================= -->
            <StackPanel x:Name="PageAdvanced" Visibility="Collapsed">
                <TextBlock Text="ADVANCED TOOLS" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock Style="{StaticResource Hint}" Text="Every fix on its own, plus the Undo for each. If you used 'Quiet my PC down' you already have all of these - this page is for changing your mind about one of them."/>

                <Expander Header="Make desktop shortcuts for these tools" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Puts shortcuts on your Desktop and Start menu so you can run these without opening this window."/>
                        <Button x:Name="BtnCreateLaunchers" Content="Run" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Stop the virus scanner re-scanning your games (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Tells Windows Defender to skip the game folders on your My Games list. It still protects everything else on your PC."/>
                        <Button x:Name="BtnDefender" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Turn off USB power saving and the Xbox Game Bar (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Two small Windows habits that cost frames: putting USB devices to sleep, and the Game Bar recording in the background."/>
                        <Button x:Name="BtnTweaks" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Steady the system clock (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Windows slows its internal clock down when your game is not the front window, which shows up as uneven frame pacing. This keeps it steady all the time. Restart afterwards."/>
                        <Button x:Name="BtnTimerFix" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Move graphics-card interrupts off your game's core (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Your graphics card taps the processor thousands of times a second. This moves those taps onto a core your game is not using. Restart afterwards."/>
                        <Button x:Name="BtnGPUIRQ" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Move network and USB interrupts off core 0 (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="The same idea for your network adapter and USB controllers. Worth doing if you have a lot of USB devices plugged in. Restart afterwards."/>
                        <Button x:Name="BtnNicIRQ" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Repair Windows performance counters (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Only needed if the recorder or the stutter finder refuses to run, or comes back with empty columns. Restart afterwards."/>
                        <Button x:Name="BtnRepair" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Watch for Windows undoing our work (permission needed)" Foreground="#FFB74D">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Windows has a repair service whose job is to switch Windows Update back on. This watches for that happening and tells you when it does."/>
                        <Button x:Name="BtnWatchRevert" Content="Run (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Test whether your CPU is stable" Foreground="White">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="A stress test for people who have undervolted or overclocked. If your PC only crashes in games, this is how you find out whether those settings are to blame."/>
                        <Button x:Name="BtnUndervolt" Content="Run" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <TextBlock Text="UNDO" FontSize="14" Foreground="#FF5252" FontWeight="Bold" Margin="0,14,0,4"/>

                <Expander Header="Undo: graphics-card interrupt move (permission needed)" Foreground="#FF5252">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Hands interrupt handling back to Windows. Restart afterwards."/>
                        <Button x:Name="BtnUndoGPU" Content="Undo (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Undo: network and USB interrupt move (permission needed)" Foreground="#FF5252">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Hands those back to Windows too. Restart afterwards."/>
                        <Button x:Name="BtnUndoNic" Content="Undo (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Undo: steady system clock (permission needed)" Foreground="#FF5252">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Puts the clock behaviour back to the Windows default."/>
                        <Button x:Name="BtnUndoTimer" Content="Undo (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Expander Header="Undo: USB power saving and Game Bar (permission needed)" Foreground="#FF5252">
                    <StackPanel Margin="26,2,4,8">
                        <TextBlock Style="{StaticResource ExpText}" Text="Turns USB power saving and the Xbox Game Bar back on."/>
                        <Button x:Name="BtnUndoTweaks" Content="Undo (permission needed)" Style="{StaticResource RunBtn}"/>
                    </StackPanel>
                </Expander>

                <Button x:Name="BtnBackFromAdvanced" Content="Back" Background="#1E1E1E" Margin="0,10,0,0"/>
            </StackPanel>

            <!-- ================= CPU ================= -->
            <StackPanel x:Name="PageChip" Visibility="Collapsed">
                <TextBlock Text="YOUR CPU" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock Style="{StaticResource Hint}" Text="QuietWindows works this out by itself. You only need this page if it got it wrong."/>
                <TextBlock x:Name="TxtChipNow" Foreground="#4CAF50" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,2"/>
                <TextBlock x:Name="TxtChipDetail" Foreground="#888888" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,10"/>
                <TextBlock x:Name="TxtChipWarn" Foreground="#FFB74D" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,10"/>
                <TextBlock Text="Wrong? Pick the line that matches your processor. Everything in one group behaves the same here." Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,8"/>
                <Button x:Name="BtnChip1" Content="6-core, one cache block   -   5500X3D / 5600X3D / 7500X3D / 7600X3D"/>
                <Button x:Name="BtnChip2" Content="8-core, one cache block   -   5700X3D / 5800X3D / 7700X3D / 7800X3D / 9800X3D / 9850X3D"/>
                <Button x:Name="BtnChip3" Content="12-core, two halves   -   7900X3D / 9900X3D"/>
                <Button x:Name="BtnChip4" Content="16-core, two halves   -   7950X3D / 9950X3D / 7945HX3D / 9955HX3D"/>
                <Button x:Name="BtnChip5" Content="16-core, extra cache on BOTH halves   -   9950X3D2 Dual Edition"/>
                <Button x:Name="BtnChip6" Content="Anything else   -   Intel, or an AMD without the extra cache"/>
                <Button x:Name="BtnChipAuto" Content="Work it out again for me" Background="#15303A" BorderBrush="#3EA6FF" Margin="0,10,0,0"/>
                <TextBlock Style="{StaticResource Hint}" Text="After changing this, close and reopen QuietWindows so every page picks up the new numbers."/>
                <Button x:Name="BtnBackFromChip" Content="Back" Background="#1E1E1E" Margin="0,10,0,0"/>
            </StackPanel>

            <!-- ================= HELP ================= -->
            <StackPanel x:Name="PageHelp" Visibility="Collapsed">
                <TextBlock Text="WHAT DOES ALL THIS MEAN" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,8"/>

                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,10">A games console runs one thing at a time, so a game gets the whole machine. A Windows PC does not. Even while you are playing, Windows is checking for updates, indexing your files, scanning for viruses and updating apps you forgot you installed. Each of those is a small interruption, and a small interruption at the wrong moment is a stutter you can feel. QuietWindows puts those interruptions on hold while you play, and puts them back afterwards.</TextBlock>

                <TextBlock x:Name="TxtHelpReq" Foreground="#FFB74D" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,10"/>

                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap"><Run FontWeight="Bold" Foreground="White">Quiet my PC down</Run> - the one-press setup. Do it once, restart, done.</TextBlock>
                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"><Run FontWeight="Bold" Foreground="White">Before and after playing</Run> - two buttons you press around each session. The second one is not optional.</TextBlock>
                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"><Run FontWeight="Bold" Foreground="White">Record what your PC does</Run> - writes down what happened every second while you played.</TextBlock>
                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"><Run FontWeight="Bold" Foreground="White">Tell me what caused it</Run> - reads that recording back and names the culprit.</TextBlock>
                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"><Run FontWeight="Bold" Foreground="White">My games</Run> - the list of games this protects. Add yours if it is missing.</TextBlock>
                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"><Run FontWeight="Bold" Foreground="White">Extras</Run> - fixes that only apply to one specific game.</TextBlock>
                <TextBlock Foreground="#CCCCCC" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"><Run FontWeight="Bold" Foreground="White">"Permission needed"</Run> - Windows shows a blue box asking whether you allow this. That is normal for anything that changes a system setting. Say Yes.</TextBlock>

                <TextBlock Foreground="#888888" FontSize="12" TextWrapping="Wrap" Margin="0,12,0,0" Text="Nothing here is permanent. Every change has an Undo on the Advanced page, and the full walkthrough is in HOW-TO.md in the QuietWindows folder."/>
                <Button x:Name="BtnBackFromHelp" Content="Back" Background="#1E1E1E" Margin="0,15,0,0"/>
            </StackPanel>

        </Grid>
        </ScrollViewer>
    </Grid>
</Window>
"@

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
