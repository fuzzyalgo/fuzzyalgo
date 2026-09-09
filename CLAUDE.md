# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

Two largely independent implementations of the same fuzzy-logic FX trading strategy live
side by side in this repo:

- **Python** (`Lib/algotrader/`) — a research/live-trading library driven from Jupyter/Spyder
  or ad-hoc scripts, using the `MetaTrader5` Python API, `scikit-fuzzy`, `filterpy` (Kalman
  filtering), and a vendored `mplfinance` for charting.
- **MQL5** (`MetaTrader5_TMPL/MQL5/Include/FuzzyAlgo/`, `.../Scripts/FuzzyAlgo/`) — an
  in-terminal script (`TestVariables.mq5`) that computes the same kind of per-symbol,
  per-period tick features (OC/HL/SUM_POS/SUM_NEG/NETFLOW) natively inside MetaTrader 5.

There is no code sharing between the two — treat them as separate subsystems. Most existing
hard-won knowledge in this file is about the MQL5 side; read the Python section below before
assuming otherwise.

## Python side (`Lib/algotrader/`)

- `Lib/algotrader/__init__.py` re-exports three algorithm classes, each a large, mostly
  self-contained module: `Algotrader` (`algotrader.py`), `Algotrader2` (`algotrader2.py`),
  `Algotrader3` (`algotrader3.py`). These are successive rewrites, not layers that call into
  each other — check git history/imports before assuming one supersedes the others.
- `AlgoConfig.py` loads a per-account config from a `cf_accounts.json` (JSON keyed by account
  name, e.g. `RF5D01`..`RF5D04`) and sets up per-account file+stdout logging under
  `<home>/code/dbg/img/<ACCOUNT>/`. Instantiate it with an account name plus a path to
  `cf_accounts.json`, not by hand-building config.
- `Lib/mplfinance/` is a vendored copy of the `mplfinance` charting library (not the pip
  package) — `algotrader/_mpf.py` wraps it for multi-symbol/multi-period subplot figures.
- `test/` holds exploratory/scratch scripts (`ticks_get_v2.py` .. `v8.py`, `playpen.py`,
  `fuzzy_rules_get.py`, etc.) — these are dated experiments, not a pytest suite. There is no
  automated test runner in this repo; "testing" a Python change means running the relevant
  script directly against a live/demo MT5 terminal.

### Environment setup

Full instructions are in `README.md`. Summary: create a conda env (miniforge, e.g.
`fuzzyalgo-py313`) with `numpy scipy pandas matplotlib sympy cython`, install
`filterpy scikit-fuzzy networkx pynput MetaTrader5` via pip and TA-Lib from the wheel in
`install/`, then run `python setup.py` **as Administrator, from the repo root, with the conda
env active**.

