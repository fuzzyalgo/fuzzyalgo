//+------------------------------------------------------------------+
//|                                                    variables.mqh |
//|                                                        andrehowe |
//|                                             http://andrehowe.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011 - 2016, Andre Howe"
#property link      "http://andrehowe.com"
string    VERSION = "0.99.58";

//
// INPUTS
//

//+------------------------------------------------------------------+
//|   Input parameters                                               |
//+------------------------------------------------------------------+
enum e_algorithm {
    E_ALGORITHM_DEFAULT,
    E_ALGORITHM_NORMALISE,
    E_ALGORITHM_EXPERTWA,
    E_ALGORITHM_EXPERTMA,
    E_ALGORITHM_EXPERTVO,
    E_ALGORITHM_TICKS,
    E_ALGORITHM_XLS,
    E_ALGORITHM_CNT_DS,
    E_ALGORITHM_MAX
};

enum e_algoparam {
    E_ALGOPARAM_SL,
    E_ALGOPARAM_SLDF,
    E_ALGOPARAM_CL,
    E_ALGOPARAM_CLDF,
    E_ALGOPARAM_TICKSNORMALISE,    
    E_ALGOPARAM_MAX
};

enum e_algosync {
    E_ALGOSYNC_TIME,
    E_ALGOSYNC_BAR,
    E_ALGOSYNC_TICK,
    E_ALGOSYNC_MAX
};

enum e_algodirection {
    E_ALGODIRECTION_STOP,
    E_ALGODIRECTION_LIMIT,
    E_ALGODIRECTION_BUY,
    E_ALGODIRECTION_SELL,
    E_ALGODIRECTION_MAX,
};

enum e_algostoptrading {
    E_ALGOSTOPTRADING_ERR,
    E_ALGOSTOPTRADING_TRUE,
    E_ALGOSTOPTRADING_FALSE,
    E_ALGOSTOPTRADING_MAX,
};

enum e_workwithpositions {
    E_WWP_NO_SL,
    E_WWP_SL_POINTS,
    E_WWP_TRAILING_STOP,
    E_WWP_PREV_CLOSE,
    E_WWP_PREV_2x_CLOSE,
};


input int           HOURSTART                   =    1;  // at which hour to START trading
//input int           HOURSTOP                    =   21;  // at which hour to STOP  trading

// symbol
//input string        SYMBOLS                     =    "SYMBOL";  // "SYMBOL" or "SYMBOL:USDJPY.e:..."  or "ALL"
input string        SYMBOLS                     =    "SYMBOL";  // "SYMBOL" or "SYMBOL:USDJPY.e:..."  or "ALL"

// keys
input string        PROPKEY                     =    "PROPKEY";
input string        ACCKEY                      =    "ACCKEY";
input string        CONTKEY                     =    "CONTKEY";

// trading algo parameters
input string        ALGORITHM                   = "CNT_DS";// ALGORITHM {DEFAULT,NORMALISE,EXPERTWA,EXPERTVO,EXPERTMA,TICKS,XLS,CNT_DS} 
input string        ALGOPARAM                   = "SL";      // ALGOPARAM {SL,SLDF,CL,CLDF,TICKSNORMALISE} 
input string        ALGODIRECTION               = "STOP";    // ALGODIRECTION {STOP,LIMIT,BUY,SELL}
input string        ALGOSYNC                    = "TICK";     // ALGOSYNC  {TIME,BAR,TICK} 
//input string        ALGOSYNC                    = "BAR";     // ALGOSYNC  {TIME,BAR,TICK} 
input int           STEP_PEND_NUMBER            =  10; // STEP_PEND_NUMBER number of pending orders
input int           STEP_PEND_FIRST_POINT       =  10; // STEP_PEND_FIRST_POINT (if NULL use prev candle height) to use it 100% MARKET_VOLATILITY_FACTOR must be 1.0
input double        MARKET_VOLATILITY_FACTOR    =  300; // MARKET_VOLATILITY_FACTOR a_Wa > iHigh - iLow
input int           MARKET_VOLATILITY_RESET_MIN =    0; // MARKET_VOLATILITY_RESET_MIN time after pending orders are deleted
                                                        //   only used when ALGOPARAM = MARKETISVOLAFLAG is set
input int           TRAILING_STOP               =  20; // TRAILING_STOP level in points
input int           TRAILING_STEP               =  15; // TRAILING_STEP level in points
input int           SL_POINTS                   =  0; // SL level in Points (if NULL use prev candle height) 
input int           TP_POINTS                   =  0; // TP level in Points (if NULL use prev candle height) 
input double        BALANCE_INCREASE            =  0; // BALANCE_INCREASE the daily balance increase factor - 0 for unlimited increase

// database parameters
input bool          USEDATABASE                 =   false;// USEDATABASE mysql db or not

// misc parameters - hardly or never change
input int           ALGOSYNC_TOTAL_EVENTS       =    1;      // ALGOSYNC_TOTAL_EVENTS every xBAR,TIME,TICK do something
input double        ORDER_LOT                   =  0.01; // ORDER_LOT value
input int           STEP_PEND_POINT             =   100; // STEP_PEND_POINT difference between the pending orders in points 
input int           OPEN_POSITION_CLOSE_TIME_MIN=    0; // OPEN_POSITION_CLOSE_TIME_MIN open pos close time in minutes, if zero then never close the position.
input int           LOT_1_DEF_2_ASC_3_DESC      =    1; 
input int           MAGIC_PEND_START_A          =   100;
input int           MAGIC_PEND_START_B          =   200;
input int           VERBOSE                     =     1; // VERBOSE logging

input string                         FROM_TO_DATE="DD.MM.YYYY-DD.MM.YYYY";
input int                            AVG_CANDLE_HEIGHT = 0;// AVG_CANDLE_HEIGHT - if zero calc candle height, otherwise set this value
input int                            SL_LEVEL = 0; // SL_LEVEL - if AVG_CANDLE_HEIGHT(0), then set double
input int                            SR_PERIOD = 1;  // SR_PERIOD - if NULL calculate shift since day has started

