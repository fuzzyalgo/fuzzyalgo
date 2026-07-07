<#
.SYNOPSIS
    Starts terminal64.exe with an existing or generated MetaTrader config.

.DESCRIPTION
    Directory structure:

        ./RUN.ps1
        ./terminal64.zip
        ./terminal64.exe
        ./config/common.ini
        ./config/servers.dat
        ./config_<SERVER>/servers.dat
        ./MQL5/Profiles/Charts/<PROFILE>

    Behavior:

    - --help prints usage information and exits.

    - --list-server lists all available servers by scanning directories named:
        ./config_<SERVER>

    - --list-profile lists all available profiles by scanning directories below:
        ./MQL5/Profiles/Charts

    - If ./terminal64.exe does not exist, it is extracted from ./terminal64.zip.

    - If ./config/common.ini exists:
        - No arguments are required.
        - Existing ./config/common.ini is reused unless --password is provided.
        - --login is optional and, if provided, is passed to terminal64.exe.
        - --profile is optional and defaults to "Default".
        - --password together with --login recreates ./config/common.ini.
        - --server is only used when recreating ./config/common.ini.

    - If ./config/common.ini does not exist:
        - --login and --password are mandatory.
        - Optional --profile defaults to "Default".
        - Optional --server defaults to "RoboForex-ECN".
        - ./config/common.ini is created.

    - When ./config/common.ini is created or recreated:
        - Template placeholders are replaced:
            %LOGINNUMBER%
            %PASSWORD%
            %PROFILE_NAME%
            %SERVER%

        - If ./config_<SERVER>/servers.dat exists, it is copied to:
            ./config/servers.dat

        - Existing ./config/servers.dat is overwritten.

    - Starts terminal64.exe.

.USAGE
    Show help:

        .\RUN.ps1 --help

    List available servers:

        .\RUN.ps1 --list-server

    List available profiles:

        .\RUN.ps1 --list-profile

    Use existing config:

        .\RUN.ps1
        .\RUN.ps1 --login=LOGINNUMBER
        .\RUN.ps1 --profile=PROFILE_NAME
        .\RUN.ps1 --login=LOGINNUMBER --profile=PROFILE_NAME

    Create or recreate config:

        .\RUN.ps1 --login=LOGINNUMBER --password=PASSWORD [--profile=PROFILE_NAME] [--server=SERVER]

.EXAMPLES
    Show help:

        .\RUN.ps1 --help

    List available servers:

        .\RUN.ps1 --list-server

    List available profiles:

        .\RUN.ps1 --list-profile

    Use existing config with default profile:

        .\RUN.ps1

    Use existing config with login override:

        .\RUN.ps1 --login=123456789

    Use existing config with custom profile:

        .\RUN.ps1 --profile=MyProfile

    Use existing config with login and custom profile:

        .\RUN.ps1 --login=123456789 --profile=MyProfile

    Create or recreate config with default profile and default server:

        .\RUN.ps1 --login=123456789 --password=MyPassword

    Create or recreate config with custom server:

        .\RUN.ps1 --login=123456789 --password=MyPassword --server=MyServer

    Create or recreate config with custom server and custom profile:

        .\RUN.ps1 --login=123456789 --password=MyPassword --server=MyServer --profile=MyProfile

