$ErrorActionPreference = "Stop"

$CodexPath = "C:\Users\88692\Desktop\Codex"
$SyncScript = Join-Path $CodexPath "sync-obsidian.ps1"

Copy-Item -LiteralPath "$PSScriptRoot\Obsidian同步主程式.ps1" -Destination $SyncScript -Force
& "$PSScriptRoot\建立Codex入口.ps1"
& "$PSScriptRoot\安裝每5分鐘自動同步.ps1"
& $SyncScript

Write-Host "Obsidian sync package repaired."
