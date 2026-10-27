<#
fa.ps1 - implementation behind fa.cmd, the single entry point of the fuzzyalgo workspace.

    fa help                overview          fa help <command>     details + examples

Root = two levels above this file (<root>\fuzzyalgo\workspace\fa.ps1), e.g. C:\fuzzyalgo. Runs in Windows
PowerShell 5.1 and PowerShell 7, without VS Code. Arguments are parsed by hand ($args).
#>
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
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

$script:ShowCmd = $false
$script:DryRun = $false
$script:ExitCode = 0

# =====================================================================================================
# Help
# =====================================================================================================

$Help = [ordered]@{
    setup   = @'
fa setup
    One-time (safe to re-run) setup of <root> = parent of the fuzzyalgo repo:
      1 MetaEditor64.exe, terminal64.exe, metatester64.exe from their zip (only when missing)
      2 <root>\logs\ (compile logs)      3 <root>\CLAUDE.md (= fa setup claude)      4 fa doctor
    The account (config\common.ini, with the password) is not created here: run RUN.ps1 once yourself,
    see docs\mql5-development.md.
    e.g. fa setup

fa setup claude
    Only step 3: writes <root>\CLAUDE.md = @fuzzyalgo/workspace/CLAUDE.md, so an agent started at the root
    loads the repo CLAUDE.md and workspace\AGENTS.md. Claude Code reads CLAUDE.md only from its start
    directory and the parents. An existing CLAUDE.md with other content is kept with a warning
    (line endings do not count).
    e.g. fa setup claude
'@
    doctor  = @'
fa doctor
    Checks only, changes nothing: root CLAUDE.md and .mcp.json, repo branch + uncommitted files,
    MetaEditor/terminal binaries, account config, log directories, running terminal.
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
}

function Show-Help([string]$topic) {
    if ($topic -and $Help.Contains($topic)) { Write-Host $Help[$topic]; return }
    Write-Host @'
fa - fuzzyalgo workspace (<root>\fuzzyalgo\workspace\fa.cmd)

  fa setup [claude] | doctor | help [command]
  fa compile <program>... [--check]
  fa run <program> [SYMBOL] [PERIOD] [--timeout <s>]
  fa logs [compile [program] | terminal [n] | <program> [n]]

  Every command: --show-cmd prints the real command lines, --dry-run prints them without running.
  Details: fa help setup|doctor|compile|run|logs
'@
}

# =====================================================================================================
# Helpers
# =====================================================================================================

