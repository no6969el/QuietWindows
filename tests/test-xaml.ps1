$src = Get-Content "$PSScriptRoot/../QuietWindows-Menu.ps1" -Raw

# pull the here-string that holds the XAML
$start = $src.IndexOf('$XAML = @"')
$end   = $src.IndexOf('"@', $start)
if ($start -lt 0 -or $end -lt 0) { "FAIL: could not locate XAML block"; exit 1 }
$xamlText = $src.Substring($start + '$XAML = @"'.Length, $end - $start - '$XAML = @"'.Length)

try { [xml]$x = $xamlText } catch { "FAIL: XAML is not well-formed XML -> $_"; exit 1 }
"OK: XAML is well-formed XML"

# collect every x:Name defined in the markup
$names = @{}
$nsMgr = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
foreach ($n in $x.SelectNodes("//*")) {
    foreach ($a in $n.Attributes) {
        if ($a.LocalName -eq 'Name') { $names[$a.Value] = $n.LocalName }
    }
}
"OK: $($names.Count) named elements in XAML"

# every FindName("X") in the script must resolve
$missing = @()
foreach ($m in [regex]::Matches($src, 'FindName\("([^"]+)"\)')) {
    $n = $m.Groups[1].Value
    if (-not $names.ContainsKey($n)) { $missing += $n }
}
if ($missing.Count) {
    "FAIL: FindName targets with no matching x:Name -> " + (($missing | Sort-Object -Unique) -join ', ')
    exit 1
}
"OK: every FindName target exists in the XAML"

# every page referenced by Show-Page must exist
$pageList = 'PageMain','PageOptimize','PageSession','PageTroubleshoot','PageGames','PageExtras','PageAdvanced','PageChip','PageHelp'
foreach ($p in $pageList) {
    if (-not $names.ContainsKey($p)) { "FAIL: page $p missing"; exit 1 }
}
"OK: all $($pageList.Count) pages present"

# every page name the script hands to Show-Page must be one of them
foreach ($m in [regex]::Matches($src, "Show-Page\s+'([^']+)'")) {
    if ($pageList -notcontains $m.Groups[1].Value) {
        "FAIL: Show-Page '$($m.Groups[1].Value)' names a page that does not exist"; exit 1
    }
}
"OK: every Show-Page target is a real page"

# the games page needs its list box and all three buttons
foreach ($n in 'LstGames','TxtGamesCount','BtnGameAdd','BtnGameRemove','BtnGameRescan') {
    if (-not $names.ContainsKey($n)) { "FAIL: My Games control $n missing"; exit 1 }
}
"OK: My Games page is complete"

# the extras page is built at runtime, so it only needs its container
foreach ($n in 'PanelExtras','TxtExtrasEmpty') {
    if (-not $names.ContainsKey($n)) { "FAIL: Extras control $n missing"; exit 1 }
}
"OK: Extras page is complete"

# no orphaned handlers left over from the old Reset button
if ($src -match 'BtnReset') { "FAIL: stale BtnReset reference still in script"; exit 1 }
if ($src -match 'Detect-System|Load-Config|Save-Config') { "FAIL: stale detection function reference"; exit 1 }
"OK: no stale references to the old detection code"

# --- v3.3.0: the hard-fault button -------------------------------------
# Both Record-Session buttons run the SAME script; the only difference is
# -Admin, because Record-Session v3 decides for itself whether to trace. If
# somebody ever "helpfully" adds an argument to one of them, these
# assertions are what catches the two halves drifting apart.
foreach ($btn in 'BtnRecord','BtnRecordHF') {
    if (-not $names.ContainsKey($btn)) { "FAIL: $btn missing from XAML"; exit 1 }
    if ($names[$btn] -ne 'Button')     { "FAIL: $btn is a $($names[$btn]), not a Button"; exit 1 }
}
"OK: both Record-Session buttons present"

if ($src -notmatch 'FindName\("BtnRecord"\)\.Add_Click')   { "FAIL: BtnRecord has no click handler";   exit 1 }
if ($src -notmatch 'FindName\("BtnRecordHF"\)\.Add_Click') { "FAIL: BtnRecordHF has no click handler"; exit 1 }
"OK: both Record-Session buttons are wired"

# the plain button must stay non-elevated - that is the kit's
# "no admin needed" promise for the read-only tracer
$plain = [regex]::Match($src, 'FindName\("BtnRecord"\)\.Add_Click\(\{([^}]*)\}')
if (-not $plain.Success)            { "FAIL: could not read BtnRecord handler"; exit 1 }
if ($plain.Groups[1].Value -match '-Admin') { "FAIL: the plain Run button now elevates - read-only path lost"; exit 1 }
"OK: plain Run button is still non-elevated"

$hf = [regex]::Match($src, 'FindName\("BtnRecordHF"\)\.Add_Click\(\{([^}]*)\}')
if (-not $hf.Success)                        { "FAIL: could not read BtnRecordHF handler"; exit 1 }
if ($hf.Groups[1].Value -notmatch '-Admin')  { "FAIL: hard-fault button does not elevate - it will never trace"; exit 1 }
if ($hf.Groups[1].Value -notmatch 'Record-Session\.ps1') { "FAIL: hard-fault button does not launch Record-Session.ps1"; exit 1 }
"OK: hard-fault button launches Record-Session.ps1 elevated"

# the two buttons must be siblings in a horizontal StackPanel, or they
# stack vertically and the layout looks broken
$hp = $x.SelectNodes("//*[local-name()='StackPanel'][@Orientation='Horizontal']")
$found = $false
foreach ($p in $hp) {
    $kids = @($p.ChildNodes | Where-Object { $_.LocalName -eq 'Button' } |
              ForEach-Object { $_.GetAttribute('Name','http://schemas.microsoft.com/winfx/2006/xaml') })
    if ($kids -contains 'BtnRecord' -and $kids -contains 'BtnRecordHF') { $found = $true }
}
if (-not $found) { "FAIL: the two Record-Session buttons are not siblings in a horizontal StackPanel"; exit 1 }
"OK: Record-Session buttons sit side by side"

# duplicate x:Name is a runtime XamlParseException, not a parse error,
# so it would sail past the well-formedness check above
$dupes = [regex]::Matches($xamlText, 'x:Name="([^"]+)"') |
         ForEach-Object { $_.Groups[1].Value } | Group-Object | Where-Object Count -gt 1
if ($dupes) { "FAIL: duplicate x:Name -> " + (($dupes | ForEach-Object { $_.Name }) -join ', '); exit 1 }
"OK: no duplicate x:Name values"
