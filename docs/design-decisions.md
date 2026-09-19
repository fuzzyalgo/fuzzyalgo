# Design decisions

Read this before questioning or reversing a settled technical decision, or before adding a
feature that resembles something already decided against.

## `sData.SCORE` stays per-cell and unsigned (2026-09-19)

`sData` now carries a bounded `SCORE` in `[0, 1]` computed only from that one cell's own
`NETFLOW`, `OC_HL`, and `VOLS_TD`. It is intentionally sign-independent: direction remains in the
existing signed fields (`NETFLOW`, `OC`, `OC_HL`) and in the row-level/multi-period logic in
`SignalFusion.mqh`.

This explicitly rejects repurposing `SCORE` into a row summary or multi-period fusion output.
`SignalFusion.mqh` still owns cross-period aggregation/confirmation behavior; `sData.SCORE` is
only a per-period evidence-strength/quality measure that downstream code may inspect without
changing BUY/SELL direction semantics. Full rationale and implementation notes:
`docs/repository-notes.md`.

## SignalFusion ambiguity/timing weighting policy (2026-09-19)

For multi-period NETFLOW fusion in `SignalFusion.mqh`, ambiguous FLAT outcomes are now resolved
via the sign of `OC_HL` (`OC/HL`, already normalized) from a configurable tie-break period index
(default: longest configured period, `periods_num - 1`). This keeps tie resolution scale-safe
while preserving explicit FLAT when that tie-break value is zero/degenerate.

Weighted fusion keeps static period weights as the baseline and adds an adaptive mode where each
period uses `effective_weight = static_weight * VOLS_TD`, with zero/non-positive `VOLS_TD` rows
skipped and all-zero-total-weight rows returning neutral FLAT behavior. Full rationale and demo
notes: `docs/repository-notes.md`.

## `sConfig` composition over inheritance (2026-09-09)

`sConfigVars` used to be inherited by `sDataVars`/`sRefPoint`/`sSymbolVars`/`sGlobalVars`,
rebuilding `c` straight from compiled-in `input I_*` globals every time — there was no way
to hand a struct a config value that differed from those inputs. This blocked building two
`sGlobalVars` object graphs in one run differing only in `USE_TICK_CACHE` (needed for the
validation harness below). Replaced inheritance with plain composition (`sConfig c;` member
on each struct, threaded explicitly through constructors) so any future flag is a field flip
on a copied struct, not a new parameter thread. Verified as a pure internal restructuring
with zero output changes. Full details: `docs/repository-notes.md`.

## Tick-cache CSV round-trip precision (2026-09-09)

Native-vs-cache runs of `TestVariables.mq5` occasionally disagreed on `OC`/`HL`/`SUM_POS`/
`SUM_NEG` by ±1. Root cause: `TickCache.mqh` wrote bid/ask/last at `SYMBOL_DIGITS` precision
(insufficient to round-trip a double's exact bit pattern through CSV text), plus a truncating
`(int)` cast instead of `MathRound` in a few display/derivation spots. Fixed by (a) writing
bid/ask/last at a fixed `TICK_CACHE_ROUNDTRIP_DIGITS_G = 16` instead of `SYMBOL_DIGITS`, and
(b) using `MathRound` instead of truncation wherever a near-integer double is cast to `int`.
This is the resolved answer to "how do we make cache=true and cache=false agree exactly" —
verified via the validation harness below (60/60 samples match exactly). Full root-cause
writeup, including the diagnostic tooling built to isolate it: `docs/repository-notes.md`.

## Cache=false vs cache=true validation harness (implemented and verified 2026-09-10)

Built directly into `TestVariables.mq5`: runs the whole `sGlobalVars` object graph twice per
sample (cache off, cache on) over 60 one-minute samples, and diffs the results via
`CompareDataVars_g`/`CompareGlobalVars_g` in `variables.mqh`. This is the closest thing to a
regression test in this repo — proves ticks aren't lost and calculations agree at the level
that matters (the per-tick delta array each period's OC/HL/SUM_POS/SUM_NEG/NETFLOW derive
from), not just at the raw tick-array level `TestTickCacheDiff.mq5` covers. Verified: all 60
samples matched exactly across every symbol×period combination. Full design and verification
details: `docs/repository-notes.md`.

## `GetSystemTime` (DLL import) kept over native alternatives (2026-09-11)

`doLive=true` branches need wall-clock time at millisecond resolution, currently via a
`kernel32.dll` `GetSystemTime` import (requires "Allow DLL imports"). Investigated and
rejected three DLL-free alternatives:
- `SymbolInfoTick(...).time_msc` — time of the last received tick, not wall-clock time; can
  be many seconds stale in a quiet market with no indication anything is off.
- `TimeCurrent()*1000 + (GetTickCount64() % 1000)` — `TimeCurrent()` inherits the same
  tick-staleness problem one layer down (broker time), made worse by ms digits that keep
  advancing smoothly regardless of whether the underlying second is stale.
- `TimeLocal()*1000 + (GetTickCount64() % 1000)` — `GetTickCount64()` is uptime-since-boot,
  with no defined phase relationship to wall-clock second boundaries; produces a fixed-but-
  wrong ms offset for the whole run, plus a non-atomicity race at second boundaries.

Decision: keep the `GetSystemTime` DLL import; accept "Allow DLL imports" as a requirement
for `doLive=true` runs. Revisit if a native option surfaces. Full rejection reasoning:
`docs/repository-notes.md`.

## Live-buffer refresh count verified in the 60-sample harness (2026-09-14)

With `I_DEBUG=1`, the one-symbol `PRO:REF:DAY:S3600` harness emitted exactly 60
`[LiveTickBuffer]` lines for its 60 samples, with unique `to_msc` values from 15:00 through
15:59. The bounded range requests therefore shared one live-buffer refresh per sample rather
than refreshing once per configured period. The harness also reported `ALL 60 SAMPLES MATCH
EXACTLY`, confirming that the reuse did not alter native-versus-cached results.

This verifies the batching claim in the deterministic harness with `USE_TICK_CACHE=false`; it
does not claim a separate wall-clock `doLive=true` run. The PRO/REF c0 paths now use a
15-second `CopyTicksRange_g` window and select its last tick — this is `CopyTicksRange_g`'s
normal `use_cache`-gated behavior, so it applies identically whether cache mode is on or off,
not only in live mode. The remaining full-range DAY/period fetch cost is now acceptable for
the current live loop. Full evidence: `docs/repository-notes.md`.

## `sRingBuf<T>` self-times via a plain `elapsed_us` member, not a separate timer type (2026-09-13)

Latency instrumentation for `RunCacheComparisonHarness_g`'s native-vs-cache comparison was
built directly into `sRingBuf<T>`'s existing `init`/`AddBuf`/`TryGet` methods (each wraps its
own body in `GetMicrosecondCount()` and stores the delta in a public `elapsed_us` member),
instead of a
standalone `sPerfTimer` wrapper struct or a new `CompareGlobalVarsRingBufs_g` comparison
function — both were tried first and rejected as overbuilt for what should be a small, local
change. `TryGet` lost its `const` qualifier as a result (writing `elapsed_us` is a mutation);
checked every call site first, none rely on `TryGet` being callable on a `const` instance.
Callers sum/compare `elapsed_us` inline (read immediately after each call, before the next call
on the same instance overwrites it) rather than through any new abstraction. Full rationale and
rejected alternatives: `docs/repository-notes.md`.

