//+------------------------------------------------------------------+
//|                                                        Ticks.mq5 |
//|                                    Copyright (c) 2025, andrehowe |
//|                          https://www.mql5.com/en/users/andrehowe |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2025, andrehowe"
#property link "https://www.mql5.com/en/users/andrehowe"
#property version "1.0"
#property description "Ticks\n"

#include <comment.mqh>
#include <WinAPI\sysinfoapi.mqh>

#define COLOR_BLACK clrBlack
#define COLOR_BORDER clrRed
#define COLOR_BLUE clrDodgerBlue
#define COLOR_TEXT clrLightGray
#define COLOR_GREEN clrLimeGreen
#define COLOR_RED clrOrangeRed
#define COLOR_YELLOW clrYellow

// I N C L U D E S

// T Y P E D E F S
enum ENUM_PERIOD_TYPE
{
    ENUM_PERIOD_TYPE_NONE,
    ENUM_PERIOD_TYPE_SECONDS_S,
    ENUM_PERIOD_TYPE_TICKS_T,
    ENUM_PERIOD_TYPE_AVERAGE_S,
    ENUM_PERIOD_TYPE_AVERAGE_T,
    ENUM_PERIOD_TYPE_AVERAGE_SUM,
    ENUM_PERIOD_TYPE_MAX
};

// I N P U T S
input string PERIODS = "T60:T300:T900:T3600:T_AVG:S60:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
input ENUM_COPY_TICKS gCopyTicksFlags = COPY_TICKS_TIME_MS;                           // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL
input int Debug = 0;                                                                  // enable debug output
input int EventTimerIntervalMsc = 1000;                                               // Event Timer Interval in milliseconds

// G L O B A L S

CComment comment;
CComment comment2;

struct sDataVars
{

    string periodKey;
    int periodNum;
    ENUM_PERIOD_TYPE periodType;

    int DELTA;
    int PS;
    int OC;
    int HL;
    int VOLS;
    int TD;
    int TT;
    int SPREAD;
    double OC_HL;
    double VOLS_TD;
    double HL_TD;
    double SUMCOL;

    long t0;
    long t1;
    double c0;
    double c1;

    string str_txt;

}; // struct sDataVars

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitDataVarsStruct(sDataVars &sd)
{

    sd.periodKey = "";
    sd.periodNum = 0;
    sd.periodType = ENUM_PERIOD_TYPE_NONE;

    sd.DELTA = 0;
    sd.PS = 0;
    sd.OC = 0;
    sd.HL = 0;
    sd.VOLS = 0;
    sd.TD = 0;
    sd.TT = 0;
    sd.SPREAD = 0;
    sd.OC_HL = 0;
    sd.VOLS_TD = 0;
    sd.HL_TD = 0;
    sd.SUMCOL = 0;

    sd.c0 = 0.0;
    sd.t0 = 0;
    sd.c1 = 0.0;
    sd.t1 = 0;

    sd.str_txt = "";

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // void InitDataVarsStruct(sDataVars &sd)
//+------------------------------------------------------------------+

// sDataVars sData[9];
sDataVars sData[];
int sDataSize;

string symbolName;
string symbolNameAppendix = "_ticks";

// E V E N T   H A N D L E R S IMPLEMENTATION

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(void)
{

    return (_OnInit());

} // int OnInit(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer(void)
{

    _OnTimer();

} // void OnTimer(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
{

    _OnTick();

} // void OnTick(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

    _OnDeinit(reason);

} // void OnDeinit(const int reason)
//+------------------------------------------------------------------+

