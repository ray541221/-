$ErrorActionPreference = "Stop"

$Root = "C:\Users\88692\Desktop\Codex"
$SyncScript = Join-Path $Root "sync-google-drive-github.ps1"
$LockFile = Join-Path $Root ".sync.lock"
$IntervalSeconds = 15

while ($true) {
  try {
    if (-not (Test-Path -LiteralPath $LockFile)) {
      New-Item -ItemType File -Path $LockFile -Force | Out-Null
      try {
        & $SyncScript
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