input e_workwithpositions SL_LOSSES  = E_WWP_SL_POINTS;
input e_workwithpositions SL_PROFITS = E_WWP_TRAILING_STOP;



/*input*/ const bool          ADJUSTTIMEENABLED           =     false;
/*input*/ const int           SOUT1TRAILINGSTOP           =     0;


// INSTERFACE start
int g_use_socket = 0;  // 0 - use shared memory ; 1 - use socket ; 2 - force unresolved to release MQL2DLL.dll for compilation
// INSTERFACE end

//
// CONSTANTS
//
//+------------------------------------------------------------------+
//| CONSTANTS                                                        |
//+------------------------------------------------------------------+
// TODO review values - mabe make them configurable
// the following two values are in points
const int k_order_stop_level_min = 2;
const int k_step_pend_point  = STEP_PEND_POINT;

const int k_ticks_array_size = 100;

//
// GLOBAL VARIABLES
//
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
int    GMYSQLH = 0;
bool   GMYSQL_INIT_FAILED;
string GMYSQLHOST;
string GMYSQLUSER;
string GMYSQLPASS;
int    GMYSQLPORT; 

const int  MAGIC_POSITION     =   456;//  MAGIC_POS01 unique trade magic number
const int MINUTES_PER_DAY = 60*24;
int g_pending_order_expiry_time_s;  // pending order expiry time in seconds
datetime g_time_local;
datetime g_time_current;

double g_balance_start;
bool g_balance_reached;
const double g_balance_start_increase = BALANCE_INCREASE;
//int g_watcher_number;
bool g_is_master;

int g_algorithm;
int g_algoparam;
int g_algosync;
int g_algodirection;

// counts the error occurence for error messages that 
// potentially could spam STDERR, and hence only one message
// is output to STDERR
// TODO maybe create more than one variable here
// as it is used from more than one error source
// if there is more than one error, then the second one 
// is not logged anymore
int g_onerror_cnt = 0;
int g_onsystemerror_cnt = 0;
string g_computername = "";

// do we run in strategy tester mode or do we run as a normal expert advisor
bool TESTERMODE = false;
// do we need to adjust the TimeCurrent
bool ADJUSTTIME = false;

// global system flag
bool    g_system_ok;            // flag that stores the state if the trading system is ok or not

string g_contstate;
string g_tradstate;

//
// START normalise data for NN and FFT
//
#define N_INDEX_M1     0
#define N_INDEX_M5     1
#define N_INDEX_M15    2
#define N_INDEX_M30    3
#define N_INDEX_H1     4
#define N_INDEX_H4     5
#define N_INDEX_D1     6
#define N_INDEX_MAX    7
const double N_COEFF     = 0.75;
const int    N_TRAIN_CNT_IN_MIN = 60*48;  // take 48 h of previous data for training

struct SNormaliseData {

    // adate = sprintf( '%04d%02d%02d', years, months, days);
    //fname = [adate,'_',aperiod,'_',asymbol,'.csv'];
    string  fname;
    ENUM_TIMEFRAMES period;
    int     train_cnt;
    double  max;
    double  min;
    double  first;
    double  factor;
    int     bars_per_period_per_day; 
    int     shift_since_day_started;
    
};

struct SNormaliseTrader {
    
    //
    // constants    
    //
    double yentry;
    double yexit;
    // constants of states
    // 1) trailing stops
    double SP16;    //  1.6;
    double SP8;     //  0.8;
    double SP4;     //  0.4;
    double SP2;     //  0.2;
    double SP1;     //  0.1;
    double S0;      //  0.0;
    double SM1;     // -0.1;
    double SM2;     // -0.2;
    double SM4;     // -0.4;
    double SM8;     // -0.8;
    double SM16;    // -1.6;
    // 2) state of deals
    string SREADY;

    // old states    
    string SIN12;
    string SOUT1;
    string SOUT12;
    
    // new BUY states
    string SIN12B;
    string SOUT1B;
    string SOUT12B;
    // new SELL states
    string SIN12S;
    string SOUT1S;
    string SOUT12S;
    
    string SEND;

    //
    // VARS
    //
    // neutral close values
    double INP1[];
    // normal close values
    double INP2[];
    // SL values
    double AMP1[];
    // timeseries
    datetime TM1[];
    
    // init var of trailing stop
    double sts;
    // init var of state of deals
    string sd;
    string sdold;
    // init P1
    double pentry1;
    double pexit1;
    double psum1;
    // init P2
    double pentry2;
    double pexit2;
    double psum2;
    
    // init total sum
    double sum;
    double sum1;
    double sum2;
};
    
//
// END normalise data for NN and FFT
//


//
//  watcher data
//

struct SWatcherData {

    // generic
    bool update;
        
    // open position
    int      posopenbuycnt;
    int      posopensellcnt;
    datetime posopentime;
    double   posopenprice;
    double   posopenprofit;
    string   posopencomment;
    
    // pending orders buy
    int      ordbuycnt;
    datetime ordbuytime;
    double   ordbuyprice;
    string   ordbuycomment;

    // pending orders sell
    int      ordsellcnt;
    datetime ordselltime;
    double   ordsellprice;
    string   ordsellcomment;
    
    // account data
    double   accbalance;
    double   accequity;
    double   accmargin;
    double   accfreemargin;
    double   accprofit;
    double   accprofit_prev;
    
    // statistic data
    int      stat_cnt;
    double   stat_avg;
    double   stat_avg_arr[];
    
};


//
// SYMBOL data
//
// TODO get rid of List.mqh and of CObject
#include <Arrays\List.mqh>

