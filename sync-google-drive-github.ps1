$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\88692\Desktop\Codex"
$DriveRoot = "G:\" + (-join ([char[]](25105,30340,38642,31471,30828,30879)))
$WebsiteData = -join ([char[]](32178,31449,36039,26009))
$VideoFile = (-join ([char[]](32178,31449,39318,38913,24433,38899))) + ".mp4"
$DrivePath = Join-Path $DriveRoot $WebsiteData
$Branch = "main"
$KeepFiles = @("index.html", "page2.html", $VideoFile)

function Ensure-Folder([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Copy-KeepOnly([string]$Source, [string]$Destination) {
  foreach ($name in $KeepFiles) {
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

Ensure-Folder $DrivePath

git -C $RepoPath pull --rebase origin $Branch

Copy-KeepOnly $DrivePath $RepoPath
Copy-KeepOnly $RepoPath $DrivePath
Purge-DriveExtras

git -C $RepoPath add -- index.html page2.html $VideoFile sync-google-drive-github.ps1
$status = git -C $RepoPath status --porcelain
if ($status) {
  git -C $RepoPath commit -m ("sync website: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
}

git -C $RepoPath push origin $Branch

Write-Host "DONE"
