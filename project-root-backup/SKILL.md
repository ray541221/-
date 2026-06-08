---
name: project-root-backup
description: Set a Windows desktop folder as the root path for a named software/project, consolidate old backup folders into a new Google Drive backup folder named like `project-backup`, delete old empty folders, keep the project backed up to GitHub and Google Drive, and enable Google Drive mirror sync 15 seconds after file changes settle. Use when the user asks to set a desktop folder as a project root, create or use a `?-backup` folder, move old backups into the new backup folder, delete old backup folders, always back up to GitHub and Google Drive, or sync shortly after file contents change.
---

# 設定根目錄路徑與備份

## Workflow

Use this for the user's repeated pattern:

1. Set `C:\Users\88692\Desktop\<folder>` as the root path for `<software><project>`.
2. Move old backup data into `G:\我的雲端硬碟\<backup-name>`.
3. Delete old empty backup folders after verifying the destination path.
4. Always back up to GitHub and Google Drive.
5. Enable Google Drive mirror sync 15 seconds after the latest file change.

## Defaults

- Desktop root base: `C:\Users\88692\Desktop`
- Google Drive base: `G:\我的雲端硬碟`
- GitHub owner: `ray541221`
- Backup folder format: `<project>-backup`
- Repo format: `ray541221/<project>-backup`
- Root instruction file: `AGENTS.md`
- Sync mode: mirror sync to keep Google Drive exactly consistent
- Sync delay: 15 seconds after the latest file event, within the user's 10-30 second stability target

## Run

Use `scripts/setup-project-backup.ps1` when the required fields are known.

Example:

```powershell
.\scripts\setup-project-backup.ps1 `
  -FolderName "obsidian" `
  -SoftwareName "Obsidian 軟體" `
  -ProjectName "所有專案" `
  -BackupName "obsidian-backup" `
  -OldBackupPaths @("G:\我的雲端硬碟\old-obsidian")
```

## Rules

- If the desktop folder does not exist, create it.
- If the Google Drive backup folder does not exist, create it.
- If the folder is not a Git repo, run `git init`.
- If the GitHub repo does not exist, create it with `gh repo create`.
- If a remote exists, keep it unless it is clearly wrong for the requested backup repo.
- Mirror sync project files to Google Drive with `.git`, `node_modules`, `.venv`, and `__pycache__` excluded.
- Use SHA256 comparison after `robocopy` so same-size quick edits still sync.
- Move old backup folder contents into the new backup folder, then delete only old paths that were explicitly provided or found by a targeted search.
- Before deleting any folder, verify the resolved path is inside `G:\我的雲端硬碟` and is not the new backup folder.
- Create a watcher script that monitors created, changed, deleted, and renamed events.
- Wait 15 seconds after the latest file event before syncing.
- Check watcher events once per second so sync happens within 10-30 seconds.
- Create a Windows Startup shortcut so the watcher starts after login.
- Before reporting completion, run one simulation test against a disposable file in a synced folder: create the file, update it rapidly, verify the final content appears in Google Drive, delete it, and verify the Drive copy is removed.
- Commit and push after updating `AGENTS.md`.
