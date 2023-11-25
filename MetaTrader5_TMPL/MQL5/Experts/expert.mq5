//+------------------------------------------------------------------+
//|                                                       expert.mq5 |
//|                                                        andrehowe |
//|                                             http://andrehowe.com |
//+------------------------------------------------------------------+

// Migrating from MQL4 to MQL5 http://www.mql5.com/en/articles/81

// the next file is dynamically created by mt-setup.pl script
//#include <property_tester_file.mqh>
#include <library.mqh>
//#include <socket.mqh>

//ENUM_SYMBOL_INFO_DOUBLE
// double SYMBOL_BID - best sell offer
// double SYMBOL_ASK - best buy offer
 

//
// DEFAULT CALLBACK/EVENT FUNCTIONS
//
//+------------------------------------------------------------------+
//| DEFAULT CALLBACK/EVENT FUNCTIONS
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| OnInit
//+------------------------------------------------------------------+
int OnInit()
{

    TESTERMODE = MQL5InfoInteger(MQL5_TESTER);

    if( NULL != GSYMBOLLIST ) delete GSYMBOLLIST;
    GSYMBOLLIST=new CList;
    
    int err = -1;
    int symtotal = 0;

    
    if( 0 == StringCompare( SYMBOLS, "ALL", false ) )
    {
        int num_symbols=SymbolsTotal(false);
        for(int i=0;i<num_symbols;i++)
        {
            string sym = SymbolName(i,false);
            if( true == FilterSymbols( sym ) )
            {
                SymbolSelect(sym,false);
                continue;
            }
            SymbolSelect(sym,true);
            GSYMBOLLIST.Add( new CSymbol( sym, symtotal) );
            symtotal++; 
        } // for(int i=0;i<num_symbols;i++)
    }
    else
    {
        string s_sep=":";              // A separator as a character
        ushort u_sep;                  // The code of the separator character
        string str_symbol_split[];     // An array to get strings
        u_sep=StringGetCharacter(s_sep,0);//--- Get the separator code
        int num_sep=StringSplit(SYMBOLS,u_sep,str_symbol_split); //--- Split the string to substrings
        for( int cnt = 0; cnt < num_sep; cnt++ )
        {
            // the first SYMBOL will be always the Symbol() of the chart
            if( 0 == cnt )
            {
                GSYMBOLLIST.Add( new CSymbol( Symbol()             , cnt) );
            }
            else
            {
                GSYMBOLLIST.Add( new CSymbol( str_symbol_split[cnt], cnt) );
            }
        } // for( int cnt = 0; cnt < num_sep; cnt++ )
        symtotal = GSYMBOLLIST.Total();
        if( (1 > num_sep) || (symtotal != num_sep) )
        {
            dbg( "SYMBOLS not equal GSYMBOLLIST" );
            return -1234;
        }
    } // if( 0 == StringCompare( SYMBOLS, "ALL", false )
    
    
    for( int cnt = 0; cnt < symtotal; cnt++ )
    {
        CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
        // generic g_OnInit - will be called after every system check
        err = g_OnInit( s );
        if( E_ALGORITHM_TICKS != g_algorithm )
        {/*
        	//s.g_sr_handler = iCustom( s.SYMBOL, s.PERIOD, "all_t4", FROM_TO_DATE,AVG_CANDLE_HEIGHT,SL_LEVEL,SR_PERIOD );
        	s.g_sr_handler = iCustom( s.SYMBOL, s.PERIOD, "all_t4", FROM_TO_DATE,SR_PERIOD,0.1,0.2,0.3 );
        	if( INVALID_HANDLE == s.g_sr_handler )
        	{
        		Print( "Failed to create the all_t4 indicator" );
        		err = -142;
        	}*/
        }
        // init market book
        if( false == TESTERMODE )
        {
            g_OnInitMarketBook( s );
        }    
    } // for( int cnt = 0; cnt < total; cnt++ )

    // assume the system is NOT OK at startup
    g_system_ok = 0;
    
    // check the forex tick quotes every millisecond
    // TODO fix me MQL2DLL 64-bit version
    /*if( false == TESTERMODE )
    {
        EventSetMillisecondTimer(1);
    }

    if( false == TESTERMODE )
    {
        if( 0 < g_use_socket )
        {
            SocketOpen(g_socket_client_handle,g_socket_host,g_socket_port);
        }
        else
        {
            GSM_HANDLE = MQL2DLL::SM_openWC( g_computername, ACCKEY, PROPKEY, CONTKEY );
        }
    }*/
    
    return (err);
} // int OnInit()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| OnBookEvent
//+------------------------------------------------------------------+
void OnBookEvent (const string& symbol)
{
    // sanity check
    if( false == VERBOSE )
    {
        return;
    }
    int total = GSYMBOLLIST.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
    
        CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
        // sanity checks
        if( symbol != s.SYMBOL )
        {
            continue;
        }
        if( false == s.g_market_book )
        {
            return;
        }
        // get the book
        MqlBookInfo priceArray[];
        bool getBook=MarketBookGet(symbol,priceArray);
        if(getBook)
        {
            int size=ArraySize(priceArray);
            for(int i=0;i<size;i++)
            {
                dbg(s, IntegerToString(i)+": "+nds(s, priceArray[i].price,s.DIGITS)
                +"    Volume = "+nds(s, priceArray[i].volume,s.DIGITS) +
                " type = " + EnumToString((ENUM_BOOK_TYPE)priceArray[i].type));
            }
        }
        else
        {
            dbg("OnBookEvent ERROR " + symbol);
        } // if(getBook)
        
    } // for( int cnt = 0; cnt < total; cnt++ )
    
} // void OnBookEvent (const string& symbol)
//+------------------------------------------------------------------+
 
//+------------------------------------------------------------------+
//| OnTick
//+------------------------------------------------------------------+
void OnTick()
{

    // TODO fix me MQL2DLL 64-bit version
    //if( true == TESTERMODE )
    {
        // check the forex ticks every millisecond
        int total = GSYMBOLLIST.Total();
        for( int cnt = 0; cnt < total; cnt++ )
        {
           CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
           // check if the tick is valid and if the system is running OK
           g_OnSystemCheck(s);
           
           if( false == g_system_ok )
           {
               return;
           }
           g_OnTick(s);
           g_OnHistory(s);
           
        } // for( int cnt = 0; cnt < total; cnt++ )
    }
} // void OnTick()
//+------------------------------------------------------------------+
  
//+------------------------------------------------------------------+
//| OnTimer
//+------------------------------------------------------------------+
void OnTimer() 
{
    // TODO fix me MQL2DLL 64-bit version
    //if( false == TESTERMODE )
    {
        // check the forex ticks every millisecond
        int total = GSYMBOLLIST.Total();
        for( int cnt = 0; cnt < total; cnt++ )
        {
           CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
           // check if the tick is valid and if the system is running OK
           g_OnSystemCheck(s);
           
           if( false == g_system_ok )
           {
               return;
           }
           g_OnTick(s);
           g_OnHistory(s);
           
        } // for( int cnt = 0; cnt < total; cnt++ )
    }
} // void OnTimer() 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| OnDeinit
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  
{

    // close mysql
    // TODO FIXME 64-bits
    //m_sql_close();
    
    int total = GSYMBOLLIST.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
    	if( INVALID_HANDLE != s.g_sr_handler )
    	{
    		IndicatorRelease( s.g_sr_handler );
    		s.g_sr_handler = INVALID_HANDLE;
    	}
        // release the market book
        if( true == s.g_market_book )
        {
            s.g_market_book = MarketBookRelease(s.SYMBOL);
            if( false == s.g_market_book )
            {
                string log = "ERROR MarketBookRelease for " + s.SYMBOL + " failed.";
                Log2Sql( s, "MARKET", -212, log );
            }
        }
    } // for( int cnt = 0; cnt < total; cnt++ )
    
    
    if( true == TESTERMODE )
    {
        CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(0);
        if (0.0 !=s.g_test_balance_start)
        {
            double bal_now = AccountInfoDouble(ACCOUNT_BALANCE);
            double base = g_balance_start_increase;
            if( 0.0 == g_balance_start_increase )
            {
                base = 1.011;
            }
            double expected = MathPow( base,  (double)s.g_test_day_cnt );
            double bal_goal = 0;
            bal_goal = expected * s.g_test_balance_start;
            double bal_diff_abs = bal_now-bal_goal;
            double bal_diff_goal = (bal_goal-s.g_test_balance_start);
            double bal_diff_per = 0;
            if( 0.0 != bal_diff_goal ) { bal_diff_per = bal_diff_abs/bal_diff_goal*100; }
            
            double bal_per = 0;
            if( 0.0 != s.g_test_balance_start ) { bal_per = (bal_now-s.g_test_balance_start)/s.g_test_balance_start*100; }
            
            string log = StringFormat( "DAYS[%d] BAL_START[%s] BAL_END[%s] BAL_GOAL[%s] BAL_PER[%s] GAIN_ABS[%s] GAIN_PER[%s] %s^%d = %s ", 
                    s.g_test_day_cnt, nds(s,s.g_test_balance_start,2), nds(s,bal_now,2), nds(s,bal_goal,2), nds(s,bal_per,2),
                    nds(s,bal_diff_abs,2),  nds(s,bal_diff_per,2),
                    nds(s,base,2), s.g_test_day_cnt, nds(s,expected,2) );
            dbg( log );
            log = StringFormat( "  SUM[%s] SUM1[%s] SUM2[%s] at=%d ts=%d v=%d",
                    nds(s,s.g_normt.sum,1),  nds(s,s.g_normt.sum1,1), nds(s,s.g_normt.sum2,1),
                    ADJUSTTIMEENABLED, SOUT1TRAILINGSTOP, VERBOSE );
            dbg( log );
        }
    } // if( true == TESTERMODE)
    
    if( NULL != GSYMBOLLIST ) delete GSYMBOLLIST;
    GSYMBOLLIST = NULL;
/*
    if( false == TESTERMODE )
    {
        if( 0 < g_use_socket )
        {
            SocketClose(g_socket_client_handle);
        }
        else
        {
            // TODO fix me MQL2DLL 64-bit version
            //MQL2DLL::SM_closeWC( GSM_HANDLE );
        }
    }
*/
} // void OnDeinit(const int reason)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| OnTrade
//+------------------------------------------------------------------+
void OnTrade()
{
    int total = GSYMBOLLIST.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CSymbol* s = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
        // check if datetime and tick prices are available of the server
        // if not, then do not bother processing the history
        g_OnSystemCheck(s);
        if( false == g_system_ok )
        {
            return;
        }
        g_OnHistory(s);
    } // for( int cnt = 0; cnt < total; cnt++ )

} // void OnTrade()
//+------------------------------------------------------------------+



