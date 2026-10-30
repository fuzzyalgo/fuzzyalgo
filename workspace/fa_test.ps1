<#
fa_test.ps1 - checks that fa gh behaves like plain gh: arguments, stdin, stdout and exit code, gh's own folder
<root>\.gh, and only the github.com account. Runs a temporary copy of the workspace files with a fake gh.

    powershell -NoProfile -ExecutionPolicy Bypass -File <root>\fuzzyalgo\workspace\fa_test.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File <root>\fuzzyalgo\workspace\fa_test.ps1 -Ref 0783c72

-Ref <commit> tests the files of that commit instead of the working tree (0783c72: before the 2026-10-30 fixes).
The PowerShell checks run in Windows PowerShell 5.1 and, when installed, PowerShell 7 (pwsh); the cmd checks go
through fa.cmd. Every check prints PASS or FAIL; the exit code is 1 when one fails.
The fake gh (compiled with the csc.exe of .NET Framework) prints its arguments, its stdin, GH_CONFIG_DIR and
whether GH_TOKEN is set, never a value; the copy has a .mcp.json with a fake token. Only the two "real gh"
checks use the real gh and <root>\.mcp.json (gh auth status, read-only); -Ref and -NoRealGh skip them.
#>
param([string]$Ref, [switch]$NoRealGh, [switch]$Inner, [string]$Fa)

$ErrorActionPreference = 'Continue'

function Report([string]$where, [string]$name, [bool]$ok, [string]$got) {
    if ($ok) { "PASS  [$where] $name" } else { "FAIL  [$where] $name$(if ($got) { "   (got: $got)" })" }
}
# the lines the fake gh wrote during one call
function Invoke-Gh([scriptblock]$call) {
    Remove-Item -LiteralPath $env:FAKE_GH_LOG -ErrorAction SilentlyContinue
    $null = & $call 2>&1
    if (Test-Path -LiteralPath $env:FAKE_GH_LOG) { [IO.File]::ReadAllLines($env:FAKE_GH_LOG) } else { @() }
}
function Get-GhArgs($log) { @($log | Where-Object { $_ -like 'arg <*>' } | ForEach-Object { $_.Substring(5, $_.Length - 6) }) }
function Show-Args($log) { (@(Get-GhArgs $log) | ForEach-Object { "<$_>" }) -join ' ' }
function Same([string[]]$a, [string[]]$b) {
    if (@($a).Count -ne @($b).Count) { return $false }
    for ($i = 0; $i -lt @($a).Count; $i++) { if (@($a)[$i] -cne @($b)[$i]) { return $false } }
    $true
}
function Test-GhEnv($log, [string]$ghDir) { ($log -contains "GH_CONFIG_DIR <$ghDir>") -and ($log -contains 'GH_TOKEN set') }
function Show-GhEnv($log) { @($log | Where-Object { $_ -like 'GH_*' }) -join ', ' }

