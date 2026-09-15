# Repository notes (full historical detail)

> This file is the full verbatim archive of the former monolithic
> `CLAUDE.md` (pre-2026-09-13 split into a short documentation map plus
> `docs/architecture.md`, `docs/mql5-development.md`, `docs/known-issues.md`,
> `docs/design-decisions.md`, and `docs/changelog.md`). It is **not frozen**:
> it continues as the living, append-only, full-detail investigation log
> going forward — new deep-dive root-cause writeups get appended here in
> full, exactly as the old "Historical investigation notes" section below
> was maintained, because that kind of reasoning is cheap to re-read and
> expensive to re-derive. The focused docs above only ever carry a condensed
> pointer into this file; if you need the full story behind a decision or a
> bug, it's here.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**This file is long and grows over time.** The copy auto-injected into context via
`<system-reminder>` at session start can be silently truncated (look for a
`[N lines truncated]` marker). Before answering any "recap" / "what's the state of X" /
"summarize the project" request, `Read` this file directly (and check `git log`) rather
than trusting the auto-injected excerpt — otherwise a whole section can be missed with
no visible sign anything is wrong.

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

There is no automated test suite (no pytest, no MQL5 unit-test harness) — "testing" a
change means either running a Python script directly against a live/demo MT5 terminal, or
compiling + running an `.mq5` script in the terminal and inspecting its printed output
(see the cache-comparison harness below for the closest thing to a regression test that
exists in this repo).

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
whenever the per-user JSON files derived from `config_RoboForex-ECN/*.tmpl`
(`cf_accounts`, `cf_periods`, `cf_symbols`, `cf_pid_params`) are missing.
Per-user account credentials live in `cf_accounts_<user>@<host>.json` (gitignored) — never cat
or commit these.

## MQL5 side (`MetaTrader5_TMPL/MQL5/.../FuzzyAlgo/`)

- `MQL5/Include/FuzzyAlgo/variables.mqh` (~1,440 lines) is the core data model: `sConfig`
  (per-run config, composed into every other struct below), `sData`/`sDataVars` (per-symbol,
  per-period derived tick features — `OC`/`HL`/`SUM_POS`/`SUM_NEG`/`NETFLOW`/etc., plus the
  raw per-tick delta series `ticks_arr`), `sRefPoint` (a single fixed reference tick, native
  `CopyTicks` only, never cached), `sSymbolVars` (all periods for one symbol), `sGlobalVars`
  (all symbols for one sample), and `sRingBuf<T>` (a fixed-size ring buffer used to hold
  recent `sGlobalVars` snapshots). `ENUM_PERIOD_TYPE` (DAY/PRO/REF/SECONDS_S/TICKS_T) selects
  how each period's tick window is anchored. `CompareDataVars_g`/`CompareGlobalVars_g` at the
  bottom of this file are the cache-comparison harness's diffing functions (see below).
- `MQL5/Include/FuzzyAlgo/TickCache.mqh` caches a full day's ticks per symbol to CSV so a
  closed-market/backtest run can replay ticks without re-hitting the terminal's tick store on
  every sample. Gated by `input bool I_USE_TICK_CACHE` / `conf.c.USE_TICK_CACHE`. See the
  historical notes below for the precision bugs this surfaced and how they were fixed.
- `MQL5/Include/FuzzyAlgo/HistogramChart.mqh` — charting helper, not otherwise load-bearing to
  the data model above.
- `MQL5/Scripts/FuzzyAlgo/TestVariables.mq5` — the main script; builds the object graph above
  per sample (live loop or closed-market/backtest via `doLive`), and (as of 2026-09-10) runs
  the cache=false vs cache=true comparison harness before the existing demo/live loop.
- `MQL5/Scripts/FuzzyAlgo/TestTickCacheDiff.mq5` — standing diagnostic/regression script that
  diffs raw tick arrays between native and cached fetches, and native-vs-native a few seconds
  apart, to catch cache- or feed-related discrepancies. Not a throwaway script — kept
  intentionally as a regression tool.
- `MQL5/Scripts/FuzzyAlgo/TestFFT.mq5` — separate FFT-based script, uses the same `variables.mqh`
  object graph but is not part of the tick-cache investigation below.
- `MQL5/Files/FuzzyAlgo/ticks_cache/` — where `TickCache.mqh` writes/reads per-symbol,
  per-day CSV tick caches (gitignored).

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

## Known open issues (TestVariables.mq5)

- **EURUSD `sRefPoint`/`CopyTicks` intermittently returns 0 results** — seen as
  `XX EURUSD ... price: 0.00000` while other symbols (EURGBP/GBPJPY/NZDUSD) succeeded
  (`OK ...`) in the same run; in other runs EURUSD came back `OK`, so it's intermittent,
  not constant. Corrupts the `c0_ref`-based delta column for EURUSD when it happens. If
  reported again, check `sRefPoint`'s `CopyTicks` call/retry logic in
  `MQL5/Include/FuzzyAlgo/variables.mqh` first.
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
  recomputing from scratch if this becomes a bottleneck (see the Phase 2 plan below,
  which addresses exactly this).

Two issues from earlier investigations have already been fixed and are kept here only
as pointers into the historical notes below, in case similar symptoms recur:
- Ref-delta being period-0-only instead of a real per-period REF metric — fixed via a
  dedicated `ENUM_PERIOD_TYPE_REF` period type.
- The live loop printing a lagged ring-buffer entry instead of the sample it just
  added — fixed by reading `ringbuf.Count() - 1` instead of index `0`.

## Historical investigation notes (MQL5 tick cache)

This section is a chronological record of the tick-cache work: what was built, what broke,
how it was root-caused, and how it was fixed. It's kept in full (not summarized) because the
root-cause reasoning — especially the floating-point/rounding traps — is exactly the kind of
thing that's cheap to re-read and expensive to re-derive if a similar symptom resurfaces.
Skip this section unless you're touching `TickCache.mqh`, the cache-related parts of
`variables.mqh`, or debugging a native-vs-cache mismatch.

### Tick cache for closed-market/backtest testing (TickCache.mqh)

`MQL5/Include/FuzzyAlgo/TickCache.mqh` caches a full calendar day's ticks for a
symbol to CSV under `MQL5/Files/FuzzyAlgo/ticks_cache/` so a closed-market/backtest
run (`doLive=false` in `TestVariables.mq5`) can replay the same day's ticks without
re-issuing `CopyTicksRange`/`CopyTicks` against the terminal's tick store on every
sample. This is Phase 1 of a two-phase latency fix (`LAT_US` growing ~3x over a
simulated run) — Phase 1 removes fetch cost only; Phase 2 (incremental
accumulation to fix `init_data_from_ticks_arr_g`'s resum cost, see `DAY`'s open
issue above) is deferred until Phase 1 is confirmed fully correct.

