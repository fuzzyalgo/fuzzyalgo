# Changelog

Dated, one-line-per-entry implementation milestones, newest first. Updated at notable
milestones (a fix verified, a feature shipped, a decision made) — not per-commit, since
`git log` already gives hash + message for free. This file exists to curate the "why," which
`git log` doesn't capture. Each entry links to `docs/repository-notes.md` for full detail
where relevant.

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
