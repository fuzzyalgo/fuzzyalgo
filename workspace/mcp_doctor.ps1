<#
mcp_doctor.ps1 - connection checks of "fa doctor", dot-sourced by fa.ps1.

Checks every server of <root>\.mcp.json with the credentials written there, the way the MCP client uses them:
  http   MCP initialize + one cheap tool call. Some servers answer initialize without a valid key, so only
         the tool call proves the key ($McpProbes); servers without a known call are reported as unverified.
  stdio  started with its command, args and env; it has to answer initialize within $McpStartSeconds.
         A known server program also has to answer one tool call ($McpStdioProbes). A GITHUB_PERSONAL_ACCESS_TOKEN
         in its env is checked against the REST API too (login, scopes, expiry: a warning $McpExpiryWarnDays days
         before a token expires).
Secrets never reach a command line or the console: curl reads them from a header file in a private temp
directory that is deleted afterwards. Needs the host functions Ok, Todo, Warn and $script:ShowCmd.
#>

$McpExpiryWarnDays = 14
$McpStartSeconds = 20
$McpCurl = Join-Path $env:SystemRoot 'System32\curl.exe'    # not "curl": in Windows PowerShell 5.1 that is Invoke-WebRequest

# A tool per http server that only works with a valid key (initialize is answered without one).
$McpProbes = @{
    'mcp.context7.com' = @{ name = 'resolve-library-id'; arguments = @{ libraryName = 'pytest'; query = 'pytest' } }
}
$McpCurlErrors = @{ 6 = 'host not found'; 7 = 'cannot connect'; 28 = 'timeout'; 35 = 'TLS handshake failed'; 60 = 'certificate not trusted' }
$McpInitialize = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"doctor","version":"1"}}}'

function McpProp($o, [string]$name) { if ($o -and $o.PSObject.Properties[$name]) { $o.PSObject.Properties[$name].Value } }

function Read-McpJson([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-Content $path -Raw | ConvertFrom-Json).mcpServers
}

