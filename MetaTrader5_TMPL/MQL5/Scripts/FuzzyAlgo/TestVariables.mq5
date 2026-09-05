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

        ulong start = GetTickCount64();
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

        long latency_ms = (long)(GetTickCount64() - start);
        for (int symbol_idx = 0; symbol_idx < tmp.c.SYMBOLS_num; symbol_idx++)
            tmp.sSym[symbol_idx].PrintRow(latency_ms);
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
