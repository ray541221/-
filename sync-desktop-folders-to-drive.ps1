$ErrorActionPreference = "Stop"

$desktop = [Environment]::GetFolderPath("Desktop")
$driveRoot = "G:\" + (-join ([char[]](25105,30340,38642,31471,30828,30879)))

$websiteData = -join ([char[]](32178,31449,36039,26009))
$scriptGen = -join ([char[]](33139,26412,29983,25104))

$pairs = @(
  @{ Source = Join-Path $desktop $websiteData; Destination = Join-Path $driveRoot $websiteData },
  @{ Source = Join-Path $desktop "WTF"; Destination = Join-Path $driveRoot "WTF" },
  @{ Source = Join-Path $desktop $scriptGen; Destination = Join-Path $driveRoot $scriptGen }
)

foreach ($pair in $pairs) {
  if (-not (Test-Path -LiteralPath $pair.Source)) {
    New-Item -ItemType Directory -Force -Path $pair.Source | Out-Null
  }

  if (-not (Test-Path -LiteralPath $pair.Destination)) {
    New-Item -ItemType Directory -Force -Path $pair.Destination | Out-Null
  }

  robocopy $pair.Source $pair.Destination /MIR /FFT /Z /XA:H /W:5 /R:2 /XD .git node_modules .venv __pycache__ | Out-Host
}

Write-Host "DONE"