class CSymbol : public CObject {

public:
    CSymbol(const string asymbol, const int anodeindex)
    {
        g_node_index = anodeindex;
        g_oninit_cnt = 0;
        g_algo_ticks_init = false;
        g_is_normalised = false;
        g_is_new_day = false;
        g_is_new_sync = false;

        // only initialise this ever once 
        // per metatrader.exe start
        // and not per every g_OnInit
        // otherwise NewDay function
        // stops working
        TimeToStruct( 0, g_tm_prev_day );
        TimeToStruct( 0, g_tm_prev_day2 );
        TimeToStruct( 0, g_tm_prev_year );
        TimeToStruct( 0, g_tm_prev_year2 );
        // tester init
        if( true == TESTERMODE )
        {
            g_test_balance_start = 0;
            g_test_day_cnt = 0;
        }

//
// INSTERFACE start
//    
        SYMBOL = asymbol;
        // interface to mysql db
        // RoboForex  - convert EURUSD.e to EURUSUD
        //    others  - convert EURUSD   to EURUSUD
        string sym = StringSubstr( SYMBOL, 0 , 6 );
        // TODO interface - is not the nicest place to be
        // set the database names here
        string db_prefix = "";
        if( true == TESTERMODE )
        {
            // DB prefix for testermode
            db_prefix = "FXT_";
        }
        else
        {
            // DB for default DEMO accounts
            // e.g. RE5D99
            db_prefix = "FXD_";
            // DB for real accounts
            // e.g. RE5R01
            if( ('R' == StringGetCharacter(ACCKEY,3)) || ('r' == StringGetCharacter(ACCKEY,3)) ) 
            {
                db_prefix = "FXR_";
            }
        } // if( true == TESTERMODE )

        // expert db        
        g_db_expert = db_prefix + sym;
        g_table_expert = ACCKEY + "_EXPERT";
        //                              CREATE FX_SYMBOL.ACCKEY_EXPERT IF NOT EXISTS TABLENAME ( id INT(10) NOT NULL AUTO_INCREMENT, item VARCHAR(100), datetime BIGINT, date VARCHAR(12), time VARCHAR(12), ask DEC(15,5), bid DEC(15,5), odatetime BIGINT, odate VARCHAR(12), otime VARCHAR(12), orderno BIGINT, dealno BIGINT, type VARCHAR(100), statedir VARCHAR(100), vol DEC(15,5), price DEC(15,5), sl DEC(15,5), tp DEC(15,5), profit DEC(15,5), commission DEC(15,5), swap DEC(15,5), balance DEC(15,5), equity DEC(15,5), comment VARCHAR(200), log VARCHAR(256), PRIMARY KEY (id), INDEX datetime (datetime) )
        g_table_expert_create = "CREATE TABLE IF NOT EXISTS "+g_db_expert+"."+g_table_expert+" ( id INT(10) NOT NULL AUTO_INCREMENT, item VARCHAR(100), datetime BIGINT, date VARCHAR(12), time VARCHAR(12), ask DEC(15,5), bid DEC(15,5), odatetime BIGINT, odate VARCHAR(12), otime VARCHAR(12), orderno BIGINT, dealno BIGINT, type VARCHAR(100), statedir VARCHAR(100), vol DEC(15,5), price DEC(15,5), sl DEC(15,5), tp DEC(15,5), profit DEC(15,5), commission DEC(15,5), swap DEC(15,5), balance DEC(15,5), equity DEC(15,5), comment VARCHAR(256), log VARCHAR(256), PRIMARY KEY (id), INDEX datetime (datetime) )";
        
        // ticks db
        g_db_ticks  = db_prefix + sym;
        g_table_ticks  = ACCKEY + "_TICKS";

        // report db
        g_db_log       = db_prefix + "REPORT";
        g_table_log    = "EXPERT_LOG";
        //                               CREATE TABLE IF NOT EXISTS FX_REPORT.EXPERT_LOG (id INT(10) NOT NULL AUTO_INCREMENT, datetime BIGINT, date VARCHAR(12), time VARCHAR(12), symbol VARCHAR(10), period VARCHAR(10), computername VARCHAR(100), propkey VARCHAR(100), acckey VARCHAR(100), item VARCHAR(100), error INT(10), version VARCHAR(10), buypos INT(10), sellpos INT(10), buyord INT(10), sellord INT(10), balance DEC(15,2), equity DEC(15,2), margin DEC(15,2), log MEDIUMTEXT, PRIMARY KEY (id), INDEX datetime (datetime) )
        g_table_log_create    = "CREATE TABLE IF NOT EXISTS "+g_db_log+"."+g_table_log+" (id INT(10) NOT NULL AUTO_INCREMENT, datetime BIGINT, date VARCHAR(12), time VARCHAR(12), symbol VARCHAR(10), period VARCHAR(10), computername VARCHAR(100), propkey VARCHAR(100), acckey VARCHAR(100), item VARCHAR(100), error INT(10), version VARCHAR(10), buypos INT(10), sellpos INT(10), buyord INT(10), sellord INT(10), balance DEC(15,2), equity DEC(15,2), margin DEC(15,2), log MEDIUMTEXT, PRIMARY KEY (id), INDEX datetime (datetime) )";

//
// INSTERFACE end
//        

        ArraySetAsSeries( g_arr_ticks_bid, false );
        ArrayResize     ( g_arr_ticks_bid, k_ticks_array_size);
        ArrayInitialize ( g_arr_ticks_bid, 0.0 );
        
        ArraySetAsSeries( g_arr_ticks_ask, false );
        ArrayResize     ( g_arr_ticks_ask, k_ticks_array_size);
        ArrayInitialize ( g_arr_ticks_ask, 0.0 );
        
        g_avg_ticks_bid = 0.0;
        g_avg_ticks_ask = 0.0;
        g_calc_new_tick_cnt = 0;
        g_sl = 0.0;
        
        g_sr_handler = INVALID_HANDLE;

    }
    
public:
    bool CSymbol::iCalcNewTick(void);
    
    int g_calc_new_tick_cnt;
    
    //+------------------------------------------------------------------+
    //| Symbol variables                                                 |
    //+------------------------------------------------------------------+
    SNormaliseTrader g_normt;
    bool g_is_normalised;
    bool g_is_new_day;
    bool g_is_new_sync;
    SNormaliseData g_normalise[N_INDEX_MAX];
    SWatcherData g_watcher_data;
    string g_db_expert;
    string g_table_expert;
    string g_table_expert_create;
    string g_db_ticks;
    string g_table_ticks;
    string g_db_log;
    string g_table_log;
    string g_table_log_create;
    
