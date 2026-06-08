param(
  [Parameter(Mandatory=$true)][string]$FolderName,
  [Parameter(Mandatory=$true)][string]$SoftwareName,
  [Parameter(Mandatory=$true)][string]$ProjectName,
  [Parameter(Mandatory=$true)][string]$BackupName,
  [string]$GitHubOwner = "ray541221",
  [string[]]$OldBackupPaths = @(),
  [string]$DesktopBase = "C:\Users\88692\Desktop",
  [string]$DriveBase = "G:\我的雲端硬碟"
)

$ErrorActionPreference = "Stop"

function Ensure-Dir($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Assert-SafeOldPath($Path, $BackupPath) {
  $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
  $driveRoot = (Resolve-Path -LiteralPath $DriveBase).Path.TrimEnd('\')
  $backupResolved = (Resolve-Path -LiteralPath $BackupPath).Path.TrimEnd('\')
  $oldResolved = $resolved.Path.TrimEnd('\')

  if ($oldResolved -notlike "$driveRoot\*") { throw "Blocked old path outside Google Drive: $oldResolved" }
  if ($oldResolved -eq $backupResolved) { throw "Blocked deleting new backup folder: $oldResolved" }
  return $oldResolved
}

$rootPath = Join-Path $DesktopBase $FolderName
$backupPath = Join-Path $DriveBase $BackupName
$repo = "$GitHubOwner/$BackupName"

Ensure-Dir $rootPath
Ensure-Dir $backupPath

$agentsPath = Join-Path $rootPath "AGENTS.md"
$agents = @"
<INSTRUCTIONS>
繁體中文/最少字數/精簡口語化/條列式解決方案/不要講原因跟廢話

$SoftwareName{$ProjectName}根目錄指定路徑：
$rootPath

永遠備份：
- GitHub：$repo
- Google Drive：$backupPath
</INSTRUCTIONS>
"@
Set-Content -LiteralPath $agentsPath -Value $agents -Encoding UTF8

foreach ($old in $OldBackupPaths) {
  if (Test-Path -LiteralPath $old) {
    $safeOld = Assert-SafeOldPath $old $backupPath
    robocopy $safeOld $backupPath /E /MOVE | Out-Host
    if (Test-Path -LiteralPath $safeOld) {
      Remove-Item -LiteralPath $safeOld -Recurse -Force
    }
  }
}

robocopy $rootPath $backupPath /E /XD .git | Out-Host

Push-Location $rootPath
try {
  git rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -ne 0) { git init | Out-Host }

  $remote = git remote get-url origin 2>$null
  if ($LASTEXITCODE -ne 0) {
    gh repo view $repo --json nameWithOwner *> $null
    if ($LASTEXITCODE -ne 0) {
      gh repo create $repo --private --source . --remote origin | Out-Host
    } else {
      git remote add origin "https://github.com/$repo.git"
    }
  }

  git add .
  $status = git status --short
  if ($status) {
    git commit -m "Update backup settings" | Out-Host
  }

  $branch = git branch --show-current
  if (-not $branch) { $branch = "main"; git checkout -b main | Out-Host }
  git push -u origin $branch | Out-Host
}
finally {
  Pop-Location
}

Write-Host "DONE"
Write-Host "Root: $rootPath"
Write-Host "GitHub: $repo"
Write-Host "Google Drive: $backupPath"
