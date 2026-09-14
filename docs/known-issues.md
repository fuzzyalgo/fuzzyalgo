# Known issues

Read this before touching `TestVariables.mq5` or `variables.mqh`, to check whether a symptom
you're seeing is already known, and before starting new work, to check what's already planned.

## Open issues

- **EURUSD `sRefPoint`/`CopyTicks` intermittently returns 0 results** — seen as
  `XX EURUSD ... price: 0.00000` while other symbols (EURGBP/GBPJPY/NZDUSD) succeeded
  (`OK ...`) in the same run; in other runs EURUSD came back `OK`, so it's intermittent,
  not constant. Corrupts the `c0_ref`-based delta column for EURUSD when it happens. If
  reported again, check `sRefPoint`'s `CopyTicks` call/retry logic in
  `MQL5/Include/FuzzyAlgo/variables.mqh` first. Full history: `docs/repository-notes.md`.
- **`DAY` period's `SUM_POS`/`SUM_NEG` recompute from the full day's tick history on
  every call, so a "frozen" value can look like a bug but usually isn't** —
  `init_ticks_arr_g`'s `ENUM_PERIOD_TYPE_DAY` branch (`variables.mqh`) calls
  `CopyTicksRange` from midnight through the current sample time on every single call, and
  `init_data_from_ticks_arr_g` resets `SUM_POS`/`SUM_NEG` to `0` and resums the whole window
  each time — nothing is accumulated incrementally. The real issue is cost: every sample
  rescans the entire day's ticks, getting more expensive as the trading day progresses —
  see the Phase 2 plan below, which addresses exactly this. Full history:
  `docs/repository-notes.md`.

## Planned / deferred work

- **Phase 2: incremental accumulation for DAY/REF/PRO** (drafted 2026-09-09, not yet
  implemented — a refactor to consolidate the old full-resum path and the new incremental
  path is planned first). Removes the resum cost described in the DAY issue above by
  maintaining running aggregates instead of resumming from scratch every sample. Full design
  sketch, correctness-risk analysis, and validation plan: `docs/repository-notes.md`.
  **Now also covers live mode's per-sample tick buffer** (`FindOrRefreshLiveBuffer_g`,
  `TickCache.mqh`, added 2026-09-14): its single fetch-per-sample still rescans
  `[day_start, to_msc]` in full every time `to_msc` advances, so it has the same
  growing-cost profile as DAY, just now underneath every period instead of only DAY's own
  branch. Measured 2026-09-14: `build avg us` (full per-sample `sGlobalVars` construction)
  improved from a pre-batching baseline of native=8343.8/cached=1378.2 to
  native=5699.5/cached=1418.8 — batching cut ~32% off native's cost, but the ~4x gap to
  cached mode remains, because the live buffer's own fetch is still O(day-so-far) per
  sample. Phase 2 would close this gap for live mode too. Full numbers and analysis:
  `docs/repository-notes.md`.
- **Live-buffer call-count reduction is verified for the deterministic harness; real live
  monitoring remains optional** (verified 2026-09-14): with one symbol, 60 samples, and
  `I_DEBUG=1`, the harness emitted exactly 60 `[LiveTickBuffer]` refresh lines with unique
  `to_msc` values from 15:00 through 15:59. The configured `PRO:REF:DAY:S3600` period set
  therefore reused one live-buffer refresh across the bounded range requests for each sample,
  rather than refreshing once per period. The same run reported `ALL 60 SAMPLES MATCH EXACTLY`.
  This verifies the batching behavior in the deterministic closed-time harness while
  `USE_TICK_CACHE=false`; it is not a separate wall-clock `doLive=true` observation. The
  remaining performance issue is not call count but that each refresh still rescans the full
  `[day_start, to_msc]` range; see the Phase 2 item above.
- **`GetSystemTime` vs `SymbolInfoTick` delta as a staleness/volatility signal** (sketched
  2026-09-11, not implemented). Idea: use `delta_msc = GetSystemTimeMsc() - tick.time_msc`
  per symbol to detect connectivity problems, skip resampling idle symbols, or trigger
  faster sampling during volatile moments. `doLive=true`-only; not scheduled. Full sketch:
  `docs/repository-notes.md`.