    MqlTick m_tick;                             // current price
    string SYMBOL;              // global variable
    ENUM_TIMEFRAMES PERIOD;     // global variable
    double POINT;               // global variable
    int    DIGITS;              // global variable
    double ASK;                 // global variable
    double BID;                 // global variable
    long   VOL;                 // global variable
    int    SPREADPOINTS;         // global variable
    int g_open_positions_trailing_stop; // trailing stop in points
    int g_open_positions_trailing_step; // trailing step in points
    // volatility detector
    MqlDateTime g_tm_prev_day;
    MqlDateTime g_tm_prev_day2;
    MqlDateTime g_tm_prev_year;
    MqlDateTime g_tm_prev_year2;
    
    // ALGOTICKS start    
    uint TICKCOUNT;
    long CVOL;
    long PREVVOL;
    datetime LASTBAR_M1;
    datetime LASTBAR_M5;
    datetime LASTBAR_M15;
    datetime LASTBAR_H1;
    datetime LASTBAR_H4;
    datetime LASTBAR_D1;
    double PREVASK, PREVBID;
    bool g_algo_ticks_init;
    // ALGOTICKS end
    
    // global order variables
    double m_order_open_price;  // open order price
    double m_order_current_price; // current order price
    datetime m_order_time;      // m_order_time
    double m_order_spread;      // m_order_spread
    double m_order_profit;      // m_order_profit
    int m_order_stop_level;     // minimum level of the price to install a Stop Loss / Take Profit
    long m_order_type;          // order type
    ulong m_order_ticket;       // order ticket 
    long m_position_id;          // m_position_id
    double m_order_volume;      // m_order_volume
    
    
    // g_HistoryProcessor global variables
    datetime g_history_start_date_d;// start date history for deals
    datetime g_history_start_date_o;// start date history for orders
    bool     g_history_started;     // flag of initialization of the counters
    int      g_history_p_cnt;       // number of open positions
    
    // expertsl global variables
    long    g_v0prev;               // stores the previous volume for opening stock
    datetime g_wait_time;               // seconds to wait for processing pending orders
    int g_tick_cnt;                     // count every real tick

    // test variables    
    int g_test_day_cnt;
    double g_test_balance_start;

    // market book variables    
    bool g_market_book;
    
    bool g_stop_trading;

    // only output the first STARTUP message
    int g_oninit_cnt;
    
    int g_node_index;
    
    datetime g_market_is_volatile_time;
    
    bool g_session_quote;
    
    double g_arr_ticks_bid[];
    double g_arr_ticks_ask[];
    double g_avg_ticks_bid;
    double g_avg_ticks_ask;
    double g_sl;
    
    int g_sr_handler;
    
    double sl_level;
    
    //
    //  01_CSV, 02_SIG, 03_EXE
    //
    
    long   g_01_CSV_t0;
    long   g_02_SIG_t0;
    long   g_03_EXE_t0;
    
    long   g_01_CSV_tc;
    long   g_02_SIG_tc;
    long   g_03_EXE_tc;

    string g_01_CSVs_fN;
    string g_01_CSVx_fN;
    string g_02_SIGs_fN;
    string g_02_SIGx_fN;
    string g_03_EXEs_fN;
    string g_03_EXEx_fN;
    
    // \MQL5\Files\H1\20200615\ 01_CSV_TC   (000_TIMENOW)  -> time of trade server
    // \MQL5\Files\H1\20200615\ 01_CSV_T0   (000_TIMEOPEN) -> actual t0 open time here
    string g_01_CSV_TC_fN;
    string g_01_CSV_T0_fN;
    string g_02_SIG_TC_fN;
    string g_02_SIG_T0_fN;
    string g_03_EXE_TC_fN;
    string g_03_EXE_T0_fN;

    //
    //  01_CSV, 02_SIG, 03_EXE
    //
       

}; // class CSymbol

bool CSymbol::iCalcNewTick()
{

    // only log the price changes to the sql server, if the sql server is slow
    // attention interface here - 10 points diff - TODO maybe change from T1 to T10 here
    if( ( 10 > MathAbs(BID - PREVBID)/POINT ) &&
        ( 10 > MathAbs(ASK - PREVASK)/POINT ) ) 
    {
    }
    else
    {
        PREVBID = BID; 
        PREVASK = ASK;
        
        // calc the average tick
        double atbid[];
        double atask[];
        ArrayResize(atbid, k_ticks_array_size);
        ArrayResize(atask, k_ticks_array_size);
        ArrayInitialize(atbid, 0.0 );
        ArrayInitialize(atask, 0.0 );
        
        atbid[0] = BID;
        int numbid1 = ArrayCopy(atbid,g_arr_ticks_bid,1,0,k_ticks_array_size-1);
        int numbid2 = ArrayCopy(g_arr_ticks_bid,atbid,0,0,k_ticks_array_size);
        
        atask[0] = ASK;
        int numask1 = ArrayCopy(atask,g_arr_ticks_ask,1,0,k_ticks_array_size-1);
        int numask2 = ArrayCopy(g_arr_ticks_ask,atask,0,0,k_ticks_array_size);
        
        //g_avg_ticks_ask = iCustPriceDF(s,0,I_PRICE_TICK_ASK,0);
        //g_avg_ticks_bid = iCustPriceDF(s,0,I_PRICE_TICK_BID,0);
        
        //string logstr = StringFormat( "ASK %.5f %.5f BID %.5f %.5f", ASK, g_avg_ticks_ask, BID, g_avg_ticks_bid );
        //Print( logstr );
        g_calc_new_tick_cnt++;
        if( k_ticks_array_size < g_calc_new_tick_cnt ) {
return( true );
        }
        
    } // if( ( 10 > MathAbs(BID - PREVBID)/POINT )
return( false );
}

/*CSymbol GUSDCHF("USDCHF");
CSymbol GUSDJPY("USDJPY");
CSymbol GEURUSD("EURUSD");*/

CList *GSYMBOLLIST=NULL;


//
// DEFINES
//

