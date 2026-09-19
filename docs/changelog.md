# Changelog

Dated, one-line-per-entry implementation milestones, newest first. Updated at notable
milestones (a fix verified, a feature shipped, a decision made) — not per-commit, since
`git log` already gives hash + message for free. This file exists to curate the "why," which
`git log` doesn't capture. Each entry links to `docs/repository-notes.md` for full detail
where relevant.

- **2026-09-19** — Added per-cell unsigned `sData.SCORE` in `variables.mqh`, computed from that
  cell's own `NETFLOW`/`OC_HL`/`VOLS_TD`, surfaced it in row printing and cache-vs-native
  comparisons, and updated the fusion demo/docs to distinguish it from the existing multi-period
  `SignalFusion.mqh` row outputs.
- **2026-09-15** — Removed `CopyTicks_g` completely from the source. PRO/REF c0 lookup
  now uses the last tick from a bounded 15-second `CopyTicksRange_g` window, gated by
  `in_conf.USE_TICK_CACHE` like every other call site — not a live-only change, it applies
  the same way in cache mode. This is the current implementation; the `CopyTicks_g` entries
  below document yesterday's state.
- **2026-09-19** — Extended `SignalFusion.mqh` with OC/HL sign tie-breaking on ambiguous
  confirmation/weighted results (defaulting to the longest configured period, configurable by
  period index), plus adaptive weighted fusion via `effective_weight = static_weight * VOLS_TD`,
  and updated `TestVariables.mq5` to print static-vs-adaptive weighted signals and tie-breaker
  activity summaries.
- **2026-09-19** — Added `SignalFusion.mqh` with a matrix extractor from `sRingBuf<sGlobalVars>`,
  weighted-average and confirmation-based NETFLOW fusion (`ConfirmationFusion_g` /
  `ConfirmationFusionSeries_g`), plus a `TestVariables.mq5` demo that prints per-row period
  NETFLOW values, BUY/SELL vote counts, and weighted-vs-confirmation signals side-by-side.
- **2026-09-15** — Re-measured native-vs-cached `build avg us` (full per-sample `sGlobalVars`
  construction) after the c0 lookup fix: native=5699.5us, cached=1418.8us, vs a
  pre-batching baseline of native=8343.8us/cached=1378.2us — the live-buffer batching cut
  ~32% off native's per-sample cost, but the ~4x gap to cached mode remains, since the live
  buffer's single fetch still rescans `[day_start, to_msc]` in full every sample (same
  growing-cost shape as the DAY period issue). Logged as an extension of the existing Phase 2
  plan in [known-issues.md](known-issues.md); the "N calls collapse to 1" claim itself is
  still unverified by direct call-count measurement.
- **2026-09-14** — verified live-buffer batching: `I_DEBUG=1` produced 60 unique refreshes
  for 60 harness samples (one per sample, not one per period), with `ALL 60 SAMPLES MATCH
  EXACTLY`; the remaining cost is the full day-to-sample rescan on each refresh.
- **2026-09-14** — Re-measured native-vs-cached `build avg us` (full per-sample `sGlobalVars`
  construction) after the `CopyTicks_g` fix above: native=5699.5us, cached=1418.8us, vs a
  pre-batching baseline of native=8343.8us/cached=1378.2us — the live-buffer batching cut
  ~32% off native's per-sample cost, but the ~4x gap to cached mode remains, since the live
  buffer's single fetch still rescans `[day_start, to_msc]` in full every sample (same
  growing-cost shape as the DAY period issue). Logged as an extension of the existing Phase 2
  plan in [known-issues.md](known-issues.md); the "N calls collapse to 1" claim itself is
  still unverified by direct call-count measurement.
- **2026-09-14** — Fixed a bug in the live-mode tick-fetch batching below: `CopyTicks_g`'s
  `use_cache=false` branch routed PRO's/REF's single-tick `c0` lookup through the new live
  buffer, but that buffer only supports bounded-range queries, not the open-ended forward
  search `CopyTicks_g` needs — caused `c0` to read `0` on 60/60 harness samples in the first
  live/demo run. Reverted that branch to always call native `CopyTicks` directly (see
  [design-decisions.md](design-decisions.md)). Compiled clean (0 errors/0 warnings); re-ran the
  harness afterward — `ALL 60 SAMPLES MATCH EXACTLY`, 0 mismatches.
- **2026-09-14** — Live-mode (`I_USE_TICK_CACHE=false`) tick fetching batched: a new
  `sLiveTickBuffer`/`g_live_tick_buffers`/`FindOrRefreshLiveBuffer_g` layer in `TickCache.mqh`
  collapses N native `CopyTicksRange`/`CopyTicks` calls per symbol per sample (one per
  configured period) down to 1, mirroring the "one fetch, many slices" pattern cache mode
  already had via `g_tick_day_caches` (see [design-decisions.md](design-decisions.md)). No
  changes needed to `variables.mqh` or any call site. Compiled clean (0 errors/0 warnings).
- **2026-09-13** — `sGlobalVars` now self-times its own construction: a public `elapsed_us`
  member set inside `sGlobalVarsImpl()` (the tick-fetch/resum work every parameterized
  constructor calls directly, since `sGlobalVars` has no separate `.init()`);
  `RunCacheComparisonHarness_g` reports native-vs-cache `sGlobalVars` build averages alongside
  `init`/`AddBuf`/`TryGet` (see [design-decisions.md](design-decisions.md)). First measured run:
  native build ~8.3ms vs cached ~1.4ms per sample (~6x) - direct confirmation that the tick
  cache's benefit lives in the fetch/resum layer, motivating Phase 2 (incremental accumulation)
  as the next win.
- **2026-09-13** — `sRingBuf<T>.init`/`AddBuf`/`TryGet` now self-time via a public `elapsed_us`
  member; `RunCacheComparisonHarness_g` reports native-vs-cache ring-buffer `init`/`AddBuf`/
  `TryGet` latency (see [design-decisions.md](design-decisions.md)). First measured run showed
  `AddBuf`/`TryGet` cost (~100-125us each) is negligible next to the live loop's `LAT_US`
  (~8.6-11ms) - confirming the cache's benefit lives in the tick-fetch/resum layer, not the
  ring-buffer layer.
- **2026-09-11** — `GetSystemTime` DLL-vs-native investigation concluded: keeping the DLL
  import (see [design-decisions.md](design-decisions.md)).
- **2026-09-10** — cache=false vs cache=true validation harness implemented and verified
  (60/60 samples match exactly).
- **2026-09-09** — `sConfig` composition-over-inheritance refactor shipped (0 errors/warnings,
  output unchanged).
- **2026-09-09** — OC/HL native-vs-cache mismatch fixed: `MathRound` + full CSV round-trip
  precision (`TICK_CACHE_ROUNDTRIP_DIGITS_G = 16`).
- **2026-09-09** — SUM_POS/SUM_NEG display-rounding fix (`MathRound` in `PrintRow`).
- **2026-09-07/09** — stale-cache OC/HL mismatch investigated and root-caused (see
  [design-decisions.md](design-decisions.md)).
- Ref-delta fixed via a dedicated `ENUM_PERIOD_TYPE_REF` period type (was period-0-only).
- Live loop ring-buffer lag fix: read `ringbuf.Count() - 1` instead of index `0`.
