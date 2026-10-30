<#
fa.ps1 - implementation of fa, the single entry point of the fuzzyalgo workspace.

    fa help                overview          fa help <command>     details + examples

Root = two levels above this file (<root>\fuzzyalgo\workspace\fa.ps1), e.g. C:\fuzzyalgo. Runs in Windows
PowerShell 5.1 and PowerShell 7, without VS Code. In PowerShell "fa" is this script (fa.ps1 comes before fa.cmd)
and runs in the caller's session; cmd and VS Code tasks go through fa.cmd, which hands the arguments over
unparsed after #FA_ARGS# on the powershell.exe command line. Arguments are parsed by hand.
#>
# Nothing of the caller's session may change how fa works: StrictMode, -WhatIf/-Confirm defaults, default
# parameter values ('*:WhatIf', '*:ErrorAction'), preference variables (Write-Host throws at Information 'Stop'),
# $OFS, native errors. Set here, in fa's script scope: the caller's own values stay as they are.
Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$WhatIfPreference = $false
$ConfirmPreference = 'High'
$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues = @{}
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$OFS = ' '
$PSNativeCommandUseErrorActionPreference = $false
$script:ExitCode = 0
$script:HasPipedInput = $MyInvocation.ExpectingInput                   # ... | fa gh ... -F -
$script:PipedInput = if ($script:HasPipedInput) { @($input) } else { @() }
# fa.cmd runs "...; & $env:FA_PS1; ... #FA_ARGS#" <arguments>: there they are a comment, fa reads them from the command line
$script:FromCmd = $args.Count -eq 0 -and "$($MyInvocation.Line)".Contains('#FA_ARGS#') -and [Environment]::CommandLine.Contains('#FA_ARGS#"')
if ($script:FromCmd) { [Environment]::SetEnvironmentVariable('FA_PS1', $null) }    # set by fa.cmd, not for the programs fa starts

# PowerShell runs "fa" in the caller's session, so every environment change would stay in the caller's terminal.
# The environment, the location and the TLS setting are therefore saved here and restored when fa ends (main, finally).
$script:CallerEnv = [Environment]::GetEnvironmentVariables()
$script:CallerLocation = Get-Location
$script:CallerTls = [Net.ServicePointManager]::SecurityProtocol
$script:InvLine = $MyInvocation.Line            # for the check of a bare -- (main)
$script:InvColumn = $MyInvocation.OffsetInLine
$script:ArgPassingWindows = ($PSVersionTable.PSVersion.Major * 100 + $PSVersionTable.PSVersion.Minor) -ge 703

# [Environment], not Env:\ - in Windows PowerShell 5.1 Get-ChildItem Env: throws when two names differ only in
# case, and Set-Item obeys -WhatIf and wildcards. A variable with an empty value is left alone unless fa changed
# it; Windows cannot set one back to ''.
function Restore-CallerEnv {
    $now = [Environment]::GetEnvironmentVariables()
    foreach ($k in @($now.Keys)) { if (-not $script:CallerEnv.ContainsKey($k)) { try { [Environment]::SetEnvironmentVariable($k, $null) } catch { } } }
    foreach ($k in @($script:CallerEnv.Keys)) {
        if (-not $now.ContainsKey($k) -or $now[$k] -cne $script:CallerEnv[$k]) { try { [Environment]::SetEnvironmentVariable($k, $script:CallerEnv[$k]) } catch { } }
    }
    try { if ((Get-Location).Path -ne $script:CallerLocation.Path) { Set-Location -LiteralPath $script:CallerLocation.Path } } catch { }    # only fails when it no longer exists
    if ([Net.ServicePointManager]::SecurityProtocol -ne $script:CallerTls) { [Net.ServicePointManager]::SecurityProtocol = $script:CallerTls }
}
# A variable of the caller's environment, case-insensitive like Windows; $null when it is not set.
function CallerEnvValue([string]$name) { foreach ($k in $script:CallerEnv.Keys) { if ($k -eq $name) { return $script:CallerEnv[$k] } } }

# =====================================================================================================
# Help
# =====================================================================================================

$Help = [ordered]@{
    setup   = @'
fa setup
    One-time (safe to re-run) setup of <root> = parent of the fuzzyalgo repo:
      1 MetaEditor64.exe, terminal64.exe, metatester64.exe from their zip (only when missing)
      2 <root>\logs\ (compile logs)      3 <root>\CLAUDE.md + MCP server (= fa setup claude)      4 fa doctor
    The account (config\common.ini, with the password) is not created here: run RUN.ps1 once yourself,
    see docs\mql5-development.md. Exit code 1 after a WARNING or a TODO of the doctor step.
    e.g. fa setup

fa setup claude
    Only step 3: writes <root>\CLAUDE.md = @fuzzyalgo/workspace/CLAUDE.md, so an agent started at the root
    loads the repo CLAUDE.md and workspace\AGENTS.md. Claude Code reads CLAUDE.md only from its start
    directory and the parents. An existing CLAUDE.md with other content is kept with a warning
    (line endings do not count).
    Then starts every stdio server of <root>\.mcp.json. github-mcp-server.exe (latest release zip of
    github/github-mcp-server) is installed where "command" points, only when it is missing or broken; a
    working one is not updated, and one that starts but stops (args, env, token) is reported, not replaced.
    .mcp.json itself is written by hand (keys) and never versioned. Exit code 1 after a WARNING.
    e.g. fa setup claude
'@
    doctor  = @'
fa doctor
    Checks only, changes nothing: root CLAUDE.md and .mcp.json, repo branch + uncommitted files,
    MetaEditor/terminal binaries, account config, log directories, running terminal, and the accounts:
      gh             logged in to github.com with the token of the github server in .mcp.json
      <root>\.mcp.json  read like Claude Code reads it: strict JSON, ${VAR} and ${VAR:-default} expanded
                     from this terminal's environment. Every server: stdio ones are started (in <root>, with
                     their env), http ones get initialize + a tool call; GitHub tokens report login, scopes
                     and expiry (a github server without GITHUB_HOST counts as github.com)
    No key is printed, also not from URLs, args or the servers' answers. A token that expires within 14 days
    is a WARN. Every check runs; the exit code is 1 when at least one is TODO (missing or failing), WARN
    does not count.
'@
    compile = @'
fa compile <program>... [--check]
    MetaEditor64.exe /compile of each program (run in MetaTrader5_TMPL, /include:MQL5), log in
    <root>\logs\compile_<program>.log. Prints the error/warning lines and the Result: line.
    Exit code 1 if a program has errors.
    <program>  file name without .mq5 (TestFFT), or the path below MQL5 (Scripts\FuzzyAlgo\TestFFT)
               when the name is not unique. Searched in MQL5\Scripts, Experts, Indicators.
    --check    syntax check only (/s): no .ex5 is written, so tracked .ex5 files stay unchanged
    A successful compile overwrites the tracked .ex5 next to the .mq5 (it shows as modified in git).
    e.g. fa compile TestVariables
         fa compile TestFFT TestTickCacheDiff --check
