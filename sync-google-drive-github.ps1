$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\88692\Desktop\Codex"
$DrivePath = "G:\我的雲端硬碟\網站資料"
$Branch = "main"
$KeepFiles = @("index.html", "page2.html", "網站首頁影音.mp4")

function Ensure-Folder([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Copy-KeepFiles([string]$Source, [string]$Destination) {
  Ensure-Folder $Destination

  foreach ($name in $KeepFiles) {
    $sourceFile = Join-Path $Source $name
    if (Test-Path -LiteralPath $sourceFile) {
      Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $Destination $name) -Force
    }
  }

  Get-ChildItem -LiteralPath $Destination -Force | Where-Object {
    $KeepFiles -notcontains $_.Name
  } | Remove-Item -Recurse -Force
}

Ensure-Folder $DrivePath

git -C $RepoPath pull --rebase origin $Branch

Copy-KeepFiles $DrivePath $RepoPath
Copy-KeepFiles $RepoPath $DrivePath

git -C $RepoPath add -- index.html page2.html "網站首頁影音.mp4"
$status = git -C $RepoPath status --porcelain
if ($status) {
  git -C $RepoPath commit -m ("sync website: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
}

git -C $RepoPath push origin $Branch

Write-Host "DONE"