// the order of the digital filter
#define FILTERORDER 62

// DigitalFilter.mq4
// double p = iCustom(symbol, timeframe, "DigitalFilter",I_IND0_PERIOD,I_IND1_PERIOD,I_IND2_PERIOD,I_IND3_PERIOD,I_IND0_DF,I_IND1_DF,I_IND2_DF,I_IND3_DF,I_IND0_ON,I_IND1_ON,I_IND2_ON,I_IND3_ON ,BUF0, shift);


// INDICATOR PERIOD
#define I_IND0_PERIOD 0 
#define I_IND1_PERIOD 14 
#define I_IND2_PERIOD 55
#define I_IND3_PERIOD 89

// INDICATOR DIGITAL FILTER ON or OFF
#define I_IND0_DF 1
#define I_IND1_DF 0
#define I_IND2_DF 0
#define I_IND3_DF 0

// INDICATOR ON of OFF
#define I_IND0_ON 1 
#define I_IND1_ON 1
#define I_IND2_ON 1
#define I_IND3_ON 1


// ccidigifilter.mq4
// double cci = iCustom(symbol, timeframe, "ccidigifilter",I_CCI0_PERIOD,I_CCI1_PERIOD,I_CCI2_PERIOD,I_CCI3_PERIOD,I_CCI0_DF,I_CCI1_DF,I_CCI2_DF,I_CCI3_DF,I_CCI0_ON,I_CCI1_ON,I_CCI2_ON,I_CCI3_ON ,BUF0, shift);

// CCI PERIOD
#define I_CCI0_PERIOD 14
#define I_CCI1_PERIOD 55
#define I_CCI2_PERIOD 89
#define I_CCI3_PERIOD 144
#define I_CCI4_PERIOD 377

//CCI DIGITAL FILTER ON or OFF
#define I_CCI0_DF 1
#define I_CCI1_DF 1
#define I_CCI2_DF 1
#define I_CCI3_DF 1

// CCI ON of OFF
#define I_CCI0_ON 1
#define I_CCI1_ON 1
#define I_CCI2_ON 1
#define I_CCI3_ON 1


#define BUF0 0
#define BUF1 1
#define BUF2 2
#define BUF3 3


#define I_PRICE_CCI         0
#define I_PRICE_MA          1
#define I_PRICE_TICK_ASK    2
#define I_PRICE_TICK_BID    3
#define I_PRICE_RSI         4
#define I_PRICE_ATR         5


//
// defenitions from mql4
// used for iHighest, iLowest, et. al.
//  see also Migrating from MQL4 to MQL5 http://www.mql5.com/en/articles/81
//
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4 


//
// XLS defines start
//

//' INDEX   DT            STAT	TradeDT	    TradeOP     DIFF    SUMUP
//' 112     1590760800    B	    1590757200	1,11327		-22		31
struct CSVTable_Sig_or_Exe
{   
    //int       INDEX; 
    long        DT;
    string      STAT;
    long        TradeDT;
    double      TradeOP;
    double      DIFF;
    double      SUMUP;            
};

 MqlTradeResult g_trade_result;

//
// XLS defines end
//


//
// SOCKET VAR START
//

//|  SOCKET DEFINES
#define ERROR_INVALID_HANDLE        6
#define ERROR_SUCCESS               0
#define SOCKET_STATUS_CONNECTED		1
#define SOCKET_STATUS_DISCONNECTED	2
//|   SOCKET_CLIENT                                                  |
struct SOCKET_CLIENT
  {
   uchar             status;
   ushort            sequence;
   uint              sock;
  };
//|  ENUM_DATA_TYPE                                            |
enum ENUM_DATA_TYPE
  {
   DATA_STRING,//String
   DATA_STRUCT //Struct
  };
//--- SOCKET global variables
string         g_socket_host="localhost"; // Host
ushort         g_socket_port=777;         // Port
ENUM_DATA_TYPE g_socket_inptype=DATA_STRING; // Data Type
SOCKET_CLIENT  g_socket_client_handle;  // socket handle

uint GSM_HANDLE;
//
// SOCKET VAR END
//


//
// IMPORTS
//

#import "kernel32.dll"
    void GetLocalTime(int& TimeArray[]);
    int GetComputerNameW(string lpBuffer, int &nSize);
    int GetEnvironmentVariableW(string lpName, string lpBuffer, int nSize);
#import "libmysql.dll"
    int mysql_init(int db);
    int mysql_errno(int handle);
    int mysql_real_connect(int handle, string host, string user, string password,
                           string DB,int port,string socket,int clientflag);
    int mysql_real_query(int handle,string query,int length);
    void mysql_close(int handle);                        
    string mysql_error(int handle); //string is ansi
#import

// TODO 64-bit version of DLL
/*#import "socket_mql5_x86.dll"
uint SocketOpen(SOCKET_CLIENT &socket,const string host,const ushort port);
void SocketClose(SOCKET_CLIENT &socket);
uint SocketWriteStruct(SOCKET_CLIENT &socket,const string symbol,const MqlTick &tick);
uint SocketWriteString(SOCKET_CLIENT &socket,const string str);
string SocketErrorString(int error_code);
#import "socket_mql5_x64.dll"
uint SocketOpen(SOCKET_CLIENT &socket,const string host,const ushort port);
void SocketClose(SOCKET_CLIENT &socket);
uint SocketWriteStruct(SOCKET_CLIENT &socket,const string symbol,const MqlTick &tick);
uint SocketWriteString(SOCKET_CLIENT &socket,const string str);
string SocketErrorString(int error_code);
#import
uint SocketOpen(SOCKET_CLIENT &socket,const string host,const ushort port)
  {
   if(_IsX64)return(socket_mql5_x64::SocketOpen(socket, host, port));
   return(socket_mql5_x86::SocketOpen(socket, host, port));
  }*/
  