'@
    run     = @'
fa run <program> [SYMBOL] [PERIOD] [--timeout <s>]
    Starts terminal64.exe /portable with a generated start configuration <root>\Temp\fa\run_<program>.ini
    ([StartUp] Script= or Expert=, Symbol, Period). Login and password are not in it: the terminal uses
    its saved account (create it once with RUN.ps1). Two terminals cannot run from the same directory,
    so it refuses while terminal64.exe of MetaTrader5_TMPL runs.
      script  ShutdownTerminal=1: waits until the script ended and the terminal closed (default 300 s),
              then prints the new log lines of the script and the terminal errors
      expert  attached to the chart; the terminal stays open, fa returns at once (fa logs <program>)
    Indicators cannot be started this way (only by a chart template or profile).
    SYMBOL default EURUSD, PERIOD (M1..MN1) default M1. Run fa compile first; a .mq5 newer than its
    .ex5 is reported.
    The program can only write files to MetaTrader5_TMPL\MQL5\Files\.
    e.g. fa run TestTickCacheDiff
         fa run TestFFT GBPUSD M5 --timeout 600
'@
    logs    = @'
fa logs
    The newest compile log, program log and terminal log, with paths.

fa logs compile [program]
    Without program: the newest compile logs with their Result: line.
    With program: errors, warnings and Result: of <root>\logs\compile_<program>.log.
    e.g. fa logs compile
         fa logs compile TestVariables

fa logs terminal [n]
    The last n (default 40) lines of the newest terminal journal (MetaTrader5_TMPL\logs).
    e.g. fa logs terminal 100

fa logs <program> [n]
    The last n (default 60) lines that program printed (MQL5\Logs, newest day that has some).
    e.g. fa logs TestTickCacheDiff
'@
    gh      = @'
fa gh <gh arguments>
    gh with the account of this workspace, from any terminal: GH_HOST = github.com, GITHUB_TOKEN cleared,
    gh's own folder <root>\.gh (GH_CONFIG_DIR: none of the other gh logins of this Windows user), and the
    github.com token of <root>\.mcp.json as GH_TOKEN for gh only (no other program fa starts gets it).
    stdin, stdout and stderr are gh's own: $x = fa gh ..., ... | fa gh ... -F -, fa gh ... > file work like
    plain gh; the exit code is gh's. Terminals of fuzzyalgo.code-workspace ("fa" profile, fa_env.ps1) have
    that environment already, there plain gh does the same. Like every fa command it leaves the terminal's
    environment as it was.
    Arguments go to gh as typed, except: fa keeps --show-cmd and --dry-run for itself and drops empty ones.
      PowerShell  removes a bare -- before fa sees it: quote it ('--'), fa stops with this hint otherwise;
                  --% does not work through fa. Numbers keep their spelling, except in lists: a,007 arrives
                  as a,7 in Windows PowerShell 5.1 (quote the list: 'a,007').
      cmd         fa.cmd passes every argument unchanged, but cmd itself acts on & | < > ^ outside double
                  quotes: quote such arguments ("a&b").
    e.g. fa gh auth status
         fa gh repo view fuzzyalgo/fuzzyalgo
         fa gh pr list --json number,title
         fa gh search issues '--' -label:bug
'@
}

function Show-Help([string]$topic) {
    if ($topic -and $Help.Contains($topic)) { Write-Host $Help[$topic]; return }
    Write-Host @'
fa - fuzzyalgo workspace (<root>\fuzzyalgo\workspace\fa.cmd)

  fa setup [claude] | doctor | help [command]
  fa compile <program>... [--check]
  fa run <program> [SYMBOL] [PERIOD] [--timeout <s>]
  fa logs [compile [program] | terminal [n] | <program> [n]]
  fa gh <gh arguments>      gh with the account of this workspace

  Every command: --show-cmd prints the real command lines, --dry-run prints them without running.
  Details: fa help setup|doctor|compile|run|logs|gh
'@
}

# =====================================================================================================
# Helpers
# =====================================================================================================

