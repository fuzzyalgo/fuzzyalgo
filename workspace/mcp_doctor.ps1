<#
mcp_doctor.ps1 - the MCP checks of "fa doctor" and "fa setup claude", dot-sourced by fa.ps1.

Reads <root>\.mcp.json the way Claude Code reads it: strict JSON; ${VAR} and ${VAR:-default} in command, args,
env, url and headers are taken from this terminal's environment (Claude Code takes its own); a variable that is
not set stays as written.
  http   initialize + one cheap tool call: some servers answer initialize without a valid key, so only the tool
         call proves the key ($McpProbes); servers without a known call are reported as unverified.
  stdio  started like Claude Code starts it (in <root>, the caller's environment + its env); it has to answer
         initialize within $McpStartSeconds, a known server program also one tool call ($McpStdioProbes). A
         GITHUB_PERSONAL_ACCESS_TOKEN in its env is checked against the REST API (login, scopes, expiry: a WARN
         $McpExpiryWarnDays days before it expires).
No key reaches a command line or the console: curl reads the headers and the URL from files in a private temp
directory that is deleted afterwards, and every text from outside is masked. One server never stops the checks
of the others. Needs from fa.ps1: Ok, Todo, Warn, Hide-Secrets, Join-ArgLine, Get-InnerMessage, CallerEnvValue,
$script:CallerEnv, $script:ShowCmd, $Root.
#>

$McpExpiryWarnDays = 14
$McpStartSeconds = 20
$McpCurl = Join-Path ([Environment]::GetFolderPath('System')) 'curl.exe'    # not "curl": in Windows PowerShell 5.1 that is Invoke-WebRequest
$McpKeyNames = 'token|key|secret|passw|auth|credential|cookie'             # names of env entries, headers and flags that hold keys

# A tool per http server that only works with a valid key (initialize is answered without one).
$McpProbes = @{
    'mcp.context7.com' = @{ name = 'resolve-library-id'; arguments = @{ libraryName = 'pytest'; query = 'pytest' }; keyHeaders = @('CONTEXT7_API_KEY', 'Authorization') }
}
# A tool per stdio server program (file name of its command, without .exe) that needs the network and the
# credentials: initialize alone succeeds even when every real call fails (network, certificate, token).
$McpStdioProbes = @{
    'github-mcp-server' = @{ name = 'get_me'; arguments = @{} }
}
$McpCurlErrors = @{ 3 = 'malformed URL'; 6 = 'host not found'; 7 = 'cannot connect'; 28 = 'timeout'; 35 = 'TLS handshake failed'
    52 = 'empty reply'; 56 = 'connection broken while receiving'; 60 = 'certificate not trusted' }
$McpInitialize = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"doctor","version":"1"}}}'
$McpInitialized = '{"jsonrpc":"2.0","method":"notifications/initialized"}'

function Test-McpProp($o, [string]$name) {
    $o -is [System.Management.Automation.PSCustomObject] -and $o.PSObject.Properties[$name] -and $o.PSObject.Properties[$name].Name -ceq $name
}
# A JSON property by its exact name (JSON names are case-sensitive); the , keeps a one-element list a list.
function McpProp($o, [string]$name) { if (Test-McpProp $o $name) { , $o.PSObject.Properties[$name].Value } }

# $null = strict JSON (or not checkable here); otherwise where it fails (" at line 3, position 5", or ''). Only
# the position: in Windows PowerShell 5.1 the error text holds the input (the whole file or the invalid value),
# keys included.
function Test-StrictJson([string]$text) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        try { ([System.Text.Json.JsonDocument]::Parse($text)).Dispose(); return $null }
        catch {
            $e = $_.Exception
            while ($e -and $e -isnot [System.Text.Json.JsonException]) { $e = $e.InnerException }
            if ($e -and $null -ne $e.LineNumber) { return " at line $($e.LineNumber + 1), position $($e.BytePositionInLine + 1)" }
            return ''
        }
    }
    # 5.1: ConvertFrom-Json accepts more than JSON (single quotes, trailing commas); the WinRT parser does not
    $jv = $null
    try { $jv = [Windows.Data.Json.JsonValue, Windows.Data.Json, ContentType = WindowsRuntime] } catch { }
    if (-not $jv) { return $null }
    try { $null = $jv::Parse($text); return $null }
    catch {
        try { $null = $text | ConvertFrom-Json }
        catch {
            $m = $_.Exception.Message
            if ($m -match 'line (\d+), position (\d+)') { return " at line $($Matches[1]), position $($Matches[2])" }
            if ($m -match '\((\d+)\):') { return " at character $($Matches[1])" }
        }
        return ''
    }
}