- `variables.mqh` routes 7 call sites (DAY/PRO×2/REF×2/SECONDS_S/TICKS_T) through
  `CopyTicksRange_g`, gated by `input bool I_USE_TICK_CACHE` (via
  `conf.c.USE_TICK_CACHE`). Cache-mode failures (window spans two calendar days,
  load failure) return `-1` — **no native fallback** by design, so a cache bug
  surfaces as a visible error rather than being silently masked. All existing
  callers already gate on `if (0 < size1)`, so `-1` degrades identically to `0`
  (skip resum, leave derived data untouched) — no caller-side changes were needed
  when the fallback was removed.
- **CSV bid/ask/last precision (superseded 2026-09-09, see the full-precision
  fix below) originally used the symbol's `SYMBOL_DIGITS`** (`WriteTicksToCsv_g`'s
  `digits` param, from `SymbolInfoInteger(symbol, SYMBOL_DIGITS)`) — an earlier
  fixed 8-decimal format was insufficient to round-trip a double exactly through
  CSV text, causing ~1-ULP native-vs-cache differences that occasionally flipped
  tick up/down classification in `OC`/`HL`/`SUM_POS`/`SUM_NEG`. Volume/volume_real
  still use fixed 1-decimal precision (unaffected — never fed into the
  point-division that amplifies ULP noise, see below). Any diagnostic comparing
  a freshly-fetched native tick against a cache-reloaded one must normalize
  through the *same* round-trip currently in use (see the full-precision fix
  below — no `digits`-rounding normalization is needed anymore) — `NormalizeDouble`
  does floating-point arithmetic rounding and does **not** reliably produce the
  same bit pattern as a decimal-string round-trip, and will report false-positive
  diffs.
- `CopyTicksRange_g` must slice/search the cached struct's `ticks[]`
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
  **Root-caused 2026-09-09, not a slicing bug or feed drift**: the user
  performed exactly this isolation test (fresh native run, delete the stale
  CSV, rebuild cache immediately after) and the ±1 mismatches persisted
  regardless — ruling out cross-run cache staleness. The actual cause was the
  CSV round-trip precision issue documented in the `OC`/`HL` follow-up bullet
  below (fixed by writing bid/ask/last at full round-trip precision instead of
  `SYMBOL_DIGITS`) — unrelated to whether the CSV was freshly built or
  pre-existing.
- **`sRefPoint`'s constructor (`variables.mqh`, ~line 705) calls native
  `CopyTicks` directly** — it never routes through the cache
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
  not bugs. **Update 2026-09-09: `OC`/`HL` turned out to need analogous
  treatment after all** — see below; the "never needed this fix" conclusion
  here held only for the display-rounding half of the fix, not the later
  discovery that `OC`/`HL`'s *raw* division-derived doubles can themselves
  straddle a truncation/rounding boundary.
  Phase 1 plan step 4 (full non-`LAT_US` diff between a complete cache=true and
  cache=false run) is now considered satisfied.
