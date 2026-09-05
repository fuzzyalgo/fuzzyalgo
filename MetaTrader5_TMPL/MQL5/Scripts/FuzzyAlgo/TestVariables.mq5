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

struct sFuzzyAlgoChart
{
    const string name;
    const int x;
    const int y;
    const int width;
    const int height;
    const int vscale_size;
    bool created;
    CHistogramChart chart;

    void create()
    {
        if (chart.CreateBitmapLabel(name, x, y, width, height))
        {
            created = true;
            // chart.Accumulative();
            chart.ShowValue(false);
            chart.ShowScaleTop(false);
            chart.ShowScaleBottom(false);
            chart.ShowScaleRight(false);
            chart.ShowLegend(false);
            int size2 = 50;
            chart.VScaleParams((int)vscale_size, -1 * vscale_size, 2);
        }
        else
        {
            created = false;
            Print("Error creating histogram chart: ", GetLastError());
            // @TODO raise exception here
        }
    }

    void destroy()
    {
        chart.Destroy();
        created = false;
    }

    sFuzzyAlgoChart() : name("FuzzyAlgoChart"),
                        x(10), y(10), width(600), height(450), vscale_size(50), created(false) {};

    sFuzzyAlgoChart(
        const string &_name,
        const int &_x,
        const int &_y,
        const int &_width,
        const int &_height,
        const int &_vscale_size) : name(_name),
                                   x(_x), y(_y), width(_width), height(_height), vscale_size(_vscale_size), created(false)
    {
        create();
    };

}; // sAlgoFftChart

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
        PrintSampleInfo("OUT2", tmp);
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

        PrintSampleInfo("OUT3", tmp, 0, (long)(GetTickCount64() - start));
        Sleep(1000);

    } // while (!IsStopped())

} // void OnStart()

//+------------------------------------------------------------------+
//| Prints one debug line for symbol sSym[symbol_idx] of a sample.   |
//| Loops over all configured periods. latency_ms < 0 omits the     |
//| latency column (used for the ring-buffer dump); >= 0 includes   |
//| it (used for the live loop).                                    |
//+------------------------------------------------------------------+
void PrintSampleInfo(const string &msg, const sGlobalVars &tmp, const int symbol_idx = 0, const long latency_ms = -1)
{
    double point = SymbolInfoDouble(tmp.sSym[symbol_idx].symbol, SYMBOL_POINT);
    long time_msc = tmp.time_msc;

    string head = StringFormat("%s %s.%03d %s", msg,
                               TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                               time_msc % 1000,
                               tmp.sSym[symbol_idx].symbol);
    if (0 <= latency_ms)
        head += StringFormat(" %3d", (int)latency_ms);

    sData d0 = tmp.sSym[symbol_idx].sData[0].d;
    string price_str = StringFormat(" | %0.5f %6d %6d %6d %6d",
                                    d0.c0,
                                    (int)((d0.c0 - d0.c0_ref) / point),
                                    (int)d0.SUM_POS + (int)d0.SUM_NEG,
                                    (int)d0.SUM_POS,
                                    (int)d0.SUM_NEG);

    string periods_str = "";
    int num_periods = tmp.sSym[symbol_idx].c.PERIODS_num;
    for (int p = 0; p < num_periods; p++)
    {
        sData d = tmp.sSym[symbol_idx].sData[p].d;
        periods_str += StringFormat(" | %s %7d %7d %8.1f %8.1f",
                                    tmp.sSym[symbol_idx].sData[p].period,
                                    (int)d.OC,
                                    (int)d.HL,
                                    OCvsHL(d.OC, d.HL),
                                    SumPosvsSumNeg(d.SUM_POS, d.SUM_NEG));
    }

    Print(head + price_str + periods_str);
} // void PrintSampleInfo(const string &msg, const sGlobalVars &tmp, const int symbol_idx, const long latency_ms)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OCvsHL(double OC, double HL)
{
    double v = 0;
    if (HL > 0)
        v = OC / HL;
    return v;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SumPosvsSumNeg(const double &sum_pos, const double &sum_neg)
{
    double v = 0;
    double sp = sum_pos;
    double sn = sum_neg;

    if ((sum_pos == 0) && (sum_neg == 0))
        return 0;
    if (sum_pos == 0)
        sp = 1;
    if (sum_neg == 0)
        sn = -1;

    if (sp > MathAbs(sn))
        v = sp / MathAbs(sn);
    else if (sp < MathAbs(sn))
        v = sn / sp;
    else
        v = 0;

    return v;
}
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
