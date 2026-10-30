<#
fa_env.ps1 - the environment of the fuzzyalgo workspace, in one place.

    Terminal profile "fa" of fuzzyalgo.code-workspace:  powershell -NoExit -File fa_env.ps1 -Terminal
    fa.ps1 dot-sources it for every command (and restores the caller's environment afterwards).

Sets: PATH (+ fuzzyalgo\workspace), GH_HOST = github.com, clears GITHUB_TOKEN (an environment token may
belong to another host and gh would take it for github.com) and gives gh the github.com token of
<root>\.mcp.json (server with GITHUB_HOST github.com) as GH_TOKEN. Nothing is stored in Windows Credential
Manager; the token only lives in this process.
#>
param([switch]$Terminal)

& {
    $workspace = $PSScriptRoot
    $root = (Resolve-Path (Join-Path $workspace '..\..')).Path
    if (($env:PATH -split ';') -notcontains $workspace) { $env:PATH = "$workspace;$env:PATH" }
    $env:GH_HOST = 'github.com'
    Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
    $token = $null
    try {
        $token = (Get-Content (Join-Path $root '.mcp.json') -Raw -ErrorAction Stop | ConvertFrom-Json).mcpServers.PSObject.Properties |
            Where-Object { $_.Value.env -and $_.Value.env.GITHUB_PERSONAL_ACCESS_TOKEN -and "$($_.Value.env.GITHUB_HOST)" -match '^(https://)?github\.com/?$' } |
            ForEach-Object { $_.Value.env.GITHUB_PERSONAL_ACCESS_TOKEN } | Select-Object -First 1
    }
    catch { }
    if ($token) { $env:GH_TOKEN = $token }
    if ($Terminal) {
        $source = if ($token) { 'GH_TOKEN from .mcp.json' } else { 'no github.com token in .mcp.json: fa doctor' }
        Write-Host "fa terminal: fa help | gh -> $env:GH_HOST ($source)" -ForegroundColor DarkGray
    }
}
