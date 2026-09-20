//+------------------------------------------------------------------+
//|                                                TestVariables.mq5 |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link "https://www.fuzzyalgo.com"
#property version "1.00"

#include <FuzzyAlgo/variables.mqh>
#include <FuzzyAlgo/SignalFusion.mqh>
#include <FuzzyAlgo/HistogramChart.mqh>
#include <WinAPI/sysinfoapi.mqh>

//+------------------------------------------------------------------+
//| Standing correctness harness (docs/design-decisions.md's         |
//| "cache=false vs cache=true validation harness"): builds 60       |
//| one-minute samples twice - once with the tick cache off, once    |
//| with it on - as two                                               |
//| independent sGlobalVars object graphs sharing the same sConfig    |
//| except for USE_TICK_CACHE, then diffs every sample via            |
//| CompareGlobalVars_g (variables.mqh). Proves the tick cache never  |
//| loses/reorders ticks and every derived OC/HL/SUM_POS/SUM_NEG/     |
//| NETFLOW value agrees, at the level that actually matters (the     |
//| per-tick delta array each period's stats are derived from) - not  |
//| just the raw MqlTick[] level TestTickCacheDiff.mq5 already        |
//| covers.                                                            |
//+------------------------------------------------------------------+
void RunCacheComparisonHarness_g(const long in_time_msc, const sRefPoint &sr)
{
    int ring_buf_num = 60;

    sConfig cfg; // real inputs, built once
    sConfig cfg_native = cfg;
    cfg_native.USE_TICK_CACHE = false;
    sConfig cfg_cached = cfg;
    cfg_cached.USE_TICK_CACHE = true;

    sRingBuf<sGlobalVars> ring_native, ring_cached;
    ring_native.init(ring_buf_num, false);
    long native_init_us = ring_native.elapsed_us;
    ring_cached.init(ring_buf_num, false);
    long cached_init_us = ring_cached.elapsed_us;

    long total_native_add_us = 0, total_cached_add_us = 0;
    long total_native_build_us = 0, total_cached_build_us = 0;

    // sr's ref point is anchored at in_time_msc (see OnStart's sr_harness
    // construction), and REF's window is [ref_point_time, sample_time] - so
    // samples must run FORWARD from in_time_msc (e.g. 15:00->16:00), not
    // backward from it. Backward samples are all <= the anchor, which never
    // leaves init_ticks_arr_g's REF zero-window guard, so REF would stay
    // permanently unset and the harness couldn't exercise it at all.
    for (int min_cnt = 0; min_cnt < ring_buf_num; min_cnt++)
    {
        long time_msc = in_time_msc + min_cnt * 60 * 1000;
        sGlobalVars g_native(time_msc, sr, cfg_native);
        total_native_build_us += g_native.elapsed_us;
        sGlobalVars g_cached(time_msc, sr, cfg_cached);
        total_cached_build_us += g_cached.elapsed_us;

        ring_native.AddBuf(g_native);
        total_native_add_us += ring_native.elapsed_us;

        ring_cached.AddBuf(g_cached);
        total_cached_add_us += ring_cached.elapsed_us;
    }

    int total = 0;
    long total_native_get_us = 0, total_cached_get_us = 0;
    for (int i = 0; i < ring_buf_num; i++)
    {
        sGlobalVars native, cached;

        ring_native.TryGet(i, native);
        total_native_get_us += ring_native.elapsed_us;

        ring_cached.TryGet(i, cached);
        total_cached_get_us += ring_cached.elapsed_us;

        string label = StringFormat("%s.%03d",
                                    TimeToString(native.time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                    native.time_msc % 1000);
        total += CompareGlobalVars_g(native, cached, label);
    }

    Print(StringFormat("cache-cmp init us: native=%d cached=%d | build avg us: native=%.1f cached=%.1f | AddBuf avg us: native=%.1f cached=%.1f | TryGet avg us: native=%.1f cached=%.1f (n=%d)",
                        native_init_us, cached_init_us,
                        (double)total_native_build_us / ring_buf_num, (double)total_cached_build_us / ring_buf_num,
                        (double)total_native_add_us / ring_buf_num, (double)total_cached_add_us / ring_buf_num,
                        (double)total_native_get_us / ring_buf_num, (double)total_cached_get_us / ring_buf_num,
                        ring_buf_num));

    if (0 == total)
        Print("ALL ", ring_buf_num, " SAMPLES MATCH EXACTLY");
    else
        Print(total, " total mismatches across ", ring_buf_num, " samples - see above");
} // void RunCacheComparisonHarness_g

// Prints one fusion decision row per buffered sample. Weighted outputs use
// default 1..N period-order weights; confirmation counts NETFLOW signs and
// resolves ambiguous rows from the last configured period's OC_HL sign.
void RunSignalFusionDemo_g(sRingBuf<sGlobalVars> &ringbuf, const int in_symbol_idx, const int in_min_confirmations)
{
    sDataMatrix mat;
    if (!ExtractRingBufToDataMatrix_g(ringbuf, mat))
    {
        Print("SignalFusion demo skipped: unable to build matrix from ring buffer");
        return;
    }

    if (mat.sample_count <= 0 || mat.periods_num <= 0 || mat.symbols_num <= 0)
    {
        Print("SignalFusion demo skipped: empty matrix");
        return;
    }

    if (in_symbol_idx < 0 || in_symbol_idx >= mat.symbols_num)
    {
        Print("SignalFusion demo skipped: invalid symbol index ", in_symbol_idx);
        return;
    }

    sFusionWeights fusion_weights;
    fusion_weights.InitDefault(mat.periods_num);
    int tie_breaker_period_idx = mat.periods_num - 1;

    ENUM_FUSION_SIGNAL weighted_static_series[];
    ENUM_FUSION_SIGNAL weighted_adaptive_series[];
    ENUM_FUSION_SIGNAL confirmation_series[];
    bool has_weighted_static = WeightedAverageFusionSeries_g(mat,
                                                             in_symbol_idx,
                                                             fusion_weights,
                                                             false,
                                                             weighted_static_series,
                                                             tie_breaker_period_idx,
                                                             true);
    bool has_weighted_adaptive = WeightedAverageFusionSeries_g(mat,
                                                               in_symbol_idx,
                                                               fusion_weights,
                                                               true,
                                                               weighted_adaptive_series,
                                                               tie_breaker_period_idx,
                                                               true);
    bool has_confirmation = ConfirmationFusionSeries_g(mat,
                                                       in_symbol_idx,
                                                       in_min_confirmations,
                                                       confirmation_series,
                                                       tie_breaker_period_idx,
                                                       true);
    if (!has_weighted_static || !has_weighted_adaptive || !has_confirmation)
    {
        Print("SignalFusion demo skipped: unable to build signal series");
        return;
    }

    Print(StringFormat("SignalFusion demo: symbol=%s rows=%d periods=%d min_confirmations=%d",
                       mat.symbols_arr[in_symbol_idx],
                       mat.sample_count,
                       mat.periods_num,
                       in_min_confirmations));

    int tie_breaker_resolved_count = 0;
    int tie_breaker_ambiguous_flat_count = 0;

    for (int row_idx = 0; row_idx < mat.sample_count; row_idx++)
    {
        string netflow_per_period = "";
        for (int period_idx = 0; period_idx < mat.periods_num; period_idx++)
        {
            int cell_idx = mat.CellIndex(row_idx, in_symbol_idx, period_idx);
            if (cell_idx < 0)
                continue;
            netflow_per_period += StringFormat(" %s(NF=%+.2f SCORE=%.2f)",
                                               mat.periods_arr[period_idx],
                                               mat.cells[cell_idx].NETFLOW,
                                               mat.cells[cell_idx].SCORE);
        }

        int buy_votes = 0;
        int sell_votes = 0;
        CountNetflowSignAgreement_g(mat, row_idx, in_symbol_idx, buy_votes, sell_votes);

        int threshold = in_min_confirmations;
        if (threshold <= 0)
            threshold = 1;
        if (threshold > mat.periods_num)
            threshold = mat.periods_num;

        ENUM_FUSION_SIGNAL confirmation_raw = ConfirmationSignalFromVotes_g(buy_votes, sell_votes, threshold);
        double oc_hl_tb = 0.0;
        int tie_idx_used = -1;
        ENUM_FUSION_SIGNAL tie_signal = OCHLTieBreakerSignal_g(mat, row_idx, in_symbol_idx, tie_breaker_period_idx, oc_hl_tb, tie_idx_used);
        if (ENUM_FUSION_SIGNAL_FLAT == confirmation_raw)
        {
            if (ENUM_FUSION_SIGNAL_FLAT != tie_signal)
                tie_breaker_resolved_count++;
            else
                tie_breaker_ambiguous_flat_count++;
        }

        Print(StringFormat("%s.%03d |%s | votes BUY=%d SELL=%d | weighted_static=%s weighted_adaptive=%s confirmation=%s",
                           TimeToString(mat.time_msc[row_idx] / 1000, TIME_DATE | TIME_SECONDS),
                           mat.time_msc[row_idx] % 1000,
                           netflow_per_period,
                           buy_votes,
                           sell_votes,
                           FusionSignalToString_g(weighted_static_series[row_idx]),
                           FusionSignalToString_g(weighted_adaptive_series[row_idx]),
                           FusionSignalToString_g(confirmation_series[row_idx])));
    }

    if (tie_breaker_resolved_count > 0)
    {
        Print(StringFormat("SignalFusion demo tie-breaker summary: OC_HL tie-breaker resolved %d ambiguous rows using period %s(idx=%d)",
                           tie_breaker_resolved_count,
                           mat.periods_arr[tie_breaker_period_idx],
                           tie_breaker_period_idx));
    }
    else
    {
        Print(StringFormat("SignalFusion demo tie-breaker summary: no ambiguous rows were resolved by OC_HL (ambiguous rows with OC_HL==0/degenerate=%d, period=%s idx=%d)",
                           tie_breaker_ambiguous_flat_count,
                           mat.periods_arr[tie_breaker_period_idx],
                           tie_breaker_period_idx));
    }
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    MqlDateTime time_struct = {};
    time_struct.year = 2026;
    time_struct.mon = 9;
    time_struct.day = 4;
    time_struct.hour = 15;
    time_struct.min = 0;
    time_struct.sec = 0;
    long in_time_msc_cache_cmp = StructToTime(time_struct) * 1000;
    sRefPoint sr_harness(in_time_msc_cache_cmp);
    RunCacheComparisonHarness_g(in_time_msc_cache_cmp, sr_harness);

    bool doLive = false;
    long in_time_msc;
    int ring_buf_num = 60;
    int delta_ringbuf_entries_secs = 60;

    if (doLive)
    {
        in_time_msc = GetSystemTimeMsc();
        // in_time_msc = TimeCurrent()*1000;
        // in_time_msc = TimeLocal()*1000;
        // in_time_msc = (datetime)t.time_msc;
    }
    else
    {
        in_time_msc = in_time_msc_cache_cmp;
    } // if( doLive )

    sGlobalVars g(in_time_msc);
    Print("symbols " + g.c.SYMBOLS + " | " + IntegerToString(g.c.SYMBOLS_num));
    ArrayPrint(g.c.SYMBOLS_arr);
    Print("periods " + g.c.PERIODS + " | " + IntegerToString(g.c.PERIODS_num));
    ArrayPrint(g.c.PERIODS_arr);
    Print("hosts   " + g.c.HOSTS + " | " + IntegerToString(g.c.HOSTS_num));
    ArrayPrint(g.c.HOSTS_arr);

    // Build one hour of one-minute cached samples, then show fusion output
    // for every configured symbol over the same matrix.
    sConfig cfg;
    sConfig cfg_cached = cfg;
    cfg_cached.USE_TICK_CACHE = true;

    long fusion_start_msc = in_time_msc;
    sRefPoint sr2(fusion_start_msc);

    sRingBuf<sGlobalVars> ringbuf;
    bool res = ringbuf.init(ring_buf_num, false);
    for (int min_cnt = 0; min_cnt < ring_buf_num; min_cnt++)
    {
        long time_msc = fusion_start_msc + min_cnt * delta_ringbuf_entries_secs * 1000;
        sGlobalVars tmp(time_msc, sr2, cfg_cached);
        ringbuf.AddBuf(tmp);
    }

    for (int min_cnt = 0; min_cnt < ring_buf_num; min_cnt++)
    {
        sGlobalVars tmp;
        res = ringbuf.TryGet(min_cnt, tmp);
        for (int symbol_idx = 0; symbol_idx < tmp.c.SYMBOLS_num; symbol_idx++)
            tmp.sSym[symbol_idx].PrintRow();
    }

    for (int cnt = 0; cnt < g.c.SYMBOLS_num; cnt++)
        RunSignalFusionDemo_g(ringbuf, cnt, 3);

    // Keep the following replay/live loop on the uncached path so it remains
    // an independent view of terminal tick data.
    sConfig cfg_native = cfg;
    cfg_native.USE_TICK_CACHE = false;

    sRefPoint sr3(in_time_msc);
    long replay_day_start_msc = 0;
    long replay_day_end_msc = 0;
    if (!doLive)
        GetDayBoundsMsc_g(in_time_msc, replay_day_start_msc, replay_day_end_msc);

    int min_cnt = 0;
    while (!IsStopped())
    {
        long time_msc;
        if (doLive)
            time_msc = GetSystemTimeMsc();
        else
            time_msc = in_time_msc + min_cnt * 60 * 1000;

        // Keep this deterministic historical replay within its configured
        // calendar day; stop before constructing the next midnight's sample.
        if (!doLive && time_msc >= replay_day_end_msc)
        {
            Print("Historical replay complete at day boundary");
            break;
        }

        // GetTickCount64() only has ~15.6ms resolution (the Windows system
        // timer tick), so per-sample latency here - which is well under
        // that - was quantizing to 0 or 16 instead of showing real
        // variance. GetMicrosecondCount() is a free-running counter with
        // microsecond resolution, not tied to that OS timer tick.
        ulong start_us = GetMicrosecondCount();
        sGlobalVars tmp1(time_msc, sr3, cfg_native);
        ringbuf.AddBuf(tmp1);
        sGlobalVars tmp;
        // ringbuf was init'd with indexNewest=false (see the ringbuf.init(...)
        // call above), so logical
        // index 0 means "oldest buffered entry", not "the one just added" -
        // TryGet(0, ...) would silently replay the seed-fill backlog one
        // iteration late instead of showing the sample just pushed above.
        // Count()-1 is the newest logical index under indexNewest=false
        // (MapLogicalToPhysical maps it to head-1), so this fetches tmp1.
        res = ringbuf.TryGet(ringbuf.Count() - 1, tmp);
        min_cnt++;

        long latency_us = (long)(GetMicrosecondCount() - start_us);
        for (int symbol_idx = 0; symbol_idx < tmp.c.SYMBOLS_num; symbol_idx++)
            tmp.sSym[symbol_idx].PrintRow(latency_us);

        if (doLive)
        {
            Sleep(cfg_native.EVENT_TIMER_INTERVAL_MSC);
        }
        else
        {
            Sleep(1);
        } // if( doLive )

    } // while (!IsStopped())

} // void OnStart()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// #include <WinAPI/sysinfoapi.mqh>
// https://www.mql5.com/en/forum/462879/page2
datetime GetSystemTimeMsc(void)
{
    SYSTEMTIME st;
    GetSystemTime(st);

    MqlDateTime dt;
    dt.year = st.wYear;
    dt.mon = st.wMonth;
    dt.day = st.wDay;
    dt.hour = st.wHour;
    dt.min = st.wMinute;
    dt.sec = st.wSecond;
    //---
    return (1000 * (StructToTime(dt) + 3 * 3600 /*7200*/) + st.wMilliseconds);
} // long GetSystemTimeMsc(void)
//+------------------------------------------------------------------+