# One HTTP request through curl.exe. --ssl-no-revoke: Schannel curl fails with exit 35 when it cannot reach the
# revocation list of a certificate.
function Invoke-McpCurl([string]$url, [string[]]$headers = @(), [string]$body = '') {
    $dir = Join-Path $env:TEMP ('doctor_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory $dir | Out-Null
    try {
        $hf = Join-Path $dir 'headers.txt'; $out = Join-Path $dir 'out.txt'; $hdr = Join-Path $dir 'response.txt'
        [IO.File]::WriteAllLines($hf, [string[]]$headers)
        $argv = @('-s', '--ssl-no-revoke', '--connect-timeout', '10', '--max-time', '30', '-D', $hdr, '-o', $out, '-w', '%{http_code}', '-H', "@$hf")
        if ($body) { $bf = Join-Path $dir 'body.json'; [IO.File]::WriteAllText($bf, $body); $argv += @('--data-binary', "@$bf") }
        $argv += $url
        if ($script:ShowCmd) { Write-Host "  > curl.exe $($argv -join ' ')" -ForegroundColor DarkGray }
        $prev = $ErrorActionPreference
        try { $ErrorActionPreference = 'Continue'; $code = & $McpCurl @argv 2>$null; $exit = $LASTEXITCODE }
        finally { $ErrorActionPreference = $prev }
        [pscustomobject]@{
            Exit    = $exit
            Code    = [int]("0$code" -replace '\D', '')
            Headers = $(if (Test-Path $hdr) { [IO.File]::ReadAllText($hdr) } else { '' })
            Body    = $(if (Test-Path $out) { [IO.File]::ReadAllText($out) } else { '' })
        }
    }
    finally { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

function Get-HttpProblem($r) {
    if ($r.Exit -ne 0) { return "curl exit $($r.Exit)$(if ($McpCurlErrors[[int]$r.Exit]) { ': ' + $McpCurlErrors[[int]$r.Exit] })" }
    if ($r.Code -in 401, 403) { return "HTTP $($r.Code): key rejected" }
    return "HTTP $($r.Code)"
}

# An MCP http answer is JSON or an event stream whose last data: line holds the JSON.
function ConvertFrom-McpAnswer([string]$text) {
    $data = @($text -split "`r?`n" | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() })
    try { return $(if ($data) { $data[-1] } else { $text }) | ConvertFrom-Json } catch { return $null }
}

function Get-McpErrorText($a) {
    $t = if ($a.error) { $a.error.message } else { @($a.result.content | ForEach-Object { $_.text }) -join ' ' }
    $t = ($t -replace '\s+', ' ').Trim()
    if ($t.Length -gt 120) { $t = $t.Substring(0, 120) + '...' }
    return $t
}

function Test-McpHttp([string]$name, $def) {
    $url = [string](McpProp $def 'url')
    $headers = @('Accept: application/json, text/event-stream', 'Content-Type: application/json')
    $h = McpProp $def 'headers'
    if ($h) { $headers += @($h.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) }
    $r = Invoke-McpCurl $url $headers $McpInitialize
    $a = if ($r.Exit -eq 0 -and $r.Code -eq 200) { ConvertFrom-McpAnswer $r.Body }
    if (-not $a -or -not $a.result) { Todo "MCP $name`: no answer to initialize from $url ($(Get-HttpProblem $r))"; return }
    $server = "$($a.result.serverInfo.name) $($a.result.serverInfo.version)".Trim()
    $probe = $McpProbes[([uri]$url).Host]
    if (-not $probe) { Warn "MCP $name`: $server answers, key not verified (no known tool call for $(([uri]$url).Host))"; return }
    if ($r.Headers -match '(?im)^mcp-session-id:[ \t]*([^\s]+)') { $headers += "Mcp-Session-Id: $($Matches[1])" }
    $call = @{ jsonrpc = '2.0'; id = 2; method = 'tools/call'; params = $probe } | ConvertTo-Json -Depth 5 -Compress
    $r = Invoke-McpCurl $url $headers $call
    $a = if ($r.Exit -eq 0 -and $r.Code -eq 200) { ConvertFrom-McpAnswer $r.Body }
    if (-not $a) { Todo "MCP $name`: tool call $($probe.name) failed ($(Get-HttpProblem $r))"; return }
    if ($a.error -or $a.result.isError) { Todo "MCP $name`: $($probe.name) refused - key in .mcp.json invalid or expired? ($(Get-McpErrorText $a))"; return }
    Ok "MCP $name`: $server, key accepted ($($probe.name))"
}

# A tool per stdio server program (file name of its command) that needs the network and the credentials:
# initialize alone succeeds even when every real call fails (network, certificate, token).
$McpStdioProbes = @{
    'github-mcp-server.exe' = @{ name = 'get_me'; arguments = @{} }
}

# Starts a stdio server like the MCP client does and waits for its answer to initialize; with $Probe also for
# the answer to that tool call. Prints nothing: Exe (expanded command), Found, Ok, Server ("name version"),
# Why (the failure, keys masked), Probe (tool name or ''), ProbeOk, ProbeText (error text, keys masked).
function Get-McpStdioState($def, [switch]$Probe) {
    $exe = [Environment]::ExpandEnvironmentVariables([string](McpProp $def 'command'))
    $state = [pscustomobject]@{ Exe = $exe; Found = $false; Ok = $false; Server = ''; Why = ''; Probe = ''; ProbeOk = $false; ProbeText = '' }
    $call = if ($Probe) { $McpStdioProbes[[IO.Path]::GetFileName($exe)] }
    $cmd = Get-Command $exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { $state.Why = 'not found'; return $state }
    $state.Found = $true
    $e = McpProp $def 'env'
    $argLine = (@(McpProp $def 'args') | Where-Object { $null -ne $_ } | ForEach-Object {
            if ("$_" -match '[\s"]') { '"' + ("$_" -replace '"', '\"') + '"' } else { "$_" } }) -join ' '
    if ($script:ShowCmd) { Write-Host "  > $exe $argLine" -ForegroundColor DarkGray }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $cmd.Source
    $psi.Arguments = $argLine
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    if ($e) { $e.PSObject.Properties | ForEach-Object { $psi.EnvironmentVariables[$_.Name] = [string]$_.Value } }
    $answer = $null
    # Windows PowerShell 5.1 (.NET Framework) creates the stdin writer with [Console]::InputEncoding and writes
    # its BOM at once; the server reads that as the first JSON character ("invalid character 'ï' looking for
    # beginning of value"). UTF-8 without BOM while the process starts avoids it.
    $prevEncoding = [Console]::InputEncoding
    try { [Console]::InputEncoding = New-Object Text.UTF8Encoding $false } catch { }
    try { $p = [Diagnostics.Process]::Start($psi) }
    finally { try { [Console]::InputEncoding = $prevEncoding } catch { } }
    $errTask = $p.StandardError.ReadToEndAsync()
    try {
        $bytes = (New-Object Text.UTF8Encoding $false).GetBytes($McpInitialize + "`n")
        $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length); $p.StandardInput.BaseStream.Flush()
        $deadline = (Get-Date).AddSeconds($McpStartSeconds)
        while (-not $answer -and (Get-Date) -lt $deadline) {
            $t = $p.StandardOutput.ReadLineAsync()
            if (-not $t.Wait([int][Math]::Max(1, ($deadline - (Get-Date)).TotalMilliseconds))) { break }
            if ($null -eq $t.Result) { break }    # the server ended
            try { $j = $t.Result | ConvertFrom-Json } catch { continue }
            if ((McpProp $j 'id') -eq 1) { $answer = $j }
        }
        if ($answer -and $answer.result -and $call) {
            $state.Probe = $call.name
            $msg = '{"jsonrpc":"2.0","method":"notifications/initialized"}' + "`n" +
                (@{ jsonrpc = '2.0'; id = 2; method = 'tools/call'; params = $call } | ConvertTo-Json -Depth 5 -Compress) + "`n"
            $bytes = (New-Object Text.UTF8Encoding $false).GetBytes($msg)
            $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length); $p.StandardInput.BaseStream.Flush()
            $reply = $null
            $deadline = (Get-Date).AddSeconds($McpStartSeconds)
            while (-not $reply -and (Get-Date) -lt $deadline) {
                $t = $p.StandardOutput.ReadLineAsync()
                if (-not $t.Wait([int][Math]::Max(1, ($deadline - (Get-Date)).TotalMilliseconds))) { break }
                if ($null -eq $t.Result) { break }
                try { $j = $t.Result | ConvertFrom-Json } catch { continue }
                if ((McpProp $j 'id') -eq 2) { $reply = $j }
            }
            if (-not $reply) { $state.ProbeText = "no answer in $McpStartSeconds s" }
            elseif ($reply.error -or $reply.result.isError) { $state.ProbeText = Get-McpErrorText $reply }
            else { $state.ProbeOk = $true }
        }
    }
    catch { }
    finally {
        try { $p.StandardInput.Close() } catch { }
        if (-not $p.WaitForExit(3000)) { try { $p.Kill() } catch { } }
    }
    if ($e) { foreach ($v in @($e.PSObject.Properties | Where-Object { $_.Name -match 'TOKEN|KEY|SECRET|PASSWORD' } | ForEach-Object { [string]$_.Value } | Where-Object { $_.Length -ge 8 })) { $state.ProbeText = "$($state.ProbeText)".Replace($v, '***') } }
    if ($answer -and $answer.result) {
        $state.Ok = $true
        $state.Server = "$($answer.result.serverInfo.name) $($answer.result.serverInfo.version)".Trim()
        return $state
    }
    $why = if ($errTask.Wait(2000)) { @($errTask.Result -split "`r?`n" | Where-Object { $_ -match '(?i)error|fail|denied|not found' })[-1] } else { '' }
    if ($e) { foreach ($v in @($e.PSObject.Properties | ForEach-Object { [string]$_.Value } | Where-Object { $_.Length -ge 8 })) { $why = "$why".Replace($v, '***') } }
    $state.Why = "$(if ($p.HasExited) { "ended (exit $($p.ExitCode))" } else { "no answer in $McpStartSeconds s" }) without answering initialize$(if ($why) { ": $why" })"
    return $state
}

