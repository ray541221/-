param(
  [Parameter(Mandatory=$true)][string]$FolderName,
  [Parameter(Mandatory=$true)][string]$SoftwareName,
  [Parameter(Mandatory=$true)][string]$ProjectName,
  [Parameter(Mandatory=$true)][string]$BackupName,
  [string]$GitHubOwner = "ray541221",
  [string[]]$OldBackupPaths = @(),
  [string]$DesktopBase = "C:\Users\88692\Desktop",
  [string]$DriveBase = ("G:\" + (-join ([char[]](25105,30340,38642,31471,30828,30879)))),
  [switch]$SkipWatcher
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

function Write-SyncScript($RootPath, $BackupPath) {
  $scriptPath = Join-Path $RootPath "sync-to-google-drive.ps1"
  $content = @'
param(
  [Parameter(Mandatory=$true)][string]$Source,
  [Parameter(Mandatory=$true)][string]$Destination
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source)) {
  New-Item -ItemType Directory -Force -Path $Source | Out-Null
}

if (-not (Test-Path -LiteralPath $Destination)) {
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
}

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

if ($robocopyCode -gt 7) { exit $robocopyCode }
exit 0
'@
  Set-Content -LiteralPath $scriptPath -Value $content -Encoding UTF8
  return $scriptPath
}

function Write-WatcherScript($RootPath, $BackupPath, $SyncScriptPath) {
  $watcherPath = Join-Path $RootPath "watch-google-drive-sync.ps1"
  $escapedRoot = $RootPath.Replace("'", "''")
  $escapedBackup = $BackupPath.Replace("'", "''")
  $escapedSync = $SyncScriptPath.Replace("'", "''")
  $content = @"
`$ErrorActionPreference = "Stop"

`$source = '$escapedRoot'
`$destination = '$escapedBackup'
`$syncScript = '$escapedSync'
`$script:pendingSync = `$false
`$script:lastEventAt = Get-Date "2000-01-01"
`$settleSeconds = 5

`$requestSync = {
  `$script:pendingSync = `$true
  `$script:lastEventAt = Get-Date
}

`$runSync = {
  `$script:pendingSync = `$false
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    `$syncScript,
    "-Source",
    `$source,
    "-Destination",
    `$destination
  )
}

if (-not (Test-Path -LiteralPath `$source)) {
  New-Item -ItemType Directory -Force -Path `$source | Out-Null
}

`$watcher = New-Object System.IO.FileSystemWatcher
`$watcher.Path = `$source
`$watcher.IncludeSubdirectories = `$true
`$watcher.EnableRaisingEvents = `$true

Register-ObjectEvent `$watcher Created -Action { & `$requestSync } | Out-Null
Register-ObjectEvent `$watcher Changed -Action { & `$requestSync } | Out-Null
Register-ObjectEvent `$watcher Deleted -Action { & `$requestSync } | Out-Null
Register-ObjectEvent `$watcher Renamed -Action { & `$requestSync } | Out-Null

& `$runSync

while (`$true) {
  Wait-Event -Timeout 1 | Out-Null
  if (`$script:pendingSync -and (((Get-Date) - `$script:lastEventAt).TotalSeconds -ge `$settleSeconds)) {
    & `$runSync
  }
}
"@
  Set-Content -LiteralPath $watcherPath -Value $content -Encoding UTF8
  return $watcherPath
}

function Install-StartupShortcut($Name, $RootPath, $WatcherScriptPath) {
  $startup = [Environment]::GetFolderPath("Startup")
  $shortcutPath = Join-Path $startup "$Name.lnk"
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = "powershell.exe"
  $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatcherScriptPath`""
  $shortcut.WorkingDirectory = $RootPath
  $shortcut.Save()
  return $shortcutPath
}

function Test-GitRepo {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  git rev-parse --is-inside-work-tree *> $null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $oldPreference
  return ($code -eq 0)
}

function Test-GitRemote {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  git remote get-url origin *> $null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $oldPreference
  return ($code -eq 0)
}

function Test-GhRepo($Repo) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  gh repo view $Repo --json nameWithOwner *> $null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $oldPreference
  return ($code -eq 0)
}

function Ensure-GitIdentity {
  $name = git config user.name
  if (-not $name) {
    $name = git config --global user.name
  }
  if (-not $name) {
    git config user.name "88692"
  }

  $email = git config user.email
  if (-not $email) {
    $email = git config --global user.email
  }
  if (-not $email) {
    git config user.email "88692@users.noreply.github.com"
  }
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
- 即時同步：資料內容有變動就馬上同步
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

$syncScriptPath = Write-SyncScript $rootPath $backupPath
robocopy $rootPath $backupPath /MIR /IS /Z /XA:H /W:5 /R:2 /XD .git node_modules .venv __pycache__ | Out-Host
if ($LASTEXITCODE -gt 7) { throw "Google Drive sync failed: $LASTEXITCODE" }

if (-not $SkipWatcher) {
  $watcherScriptPath = Write-WatcherScript $rootPath $backupPath $syncScriptPath
  $shortcutPath = Install-StartupShortcut "RealtimeSync-$BackupName" $rootPath $watcherScriptPath
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $watcherScriptPath
  )
}

Push-Location $rootPath
try {
  if (-not (Test-GitRepo)) { git init | Out-Host }

  if (-not (Test-GitRemote)) {
    if (-not (Test-GhRepo $repo)) {
      gh repo create $repo --private --source . --remote origin | Out-Host
    } else {
      git remote add origin "https://github.com/$repo.git"
    }
  }

  Ensure-GitIdentity
  git add .
  $status = git status --short
  if ($status) {
    git commit -m "Update backup settings" | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Git commit failed: $LASTEXITCODE" }
  }

  $branch = git branch --show-current
  if (-not $branch) {
    $branch = "main"
    git checkout -b main | Out-Host
  }
  git push -u origin $branch | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "Git push failed: $LASTEXITCODE" }
}
finally {
  Pop-Location
}

Write-Host "DONE"
Write-Host "Root: $rootPath"
Write-Host "GitHub: $repo"
Write-Host "Google Drive: $backupPath"
if (-not $SkipWatcher) {
  Write-Host "Watcher: $watcherScriptPath"
  Write-Host "Startup: $shortcutPath"
}
