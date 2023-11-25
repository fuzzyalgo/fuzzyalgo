//+------------------------------------------------------------------+
//|                                                   Ticks2Bars.mq5 |
//|                               Copyright (c) 2018-2019, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                        https://www.mql5.com/en/blogs/post/719145 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018-2019, Marketeer"
#property link      "https://www.mql5.com/en/users/marketeer"
#property version   "1.0"
#property description "Ticks2Bars\n"
#property description "Non-trading expert, generating bar chart from ticks - 1 bar per 1 tick."

#include <comment.mqh>
#include <myobjects.mqh>


#define COLOR_BLACK     clrBlack
#define COLOR_BORDER    clrRed
#define COLOR_BLUE      clrDodgerBlue
#define COLOR_TEXT      clrLightGray
#define COLOR_GREEN     clrLimeGreen
#define COLOR_RED       clrOrangeRed
#define COLOR_YELLOW    clrYellow

/*
https://www.mql5.com/en/blogs/post/719145
https://www.mql5.com/en/blogs/post/718632
https://www.mql5.com/en/blogs/post/718430
https://www.mql5.com/en/blogs/post/748035
*/


// I N C L U D E S


// T Y P E D E F S

enum BAR_RENDER_MODE
{
    OHLC,
    HighLow
};


// I N P U T S
input uint TimeDelta = 60;
input int Limit = 32000;
input bool Reset = true;
input bool LoopBack = false;
input bool EmulateTicks = true;
input BAR_RENDER_MODE RenderBars = OHLC;

input uint nS1 = 4;
input uint nS2 = 8;
input uint nS3 = 16;
input uint nS4 = 32;
input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;
input ENUM_MA_METHOD     ma_method     = MODE_SMA;


// G L O B A L S

CComment comment;
CComment comment2;

struct sMAvars
{

    string periodKey;

    int hS1;
    int hS2;
    int hS3;
    int hS4;

    uint nS1;
    uint nS2;
    uint nS3;
    uint nS4;

    datetime t0;
    double c0;
    double ma1;
    double ma2;
    double ma3;
    double ma4;

    int mad1;
    int mad2;
    int mad3;
    int mad4;
    int mad_avg;

    int c0d1;
    int c0d2;
    int c0d3;
    int c0d4;
    int c0d_avg;

    int sum_avg;

    string str_txt;

}; // struct sMAvars

sMAvars sMa[9];

string symbolName;
string symbolNameAppendix = "_ticks";
bool firstRun;
bool stopAll;
bool justCreated;
datetime lastTime;
uint tickCount;

MqlRates rates[];

uint gCopyTicksFlags = COPY_TICKS_INFO; // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL


// E V E N T   H A N D L E R S IMPLEMENTATION


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(void)
{

    return(  _OnInit() ) ;

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

    _OnDeinit( reason );

} // void OnDeinit(const int reason)
//+------------------------------------------------------------------+





