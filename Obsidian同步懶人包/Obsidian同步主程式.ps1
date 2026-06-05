$ErrorActionPreference = "Stop"

$VaultPath = "C:\Users\88692\Desktop\Obsidian"
$DrivePath = "G:\我的雲端硬碟\Obsidian\Obsidian"
$RemoteUrl = "https://github.com/ray541221/obsidian-backup.git"
$Branch = "main"
$LogDir = "C:\Users\88692\Desktop\Codex\.sync-logs\obsidian"
$LogFile = Join-Path $LogDir ("obsidian-sync-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Start-Transcript -Path $LogFile -Append | Out-Null

function Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name not found"
    }
}

function Ensure-GitRepo {
    if (-not (Test-Path -LiteralPath (Join-Path $VaultPath ".git"))) {
        Step "init git repo"
        git -C $VaultPath init -b $Branch
    }

    git -C $VaultPath config user.name "ray541221"
    git -C $VaultPath config user.email "ray541221@users.noreply.github.com"

    $remotes = git -C $VaultPath remote
    if ($remotes -notcontains "origin") {
        git -C $VaultPath remote add origin $RemoteUrl
    }
    else {
        git -C $VaultPath remote set-url origin $RemoteUrl
    }
}

function Ensure-GitIgnore {
    $ignorePath = Join-Path $VaultPath ".gitignore"
    $needed = @(
        ".trash/",
        ".obsidian/workspace.json",
        ".obsidian/workspace-mobile.json",
        ".obsidian/cache/",
        ".obsidian/plugins/*/data.json"
    )

    if (-not (Test-Path -LiteralPath $ignorePath)) {
        Set-Content -LiteralPath $ignorePath -Value ($needed -join [Environment]::NewLine) -Encoding UTF8
        return
    }

    $current = Get-Content -LiteralPath $ignorePath -ErrorAction SilentlyContinue
    foreach ($line in $needed) {
        if ($current -notcontains $line) {
            Add-Content -LiteralPath $ignorePath -Value $line -Encoding UTF8
        }
    }
}

function Pull-GitHub {
    Step "pull github"
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git -C $VaultPath fetch origin $Branch
    $fetchExit = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($fetchExit -eq 0) {
        git -C $VaultPath pull --rebase origin $Branch
    }
}

function Push-GitHub {
    Step "commit and push github"
    git -C $VaultPath add -A
    $status = git -C $VaultPath status --porcelain
    if ($status) {
        git -C $VaultPath commit -m ("sync: obsidian {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    }
    else {
        Write-Host "No git changes."
    }

    git -C $VaultPath branch -M $Branch
    git -C $VaultPath push -u origin $Branch
}

function Push-GoogleDrive {
    Step "local -> google drive mirror"
    New-Item -ItemType Directory -Force -Path $DrivePath | Out-Null
    robocopy $VaultPath $DrivePath /MIR /XD .git /R:2 /W:2 /NFL /NDL /NP
    if ($LASTEXITCODE -gt 7) { throw "robocopy failed: $LASTEXITCODE" }
}

Require-Command git
Require-Command robocopy
if (-not (Test-Path -LiteralPath $VaultPath)) { throw "Vault not found: $VaultPath" }

Ensure-GitRepo
Ensure-GitIgnore
Pull-GitHub
Push-GitHub
Push-GoogleDrive

Step "done"
Stop-Transcript | Out-Null
