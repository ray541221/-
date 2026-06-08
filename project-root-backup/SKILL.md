---
name: project-root-backup
description: Set a Windows desktop folder as the root path for a named software/project, consolidate old backup folders into a new Google Drive backup folder named like `project-backup`, delete old empty folders, and keep the project backed up to GitHub and Google Drive. Use when the user says to set a desktop folder as a project root, create or use a `?-backup` folder, move old backups into the new backup folder, delete old backup folders, or always back up to GitHub and Google Drive.
---

# Project Root Backup

## Workflow

Use this for the user's repeated pattern:

1. Set `C:\Users\88692\Desktop\<folder>` as the root path for `<software><project>`.
2. Move old backup data into `G:\我的雲端硬碟\<backup-name>`.
3. Delete old empty backup folders after verifying the destination path.
4. Always back up to GitHub and Google Drive.

## Defaults

- Desktop root base: `C:\Users\88692\Desktop`
- Google Drive base: `G:\我的雲端硬碟`
- GitHub owner: `ray541221`
- Backup folder format: `<project>-backup`
- Repo format: `ray541221/<project>-backup`
- Root instruction file: `AGENTS.md`

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
- Copy/sync project files to Google Drive with `.git` excluded.
- Move old backup folder contents into the new backup folder, then delete only the old folder paths that were explicitly provided or found by a targeted search.
- Before deleting any folder, verify the resolved path is inside `G:\我的雲端硬碟` and is not the new backup folder.
- Commit and push after updating `AGENTS.md`.
