$ErrorActionPreference = "Stop"

$scriptPath = "C:\Users\88692\Desktop\Codex\sync-desktop-folders-to-drive.ps1"
$desktop = [Environment]::GetFolderPath("Desktop")
$websiteData = -join ([char[]](32178,31449,36039,26009))
$scriptGen = -join ([char[]](33139,26412,29983,25104))
$folders = @(
  (Join-Path $desktop $websiteData),
  (Join-Path $desktop "WTF"),
  (Join-Path $desktop $scriptGen)
)

$sync = {
  param($Path)
  $now = Get-Date
  if ($script:lastRun -and (($now - $script:lastRun).TotalSeconds -lt 3)) {
    return
  }
  $script:lastRun = $now
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

  Register-ObjectEvent $watcher Created -Action { & $sync $Event.SourceEventArgs.FullPath } | Out-Null
  Register-ObjectEvent $watcher Changed -Action { & $sync $Event.SourceEventArgs.FullPath } | Out-Null
  Register-ObjectEvent $watcher Deleted -Action { & $sync $Event.SourceEventArgs.FullPath } | Out-Null
  Register-ObjectEvent $watcher Renamed -Action { & $sync $Event.SourceEventArgs.FullPath } | Out-Null
  $watchers += $watcher
}

& $sync "startup"

while ($true) {
  Wait-Event -Timeout 60 | Out-Null
}
