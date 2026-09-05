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
            PrintSampleInfo(tmp, symbol_idx);
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
        res = ringbuf.TryGet(0, tmp);
        min_cnt++;

        long latency_ms = (long)(GetTickCount64() - start);
        for (int symbol_idx = 0; symbol_idx < tmp.c.SYMBOLS_num; symbol_idx++)
            PrintSampleInfo(tmp, symbol_idx, latency_ms);
        Sleep(1000);

    } // while (!IsStopped())

} // void OnStart()

//+------------------------------------------------------------------+
//| Prints a column-header line matching PrintSampleInfo's layout.   |
//| Field widths here MUST stay in sync with the StringFormat calls  |
//| in PrintSampleInfo below, or columns will drift out of alignment.|
//+------------------------------------------------------------------+
void PrintSampleInfoHeader(const sGlobalVars &tmp, const int symbol_idx = 0)
{
    string head = StringFormat("%-19s.%-3s %-6s", "TIME", "MS", "SYM");

    string periods_str = "";
    int num_periods = tmp.sSym[symbol_idx].c.PERIODS_num;
    for (int p = 0; p < num_periods; p++)
    {
        periods_str += StringFormat(" | %-5s %7s %7s %8s %7s %9s %9s",
                                    tmp.sSym[symbol_idx].sData[p].period,
                                    "OC", "HL", "OC/HL", "NETFLOW", "SUMPOS", "SUMNEG");
    }

    string foot = StringFormat(" | %10s %6s %6s", "C0", "REFDLT", "LAT_MS");

    Print(head + periods_str + foot);
} // void PrintSampleInfoHeader(const sGlobalVars &tmp, const int symbol_idx)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Prints one debug line for symbol sSym[symbol_idx] of a sample.   |
//| Loops over all configured periods. latency_ms defaults to -1     |
//| for the ring-buffer dump (no real latency to report); the live  |
//| loop passes the measured tick latency. Every 100th call reprints |
//| the column header via PrintSampleInfoHeader.                    |
//+------------------------------------------------------------------+
void PrintSampleInfo(const sGlobalVars &tmp, const int symbol_idx = 0, const long latency_ms = -1)
{
    static int print_count = 0;
    if (0 == print_count % 100)
        PrintSampleInfoHeader(tmp, symbol_idx);
    print_count++;

    double point = SymbolInfoDouble(tmp.sSym[symbol_idx].symbol, SYMBOL_POINT);
    long time_msc = tmp.time_msc;
    sData d0 = tmp.sSym[symbol_idx].sData[0].d;

    string head = StringFormat("%-19s.%03d %-6s",
                               TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                               time_msc % 1000,
                               tmp.sSym[symbol_idx].symbol);

    string periods_str = "";
    int num_periods = tmp.sSym[symbol_idx].c.PERIODS_num;
    for (int p = 0; p < num_periods; p++)
    {
        sData d = tmp.sSym[symbol_idx].sData[p].d;
        periods_str += StringFormat(" | %-5s %7d %7d %8.1f %7.2f %9d %9d",
                                    tmp.sSym[symbol_idx].sData[p].period,
                                    (int)d.OC,
                                    (int)d.HL,
                                    d.OC_HL,
                                    d.NETFLOW,
                                    (int)d.SUM_POS,
                                    (int)d.SUM_NEG);
    }

    string foot = StringFormat(" | %10.5f %6d %6d",
                               d0.c0,
                               (int)((d0.c0 - d0.c0_ref) / point),
                               (int)latency_ms);

    Print(head + periods_str + foot);
} // void PrintSampleInfo(const sGlobalVars &tmp, const int symbol_idx, const long latency_ms)
//+------------------------------------------------------------------+

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