// A P P L I C A T I O N

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExtractHighLowFromMqlTickArray( const MqlTick& mqltickarray[], int& OC, int& HL)
{
    double high = 0;
    double low  = 1000000000;
    int size = ArraySize( mqltickarray );

    HL = 0;
    OC = 0;

    if( 0 < size )
    {
        MqlTick t0 = mqltickarray[size - 1];
        if(t0.ask == 0 || t0.bid == 0 || t0.ask < t0.bid)
            return;
        MqlTick tstart = mqltickarray[0];
        if(tstart.ask == 0 || tstart.bid == 0 || tstart.ask < tstart.bid)
            return;
        OC = (int)(( ((t0.ask + t0.bid) / 2 ) - ((tstart.ask + tstart.bid) / 2 ) ) / _Point);
    }
    else
    {
        return;
    }

    for( int cnt = 0; cnt < size; cnt++ )
    {
        MqlTick t = mqltickarray[cnt];
        // sanity check
        if(t.ask == 0 || t.bid == 0 || t.ask < t.bid)
            continue;
        if( high < t.ask )
            high = t.ask;
        if( low  > t.bid )
            low  = t.bid;

    } // for( cnt = 0; cnt < size; cnt++ )

    HL = (int)(( high - low ) / _Point);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void ExtractHighLowFromMqlTickArray( const MqlTick& mqltickarray[], int& OC, int& HL)
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void reset()
{
    ResetLastError();
    int deleted = CustomRatesDelete(symbolName, 0, LONG_MAX);
    int err = GetLastError();
    if(err != ERR_SUCCESS)
    {
        Alert("CustomRatesDelete failed, ", err);
        stopAll = true;
        return;
    }
    else
    {
        Print("Rates deleted: ", deleted);
    }

    ResetLastError();
    deleted = CustomTicksDelete(symbolName, 0, LONG_MAX);
    if(deleted == -1)
    {
        Print("CustomTicksDelete failed ", GetLastError());
        stopAll = true;
        return;
    }
    else
    {
        Print("Ticks deleted: ", deleted);
    }

// wait for changes to take effect in background (asynchronously)
    int size;
    do
    {
        Sleep(100);

        MqlTick array[];
        size = CopyTicks(symbolName, array, gCopyTicksFlags, 0, Limit);
        Print("Remaining ticks: ", size);
    }
    while(size > 0);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void reset()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool apply(const datetime cursor, const MqlTick &t, MqlRates &r)
{
    static MqlTick p;

// eliminate strange things
    if(t.ask == 0 || t.bid == 0 || t.ask < t.bid)
        return false;

    r.high = t.ask;
    r.low = t.bid;

    if(t.last != 0)
    {
        if(RenderBars == OHLC)
        {
            if(t.last > p.last)
            {
                r.open = r.low;
                r.close = r.high;
            }
            else
            {
                r.open = r.high;
                r.close = r.low;
            }
        }
        else
        {
            r.open = r.close = (r.high + r.low) / 2;
        }

        if(t.last < t.bid)
            r.low = t.last;
        if(t.last > t.ask)
            r.high = t.last;
        r.close = t.last;
    }
    else
    {
        if(RenderBars == OHLC)
        {
            if((t.ask + t.bid) / 2 > (p.ask + p.bid) / 2)
            {
                r.open = r.low;
                r.close = r.high;
            }
            else
            {
                r.open = r.high;
                r.close = r.low;
            }
        }
        else
        {
            r.open = r.close = (r.high + r.low) / 2;
        }
    }

    r.time = cursor;
    r.spread = (int)((t.ask - t.bid) / _Point);
    r.tick_volume = 1;
    r.real_volume = (long)t.volume;

    p = t;
    return true;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // bool apply(const datetime cursor, const MqlTick &t, MqlRates &r)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fillArray()
{
    MqlTick array[];
    int size = CopyTicks(_Symbol, array, gCopyTicksFlags, 0, Limit);
    if(size == -1)
    {
        Print("CopyTicks failed: ", GetLastError());
        stopAll = true;
    }
    else
    {
        Print("Ticks start at ", array[0].time, "'", array[0].time_msc % 1000);
        MqlRates r[];
        ArrayResize(r, size);
        datetime start = (datetime)(((long)TimeCurrent() / 60 * 60) - (size - 1) * 60);
        datetime cursor = start;
        int j = 0;
        for(int i = 0; i < size; i++)
        {
            if(apply(cursor, array[i], r[j]))
            {
                cursor += TimeDelta;
                j++;
            }
        }
        if(j < size)
        {
            Print("Shrinking to ", j);
            ArrayResize(r, j);
        }
        if(CustomRatesUpdate(symbolName, r) == 0)
        {
            Print("CustomRatesUpdate failed: ", GetLastError());
            stopAll = true;
        }
    }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void fillArray()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void shift()
{
    ResetLastError();
    int length = CopyRates(symbolName, PERIOD_M1, 0, Limit, rates);
    if(length <= 0)
    {
        Print("CopyRates failed: ", GetLastError(), " length: ", length);
        stopAll = true;
    }
    else
    {
        for(int i = 0; i < length; i++)
        {
            rates[i].time -= TimeDelta;
        }


        if(CustomRatesDelete(symbolName, 0, rates[0].time - TimeDelta) == -1)
        {
            Print("Not deleted: ", GetLastError());
        }

        if(CustomRatesUpdate(symbolName, rates) == -1)
        {
            Print("Not shifted: ", symbolName, " ", length, " error: ", GetLastError());
            stopAll = true;
        }
    }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void shift()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void add(datetime time = 0)
{
    MqlTick t;
    if(SymbolInfoTick(_Symbol, t))
    {
        if(time == 0)
            time = (datetime)((long)TimeCurrent() / 60 * 60);

        t.time = time;
        t.time_msc = time * 1000;

        MqlRates r[1];
        if(apply(time, t, r[0]))
        {
            if(EmulateTicks)
            {
                MqlTick ta[1];
                ta[0] = t;
                ta[0].time += TimeDelta; // forward tick (next temporary bar) to activate EA (if any)
                ta[0].time_msc = ta[0].time * 1000;
                ResetLastError();
                if(CustomTicksAdd(symbolName, ta) == -1)
                {
                    Print("Not ticked:", GetLastError(), " ", (long)ta[0].time);
                    ArrayPrint(ta);
                    stopAll = true;
                }
                // remove the temporary tick
                CustomTicksDelete(symbolName, ta[0].time_msc, LONG_MAX);
            }
            ResetLastError();
            if(CustomRatesUpdate(symbolName, r) == -1)
            {
                Print("Not updated: ", GetLastError());
                ArrayPrint(r);
                stopAll = true;
            }
        }
    }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void add(datetime time = 0)
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetSymbolNameAndPeriodFromKey( const string& periodKey, const string& symbol, string& _symbolName, ENUM_TIMEFRAMES& period )
{

    bool ret = false;

    if( "T1" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_M1;
        return true;
    }

    if( "T5" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_M5;
        return true;
    }

    if( "T15" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_M15;
        return true;
    }

    if( "T30" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_M30;
        return true;
    }

    if( "T60" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H1;
        return true;
    }

    if( "T120" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H2;
        return true;
    }

    if( "T180" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H3;
        return true;
    }

    if( "T240" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H4;
        return true;
    }

    if( "T360" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H6;
        return true;
    }

    if( "T480" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H8;
        return true;
    }

    if( "T720" == periodKey)
    {
        _symbolName = symbol + symbolNameAppendix;
        period = PERIOD_H12;
        return true;
    }

    if( "S60" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M1;
        return true;
    }

    if( "S120" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M2;
        return true;
    }

    if( "S180" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M3;
        return true;
    }

    if( "S240" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M4;
        return true;
    }

    if( "S300" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M5;
        return true;
    }

    if( "S600" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M10;
        return true;
    }

    if( "S900" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M15;
        return true;
    }

    if( "S1200" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M20;
        return true;
    }

    if( "S3600" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_H1;
        return true;
    }

    return false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // bool GetSymbolNameAndPeriodFromKey( const string& periodKey, const string& symbol, string _symbolName, ENUM_TIMEFRAMES period )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitMaVarsStruct( sMAvars &ma )
{

    ma.periodKey = "";

    ma.hS1 = INVALID_HANDLE;
    ma.hS2 = INVALID_HANDLE;
    ma.hS3 = INVALID_HANDLE;
    ma.hS4 = INVALID_HANDLE;

    ma.nS1 = nS1;
    ma.nS2 = nS2;
    ma.nS3 = nS3;
    ma.nS4 = nS4;

    ma.t0 = 0;
    ma.c0 = 0.0;
    ma.ma1 = 0.0;
    ma.ma2 = 0.0;
    ma.ma3 = 0.0;
    ma.ma4 = 0.0;

    ma.mad1 = 0;
    ma.mad2 = 0;
    ma.mad3 = 0;
    ma.mad4 = 0;
    ma.mad_avg = 0;

    ma.c0d1 = 0;
    ma.c0d2 = 0;
    ma.c0d3 = 0;
    ma.c0d4 = 0;
    ma.c0d_avg = 0;

    ma.sum_avg = 0;

    ma.str_txt = "";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void InitMaVarsStruct( sMAvars &ma )
//+------------------------------------------------------------------+



// E V E N T   H A N D L E R S IMPLEMENTATION

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int _OnInit(void)
{
    tickCount = 0;

    datetime t0 = iTime( _Symbol, PERIOD_H1, 0);
    MqlDateTime dt0;
    TimeToStruct( t0, dt0 );
    symbolNameAppendix = StringFormat( "_%02d%02d%02d", 
                                        dt0.mon,
                                        dt0.day,
                                        dt0.hour );
    symbolName = Symbol() + symbolNameAppendix;


//--- panel position
    int y = 30;
    //if(ChartGetInteger(0, CHART_SHOW_ONE_CLICK))
    //    y = 120;
    comment.Create("comment_panel_01", 20, y);
    comment2.Create("comment_panel_02", 20, 0);
//--- panel style
    bool InpAutoColors = false; //Auto Colors
    comment.SetAutoColors(InpAutoColors);
    comment.SetColor(COLOR_BORDER, COLOR_BLACK, 255);
    comment.SetFont("Lucida Console", 13, false, 1.7);

    comment2.SetAutoColors(InpAutoColors);
    comment2.SetColor(COLOR_YELLOW, COLOR_BLACK, 255);
    comment2.SetFont("Lucida Console", 12, false, 1.7);

    stopAll = false;
    justCreated = false;

    if(SymbolInfoInteger(_Symbol, SYMBOL_CUSTOM))
    {
        Alert("" + _Symbol + " is a custom symbol. Only built-in symbol can be used as a host.");
        return INIT_FAILED;
    }

    if(!SymbolSelect(symbolName, true))
    {
        ResetLastError();
        SymbolInfoInteger(symbolName, SYMBOL_CUSTOM);
        if(ERR_MARKET_UNKNOWN_SYMBOL == GetLastError())
        {
            Print( "create symbol: " + symbolName );
            CustomSymbolCreate( symbolName, _Symbol, _Symbol );
            justCreated = true;
        }

        if(!SymbolSelect(symbolName, true))
        {
            Alert("Can't select symbol:", symbolName, " err:", GetLastError());
            return INIT_FAILED;
        }
    }


    firstRun = true;

    // TODO ported here from OnTick
    // leave here if there are no problems with it
    if(firstRun)
    {
        if(!TerminalInfoInteger(TERMINAL_CONNECTED))
        {
            Print("Waiting for connection...");
            return(INIT_FAILED);
        }
        // NB! Since some MT5 build function SeriesInfoInteger(SERIES_SYNCHRONIZED) does not work properly anymore
        // and returns false always, so replaced with SymbolIsSynchronized
        // if(!SeriesInfoInteger(_Symbol, _Period, SERIES_SYNCHRONIZED))
        if(!SymbolIsSynchronized(_Symbol))
        {
            Print("Unsynchronized, skipping ticks...");
            return(INIT_FAILED);
        }

        if(Reset)
            reset();

        if(Limit > 0)
        {
            fillArray();
            Print("Buffer filled in for ", symbolName);
        }

        if(justCreated)
        {
            long id = ChartOpen(symbolName, PERIOD_M1);
            if(id == 0)
            {
                Print("Can't open new chart for ", symbolName, ", code: ", GetLastError());
                return(INIT_FAILED);
            }
            else
            {
                ChartSetSymbolPeriod(id, symbolName, PERIOD_H12);
                ChartSetInteger(id, CHART_MODE, CHART_CANDLES);
                Sleep(1000);
                string tmpl = TerminalInfoString(TERMINAL_DATA_PATH)+"\\Mql5\\Profiles\\Templates\\TicksTmpl.tpl";
                Print( tmpl );
                ChartApplyTemplate(id, tmpl);
                ChartRedraw(id);
            }
            justCreated = false;
        }

        firstRun = false;
        lastTime = (datetime)((long)TimeCurrent() / 60 * 60);

        //return;
    }


    //
    // init all ma structs with default values
    //
    sMAvars md;
    InitMaVarsStruct( md );
    int sMaSize = ArraySize(sMa);
    for( int cnt = 0; sMaSize > cnt; cnt++ )
    {
        sMa[cnt] = md;
    }
    /*
    sMa[0].periodKey = "T1";
    sMa[1].periodKey = "T5";
    sMa[2].periodKey = "T15";
    sMa[3].periodKey = "T60";
    sMa[4].periodKey = "S60";
    sMa[5].periodKey = "S300";
    sMa[6].periodKey = "S900";
    sMa[7].periodKey = "S3600";
    sMa[8].periodKey = "SUM_AVG";
    */
    /*
    sMa[0].periodKey = "S60";
    sMa[1].periodKey = "S120";
    sMa[2].periodKey = "S180";
    sMa[3].periodKey = "S240";
    sMa[4].periodKey = "S300";
    sMa[5].periodKey = "S600";
    sMa[6].periodKey = "S900";
    sMa[7].periodKey = "S1200";
    sMa[8].periodKey = "SUM_AVG";
    */
    /*
    sMa[0].periodKey = "S60";
    sMa[1].periodKey = "T1";
    sMa[2].periodKey = "T5";
    sMa[3].periodKey = "T15";
    sMa[4].periodKey = "T60";
    sMa[5].periodKey = "T120";
    sMa[6].periodKey = "T480";
    sMa[7].periodKey = "T720";
    sMa[8].periodKey = "SUM_AVG";
    */

    sMa[0].periodKey = "T1";
    sMa[1].periodKey = "T5";
    sMa[2].periodKey = "T15";
    sMa[3].periodKey = "T60";
    sMa[4].periodKey = "S60";
    sMa[5].periodKey = "S120";
    sMa[6].periodKey = "S180";
    sMa[7].periodKey = "S240";
    sMa[8].periodKey = "SUM_AVG";


    //
    // open all the iMa handles
    //
    for( int cnt = 0; sMaSize > cnt; cnt++ )
    {

        if( "SUM_AVG" == sMa[cnt].periodKey )
            continue;

        string _symbolName = "";
        ENUM_TIMEFRAMES period = 0;
        if( false == GetSymbolNameAndPeriodFromKey(sMa[cnt].periodKey, _Symbol, _symbolName, period) )
        {
            Print(" GetSymbolNameAndPeriodFromKey failed ", _symbolName, " ", sMa[cnt].periodKey );
            return(INIT_FAILED);
        }

        sMa[cnt].hS1 = iMA( _symbolName, period, sMa[cnt].nS1, 0, ma_method, applied_price );
        //hS1=iCustom(Symbol(),Period(),"GRFLsqFit",nS1,nS2,nS3,nS4);
        //Ind_Handle_S1_M1_Ticks=iCustom(Symbol()/*+symbolNameAppendix*/,PERIOD_M1,"GRFLsqFit",nS1,nS2,nS3,nS4);
        if(sMa[cnt].hS1 == INVALID_HANDLE)
        {
            Print(" iMA hS1 init failed ", _symbolName, " ", sMa[cnt].periodKey );
            return(INIT_FAILED);
        }

        sMa[cnt].hS2 = iMA( _symbolName, period, sMa[cnt].nS2, 0, ma_method, applied_price );
        if(sMa[cnt].hS2 == INVALID_HANDLE)
        {
            Print(" iMA hS2 init failed ", _symbolName, " ", sMa[cnt].periodKey );
            return(INIT_FAILED);
        }

        sMa[cnt].hS3 = iMA( _symbolName, period, sMa[cnt].nS3, 0, ma_method, applied_price );
        if(sMa[cnt].hS3 == INVALID_HANDLE)
        {
            Print(" iMA hS3 init failed ", _symbolName, " ", sMa[cnt].periodKey );
            return(INIT_FAILED);
        }

        sMa[cnt].hS4 = iMA( _symbolName, period, sMa[cnt].nS4, 0, ma_method, applied_price );
        if(sMa[cnt].hS4 == INVALID_HANDLE)
        {
            Print(" iMA hS4 init failed ", _symbolName, " ", sMa[cnt].periodKey );
            return(INIT_FAILED);
        }

    } // for( int cnt = 0; sMaSize>cnt; cnt++ )

    //ArrayPrint( sMa );

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

    ulong position_ID = 0;
    long pos_open_time = 0;
    long create_time_delta = 0;

    double last_price = 0;
    double last_spread = 0;
    ulong  pos_open_time_delta = 0;
    long   pos_open_price_delta = 0;
    double pos_open_price = 0;
    double pos_open_price_last = 0;
    double pos_open_profit = 0;
    double pos_open_vol = 0;
    ENUM_POSITION_TYPE pos_open_type = 0;
    
    

    int size = 0;
    MqlTick array[];
    int size1    = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 1   ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc1   = 0;
    int hl1   = 0;
    ExtractHighLowFromMqlTickArray( array, oc1, hl1 );

    int size2    = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 2   ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc2   = 0;
    int hl2   = 0;
    ExtractHighLowFromMqlTickArray( array, oc2, hl2 );

    int size5    = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 5   ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc5   = 0;
    int hl5   = 0;
    ExtractHighLowFromMqlTickArray( array, oc5, hl5 );

    int size15   = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 15  ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc15   = 0;
    int hl15   = 0;
    ExtractHighLowFromMqlTickArray( array, oc15, hl15 );

    int size60   = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 60  ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc60   = 0;
    int hl60   = 0;
    ExtractHighLowFromMqlTickArray( array, oc60, hl60 );

    int size300  = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 120 ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc300  = 0;
    int hl300  = 0;
    ExtractHighLowFromMqlTickArray( array, oc300, hl300 );

    int size900  = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 180 ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc900   = 0;
    int hl900   = 0;
    ExtractHighLowFromMqlTickArray( array, oc900, hl900 );

    int size3600 = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - 240 ) * 1000, (TimeCurrent() - 0) * 1000 );
    int oc3600   = 0;
    int hl3600   = 0;
    ExtractHighLowFromMqlTickArray( array, oc3600, hl3600 );


    string _t_str = StringFormat( " tc: %s %4d %4d %4d %4d %4d %4d %6d %6d", TimeToString(TimeCurrent(), TIME_SECONDS),
                                  size1, size2, size5, size15, size60, size300, size900, size3600 );
    //Print( _t_str );


    string _oc_str = StringFormat( " oc: %s %4d %4d %4d %4d %4d %4d %6d %6d", TimeToString(TimeCurrent(), TIME_SECONDS),
                                   oc1, oc2, oc5, oc15, oc60, oc300, oc900, oc3600 );
    //Print( _oc_str );

    string _hl_str = StringFormat( " hl: %s %4d %4d %4d %4d %4d %4d %6d %6d", TimeToString(TimeCurrent(), TIME_SECONDS),
                                   hl1, hl2, hl5, hl15, hl60, hl300, hl900, hl3600 );
    //Print( _hl_str );

    double tick_avg = (((double)size1 / 1) +     ((double)size2 / 2) +
                       (double)(size5 / 5) +     ((double)size15 / 15) +
                       ((double)size60 / 60) +   ((double)size300 / 300) +
                       ((double)size900 / 900) + ((double)size3600 / 3600) ) / 8;
    double tick_avg_low = (((double)size1 / 1) +     ((double)size2 / 2) +
                           (double)(size5 / 5) +     ((double)size15 / 15)  ) / 4;
    double tick_avg_high = (((double)size60 / 60) +   ((double)size300 / 300) +
                            ((double)size900 / 900) + ((double)size3600 / 3600) ) / 4;
    string str = StringFormat( " t: %s %s  avg:  %0.1f/ %0.1f/ %0.1f  %4d/1 %4d/2 %4d/5 %4d/15 %6d/60 %6d/300 %6d/900 %6d/3600",
                               TimeToString(TimeCurrent(), TIME_SECONDS),
                               _Symbol,
                               tick_avg,
                               tick_avg_low,
                               tick_avg_high,
                               size1, size2, size5, size15, size60, size300, size900, size3600 );
    //Print( str );

    double oc_avg = (((double)oc1) +     ((double)oc2) +
                     (double)(oc5) +     ((double)oc15) +
                     ((double)oc60) +   ((double)oc300) +
                     ((double)oc900) + ((double)oc3600) ) / 8;
    double oc_avg_low = (((double)oc1) +     ((double)oc2) +
                         (double)(oc5) +     ((double)oc15)  ) / 4;
    double oc_avg_high = (((double)oc60) +   ((double)oc300) +
                          ((double)oc900) + ((double)oc3600) ) / 4;
    str = StringFormat( " t: %s %s  avg: %4d/%4d/%4d  %4d %4d %4d %4d %6d %6d %6d %6d",
                        TimeToString(TimeCurrent(), TIME_SECONDS),
                        _Symbol,
                        (int)oc_avg,
                        (int)oc_avg_low,
                        (int)oc_avg_high,
                        oc1, oc2, oc5, oc15, oc60, oc300, oc900, oc3600 );
    //Print( str );

    double hl_avg = (((double)hl1) +     ((double)hl2) +
                     (double)(hl5) +     ((double)hl15) +
                     ((double)hl60) +   ((double)hl300) +
                     ((double)hl900) + ((double)hl3600) ) / 8;
    double hl_avg_low = (((double)hl1) +     ((double)hl2) +
                         (double)(hl5) +     ((double)hl15)  ) / 4;
    double hl_avg_high = (((double)hl60) +   ((double)hl300) +
                          ((double)hl900) + ((double)hl3600) ) / 4;
    str = StringFormat( " t: %s %s  avg: %4d/%4d/%4d  %4d %4d %4d %4d %6d %6d %6d %6d",
                        TimeToString(TimeCurrent(), TIME_SECONDS),
                        _Symbol,
                        (int)hl_avg,
                        (int)hl_avg_low,
                        (int)hl_avg_high,
                        hl1, hl2, hl5, hl15, hl60, hl300, hl900, hl3600 );
    //Print( str );


    double acc_bal = AccountInfoDouble(ACCOUNT_BALANCE);
    double acc_cre = AccountInfoDouble(ACCOUNT_CREDIT);
    double acc_pro = AccountInfoDouble(ACCOUNT_PROFIT);
    double acc_equ = AccountInfoDouble(ACCOUNT_EQUITY);
    double acc_mrg = AccountInfoDouble(ACCOUNT_MARGIN);
    double acc_mrg_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double acc_mrg_lvl = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    double acc_mrg_so_call = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
    double acc_mrg_so_so = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);

    str += StringFormat( "   ACCOUNT: %s / %s / %s - MARGIN free: %s ",
                         DoubleToString(acc_equ, 2),
                         DoubleToString(acc_bal, 2),
                         DoubleToString(acc_pro, 2),
                         DoubleToString(acc_mrg_free, 2) );
    //Print( str );


    //--- get data on the last tick
    MqlTick t;
    if(!SymbolInfoTick(Symbol(), t))
    {
        Print("SymbolInfoTick() failed, error = ", GetLastError());
    }
    else
    {
        // eliminate strange things
        if(t.ask == 0 || t.bid == 0 || t.ask < t.bid)
        {
            Print("SymbolInfoTick() Ticks error");
        }
        else
        {
            last_spread = (t.ask - t.bid) / _Point;
            last_price = (t.ask + t.bid) / 2;
            //--- display the last tick time up to milliseconds
            str += StringFormat("    -  Last tick [ %s / %s / %s ] was at %s.%03d with spread [ %4d ]",
                                DoubleToString(t.ask, _Digits),
                                DoubleToString(last_price, _Digits),
                                DoubleToString(t.bid, _Digits),
                                TimeToString(t.time, TIME_SECONDS),
                                t.time_msc % 1000,
                                (int)last_spread );
            //Print( str );
        }
    }


    str = StringFormat(" t: %s  no open position", TimeToString(TimeCurrent(), TIME_SECONDS ) );

    string sBS = "";
    //--- check if a position is present and display the time of its changing
    if(PositionSelect(_Symbol))
    {


        //--- receive position ID for further work
        position_ID = PositionGetInteger(POSITION_IDENTIFIER);
        //--- receive the time of position forming in milliseconds since 01.01.1970
        pos_open_time = PositionGetInteger(POSITION_TIME);
        create_time_delta = TimeCurrent() - pos_open_time;

        pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        pos_open_profit =  PositionGetDouble(POSITION_PROFIT);
        pos_open_vol =  PositionGetDouble(POSITION_VOLUME);

        pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if( POSITION_TYPE_BUY == pos_open_type )
        {
            pos_open_price_delta = (long)((pos_open_price_last - pos_open_price) / _Point);
            sBS = "BUY ";
        }

        if( POSITION_TYPE_SELL == pos_open_type )
        {
            pos_open_price_delta = (long)((pos_open_price - pos_open_price_last) / _Point);
            sBS = "SELL";
        }

        str = StringFormat(" t: %s [%s v%0.2f] %s #%d   %6d / %6ds ",
                           TimeToString(TimeCurrent(), TIME_SECONDS ),
                           sBS,
                           pos_open_vol,
                           _Symbol,
                           position_ID,
                           pos_open_price_delta,
                           create_time_delta );


        str += StringFormat(" -  open price delta: %5d - last price %s  - open price %s - profit: %s - vol: %s",
                            pos_open_price_delta,
                            DoubleToString(pos_open_price_last, _Digits),
                            DoubleToString(pos_open_price, _Digits),
                            DoubleToString(pos_open_profit, 2),
                            DoubleToString(pos_open_vol, 2) );


        str += StringFormat(" -  %d delta seconds => curr time %s  - open time %s",
                            create_time_delta, TimeToString(TimeCurrent(), TIME_SECONDS ), TimeToString(pos_open_time, TIME_SECONDS ) );


    } // if(PositionSelect(_Symbol))


    //Print( str );

    //
    // calc all the iMa handles
    //
    double buf[1];
    int sMaSize = ArraySize(sMa);
    vector<double> vweights = vector::Ones((sMaSize - 1));
    //vector<double> vweights = {1,2,3,4,5,6,70,80};
    for( int cnt = 0; sMaSize > cnt; cnt++ )
    {

        if( "SUM_AVG" == sMa[cnt].periodKey )
        {
            // t0, c0
            sMa[cnt].t0 = TimeCurrent();
            sMa[cnt].c0 = last_price;
            // ma1,...
            vector<double> vma1(sMaSize - 1);
            vector<double> vma2(sMaSize - 1);
            vector<double> vma3(sMaSize - 1);
            vector<double> vma4(sMaSize - 1);
            for( int avg_cnt = 0; (sMaSize - 1) > avg_cnt; avg_cnt++ )
            {
                vma1[avg_cnt] = sMa[avg_cnt].ma1;
                vma2[avg_cnt] = sMa[avg_cnt].ma2;
                vma3[avg_cnt] = sMa[avg_cnt].ma3;
                vma4[avg_cnt] = sMa[avg_cnt].ma4;
            }
            sMa[cnt].ma1 = NormalizeDouble(vma1.Average(vweights), _Digits);
            sMa[cnt].ma2 = NormalizeDouble(vma2.Average(vweights), _Digits);
            sMa[cnt].ma3 = NormalizeDouble(vma3.Average(vweights), _Digits);
            sMa[cnt].ma4 = NormalizeDouble(vma4.Average(vweights), _Digits);

            // mad1,...
            vector<double> vmad1(sMaSize - 1);
            vector<double> vmad2(sMaSize - 1);
            vector<double> vmad3(sMaSize - 1);
            vector<double> vmad4(sMaSize - 1);
            vector<double> vmad_avg(sMaSize - 1);
            for( int avg_cnt = 0; (sMaSize - 1) > avg_cnt; avg_cnt++ )
            {
                vmad1[avg_cnt] = (double)sMa[avg_cnt].mad1;
                vmad2[avg_cnt] = (double)sMa[avg_cnt].mad2;
                vmad3[avg_cnt] = (double)sMa[avg_cnt].mad3;
                vmad4[avg_cnt] = (double)sMa[avg_cnt].mad4;
                vmad_avg[avg_cnt] = (double)sMa[avg_cnt].mad_avg;
            }
            sMa[cnt].mad1 = (int)vmad1.Average(vweights);
            sMa[cnt].mad2 = (int)vmad2.Average(vweights);
            sMa[cnt].mad3 = (int)vmad3.Average(vweights);
            sMa[cnt].mad4 = (int)vmad4.Average(vweights);
            sMa[cnt].mad_avg = (int)vmad_avg.Average(vweights);

            // c0d1,...
            vector<double> vc0d1(sMaSize - 1);
            vector<double> vc0d2(sMaSize - 1);
            vector<double> vc0d3(sMaSize - 1);
            vector<double> vc0d4(sMaSize - 1);
            vector<double> vc0d_avg(sMaSize - 1);
            for( int avg_cnt = 0; (sMaSize - 1) > avg_cnt; avg_cnt++ )
            {
                vc0d1[avg_cnt] = (double)sMa[avg_cnt].c0d1;
                vc0d2[avg_cnt] = (double)sMa[avg_cnt].c0d2;
                vc0d3[avg_cnt] = (double)sMa[avg_cnt].c0d3;
                vc0d4[avg_cnt] = (double)sMa[avg_cnt].c0d4;
                vc0d_avg[avg_cnt] = (double)sMa[avg_cnt].c0d_avg;
            }
            sMa[cnt].c0d1 = (int)vc0d1.Average(vweights);
            sMa[cnt].c0d2 = (int)vc0d2.Average(vweights);
            sMa[cnt].c0d3 = (int)vc0d3.Average(vweights);
            sMa[cnt].c0d4 = (int)vc0d4.Average(vweights);
            sMa[cnt].c0d_avg = (int)vc0d_avg.Average(vweights);

            // avg
            vector<double> vavg(sMaSize - 1);
            for( int avg_cnt = 0; (sMaSize - 1) > avg_cnt; avg_cnt++ )
            {
                vavg[avg_cnt] = (double)sMa[avg_cnt].sum_avg;
            }
            sMa[cnt].sum_avg = (int)vavg.Average(vweights);

            sMa[cnt].str_txt = StringFormat("%10s C0 %s MAD %4d %4d %4d %4d %4d C0D %4d %4d %4d %4d %4d SUM_AVG %4d",
                                            sMa[cnt].periodKey,
                                            DoubleToString(sMa[cnt].c0, Digits()),
                                            sMa[cnt].mad1,
                                            sMa[cnt].mad2,
                                            sMa[cnt].mad3,
                                            sMa[cnt].mad4,
                                            sMa[cnt].mad_avg,
                                            sMa[cnt].c0d1,
                                            sMa[cnt].c0d2,
                                            sMa[cnt].c0d3,
                                            sMa[cnt].c0d4,
                                            sMa[cnt].c0d_avg,
                                            sMa[cnt].sum_avg  );

            continue;

        } // if( "SUM_AVG" == sMa[cnt].periodKey )

        string _symbolName = "";
        ENUM_TIMEFRAMES period = 0;
        if( true == GetSymbolNameAndPeriodFromKey(sMa[cnt].periodKey, _Symbol, _symbolName, period) )
        {
            sMa[cnt].t0 = iTime( _symbolName, period, 0 );
        }

        sMa[cnt].c0 = last_price;
        sMa[cnt].ma1 = sMa[cnt].c0;
        if( 0 < BarsCalculated(sMa[cnt].hS1) )
        {
            if( 0 < CopyBuffer(sMa[cnt].hS1, 0, 0, 1, buf) )
            {
                sMa[cnt].ma1 = buf[0];
            }
        }

        sMa[cnt].ma2 = sMa[cnt].c0;
        if( 0 < BarsCalculated(sMa[cnt].hS2) )
        {
            if( 0 < CopyBuffer(sMa[cnt].hS2, 0, 0, 1, buf) )
            {
                sMa[cnt].ma2 = buf[0];
            }
        }

        sMa[cnt].ma3 = sMa[cnt].c0;
        if( 0 < BarsCalculated(sMa[cnt].hS3) )
        {
            if( 0 < CopyBuffer(sMa[cnt].hS3, 0, 0, 1, buf) )
            {
                sMa[cnt].ma3 = buf[0];
            }
        }

        sMa[cnt].ma4 = sMa[cnt].c0;
        if( 0 < BarsCalculated(sMa[cnt].hS4) )
        {
            if( 0 < CopyBuffer(sMa[cnt].hS4, 0, 0, 1, buf) )
            {
                sMa[cnt].ma4 = buf[0];
            }
        }

        sMa[cnt].mad1 = (int)((sMa[cnt].c0  - sMa[cnt].ma1) / _Point);
        sMa[cnt].mad2 = (int)((sMa[cnt].ma1 - sMa[cnt].ma2) / _Point);
        sMa[cnt].mad3 = (int)((sMa[cnt].ma2 - sMa[cnt].ma3) / _Point);
        sMa[cnt].mad4 = (int)((sMa[cnt].ma3 - sMa[cnt].ma4) / _Point);
        sMa[cnt].mad_avg = (int)(( sMa[cnt].mad1 + sMa[cnt].mad2 + sMa[cnt].mad3 + sMa[cnt].mad4 ) / 4);


        sMa[cnt].c0d1 = int( (sMa[cnt].c0 - sMa[cnt].ma1 ) / Point() );
        sMa[cnt].c0d2 = int( (sMa[cnt].c0 - sMa[cnt].ma2 ) / Point() );
        sMa[cnt].c0d3 = int( (sMa[cnt].c0 - sMa[cnt].ma3 ) / Point() );
        sMa[cnt].c0d4 = int( (sMa[cnt].c0 - sMa[cnt].ma4 ) / Point() );
        sMa[cnt].c0d_avg = (( sMa[cnt].c0d1 + sMa[cnt].c0d2 + sMa[cnt].c0d3 + sMa[cnt].c0d4 ) / 4);



        sMa[cnt].sum_avg = (int)(( sMa[cnt].mad1 + sMa[cnt].mad2 + sMa[cnt].mad3 + sMa[cnt].mad4 +
                                   sMa[cnt].c0d1 + sMa[cnt].c0d2 + sMa[cnt].c0d3 + sMa[cnt].c0d4 ) / 8);
        //Print( str );

        sMa[cnt].str_txt = StringFormat("%10s C0 %s MAD %4d %4d %4d %4d %4d C0D %4d %4d %4d %4d %4d SUM_AVG %4d",
                                        sMa[cnt].periodKey,
                                        DoubleToString(sMa[cnt].c0, Digits()),
                                        sMa[cnt].mad1,
                                        sMa[cnt].mad2,
                                        sMa[cnt].mad3,
                                        sMa[cnt].mad4,
                                        sMa[cnt].mad_avg,
                                        sMa[cnt].c0d1,
                                        sMa[cnt].c0d2,
                                        sMa[cnt].c0d3,
                                        sMa[cnt].c0d4,
                                        sMa[cnt].c0d_avg,
                                        sMa[cnt].sum_avg  );



    } // for( int cnt = 0; sMaSize>cnt; cnt++ )



    int mad_avg_low =  (sMa[0].mad_avg + sMa[1].mad_avg + sMa[2].mad_avg + sMa[3].mad_avg) / 4;
    int mad_avg_high = (sMa[4].mad_avg + sMa[5].mad_avg + sMa[6].mad_avg + sMa[7].mad_avg) / 4;
    int c0d_avg_low =  (sMa[0].c0d_avg + sMa[1].c0d_avg + sMa[2].c0d_avg + sMa[3].c0d_avg) / 4;
    int c0d_avg_high = (sMa[4].c0d_avg + sMa[5].c0d_avg + sMa[6].c0d_avg + sMa[7].c0d_avg) / 4;
    int sum_avg_low =  (sMa[0].sum_avg + sMa[1].sum_avg + sMa[2].sum_avg + sMa[3].sum_avg) / 4;
    int sum_avg_high = (sMa[4].sum_avg + sMa[5].sum_avg + sMa[6].sum_avg + sMa[7].sum_avg) / 4;


    str = StringFormat(" t: %s %s  c0: %s s: %2d tickv: %0.1f/%0.1f/%0.1f  mad: %4d/%4d/%4d c0d: %4d/%4d/%4d avg: %4d/%4d/%4d  pips: %6d over %6d s",
                       TimeToString(TimeCurrent(), TIME_SECONDS ),
                       _Symbol,
                       DoubleToString(sMa[sMaSize - 1].c0, Digits()),
                       (int)last_spread,
                       tick_avg,
                       tick_avg_low,
                       tick_avg_high,
                       sMa[sMaSize - 1].mad_avg,
                       mad_avg_low,
                       mad_avg_high,
                       sMa[sMaSize - 1].c0d_avg,
                       c0d_avg_low,
                       c0d_avg_high,
                       sMa[sMaSize - 1].sum_avg,
                       sum_avg_low,
                       sum_avg_high,
                       pos_open_price_delta,
                       create_time_delta );
    //Print( str );

    //
    // comment output c0 and spread
    //
    int _comment_txt_line_start = 0;

    string delta_ms_since_last_tick_str = "n/a";
    if( 0 < tickCount )
        delta_ms_since_last_tick_str = IntegerToString                                                                                                   (GetTickCount() - tickCount);
    string tickv_str = StringFormat("c0: %s s: %2d d: %4s",
                                    DoubleToString(sMa[sMaSize - 1].c0, Digits()),
                                    (int)last_spread,
                                    delta_ms_since_last_tick_str );
    tickCount = 0;
    comment.SetText(_comment_txt_line_start, tickv_str, COLOR_TEXT);

    //
    // comment output tick speed
    //
    _comment_txt_line_start++;

    double tick_threshold = 1.0;
    if( "GBPJPY" == _Symbol || "NZDUSD" == _Symbol )
        tick_threshold = 2.0;

    tickv_str = StringFormat(" %4d/min :  %0.1f/ %0.1f/ %0.1f ",
                             size60,
                             tick_avg,
                             tick_avg_low,
                             tick_avg_high );

    if( tick_threshold < tick_avg_low &&  tick_threshold < tick_avg_high )
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

    string hl_str = StringFormat(" %4d  HL : %4d/%4d/%4d",
                                 hl60,
                                 (int)hl_avg,
                                 (int)hl_avg_low,
                                 (int)hl_avg_high );

    if( hl_threshold < hl_avg_low &&  hl_threshold < hl_avg_high )
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

    string oc_str = StringFormat(" %4d  OC : %4d/%4d/%4d",
                                 oc60,
                                 (int)oc_avg,
                                 (int)oc_avg_low,
                                 (int)oc_avg_high );

    if( +1 * oc_threshold < oc_avg_low && +1 * oc_threshold < oc_avg_high)
    {
        comment.SetText(_comment_txt_line_start, oc_str, COLOR_BLUE);
    }
    else if ( -1 * oc_threshold > oc_avg_low && -1 * oc_threshold > oc_avg_high )
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

    for( int cnt = 0; sMaSize > cnt; cnt++ )
    {
        _ma_str = StringFormat("  %7s : %4d/%4d/%4d",
                               sMa[cnt].periodKey,
                               sMa[cnt].mad_avg,
                               sMa[cnt].c0d_avg,
                               sMa[cnt].sum_avg );
        _sum_avg_threshold = 10 + (int)last_spread;
        int _lineno = _comment_txt_line_start + cnt;
        if( +1 * _sum_avg_threshold < sMa[cnt].sum_avg )
        {
            comment.SetText(_lineno, _ma_str, COLOR_BLUE);
        }
        else if ( -1 * _sum_avg_threshold > sMa[cnt].sum_avg )
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
    _comment_txt_line_start += sMaSize;

    if( "" == sBS || 0.0 == pos_open_vol )
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
                                     create_time_delta );

        if( 10 < pos_open_price_delta )
        {
            if( "BUY " == sBS )
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_BLUE);
            else if( "SELL" == sBS )
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_RED);
            else
                comment.SetText(_comment_txt_line_start, bs_str, COLOR_TEXT);

        }
        else if ( -10 > pos_open_price_delta )
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
                                 TimeToString(TimeCurrent(), TIME_SECONDS ),
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
    if(PositionSelect(_Symbol))
    {
        /*double pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        double pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        long pos_open_time = PositionGetInteger(POSITION_TIME);
        long pos_open_price_delta = 0;
        ENUM_POSITION_TYPE pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);*/
        if( POSITION_TYPE_BUY == pos_open_type )
        {
            pos_open_price_delta = (long)((pos_open_price_last - pos_open_price) / _Point);
            _color = clrBlue;
            _colorLine = clrBlue;
            if( 0 > pos_open_price_delta )
                _color = clrYellow;
        }

        if( POSITION_TYPE_SELL == pos_open_type )
        {
            pos_open_price_delta = (long)((pos_open_price - pos_open_price_last) / _Point);
            _color = clrRed;
            _colorLine = clrRed;
            if( 0 > pos_open_price_delta )
                _color = clrYellow;
        }

        SetTline(0,      "OP_tline", 0, pos_open_time, pos_open_price, timep, pos_open_price,      _colorLine, STYLE_SOLID, 3, "OP_tline");
        SetRightPrice(0, "OP_price", 0, timep,         pos_open_price,                             _colorLine, "Georgia");
        SetRectangle(0,  "OP_rect",  0, time1,         pos_open_price, time0, pos_open_price_last, _color, STYLE_SOLID, 1, "OpenPrice");


        if( 0 == ObjectFind( 0, "OC_tline") )
            ObjectDelete( 0,    "OC_tline");
        if( 0 == ObjectFind( 0, "OC_price") )
            ObjectDelete( 0,    "OC_price");
        if( 0 == ObjectFind( 0, "OC_rect") )
            ObjectDelete( 0,    "OC_rect");

    }
    else
    {
        if( 0 == ObjectFind( 0, "OP_tline") )
            ObjectDelete( 0,    "OP_tline");
        if( 0 == ObjectFind( 0, "OP_price") )
            ObjectDelete( 0,    "OP_price");
        if( 0 == ObjectFind( 0, "OP_rect") )
            ObjectDelete( 0,    "OP_rect");

        if( 10 < oc60 )
        {
            _color = clrBlue;
            _colorLine = clrBlue;
        }
        if( -10 > oc60 )
        {
            _color = clrRed;
            _colorLine = clrRed;
        }
        double o0 = iOpen( _Symbol, _Period, 0 );
        double oc = o0/*last_price -*/ + oc60 * _Point;
        SetTline(     0, "OC_tline", 0, time1, oc, timep, oc,         _colorLine, STYLE_SOLID, 3, "OP_tline");
        SetRightPrice(0, "OC_price", 0, timep, oc,                    _colorLine, "Georgia");
        SetRectangle( 0, "OC_rect",  0, time1, oc, time0, o0, _color, STYLE_SOLID, 1, "OpenPrice");

    } // if(PositionSelect(_Symbol))

    SetTline(0, "PRICE_tline", 0, time1, last_price, timep, last_price, clrSpringGreen, STYLE_SOLID, 3, "PRICE_tline");
    SetRightPrice(0, "PRICE_price", 0, timep, last_price, clrSpringGreen, "Georgia");
#endif

    //EventKillTimer();

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

    ResetAllTickBarsIfStopAllOrNewHour( stopAll );

    if(LoopBack && Limit > 0)
    {
        shift();
        add();
    }
    else
    {
        lastTime += TimeDelta;
        add(lastTime);
    }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void _OnTick(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _OnDeinit(const int reason)
{

    Print( "OnDeinit: ", reason );
    //
    // open all the iMa handles
    //
    int sMaSize = ArraySize(sMa);
    for( int cnt = 0; sMaSize > cnt; cnt++ )
    {
        if(INVALID_HANDLE != sMa[cnt].hS1)
        {
            IndicatorRelease(sMa[cnt].hS1);
        }
        if(INVALID_HANDLE != sMa[cnt].hS2)
        {
            IndicatorRelease(sMa[cnt].hS2);
        }
        if(INVALID_HANDLE != sMa[cnt].hS3)
        {
            IndicatorRelease(sMa[cnt].hS3);
        }
        if(INVALID_HANDLE != sMa[cnt].hS4)
        {
            IndicatorRelease(sMa[cnt].hS4);
        }
    } // for( int cnt = 0; sMaSize>cnt; cnt++ )

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetAllTickBarsIfStopAllOrNewHour( bool stop_all = false )
{
    
    // no error
    if( false == stop_all )
    {
        datetime t0 = iTime( _Symbol, PERIOD_M1, 0);
        MqlDateTime dt0;
        TimeToStruct( t0, dt0 );
        datetime t1 = iTime( _Symbol, PERIOD_M1, 1);
        MqlDateTime dt1;
        TimeToStruct( t1, dt1 );
        // a new hour has begun - create new custom symbol of the hour
        if( dt0.hour != dt1.hour )
        {
            string str_apx = StringFormat( "_%02d%02d%02d", 
                                                dt0.mon,
                                                dt0.day,
                                                dt0.hour );
            // if the appendix hasn't changed yet 
            //  -> e.g. for PERIOD_M1 that could happen
            //          the full first 60s
            if( str_apx != symbolNameAppendix )
            {
                symbolNameAppendix = str_apx;
                symbolName = Symbol() + symbolNameAppendix;
                _OnDeinit(0);
                // TODO error handling
                int ret = _OnInit();
                Print( "newHour: ",  stopAll, " _OnInit: ", ret );
            }
            
        } // if( dt0.hour != dt1.hour )
    }
    else
    {
        _OnDeinit(0);
        Sleep(1000);
        // TODO error handling
        int ret = _OnInit();
        Sleep(1000);
        Print( "stopAll: ",  stopAll, " _OnInit: ", ret );
        stopAll = false;
        
    } // if( false == stop_all )

} // void ResetAllTickBarsIfStopAllOrNewHour( bool stop_all = false )
//+------------------------------------------------------------------+

