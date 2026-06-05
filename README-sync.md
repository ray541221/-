# Codex 三方同步

同步目標：
- 本地：C:\Users\88692\Desktop\Codex
- GitHub：https://github.com/ray541221/codex-backup.git
- Google Drive：G:\我的雲端硬碟\codex-backup

使用：
```powershell
.\sync-all.ps1
.\install-sync-task.ps1
```

排程：每天 06:00 自動執行 `sync-all.ps1`。

注意：
- 需先建立 GitHub repo：`codex-backup`
- 需先登入 GitHub CLI 或 Git credential
- Google Drive 路徑需存在並已同步到本機