// A P P L I C A T I O N

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExtractHighLowFromMqlTickArray(const MqlTick &mqltickarray[], int &OC, int &HL, int &SPREAD)
{
    int spread = 0;
    double high = 0;
    double low = 1000000000;
    int size = ArraySize(mqltickarray);

    HL = 0;
    OC = 0;
    SPREAD = 0;

    if (0 < size)
    {
        MqlTick t0 = mqltickarray[size - 1];
        if (t0.ask == 0 || t0.bid == 0 || t0.ask < t0.bid)
            return;
        MqlTick tstart = mqltickarray[0];
        if (tstart.ask == 0 || tstart.bid == 0 || tstart.ask < tstart.bid)
            return;
        OC = (int)((((t0.ask + t0.bid) / 2) - ((tstart.ask + tstart.bid) / 2)) / _Point);
    }
    else
    {
        return;
    }

    for (int cnt = 0; cnt < size; cnt++)
    {
        MqlTick t = mqltickarray[cnt];
        // sanity check
        if (t.ask == 0 || t.bid == 0 || t.ask < t.bid)
            continue;
        if (high < t.ask)
            high = t.ask;
        if (low > t.bid)
            low = t.bid;
        int s = (int)((t.ask - t.bid) / _Point);
        if ( spread < s )
            spread = s;
    

    } // for( cnt = 0; cnt < size; cnt++ )

    HL = (int)((high - low) / _Point);
    SPREAD = spread;

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // void ExtractHighLowFromMqlTickArray( const MqlTick& mqltickarray[], int& OC, int& HL)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetPeriodFromKeyAndInitDataVarsStruct(const string &periodKey, sDataVars &sd)
{

    InitDataVarsStruct(sd);

    if ("T60" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 60;
        sd.periodKey = periodKey;
        return true;
    }

    if ("T300" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 300;
        sd.periodKey = periodKey;
        return true;
    }

    if ("T900" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 900;
        sd.periodKey = periodKey;
        return true;
    }

    if ("T3600" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 3600;
        sd.periodKey = periodKey;
        return true;
    }

    if ("T_AVG" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_AVERAGE_T;
        sd.periodNum = 0;
        sd.periodKey = periodKey;
        return true;
    }

    if ("S60" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 60;
        sd.periodKey = periodKey;
        return true;
    }

    if ("S300" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 300;
        sd.periodKey = periodKey;
        return true;
    }

    if ("S900" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 900;
        sd.periodKey = periodKey;
        return true;
    }

    if ("S3600" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 3600;
        sd.periodKey = periodKey;
        return true;
    }

    if ("S_AVG" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_AVERAGE_S;
        sd.periodNum = 0;
        sd.periodKey = periodKey;
        return true;
    }

    if ("SUM_AVG" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_AVERAGE_SUM;
        sd.periodNum = 0;
        sd.periodKey = periodKey;
        return true;
    }

    return false;

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // bool GetPeriodFromKeyAndInitDataVarsStruct(const string &periodKey, sDataVars &sd)
//+------------------------------------------------------------------+

// E V E N T   H A N D L E R S IMPLEMENTATION

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int _OnInit(void)
{

    datetime t0 = iTime(_Symbol, PERIOD_H1, 0);
    MqlDateTime dt0;
    TimeToStruct(t0, dt0);
    symbolNameAppendix = StringFormat("_%02d%02d%02d",
                                      dt0.mon,
                                      dt0.day,
                                      dt0.hour);
    symbolName = Symbol() + symbolNameAppendix;

    //--- panel position
    int y = 30;
    // if(ChartGetInteger(0, CHART_SHOW_ONE_CLICK))
    //     y = 120;
    comment.Create("comment_panel_01", 20, y);
    comment2.Create("comment_panel_02", 20, 0);
    //--- panel style
    bool InpAutoColors = false; // Auto Colors
    comment.SetAutoColors(InpAutoColors);
    comment.SetColor(COLOR_BORDER, COLOR_BLACK, 255);
    comment.SetFont("Lucida Console", 13, false, 1.7);

    comment2.SetAutoColors(InpAutoColors);
    comment2.SetColor(COLOR_YELLOW, COLOR_BLACK, 255);
    comment2.SetFont("Lucida Console", 12, false, 1.7);

    if (!TerminalInfoInteger(TERMINAL_CONNECTED))
    {
        Print("Waiting for connection...");
        return (INIT_FAILED);
    }

    if (!SymbolIsSynchronized(_Symbol))
    {
        Print("Unsynchronized, skipping ticks...");
        return (INIT_FAILED);
    }

    //
    // init all sData structs with default values and set periodKey
    //

    string s_sep = ":";                                          // A separator as a character
    ushort u_sep;                                                // The code of the separator character
    string str_period_split[];                                   // An array to get strings
    u_sep = StringGetCharacter(s_sep, 0);                        //--- Get the separator code
    int num_sep = StringSplit(PERIODS, u_sep, str_period_split); //--- Split the string to substrings
    if (1 > num_sep)
    {
        Print(" PERIODS stringsplit failed ", PERIODS);
        return (INIT_FAILED);
    }

    ArrayFree(sData);
    ArrayResize(sData, num_sep);
    sDataSize = ArraySize(sData);

    for (int cnt = 0; cnt < num_sep; cnt++)
    {
        if (false == GetPeriodFromKeyAndInitDataVarsStruct(str_period_split[cnt], sData[cnt]))
        {
            Print(" GetPeriodFromKeyAndInitDataVarsStruct failed ", str_period_split[cnt]);
            return (INIT_FAILED);
        }

    } // for( int cnt = 0; cnt < num_sep; cnt++ )

    // ArrayPrint( sData );

    // EventSetTimer(1);
    EventSetMillisecondTimer(EventTimerIntervalMsc);

    return INIT_SUCCEEDED;

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // int _OnInit(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// #include <WinAPI\sysinfoapi.mqh>
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
    return (1000 * (StructToTime(dt) + 7200) + st.wMilliseconds);
} // long GetSystemTimeMsc(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _OnTimer()
{

    string str;
    datetime tc = TimeCurrent();
    datetime tl = TimeLocal();
    datetime tsmsc = GetSystemTimeMsc();

    string delta_ms_since_last_tick_str = "n/a";
    int delta_ms_since_last_tick = 0;

    //--- get data on the last tick
    double last_price = 0;
    double last_spread = 0;
    MqlTick t;
    if (!SymbolInfoTick(Symbol(), t))
    {
        Print("SymbolInfoTick() failed, error = ", GetLastError());
    }
    else
    {
        // eliminate strange things
        if (t.ask == 0 || t.bid == 0 || t.ask < t.bid)
        {
            Print("SymbolInfoTick() Ticks error");
        }
        else
        {
            last_spread = (t.ask - t.bid) / _Point;
            last_price = (t.ask + t.bid) / 2;

            delta_ms_since_last_tick = (int)(tsmsc - t.time_msc);
            if (0 != delta_ms_since_last_tick)
            {
                delta_ms_since_last_tick_str = StringFormat("%3d.%03ds",
                                                            (int)((tsmsc - t.time_msc) / 1000),
                                                            (int)((tsmsc - t.time_msc) % 1000));
            }

            if (0 < Debug)
            {
                //--- display the last tick time up to milliseconds
                str = StringFormat("    tt %s.%03d  tsmsc %s.%03d  tl %s  tc %s  delta: %s",
                                   TimeToString(t.time, TIME_SECONDS),
                                   t.time_msc % 1000,
                                   TimeToString(tsmsc / 1000, TIME_SECONDS),
                                   tsmsc % 1000,

                                   TimeToString(tl, TIME_SECONDS),
                                   TimeToString(tc, TIME_SECONDS),

                                   delta_ms_since_last_tick_str);

                Print(str);

                str = StringFormat("    -  Last tick [ %s / %s / %s ] was at %s.%03d with spread [ %4d ]",
                                   DoubleToString(t.ask, _Digits),
                                   DoubleToString(last_price, _Digits),
                                   DoubleToString(t.bid, _Digits),
                                   TimeToString(t.time, TIME_SECONDS),
                                   // t.time_msc % 1000,
                                   tl % 1000,
                                   (int)last_spread);
                Print(str);

            } // if (0 < Debug)

        } // if (t.ask == 0 || t.bid == 0 || t.ask < t.bid)

    } // if (!SymbolInfoTick(Symbol(), t))

    for (int cnt = 0; cnt < sDataSize; cnt++)
    {

        if (ENUM_PERIOD_TYPE_SECONDS_S == sData[cnt].periodType)
        {

            MqlTick array[];
            int size1 = CopyTicksRange(_Symbol, array, gCopyTicksFlags, t.time_msc - sData[cnt].periodNum * 1000, t.time_msc);
            if (0 < size1)
            {
                int oc1 = 0;
                int hl1 = 0;
                int spread1 = 0;
                ExtractHighLowFromMqlTickArray(array, oc1, hl1, spread1);
                sData[cnt].HL = hl1;
                sData[cnt].OC = oc1;
                sData[cnt].VOLS = size1;
                // sData[cnt].TD = (int)(array[size1-1].time_msc-array[0].time_msc)/1000;
                sData[cnt].TD = (int)sData[cnt].periodNum;
                sData[cnt].TT = (int)( (sData[cnt].TD*1000)/sData[cnt].VOLS );
                sData[cnt].SPREAD = spread1;
                sData[cnt].OC_HL = MathAbs((double)((double)sData[cnt].OC/(double)sData[cnt].HL));
                sData[cnt].VOLS_TD = (double)((double)sData[cnt].VOLS/(double)sData[cnt].TD);
                sData[cnt].HL_TD = (double)((double)sData[cnt].HL/(double)sData[cnt].TD);
                sData[cnt].SUMCOL = sData[cnt].OC_HL + sData[cnt].VOLS_TD + sData[cnt].HL_TD;
                sData[cnt].c0 = last_price;
                sData[cnt].t0 = array[size1-1].time_msc;
                sData[cnt].c1 = (array[0].ask + array[0].bid) / 2;
                sData[cnt].t1 = array[0].time_msc;

                if (0 < Debug)
                {
                    str = StringFormat("   st %s.%03d  tt %s.%03d  at %s.%03d  deltaS1: %dms   deltaS2: %3d.%03d",
                                       // st - system time
                                       TimeToString(tsmsc / 1000, TIME_SECONDS),
                                       tsmsc % 1000,

                                       // tt - last tick time
                                       TimeToString(t.time_msc / 1000, TIME_SECONDS),
                                       t.time_msc % 1000,

                                       // at - array time
                                       TimeToString(array[size1 - 1].time_msc / 1000, TIME_SECONDS),
                                       array[size1 - 1].time_msc % 1000,

                                       // delta last tick and array time - must be 0ms always
                                       (int)t.time_msc - array[size1 - 1].time_msc,

                                       // delta_ms_since_last_tick = (tsmsc-t.time_msc)
                                       delta_ms_since_last_tick / 1000,
                                       delta_ms_since_last_tick % 1000);
                    Print(str);
                } // if( 0 < Debug )

            } // if( 0 < size1 )
        } // if (ENUM_PERIOD_TYPE_SECONDS_S == sData[cnt].periodType)

        if (ENUM_PERIOD_TYPE_TICKS_T == sData[cnt].periodType)
        {
            MqlTick src_array[];
            int src_size = 0;

            for (int inc_cnt = 1; inc_cnt < 15; inc_cnt++)
            {
                src_size = CopyTicksRange(_Symbol, src_array, gCopyTicksFlags, t.time_msc - inc_cnt * sData[cnt].periodNum * 1000, t.time_msc);
            }

            if (src_size > sData[cnt].periodNum)
            {

                MqlTick dst_array[];
                ArrayCopy(dst_array, src_array, 0, (src_size - sData[cnt].periodNum), sData[cnt].periodNum);
                int dst_size = ArraySize(dst_array);
                if (sData[cnt].periodNum == dst_size)
                {

                    int oc1 = 0;
                    int hl1 = 0;
                    int spread1 = 0;
                    ExtractHighLowFromMqlTickArray(dst_array, oc1, hl1, spread1);
                    sData[cnt].HL = hl1;
                    sData[cnt].OC = oc1;
                    sData[cnt].VOLS = dst_size;
                    sData[cnt].TD = (int)(dst_array[dst_size - 1].time_msc - dst_array[0].time_msc) / 1000;
                    sData[cnt].TT = (int)( (sData[cnt].TD*1000)/sData[cnt].VOLS );
                    sData[cnt].SPREAD = spread1;
                    sData[cnt].OC_HL = MathAbs((double)((double)sData[cnt].OC/(double)sData[cnt].HL));
                    sData[cnt].VOLS_TD = (double)((double)sData[cnt].VOLS/(double)sData[cnt].TD);
                    sData[cnt].HL_TD = (double)((double)sData[cnt].HL/(double)sData[cnt].TD);
                    sData[cnt].SUMCOL = sData[cnt].OC_HL + sData[cnt].VOLS_TD + sData[cnt].HL_TD;
                    sData[cnt].c0 = last_price;
                    sData[cnt].t0 = dst_array[dst_size-1].time_msc;
                    sData[cnt].c1 = (dst_array[0].ask + dst_array[0].bid) / 2;
                    sData[cnt].t1 = dst_array[0].time_msc;

                    if (0 < Debug)
                    {

                        /*MqlTick arr1[2];
                        arr1[0]=src_array[0];
                        arr1[1]=src_array[src_size-1];
                        ArrayPrint( arr1 );
                        MqlTick arr2[2];
                        arr2[0]=dst_array[0];
                        arr2[1]=dst_array[dst_size-1];
                        ArrayPrint( arr2 );*/

                        str = StringFormat("   st %s.%03d  tt %s.%03d  at %s.%03d  deltaT1: %dms   deltaT2: %3d.%03d",
                                           // st - system time
                                           TimeToString(tsmsc / 1000, TIME_SECONDS),
                                           tsmsc % 1000,

                                           // tt - last tick time
                                           TimeToString(t.time_msc / 1000, TIME_SECONDS),
                                           t.time_msc % 1000,

                                           // at - array time
                                           TimeToString(dst_array[dst_size - 1].time_msc / 1000, TIME_SECONDS),
                                           dst_array[dst_size - 1].time_msc % 1000,

                                           // delta last tick and array time - must be 0ms always
                                           (int)t.time_msc - dst_array[dst_size - 1].time_msc,

                                           // delta_ms_since_last_tick = (tsmsc-t.time_msc)
                                           delta_ms_since_last_tick / 1000,
                                           delta_ms_since_last_tick % 1000);
                        Print(str);
                    } // if( 0 < Debug )

                } // if( sData[cnt].periodNum == dst_size )

            } // if( size1 > sData[cnt].periodNum )

        } // if (ENUM_PERIOD_TYPE_TICKS_T == sData[cnt].periodType)

    } // for( int cnt = 0; cnt < sDataSize; cnt++ )
    
    // calc average statistics
    int cnt_s = 0;
    int cnt_t = 0;
    int oc_s_avg = 0;
    int oc_t_avg = 0;
    int hl_s_avg = 0;
    int hl_t_avg = 0;
    int vols_s_avg = 0;
    int vols_t_avg = 0;
    int td_s_avg = 0;
    int td_t_avg = 0;
    int tt_s_avg = 0;
    int tt_t_avg = 0;
    int spread_s_avg = 0;
    int spread_t_avg = 0;
    double oc_hl_s_avg = 0;
    double oc_hl_t_avg = 0;
    double vols_td_s_avg = 0;
    double vols_td_t_avg = 0;
    double hl_td_s_avg = 0;
    double hl_td_t_avg = 0;
    double sumcol_s_avg = 0;
    double sumcol_t_avg = 0;
    
    for (int cnt = 0; cnt < sDataSize; cnt++)
    {
    
        if (ENUM_PERIOD_TYPE_SECONDS_S == sData[cnt].periodType)
        {
            cnt_s++;
            oc_s_avg += sData[cnt].OC;
            hl_s_avg += sData[cnt].HL;
            vols_s_avg += sData[cnt].VOLS;
            td_s_avg += sData[cnt].TD;
            tt_s_avg += sData[cnt].TT;
            spread_s_avg += sData[cnt].SPREAD;
            oc_hl_s_avg += sData[cnt].OC_HL;
            vols_td_s_avg += sData[cnt].VOLS_TD;
            hl_td_s_avg += sData[cnt].HL_TD;
            sumcol_s_avg += sData[cnt].SUMCOL;
        }    
    
        if (ENUM_PERIOD_TYPE_TICKS_T == sData[cnt].periodType)
        {
            cnt_t++;
            oc_t_avg += sData[cnt].OC;
            hl_t_avg += sData[cnt].HL;
            vols_t_avg += sData[cnt].VOLS;
            td_t_avg += sData[cnt].TD;
            tt_t_avg += sData[cnt].TT;
            spread_t_avg += sData[cnt].SPREAD;
            oc_hl_t_avg += sData[cnt].OC_HL;
            vols_td_t_avg += sData[cnt].VOLS_TD;
            hl_td_t_avg += sData[cnt].HL_TD;
            sumcol_t_avg += sData[cnt].SUMCOL;
        }

        if (ENUM_PERIOD_TYPE_AVERAGE_S == sData[cnt].periodType)
        {
            sData[cnt].OC = (int)oc_s_avg/cnt_s;
            sData[cnt].HL = (int)hl_s_avg/cnt_s;
            sData[cnt].VOLS = (int)vols_s_avg/cnt_s;
            sData[cnt].TD = (int)td_s_avg/cnt_s;
            sData[cnt].TT = (int)tt_s_avg/cnt_s;
            sData[cnt].SPREAD = (int)spread_s_avg/cnt_s;
            sData[cnt].OC_HL = (double)oc_hl_s_avg/cnt_s;
            sData[cnt].VOLS_TD = (double)vols_td_s_avg/cnt_s;
            sData[cnt].HL_TD = (double)hl_td_s_avg/cnt_s;
            sData[cnt].SUMCOL = (double)sumcol_s_avg/cnt_s;
        }
        
        if (ENUM_PERIOD_TYPE_AVERAGE_T == sData[cnt].periodType)
        {
            sData[cnt].OC = (int)oc_t_avg/cnt_t;
            sData[cnt].HL = (int)hl_t_avg/cnt_t;
            sData[cnt].VOLS = (int)vols_t_avg/cnt_t;
            sData[cnt].TD = (int)td_t_avg/cnt_t;
            sData[cnt].TT = (int)tt_t_avg/cnt_t;
            sData[cnt].SPREAD = (int)spread_t_avg/cnt_t;
            sData[cnt].OC_HL = (double)oc_hl_t_avg/cnt_t;
            sData[cnt].VOLS_TD = (double)vols_td_t_avg/cnt_t;
            sData[cnt].HL_TD = (double)hl_td_t_avg/cnt_t;
            sData[cnt].SUMCOL = (double)sumcol_t_avg/cnt_t;
        }

        if (ENUM_PERIOD_TYPE_AVERAGE_SUM == sData[cnt].periodType)
        {
            sData[cnt].OC = ((int)oc_s_avg/cnt_s + (int)oc_t_avg/cnt_t)/2;
            sData[cnt].HL = ((int)hl_s_avg/cnt_s + (int)hl_t_avg/cnt_t)/2;
            sData[cnt].VOLS = ((int)vols_s_avg/cnt_s + (int)vols_t_avg/cnt_t)/2;
            sData[cnt].TD = ((int)td_s_avg/cnt_s + (int)td_t_avg/cnt_t)/2;
            sData[cnt].TT = ((int)tt_s_avg/cnt_s + (int)tt_t_avg/cnt_t)/2;
            sData[cnt].SPREAD = ((int)spread_s_avg/cnt_s + (int)spread_t_avg/cnt_t)/2;
            sData[cnt].OC_HL = ((double)oc_hl_s_avg/cnt_s + (double)oc_hl_t_avg/cnt_t)/2;
            sData[cnt].VOLS_TD = ((double)vols_td_s_avg/cnt_s + (double)vols_td_t_avg/cnt_t)/2;
            sData[cnt].HL_TD = ((double)hl_td_s_avg/cnt_s + (double)hl_td_t_avg/cnt_t)/2;
            sData[cnt].SUMCOL = ((double)sumcol_s_avg/cnt_s + (double)sumcol_t_avg/cnt_t)/2;
        }

    } // for( int cnt = 0; cnt < sDataSize; cnt++ )
    

    // ArrayPrint( sData );

    ulong position_ID = 0;
    long pos_open_time = 0;
    long create_time_delta = 0;

    ulong pos_open_time_delta = 0;
    long pos_open_price_delta = 0;
    double pos_open_price = 0;
    double pos_open_price_last = 0;
    double pos_open_profit = 0;
    double pos_open_vol = 0;
    ENUM_POSITION_TYPE pos_open_type = 0;

    double acc_bal = AccountInfoDouble(ACCOUNT_BALANCE);
    double acc_cre = AccountInfoDouble(ACCOUNT_CREDIT);
    double acc_pro = AccountInfoDouble(ACCOUNT_PROFIT);
    double acc_equ = AccountInfoDouble(ACCOUNT_EQUITY);
    double acc_mrg = AccountInfoDouble(ACCOUNT_MARGIN);
    double acc_mrg_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double acc_mrg_lvl = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    double acc_mrg_so_call = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
    double acc_mrg_so_so = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);

    str = StringFormat("   ACCOUNT: %s / %s / %s - MARGIN free: %s ",
                       DoubleToString(acc_equ, 2),
                       DoubleToString(acc_bal, 2),
                       DoubleToString(acc_pro, 2),
                       DoubleToString(acc_mrg_free, 2));
    if (0 < Debug)
        Print(str);

    str = StringFormat(" t: %s  no open position", TimeToString(TimeCurrent(), TIME_SECONDS));

    string sBS = "";
    //--- check if a position is present and display the time of its changing
    if (PositionSelect(_Symbol))
    {

        //--- receive position ID for further work
        position_ID = PositionGetInteger(POSITION_IDENTIFIER);
        //--- receive the time of position forming in milliseconds since 01.01.1970
        pos_open_time = PositionGetInteger(POSITION_TIME);
        create_time_delta = TimeCurrent() - pos_open_time;

        pos_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        pos_open_price_last = PositionGetDouble(POSITION_PRICE_CURRENT);
        pos_open_profit = PositionGetDouble(POSITION_PROFIT);
        pos_open_vol = PositionGetDouble(POSITION_VOLUME);

        pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if (POSITION_TYPE_BUY == pos_open_type)
        {
            pos_open_price_delta = (long)((pos_open_price_last - pos_open_price) / _Point);
            sBS = "BUY ";
        }

        if (POSITION_TYPE_SELL == pos_open_type)
        {
            pos_open_price_delta = (long)((pos_open_price - pos_open_price_last) / _Point);
            sBS = "SELL";
        }

        str = StringFormat(" t: %s [%s v%0.2f] %s #%d   %6d / %6ds ",
                           TimeToString(TimeCurrent(), TIME_SECONDS),
                           sBS,
                           pos_open_vol,
                           _Symbol,
                           position_ID,
                           pos_open_price_delta,
                           create_time_delta);

        str += StringFormat(" -  open price delta: %5d - last price %s  - open price %s - profit: %s - vol: %s",
                            pos_open_price_delta,
                            DoubleToString(pos_open_price_last, _Digits),
                            DoubleToString(pos_open_price, _Digits),
                            DoubleToString(pos_open_profit, 2),
                            DoubleToString(pos_open_vol, 2));

        str += StringFormat(" -  %d delta seconds => curr time %s  - open time %s",
                            create_time_delta, TimeToString(TimeCurrent(), TIME_SECONDS), TimeToString(pos_open_time, TIME_SECONDS));

    } // if(PositionSelect(_Symbol))

    if (0 < Debug)
        Print(str);

    //
    // comment output c0 and spread
    //
    int _comment_txt_line_start = 0;

    string tickv_str = StringFormat("c0: %s s: %2d d: %4s",
                                    // TODO FixMe - here the T60 c0 shall go
                                    DoubleToString(sData[0].c0, Digits()),
                                    (int)last_spread,
                                    delta_ms_since_last_tick_str);

    comment.SetText(_comment_txt_line_start, tickv_str, COLOR_TEXT);
    _comment_txt_line_start++;

    //
    // comment output MA
    //

    // first set the header
    string _header_str = "              OC/  HL/VOLS/  TD/  TT/   S/";
    comment.SetText(_comment_txt_line_start, _header_str, COLOR_TEXT);
    _comment_txt_line_start++;
    
    int _sum_avg_threshold = 0;
    string _ma_str = "";

    for (int cnt = 0; sDataSize > cnt; cnt++)
    {

        _ma_str = StringFormat("  %7s : %4d/%4d/%4d/%4d/%4d/%4d/%4.1f/%4.1f/%4.1f/%4.1f",
                               sData[cnt].periodKey,
                               sData[cnt].OC,
                               sData[cnt].HL,
                               sData[cnt].VOLS,
                               sData[cnt].TD,
                               sData[cnt].TT,
                               sData[cnt].SPREAD,
                               sData[cnt].OC_HL,
                               sData[cnt].VOLS_TD,
                               sData[cnt].HL_TD,
                               sData[cnt].SUMCOL);
        _sum_avg_threshold = 10 + (int)last_spread;
        int _lineno = _comment_txt_line_start + cnt;
        if (+1 * _sum_avg_threshold < sData[cnt].SUMCOL)
        {
            comment.SetText(_lineno, _ma_str, COLOR_BLUE);
        }
        else if (-1 * _sum_avg_threshold > sData[cnt].SUMCOL)
        {
            comment.SetText(_lineno, _ma_str, COLOR_RED);
        }
        else
        {
            comment.SetText(_lineno, _ma_str, COLOR_TEXT);
        }
    } // for( int cnt = 0; sMaSize > cnt; cnt++ )

    //
    // comment output open positions
    //
    _comment_txt_line_start += sDataSize;

    if ("" == sBS || 0.0 == pos_open_vol)
    {
        string bs_str = StringFormat("%s(0.00)",
                                     _Symbol);
        comment.SetText(_comment_txt_line_start, bs_str, COLOR_TEXT);
    }
    else
    {
        string bs_str = StringFormat("%s(%0.2f) %6d over %6d s",
                                     //_Symbol,
                                     sBS,
                                     pos_open_vol,
                                     pos_open_price_delta,
                                     create_time_delta);

        if (10 < pos_open_price_delta)
        {
            if ("BUY " == sBS)
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_BLUE);
            else if ("SELL" == sBS)
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_RED);
            else
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_TEXT);
        }
        else if (-10 > pos_open_price_delta)
        {
            comment.SetText(_comment_txt_line_start, bs_str, COLOR_YELLOW);
        }
        else
        {
            comment.SetText(_comment_txt_line_start, bs_str, COLOR_TEXT);
        }
    } // if( "" == sBS || 0.0 == pos_open_vol )

    //
    // comment show
    //
    comment.Show();

    string c2_str = StringFormat("%s  %s%s",
                                 TimeToString(TimeCurrent(), TIME_SECONDS),
                                 _Symbol,
                                 symbolNameAppendix);
    comment2.SetText(0, c2_str, COLOR_TEXT);
    comment2.Show();

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // void _OnTimer()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _OnTick(void)
{

} // void _OnTick(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _OnDeinit(const int reason)
{

    Print("OnDeinit: ", reason);

    //--- remove panel
    comment.Destroy();
    comment2.Destroy();

    ObjectsDeleteAll(0, "", -1, -1);
    ChartRedraw(0);

    Comment("");
    //--- destroy the timer after completing the work
    EventKillTimer();

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // void _OnDeinit(const int reason)
//+------------------------------------------------------------------+

//
// helper functions
//
