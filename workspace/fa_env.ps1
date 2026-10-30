<#
fa_env.ps1 - the environment of the fuzzyalgo workspace, in one place.

    Terminal profile "fa" of fuzzyalgo.code-workspace:  powershell -NoExit -ExecutionPolicy Bypass -File fa_env.ps1 -Terminal
    fa.ps1, at the start of every command:               $token = & fa_env.ps1 -PassThru

Sets PATH (+ fuzzyalgo\workspace), GH_HOST = github.com and GH_CONFIG_DIR = <root>\.gh, and clears GITHUB_TOKEN
(an environment token may belong to another host, and gh would take it for github.com). <root>\.gh is gh's own
folder for this workspace, created when missing: gh there sees none of the other logins and settings of this
Windows user (%APPDATA%\GitHub CLI, e.g. another GitHub host), only the token below. The github.com token of
<root>\.mcp.json - the
GITHUB_PERSONAL_ACCESS_TOKEN of a server whose GITHUB_HOST is github.com or missing, ${VAR} expanded the way
Claude Code does it - is
  -Terminal  the GH_TOKEN of the terminal (every program started there inherits it), plus one grey line;
  -PassThru  returned, for gh only; the caller's GH_TOKEN is removed until fa ends (fa.ps1 restores it).
Nothing is stored in Windows Credential Manager.
#>
param([switch]$Terminal, [switch]$PassThru)

& {
    Set-StrictMode -Off
    $PSDefaultParameterValues = @{}    # e.g. a profile's '*:ErrorAction'; only in this block
    $InformationPreference = 'SilentlyContinue'    # with Stop (a profile) Write-Host throws after printing
    $workspace = $PSScriptRoot
    $root = (Resolve-Path -LiteralPath (Join-Path $workspace '..\..')).ProviderPath
    # a JSON property by its exact name
    function prop($o, [string]$name) {
        if ($o -is [System.Management.Automation.PSCustomObject]) { $p = $o.PSObject.Properties[$name]; if ($p -and $p.Name -ceq $name) { , $p.Value } }
    }
    # ${VAR} / ${VAR:-default}; $null when a variable without default is not set (Claude Code would pass it on as written)
    function expand([string]$text) {
        $out = ''; $last = 0
        foreach ($m in [regex]::Matches($text, '\$\{([A-Za-z_][A-Za-z0-9_]*)(:-[^}]*)?\}')) {
            $value = [Environment]::GetEnvironmentVariable($m.Groups[1].Value)
            if ($null -eq $value) {
                if (-not $m.Groups[2].Success) { return $null }
                $value = $m.Groups[2].Value.Substring(2)
            }
            $out += $text.Substring($last, $m.Index - $last) + $value
            $last = $m.Index + $m.Length
        }
        $out + $text.Substring($last)
    }
    # first, while the environment is still the caller's (${GITHUB_TOKEN} in .mcp.json = the caller's one)
    $token = $null
    try {
        $servers = prop ([IO.File]::ReadAllText((Join-Path $root '.mcp.json')) | ConvertFrom-Json) 'mcpServers'
        foreach ($s in @(if ($servers -is [System.Management.Automation.PSCustomObject]) { $servers.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } })) {
            $type = prop $s.Value 'type'
            if ($null -ne $type -and $type -cne 'stdio') { continue }
            $e = prop $s.Value 'env'
            if ($e -isnot [System.Management.Automation.PSCustomObject]) { continue }
            $t = $e.PSObject.Properties['GITHUB_PERSONAL_ACCESS_TOKEN']; $h = $e.PSObject.Properties['GITHUB_HOST']
            if (-not $t -or $t.Value -isnot [string]) { continue }
            $value = expand $t.Value
            $ghHost = if ($h) { if ($h.Value -is [string]) { expand $h.Value } else { $null } } else { '' }
            if ($value -and $null -ne $ghHost -and $ghHost -match '^((https?://)?([\w-]+\.)*github\.com(:\d+)?/?)?$') { $token = $value; break }
        }
    }
    catch { }
    $path = [Environment]::GetEnvironmentVariable('PATH')
    if (@("$path".Split(';') | ForEach-Object { $_.TrimEnd('\') }) -notcontains $workspace.TrimEnd('\')) { [Environment]::SetEnvironmentVariable('PATH', "$workspace;$path") }
    if ([Environment]::GetEnvironmentVariable('GH_HOST') -cne 'github.com') { [Environment]::SetEnvironmentVariable('GH_HOST', 'github.com') }
    if ([Environment]::GetEnvironmentVariable('GITHUB_TOKEN')) { [Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $null) }
    $ghConfig = Join-Path $root '.gh'
    if (-not [IO.Directory]::Exists($ghConfig)) { try { [void][IO.Directory]::CreateDirectory($ghConfig) } catch { } }
    if ([Environment]::GetEnvironmentVariable('GH_CONFIG_DIR') -cne $ghConfig) { [Environment]::SetEnvironmentVariable('GH_CONFIG_DIR', $ghConfig) }
    if ($PassThru) {
        if ([Environment]::GetEnvironmentVariable('GH_TOKEN')) { [Environment]::SetEnvironmentVariable('GH_TOKEN', $null) }
        return $token
    }
    if ($token) { [Environment]::SetEnvironmentVariable('GH_TOKEN', $token) }
    if ($Terminal) {
        $source = if ($token) { 'GH_TOKEN from .mcp.json' } else { 'no github.com token in .mcp.json: fa doctor' }
        Write-Host "fa terminal: fa help | gh -> github.com ($source)" -ForegroundColor DarkGray
    }
}
