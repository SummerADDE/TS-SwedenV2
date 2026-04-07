# Syncs repository script files into the Steam asset script folders.
# Kör detta script från TS-SwedenV2-roten när du vill uppdatera Steam med dina senaste ändringar.

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Paths = @(
    @{ src = Join-Path $RepoRoot "SECrossingsTest\RailNetwork\LevelCrossings\scripts"; dst = "C:\Program Files (x86)\Steam\steamapps\common\RailWorks\Assets\SummerADDE\SECrossingsTest\RailNetwork\LevelCrossings\scripts" },
    @{ src = Join-Path $RepoRoot "SESignalsTest\RailNetwork\signals\scripts"; dst = "C:\Program Files (x86)\Steam\steamapps\common\RailWorks\Assets\SummerADDE\SESignalsTest\RailNetwork\signals\scripts" }
)

foreach ($path in $Paths) {
    if (-not (Test-Path $path.src)) {
        Write-Error "Källmappen finns inte: $($path.src)"
        continue
    }
    if (-not (Test-Path $path.dst)) {
        Write-Error "Målmappen finns inte: $($path.dst)"
        continue
    }

    Write-Host "Synkroniserar: $($path.src) -> $($path.dst)" -ForegroundColor Cyan
    Copy-Item -Path (Join-Path $path.src "*.lua") -Destination $path.dst -Force -Verbose
}

Write-Host "Synkronisering klar." -ForegroundColor Green
