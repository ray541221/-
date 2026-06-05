$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Name
    )

    Write-Step "Installing $Name"
    winget install --id $Id -e --accept-package-agreements --accept-source-agreements
}

function Add-UserPath {
    param([string]$PathToAdd)

    if (-not (Test-Path -LiteralPath $PathToAdd)) {
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $paths = @()
    if ($userPath) {
        $paths = $userPath -split ";"
    }

    if ($paths -notcontains $PathToAdd) {
        $newPath = (($paths + $PathToAdd) | Where-Object { $_ }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    }

    if (($env:Path -split ";") -notcontains $PathToAdd) {
        $env:Path = "$env:Path;$PathToAdd"
    }
}

function Show-Version {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    try {
        $result = & $Command 2>&1
        Write-Host "$Name: $result" -ForegroundColor Green
    }
    catch {
        Write-Host "$Name: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Step "Checking winget"
winget --version

Install-WingetPackage -Id "Git.Git" -Name "Git"
Install-WingetPackage -Id "OpenJS.NodeJS.LTS" -Name "Node.js LTS"
Install-WingetPackage -Id "Python.Python.3.12" -Name "Python 3.12"
Install-WingetPackage -Id "Microsoft.VisualStudioCode" -Name "VS Code"
Install-WingetPackage -Id "GitHub.cli" -Name "GitHub CLI"
Install-WingetPackage -Id "astral-sh.uv" -Name "uv"
Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"

Write-Step "Installing pnpm"
npm install -g pnpm

Write-Step "Installing VS Code Python extension"
code --install-extension ms-python.python --force

Write-Step "Fixing PowerShell execution policy for pnpm"
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

Write-Step "Fixing PATH"
Add-UserPath "C:\Program Files\Git\cmd"
Add-UserPath "C:\Program Files\nodejs"
Add-UserPath "$env:LOCALAPPDATA\Programs\Python\Python312"
Add-UserPath "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts"
Add-UserPath "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe"
Add-UserPath "C:\Program Files\Docker\Docker\resources\bin"

Write-Step "Verification"
Show-Version "Git" { git --version }
Show-Version "Node.js" { node --version }
Show-Version "npm" { npm --version }
Show-Version "pnpm" { pnpm --version }
Show-Version "Python 3.12" { & "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" --version }
Show-Version "pip" { & "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" -m pip --version }
Show-Version "uv" { uv --version }
Show-Version "VS Code" { code --version | Select-Object -First 1 }
Show-Version "GitHub CLI" { gh --version | Select-Object -First 1 }
Show-Version "Docker" { docker --version }
Show-Version "Docker Compose" { docker compose version }

Write-Step "Done"
Write-Host "AI/frontend development environment install script finished." -ForegroundColor Green
Write-Host "If Docker asks for WSL or restart on first launch, follow Docker Desktop prompts." -ForegroundColor Yellow