.FULL TERMINAL COMMAND
    Existing config, no login:

        terminal64.exe /portable /profile:Default /config:.\config\common.ini

    Existing config, with login:

        terminal64.exe /portable /login:123456789 /profile:Default /config:.\config\common.ini

    Existing config, with custom profile:

        terminal64.exe /portable /profile:MyProfile /config:.\config\common.ini

    Existing config, with login and custom profile:

        terminal64.exe /portable /login:123456789 /profile:MyProfile /config:.\config\common.ini

    Generated config:

        terminal64.exe /portable /login:123456789 /profile:Default /config:.\config\common.ini
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsList
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Usage {
    Write-Host "Usage:"
    Write-Host ""
    Write-Host "  Show help:"
    Write-Host "    .\RUN.ps1 --help"
    Write-Host ""
    Write-Host "  List available servers:"
    Write-Host "    .\RUN.ps1 --list-server"
    Write-Host ""
    Write-Host "  List available profiles:"
    Write-Host "    .\RUN.ps1 --list-profile"
    Write-Host ""
    Write-Host "  Use existing config:"
    Write-Host "    .\RUN.ps1"
    Write-Host "    .\RUN.ps1 --login=LOGINNUMBER"
    Write-Host "    .\RUN.ps1 --profile=PROFILE_NAME"
    Write-Host "    .\RUN.ps1 --login=LOGINNUMBER --profile=PROFILE_NAME"
    Write-Host ""
    Write-Host "  Create or recreate config:"
    Write-Host "    .\RUN.ps1 --login=LOGINNUMBER --password=PASSWORD [--profile=PROFILE_NAME] [--server=SERVER]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\RUN.ps1 --help"
    Write-Host "  .\RUN.ps1 --list-server"
    Write-Host "  .\RUN.ps1 --list-profile"
    Write-Host "  .\RUN.ps1"
    Write-Host "  .\RUN.ps1 --login=123456789"
    Write-Host "  .\RUN.ps1 --profile=MyProfile"
    Write-Host "  .\RUN.ps1 --login=123456789 --profile=MyProfile"
    Write-Host "  .\RUN.ps1 --login=123456789 --password=MyPassword"
    Write-Host "  .\RUN.ps1 --login=123456789 --password=MyPassword --server=MyServer"
    Write-Host "  .\RUN.ps1 --login=123456789 --password=MyPassword --server=MyServer --profile=MyProfile"
}

# ------------------------------------------------------------
# Parse command line arguments
# ------------------------------------------------------------
$login = $null
$password = $null
$profile = $null
$server = $null
$listServer = $false
$listProfile = $false
$showHelp = $false

