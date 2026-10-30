# AGENTS.md - fuzzyalgo workspace

Source of truth: `fuzzyalgo\workspace\` in git `fuzzyalgo/fuzzyalgo` (this file, `fa.cmd`, `fuzzyalgo.code-workspace`).

- Workspace root `<root>` = folder containing the `fuzzyalgo` repo, e.g. `C:\fuzzyalgo`.
- **Paths in the repo `CLAUDE.md` and in `docs\` are relative to the repo `<root>\fuzzyalgo\`**, not to `<root>`:
  `docs/architecture.md` = `<root>\fuzzyalgo\docs\architecture.md`. A session started at `<root>` gets
  that file through `<root>\CLAUDE.md` -> `fuzzyalgo\workspace\CLAUDE.md` -> `@../CLAUDE.md` + this file.
- **Single entry point: `<root>\fuzzyalgo\workspace\fa.cmd <command>`** - `fa help`, `fa help <command>`.
  Runs from any PowerShell or cmd, without VS Code; in terminals of `fuzzyalgo.code-workspace` it is on `PATH`.
  Prefer `fa compile` / `fa run` / `fa logs` over calling `MetaEditor64.exe` or `terminal64.exe` by hand.
- `--show-cmd` prints the real command lines, `--dry-run` prints them without running. Exit code 0 = OK.
- **Agents: when an instruction is ambiguous or seems to contradict an earlier one, ask before acting** - in
  ordinary chat text, not in a timed question/option form (it times out and can discard the typed answer).

Typical loop:
```
fa compile TestVariables              # MetaEditor -> <root>\logs\compile_testvariables.log, prints errors + Result:
fa compile TestVariables --check      # syntax only, the tracked .ex5 stays unchanged
fa run TestVariables                  # terminal with [StartUp] Script=, waits until it closes, prints its log lines
fa logs TestVariables                 # what it printed (MQL5\Logs), later again
fa logs compile                       # newest compile logs with their Result: line
```

## 0. Fresh machine

```
git clone git@github.com:fuzzyalgo/fuzzyalgo.git C:\fuzzyalgo\fuzzyalgo
C:\fuzzyalgo\fuzzyalgo\workspace\fa.cmd setup
cd C:\fuzzyalgo\fuzzyalgo\MetaTrader5_TMPL; .\RUN.ps1 --login=<n> --password=<pw>    # once, by the user (password)
code C:\fuzzyalgo\fuzzyalgo\workspace\fuzzyalgo.code-workspace
```
Steps (re-run safe): MetaTrader binaries from their zip -> `<root>\logs\` -> `<root>\CLAUDE.md` + MCP server -> `fa doctor`.

- **Agent instructions at the root.** Everything versioned lives in the repo, even what has to take effect at
  `<root>`. Claude Code loads `CLAUDE.md` only from the directory it starts in and its parents, so `fa setup`
  writes `<root>\CLAUDE.md` = `@fuzzyalgo/workspace/CLAUDE.md`. `fa setup claude` does only that step (plus the MCP server program, see below). An existing
  `<root>\CLAUDE.md` with other content is left unchanged with a warning (line endings do not count); `fa doctor`
  reports it. The repo `CLAUDE.md` stays the content, so a session started inside the repo works as before.
- **Per machine, never versioned:** `<root>\.mcp.json` (MCP servers, keys) and `<root>\.claude\`.
  Claude Code finds `.mcp.json` in the parent directories too (checked: from `<root>`, `<root>\fuzzyalgo` and
  `<root>\fuzzyalgo\docs` all list its servers), but approves the servers **per start directory**: start `claude`
  once in that directory and accept them, or list them in `enabledMcpjsonServers` of its `.claude\settings.local.json`.
- **GitHub account:** one classic PAT for github.com, kept only in `<root>\.mcp.json` (server `github`,
  `GITHUB_HOST` `https://github.com`). `workspace\fa_env.ps1` is the one place that sets the environment:
  `PATH`, `GH_HOST=github.com`, `GH_CONFIG_DIR=<root>\.gh` (gh's own folder, so gh sees none of the other gh
  logins of this Windows user), clears `GITHUB_TOKEN` (an environment token may belong to another host, and gh
  would take it for github.com) and gives gh that PAT as `GH_TOKEN`. Nothing is stored in Windows Credential
  Manager; do not run `gh auth login` in a `fa` terminal (it would store the PAT a second time). The default
  terminal profile `fa` of `fuzzyalgo.code-workspace` runs it (`powershell -NoExit -File fa_env.ps1 -Terminal`,
  one grey status line), so plain gh there sees only the github.com account; open a new `fa` terminal after
  changing `fa_env.ps1`. `fa.ps1` calls it for every command and gives the PAT to gh only, not to MetaEditor, the
  terminal or the MCP servers. From any other terminal use `fa gh <args>`.
- **`fa` leaves the caller's session alone.** In PowerShell `fa` resolves to `fa.ps1` (before `fa.cmd`) and
  runs in the terminal's own session; `fa.ps1` saves all environment variables, the location and the TLS
  protocols at the start and restores them in the `finally` of the main dispatch (also on `exit` and after
  errors). Profile settings such as `$PSDefaultParameterValues['*:WhatIf']` do not reach it.