`setup.py` provisions one isolated MT5 terminal install per account under
`%APPDATA%\MetaTrader5_<ACCOUNT>\`, copying the terminal/editor/tester binaries and
**symlinking** `Experts|Files|Images|Include|Indicators|Libraries|Presets|Profiles|Scripts`
back into `MetaTrader5_TMPL/MQL5/` — editing an `.mq5`/`.mqh` file in this repo therefore
changes it for every provisioned account's terminal simultaneously; they are the same file on
disk, not copies. It also symlinks `Lib/algotrader` and `Lib/mplfinance` into the conda env's
`site-packages`. Requires admin privileges (for `CreateSymbolicLinkW`) and must be re-run
whenever `config_RoboForex-ECN/cf_accounts.tmpl`-derived per-user JSON files are missing.
Per-user account credentials live in `cf_accounts_<user>@<host>.json` (gitignored) — never cat
or commit these.

## Compiling MQL5 scripts (FuzzyAlgo)

FuzzyAlgo source lives under `MetaTrader5_TMPL/MQL5/`:
- `MQL5/Include/FuzzyAlgo/` — shared headers (`.mqh`)
- `MQL5/Scripts/FuzzyAlgo/` — scripts (`.mq5`) and their compiled output (`.ex5`)

The compiler (`MetaEditor64.exe`) is not committed as an exe — it ships zipped at
`MetaTrader5_TMPL/metaeditor64.zip`. Extract it once into `MetaTrader5_TMPL/` before compiling:

```bash
cd MetaTrader5_TMPL
unzip -o metaeditor64.zip -d .
```

### Compile command

Run from `MetaTrader5_TMPL/` (paths are relative to this working directory).
`/include:` must point at `MQL5` itself — MetaEditor appends `Include\...` internally,
so passing `MQL5\Include` doubles the path and every include fails with error 106.

```bash
cd MetaTrader5_TMPL
./MetaEditor64.exe /compile:"MQL5\Scripts\FuzzyAlgo\<Script>.mq5" /include:"MQL5" /log:"C:\fuzzyalgo\logs\compile_<script>.log"
```

Example — compiling both test scripts:

```bash
cd MetaTrader5_TMPL
./MetaEditor64.exe /compile:"MQL5\Scripts\FuzzyAlgo\TestVariables.mq5" /include:"MQL5" /log:"C:\fuzzyalgo\logs\compile_testvariables.log"
./MetaEditor64.exe /compile:"MQL5\Scripts\FuzzyAlgo\TestFFT.mq5" /include:"MQL5" /log:"C:\fuzzyalgo\logs\compile_testfft.log"
```

### Logs

- Always write compiler logs to `C:\fuzzyalgo\logs\` (a sibling of this repo, **outside**
  `fuzzyalgo/`) — never inside the repo tree, so build artifacts don't get committed.
- Log files are UTF-16LE. Convert before reading: `iconv -f UTF-16LE -t UTF-8 <file>`.
- Check the last few lines for the `Result: N errors, N warnings` summary.

### Notes

- Successful compilation overwrites the corresponding `.ex5` binary next to the `.mq5`
  source (e.g. `TestVariables.ex5`), which is tracked in git — expect it to show as
  modified after a successful build even with no source changes (rebuild timestamps).
- `MetaEditor64.exe` and `*.zip` binaries should stay untracked/ignored; don't commit them.

## Running the MetaTrader terminal (RUN.ps1)

`MetaTrader5_TMPL/RUN.ps1` starts `terminal64.exe`. Run it from `MetaTrader5_TMPL/`:

```bash
powershell.exe -file RUN.ps1
```

- Credentials (`--login`/`--password`/`--server`) are only required **once**, to create
  `config/common.ini`. The user typically does this initial run themselves since it
  involves a password.
- Once `config/common.ini` exists, run with **no arguments** (or `--login=` /
  `--profile=` only) — it reuses the existing config and just launches the terminal.
  This is the form Claude should use.
- Passing `--password` again regenerates `common.ini` — don't do this unless the user
  explicitly asks to change credentials.
- `config/common.ini` is gitignored (contains the password in plaintext) — never cat
  it out or commit it.

## Tick cache for closed-market/backtest testing (TickCache.mqh)

`MQL5/Include/FuzzyAlgo/TickCache.mqh` caches a full calendar day's ticks for a
symbol to CSV under `MQL5/Files/FuzzyAlgo/ticks_cache/` so a closed-market/backtest
run (`doLive=false` in `TestVariables.mq5`) can replay the same day's ticks without
re-issuing `CopyTicksRange`/`CopyTicks` against the terminal's tick store on every
sample. This is Phase 1 of a two-phase latency fix (`LAT_US` growing ~3x over a
simulated run) — Phase 1 removes fetch cost only; Phase 2 (incremental
accumulation to fix `init_data_from_ticks_arr_g`'s resum cost, see `DAY`'s open
issue below) is deferred until Phase 1 is confirmed fully correct.

- `variables.mqh` routes 7 call sites (DAY/PRO×2/REF×2/SECONDS_S/TICKS_T) through
  `CopyTicksRange_g`/`CopyTicks_g`, gated by `input bool I_USE_TICK_CACHE` (via
  `conf.c.USE_TICK_CACHE`). Cache-mode failures (window spans two calendar days,
  load failure) return `-1` — **no native fallback** by design, so a cache bug
  surfaces as a visible error rather than being silently masked. All existing
  callers already gate on `if (0 < size1)`, so `-1` degrades identically to `0`
  (skip resum, leave derived data untouched) — no caller-side changes were needed
  when the fallback was removed.
- CSV bid/ask/last precision **must** use the symbol's actual `SYMBOL_DIGITS`
  (`WriteTicksToCsv_g`'s `digits` param, from `SymbolInfoInteger(symbol,
  SYMBOL_DIGITS)`) — an earlier fixed 8-decimal format was insufficient to
  round-trip a double exactly through CSV text, causing ~1-ULP native-vs-cache
  differences that occasionally flipped tick up/down classification in
  `OC`/`HL`/`SUM_POS`/`SUM_NEG`. Volume/volume_real use fixed 1-decimal precision.
  Any diagnostic comparing a freshly-fetched native tick against a cache-reloaded
  one must normalize the native value through the *same* round-trip
  (`StringToDouble(DoubleToString(x, digits))`) — `NormalizeDouble` does
  floating-point arithmetic rounding and does **not** reliably produce the same
  bit pattern as a decimal-string round-trip, and will report false-positive
  diffs.
- `CopyTicksRange_g`/`CopyTicks_g` must slice/search the cached struct's `ticks[]`
  array **by reference** (MQL5 function args are reference semantics already) —
  do not stage an `ArrayCopy` of the whole day's cached ticks before searching it.
  An earlier version did exactly that on every single call, which defeated the
  point of caching (full ~72k-tick copy per sample instead of one cheap binary
  search + a small output slice).
- Diagnostic script `MQL5/Scripts/FuzzyAlgo/TestTickCacheDiff.mq5` exists for
  exactly this kind of verification: it diffs raw tick arrays (no OC/HL
  derivation) between native and cached fetches for a fixed set of windows, and
  separately between two native-only fetches a few seconds apart
  (`NativeVsNativeCheck`) to rule out the terminal's local tick store still
  settling/mutating in the background. As of the last run, both native-vs-cache
  and native-vs-native match exactly across all 8 tested windows — the tick
  fetch/cache layer is confirmed stable and deterministic. Kept in the repo
  intentionally as a standing regression tool, not a throwaway script — a future
  refactor is planned to fold this comparison capability into `variables.mqh`
  itself as a general-purpose "compare two ring buffers / tick arrays / value
  sets" function, with `TestVariables.mq5` driving one cache=true and one
  cache=false run and diffing the resulting ring buffers directly, instead of
  a separate diagnostic script. Not done yet — deferred until after this Phase 1
  commit.
- **Observed 2026-09-07: a stale cache CSV can make cache=true and cache=false
  `TestVariables.mq5` runs disagree on real `OC`/`HL` values (not just the
  already-understood SUM_POS/SUM_NEG rounding noise above)** — a paired run
  (cache=false at 16:45, cache=true at 16:49, both for `2026.09.04` EURUSD)
  showed several whole-point mismatches in `S3600`/`REF`'s `OC`/`HL` (e.g.
  15:04:00 REF HL 33 vs 34, 15:21:00 S3600 OC 10 vs 11, 15:30:00 REF HL 68 vs
  69) — a real difference in the *tick set* fetched, not a display artifact.
  The cache=true run's `[TickCache] ... existed=true` line confirmed it loaded
  a **pre-existing** `EURUSD_20260904.csv`, built by some earlier run, while
  cache=false's native `CopyTicksRange` reflects the broker's tick history
  *as of the moment it ran*. Even though `2026.09.04` is a past date, the
  broker feed can still revise/backfill historical tick data between when the
  cache CSV was written and when a later native call re-fetches the same
  window — so an old cache file and a fresh native fetch are not guaranteed to
  agree, and a mismatch here does not necessarily indicate a bug in
  `CopyTicksRange_g`'s slicing logic itself. This is the same class of risk
  `TestTickCacheDiff.mq5`'s `NativeVsNativeCheck` was built to catch (see
  above) — that script fetches native and cache *within one execution*, so
  it's immune to this drift, and it has continued to show exact matches.
  **Not yet root-caused as a pure `TickCache.mqh` bug vs. genuine upstream
  data revision** — before the planned refactor (folding this comparison into
  `variables.mqh`), rerun the comparison right after deleting the stale
  `MQL5/Files/FuzzyAlgo/ticks_cache/EURUSD_20260904.csv` (forcing cache=true to
  rebuild from a fresh native fetch in the same rough time window as the
  cache=false run) to check whether the mismatches disappear; if they persist
  even with a freshly-built cache, that would point at a real slicing bug
  instead of feed drift.
- **`sRefPoint`'s constructor (`variables.mqh`, ~line 705) calls native
  `CopyTicks` directly, not `CopyTicks_g`** — it never routes through the cache
  regardless of `I_USE_TICK_CACHE`. Since `sRefPoint` runs once per script
  execution (not once per sample), this was a plausible suspect for run-to-run
  differences between separate `TestVariables.mq5` executions — **ruled out**:
  the actual root cause (below) was a display-layer rounding bug that affects
  both cached and native runs identically, unrelated to `sRefPoint`. Left
  uncached deliberately (single call per execution, not worth the cache
  plumbing), but still worth remembering if a *different* future symptom is
  anchor-timing-shaped.
- **Root cause of the `SUM_POS`/`SUM_NEG` ±1 mismatch between
  `I_USE_TICK_CACHE=true` and `=false` runs: found and fixed. It was a display
  rounding bug, not a tick-cache bug.** `SUM_POS`/`SUM_NEG` are theoretically
  always whole numbers (each tick contributes exactly one whole `point`-unit to
  the running delta sum), but summing thousands of per-tick doubles accumulates
  ~1e-8 of floating-point noise — harmless on its own, but `sSymbolVars::PrintRow`
  displayed them with a **truncating** `(int)` cast. Native and cache-sliced
  fetches accumulate that noise in a subtly different order (ticks sharing
  identical/adjacent `time_msc` can be summed in a different sequence), so the
  noise sometimes landed on the other side of a `.0`/`.5` boundary between the
  two modes — truncation then displayed a different integer even though the
  true (rounded) value was identical. Confirmed via a two-layer fingerprint
  technique (kept permanently, see "RTFP diagnostics" below) and fixed by
  changing `PrintRow`'s `(int)sData[p].d.SUM_POS` / `(int)sData[p].d.SUM_NEG` to
  `(int)MathRound(...)`. **Verified end-to-end**: a paired cache=true/cache=false
  run over `2026.09.04 14:59:51`–`15:46:00` (EURUSD) now matches exactly on
  every previously-flagged mismatch (15:02:00 and 15:03:00 S3600) and on every
  spot-checked value through the full run, including large swings (REF SUM_NEG
  reaching `-1544671` by 15:46:00, S3600 SUM_POS jumping to `95487` at 15:43:00)
  — all consistent with genuine price movement and REF/S3600 window semantics,
  not bugs. `OC`/`HL` never needed this fix — they're single-arithmetic values,
  not summed across the window, so they never accumulate this kind of noise.
  Phase 1 plan step 4 (full non-`LAT_US` diff between a complete cache=true and
  cache=false run) is now considered satisfied.
- **RTFP diagnostics** (short for "real-time fingerprint") — two Print layers
  added to `init_ticks_arr_g`'s REF and `SECONDS_S`/S`<n>` branches
  (`variables.mqh`) while root-causing the bug above, kept permanently behind
  `input int I_DEBUG >= 2` (0 is the default; 1 keeps the pre-existing
  `sPeriodVars::print()` behavior only) rather than deleted, since the same
  mismatch class could recur if the cache or native fetch path changes again:
  - **Aggregate fingerprint** (`RTFP REF`/`RTFP S<n>`): `bid_sum`/`ask_sum`/
    `time_sum`/`size`/`first_t`/`last_t` computed by iterating the raw
    `MqlTick` array right after `CopyTicksRange_g` returns. Proves the tick
    *set* fetched is identical between modes, but is insufficient on its own to
    catch an accumulation-order difference — floating-point addition is
    commutative to within ~1 ULP, so this layer can match exactly while
    `SUM_POS`/`SUM_NEG` still differ.
  - **Raw output fingerprint** (`RTFP REF RAW`/`RTFP S<n> RAW`): `SUM_POS`/
    `SUM_NEG` printed at 12-decimal precision, with no `(int)` cast, immediately
    after `init_data_from_ticks_arr_g` returns. This is what actually exposed
    the noise (e.g. `-12182.999999998943` vs `-12183.000000001766` — the same
    logical value, opposite sides of `-12183.0`) and proved it was a display
    artifact rather than a real data difference.
  - `TickCache.mqh`'s `FindOrLoadDayCache_g` also has a one-line `[TickCache]
    ... existed=... loaded=...` Print (confirms whether a run loaded a
    pre-existing CSV or built one fresh), gated behind its own
    `g_tick_cache_debug_g` file-scope int (mirrors `I_DEBUG`, set from it in
    `sConfigVars`'s constructor — `TickCache.mqh` can't reference `I_DEBUG`
    directly since it's `#include`d before that input is declared).
  - Any diagnostic comparing a freshly-fetched native tick/sum against a
    cache-reloaded one must normalize through the same round-trip the cache
    uses (`StringToDouble(DoubleToString(x, digits))`), never `NormalizeDouble`
    — see the CSV precision bullet above. This bit twice during this
    investigation before being written down here.

