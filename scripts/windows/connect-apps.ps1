<#
.SYNOPSIS
    Connect Jarvis (Hermes) to your apps: Google Workspace, Notion, Todoist, Zapier, GitHub, Canva, Strava, ElevenLabs.

.DESCRIPTION
    Run AFTER install-jarvis.ps1. Runs as your normal user. Interactive: it asks which apps you want.
    Everything is configured inside Hermes itself (config.yaml + .env), not through OpenMausBot's
    "Connected apps", because OpenMausBot has a known bug (PR #1875) that breaks its own per-turn
    tools for Hermes bots from the second message on. Servers configured inside Hermes are not affected.

    Secrets (tokens, client secrets) are typed into Hermes prompts or hidden prompts and stored ONLY in
    Hermes' .env / token folder. They are never written to this repo.

    config.yaml is backed up before any change.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\connect-apps.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Step([string]$Text) { Write-Host ''; Write-Host ('==> ' + $Text) -ForegroundColor Cyan }
function Write-Ok([string]$Text)   { Write-Host ('    [ok] ' + $Text) -ForegroundColor Green }
function Write-Warn2([string]$Text){ Write-Host ('    [!]  ' + $Text) -ForegroundColor Yellow }
function Write-Info([string]$Text) { Write-Host ('    ' + $Text) -ForegroundColor Gray }
function Pause-Enter([string]$Text) { [void](Read-Host ('    ' + $Text + ' (press Enter)')) }

function Confirm-Step([string]$Question, [bool]$DefaultYes = $true) {
    $suffix = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }
    $answer = Read-Host ('    ' + $Question + ' ' + $suffix)
    if ([string]::IsNullOrWhiteSpace($answer)) { return $DefaultYes }
    return ($answer.Trim().ToLower() -in @('y', 'yes'))
}

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (($machine, $user) | Where-Object { $_ }) -join ';'
}

function Test-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Read-Secret([string]$Prompt) {
    $secure = Read-Host ('    ' + $Prompt) -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Get-HermesValue([string[]]$HermesArgs) {
    # First non-empty stdout line of a hermes command. Native stderr must not become a terminating error in PS 5.1.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & hermes @HermesArgs 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }
        return ($out | Where-Object { $_.Trim() } | Select-Object -First 1)
    } finally { $ErrorActionPreference = $prev }
}

function Invoke-Hermes([string[]]$HermesArgs) {
    # Runs hermes interactively in this console. Returns the exit code.
    & hermes @HermesArgs
    return $LASTEXITCODE
}

