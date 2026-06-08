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

function Sync-Mirror($Source, $Destination) {
  robocopy $Source $Destination /MIR /IS /Z /XA:H /W:5 /R:2 /XD .git node_modules .venv __pycache__ | Out-Host
  $robocopyCode = $LASTEXITCODE

  $excludedDirs = @(".git", "node_modules", ".venv", "__pycache__")
  $sourceFiles = Get-ChildItem -LiteralPath $Source -Recurse -File -Force | Where-Object {
    $relative = $_.FullName.Substring($Source.TrimEnd('\').Length).TrimStart('\')
    $parts = $relative -split '[\\/]'
    -not ($parts | Where-Object { $excludedDirs -contains $_ })
  }

  foreach ($file in $sourceFiles) {
    $relative = $file.FullName.Substring($Source.TrimEnd('\').Length).TrimStart('\')
    $target = Join-Path $Destination $relative
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetDir)) {
      New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }

    $copyNeeded = -not (Test-Path -LiteralPath $target)
    if (-not $copyNeeded) {
      $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
      $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
      $copyNeeded = ($sourceHash -ne $targetHash)
    }

    if ($copyNeeded) {
      Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
  }

  if ($robocopyCode -gt 7) {
    throw "Robocopy failed: $robocopyCode"
  }
}

foreach ($pair in $pairs) {
  if (-not (Test-Path -LiteralPath $pair.Source)) {
    New-Item -ItemType Directory -Force -Path $pair.Source | Out-Null
  }

  if (-not (Test-Path -LiteralPath $pair.Destination)) {
    New-Item -ItemType Directory -Force -Path $pair.Destination | Out-Null
  }

  Sync-Mirror $pair.Source $pair.Destination
}

Write-Host "DONE"