## Phase 2 plan: incremental accumulation for DAY/REF/PRO (drafted 2026-09-09, not yet implemented — refactoring first)

Phase 1 (above) removed the cost of re-*fetching* a growing window's ticks on
every sample. It did not remove the cost of re-*summing* that window:
`init_ticks_arr_g`'s `DAY`/`REF`/`PRO` branches (`variables.mqh`) each refetch
from their fixed anchor (midnight / ref-point / position-open-time) through
`in_time_msc` every sample, and `init_data_from_ticks_arr_g` resums the entire
window from scratch every time — this is the cost behind the "DAY period...
recompute from the full day's tick history on every call" open issue below,
and the reason `LAT_US` grows over a simulated run.

`DAY`/`REF`/`PRO` share a "growing window from a fixed anchor" shape (window
only extends, never shrinks/slides), making them incrementally accumulable.
`SECONDS_S`/`TICKS_T` are sliding windows (both ends move) and are explicitly
**out of scope** for this phase — eviction on the trailing edge is a much
harder problem (risks dropping the current max/min needed for `HL`).

Confirmed during planning: nothing outside `variables.mqh` reads the full
per-tick `ticks_arr` array `init_data_from_ticks_arr_g` populates for
DAY/REF/PRO (grepped `ticks_arr` across all of `MetaTrader5_TMPL/MQL5`), so an
incremental design that only maintains running aggregates (not a full
reconstructed per-tick array) is safe for these three period types.

