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
#include <myobjects.mqh>

#define COLOR_BLACK clrBlack
#define COLOR_BORDER clrRed
#define COLOR_BLUE clrDodgerBlue
#define COLOR_TEXT clrLightGray
#define COLOR_GREEN clrLimeGreen
#define COLOR_RED clrOrangeRed
#define COLOR_YELLOW clrYellow

// I N C L U D E S

// T Y P E D E F S
enum ENUM_PERIOD_TYPE {
    ENUM_PERIOD_TYPE_NONE,
    ENUM_PERIOD_TYPE_SECONDS_S,
    ENUM_PERIOD_TYPE_TICKS_T,
    ENUM_PERIOD_TYPE_AVERAGE_S,
    ENUM_PERIOD_TYPE_AVERAGE_T,
    ENUM_PERIOD_TYPE_AVERAGE_SUM,
    ENUM_PERIOD_TYPE_MAX
};

// I N P U T S
input int Debug = 0; // enable debug output
input string PERIODS = "T60:T300:T900:T3600:T_AVG:S60:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds

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
    int OC_HL;
    int VOLS_TD;
    int HL_TD;
    int SUMCOL;

    datetime t0;
    datetime t1;
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


//sDataVars sData[9];
sDataVars sData[];
int sDataSize;


string symbolName;
string symbolNameAppendix = "_ticks";
uint tickCount;

MqlRates rates[];