# -----------------------------------------------------------------------------------------------------
# the PowerShell checks, in a child powershell.exe / pwsh started below: fa.ps1 called like "fa" in a terminal
if ($Inner) {
    $where = "PS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
    $ghDir = Join-Path (Split-Path (Split-Path (Split-Path $Fa))) '.gh'
    $env:GH_TOKEN = 'caller-token'    # a token of the terminal: gh must get the .mcp.json one, the terminal keeps this
    $envBefore = [Environment]::GetEnvironmentVariables(); $locBefore = (Get-Location).Path

    $log = Invoke-Gh { & $Fa gh pr list --json number,title }
    Report $where 'fa gh pr list --json number,title: number,title stays one argument' (Same (Get-GhArgs $log) @('pr', 'list', '--json', 'number,title')) (Show-Args $log)

    $log = Invoke-Gh { & $Fa gh issue create --title 'a b' --body 'say "hi"' }
    Report $where "fa gh issue create --title 'a b' --body 'say `"hi`"': spaces and quotes arrive" (Same (Get-GhArgs $log) @('issue', 'create', '--title', 'a b', '--body', 'say "hi"')) (Show-Args $log)

    $x = & $Fa gh x 2>$null
    Report $where '$x = fa gh ...: the output is captured' (@($x) -contains 'arg <x>') "$(@($x).Count) lines captured"

    $j = $null; try { $j = & $Fa gh json --a 2>$null | ConvertFrom-Json } catch { }
    Report $where 'fa gh ... | ConvertFrom-Json' ($null -ne $j -and $j.argc -eq 2) "$j"

    $log = Invoke-Gh { 'hello' | & $Fa gh issue create -F - }
    $in = "$(@($log | Where-Object { $_ -like 'stdin *' }))"
    Report $where "'hello' | fa gh issue create -F -: gh reads hello, no BOM" ($in -match '^stdin <hello(\\r)?\\n>$') $in

    $env:FAKE_GH_EXIT = '3'; $null = & $Fa gh x 2>&1; $code = $LASTEXITCODE; Remove-Item Env:FAKE_GH_EXIT
    Report $where 'the exit code is the one of gh (3)' ($code -eq 3) "$code"

    $log = Invoke-Gh { & $Fa gh x }
    Report $where 'fa gh: gh gets GH_CONFIG_DIR = <root>\.gh and a GH_TOKEN' (Test-GhEnv $log $ghDir) (Show-GhEnv $log)

    # the whole block: in 5.1 GetEnvironmentVariable returns $null for a variable that is set but empty
    $envAfter = [Environment]::GetEnvironmentVariables()
    $diff = @(foreach ($k in $envBefore.Keys) { if (-not $envAfter.Contains($k) -or $envAfter[$k] -cne $envBefore[$k]) { $k } }) +
            @(foreach ($k in $envAfter.Keys) { if (-not $envBefore.Contains($k)) { $k } })
    Report $where 'the environment and location of the terminal are unchanged after fa' ($diff.Count -eq 0 -and (Get-Location).Path -eq $locBefore) ($diff -join ', ')

    # last, it changes this session: what the "fa" terminal profile runs, then plain gh
    $null = & (Join-Path (Split-Path $Fa) 'fa_env.ps1') -Terminal 6>$null
    $log = Invoke-Gh { & gh x }
    Report $where 'fa terminal (fa_env.ps1 -Terminal), plain gh: GH_CONFIG_DIR = <root>\.gh and a GH_TOKEN' (Test-GhEnv $log $ghDir) (Show-GhEnv $log)
    exit 0
}

# -----------------------------------------------------------------------------------------------------
$FakeGhSource = @'
// fake gh: prints its arguments, GH_TOKEN set or not (never the value), GH_CONFIG_DIR and, after an argument "-",
// its stdin; also into the file FAKE_GH_LOG. First argument "json": only {"argc":n}. Exit code FAKE_GH_EXIT (0).
using System;
using System.IO;
using System.Text;
public static class FakeGh {
    static Stream o;
    static string logFile;
    static void W(string s) {
        byte[] b = new UTF8Encoding(false).GetBytes(s + "\n");
        o.Write(b, 0, b.Length); o.Flush();
        if (!string.IsNullOrEmpty(logFile)) File.AppendAllText(logFile, s + "\r\n");
    }
    public static int Main(string[] a) {
        o = Console.OpenStandardOutput();
        logFile = Environment.GetEnvironmentVariable("FAKE_GH_LOG");
        if (a.Length > 0 && a[0] == "json") { W("{\"argc\":" + a.Length + "}"); }
        else {
            foreach (string s in a) W("arg <" + s + ">");
            W("GH_TOKEN " + (string.IsNullOrEmpty(Environment.GetEnvironmentVariable("GH_TOKEN")) ? "unset" : "set"));
            W("GH_CONFIG_DIR <" + Environment.GetEnvironmentVariable("GH_CONFIG_DIR") + ">");
            if (Array.IndexOf(a, "-") >= 0) {
                if (!Console.IsInputRedirected) W("stdin <not redirected>");
                else {
                    MemoryStream m = new MemoryStream();
                    Console.OpenStandardInput().CopyTo(m);
                    byte[] b = m.ToArray();
                    bool bom = b.Length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF;
                    string text = new UTF8Encoding(false).GetString(b, bom ? 3 : 0, b.Length - (bom ? 3 : 0));
                    W("stdin <" + text.Replace("\r", "\\r").Replace("\n", "\\n") + ">" + (bom ? " with BOM" : ""));
                }
            }
        }
        string rc = Environment.GetEnvironmentVariable("FAKE_GH_EXIT");
        return string.IsNullOrEmpty(rc) ? 0 : int.Parse(rc);
    }
}
'@

$repo = Split-Path $PSScriptRoot
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('fa_test_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$root = Join-Path $tmp 'root'; $ws = Join-Path $root 'fuzzyalgo\workspace'; $bin = Join-Path $tmp 'bin'
$results = New-Object System.Collections.Generic.List[string]
function Out-Result { process { if ($_ -match '^(PASS|FAIL)  ') { $results.Add($_); $_ } } }
$oldPath = $env:PATH
try {
    [void][IO.Directory]::CreateDirectory($ws); [void][IO.Directory]::CreateDirectory($bin)
    foreach ($f in 'fa.ps1', 'fa_env.ps1', 'mcp_doctor.ps1', 'fa.cmd') {
        if ($Ref) {
            $text = @(& git -C $repo show "$($Ref):workspace/$f")
            if ($LASTEXITCODE) { throw "git show $($Ref):workspace/$f failed" }
            [IO.File]::WriteAllText((Join-Path $ws $f), ($text -join "`r`n") + "`r`n")
        }
        else { [IO.File]::Copy((Join-Path $PSScriptRoot $f), (Join-Path $ws $f)) }
    }
    [IO.File]::WriteAllText((Join-Path $root '.mcp.json'), '{"mcpServers":{"github":{"command":"github-mcp-server.exe","env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"ghp_FAKE0000000000000000000000000000000000"}}}}')

    $csc = @("$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe", "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe") | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $csc) { throw 'no csc.exe of .NET Framework 4 to compile the fake gh' }
    $src = Join-Path $tmp 'fakegh.cs'; [IO.File]::WriteAllText($src, $FakeGhSource)
    $out = & $csc /nologo "/out:$(Join-Path $bin 'gh.exe')" $src 2>&1
    if ($LASTEXITCODE) { throw "compiling the fake gh failed: $out" }

    $env:PATH = "$bin;$oldPath"; $env:FAKE_GH_LOG = Join-Path $tmp 'gh.log'
    "fa_test: files of $(if ($Ref) { "commit $Ref" } else { 'the working tree' }), fake gh in $bin"

    $shells = @("$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe") + @(Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object Source)
    foreach ($sh in $shells) {
        & $sh -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Inner -Fa (Join-Path $ws 'fa.ps1') 2>&1 | ForEach-Object { "$_" } | Out-Result
    }

    # cmd: one .cmd file per check, as typed in cmd.exe
    $faCmd = Join-Path $ws 'fa.cmd'; $stdinFile = Join-Path $tmp 'stdin.txt'; [IO.File]::WriteAllText($stdinFile, "hello`r`n")
    function Invoke-Cmd([string]$line) {
        $bat = Join-Path $tmp 'case.cmd'
        [IO.File]::WriteAllText($bat, "@echo off`r`n$line`r`nexit /b %ERRORLEVEL%`r`n")
        Invoke-Gh { & cmd.exe /d /c $bat; $script:CmdExit = $LASTEXITCODE }
    }
    $log = Invoke-Cmd "call `"$faCmd`" gh pr list --json number,title"
    Report 'cmd' 'fa.cmd gh pr list --json number,title' (Same (Get-GhArgs $log) @('pr', 'list', '--json', 'number,title')) (Show-Args $log) | Out-Result
    $log = Invoke-Cmd "call `"$faCmd`" gh issue create --title `"a b`""
    Report 'cmd' 'fa.cmd gh issue create --title "a b"' (Same (Get-GhArgs $log) @('issue', 'create', '--title', 'a b')) (Show-Args $log) | Out-Result
    $log = Invoke-Cmd "call `"$faCmd`" gh issue create -F - < `"$stdinFile`""
    $in = "$(@($log | Where-Object { $_ -like 'stdin *' }))"
    Report 'cmd' 'fa.cmd gh issue create -F - < file: gh reads the file' ($in -match '^stdin <hello\\r\\n>$') "$in, fa.cmd exit $script:CmdExit" | Out-Result
    $log = Invoke-Cmd "set FAKE_GH_EXIT=3`r`ncall `"$faCmd`" gh x"
    Report 'cmd' 'fa.cmd: the exit code is the one of gh (3)' ($script:CmdExit -eq 3) "$script:CmdExit" | Out-Result

    # the real gh with the real <root>\.mcp.json: one account only, also for plain gh in a fa terminal
    $env:PATH = $oldPath; Remove-Item Env:FAKE_GH_LOG
    $realGh = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($Ref -or $NoRealGh) { 'SKIP  [real gh] (-Ref or -NoRealGh)' }
    elseif (-not $realGh -or -not (Test-Path -LiteralPath (Join-Path (Split-Path $repo) '.mcp.json'))) { 'SKIP  [real gh] no gh on PATH or no <root>\.mcp.json' }
    else {
        function Get-LoggedIn([scriptblock]$call) { @(& $call 2>&1 | ForEach-Object { if ("$_" -match 'Logged in to (\S+) account') { $Matches[1] } }) }
        $hosts = Get-LoggedIn { & (Join-Path $PSScriptRoot 'fa.ps1') gh auth status }
        Report 'real gh' 'fa gh auth status: logged in to github.com only' (Same $hosts @('github.com')) ($hosts -join ', ') | Out-Result
        $envPs1 = (Join-Path $PSScriptRoot 'fa_env.ps1').Replace("'", "''")
        $hosts = Get-LoggedIn { & "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& '$envPs1' -Terminal 6>`$null; gh auth status" }
        Report 'real gh' 'fa terminal, plain gh auth status: logged in to github.com only' (Same $hosts @('github.com')) ($hosts -join ', ') | Out-Result
    }

    $failed = @($results | Where-Object { $_ -like 'FAIL*' }).Count
    "`n$($results.Count - $failed) passed, $failed failed"
    exit $(if ($failed) { 1 } else { 0 })
}
finally {
    $env:PATH = $oldPath; Remove-Item Env:FAKE_GH_LOG -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
