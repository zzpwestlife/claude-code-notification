<# : batch script
@echo off
setlocal
cd %~dp0
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression ($(Get-Content '%~f0' | Out-String))"
goto :EOF
#>

# ==========================================
# Claude Code Notification Quick Install Script (Windows)
# ==========================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------

function Show-Message {
    param (
        [string]$Title,
        [string]$Message,
        [string]$Icon = "Information"
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::$Icon)
}

function Get-Input {
    param (
        [string]$Title,
        [string]$Prompt,
        [string]$DefaultValue = "",
        [string]$Regex = "",
        [string]$ErrorMessage = "Invalid Input"
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(800, 200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(760, 20)
    $label.Text = $Prompt
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 50)
    $textBox.Size = New-Object System.Drawing.Size(760, 20)
    $textBox.Text = $DefaultValue
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(610, 100)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = "确定"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(695, 100)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = "取消"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    while ($true) {
        $result = $form.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
            return $null
        }
        
        $inputVal = $textBox.Text
        if (-not [string]::IsNullOrEmpty($Regex)) {
            if ($inputVal -match $Regex) {
                return $inputVal
            } else {
                Show-Message -Title "错误" -Message $ErrorMessage -Icon "Error"
            }
        } else {
            return $inputVal
        }
    }
}

function Select-Folder {
    param([string]$Description)
    
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    
    # Try to set initial path to user profile
    if (Test-Path "$env:USERPROFILE\code") {
        $dialog.SelectedPath = "$env:USERPROFILE\code"
    } else {
        $dialog.SelectedPath = "$env:USERPROFILE"
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

# ---------------------------------------------------------
# Main Logic
# ---------------------------------------------------------

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\install_quick.log"

function Log-Write {
    param([string]$Message, [string]$Level="INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry
}

try {
    Log-Write "开始安装..."

    # Check Dependencies
    $missing = @()
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $missing += "git" }
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { $missing += "node" }
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { $missing += "npm" }

    if ($missing.Count -gt 0) {
        Show-Message -Title "缺少依赖" -Message "缺少工具: $($missing -join ', ')。请先安装它们。" -Icon "Error"
        exit 1
    }

    $RepoUrl = "https://github.com/zzpwestlife/claude-code-notification.git"

    # Inputs
    $TargetDir = Get-Input -Title "配置" -Prompt "安装目录:" -DefaultValue "$env:USERPROFILE\code\claude-code-notification"
    if ([string]::IsNullOrEmpty($TargetDir)) { exit 0 }

    # Webhook Clipboard Detection
    $DefaultWebhook = ""
    try {
        $Clipboard = Get-Clipboard -Raw -ErrorAction SilentlyContinue
        if ($Clipboard -match "^https://open.feishu.cn/open-apis/bot/v2/hook/.*$") {
            $Clipboard = $Clipboard.Trim()
            $Confirm = [System.Windows.Forms.MessageBox]::Show("检测到剪贴板包含飞书 Webhook 地址：`n`n$Clipboard`n`n是否直接使用？", "配置", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($Confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                $WebhookUrl = $Clipboard
            } else {
                $DefaultWebhook = $Clipboard
            }
        }
    } catch {
        # Ignore clipboard errors
    }

    if ([string]::IsNullOrEmpty($WebhookUrl)) {
        $WebhookUrl = Get-Input -Title "配置" -Prompt "请输入飞书 Webhook 地址 (已自动尝试读取剪贴板):" -DefaultValue $DefaultWebhook -Regex "^https://open.feishu.cn/open-apis/bot/v2/hook/.*$" -ErrorMessage "无效的 URL。必须以 https://open.feishu.cn/open-apis/bot/v2/hook/ 开头"
        if ([string]::IsNullOrEmpty($WebhookUrl)) { exit 0 }
    }

    # Installation
    if (-not (Test-Path $TargetDir)) {
        Log-Write "正在克隆仓库..."
        New-Item -ItemType Directory -Force -Path (Split-Path $TargetDir) | Out-Null
        git clone $RepoUrl $TargetDir
    } else {
        Log-Write "正在更新仓库..."
        Set-Location $TargetDir
        git stash
        git pull
        git stash pop
    }

    Set-Location $TargetDir
    Log-Write "正在安装依赖..."
    npm install

    # Write Config
    Log-Write "正在写入配置..."
    $EnvContent = "FEISHU_WEBHOOK_URL=$WebhookUrl"
    Set-Content -Path "$TargetDir\.env" -Value $EnvContent

    # Update Settings
    $SettingsFile = "$env:USERPROFILE\.claude\settings.json"
    $NodePath = (Get-Command node).Source
    # Escape backslashes for JSON
    $NodePathJson = $NodePath -replace "\\", "\\"
    $ScriptPathJson = "$TargetDir\src\index.js" -replace "\\", "\\"

    if (-not (Test-Path $SettingsFile)) {
        New-Item -ItemType File -Force -Path $SettingsFile -Value "{ ""hooks"": {} }" | Out-Null
    }

    # Use a small JS script to update JSON (reliable cross-platform)
    $UpdateScript = @"
const fs = require('fs');
const path = '$($SettingsFile -replace "\\", "\\\\")';
try {
    const settings = JSON.parse(fs.readFileSync(path, 'utf8'));
    if (!settings.hooks) settings.hooks = {};
    
    const stopHook = {
        ""hooks"": [{
            ""command"": ""node $ScriptPathJson"",
            ""type"": ""command""
        }]
    };
    
    // Merge logic same as bash...
    if (!settings.hooks.Stop) settings.hooks.Stop = [];
    settings.hooks.Stop = settings.hooks.Stop.filter(h => !JSON.stringify(h).includes('claude-code-notification'));
    settings.hooks.Stop.push(stopHook);

    fs.writeFileSync(path, JSON.stringify(settings, null, 2));
} catch (e) {
    console.error(e);
    process.exit(1);
}
"@
    Set-Content -Path "$TargetDir\update_settings.js" -Value $UpdateScript
    node "$TargetDir\update_settings.js"
    Remove-Item "$TargetDir\update_settings.js"

    Show-Message -Title "成功" -Message "安装完成！"
    Log-Write "安装成功。"

} catch {
    Log-Write "Error: $_" "ERROR"
    Show-Message -Title "错误" -Message "安装失败。请查看日志了解详情。`n$_" -Icon "Error"
    exit 1
}