uint gCopyTicksFlags = COPY_TICKS_ALL; // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL

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
void ExtractHighLowFromMqlTickArray(const MqlTick &mqltickarray[], int &OC, int &HL)
{
    double high = 0;
    double low = 1000000000;
    int size = ArraySize(mqltickarray);

    HL = 0;
    OC = 0;

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

    } // for( cnt = 0; cnt < size; cnt++ )

    HL = (int)((high - low) / _Point);

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
    tickCount = 0;

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
    
    string s_sep=":";              // A separator as a character
    ushort u_sep;                  // The code of the separator character
    string str_period_split[];     // An array to get strings
    u_sep=StringGetCharacter(s_sep,0);//--- Get the separator code
    int num_sep=StringSplit(PERIODS,u_sep,str_period_split); //--- Split the string to substrings
    if ( 1 > num_sep )
    {
        Print(" PERIODS stringsplit failed ", PERIODS);
        return (INIT_FAILED);
    }
    
    ArrayFree( sData );
    ArrayResize( sData, num_sep );
    sDataSize = ArraySize(sData);    
    
    for( int cnt = 0; cnt < num_sep; cnt++ )
    {
        if( false == GetPeriodFromKeyAndInitDataVarsStruct(str_period_split[cnt], sData[cnt] ) )
        {
            Print(" GetPeriodFromKeyAndInitDataVarsStruct failed ", str_period_split[cnt] );
            return (INIT_FAILED);
        }
        
    } // for( int cnt = 0; cnt < num_sep; cnt++ )

    //ArrayPrint( sData );

    EventSetTimer(1);

    return INIT_SUCCEEDED;

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // int _OnInit(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _OnTimer()
{
   
    string str;
    datetime tc = TimeCurrent();
    
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
            //--- display the last tick time up to milliseconds
            str = StringFormat("    -  Last tick [ %s / %s / %s ] was at %s.%03d with spread [ %4d ]",
                               DoubleToString(t.ask, _Digits),
                               DoubleToString(last_price, _Digits),
                               DoubleToString(t.bid, _Digits),
                               TimeToString(t.time, TIME_SECONDS),
                               t.time_msc % 1000,
                               (int)last_spread);
            if (0 < Debug)
                Print(str);
        }
    } // if (!SymbolInfoTick(Symbol(), t))


    for( int cnt = 0; cnt < sDataSize; cnt++ )
    {

        if (ENUM_PERIOD_TYPE_AVERAGE_SUM == sData[cnt].periodType)
            continue;
        if (ENUM_PERIOD_TYPE_AVERAGE_S   == sData[cnt].periodType)
            continue;
        if (ENUM_PERIOD_TYPE_AVERAGE_T   == sData[cnt].periodType)
            continue;
        
        MqlTick array[];
        int size1 = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (tc - sData[cnt].periodNum) * 1000, (tc - 0) * 1000);
        int oc1 = 0;
        int hl1 = 0;
        ExtractHighLowFromMqlTickArray(array, oc1, hl1);
        sData[cnt].HL = hl1;
        sData[cnt].OC = oc1;
        sData[cnt].VOLS = size1;
        sData[cnt].SPREAD = (int)last_spread;
        sData[cnt].c0 = last_price;
        sData[cnt].t0 = tc;
    
        
    } // for( int cnt = 0; cnt < sDataSize; cnt++ )
    
    //ArrayPrint( sData );


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

    string delta_ms_since_last_tick_str = "n/a";
    if (0 < tickCount)
        delta_ms_since_last_tick_str = IntegerToString(GetTickCount() - tickCount);
    string tickv_str = StringFormat("c0: %s s: %2d d: %4s",
                                    // TODO FixMe - here the T60 c0 shall go
                                    DoubleToString(sData[0].c0, Digits()),
                                    (int)last_spread,
                                    delta_ms_since_last_tick_str);
    tickCount = 0;
    comment.SetText(_comment_txt_line_start, tickv_str, COLOR_TEXT);

    //
    // comment output tick speed
    //
    _comment_txt_line_start++;

    double tick_threshold = 1.0;
    if ("GBPJPY" == _Symbol || "NZDUSD" == _Symbol)
        tick_threshold = 2.0;
    double tick_avg = 1;
    double tick_avg_low = 2;
    double tick_avg_high = 3;

    tickv_str = StringFormat(" %4d/min :  %0.1f/ %0.1f/ %0.1f ",
                             // TODO FixMe - here the T60 VOLS shall go
                             sData[0].VOLS,
                             tick_avg,
                             tick_avg_low,
                             tick_avg_high);

    if (tick_threshold < tick_avg_low && tick_threshold < tick_avg_high)
    {
        comment.SetText(_comment_txt_line_start, tickv_str, COLOR_GREEN);
    }
    else
    {
        comment.SetText(_comment_txt_line_start, tickv_str, COLOR_TEXT);
    }

    //
    // comment output HL
    //
    _comment_txt_line_start++;
    double hl_threshold = 10;
    double hl_avg = 4;
    double hl_avg_low = 5;
    double hl_avg_high = 6;

    string hl_str = StringFormat(" %4d  HL : %4d/%4d/%4d",
                                 // TODO FixMe - here the T60 HL shall go
                                 sData[0].HL,
                                 (int)hl_avg,
                                 (int)hl_avg_low,
                                 (int)hl_avg_high);

    if (hl_threshold < hl_avg_low && hl_threshold < hl_avg_high)
    {
        comment.SetText(_comment_txt_line_start, hl_str, COLOR_GREEN);
    }
    else
    {
        comment.SetText(_comment_txt_line_start, hl_str, COLOR_TEXT);
    }

    //
    // comment output OC
    //
    _comment_txt_line_start++;
    double oc_threshold = 10;
    double oc_avg = 7;
    double oc_avg_low = 8;
    double oc_avg_high = 9;

    string oc_str = StringFormat(" %4d  OC : %4d/%4d/%4d",
                                 // TODO FixMe - here the T60 OC shall go
                                 sData[0].OC,
                                 (int)oc_avg,
                                 (int)oc_avg_low,
                                 (int)oc_avg_high);

    if (+1 * oc_threshold < oc_avg_low && +1 * oc_threshold < oc_avg_high)
    {
        comment.SetText(_comment_txt_line_start, oc_str, COLOR_BLUE);
    }
    else if (-1 * oc_threshold > oc_avg_low && -1 * oc_threshold > oc_avg_high)
    {
        comment.SetText(_comment_txt_line_start, oc_str, COLOR_RED);
    }
    else
    {
        comment.SetText(_comment_txt_line_start, oc_str, COLOR_TEXT);
    }

    //
    // comment output MA
    //
    _comment_txt_line_start++;

    int _sum_avg_threshold = 0;
    string _ma_str = "";

    for (int cnt = 0; sDataSize > cnt; cnt++)
    {
        _ma_str = StringFormat("  %7s : %4d/%4d/%4d",
                               sData[cnt].periodKey,
                               sData[cnt].OC,
                               sData[cnt].HL,
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

#ifdef MAMBO_JUMBO
    int _color = clrWhite;
    int _colorLine = clrWhite;
    datetime _width_factor = 1;
    datetime time0 = iTime(_Symbol, _Period, 0);
    datetime time1 = time0 - 1 * PeriodSeconds();
    datetime time4 = time0 - 4 * PeriodSeconds();
    datetime time5 = time0 - 5 * PeriodSeconds();
    datetime timep = time0 + 3 * PeriodSeconds();
    if (PositionSelect(_Symbol))
    {
        /*double pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        double pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        long pos_open_time = PositionGetInteger(POSITION_TIME);
        long pos_open_price_delta = 0;
        ENUM_POSITION_TYPE pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);*/
        if (POSITION_TYPE_BUY == pos_open_type)
        {
            pos_open_price_delta = (long)((pos_open_price_last - pos_open_price) / _Point);
            _color = clrBlue;
            _colorLine = clrBlue;
            if (0 > pos_open_price_delta)
                _color = clrYellow;
        }

        if (POSITION_TYPE_SELL == pos_open_type)
        {
            pos_open_price_delta = (long)((pos_open_price - pos_open_price_last) / _Point);
            _color = clrRed;
            _colorLine = clrRed;
            if (0 > pos_open_price_delta)
                _color = clrYellow;
        }

        SetTline(0, "OP_tline", 0, pos_open_time, pos_open_price, timep, pos_open_price, _colorLine, STYLE_SOLID, 3, "OP_tline");
        SetRightPrice(0, "OP_price", 0, timep, pos_open_price, _colorLine, "Georgia");
        SetRectangle(0, "OP_rect", 0, time1, pos_open_price, time0, pos_open_price_last, _color, STYLE_SOLID, 1, "OpenPrice");

        if (0 == ObjectFind(0, "OC_tline"))
            ObjectDelete(0, "OC_tline");
        if (0 == ObjectFind(0, "OC_price"))
            ObjectDelete(0, "OC_price");
        if (0 == ObjectFind(0, "OC_rect"))
            ObjectDelete(0, "OC_rect");
    }
    else
    {
        if (0 == ObjectFind(0, "OP_tline"))
            ObjectDelete(0, "OP_tline");
        if (0 == ObjectFind(0, "OP_price"))
            ObjectDelete(0, "OP_price");
        if (0 == ObjectFind(0, "OP_rect"))
            ObjectDelete(0, "OP_rect");

        if (10 < oc60)
        {
            _color = clrBlue;
            _colorLine = clrBlue;
        }
        if (-10 > oc60)
        {
            _color = clrRed;
            _colorLine = clrRed;
        }
        double o0 = iOpen(_Symbol, _Period, 0);
        double oc = o0 /*last_price -*/ + oc60 * _Point;
        SetTline(0, "OC_tline", 0, time1, oc, timep, oc, _colorLine, STYLE_SOLID, 3, "OP_tline");
        SetRightPrice(0, "OC_price", 0, timep, oc, _colorLine, "Georgia");
        SetRectangle(0, "OC_rect", 0, time1, oc, time0, o0, _color, STYLE_SOLID, 1, "OpenPrice");

    } // if(PositionSelect(_Symbol))

    SetTline(0, "PRICE_tline", 0, time1, last_price, timep, last_price, clrSpringGreen, STYLE_SOLID, 3, "PRICE_tline");
    SetRightPrice(0, "PRICE_price", 0, timep, last_price, clrSpringGreen, "Georgia");
#endif

    // EventKillTimer();

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

    tickCount = GetTickCount();

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
