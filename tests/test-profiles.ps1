$env:APPDATA = '/tmp/appdata'
. "$PSScriptRoot/../scripts/CPU-Profile.ps1"

$names = @(
  '5500X3D','5600X3D','5700X3D','5800X3D',
  '7500X3D','7600X3D','7700X3D','7800X3D','7900X3D','7950X3D','7945HX3D',
  '9800X3D','9850X3D','9900X3D','9950X3D','9950X3D2','9955HX3D'
)

"{0,-10} {1,-34} {2,-7} {3,-6} {4,-5} {5,-9} {6,-11} {7}" -f 'FORCE','Model','Topo','VCche','Freq','VCacheRng','BgRange','IRQ'
"-" * 118
foreach ($n in $names) {
    $env:QW_FORCE_PROFILE = $n
    Clear-CpuConfig
    $p = Get-CpuProfile -NoCache
    "{0,-10} {1,-34} {2,-7} {3,-6} {4,-5} {5,-9} {6,-11} {7}" -f `
        $n, $p.Model, $p.Topology, $p.VCacheScope, $p.FreqFirst, $p.VCacheRange, $p.BackgroundRange, ($p.IrqTargets -join ',')
}

""
"=== 9950X3D2 advice ==="
$env:QW_FORCE_PROFILE = '9950X3D2'; Clear-CpuConfig
$p = Get-CpuProfile -NoCache
Get-CpuTopologySummary $p
Get-CpuPinningAdvice  $p

""
"=== 5600X3D advice + warnings ==="
$env:QW_FORCE_PROFILE = '5600X3D'; Clear-CpuConfig
$p = Get-CpuProfile -NoCache
Get-CpuTopologySummary $p
Get-CpuPinningAdvice  $p
Write-CpuWarnings $p

""
"=== mobile warning (9955HX3D) ==="
$env:QW_FORCE_PROFILE = '9955HX3D'; Clear-CpuConfig
$p = Get-CpuProfile -NoCache
Write-CpuWarnings $p

""
"=== unknown / non-X3D fallback (no force) ==="
Remove-Item Env:QW_FORCE_PROFILE -ErrorAction SilentlyContinue
Clear-CpuConfig
$p = Get-CpuProfile -NoCache
"Model=$($p.Model)  HasBigCache=$($p.HasBigCache)  TopologyKnown=$($p.TopologyKnown)  Source=$($p.DetectSource)  Freq=$($p.FreqFirst)  Logical=$($p.LogicalCores)"
Write-CpuWarnings $p
Get-CpuPinningAdvice $p

""
"=== bad force value is ignored ==="
$env:QW_FORCE_PROFILE = 'NotARealChip'
Clear-CpuConfig
$p = Get-CpuProfile -NoCache
"Simulated=$($p.Simulated)"
Write-CpuWarnings $p

""
"=== Resolve-CpuTarget rejects an impossible env override ==="
Remove-Item Env:QW_FORCE_PROFILE -ErrorAction SilentlyContinue
$env:QW_FREQ_FIRST_CORE = '999'
Clear-CpuConfig
$r = Resolve-CpuTarget
"resolved FreqFirst=$($r.FreqFirst)  Limit=$($r.Limit)  Valid=$($r.Valid)"
Remove-Item Env:QW_FREQ_FIRST_CORE -ErrorAction SilentlyContinue
