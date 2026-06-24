$ErrorActionPreference = "Stop"

$Root = "C:\Users\88692\Desktop\Codex"
$DriveRoot = "G:\" + (-join ([char[]](25105,30340,38642,31471,30828,30879)))
$DrivePath = Join-Path $DriveRoot "Nirvana_Studio"
$SyncScript = Join-Path $Root "sync-google-drive-github.ps1"
$LockFile = Join-Path $Root ".sync.lock"
$StateFile = Join-Path $Root ".sync.state"
$IntervalSeconds = 15

function Get-Fingerprint([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return ""
  }

  Get-ChildItem -LiteralPath $Path -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch "\\.git\\" -and $_.Name -notin @(".sync.lock", ".sync.state") } |
    Sort-Object FullName |
    ForEach-Object { "{0}|{1}|{2}" -f $_.FullName.Substring($Path.Length), $_.Length, $_.LastWriteTimeUtc.Ticks } |
    Out-String
}

function Get-CurrentState {
  $repo = Get-Fingerprint $Root
  $drive = Get-Fingerprint $DrivePath
  return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($repo + "`n---drive---`n" + $drive))
}

if (-not (Test-Path -LiteralPath $StateFile)) {
  Get-CurrentState | Set-Content -LiteralPath $StateFile -Encoding ASCII
}

while ($true) {
  try {
    $previous = Get-Content -LiteralPath $StateFile -Raw -ErrorAction SilentlyContinue
    $current = Get-CurrentState

    if ($current -ne $previous -and -not (Test-Path -LiteralPath $LockFile)) {
      New-Item -ItemType File -Path $LockFile -Force | Out-Null
      try {
        & $SyncScript
        Get-CurrentState | Set-Content -LiteralPath $StateFile -Encoding ASCII
      }
      finally {
        Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
      }
    }
  }
  catch {
    Write-Host ("sync failed: {0}" -f $_.Exception.Message)
  }

  Start-Sleep -Seconds $IntervalSeconds
}