Same pattern extended to `sGlobalVars` on 2026-09-13: a public `elapsed_us` member timing
`sGlobalVarsImpl()`'s body (the `ArrayResize(sSym, ...)` + per-symbol `sSym[cnt].init(...)` loop
— the actual tick-fetch/resum work). Needed because `sGlobalVars`'s heavy lifting runs from
inside its parameterized constructors, not a separately-callable `.init()` like `sRingBuf<T>`
has — so timing had to move to where the constructor's real work happens
(`sGlobalVarsImpl()`), not stay bolted onto a method that's sometimes skipped. The empty
default constructor (used for `ArrayResize` placeholders) sets `elapsed_us(0)` and never calls
`sGlobalVarsImpl()`, so it stays untimed/zero as before. `RunCacheComparisonHarness_g` now
reports native-vs-cached `sGlobalVars` build averages alongside `init`/`AddBuf`/`TryGet`.

## Live-mode tick fetching batched per-sample via `TickCache.mqh`, not a `variables.mqh` restructure (2026-09-14)

Live mode (`use_cache=false`) issued one native `CopyTicksRange` call per period
branch (PRO/REF/DAY/`S<n>`) per symbol per sample — N native calls where cache mode already
only needed 1 (`TickCache.mqh`'s `g_tick_day_caches`/`FindOrLoadDayCache_g` load a symbol+day
once from CSV and slice in memory for every period). Considered restructuring
`sSymbolVars`/`sDataVars`/`init_ticks_arr_g` to fetch a shared `master_ticks[]` once per
symbol per sample and slice it for every period — rejected in favor of a narrower fix: added a
live-mode counterpart (`sLiveTickBuffer`/`g_live_tick_buffers`/`FindOrRefreshLiveBuffer_g`) to
`TickCache.mqh` itself, so `CopyTicksRange_g`'s existing `use_cache==false` branch now fetches
`[day_start(to_msc), to_msc]` once per distinct `to_msc` and slices it via
the same `TickCacheLowerBound_g` binary search cache mode already uses — zero changes needed
to `variables.mqh` or any call site, since every caller already passes the same `to_msc` per
sample. Explicitly rejected as part of this: widening the live buffer's fetch window to cover
a PRO position opened before the current day (PRO is a period like any other — empty with no
open position, `[position_open_time, in_time_msc]` when one exists — not a special anchor that
warrants expanding the shared day-window fetch). Compiled clean (0 errors/0 warnings) for both
`TestVariables.mq5` and `TestTickCacheDiff.mq5`. First live/demo terminal run of this feature
surfaced a bug in the c0 lookup specifically — see the entry immediately below.
Full rationale, rejected alternatives, and follow-up verification notes:
`docs/repository-notes.md`.

## c0 lookup uses `CopyTicksRange_g` (2026-09-15)

The c0 paths in PRO (no open position/window) and REF (window not yet open) use a bounded
15-second `CopyTicksRange_g` window and select the last returned tick, which handles the fact
that a sample timestamp may not have an exact tick. Since this is a call to `CopyTicksRange_g`
with `in_conf.USE_TICK_CACHE` threaded through, it is not live-only — the same bounded window
is used whether `USE_TICK_CACHE` is true or false. This also keeps the lookup on the
established range-fetch path and avoids the unreliable direct single-tick call.

The 2026-09-15 run confirmed `ALL 60 SAMPLES MATCH EXACTLY`. Live `LAT_US` was generally about
1.4-2.9 ms, so the current implementation is considered sufficiently fast. The next work is
optional Phase 2 incremental accumulation/fetching, not a correctness fix.
