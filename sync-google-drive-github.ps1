$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\88692\Desktop\Codex"
$DriveRoot = "G:\" + (-join ([char[]](25105,30340,38642,31471,30828,30879)))
$DrivePath = Join-Path $DriveRoot "Nirvana_Studio"
$Branch = "main"

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

Ensure-Folder $DrivePath

Invoke-Git -C $RepoPath add -A
$prePullStatus = git -C $RepoPath status --porcelain
if ($prePullStatus) {
  Invoke-Git -C $RepoPath commit -m ("sync codex folder: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
}

Invoke-Git -C $RepoPath pull --rebase origin $Branch

robocopy $DrivePath $RepoPath /E /XO /XD .git /XF .sync.lock .sync.state /XJ /R:2 /W:2 /NFL /NDL /NP | Out-Host
if ($LASTEXITCODE -gt 7) {
  throw "robocopy drive to repo failed: $LASTEXITCODE"
}

Invoke-Git -C $RepoPath add -A
$driveImportStatus = git -C $RepoPath status --porcelain
if ($driveImportStatus) {
  Invoke-Git -C $RepoPath commit -m ("sync drive imports: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
}

robocopy $RepoPath $DrivePath /MIR /XD .git /XF .sync.lock .sync.state /XJ /R:2 /W:2 /NFL /NDL /NP | Out-Host
if ($LASTEXITCODE -gt 7) {
  throw "robocopy failed: $LASTEXITCODE"
}

Invoke-Git -C $RepoPath add -A
$status = git -C $RepoPath status --porcelain
if ($status) {
  Invoke-Git -C $RepoPath commit -m ("sync codex folder: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
}

Invoke-Git -C $RepoPath push origin $Branch

Write-Host "DONE"
