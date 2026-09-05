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
- **Live loop in `OnStart` prints a lagged ring-buffer entry, not the sample it just
  added** — `ringbuf.init(ring_buf_num, false)` sets `indexNewest = false`, so the live
  loop's `TryGet(0, tmp)` (`sRingBuf::MapLogicalToPhysical`, `variables.mqh`) returns the
  OLDEST buffered entry (the tail), not the `tmp1` just pushed via `AddBuf`. The first
  `ring_buf_num` (10) live-loop iterations therefore just drain the 10 one-second-apart
  seed samples from the initial historical fill, one iteration late, before any freshly
  computed live sample is ever shown. This is visible in the printed sample timestamps:
  after the ring-buffer dump ends at `15:00:00.000`, the live loop reprints
  `14:59:52.000` through `15:00:00.000` a second time before jumping straight to
  `15:01:00.000` — a full simulated minute skipped — once the stale seed data is
  exhausted. `LAT_MS` in that stretch measures the current iteration's `AddBuf`+`TryGet`
  cost, but the printed sample itself is up to 10 iterations old, so latency and sample
  are not actually in sync. Fix direction: pass `indexNewest = true` to `ringbuf.init`,
  or read the just-added item directly instead of `TryGet(0, ...)`.
