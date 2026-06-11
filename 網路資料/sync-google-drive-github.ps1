$ErrorActionPreference = "Stop"

$RepoPath = Split-Path -Parent $PSScriptRoot
$SitePath = $PSScriptRoot
$DriveRoot = "G:\" + (-join ([char[]](25105,30340,38642,31471,30828,30879)))
$WebsiteData = -join ([char[]](32178,36335,36039,26009))
$VideoFile = (-join ([char[]](32178,31449,39318,38913,24433,38899))) + ".mp4"
$DrivePath = Join-Path $DriveRoot $WebsiteData
$Branch = "main"
$SyncScript = "sync-google-drive-github.ps1"
$KeepFiles = @("index.html", "page2.html", $VideoFile, $SyncScript)
$ContentFiles = @("index.html", "page2.html", $VideoFile)

function Invoke-Git {
  & git @args
  if ($LASTEXITCODE -ne 0) {
    throw "git failed: git $($args -join ' ')"
  }
}

function Ensure-Folder([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Copy-KeepOnly {
  param(
    [string]$Source,
    [string]$Destination,
    [string[]]$Files = $KeepFiles
  )

  foreach ($name in $Files) {
    $sourceFile = Join-Path $Source $name
    if (Test-Path -LiteralPath $sourceFile) {
      Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $Destination $name) -Force
    }
  }
}

function Purge-DriveExtras {
  Get-ChildItem -LiteralPath $DrivePath -Force | Where-Object {
    $KeepFiles -notcontains $_.Name
  } | Remove-Item -Recurse -Force
}

function Purge-RepoExtras {
  Get-ChildItem -LiteralPath $RepoPath -Force | Where-Object {
    $_.Name -ne ".git" -and $_.Name -ne $WebsiteData
  } | Remove-Item -Recurse -Force
}

function Purge-SiteExtras {
  Get-ChildItem -LiteralPath $SitePath -Force | Where-Object {
    $KeepFiles -notcontains $_.Name
  } | Remove-Item -Recurse -Force
}

function Commit-IfNeeded {
  Invoke-Git -C $RepoPath add -A
  $status = git -C $RepoPath status --porcelain
  if ($status) {
    Invoke-Git -C $RepoPath commit -m ("sync website: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
  }
}

Ensure-Folder $DrivePath

Purge-RepoExtras
Purge-SiteExtras
Purge-DriveExtras
Copy-KeepOnly $DrivePath $SitePath $ContentFiles
Copy-KeepOnly $SitePath $DrivePath $KeepFiles
Commit-IfNeeded

Invoke-Git -C $RepoPath pull --rebase origin $Branch

Purge-RepoExtras
Purge-SiteExtras
Purge-DriveExtras
Copy-KeepOnly $SitePath $DrivePath $KeepFiles
Commit-IfNeeded

Invoke-Git -C $RepoPath push origin $Branch

Write-Host "DONE"
