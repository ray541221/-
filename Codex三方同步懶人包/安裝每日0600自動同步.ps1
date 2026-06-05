$ErrorActionPreference = "Stop"

$TaskName = "Codex三方同步"
$ScriptPath = "C:\Users\88692\Desktop\Codex\sync-all.ps1"

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "sync-all.ps1 not found: $ScriptPath"
}

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At "06:00"
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Sync Desktop Codex, GitHub codex-backup, Google Drive codex-backup daily at 06:00" -Force | Out-Null
Write-Host "Installed scheduled task: $TaskName daily 06:00"