# The mcpServers object of .mcp.json ($null when the file does not exist); throws when Claude Code cannot read it.
function Read-McpJson([string]$path) {
    if (-not [IO.File]::Exists($path)) { return $null }
    $text = [IO.File]::ReadAllText($path)
    $at = Test-StrictJson $text
    if ($null -ne $at) { throw "not valid JSON$at - Claude Code needs strict JSON (no comments, trailing commas or single quotes)" }
    if ($text.TrimStart() -notmatch '^\{') { throw 'not a JSON object { ... } - Claude Code cannot use it' }
    try { $json = $text | ConvertFrom-Json }
    catch { throw 'cannot be read by PowerShell (names that differ only in case?) - error text not shown, it can contain keys' }
    , (McpProp $json 'mcpServers')
}

# The servers (JSON names) of mcpServers; none when it is missing, empty or no object.
function Get-McpServerList($servers) {
    @(if ($servers -is [System.Management.Automation.PSCustomObject]) { $servers.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } })
}

# ${VAR} and ${VAR:-default} like Claude Code: a set variable wins (also when empty), else the default, else it
# stays as written and its name goes to $missing.
function Expand-McpValue([string]$text, $missing) {
    $b = New-Object System.Text.StringBuilder
    $last = 0
    foreach ($m in [regex]::Matches($text, '\$\{([A-Za-z_][A-Za-z0-9_]*)(:-[^}]*)?\}')) {
        [void]$b.Append($text.Substring($last, $m.Index - $last))
        $value = CallerEnvValue $m.Groups[1].Value
        if ($null -ne $value) { [void]$b.Append($value) }
        elseif ($m.Groups[2].Success) { [void]$b.Append($m.Groups[2].Value.Substring(2)) }
        else { $missing.Add($m.Groups[1].Value); [void]$b.Append($m.Value) }
        $last = $m.Index + $m.Length
    }
    [void]$b.Append($text.Substring($last))
    $b.ToString()
}