//
// ALGORITHM
//
//+------------------------------------------------------------------+
//| ALGORITHM
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   g_OnSystemCheck
//+------------------------------------------------------------------+
void g_OnSystemCheck(CSymbol& s)
{

    bool nok = false;
    string logstr = "";
    
    //
    // m_GetDatetime start
    //
    datetime tg = TimeGMT();
    datetime tc = TimeCurrent();
    datetime tl = TimeLocal();
    datetime tt = TimeTradeServer();
    if( 0 == tg ) 
    {
        logstr = logstr + "WARNING m_GetDatetime Failed to retrieve TimeGMT(0) | ";
        nok = true;
    }
    if( 0 == tc )
    {
        logstr = logstr + "WARNING m_GetDatetime Failed to retrieve TimeCurrent(0) | ";
        nok = true;
    }
    if( 0 == tl )
    {
        logstr = logstr + "WARNING m_GetDatetime Failed to retrieve TimeLocal(0) | ";
        nok = true;
    }
    if( 0 == tt )
    {
        logstr = logstr + "WARNING m_GetDatetime Failed to retrieve TimeTradeServer(0) | ";
        nok = true;
    }
    if( tc < tg )
    {
        // TODO review me - happens in testermode
        // 	2016.03.24 02:00:01   DBG EURUSD.e - SYSTEM ERROR - DISCONNECT | WARNING m_GetDatetime TimeCurrent < TimeGMT 2016.03.24 02:00:00 2016.03.24 02:00:01 | 
        // TODO to prove that timecurrent is still another two hours not NULL
        //  because otherwise D1 would not be logged, as GOOD NIGHT would never be triggered
        //   as if you start expert advosor on Saturday timecurrent is null
        // KN	0	00:59:03.008	EXPERT (EURUSD.e,M1)	DBG EURUSD.e - SYSTEM ERROR - DISCONNECT | WARNING m_GetDatetime TimeCurrent < TimeGMT | TIME ERROR UPDATE NTP SERVER - TIME DIFF SECONDS: 7201 TIME_LOCAL: 2016.03.26 00:59:03 != TIME_CURRENT: 2016.03.25 22:59:02 | 
        logstr = logstr + "WARNING m_GetDatetime TimeCurrent < TimeGMT " + TimeToString(tc,TIME_DATE|TIME_SECONDS) + " " + TimeToString(tg,TIME_DATE|TIME_SECONDS) + " | ";
        if( false == TESTERMODE )
        {
            nok = true;
        }
    }    
    
    // TODO make NTP time server work
    datetime tls = tl;
    datetime tcs = tc;
    if( true == ADJUSTTIME ) {
        tcs = m_HourDec( tcs );
    }
    long tdiff = tls - tcs;    
    if( 15 < MathAbs((double)tdiff) ) 
    {
        logstr = logstr + "TIME ERROR UPDATE NTP SERVER - TIME DIFF SECONDS: " + IntegerToString(tdiff) + " TIME_LOCAL: " + TimeToString(tl, TIME_DATE | TIME_SECONDS ) + " != TIME_CURRENT: " + TimeToString(tc, TIME_DATE | TIME_SECONDS ) + " | ";
        // TODO this should be a warning but not an error
        // an error could stop/hinder too much:
        //  - not to trigger "GOOD NIGHT"
        //  - not to trade during volatile period
        //nok = true;
    } // if( 15 < MathAbs((double)tdiff) )
    
    g_time_current = tc;
    if( true == ADJUSTTIME ) {
        tl = m_HourDec( tl );
    }
    g_time_local = tl;
    
    //
    // m_GetDatetime end
    //
    
    //
    // m_GetTick() start
    //
    ResetLastError();
    //--- Recalculate the parameters of each m_tick
    if(false == SymbolInfoTick(s.SYMBOL,s.m_tick))
    {
        // error 4302 ERR_MARKET_NOT_SELECTED Symbol is not selected in MarketWatch
        logstr =  logstr + "WARNING m_GetTick SymbolInfoTick Failed to retrieve data SymbolInfoTick(), error code: " + IntegerToString(GetLastError()) + " | ";
        nok = true;
    }
    s.VOL = iTickVolume(s.SYMBOL,s.PERIOD,0);//m_tick.volume;
    s.ASK = s.m_tick.ask;
    s.BID = s.m_tick.bid;
    // validity check of input paramters
    if( ( s.ASK == 0.0 ) || ( s.BID == 0.0 )){
        logstr =  logstr + "WARNING m_GetTick TICK ASK["+nds(s,s.ASK)+"] BID["+nds(s,s.BID)+"] | ";
        nok = true;
    }
    
    //--- Check availability of historical data for current timeframe
    if(Bars(s.SYMBOL,s.PERIOD)<(MINUTES_PER_DAY/(PeriodSeconds(s.PERIOD)/60)+1))
    {
        logstr =  logstr + "WARNING m_GetTick Little historical data for trade | ";
        nok = true;
    }
    
    //--- Update parameters
    // if spread "too high", then return false 
    s.SPREADPOINTS = (int)SymbolInfoInteger(s.SYMBOL,SYMBOL_SPREAD);
    s.m_order_spread=/*ASK-BID;*/ s.SPREADPOINTS*s.POINT;
    // TODO (define "too high") make a define or input parameter for the "100" => 2*2*25
    //   TODO if spread is too high then either ignore the order 
    //     or send out the pending orders faster, e.g. due to paralell creation of 
    //      10 pending orders by 10 different EAs or VMs
    if( 100 < s.SPREADPOINTS )
    {
        logstr =  logstr + StringFormat("%s WARNING SPREAD TOO HIGH ASK/BID/SPREAD/POINT %s/%s/%s/%d", s.SYMBOL, nds(s,s.ASK,s.DIGITS), nds(s,s.BID,s.DIGITS), nds(s,s.m_order_spread,s.DIGITS), s.SPREADPOINTS ) + " | ";
    //    nok = true;
    }

    m_CheckTrailingStop(s);
        
    //
    // m_GetTick() end
    //

    
    if( false == TerminalInfoInteger(TERMINAL_CONNECTED) )
    {
        logstr =  logstr + "ERROR !TERMINAL_CONNECTED | ";
        nok = true;
    }
    if( false == TerminalInfoInteger(TERMINAL_DLLS_ALLOWED) )
    {
        logstr =  logstr + "ERROR !TERMINAL_DLLS_ALLOWED | ";
        nok = true;
    }
    if( false == TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
    {
        logstr =  logstr + "ERROR !TERMINAL_TRADE_ALLOWED | ";
        nok = true;
    }
    
    // system is running ok until this point
    if( (false == nok) && (0!=g_time_local) )
    {
    
        // TODO make proper use of the session function later
        //datetime fd = 0; // from_date
        //datetime td = 0; //   to_date
        //MqlDateTime fdstr,tdstr;
        //bool res = SymbolInfoSessionQuote(s.SYMBOL,MONDAY,0,fd,td);
        //if( true == res )
        // TODO FIXME - this does not work with ALGO_FX
        if( 0 )
        {
            //TimeToStruct(fd,fdstr);
            //TimeToStruct(td,tdstr);
            MqlDateTime tlstr;
            TimeToStruct(g_time_local,tlstr);
            if( 
               (
                // 01:xy -> 22:xy
                (( 0/*fdstr.hour*/ <  tlstr.hour ) && ( tlstr.hour < 23/*tdstr.hour*/ ))
                // 00:02 < time local
             ||  (( 0/*fdstr.hour*/ == tlstr.hour ) && ( 2/*fdstr.min*/  < tlstr.min ))
                // 23:59 > time local
             || (( 23/*tdstr.hour*/ == tlstr.hour ) && ( 58/*tdstr.min*/  > tlstr.min )) 
               )
             // only monday to friday
             && ( (1 <= tlstr.day_of_week) && (5 >= tlstr.day_of_week) )
            )
            {
                // yes, we do receive quotes
                s.g_session_quote = true;
            } 
            else
            {
                if( true == s.g_session_quote ) 
                {
                    if( E_ALGORITHM_TICKS == g_algorithm )
                    {
                        //iLogPeriod(s,PERIOD_M1, 0);
                        iLogPeriod(s,PERIOD_M5, 0);
                        iLogPeriod(s,PERIOD_M15,0);
                        iLogPeriod(s,PERIOD_H1, 0);
                        iLogPeriod(s,PERIOD_H4, 0);
                        iLogPeriod(s,PERIOD_D1, 0);
                    }
                }
                // no, we do not receive quotes
                s.g_session_quote = false;
                logstr =  logstr + "GOOD NIGHT !NO SESSION QUOTE | ";
                nok = true;
            }
        } // if( true == res )
    
    } // if( false == nok )
    
    if( 0 != SymbolInfoInteger(s.SYMBOL, SYMBOL_START_TIME ) )
    {
        logstr =  logstr + "ERROR !SYMBOL_START_TIME | ";
        nok = true;
    }
    if( 0 != SymbolInfoInteger(s.SYMBOL, SYMBOL_EXPIRATION_TIME ) )
    {
        logstr =  logstr + "ERROR !SYMBOL_EXPIRATION_TIME | ";
        nok = true;
    }   
    if( (SYMBOL_TRADE_MODE_FULL != SymbolInfoInteger(s.SYMBOL, SYMBOL_TRADE_MODE )) && (E_ALGORITHM_TICKS != g_algorithm) )
    {
        // TODO support additional the case SYMBOL_TRADE_MODE_CLOSEONLY as well
        // 20150116 one day after SNB swiss franc euro crash the trade server allows only closing positions
        // this should be supported as well
        // 2015.01.16 12:13:15.685	EXPERT (USDJPY,M1)	 SYMBOL_TRADE_MODE: SYMBOL_TRADE_MODE_CLOSEONLY
        // dbg(s, " SYMBOL_TRADE_MODE: ", EnumToString((ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(SYMBOL, SYMBOL_TRADE_MODE )) );
        logstr =  logstr + "ERROR !SYMBOL_TRADE_MODE_FULL | ";
        nok = true;
    }   
    if( false == AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) )
    {
        logstr =  logstr + "ERROR !ACCOUNT_TRADE_ALLOWED | ";
        nok = true;
    }
    
    if( true == nok )
    {
        if( true == g_system_ok )
        {
            string log = "SYSTEM ERROR - DISCONNECT | " + logstr;
            Log2Sql( s, "SYSTEM", 1, log );
            g_system_ok = false;
        } 
        // Show error at startup
        // if NOK == true and g_system_ok == false
        //  what happens at startup ( 0 == g_onerror_cnt ) 
        //   in this special case display the error
        else if ( 0 == g_onsystemerror_cnt ) 
        {
            string log = "SYSTEM ERROR - DISCONNECT AT STARTUP | " + logstr;
            Log2Sql( s, "SYSTEM", 1, log );
            g_onsystemerror_cnt++;
        }
    } // if( true == nok )
    if( false == nok )
    {
        if( false == g_system_ok )
        {
            int err = g_OnInit(s);  
            if( 0 == err )
            {
                string log = "SYSTEM OK";
                Log2Sql( s, "SYSTEM", err, log );
                g_system_ok = true;
            }
            else
            {
                string log = "SYSTEM ERROR - INIT ERR [" + IntegerToString(err) + "]";
                Log2Sql( s, "SYSTEM", err, log );
                g_system_ok = false;
            }      
        }
    } // if( false == nok )
} // void g_OnSystemCheck()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   g_OnHistory
//+------------------------------------------------------------------+
void g_OnHistory(CSymbol& s)
{
    // TODO clean me up - only for none watchers log the history
    // TODO log history for watchers as well once the master is broken down
    // only the master is allowed to log to the database
    if( (true == USEDATABASE) && ( true == g_is_master ) ) 
    {
        if( false == s.g_history_started ){
            g_InitHistoryProcessor(s);
        }else{
            g_HistoryProcessor(s);
        }
    } // if( (true == USEDATABASE) && ( 0 == g_watcher_number ) ) 
} // void g_OnHistory()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   g_OnInitMarketBook
//+------------------------------------------------------------------+
void g_OnInitMarketBook(CSymbol& s)
{

    s.g_market_book = false;
    // TODO MarketBookAdd is not working yet
    /*if( E_ALGORITHM_TICKS == g_algorithm )
    {
        s.g_market_book = MarketBookAdd(s.SYMBOL);
        if( false == s.g_market_book )
        {
            string log = "ERROR MarketBookAdd for " + s.SYMBOL + " failed.";
            Log2Sql( s, "MARKET", -211, log );
        }
    } // if( E_ALGORITHM_TICKS == g_algorithm )*/
} // int g_OnInitMarketBook(CSymbol& s)