**Correctness risk identified**: two consecutive samples' fetch windows must
overlap at exactly the previous sample's `in_time_msc`, or same-millisecond
boundary ticks can be lost (non-overlapping `from = last+1`) or double-counted
(naive overlapping `from = last`). Planned mitigation: fetch
`[last_time_msc, in_time_msc]` inclusive, then skip exactly the leading ticks
that structurally match (bid/ask/last/volume/flags/volume_real) the tie-set
already consumed at `last_time_msc` on the previous call. This only needs to
hold *within one script execution* — the tick-revision risk documented above
is a cross-run phenomenon; `TestTickCacheDiff.mq5`'s `NativeVsNativeCheck`
already proved repeated native fetches of the same window are byte-identical
within a single run, which is exactly the property this depends on. A backward
time seek, or a failed tie-check, forces a full rebuild rather than trusting
stale state (self-healing, logged via `I_DEBUG`, not silently masked).

**Design sketch**:
- New `sIncrAccum` struct (new file `IncrAccum.mqh`, included the way
  `TickCache.mqh` is): `symbol`, `period_type`, `anchor_msc`, `last_time_msc`,
  `tie_ticks[]` (boundary dedup), plus the running aggregate fields
  `init_data_from_ticks_arr_g` currently derives (`c0`/`t0`/`sum_pos`/
  `sum_neg`/`hi`/`lo`/etc.).
