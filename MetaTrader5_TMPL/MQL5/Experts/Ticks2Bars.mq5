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
bool firstRun;
bool stopAll;
bool justCreated;
datetime lastTime;

MqlRates rates[];


// A P P L I C A T I O N

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
        Sleep(1000);

        MqlTick array[];
        size = CopyTicks(symbolName, array, COPY_TICKS_ALL, 0, Limit);
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
    int size = CopyTicks(_Symbol, array, COPY_TICKS_ALL, 0, Limit);
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
                cursor += 60;
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
            rates[i].time -= 60;
        }

        if(CustomRatesDelete(symbolName, 0, rates[0].time - 60) == -1)
        {
            Print("Not deleted: ", GetLastError());
        }

        if(CustomRatesUpdate(symbolName, rates) == -1)
        {
            Print("Not shifted: ", GetLastError());
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
                ta[0].time += 60; // forward tick (next temporary bar) to activate EA (if any)
                ta[0].time_msc = ta[0].time * 1000;
                if(CustomTicksAdd(symbolName, ta) == -1)
                {
                    Print("Not ticked:", GetLastError(), " ", (long)ta[0].time);
                    ArrayPrint(ta);
                    stopAll = true;
                }
                // remove the temporary tick
                CustomTicksDelete(symbolName, ta[0].time_msc, LONG_MAX);
            }
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
        _symbolName = symbol + "_ticks";
        period = PERIOD_M1;
        return true;
    }

    if( "T5" == periodKey)
    {
        _symbolName = symbol + "_ticks";
        period = PERIOD_M5;
        return true;
    }

    if( "T15" == periodKey)
    {
        _symbolName = symbol + "_ticks";
        period = PERIOD_M15;
        return true;
    }

    if( "T60" == periodKey)
    {
        _symbolName = symbol + "_ticks";
        period = PERIOD_H1;
        return true;
    }

    if( "T240" == periodKey)
    {
        _symbolName = symbol + "_ticks";
        period = PERIOD_H4;
        return true;
    }

    if( "T720" == periodKey)
    {
        _symbolName = symbol + "_ticks";
        period = PERIOD_H12;
        return true;
    }

    if( "S60" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M1;
        return true;
    }

    if( "S300" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M5;
        return true;
    }

    if( "S900" == periodKey)
    {
        _symbolName = symbol;
        period = PERIOD_M15;
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



// E V E N T   H A N D L E R S

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(void)
{
    stopAll = false;
    justCreated = false;

    if(SymbolInfoInteger(_Symbol, SYMBOL_CUSTOM))
    {
        Alert("" + _Symbol + " is a custom symbol. Only built-in symbol can be used as a host.");
        return INIT_FAILED;
    }

    symbolName = Symbol() + "_ticks";
    if(!SymbolSelect(symbolName, true))
    {
        ResetLastError();
        SymbolInfoInteger(symbolName, SYMBOL_CUSTOM);
        if(ERR_MARKET_UNKNOWN_SYMBOL == GetLastError())
        {
            Print( "create symbol" );
            CustomSymbolCreate( symbolName, _Symbol, _Symbol );
            justCreated = true;
        }

        if(!SymbolSelect(symbolName, true))
        {
            Alert("Can't select symbol:", symbolName, " err:", GetLastError());
            return INIT_FAILED;
        }
    }

    EventSetTimer(5);

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
                Sleep(1000);
                ChartSetSymbolPeriod(id, symbolName, PERIOD_M1);
                ChartSetInteger(id, CHART_MODE, CHART_CANDLES);
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
    sMa[0].periodKey = "T1";
    sMa[1].periodKey = "T5";
    sMa[2].periodKey = "T15";
    sMa[3].periodKey = "T60";
    sMa[4].periodKey = "S60";
    sMa[5].periodKey = "S300";
    sMa[6].periodKey = "S900";
    sMa[7].periodKey = "S3600";
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
        //Ind_Handle_S1_M1_Ticks=iCustom(Symbol()/*+"_ticks"*/,PERIOD_M1,"GRFLsqFit",nS1,nS2,nS3,nS4);
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

    ArrayPrint( sMa );


    return INIT_SUCCEEDED;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // int OnInit(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
{

    ulong position_ID = 0;
    long create_time = 0;
    long create_time_delta = 0;

    double last_price = 0;
    double last_spread = 0;
    ulong  pos_open_time_delta = 0;
    ulong  pos_open_price_delta = 0;
    double pos_open_price = 0;
    double pos_open_price_last = 0;
    double pos_open_profit = 0;
    double pos_open_vol = 0;
    ENUM_POSITION_TYPE pos_open_type;

    MqlTick array[];
    int size1   = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 1   ) * 1000, (TimeCurrent() - 0) * 1000 );
    //ArrayPrint(array);
    int size2   = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 2   ) * 1000, (TimeCurrent() - 0) * 1000 );
    int size5   = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 5   ) * 1000, (TimeCurrent() - 0) * 1000 );
    int size15  = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 15  ) * 1000, (TimeCurrent() - 0) * 1000 );
    int size60  = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 60  ) * 1000, (TimeCurrent() - 0) * 1000 );
    int size300 = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 300 ) * 1000, (TimeCurrent() - 0) * 1000 );
    int size900 = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 900 ) * 1000, (TimeCurrent() - 0) * 1000 );
    int size3600 = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, (TimeCurrent() - 3600 ) * 1000, (TimeCurrent() - 0) * 1000 );
    //string str = StringFormat( " t: %s %4d %4d %4d %4d %4d %4d %6d %6d", TimeToString(TimeCurrent(), TIME_SECONDS),
    //                           size1, size2, size5, size15, size60, size300, size900, size3600 );
    double tick_avg = (((double)size1 / 1) +     ((double)size2 / 2) +
                       (double)(size5 / 5) +     ((double)size15 / 15) +
                       ((double)size60 / 60) +   ((double)size300 / 300) +
                       ((double)size900 / 900) + ((double)size3600 / 3600) ) / 8;
    double tick_avg_low = (((double)size1 / 1) +     ((double)size2 / 2) +
                           (double)(size5 / 5) +     ((double)size15 / 15)  ) / 4;
    double tick_avg_high = (((double)size60 / 60) +   ((double)size300 / 300) +
                            ((double)size900 / 900) + ((double)size3600 / 3600) ) / 4;
    string str = StringFormat( " t: %s  avg:%0.1f/%0.1f/%0.1f  %4d/1 %4d/2 %4d/5 %4d/15 %6d/60 %6d/300 %6d/900 %6d/3600",
                               TimeToString(TimeCurrent(), TIME_SECONDS),
                               tick_avg,
                               tick_avg_low,
                               tick_avg_high,
                               size1, size2, size5, size15, size60, size300, size900, size3600 );
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
            Print( str );
        }
    }


    str = StringFormat(" t: %s  no open position", TimeToString(TimeCurrent(), TIME_SECONDS ) );

    //--- check if a position is present and display the time of its changing
    if(PositionSelect(_Symbol))
    {


        //--- receive position ID for further work
        position_ID = PositionGetInteger(POSITION_IDENTIFIER);
        //--- receive the time of position forming in milliseconds since 01.01.1970
        create_time = PositionGetInteger(POSITION_TIME);
        create_time_delta = TimeCurrent() - create_time;

        pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        pos_open_profit =  PositionGetDouble(POSITION_PROFIT);
        pos_open_vol =  PositionGetDouble(POSITION_VOLUME);

        string sBS;
        pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if( POSITION_TYPE_BUY == pos_open_type )
        {
            pos_open_price_delta = (ulong)((pos_open_price_last - pos_open_price) / _Point);
            sBS = "BUY ";
        }

        if( POSITION_TYPE_SELL == pos_open_type )
        {
            pos_open_price_delta = (ulong)((pos_open_price - pos_open_price_last) / _Point);
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
                            create_time_delta, TimeToString(TimeCurrent(), TIME_SECONDS ), TimeToString(create_time, TIME_SECONDS ) );


    } // if(PositionSelect(_Symbol))

    Print( str );

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

        if( 0 < CopyBuffer(sMa[cnt].hS1, 0, 0, 1, buf) )
        {
            sMa[cnt].ma1 = buf[0];
        }
        if( 0 < CopyBuffer(sMa[cnt].hS2, 0, 0, 1, buf) )
        {
            sMa[cnt].ma2 = buf[0];
        }
        if( 0 < CopyBuffer(sMa[cnt].hS3, 0, 0, 1, buf) )
        {
            sMa[cnt].ma3 = buf[0];
        }
        if( 0 < CopyBuffer(sMa[cnt].hS4, 0, 0, 1, buf) )
        {
            sMa[cnt].ma4 = buf[0];
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

    ArrayPrint(sMa);
    
/*  
    TimeToString(TimeCurrent(), TIME_SECONDS ),
  
    last_spread
    last_price
    create_time_delta
    pos_open_price_delta  

    tick_avg
    tick_avg_low
    tick_avg_high
    
    sMa[sMaSize-1].mad_avg
    sMa[sMaSize-1].c0d_avg
    sMa[sMaSize-1].sum_avg
      
*/    

    str = StringFormat(" t: %s %s  c0: %s s: %2d tickv: %0.1f/%0.1f/%0.1f ma: %4d/%4d/%4d pips: %6d over %6d s",
        TimeToString(TimeCurrent(), TIME_SECONDS ),
        _Symbol,
        DoubleToString(sMa[sMaSize-1].c0, Digits()),
        (int)last_spread,
        tick_avg,
        tick_avg_low,
        tick_avg_high,
        sMa[sMaSize-1].mad_avg,
        sMa[sMaSize-1].c0d_avg,
        sMa[sMaSize-1].sum_avg,
        pos_open_price_delta ,
        create_time_delta );
    Print( str );


    //EventKillTimer();

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void OnTimer()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
{

    if(stopAll)
    {
        return;
    }

    if(LoopBack && Limit > 0)
    {
        shift();
        add();
    }
    else
    {
        lastTime += 60;
        add(lastTime);
    }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void OnTick(void)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

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


    Comment("");
//--- destroy the timer after completing the work
    EventKillTimer();
    return;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void OnDeinit(const int reason)
//+------------------------------------------------------------------+
