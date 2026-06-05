$ErrorActionPreference = "Stop"
$Root = "C:\Users\88692\Desktop\Codex"
$WhiteList = @(
'Codex三方同步懶人包','Codex三方同步懶人包.zip',
'AI開發環境懶人包','AI開發環境懶人包.zip',
'Obsidian同步懶人包','Obsidian同步懶人包.zip',
'install-ai-dev-env.ps1','install-sync-task.ps1','README-sync.md','sync-all.ps1','sync-obsidian.ps1',
'保護白名單防誤刪.ps1','解除白名單防誤刪.ps1'
)
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$DeleteOnly = [System.Security.AccessControl.FileSystemRights]::Delete
$DeleteTree = [System.Security.AccessControl.FileSystemRights]::Delete -bor [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles
function Add-DenyDelete($Path, [bool]$Recursive) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $item = Get-Item -LiteralPath $Path -Force
    $acl = Get-Acl -LiteralPath $Path
    $inherit = [System.Security.AccessControl.InheritanceFlags]::None
    $rights = $DeleteOnly
    if ($Recursive -and $item.PSIsContainer) {
        $inherit = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        $rights = $DeleteTree
    }
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $rights, $inherit, [System.Security.AccessControl.PropagationFlags]::None, [System.Security.AccessControl.AccessControlType]::Deny)
    $acl.RemoveAccessRuleAll($rule) | Out-Null
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
    if (-not $item.PSIsContainer) { Set-ItemProperty -LiteralPath $Path -Name IsReadOnly -Value $true }
}
Add-DenyDelete $Root $false
foreach ($name in $WhiteList) { Add-DenyDelete (Join-Path $Root $name) $true }
Write-Host "完成：Codex 根目錄與白名單已設定防誤刪。"