- File-scope registry `g_incr_accums_g[]` keyed by `(symbol, period_type)`
  (sufficient since DAY/REF/PRO each occur at most once per symbol), with a
  `FindOrCreateIncrAccum_g` lookup-or-create function mirroring
  `TickCache.mqh`'s `FindOrLoadDayCache_g` pattern.
- `UpdateIncrAccum_g`: full reset (reuse today's existing resum logic
  verbatim) when invalid, anchor changed (DAY's midnight rollover, PRO's
  position closed/reopened at a different `POSITION_TIME_MSC`), or time went
  backward; otherwise incremental fold-in via the tie-boundary dedup above.
  `REF`'s anchor is fixed for the script's lifetime (same lifetime as the
  registry), so it never resets within a run.
- Gated by new `input bool I_USE_INCR_ACCUM = false;` (via
  `conf.c.USE_INCR_ACCUM`), following `I_USE_TICK_CACHE`'s exact precedent —
  the existing full-resum path stays untouched as the fallback/reference until
  proven correct.
- Validation follows Phase 1's pattern exactly: extend
  `TestTickCacheDiff.mq5` (or add `TestIncrAccumDiff.mq5`) to run both
  `I_USE_INCR_ACCUM=false` and `=true` across the same simulated time range and
  assert `OC`/`HL`/`SUM_POS`/`SUM_NEG`/`NETFLOW`/`c0`/`t0` match exactly on
  every sample, including across a midnight boundary and a position
  close/reopen. Only flip the default to `true` once that passes cleanly.