//+------------------------------------------------------------------+
//|   g_OnInit
//+------------------------------------------------------------------+
int g_OnInit(CSymbol& s)
{
    int err = 0;  
    
    g_tradstate = "STOP";
    g_contstate = CONTKEY;

    // assemble the input parameters
    err = m_AssembleInputParameters();
    if( 0 != err )
    {
        return (err);
    }
    
    //
    // INIT GLOBAL VARIABLES
    //  

//---
    // reset trailing parameters
    s.g_open_positions_trailing_stop  = TRAILING_STOP;
    s.g_open_positions_trailing_step  = TRAILING_STEP;
    m_CheckTrailingStop(s);

//--- If the price includes 4 decimal places
    /*// TRAILING_STOP in points
    if(DIGITS == 4)
    {
        g_open_positions_trailing_stop = g_open_positions_trailing_stop  / 10;
        g_open_positions_trailing_step = g_open_positions_trailing_step  / 10;
    }*/
    s.g_wait_time = g_time_current;  
    s.g_tick_cnt = 0;
    s.g_v0prev = 0;
    
    // at least keep the pending order for one day
    // in the default mode
    if( 0 == MARKET_VOLATILITY_RESET_MIN )
    {
        g_pending_order_expiry_time_s = MINUTES_PER_DAY*60;// 1 day
    }
    else
    {
        g_pending_order_expiry_time_s = MARKET_VOLATILITY_RESET_MIN*60;  // 1 day
    }
        
    //--- Initialize the generator of random numbers
    MathSrand(GetTickCount());

    // history
    s.g_history_started = false;
    // ticks algo 
    s.g_algo_ticks_init = false;
    
    // do not start trading unless told otherwise, hence set the flag to true
    s.g_stop_trading = true;
    
    //s.g_is_normalised = false;

    // check point and digits
    err = m_CheckPredefinedVariables(s);
    if( 0 != err )
    {
        return (err);
    }
    
    //
    // INIT MYSQL
    //     
    GMYSQL_INIT_FAILED = true;
    if( true == USEDATABASE ) 
    {
        err = m_sql_init(s);
        if( 0 == err )
        {
            GMYSQL_INIT_FAILED = false;
            err = m_sql_createdb(s);
            if( 0 == err )
            {
                dbg( "DATABASES created" );
            }
        }
    } // if( true == USEDATABASE ) 

    // only output the first STARTUP message
    // TODO fix me MQL2DLL 64-bit version
    g_is_master = true;
    if( 0 == s.g_oninit_cnt )
    {
        string log = "STARTUP - ALGORITHM["+ALGORITHM+"] ALGOPARAM["+ALGOPARAM+"] COMPUTER["+g_computername+"] MASTER["+IntegerToString(g_is_master)+"] VERSION["+VERSION+"] SYSTEM OK["+IntegerToString(g_system_ok)+"] ERROR["+IntegerToString(err)+"] USEDATABASE["+IntegerToString(USEDATABASE)+"] TESTERMODE["+IntegerToString(TESTERMODE)+"]";
        Log2Sql( s, "STARTUP", err, log );
    }
    s.g_oninit_cnt++;

    //
    // MISC INIT
    //
    m_InitWatcherData( s );
    g_OnHistory(s);
    m_AccountInformation();
    
    // balance start will be set in trading allowed, if trading is allowed    
    //g_balance_start = 0;
    g_balance_start = AccountInfoDouble(ACCOUNT_BALANCE);
    g_balance_reached = false;
    
    s.g_market_is_volatile_time = 0;
    
    s.g_session_quote = false;
    
    //
    //  01_CSV, 02_SIG, 03_EXE
    //
    
    s.g_01_CSV_t0 = 0;
    s.g_02_SIG_t0 = 0;
    s.g_03_EXE_t0 = 0;
    s.g_01_CSV_tc = 0;
    s.g_02_SIG_tc = 0;
    s.g_03_EXE_tc = 0;
    
    s.g_01_CSVs_fN = "";
    s.g_01_CSVx_fN = "";
    s.g_02_SIGs_fN = "";
    s.g_02_SIGx_fN = "";
    s.g_03_EXEs_fN = "";
    s.g_03_EXEx_fN = "";
    
    s.g_01_CSV_TC_fN = "";
    s.g_01_CSV_T0_fN = "";
    s.g_02_SIG_TC_fN = "";
    s.g_02_SIG_T0_fN = "";
    s.g_03_EXE_TC_fN = "";
    s.g_03_EXE_T0_fN = "";
    
    // TODO make me optional - like for weekends for data and history retrievement
    m_update_01_CSV( s );
    m_update_03_EXE_2( s, -1 );

    //
    //  01_CSV, 02_SIG, 03_EXE
    //
    
    return(err);

} // int g_OnInit()
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   g_OnTick                                                       |
//+------------------------------------------------------------------+
void g_OnTick(CSymbol& s)
{

    //
    // generic part of algorithm processed per tick
    //
    
    // ticks to wait for processing pending orders
    bool bIsNewTick = false;
    s.g_tick_cnt++;
    if( s.g_tick_cnt >= ALGOSYNC_TOTAL_EVENTS )
    {
		bIsNewTick = true;
        s.g_tick_cnt = 0;
    }

    // seconds to wait for processing pending orders
    //  wait for at least one bar
    bool bIsNewTime = false;    
    if( (s.g_wait_time + ALGOSYNC_TOTAL_EVENTS*PeriodSeconds(s.PERIOD) ) < g_time_current )
    {
        // MathRand()%7 - 0 .. 6
        s.g_wait_time = g_time_current;
		bIsNewTime = true;
    }

    // check if there is a new bar
    // TODO implement ALGOSYNC_TOTAL_EVENTS here
	bool bIsNewBar = false;
	long v0 = iTickVolume(s.SYMBOL,s.PERIOD,0);
	if( v0 < s.g_v0prev ) 
	{
		bIsNewBar = true;
	}
	s.g_v0prev = v0;

    // if there is a new bar then log every new bar
    s.g_is_new_sync = m_AlgorithmIsNewSync(s, bIsNewBar, bIsNewTime, bIsNewTick );
    //dbg(s, "m_AlgorithmIsNewSync( IN: " + IntegerToString(bIsNewBar) + " "  + IntegerToString(v0) + " "  + IntegerToString(bIsNewTick) + " OUT: " + IntegerToString(s.g_is_new_sync) + " )" );
    if( true == s.g_is_new_sync )
    {
        // reset the volatility flag
        s.g_is_new_day = m_IsNewDay( s, g_time_local );
        if( true == s.g_is_new_day )
        {
            g_balance_start = AccountInfoDouble(ACCOUNT_BALANCE);
            // in the testermode count the days that we are trading for the statistic
            if( true == TESTERMODE )
            {
                if( 0 == s.g_test_day_cnt )
                {
                    s.g_test_balance_start = AccountInfoDouble(ACCOUNT_BALANCE);
                }
                MqlDateTime t;
                TimeToStruct(g_time_local,t);
                // trading is always allowed from Mon (1) to Fr (5) :  Sun => (0)
                //  in the time from 3rd of Jan until 22nd of December            
                if( (1 <= t.day_of_week) && (5 >= t.day_of_week) 
                 && (2<t.day_of_year) && (357>t.day_of_year) )
                {
                    s.g_test_day_cnt ++;
                }            
            } // if( true == TESTERMODE )
        
        } // if( true == m_IsNewDay( s, g_time_local ) )
        
    } // if( true == s.g_is_new_sync )

    // check if trading is allowed and for the TICKS EA trading is always allowed
    // TODO fix the function as it randomly does not seem to work
    // TODO fix me MQL2DLL 64-bit version
    bool ta = true;/*m_TradingAllowed(s);*/
    if( false == ta )
    {
        if( 0 < m_CntOrderTotalBySymbol( s ) )
        {
            m_RemovePendingOrders(s, "TRADING NOT ALLOWED" );
            Sleep(1000);
        }
        if( true == PositionSelect(s.SYMBOL) ) 
        {
            // TODO - document this properly
            // if this is zero, then do not close open positions
            // and just keep them open forever
            // and hence here work with the open positions
            // we need this here in case 
            // - the master stopped working
            // - there is only the slave left
            // - the perl script is broken as well 
            // - and somehow sends STOP or ERROR
            // that we still can serve the open positions
            if( 0 == OPEN_POSITION_CLOSE_TIME_MIN )
            {
                m_WorkWithPositions(s);
            }
            else
            {
                m_PositionClose(s, MAGIC_POSITION, g_computername + " TRADING NOT ALLOWED" );
                Sleep(1000);
            }
        }
        return;
    } // if( false == m_TradingAllowed(s) )

    //
    // algorithm start here
    //
    if( E_ALGORITHM_DEFAULT == g_algorithm )
    {
        // run the default algorithm here
        AlgorithmDefault( s );
    } 
    else if( E_ALGORITHM_CNT_DS == g_algorithm )
    {
        // run the Cnt_Ds algorithm here
        AlgorithmCntDs( s );
    } 
    else if( E_ALGORITHM_EXPERTWA == g_algorithm )
    {
        // run the WA algorithm here
        AlgorithmExpertWA( s );
    } 
    else if( E_ALGORITHM_EXPERTMA == g_algorithm )
    {
        // run the MA algorithm here
        AlgorithmExpertMA( s );
    } 
    else if( E_ALGORITHM_EXPERTVO == g_algorithm )
    {
        // run the Volatile algorithm here
        AlgorithmExpertVolatile( s );
    } 
    else if( E_ALGORITHM_TICKS == g_algorithm )
    {
        // run the ticks algorithm here
        AlgorithmTicks( s );
    } 
    else if( E_ALGORITHM_NORMALISE == g_algorithm )
    {
        // run the ticks algorithm here
        AlgorithmNormalise( s );
    } 
    else if( E_ALGORITHM_XLS == g_algorithm )
    {
        // run the ticks algorithm here
        AlgorithmXLS( s );
    } 
    else
    {
        if( 0 == g_onerror_cnt )
        {
            string log = "ERROR - Please implement the input string ALGORITHM = [" + ALGORITHM + "]";
            Log2Sql( s, "ERROR", -44, log );
        }
        g_onerror_cnt++;
    } // if( E_ALGORITHM_DEFAULT == g_algorithm )

} // int g_OnTick()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| AlgorithmTicks
//+------------------------------------------------------------------+
void AlgorithmTicks( CSymbol& s )
{

    // sanity check
    if( (true == USEDATABASE) && (true == GMYSQL_INIT_FAILED) ) return;

    // check that the timer doesn't run too long
    uint tc = GetTickCount();

    if( false == s.g_algo_ticks_init )
    {
        s.TICKCOUNT = GetTickCount();
        s.CVOL = 0;
        s.PREVVOL = 0;
        s.LASTBAR_M1  = iTime(s.SYMBOL,PERIOD_M1,0);
        s.LASTBAR_M5  = iTime(s.SYMBOL,PERIOD_M5,0);
        s.LASTBAR_M15 = iTime(s.SYMBOL,PERIOD_M15,0);
        s.LASTBAR_H1  = iTime(s.SYMBOL,PERIOD_H1,0);
        s.LASTBAR_H4  = iTime(s.SYMBOL,PERIOD_H4,0);
        s.LASTBAR_D1  = iTime(s.SYMBOL,PERIOD_D1,0);
        s.PREVASK = 0.0;
        s.PREVBID = 0.0;
        s.g_algo_ticks_init = true;
    } // if( false == g_algo_ticks_init )


    if( E_ALGOPARAM_TICKSNORMALISE == g_algoparam ) 
    {
        if( false == s.g_is_normalised )
        {
            // init normalise data
            for( int index = 0; index < N_INDEX_MAX; index ++ )
            {
                m_InitNormalise( s, g_time_local, index );
                m_DoNormalise  ( s, g_time_local, index, false /*aNewDayHasStarted*/ );
            }
            s.g_is_normalised = true;
return;            
        }
        else
        {
            /*if( true == m_IsNewDay2( s, g_time_local ) )
            {
                // normalise price data for NN and FFT
                m_InitNormalise( s, g_time_local, N_INDEX_M1 );
                m_DoNormalise  ( s, g_time_local, N_INDEX_M1,  true  );
                m_InitNormalise( s, g_time_local, N_INDEX_M5 );
                m_DoNormalise  ( s, g_time_local, N_INDEX_M5,  true  );
                m_InitNormalise( s, g_time_local, N_INDEX_M15 );
                m_DoNormalise  ( s, g_time_local, N_INDEX_M15, true  );
                
            } // if( true == m_IsNewDay2( s, g_time_local ) )
        
            if( true == m_IsNewYear2( s, g_time_local ) )
            {
                // normalise price data for NN and FFT
                m_InitNormalise( s, g_time_local, N_INDEX_H1 );
                m_DoNormalise  ( s, g_time_local, N_INDEX_H1, true   );
                m_InitNormalise( s, g_time_local, N_INDEX_H4 );
                m_DoNormalise  ( s, g_time_local, N_INDEX_H4, true   );
                m_InitNormalise( s, g_time_local, N_INDEX_D1 );
                m_DoNormalise  ( s, g_time_local, N_INDEX_D1, true   );
                
            } // if( true == m_IsNewYear2( s, g_time_local ) )*/
        } // if( false == s.g_is_normalised )
        
    } // if( E_ALGOPARAM_TICKSNORMALISE == g_algoparam ) 

    // main log function - it logs every tick, if configured to do so
    //if( (E_ALGOSYNC_TICK == g_algosync) && (1 == ALGOSYNC_TOTAL_EVENTS) )
    //{
    //    iLogTicks(s);
    //}    

    // if there is a new bar then log every new bar
    //if(true == s.g_is_new_sync )
    {

        //m_LogNewBar_M1(s);
        //m_LogNewBar_M5(s);
        //m_LogNewBar_M15(s);
        m_LogNewBar_H1(s);
        //m_LogNewBar_H4(s);
        //m_LogNewBar_D1(s);
        
    } // if(true == bIsNewSync)
    
        
    // check that the writing to the mysql server does not take too long
    uint diff = GetTickCount() - tc;
    if( diff > 300 ) {
        //dbg(s, "ERROR AlgorithmTicks runs for too long  DIFF[" + IntegerToString(diff) + "]  bIsNewSync[" + IntegerToString(s.g_is_new_sync) + "]" );
    }
   
} // void AlgorithmTicks( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| AlgorithmNormalise
//+------------------------------------------------------------------+
void AlgorithmNormalise( CSymbol& s)
{

    if(false == s.g_is_new_sync )
    {
return;
    }

    if( (false == s.g_is_normalised) && (false == s.g_is_new_day) )
    {
        // init normalise data
        int nind = m_GetNormtIndexFromTF(s.PERIOD);
        m_InitNormalise( s, g_time_local, nind );
        m_InitAlgoNormalise( s, nind );
        m_DoNormalise( s, g_time_local, nind, s.g_is_new_day );
        for( int i = 0; i < s.g_normalise[nind].shift_since_day_started; i++ )
        {
            m_DoAlgoNormalise2( s, i, s.g_is_new_day );
        }
        // the following line is set in m_DoNormalise function
        //s.g_is_normalised = true;
return;
    } // if( (false == s.g_is_normalised) && (false == s.g_is_new_day) )
       
    
    // check that the timer doesn't run too long
    uint tc = GetTickCount();

    // TODO NORM
    // TODO NORM - watch for overrun of shift_since_day_started 
    //   it shall not be null - it shall be at the end of the day 
    // TODO NORM - iTime(1 or 0)  normally it shall be zero
    //    as zero is the closing time
    // TODO NORM - iClose(1 or 0) normally it shall be one 
    //    but some places might have it assigned as zero 
    //    clean them up and bring them together 
    // TODO NORM - remove ADJUSTTIME
    datetime t0 = iTime(s.SYMBOL, s.PERIOD,0);
    if( true == ADJUSTTIME ){
        t0 = m_HourDec(t0);
    }
    int index = m_GetNormtIndexFromTF(s.PERIOD);
    s.g_normt.TM1[s.g_normalise[index].shift_since_day_started]  = t0;
    s.g_normt.INP2[s.g_normalise[index].shift_since_day_started] = iClose(s.SYMBOL, s.PERIOD, 1 );
    s.g_normt.INP1[s.g_normalise[index].shift_since_day_started] = m_Price2Neural( s, index, s.g_normt.INP2[s.g_normalise[index].shift_since_day_started] );
    m_DoAlgoNormalise2( s, s.g_normalise[index].shift_since_day_started, s.g_is_new_day );
    s.g_normalise[index].shift_since_day_started++;

    // check that the writing to the mysql server does not take too long
    uint diff = GetTickCount() - tc;
    if( diff > 300 ) {
        dbg(s, "ERROR AlgorithmNormalise runs for too long  DIFF[" + IntegerToString(diff) + "]  bIsNewSync[" + IntegerToString(s.g_is_new_sync) + "]" );
    }
   
} // void AlgorithmNormalise( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| AlgorithmDefault
//+------------------------------------------------------------------+
void AlgorithmDefault( CSymbol& s )
{
    // TODO WATCHER
    // options:
    //   REMOVEATSTARTUP
    //    - only use with care otherwise open positions will loose their
    //       opposite pending orders which act as SL to control losses
    //   REMOVEALLATSTARTUP
    //    - create new option which removes pending orders plus open positions
    // mysql database:
    //    FX_REPORT.EXPERT_LOG alter table
    //      rename field expert to computername
    //      field propkey usage: TICKS, WATCHER, or EXPERTPROPKEY  (ALGORITHM/ALGOPARAM)
    //      add fields balance, equity 
    //    FX_EURUSD alter table name
    //      expert_watcher_acckey_n  ->  expert_acckey
    //      expert_propkey_acckey_n  ->  expert_acckey
    //    FX_EURUSD.EXPERT_ACCKEY alter table
    //      add computername, balance, equity, swap, comission
    // orders:
    //    - check that opposite orders (BUY/SELL) have the same volumes
    // positions:
    //    - check that open positions might have lost their opposite pending orders
    //        so they might run for 24hours into huge losses
    //    - if open position the set event timer to 1ms to check for trailing stop
    //        otherwise the trailing stop will be checked every tick only 
    //          which might occur every couple of seconds only
    // system ok check:
    //    - check every second that tick is received, otherwise indicate error message

    //
    // TODO EXPERT
    // history:
    //   if IsNewDay then g_history_started = false
    //      to reset history and set the history_start date to new day
    //   the history_processor for multi-currency ea's do not work
    //      as the select the history by index and not by date
    //   investigate: 2014.11.19 10:19:25.574	EXPERT (EURUSD,M1)	ERROR retrieving orders from history
    // Print:
    //   convert all print statements to Log2Sql statements
    // MarketIsVolatile:
    //   "STEP_PEND_FIRST_POINT*0.75" should expire after new variable
    //   MARKET_VOLATILE_EXPIRY_TIME and be set back to "STEP_PEND_FIRST_POINT"
    // LOT BALANCE UPDATE:
    //   TODO implement a wait after g_OpenOrder to check if order has really been opened 
    //     important for LOT BALANCE UPDATE ERROR
    // 
    
    // every tick process the open positions
    m_WorkWithPositions(s);

    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(true == s.g_is_new_sync )
    {
    
        int first_pend_point =  (int)STEP_PEND_FIRST_POINT;
        double open_price = m_CalcOpenPrice(s);

        /*
        //
        // 20230709 TODO understand me - how to set parameters, that this will work
        //
        // set the volatility flag
        string log;
        double pivot; int wa; int wa2;
        bool market_is_volatile = iMarketIsVolatile(s,log,pivot,wa,wa2);
        if( true == market_is_volatile )
        {
          Log2Sql( s, "MARKET", 0, log );
          open_price =  pivot; 
          
          if( false == PositionSelect(s.SYMBOL) ) 
          {
              // remove the existing remaining pending orders if the market is volatile
              m_RemovePendingOrders(s, "ISVOLATILE CANCEL PENDING");
          }
        }
        else
        {
          // do not open a pending order if the market is not volatile
          return;
        } // if( true == market_is_volatile )*/
          
        
    	// if there is no open position, then create a new pending order or modfiy them
        if( false == PositionSelect(s.SYMBOL) ) 
        {
            int pend_num = STEP_PEND_NUMBER;
            // TODO 20230711 understand me
            /*double lot = 0.0;           
            if( false == m_Calculate_Lot(s,lot,pend_num) )
            {
                return;
            }*/
            double lot = 0.01;
            
            // either create a new one if none exists, or modify the price of the existing one
            if( E_ALGODIRECTION_STOP == g_algodirection )
            {
                ////lot = 0.01;
                //first_pend_point = 100;
                //k_step_pend_point = 100;
                //pend_num = 1;
                m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_STOP, open_price, lot, first_pend_point, k_step_pend_point, pend_num );
            }
            else
            {
                m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_LIMIT,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_LIMIT, open_price, lot, first_pend_point, k_step_pend_point, pend_num );
            }
        } // if( false == PositionSelect(SYMBOL) )
    
    } // if( true == bIsNewSync )
    
} // void AlgorithmDefault( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| void AlgorithmCntDs( CSymbol& s )
//+------------------------------------------------------------------+
void AlgorithmCntDs( CSymbol& s )
{

    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(false == s.g_is_new_sync )
    {
        return;
    }
    
    //m_WorkWithPositions(s);
    if( true == PositionSelect(s.SYMBOL)) {
    
        s.m_order_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        s.m_order_current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
        s.m_order_profit=PositionGetDouble(POSITION_PROFIT);
        s.m_order_type       = (int)PositionGetInteger(POSITION_TYPE);
        s.m_order_time = (datetime)PositionGetInteger(POSITION_TIME);
        s.m_order_volume = PositionGetDouble(POSITION_VOLUME);
        s.m_position_id = PositionGetInteger(POSITION_IDENTIFIER);
        //double vol = PositionGetDouble(POSITION_VOLUME);
        //double sl=PositionGetDouble(POSITION_SL);
        //double tp=PositionGetDouble(POSITION_TP);
        double price_diff_in_points1 = 0;
        double price_diff_in_points2 = 0;
        if(s.m_order_type==POSITION_TYPE_BUY)
        {
            //if( -1 > s.m_order_profit )
            //    m_PositionClose(s,1231,"CLOSE s.m_order_loss",true);        
            /*
            //if( 1 < s.m_order_profit )
            //    m_PositionClose(s,1231,"CLOSE s.m_order_profit",true);        
            price_diff_in_points1 = (s.m_order_current_price - s.m_order_open_price)/s.POINT; 
            if( 30 < price_diff_in_points1 )
                m_PositionClose(s,1231,"CLOSE price_diff_in_points1",true);        
            */      
            price_diff_in_points2 = (s.m_order_open_price - s.m_order_current_price)/s.POINT;
            if( 30 < price_diff_in_points2 )
                m_PositionClose(s,1231,"CLOSE price_diff_in_points2",true);  
        }// end POSITION_TYPE_BUY    
        else if(s.m_order_type==POSITION_TYPE_SELL)
        {
            //if( -1 > s.m_order_profit )
            //    m_PositionClose(s,4561,"CLOSE s.m_order_loss",true);        
            /*
            //if( 1 < s.m_order_profit )
            //    m_PositionClose(s,4561,"CLOSE s.m_order_profit",true);        
            price_diff_in_points1 = (s.m_order_open_price - s.m_order_current_price)/s.POINT;
            if( 30 < price_diff_in_points1 )
                m_PositionClose(s,4561,"CLOSE price_diff_in_points1",true);        
            */   
            price_diff_in_points2 = (s.m_order_current_price - s.m_order_open_price)/s.POINT; 
            if( 30 < price_diff_in_points2 )
                m_PositionClose(s,4561,"CLOSE price_diff_in_points2",true);    
        }// end POSITION_TYPE_SELL
    
    } // if( true == PositionSelect(s.SYMBOL)) */
    

    double bal = 0;
    double equ = 0;

    if( true == TESTERMODE )
    {
        MqlDateTime t;
        TimeToStruct(g_time_local,t);
        /*if( HOURSTART > t.hour ) {
            if( true == PositionSelect(s.SYMBOL) ) 
                m_PositionClose(s,444,"outside hours",true);
            return;
        }*/
        /*if( (HOURSTART+1) < t.hour ) {
            if( true == PositionSelect(s.SYMBOL) ) 
                m_PositionClose(s,666,"outside hours",true);
            return;
        }*/
        
    } // if( true == TESTERMODE )

    MqlTick _t;
    if(SymbolInfoTick(s.SYMBOL, _t))
    {

    
        int size = 0;
        MqlTick array[];
        uint gCopyTicksFlags = COPY_TICKS_INFO; // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL
        //int size1    = CopyTicksRange(_Symbol, array, gCopyTicksFlags, (TimeCurrent() - nS1   ) * 1000, (TimeCurrent() - 0) * 1000 );
        //int size1   = CopyTicks(_Symbol, array, gCopyTicksFlags, 0, nS1 );
        int size1   = CopyTicks(s.SYMBOL, array, gCopyTicksFlags, 0, 100 );
        int oc1   = 0;
        int hl1   = 0;
        long delta_msc1 = 0;
        ExtractHighLowFromMqlTickArray( array, oc1, hl1, delta_msc1 );
        double cnt_ds = -100;
        if( 0 != delta_msc1)
            cnt_ds = (int)(-100+((double)size1/delta_msc1*1000)*20);

        int size2   = CopyTicks(s.SYMBOL, array, gCopyTicksFlags, 0, 1000 );
        int oc2   = 0;
        int hl2   = 0;
        long delta_msc2 = 0;
        ExtractHighLowFromMqlTickArray( array, oc2, hl2, delta_msc2 );

        int size3   = CopyTicks(s.SYMBOL, array, gCopyTicksFlags, 0, 10000 );
        int oc3   = 0;
        int hl3   = 0;
        long delta_msc3 = 0;
        ExtractHighLowFromMqlTickArray( array, oc3, hl3, delta_msc3 );
       
        int oc1_avg = (oc1+oc2+oc3)/3;

        if( false == g_balance_reached )
        {
            //if( 0 < cnt_ds )
                if( 1 < oc3 ||  -1 > oc3 )
                //if( 30 < oc1_avg ||  -30 > oc1_avg )
                {
                    if( 0 < oc3 )
                        m_PositionOpenBuy(s,0.01);            
                    else
                        m_PositionOpenSell(s,0.01);            
                    
                }
    
            /*if( 10 < oc1 )
            {
                if( 0 > cnt_ds )
                    m_PositionOpenBuy(s,0.01);            
            }
            if( -10 > oc1 )
            {
                
                if( 0 > cnt_ds )
                    m_PositionOpenSell(s,0.01);            
            }*/
            
            /*if( 10 < oc1 )
            {
                if( 0 < cnt_ds )
                    m_PositionOpenBuy(s,0.01);
                else            
                    m_PositionOpenSell(s,0.01);            
            }
            if( -10 > oc1 )
            {
                
                if( 0 < cnt_ds )
                    m_PositionOpenSell(s,0.01);
                else            
                    m_PositionOpenBuy(s,0.01);            
            }*/
    
            /*if( 10 < oc1 )
            {
                //m_PositionOpenBuy(s,0.01);
                m_PositionOpenSell(s,0.01);            
            }
            if( -10 > oc1 )
            {
                //m_PositionOpenSell(s,0.01);
                m_PositionOpenBuy(s,0.01);            
            }*/

        } // if( false == g_balance_reached )
            
        double price  = NormalizeDouble((_t.ask + _t.bid )/2, s.DIGITS);
        int spread = (int)((_t.bid - _t.ask)/s.POINT);
        double o0 = iOpen(s.SYMBOL,PERIOD_D1,0);
        double oc = NormalizeDouble((price - o0)/s.POINT, 0);
        double vol = 0;
        double profit = 0;
        string stype = "     ";
        datetime order_time_delta = 0;
        double order_price_delta = 0;
        if( true == PositionSelect(s.SYMBOL) ) 
        {
            vol = s.m_order_volume;
            profit = s.m_order_profit;
            order_time_delta = (TimeCurrent() - s.m_order_time);
            order_price_delta = (s.m_order_open_price - s.m_order_current_price)/s.POINT;
            if(s.m_order_type==POSITION_TYPE_BUY)
            {
                stype = "BUY  ";
            }// end POSITION_TYPE_BUY    
            else if(s.m_order_type==POSITION_TYPE_SELL)
            {
                stype = "SELL ";
            }// end POSITION_TYPE_SELL
            
        } // if( true == PositionSelect(s.SYMBOL) ) 
          
          
        equ = AccountInfoDouble(ACCOUNT_EQUITY);
        bal = AccountInfoDouble(ACCOUNT_BALANCE);
        if( false == g_balance_reached )
        {
            if( equ > 2.02 * g_balance_start ) 
            {
                g_balance_reached = true;
                m_PositionClose(s,888,"balance reached",true);
            }
        } 
        else 
        {
            if( true == PositionSelect(s.SYMBOL) ) 
                m_PositionClose(s,999,"balance reached error",true);
            // no more log output here
            return;
        } // if( false == g_balance_reached )
              
        string log =  StringFormat( "%s v:%0.2f b:%5.2f/e:%5.2f p:%s  oc:%6d  s:%6d  t: %6d  d: %6d %+0.2f  oc1: %6d %6d %6d %6d  hl1: %6d  dmsc1: %6d  cnt_ds: %6d",
                                                stype, 
                                                vol,
                                                bal,
                                                equ,
                                                nds(s,price,s.DIGITS),
                                                (int)oc,
                                                spread,
                                                (int)order_time_delta,
                                                (int)order_price_delta,
                                                s.m_order_profit,
                                                oc1_avg,
                                                oc1,
                                                oc2,
                                                oc3,
                                                hl1,
                                                delta_msc1,
                                                (int)cnt_ds 
                                                );
        dbg( log );
                
    } // if(SymbolInfoTick(s.SYMBOL, _t))

    
} // void AlgorithmCntDs( CSymbol& s )
//+------------------------------------------------------------------+
 
 
//+------------------------------------------------------------------+
//| AlgorithmXLS
//+------------------------------------------------------------------+
void AlgorithmXLS( CSymbol& s )
{

    
    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(true == s.g_is_new_sync )
    {
    
        CSVTable_Sig_or_Exe t02Sigx[];
        long                t0 = (long)iTime(s.SYMBOL, s.PERIOD,0);
        int                 t0_index = -1;
        long                lret_last_t0 = 0;
        
        if( 0 == t0 )
        {
            return;
        }

        if( t0 != s.g_01_CSV_t0 ) 
        {
            m_update_01_CSV( s );
            // s.g_t0_01_Csv = t0; will be updated inside m_update_01_CSV
        } // if( t0 != s.g_t0_01_Csv ) 

        // H1  - do not start before 4AM on Monday
        //       with other stuff than CSV writing
        if( false == m_TradingTimeAllowed( t0 ) ) {
            return;
        }

        if( (t0 != s.g_03_EXE_t0) && (t0 == s.g_01_CSV_t0) ) 
        {
            // read t0 position from 02_SIGx and return t0_index of t02Sigx once available
            lret_last_t0 = m_Read_SIG_or_EXE_CSV_File(s.g_02_SIGx_fN, t02Sigx, t0, t0_index );
            if( (0 <= t0_index) && (0 < lret_last_t0) ) {
            
                CSVTable_Sig_or_Exe t02Exes;
                //  execute t02Sigx[t0_index] and return exe results in t02Exes
                bool bRet = m_execute_SIG_from_CSV( s, t02Sigx[t0_index], t02Exes );
                if( true == bRet ) {
                    // everything is fine
                } else {
                    // TODO implement some error handling here
                } // if( true == bRet )
                
                // update exe results t02Exes into file 03_EXEx and into file 03_EXEs CSV files
                //m_update_03_EXE  ( s, t0, t02Exes );
                m_update_03_EXE_2( s, t0/*, t02Exes*/ );
            
            } else {
                // TODO implement some BIG handling here
                dbg(s, "XXX ERR XXX  t0: " + IntegerToString(t0) + " t0_index: " + IntegerToString(t0_index) + " lret_last_t0: " + IntegerToString(lret_last_t0) );
            } // if( (0 < t0_index) && (0 < lret_last_t0) )

        } // if( (t0 != s.g_t0_03_Exe) && (t0 == s.g_t0_01_Csv) ) 
    
    } // if( true == bIsNewSync )
    
} // void AlgorithmXLS( CSymbol& s )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| AlgorithmExpertVolatile
//+------------------------------------------------------------------+
void AlgorithmExpertVolatile( CSymbol& s )
{

    if( (E_ALGOPARAM_SLDF == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
    {
        if( true == s.iCalcNewTick() ) {
            s.g_avg_ticks_ask = iCustPriceDF(s,0,I_PRICE_TICK_ASK,0);
            s.g_avg_ticks_bid = iCustPriceDF(s,0,I_PRICE_TICK_BID,0);
        } else {
        // TODO what happens if you got to wait for 100 new ticks after ea restart during working hours
        //      in that case no SL could be applied as the ASK/BID price (DF digital filter) could 
        //      not be calculated
            //return;        
        }
    }
    
    // every tick process the open positions
    m_WorkWithPositions(s);
    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(true == s.g_is_new_sync )
    {
        // set the volatility flag
        datetime dt = iTime(s.SYMBOL,s.PERIOD,0);
        if( (0!=s.g_market_is_volatile_time)&&(dt != s.g_market_is_volatile_time) )
        {
            s.g_market_is_volatile_time = 0;
        }
        string log; double pivot; int wa; int wa2;
        bool market_is_volatile = false;
        // set shift default value
        int shift = 1;
        // if we analase every tick then set shift to zero
        if( E_ALGOSYNC_TICK == g_algosync )
        {
            shift = 0;
        }
        market_is_volatile = iMarketIsVolatile(s,log,pivot,wa,wa2,shift);
        if( false == market_is_volatile )
        {
return;        
        }
        if( 0 != s.g_market_is_volatile_time )
        {
return;        
        }
        s.g_market_is_volatile_time = dt;
        
        Log2Sql( s, "MARKET", 0, log );
        m_log_history_to_sql(   s, "ABC_O", g_time_local,
                                g_time_current*1000,g_time_current,
                                0,0,"ORDER_TYPE_TRIGGER","ORDER_PEND_TRIGGER",
                                0,pivot,0.0,0.0,0.0,0.0,
                                log,
                                ""
                            );
        
        int pend_num = STEP_PEND_NUMBER;
        double lot = 0.0;
        int first_pend_point =  (int)STEP_PEND_FIRST_POINT;
        double open_price = pivot;
        
        if( E_ALGODIRECTION_BUY == g_algodirection )
        {
            if( false == m_Calculate_Lot(s,lot,pend_num) )
            {
return;
            }
            if( STEP_PEND_FIRST_POINT < wa )
            {
                bool buy  = false;
                bool sell = false;
                if( 0 < wa2 )
                {
                    buy = true;
                }
                if( 0 > wa2 )
                {
                    sell = true;
                }
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                    if( true == buy  ) m_PositionOpenBuy(s,lot);
                    if( true == sell ) m_PositionOpenSell(s,lot);
                }
                else
                {
                    if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
                    {
                        //if( true == buy  ) m_PositionOpenBuy(s,lot);//
                        if( true == sell ) m_PositionClose(s,123,"CLOSE",true);
                        if( true == sell ) m_PositionOpenSell(s,lot);
                    }

                    if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
                    {
                        if( true == buy  ) m_PositionClose(s,123,"CLOSE",true);
                        if( true == buy  ) m_PositionOpenBuy(s,lot);
                        //if( true == sell ) m_PositionOpenSell(s,lot);//
                    }
                    
                }
            }
        }
        else if( E_ALGODIRECTION_SELL == g_algodirection )
        {
            if( false == m_Calculate_Lot(s,lot,pend_num) )
            {
return;
            }
            if( STEP_PEND_FIRST_POINT < wa )
            {
                bool buy  = false;
                bool sell = false;
                if( 0 < wa2 )
                {
                    sell = true;
                }
                if( 0 > wa2 )
                {
                    buy = true;
                }
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                    if( true == buy  ) m_PositionOpenBuy(s,lot);
                    if( true == sell ) m_PositionOpenSell(s,lot);
                }
                else
                {
                    if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
                    {
                        if( true == buy  ) m_PositionOpenBuy(s,lot);//
                        if( true == sell ) m_PositionClose(s,123,"CLOSE",true);
                        if( true == sell ) m_PositionOpenSell(s,lot);
                    }

                    if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
                    {
                        if( true == buy  ) m_PositionClose(s,123,"CLOSE",true);
                        if( true == buy  ) m_PositionOpenBuy(s,lot);
                        if( true == sell ) m_PositionOpenSell(s,lot);//
                    }
                    
                }
            }
        } 
        else if( E_ALGODIRECTION_STOP == g_algodirection )
        {
            if( false == PositionSelect(s.SYMBOL) ) 
            {
                // either create a new one if none exists, or modify the price of the existing one
                m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_STOP, open_price, lot, first_pend_point, k_step_pend_point, pend_num );
            } // if( false == PositionSelect(s.SYMBOL) ) 
        }
        else if( E_ALGODIRECTION_LIMIT == g_algodirection )
        {
            if( false == PositionSelect(s.SYMBOL) ) 
            {
                // remove the existing remaining pending orders if the market is volatile
                // TODO make this an option
                m_RemovePendingOrders(s, "ISVOLATILE CANCEL PENDING");
                if( false == m_Calculate_Lot(s,lot,pend_num) )
                {
return;
                }
                // either create a new one if none exists, or modify the price of the existing one
                m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_LIMIT,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_LIMIT, open_price, lot, first_pend_point, k_step_pend_point, pend_num );
            } // if( false == PositionSelect(s.SYMBOL) ) 
        } // if( E_ALGODIRECTION_BUY == g_algodirection )  
            
            
    } // if( true == bIsNewSync )
    
} // void AlgorithmExpertVolatile( CSymbol& s, bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick )
//+------------------------------------------------------------------+