function Test-McpStdio([string]$name, $def) {
    $state = Get-McpStdioState $def -Probe
    if ($state.Ok -and -not $state.Probe) { Ok "MCP $name`: $($state.Server) started" }
    elseif ($state.Ok -and $state.ProbeOk) { Ok "MCP $name`: $($state.Server) started, $($state.Probe) answered" }
    elseif ($state.Ok) { Todo "MCP $name`: $($state.Server) started, but $($state.Probe) failed: $($state.ProbeText)" }
    elseif (-not $state.Found) { Todo "MCP $name`: command not found: $($state.Exe)$(if ([IO.Path]::GetFileName($state.Exe) -eq 'github-mcp-server.exe') { ' - fa setup claude installs it' })" }
    else { Todo "MCP $name`: $($state.Exe) $($state.Why)" }
    $e = McpProp $def 'env'
    $token = McpProp $e 'GITHUB_PERSONAL_ACCESS_TOKEN'
    if ($token) { Test-GitHubToken (McpProp $e 'GITHUB_HOST') $token "MCP $name token" }
}

function Report-Expiry([string]$msg, [string]$expiry) {
    if (-not $expiry) { Ok "$msg, no expiry date"; return }
    $when = [DateTimeOffset]::Parse(($expiry -replace ' UTC$', ' +00:00'), [Globalization.CultureInfo]::InvariantCulture)
    $days = [int][Math]::Floor(($when - [DateTimeOffset]::UtcNow).TotalDays)
    $text = "$msg, expires $($when.ToString('yyyy-MM-dd')) (in $days days)"
    if ($days -lt 0) { Todo "$text - create a new token" }
    elseif ($days -le $McpExpiryWarnDays) { Warn "$text - renew it soon" }
    else { Ok $text }
}