//+------------------------------------------------------------------+
//|   Inport DLL                                                     |
//+------------------------------------------------------------------+
#import "MQL2DLL.dll"
// strings are unicode
uint SocketOpen(SOCKET_CLIENT &socket,const string host,const ushort port);
void SocketClose(SOCKET_CLIENT &socket);
uint SocketWriteStruct(SOCKET_CLIENT &socket,const string symbol,const MqlTick &tick);
uint SocketWriteString(SOCKET_CLIENT &socket,const string str);
// BEWARE the following function is unresolved and it will be called when g_use_socket=2
// to force the unloading of the MQL2DLL.dll to be able to compile it
string SocketReceiveString(SOCKET_CLIENT &socket);
string SocketReceiveString(SOCKET_CLIENT &socket, uint& error);
string SocketErrorString(int error_code);
uint   SM_openWC ( const string cn, const string ak, const string pk, const string ck  );
uint   SM_writeWC( const int handle, int id, int type, const string buf );
string SM_readWC ( const int handle, int id, int type, uint& len);
uint   SM_closeWC( const int handle );
string SM_GetEnvironmentVariableWC(const string envvar, int& len);
#import






//+------------------------------------------------------------------+
//|   m_AssembleInputParameters
//+------------------------------------------------------------------+
int m_AssembleInputParameters()
{

    int err = 0;
    //
    // sanity check for ALGORITHM and ALGOPARAM
    //
    g_algorithm = -1;
    g_algoparam = -1;
    g_algosync  = -1;
    g_algodirection = -1;
    if( 0 == StringCompare( "DEFAULT" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_DEFAULT;
    } 
    else if( 0 == StringCompare( "NORMALISE" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_NORMALISE;
    } 
    else if( 0 == StringCompare( "EXPERTWA" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_EXPERTWA;
    } 
    else if( 0 == StringCompare( "EXPERTMA" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_EXPERTMA;
    } 
    else if( 0 == StringCompare( "EXPERTVO" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_EXPERTVO;
    } 
    else if( 0 == StringCompare( "TICKS" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_TICKS;
    } 
    else if( 0 == StringCompare( "XLS" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_XLS;
    } 
    else if( 0 == StringCompare( "CNT_DS" , ALGORITHM ) )
    {
        g_algorithm = E_ALGORITHM_CNT_DS;
    } 
    else
    {
        err = -41;
        string log = "ERROR - Please implement the input string ALGORITHM = [" + ALGORITHM + "]";
        dbg( log );
        
    }
    if( 0 == StringCompare( "SL" , ALGOPARAM ) )
    {
        g_algoparam = E_ALGOPARAM_SL;
    } 
    else if( 0 == StringCompare( "SLDF" , ALGOPARAM ) )
    {
        g_algoparam = E_ALGOPARAM_SLDF;
    } 
    else if( 0 == StringCompare( "CL" , ALGOPARAM ) )
    {
        g_algoparam = E_ALGOPARAM_CL;
    } 
    else if( 0 == StringCompare( "CLDF" , ALGOPARAM ) )
    {
        g_algoparam = E_ALGOPARAM_CLDF;
    } 
    else if( 0 == StringCompare( "TICKSNORMALISE" , ALGOPARAM ) )
    {
        g_algoparam = E_ALGOPARAM_TICKSNORMALISE;
    } 
    else
    {
        err = -42;
        string log = "ERROR - Please implement the input string ALGOPARAM = [" + ALGOPARAM + "]";
        dbg( log );
    }

    if( 0 == StringCompare( "STOP" , ALGODIRECTION ) )
    {
        g_algodirection = E_ALGODIRECTION_STOP;
    } 
    else if( 0 == StringCompare( "LIMIT" , ALGODIRECTION ) )
    {
        g_algodirection = E_ALGODIRECTION_LIMIT;
    } 
    else if( 0 == StringCompare( "BUY" , ALGODIRECTION ) )
    {
        g_algodirection = E_ALGODIRECTION_BUY;
    } 
    else if( 0 == StringCompare( "SELL" , ALGODIRECTION ) )
    {
        g_algodirection = E_ALGODIRECTION_SELL;
    } 
    else
    {
        err = -44;
        string log = "ERROR - Please implement the input string ALGODIRECTION = [" + ALGODIRECTION + "]";
        dbg( log );
        
    }
    if( 0 == StringCompare( "TIME" , ALGOSYNC ) )
    {
        g_algosync = E_ALGOSYNC_TIME;
    } 
    else if( 0 == StringCompare( "BAR" , ALGOSYNC ) )
    {
        g_algosync = E_ALGOSYNC_BAR;
    } 
    else if( 0 == StringCompare( "TICK" , ALGOSYNC ) )
    {
        g_algosync = E_ALGOSYNC_TICK;
    } 
    else
    {
        err = -43;
        string log = "ERROR - Please implement the input string ALGOSYNC = [" + ALGOSYNC + "]";
        dbg( log );
    }

    return (err);   
} // int m_AssembleInputParameters()
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_ANSI2UNICODE
//+------------------------------------------------------------------+
string m_ANSI2UNICODE(string s) {
    ushort mychar;
    long m,d;
    double mm,dd;
    string img;    
    string res="";
    if (StringLen(s)>0) {
       string g=" ";
       for (int i=0;i<StringLen(s);i++) {          
          string f="  ";          
          mychar=ushort(StringGetCharacter(s,i));
          mm=MathMod(mychar,256);
          img=DoubleToString(mm,0);
          m=StringToInteger(img);
          dd=(double) (mychar-m)/256;
          img=DoubleToString(dd,0);
          d=StringToInteger(img);
          if (m!=0) {
             StringSetCharacter(f,0,ushort(m));
             StringSetCharacter(f,1,ushort(d));
             StringConcatenate(res,res,f);
          } else {
            break;                      
          }
       }
   }
   return(res);
} // string m_ANSI2UNICODE(string s)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_UNICODE2ANSI
//+------------------------------------------------------------------+
string m_UNICODE2ANSI(string s) {
   int leng,ipos;
   uchar m,d;
   ulong big;
   leng=StringLen(s);
   string unichar;
   string res="";
   if (leng!=0)
     {    
      unichar=" ";
      ipos=0;      
      while (ipos<leng)
        { //uchar typecasted because each double byte char is actually one byte
         m=uchar(StringGetCharacter(s,ipos));
         if (ipos+1<leng)
           d=uchar(StringGetCharacter(s,ipos+1));
         else
           d=0;
         big=d*256+m;  
         StringSetCharacter(unichar,0,ushort(big));        
         StringConcatenate(res,res,unichar);    
         ipos=ipos+2;
        }
     }
    return(res);
} // string m_UNICODE2ANSI(string s)
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_GetWatcherNumber
//+------------------------------------------------------------------+
int m_GetWatcherNumber( string a_name )
{
    // for testing uncomment
    //a_name = "watcher01";
    int num = 0;
    string match = "WATCHER";
    int lenm = StringLen(match);
    int lenc = StringLen(a_name);
    if( lenm < lenc )
    {
        string cmp = StringSubstr( a_name, 0, lenm );
        if( 0 == StringCompare( match, cmp, false ) )
        {
            string strnum = StringSubstr( a_name, lenm, 2 );
            num = (int)StringToInteger( strnum );
            //dbg ( "NUM " + IntegerToString(g_watcher_number) );
        } 
    }
    return (num);    
} // int m_GetWatcherNumber()
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_GetEnvVar
//+------------------------------------------------------------------+
int m_GetEnvVar( const string a_envvar, string& a_envvalue )
{
    int len;
    a_envvalue = SM_GetEnvironmentVariableWC( a_envvar, len );
    return(len);
} // int m_GetEnvVar( const string a_envvar, string& a_envvalue )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_CheckPredefinedVariables
//+------------------------------------------------------------------+
int m_CheckPredefinedVariables( CSymbol& s)
{
    int err = 0;
//--- Platform dependant init START
    // 10:53:40.994	EXPERT (EURUSD,M1)	 ONINIT DIGITS[4] POINTS[0.000100]
    // 10:53:42.025	EXPERT (USDJPY,M1)	 ONINIT DIGITS[4] POINTS[0.000100]
    
    s.PERIOD = Period();
    //s.SYMBOL = Symbol();

    // TODO the digit and point return values are empty
    // 2015.01.22 10:13:38.781	EXPERT (EURUSD.e,M1)	ERROR - Point Digits Startup Error SYMBOL[EURUSD] DIGITS[0] POINT[0.00000]
    s.POINT  = SymbolInfoDouble ( s.SYMBOL, SYMBOL_POINT  ); //_Point
    s.DIGITS = (int)SymbolInfoInteger( s.SYMBOL, SYMBOL_DIGITS ); //_Digits;
    
    if( PERIOD_M1 == s.PERIOD )
    {
        // OK
    }    
    else if( PERIOD_M5 == s.PERIOD )
    {
        // TO TEST
    }    
    else if( PERIOD_M15 == s.PERIOD )
    {
        // TO TEST
    }    
    else if( PERIOD_M30 == s.PERIOD )
    {
        // TO TEST
    }    
    else if( PERIOD_H1 == s.PERIOD )
    {
        // TO TEST
    }    
    else if( PERIOD_H4 == s.PERIOD )
    {
        // TO TEST
    }    
    else if( PERIOD_D1 == s.PERIOD )
    {
        // TO TEST
    }    
    else
    {
        err = -50;
        string log = "ERROR - Please implement the PERIOD = [" + EnumToString((ENUM_TIMEFRAMES)s.PERIOD) + "]";
        dbg(s, log );
        
    }
    
    bool bDigitsOk = false;
    // RoboForex  - convert EURUSD.e to EURUSUD
    //    others  - convert EURUSD   to EURUSUD
    string sym = StringSubstr( s.SYMBOL, 0 , 6 );
    if( 
         ( 0 == StringCompare( "EURUSD" , sym ) )  // OK
      || ( 0 == StringCompare( "GBPUSD" , sym ) )  // MAYBE
      || ( 0 == StringCompare( "EURGBP" , sym ) )  // NO
      || ( 0 == StringCompare( "EURCHF" , sym ) )  // NO
      || ( 0 == StringCompare( "USDCHF" , sym ) )  // NO
      || ( 0 == StringCompare( "USDCNH" , sym ) )  // NO
      || ( 0 == StringCompare( "XAGUSD" , sym ) )  // NO
      || ( 0 == StringCompare( "USDTRY" , sym ) )  // NO
      || ( 0 == StringCompare( "AUDNZD" , sym ) )  // NO
      || ( 0 == StringCompare( "USDMXN" , sym ) )  // NO
      || ( 0 == StringCompare( "USDPLN" , sym ) )  // NO
      || ( 0 == StringCompare( "AUDCAD" , sym ) )  // NO
      || ( 0 == StringCompare( "AUDCHF" , sym ) )  // NO
      || ( 0 == StringCompare( "AUDUSD" , sym ) )  // NO
      || ( 0 == StringCompare( "CADCHF" , sym ) )  // NO
      || ( 0 == StringCompare( "EURAUD" , sym ) )  // NO
      || ( 0 == StringCompare( "EURCAD" , sym ) )  // NO
      || ( 0 == StringCompare( "EURNZD" , sym ) )  // NO
      || ( 0 == StringCompare( "USDCAD" , sym ) )  // NO
      || ( 0 == StringCompare( "USDZAR" , sym ) )  // NO
      || ( 0 == StringCompare( "EURPLN" , sym ) )  // NO
      || ( 0 == StringCompare( "GBPNZD" , sym ) )  // NO
      || ( 0 == StringCompare( "GBPAUD" , sym ) )  // NO
      || ( 0 == StringCompare( "GBPCAD" , sym ) )  // NO
      || ( 0 == StringCompare( "GBPCHF" , sym ) )  // NO
      || ( 0 == StringCompare( "NZDCAD" , sym ) )  // NO
      || ( 0 == StringCompare( "NZDCHF" , sym ) )  // NO
      || ( 0 == StringCompare( "NZDUSD" , sym ) )  // NO
    )
    {
        if( (5 == s.DIGITS) && (0.00001 == s.POINT) )
        {
            bDigitsOk = true;
        }
    } 
    else if( 
         ( 0 == StringCompare( "USDRUB" , sym ) )  // OK 
    )
    {
        if( (4 == s.DIGITS) && (0.0001 == s.POINT) )
        {
            bDigitsOk = true;
        }
    } 
    else if( 
         ( 0 == StringCompare( "USDJPY" , sym ) )  // OK 
      || ( 0 == StringCompare( "EURJPY" , sym ) )  // MAYBE
      || ( 0 == StringCompare( "AUDJPY" , sym ) )  // NO
      || ( 0 == StringCompare( "CHFJPY" , sym ) )  // NO
      || ( 0 == StringCompare( "GBPJPY" , sym ) )  // NO
      || ( 0 == StringCompare( "XAUUSD" , sym ) )  // NO
      || ( 0 == StringCompare( "CADJPY" , sym ) )  // NO
      || ( 0 == StringCompare( "XAGEUR" , sym ) )  // NO
      || ( 0 == StringCompare( "NZDJPY" , sym ) )  // NO
    )
    {
        if( (3 == s.DIGITS) && (0.001 == s.POINT) )
        {
            bDigitsOk = true;
        }
    } 
    else if( 
         ( 0 == StringCompare( "XAUEUR" , sym ) )  // NO
       ||( 0 == StringCompare( "XPTUSD" , sym ) )  // NO
       ||( 0 == StringCompare( "XPDUSD" , sym ) )  // NO
    )
    {
        if( (2 == s.DIGITS) && (0.01 == s.POINT) )
        {
            bDigitsOk = true;
        }
    } 
    else
    {
        err = -51;
        string log = "ERROR - Please implement the SYMBOL = [" + s.SYMBOL + "]";
        dbg(s, log );
        
    }
    if( false == bDigitsOk )
    {
        err = -52;
        string log = "ERROR - Point Digits Startup Error SYMBOL[" + s.SYMBOL + "] DIGITS[" + IntegerToString(s.DIGITS) + "] POINT[" + DoubleToString(s.POINT,5) + "]";
        dbg(s, log );
        
    }
    
    if( 0 == err )
    {
        // TODO build 64-bit MQL2DLL library
        /*int len = m_GetEnvVar("COMPUTERNAME", g_computername);
        if( 1 > len )
        {
            err = -53;
            string log = "ERROR - m_GetEnvVar(COMPUTERNAME) len = [" + IntegerToString(len) + "]";
            dbg(s, log );
        }*/
        if( true == TESTERMODE )
        {
           g_is_master = true;
           //g_watcher_number = 0;
        }
        else
        {
           g_is_master = false;
           //g_watcher_number = m_GetWatcherNumber( g_computername );
        }
    } // if( 0 == err )

    if( (0 == err) && (true == USEDATABASE) )
    {
        
        string tmp1;
        int len = m_GetEnvVar("MYSQLHOST", tmp1);
        if( 1 > len )
        {
            err = -54;
            string log = "ERROR - m_GetEnvVar(MYSQLHOST) len = [" + IntegerToString(len) + "]";
            dbg(s, log );
        }
        else
        {
            GMYSQLHOST = m_UNICODE2ANSI(tmp1); 
        }

        string tmp2;
        len = m_GetEnvVar("MYSQLUSER", tmp2);
        if( 1 > len )
        {
            err = -55;
            string log = "ERROR - m_GetEnvVar(MYSQLUSER) len = [" + IntegerToString(len) + "]";
            dbg(s, log );
        }
        else
        {
            GMYSQLUSER = m_UNICODE2ANSI(tmp2); 
        }

        string tmp3;
        len = m_GetEnvVar("MYSQLPASS", tmp3);
        if( 1 > len )
        {
            err = -56;
            string log = "ERROR - m_GetEnvVar(MYSQLPASS) len = [" + IntegerToString(len) + "]";
            dbg(s, log );
        }
        else
        {
            GMYSQLPASS = m_UNICODE2ANSI(tmp3); 
        }

        string tmp4;
        len = m_GetEnvVar("MYSQLPORT", tmp4);
        if( 1 > len )
        {
            err = -57;
            string log = "ERROR - m_GetEnvVar(MYSQLPORT) len = [" + IntegerToString(len) + "]";
            dbg(s, log );
        }
        else
        {
            GMYSQLPORT = (int)StringToInteger(tmp4); 
        }
        
        //Print( "MYSQLHOST["+m_ANSI2UNICODE(GMYSQLHOST)+"] MYSQLUSER["+m_ANSI2UNICODE(GMYSQLUSER)+"] MYSQLPASS["+m_ANSI2UNICODE(GMYSQLPASS)+"] MYSQLPORT["+IntegerToString(GMYSQLPORT)+"]  " );

    } // if( (0 == err) && (true == USEDATABASE) )
    
//--- Platform dependant init END
    return (err);
} // int m_CheckPredefinedVariables()
//+------------------------------------------------------------------+







//+------------------------------------------------------------------+
//|  nds - double to string
//+------------------------------------------------------------------+
string nds( CSymbol& s, double p, int digits = -42 ) {
    if( -42 == digits )
    {
        digits = s.DIGITS;
    }
    if( 0 > digits )
    {
        digits = 0;
    }
    return (DoubleToString( NormalizeDouble( p,  digits), digits));
} // string nds( CSymbol& s, double p, int digits = -42 )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  nds - double to string
//+------------------------------------------------------------------+
string nds( double p, int digits ) {
    return (DoubleToString( NormalizeDouble( p,  digits), digits));
} // string nds( CSymbol& s, double p, int digits = -42 )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   dbg - print debug statement
//+------------------------------------------------------------------+
void dbg( CSymbol& s, string alog)
{
    if( VERBOSE )
        Print("DBG "+s.SYMBOL+" - " + alog); 
} // void dbg( CSymbol& s, string alog)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   dbg - print debug statement
//+------------------------------------------------------------------+
void dbg( string alog)
{
    if( VERBOSE )
        Print("DBG          - " + alog); 
} // void dbg( string alog)
//+------------------------------------------------------------------+


