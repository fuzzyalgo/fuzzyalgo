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
- **`GetSystemTime` vs `SymbolInfoTick` delta as a staleness/volatility signal** (sketched
  2026-09-11, not implemented). Idea: use `delta_msc = GetSystemTimeMsc() - tick.time_msc`
  per symbol to detect connectivity problems, skip resampling idle symbols, or trigger
  faster sampling during volatile moments. `doLive=true`-only; not scheduled. Full sketch:
  `docs/repository-notes.md`.