# GitHub token: login, scopes and expiry (classic tokens send their expiry date in a response header).
function Test-GitHubToken([string]$ghHost, [string]$token, [string]$label) {
    $h = ($ghHost -replace '^https?://', '').TrimEnd('/')
    if (-not $h) { $h = 'github.com' }
    $api = if ($h -eq 'github.com') { 'https://api.github.com' } else { "https://$h/api/v3" }
    $r = Invoke-McpCurl "$api/user" @("Authorization: token $token", 'User-Agent: doctor', 'Accept: application/vnd.github+json')
    if ($r.Exit -ne 0 -or $r.Code -ne 200) { Todo "$label`: not accepted by $h ($(Get-HttpProblem $r))"; return }
    $msg = "$label`: $h login $((ConvertFrom-Json $r.Body).login)"
    if ($r.Headers -match '(?im)^x-oauth-scopes:[ \t]*([^\r\n]*?)[ \t]*\r?$' -and $Matches[1]) { $msg += ", scopes $($Matches[1])" }
    $expiry = if ($r.Headers -match '(?im)^github-authentication-token-expiration:[ \t]*([^\r\n]*?)[ \t]*\r?$') { $Matches[1] } else { '' }
    Report-Expiry $msg $expiry
}

# Every server of <root>\.mcp.json. Returns the parsed servers for the caller's own comparisons.
function Test-McpServers([string]$path) {
    $servers = $null
    try { $servers = Read-McpJson $path } catch { Todo "$path is not valid JSON: $($_.Exception.Message)"; return $null }
    if (-not $servers) { Todo "no MCP servers: $path missing or empty (per machine, by hand, never versioned)"; return $null }
    foreach ($p in $servers.PSObject.Properties) {
        $type = McpProp $p.Value 'type'
        if (-not $type) { $type = if (McpProp $p.Value 'url') { 'http' } else { 'stdio' } }
        switch ($type) {
            'stdio' { Test-McpStdio $p.Name $p.Value }
            'http' { Test-McpHttp $p.Name $p.Value }
            default { Warn "MCP $($p.Name): type '$type' is not checked" }
        }
    }
    return $servers
}