# Adds KEY=value to Hermes' .env unless the key already exists. Returns $true if written.
function Add-EnvValue([string]$EnvFile, [string]$Key, [string]$Value) {
    $existing = ''
    if (Test-Path $EnvFile) { $existing = [System.IO.File]::ReadAllText($EnvFile) }
    if ($existing -match ('(?m)^\s*' + [regex]::Escape($Key) + '\s*=')) {
        Write-Warn2 ($Key + ' already exists in .env - left unchanged')
        return $false
    }
    $sep = ''
    if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) { $sep = "`r`n" }
    [System.IO.File]::AppendAllText($EnvFile, ($sep + $Key + '=' + $Value + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    return $true
}

# ----------------------------------------------------------------------------- preflight
Write-Step 'Preflight'
Update-SessionPath
if (-not (Test-Command 'hermes')) { throw 'hermes not found on PATH. Run install-jarvis.ps1 first, then open a NEW PowerShell window.' }
$ConfigPath = ([string](Get-HermesValue @('config', 'path'))).Trim()
$EnvPath    = ([string](Get-HermesValue @('config', 'env-path'))).Trim()
Write-Info ('config.yaml : ' + $ConfigPath)
Write-Info ('.env        : ' + $EnvPath)
if (-not $ConfigPath -or -not $EnvPath) { throw 'Could not read Hermes config paths. Run `hermes config path` yourself to see the error.' }
if (-not (Test-Path (Split-Path $ConfigPath -Parent))) { throw 'Hermes config folder does not exist yet. Run `hermes setup` once, then retry.' }
if (Test-Path $ConfigPath) {
    $backup = $ConfigPath + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item $ConfigPath $backup
    Write-Ok ('Backed up config.yaml -> ' + $backup)
}

# ----------------------------------------------------------------------------- menu
$catalog = @(
    @{ Id = 'google';     Name = 'Google Workspace: Gmail + Calendar + Drive + Docs + Sheets (needs a one-time Google Cloud OAuth client, ~15 min)' },
    @{ Id = 'notion';     Name = 'Notion (browser login)' },
    @{ Id = 'todoist';    Name = 'Todoist (browser login)' },
    @{ Id = 'zapier';     Name = 'Zapier MCP (token) - also reaches thousands of other apps' },
    @{ Id = 'github';     Name = 'GitHub (personal access token)' },
    @{ Id = 'canva';      Name = 'Canva (browser login)' },
    @{ Id = 'strava';     Name = 'Strava (browser login, needs a Strava subscription)' },
    @{ Id = 'elevenlabs'; Name = 'ElevenLabs (API key, via uvx)' }
)
Write-Step 'Which apps do you want to connect?'
for ($i = 0; $i -lt $catalog.Count; $i++) { Write-Host ('    ' + ($i + 1) + ') ' + $catalog[$i].Name) }
Write-Host '    a) all of the above'
$pick = Read-Host '    Enter numbers separated by commas (example: 1,2,3), or a'
$selected = @()
if ($pick.Trim().ToLower() -eq 'a') { $selected = $catalog | ForEach-Object { $_.Id } }
else {
    foreach ($tok in ($pick -split '[,\s]+' | Where-Object { $_ })) {
        $n = 0
        if ([int]::TryParse($tok, [ref]$n) -and $n -ge 1 -and $n -le $catalog.Count) { $selected += $catalog[$n - 1].Id }
    }
}
if ($selected.Count -eq 0) { Write-Warn2 'Nothing selected.'; return }

$results = @{}

# ----------------------------------------------------------------------------- services
function Connect-OAuthCatalog([string]$Name) {
    Write-Step ('Connect ' + $Name + ' (browser login)')
    Write-Info ('hermes mcp install ' + $Name)
    $code = Invoke-Hermes @('mcp', 'install', $Name)
    if ($code -ne 0) { throw ('hermes mcp install ' + $Name + ' failed (exit ' + $code + ')') }
    Write-Info 'A browser window will open. Approve access, then come back here.'
    $code = Invoke-Hermes @('mcp', 'login', $Name)
    if ($code -ne 0) { throw ('hermes mcp login ' + $Name + ' failed (exit ' + $code + ')') }
}

function Connect-HeaderServer([string]$Name, [string]$Url, [string]$TokenHelp) {
    Write-Step ('Connect ' + $Name + ' (token)')
    Write-Info $TokenHelp
    Write-Info 'Hermes will ask for the token and store it in its own .env (not shown here).'
    $code = Invoke-Hermes @('mcp', 'add', $Name, '--url', $Url, '--auth', 'header')
    if ($code -ne 0) { throw ('hermes mcp add ' + $Name + ' failed (exit ' + $code + ')') }
}

function Connect-Google {
    Write-Step 'Connect Google Workspace (Gmail, Calendar, Drive, Docs, Sheets)'
    Write-Info 'Uses the open-source "workspace-mcp" server with YOUR OWN Google Cloud OAuth client.'
    Write-Info 'Your data goes only between your PC and Google. Sign-in happens once in the browser.'

    # uv / uvx
    Update-SessionPath
    if (-not (Test-Command 'uvx')) {
        if (Test-Command 'winget') {
            Write-Info 'Installing uv (provides uvx) with winget...'
            & winget install --id astral-sh.uv -e --accept-source-agreements --accept-package-agreements
            Update-SessionPath
        }
        if (-not (Test-Command 'uvx')) {
            Write-Info 'Trying the official uv installer...'
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://astral.sh/uv/install.ps1 | iex'
            Update-SessionPath
            $fallback = Join-Path $env:USERPROFILE '.local\bin'
            if (Test-Path (Join-Path $fallback 'uvx.exe')) { $env:Path = $env:Path + ';' + $fallback }
        }
    }
    if (-not (Test-Command 'uvx')) { throw 'uvx not found. Install uv from https://docs.astral.sh/uv/ and run this script again.' }
    $uvx = (Get-Command uvx).Source
    Write-Ok ('uvx: ' + $uvx)

    Write-Host ''
    Write-Host '    --- Google Cloud Console (one time, about 10 minutes) ---' -ForegroundColor White
    Write-Host '    I will open each page for you. Use the SAME Google account you want Jarvis to read.'
    Pause-Enter '1/5  Create a project named "Jarvis"'
    Start-Process 'https://console.cloud.google.com/projectcreate'
    Pause-Enter '     Done? (make sure the new project is selected at the top)'
    Write-Info '2/5  Enable the 5 APIs (click Enable on each page if asked)'
    Start-Process 'https://console.cloud.google.com/flows/enableapi?apiid=gmail.googleapis.com,calendar-json.googleapis.com,drive.googleapis.com,docs.googleapis.com,sheets.googleapis.com'
    Pause-Enter '     Done? (Gmail, Calendar, Drive, Docs, Sheets APIs enabled)'
    Write-Info '3/5  Consent screen: Get started -> App name "Jarvis" -> Audience "External" -> your email -> Create'
    Start-Process 'https://console.cloud.google.com/auth/overview'
    Pause-Enter '     Done?'
    Write-Info '     Then Audience -> Test users -> Add users -> your own Gmail address -> Save.'
    Write-Info '     Optional but recommended: Publish app (Testing -> Production). Otherwise Google asks you to sign in again every 7 days.'
    Start-Process 'https://console.cloud.google.com/auth/audience'
    Pause-Enter '     Done?'
    Write-Info '4/5  Create the OAuth client: Application type = "Desktop app", name "Jarvis Hermes"'
    Start-Process 'https://console.cloud.google.com/auth/clients'
    Write-Host ''
    $clientId = (Read-Host '    Paste the Client ID (ends with .apps.googleusercontent.com)').Trim()
    $clientSecret = (Read-Secret 'Paste the Client secret (hidden)').Trim()
    $email = (Read-Host '    Your Google email address').Trim()
    if (-not $clientId -or -not $clientSecret -or -not $email) { throw 'Client ID, secret and email are all required.' }

    Write-Info '5/5  Saving to Hermes .env and config.yaml'
    if (-not (Test-Path $EnvPath)) { New-Item -ItemType File -Path $EnvPath -Force | Out-Null }
    [void](Add-EnvValue $EnvPath 'GOOGLE_OAUTH_CLIENT_ID' $clientId)
    [void](Add-EnvValue $EnvPath 'GOOGLE_OAUTH_CLIENT_SECRET' $clientSecret)
    [void](Add-EnvValue $EnvPath 'USER_GOOGLE_EMAIL' $email)
    $clientSecret = $null

    $block = @'
  google:
    command: '@@UVX@@'
    args:
      - "workspace-mcp@1.30.0"
      - "--single-user"
      - "--permissions"
      - "gmail:send"
      - "calendar:full"
      - "drive:full"
      - "docs:full"
      - "sheets:full"
      - "--tool-tier"
      - "extended"
    env:
      GOOGLE_OAUTH_CLIENT_ID: "${GOOGLE_OAUTH_CLIENT_ID}"
      GOOGLE_OAUTH_CLIENT_SECRET: "${GOOGLE_OAUTH_CLIENT_SECRET}"
      USER_GOOGLE_EMAIL: "${USER_GOOGLE_EMAIL}"
    connect_timeout: 120
    timeout: 180
    trust: untrusted
'@
    $block = $block.Replace('@@UVX@@', $uvx)
    Add-YamlServer 'google' $block

    Write-Info 'Pre-downloading workspace-mcp so Hermes starts fast...'
    & uvx 'workspace-mcp@1.30.0' --help | Out-Null
    Write-Host ''
    Write-Host '    FIRST SIGN-IN (once): run these two lines in this window when I finish:' -ForegroundColor White
    Write-Host '        hermes mcp test google'
    Write-Host '        hermes chat        then ask:  List my Google calendars and today''s events'
    Write-Host '    A browser opens -> choose your account -> "Google hasn''t verified this app" -> Advanced -> Go to Jarvis -> TICK EVERY permission -> Allow.' -ForegroundColor Gray
    Write-Host '    Safety: trust=untrusted means reads run freely, but sending mail / creating or editing events and files asks YOU first.' -ForegroundColor Gray
}

# Adds a server block under mcp_servers in config.yaml, or shows it for manual paste when that is not safe.
function Add-YamlServer([string]$Name, [string]$Block) {
    $yaml = ''
    if (Test-Path $ConfigPath) { $yaml = [System.IO.File]::ReadAllText($ConfigPath) }
    if ($yaml -match ('(?m)^  ' + [regex]::Escape($Name) + ':')) {
        Write-Warn2 ('config.yaml already has an "' + $Name + '" MCP server - left unchanged')
        return
    }
    if ($yaml -notmatch '(?m)^mcp_servers\s*:') {
        $prefix = ''
        if ($yaml.Length -gt 0 -and -not $yaml.EndsWith("`n")) { $prefix = "`r`n" }
        $text = $prefix + "`r`nmcp_servers:`r`n" + ($Block -replace "`r?`n", "`r`n") + "`r`n"
        [System.IO.File]::AppendAllText($ConfigPath, $text, (New-Object System.Text.UTF8Encoding($false)))
        Write-Ok ('Added "' + $Name + '" to config.yaml (new mcp_servers section)')
    } else {
        Write-Warn2 'config.yaml already has an mcp_servers section. To avoid breaking it, paste this block under it yourself:'
        Write-Host ''
        Write-Host $Block -ForegroundColor White
        Write-Host ''
        try { Set-Clipboard -Value $Block; Write-Info '(copied to your clipboard)' } catch { }
        Start-Process notepad.exe $ConfigPath
        Pause-Enter 'Paste it under mcp_servers:, save the file, then continue'
    }
    if ($yaml -match '(?m)^\s*platform_toolsets\s*:' ) {
        Write-Warn2 'Your config.yaml has platform_toolsets. If it lists an "acp:" entry, add this server there too, or Jarvis will not see it.'
    }
}

function Connect-ElevenLabs {
    Write-Step 'Connect ElevenLabs (voice / text-to-speech tools)'
    Update-SessionPath
    if (-not (Test-Command 'uvx')) { Write-Warn2 'uvx not found. Select Google Workspace first (it installs uv) or install uv, then retry.'; return }
    $uvx = (Get-Command uvx).Source
    Write-Info 'Create an API key at https://elevenlabs.io/app/settings/api-keys'
    Start-Process 'https://elevenlabs.io/app/settings/api-keys'
    $key = (Read-Secret 'Paste the ElevenLabs API key (hidden)').Trim()
    if (-not $key) { throw 'API key required.' }
    if (-not (Test-Path $EnvPath)) { New-Item -ItemType File -Path $EnvPath -Force | Out-Null }
    [void](Add-EnvValue $EnvPath 'ELEVENLABS_API_KEY' $key)
    $block = @'
  elevenlabs:
    command: '@@UVX@@'
    args: ["elevenlabs-mcp"]
    env:
      ELEVENLABS_API_KEY: "${ELEVENLABS_API_KEY}"
    timeout: 600
    connect_timeout: 180
'@
    Add-YamlServer 'elevenlabs' ($block.Replace('@@UVX@@', $uvx))
}

# ----------------------------------------------------------------------------- run selected
foreach ($id in $selected) {
    try {
        switch ($id) {
            'google'     { Connect-Google }
            'notion'     { Connect-OAuthCatalog 'notion' }
            'todoist'    { Connect-OAuthCatalog 'todoist' }
            'canva'      { Connect-OAuthCatalog 'canva' }
            'strava'     { Connect-OAuthCatalog 'strava' }
            'zapier'     { Connect-HeaderServer 'zapier' 'https://mcp.zapier.com/api/v1/connect' 'Token: https://mcp.zapier.com -> + Add MCP Server -> Other -> Connect tab -> Generate token (shown once). Add Gmail / Calendar / Drive actions there if you want them through Zapier.' }
            'github'     { Connect-HeaderServer 'github' 'https://api.githubcopilot.com/mcp/' 'Token: https://github.com/settings/personal-access-tokens/new (fine-grained; pick only the repos and permissions Jarvis may use).' }
            'elevenlabs' { Connect-ElevenLabs }
        }
        $results[$id] = 'ok'
    } catch {
        $results[$id] = 'FAILED: ' + $_.Exception.Message
        Write-Warn2 ($id + ' failed: ' + $_.Exception.Message)
    }
}

# ----------------------------------------------------------------------------- summary
Write-Step 'Summary'
foreach ($id in $selected) {
    if ($results[$id] -eq 'ok') { Write-Ok $id } else { Write-Warn2 ($id + ' -> ' + $results[$id]) }
}
Write-Host ''
Write-Info 'Check what Hermes sees:'
& hermes mcp list
Write-Host ''
Write-Host ' Next:' -ForegroundColor Green
Write-Host '  1. Test each server:   hermes mcp test <name>'
Write-Host '  2. Fully quit OpenMausBot (tray icon -> Quit) and open it again, so a fresh `hermes acp` loads the new servers.'
Write-Host '  3. In the Jarvis chat, ask: "What is on my calendar tomorrow?"  or  "list the tools you have"'
Write-Host ''