**Deliberately deferred**: implementing this directly on top of the current
code would leave two parallel, easily-diverging implementations of DAY/REF/PRO
window logic (old full-resum path kept as fallback + new incremental path) —
a refactor to consolidate/share logic between them is planned first, before
Phase 2 lands.

## TestVariables.mq5: cache=false vs cache=true validation harness (drafted 2026-09-09, not yet implemented)

### Context

Phase 1 (tick cache, `TickCache.mqh`) is shipped and confirmed correct at the
raw-tick level via `TestTickCacheDiff.mq5`. Before starting the bigger planned
refactor (unifying `TickCache.mqh`'s data structures into `variables.mqh` and
bundling helper functions into a struct/class that shares `sConfigVars`'s `c`
so globals like `I_DEBUG` stop being "loose"), the user wants a stronger,
standing correctness harness built directly into `TestVariables.mq5`: run the
whole `sGlobalVars` object graph twice — once with the tick cache off, once
with it on — over the same 60 one-minute samples, and diff the results. This
proves "we haven't lost any ticks and all the calculations are right" at the
level that actually matters (the per-tick delta array each period's
OC/HL/SUM_POS/SUM_NEG/NETFLOW are derived from), not just at the raw
`MqlTick[]` level `TestTickCacheDiff.mq5` already covers.

Key correction from the user during planning: `sDataVars` (defined in
`variables.mqh`) already stores `double ticks_arr[]` — the full per-tick delta
series for that (symbol, period) window, populated by
`init_data_from_ticks_arr_g`. Every `sGlobalVars` snapshot in a ring buffer
already carries this via `sSym[s].sData[p].ticks_arr`, so no new plumbing is
needed to expose it — the harness should diff it directly between the two runs,
per (symbol, period, sample), using `TestTickCacheDiff.mq5`'s diff-reporting
style (first-N `DIFF[i]` lines, then a count, then a final MATCH/MISMATCH
summary line), plus a secondary check on the derived `sData` aggregate fields.

### Problem: `I_USE_TICK_CACHE` is a fixed `input`

`input bool I_USE_TICK_CACHE` cannot change value within one script execution,
and every level of the object graph (`init_ticks_arr_g` via a local
`sConfigVars conf` reading `conf.c.USE_TICK_CACHE`) reads it independently.
Running one cache=false and one cache=true `sGlobalVars` build in the same
`OnStart()` therefore requires threading an explicit override through the call
chain, bypassing `conf.c.USE_TICK_CACHE` for this call. This is additive only
— new parameter, new constructor overload — nothing existing changes shape or
behavior when the new parameter isn't supplied.

### Design

#### 1. Thread a `use_cache` override through `variables.mqh`

- `init_ticks_arr_g(...)`: add `const bool in_use_cache` parameter. Replace
  all 7 internal reads of `conf.c.USE_TICK_CACHE` (lines ~194, 254, 261, 314,
  321, 393, 443 — the `CopyTicksRange_g`/`CopyTicks_g` calls and the two RTFP
  `Print` labels) with `in_use_cache`. `conf` (the local `sConfigVars`) is
  still constructed for `conf.c.COPY_TICKS_FLAG`/`conf.c.DEBUG` — only the
  cache flag itself is overridden.
- `sDataVars::init(...)`: add `const bool _use_cache` parameter, pass through
  to `init_ticks_arr_g`.
- `sSymbolVars::init(...)`: add `const bool _use_cache` parameter, pass
  through to `sData[cnt].init(...)`.
- `sGlobalVars`: add a `bool use_cache` member. Keep the existing 1-arg and
  2-arg constructors unchanged in signature, defaulting `use_cache` to
  `I_USE_TICK_CACHE` in their member-init lists (so every existing call site in
  `TestVariables.mq5`/`TestFFT.mq5` keeps compiling with identical behavior).
  Add one new 3-arg overload `sGlobalVars(const datetime &_tmsc, const
  sRefPoint &_ref_point, const bool &_use_cache)` that sets `use_cache`
  explicitly. `sGlobalVarsImpl()` passes `use_cache` into
  `sSym[cnt].init(time_msc, c.SYMBOLS_arr[cnt], cnt, ref_point, use_cache)`.

No changes to `sRefPoint` — it deliberately never uses the cache (documented,
single native `CopyTicks` call per run) and stays that way.

#### 2. New comparison functions in `variables.mqh`

