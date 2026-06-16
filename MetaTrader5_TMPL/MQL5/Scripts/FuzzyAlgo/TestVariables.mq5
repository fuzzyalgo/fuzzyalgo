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

    int ring_buf_num = 10;

    MqlDateTime time_struct = {};
    time_struct.year = 2026;
    time_struct.mon = 5;
    time_struct.day = 15;
    time_struct.hour = 12;
    time_struct.min = 0;
    time_struct.sec = 0;
    long in_time_msc;
    in_time_msc = StructToTime(time_struct) * 1000;
    in_time_msc = GetSystemTimeMsc();
    // in_time_msc = TimeCurrent()*1000;
    //   in_time_msc = TimeLocal()*1000;
    //   in_time_msc = (datetime)t.time_msc;

    int diag_x;
    int diag_y;
    int pos_x = 10;
    int pos_y = 10;
    int diag_width = 320;
    int diag_height = 320;

    string name1 = "FuzzyAlgo" + IntegerToString(50);
    diag_x = pos_x + 0 * diag_width;
    diag_y = pos_y + 0 * diag_height;
    sFuzzyAlgoChart afc1(name1, diag_x, diag_y, diag_width, diag_height, 50);

    sGlobalVars g(in_time_msc);
    Print("symbols " + g.c.SYMBOLS + " | " + IntegerToString(g.c.SYMBOLS_num));
    ArrayPrint(g.c.SYMBOLS_arr);
    Print("symbols " + g.c.PERIODS + " | " + IntegerToString(g.c.PERIODS_num));
    ArrayPrint(g.c.PERIODS_arr);
    Print("symbols " + g.c.HOSTS + " | " + IntegerToString(g.c.HOSTS_num));
    ArrayPrint(g.c.HOSTS_arr);

    sRingBuf<sGlobalVars> ringbuf;
    bool res = ringbuf.init(ring_buf_num, false);
    for (int min_cnt = (ring_buf_num - 1); min_cnt >= 0; min_cnt--)
    {
        long time_msc = in_time_msc - min_cnt * 1 * 1000;
        sGlobalVars tmp(time_msc);
        ringbuf.AddBuf(tmp);
    }

    // @TODO move SUM_POS et.al. into variables
    double c1 = 0;
    int SUM_POS = 0;
    int SUM_NEG = 0;
    int SUM_ALL = 0;

    for (int min_cnt = 0; min_cnt < ring_buf_num; min_cnt++)
    {
        sGlobalVars tmp;
        res = ringbuf.TryGet(min_cnt, tmp);
        if (0 == min_cnt)
        {
            c1 = tmp.sSym[0].sData[0].d.c0;
        }
        double c0 = tmp.sSym[0].sData[0].d.c0;
        double point = SymbolInfoDouble(tmp.sSym[0].symbol, SYMBOL_POINT);
        int p0 = (int)((c0 - c1) / point);
        if (0 < p0)
            SUM_POS += p0;
        if (0 > p0)
            SUM_NEG += p0;
        SUM_ALL += p0;

        long time_msc = tmp.time_msc;
        string msg = "OUT2";
        string str = StringFormat("%s %s.%03d %s | %0.5f %6d %6d %6d %6d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d", msg,
                                  TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                  time_msc % 1000,
                                  tmp.sSym[0].symbol,

                                  c0,
                                  p0,
                                  SUM_ALL,
                                  SUM_POS,
                                  SUM_NEG,

                                  tmp.sSym[0].sData[0].period,
                                  (int)tmp.sSym[0].sData[0].d.OC,
                                  (int)tmp.sSym[0].sData[0].d.HL,
                                  (int)tmp.sSym[0].sData[0].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[0].d.SUM_NEG,

                                  tmp.sSym[0].sData[1].period,
                                  (int)tmp.sSym[0].sData[1].d.OC,
                                  (int)tmp.sSym[0].sData[1].d.HL,
                                  (int)tmp.sSym[0].sData[1].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[1].d.SUM_NEG,

                                  tmp.sSym[0].sData[2].period,
                                  (int)tmp.sSym[0].sData[2].d.OC,
                                  (int)tmp.sSym[0].sData[2].d.HL,
                                  (int)tmp.sSym[0].sData[2].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[2].d.SUM_NEG);
        Print(str);
    }

    sRefPoint sr3(in_time_msc);

    int min_cnt = 0;
    while (!IsStopped())
    {
        long time_msc = in_time_msc + min_cnt * 60 * 1000;
        time_msc = GetSystemTimeMsc();
        ulong start = GetTickCount64();
        sGlobalVars tmp1(time_msc, sr3);
        ringbuf.AddBuf(tmp1);
        sGlobalVars tmp;
        res = ringbuf.TryGet(0, tmp);
        min_cnt++;

        double c0 = tmp.sSym[0].sData[0].d.c0;
        double point = SymbolInfoDouble(tmp.sSym[0].symbol, SYMBOL_POINT);
        int p0 = (int)((c0 - c1) / point);
        if (0 < p0)
            SUM_POS += p0;
        if (0 > p0)
            SUM_NEG += p0;
        SUM_ALL += p0;

        // time_msc = tmp.time_msc;
        string msg = "OUT3";
        string str = StringFormat("%s %s.%03d %s %3d | %0.5f %6d %6d %6d %6d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d", msg,
                                  TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                  time_msc % 1000,
                                  tmp.sSym[0].symbol,
                                  (GetTickCount64() - start),

                                  c0,
                                  p0,
                                  SUM_ALL,
                                  SUM_POS,
                                  SUM_NEG,

                                  tmp.sSym[0].sData[0].period,
                                  (int)tmp.sSym[0].sData[0].d.OC,
                                  (int)tmp.sSym[0].sData[0].d.HL,
                                  (int)tmp.sSym[0].sData[0].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[0].d.SUM_NEG,

                                  tmp.sSym[0].sData[1].period,
                                  (int)tmp.sSym[0].sData[1].d.OC,
                                  (int)tmp.sSym[0].sData[1].d.HL,
                                  (int)tmp.sSym[0].sData[1].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[1].d.SUM_NEG,

                                  tmp.sSym[0].sData[2].period,
                                  (int)tmp.sSym[0].sData[2].d.OC,
                                  (int)tmp.sSym[0].sData[2].d.HL,
                                  (int)tmp.sSym[0].sData[2].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[2].d.SUM_NEG);

        // FftCalc(time_msc, afc1);
        Print(str);
        Sleep(1000);

    } // while (!IsStopped())

    afc1.destroy();

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
