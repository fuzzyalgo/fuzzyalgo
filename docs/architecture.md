# Architecture

Read this when you need to understand subsystem boundaries, core data structures, or where a
piece of functionality lives, before making a change.

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
hard-won knowledge in this repo's docs is about the MQL5 side; read the Python section below
before assuming otherwise.

There is no automated test suite (no pytest, no MQL5 unit-test harness) — "testing" a
change means either running a Python script directly against a live/demo MT5 terminal, or
compiling + running an `.mq5` script in the terminal and inspecting its printed output
(see the cache-comparison harness in [design-decisions.md](design-decisions.md) for the
closest thing to a regression test that exists in this repo).

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

Environment setup (conda env, dependencies, `setup.py`) is documented in full in
`README.md` — that is the canonical source, not this file.

One architectural fact worth keeping here since it's not a setup step: `setup.py`
provisions one isolated MT5 terminal install per account under
`%APPDATA%\MetaTrader5_<ACCOUNT>\`, and **symlinks**
`Experts|Files|Images|Include|Indicators|Libraries|Presets|Profiles|Scripts` back into
`MetaTrader5_TMPL/MQL5/` — editing an `.mq5`/`.mqh` file in this repo therefore changes it
for every provisioned account's terminal simultaneously; they are the same file on disk,
not copies. It also symlinks `Lib/algotrader` and `Lib/mplfinance` into the conda env's
`site-packages`.

## MQL5 side (`MetaTrader5_TMPL/MQL5/.../FuzzyAlgo/`)

- `MQL5/Include/FuzzyAlgo/variables.mqh` (~1,440 lines) is the core data model: `sConfig`
  (per-run config, composed into every other struct below), `sData`/`sDataVars` (per-symbol,
  per-period derived tick features — `OC`/`HL`/`SUM_POS`/`SUM_NEG`/`NETFLOW`/etc., plus the
  raw per-tick delta series `ticks_arr`), `sRefPoint` (a single fixed reference tick, native
  `CopyTicks` only, never cached), `sSymbolVars` (all periods for one symbol), `sGlobalVars`
  (all symbols for one sample), and `sRingBuf<T>` (a fixed-size ring buffer used to hold
  recent `sGlobalVars` snapshots). `ENUM_PERIOD_TYPE` (DAY/PRO/REF/SECONDS_S/TICKS_T) selects
  how each period's tick window is anchored. `CompareDataVars_g`/`CompareGlobalVars_g` at the
  bottom of this file are the cache-comparison harness's diffing functions (see
  [design-decisions.md](design-decisions.md)).
- `MQL5/Include/FuzzyAlgo/TickCache.mqh` caches a full day's ticks per symbol to CSV so a
  closed-market/backtest run can replay ticks without re-hitting the terminal's tick store on
  every sample. Gated by `input bool I_USE_TICK_CACHE` / `conf.c.USE_TICK_CACHE`. See
  `docs/repository-notes.md` for the precision bugs this surfaced and how they were fixed.
- `MQL5/Include/FuzzyAlgo/SignalFusion.mqh` adds matrix-style extraction from
  `sRingBuf<sGlobalVars>` into `sDataMatrix`, plus multi-period NETFLOW fusion helpers:
  weighted-average (`WeightedAverageFusion_g`) and confirmation-threshold voting
  (`ConfirmationFusion_g` / `ConfirmationFusionSeries_g`), plus vote diagnostics
  (`CountNetflowSignAgreement_g`).
- `MQL5/Include/FuzzyAlgo/HistogramChart.mqh` — charting helper, not otherwise load-bearing to
  the data model above.
- `MQL5/Scripts/FuzzyAlgo/TestVariables.mq5` — the main script; builds the object graph above
  per sample (live loop or closed-market/backtest via `doLive`), and runs the cache=false vs
  cache=true comparison harness before the existing demo/live loop.
- `MQL5/Scripts/FuzzyAlgo/TestTickCacheDiff.mq5` — standing diagnostic/regression script that
  diffs raw tick arrays between native and cached fetches, and native-vs-native a few seconds
  apart, to catch cache- or feed-related discrepancies. Not a throwaway script — kept
  intentionally as a regression tool.
- `MQL5/Scripts/FuzzyAlgo/TestFFT.mq5` — separate FFT-based script, uses the same
  `variables.mqh` object graph but is not part of the tick-cache investigation.
- `MQL5/Files/FuzzyAlgo/ticks_cache/` — where `TickCache.mqh` writes/reads per-symbol,
  per-day CSV tick caches (gitignored).