function Fail([string]$msg) { throw [System.Management.Automation.RuntimeException]::new("FA: $msg") }
function Say([string]$msg, [string]$color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Ok([string]$msg) { Write-Host "  OK    $msg" -ForegroundColor Green }
function Todo([string]$msg) { Write-Host "  TODO  $msg" -ForegroundColor Yellow }
function Title([string]$msg) { Write-Host "`n=== $msg" -ForegroundColor Cyan }

function Show-Cmd([string]$line, [string]$cwd) {
    if ($script:ShowCmd -or $script:DryRun) { Write-Host "  [$cwd]> $line" -ForegroundColor DarkGray }
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

function Newest([string]$dir, [string]$filter) {
    Get-ChildItem $dir -Filter $filter -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
}

function Rel([string]$path) { if ($path.StartsWith("$Root\")) { $path.Substring($Root.Length + 1) } else { $path } }

# A program by file name (TestFFT) or path below MQL5 (Scripts\FuzzyAlgo\TestFFT[.mq5]).
function Find-Program([string]$name) {
    $n = ($name -replace '/', '\' -replace '\.(mq5|ex5)$', '' -replace '^(MetaTrader5_TMPL\\)?MQL5\\', '')
    $all = foreach ($k in $Kinds) { Get-ChildItem (Join-Path $MqlDir $k) -Recurse -Filter *.mq5 -File -ErrorAction SilentlyContinue }
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
    if (-not (Test-Path $log)) { Fail "no compile log $log" }
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

function Line-Count([string]$path) { if (Test-Path $path) { (Read-Utf16 $path).Count } else { 0 } }

# =====================================================================================================
# setup / doctor
# =====================================================================================================

# <root>\CLAUDE.md: Claude Code loads CLAUDE.md only from the start directory and its parents, so the root
# needs a pointer to the versioned instructions in fuzzyalgo\workspace. An existing different file is kept.
# Get-Content splits LF and CRLF alike, so line endings do not count as a difference.
function Test-RootClaude([string]$path) { (@(Get-Content $path) -join "`n").Trim() -eq $RootClaudeImport }
function Setup-RootClaude {
    $path = Join-Path $Root 'CLAUDE.md'
    if (-not (Test-Path $path)) {
        Act "write $path" { Set-Content $path $RootClaudeImport -Encoding ASCII }
        Ok "$(if ($script:DryRun) { 'would create' } else { 'created' }) $path"
    }
    elseif (Test-RootClaude $path) { Ok "already present: $path" }
    else { Say "  WARNING  $path has different content - left unchanged; expected: $RootClaudeImport" Yellow }
}

function Cmd-Setup([string[]]$a) {
    if ($a[0] -eq 'claude') {
        if ($a.Count -gt 1) { Fail "unexpected '$($a[1])' - fa help setup" }
        Setup-RootClaude; return
    }
    if ($a.Count -gt 0) { Fail "unexpected '$($a[0])' - fa help setup" }

    Title '1/4 MetaTrader binaries'
    foreach ($exe in 'MetaEditor64.exe', 'terminal64.exe', 'metatester64.exe') {
        $path = Join-Path $TmplDir $exe
        $zip = Join-Path $TmplDir ($exe.ToLower() -replace '\.exe$', '.zip')
        if (Test-Path $path) { Ok "already present: $(Rel $path)"; continue }
        if (-not (Test-Path $zip)) { Todo "neither $exe nor $(Rel $zip)"; continue }
        Act "unzip $zip -> $TmplDir" { Expand-Archive -LiteralPath $zip -DestinationPath $TmplDir -Force }
        Ok "$(if ($script:DryRun) { 'would unpack' } else { 'unpacked' }) $(Rel $path)"
    }
    Title '2/4 compile log directory'
    if (Test-Path $LogDir) { Ok "already present: $LogDir" }
    else { Act "mkdir $LogDir" { New-Item -ItemType Directory $LogDir | Out-Null }; Ok $LogDir }
    Title '3/4 CLAUDE.md at the root'
    Setup-RootClaude
    Title '4/4 doctor'
    Cmd-Doctor
}

function Cmd-Doctor {
    Title 'agent instructions'
    $rootClaude = Join-Path $Root 'CLAUDE.md'
    if (-not (Test-Path $rootClaude)) { Todo "no $rootClaude (agent instructions are not loaded at the root): fa setup claude" }
    elseif (-not (Test-RootClaude $rootClaude)) { Todo "$rootClaude differs from the expected '$RootClaudeImport' - kept; edit or delete it, then: fa setup claude" }
    else { Ok 'CLAUDE.md at the root imports fuzzyalgo\workspace\CLAUDE.md' }
    if (Test-Path (Join-Path $Root '.mcp.json')) { Ok "$Root\.mcp.json (per machine, not versioned)" }
    else { Todo "no $Root\.mcp.json (MCP servers, per machine, by hand)" }

    Title 'repository'
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { Todo 'git not on PATH' }
    else {
        $remote = (& git -C $RepoDir remote get-url origin 2>$null)
        $branch = (& git -C $RepoDir branch --show-current 2>$null)
        $dirty = @(& git -C $RepoDir status --porcelain 2>$null)
        Ok "fuzzyalgo: $branch ($remote)"
        if ($dirty.Count) { Say "  INFO  $($dirty.Count) uncommitted change(s) in the repo (git status)" DarkGray }
    }

    Title 'MetaTrader'
    foreach ($exe in $MetaEditor, $Terminal) {
        if (Test-Path $exe) { Ok "$(Rel $exe) $((Get-Item $exe).VersionInfo.FileVersion)" } else { Todo "no $(Rel $exe): fa setup" }
    }
    if (Test-Path $CommonIni) { Ok "account config $(Rel $CommonIni) (not read: has the password)" }
    else { Todo "no $(Rel $CommonIni): once, yourself: cd $TmplDir; .\RUN.ps1 --login=<n> --password=<pw>" }
    $running = Terminal-Running
    if ($running) { Say "  INFO  terminal64.exe is running (pid $($running.Id -join ', ')) - fa run refuses until it is closed" DarkGray }
    else { Ok 'no terminal64.exe of MetaTrader5_TMPL running' }

    Title 'logs'
    if (Test-Path $LogDir) { Ok "compile logs: $LogDir" } else { Todo "no $LogDir`: fa setup" }
    foreach ($d in $MqlLogDir, $TerminalLogDir) {
        $f = Newest $d '*.log'
        if ($f) { Ok "$(Rel $f.FullName) ($($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))" } else { Say "  INFO  no log in $(Rel $d) yet" DarkGray }
    }
}

# =====================================================================================================
# compile / run / logs
# =====================================================================================================

function Cmd-Compile([string[]]$a) {
    $check = $a -contains '--check'
    $names = @($a | Where-Object { $_ -ne '--check' })
    if (-not $names) { Fail 'which program? - fa help compile' }
    $programs = @($names | ForEach-Object { Find-Program $_ })    # resolve all before compiling any
    if (-not (Test-Path $MetaEditor)) { Fail "no $(Rel $MetaEditor): fa setup" }
    if (-not (Test-Path $LogDir)) { Act "mkdir $LogDir" { New-Item -ItemType Directory $LogDir | Out-Null } }
    foreach ($p in $programs) {
        $log = Join-Path $LogDir "compile_$($p.Name.ToLower()).log"
        Title "$(if ($check) { 'check' } else { 'compile' }) $($p.Rel)"
        $argLine = $(if ($check) { '/s ' } else { '' }) + "/compile:`"MQL5\$($p.Rel)`" /include:`"MQL5`" /log:`"$log`""
        Act "delete old $log" { Remove-Item $log -ErrorAction SilentlyContinue }
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
    if (-not (Test-Path $Terminal)) { Fail "no $(Rel $Terminal): fa setup" }
    if (-not (Test-Path $CommonIni)) { Fail "no account yet ($(Rel $CommonIni)): run RUN.ps1 --login=<n> --password=<pw> once yourself" }
    if (-not (Test-Path $p.Ex5)) { Fail "$(Rel $p.Ex5) does not exist: fa compile $($p.Name)" }
    if ((Get-Item $p.Mq5).LastWriteTime -gt (Get-Item $p.Ex5).LastWriteTime) { Say "  NOTE  $($p.Name).mq5 is newer than its .ex5 - the old build runs (fa compile $($p.Name))" Yellow }
    $running = Terminal-Running
    if ($running) { Fail "terminal64.exe of MetaTrader5_TMPL already runs (pid $($running.Id -join ', ')); two cannot run from one directory - close it first" }

    $isScript = $p.Kind -eq 'Scripts'
    $start = $p.Rel.Substring($p.Kind.Length + 1) -replace '\.mq5$', ''    # relative to MQL5\Scripts or \Experts
    $ini = Join-Path $FaTemp "run_$($p.Name.ToLower() -replace '\W', '_').ini"
    $content = @('[StartUp]', "$(if ($isScript) { 'Script' } else { 'Expert' })=$start", "Symbol=$symbol", "Period=$period")
    if ($isScript) { $content += 'ShutdownTerminal=1' }
    Title "run $($p.Rel) on $symbol $period"
    Act "write $ini" {
        New-Item -ItemType Directory $FaTemp -Force | Out-Null
        Set-Content $ini $content -Encoding ASCII
    }
    if ($script:ShowCmd -or $script:DryRun) { $content | ForEach-Object { Say "      $_" DarkGray } }

    $day = (Get-Date).ToString('yyyyMMdd')
    $mqlLog = Join-Path $MqlLogDir "$day.log"
    $termLog = Join-Path $TerminalLogDir "$day.log"
    $mqlBefore = Line-Count $mqlLog
    $termBefore = Line-Count $termLog
    $argLine = "/portable `"/config:$ini`""
    Show-Cmd "`"$Terminal`" $argLine" $TmplDir
    if ($script:DryRun) { return }
    $proc = Start-Process -FilePath $Terminal -ArgumentList $argLine -WorkingDirectory $TmplDir -PassThru
    if (-not $isScript) { Ok "expert started in the terminal (pid $($proc.Id)); it stays open - fa logs $($p.Name)"; return }

    Say "  waiting for the script and the terminal to end (max $timeout s) ..." DarkGray
    if (-not $proc.WaitForExit($timeout * 1000)) {
        $script:ExitCode = 1
        Say "  the terminal still runs after $timeout s (pid $($proc.Id)) - left open; fa logs $($p.Name), --timeout" Red
    }
    $new = if (Test-Path $mqlLog) { @(Read-Utf16 $mqlLog | Select-Object -Skip $mqlBefore) } else { @() }
    $mine = @($new | Where-Object { $_ -match "\t$([regex]::Escape($p.Name)) \(" })
    Title "$($p.Name): $($mine.Count) new line(s) in $(Rel $mqlLog)"
    $mine | ForEach-Object { Say "  $_" }
    $journal = if (Test-Path $termLog) { @(Read-Utf16 $termLog | Select-Object -Skip $termBefore) } else { @() }
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
            if ($x[1]) { Say ("  {0,-9} {1}  {2}" -f $x[0], $x[1].LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $x[1].FullName) }
            else { Say ("  {0,-9} -" -f $x[0]) DarkGray }
        }
        Say '  fa logs compile [program] | terminal [n] | <program> [n]' DarkGray
        return
    }
    if ($what -eq 'compile') {
        if ($a.Count -gt 1) {
            $name = $a[1] -replace '\.mq5$', '' -replace '^.*[\\/]', ''
            $log = Join-Path $LogDir "compile_$($name.ToLower()).log"
            Title (Rel $log); [void](Show-CompileLog $log); return
        }
        $logs = @(Get-ChildItem $LogDir -Filter *.log -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 15)
        if (-not $logs) { Say "  no logs in $LogDir"; return }
        foreach ($l in $logs) {
            $r = (Read-Utf16 $l.FullName | Where-Object { $_ -match '^(Result:| : information: result) \d+ error' } | Select-Object -Last 1) -replace '^ : information: result', 'Result:'
            Say ("  {0}  {1,-40} {2}" -f $l.LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $l.Name, $r) $(if ($r -match '^Result: 0 error') { 'Gray' } else { 'Red' })
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
    foreach ($f in @(Get-ChildItem $MqlLogDir -Filter *.log -File -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $mine = @(Read-Utf16 $f.FullName | Where-Object { $_ -match $pattern })
        if (-not $mine) { continue }
        Title "$name in $(Rel $f.FullName) (last $([Math]::Min($mine.Count, $(if ($n) { $n } else { 60 }))) of $($mine.Count))"
        $mine | Select-Object -Last $(if ($n) { $n } else { 60 }) | ForEach-Object { Say "  $_" }
        return
    }
    Fail "'$name' printed nothing in $(Rel $MqlLogDir) - fa logs compile | terminal"
}

# =====================================================================================================
# main
# =====================================================================================================

$argv = @()
foreach ($x in $args) {
    switch ($x) {
        '--show-cmd' { $script:ShowCmd = $true }
        '--dry-run' { $script:DryRun = $true }
        default { if ("$x" -ne '') { $argv += [string]$x } }    # empty = unset VS Code task input
    }
}
if ($script:DryRun) {
    Say 'DRY RUN - state-changing commands and file actions will be printed but not executed; read-only queries may run.' Yellow
}
if ($argv -contains '--help' -or $argv -contains '-h') { Show-Help $argv[0]; exit 0 }

try {
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
        default { Fail "unknown command '$cmd' - fa help" }
    }
}
catch {
    Write-Host ($_.Exception.Message -replace '^FA: ', 'fa: ') -ForegroundColor Red
    if ($env:FA_DEBUG) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray }
    exit 1
}
exit $script:ExitCode
