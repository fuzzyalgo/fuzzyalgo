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

// @TODO 2025-12-24 andrehowe - implement no trading times
// Schedule for trading on currency pairs
// 24/12/2025 – trading stops at 8:00 PM server time
// 25/12/2025 – no trading
// 26/12/2025 – trading starts at 10:00 AM server time
// 31/12/2025 – trading stops at 8:00 PM server time
// 01/01/2026 – no trading
// 02/01/2026 – trading starts at 10:00 AM server time

// I N C L U D E S

// T Y P E D E F S
enum ENUM_PERIOD_TYPE
{
    ENUM_PERIOD_TYPE_NONE,
    ENUM_PERIOD_TYPE_PRO,
    ENUM_PERIOD_TYPE_SECONDS_S,
    ENUM_PERIOD_TYPE_TICKS_T,
    ENUM_PERIOD_TYPE_AVERAGE_S,
    ENUM_PERIOD_TYPE_AVERAGE_T,
    ENUM_PERIOD_TYPE_AVERAGE_SUM,
    ENUM_PERIOD_TYPE_MAX
};

// I N P U T S
// input string PERIODS = "T60:T300:T900:T3600:T_AVG:S60:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG:S15:S30:S60:S300:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG";            // periods are seperated by colon. T for Ticks and S for seconds
input string ACCOUNT = "RF5D03"; // forex account name s use
input string PERIODS = "PRO:T15:T30:T60:T_AVG:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
input ENUM_COPY_TICKS gCopyTicksFlags = COPY_TICKS_TIME_MS;                   // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL
input int Debug = 0;                                                          // enable debug output
input int EventTimerIntervalMsc = 1000;                                       // Event Timer Interval in milliseconds

// G L O B A L S
string FolderOfTheDay;
string FnInAll = "";
string FnInCur = "";
string FnInScr1 = "";
string FnInScr2 = "";
string FnInAllPath = "";
string FnInCurPath = "";
string FnInScr1Path = "";
string FnInScr2Path = "";
string FnAnaFolder = "";
string FnAnaFolderTimeMS = "";
bool CopyIntoAnaFolder = true;
long id_pro_chart = 0;
long id_chart = 0;

CComment comment;
CComment comment2;

struct sDataVars
{

    string symbol;
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

    long daily_open_t0;
    double daily_open_c0;
    long id_pro_chart;

    string str_txt;

