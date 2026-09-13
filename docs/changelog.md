# Changelog

Dated, one-line-per-entry implementation milestones, newest first. Updated at notable
milestones (a fix verified, a feature shipped, a decision made) — not per-commit, since
`git log` already gives hash + message for free. This file exists to curate the "why," which
`git log` doesn't capture. Each entry links to `docs/repository-notes.md` for full detail
where relevant.

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
