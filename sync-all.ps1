$ErrorActionPreference = "Stop"

$LocalPath = "C:\Users\88692\Desktop\Codex"
$DrivePath = "G:\我的雲端硬碟\codex-backup"
$RemoteUrl = "https://github.com/88692/codex-backup.git"
$Branch = "main"
$LogDir = Join-Path $LocalPath ".sync-logs"
$LogFile = Join-Path $LogDir ("sync-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

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
    if (-not (Test-Path -LiteralPath (Join-Path $LocalPath ".git"))) {
        Step "init git repo"
        git -C $LocalPath init -b $Branch
    }

    $remotes = git -C $LocalPath remote
    if ($remotes -notcontains "origin") {
        Step "add origin"
        git -C $LocalPath remote add origin $RemoteUrl
    }
    else {
        $origin = git -C $LocalPath remote get-url origin
        if ($origin -ne $RemoteUrl) {
        Step "update origin"
        git -C $LocalPath remote set-url origin $RemoteUrl
        }
    }
}

function Ensure-GitIgnore {
    $ignorePath = Join-Path $LocalPath ".gitignore"
    $needed = @(".sync-logs/", "*.tmp")
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
    git -C $LocalPath fetch origin $Branch
    $fetchExit = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($fetchExit -eq 0) {
        git -C $LocalPath pull --rebase origin $Branch
    }
    else {
        Write-Host "GitHub fetch skipped; remote may not exist yet." -ForegroundColor Yellow
    }
}

function Sync-DriveToLocal {
    if (-not (Test-Path -LiteralPath $DrivePath)) {
        Step "create drive folder"
        New-Item -ItemType Directory -Force -Path $DrivePath | Out-Null
    }

    Step "drive -> local newer files"
    robocopy $DrivePath $LocalPath /E /XO /XD .git .sync-logs /XF sync-all.ps1 install-sync-task.ps1 README-sync.md /R:2 /W:2 /NFL /NDL /NP
    if ($LASTEXITCODE -gt 7) { throw "robocopy drive->local failed: $LASTEXITCODE" }
}

function Push-LocalToDrive {
    Step "local -> drive mirror"
    robocopy $LocalPath $DrivePath /MIR /XD .git .sync-logs /R:2 /W:2 /NFL /NDL /NP
    if ($LASTEXITCODE -gt 7) { throw "robocopy local->drive failed: $LASTEXITCODE" }
}

function Push-GitHub {
    Step "commit and push github"
    git -C $LocalPath add -A
    $status = git -C $LocalPath status --porcelain
    if ($status) {
        git -C $LocalPath commit -m ("sync: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    }
    else {
        Write-Host "No git changes."
    }

    git -C $LocalPath branch -M $Branch
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git -C $LocalPath push -u origin $Branch
    $pushExit = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($pushExit -ne 0) {
        Write-Host "GitHub push skipped; create the remote repo or login first." -ForegroundColor Yellow
    }
}

Require-Command git
Require-Command robocopy
Ensure-GitRepo
Ensure-GitIgnore
Pull-GitHub
Sync-DriveToLocal
Push-GitHub
Push-LocalToDrive

Step "done"
Stop-Transcript | Out-Null