    void print()
    {
        string str = StringFormat("sym: %s num: %4d key: %10s type: %s", symbol, periodNum, periodKey, EnumToString(periodType));
        if (0 < Debug)
        {
            Print(str);
        }
    } // void print()

}; // struct sDataVars

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitDataVarsStruct(sDataVars &sd, const string &symbol)
{

    sd.symbol = symbol;
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

    sd.daily_open_t0 = 0;
    sd.daily_open_c0 = 0.0;
    sd.id_pro_chart = 0;

    sd.str_txt = "";

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // void InitDataVarsStruct(sDataVars &sd, const string& symbol)
//+------------------------------------------------------------------+

// sDataVars sData[9];
sDataVars sData[];
int sDataSize;

string customSymbolName;
string symbolNameAppendix;

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
        if (spread < s)
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
bool GetPeriodFromKeyAndInitDataVarsStruct(const string &symbol, const string &periodKey, sDataVars &sd)
{

    InitDataVarsStruct(sd, symbol);

    if ("PRO" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_PRO;
        sd.periodNum = 0;
        sd.periodKey = periodKey;

        sd.daily_open_t0 = 0;
        sd.daily_open_c0 = 0.0;
        sd.id_pro_chart = 0;

        sd.print();
        return true;
    }

    if ("T15" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 15;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("T30" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 30;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("T60" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 60;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("T300" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 300;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("T900" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 900;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("T3600" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_TICKS_T;
        sd.periodNum = 3600;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("T_AVG" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_AVERAGE_T;
        sd.periodNum = 0;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S15" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 15;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S30" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 30;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S60" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 60;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S300" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 300;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S900" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 900;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S3600" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_SECONDS_S;
        sd.periodNum = 3600;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("S_AVG" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_AVERAGE_S;
        sd.periodNum = 0;
        sd.periodKey = periodKey;
        sd.print();
        return true;
    }

    if ("SUM_AVG" == periodKey)
    {
        sd.periodType = ENUM_PERIOD_TYPE_AVERAGE_SUM;
        sd.periodNum = 0;
        sd.periodKey = periodKey;
        sd.print();
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

    datetime dt0 = iTime(_Symbol, PERIOD_M1, 0);
    MqlDateTime t0;
    TimeToStruct(dt0, t0);
    symbolNameAppendix = StringFormat("%04d-%02d-%02d",
                                      t0.year,
                                      t0.mon,
                                      t0.day);

    FolderOfTheDay = StringFormat("%s\\%04d\\%02d\\%02d",
                                  ACCOUNT,
                                  t0.year,
                                  t0.mon,
                                  t0.day);
    FolderCreate(FolderOfTheDay);
    FnAnaFolder = FolderOfTheDay + "\\ANA";
    FolderCreate(FnAnaFolder);

    FnAnaFolderTimeMS = StringFormat("%s\\%02d-%02d-%02d.%03d",
                                     FnAnaFolder,
                                     t0.hour,
                                     t0.min,
                                     t0.sec,
                                     0); // TODO use tsmsc later once all symbols run from one chart/agent //tsmsc % 1000 );
    FolderCreate(FnAnaFolderTimeMS);

    customSymbolName = symbolNameAppendix + "_PRO_" + Symbol();
    FnInAll = Symbol() + "_INP_ALL.csv";
    FnInCur = Symbol() + "_INP_CUR.csv";
    FnInScr1 = Symbol() + "_INP_SCR1.png";
    FnInScr2 = Symbol() + "_INP_SCR2.png";
    FnInAllPath = FolderOfTheDay + "\\" + FnInAll;
    FnInCurPath = FolderOfTheDay + "\\" + FnInCur;
    FnInScr1Path = FolderOfTheDay + "\\" + FnInScr1;
    FnInScr2Path = FolderOfTheDay + "\\" + FnInScr2;

    bool justCreated = false;

    if (SymbolInfoInteger(_Symbol, SYMBOL_CUSTOM))
    {
        Alert("" + _Symbol + " is a custom symbol. Only built-in symbol can be used as a host.");
        return INIT_FAILED;
    }

    if (!SymbolSelect(customSymbolName, true))
    {
        ResetLastError();
        SymbolInfoInteger(customSymbolName, SYMBOL_CUSTOM);
        if (ERR_MARKET_UNKNOWN_SYMBOL == GetLastError())
        {
            Print("create symbol: " + customSymbolName);
            // CustomSymbolCreate( customSymbolName, _Symbol, _Symbol );
            CustomSymbolCreate(customSymbolName);
            justCreated = true;
        }

        if (!SymbolSelect(customSymbolName, true))
        {
            Alert("Can't select symbol:", customSymbolName, " err:", GetLastError());
            return INIT_FAILED;
        }
    }

    if (!TerminalInfoInteger(TERMINAL_CONNECTED))
    {
        Print("Waiting for connection...");
        return (INIT_FAILED);
    }
    // NB! Since some MT5 build function SeriesInfoInteger(SERIES_SYNCHRONIZED) does not work properly anymore
    // and returns false always, so replaced with SymbolIsSynchronized
    // if(!SeriesInfoInteger(_Symbol, _Period, SERIES_SYNCHRONIZED))
    if (!SymbolIsSynchronized(_Symbol))
    {
        Print("Unsynchronized, skipping ticks...");
        return (INIT_FAILED);
    }

    id_pro_chart = 0;
    id_chart = 0;

    //--- variables for chart identifiers
    long curr_chart = ChartFirst();
    int cnt_chart = 0;

    //--- until the open chart limit is reached (CHARTS_MAX)
    while (!IsStopped() && cnt_chart < CHARTS_MAX)
    {
        //--- terminate the loop if the end of the chart list is reached
        if (curr_chart < 0)
            break;

        string chart_sym = ChartSymbol(curr_chart);
        if (0 == StringCompare(customSymbolName, chart_sym))
        {
            // TODO consolidate with sDataVars structure
            id_pro_chart = curr_chart;
            //--- print the next chart data in the journal if it matches
            if (0 < Debug)
                PrintFormat("Chart[%d] ID: %I64d,  symbol: %s", cnt_chart, id_pro_chart, chart_sym);
        }
        if (0 == StringCompare(_Symbol, chart_sym))
        {
            // TODO consolidate with sDataVars structure
            id_chart = curr_chart;
            //--- print the next chart data in the journal if it matches
            if (0 < Debug)
                PrintFormat("Chart[%d] ID: %I64d,  symbol: %s", cnt_chart, id_chart, chart_sym);
        }

        //--- get the next chart ID based on the previous one
        curr_chart = ChartNext(curr_chart);

        //--- increase the chart counter
        cnt_chart++;
    } // while (!IsStopped() && cnt_chart < CHARTS_MAX)

    if (id_pro_chart == 0)
    {
        long id = ChartOpen(customSymbolName, PERIOD_M1);
        if (id == 0)
        {
            Print("Can't open new chart for ", customSymbolName, ", code: ", GetLastError());
            return (INIT_FAILED);
        }
        id_pro_chart = id;

        string TicksTmplFN = "TicksTmpl.tpl";
        ResetLastError();
        // was the applying of the template successful
        bool okTmplApply = ChartApplyTemplate(id, TicksTmplFN);
        if (false == okTmplApply)
        {
            Print("ChartApplyTemplate() error ", GetLastError());
            // string tmpl = TerminalInfoString(TERMINAL_DATA_PATH)+"\\Mql5\\Profiles\\Templates\\TicksTmpl.tpl";
            // 2025.12.25 10:18:06.925	Ticks (EURUSD,M1)	C:\Users\G6\AppData\Roaming\MetaTrader5_RF5D03\Mql5\Profiles\Templates\TicksTmpl.tpl
            // 2025.12.25 10:18:07.925	Ticks (EURUSD,M1)	ChartApplyTemplate() error 5019
            // ERR_FILE_NOT_EXIST 5019 File does not exist
            // chart template not found or error while applying chart template
            ChartSetSymbolPeriod(id, customSymbolName, PERIOD_M1);
            ChartSetInteger(id, CHART_MODE, CHART_CANDLES);
        }
    } // if (id_pro_chart == 0)

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
        if (false == GetPeriodFromKeyAndInitDataVarsStruct(_Symbol, str_period_split[cnt], sData[cnt]))
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

    datetime dt0 = iTime(_Symbol, PERIOD_M1, 0);
    MqlDateTime t0;
    TimeToStruct(dt0, t0);
    FnAnaFolderTimeMS = StringFormat("%s\\%02d-%02d-%02d.%03d",
                                     FnAnaFolder,
                                     t0.hour,
                                     t0.min,
                                     t0.sec,
                                     0); // TODO use tsmsc later once all symbols run from one chart/agent //tsmsc % 1000 );
    FolderCreate(FnAnaFolderTimeMS);

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
            delta_ms_since_last_tick_str = StringFormat("%3d.%03ds", 0, 0);
            // if the tick was faster than system time then set null
            // TODO find out why tsmsc was late
            if (tsmsc < t.time_msc)
            {
                delta_ms_since_last_tick = 0;
            }
            delta_ms_since_last_tick_str = StringFormat("%3d.%03ds",
                                                        (int)(delta_ms_since_last_tick / 1000),
                                                        (int)(delta_ms_since_last_tick % 1000));

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
                sData[cnt].TT = (int)((sData[cnt].TD * 1000) / sData[cnt].VOLS);
                sData[cnt].SPREAD = spread1;
                sData[cnt].OC_HL = MathAbs((double)((double)sData[cnt].OC / (double)sData[cnt].HL));
                sData[cnt].VOLS_TD = (double)((double)sData[cnt].VOLS / (double)sData[cnt].TD);
                sData[cnt].HL_TD = (double)((double)sData[cnt].HL / (double)sData[cnt].TD);
                sData[cnt].SUMCOL = sData[cnt].OC_HL + sData[cnt].VOLS_TD + sData[cnt].HL_TD;
                sData[cnt].c0 = last_price;
                sData[cnt].t0 = array[size1 - 1].time_msc;
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
                    sData[cnt].TT = (int)((sData[cnt].TD * 1000) / sData[cnt].VOLS);
                    sData[cnt].SPREAD = spread1;
                    sData[cnt].OC_HL = MathAbs((double)((double)sData[cnt].OC / (double)sData[cnt].HL));
                    sData[cnt].VOLS_TD = (double)((double)sData[cnt].VOLS / (double)sData[cnt].TD);
                    sData[cnt].HL_TD = (double)((double)sData[cnt].HL / (double)sData[cnt].TD);
                    sData[cnt].SUMCOL = sData[cnt].OC_HL + sData[cnt].VOLS_TD + sData[cnt].HL_TD;
                    sData[cnt].c0 = last_price;
                    sData[cnt].t0 = dst_array[dst_size - 1].time_msc;
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
            sData[cnt].OC = (int)oc_s_avg / cnt_s;
            sData[cnt].HL = (int)hl_s_avg / cnt_s;
            sData[cnt].VOLS = (int)vols_s_avg / cnt_s;
            sData[cnt].TD = (int)td_s_avg / cnt_s;
            sData[cnt].TT = (int)tt_s_avg / cnt_s;
            sData[cnt].SPREAD = (int)spread_s_avg / cnt_s;
            sData[cnt].OC_HL = (double)oc_hl_s_avg / cnt_s;
            sData[cnt].VOLS_TD = (double)vols_td_s_avg / cnt_s;
            sData[cnt].HL_TD = (double)hl_td_s_avg / cnt_s;
            sData[cnt].SUMCOL = (double)sumcol_s_avg / cnt_s;
        }

        if (ENUM_PERIOD_TYPE_AVERAGE_T == sData[cnt].periodType)
        {
            sData[cnt].OC = (int)oc_t_avg / cnt_t;
            sData[cnt].HL = (int)hl_t_avg / cnt_t;
            sData[cnt].VOLS = (int)vols_t_avg / cnt_t;
            sData[cnt].TD = (int)td_t_avg / cnt_t;
            sData[cnt].TT = (int)tt_t_avg / cnt_t;
            sData[cnt].SPREAD = (int)spread_t_avg / cnt_t;
            sData[cnt].OC_HL = (double)oc_hl_t_avg / cnt_t;
            sData[cnt].VOLS_TD = (double)vols_td_t_avg / cnt_t;
            sData[cnt].HL_TD = (double)hl_td_t_avg / cnt_t;
            sData[cnt].SUMCOL = (double)sumcol_t_avg / cnt_t;
        }

        if (ENUM_PERIOD_TYPE_AVERAGE_SUM == sData[cnt].periodType)
        {
            sData[cnt].OC = ((int)oc_s_avg / cnt_s + (int)oc_t_avg / cnt_t) / 2;
            sData[cnt].HL = ((int)hl_s_avg / cnt_s + (int)hl_t_avg / cnt_t) / 2;
            sData[cnt].VOLS = ((int)vols_s_avg / cnt_s + (int)vols_t_avg / cnt_t) / 2;
            sData[cnt].TD = ((int)td_s_avg / cnt_s + (int)td_t_avg / cnt_t) / 2;
            sData[cnt].TT = ((int)tt_s_avg / cnt_s + (int)tt_t_avg / cnt_t) / 2;
            sData[cnt].SPREAD = ((int)spread_s_avg / cnt_s + (int)spread_t_avg / cnt_t) / 2;
            sData[cnt].OC_HL = ((double)oc_hl_s_avg / cnt_s + (double)oc_hl_t_avg / cnt_t) / 2;
            sData[cnt].VOLS_TD = ((double)vols_td_s_avg / cnt_s + (double)vols_td_t_avg / cnt_t) / 2;
            sData[cnt].HL_TD = ((double)hl_td_s_avg / cnt_s + (double)hl_td_t_avg / cnt_t) / 2;
            sData[cnt].SUMCOL = ((double)sumcol_s_avg / cnt_s + (double)sumcol_t_avg / cnt_t) / 2;
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

    string sBS = "-";
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
            sBS = "B";
        }

        if (POSITION_TYPE_SELL == pos_open_type)
        {
            pos_open_price_delta = (long)((pos_open_price - pos_open_price_last) / _Point);
            sBS = "S";
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

    // TODO performance deal_cnt doesn't need to be calculated every time for performance reasons
    datetime dt_start_of_today = iTime(Symbol(), PERIOD_D1, 0);
    datetime dt_now = tsmsc / 1000 - 1;
    string histOKstatus = "OK";
    sDataHist hist;
    hist.init(_Symbol, dt_start_of_today, dt_now);
    bool histOK = m_LogHistoryDeals(hist);
    if (false == histOK)
    {
        histOKstatus = "NO";
        Print("ERROR m_LogHistoryDeals TODO implement error handling here");
    }
    // 2025.12.29 23:13:38.541	Ticks (NZDUSD,H1)	1767053618541  2025.12.30 00:13:38.541 NZDUSD @ 0.58012  d:   111 s: 92/161 SUM_AVG (OC:   -13 HL:   161   OC/HL: -0.08)  0.00@  PRO:     0 over      0s /    0.00 /    0.00 HIST[OK]: NZDUSD(2025.12.30 00:00:00-00:13:37 profit: #0  0.00 win: #0  0.00 loss: #0  0.00  comm:  0.00 / TOTAL profit: #0  0.00 win: #0  0.00 loss: #0  0.00  comm:  0.00)
    string hist_str = StringFormat("HIST[%s]: %s",
                                   histOKstatus,
                                   hist.formatstr());

    // 2025.12.29 17:03:18.125	Ticks (EURUSD,H1)	1767031398123  2025.12.29 18:03:18.123 EURUSD d:     0 s:  0/  6    SUM_AVG (OC:   -52 HL:    99   OC/HL: -0.53)  0.01@BUY   PRO:   -71 over   6137s /   -0.72 /    0.12
    // update custom profit rate symbol
    double pro_acc = AccountInfoDouble(ACCOUNT_PROFIT); // full total profit
    double pro_sym = pos_open_profit;                   // profit per symbol
    int last = sDataSize - 1;
    double c0 = NormalizeDouble(((double)sData[last].OC / (double)sData[last].HL), 2);
    if (0 < Debug)
    {
        str = StringFormat("%ld%03d  %s.%03d %s @ %s  d:%6d s:%3d/%3d %7s (OC: %5d HL: %5d   OC/HL: %5.2f)  %3.2f@%s  PRO: %5d over %6ds / %7.2f / %7.2f %s",
                           (long)tsmsc / 1000, tsmsc % 1000,
                           TimeToString(tsmsc / 1000, TIME_SECONDS | TIME_DATE),
                           tsmsc % 1000,
                           sData[last].symbol,
                           DoubleToString(last_price, Digits()),
                           delta_ms_since_last_tick,
                           (int)last_spread,
                           (int)sData[last].SPREAD,
                           sData[last].periodKey,
                           sData[last].OC,
                           sData[last].HL,
                           c0,
                           pos_open_vol,
                           sBS,
                           pos_open_price_delta,
                           create_time_delta,
                           pro_sym,
                           pro_acc,
                           hist_str);
        Print(str);
    }

    //
    // File input operations START
    //

    //                  1767053618541 2025.12.30 00:13:38.541 NZDUSD 0.58012     111     92   161   -13   161 -0.08 0.00 -       0      0    0.00    0.00 HIST[OK]: NZDUSD(2025.12.30 00:00:00-00:13:37 profit: #0  0.00 win: #0  0.00 loss: #0  0.00  comm:  0.00 / TOTAL profit: #0  0.00 win: #0  0.00 loss: #0  0.00  comm:  0.00)
    string csvheader = "epocms        date       time         symbol price   dtickms spread spavg    oc    hl oc_hl  vol T dprofit  dtime  sympro  allpro HIST";
    csvheader = csvheader + " " + hist.formatstrcsvheader();
    str = StringFormat("%ld%03d %s.%03d %s %s %7d %6d %5d %5d %5d %5.2f %3.2f %s %7d %6d %7.2f %7.2f %4s %s",
                       (long)tsmsc / 1000, tsmsc % 1000,
                       TimeToString(tsmsc / 1000, TIME_SECONDS | TIME_DATE),
                       tsmsc % 1000,
                       sData[last].symbol,
                       DoubleToString(last_price, Digits()),
                       delta_ms_since_last_tick,
                       (int)last_spread,
                       (int)sData[last].SPREAD,
                       sData[last].OC,
                       sData[last].HL,
                       c0,
                       pos_open_vol,
                       sBS,
                       pos_open_price_delta,
                       create_time_delta,
                       pro_sym,
                       pro_acc,
                       histOKstatus,
                       hist.formatstrcsv());
    // Print(str);

    // write the last INP(ut) "one line CUR(rent)" with csv header
    // recreate file as FILE_WRITE only is set
    ResetLastError();
    int file_handle = FileOpen(FnInCurPath, FILE_WRITE | FILE_CSV | FILE_ANSI);
    if (file_handle != INVALID_HANDLE)
    {
        FileWriteString(file_handle, csvheader);
        FileWriteString(file_handle, str + "\n");
        FileClose(file_handle);
    } // if(file_handle!=INVALID_HANDLE)
    if (true == CopyIntoAnaFolder)
    {
        string fndst = FnAnaFolderTimeMS + "\\" + FnInCur;
        FileCopy(FnInCurPath, 0, fndst, FILE_REWRITE);
    }

    // attach the last INPut to ALL whole day log to the last line
    ResetLastError();
    file_handle = FileOpen(FnInAllPath, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI);
    if (file_handle != INVALID_HANDLE)
    {
        FileSeek(file_handle, 0, SEEK_END);
        FileWriteString(file_handle, str + "\n");
        FileClose(file_handle);
    } // if(file_handle!=INVALID_HANDLE)
    if (true == CopyIntoAnaFolder)
    {
        string fndst = FnAnaFolderTimeMS + "\\" + FnInAll;
        FileCopy(FnInAllPath, 0, fndst, FILE_REWRITE);
    }

    //
    // File input operations END
    //

    MqlRates r[1];
    int length = CopyRates(customSymbolName, PERIOD_M1, dt0, 1, r);
    if ((1 == length) && (r[0].time == dt0))
    {
        // r[0].time = dt0;
        // r[0].open = iOpen(_Symbol, PERIOD_M1, 0);
        if (c0 > r[0].high)
            r[0].high = c0;
        if (c0 < r[0].low)
            r[0].low = c0;
        r[0].close = c0;
        r[0].tick_volume = r[0].tick_volume + 1;
    }
    else
    {
        r[0].time = dt0;
        r[0].open = c0;
        r[0].high = c0;
        r[0].low = c0;
        r[0].close = c0;
        r[0].real_volume = 0;
        r[0].spread = 0;
        r[0].tick_volume = 1;
    }

    CustomRatesUpdate(customSymbolName, r);

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

    if ("-" == sBS || 0.0 == pos_open_vol)
    {
        string bs_str = StringFormat("%s(0.00)",
                                     _Symbol);
        comment.SetText(_comment_txt_line_start, bs_str, COLOR_TEXT);
    }
    else
    {
        string bs_str = StringFormat("%s(%0.2f) %6d over %6d s  profit: %s / %s / %s",
                                     //_Symbol,
                                     sBS,
                                     pos_open_vol,
                                     pos_open_price_delta,
                                     create_time_delta,
                                     DoubleToString(pos_open_profit, 2),
                                     DoubleToString(acc_pro, 2),
                                     DoubleToString(pos_open_profit / acc_pro * 100, 0));

        bs_str = bs_str + "%";
        if (10 < pos_open_price_delta)
        {
            if ("B" == sBS)
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_BLUE);
            else if ("S" == sBS)
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
    } // if( "-" == sBS || 0.0 == pos_open_vol )

    /*
    double acc_bal = AccountInfoDouble(ACCOUNT_BALANCE);
    double acc_cre = AccountInfoDouble(ACCOUNT_CREDIT);
    double acc_pro = AccountInfoDouble(ACCOUNT_PROFIT);
    double acc_equ = AccountInfoDouble(ACCOUNT_EQUITY);
    double acc_mrg = AccountInfoDouble(ACCOUNT_MARGIN);
    double acc_mrg_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double acc_mrg_lvl = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    double acc_mrg_so_call = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
    double acc_mrg_so_so = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
    */

    color col = COLOR_TEXT;
    if ("B" == sBS)
        col = COLOR_BLUE;
    else if ("S" == sBS)
        col = COLOR_RED;

    _comment_txt_line_start++;
    string ac_bal_str = StringFormat("%s( balance: %s equity: %s profit: %s )",
                                     _Symbol,
                                     DoubleToString(acc_bal, 2),
                                     DoubleToString(acc_equ, 2),
                                     DoubleToString(acc_pro, 2));
    comment.SetText(_comment_txt_line_start, ac_bal_str, col);

    _comment_txt_line_start++;
    string ac_mrg_str = StringFormat("%s( margin: %s free: %s lvl: %s )",
                                     _Symbol,
                                     DoubleToString(acc_mrg, 2),
                                     DoubleToString(acc_mrg_free, 2),
                                     DoubleToString(acc_mrg_lvl, 2));
    comment.SetText(_comment_txt_line_start, ac_mrg_str, col);

    _comment_txt_line_start++;
    // datetime dt_start_of_today = iTime(Symbol(), PERIOD_D1, 0);
    // datetime dt_now = tsmsc / 1000 - 1;
    // int deal_cnt = m_LogHistoryDeals(dt_start_of_today, dt_now, _Symbol);
    string ac_hist_str = StringFormat("%s( history: %d deal_cnts )",
                                      _Symbol,
                                      hist.deal_cnt);
    comment.SetText(_comment_txt_line_start, ac_hist_str, col);

    //
    // comment show
    //
    comment.Show();

    string c2_str = StringFormat("%s %s  %s",
                                 TimeToString(TimeCurrent(), TIME_SECONDS),
                                 symbolNameAppendix,
                                 _Symbol);
    comment2.SetText(0, c2_str, COLOR_TEXT);
    comment2.Show();

    if( 0 < id_chart )
    {
        ChartScreenShot(id_chart, FnInScr1Path, 1600, 900, ALIGN_RIGHT);
        if (true == CopyIntoAnaFolder)
        {
            string fndst = FnAnaFolderTimeMS + "\\" + FnInScr1;
            FileCopy(FnInScr1Path, 0, fndst, FILE_REWRITE);
        }
    }
    if( 0 < id_pro_chart )
    {
        ChartScreenShot(id_pro_chart, FnInScr2Path, 1600, 900, ALIGN_RIGHT);
        if (true == CopyIntoAnaFolder)
        {
            string fndst = FnAnaFolderTimeMS + "\\" + FnInScr2;
            FileCopy(FnInScr2Path, 0, fndst, FILE_REWRITE);
        }
    }
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
struct sDataHist
{

    // global params
    string symbol;
    datetime dtstart;
    datetime dtend;

    // information per symbol
    int deal_cnt;
    int deal_cnt_win;
    int deal_cnt_loss;
    double deal_profit;
    double deal_profit_win;
    double deal_profit_loss;
    double commission;

    // information for "ALL" symbols
    int Adeal_cnt;
    int Adeal_cnt_win;
    int Adeal_cnt_loss;
    double Adeal_profit;
    double Adeal_profit_win;
    double Adeal_profit_loss;
    double Acommission;

    void init(const string &a_symbol, const datetime &a_dtstart, const datetime &a_dtend)
    {
        symbol = a_symbol;
        dtstart = a_dtstart;
        dtend = a_dtend;

        // information per symbol
        deal_cnt = 0;
        deal_cnt_win = 0;
        deal_cnt_loss = 0;
        deal_profit = 0;
        deal_profit_win = 0;
        deal_profit_loss = 0;
        commission = 0;

        // information for "ALL" symbols
        Adeal_cnt = 0;
        Adeal_cnt_win = 0;
        Adeal_cnt_loss = 0;
        Adeal_profit = 0;
        Adeal_profit_win = 0;
        Adeal_profit_loss = 0;
        Acommission = 0;
    } // void init( const string& symbol, const datetime& a_dtstart, const datetime& a_dtend )

    string formatstr()
    {
        string str = StringFormat("%s(%s-%s profit: #%d %5.2f win: #%d %5.2f loss: #%d %5.2f  comm: %5.2f / TOTAL profit: #%d %5.2f win: #%d %5.2f loss: #%d %5.2f  comm: %5.2f)",
                                  symbol,
                                  TimeToString(dtstart, TIME_SECONDS | TIME_DATE),
                                  TimeToString(dtend, TIME_SECONDS),
                                  deal_cnt,
                                  deal_profit,
                                  deal_cnt_win,
                                  deal_profit_win,
                                  deal_cnt_loss,
                                  deal_profit_loss,
                                  commission,
                                  Adeal_cnt,
                                  Adeal_profit,
                                  Adeal_cnt_win,
                                  Adeal_profit_win,
                                  Adeal_cnt_loss,
                                  Adeal_profit_loss,
                                  Acommission);
        return (str);
    }

    string formatstrcsvheader()
    {
        string str = "dtstart     dtend  #deal profit #dealwin profitwin #dealloss profitloss comm  #Adeal Aprofit #Adealwin Aprofitwin #Adealloss Aprofitloss Acomm\n";
        return str;
    }

    string formatstrcsv()
    {
        string str = StringFormat("%s %s %6d %5.2f %6d %5.2f %6d %5.2f %5.2f %6d %5.2f %6d %5.2f %6d %5.2f %5.2f",
                                  TimeToString(dtstart, TIME_SECONDS),
                                  TimeToString(dtend, TIME_SECONDS),
                                  deal_cnt,
                                  deal_profit,
                                  deal_cnt_win,
                                  deal_profit_win,
                                  deal_cnt_loss,
                                  deal_profit_loss,
                                  commission,
                                  Adeal_cnt,
                                  Adeal_profit,
                                  Adeal_cnt_win,
                                  Adeal_profit_win,
                                  Adeal_cnt_loss,
                                  Adeal_profit_loss,
                                  Acommission);
        return (str);
    }

}; // struct sDataHist

//+------------------------------------------------------------------+
//|   m_LogHistoryDeals
//+------------------------------------------------------------------+
bool m_LogHistoryDeals(sDataHist &a_hist)
{
    //
    // Get total deals in history
    //

    //
    //  TODO not working in tester mode:
    //  DEAL_TIME_MSC is always 0
    //

    if (false == HistorySelect(a_hist.dtstart, a_hist.dtend))
    {
        printf("DEBUG ERROR HISTORY SELECT2 ( %s %s %s ) [%s]", a_hist.symbol, TimeToString(a_hist.dtstart), TimeToString(a_hist.dtend), GetLastError());
        return false;
    }

    int total = HistoryDealsTotal();

    for (int j = 0; j < total; j++)
    {
        ulong d_ticket = HistoryDealGetTicket(j);
        if (d_ticket > 0)
        {

            // calc here for ALL symbols the total together
            a_hist.Acommission += HistoryDealGetDouble(d_ticket, DEAL_COMMISSION);
            ENUM_DEAL_ENTRY Adentry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(d_ticket, DEAL_ENTRY);
            if (DEAL_ENTRY_INOUT == Adentry || DEAL_ENTRY_OUT == Adentry || DEAL_ENTRY_INOUT == Adentry)
            {
                a_hist.Adeal_cnt++;
                double profit = HistoryDealGetDouble(d_ticket, DEAL_PROFIT);
                a_hist.Adeal_profit += profit;
                if (0.0 < profit)
                {
                    a_hist.Adeal_cnt_win++;
                    a_hist.Adeal_profit_win += profit;
                }
                else
                {
                    a_hist.Adeal_cnt_loss++;
                    a_hist.Adeal_profit_loss += profit;
                }

            } // if( DEAL_ENTRY_INOUT == Adentry || DEAL_ENTRY_OUT == Adentry || DEAL_ENTRY_INOUT == Adentry )

            if (a_hist.symbol != "ALL")
            {
                if (a_hist.symbol != HistoryDealGetString(d_ticket, DEAL_SYMBOL))
                {
                    continue;
                }
            }

            // calc here for a_symbol only
            a_hist.commission += HistoryDealGetDouble(d_ticket, DEAL_COMMISSION);
            ENUM_DEAL_ENTRY dentry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(d_ticket, DEAL_ENTRY);
            if (DEAL_ENTRY_INOUT == dentry || DEAL_ENTRY_OUT == dentry || DEAL_ENTRY_INOUT == dentry)
            {
                a_hist.deal_cnt++;
                double profit = HistoryDealGetDouble(d_ticket, DEAL_PROFIT);
                a_hist.deal_profit += profit;
                if (0.0 < profit)
                {
                    a_hist.deal_cnt_win++;
                    a_hist.deal_profit_win += profit;
                }
                else
                {
                    a_hist.deal_cnt_loss++;
                    a_hist.deal_profit_loss += profit;
                }

            } // if( DEAL_ENTRY_INOUT == dentry || DEAL_ENTRY_OUT == dentry || DEAL_ENTRY_INOUT == dentry )

            if (0 < Debug)
            {

                string str = StringFormat("%s(%s-%s #%d %s %15s %15s %6.2f %d)",
                                          HistoryDealGetString(d_ticket, DEAL_SYMBOL),
                                          TimeToString(a_hist.dtstart, TIME_SECONDS),
                                          TimeToString(a_hist.dtend, TIME_SECONDS),
                                          d_ticket,
                                          TimeToString(HistoryDealGetInteger(d_ticket, DEAL_TIME), TIME_DATE | TIME_SECONDS),
                                          EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(d_ticket, DEAL_TYPE)),
                                          EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d_ticket, DEAL_ENTRY)),
                                          HistoryDealGetDouble(d_ticket, DEAL_PROFIT)
                                          /*HistoryDealGetInteger(d_ticket,DEAL_TIME_MSC),
                                          HistoryDealGetInteger(d_ticket,DEAL_TIME),
                                          HistoryDealGetInteger(d_ticket,DEAL_ORDER),
                                          EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(d_ticket,DEAL_TYPE)),
                                          EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d_ticket,DEAL_ENTRY)),
                                          HistoryDealGetDouble(d_ticket,DEAL_VOLUME),
                                          HistoryDealGetDouble(d_ticket,DEAL_PRICE),
                                          HistoryDealGetDouble(d_ticket,DEAL_PROFIT),
                                          HistoryDealGetString(d_ticket,DEAL_COMMENT),
                                          HistoryDealGetDouble(d_ticket,DEAL_COMMISSION),
                                          HistoryDealGetDouble(d_ticket,DEAL_SWAP),
                                          HistoryDealGetInteger(d_ticket,DEAL_MAGIC),
                                          HistoryDealGetInteger(d_ticket,DEAL_POSITION_ID)*/
                );
                Print(str);
            } // if( true == a_log )
        } // if (d_ticket>0)
    } // for (int j=0; j<tot_deals; j++)

    return true;

} // bool m_LogHistoryDeals(const string &a_symbol, const datetime &a_start, const datetime &a_end, bool a_log = true)
//+------------------------------------------------------------------+