Placed near the bottom, after `sGlobalVars`, following `TestTickCacheDiff.mq5`'s
existing diff-reporting shape:

- `int CompareDataVars_g(const sDataVars &a, const sDataVars &b, const string &context)`
  - Compares `ArraySize(a.ticks_arr)` vs `ArraySize(b.ticks_arr)`; prints a
    SIZE MISMATCH line and returns early (with a nonzero mismatch count) if
    they differ.
  - Loops index-by-index comparing `a.ticks_arr[i] == b.ticks_arr[i]` (exact
    double equality — expected to hold exactly given Phase 1 already proved
    the underlying tick sets match after digits-normalization, and each
    `ticks_arr[i]` is computed once, independently, with no iterative
    accumulation noise). Prints the first 5 `DIFF[i]` lines
    (`a.ticks_arr[i]` vs `b.ticks_arr[i]`), then a total diff count.
  - Also compares the derived `sData` fields: exact-int equality for
    `OC`/`HL`/`VOLS`/`TD`/`SPREAD`; `MathRound`-to-int equality for
    `SUM_POS`/`SUM_NEG` (matching `PrintRow`'s established display-equivalence
    contract) — if the rounded values match but the raw doubles don't, print
    an RTFP-style raw-value note (informational, not a failure); small-epsilon
    (1e-9) equality for `NETFLOW`/`OC_HL`/`VOLS_TD`/`HL_TD`/`SUMCOL`; exact
    equality for `c0`/`c1`/`t0`/`t1`.
  - Prints one final line per (symbol, period, sample): "MATCH exactly (N
    ticks)" or "MISMATCH (n diffs)", mirroring
    `TestTickCacheDiff.mq5`'s per-window summary line.
  - Returns the total mismatch count (ticks_arr diffs + sData field diffs).

- `int CompareGlobalVars_g(const sGlobalVars &a, const sGlobalVars &b, const string &context)`
  - Loops every symbol × every period (`a.sSym[s].sData[p]` vs
    `b.sSym[s].sData[p]`), calling `CompareDataVars_g` for each, summing
    mismatch counts.
  - Prints one overall line for this sample: total mismatches across all
    symbol×period combinations (0 = full match).
  - Returns the total.

