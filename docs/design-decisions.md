# Design decisions

Read this before questioning or reversing a settled technical decision, or before adding a
feature that resembles something already decided against.

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
