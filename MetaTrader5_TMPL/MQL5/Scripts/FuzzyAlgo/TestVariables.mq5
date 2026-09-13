//+------------------------------------------------------------------+
//|                                                          FFT.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

#include <FuzzyAlgo/variables.mqh>
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

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    bool doLive = false;
    long in_time_msc;
    int ring_buf_num = 10;

    if (doLive)
    {
        in_time_msc = GetSystemTimeMsc();
        // in_time_msc = TimeCurrent()*1000;
        // in_time_msc = TimeLocal()*1000;
        // in_time_msc = (datetime)t.time_msc;
    }
    else
    {
        MqlDateTime time_struct = {};
        time_struct.year = 2026;
        time_struct.mon = 9;
        time_struct.day = 4;
        time_struct.hour = 15;
        time_struct.min = 0;
        time_struct.sec = 0;
        in_time_msc = StructToTime(time_struct) * 1000;

    } // if( doLive )

    sRefPoint sr_harness(in_time_msc);
    RunCacheComparisonHarness_g(in_time_msc, sr_harness);

    sGlobalVars g(in_time_msc);
    Print("symbols " + g.c.SYMBOLS + " | " + IntegerToString(g.c.SYMBOLS_num));
    ArrayPrint(g.c.SYMBOLS_arr);
    Print("periods " + g.c.PERIODS + " | " + IntegerToString(g.c.PERIODS_num));
    ArrayPrint(g.c.PERIODS_arr);
    Print("hosts   " + g.c.HOSTS + " | " + IntegerToString(g.c.HOSTS_num));
    ArrayPrint(g.c.HOSTS_arr);

    sRefPoint sr2(in_time_msc);

    sRingBuf<sGlobalVars> ringbuf;
    bool res = ringbuf.init(ring_buf_num, false);
    for (int min_cnt = (ring_buf_num - 1); min_cnt >= 0; min_cnt--)
    {
        long time_msc = in_time_msc - min_cnt * 1 * 1000;
        sGlobalVars tmp(time_msc, sr2);
        ringbuf.AddBuf(tmp);
    }

    for (int min_cnt = 0; min_cnt < ring_buf_num; min_cnt++)
    {
        sGlobalVars tmp;
        res = ringbuf.TryGet(min_cnt, tmp);
        for (int symbol_idx = 0; symbol_idx < tmp.c.SYMBOLS_num; symbol_idx++)
            tmp.sSym[symbol_idx].PrintRow();
    }

    sRefPoint sr3(in_time_msc);

    int min_cnt = 0;
    while (!IsStopped())
    {
        long time_msc;
        if (doLive)
            time_msc = GetSystemTimeMsc();
        else
            time_msc = in_time_msc + min_cnt * 60 * 1000;

        // GetTickCount64() only has ~15.6ms resolution (the Windows system
        // timer tick), so per-sample latency here - which is well under
        // that - was quantizing to 0 or 16 instead of showing real
        // variance. GetMicrosecondCount() is a free-running counter with
        // microsecond resolution, not tied to that OS timer tick.
        ulong start_us = GetMicrosecondCount();
        sGlobalVars tmp1(time_msc, sr3);
        ringbuf.AddBuf(tmp1);
        sGlobalVars tmp;
        // ringbuf was init'd with indexNewest=false (see line 54), so logical
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
        Sleep(1000);

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
