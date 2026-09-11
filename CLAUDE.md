# CLAUDE.md

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
  **Root-caused 2026-09-09, not a slicing bug or feed drift**: the user
  performed exactly this isolation test (fresh native run, delete the stale
  CSV, rebuild cache immediately after) and the ±1 mismatches persisted
  regardless — ruling out cross-run cache staleness. The actual cause was the
  CSV round-trip precision issue documented in the `OC`/`HL` follow-up bullet
  above (fixed by writing bid/ask/last at full round-trip precision instead of
  `SYMBOL_DIGITS`) — unrelated to whether the CSV was freshly built or
  pre-existing.
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

## `sConfig` composition refactor (implemented 2026-09-09 — foundation for the cache-comparison harness below)

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
  already-documented decision below).
- Building a differently-configured `sGlobalVars` is now a plain struct copy:
  `sConfig cfg_cached = cfg; cfg_cached.USE_TICK_CACHE = true;` then
  `sGlobalVars g_cached(time_msc, sr, cfg_cached);` — no bool-threading
  plumbing needed.

Verified: this was a pure internal restructuring with zero output changes for
any existing call site — confirmed by compiling and running `TestVariables.mq5`
and `TestFFT.mq5` (0 errors/0 warnings on both) with output unchanged from
pre-refactor.

## TestVariables.mq5: cache=false vs cache=true validation harness (implemented and verified 2026-09-10 — 60/60 samples match exactly)

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

### Problem: `I_USE_TICK_CACHE` is a fixed `input` — solved by the `sConfig` refactor above

`input bool I_USE_TICK_CACHE` cannot change value within one script execution,
and every level of the object graph read it independently via inheritance.
Running one cache=false and one cache=true `sGlobalVars` build in the same
`OnStart()` therefore needed an explicit override threaded through the call
chain. Rather than threading a single raw `bool`, the `sConfig` composition
refactor documented above (implemented 2026-09-09) solves this generally: any
`sGlobalVars` graph can now be built from an explicitly-supplied, possibly
overridden `sConfig` value.

### Design

#### 1. `sConfig`-threading — already implemented (see the composition refactor above)

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

### Files touched

- `MetaTrader5_TMPL/MQL5/Include/FuzzyAlgo/variables.mqh` — `sConfig`-threading
  through `init_ticks_arr_g`/`sDataVars::init`/`sSymbolVars::init`/the
  `sGlobalVars` 3-arg constructor (see the composition refactor above), plus
  `CompareDataVars_g`/`CompareGlobalVars_g`.
- `MetaTrader5_TMPL/MQL5/Scripts/FuzzyAlgo/TestVariables.mq5` —
  `RunCacheComparisonHarness_g`, called from `OnStart()` before the existing
  demo/live-loop code (left as-is).

### Verification — passed 2026-09-10

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

## `GetSystemTime` (DLL import) vs native alternatives — findings 2026-09-11, staying on the DLL for now

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

### Deferred idea: `GetSystemTime` vs `SymbolInfoTick` delta as a staleness/volatility signal

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
