# Known issues

Read this before touching `TestVariables.mq5` or `variables.mqh`, to check whether a symptom
you're seeing is already known, and before starting new work, to check what's already planned.

## Open issues

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

- **Phase 2: incremental accumulation/fetching** (ready for a separate trial, not required for
  correctness). The current implementation still recomputes full windows and refreshes the
  live day range. Two 2026-09-20 runs bound the cost:
  - without an open PRO position, native/cached `sGlobalVars` builds averaged 4.52/2.02 ms,
    but native replay latency grew from 1.39 ms over its first 60 rows to 6.79 ms over its last
    60 rows (15:00 through 20:47 overall), confirming the DAY/REF growing-window cost;
  - with a cross-day PRO position holding about 5.68 million ticks per sample, both modes
    averaged about 0.32 seconds because the day-scoped cache must use the native cross-day path.
  Phase 2 should therefore cover DAY/REF first and preserve a reset/rebuild path for PRO anchor
  changes and cross-day positions. Full design sketch, risk analysis, and validation history:
  `docs/repository-notes.md`.
- **Expose fusion decision provenance and runtime policy inputs.** The current final
  `confirmation` value does not tell a caller whether the threshold was met or OC/HL resolved
  an ambiguous row. In the no-PRO EURUSD run, 31/60 rows used the tie-breaker; all 27 final BUY
  confirmations came from that fallback, while the 29 direct confirmations were SELL. The
  next round should expose raw signal, final signal, and `tie_breaker_used`, and should make
  confirmation threshold, tie-break period, and per-row tie logging script inputs rather than
  demo literals. It must also decide whether an empty/zero PRO period remains an abstention
  under a fixed threshold or reduces the effective threshold. Full evidence:
  `docs/repository-notes.md`.
- **OC/HL tie-break resolution logic itself is a design concern, not just a provenance
  gap.** Once a confirmation/weighted-average vote is ambiguous, the fallback consults only
  one period's OC/HL sign (default: the last-configured period, `periods_num - 1` - an
  accident of `I_PERIODS` ordering, not a deliberate "most reliable period" choice), and
  never re-consults the other periods' NETFLOW votes that produced the ambiguity. A single
  period's OC/HL is comparatively noisy, so an already-ambiguous row is resolved with one of
  the least robust signals available. Candidate fixes (need a decision before implementing):
  (1) aggregate OC/HL across all periods (majority/weighted sign) instead of one period;
  (2) use the period with the strongest NETFLOW magnitude instead of switching signal
  families; (3) always use the explicitly-longest configured period as a deliberate
  trend-filter, rather than "last in array" by accident; (4) drop the OC/HL fallback
  entirely and return FLAT/no-trade on true ties. Full tradeoff writeup:
  `docs/repository-notes.md`.
- **A lightweight fusion snapshot is optional, not the next performance priority.** Without
  the pathological cross-day PRO array, `AddBuf` and `TryGet` averaged only about 0.11-0.13 ms
  each versus 2.02-4.52 ms to build `sGlobalVars`. Keep the idea of storing only
  NETFLOW/OC_HL/VOLS_TD/SCORE for high-symbol-count or large-PRO workloads, but prioritize
  incremental DAY/REF aggregation first.
- **Live-buffer call-count reduction is verified for the deterministic harness; real live
  monitoring remains optional** (verified 2026-09-14): with one symbol, 60 samples, and
  `I_DEBUG=1`, the harness emitted exactly 60 `[LiveTickBuffer]` refresh lines with unique
  `to_msc` values from 15:00 through 15:59. The configured `PRO:REF:DAY:S3600` period set
  therefore reused one live-buffer refresh across the bounded range requests for each sample,
  rather than refreshing once per period. The same run reported `ALL 60 SAMPLES MATCH EXACTLY`.
  This verifies the batching behavior in the deterministic closed-time harness while
  `USE_TICK_CACHE=false`; it is not a separate wall-clock `doLive=true` observation. The
  remaining optimization opportunity is the full `[day_start, to_msc]` refresh and resum work;
  see the Phase 2 item above.
- **`GetSystemTime` vs `SymbolInfoTick` delta as a staleness/volatility signal** (sketched
  2026-09-11, not implemented). Idea: use `delta_msc = GetSystemTimeMsc() - tick.time_msc`
  per symbol to detect connectivity problems, skip resampling idle symbols, or trigger
  faster sampling during volatile moments. `doLive=true`-only; not scheduled. Full sketch:
  `docs/repository-notes.md`.
