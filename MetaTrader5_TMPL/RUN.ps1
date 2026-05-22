[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsList
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Usage {
    Write-Host "Usage:"
    Write-Host "  .\RUN.ps1 --login=LOGINNUMBER --password=PASSWORD [--profile=PROFILE_NAME] [--server=SERVER]"
}

# ------------------------------------------------------------
# Parse command line arguments
# ------------------------------------------------------------
$login = $null
$password = $null
$profile = $null
$server = $null

foreach ($arg in $ArgsList) {
    switch -Regex ($arg) {
        '^--login=(.+)$' {
            $login = $Matches[1]
            continue
        }

        '^--password=(.+)$' {
            $password = $Matches[1]
            continue
        }

        '^--profile=(.+)$' {
            $profile = $Matches[1]
            continue
        }

        '^--server=(.+)$' {
            $server = $Matches[1]
            continue
        }

        default {
            Write-Error "Unknown argument: $arg"
            Write-Usage
            exit 1
        }
    }
}

if ([string]::IsNullOrWhiteSpace($login)) {
    Write-Error "Missing mandatory argument: --login=LOGINNUMBER"
    Write-Usage
    exit 2
}

if ([string]::IsNullOrWhiteSpace($password)) {
    Write-Error "Missing mandatory argument: --password=PASSWORD"
    Write-Usage
    exit 3
}

if ([string]::IsNullOrWhiteSpace($profile)) {
    $profile = 'Default'
}

if ([string]::IsNullOrWhiteSpace($server)) {
    $server = 'RoboForex-ECN'
}

# ------------------------------------------------------------
# Resolve paths
# ------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$terminalExePath = Join-Path $scriptDir 'terminal64.exe'
$terminalZipPath = Join-Path $scriptDir 'terminal64.zip'

$configDir = Join-Path $scriptDir 'config'
$configPath = Join-Path $configDir 'common.ini'
$configServersDatPath = Join-Path $configDir 'servers.dat'

$serverConfigDirName = "config_$server"
$serverConfigDir = Join-Path $scriptDir $serverConfigDirName
$serverServersDatPath = Join-Path $serverConfigDir 'servers.dat'

# ------------------------------------------------------------
# Ensure terminal64.exe exists
# If missing, unpack ./terminal64.zip
# ------------------------------------------------------------
if (-not (Test-Path -LiteralPath $terminalExePath)) {
    if (-not (Test-Path -LiteralPath $terminalZipPath)) {
        Write-Error "terminal64.exe does not exist and terminal64.zip was not found: $terminalZipPath"
        exit 4
    }

    try {
        Expand-Archive -LiteralPath $terminalZipPath -DestinationPath $scriptDir -Force
    }
    catch {
        Write-Error "Failed to unpack terminal64.zip. $($_.Exception.Message)"
        exit 5
    }

    if (-not (Test-Path -LiteralPath $terminalExePath)) {
        Write-Error "terminal64.exe was not found after unpacking terminal64.zip"
        exit 6
    }
}

# ------------------------------------------------------------
# Embedded config template
# ------------------------------------------------------------
$configTemplate = @'
;https://www.metatrader5.com/en/terminal/help/start_advanced/start
[Common]
Login=%LOGINNUMBER%
Server=%SERVER%
Password=%PASSWORD%
KeepPrivate=1
NewsEnable=1
;CertInstall=1
;CertPassword=10
;ProxyEnable=0
;ProxyType=0
;ProxyAddress=192.168.0.1:3128
;ProxyLogin=10
;ProxyPassword=10
 
[Charts]
ProfileLast=%PROFILE_NAME%
MaxBars=5000
PrintColor=1
SaveDeleted=1

[Experts]
AllowLiveTrading=1
AllowDllImport=1
Enabled=1
Account=0
Profile=0
'@

# ------------------------------------------------------------
# Ensure ./config directory exists
# ------------------------------------------------------------
try {
    if (-not (Test-Path -LiteralPath $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
}
catch {
    Write-Error "Failed to create config directory: $configDir. $($_.Exception.Message)"
    exit 7
}

# ------------------------------------------------------------
# Create ./config/common.ini every time
# Replace %LOGINNUMBER%, %PASSWORD%, %PROFILE_NAME%, %SERVER%
# ------------------------------------------------------------
try {
    $configContent = $configTemplate.Replace('%LOGINNUMBER%', $login)
    $configContent = $configContent.Replace('%PASSWORD%', $password)
    $configContent = $configContent.Replace('%PROFILE_NAME%', $profile)
    $configContent = $configContent.Replace('%SERVER%', $server)

    Set-Content -LiteralPath $configPath -Value $configContent -Encoding UTF8
}
catch {
    Write-Error "Failed to create config file: $configPath. $($_.Exception.Message)"
    exit 8
}

# ------------------------------------------------------------
# Copy server-specific servers.dat if available
#
# Example:
#   ./config_RoboForex-ECN/servers.dat
#
# Copy to:
#   ./config/servers.dat
#
# Only copy if ./config/servers.dat does not already exist.
# ------------------------------------------------------------
try {
    if (
        (Test-Path -LiteralPath $serverServersDatPath) -and
        (-not (Test-Path -LiteralPath $configServersDatPath))
    ) {
        Copy-Item `
            -LiteralPath $serverServersDatPath `
            -Destination $configServersDatPath `
            -Force
    }
}
catch {
    Write-Error "Failed to copy servers.dat from '$serverServersDatPath' to '$configServersDatPath'. $($_.Exception.Message)"
    exit 9
}

# ------------------------------------------------------------
# Build terminal64.exe arguments
# ------------------------------------------------------------
$terminalArgs = @(
    '/portable'
    "/login:$login"
    "/profile:$profile"
    "/config:$configPath"
)

# ------------------------------------------------------------
# Start terminal64.exe, check startup error and exit
# ------------------------------------------------------------
try {
    & $terminalExePath @terminalArgs

    $exitCode = $LASTEXITCODE

    if ($null -eq $exitCode) {
        $exitCode = 0
    }

    if ($exitCode -ne 0) {
        Write-Error "terminal64.exe exited with code $exitCode"
    }

    exit $exitCode
}
catch {
    Write-Error "Failed to start terminal64.exe. $($_.Exception.Message)"
    exit 10
}