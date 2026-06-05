$ErrorActionPreference = "Stop"

$VaultPath = "C:\Users\88692\Desktop\Obsidian"
$LinkPath = "C:\Users\88692\Desktop\Codex\ObsidianVault"

if (-not (Test-Path -LiteralPath $VaultPath)) {
    throw "Vault not found: $VaultPath"
}

if (-not (Test-Path -LiteralPath $LinkPath)) {
    New-Item -ItemType Junction -Path $LinkPath -Target $VaultPath | Out-Null
}

Write-Host "Codex ObsidianVault ready: $LinkPath"
