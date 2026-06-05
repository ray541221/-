$ErrorActionPreference = "Stop"

$TaskName = "ObsidianVaultForeverSync"
$ScriptPath = "C:\Users\88692\Desktop\Codex\sync-obsidian.ps1"

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Copy-Item -LiteralPath "$PSScriptRoot\Obsidian同步主程式.ps1" -Destination $ScriptPath -Force
}

schtasks /Create /TN $TaskName /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath" /SC MINUTE /MO 5 /F
Write-Host "Installed scheduled task: $TaskName every 5 minutes"
