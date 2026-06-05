$ErrorActionPreference = "Stop"

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Target = "C:\Users\88692\Desktop\Codex"
$Drive = "G:\我的雲端硬碟\codex-backup"
$Remote = "https://github.com/ray541221/codex-backup.git"

New-Item -ItemType Directory -Force -Path $Target | Out-Null
New-Item -ItemType Directory -Force -Path $Drive | Out-Null

Copy-Item -LiteralPath (Join-Path $PackageRoot "三方同步主程式.ps1") -Destination (Join-Path $Target "sync-all.ps1") -Force
Copy-Item -LiteralPath (Join-Path $PackageRoot "安裝每日0600自動同步.ps1") -Destination (Join-Path $Target "install-sync-task.ps1") -Force

if (-not (Test-Path -LiteralPath (Join-Path $Target ".git"))) {
    git -C $Target init -b main
}

$remotes = git -C $Target remote
if ($remotes -notcontains "origin") {
    git -C $Target remote add origin $Remote
}
else {
    git -C $Target remote set-url origin $Remote
}

git -C $Target config user.name "88692"
git -C $Target config user.email "88692@users.noreply.github.com"

& (Join-Path $Target "install-sync-task.ps1")
& (Join-Path $Target "sync-all.ps1")

Write-Host "完成：已安裝/修復 Codex 三方同步。" -ForegroundColor Green