foreach ($arg in $ArgsList) {
    switch -Regex ($arg) {
        '^--help$' {
            $showHelp = $true
            continue
        }

        '^--list-server$' {
            $listServer = $true
            continue
        }

        '^--list-profile$' {
            $listProfile = $true
            continue
        }

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

# ------------------------------------------------------------
# Resolve paths
# ------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$terminalExePath = Join-Path $scriptDir 'terminal64.exe'
$terminalZipPath = Join-Path $scriptDir 'terminal64.zip'

$configDir = Join-Path $scriptDir 'config'
$configPath = Join-Path $configDir 'common.ini'
$configServersDatPath = Join-Path $configDir 'servers.dat'

# ------------------------------------------------------------
# Show help and exit
# ------------------------------------------------------------
if ($showHelp) {
    Write-Usage
    exit 0
}

# ------------------------------------------------------------
# List available servers and exit
#
# Finds directories:
#   ./config_<SERVER>
#
# Prints:
#   <SERVER>
# ------------------------------------------------------------
if ($listServer) {
    try {
        $prefix = 'config_'

        $servers = Get-ChildItem `
                -LiteralPath $scriptDir `
                -Directory `
                -Filter "$prefix*" `
                -ErrorAction SilentlyContinue |
            ForEach-Object {
                $_.Name.Substring($prefix.Length)
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Sort-Object -Unique

        foreach ($serverName in $servers) {
            Write-Host $serverName
        }

        exit 0
    }
    catch {
        Write-Error "Failed to list server directories. $($_.Exception.Message)"
        exit 12
    }
}

# ------------------------------------------------------------
# List available profiles and exit
#
# Finds directories below:
#   ./MQL5/Profiles/Charts
#
# Prints:
#   <PROFILE_NAME>
# ------------------------------------------------------------
if ($listProfile) {
    try {
        $chartsDir = Join-Path $scriptDir 'MQL5\Profiles\Charts'

        if (-not (Test-Path -LiteralPath $chartsDir)) {
            exit 0
        }

        $profiles = Get-ChildItem `
                -LiteralPath $chartsDir `
                -Directory `
                -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Sort-Object -Unique

        foreach ($profileName in $profiles) {
            Write-Host $profileName
        }

        exit 0
    }
    catch {
        Write-Error "Failed to list profile directories. $($_.Exception.Message)"
        exit 13
    }
}

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($profile)) {
    $profile = 'Default'
}

if ([string]::IsNullOrWhiteSpace($server)) {
    $server = 'RoboForex-ECN'
}

$configExists = Test-Path -LiteralPath $configPath

# ------------------------------------------------------------
# Decide whether common.ini must be created/recreated
#
# Rules:
#   - If common.ini does not exist, generate it.
#   - If common.ini exists and --password is provided, regenerate it.
#   - If common.ini exists and --password is not provided, reuse it.
# ------------------------------------------------------------
$generateConfig = $false

if (-not $configExists) {
    $generateConfig = $true
}
elseif (-not [string]::IsNullOrWhiteSpace($password)) {
    $generateConfig = $true
}

# ------------------------------------------------------------
# Validate arguments
# ------------------------------------------------------------

# If config must be generated, login and password are mandatory.
if ($generateConfig) {
    if ([string]::IsNullOrWhiteSpace($login)) {
        Write-Error "Missing mandatory argument: --login=LOGINNUMBER. It is required when creating or recreating ./config/common.ini."
        Write-Usage
        exit 2
    }

    if ([string]::IsNullOrWhiteSpace($password)) {
        Write-Error "Missing mandatory argument: --password=PASSWORD. It is required because ./config/common.ini does not exist."
        Write-Usage
        exit 3
    }
}

# If password is provided, login must also be provided.
if (
    (-not [string]::IsNullOrWhiteSpace($password)) -and
    [string]::IsNullOrWhiteSpace($login)
) {
    Write-Error "Argument --password requires --login."
    Write-Usage
    exit 10
}

# If server is provided while not generating config, it has no useful effect.
if (
    (-not $generateConfig) -and
    ($ArgsList -match '^--server=')
) {
    Write-Error "Argument --server can only be used together with --login and --password, because it is written into ./config/common.ini."
    Write-Usage
    exit 11
}

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
# Create or recreate ./config/common.ini when needed
# ------------------------------------------------------------
if ($generateConfig) {
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
    # Copy server-specific servers.dat when generating config
    #
    # Source:
    #   ./config_<SERVER>/servers.dat
    #
    # Destination:
    #   ./config/servers.dat
    #
    # If destination exists, overwrite it.
    # ------------------------------------------------------------
    try {
        $serverConfigDirName = "config_$server"
        $serverConfigDir = Join-Path $scriptDir $serverConfigDirName
        $serverServersDatPath = Join-Path $serverConfigDir 'servers.dat'

        if (Test-Path -LiteralPath $serverServersDatPath) {
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
}
else {
    Write-Host "Using existing config file:"
    Write-Host "  $configPath"
}

# ------------------------------------------------------------
# Build terminal64.exe arguments
# ------------------------------------------------------------
$terminalArgs = @(
    '/portable'
)

# /login is only passed if --login was supplied.
if (-not [string]::IsNullOrWhiteSpace($login)) {
    $terminalArgs += "/login:$login"
}

# /profile is always passed.
# If --profile was not supplied, it defaults to Default.
$terminalArgs += "/profile:$profile"

# /config is always passed.
$terminalArgs += "/config:$configPath"

# Show the exact command being executed
Write-Host "Starting terminal:"
Write-Host "`"$terminalExePath`" $($terminalArgs -join ' ')"

# ------------------------------------------------------------
# Start terminal64.exe
# ------------------------------------------------------------
try {
    Start-Process -FilePath $terminalExePath -ArgumentList $terminalArgs

    # We started the GUI and are not waiting for it, so return success.
    exit 0
}
catch {
    Write-Error "Failed to start terminal64.exe. $($_.Exception.Message)"
    exit 255
}
