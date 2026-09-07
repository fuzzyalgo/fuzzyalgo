# CLAUDE.md

Instructions for Claude Code when working in this repository.

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