- `fa doctor` starts or calls every server of `.mcp.json` with its credentials (`workspace\mcp_doctor.ps1`),
  reports login, scopes and expiry of GitHub tokens (WARN 14 days before), checks gh, and prints no key.
  It runs every check and exits 1 when at least one is TODO.
- `fa setup claude` also installs `github-mcp-server.exe` (latest release zip of `github/github-mcp-server`) at the
  path the `command` of `.mcp.json` names, only when it is missing or does not answer initialize; a working one is
  not updated. Restart Claude Code afterwards; a running `github-mcp-server.exe` cannot be overwritten.

## 1. Layout

| Path | Content | Created by |
|---|---|---|
| `CLAUDE.md` | one line `@fuzzyalgo/workspace/CLAUDE.md` | `fa setup`, `fa setup claude` |
| `.mcp.json`, `.claude\` | per machine, never versioned | by hand |
| `.gh\` | gh's own folder (`GH_CONFIG_DIR`) for `fa gh` and `fa` terminals; normally empty, never versioned | `fa_env.ps1` |
| `logs\compile_<program>.log` | MetaEditor compile logs (UTF-16LE), outside the repo | `fa compile` |
| `Temp\fa\run_<program>.ini` | start configuration of the last `fa run` (no credentials) | `fa run` |
| `fuzzyalgo\` | git `fuzzyalgo/fuzzyalgo`; map in `CLAUDE.md`, details in `docs\` | clone |
| `fuzzyalgo\workspace\` | `fa.cmd` + `fa.ps1`, `fa_env.ps1`, `mcp_doctor.ps1`, `fa_test.ps1`, `fuzzyalgo.code-workspace`, this file | git |
| `fuzzyalgo\MetaTrader5_TMPL\` | portable MT5: `MetaEditor64.exe`, `terminal64.exe` (from the zips, ignored), `RUN.ps1` | git + `fa setup` |
| `...\MQL5\Scripts\FuzzyAlgo\`, `Include\FuzzyAlgo\` | FuzzyAlgo sources; `.ex5` next to the `.mq5`, **tracked** | git, `fa compile` |
| `...\MQL5\Logs\<yyyyMMdd>.log` | `Print()` output of scripts/experts (UTF-16LE) | terminal |
| `...\MQL5\Files\` | the only directory a running program can write to | programs |
| `...\logs\<yyyyMMdd>.log` | terminal journal (login, network, errors) | terminal |
| `...\config\common.ini` | account incl. **password** - never read, print or commit | `RUN.ps1` |

## 2. Commands

| Command | Does |
|---|---|
| `fa compile <program>... [--check]` | `MetaEditor64.exe /compile:"MQL5\<path>" /include:"MQL5" /log:<root>\logs\compile_<program>.log` in `MetaTrader5_TMPL` (`/s` with `--check`); prints error/warning lines and `Result:`; exit 1 on errors. `<program>` = name (`TestFFT`) or path below `MQL5` when the name is not unique |
| `fa run <program> [SYMBOL] [PERIOD] [--timeout s]` | `terminal64.exe /portable /config:<root>\Temp\fa\run_<program>.ini` with `[StartUp] Script=`/`Expert=`, `Symbol` (EURUSD), `Period` (M1). Script: `ShutdownTerminal=1`, waits (300 s), prints the script's new log lines and journal errors. Expert: stays open. Refuses while the terminal runs (one per directory) |
| `fa logs [compile [program] \| terminal [n] \| <program> [n]]` | newest logs, decoded from UTF-16LE |
| `fa doctor` | checks only: root `CLAUDE.md`, repo, binaries, account config, logs, running terminal, every `.mcp.json` server, gh; exit 1 on any TODO |
| `fa gh <args>` | gh with the github.com account of `.mcp.json` and gh's own folder `<root>\.gh`, from any terminal; arguments, stdin, output and exit code as with plain gh |
| `fa setup [claude]` | see section 0 |

- `fa run` passes no credentials; the terminal uses its saved account (`config\common.ini` from `RUN.ps1`).
  For the user's interactive chart session keep using `RUN.ps1` (profiles, `--login`).
- Indicators cannot be started from the command line (`[StartUp]` knows only `Script` and `Expert`).
- A successful `fa compile` rewrites the tracked `.ex5`; use `--check` when only the syntax matters.
- After changing `fa.ps1`, `fa_env.ps1` or `fa.cmd` run `workspace\fa_test.ps1`: `fa gh` with a fake gh in
  Windows PowerShell 5.1, PowerShell 7 and cmd, plus `gh auth status` with the real gh (one account only).
  `powershell -NoProfile -ExecutionPolicy Bypass -File <root>\fuzzyalgo\workspace\fa_test.ps1 [-Ref <commit>]
  [-NoRealGh]`; exit 0 = every check PASS. `-Ref 0783c72` shows what the version before the fixes got wrong.
