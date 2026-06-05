$ErrorActionPreference = "Stop"
& "C:\Users\88692\Desktop\Codex\install-sync-task.ps1"
Get-ScheduledTask -TaskName "Codex三方同步" | Select-Object TaskName,State
