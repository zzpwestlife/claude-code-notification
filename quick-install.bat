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
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(360, 20)
    $label.Text = $Prompt
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 50)
    $textBox.Size = New-Object System.Drawing.Size(360, 20)
    $textBox.Text = $DefaultValue
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(210, 100)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(295, 100)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = "Cancel"
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
                Show-Message -Title "Error" -Message $ErrorMessage -Icon "Error"
            }
        } else {
            return $inputVal
        }
    }
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
    Log-Write "Starting installation..."

    # Check Dependencies
    $missing = @()
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $missing += "git" }
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { $missing += "node" }
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { $missing += "npm" }

    if ($missing.Count -gt 0) {
        Show-Message -Title "Missing Dependencies" -Message "Missing tools: $($missing -join ', '). Please install them first." -Icon "Error"
        exit 1
    }

    Show-Message -Title "Welcome" -Message "Welcome to Claude Code Notification Setup!"

    # Inputs
    $TargetDir = Get-Input -Title "Configuration" -Prompt "Installation Directory:" -DefaultValue "$env:USERPROFILE\code\claude-code-notification"
    if ([string]::IsNullOrEmpty($TargetDir)) { exit 0 }

    $WebhookUrl = Get-Input -Title "Configuration" -Prompt "Enter Feishu Webhook URL:" -Regex "^https://open.feishu.cn/open-apis/bot/v2/hook/.*$" -ErrorMessage "Invalid URL. Must start with https://open.feishu.cn/open-apis/bot/v2/hook/"
    if ([string]::IsNullOrEmpty($WebhookUrl)) { exit 0 }

    # Installation
    if (-not (Test-Path $TargetDir)) {
        Log-Write "Cloning repository..."
        New-Item -ItemType Directory -Force -Path (Split-Path $TargetDir) | Out-Null
        git clone $RepoUrl $TargetDir
    } else {
        Log-Write "Updating repository..."
        Set-Location $TargetDir
        git pull
    }

    Set-Location $TargetDir
    Log-Write "Installing dependencies..."
    npm install

    # Write Config
    Log-Write "Writing configuration..."
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

    Show-Message -Title "Success" -Message "Installation Complete!"
    Log-Write "Installation successful."

} catch {
    Log-Write "Error: $_" "ERROR"
    Show-Message -Title "Error" -Message "Installation failed. Check log for details.`n$_" -Icon "Error"
    exit 1
}