If a real mismatch surfaces, whether it's a genuine bug or a same-millisecond
tie-order difference between native and cached fetches (a known possibility,
per this file's RTFP writeup above) is a drill-down for that moment — no
speculative tie-detection logic is being pre-built now, consistent with how
the RTFP diagnostics were added only after an actual mismatch was found.

#### 3. Wire up the harness in `TestVariables.mq5`

Add a new function (e.g. `RunCacheComparisonHarness_g(const long in_time_msc,
const sRefPoint &sr)`) called near the top of `OnStart()`, before the existing
ring-buffer demo/live loop (which stay untouched):

- `sRingBuf<sGlobalVars> ring_native, ring_cached;` both `init(60, false)`.
- Loop `min_cnt` from 59 down to 0 (oldest to newest, matching the existing
  seed-fill pattern): `time_msc = in_time_msc - min_cnt * 60 * 1000`; build
  `sGlobalVars g_native(time_msc, sr, false)` and `sGlobalVars g_cached(time_msc,
  sr, true)`; `AddBuf` each into its ring.
- Loop `i` from 0 to 59: `TryGet` both rings at `i`, call
  `CompareGlobalVars_g(native, cached, label)` where `label` includes the
  sample's timestamp.
- After the loop, print a final grand-total mismatch count across all 60
  samples ("ALL 60 SAMPLES MATCH EXACTLY" or "N total mismatches across 60
  samples — see above").

### Files touched

- `MetaTrader5_TMPL/MQL5/Include/FuzzyAlgo/variables.mqh` — thread `use_cache`
  through `init_ticks_arr_g`/`sDataVars::init`/`sSymbolVars::init`/new
  `sGlobalVars` 3-arg constructor; add `CompareDataVars_g`/`CompareGlobalVars_g`.
- `MetaTrader5_TMPL/MQL5/Scripts/FuzzyAlgo/TestVariables.mq5` — add
  `RunCacheComparisonHarness_g`, call it from `OnStart()` before the existing
  demo/live-loop code (which is left as-is).

### Verification

1. Compile both files per this file's documented `MetaEditor64.exe /compile`
   command (once for `TestVariables.mq5`), check the `.log` for `0 errors`.
2. Run the script in the terminal (or via script execution in MetaEditor) with
   `doLive=false` against the existing 2026.09.04 EURUSD/GBPJPY/etc. window
   already used for Phase 1 validation, confirm the harness prints "ALL 60
   SAMPLES MATCH EXACTLY" (or investigate any reported `DIFF`/`MISMATCH` lines
   before proceeding — do not paper over a real mismatch).
3. Confirm the existing ring-buffer demo and live loop still behave exactly as
   before (unchanged output), proving the new 3-arg `sGlobalVars` overload and
   parameter threading didn't disturb existing call sites.

## Known open issues (TestVariables.mq5)

- **EURUSD `sRefPoint`/`CopyTicks` intermittently returns 0 results** — seen as
  `XX EURUSD ... price: 0.00000` while other symbols (EURGBP/GBPJPY/NZDUSD) succeeded
  (`OK ...`) in the same run; in other runs EURUSD came back `OK`, so it's intermittent,
  not constant. Corrupts the `c0_ref`-based delta column for EURUSD when it happens. If
  reported again, check `sRefPoint`'s `CopyTicks` call/retry logic in
  `MQL5/Include/FuzzyAlgo/variables.mqh` first.
- ~~**Ref-delta in `PrintRow` (formerly `PrintSampleInfo`) is period-0-only, not a real per-period metric**~~
  — **fixed.** A dedicated `ENUM_PERIOD_TYPE_REF` period type now computes its own
  `OC`/`HL`/`SUM_POS`/`SUM_NEG`/`NETFLOW` relative to the ref point (`init_ticks_arr_g`'s
  REF branch, `variables.mqh`), and `PrintRow` locates the REF slot by `period_type`
  (`sSymbolVars::PrintRow`, `variables.mqh`) instead of assuming `sData[0]`. Add `"REF"`
  to `I_PERIODS` to enable it. Three states apply: before the ref point, REF's
  OC/HL/SUM_POS/SUM_NEG/NETFLOW stay at 0 (no elapsed window) but `c0` is still the real
  current price via a single-tick lookup; at the ref point, `REFDLT` is exactly 0; after
  it, values accumulate monotonically in magnitude from the anchor. Live-tested and
  confirmed correct in all three states.
- **`DAY` period's `SUM_POS`/`SUM_NEG` recompute from the full day's tick history on
  every call, so a "frozen" value can look like a bug but usually isn't** —
  `init_ticks_arr_g`'s `ENUM_PERIOD_TYPE_DAY` branch (`variables.mqh`) calls
  `CopyTicksRange` from midnight (`start_time_day_msc`) through the current sample time
  on every single call, and `init_data_from_ticks_arr_g` resets `SUM_POS`/`SUM_NEG` to
  `0` and resums the whole window each time — nothing is accumulated incrementally. In
  a live run GBPJPY's `DAY` row showed `SUM_NEG` pinned at `-2827809` from sample
  `14:59:51.000` through `15:01:00.000` while `SUM_POS`/`OC` kept climbing; that's
  consistent with no further down-ticks occurring in that window (an early sharp drop
  followed by a sustained rally), not staleness. The real issue is cost: every sample
  rescans the entire day's ticks, so `CopyTicksRange` plus the summation loop get more
  expensive as the trading day progresses — worth accumulating incrementally instead of
  recomputing from scratch if this becomes a bottleneck.
- ~~**Live loop in `OnStart` prints a lagged ring-buffer entry, not the sample it just
  added**~~ — **fixed.** `ringbuf.init(ring_buf_num, false)` sets `indexNewest = false`,
  so logical index `0` means "oldest buffered entry", not "the one just added" —
  `TryGet(0, tmp)` was replaying the seed-fill backlog one iteration late instead of
  showing the sample `AddBuf` had just pushed. The live loop (`TestVariables.mq5`) now
  calls `TryGet(ringbuf.Count() - 1, tmp)`, which is the newest logical index under
  `indexNewest = false` (`sRingBuf::MapLogicalToPhysical` maps it to `head - 1`). Confirmed
  live: after the ring-buffer dump ends at `15:00:00.000`, the loop's first iteration
  reprints `15:00:00.000` once more (same instant, `LAT_MS 0` — expected, since
  `min_cnt=0`'s simulated time equals `in_time_msc`), then advances cleanly to
  `15:01:00.000`, `15:02:00.000`, etc. with no repeats or skipped minutes.