function Fail([string]$msg) { throw [System.Management.Automation.RuntimeException]::new("FA: $msg") }
function Say([string]$msg, [string]$color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Ok([string]$msg) { Write-Host "  OK    $msg" -ForegroundColor Green }
function Todo([string]$msg) { $script:TodoCount++; Write-Host "  TODO  $msg" -ForegroundColor Yellow }
function Warn([string]$msg) { Write-Host "  WARN  $msg" -ForegroundColor Yellow }
# setup: something it could not do; the exit code becomes 1
function Warning([string]$msg) { $script:ExitCode = 1; Write-Host "  WARNING  $msg" -ForegroundColor Yellow }
function Title([string]$msg) { Write-Host "`n=== $msg" -ForegroundColor Cyan }

function Show-Cmd([string]$line, [string]$cwd) {
    if ($script:ShowCmd -or $script:DryRun) { Write-Host "  [$cwd]> $line" -ForegroundColor DarkGray }
}

# Texts from outside (errors, answers, URLs) with the given secrets and anything that looks like a token masked.
function Hide-Secrets([string]$text, [string[]]$secrets = @()) {
    if (-not $text) { return $text }
    foreach ($v in @($secrets | Where-Object { $_ } | Sort-Object Length -Descending)) { $text = $text.Replace($v, '***') }
    $text -replace '\b(gh[pousr]_|github_pat_|ctx7sk-|sk-)[A-Za-z0-9_-]{8,}', '$1***'
}

# Dates as in the MetaTrader file names, whatever the culture (calendar, time separator).
function Stamp([datetime]$t, [string]$fmt = 'yyyy-MM-dd HH:mm') { $t.ToString($fmt, [Globalization.CultureInfo]::InvariantCulture) }

# The message of an error without PowerShell's wrapper ("Exception calling ... with 2 argument(s)").
function Get-InnerMessage($err) { $e = $err.Exception; if ($e.InnerException) { $e = $e.InnerException }; $e.Message -replace '^FA: ', '' }

# Output of a program, stderr dropped. Local EAP: under Stop, 5.1 turns a stderr line into an error even with 2>$null.
function Get-NativeOutput([string]$exe, [string[]]$argList) { $ErrorActionPreference = 'Continue'; & $exe @argList 2>$null }

# Single arguments as one command line that Windows programs split back into the same arguments
# (CommandLineToArgvW rules): backslashes count only before a quote, so they are doubled there and at the end
# of a quoted argument. Used for gh and the stdio MCP servers (mcp_doctor.ps1).
function Join-ArgLine([string[]]$list) {
    (@($list) | ForEach-Object {
            if ($_ -ne '' -and $_ -notmatch '[\s"]') { $_ }
            else { '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"' }
        }) -join ' '
}

# The arguments of a command line the way gh (a Go program) splits them: CommandLineToArgvW rules, "" inside
# quotes = one " that ends the quoted part. fa.cmd hands its arguments over this way.
function Split-ArgLine([string]$line) {
    $list = New-Object System.Collections.Generic.List[string]
    $b = New-Object System.Text.StringBuilder
    $inQuote = $false; $have = $false; $slashes = 0
    for ($i = 0; $i -lt $line.Length; $i++) {
        $c = $line[$i]
        if ($c -eq [char]'\') { $slashes++; continue }
        if ($c -eq [char]'"') {
            [void]$b.Append([char]'\', [int][Math]::Floor($slashes / 2))
            if ($slashes % 2) { [void]$b.Append([char]'"') }
            elseif ($inQuote -and $i + 1 -lt $line.Length -and $line[$i + 1] -eq [char]'"') { [void]$b.Append([char]'"'); $i++; $inQuote = $false }
            else { $inQuote = -not $inQuote }
            $slashes = 0; $have = $true; continue
        }
        if ($slashes) { [void]$b.Append([char]'\', $slashes); $slashes = 0; $have = $true }
        if (($c -eq [char]' ' -or $c -eq [char]"`t") -and -not $inQuote) {
            if ($have) { $list.Add($b.ToString()); [void]$b.Clear(); $have = $false }
            continue
        }
        [void]$b.Append($c); $have = $true
    }
    if ($slashes) { [void]$b.Append([char]'\', $slashes); $have = $true }
    if ($have) { $list.Add($b.ToString()) }
    , $list.ToArray()
}

# PowerShell drops a bare -- from $args; only the typed line shows it (the command at our column).
function Test-DroppedDashDash {
    if (-not $script:InvLine) { return $false }
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($script:InvLine, [ref]$tokens, [ref]$errors)
    $cmd = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.CommandAst] }, $true) | Where-Object { $_.Extent.StartColumnNumber -eq $script:InvColumn })[0]
    if (-not $cmd) { return $false }
    @($cmd.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq '-' }).Count -gt 0
}

# Run a program and wait for it. $argLine is passed verbatim, because MetaEditor wants /compile:"<path>".
function Exec([string]$exe, [string]$argLine, [string]$cwd) {
    Show-Cmd "`"$exe`" $argLine" $cwd
    if ($script:DryRun) { return 0 }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $argLine
    $psi.WorkingDirectory = $cwd
    $psi.UseShellExecute = $false
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()
    return $p.ExitCode
}

# State changing file operations: shown with --show-cmd, skipped with --dry-run.
function Act([string]$desc, [scriptblock]$action) {
    if ($script:ShowCmd -or $script:DryRun) { Write-Host "  > $desc" -ForegroundColor DarkGray }
    if (-not $script:DryRun) { & $action }
}

# MetaTrader logs are UTF-16LE and may be open in the running terminal.
function Read-Utf16([string]$path) {
    $fs = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
    try { $text = (New-Object IO.StreamReader($fs, [Text.Encoding]::Unicode, $true)).ReadToEnd() }
    finally { $fs.Close() }
    return @($text -split "`r?`n" | Where-Object { $_ -ne '' })
}

# -LiteralPath everywhere: a [ in <root> would be a wildcard.
function Newest([string]$dir, [string]$filter) {
    Get-ChildItem -LiteralPath $dir -Filter $filter -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
}

function Rel([string]$path) { if ($path.StartsWith("$Root\")) { $path.Substring($Root.Length + 1) } else { $path } }

# The zip of a MetaTrader binary (tracked in git, unpacked by fa setup).
function Get-BinaryZip([string]$exe) { Join-Path $TmplDir (([IO.Path]::GetFileName($exe)).ToLower() -replace '\.exe$', '.zip') }

# A program by file name (TestFFT) or path below MQL5 (Scripts\FuzzyAlgo\TestFFT[.mq5]).
function Find-Program([string]$name) {
    $n = ($name -replace '/', '\' -replace '\.(mq5|ex5)$', '' -replace '^(MetaTrader5_TMPL\\)?MQL5\\', '')
    $all = foreach ($k in $Kinds) { Get-ChildItem -LiteralPath (Join-Path $MqlDir $k) -Recurse -Filter *.mq5 -File -ErrorAction SilentlyContinue }
    $hits = @($all | Where-Object { $_.FullName.Substring($MqlDir.Length + 1) -ieq "$n.mq5" })
    if (-not $hits) { $hits = @($all | Where-Object { $_.BaseName -ieq $n }) }
    if ($hits.Count -eq 1) {
        $f = $hits[0]
        $rel = $f.FullName.Substring($MqlDir.Length + 1)            # Scripts\FuzzyAlgo\TestFFT.mq5
        return [pscustomobject]@{ Name = $f.BaseName; Rel = $rel; Kind = $rel.Split('\')[0]; Mq5 = $f.FullName
                                  Ex5 = [IO.Path]::ChangeExtension($f.FullName, '.ex5') }
    }
    if ($hits.Count -gt 1) {
        Fail ("'$name' is not unique, use the path below MQL5:`n" + (($hits | ForEach-Object { '  ' + $_.FullName.Substring($MqlDir.Length + 1) }) -join "`n"))
    }
    $like = @($all | Where-Object { $_.BaseName -like "*$n*" } | Select-Object -First 10 | ForEach-Object { '  ' + $_.FullName.Substring($MqlDir.Length + 1) })
    Fail ("no program '$name' in MQL5\$($Kinds -join ', ')" + $(if ($like) { ", similar:`n" + ($like -join "`n") } else { '' }))
}

# Errors, warnings and the Result: line of a compile log. Returns the error count (-1 = no Result: line).
function Show-CompileLog([string]$log) {
    if (-not (Test-Path -LiteralPath $log)) { Fail "no compile log $log" }
    $lines = Read-Utf16 $log
    $issues = @($lines | Where-Object { $_ -match ' : (error|warning) ' })
    foreach ($l in ($issues | Select-Object -First 50)) { Say "  $l" $(if ($l -match ' : error ') { 'Red' } else { 'Yellow' }) }
    if ($issues.Count -gt 50) { Say "  ... $($issues.Count - 50) more in $log" DarkGray }
    # compile: "Result: 0 errors, ..."; --check (/s): " : information: result 0 errors, ..."
    $result = $lines | Where-Object { $_ -match '^(Result:| : information: result) \d+ error' } | Select-Object -Last 1
    if (-not $result) { Say "  no Result: line in $log" Red; return -1 }
    $result = $result -replace '^ : information: result', 'Result:'
    $errors = if ($result -match '^Result: (\d+) error') { [int]$Matches[1] } else { -1 }
    Say "  $result" $(if ($errors -eq 0) { 'Green' } else { 'Red' })
    return $errors
}

function Terminal-Running { @(Get-Process terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -ieq $Terminal }) }

function Line-Count([string]$path) { if (Test-Path -LiteralPath $path) { (Read-Utf16 $path).Count } else { 0 } }

# =====================================================================================================
# setup / doctor
# =====================================================================================================

# <root>\CLAUDE.md: Claude Code loads CLAUDE.md only from the start directory and its parents, so the root
# needs a pointer to the versioned instructions in fuzzyalgo\workspace. An existing different file is kept.
# Get-Content splits LF and CRLF alike, so line endings do not count as a difference.
function Test-RootClaude([string]$path) { (@(Get-Content -LiteralPath $path) -join "`n").Trim() -eq $RootClaudeImport }
function Setup-RootClaude {
    $path = Join-Path $Root 'CLAUDE.md'
    if (-not (Test-Path -LiteralPath $path)) {
        Act "write $path" { Set-Content -LiteralPath $path -Value $RootClaudeImport -Encoding ASCII }
        Ok "$(if ($script:DryRun) { 'would create' } else { 'created' }) $path"
    }
    elseif (Test-RootClaude $path) { Ok "already present: $path" }
    else { Warning "$path has different content - left unchanged; expected: $RootClaudeImport" }
}

# github-mcp-server.exe of the stdio servers in <root>\.mcp.json, installed where "command" points. A server that
# answers initialize is left alone (no update); github-mcp-server is a single Go exe from the GitHub releases
# (not on winget or PyPI).
function Setup-McpServers {
    $servers = $null
    try { $servers = Read-McpJson $McpJson }
    catch { Warning "$McpJson`: $(Get-InnerMessage $_) - MCP server not installed"; return }
    $list = @(Get-McpServerList $servers)
    if (-not $list) { Warning "no MCP servers in $McpJson (missing or empty; per machine, by hand, never versioned) - MCP server not installed"; return }
    foreach ($p in $list) {
        $s = $null
        # a failed check or install ends neither the other servers nor fa setup (its doctor step still runs)
        try { $s = Get-McpServer $p.Name $p.Value; Setup-McpServer $s }
        catch { Warning "MCP $($p.Name): $(Hide-Secrets (Get-InnerMessage $_) $(if ($s) { $s.Secrets }))" }
    }
}
function Setup-McpServer($s) {
    $label = "MCP $($s.Name)"
    if ($s.Type -cne 'stdio') { return }
    if ($s.Invalid) { Warning "$label`: $($s.Invalid) - not checked"; return }
    if ($s.Missing.Count) { Warning "$label`: Missing environment variables: $(@($s.Missing | Select-Object -Unique) -join ', ') (not set in this terminal)" }
    if ($s.Command -match '\$\{') { Warning ($label + ': "command" has an unset ${...} - not installed'); return }
    $state = Get-McpStdioState $s
    $isGitHub = (Get-McpProgramName $s.Command) -eq 'github-mcp-server'
    if ($state.Ok) {
        $latest = if ($isGitHub) { try { ", latest release $((Get-GitHubMcpRelease).tag_name), not updated" } catch { '' } }
        Ok "$label`: $($state.Server) works$latest"; return
    }
    $cmdText = Hide-Secrets $s.Command $s.Secrets
    if (-not $isGitHub) { Warning "$label`: $cmdText $($state.Why) - setup does not know how to install it"; return }
    if (-not (Test-FullPath $s.Command)) { Warning "$label`: command '$cmdText' is not a full path - put one into $McpJson"; return }
    if ($s.Command -match '["<>|*?]|[\x00-\x1f]') { Warning "$label`: command '$cmdText' has characters a file name cannot have"; return }
    # found and runs, but stops at initialize (args, env, token): a new exe would not help
    if ($state.Found -and $state.Why -notlike 'cannot be started*' -and (Test-GitHubMcpVersion $state.Path)) {
        Warning "$label`: $($state.Path) works (--version), but $($state.Why) - check args and env in $McpJson"; return
    }
    $exe = if ($s.Command -match '\.exe$') { $s.Command } else { "$($s.Command).exe" }
    Say "  $label`: $cmdText $($state.Why) - installing"
    Install-GitHubMcp $exe
    if ($script:DryRun) { return }
    $state = Get-McpStdioState $s
    if ($state.Ok) { Ok "$label`: $($state.Server) installed and started" } else { Warning "$label`: installed, but $cmdText $($state.Why)" }
}

# The machine's architecture, also for an x64 PowerShell emulated on ARM64.
function Get-NativeArch {
    $a = $null
    try { $a = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PROCESSOR_ARCHITECTURE -ErrorAction Stop).PROCESSOR_ARCHITECTURE } catch { }
    if (-not $a) { $a = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITEW6432') }
    if (-not $a) { $a = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE') }
    switch ($a) { 'ARM64' { 'arm64' } 'x86' { 'i386' } default { 'x86_64' } }
}

# 5.1 may offer only TLS 1.0/1.1, which api.github.com refuses; PS 7 uses the system default (0). Restored by Restore-CallerEnv.
function Use-Tls12 {
    $p = [Net.ServicePointManager]::SecurityProtocol
    if ([int]$p -ne 0 -and -not ($p -band [Net.SecurityProtocolType]::Tls12)) { [Net.ServicePointManager]::SecurityProtocol = $p -bor [Net.SecurityProtocolType]::Tls12 }
}

# Expand-Archive fails when -DestinationPath exists and has [ ] in it (it tests the path as a wildcard).
# Files are overwritten; an entry that would land outside $dir (..\, a full path) stops it.
function Expand-Zip([string]$zip, [string]$dir) {
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $base = [IO.Path]::GetFullPath($dir).TrimEnd('\') + '\'
    $z = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($e in $z.Entries) {
            $dest = [IO.Path]::GetFullPath([IO.Path]::Combine($base, $e.FullName))
            if (-not $dest.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { Fail "$zip has an entry outside its target directory: $($e.FullName)" }
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest))
            if ($e.Name) { [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dest, $true) }    # no name: a directory entry
        }
    }
    finally { $z.Dispose() }
}

# With the github.com token (GH_TOKEN for gh) when there is one: without a token GitHub allows 60 API requests
# an hour per IP address (403 "rate limit exceeded"). A rejected token falls back to none.
function Get-GitHubMcpRelease {
    Use-Tls12
    $url = 'https://api.github.com/repos/github/github-mcp-server/releases/latest'
    if ($script:ShowCmd -or $script:DryRun) { Say "  > GET $url" DarkGray }
    $headers = @{ 'User-Agent' = 'fa' }
    if ($script:GhToken) { try { return Invoke-RestMethod -Uri $url -UseBasicParsing -Headers ($headers + @{ Authorization = "token $($script:GhToken)" }) } catch { } }
    try { Invoke-RestMethod -Uri $url -UseBasicParsing -Headers $headers }
    catch { Fail "cannot read the latest github-mcp-server release from api.github.com (403 = API rate limit): $(Hide-Secrets (Get-InnerMessage $_) @($script:GhToken))" }
}
function Install-GitHubMcp([string]$exe) {
    $release = Get-GitHubMcpRelease
    $name = "github-mcp-server_Windows_$(Get-NativeArch).zip"
    $asset = @($release.assets | Where-Object { $_.name -eq $name })[0]
    if (-not $asset) { Fail "github-mcp-server $($release.tag_name) has no $name" }
    Act "download $($asset.browser_download_url), install as $exe" {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('fa_mcp_' + [guid]::NewGuid().ToString('N'))    # no [ ]: 5.1 -OutFile takes them as wildcards
        [void][IO.Directory]::CreateDirectory($tmp)
        try {
            $zip = Join-Path $tmp $name
            Use-Tls12
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
            Expand-Zip $zip (Join-Path $tmp 'x')
            $found = Get-ChildItem -LiteralPath (Join-Path $tmp 'x') -Recurse -Filter 'github-mcp-server.exe' -File | Select-Object -First 1
            if (-not $found) { Fail "$name has no github-mcp-server.exe" }
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($exe))
            try { [IO.File]::Copy($found.FullName, $exe, $true) }
            catch { Fail "cannot write $exe ($(Get-InnerMessage $_)) - is it still running (Claude Code)?" }
        }
        finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
    Ok "github-mcp-server $($release.tag_name) $(if ($script:DryRun) { 'would be ' })installed: $exe"
}
# Whether the exe itself runs (it may stop at initialize for its args or env).
function Test-GitHubMcpVersion([string]$exe) {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exe; $psi.Arguments = '--version'; $psi.WorkingDirectory = $Root
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
        $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
        $p = [Diagnostics.Process]::Start($psi)
        $p.StandardInput.Close()
        $null = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit(10000)) { Stop-ProcessTree $p; return $false }
        return $p.ExitCode -eq 0
    }
    catch { return $false }
}

function Cmd-Setup([string[]]$a) {
    if ($a.Count -and $a[0] -eq 'claude') {
        if ($a.Count -gt 1) { Fail "unexpected '$($a[1])' - fa help setup" }
        Setup-RootClaude; Setup-McpServers; return
    }
    if ($a.Count -gt 0) { Fail "unexpected '$($a[0])' - fa help setup" }

    Title '1/4 MetaTrader binaries'
    foreach ($exe in 'MetaEditor64.exe', 'terminal64.exe', 'metatester64.exe') {
        $path = Join-Path $TmplDir $exe
        $zip = Get-BinaryZip $path
        if (Test-Path -LiteralPath $path) { Ok "already present: $(Rel $path)"; continue }
        if (-not (Test-Path -LiteralPath $zip)) { Warning "neither $exe nor $(Rel $zip) (tracked in git: git checkout)"; continue }
        Act "unzip $zip -> $TmplDir" { Expand-Zip $zip $TmplDir }
        Ok "$(if ($script:DryRun) { 'would unpack' } else { 'unpacked' }) $(Rel $path)"
    }
    Title '2/4 compile log directory'
    if (Test-Path -LiteralPath $LogDir) { Ok "already present: $LogDir" }
    else {
        Act "mkdir $LogDir" { [void][IO.Directory]::CreateDirectory($LogDir) }
        Ok "$(if ($script:DryRun) { 'would create' } else { 'created' }) $LogDir"
    }
    Title '3/4 CLAUDE.md and MCP server at the root'
    Setup-RootClaude
    Setup-McpServers
    Title '4/4 doctor'
    Cmd-Doctor
}

# Exit code of gh auth status with the .mcp.json token, which only this gh call gets.
function Test-GhAuth([string]$exe) {
    $ErrorActionPreference = 'Continue'
    try {
        [Environment]::SetEnvironmentVariable('GH_TOKEN', $script:McpGhToken)
        $out = & $exe auth status -h $GitHost --active 2>&1 | Out-String
        $code = $LASTEXITCODE
        if ($code -ne 0 -and $out -match 'unknown flag') { $null = & $exe auth status -h $GitHost 2>&1; $code = $LASTEXITCODE }    # gh before 2.40
        return $code
    }
    finally { [Environment]::SetEnvironmentVariable('GH_TOKEN', $null) }
}

function Cmd-Doctor {
    Title 'agent instructions'
    $rootClaude = Join-Path $Root 'CLAUDE.md'
    if (-not (Test-Path -LiteralPath $rootClaude)) { Todo "no $rootClaude (agent instructions are not loaded at the root): fa setup claude" }
    elseif (-not (Test-RootClaude $rootClaude)) { Todo "$rootClaude differs from the expected '$RootClaudeImport' - kept; edit or delete it, then: fa setup claude" }
    else { Ok 'CLAUDE.md at the root imports fuzzyalgo\workspace\CLAUDE.md' }

    Title 'repository'
    $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $git) { Todo 'git not on PATH' }
    else {
        $remote = "$(@(Get-NativeOutput $git.Source @('-C', $RepoDir, 'remote', 'get-url', 'origin'))[0])"
        # a remote URL may carry a user and token (https://user:token@host/...)
        $remote = Hide-Secrets ($remote -replace '^([a-z][a-z0-9+.-]*://)[^/@]*@', '$1')
        $branch = "$(@(Get-NativeOutput $git.Source @('-C', $RepoDir, 'branch', '--show-current'))[0])"
        $dirty = @(Get-NativeOutput $git.Source @('-C', $RepoDir, 'status', '--porcelain'))
        Ok "fuzzyalgo: $branch ($remote)"
        if ($dirty.Count) { Say "  INFO  $($dirty.Count) uncommitted change(s) in the repo (git status)" DarkGray }
    }

    Title 'MetaTrader'
    foreach ($exe in $MetaEditor, $Terminal) {
        $zip = Get-BinaryZip $exe
        if (Test-Path -LiteralPath $exe) { Ok "$(Rel $exe) $((Get-Item -LiteralPath $exe).VersionInfo.FileVersion)" }
        elseif (Test-Path -LiteralPath $zip) { Todo "no $(Rel $exe): fa setup" }
        else { Todo "no $(Rel $exe), and its zip $(Rel $zip) is missing too (tracked in git: git checkout)" }
    }
    if (Test-Path -LiteralPath $CommonIni) { Ok "account config $(Rel $CommonIni) (not read: has the password)" }
    else { Todo "no $(Rel $CommonIni): once, yourself: cd $TmplDir; .\RUN.ps1 --login=<n> --password=<pw>" }
    $running = Terminal-Running
    if ($running) { Say "  INFO  terminal64.exe is running (pid $($running.Id -join ', ')) - fa run refuses until it is closed" DarkGray }
    else { Ok 'no terminal64.exe of MetaTrader5_TMPL running' }

    Title 'logs'
    if (Test-Path -LiteralPath $LogDir) { Ok "compile logs: $LogDir" } else { Todo "no $LogDir`: fa setup" }
    foreach ($d in $MqlLogDir, $TerminalLogDir) {
        $f = Newest $d '*.log'
        if ($f) { Ok "$(Rel $f.FullName) ($(Stamp $f.LastWriteTime))" } else { Say "  INFO  no log in $(Rel $d) yet" DarkGray }
    }

    Title "accounts and MCP servers ($McpJson)"
    Test-McpServers $McpJson
    $gh = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gh) { Todo 'gh not on PATH (winget install GitHub.cli)' }
    elseif (-not $script:McpGhToken) { Todo "gh: no github server in $McpJson with a GITHUB_PERSONAL_ACCESS_TOKEN and GITHUB_HOST github.com (or none)" }
    elseif ((Test-GhAuth $gh.Source) -eq 0) { Ok "gh logged in to $GitHost with the token of .mcp.json" }
    else { Todo "gh does not accept the token of .mcp.json for $GitHost (fa gh auth status)" }
    if ($script:McpGhToken) {
        $callerToken = CallerEnvValue 'GH_TOKEN'; $callerHost = CallerEnvValue 'GH_HOST'; $callerConfig = CallerEnvValue 'GH_CONFIG_DIR'
        if ($callerToken -and $callerToken -cne $script:McpGhToken) { Say "  INFO  the GH_TOKEN of this terminal is not the one in .mcp.json - open a new fa terminal or use fa gh <args>" DarkGray }
        elseif (-not $callerToken -or ($callerHost -and $callerHost -ne $GitHost)) { Say "  INFO  plain gh in this terminal does not use the .mcp.json token: use fa gh <args>" DarkGray }
        elseif ("$callerConfig".TrimEnd('\') -ne $GhConfigDir) { Say "  INFO  plain gh in this terminal also sees the other gh logins of this Windows user - open a new fa terminal or use fa gh <args>" DarkGray }
    }
    if (Test-Path -LiteralPath (Join-Path $GhConfigDir 'hosts.yml')) { Say "  INFO  $GhConfigDir\hosts.yml has gh logins of its own (gh auth login in a fa terminal?) - not needed, fa gh uses the token of .mcp.json" DarkGray }
    if ($script:TodoCount) { Say "`n$($script:TodoCount) TODO(s) - see above" Yellow; $script:ExitCode = 1 }
    else { Say "`nall checks OK" Green }
}

# =====================================================================================================
# compile / run / logs / gh
# =====================================================================================================

function Cmd-Compile([string[]]$a) {
    $check = $a -contains '--check'
    $names = @($a | Where-Object { $_ -ne '--check' })
    if (-not $names) { Fail 'which program? - fa help compile' }
    $programs = @($names | ForEach-Object { Find-Program $_ })    # resolve all before compiling any
    if (-not (Test-Path -LiteralPath $MetaEditor)) { Fail "no $(Rel $MetaEditor): fa setup" }
    if (-not (Test-Path -LiteralPath $LogDir)) { Act "mkdir $LogDir" { [void][IO.Directory]::CreateDirectory($LogDir) } }
    foreach ($p in $programs) {
        $log = Join-Path $LogDir "compile_$($p.Name.ToLower()).log"
        Title "$(if ($check) { 'check' } else { 'compile' }) $($p.Rel)"
        $argLine = $(if ($check) { '/s ' } else { '' }) + "/compile:`"MQL5\$($p.Rel)`" /include:`"MQL5`" /log:`"$log`""
        Act "delete old $log" { Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue }
        [void](Exec $MetaEditor $argLine $TmplDir)    # exit code is meaningless (1 for a clean /s check); the log decides
        if ($script:DryRun) { continue }
        $errors = Show-CompileLog $log
        Say "  log: $log" DarkGray
        if ($errors -ne 0) { $script:ExitCode = 1 }
        elseif (-not $check) { Say "  $(Rel $p.Ex5) written (tracked in git: shows as modified)" DarkGray }
    }
}

function Cmd-Run([string[]]$a) {
    $timeout = 300
    $rest = @()
    for ($i = 0; $i -lt $a.Count; $i++) {
        if ($a[$i] -eq '--timeout') {
            if ($i + 1 -ge $a.Count -or $a[$i + 1] -notmatch '^\d+$') { Fail '--timeout needs seconds - fa help run' }
            $timeout = [int]$a[++$i]
        }
        else { $rest += $a[$i] }
    }
    if (-not $rest) { Fail 'which program? - fa help run' }
    $p = Find-Program $rest[0]
    $symbol = 'EURUSD'; $period = 'M1'
    foreach ($x in ($rest | Select-Object -Skip 1)) {
        if ($x -imatch $Periods) { $period = $x.ToUpper() }
        elseif ($x -match '^[A-Za-z0-9._#-]+$') { $symbol = $x.ToUpper() }
        else { Fail "neither symbol nor period: '$x' - fa help run" }
    }
    if ($p.Kind -eq 'Indicators') { Fail "$($p.Rel) is an indicator: the terminal starts only scripts and experts from the command line; attach it with a chart template or profile" }
    if (-not (Test-Path -LiteralPath $Terminal)) { Fail "no $(Rel $Terminal): fa setup" }
    if (-not (Test-Path -LiteralPath $CommonIni)) { Fail "no account yet ($(Rel $CommonIni)): run RUN.ps1 --login=<n> --password=<pw> once yourself" }
    if (-not (Test-Path -LiteralPath $p.Ex5)) { Fail "$(Rel $p.Ex5) does not exist: fa compile $($p.Name)" }
    if ((Get-Item -LiteralPath $p.Mq5).LastWriteTime -gt (Get-Item -LiteralPath $p.Ex5).LastWriteTime) { Say "  NOTE  $($p.Name).mq5 is newer than its .ex5 - the old build runs (fa compile $($p.Name))" Yellow }
    $running = Terminal-Running
    if ($running) { Fail "terminal64.exe of MetaTrader5_TMPL already runs (pid $($running.Id -join ', ')); two cannot run from one directory - close it first" }

    $isScript = $p.Kind -eq 'Scripts'
    $start = $p.Rel.Substring($p.Kind.Length + 1) -replace '\.mq5$', ''    # relative to MQL5\Scripts or \Experts
    $ini = Join-Path $FaTemp "run_$($p.Name.ToLower() -replace '\W', '_').ini"
    $content = @('[StartUp]', "$(if ($isScript) { 'Script' } else { 'Expert' })=$start", "Symbol=$symbol", "Period=$period")
    if ($isScript) { $content += 'ShutdownTerminal=1' }
    Title "run $($p.Rel) on $symbol $period"
    Act "write $ini" {
        [void][IO.Directory]::CreateDirectory($FaTemp)
        Set-Content -LiteralPath $ini -Value $content -Encoding ASCII
    }
    if ($script:ShowCmd -or $script:DryRun) { $content | ForEach-Object { Say "      $_" DarkGray } }

    $day = Stamp (Get-Date) 'yyyyMMdd'
    $mqlLog = Join-Path $MqlLogDir "$day.log"
    $termLog = Join-Path $TerminalLogDir "$day.log"
    $mqlBefore = Line-Count $mqlLog
    $termBefore = Line-Count $termLog
    $argLine = "/portable `"/config:$ini`""
    Show-Cmd "`"$Terminal`" $argLine" $TmplDir
    if ($script:DryRun) { return }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Terminal; $psi.Arguments = $argLine; $psi.WorkingDirectory = $TmplDir; $psi.UseShellExecute = $true
    $proc = [Diagnostics.Process]::Start($psi)    # not Start-Process: its -FilePath takes [ ] as wildcards
    if (-not $isScript) { Ok "expert started in the terminal (pid $($proc.Id)); it stays open - fa logs $($p.Name)"; return }

    Say "  waiting for the script and the terminal to end (max $timeout s) ..." DarkGray
    if (-not $proc.WaitForExit($timeout * 1000)) {
        $script:ExitCode = 1
        Say "  the terminal still runs after $timeout s (pid $($proc.Id)) - left open; fa logs $($p.Name), --timeout" Red
    }
    $new = if (Test-Path -LiteralPath $mqlLog) { @(Read-Utf16 $mqlLog | Select-Object -Skip $mqlBefore) } else { @() }
    $mine = @($new | Where-Object { $_ -match "\t$([regex]::Escape($p.Name)) \(" })
    Title "$($p.Name): $($mine.Count) new line(s) in $(Rel $mqlLog)"
    $mine | ForEach-Object { Say "  $_" }
    $journal = if (Test-Path -LiteralPath $termLog) { @(Read-Utf16 $termLog | Select-Object -Skip $termBefore) } else { @() }
    $bad = @($journal | Where-Object { $_ -match '(?i)error|fail|cannot|not found|invalid|removed' })
    if ($bad) { Title "terminal journal $(Rel $termLog)"; $bad | ForEach-Object { Say "  $_" Yellow } }
    if (-not $mine) { $script:ExitCode = 1; Say '  the script printed nothing - did it start? fa logs terminal' Red }
}

function Cmd-Logs([string[]]$a) {
    $what = $a[0]
    $n = 0
    if ($a.Count -gt 1 -and $what -ne 'compile') {
        if ($a[1] -notmatch '^\d+$') { Fail "line count expected, not '$($a[1])' - fa help logs" }
        $n = [int]$a[1]
    }
    if (-not $what) {
        $c = Newest $LogDir 'compile_*.log'
        $m = Newest $MqlLogDir '*.log'
        $t = Newest $TerminalLogDir '*.log'
        foreach ($x in @(@('compile', $c), @('programs', $m), @('terminal', $t))) {
            if ($x[1]) { Say ("  {0,-9} {1}  {2}" -f $x[0], (Stamp $x[1].LastWriteTime), $x[1].FullName) }
            else { Say ("  {0,-9} -" -f $x[0]) DarkGray }
        }
        Say '  fa logs compile [program] | terminal [n] | <program> [n]' DarkGray
        return
    }
    if ($what -eq 'compile') {
        if ($a.Count -gt 1) {
            $name = $a[1] -replace '\.mq5$', '' -replace '^.*[\\/]', ''
            $log = Join-Path $LogDir "compile_$($name.ToLower()).log"
            if (-not (Test-Path -LiteralPath $log)) { Fail "no compile log $(Rel $log) - fa logs compile lists them" }
            Title (Rel $log); [void](Show-CompileLog $log); return
        }
        $logs = @(Get-ChildItem -LiteralPath $LogDir -Filter *.log -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 15)
        if (-not $logs) { Say "  no logs in $LogDir"; return }
        foreach ($l in $logs) {
            $r = (Read-Utf16 $l.FullName | Where-Object { $_ -match '^(Result:| : information: result) \d+ error' } | Select-Object -Last 1) -replace '^ : information: result', 'Result:'
            Say ("  {0}  {1,-40} {2}" -f (Stamp $l.LastWriteTime), $l.Name, $r) $(if ($r -match '^Result: 0 error') { 'Gray' } else { 'Red' })
        }
        return
    }
    if ($what -eq 'terminal') {
        $t = Newest $TerminalLogDir '*.log'
        if (-not $t) { Fail "no log in $TerminalLogDir" }
        Title (Rel $t.FullName)
        Read-Utf16 $t.FullName | Select-Object -Last $(if ($n) { $n } else { 40 }) | ForEach-Object { Say "  $_" }
        return
    }
    $name = $what -replace '\.(mq5|ex5)$', '' -replace '^.*[\\/]', ''
    $pattern = "\t$([regex]::Escape($name)) \("
    foreach ($f in @(Get-ChildItem -LiteralPath $MqlLogDir -Filter *.log -File -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $mine = @(Read-Utf16 $f.FullName | Where-Object { $_ -match $pattern })
        if (-not $mine) { continue }
        Title "$name in $(Rel $f.FullName) (last $([Math]::Min($mine.Count, $(if ($n) { $n } else { 60 }))) of $($mine.Count))"
        $mine | Select-Object -Last $(if ($n) { $n } else { 60 }) | ForEach-Object { Say "  $_" }
        return
    }
    Fail "'$name' printed nothing in $(Rel $MqlLogDir) - fa logs compile | terminal"
}

# gh with the account of this workspace (fa_env.ps1) for terminals that are not fa terminals. gh gets the console
# itself (its own stdin, stdout, stderr), so $x = fa gh ..., ... | fa gh ... -F - and > file work like plain gh.
# The token is set for this one call only.
function Cmd-Gh([string[]]$a) {
    $gh = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gh) { Fail 'gh CLI missing: winget install GitHub.cli' }
    if (-not $a) { Fail 'fa gh <gh arguments>, e.g. fa gh repo view fuzzyalgo/fuzzyalgo' }
    # ProviderPath: also from HKCU:\ or a PowerShell-only drive, which a program cannot start in
    Show-Cmd "`"$($gh.Source)`" $(Join-ArgLine $a)" (Get-Location -PSProvider FileSystem).ProviderPath
    if ($script:DryRun) { return }
    $ErrorActionPreference = 'Continue'                  # stderr of gh is no error of fa
    $OutputEncoding = [Text.UTF8Encoding]::new($false)   # what PowerShell pipes into gh
    $prevOut = $null; $prevIn = $null
    try {
        # captured output ($x = fa gh ...) is decoded with the console encoding; gh writes UTF-8
        try { if ([Console]::OutputEncoding.CodePage -ne 65001) { $prevOut = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } } catch { $prevOut = $null }
        # Windows PowerShell 5.1 writes the BOM of a UTF-8 console input encoding into gh's stdin
        if ($script:HasPipedInput) { try { if ([Console]::InputEncoding.GetPreamble().Length) { $prevIn = [Console]::InputEncoding; [Console]::InputEncoding = [Text.UTF8Encoding]::new($false) } } catch { $prevIn = $null } }
        [Environment]::SetEnvironmentVariable('GH_TOKEN', $script:GhToken)
        if ($script:ArgPassingWindows) {
            $PSNativeCommandArgumentPassing = 'Windows'    # 7.3+: every argument as it is, also '' and "
            if ($script:HasPipedInput) { $script:PipedInput | & $gh.Source @a } else { & $gh.Source @a }
        }
        else {
            # 5.1 and 7.0-7.2 drop '' and break " in arguments; --% passes the line built here unchanged
            # (it expands %FA_GH_ARGS% once). --% takes the rest of the line, so the } is on the next one.
            [Environment]::SetEnvironmentVariable('FA_GH_ARGS', (Join-ArgLine $a))
            if ($script:HasPipedInput) { $script:PipedInput | & $gh.Source --% %FA_GH_ARGS%
            }
            else { & $gh.Source --% %FA_GH_ARGS%
            }
        }
        $script:ExitCode = $LASTEXITCODE
    }
    finally {
        if ($prevOut) { try { [Console]::OutputEncoding = $prevOut } catch { } }
        if ($prevIn) { try { [Console]::InputEncoding = $prevIn } catch { } }
        [Environment]::SetEnvironmentVariable('GH_TOKEN', $null)
        [Environment]::SetEnvironmentVariable('FA_GH_ARGS', $null)
    }
}

# =====================================================================================================
# main
# =====================================================================================================

# Everything inside one try: every error ends as one red line with exit code 1, and the finally gives the
# caller's terminal its environment back, also after exit.
try {
    $Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).ProviderPath
    $RepoDir = Join-Path $Root 'fuzzyalgo'
    $TmplDir = Join-Path $RepoDir 'MetaTrader5_TMPL'
    $MqlDir = Join-Path $TmplDir 'MQL5'
    $MetaEditor = Join-Path $TmplDir 'MetaEditor64.exe'
    $Terminal = Join-Path $TmplDir 'terminal64.exe'
    $CommonIni = Join-Path $TmplDir 'config\common.ini'    # has the password: only tested for existence, never read
    $MqlLogDir = Join-Path $MqlDir 'Logs'                  # Print() of scripts/experts/indicators, UTF-16LE, one file per day
    $TerminalLogDir = Join-Path $TmplDir 'logs'            # terminal journal (login, network), UTF-16LE
    $LogDir = Join-Path $Root 'logs'                       # compile logs, outside the repo (docs\mql5-development.md)
    $FaTemp = Join-Path $Root 'Temp\fa'                    # generated start configurations of fa run
    $Kinds = @('Scripts', 'Experts', 'Indicators')
    $Periods = '^(M(1|2|3|4|5|6|10|12|15|20|30)|H(1|2|3|4|6|8|12)|D1|W1|MN1)$'
    $RootClaudeImport = '@fuzzyalgo/workspace/CLAUDE.md'    # the only line of <root>\CLAUDE.md
    $McpJson = Join-Path $Root '.mcp.json'                  # MCP servers + keys, per machine, never versioned
    $GitHost = 'github.com'
    $GhConfigDir = Join-Path $Root '.gh'                    # gh's own folder (GH_CONFIG_DIR, fa_env.ps1), per machine
    # PATH, GH_HOST, GH_CONFIG_DIR, no GITHUB_TOKEN: the same as a workspace terminal. The github.com token of .mcp.json is
    # returned, not set: only gh gets it (Cmd-Gh, Test-GhAuth), no other program fa starts.
    $script:McpGhToken = & (Join-Path $PSScriptRoot 'fa_env.ps1') -PassThru
    $script:GhToken = if ($script:McpGhToken) { $script:McpGhToken } else { CallerEnvValue 'GH_TOKEN' }
    $script:ShowCmd = $false; $script:DryRun = $false; $script:TodoCount = 0
    . (Join-Path $PSScriptRoot 'mcp_doctor.ps1')

    $words = @()
    if ($script:FromCmd) {
        # fa.cmd: the arguments as typed, split the way gh (a Go program) splits its own command line
        $cl = [Environment]::CommandLine
        $words = Split-ArgLine $cl.Substring($cl.IndexOf('#FA_ARGS#"') + 10)
    }
    else {
        # Typed in PowerShell: an unquoted list a,b arrives as an array and -name:value as '-name:' + 'value'; both
        # are put back as typed. $args[$i], not foreach: in 5.1 only the indexed element keeps a number's spelling.
        $list = New-Object System.Collections.Generic.List[string]
        $glue = $false
        for ($i = 0; $i -lt $args.Count; $i++) {
            $w = if ($args[$i] -is [array]) { @($args[$i]) -join ',' } else { [string]$args[$i] }
            if ($w -eq '--%') { Fail '--% does not work through fa: quote the arguments instead' }
            if ($glue) { $list[$list.Count - 1] += $w; $glue = $false; continue }
            $list.Add($w)
            $glue = $w -match '^-\w[\w-]*:$'
        }
        $words = $list.ToArray()
    }
    $argv = @()
    foreach ($w in $words) {
        if ($w -eq '--show-cmd') { $script:ShowCmd = $true }
        elseif ($w -eq '--dry-run') { $script:DryRun = $true }
        elseif ($w -ne '') { $argv += $w }    # empty = unset VS Code task input
    }
    if (-not $script:FromCmd -and $argv.Count -and $argv[0] -eq 'gh' -and (Test-DroppedDashDash)) {
        Fail "PowerShell removed a bare -- before fa saw it: quote it, e.g. fa gh repo clone cli/cli '--' --depth=1"
    }
    if ($script:DryRun) { Say 'DRY RUN - state-changing commands and file actions will be printed but not executed; read-only queries may run.' Yellow }

    # "fa gh ... -h" is gh's help
    if ($argv[0] -ne 'gh' -and ($argv -contains '--help' -or $argv -contains '-h')) { Show-Help $argv[0]; exit 0 }
    $cmd = $argv[0]
    $rest = @($argv | Select-Object -Skip 1)
    switch ($cmd) {
        { -not $_ } { Show-Help; break }
        'help' { Show-Help $rest[0]; break }
        'setup' { Cmd-Setup $rest; break }
        'doctor' { Cmd-Doctor; break }
        'compile' { Cmd-Compile $rest; break }
        'run' { Cmd-Run $rest; break }
        'logs' { Cmd-Logs $rest; break }
        'gh' { Cmd-Gh $rest; break }
        default { Fail "unknown command '$cmd' - fa help" }
    }
}
catch {
    Write-Host (Hide-Secrets ($_.Exception.Message -replace '^FA: ', 'fa: ') @($script:GhToken, $script:McpGhToken)) -ForegroundColor Red
    if ([Environment]::GetEnvironmentVariable('FA_DEBUG')) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray }
    exit 1
}
finally { Restore-CallerEnv }
exit $script:ExitCode