//=====================================================================
//	External parameters:
//=====================================================================
/*input*/ int							 CCI1_Period = 3;
/*input*/ int							 CCI2_Period = 56;
/*input*/ int							 CCI3_Period = 56;
/*input*/ int							 RSI1_Period = 14;
/*input*/ int                            ATR1_Period = 1;
/*input*/ int                            ATRX_Period = 240;
/*input*/ ENUM_APPLIED_PRICE	         CCI_Price_Type = PRICE_TYPICAL;
/*input*/ int                            CCI_lvl     = 99;
/*input*/ int                            RSI_lvl     = 5;
/*input*/ double                         ATR_lvl     = 0.0003;
/*input*/ int                            ATRX_lvl    = 300;

static int firsttimebuy = false;
static int firsttimesell = false;
//---------------------------------------------------------------------

//+------------------------------------------------------------------+
//| AlgorithmExpertWA
//+------------------------------------------------------------------+
void AlgorithmExpertWA( CSymbol& s  )
{



    // every tick process the open positions
    m_WorkWithPositions(s);

    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(true == s.g_is_new_sync )
    {
        int first_pend_point =  (int)(STEP_PEND_FIRST_POINT+s.SPREADPOINTS/2);
        double open_price = m_CalcOpenPrice(s);
        int pend_num = STEP_PEND_NUMBER;
        double lot = 0.0;
        /*if( false == m_Calculate_Lot(s,lot,pend_num) )
        {
            return;
        }*/
        lot = 1;
        datetime t0 = iTime(s.SYMBOL, s.PERIOD,0);
        if( true == ADJUSTTIME ){
            t0 = m_HourDec(t0);
        }
        
        bool buyflag = false;
        bool sellflag = false;
        double CCI_buy = +1*CCI_lvl;
        double RSI_buy = 50+RSI_lvl;
        double CCI_sell = -1*CCI_lvl;
        double RSI_sell = 50-RSI_lvl;
        
        double max=iHigh(s.SYMBOL,s.PERIOD,iHighest(s.SYMBOL,s.PERIOD,MODE_HIGH,ATRX_Period,1));
        double min=iLow(s.SYMBOL,s.PERIOD,iLowest(s.SYMBOL,s.PERIOD,MODE_LOW,ATRX_Period,1));
        double ATRX = (max-min)/Point();
        double CCI1 = iCustPrice(s,CCI1_Period,I_PRICE_CCI,1);
        double CCI2 = iCustPrice(s,CCI2_Period,I_PRICE_CCI,1);
        double CCI3 = iCustPrice(s,CCI3_Period,I_PRICE_CCI,1);
        double RSI1 = iCustPrice(s,RSI1_Period,I_PRICE_RSI,1);
        double ATR1 = iCustPrice(s,ATR1_Period,I_PRICE_ATR,1);
        
        //if( false == firsttimebuy )
        if(    (CCI_buy<CCI1) && (CCI_buy<CCI2) && (CCI_buy<CCI3) 
            && (RSI_buy<RSI1)  
            && (ATR_lvl<ATR1) 
            && (ATRX_lvl<ATRX) 
            )
        {
            buyflag = true;
            firsttimebuy = true;
            firsttimesell = false;
        }
        //if( false == firsttimesell )
        if(    (CCI_sell>CCI1) && (CCI_sell>CCI2) && (CCI_sell>CCI3) 
            && (RSI_sell>RSI1)  
            && (ATR_lvl<ATR1) 
            && (ATRX_lvl<ATRX) 
            )
        {
            sellflag = true;
            firsttimebuy = false;
            firsttimesell = true;
        }
        
        
        bool mod_order = false;
        if( true == buyflag )
        {
            dbg(s, "    " );
            dbg(s, "BUY:     " + TimeToString(t0, TIME_DATE|TIME_SECONDS) + " LOT: " + nds(s,lot,2) + " OPENP: " + nds(s,open_price) + 
                   " ATRX: " + nds(s,ATRX,0) + " ATR1: " + nds(s,ATR1,5)  + " RSI1: " + nds(s,RSI1,1) +
                   " CCI1: " + nds(s,CCI1,0) + " CCI2: " + nds(s,CCI2,0) + " CCI3: " + nds(s,CCI3,0) );
                   
            if( E_ALGODIRECTION_STOP == g_algodirection )                
            {
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                   m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_LIMIT == g_algodirection )                
            {
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                    m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_LIMIT,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_BUY == g_algodirection )                
            {
                m_PositionOpenBuy(s,lot);
            }
            else if( E_ALGODIRECTION_SELL == g_algodirection )                
            {
                m_PositionOpenSell(s,lot);
            } // if( E_ALGODIRECTION_STOP == g_algodirection ) 
            mod_order = true;
        } 
        else if( true == sellflag )
        {
            dbg(s, "    " );
            dbg(s, "SELL:    " + TimeToString(t0, TIME_DATE|TIME_SECONDS) + " LOT: " + nds(s,lot,2) + " OPENP: " + nds(s,open_price) + 
                   " ATRX: " + nds(s,ATRX,0) + " ATR1: " + nds(s,ATR1,5)  + " RSI1: " + nds(s,RSI1,1) +
                   " CCI1: " + nds(s,CCI1,0) + " CCI2: " + nds(s,CCI2,0) + " CCI3: " + nds(s,CCI3,0) );
            
            if( E_ALGODIRECTION_STOP == g_algodirection )                
            {
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                   m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_LIMIT == g_algodirection )                
            {
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                    m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_LIMIT,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_BUY == g_algodirection )                
            {
                m_PositionOpenSell(s,lot);
            }
            else if( E_ALGODIRECTION_SELL == g_algodirection )                
            {
                m_PositionOpenBuy(s,lot);
            } // if( E_ALGODIRECTION_STOP == g_algodirection )                
            mod_order = true;
        } // else if( (c0 < ma3) && (ma3 < ma14) && (ma14 < ma55) )
        else
        {
            dbg(s, "WAS :    " + TimeToString(t0, TIME_DATE|TIME_SECONDS) + " LOT: " + nds(s,lot,2) + " OPENP: " + nds(s,open_price) + 
                   " ATRX: " + nds(s,ATRX,0) + " ATR1: " + nds(s,ATR1,5)  + " RSI1: " + nds(s,RSI1,1) +
                   " CCI1: " + nds(s,CCI1,0) + " CCI2: " + nds(s,CCI2,0) + " CCI3: " + nds(s,CCI3,0) );
            
        } // if( true == buyflag )
        
    } // if( true == bIsNewSync )
    

} // void AlgorithmExpertWa( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick  )
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| AlgorithmExpertMA
//+------------------------------------------------------------------+
void AlgorithmExpertMA2( CSymbol& s  )
{

    // every tick process the open positions
    m_WorkWithPositions(s);

    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(true == s.g_is_new_sync )
    {
        int first_pend_point =  (int)(STEP_PEND_FIRST_POINT+s.SPREADPOINTS/2);
        double open_price = m_CalcOpenPrice(s);
        int pend_num = STEP_PEND_NUMBER;
        double lot = 0.0;
        double profit = 0;
        double order_price = 0;
        double order_lot = 0;
        int shift = 1;
        string stext = " ";
        double cci0 = iCustPrice(s,STEP_PEND_FIRST_POINT, I_PRICE_CCI, 0+shift);
        double cci1 = iCustPrice(s,STEP_PEND_FIRST_POINT, I_PRICE_CCI, 1+shift);

        if( true == PositionSelect(s.SYMBOL) ) 
        {
            profit = PositionGetDouble(POSITION_PROFIT);
            order_price = PositionGetDouble(POSITION_PRICE_OPEN);
            order_lot = PositionGetDouble(POSITION_VOLUME);
            if( POSITION_TYPE_BUY == (int)PositionGetInteger(POSITION_TYPE) )
            {
                if( (100 > cci0) && ( 0 < profit) )
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " CCI BELOW" );
                    Sleep(1000);
return;                    
                }
            }
            if( POSITION_TYPE_SELL == (int)PositionGetInteger(POSITION_TYPE) )
            {
                if( (-100 < cci0) && ( 0 < profit) )
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " CCI BELOW" );
                    Sleep(1000);
return;                    
                }
            }
        } // if( true == PositionSelect(s.SYMBOL) ) 
        
        
        double ma3    = iCustPrice(s,3,  I_PRICE_MA,0+shift);
        double ma14   = iCustPrice(s,14, I_PRICE_MA,0+shift);
        double ma55   = iCustPrice(s,144,I_PRICE_MA,0+shift);
        double ma3_1  = iCustPrice(s,3,  I_PRICE_MA,1+shift);
        double ma14_1 = iCustPrice(s,14, I_PRICE_MA,1+shift);
        double ma55_1 = iCustPrice(s,144,I_PRICE_MA,1+shift);


        double m1_0 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,0+shift);
        double m1_1 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,1+shift);

        double m5_0 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,0+shift);
        double m5_1 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,5+shift);

        double m15_0 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,0+shift);
        double m15_1 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,15+shift);

        double h1_0 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,0+shift);
        double h1_1 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,60+shift);

        double h4_0 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,0+shift);
        double h4_1 = iCustPrice(s,STEP_PEND_FIRST_POINT,  I_PRICE_MA,240+shift);
        
        
        double   c0 = iClose(s.SYMBOL, s.PERIOD,1);
        double   o0 = iOpen (s.SYMBOL, s.PERIOD,0);
        datetime t0 = iTime (s.SYMBOL, s.PERIOD,0);
        if( true == ADJUSTTIME ){
            t0 = m_HourDec(t0);
        }
        
        bool buyflag = false;
        //if( (( ma3 > ma14 ) && ( ma14 > ma55 )) && ( ma3_1 < ma14_1 ) )
        //if( ( ma3 > ma14 ) && ( ma3_1 < ma14_1 ) && ( 0 < cci0 ) )
        //if( ( ma3 > ma55 ) && ( ma3_1 < ma55_1 ) )
        if( ( m1_0 > m1_1 ) && ( m5_0 > m5_1 ) && ( m15_0 > m15_1 ) && ( h1_0 > h1_1 ) && ( h4_0 > h4_1 ) )
        {
            buyflag = true;
        }

        bool sellflag = false;
        // if( (( ma3 < ma14 ) && ( ma14 < ma55 )) && ( ma3_1 > ma14_1 ) )
        //if( ( ma3 < ma14 ) && ( ma3_1 > ma14_1 ) && ( 0 > cci0 ) )
        //if( ( ma3 < ma55 ) && ( ma3_1 > ma55_1 )  )
        if( ( m1_0 < m1_1 ) && ( m5_0 < m5_1 ) && ( m15_0 < m15_1 ) && ( h1_0 < h1_1 ) && ( h4_0 < h4_1 ) )
        {
            sellflag = true;
        }

        /*int num_pos = PositionSelect( s.SYMBOL );
        if( 0 < num_pos )
        {
            buyflag = false;
            sellflag = false;
        }*/

        if( true == buyflag )
        {
            if( E_ALGODIRECTION_STOP == g_algodirection )                
            {
                // remove the existing remaining pending orders if the market is volatile
                // TODO make this an option
                m_RemovePendingOrders(s, "ISVOLATILE CANCEL PENDING");
                if( false == m_Calculate_Lot(s,lot,pend_num) )
                {
                    return;
                }
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                   m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_LIMIT == g_algodirection )                
            {
                // remove the existing remaining pending orders if the market is volatile
                // TODO make this an option
                m_RemovePendingOrders(s, "ISVOLATILE CANCEL PENDING");
                if( false == m_Calculate_Lot(s,lot,pend_num) )
                {
                    return;
                }
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                    m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_LIMIT,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_BUY == g_algodirection )                
            {
                if( POSITION_TYPE_SELL == (int)PositionGetInteger(POSITION_TYPE) )
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " MA CLOSE" );
                    Sleep(1000);
                }
                if( 0 < cci0 )
                {
                    if( false == m_Calculate_Lot(s,lot,pend_num) )
                    {
                        return;
                    }
                    m_PositionOpenBuy(s,lot);
                }
                else
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " CCI CLOSE" );
                    Sleep(1000);
                }
            }
            else if( E_ALGODIRECTION_SELL == g_algodirection )                
            {
                if( POSITION_TYPE_BUY == (int)PositionGetInteger(POSITION_TYPE) )
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " MA CLOSE" );
                    Sleep(1000);
                }
                if( 0 > cci0 )
                {
                    if( false == m_Calculate_Lot(s,lot,pend_num) )
                    {
                        return;
                    }
                    m_PositionOpenSell(s,lot);
                }
                else
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " CCI CLOSE" );
                    Sleep(1000);
                }
            } // if( E_ALGODIRECTION_STOP == g_algodirection ) 
            
            stext = "BUY:     ";
            
        } 
        else if( true == sellflag )
        {
            
            if( E_ALGODIRECTION_STOP == g_algodirection )                
            {
                // remove the existing remaining pending orders if the market is volatile
                // TODO make this an option
                m_RemovePendingOrders(s, "ISVOLATILE CANCEL PENDING");
                if( false == m_Calculate_Lot(s,lot,pend_num) )
                {
                    return;
                }
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                   m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_LIMIT == g_algodirection )                
            {
                // remove the existing remaining pending orders if the market is volatile
                // TODO make this an option
                m_RemovePendingOrders(s, "ISVOLATILE CANCEL PENDING");
                if( false == m_Calculate_Lot(s,lot,pend_num) )
                {
                    return;
                }
            	// if there is no open position, then create a new pending order or modfiy them
                if( false == PositionSelect(s.SYMBOL) ) 
                {
                    m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_LIMIT,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                } // if( false == PositionSelect(SYMBOL) )
            } 
            else if( E_ALGODIRECTION_BUY == g_algodirection )                
            {
                if( POSITION_TYPE_BUY == (int)PositionGetInteger(POSITION_TYPE) )
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " MA CLOSE" );
                    Sleep(1000);
                }
                if( 0 > cci0 )
                {
                    if( false == m_Calculate_Lot(s,lot,pend_num) )
                    {
                        return;
                    }
                    m_PositionOpenSell(s,lot);
                }
                else
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " CCI CLOSE" );
                    Sleep(1000);
                }
            }
            else if( E_ALGODIRECTION_SELL == g_algodirection )                
            {
                if( POSITION_TYPE_SELL == (int)PositionGetInteger(POSITION_TYPE) )
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " MA CLOSE" );
                    Sleep(1000);
                }
                if( 0 < cci0 )
                {
                    if( false == m_Calculate_Lot(s,lot,pend_num) )
                    {
                        return;
                    }
                    m_PositionOpenBuy(s,lot);
                }
                else
                {
                    m_PositionClose(s, MAGIC_POSITION, g_computername + " CCI CLOSE" );
                    Sleep(1000);
                }
            } // if( E_ALGODIRECTION_STOP == g_algodirection )                
            
            stext = "SELL:    ";
        } 
        else
        {
            stext = "WAS :    ";
        } // if( true == buyflag )
        
        if( true == PositionSelect(s.SYMBOL) ) 
        {
            profit = PositionGetDouble(POSITION_PROFIT);
            order_price = PositionGetDouble(POSITION_PRICE_OPEN);
            order_lot = PositionGetDouble(POSITION_VOLUME);
        }
        double bal = AccountInfoDouble(ACCOUNT_BALANCE);
        //double equ = AccountInfoDouble(ACCOUNT_EQUITY);
        double margin = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        double pdiff = MathAbs( open_price - order_price ) / s.POINT;
        dbg(s, stext + TimeToString(t0, TIME_DATE|TIME_SECONDS) + " MA3: " + nds(s,ma3,4) + " MA14: " + nds(s,ma14,4)  + " MA55: " + nds(s,ma55,4) + " CCI0: " + nds(s,cci0,2)  + " CCI1: " + nds(s,cci1,2) + " LOT: " + nds(s,order_lot,2) + " P: " + nds(s,open_price) + " OP: " + nds(s,order_price) + " BAL: " + nds(s,bal,2) + " PROFIT: " + nds(s,profit,2) + " PDIFF: " + IntegerToString((int)pdiff) );
        
    } // if( true == bIsNewSync )
    

} // void AlgorithmExpertMa( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick  )
//+------------------------------------------------------------------+









