# An object whose values are all strings ("env", "headers") as name/value pairs; $null when it is not one.
function Get-McpStringMap($o) {
    if ($o -isnot [System.Management.Automation.PSCustomObject]) { return $null }
    $props = @($o.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' })
    if (@($props | Where-Object { $_.Value -isnot [string] }).Count) { return $null }
    , $props
}

# One server of .mcp.json as Claude Code sees it: its type and command/args/env or url/headers, ${...} expanded.
# Invalid = why Claude Code skips it ('' = usable); Todos and Warnings are reported before the server is checked.
function Get-McpServer([string]$name, $def) {
    $s = [pscustomobject]@{ Name = $name; Type = ''; Command = ''; Args = @(); Env = [ordered]@{}; Url = ''; Headers = [ordered]@{}; Secrets = @()
        Missing = New-Object System.Collections.Generic.List[string]; Todos = New-Object System.Collections.Generic.List[string]
        Warnings = New-Object System.Collections.Generic.List[string]; Invalid = '' }
    if ($def -isnot [System.Management.Automation.PSCustomObject]) { $s.Invalid = 'is not a JSON object'; return $s }
    if (Test-McpProp $def 'type') {
        $type = McpProp $def 'type'
        if ($type -isnot [string] -or $type -cnotin 'stdio', 'http', 'sse', 'ws', 'sdk') { $s.Invalid = '"type" must be one of stdio, http, sse, ws, sdk (lower case)'; return $s }
        $s.Type = $type
    }
    elseif (Test-McpProp $def 'command') { $s.Type = 'stdio' }
    elseif (Test-McpProp $def 'url') { $s.Type = 'http'; $s.Todos.Add('"url" without "type": Claude Code skips it - add "type": "http"') }
    else { $s.Invalid = 'neither "command" (stdio) nor "url"'; return $s }

    if ($s.Type -ceq 'stdio') {
        $cmd = McpProp $def 'command'
        if ($cmd -isnot [string] -or -not $cmd) { $s.Invalid = '"command" must be a non-empty string'; return $s }
        if (Test-McpProp $def 'args') {
            $list = McpProp $def 'args'
            if ($list -isnot [array] -or @($list | Where-Object { $_ -isnot [string] }).Count) { $s.Invalid = '"args" must be a list of strings'; return $s }
            $s.Args = @($list | ForEach-Object { Expand-McpValue $_ $s.Missing })
        }
        if (Test-McpProp $def 'env') {
            $props = Get-McpStringMap (McpProp $def 'env')
            if ($null -eq $props) { $s.Invalid = '"env" must be an object with string values'; return $s }
            foreach ($p in $props) { $s.Env[$p.Name] = Expand-McpValue $p.Value $s.Missing }
        }
        if ($cmd -match '%[^%\s]+%') { $s.Warnings.Add('"command" has %VAR%: Claude Code does not expand it (only ${VAR})') }
        $s.Command = Expand-McpValue $cmd $s.Missing
    }
    elseif ($s.Type -ceq 'http') {
        $url = McpProp $def 'url'
        if ($url -isnot [string] -or -not $url) { $s.Invalid = '"url" must be a non-empty string'; return $s }
        if (Test-McpProp $def 'headers') {
            $props = Get-McpStringMap (McpProp $def 'headers')
            if ($null -eq $props) { $s.Invalid = '"headers" must be an object with string values'; return $s }
            foreach ($p in $props) { $s.Headers[$p.Name] = Expand-McpValue $p.Value $s.Missing }
        }
        $s.Url = Expand-McpValue $url $s.Missing
    }
    if ($s.Missing.Count) {
        $s.Todos.Add('Missing environment variables: ' + (@($s.Missing | Select-Object -Unique) -join ', ') + ' - not set in this terminal; Claude Code passes ${...} on as written')
    }
    $s.Secrets = @(Get-McpSecrets $s)
    $s
}

# The values of a server that are or may be keys, for Hide-Secrets: env values with a key name (or long ones),
# header values (also without "Bearer "), values after key flags (--api-key x, --token=x), and from the URL the
# user, query values and long path parts (some servers carry the key in the path).
function Get-McpSecrets($s) {
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($k in @($s.Env.Keys)) { $v = [string]$s.Env[$k]; if (($k -match $McpKeyNames -and $v.Length -ge 3) -or $v.Length -ge 8) { $list.Add($v) } }
    foreach ($k in @($s.Headers.Keys)) {
        $v = [string]$s.Headers[$k]
        if ($v.Length -ge 3) { $list.Add($v) }
        if ($v -match '^\S+\s+(\S.{2,})$') { $list.Add($Matches[1]) }
    }
    $prevKey = $false
    foreach ($a in @($s.Args)) {
        if ($prevKey -and $a.Length -ge 3) { $list.Add($a) }
        $prevKey = $a -match "^-{1,2}[\w-]*($McpKeyNames)[\w-]*$"
        if ($a -match '^-{0,2}[\w.-]+=(.{3,})$') { $list.Add($Matches[1]) }
    }
    $u = $null
    if ($s.Url -and [Uri]::TryCreate($s.Url, [UriKind]::Absolute, [ref]$u)) {
        if ($u.UserInfo) {
            $list.Add($u.UserInfo)
            foreach ($part in $u.UserInfo.Split(':')) { if ($part.Length -ge 3) { $list.Add($part); $list.Add([Uri]::UnescapeDataString($part)) } }
        }
        foreach ($q in $u.Query.TrimStart('?').Split('&')) { $v = ($q -split '=', 2)[1]; if ($v -and $v.Length -ge 3) { $list.Add($v); $list.Add([Uri]::UnescapeDataString($v)) } }
        foreach ($seg in $u.AbsolutePath.Split('/')) {
            $d = [Uri]::UnescapeDataString($seg)
            if ($d.Length -ge 16 -and $d -match '\d' -and $d -match '[A-Za-z]') { $list.Add($seg); $list.Add($d) }
        }
    }
    @($list | Select-Object -Unique)
}

# A URL for the console: no user, no query values.
function Show-Url([string]$url) {
    $u = $null
    if (-not [Uri]::TryCreate($url, [UriKind]::Absolute, [ref]$u)) { return '(not a URL)' }
    $q = if ($u.Query.Length -gt 1) { '?' + (($u.Query.TrimStart('?').Split('&') | ForEach-Object { ($_ -split '=', 2)[0] + '=***' }) -join '&') } else { '' }
    "$($u.Scheme)://$($u.Authority)$($u.AbsolutePath)$q"
}

# One HTTP request through curl.exe. The URL and the headers (keys) go through files in a private temp directory
# (-K, -H @file), never the command line. -q: no .curlrc. -g: [ ] { } in the URL are no curl globs.
# --ssl-no-revoke: Schannel curl fails with exit 35 when it cannot reach the revocation list of a certificate.
function Invoke-McpCurl([string]$url, [string[]]$headers = @(), [string]$body = '') {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ('fa_doctor_' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($dir)
    try {
        $hf = Join-Path $dir 'headers.txt'; $cf = Join-Path $dir 'curl.cfg'; $out = Join-Path $dir 'out.txt'; $hdr = Join-Path $dir 'response.txt'
        [IO.File]::WriteAllLines($hf, [string[]]$headers)
        [IO.File]::WriteAllText($cf, 'url = "' + ($url -replace '\\', '\\' -replace '"', '\"') + '"' + "`n")
        $argv = @('-q', '-s', '-g', '--ssl-no-revoke', '--connect-timeout', '10', '--max-time', '30', '-D', $hdr, '-o', $out, '-w', '%{http_code}', '-H', "@$hf", '-K', $cf)
        if ($body) { $bf = Join-Path $dir 'body.json'; [IO.File]::WriteAllText($bf, $body); $argv += @('--data-binary', "@$bf") }
        if ($script:ShowCmd) { Write-Host "  > curl.exe ... $(Show-Url $url)" -ForegroundColor DarkGray }
        $ErrorActionPreference = 'Continue'
        $code = & $McpCurl @argv 2>$null; $exit = $LASTEXITCODE
        [pscustomobject]@{
            Exit    = $exit
            Code    = [int]("0$code" -replace '\D', '')
            Headers = $(if ([IO.File]::Exists($hdr)) { [IO.File]::ReadAllText($hdr) } else { '' })
            Body    = $(if ([IO.File]::Exists($out)) { [IO.File]::ReadAllText($out) } else { '' })
        }
    }
    finally { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

# A status that arrived counts even when curl failed afterwards: GitHub closes TLS after a 401 without
# close_notify, which Schannel curl reports as exit 56.
function Get-HttpProblem($r, [bool]$sentKey = $true) {
    if ($r.Code -eq 401) { return "HTTP 401: $(if ($sentKey) { 'key rejected' } else { 'needs a key, none in .mcp.json' })" }
    if ($r.Code -eq 403) { return "HTTP 403: $(if ($sentKey) { 'refused (key rejected, not allowed or rate limit)' } else { 'refused, no key in .mcp.json' })" }
    if ($r.Code -and $r.Code -ne 200) { return "HTTP $($r.Code)" }
    if ($r.Exit -ne 0) { return "curl exit $($r.Exit)$(if ($McpCurlErrors[[int]$r.Exit]) { ': ' + $McpCurlErrors[[int]$r.Exit] })" }
    "HTTP $($r.Code), unexpected answer"
}

# The JSON-RPC answer with this id from an http answer: plain JSON, or an event stream (events end at a blank
# line, their data: lines together are one message). Requests and notifications of the server are skipped.
function ConvertFrom-McpAnswer($r, [int]$id) {
    $text = [string]$r.Body
    $isSse = $r.Headers -match '(?im)^content-type:[ \t]*text/event-stream' -or $text -match '(?m)^data:'
    $payloads = if ($isSse) {
        foreach ($chunk in (($text -replace "`r", '') -split "`n`n")) {
            $data = @($chunk -split "`n" | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5) -replace '^ ', '' })
            if ($data) { $data -join "`n" }
        }
    }
    else { , $text }
    foreach ($payload in @($payloads)) {
        $j = $null
        try { $j = $payload | ConvertFrom-Json } catch { continue }
        foreach ($m in @($j)) {
            if ($m -is [System.Management.Automation.PSCustomObject] -and -not (Test-McpProp $m 'method') -and (McpProp $m 'id') -eq $id) { return $m }
        }
    }
    $null
}

# The error text of an answer (error.message, or the text of an isError result), keys masked, short.
function Get-McpErrorText($a, [string[]]$secrets = @()) {
    $err = McpProp $a 'error'
    $content = McpProp (McpProp $a 'result') 'content'    # assigned first: @(McpProp ...) would nest the list in a list
    $t = if ($null -ne $err) { [string](McpProp $err 'message') }
    else { @(foreach ($c in @($content)) { [string](McpProp $c 'text') }) -join ' ' }
    $t = ("$(Hide-Secrets $t $secrets)" -replace '\s+', ' ').Trim()
    if ($t.Length -gt 120) { $t = $t.Substring(0, 120) + '...' }
    $t
}

function Test-McpHttp($s) {
    $label = "MCP $($s.Name)"
    $uri = $null
    if (-not [Uri]::TryCreate($s.Url, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -notin 'http', 'https' -or $s.Url -match '[\x00-\x20]') {
        Todo "$label`: ""url"" is not an http(s) URL: $(Hide-Secrets (Show-Url $s.Url) $s.Secrets)"; return
    }
    $where = Hide-Secrets (Show-Url $s.Url) $s.Secrets
    $headers = @('Accept: application/json, text/event-stream', 'Content-Type: application/json')
    foreach ($k in @($s.Headers.Keys)) { $headers += "$k`: $($s.Headers[$k])" }
    $sentKey = $s.Headers.Count -gt 0
    $r = Invoke-McpCurl $s.Url $headers $McpInitialize
    if ($r.Code -ge 300 -and $r.Code -lt 400) {
        $to = '(no Location)'
        if ($r.Headers -match '(?im)^location:[ \t]*(\S+)') {
            $t = $null
            $to = if ([Uri]::TryCreate($uri, $Matches[1], [ref]$t)) { Hide-Secrets (Show-Url $t.AbsoluteUri) $s.Secrets } else { '(no valid Location)' }
        }
        Todo "$label`: $where answers HTTP $($r.Code), a redirect to $to - put that URL into .mcp.json"; return
    }
    if ($r.Code -eq 401 -and -not $sentKey -and $r.Headers -match '(?im)^www-authenticate:[ \t]*bearer') {
        Warn "$label`: $where is an OAuth server (HTTP 401, sign-in) - sign in with /mcp in Claude Code; not checked"; return
    }
    $a = if ($r.Code -eq 200) { ConvertFrom-McpAnswer $r 1 }
    $result = McpProp $a 'result'
    if ($result -isnot [System.Management.Automation.PSCustomObject]) {
        if (Test-McpProp $a 'error') { Todo "$label`: initialize refused (HTTP $($r.Code)): $(Get-McpErrorText $a $s.Secrets)" }
        else { Todo "$label`: no answer to initialize from $where ($(Get-HttpProblem $r $sentKey))" }
        return
    }
    $info = McpProp $result 'serverInfo'
    $server = Hide-Secrets ("$(McpProp $info 'name') $(McpProp $info 'version')".Trim()) $s.Secrets
    if (-not $server) { $server = 'server' }
    $probe = $McpProbes[$uri.Host]
    if (-not $probe) { Warn "$label`: $server answers, key not verified (no known tool call for $($uri.Host))"; return }
    $keyNames = @($probe.keyHeaders)
    if (-not @($s.Headers.Keys | Where-Object { $keyNames -contains $_ }).Count) {
        Warn "$label`: $server answers; .mcp.json sends no key ($($keyNames -join ' or ') header) - nothing to verify"; return
    }
    if ($r.Headers -match '(?im)^mcp-session-id:[ \t]*(\S+)') { $headers += "Mcp-Session-Id: $($Matches[1])" }
    $null = Invoke-McpCurl $s.Url $headers $McpInitialized
    $call = @{ jsonrpc = '2.0'; id = 2; method = 'tools/call'; params = @{ name = $probe.name; arguments = $probe.arguments } } | ConvertTo-Json -Depth 5 -Compress
    $r = Invoke-McpCurl $s.Url $headers $call
    $a = if ($r.Code -eq 200) { ConvertFrom-McpAnswer $r 2 }
    if (-not $a) { Todo "$label`: tool call $($probe.name) failed ($(Get-HttpProblem $r $sentKey))"; return }
    if ((Test-McpProp $a 'error') -or (McpProp (McpProp $a 'result') 'isError') -eq $true) {
        Todo "$label`: $($probe.name) refused - key in .mcp.json invalid or expired? ($(Get-McpErrorText $a $s.Secrets))"; return
    }
    Ok "$label`: $server, key not rejected ($($probe.name) answered)"
}

# The REST API behind GITHUB_HOST, derived the way github-mcp-server does it (parseAPIHost): empty = github.com;
# otherwise a scheme is required, https only (http only to loopback); a host ending in github.com =
# api.github.com, in ghe.com = api.<host>, any other = GitHub Enterprise Server <scheme>://<host>/api/v3.
function Get-GitHubApi([string]$ghHost) {
    if (-not $ghHost) { return @{ Api = 'https://api.github.com'; Host = 'github.com' } }
    $u = $null
    if ($ghHost -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://' -or -not [Uri]::TryCreate($ghHost, [UriKind]::Absolute, [ref]$u)) {
        return @{ Why = "GITHUB_HOST '$ghHost' is not a URL with a scheme (https://...) - github-mcp-server refuses it" }
    }
    if ($u.Scheme -ne 'https' -and -not ($u.Scheme -eq 'http' -and $u.IsLoopback)) { return @{ Why = "GITHUB_HOST '$ghHost' is not https - github-mcp-server refuses it" } }
    $h = $u.Host
    if ($h.EndsWith('github.com')) { return @{ Api = 'https://api.github.com'; Host = 'github.com' } }
    if ($h.EndsWith('ghe.com')) { return @{ Api = "https://api.$h"; Host = $h } }
    @{ Api = "$($u.Scheme)://$($u.Authority)/api/v3"; Host = $u.Authority }
}

function Report-Expiry([string]$msg, [string]$expiry) {
    if (-not $expiry) { Ok "$msg, no expiry date"; return }
    $when = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse(($expiry -replace ' UTC$', ' +00:00'), [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$when)) { Warn "$msg, expiry date not understood: $expiry"; return }
    $now = [DateTimeOffset]::UtcNow
    $date = $when.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
    $days = ($when.Date - $now.ToOffset($when.Offset).Date).Days    # calendar days, as the date reads
    $in = if ($days -eq 0) { 'today' } elseif ($days -eq 1) { 'in 1 day' } else { "in $days days" }
    if ($when -le $now) { Todo "$msg, expired $date - create a new token" }
    elseif ($days -le $McpExpiryWarnDays) { Warn "$msg, expires $date ($in) - renew it soon" }
    else { Ok "$msg, expires $date ($in)" }
}

# A GitHub token against the REST API of its host: login, scopes and expiry (classic tokens send their expiry
# date in a response header).
function Test-GitHubToken([string]$ghHost, [string]$token, [string]$label) {
    $api = Get-GitHubApi $ghHost
    if ($api.Why) { Todo "$label`: $($api.Why)"; return }
    $r = Invoke-McpCurl "$($api.Api)/user" @("Authorization: token $token", 'User-Agent: fa-doctor', 'Accept: application/vnd.github+json')
    if ($r.Code -ne 200) { Todo "$label`: $(if ($r.Code) { 'not accepted by' } else { 'cannot reach' }) $($api.Host) ($(Get-HttpProblem $r))"; return }
    $user = try { $r.Body | ConvertFrom-Json } catch { $null }
    $login = McpProp $user 'login'
    if ($login -isnot [string] -or -not $login) { Todo "$label`: $($api.Host) answered 200, but not with a user (proxy or sign-in page?)"; return }
    $msg = "$label`: $($api.Host) login $login"
    if ($r.Headers -match '(?im)^x-oauth-scopes:[ \t]*([^\r\n]*?)[ \t]*\r?$' -and $Matches[1]) { $msg += ", scopes $($Matches[1])" }
    $expiry = if ($r.Headers -match '(?im)^github-authentication-token-expiration:[ \t]*([^\r\n]*?)[ \t]*\r?$') { $Matches[1] } else { '' }
    Report-Expiry $msg $expiry
}

# The program a stdio "command" starts, found the way the MCP client (Node, libuv) finds it: a name without a
# path is looked up in the working directory (<root>) first, then in PATH, as name, name.com and name.exe.
# Returns Path, or Why when there is none.
function Resolve-McpCommand([string]$cmd) {
    if ($cmd -match '["<>|*?]|[\x00-\x1f]') { return @{ Why = 'has characters a file name cannot have' } }
    if ($cmd -notmatch '[\\/:]') {
        foreach ($c in "$Root\$cmd", "$Root\$cmd.com", "$Root\$cmd.exe") { if ([IO.File]::Exists($c)) { return @{ Path = $c } } }
        $pattern = [Management.Automation.WildcardPattern]::Escape($cmd)
        $app = Get-Command -Name $pattern -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($app) { return @{ Path = $app.Source } }
        # only programs: an alias, function or .ps1 of this session cannot be started by the MCP client either
        $other = Get-Command -Name $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($other) { return @{ Why = "is a PowerShell $($other.CommandType), not a program" } }
        return @{ Why = 'not found' }
    }
    $full = try { [IO.Path]::GetFullPath([IO.Path]::Combine($Root, $cmd)) } catch { $null }
    if (-not $full) { return @{ Why = 'is not a valid path' } }
    foreach ($c in $full, "$full.com", "$full.exe") { if ([IO.File]::Exists($c)) { return @{ Path = $c } } }
    @{ Why = 'not found' }
}

# A drive or UNC path; not IsPathRooted, which throws on " in Windows PowerShell 5.1.
function Test-FullPath([string]$path) { $path -match '^([A-Za-z]:[\\/]|[\\/]{2}[^\\/])' }

# The program name of a command: file name without .exe (not GetFileName, which throws on " in 5.1).
function Get-McpProgramName([string]$cmd) { (($cmd -split '[\\/]')[-1]) -replace '\.exe$', '' }

# A server and the programs it started (a .cmd or npx server runs node below cmd).
function Stop-ProcessTree($p) {
    try { if ($p.HasExited) { return } } catch { return }
    if ($PSVersionTable.PSVersion.Major -ge 7) { try { $p.Kill($true) } catch { }; return }
    $ErrorActionPreference = 'Continue'
    try { & (Join-Path ([Environment]::GetFolderPath('System')) 'taskkill.exe') /PID $p.Id /T /F 2>&1 | Out-Null } catch { }
    try { if (-not $p.HasExited) { $p.Kill() } } catch { }
}

function Write-McpLine($p, [string]$json) {
    $bytes = (New-Object Text.UTF8Encoding $false).GetBytes($json + "`n")
    $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
    $p.StandardInput.BaseStream.Flush()
}

# The answer with this id (requests and notifications of the server are skipped); Eof when the server closed stdout.
function Read-McpReply($p, [int]$id, [datetime]$deadline) {
    while ((Get-Date) -lt $deadline) {
        $t = $p.StandardOutput.ReadLineAsync()
        if (-not $t.Wait([int][Math]::Max(1, ($deadline - (Get-Date)).TotalMilliseconds))) { return @{ Msg = $null; Eof = $false } }
        if ($null -eq $t.Result) { return @{ Msg = $null; Eof = $true } }
        $j = $null
        try { $j = $t.Result | ConvertFrom-Json } catch { continue }
        if ($j -is [System.Management.Automation.PSCustomObject] -and -not (Test-McpProp $j 'method') -and (McpProp $j 'id') -eq $id) { return @{ Msg = $j; Eof = $false } }
    }
    @{ Msg = $null; Eof = $false }
}

# Starts a stdio server the way Claude Code does (in <root>, its environment + env of .mcp.json) and waits for
# its answer to initialize; with -Probe also for the answer to the known tool call. Prints only the command line
# (--show-cmd). Returns Exe (the command), Path (the program found), Found, Ok, Server ("name version"), Why (the
# failure, keys masked), Probe (tool name or ''), ProbeOk, ProbeText (its error, keys masked).
function Get-McpStdioState($s, [switch]$Probe) {
    $state = [pscustomobject]@{ Exe = $s.Command; Path = ''; Found = $false; Ok = $false; Server = ''; Why = ''; Probe = ''; ProbeOk = $false; ProbeText = '' }
    $res = Resolve-McpCommand $s.Command
    if (-not $res.Path) { $state.Why = $res.Why; return $state }
    $state.Path = $res.Path; $state.Found = $true
    $call = if ($Probe) { $McpStdioProbes[(Get-McpProgramName $res.Path)] }
    $argLine = Join-ArgLine @($s.Args)
    if ($script:ShowCmd) { Write-Host (Hide-Secrets "  [$Root]> `"$($res.Path)`" $argLine" $s.Secrets) -ForegroundColor DarkGray }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $res.Path; $psi.Arguments = $argLine; $psi.WorkingDirectory = $Root
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $utf8 = New-Object Text.UTF8Encoding $false
    $psi.StandardOutputEncoding = $utf8; $psi.StandardErrorEncoding = $utf8
    # The environment Claude Code gives it: its own (here: this terminal's, not fa's) + env of .mcp.json.
    # Windows PowerShell 5.1 may return $null on the first read of EnvironmentVariables.
    $ev = $psi.EnvironmentVariables
    if ($null -eq $ev) { $ev = $psi.EnvironmentVariables }
    if ($null -eq $ev) { $state.Why = 'cannot set its environment'; return $state }
    try {
        $ev.Clear()
        foreach ($k in @($script:CallerEnv.Keys)) { $ev[[string]$k] = [string]$script:CallerEnv[$k] }
        foreach ($k in @($s.Env.Keys)) { $ev[[string]$k] = [string]$s.Env[$k] }
    }
    catch { $state.Why = "cannot set its environment: $(Hide-Secrets (Get-InnerMessage $_) $s.Secrets)"; return $state }

    $answer = $null; $eof = $false; $exitedEarly = $false
    # Windows PowerShell 5.1 (.NET Framework) creates the stdin writer with [Console]::InputEncoding and writes
    # its BOM (EF BB BF) at once; the server reads that as the first JSON character ("invalid character ...
    # looking for beginning of value"). UTF-8 without BOM while the process starts avoids it.
    $prevIn = $null
    try { if ([Console]::InputEncoding.GetPreamble().Length) { $prevIn = [Console]::InputEncoding; [Console]::InputEncoding = $utf8 } } catch { $prevIn = $null }
    try { $p = [Diagnostics.Process]::Start($psi) }
    catch { $state.Why = "cannot be started: $(Hide-Secrets (Get-InnerMessage $_) $s.Secrets)"; return $state }
    finally { if ($prevIn) { try { [Console]::InputEncoding = $prevIn } catch { } } }
    $errTask = $p.StandardError.ReadToEndAsync()
    try {
        Write-McpLine $p $McpInitialize
        $reply = Read-McpReply $p 1 ((Get-Date).AddSeconds($McpStartSeconds))
        $answer = $reply.Msg; $eof = $reply.Eof
        if ((McpProp $answer 'result') -is [System.Management.Automation.PSCustomObject] -and $call) {
            $state.Probe = $call.name
            Write-McpLine $p $McpInitialized
            Write-McpLine $p (@{ jsonrpc = '2.0'; id = 2; method = 'tools/call'; params = @{ name = $call.name; arguments = $call.arguments } } | ConvertTo-Json -Depth 5 -Compress)
            $reply = Read-McpReply $p 2 ((Get-Date).AddSeconds($McpStartSeconds))
            if (-not $reply.Msg) { $state.ProbeText = if ($reply.Eof) { 'the server ended without answering' } else { "no answer in $McpStartSeconds s" } }
            elseif ((Test-McpProp $reply.Msg 'error') -or (McpProp (McpProp $reply.Msg 'result') 'isError') -eq $true) { $state.ProbeText = Get-McpErrorText $reply.Msg $s.Secrets }
            else { $state.ProbeOk = $true }
        }
    }
    catch { }    # stdin closed, server gone: decided below from what arrived
    finally {
        try { $exitedEarly = $p.HasExited } catch { }
        try { $p.StandardInput.Close() } catch { }
        try { if (-not $p.WaitForExit(3000)) { Stop-ProcessTree $p } } catch { }
    }
    $result = McpProp $answer 'result'
    if ($result -is [System.Management.Automation.PSCustomObject]) {
        $info = McpProp $result 'serverInfo'
        $state.Ok = $true
        $state.Server = Hide-Secrets ("$(McpProp $info 'name') $(McpProp $info 'version')".Trim()) $s.Secrets
        if (-not $state.Server) { $state.Server = 'server' }
        return $state
    }
    $exitText = try { if ($p.HasExited) { " (exit $($p.ExitCode))" } else { '' } } catch { '' }
    $why = if (Test-McpProp $answer 'error') { "initialize refused: $(Get-McpErrorText $answer $s.Secrets)" }
    elseif ($eof -or $exitedEarly) { "ended$exitText without answering initialize" }
    else { "no answer to initialize in $McpStartSeconds s" }
    # the last stderr line that names a problem (else the last one), e.g. a missing token
    $hint = ''
    try {
        if ($errTask.Wait(2000)) {
            $lines = @($errTask.Result -split "`r?`n" | Where-Object { $_.Trim() })
            $pick = @($lines | Where-Object { $_ -match '(?i)error|fail|denied|not found|invalid|missing|required' })
            $hint = if ($pick) { $pick[-1] } elseif ($lines) { $lines[-1] } else { '' }
            $hint = ("$(Hide-Secrets $hint $s.Secrets)" -replace '\s+', ' ').Trim()
            if ($hint.Length -gt 200) { $hint = $hint.Substring(0, 200) + '...' }
        }
    }
    catch { $hint = '' }
    $state.Why = $why + $(if ($hint) { ": $hint" } else { '' })
    $state
}

function Test-McpStdio($s) {
    $label = "MCP $($s.Name)"
    $state = Get-McpStdioState $s -Probe
    $cmdText = Hide-Secrets $s.Command $s.Secrets
    if ($state.Ok -and -not $state.Probe) { Ok "$label`: $($state.Server) started" }
    elseif ($state.Ok -and $state.ProbeOk) { Ok "$label`: $($state.Server) started, $($state.Probe) answered" }
    elseif ($state.Ok) { Todo "$label`: $($state.Server) started, but $($state.Probe) failed: $($state.ProbeText)" }
    elseif (-not $state.Found) {
        $hint = if ((Get-McpProgramName $s.Command) -eq 'github-mcp-server' -and (Test-FullPath $s.Command)) { ' - fa setup claude installs it' } else { '' }
        Todo "$label`: command $($state.Why): $cmdText$hint"
    }
    else { Todo "$label`: $cmdText $($state.Why)" }
    $token = [string]$s.Env['GITHUB_PERSONAL_ACCESS_TOKEN']
    if ($token -and $token -notmatch '\$\{') { Test-GitHubToken ([string]$s.Env['GITHUB_HOST']) $token "$label token" }
}

# Every server of <root>\.mcp.json; one that fails never stops the others.
function Test-McpServers([string]$path) {
    $servers = $null
    try { $servers = Read-McpJson $path }
    catch { Todo "$path`: $(Get-InnerMessage $_)"; return }
    $list = @(Get-McpServerList $servers)
    if (-not $list) { Todo "no MCP servers in $path (missing or empty; per machine, by hand, never versioned)"; return }
    foreach ($p in $list) {
        $s = $null
        try {
            $s = Get-McpServer $p.Name $p.Value
            foreach ($w in $s.Warnings) { Warn "MCP $($p.Name): $w" }
            foreach ($t in $s.Todos) { Todo "MCP $($p.Name): $t" }
            if ($s.Invalid) { Todo "MCP $($p.Name): $($s.Invalid) - Claude Code skips it; not checked"; continue }
            switch -CaseSensitive ($s.Type) {
                'stdio' { Test-McpStdio $s }
                'http' { Test-McpHttp $s }
                default { Warn "MCP $($p.Name): type '$($s.Type)' is not checked" }
            }
        }
        catch { Todo "MCP $($p.Name): check failed - $(Hide-Secrets (Get-InnerMessage $_) $(if ($s) { $s.Secrets }))" }
    }
}