- **Follow-up 2026-09-09: `OC`/`HL` had the same class of native-vs-cache ±1
  mismatch as `SUM_POS`/`SUM_NEG` above, for a related but distinct reason —
  found and fully fixed in two steps.** `TestVariables.mq5` cache=false vs
  cache=true runs over `2026.09.04` disagreed on several whole-point `OC`/`HL`
  values (e.g. 15:04:00 REF HL 33 vs 34, 15:21:00 S3600 OC 10 vs 11) even after
  confirming (per the user's own isolation test — fresh native run, delete the
  stale CSV, rebuild cache immediately after) that stale cross-run cache data
  was not the cause.
  - **Step 1 — `MathRound`**: unlike `SUM_POS`/`SUM_NEG`, `OC`/`HL` are each a
    single arithmetic result (`(c0-c1)/point`, `(high-low)/point`), not an
    accumulated sum, so they don't pick up *order-of-summation* noise — but
    they can still land within ~1e-11 of an integer/half-integer boundary due
    to ULP-level bit-pattern differences between a native in-memory double and
    a CSV-round-tripped one, then get amplified ~10^5x by the division by
    `point` (~0.00001 for 5-digit EURUSD). `init_data_from_ticks_arr_g`'s `OC`/
    `HL` assignments (`variables.mqh`) were truncating (`(int)(...)`) instead of
    rounding, exactly like the pre-fix `PrintRow` truncation above — changed to
    `(int)MathRound(...)`. This fixed most, but not all, of the observed
    mismatches — a new diagnostic (`ComputeOcHlRaw_g`/`CompareOcHlDerivation` in
    `TestTickCacheDiff.mq5`, see below) proved the 3 survivors' underlying raw
    `OC` values genuinely differed *before* rounding too (e.g.
    `OC_raw(native=32.499999999991 cache=32.500000000013)`), sitting almost
    exactly on a `.5` boundary — not fixable by changing which rounding
    function is applied, since the two sides' true inputs actually differed.
  - **Step 2 — full CSV round-trip precision (the real fix for the 3
    survivors)**: `WriteTicksToCsv_g` (`TickCache.mqh`) was writing bid/ask/last
    at `SYMBOL_DIGITS` (5 for EURUSD) instead of a precision sufficient to
    round-trip the double's exact bit pattern. Changed to a fixed
    `TICK_CACHE_ROUNDTRIP_DIGITS_G = 16` (a double has ~17 significant decimal
    digits total; 16 fractional digits is comfortably enough for any FX price
    with a single-digit integer part) for bid/ask/last specifically —
    volume/volume_real remain at 1-decimal precision, since they never feed the
    point-division that amplifies this noise. **Verified fully fixed**: rerunning
    `TestTickCacheDiff.mq5` after this change showed `OC_raw`/`HL_raw` identical
    to 12 decimals between native and cache in *every* tested window (not just
    matching after rounding) — including the 3 that survived Step 1 alone. This
    also retroactively obsoleted the CSV-precision bullet above (moved the cache
    from "`SYMBOL_DIGITS`, must digits-normalize before comparing" to "full
    round-trip precision, no normalization needed").
  - **Diagnostic tooling added during this investigation, kept permanently in
    `TestTickCacheDiff.mq5`**: `ComputeOcHlRaw_g` mirrors
    `init_data_from_ticks_arr_g`'s `c0`/`c1`/`OC` and `high`/`low`/`HL`
    derivation exactly, returning the raw undivided doubles plus the array
    index of whichever tick produced the high/low extreme.
    `CompareOcHlDerivation` runs it on both native and cache tick arrays for a
    window and prints `OC_raw`/`OC_trunc`/`OC_round` and `HL_raw`/`HL_trunc`/
    `HL_round` for both sides, flags a `>>> TRUNCATION FLIP` when only the
    truncated ints differ, flags `>>> STILL DIFFERS AFTER ROUNDING` when even
    the rounded ints differ (a real, non-artifact difference), and — when HL's
    extreme-tick index differs between native and cache — prints the specific
    candidate tick from each side so a "different tick selected" scenario is
    distinguishable from "same tick, precision wobble." The test window set in
    `OnStart()` was also extended from 8 to 10 timestamps (added 15:14:00,
    15:16:00) to include two more windows a clean-cache comparison had flagged.
  - **Also fixed as part of Step 2**: `TestTickCacheDiff.mq5`'s existing
    `DIFF[...]` check (distinct from `RAWDIFF[...]`) was left over from when the
    cache stored `SYMBOL_DIGITS`-precision values — it rounded only the native
    side to `digits` before comparing against the cache side, which after Step
    2 compares a deliberately-rounded value against a full-precision one and
    manufactures a false mismatch. Fixed to round *both* sides through the same
    `digits` round-trip before comparing (matches `RAWDIFF`'s already-correct,
    unrounded-both-sides comparison, just at display precision instead of raw).
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

### Phase 2 plan: incremental accumulation for DAY/REF/PRO (drafted 2026-09-09, not yet implemented — refactoring first)

Phase 1 (above) removed the cost of re-*fetching* a growing window's ticks on
every sample. It did not remove the cost of re-*summing* that window:
`init_ticks_arr_g`'s `DAY`/`REF`/`PRO` branches (`variables.mqh`) each refetch
from their fixed anchor (midnight / ref-point / position-open-time) through
`in_time_msc` every sample, and `init_data_from_ticks_arr_g` resums the entire
window from scratch every time — this is the cost behind the "DAY period...
recompute from the full day's tick history on every call" open issue above,
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

### `sConfig` composition refactor (implemented 2026-09-09 — foundation for the cache-comparison harness below)

`sConfigVars` was inherited by `sDataVars`, `sRefPoint`, `sSymbolVars`, and
`sGlobalVars`, and its constructor unconditionally rebuilt `c` straight from
the compiled-in `input I_*` globals every time one of these structs was
constructed — there was no way to hand a struct a config value that differed
from those inputs. This blocked the harness design below, which needs two
`sGlobalVars` object graphs in one script run differing only in
`USE_TICK_CACHE`. Threading a single `bool in_use_cache` override through the
call chain would have solved that one flag but not generalized — the next
flag needing per-instance variation would mean threading a second raw
parameter through the same layers again.

Fixed by replacing inheritance with composition, so any future flag is a field
flip on a copied struct, not a new parameter thread:

- `sConfig` (`variables.mqh`) is now a top-level struct with its own
  constructor (reading `I_ACCOUNT`/`I_SYMBOLS`/`I_PERIODS`/`I_HOSTS`/
  `I_COPY_TICKS_FLAG`/`I_DEBUG`/`I_EVENT_TIMER_INTERVAL_MSC`/`I_USE_TICK_CACHE`
  — unchanged behavior from the old `sConfigVars()`). `struct sConfigVars` no
  longer exists.
- `get_period_num_and_type_g` (renamed from the old inherited
  `get_period_num_and_type`) is a free function at file scope — it never read
  `c`, so it never belonged on a config struct.
- `sDataVars`/`sRefPoint`/`sSymbolVars`/`sGlobalVars` each hold an explicit
  `sConfig c;` member instead of inheriting — `g.c.SYMBOLS`-style external
  reads (`TestVariables.mq5`, `TestFFT.mq5`) are unchanged, since that syntax
  is identical whether `c` comes from inheritance or plain composition.
- `init_ticks_arr_g`, `sDataVars::init`, and `sSymbolVars::init` each take an
  explicit `const sConfig &in_conf` parameter now (no more implicit `conf.c.*`
  via inheritance). `sGlobalVars` keeps its existing 0/1/2-arg constructors'
  signatures and behavior unchanged (each still default-constructs its own
  `c`), plus a new 3-arg overload —
  `sGlobalVars(const datetime &_tmsc, const sRefPoint &_ref_point, const sConfig &_conf)`
  — that sets `c = _conf` explicitly and threads it through
  `sGlobalVarsImpl()`. `sRefPoint` is unaffected (its own default-constructed
  `c`, never overridden — it deliberately never uses the cache, per the
  already-documented decision above).
- Building a differently-configured `sGlobalVars` is now a plain struct copy:
  `sConfig cfg_cached = cfg; cfg_cached.USE_TICK_CACHE = true;` then
  `sGlobalVars g_cached(time_msc, sr, cfg_cached);` — no bool-threading
  plumbing needed.

Verified: this was a pure internal restructuring with zero output changes for
any existing call site — confirmed by compiling and running `TestVariables.mq5`
and `TestFFT.mq5` (0 errors/0 warnings on both) with output unchanged from
pre-refactor.

### TestVariables.mq5: cache=false vs cache=true validation harness (implemented and verified 2026-09-10 — 60/60 samples match exactly)

#### Context

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

#### Problem: `I_USE_TICK_CACHE` is a fixed `input` — solved by the `sConfig` refactor above

`input bool I_USE_TICK_CACHE` cannot change value within one script execution,
and every level of the object graph read it independently via inheritance.
Running one cache=false and one cache=true `sGlobalVars` build in the same
`OnStart()` therefore needed an explicit override threaded through the call
chain. Rather than threading a single raw `bool`, the `sConfig` composition
refactor documented above (implemented 2026-09-09) solves this generally: any
`sGlobalVars` graph can now be built from an explicitly-supplied, possibly
overridden `sConfig` value.

#### Design

##### 1. `sConfig`-threading — already implemented (see the composition refactor above)

- `init_ticks_arr_g(...)`, `sDataVars::init(...)`, and `sSymbolVars::init(...)`
  each already take an explicit `const sConfig &in_conf` parameter — done as
  part of the composition refactor above, not as a separate bool-threading
  step.
- `sGlobalVars` already has the new 3-arg overload
  `sGlobalVars(const datetime &_tmsc, const sRefPoint &_ref_point, const sConfig &_conf)`
  that sets `c = _conf` explicitly and threads it through `sGlobalVarsImpl()`.
  The existing 0/1/2-arg constructors are unchanged.
- Step 5 below is the harness's own call-site usage of this — building two
  `sConfig` copies that differ only in `USE_TICK_CACHE`:
  ```mql5
  sConfig cfg;                    // real inputs, built once
  sConfig cfg_native = cfg; cfg_native.USE_TICK_CACHE = false;
  sConfig cfg_cached = cfg; cfg_cached.USE_TICK_CACHE = true;
  ...
  sGlobalVars g_native(time_msc, sr, cfg_native);
  sGlobalVars g_cached(time_msc, sr, cfg_cached);
  ```

No changes needed to `sRefPoint` — it deliberately never uses the cache
(documented, single native `CopyTicks` call per run) and stays that way.

##### 2. New comparison functions in `variables.mqh`

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

##### 3. Wire up the harness in `TestVariables.mq5`

Add a new function (e.g. `RunCacheComparisonHarness_g(const long in_time_msc,
const sRefPoint &sr)`) called near the top of `OnStart()`, before the existing
ring-buffer demo/live loop (which stay untouched):

- `sRingBuf<sGlobalVars> ring_native, ring_cached;` both `init(60, false)`.
- Loop `min_cnt` from 59 down to 0 (oldest to newest, matching the existing
  seed-fill pattern): `time_msc = in_time_msc - min_cnt * 60 * 1000`; build
  `sConfig cfg_native = cfg; cfg_native.USE_TICK_CACHE = false;` and
  `sConfig cfg_cached = cfg; cfg_cached.USE_TICK_CACHE = true;`, then
  `sGlobalVars g_native(time_msc, sr, cfg_native)` and
  `sGlobalVars g_cached(time_msc, sr, cfg_cached)`; `AddBuf` each into its ring.
- Loop `i` from 0 to 59: `TryGet` both rings at `i`, call
  `CompareGlobalVars_g(native, cached, label)` where `label` includes the
  sample's timestamp.
- After the loop, print a final grand-total mismatch count across all 60
  samples ("ALL 60 SAMPLES MATCH EXACTLY" or "N total mismatches across 60
  samples — see above").

#### Files touched

- `MetaTrader5_TMPL/MQL5/Include/FuzzyAlgo/variables.mqh` — `sConfig`-threading
  through `init_ticks_arr_g`/`sDataVars::init`/`sSymbolVars::init`/the
  `sGlobalVars` 3-arg constructor (see the composition refactor above), plus
  `CompareDataVars_g`/`CompareGlobalVars_g`.
- `MetaTrader5_TMPL/MQL5/Scripts/FuzzyAlgo/TestVariables.mq5` —
  `RunCacheComparisonHarness_g`, called from `OnStart()` before the existing
  demo/live-loop code (left as-is).

#### Verification — passed 2026-09-10

Compiled clean (0 errors) and run with `doLive=false` against the
2026.09.04 15:00:00 EURUSD window, walking `sr_harness`'s REF anchor forward
through 60 one-minute samples (15:00:00→15:59:00). REF's tick count grew
monotonically every sample (91 → 11,641 ticks), confirming REF was actually
exercised rather than stuck at its zero-window guard — this required the
harness to sample *forward* from the anchor, not backward (see the
`RunCacheComparisonHarness_g` header comment in `TestVariables.mq5` for why
backward samples never leave the zero-window guard). PRO stayed at "0 ticks"
throughout every sample, expected since the test account has no open
position (`c0` still resolves via the no-position branch; everything else
stays 0 — not a bug).

Every symbol×period combination (PRO/REF/DAY/S3600) reported zero mismatches
at every sample, and the harness printed `ALL 60 SAMPLES MATCH EXACTLY`. The
pre-existing ring-buffer dump and live loop ran unchanged afterward,
confirming the new 3-arg `sGlobalVars` overload and `sConfig` threading
didn't disturb any existing call site.

### `GetSystemTime` (DLL import) vs native alternatives — findings 2026-09-11, staying on the DLL for now

`TestVariables.mq5`/`TestFFT.mq5`/`Ticks.mq5` each define their own
`GetSystemTimeMsc()` wrapper around the `kernel32.dll` `GetSystemTime`
import (`WinAPI/sysinfoapi.mqh`), used only in `doLive=true` branches to get
wall-clock time at millisecond resolution. This requires "Allow DLL imports"
to be enabled for the terminal/script, which the user would prefer to avoid
if a native (non-DLL) equivalent existed. Investigated three alternatives;
none is a real substitute — decision is to keep `GetSystemTime` and allow
DLL imports for now.

- **`SymbolInfoTick(symbol, tick)` → `tick.time_msc`**: rejected outright by
  the user, correctly — this is the time of the *last received tick*, not
  current wall-clock time. In a slow/quiet market it can be many seconds
  stale (the user's example: 15s old) while still being reported as "the
  time," with no indication anything is off. It's also symbol-specific
  (every symbol has its own last-tick time) and not routed through
  `TickCache.mqh` at all — there is no cached-tick equivalent of this call,
  so using it in `doLive` mode wouldn't interact with the Phase 1 tick cache
  one way or the other (cache is for closed-market/backtest replay only,
  `doLive=false`). Not going to be used for "what time is it" — see the
  deferred idea below for a legitimate *different* use of it.
- **`TimeCurrent()*1000 + (GetTickCount64() % 1000)`**: rejected.
  `TimeCurrent()` is server/broker time — defined as the time of the last
  quote received, i.e. it inherits the *exact same staleness problem* as
  `SymbolInfoTick`, just hidden one layer down (whole-second broker time
  instead of per-symbol tick time). Grafting live millisecond ticks from
  `GetTickCount64() % 1000` on top makes this actively worse, not better: the
  ms digits keep advancing smoothly every millisecond regardless of whether
  the underlying second is fresh or stale, so the composite value *looks*
  live and precise while silently being wrong — a worse failure mode than an
  honestly-stale timestamp, since there's no visible sign anything is off.
- **`TimeLocal()*1000 + (GetTickCount64() % 1000)`**: rejected for a
  different reason. `TimeLocal()` is real OS local time, not tick-gated, so
  it doesn't have the staleness problem above. But `GetTickCount64()` is
  milliseconds since boot — a completely separate clock with no defined
  phase relationship to wall-clock second boundaries. `% 1000` gives "how far
  into the boot-uptime clock's current second," not "how far into *this*
  wall-clock second" — those only coincide if the machine happened to boot at
  an exact whole-second boundary, which is arbitrary. So the ms component
  isn't noise around the right answer, it's a fixed-but-wrong offset (0-999ms)
  for the entire run, and it can't be calibrated away without reading real
  wall-clock time from somewhere — i.e. `GetSystemTime` itself. There's also
  a non-atomicity race: the two calls aren't taken together, so a wall-clock
  second rollover between the `TimeLocal()` read and the `GetTickCount64()`
  read can produce a spurious ~1-second glitch right at the boundary.
  `GetSystemTime()` avoids all of this because it's one atomic call returning
  year/month/day/hour/min/sec/ms together from a single live read —
  self-consistent by construction.
- **Conclusion**: no DLL-free way to get true OS wall-clock milliseconds was
  found in native MQL5. Decision (2026-09-11): keep `GetSystemTime` via the
  DLL import, accept "Allow DLL imports" as a requirement for `doLive=true`
  runs. Revisit later if a native option surfaces.

#### Deferred idea: `GetSystemTime` vs `SymbolInfoTick` delta as a staleness/volatility signal

Not `SymbolInfoTick` as a *replacement* for `GetSystemTime` (rejected above),
but as a second, complementary reading: `delta_msc = GetSystemTimeMsc() -
tick.time_msc` (per symbol) is "how old is this symbol's last tick, right
now." Ideally near zero; a large delta means either a technical problem
(broken connection, trade server down) or a genuinely quiet/illiquid moment
for that symbol specifically. Sketched (not implemented) uses for a future
live-mode refinement:

- **All symbols' deltas > ~30s simultaneously** → likely a connectivity/feed
  problem (broken internet, trade server temporarily down) rather than a
  market condition — a cross-symbol signal, not a per-symbol one.
- **One symbol's delta is a few seconds while others are fresh** → that
  symbol simply hasn't ticked; skip updating its ring buffer/`sSymbolVars`
  slot for this cycle rather than resampling a window that hasn't changed.
  Relevant given the live loop currently updates every second
  (`TestVariables.mq5`'s `Sleep(1000)` loop) — most of that cadence is wasted
  work for a symbol sitting idle.
  - **One symbol's delta is very small (e.g. ~32ms) and spread (ask − bid) is
  elevated** → market entering volatile territory for that symbol; sample
  faster (sub-second) and watch spread, instead of the fixed 1s cadence.

This is explicitly a `doLive=true`-only idea — `SymbolInfoTick` has no cached
equivalent in `TickCache.mqh`, so it doesn't apply to closed-market/backtest
runs. Not scheduled; revisit when live-loop cadence/volatility-adaptive
sampling becomes an active piece of work.

### Live-mode per-sample tick buffer: collapsing N native `CopyTicksRange` calls per sample down to 1 (implemented and compiled clean 2026-09-14)

#### Problem

`init_ticks_arr_g` (`variables.mqh`) calls `CopyTicksRange_g` once per period
branch (PRO, REF, DAY, each `S<n>`/`T<n>` in `I_PERIODS`) for every symbol, every sample. For
`use_cache=true` (closed-market/backtest) this was already cheap — Phase 1's `TickCache.mqh`
loads a symbol+day's ticks from CSV into `g_tick_day_caches[]` once and every subsequent call
just binary-searches/slices that in-memory array (`TickCacheLowerBound_g` + `ArrayCopy`). But
for `use_cache=false` (live mode, `doLive=true` in `TestVariables.mq5`), every single period
branch fell straight through to a **native** `CopyTicksRange`/`CopyTicks` call against the
terminal's tick store — i.e. with N periods configured, N native calls per symbol per sample,
even though every one of those calls shares the same `to_msc` (`in_time_msc`) within one
sample and most of them (PRO/REF/DAY, plus any `S<n>` window) are subsets of the same
`[day_start(in_time_msc), in_time_msc]` range. This is exactly the same "day-level" batching
opportunity Phase 1 already exploited for cache mode, just never extended to live mode.

Raised by the user directly: "CopyTicksRange_g is called too often, it shall be called once
per symbol for the whole day and then the actual MQL array shall be used that was retrieved
once for the sub periods" — with an explicit distinction between live and
cache/backtest/history modes:
- **Live mode**: `CopyTicksRange` should be called once per `time_msc` sample (fetching
  `[day_start, now]`), then sliced in memory for every period. No accumulation/incremental
  fetching implemented yet (see the Phase 2 plan above for a related, larger idea) — "for now
  every time_msc one fetch of day ticks is done."
- **Cache/backtest/history mode**: the fetch + CSV-write + in-memory population should happen
  once per historic trading day, on the very first `time_msc` sample of that day; every
  subsequent `time_msc` for the same day reuses the already-populated array. This is precisely
  what `g_tick_day_caches[]`/`FindOrLoadDayCache_g` already do — confirmed during planning that
  **no change was needed on the cache-mode side**, only live mode was missing the equivalent
  mechanism.

One design point the user corrected explicitly during planning: an earlier draft of this plan
considered widening the day-window fetch to cover an open position's opening time when it
predates the current trading day (a "PRO anchor extension"). The user clarified this is wrong
— **PRO is a period like any other period**; it is empty when there is no open position, and
when a position is open, PRO runs from the position's open time to `in_time_msc`, using
whatever data is available in that window. No special widening of the master fetch window for
PRO was implemented.

#### Design considered and rejected: restructuring `variables.mqh`

The first plan sketched touching `sSymbolVars`/`sDataVars`/`init_ticks_arr_g` directly — adding
a `master_ticks[]` array to `sSymbolVars`, fetching it once in `sSymbolVars::init`, and
refactoring every period branch in `init_ticks_arr_g` to slice from a passed-in master array
instead of calling `CopyTicksRange_g` itself. Rejected in favor of a narrower fix
once it became clear the *cache-mode* side of this exact pattern already exists one layer
down, inside `TickCache.mqh` — `CopyTicksRange_g` already presents one drop-in
API to every call site in `variables.mqh` regardless of `use_cache`, and every one of those
call sites already passes the same `to_msc`/`from_msc` (`in_time_msc`) per sample. Extending
the *live* branch of that same API to do the equivalent "one fetch, many slices" batching
requires zero changes to `variables.mqh`, `sSymbolVars`, `sDataVars`, `TestVariables.mq5`, or
`TestTickCacheDiff.mq5` — the optimization is fully containable inside `TickCache.mqh`.

#### Implementation

Added a live-mode counterpart to `sTickDayCache`/`g_tick_day_caches`/`FindOrLoadDayCache_g`,
all in `TickCache.mqh`:

- **`sLiveTickBuffer`** (`symbol`, `day_start_msc`, `last_to_msc`, `ticks[]`) +
  file-scope `g_live_tick_buffers[]` — one slot per symbol, holding "today's ticks from
  day-start up to the last `to_msc` this buffer was fetched for." Unlike `sTickDayCache`
  (immutable once loaded — a historical day's ticks never change), this buffer is designed to
  keep growing as live time passes.
- **`FindOrRefreshLiveBuffer_g(symbol, to_msc, flags, debug)`**: finds or creates the symbol's
  slot; resets it (drops `ticks[]`, `last_to_msc = 0`) if the calendar day has rolled over
  since it was last used; if `last_to_msc >= to_msc` — i.e. this is not the first period-branch
  call for this exact `time_msc` sample — returns immediately with **zero native calls**;
  otherwise issues exactly one `CopyTicksRange(symbol, day_start_msc, to_msc)` and stores the
  result, updating `last_to_msc`. A real fetch error (`CopyTicksRange` returning negative)
  returns `-1` without touching the existing buffer contents, so a transient failure doesn't
  wipe out otherwise-usable data — mirrors `CopyTicksRange_g`'s existing "no silent masking"
  philosophy for cache-mode failures.
- **`CopyTicksRange_g`**, `use_cache==false` branch: now routes through
  `FindOrRefreshLiveBuffer_g` + the same `TickCacheLowerBound_g` binary-search slicer already
  used for cache mode, instead of calling native `CopyTicksRange`/`CopyTicks` directly. One
  safety fallback: if the requested `from_msc` predates the buffer's `day_start_msc` (e.g. a
  PRO position opened on an earlier calendar day — the one case explicitly discussed above),
  that single request bypasses the buffer and calls native directly, rather than widening the
  buffer's window to accommodate it — keeps the buffer bounded to "today" unconditionally.
  Live c0 lookups are handled separately through a bounded 15-second `CopyTicksRange_g`
  request — the same request path used regardless of `use_cache`, not a live-only branch.

No changes were needed to `variables.mqh`, `sConfig`, `sSymbolVars`, `sDataVars`,
`TestVariables.mq5`, or `TestTickCacheDiff.mq5` — every existing call site already calls
`CopyTicksRange_g(symbol, arr, flags, from_msc, to_msc, in_conf.USE_TICK_CACHE, in_conf.DEBUG)`
with the exact same signature; the batching is entirely internal to
`TickCache.mqh`.

#### Net effect

- **Live mode**: N native `CopyTicksRange` calls per symbol per sample (one per configured
  period in `I_PERIODS`) collapses to **1** native call per symbol per sample — every period
  branch (PRO/REF/DAY/`S<n>`) for the same `in_time_msc` now shares one buffer via cheap
  in-memory binary-search slicing.
  - PRO's and REF's former single-tick "no window yet" branches now use a bounded 15-second
    `CopyTicksRange_g` lookup for c0, gated by `in_conf.USE_TICK_CACHE` like every other call
    site — this runs the same way in cache mode as in live mode, it is not a live-only path.
  - `ENUM_PERIOD_TYPE_TICKS_T`'s retry loop (`inc_cnt` from 5 to 14, `variables.mqh`) calls
    `CopyTicksRange_g` up to 10 times with a *growing* `from_msc` but the same `to_msc` — each
    of those retries now also shares the one live buffer instead of issuing up to 10 native
    calls on its own.
- **Cache/backtest mode**: unchanged — confirmed already correct at the day-level batching this
  request asked for (`g_tick_day_caches`/`FindOrLoadDayCache_g`), so no source changes were made
  to that path at all.

#### Verification

Compiled both `TestVariables.mq5` and `TestTickCacheDiff.mq5` (the two scripts that `#include`
`TickCache.mqh` and call `CopyTicksRange_g` directly) via `MetaEditor64.exe` —
both **0 errors, 0 warnings**. No behavioral/output diff expected for `use_cache=true` runs
(that path's source is untouched) or for `TestVariables.mq5`'s existing 60-sample cache=false
vs cache=true validation harness (`RunCacheComparisonHarness_g`) — its cache=false side now
issues fewer native calls per sample internally, but the *ticks fetched and returned* for any
given `(from_msc, to_msc)` slice are unchanged (same underlying data, just sourced from one
shared buffer fetch instead of N independent native fetches covering overlapping ranges). Not
yet re-run against a live/demo terminal with `doLive=true` and multiple configured periods to
directly observe the native-call-count reduction (e.g. via `I_DEBUG>=1`'s new
`[LiveTickBuffer] ... to_msc=... ticks=...` print, which fires once per sample instead of once
per period) — recommended next validation step before considering this fully closed out.

#### c0 lookup correction (2026-09-14 to 2026-09-15)

The first live-buffer experiment routed the PRO/REF "no window yet" c0 lookup through the
day buffer. That failed because a day buffer is a bounded range, while the former single-tick
lookup required a different search contract; c0 became zero in the harness. The obsolete
single-tick helper was removed from the source. The current implementation requests the
preceding 15 seconds with `CopyTicksRange_g` and selects the last returned tick instead. This
call is gated by `in_conf.USE_TICK_CACHE` exactly like every other `CopyTicksRange_g` call site,
so it is not a live-only fix — the same 15-second window is used in cache mode too.

The corrected run reported zero mismatches for every PRO, REF, DAY, and S3600 comparison and
ended with `ALL 60 SAMPLES MATCH EXACTLY`. Live `LAT_US` was generally approximately
1.4-2.9 ms. This is the accepted current baseline; incremental fetching/accumulation remains
optional Phase 2 work.

#### Performance re-measurement after the fix (2026-09-14)

`RunCacheComparisonHarness_g`'s latency line (from the `elapsed_us` self-timing feature,
2026-09-13) lets native-vs-cached `build`/`AddBuf`/`TryGet`/`init` costs be compared directly
before and after this batching feature:

| metric | pre-batching baseline (2026-09-13) | post-fix (2026-09-14) |
|---|---|---|
| `init` (`sRingBuf<T>::init`) | native=186us cached=141us | native=155us cached=156us |
| `AddBuf` | native=105.2us cached=88.5us | native=139.7us cached=113.6us |
| `TryGet` | native=81.4us cached=85.2us | native=84.8us cached=88.5us |
| **`build`** (full per-sample `sGlobalVars` construction) | **native=8343.8us cached=1378.2us** | **native=5699.5us cached=1418.8us** |

`init`/`AddBuf`/`TryGet` are pure `sRingBuf<T>` mechanics, independent of tick-fetch mode — the
small native-vs-cached deltas in both runs are noise, not signal. `build` is the metric that
actually reflects tick-fetch cost (it wraps `init_ticks_arr_g`, which is what calls
`CopyTicksRange_g`), and it shows a real but partial win: native's per-sample cost
dropped ~32% (8343.8us → 5699.5us), but the gap to cached mode's ~1.4ms is still ~4x, essentially
unchanged in ratio.

**Why the gap didn't close further**: `FindOrRefreshLiveBuffer_g` still issues
`CopyTicksRange(symbol, fresh, flags, day_start_msc, to_msc)` on every refresh — a **full
day-start-to-now rescan**, growing more expensive as the trading day progresses (the harness's
own DAY tick counts climb from 30270 at 15:00:00 to 41911 at 15:59:00 in the same run — the live
buffer's fetch window grows in exact lockstep, since both cover `[day_start, to_msc]`). This is
the same growing-cost profile already documented for the DAY period branch in
`docs/known-issues.md`'s open issues — the batching feature collapsed the *per-period
multiplier* (N calls → 1 per sample) but inherited DAY's *per-sample* cost growth for that one
remaining call, since it fetches the same day-so-far window DAY itself fetches. Cached mode's
`build` stays flat across the day because its CSV is loaded once (`FindOrLoadDayCache_g`) and
only sliced afterward — no re-fetch cost at all after the first sample. Phase 2's planned
incremental-accumulation work (see `docs/known-issues.md`) would remove this cost for the live
buffer the same way it's planned to for DAY — noted there as an extension of that existing plan
rather than a new issue.

### `sRingBuf<T>` self-timing (`elapsed_us`) and `RunCacheComparisonHarness_g` latency reporting (2026-09-13)

`RunCacheComparisonHarness_g` (`TestVariables.mq5`) already proved native-vs-cache output
*correctness* (60/60 samples match exactly, see the validation-harness decision above), but had
no timing at all — the only latency evidence anywhere in the project was the live loop's
anecdotal `LAT_US` column (`OnStart()`), which showed `LAT_US` growing ~3x over a simulated run
but never separated *what* was getting slower (tick-fetch/resum cost vs. ring-buffer mechanics)
or compared native against cached directly.

**Rejected alternatives, in order:**

1. A standalone `sPerfTimer` struct (`Start()`/`ElapsedUs()`), used externally by wrapping
   arbitrary blocks of caller code, applied to `OnStart()`'s plain live loop. Rejected by the
   user — wrong target: the live loop isn't where the native-vs-cache comparison lives.
2. The same `sPerfTimer` struct applied inside `RunCacheComparisonHarness_g`'s sample-build
   loop, plus a new `CompareGlobalVarsRingBufs_g` function extracting the harness's existing
   inline comparison loop into a reusable ring-buffer-diff helper. Rejected by the user as
   "too complicated and overbloated" — introduced two new pieces of surface area
   (a generic timer type, a new comparison function) for what should be a small, local change.

**What shipped instead**, per the user's own minimal specification: no new struct, no new
function. `sRingBuf<T>` (`variables.mqh`) now times its own two mutating/reading operations
internally and exposes the result as a plain public member:

- Added `long elapsed_us;` to `sRingBuf<T>`, initialized to `0` in the constructor.
- `AddBuf()` wraps its existing body in `GetMicrosecondCount()` before/after and stores the
  delta in `elapsed_us`. No behavior change to the add itself.
- `TryGet()` does the same around its existing body. This required dropping `const` from
  `TryGet`'s signature, since writing `elapsed_us` is a mutation — MQL5 enforces
  const-correctness on methods same as C++, so a `const` method cannot write an instance
  member even one unrelated to the struct's logical read-only contract. Checked every call
  site first (`TestVariables.mq5`, `TestFFT.mq5`, plus the commented-out usage example inside
  `variables.mqh` itself) — none invoke `TryGet` on a `const`-qualified `sRingBuf`, so dropping
  `const` is a safe, non-breaking change.

Callers derive whatever combined metric they need by reading `elapsed_us` right after each call
(the field is overwritten by the *next* call on the same instance, so it must be read
immediately, exactly matching the existing call pattern of "call, then use the result before
calling again"):

- **Normal use** (single ring buffer): `AddBuf(...)`'s `elapsed_us` + `TryGet(...)`'s
  `elapsed_us` reconstructs the same total the old inline
  `start_us = GetMicrosecondCount(); ...; latency_us = GetMicrosecondCount() - start_us;`
  pattern measured — minus whatever work happens *between* the `AddBuf`/`TryGet` calls (e.g.
  `sGlobalVars` construction), which was never inside `sRingBuf<T>` to begin with and is out of
  scope for this change.
- **Comparison use** (`RunCacheComparisonHarness_g`): `ring_native` and `ring_cached` are
  separate instances, so each has its own independent `elapsed_us` — read `ring_native.elapsed_us`
  right after `ring_native.AddBuf(...)`/`ring_native.TryGet(...)` and `ring_cached.elapsed_us`
  right after the matching cached call, accumulate both across all 60 samples, and print one
  native-vs-cached average line for `AddBuf` and one for `TryGet`. The harness's existing
  `CompareGlobalVars_g`-based correctness diff is untouched — this only adds four accumulators
  and one `Print`.

This isolates *ring-buffer copy cost* (copying a whole `sGlobalVars` graph — nested `sSymbolVars[]`/
`sData[]`/dynamic tick arrays — into and out of the ring buffer) from *tick-fetch/resum cost*
(inside the `sGlobalVars` constructor itself, which dominates and is where the Phase 1/Phase 2
cache work actually pays off). Verified: `TestVariables.mq5` and `TestFFT.mq5` (the other
`sRingBuf<T>.TryGet` call site) both compile with 0 errors/0 warnings after dropping `const`.

`init()` got the same treatment, prompted by checking whether the *constructor* (`sRingBuf()`)
does any allocation - it doesn't, it's plain scalar assignment. `init()` is where
`ArrayResize(m_buf, m_capacity)` actually allocates the backing array, so that's the one
timed: same `GetMicrosecondCount()`-before/after pattern, `elapsed_us` set on both the
early-return (`capacity <= 0`) and success paths. Called once per ring buffer (not in a loop
like `AddBuf`/`TryGet`), so `RunCacheComparisonHarness_g` just reads
`ring_native.elapsed_us`/`ring_cached.elapsed_us` directly after each `init()` call — no
averaging needed - and reports both alongside the `AddBuf`/`TryGet` averages in the same
`Print`.

**Measured on first run** (`RunCacheComparisonHarness_g`, n=60):
`AddBuf avg us: native=122.1 cached=112.7 | TryGet avg us: native=102.2 cached=100.9` — total
ring-buffer overhead per sample is ~215-225us either way. Compare against the live loop's
`LAT_US` column from the same run (`OnStart()`'s plain loop, same symbol/config, doLive=false):
values in the 8600-11000us range. The two numbers intentionally measure different scopes and
were never expected to match — `LAT_US` spans from before `sGlobalVars tmp1(...)` is
*constructed* through the end of `AddBuf`+`TryGet`, so the ~97-98% of it not accounted for by
`AddBuf`/`TryGet` is time spent inside the `sGlobalVars` constructor itself (the
`CopyTicks`/`CopyTicksRange` fetch plus `DAY`/`REF`/`PRO` resum). This confirms the question this
change set out to answer: **the cache's benefit lives entirely in the tick-fetch/resum layer,
not the ring-buffer layer** — native and cached `AddBuf`/`TryGet` costs are close (not
identical, since native/cached ticks-array lengths can differ slightly) because copying an
already-built struct costs the same regardless of how its data was fetched. Consistent with the
already-documented `DAY` full-resum cost in `docs/known-issues.md` and motivates Phase 2
(incremental accumulation) more concretely than the previous anecdotal `LAT_US`-only evidence.

**Extended to `sGlobalVars` itself, same day.** The above confirmed the tick-fetch/resum cost
dominates but didn't measure it directly — `AddBuf`/`TryGet`/`init` only cover the ring-buffer
layer, and the harness's sample-build loop calls `sGlobalVars g_native(time_msc, sr,
cfg_native)`/`g_cached(...)` directly, outside any `sRingBuf<T>` method. The user asked for the
same `elapsed_us` pattern one level up ("we need the constructor as well with self timing
sGlobalVars and/or sGlobalVarsImpl because sometimes .init is not called, then everything runs
in constructor"), correctly identifying that `sGlobalVars` has no separately-callable `.init()`
analogous to `sRingBuf<T>`'s — its three parameterized constructors (1/2/3-arg) each call
`sGlobalVarsImpl()` directly from the constructor body, so timing had to live inside
`sGlobalVarsImpl()` itself, not a method that might not run.

Shipped: added `long elapsed_us;` to `sGlobalVars`, set to `0` in the empty default constructor
(used only for `ArrayResize` placeholders — never calls `sGlobalVarsImpl()`, so it stays
untimed by design, mirroring `sRingBuf()`'s own no-allocation constructor above). Wrapped
`sGlobalVarsImpl()`'s existing body (`ArrayResize(sSym, c.SYMBOLS_num)` + the per-symbol
`sSym[cnt].init(...)` loop — the actual `CopyTicks`/`CopyTicksRange` fetch and resum work) in
the same `GetMicrosecondCount()`-before/after pattern. No new struct, no new function — same
minimal shape as every prior extension of this pattern.

`RunCacheComparisonHarness_g` reads `g_native.elapsed_us`/`g_cached.elapsed_us` immediately
after each construction, accumulates native/cached totals across all 60 samples, and reports
the averages in the same `Print` line as `init`/`AddBuf`/`TryGet` (new `build avg us` field).
This finally gives the harness a direct, measured native-vs-cached build-time number instead of
inferring it as "whatever `LAT_US` doesn't explain." Verified: `TestVariables.mq5` and
`TestFFT.mq5` both compile with 0 errors/0 warnings after this change (`TestFFT.mq5` doesn't use
`sGlobalVars`'s 3-arg constructor or `elapsed_us` at all, so it was only reconfirmed as an
unaffected control, not expected to change).

**Measured on first run with `build avg us` wired in**: `cache-cmp init us: native=186 cached=141
| build avg us: native=8343.8 cached=1378.2 | AddBuf avg us: native=105.2 cached=88.5 | TryGet
avg us: native=81.4 cached=85.2 (n=60)`. This is the direct measurement the whole instrumentation
chain (init → AddBuf/TryGet → build) was built to produce: native `sGlobalVars` construction
costs ~8.3ms per sample, cached costs ~1.4ms — a ~6x reduction, and it accounts for essentially
all of the previously-unexplained gap between `AddBuf`/`TryGet` (~100us each, native≈cached, as
expected — copy cost doesn't depend on fetch method) and the live loop's anecdotal `LAT_US`
(~8.6-11ms). Confirms empirically, not just anecdotally, that the tick cache's benefit is real
and concentrated entirely in the tick-fetch/resum layer — directly supports prioritizing Phase 2
(incremental accumulation) as the next latency win, since even the cached path's remaining
~1.4ms is presumably still dominated by `DAY`'s full-window resum (the one part Phase 1 doesn't
touch).

### Live-buffer refresh count verification (2026-09-14)

The remaining direct verification item for the live-mode batching change was to count the
existing `[LiveTickBuffer]` diagnostic lines. The diagnostic is emitted only by
`FindOrRefreshLiveBuffer_g` after an actual native buffer refresh; period branches that reuse
the already-fetched buffer are silent. Therefore the line count distinguishes one shared
refresh per sample from one refresh per configured period.

`RunCacheComparisonHarness_g` was run with `I_DEBUG=1`, one symbol (`EURUSD`), 60 samples from
15:00:00 through 15:59:00, and periods `PRO:REF:DAY:S3600`. The run emitted exactly 60
`[LiveTickBuffer] EURUSD` lines. Their `to_msc` values were unique and increased by exactly
60,000 milliseconds from the first sample to the last. There were no duplicate refreshes for
the four configured period keys.

The same run printed `ALL 60 SAMPLES MATCH EXACTLY`. This establishes both points needed for
the batching claim in the deterministic harness: bounded range requests for the same symbol
and sample share one live-buffer refresh, and the reuse preserves the native-versus-cached
ring-buffer results. It is important that this was the harness's historical-time run with
`USE_TICK_CACHE=false`, not a separate wall-clock `doLive=true` run; it exercises the live
buffer implementation deterministically without claiming to test live clock scheduling.

The count concerns the bounded range requests only. The current c0 path also uses a bounded
15-second `CopyTicksRange_g` request — the same request used in both cache and live modes, not
a live-specific contract.

The remaining performance issue is visible in the same log and in the build timings: native
`sGlobalVars` construction averaged 11,003.9us versus 2,336.2us cached, while `AddBuf` and
`TryGet` remained around 100us each. The live buffer still fetches the complete
`[day_start, to_msc]` range on every newer sample, so the next optimization target remains
incremental accumulation/extension rather than further period-level batching.

### Current c0 lookup and Phase 2 status (2026-09-15)

The PRO and REF c0 paths now use `CopyTicksRange_g` over the preceding 15 seconds and take
the last returned tick. This call is gated by `in_conf.USE_TICK_CACHE` like every other
`CopyTicksRange_g` call site in `init_ticks_arr_g`, so it is not live-specific — it runs
identically in cache mode and live mode. This avoids depending on an exact tick at the sample
timestamp and keeps c0 on the range-fetch path already used by the period calculations.

The latest run verified:

- `ALL 60 SAMPLES MATCH EXACTLY`.
- Every PRO, REF, DAY, and S3600 comparison had zero mismatches.
- Live c0 values were populated with millisecond tick timestamps (verified with the live loop;
  the same c0 path also runs in cache mode).
- Live `LAT_US` was generally approximately `1.4-2.9 ms`.
- Native/cached build averages were `8687.4 us` and `3238.7 us`; ring-buffer `AddBuf` and
  `TryGet` remained small compared with object construction.

This establishes a stable baseline for Phase 2. Incremental accumulation/fetching is now an
optional performance experiment to reduce full-window recomputation and refresh work; it is no
longer part of the correctness fix. Phase 2 should preserve the current 60-sample exact-match
result as its acceptance criterion.
