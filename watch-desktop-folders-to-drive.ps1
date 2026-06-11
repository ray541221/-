$ErrorActionPreference = "Stop"

$scriptPath = "C:\Users\88692\Desktop\Codex\sync-desktop-folders-to-drive.ps1"
$desktop = [Environment]::GetFolderPath("Desktop")
$websiteData = -join ([char[]](32178,31449,36039,26009))
$folders = @(
  (Join-Path $desktop $websiteData)
)

$script:pendingSync = $false
$script:lastEventAt = Get-Date "2000-01-01"
$settleSeconds = 15

$requestSync = {
  $script:pendingSync = $true
  $script:lastEventAt = Get-Date
}

$runSync = {
  $script:pendingSync = $false
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $scriptPath
  )
}

$watchers = @()
foreach ($folder in $folders) {
  if (-not (Test-Path -LiteralPath $folder)) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
  }

  $watcher = New-Object System.IO.FileSystemWatcher
  $watcher.Path = $folder
  $watcher.IncludeSubdirectories = $true
  $watcher.EnableRaisingEvents = $true

  Register-ObjectEvent $watcher Created -Action { & $requestSync } | Out-Null
  Register-ObjectEvent $watcher Changed -Action { & $requestSync } | Out-Null
  Register-ObjectEvent $watcher Deleted -Action { & $requestSync } | Out-Null
  Register-ObjectEvent $watcher Renamed -Action { & $requestSync } | Out-Null
  $watchers += $watcher
}

& $runSync

while ($true) {
  Wait-Event -Timeout 1 | Out-Null
  if ($script:pendingSync -and (((Get-Date) - $script:lastEventAt).TotalSeconds -ge $settleSeconds)) {
    & $runSync
  }
}