//+------------------------------------------------------------------+
void AlgorithmExpertMA( CSymbol& s  )
{

    // every tick process the open positions, if position is in profit
    //                    SL_PROFITS           SL_LOSSES
    //m_WorkWithPositions(s,E_WWP_TRAILING_STOP, E_WWP_NO_SL );
    //m_WorkWithPositions(s,E_WWP_TRAILING_STOP, E_WWP_SL_POINTS );
    //m_WorkWithPositions(s,SL_PROFITS, SL_LOSSES );
    
    //m_WorkWithPositions2(s,SL_PROFITS, SL_LOSSES );

    /*if( true == TESTERMODE )
    {
        m_GetWatcherData(s);
        m_LogWatcherData(s,true);
    }*/
    
    // if there is a new time then work with pending orders
    //   meaning either create them or modify them
    if(true == s.g_is_new_sync )
    {
        if( false == TESTERMODE )
        {
            m_GetWatcherData(s);
            m_LogWatcherData(s,true);
        }
                
        //if( ( 20 <= s.g_watcher_data.accprofit ) || ( -20 >= s.g_watcher_data.accprofit ) )
        if( 0 < s.g_watcher_data.accprofit ) 
        {
            if( s.g_watcher_data.accprofit < 3*s.g_watcher_data.stat_avg )
            {
                //m_PositionClose(s, MAGIC_POSITION, "STAT", true );
            }
        }
        
        
        static int buycnt = 0;
        static int sellcnt = 0;
        bool buyflag = false;
        bool sellflag = false;
        bool exitflag = false;
        int pend_num = STEP_PEND_NUMBER;
        double open_price = iClose(s.SYMBOL,s.PERIOD,1);
        int first_pend_point =  (int)STEP_PEND_FIRST_POINT;
        
        int shift = 1;
        int cnt = 10;
        
        double bufbuy[];
        ArraySetAsSeries( bufbuy, true );
        if(CopyBuffer(s.g_sr_handler,0,shift,cnt,bufbuy)>0)
        {
            dbg (s, "BUY :   " + DoubleToString(bufbuy[0],0) 
                + " " + DoubleToString(bufbuy[1],0) 
                + " " + DoubleToString(bufbuy[2],0) 
                + " " + DoubleToString(bufbuy[3],0) 
                + " " + DoubleToString(bufbuy[4],0) 
                + " " + DoubleToString(bufbuy[5],0) 
                + " " + DoubleToString(bufbuy[6],0) 
                + " " + DoubleToString(bufbuy[7],0) 
                + " " + DoubleToString(bufbuy[8],0) 
                + " " + DoubleToString(bufbuy[9],0) 
                );
        
            if( 0.0 != bufbuy[0] )
            {
                buyflag = true;
            }
        }

        double bufsell[];
        ArraySetAsSeries( bufsell, true );
        if(CopyBuffer(s.g_sr_handler,1,shift,cnt,bufsell)>0)
        {
            dbg (s, "SELL:   " + DoubleToString(bufsell[0],0) 
                + " " + DoubleToString(bufsell[1],0) 
                + " " + DoubleToString(bufsell[2],0) 
                + " " + DoubleToString(bufsell[3],0) 
                + " " + DoubleToString(bufsell[4],0) 
                + " " + DoubleToString(bufsell[5],0) 
                + " " + DoubleToString(bufsell[6],0) 
                + " " + DoubleToString(bufsell[7],0) 
                + " " + DoubleToString(bufsell[8],0) 
                + " " + DoubleToString(bufsell[9],0) 
                );
            if( 0.0 != bufsell[0] )
            {
                sellflag = true;
            }
        }
        
        double bufcmp1[];
        ArraySetAsSeries( bufcmp1, true );
        if(CopyBuffer(s.g_sr_handler,6,shift,cnt,bufcmp1)>0)
        {
            dbg (s, "CMP1-BO1: " + DoubleToString(bufcmp1[0],0) 
                + " " + DoubleToString(bufcmp1[1],0) 
                + " " + DoubleToString(bufcmp1[2],0) 
                + " " + DoubleToString(bufcmp1[3],0) 
                + " " + DoubleToString(bufcmp1[4],0) 
                + " " + DoubleToString(bufcmp1[5],0) 
                + " " + DoubleToString(bufcmp1[6],0) 
                + " " + DoubleToString(bufcmp1[7],0) 
                + " " + DoubleToString(bufcmp1[8],0) 
                + " " + DoubleToString(bufcmp1[9],0) 
                );
                
            /*if( true == PositionSelect(s.SYMBOL) )
            {
                if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
                {  
                    if( bufcmp1[1] < bufcmp1[2] )
                    {
                        exitflag = true;
                    }
                }
                if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
                {                
                    if( bufcmp1[1] > bufcmp1[2] )
                    {
                        exitflag = true;
                    }
                }
            }*/
                
        } // if(CopyBuffer(s.g_sr_handler,6,shift,cnt,bufcmp1)>0)

        double bufcmp2[];
        ArraySetAsSeries( bufcmp2, true );
        if(CopyBuffer(s.g_sr_handler,12,shift,cnt,bufcmp2)>0)
        {
            dbg (s, "CMP2-DIF: " + DoubleToString(bufcmp2[0],0) 
                + " " + DoubleToString(bufcmp2[1],0) 
                + " " + DoubleToString(bufcmp2[2],0) 
                + " " + DoubleToString(bufcmp2[3],0) 
                + " " + DoubleToString(bufcmp2[4],0) 
                + " " + DoubleToString(bufcmp2[5],0) 
                + " " + DoubleToString(bufcmp2[6],0) 
                + " " + DoubleToString(bufcmp2[7],0) 
                + " " + DoubleToString(bufcmp2[8],0) 
                + " " + DoubleToString(bufcmp2[9],0) 
                );
                
        } // if(CopyBuffer(s.g_sr_handler,9,shift,cnt,bufcmp2)>0)

        double bufcmp3[];
        ArraySetAsSeries( bufcmp3, true );
        if(CopyBuffer(s.g_sr_handler,14,shift,cnt,bufcmp3)>0)
        {
            dbg (s, "CMP3-INT: " + DoubleToString(bufcmp3[0],0) 
                + " " + DoubleToString(bufcmp3[1],0) 
                + " " + DoubleToString(bufcmp3[2],0) 
                + " " + DoubleToString(bufcmp3[3],0) 
                + " " + DoubleToString(bufcmp3[4],0) 
                + " " + DoubleToString(bufcmp3[5],0) 
                + " " + DoubleToString(bufcmp3[6],0) 
                + " " + DoubleToString(bufcmp3[7],0) 
                + " " + DoubleToString(bufcmp3[8],0) 
                + " " + DoubleToString(bufcmp3[9],0) 
                );
                
        } // if(CopyBuffer(s.g_sr_handler,10,shift,cnt,bufcmp2)>0)


        if( true == exitflag )
        {
            if( true == PositionSelect(s.SYMBOL) )
            {
                m_PositionClose(s, MAGIC_POSITION, "EXIT", true );
            }
            if( 0 < m_CntOrderPending(s, ORDER_TYPE_SELL_STOP) )
            {
                m_RemovePendingOrders(s, "POSITION CANCEL PENDING", ORDER_TYPE_SELL_STOP);
            }
            if( 0 < m_CntOrderPending(s, ORDER_TYPE_BUY_STOP) )
            {
                m_RemovePendingOrders(s, "POSITION CANCEL PENDING", ORDER_TYPE_BUY_STOP);
            }
        } // if( true == exitflag )
      

        // move the exist flag in front of order lot calculation
        // otherwise the order might never be closed as there 
        // is not enough margin left for opening new orders.
        double lot = 0;
        if( 10 <= ORDER_LOT )
        {
            // calc lot depending on available margin
            if( false == m_Calculate_Lot(s,lot,pend_num) )
            {
return;
            }
        }
        else
        {
            lot = ORDER_LOT;
        }
        double vol = 0; 
        if(true == PositionSelect(s.SYMBOL))
        {
            vol = PositionGetDouble(POSITION_VOLUME);  
        }  
        double calc_margin = 0;
        double acc_free_margin=AccountInfoDouble(ACCOUNT_FREEMARGIN);
        
        if( true == buyflag )
        {

            //if( m_CntOrderTotalBySymbol(s) )
            {                        
                m_RemovePendingOrders(s, "POSITION CANCEL PENDING");
            }
            
            s.sl_level = (int) MathAbs( iHigh(s.SYMBOL,s.PERIOD,1) - iLow(s.SYMBOL,s.PERIOD,1) ) / s.POINT;
            dbg( s, "SL_LEVEL BUY: " + DoubleToString( s.sl_level) );
            if( 0 < pend_num )
            {
                if( 0 == STEP_PEND_FIRST_POINT )
                {
                    first_pend_point = (int)s.sl_level;
                }            
                //m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                m_PositionOpenBuy(s,0.03);            
                g_OpenOrder(s, open_price,ORDER_TYPE_SELL_LIMIT,50,0,0,lot, 411);
                g_OpenOrder(s, open_price,ORDER_TYPE_SELL_LIMIT,150,0,0,lot, 412);
                g_OpenOrder(s, open_price,ORDER_TYPE_SELL_LIMIT,300,0,0,lot, 413);
                //g_OpenOrder(s, open_price,ORDER_TYPE_SELL_STOP, 300,0,0,0.03,444);
                //m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_STOP, open_price, lot, first_pend_point, k_step_pend_point, pend_num );
            }
            else
            {
                m_PositionOpenBuy(s,lot);            
            }
        }      
        if( true == sellflag )
        {

            //if( m_CntOrderTotalBySymbol(s) )
            {                        
                m_RemovePendingOrders(s, "POSITION CANCEL PENDING");
            }
                       
            s.sl_level = (int) MathAbs( iHigh(s.SYMBOL,s.PERIOD,1) - iLow(s.SYMBOL,s.PERIOD,1) ) / s.POINT;
            dbg( s, "SL_LEVEL SELL: " + DoubleToString(s.sl_level) );
            if( 0 < pend_num )
            {
                if( 0 == STEP_PEND_FIRST_POINT )
                {
                    first_pend_point = (int)s.sl_level;
                }            
                //m_WorkWithPendingOrders(s,ORDER_TYPE_SELL_STOP, open_price, lot, first_pend_point, k_step_pend_point, pend_num );
                m_PositionOpenSell(s,0.03);            
                g_OpenOrder(s, open_price,ORDER_TYPE_BUY_LIMIT,50,0,0,lot, 311);
                g_OpenOrder(s, open_price,ORDER_TYPE_BUY_LIMIT,150,0,0,lot, 312);
                g_OpenOrder(s, open_price,ORDER_TYPE_BUY_LIMIT,300,0,0,lot, 313);
                //g_OpenOrder(s, open_price,ORDER_TYPE_BUY_STOP, 300,0,0,0.03,333);
                //m_WorkWithPendingOrders(s,ORDER_TYPE_BUY_STOP,  open_price, lot, first_pend_point, k_step_pend_point, pend_num );
            }
            else
            {
                m_PositionOpenSell(s,lot);
            }
            
        }   
    }  // if(true == s.g_is_new_sync )
        
} // void AlgorithmExpertMa( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick  )
//+------------------------------------------------------------------+


