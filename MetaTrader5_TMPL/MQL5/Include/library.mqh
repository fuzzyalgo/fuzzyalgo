//+------------------------------------------------------------------+
//|                                                      library.mqh |
//|                                                        andrehowe |
//|                                             http://andrehowe.com |
//+------------------------------------------------------------------+
#include <variables.mqh>
//#include <socket.mqh>

#include <Trade\DealInfo.mqh>

//
// MYSQL FUNCTIONS
//
//+------------------------------------------------------------------+
//| MYSQL FUNCTIONS                                                  |
//+------------------------------------------------------------------+

/*
CREATE TABLE IF NOT EXISTS TABLENAME ( 
id INT(10) NOT NULL AUTO_INCREMENT, 

#item
item VARCHAR(100),

# Tick Info
datetime BIGINT,
date VARCHAR(12),
time VARCHAR(12),
ask DEC(15,5),
bid DEC(15,5),

# Order Time
odatetime BIGINT,
odate VARCHAR(12),
otime VARCHAR(12),

# Ticket
orderno BIGINT,
dealno  BIGINT,
type VARCHAR(100),
statedir VARCHAR(100),

# price info
vol DEC(15,5),
price DEC(15,5),
sl DEC(15,5),
tp DEC(15,5),
profit DEC(15,5),
balance DEC(15,5),

#comment
comment VARCHAR(256),
log VARCHAR(256),

PRIMARY KEY (id), 
INDEX datetime (datetime) 
)
*/

//+------------------------------------------------------------------+
//|   m_mysql_error                                           
//+------------------------------------------------------------------+
string m_mysql_error( int handle ) 
{
   return (m_ANSI2UNICODE(mysql_error(handle)));
} // string m_mysql_error( int handle )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_sql_query                                           
//+------------------------------------------------------------------+
int m_sql_query(string _query, string _db, string _table, string _create ) 
{
    int error = m_sql_query_sub(_query);
    // TODO datetinme interface change from EPOCH to JAVA EPOCH (ms since 1970), hence datetime is a BIGINT now.
    // 2013.07.29 15:53:11	ticks USDCHF,M1: Query: INSERT INTO TICKS_M1_AL4D01 (id,datetime,date,time,bid,ask,volume,tvol,rvol,ms,cvol ) VALUES (0,1375113191908,'2013.07.29','15:53:11',0.93199,0.93210,0,15,0,250,12) 
    // 2013.07.29 15:52:57	ticks USDCHF,M1: INSERT INTO TABLE ERROR: 1264
    // 2013.07.29 15:51:54	ticks USDCHF,M1: Returned error: Out of range value for column 'datetime' at row 1
    if( error == 1264 ){
        string alterq = "";
        StringConcatenate(alterq, "ALTER TABLE `",_db,"`.`",_table,"` CHANGE COLUMN `datetime` `datetime` BIGINT(20) NULL DEFAULT NULL AFTER `id`" );
        error = m_sql_query_sub(alterq);
        if( error > 0 ){
            dbg("ALTER TABLE ERROR: "+ IntegerToString(error));        
            dbg("Mysql connection error = "+m_mysql_error(GMYSQLH));
            return (42);
        }
        dbg("Successfully altered TABLE!");
        m_sql_query_sub(_query);
        
    // 2014.03.03 17:01:15.939	TICKS (EURUSD,M1)	CREATE TABLE IF NOT EXISTS ERROR: 1049
    // 2014.03.03 17:04:24.923	TICKS (EURUSD,M1)	Returned error: Unknown database 'fx_eurusd'
    } else if( error == 1049 ){
        string _createdb = "";
        StringConcatenate(_createdb,"CREATE DATABASE IF NOT EXISTS ",_db);
        error = m_sql_query_sub(_createdb);
        if( error > 0 ){
            dbg("CREATE DATABASE IF NOT EXISTS "+_db+" - ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
            return (error);
        }
        error = m_sql_query_sub(_create);
        if( error > 0 ){
            dbg("CREATE TABLE IF NOT EXISTS "+_db+"."+_table+" - ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
            return (error);
        }
        dbg("Successfully created TABLE `"+_db+"`.`"+_table+"`");
        m_sql_query_sub(_query);
    
    // TODO if the table has been dropped in between due to error then create a new one
    // 16:07:11 ticks USDCHF,M1: Query: INSERT INTO TICKS_M1_AL4D01 (id,datetime,date,time,bid,ask,volume,tvol,rvol,ms,cvol ) VALUES (0,1375114031324,'2013.07.29','16:07:11',0.93154,0.93165,0,22,0,250,19) 
    // 16:07:11 ticks USDCHF,M1: Returned error: Table 'fx_usdchf.ticks_m1_al4d01' doesn't exist
    // 16:07:11 ticks USDCHF,M1: INSERT INTO TABLE ERROR: 1146
    } else if( error == 1146 ){
        error = m_sql_query_sub(_create);
        if( error == 1049 )
        {
            string _createdb = "";
            StringConcatenate(_createdb,"CREATE DATABASE IF NOT EXISTS ",_db);
            error = m_sql_query_sub(_createdb);
            if( error > 0 ){
                dbg("CREATE DATABASE IF NOT EXISTS "+_db+" - ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
                return (error);
            }
            error = m_sql_query_sub(_create);
            if( error > 0 ){
                dbg("CREATE TABLE IF NOT EXISTS "+_db+"."+_table+" - ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
                return (error);
            }
            dbg("Successfully created TABLE `"+_db+"`.`"+_table+"`");
        }                
        else if( error > 0 )
        {
            dbg("CREATE TABLE IF NOT EXISTS ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
            return (error);
        }
        dbg("Successfully created TABLE!");
        m_sql_query_sub(_query);
        
    } else if( error > 0 ){
        dbg("INSERT INTO TABLE ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
        if( GMYSQLH != 0 ){
            mysql_close(GMYSQLH);
        }
        GMYSQLH=mysql_init(0);
        if (GMYSQLH == 0) {
            dbg("mysql_init ERROR!!!");
            return (1);
        }   
        int res=mysql_real_connect(GMYSQLH,GMYSQLHOST,GMYSQLUSER,GMYSQLPASS,m_UNICODE2ANSI(_db),GMYSQLPORT,"",0);
        dbg("connection result="+IntegerToString(res));
        if (res==GMYSQLH){
            dbg("Successfully connected to the MySQL server!");
            m_sql_query_sub(_query);
        }else { 
            dbg("Mysql connection error = "+m_mysql_error(GMYSQLH));
            return (2);
        }
    }
    return (0);
} // int m_sql_query(string _query, string _db, string _table, string _create )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_sql_query_sub                                           
//+------------------------------------------------------------------+
int m_sql_query_sub(string _query) 
{
    if( true == GMYSQL_INIT_FAILED ) return (0);
    int length=StringLen(_query);
    mysql_real_query(GMYSQLH,m_UNICODE2ANSI(_query),length);
    int mysqlerr=mysql_errno(GMYSQLH);
    if (mysqlerr>0)
    {
        dbg("Query: "+_query);
        dbg("Returned error: "+m_mysql_error(GMYSQLH) );       
    }      
    return (mysqlerr);
} // int m_sql_query_sub(string _query)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_sql_close                                           
//+------------------------------------------------------------------+
void m_sql_close() 
{
   mysql_close(GMYSQLH); //Close connection
} // void m_sql_close() 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_sql_init                                           
//+------------------------------------------------------------------+
int m_sql_init(CSymbol& s) 
{
    if( GMYSQLH != 0 ){
        mysql_close(GMYSQLH);
    }
    GMYSQLH=mysql_init(0);
    if (GMYSQLH == 0) {
        dbg("mysql_init ERROR!!!");
        return(1);
    }   
    dbg("mysql handle="+IntegerToString(GMYSQLH));
    // at first connect the DB name is empty "", as it mabe created and used later
    int res=mysql_real_connect(GMYSQLH,GMYSQLHOST,GMYSQLUSER,GMYSQLPASS,"",GMYSQLPORT,"",0);
    dbg("connection result="+IntegerToString(res));
    if (res==GMYSQLH){
        dbg("Successfully connected to the MySQL server!");
    }else { 
        dbg("Mysql connection error = "+m_mysql_error(GMYSQLH));
        return(2);
    } 
    return (0);
} // int m_sql_init(CSymbol& s) 
//+------------------------------------------------------------------+
    
//+------------------------------------------------------------------+
//|   m_sql_createdb                                           
//+------------------------------------------------------------------+
int m_sql_createdb(CSymbol& s) 
{
    //Create expert history database
    string query = "CREATE DATABASE IF NOT EXISTS " + s.g_db_expert;
    int error = m_sql_query_sub(query);
    if( error > 0 ){
        dbg("CREATE DATABASE "+s.g_db_expert+" ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
        return (error);
    }
    /*query = "USE " + _db;
    error = m_sql_query_sub(query);
    if( error > 0 ){
        dbg("USE "+_db+" ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
        return (error);
    }*/

    // create the report database FX_REPORT
    query = "CREATE DATABASE IF NOT EXISTS " + s.g_db_log;
    error = m_sql_query_sub(query);
    if( error > 0 ){
        dbg("CREATE DATABASE "+s.g_db_log+" ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
        return (error);
    }

    //Create ticks table
    query = "CREATE DATABASE IF NOT EXISTS " + s.g_db_ticks;
    error = m_sql_query_sub(query);
    if( error > 0 ){
        dbg("CREATE DATABASE "+s.g_db_ticks+" ERROR: "+ IntegerToString(error) + " " +m_mysql_error(GMYSQLH));
        return (error);
    }
    return (0);
} // int m_sql_createdb(CSymbol& s) 
//+------------------------------------------------------------------+

//
// MYSQL LOG FUNCTIONS
//
//+------------------------------------------------------------------+
//| MYSQL LOG FUNCTIONS                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_log_history_to_sql
//+------------------------------------------------------------------+
void m_log_history_to_sql(  CSymbol& s, string item, datetime ttime,
                            ulong otimemsc, datetime otime,
                            ulong orderno, ulong dealno, string type, string statedir,
                            double vol, double price, double sl, double tp, double profit, double balance,
                            string comment,
                            string log, double commission=0, double swap=0 )
{

    // TODO TIME - subtract one hour for certain accounts
    //   still TODO otimemsc adjustment
    if(( true == ADJUSTTIME ) && ( true == TESTERMODE )){
        ttime = m_HourDec(ttime);
    } // if(( true == ADJUSTTIME ) && ( true == TESTERMODE ))
    if( true == ADJUSTTIME ) {
        if( 0 < otime ){
            otime = m_HourDec(otime);
        }
    } // if( true == ADJUSTTIME )

    if( VERBOSE )
    {
        string vlog = StringFormat(
                "H[%s] DT[%s] ASK[%1.5f] BID[%1.5f] OTMSC[%I64d] OT[%s] ORDER[%d] DEAL[%d] TYPE[%s] SD[%s] VOL[%0.2f] PRICE[%1.5f] SL[%1.5f] TP[%1.5f] PROFIT[%3.1f] BAL[%0.2f] C[%s]",
                            item,
                            TimeToString( ttime, TIME_SECONDS ), s.ASK, s.BID,
                            otimemsc, TimeToString( otime, TIME_SECONDS ),
                            orderno, dealno, type, statedir,
                            vol, price, sl, tp, profit, balance,
                            comment 
                            );
        dbg(s, vlog);
    }
    
    if( true == GMYSQL_INIT_FAILED ) return;
    
    if( 0.0 == balance ){
        balance = AccountInfoDouble(ACCOUNT_BALANCE);
    }
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // datetime ms - dtms
    datetime dt = ttime;
    string aid = "0";
    string atdatetime = "";
    // Interface to float.js library - The timestamps must be specified as Javascript timestamps, as milliseconds since January 1, 1970 00:00. This is like Unix timestamps, but in milliseconds instead of seconds (remember to multiply with 1000!).
    int len = StringConcatenate(atdatetime, IntegerToString(dt), m_GetMilliSecondsAsString( TESTERMODE ) );
    string atdate = TimeToString(ttime,TIME_DATE);
    string attime = TimeToString(ttime,TIME_SECONDS);
    string abid  = nds(s,s.ASK);
    string aask  = nds(s,s.BID);

    // orderno time
    string adatetime = IntegerToString(otimemsc);
    string adate = TimeToString(otime,TIME_DATE);
    string atime = TimeToString(otime,TIME_SECONDS);
    
    // ticket
    string aorderno = IntegerToString(orderno);
    string adealno  = IntegerToString(dealno);
    // string type;
    // string statedir;
    
    // price info
    string avol  = nds(s,vol, 2);
    string aprice = nds(s,price);
    string asl = nds(s,sl);
    string atp = nds(s,tp);
    string aprofit  = nds(s,profit, 2);
    string acommission  = nds(s,commission, 2);
    string aswap  = nds(s,swap, 2);
    string abalance  = nds(s,balance,2);
    string aequity  = nds(s,equity, 2);
    
    // string comment

    string query = "";
    // CREATE FX_SYMBOL.ACCKEY_EXPERT IF NOT EXISTS TABLENAME ( id INT(10) NOT NULL AUTO_INCREMENT, item VARCHAR(100), datetime BIGINT, date VARCHAR(12), time VARCHAR(12), ask DEC(15,5), bid DEC(15,5), odatetime BIGINT, odate VARCHAR(12), otime VARCHAR(12), orderno BIGINT, dealno BIGINT, type VARCHAR(100), statedir VARCHAR(100), vol DEC(15,5), price DEC(15,5), sl DEC(15,5), tp DEC(15,5), profit DEC(15,5), commission DEC(15,5), swap DEC(15,5), balance DEC(15,5), equity DEC(15,5), comment VARCHAR(200), log VARCHAR(256), PRIMARY KEY (id), INDEX datetime (datetime) )
    len = StringConcatenate(query,"INSERT INTO ",s.g_db_expert,".",s.g_table_expert," (id,item,datetime,date,time,ask,bid,odatetime,odate,otime,orderno,dealno,type,statedir,vol,price,sl,tp,profit,commission,swap,balance,equity,comment,log) VALUES (",aid,",'",item,"',",atdatetime,",'",atdate,"','",attime,"',",aask,",",abid,",",adatetime,",'",adate,"','",atime,"',",aorderno,",",adealno,",'",type,"','",statedir,"',",avol,",",aprice,",",asl,",",atp,",",aprofit,",",acommission,",",aswap,",",abalance,",",aequity,",'",comment,"','",log,"') ");
    m_sql_query( query, s.g_db_expert, s.g_table_expert, s.g_table_expert_create );
    
} // void m_log_history_to_sql(  CSymbol& s, string item, datetime ttime,

//+------------------------------------------------------------------+
//| Log2Sql
//+------------------------------------------------------------------+
void Log2Sql( CSymbol& s, string aitem, int aerror, string alog ) 
{

    dbg(s, alog);
    if( false == USEDATABASE )
    {
        return;
    }
    
    // datetime ms - dtms
    datetime dt = (datetime)TimeLocal(); //tick.time;
    string aid = "0";
    string adatetime = "";
    // Interface to float.js library - The timestamps must be specified as Javascript timestamps, as milliseconds since January 1, 1970 00:00. This is like Unix timestamps, but in milliseconds instead of seconds (remember to multiply with 1000!).
    StringConcatenate(adatetime, IntegerToString(dt), m_GetMilliSecondsAsString( TESTERMODE ) );
    string adate = TimeToString(dt,TIME_DATE);
    string atime = TimeToString(dt,TIME_SECONDS);
    string asymbol = s.SYMBOL;
	// convert EURUSD.e to EURUSD - for e.g. RE5R accounts
	if( 6 < StringLen(asymbol) ) {
		asymbol = StringSubstr(asymbol,0,6);
	}
    // convert Period_M1 to M1
    string aperiod = ConvertPeriodToString(s.PERIOD);
    int pos = StringFind(aperiod,"_" );
    if( 0 < pos ) {
        aperiod = StringSubstr( aperiod, pos+1 ); 
    }
    // convert EXPERT_PROPKEY_ACCKEY_N to EXPERT PROPKEY ACCKEY
    string acomputername  = g_computername;
    string apropkey = PROPKEY;
    string aacckey  = ACCKEY;
    // TODO leave the following lines of code
    // maybe create a helper split library function
    /* int start = 0; int end = 0;
    end = StringFind( atable, "_", start );
    aexpert = StringSubstr( atable, start, end-start ); 
    start = end+1;
    end = StringFind( atable, "_", start );
    apropkey = StringSubstr( atable, start,end-start ); 
    start = end+1;
    end = StringFind( atable, "_", start );
    aacckey = StringSubstr( atable, start,end-start ); */
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin  = AccountInfoDouble(ACCOUNT_MARGIN);

    // CREATE TABLE IF NOT EXISTS FX_REPORT.EXPERT_LOG (id INT(10) NOT NULL AUTO_INCREMENT, datetime BIGINT, date VARCHAR(12), time VARCHAR(12), symbol VARCHAR(10), period VARCHAR(10), computername VARCHAR(100), propkey VARCHAR(100), acckey VARCHAR(100), item VARCHAR(100), error INT(10), version VARCHAR(10), buypos INT(10), sellpos INT(10), buyord INT(10), sellord INT(10), balance DEC(15,2), equity DEC(15,2), margin DEC(15,2), log MEDIUMTEXT, PRIMARY KEY (id), INDEX datetime (datetime) )
    string query = "INSERT INTO "+s.g_db_log+"."+s.g_table_log+" (id,datetime,date,time,symbol,period,computername,propkey,acckey,item,error,version,buypos,sellpos,buyord,sellord,balance,equity,margin,log) VALUES ("+aid+","+adatetime+",'"+adate+"','"+atime+"','"+asymbol+"','"+aperiod+"','"+acomputername+"','"+apropkey+"','"+aacckey+"','"+aitem+"',"+IntegerToString(aerror)+",'"+VERSION+"','"+IntegerToString(s.g_watcher_data.posopenbuycnt)+"','"+IntegerToString(s.g_watcher_data.posopensellcnt)+"','"+IntegerToString(s.g_watcher_data.ordbuycnt)+"','"+IntegerToString(s.g_watcher_data.ordsellcnt)+"','"+nds(s,balance,2)+"','"+nds(s,equity,2)+"','"+nds(s,margin,2)+"','"+alog+"')";  
    m_sql_query( query, s.g_db_log, s.g_table_log, s.g_table_log_create );
    
} // void Log2Sql( CSymbol& s, string aitem, int aerror, string alog ) 
//+------------------------------------------------------------------+

//
// ACCOUNT FUNCTIONS
//
//+------------------------------------------------------------------+
//| ACCOUNT FUNCTIONS                                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_AccountInformation                                           |
//+------------------------------------------------------------------+
void m_AccountInformation()
{
    // ONINIT DIGITS[5] POINTS[0.000010]
    dbg( "ACCOUNT_NAME:    " + AccountInfoString(ACCOUNT_NAME));
    dbg( "ACCOUNT_SERVER:  " + AccountInfoString(ACCOUNT_SERVER));
    dbg( "ACCOUNT_COMPANY: " + AccountInfoString(ACCOUNT_COMPANY));
    dbg( "ACCOUNT_LEVERAGE: 1:" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)));

    //
    // GET ADJUSTTIME depending on account information
    //
    string server = AccountInfoString(ACCOUNT_SERVER);
    StringToLower(server);
    int pos = StringFind( server, "alpari", 0 );
    if( pos >= 0 ){ ADJUSTTIME = true; }
    pos = StringFind( server, "roboforex", 0 );
    if( pos >= 0 ){ ADJUSTTIME = true; }
    pos = StringFind( server, "metaquotes", 0 );
    if( pos >= 0 ){ ADJUSTTIME = true; }
    
    // TODO review me
    if( false == ADJUSTTIMEENABLED )
    {
        ADJUSTTIME = false;
    }
    
    if( true == ADJUSTTIME ){
        datetime tc = TimeCurrent();
        datetime ta = m_HourDec(tc);
        dbg("Found ADJUSTTIME server [" + AccountInfoString(ACCOUNT_SERVER) + 
              "] from [" + TimeToString(tc, TIME_DATE | TIME_SECONDS ) + "] to [" + TimeToString(ta, TIME_DATE | TIME_SECONDS ) + "]" );
    }
    
    // call getdt function with true to verbosely output the system time
    // and ignore the return value - in case the trade server time is not running yet
    dbg( "Time GMT: " + TimeToString(TimeGMT(), TIME_DATE | TIME_SECONDS ));
    dbg( "Time CUR: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS ));
    dbg( "Time LOC: " + TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS ));
    dbg( "Time TRA: " + TimeToString(TimeTradeServer(), TIME_DATE | TIME_SECONDS ));
    dbg( "Time DST: " + IntegerToString(TimeDaylightSavings()));
    dbg( "Time OFF: " + IntegerToString(TimeGMTOffset()));
/*
RF account - wrong Time Cur
DO  0   23:56:28    expert (EURUSD,M1)   ONINIT DIGITS[4] POINTS[0.000100]
FD  0   23:56:28    expert (EURUSD,M1)  The counters of orders, positions and deals are successfully initialized
NM  0   23:56:28    expert (EURUSD,M1)  Time GMT: 2013.08.28 21:56
QD  0   23:56:28    expert (EURUSD,M1)  Time CUR: 1970.01.01 00:00
NL  0   23:56:28    expert (EURUSD,M1)  Time LOC: 2013.08.28 23:56
QD  0   23:56:28    expert (EURUSD,M1)  Time TRA: 2013.08.29 00:56
QO  0   23:56:28    expert (EURUSD,M1)  Time DST: -3600
ME  0   23:56:28    expert (EURUSD,M1)  Time OFF: -7200
OS  0   23:56:28    expert (EURUSD,M1)  ACCOUNT_NAME:    Will Smith
OJ  0   23:56:28    expert (EURUSD,M1)  ACCOUNT_SERVER:  RoboForex-MetaTrader 5
NS  0   23:56:28    expert (EURUSD,M1)  ACCOUNT_COMPANY: RoboForex LP
GI  0   23:56:28    expert (EURUSD,M1)  Found ADJUSTTIME server [RoboForex-MetaTrader 5] from [1970.01.01 00:00] to []
JG  0   23:56:29    expert (EURUSD,M1)  INIT - Expert[EXPERT] Version[0.01] Error[0]
*/
    
} // void m_AccountInformation() 


//
// TIME/PERIOD FUNCTIONS
//
//+------------------------------------------------------------------+
//| TIME/PERIOD FUNCTIONS                                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_AlgorithmIsNewSync
//+------------------------------------------------------------------+
bool m_AlgorithmIsNewSync( CSymbol& s, bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick )
{

    // TODO clean me up - a bit ugly - maybe make TICKS EA part of the normal EA
    // if this is not the TICKS EA - as TICKS is neither MASTER nor a SLAVE
    // if this is a watcher then log the watcher data
    // only the master is allowed to log to the database if not in tester mode
    if( (true == g_is_master) && (false == TESTERMODE) )
    {
        m_GetWatcherData( s );
        m_LogWatcherData( s );
    }

    bool bIsNewSync = false;
    if( E_ALGOSYNC_TIME == g_algosync )
    {
        bIsNewSync = _bIsNewTime;
    } 
    else if( E_ALGOSYNC_BAR == g_algosync )
    {
        bIsNewSync = _bIsNewBar;
    } 
    else if( E_ALGOSYNC_TICK == g_algosync )
    {
        bIsNewSync = _bIsNewTick;
    } 
    else
    {
        string log = "ERROR - Please implement the input string ALGOSYNC = [" + ALGOSYNC + "]";
        dbg( s, log );
    } // if( E_ALGOSYNC_TIME == g_algosync )
    
    // if this is not the TICKS EA - as TICKS is neither MASTER nor a SLAVE
    // if this is a newsync and a SLAVE then modify/open 
    //  pending orders (in case the other EA has died).
    if( E_ALGORITHM_TICKS != g_algorithm )
    {
       if( (true == bIsNewSync) && ( false == g_is_master ) )
       {
           bIsNewSync = false;
       } // if( (true == bIsNewSync) && ( 0 < g_watcher_number ) )
    }   
    
    return (bIsNewSync);
} // bool m_AlgorithmIsNewSync( bool _bIsNewBar, bool _bIsNewTime, bool _bIsNewTick )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_DoStopTrading - balance handler
//+------------------------------------------------------------------+
e_algostoptrading m_DoStopTrading(CSymbol& s)
{
    double bal = AccountInfoDouble( ACCOUNT_BALANCE );
    double equ = AccountInfoDouble( ACCOUNT_EQUITY );
    
    e_algostoptrading st = E_ALGOSTOPTRADING_ERR;
    
    if( true == TESTERMODE )
    { 
        st = E_ALGOSTOPTRADING_FALSE;
    }
    else
    {
        long tvol = iTickVolume( s.SYMBOL, s.PERIOD, 0 );
        int pos_tot = (int) PositionsTotal();
        int ord_tot = (int) OrdersTotal();
        uint tc = GetTickCount();
        double inc = 0;
        if( (0<equ) && (0<g_balance_start) ) { inc = (equ/g_balance_start-1)*100; }
        string str_tx=StringFormat("%03d %s %s %s %s %s %s %s %s %s %s %s %s %d %d",tvol, IntegerToString(g_time_local),
                             TimeToString(g_time_local,TIME_DATE|TIME_SECONDS),g_computername, ACCKEY, PROPKEY, CONTKEY,
                             g_contstate,g_tradstate,nds(s,g_balance_start,2),nds(s,bal,2),nds(s,equ,2),nds(s,inc,2), pos_tot, ord_tot );
        string str_rx;
        uint err = m_Write2Host( s, str_tx, str_rx );
        if((err!=ERROR_SUCCESS)&&(0<VERBOSE))
        {
            dbg(s, "SOCK ERR TX: " + str_tx);
            dbg(s, "SOCK ERR RX: " + str_rx);
        }
        else
        {
            string s_sep=":";                // A separator as a character
            ushort u_sep;                  // The code of the separator character
            string str_rx_split[];               // An array to get strings
            //--- Get the separator code
            u_sep=StringGetCharacter(s_sep,0);
            //--- Split the string to substrings
            int num_sep=StringSplit(str_rx,u_sep,str_rx_split);
            //--- Show a comment 
            //PrintFormat("Strings obtained: %d. Used separator '%s' with the code %d",num_sep,s_sep,u_sep);
        
            // "STOP:MASTER|CONT:SLAVE" at least is sent back from the master controller        
            if( 2 <= num_sep )
            {
                if( 0 == StringCompare(str_rx_split[1], "MASTER", false) )
                {
                    // TODO INTERFACE
                    //dbg( "MASTER TRADING ("+ str_rx_split[1] + ")" );
                    g_is_master = true;
                    g_contstate = "MASTER";
                }
                if( 0 == StringCompare(str_rx_split[1], "SLAVE", false) )
                {
                    // TODO INTERFACE
                    //dbg( "SLAVE TRADING ("+ str_rx_split[1] + ")" );
                    g_is_master = false;
                    g_contstate = "SLAVE";
                }
            }
            
            // "STOP|CONT" at least is sent back from the master controller        
            if( 1 <= num_sep )
            {
                if( 0 == StringCompare(str_rx_split[0], "STOP", false) )
                {
                    // TODO INTERFACE
                    //dbg( "STOP TRADING ("+ str_rx_split[0] + ")" );
                    st = E_ALGOSTOPTRADING_TRUE;
                }
                if( 0 == StringCompare(str_rx_split[0], "CONT", false) )
                {
                    // TODO INTERFACE
                    //dbg( "CONT TRADING ("+ str_rx_split[0] + ")" );
                    st = E_ALGOSTOPTRADING_FALSE;
                }
            } // if( 1 <= num_sep )
                        
            // if the tcp connection was working 
            //   then overwrite the current STOP trading command
            if(E_ALGOSTOPTRADING_ERR!=st)
            {
                if(E_ALGOSTOPTRADING_FALSE==st) {
                    g_tradstate = "CONT";
                }
                if(E_ALGOSTOPTRADING_TRUE==st) {
                    g_tradstate = "STOP";
                }
            } // if(E_ALGOSTOPTRADING_ERR!=st)

            if(E_ALGOSTOPTRADING_ERR==st)
            {
                //dbg( "ERR TRADING ("+ str_rx + ")" );
            }            
        } // if(err!=ERROR_SUCCESS)
        
    } // if( true == TESTERMODE )
    //dbg( "m_DoStopTrading: " + EnumToString((e_algostoptrading)st) + "  " + IntegerToString(s.g_stop_trading) );

    // the EA overwrites the result above in case it already reached its daily limit
    // that happens for any mode TESTERMODE
    // that helps in case TCPSERVER or perl or both is broken
    if(    ( 0 < bal ) && ( 0 < equ ) && ( 0 < g_balance_start )
        && ( bal == equ ) && ( 0 < g_balance_start_increase )
        && ( bal > g_balance_start*g_balance_start_increase ) 
      ) 
    {
        st = E_ALGOSTOPTRADING_TRUE;
    } 
    
    return (st);
       
    // keep this code for the implementation of E_ALGOPARAM_BALANCECONTROLLER    
    /*// we assume the balance controller is running
    else
    {
        //--- write the balance and equity to a CSV file
        ResetLastError();
        // TODO INTERFACE
        int handle=FileOpen("bal.csv",FILE_WRITE|FILE_ANSI,';');
        if(handle!=INVALID_HANDLE)
        {
            FileWrite(handle,TimeToString(g_time_local,TIME_DATE|TIME_SECONDS),IntegerToString(g_time_local),DoubleToString(g_balance_start,2),DoubleToString(bal,2),DoubleToString(equ,2), "END");
            FileClose(handle);
        }
        else
        {
            // TODO - re-think the error handling here
            //if( 3 > g_onerror_cnt )
            //{
            //    g_onerror_cnt++;
            //    string log = "File open BAL.CSV failed with error: "+IntegerToStr(GetLastError());
            //    Log2Sql( "ERROR", -51, log );
            //}
        } // if(handle!=INVALID_HANDLE)

        //--- read trading control statement from the CSV file
        ResetLastError();
        // TODO INTERFACE
        handle=FileOpen("control.csv",FILE_READ|FILE_ANSI,';');
        if(handle!=INVALID_HANDLE)
        {
            string stop;
            stop = FileReadString(handle,1);
            FileClose(handle);
            if( 0 == StringCompare(stop, "STOP", false) )
            {
                // TODO INTERFACE
                //dbg( "STOP TRADING" );
                return (E_ALGOSTOPTRADING_TRUE);
            }
            if( 0 == StringCompare(stop, "CONT", false) )
            {
                // TODO INTERFACE
                //dbg( "CONT TRADING" );
                return (E_ALGOSTOPTRADING_FALSE);
            }
        } // if(handle!=INVALID_HANDLE)
        
    } // if( (E_ALGOPARAM_BALANCECONTROLLER != g_algoparam) || (true == TESTERMODE) )
    return (E_ALGOSTOPTRADING_ERR);*/
    
} // e_algostoptrading m_DoStopTrading()

//+------------------------------------------------------------------+
//| m_TradingTimeAllowed
//+------------------------------------------------------------------+
bool m_TradingTimeAllowed( datetime dt )
{
    MqlDateTime t;
    TimeToStruct(dt,t);
    // if day of week is saturday (6) or sunday (0)
    if( (6==t.day_of_week) || (0==t.day_of_week) )
    {
        return (false);
    }
    
    //// trade only from 3rd of Jan until 22nd of December
    //if( (3>t.day_of_year) || (356<t.day_of_year) )
    //{
    //    return (false);
    //}
    
    // TODO implement 
    // SymbolInfoSessionTrade and SymbolInfoSessionQuotes instead

    //// task scheduler runs mt-startup every night Mo-Fr
    //if((0 == t.hour)||(1 == t.hour)){
    //   return (false);
    //}    
    //if(( 23 == t.hour ) && ( 45 <= t.min )){
    //   return (false);
    //} 

    
    //// task scheduler runs mt-startup only Sun night
    //// Friday  
    //if( (5==t.day_of_week) && (21 < t.hour) )
    //{
    //    return (false);
    //}
    
    // Monday  
    if( (1==t.day_of_week) && (4 > t.hour) )
    {
        return (false);
    }
    
    return (true);
} // bool m_TradingTimeAllowed( datetime dt )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Is trading logically allowed on the platform. TODO pass the check as input
//+------------------------------------------------------------------+
bool m_TradingAllowed(CSymbol& s)
{

    // keep order # 1
    // stop trading after the current account balance
    // has been reaches an g_balance_start_increase in percent
    // increase against account balance when the new day started
    // TODO code review - remove here - otherwise it will never be set after startup
    //if( (0 == g_balance_start) && (E_ALGORITHM_TICKS != g_algorithm) )
    if( (0 == g_balance_start) && (E_ALGORITHM_TICKS != g_algorithm) )
    {
    
        //
        // TODO this does not work over X-MAS
        //  m_GetShiftSinceNewDayStarted is not bank holiday safe
        //   see point X-Mas trading at https://trac.nohowe.com/wiki/OrderAlgorithmDefects
        //
        
        
        int total = GSYMBOLLIST.Total();
        for( int cnt = 0; cnt < total; cnt++ )
        {
            CSymbol* sv = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
            m_vFindIfMarketWasVolatileToday(sv);
        } // for( int cnt = 0; cnt < total; cnt++ )
        
        
        
        /*int total = GSYMBOLLIST.Total();
        int shift = m_GetShiftSinceNewDayStarted(s) + 36000;
        dbg(s, "m_vFindIfMarketWasVolatileToday2 " + IntegerToString(shift ) );
        for( ; shift > 0; shift-- )
        {
            for( int cnt = 0; cnt < total; cnt++ )
            {
                CSymbol* sv = (CSymbol*)GSYMBOLLIST.GetNodeAtIndex(cnt);
                string log = ""; double pivot = 0; int wa; int wa2;
                if( true == iMarketIsVolatile(sv,log,pivot, wa, wa2, shift) )
                {
                    dbg(sv, log );
                }
            }
        }
        dbg(s, "m_vFindIfMarketWasVolatileToday2 END" );*/
        
   
        //
        // TODO this does not work over X-MAS
        //  m_GetShiftSinceNewDayStarted is not bank holiday safe
        //   see point X-Mas trading at https://trac.nohowe.com/wiki/OrderAlgorithmDefects
        //
        // TODO a bit ugly - refactor the names, which are misleading
        // find the value for g_balance_start
        // this did not work after the SNB swiss franc euro crash on the 
        // 2015 01 15 as the USDCHF chart just stopped on that day
          //int shift = m_GetShiftSinceNewDayStarted();
          //datetime tp = iTime(SYMBOL, PERIOD, shift ) /*+ PeriodSeconds(PERIOD)*/;
        // this doesn't seem to work always
        //datetime tpold = D'00:00:00';  
        // hence use instead        
        MqlDateTime t;
        TimeToStruct(g_time_local,t);
        t.hour = 0; t.min = 0; t.sec = 0;
        datetime tp = StructToTime(t);  
        datetime tn = g_time_current + 1;
        m_GetHistoryInfo(tp,tn);
        // check if m_GetHistoryInfo was successful
        if( 0 == g_balance_start ) {
            return (false);
        }
    } // if( 0 == g_balance_start )


    // TODO clean me up - a bit ugly
    // do this before hand - otherwise the perl dokillupdater
    // won't show any balances after a mt-startup
    e_algostoptrading st = m_DoStopTrading(s);
    
    // trading is alway allowed for the ticks algorithm
    // but keep the order and do not move this line
    if(E_ALGORITHM_TICKS == g_algorithm) 
    {
        return (true);
    }

    // keep order # 2
    if( false == m_TradingTimeAllowed(g_time_local))
    {
        return (false);
    }
    
    // keep order # 3
    // shall we stop trading because the balance is high enough
    
    if( E_ALGOSTOPTRADING_TRUE == st )
    {
        if( false == s.g_stop_trading )
        {
            s.g_stop_trading = true;
        }
        return (false);
    }
    else if( E_ALGOSTOPTRADING_FALSE == st )
    {
        if( true == s.g_stop_trading )
        {
            s.g_stop_trading = false;
        }
        return (true);
    }
    else if( E_ALGOSTOPTRADING_ERR == st )
    {
        if( true == s.g_stop_trading )
        {
            return (false);
        }
        else if( false == s.g_stop_trading )
        {
            return (true);
        }
    } // if( E_ALGOSTOPTRADING_TRUE == st )

    return (true);

} // bool m_TradingAllowed(CSymbol& s)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_GetShiftSinceNewDayStarted
//+------------------------------------------------------------------+
// TODO NORM merge this function with m_GetShiftSinceDayStarted
int m_GetShiftSinceNewDayStarted(CSymbol& s)
{
    string slog = StringFormat( "ERROR m_GetShiftSinceDayStarted2(period = %s )", EnumToString((ENUM_TIMEFRAMES)s.PERIOD) ) ;
    
    MqlDateTime tm;
    datetime t0 = g_time_local;
    if( true == ADJUSTTIME ){
        t0 = m_HourDec(t0);
    }
    TimeToStruct( t0, tm );
    
    int shift = 0;
    
    int index = m_GetNormtIndexFromTF(s.PERIOD);
    
    switch(index)
    {
    
        case N_INDEX_M1:
            shift = tm.hour*60 + tm.min/1; 
            break;
        case N_INDEX_M5: 
            shift = tm.hour*12 + tm.min/5; 
            break;
        case N_INDEX_M15: 
            shift = tm.hour*4 + tm.min/15; 
            break;
        case N_INDEX_M30: 
            shift = tm.hour*2 + tm.min/30; 
            break;
        case N_INDEX_H1:
            shift = tm.hour; 
            break;
        case N_INDEX_H4: 
            shift = tm.hour/4; 
            break;
        case N_INDEX_D1: 
            shift = 0; 
            break;
        default:
            dbg(s, slog );
            break;
            
    } // switch(aTf)
    
    return (shift);
    
} // int  m_GetShiftSinceNewDayStarted()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Returns true if the new day has started
//+------------------------------------------------------------------+
bool m_IsNewDay(CSymbol& s, datetime datenew)
{
    // 1) check if s.g_tm_prev_day with an uninatialised time
    //     if so then set it with the datenew
    datetime dateprev = StructToTime(s.g_tm_prev_day);
    if( 0 == dateprev )
    {
        TimeToStruct(datenew,s.g_tm_prev_day);
        return false;
    }
    
    // 2) check if there is a new year
    MqlDateTime tm;
    TimeToStruct(datenew,tm);
    if( s.g_tm_prev_day.day != tm.day )
    {
        string log = "NEW DAY1: " +  IntegerToString( tm.day  ) + " ASK/BID "  + nds(s,s.ASK) + " / " + nds(s,s.BID) + " / NEW: " + TimeToString( datenew, TIME_DATE|TIME_SECONDS ) + " / OLD: " +  TimeToString( dateprev, TIME_DATE|TIME_SECONDS );
        Log2Sql( s, "MARKET", 0, log );
        s.g_tm_prev_day = tm;
        return(true);
    }
    return(false);
} // bool m_IsNewDay(CSymbol& s, datetime date)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Returns true if the new day has started
//+------------------------------------------------------------------+
bool m_IsNewDay2(CSymbol& s, datetime datenew)
{
    // 1) check if s.g_tm_prev_day2 with an uninatialised time
    //     if so then set it with the datenew
    datetime dateprev = StructToTime(s.g_tm_prev_day2);
    if( 0 == dateprev )
    {
        TimeToStruct(datenew,s.g_tm_prev_day2);
        return false;
    }
    
    // 2) check if there is a new year
    MqlDateTime tm;
    TimeToStruct(datenew,tm);
    if( s.g_tm_prev_day2.day != tm.day )
    {
        string log = "NEW DAY2: " +  IntegerToString( tm.day  ) + " ASK/BID "  + nds(s,s.ASK) + " / " + nds(s,s.BID) + " / NEW: " + TimeToString( datenew, TIME_DATE|TIME_SECONDS ) + " / OLD: " +  TimeToString( dateprev, TIME_DATE|TIME_SECONDS );
        Log2Sql( s, "MARKET", 0, log );
        s.g_tm_prev_day2 = tm;
        return(true);
    }
    return(false);
} // bool m_IsNewDay2(CSymbol& s, datetime date)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Returns true if the new year has started
//+------------------------------------------------------------------+
bool m_IsNewYear(CSymbol& s, datetime datenew )
{
    // 1) check if s.g_tm_prev_year with an uninatialised time
    //     if so then set it with the datenew
    datetime dateprev = StructToTime(s.g_tm_prev_year);
    if( 0 == dateprev )
    {
        TimeToStruct(datenew,s.g_tm_prev_year);
        return false;
    }
    
    // 2) check if there is a new year
    MqlDateTime tm;
    TimeToStruct(datenew,tm);
    if( s.g_tm_prev_year.year != tm.year )
    {
        string log = "NEW YEAR1: " +  IntegerToString( tm.day  ) + " ASK/BID "  + nds(s,s.ASK) + " / " + nds(s,s.BID) + " / NEW: " + TimeToString( datenew, TIME_DATE|TIME_SECONDS ) + " / OLD: " +  TimeToString( dateprev, TIME_DATE|TIME_SECONDS );
        Log2Sql( s, "MARKET", 0, log );
        s.g_tm_prev_year = tm;
        return(true);
    }
    return(false);
} // bool m_IsNewYear(CSymbol& s, datetime date)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Returns true if the new year has started
//+------------------------------------------------------------------+
bool m_IsNewYear2(CSymbol& s, datetime datenew )
{
    // 1) check if s.g_tm_prev_year2 with an uninatialised time
    //     if so then set it with the datenew
    datetime dateprev = StructToTime(s.g_tm_prev_year2);
    if( 0 == dateprev )
    {
        TimeToStruct(datenew,s.g_tm_prev_year2);
        return false;
    }
    
    // 2) check if there is a new year
    MqlDateTime tm;
    TimeToStruct(datenew,tm);
    if( s.g_tm_prev_year2.year != tm.year )
    {
        string log = "NEW YEAR2: " +  IntegerToString( tm.day  ) + " ASK/BID "  + nds(s,s.ASK) + " / " + nds(s,s.BID) + " / NEW: " + TimeToString( datenew, TIME_DATE|TIME_SECONDS ) + " / OLD: " +  TimeToString( dateprev, TIME_DATE|TIME_SECONDS );
        Log2Sql( s, "MARKET", 0, log );
        s.g_tm_prev_year2 = tm;
        return(true);
    }
    return(false);
} // bool m_IsNewYear2(CSymbol& s, datetime date)
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Returns the amount of seconds elapsed from the beginning of the minute for the specified time.
//+------------------------------------------------------------------+
int m_TimeSeconds(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.sec);
} // int m_TimeSeconds(datetime date)
//+------------------------------------------------------------------+


double CalcCciEnter( ENUM_TIMEFRAMES timeframe, double a_cci_enter ) 
{

    int period = PeriodSeconds( timeframe ) / 60;
    double ccie = a_cci_enter;
    if( 1 == period ) {
        ccie = a_cci_enter/10*10;
    } else if ( 5 == period ) {
        ccie = a_cci_enter/10*5;
    } else if ( 15 == period ) {
        ccie = a_cci_enter/10*4;
    } else if ( 30 == period ) {
    } else if ( 60 == period ) {
        ccie = a_cci_enter/10*2;
    } else if ( 240 == period ) {
        ccie = a_cci_enter/10*1;
    } else if ( 1440 == period ) {
    } else if ( 10080 == period ) {
    } else if ( 40320 == period ) {
    } 
    return (ccie);
} // double CalcCciEnter( ENUM_TIMEFRAMES timeframe, double a_cci_enter ) 
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| ConvertPeriodToString
//+------------------------------------------------------------------+
string ConvertPeriodToString( ENUM_TIMEFRAMES timeframe ) 
{
    int period = PeriodSeconds( timeframe ) / 60;
    string str = "";
    if( 1 == period ) {
        str = "M1";
    } else if ( 5 == period ) {
        str = "M5";
    } else if ( 15 == period ) {
        str = "M15";
    } else if ( 30 == period ) {
        str = "M30";
    } else if ( 60 == period ) {
        str = "H1";
    } else if ( 240 == period ) {
        str = "H4";
    } else if ( 1440 == period ) {
        str = "D1";
    } else if ( 10080 == period ) {
        str = "W1";
    } else if ( 40320 == period ) {
        str = "MN";
    } else  {
        str = IntegerToString(period);
    }
    return (str);
} // string ConvertPeriodToString( ENUM_TIMEFRAMES timeframe )
//+------------------------------------------------------------------+

datetime m_HourDec( datetime dt ) {
    dt = dt - 3600;
    return (dt);
} // datetime m_HourDec( datetime dt )
//+------------------------------------------------------------------+

string m_GetMilliSecondsAsString( bool atestermode ) {
    // Interface to float.js library - The timestamps must be specified as Javascript timestamps, as milliseconds since January 1, 1970 00:00. This is like Unix timestamps, but in milliseconds instead of seconds (remember to multiply with 1000!).
    string sdtms ="000";  
    if( false == atestermode )
    {  
        int    TimeArray[4];
        GetLocalTime(TimeArray);
        int dtms=TimeArray[3]>>16;
        sdtms =IntegerToString(1000+dtms);
        sdtms=StringSubstr(sdtms,1);
    }
    return (sdtms);
} // string m_GetMilliSecondsAsString( bool atestermode )
//+------------------------------------------------------------------+


//
// STRING FUNCTIONS
//
//+------------------------------------------------------------------+
//| STRING FUNCTIONS                                                 |
//+------------------------------------------------------------------+

/*
string StringToLower(string atext) {
    // http://forum.mql4.com/4891    
    // Example: StringChangeToLowerCase("oNe mAn"); // one man
    int len=StringLen(atext), i, char;
    for(i=0; i < len; i++) {
        char=StringGetChar(atext, i);
        if(char >= 65 && char <= 90) {
            atext=StringSetChar(atext, i, char+32);
        }
    }
    return(atext);  
} // string StringToLower(string atext)
*/


// string format MA value
string fma( CSymbol& s, double price ) {
    string str = DoubleToString( NormalizeDouble(price,  s.DIGITS-1), s.DIGITS-1);
    return (str);
} // string fma( double price )

// string format cci value
string fcci( double price ) { 
    // "-999.9"
    string sret = "";  
    price = NormalizeDouble(price,  1);
    string scci = DoubleToString( price, 1);
    if( 0 > price ) {
        if( -10 < price ) sret = "  " + scci;
        else if( -100 < price ) sret = " "  + scci;
        else sret = scci;
    } else {
        if( 10 > price ) sret = "   " + scci;
        else if( 100 > price ) sret = "  "  + scci;
        else sret = " "  + scci;
    }
    return (sret);
} // string fcci( double price ) 

// convert price to point
string ctp( CSymbol& s, double in ){
    string ctp = "   ";
    int out = (int)(MathAbs( in )/s.POINT/10);
    if( out == 0  ) ctp = "  0";
    //if( out == 0  ) ctp = "   ";
    else if( out < 10  ) ctp = "  " + IntegerToString(out);
    else if( out < 100 ) ctp = " "  + IntegerToString(out);
    else ctp = IntegerToString(out);
    return ( ctp );
} // string ctp( double in )


/*
void _ArraySort2D(double &rdDest[][], double &_dSource[][], int _iSortIndex){
   
   // sort arrays in mt4 - http://forum.mql4.com/31353/page3#329443
   int liSize[2];
   liSize[0] = ArrayRange(_dSource, 0);
   liSize[1] = ArrayRange(_dSource, 1);
   int liPosition;

//2014.02.12 17:21:09	Normalise USDCHF,M1: 2014.02.12 18:21:00 0.90113 4321 -       1       1   4123 52
//2014.02.12 17:21:09	Normalise USDCHF,M1: -112.60000000 < -83.60000000 2 3 3.00000000 2.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: -83.60000000 < -72.30000000 1 3 2.00000000 1.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: -72.30000000 < 13.50000000 0 3 1.00000000 4.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: 0.90119000 < 0.90121000 2 3 1.00000000 2.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: 0.90121000 < 0.90143000 1 3 2.00000000 3.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: 0.90119000 < 0.90121000 1 2 1.00000000 2.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: 0.90143000 < 0.90189000 0 3 3.00000000 4.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: 0.90121000 < 0.90143000 0 2 2.00000000 3.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: 0.90119000 < 0.90121000 0 1 1.00000000 2.00000000
//2014.02.12 17:21:09	Normalise USDCHF,M1: -|/\ USDCHF 1 2014.02.12 17:21:09 C0 0.9011 MA1 0.9012 MA2 0.9012 MA3 0.9014 MA4 0.9019 CCI1 -72.3 CCI2 -83.6 CCI3 -112.6 CCI4 13.5
//
//2014.02.12 17:21:09	Normalise EURUSD,M1: 2014.02.12 18:21:00 1.35908 1234 -       1       1   3124 78
//2014.02.12 17:21:09	Normalise EURUSD,M1: 109.20000000 < 116.30000000 1 2 2.00000000 1.00000000
//2014.02.12 17:21:09	Normalise EURUSD,M1: 116.30000000 < 138.10000000 0 2 1.00000000 3.00000000
//2014.02.12 17:21:09	Normalise EURUSD,M1: -|/\ EURUSD 1 2014.02.12 17:21:09 C0 1.3591 MA1 1.3591 MA2 1.3589 MA3 1.3586 MA4 1.3581 CCI1 116.3 CCI2 109.2 CCI3 138.1 CCI4 -5.7

 
   for (int i = 0; i < liSize[0]; i++){
      liPosition = 0;
      for (int j = i+1; j < liSize[0]; j++){
         if (_dSource[i,_iSortIndex] < _dSource[j,_iSortIndex]){
         
            //dbg(_dSource[i,_iSortIndex] + " < " + _dSource[j,_iSortIndex] + " " + i + " " + j  + " " + _dSource[i,0]  + " " + _dSource[j,0] ) ;
           
            double tmp1 = _dSource[j][0];
            double tmp2 = _dSource[j][1];
            _dSource[j][0] = _dSource[i][0];
            _dSource[j][1] = _dSource[i][1];
            _dSource[i][0] = tmp1;
            _dSource[i][1] = tmp2;
           
           liPosition++;
         }
      }
      //ArrayCopy(rdDest, _dSource, liPosition*liSize[1], i*liSize[1],  liSize[1]);
   }
   
    for (int i = 0; i < liSize[0]; i++){
        rdDest[i,0] = _dSource[i,0];
        rdDest[i,1] = _dSource[i,1];
    }
   
} // void _ArraySort2D(double &rdDest[][], double &_dSource[][], int _iSortIndex)
*/

string Sort4Doubles( double d1, double d2, double d3, double d4 ) {
    string sorted = "";
/*

    double ldDest[4][2];
    ldDest[0][1] = 0;
    ldDest[0][0] = 0;
    ldDest[1][1] = 0;
    ldDest[1][0] = 0;
    ldDest[2][1] = 0;
    ldDest[2][0] = 0;
    ldDest[3][1] = 0;
    ldDest[3][0] = 0;
    double ldSource[4][2];
    ldSource[0][1] = d1;
    ldSource[0][0] = 1;
    ldSource[1][1] = d2;
    ldSource[1][0] = 2;
    ldSource[2][1] = d3;
    ldSource[2][0] = 3;
    ldSource[3][1] = d4;
    ldSource[3][0] = 4;

    //_ArraySort2D(ldDest, ldSource, 1);
    for (int i = 0; i < ArrayRange(ldDest,0); i++){      
        //dbg(i," ",0,"= ",ldDest[i,0]);    
        //dbg(i," ",1,"= ",ldDest[i,1]);    
        sorted = sorted + DoubleToString(ldDest[i,0],0);
    }
*/	
    return (sorted);
} // string Sort4Doubles( double d1, double d2, double d3, double d4 )

//
// PRICE FUNCTIONS
//
//+------------------------------------------------------------------+
//| PRICE FUNCTIONS                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_vFindIfMarketWasVolatileToday
//+------------------------------------------------------------------+
void m_vFindIfMarketWasVolatileToday(CSymbol& s)
{
    int shift = m_GetShiftSinceNewDayStarted(s);
    dbg(s, "m_vFindIfMarketWasVolatileToday " + IntegerToString(shift ) );
    for( ; shift > 0; shift-- )
    {
        string log; double pivot; int wa; int wa2;
        if( true == iMarketIsVolatile(s,log,pivot, wa, wa2, shift) )
        {
            dbg(s, log );
        }
    }
    dbg(s, "m_vFindIfMarketWasVolatileToday END" );
} // bool m_vFindIfMarketWasVolatileToday()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Return true if the market seems to be volatile
//|  algorithm taken from WA scalping indicator
//+------------------------------------------------------------------+
bool iMarketIsVolatile(CSymbol& s, string& log, double& a_pivot, int& a_WA, int& a_WA2, int shift = 1)
{
    a_pivot = 0;
    //---- WA start
    //int j=iBarShift(SYMBOL,PERIOD,iTime(SYMBOL, PERIOD, shift),false);
    int j = shift;
    int IPeriod=15;
    double max,min,max2,min2;
    //int WA, WA2;
    double pivot,c1, pivotavg;
    max2=iHigh(s.SYMBOL,s.PERIOD,iHighest(s.SYMBOL,s.PERIOD,MODE_HIGH,IPeriod,j));
    min2=iLow(s.SYMBOL,s.PERIOD,iLowest(s.SYMBOL,s.PERIOD,MODE_LOW,IPeriod,j));
    pivot=(iClose(s.SYMBOL,s.PERIOD,j+1)+iClose(s.SYMBOL,s.PERIOD,j+2)+iClose(s.SYMBOL,s.PERIOD,j+3))/3;
    c1 = iClose(s.SYMBOL,s.PERIOD,shift);
    pivotavg = ((max2 + min2 + pivot)/3);
    a_WA2=(int)(( c1 - pivotavg )/s.POINT);
    //if( (0.0 != s.g_WA_prev) && (0.0 != WA) && ((WA/s.g_WA_prev >= 2) || (s.g_WA_prev/WA >= 2)) && ((200 < WA)||(200 < s.g_WA_prev)))
    //{
    //    printf( "Market is volatile at %s ASK/BID %s/%s max: [%.5f] min: [%.5f] pivot: [%.5f] c1: [%.5f] pivotavg: [%.5f] WA: [%.1f] WALE: [%.1f] WAL10: [%.1f]", max, min, pivot, c1, pivotavg, WA, MathLog(MathAbs(WA)), MathLog10(MathAbs(WA)) );
    //}
    //---- WA end
    
    max=iHigh(s.SYMBOL,s.PERIOD,shift);
    min=iLow(s.SYMBOL,s.PERIOD,shift);
    a_WA=(int)(( max - min )/s.POINT);
    if( MARKET_VOLATILITY_FACTOR < a_WA )
    {
        a_pivot = pivotavg;
        
        // replace this for the past volatile phases with the code beneath
        //s.g_market_is_volatile_time = g_time_local;
        // calculate the closing time of the current bar (iTime is opening time)
        datetime tt = iTime(s.SYMBOL, s.PERIOD, shift ) + PeriodSeconds(s.PERIOD);
        if( true == ADJUSTTIME )
        {
            tt = m_HourDec( tt );
        }
        //s.g_market_is_volatile = WA;
        //s.g_market_is_volatile_time = tt;
        log = StringFormat( "Market is volatile at %s WA: [%d] HIGH: [%.5f] LOW: [%.5f] pivot: [%.5f] c1: [%.5f] pivotavg: [%.5f] WA2: [%d] WA2LE: [%.1f] WA2L10: [%.1f]", TimeToString(tt, TIME_DATE | TIME_MINUTES), a_WA, max, min, pivot, c1, pivotavg, a_WA2, MathLog(MathAbs(a_WA2)), MathLog10(MathAbs(a_WA2)) );
        
        return (true);
    }
    return (false);
} // bool iMarketIsVolatile(CSymbol& s, string& log, double& a_pivot, int& a_WA, int& a_WA2, int shift = 1)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| get the bar shift from time
//+------------------------------------------------------------------+

double CopyBufferMQL4(int handle,int index,int shift) {
    double buf[];
    switch(index)
    {
        case 0: if(CopyBuffer(handle,0,shift,1,buf)>0)
            return(buf[0]); break;
        case 1: if(CopyBuffer(handle,1,shift,1,buf)>0)
            return(buf[0]); break;
        case 2: if(CopyBuffer(handle,2,shift,1,buf)>0)
            return(buf[0]); break;
        case 3: if(CopyBuffer(handle,3,shift,1,buf)>0)
            return(buf[0]); break;
        case 4: if(CopyBuffer(handle,4,shift,1,buf)>0)
            return(buf[0]); break;
        default: break;
    }
    return(EMPTY_VALUE);
} // double CopyBufferMQL4(int handle,int index,int shift)

double iATR4(string asymbol, ENUM_TIMEFRAMES timeframe, int period, int shift) {
    int handle=iATR(asymbol,timeframe,period);
    if(handle<0) {
        dbg("The iATR object is not created ERROR: "+IntegerToString(GetLastError()));
        return(-1);
    } else {
        return(CopyBufferMQL4(handle,0,shift));
    }
} // double iATR(string asymbol, ENUM_TIMEFRAMES timeframe, int period, int shift)

double iRSI4(string asymbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE price, int shift) {
    int handle=iRSI(asymbol,timeframe,period,price);
    if(handle<0) {
        dbg("The iRSI object is not created ERROR: "+IntegerToString(GetLastError()));
        return(-1);
    } else {
        return(CopyBufferMQL4(handle,0,shift));
    }
} // double iRSI(string asymbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE price, int shift)
 

double iCCI4(string asymbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE price, int shift) {
    int handle=iCCI(asymbol,timeframe,period,price);
    if(handle<0) {
        dbg("The iCCI object is not created ERROR: "+IntegerToString(GetLastError()));
        return(-1);
    } else {
        return(CopyBufferMQL4(handle,0,shift));
    }
} // double iCCI(string asymbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE price, int shift)


double iMA4(string asymbol, ENUM_TIMEFRAMES timeframe, int period, int ma_shift,ENUM_MA_METHOD ma_method,ENUM_APPLIED_PRICE applied_price,int shift) {
    int handle=iMA(asymbol,timeframe,period,ma_shift,
              ma_method,applied_price);
    if(handle<0) {
        dbg("The iMA object is not created: ERROR: "+IntegerToString(GetLastError()) );
        return(-1);
    } else {
        return(CopyBufferMQL4(handle,0,shift));
    }
} // double iMA4(string asymbol, ENUM_TIMEFRAMES timeframe, int period, int ma_shift,ENUM_MA_METHOD ma_method,ENUM_APPLIED_PRICE applied_price,int shift) {

double iMACD4(string asymbol, 
              ENUM_TIMEFRAMES timeframe, 
              int period, 
              int fast_ema_period,
              int slow_ema_period,
              int signal_period,
              ENUM_APPLIED_PRICE applied_price,
              int shift) {
                  
    int handle =iMACD(asymbol,timeframe,fast_ema_period,slow_ema_period,signal_period,applied_price);
    if(handle<0) {
        dbg("The iMACD object is not created: ERROR: "+IntegerToString(GetLastError()) );
        return(-1);
    } else {
        return(CopyBufferMQL4(handle,0,shift));
    }
} // double iMACD4(string asymbol, 

double iCustPrice( CSymbol& s, int period, int price_type, int shift ) {

    double p = EMPTY_VALUE;
    if( price_type == I_PRICE_CCI ){
        p = iCCI4(s.SYMBOL,s.PERIOD,period,PRICE_TYPICAL,shift);
        
    }else if( price_type == I_PRICE_MA ){
        if( 2 > period ) {
            p = iClose(s.SYMBOL,s.PERIOD,shift);
        } else {
            p = iMA4(s.SYMBOL,s.PERIOD,period,0, MODE_SMA,PRICE_TYPICAL,shift);
        }
        
    }else if( price_type == I_PRICE_TICK_ASK ){
        if( k_ticks_array_size > shift ) {
            p = s.g_arr_ticks_ask[shift];
        }
    
    }else if( price_type == I_PRICE_TICK_BID ){
        if( k_ticks_array_size > shift ) {
            p = s.g_arr_ticks_bid[shift];
        }
        
    }else if( price_type == I_PRICE_RSI ){
        p = iRSI4(s.SYMBOL,s.PERIOD,period,PRICE_TYPICAL,shift);
    
    }else if( price_type == I_PRICE_ATR ){
        p = iATR4(s.SYMBOL,s.PERIOD,period,shift);
    
    }else{
        dbg( "ERROR iCustPrice wrong price_type: " + IntegerToString(price_type) );
        
    }   
    return (p);
} // double iCustPrice( string symbol, ENUM_TIMEFRAMES timeframe, int period, int price_type, int shift )


double iCustPriceDF( CSymbol& s, int period, int price_type, int shift )	{

	double response = 0;
	response = 
        0.1788961087798*iCustPrice(s,period,price_type,shift)
        +0.1741251154343*iCustPrice(s,period,price_type,shift+1)
        +0.1648181803525*iCustPrice(s,period,price_type,shift+2)
        +0.1514328434889*iCustPrice(s,period,price_type,shift+3)
        +0.1346207300152*iCustPrice(s,period,price_type,shift+4)
        +0.1151889152793*iCustPrice(s,period,price_type,shift+5)
        +0.0940513925624*iCustPrice(s,period,price_type,shift+6)
        +0.0721763036748*iCustPrice(s,period,price_type,shift+7)
        +0.0505298690011*iCustPrice(s,period,price_type,shift+8)
        +0.03002064469491*iCustPrice(s,period,price_type,shift+9)
        +0.01145295884369*iCustPrice(s,period,price_type,shift+10)
        -0.00451519901817*iCustPrice(s,period,price_type,shift+11)
        -0.01740328024981*iCustPrice(s,period,price_type,shift+12)
        -0.02692545054172*iCustPrice(s,period,price_type,shift+13)
        -0.0329999682623*iCustPrice(s,period,price_type,shift+14)
        -0.0357399309593*iCustPrice(s,period,price_type,shift+15)
        -0.0354322229303*iCustPrice(s,period,price_type,shift+16)
        -0.0325100186166*iCustPrice(s,period,price_type,shift+17)
        -0.02751744539301*iCustPrice(s,period,price_type,shift+18)
        -0.02106905223299*iCustPrice(s,period,price_type,shift+19)
        -0.01380448128734*iCustPrice(s,period,price_type,shift+20)
        -0.00634504259700*iCustPrice(s,period,price_type,shift+21)
        +0.000744778986828*iCustPrice(s,period,price_type,shift+22)
        +0.00698757638705*iCustPrice(s,period,price_type,shift+23)
        +0.01201319849333*iCustPrice(s,period,price_type,shift+24)
        +0.01557962340987*iCustPrice(s,period,price_type,shift+25)
        +0.01757761993639*iCustPrice(s,period,price_type,shift+26)
        +0.01802264846263*iCustPrice(s,period,price_type,shift+27)
        +0.01704164958172*iCustPrice(s,period,price_type,shift+28)
        +0.01485269910056*iCustPrice(s,period,price_type,shift+29)
        +0.01174641229113*iCustPrice(s,period,price_type,shift+30)
        +0.00805481180547*iCustPrice(s,period,price_type,shift+31)
        +0.00411529898859*iCustPrice(s,period,price_type,shift+32)
        +0.0002549462794749*iCustPrice(s,period,price_type,shift+33)
        -0.00323497270013*iCustPrice(s,period,price_type,shift+34)
        -0.00612338064572*iCustPrice(s,period,price_type,shift+35)
        -0.00824865912522*iCustPrice(s,period,price_type,shift+36)
        -0.00952029035052*iCustPrice(s,period,price_type,shift+37)
        -0.00992398875404*iCustPrice(s,period,price_type,shift+38)
        -0.00951884912663*iCustPrice(s,period,price_type,shift+39)
        -0.00841584750885*iCustPrice(s,period,price_type,shift+40)
        -0.00676994285044*iCustPrice(s,period,price_type,shift+41)
        -0.00477073090344*iCustPrice(s,period,price_type,shift+42)
        -0.002606522475570*iCustPrice(s,period,price_type,shift+43)
        -0.000466342964063*iCustPrice(s,period,price_type,shift+44)
        +0.001480299089324*iCustPrice(s,period,price_type,shift+45)
        +0.003104663122232*iCustPrice(s,period,price_type,shift+46)
        +0.00430856052869*iCustPrice(s,period,price_type,shift+47)
        +0.00504273142287*iCustPrice(s,period,price_type,shift+48)
        +0.00530368088113*iCustPrice(s,period,price_type,shift+49)
        +0.00511846941828*iCustPrice(s,period,price_type,shift+50)
        +0.00456104492645*iCustPrice(s,period,price_type,shift+51)
        +0.00371556406243*iCustPrice(s,period,price_type,shift+52)
        +0.002691150054034*iCustPrice(s,period,price_type,shift+53)
        +0.001593979234728*iCustPrice(s,period,price_type,shift+54)
        +0.000528231197962*iCustPrice(s,period,price_type,shift+55)
        -0.000421337049683*iCustPrice(s,period,price_type,shift+56)
        -0.001141303265175*iCustPrice(s,period,price_type,shift+57)
        -0.001907390100428*iCustPrice(s,period,price_type,shift+58)
        -0.000470306039412*iCustPrice(s,period,price_type,shift+59)
        -0.01218350977729*iCustPrice(s,period,price_type,shift+60)
        -0.001767234062933*iCustPrice(s,period,price_type,shift+61);
	return (response);

} // double iCustPriceDF( string symbol, ENUM_TIMEFRAMES timeframe, int period, int price_type, int shift )


//
// TICKS-LOG FUNCTIONS
//
//+------------------------------------------------------------------+
//| TICKS-LOG FUNCTIONS                                              |
//+------------------------------------------------------------------+

void _Log_NN_sub ( CSymbol& s, string fn_nn_input, string fn_nn_target, int shift ) {

    if( 1 > shift ) {
        dbg( s, "_Log_NN_sub error - shift must be greater or equal than 1" );
        return;
    }

    // NN output target
    //string sc0 = DoubleToStr( NormalizeDouble( iClose (SYMBOL,PERIOD,shift),  4), 4);
    //_Log( fn_nn_target, sc0 );

    string DELIM = " ";

    //
    // shift-1    CloseTime of old bar and OpenTime of new bar
    //
    datetime dt = iTime(s.SYMBOL,s.PERIOD,shift-1);
    //if( true == ADJUSTTIME ) {
    //    dt = m_HourDec( dt );
    //} // if( true == ADJUSTTIME )
    string sd    = TimeToString(dt,TIME_DATE);
    string ss    = TimeToString(dt,TIME_SECONDS);
    
    //
    // shift-1    ClosePrice of old bar and Openprice of new barof old bar and OpenTime of new bar
    //
    string so    = nds( s, iOpen(s.SYMBOL,s.PERIOD,shift-1) );
    
    //
    // shift    information of old bar
    // 
    
    // ticks 
    //string sask = DoubleToStr( NormalizeDouble( Ask,  Digits), Digits);
    //string sbid = DoubleToStr( NormalizeDouble( Bid,  Digits), Digits);
    
    // cci digifilter on
    double cci0  = iCustPriceDF(s,I_CCI0_PERIOD, I_PRICE_CCI, shift);
    string scci0 = fcci( cci0 );
    double cci1  = iCustPriceDF(s,I_CCI1_PERIOD, I_PRICE_CCI, shift);
    string scci1 = fcci( cci1 );
    double cci2  = iCustPriceDF(s,I_CCI2_PERIOD, I_PRICE_CCI, shift);
    string scci2 = fcci( cci2 );
    double cci3  = iCustPriceDF(s,I_CCI3_PERIOD, I_PRICE_CCI, shift);
    string scci3 = fcci( cci3 );

    // cci digifilter off
    double occi0  = iCustPrice(s,I_CCI0_PERIOD, I_PRICE_CCI, shift);
    string socci0 = fcci( occi0 );
    double occi1  = iCustPrice(s,I_CCI1_PERIOD, I_PRICE_CCI, shift);
    string socci1 = fcci( occi1 );
    double occi2  = iCustPrice(s,I_CCI2_PERIOD, I_PRICE_CCI, shift);
    string socci2 = fcci( occi2 );
    double occi3  = iCustPrice(s,I_CCI3_PERIOD, I_PRICE_CCI, shift);
    string socci3 = fcci( occi3 );
    
    // ma digifilter on
    double ma0   = iCustPriceDF(s,I_IND0_PERIOD, I_PRICE_MA, shift);
    string sma0  = fma( s, ma0 );
    double ma1   = iCustPriceDF(s,I_IND1_PERIOD, I_PRICE_MA, shift);
    string sma1  = fma( s, ma1 );
    double ma2   = iCustPriceDF(s,I_IND2_PERIOD, I_PRICE_MA, shift);
    string sma2  = fma( s, ma2 );
    double ma3   = iCustPriceDF(s,I_IND3_PERIOD, I_PRICE_MA, shift);
    string sma3  = fma( s, ma3 );

    // ma digifilter off
    double oma0   = iCustPrice(s,I_IND0_PERIOD, I_PRICE_MA, shift);
    string soma0  = fma( s, oma0 );
    double oma1   = iCustPrice(s,I_IND1_PERIOD, I_PRICE_MA, shift);
    string soma1  = fma( s, oma1 );
    double oma2   = iCustPrice(s,I_IND2_PERIOD, I_PRICE_MA, shift);
    string soma2  = fma( s, oma2 );
    double oma3   = iCustPrice(s,I_IND3_PERIOD, I_PRICE_MA, shift);
    string soma3  = fma( s, oma3 );

    string ssortedma   = Sort4Doubles( ma0,   ma1,   ma2,   ma3 );
    string ssortedoma  = Sort4Doubles( oma0,  oma1,  oma2,  oma3 );
    string ssortedcci  = Sort4Doubles( cci0,  cci1,  cci2,  cci3 );
    string ssortedocci = Sort4Doubles( occi0, occi1, occi2, occi3 );

    string soh = ctp( s, iOpen(s.SYMBOL,s.PERIOD,shift) - iHigh (s.SYMBOL,s.PERIOD,shift) );
    string sol = ctp( s, iOpen(s.SYMBOL,s.PERIOD,shift) - iLow  (s.SYMBOL,s.PERIOD,shift) );
    string soc = ctp( s, iOpen(s.SYMBOL,s.PERIOD,shift) - iClose(s.SYMBOL,s.PERIOD,shift) );
    string shl = ctp( s, iHigh(s.SYMBOL,s.PERIOD,shift) - iLow  (s.SYMBOL,s.PERIOD,shift) );
    string ud = "+";
    if( iOpen(s.SYMBOL,s.PERIOD,shift) > iClose(s.SYMBOL,s.PERIOD,shift) ) ud = "-";
    int v01 = (int)iTickVolume(s.SYMBOL,s.PERIOD,shift);
    
    //string log = sd +DELIM+ ss +DELIM+ ud +DELIM+ so +DELIM+ sma0 +DELIM+ sma1 +DELIM+ sma2 +DELIM+ sma3 + DELIM + soc + DELIM + shl + DELIM + soh + DELIM + sol +DELIM+DELIM+DELIM+ scci0 +DELIM+ scci1 +DELIM+ scci2 +DELIM+ scci3 +DELIM+ v01;
    string log = sd +DELIM+ ss +DELIM+ so +DELIM+ ssortedma +DELIM+ ssortedcci +DELIM+ ud +DELIM+ soc + DELIM + shl + DELIM + soh + DELIM + sol +DELIM+DELIM+DELIM+ sma0 +DELIM+ sma1 +DELIM+ sma2 +DELIM+ sma3 + DELIM + scci0 +DELIM+ scci1 +DELIM+ scci2 +DELIM+ scci3 
            +DELIM+ ssortedoma +DELIM+ ssortedocci +DELIM+ soma0 +DELIM+ soma1 +DELIM+ soma2 +DELIM+ soma3 + DELIM + socci0 +DELIM+ socci1 +DELIM+ socci2 +DELIM+ socci3 +DELIM+ IntegerToString(v01);
    _Log( s, fn_nn_input, log );
} // void _Log_NN_sub ( string fn_nn_input, string fn_nn_target, int shift )

void _Log ( CSymbol& s, string fn, string text )
{
    //dbg( s, text );
    int fh = FileOpen ( fn, FILE_BIN | FILE_READ | FILE_WRITE, " " );
    if( 1 > fh )
    {
        dbg(s, "File "+fn+" not found, the last error is ERROR: "+IntegerToString(GetLastError()) );
        return;
    }    
    FileSeek ( fh, 0, SEEK_END );
    text = m_UNICODE2ANSI(text);
    ushort m=ushort(StringGetCharacter(text,StringLen(text)-1));
    //printf( "C: %04x", m );
    FileWriteString( fh, text );
    FileWriteString( fh, m_UNICODE2ANSI("\r\n") );
    //FileWrite( fh, text );
    FileClose( fh );
} // void _Log ( string fn, string text )


void _Log_NN ( CSymbol& s, string fn_nn_input, string fn_nn_target, bool atestermode, bool astartup = false ) {

	//int counted_bars=IndicatorCounted();

    int nbars=Bars(s.SYMBOL,s.PERIOD)-FILTERORDER-I_CCI3_PERIOD-1;
	//----
	if( 0 > nbars )
	{
	   //if( VERBOSE ) dbg(s,"_Log_NN too less bars " + IntegerToStr(nbars) + " " + IntegerToStr(Bars(SYMBOL,PERIOD)) + IntegerToStr(FILTERORDER) + " " + IntegerToStr(I_CCI3_PERIOD) );
	   return;
	}
	//----
	
    int fh = FileOpen ( fn_nn_input, FILE_READ , " " );
    if( 0 < fh ) {
        FileClose( fh );
        if( false == astartup ) {
            _Log_NN_sub(s,fn_nn_input, fn_nn_target, 1);            
        } // if( false == astartup )
    } else {
        if( true == atestermode ) {
            _Log_NN_sub(s,fn_nn_input, fn_nn_target, 1);            
        } else {
            // try to delete the NN TARGET file, in case it might exist
            FileDelete( fn_nn_target );
            
            // create NN_INPUT File if it does not exist	
    	    int i=nbars;
    	    //if( 100 < i ) i = 100;
    	    //if(counted_bars>=FILTERORDER) i=Bars-counted_bars-1;
    	    while(i>=0) {
                _Log_NN_sub(s,fn_nn_input, fn_nn_target, i+1);            
    		    i--;
    	    }// while(i>=0)
    	} // if( true == atestermode )
    } // if( 1 > fh )
} // void _Log_NN ( string fn_nn_input, string fn_nn_target, bool atestermode, bool astartup = false )


//
// HISTORY PROCESSOR
//
//+------------------------------------------------------------------+
//| HISTORY PROCESSOR                                                |
//+------------------------------------------------------------------+



/*

2013.07.16 22:35:46 expert (EURUSD,M1)  D: 1 22885261  0 2013.07.16 23:07 2 Balance type 0 In entry 0 0 0.00000 0.00000 0.00000 0.00000 10000.00000 
2013.07.16 22:35:46 expert (EURUSD,M1)  P: 2 EURUSD 30294456 0 2013.07.16 23:08 sell stop placed 1970.01.01 00:00 1970.01.01 00:00 return remainder specified 867 2.30000 2.30000 1.31520 0.00000 0.00000 1.31617 0.00000 867
2013.07.16 22:35:46 expert (EURUSD,M1)  P: 1 EURUSD 30294455 0 2013.07.16 23:08 buy stop placed 1970.01.01 00:00 1970.01.01 00:00 return remainder specified 867 2.30000 2.30000 1.31730 0.00000 0.00000 1.31628 0.00000 867
2013.07.16 22:35:46 expert (EURUSD,M1)   ONINIT DIGITS[5] POINTS[0.000010]


2013.07.16 11:02:59 expert (EURUSD,H1)  D: 2 22864276 EURUSD 30271980 2013.07.16 12:00 0 Buy type 1 Out entry 0 30253096 1.60000 1.30540 0.00000 0.00000 11.20000 [sl 1.30536]
2013.07.16 11:02:59 expert (EURUSD,H1)  D: 1 22864208 EURUSD 30253096 2013.07.16 12:00 1 Sell type 0 In entry 867 30253096 1.60000 1.30547 0.00000 0.00000 0.00000 867
2013.07.16 11:02:59 expert (EURUSD,H1)  O: 2 30271980 EURUSD 2013.07.16 12:00 buy filled 2013.07.16 12:00 2013.07.16 12:00 return remainder gtc 0 1.60000 0.00000 1.30536 0.00000 0.00000 1.30536 0.00000 [sl 1.30536]
2013.07.16 11:02:59 expert (EURUSD,H1)  O: 1 30253096 EURUSD 2013.07.15 19:40 sell stop filled 2013.07.15 19:40 2013.07.16 12:00 return remainder gtc 867 1.60000 0.00000 1.30581 0.00000 0.00000 1.30547 0.00000 867
2013.07.16 11:02:59 expert (EURUSD,H1)  P: 2 EURUSD 30272125 0 2013.07.16 12:01 sell stop placed 1970.01.01 00:00 1970.01.01 00:00 return remainder specified 867 1.60000 1.60000 1.30499 0.00000 0.00000 1.30599 0.00000 867
2013.07.16 11:02:59 expert (EURUSD,H1)  P: 1 EURUSD 30254857 0 2013.07.15 20:39 buy stop placed 1970.01.01 00:00 1970.01.01 00:00 return remainder specified 867 1.60000 1.60000 1.30707 0.00000 0.00000 1.30610 0.00000 867
2013.07.16 11:02:59 expert (EURUSD,H1)   ONINIT DIGITS[5] POINTS[0.000010]

2013.06.04 16:17:33 expert (EURUSD,M1)    D: 4 21654199 EURUSD 28949987 2013.06.04 17:17 0 Buy type 1 Out entry 0 28945828 2.50000 1.30462 0.00000 0.00000 42.50000 [sl 1.30462]
2013.06.04 16:17:33 expert (EURUSD,M1)    D: 3 21654058 EURUSD 28945828 2013.06.04 17:15 1 Sell type 0 In entry 867 28945828 2.50000 1.30479 0.00000 0.00000 0.00000 867
2013.06.04 16:17:33 expert (EURUSD,M1)    D: 2 21652268 EURUSD 28948055 2013.06.04 16:29 1 Sell type 1 Out entry 0 28919557 2.50000 1.30751 0.00000 0.00000 130.00000 [sl 1.30758]
2013.06.04 16:17:33 expert (EURUSD,M1)    D: 1 21652224 EURUSD 28919557 2013.06.04 16:29 0 Buy type 0 In entry 867 28919557 2.50000 1.30699 0.00000 0.00000 0.00000 867
2013.06.04 16:17:33 expert (EURUSD,M1)    O: 4 28949987 EURUSD 2013.06.04 17:17 buy filled 2013.06.04 17:17 2013.06.04 17:17 return remainder gtc 0 2.50000 0.00000 1.30462 0.00000 0.00000 1.30462 0.00000 [sl 1.30462]
2013.06.04 16:17:33 expert (EURUSD,M1)    O: 3 28948055 EURUSD 2013.06.04 16:29 sell filled 2013.06.04 16:29 2013.06.04 16:29 return remainder gtc 0 2.50000 0.00000 1.30758 0.00000 0.00000 1.30758 0.00000 [sl 1.30758]
2013.06.04 16:17:33 expert (EURUSD,M1)    O: 2 28945828 EURUSD 2013.06.04 15:29 sell stop filled 2013.06.04 15:29 2013.06.04 17:15 return remainder gtc 867 2.50000 0.00000 1.30485 0.00000 0.00000 1.30479 0.00000 867
2013.06.04 16:17:33 expert (EURUSD,M1)    O: 1 28919557 EURUSD 2013.06.03 18:21 buy stop filled 2013.06.03 18:21 2013.06.04 16:29 return remainder gtc 867 2.50000 0.00000 1.30692 0.00000 0.00000 1.30699 0.00000 867
2013.06.04 16:17:33 expert (EURUSD,M1)    P: 2 EURUSD 28949989 0 2013.06.04 17:17 sell stop placed 1970.01.01 00:00 1970.01.01 00:00 return remainder specified 867 2.50000 2.50000 1.30346 0.00000 0.00000 1.30453 0.00000 867
2013.06.04 16:17:33 expert (EURUSD,M1)    P: 1 EURUSD 28948221 0 2013.06.04 16:30 buy stop placed 1970.01.01 00:00 1970.01.01 00:00 return remainder specified 867 2.50000 2.50000 1.30553 0.00000 0.00000 1.30459 0.00000 867

2013.06.04 15:29:07 expert (EURUSD,M1)     B[002] DT[16:29:07] ASK[1.30776] BID[1.30765] VOL[012] PROFIT[165.0]
2013.06.04 15:29:06 expert (EURUSD,M1)     B[001] DT[16:29:06] ASK[1.30774] BID[1.30768] VOL[011] PROFIT[172.5]
2013.06.04 15:29:06 expert (EURUSD,M1)     B[000] DT[16:29:06] ASK[1.30699] BID[1.30693] VOL[010] PROFIT[-15.0]
2013.06.04 15:29:06 expert (EURUSD,M1)     A[239] DT[16:29:05] ASK[1.30678] BID[1.30672] VOL[009] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[238] DT[16:29:05] ASK[1.30664] BID[1.30658] VOL[008] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[237] DT[16:29:04] ASK[1.30639] BID[1.30633] VOL[007] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[236] DT[16:29:04] ASK[1.30601] BID[1.30595] VOL[006] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[235] DT[16:29:03] ASK[1.30598] BID[1.30589] VOL[005] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[234] DT[16:29:02] ASK[1.30595] BID[1.30585] VOL[004] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[233] DT[16:29:01] ASK[1.30594] BID[1.30583] VOL[003] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[232] DT[16:29:01] ASK[1.30592] BID[1.30581] VOL[002] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[231] DT[16:29:00] ASK[1.30592] BID[1.30582] VOL[001] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[230] DT[16:28:59] ASK[1.30591] BID[1.30582] VOL[082] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[229] DT[16:28:59] ASK[1.30592] BID[1.30582] VOL[081] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[228] DT[16:28:57] ASK[1.30594] BID[1.30585] VOL[080] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[227] DT[16:28:57] ASK[1.30590] BID[1.30580] VOL[079] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[226] DT[16:28:56] ASK[1.30586] BID[1.30575] VOL[078] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[225] DT[16:28:56] ASK[1.30586] BID[1.30576] VOL[077] 
2013.06.04 15:29:06 expert (EURUSD,M1)     A[224] DT[16:28:55] ASK[1.30586] BID[1.30577] VOL[076] 

*/



//+------------------------------------------------------------------+
//|   m_GetHistoryInfo                                               |
//+------------------------------------------------------------------+
int m_GetHistoryInfo( datetime from_date, datetime to_date )
  {
    // http://www.mql5.com/en/articles/138
    int order_cnt = 0;
    int deal_cnt = 0;
    //Select all history orders within a time period
    if (HistorySelect(from_date,to_date))  // get all history orders
    {
        //
        // Get total orders in history
        //
        int tot_hist_orders = HistoryOrdersTotal(); 
        ulong h_ticket; // Order ticket
        for (int j=0; j<tot_hist_orders; j++)
        {
            h_ticket = HistoryOrderGetTicket(j);
            if (h_ticket>0)
            {
                //if(/*HistoryOrderGetInteger(h_ticket,ORDER_MAGIC)!=MAGIC_NUMBER ||*/ HistoryOrderGetString(h_ticket,ORDER_SYMBOL)!=s.SYMBOL) continue;
                order_cnt++;
                /*
                //#include <Trade\HistoryOrderInfo.mqh>
                //  This function is used to select the order ticket for which we want to obtain its properties or details. 
                CHistoryOrderInfo myhistory;
                myhistory.Ticket(h_ticket);
                //if( VERBOSE )
                {
                    dbg( 
                        "O: ", order_cnt," ", 
                        myhistory.Ticket()," ", 
                        myhistory.Symbol()," ",
                        TimeToString(myhistory.TimeSetup())," ",
                        myhistory.TypeDescription()," ",
                        myhistory.StateDescription()," ",
                        TimeToString(myhistory.TimeExpiration())," ",
                        TimeToString(myhistory.TimeDone())," ",
                        myhistory.TypeFillingDescription()," ",
                        myhistory.TypeTimeDescription()," ",
                        IntegerToString(myhistory.Magic())," ",
                        DoubleToString(myhistory.VolumeInitial(),5)," ",
                        DoubleToString(myhistory.VolumeCurrent(),5)," ",
                        DoubleToString(myhistory.PriceOpen(),5)," ",
                        DoubleToString(myhistory.StopLoss(),5)," ",
                        DoubleToString(myhistory.TakeProfit(),5)," ",
                        DoubleToString(myhistory.PriceCurrent(),5)," ",
                        DoubleToString(myhistory.PriceStopLimit(),5)," ",
                        myhistory.Comment()
                    );
                } // //if( VERBOSE )
                */
            } // if (h_ticket>0)
        } // for (int j=0; j<tot_hist_orders; j++)

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double bal_now = balance;
        double swap_total = 0;
        double comm_total = 0;
        double profit_total = 0;
        dbg( "BALANCE NOW " + nds(bal_now,2) );
        //
        // Get total deals in history
        //
        
        int tot_deals = HistoryDealsTotal(); 
        ulong d_ticket; // deal ticket
        //for (int j=0; j<tot_deals; j++)
        for (int j=tot_deals; 0<=j; j--)
        {
            d_ticket = HistoryDealGetTicket(j);
            if (d_ticket>0)  
            {
                //if(HistoryDealGetString(d_ticket,DEAL_SYMBOL)!=SYMBOL) continue;
                deal_cnt++;
                
                //#include <Trade\DealInfo.mqh>
                // First thing is to now set the deal Ticket to work with by our class object 
                CDealInfo mydeal; 
                mydeal.Ticket(d_ticket);
                if( ( (DEAL_TYPE_BUY==mydeal.DealType()) || (DEAL_TYPE_SELL==mydeal.DealType()) ) )
                {
                    double profit = mydeal.Profit();
                    double swap = mydeal.Swap();
                    double commission = mydeal.Commission();
                    balance = balance - profit - commission - swap;
                    swap_total = swap_total + swap;
                    comm_total = comm_total + commission;
                    profit_total = profit_total + profit;
                    if( VERBOSE )
                    {
                        string log = "";
                        StringConcatenate(log, "D1: ", deal_cnt," ", 
                            mydeal.Symbol()," ",
                            TimeToString(mydeal.Time(), TIME_DATE|TIME_SECONDS)," ",
                            EnumToString((ENUM_DEAL_TYPE)mydeal.DealType())," ",
                            DoubleToString(mydeal.Volume(),2)," ",
                            DoubleToString(mydeal.Price(),5)," ",
                            DoubleToString(profit,2)," ",
                            DoubleToString(commission,2)," ",
                            DoubleToString(swap,2)," ",
                            DoubleToString(balance,2)," ",
                            mydeal.Comment() );
                        dbg( log );
                    }
                }
                else
                {    
                    if( VERBOSE )
                    {
                        string log = "";
                        StringConcatenate(log, "D2: ", deal_cnt," ", 
                            mydeal.Symbol()," ",
                            TimeToString(mydeal.Time(), TIME_DATE|TIME_SECONDS)," ",
                            EnumToString((ENUM_DEAL_TYPE)mydeal.DealType())," ",
                            DoubleToString(mydeal.Volume(),2)," ",
                            DoubleToString(mydeal.Price(),5)," ",
                            DoubleToString(mydeal.Profit(),2)," ",
                            DoubleToString(mydeal.Commission(),2)," ",
                            DoubleToString(mydeal.Swap(),2)," ",
                            DoubleToString(0.0,2)," ",
                            mydeal.Comment() );
                        dbg( log );
                    }
                } // if( ( (DEAL_TYPE_BUY==mydeal.DealType()) || (DEAL_TYPE_SELL==mydeal.DealType()) ) )
            } // if (d_ticket>0)
        } // for (int j=0; j<tot_deals; j++)
        g_balance_start = balance;
        dbg( "BALANCE AT START OF NEW DAY " + nds( g_balance_start,2) );
        
        // TODO log the next line to SQL database at the right place
        double bal_goal = g_balance_start*g_balance_start_increase;
        double bal_diff_abs = bal_now-g_balance_start;
        double bal_goal_diff = bal_goal-g_balance_start;
        double bal_diff_per = 0;
        if( 0.0 != bal_goal_diff ) {bal_diff_per=bal_diff_abs/bal_goal_diff*100;}
        dbg( "BAL_START "+nds( g_balance_start,2)+" BAL_NOW "+nds( bal_now,2)+" BAL_GOAL "+nds(bal_goal,2)+
               " GAIN_ABS " + nds(bal_diff_abs,2) +" GAIN_PER " + nds(bal_diff_per,2)  +
               "%   COMMISSION  " + nds(comm_total,2) +" SWAP  " + nds(swap_total,2) +" PROFIT  " + nds(profit_total,2)  );
        string log = StringFormat("BAL_TIME  FROM[%s] TO[%s] INT FROM[%d] TO[%d]", 
            TimeToString(from_date, TIME_DATE|TIME_SECONDS), TimeToString(to_date, TIME_DATE|TIME_SECONDS), 
            (long)from_date, (long)to_date );
        dbg( log);    

      /*2015.01.23 12:15:02.933	EXPERT (EURUSD.e,M1)	DEBUG - NEW DAY: 23 started at shift 792
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - BAL_START 1000.00 BAL_NOW 1015.56 BAL_GOAL 1030.00 GAIN_ABS 15.56 GAIN_PER 51.87%   COMMISSION  -6.68 SWAP  0.00 PROFIT  22.24
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - BALANCE AT START OF NEW DAY 1000.00
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 13 EURUSD.e 2015.01.23 12:32:21 0.08 1.12416 0.00 -0.18 0.00 1000.00 100
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 12 EURUSD.e 2015.01.23 12:32:29 0.16 1.12425 0.00 -0.36 0.00 999.82 101
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 11 EURUSD.e 2015.01.23 12:32:36 0.24 1.12433 0.00 -0.54 0.00 999.46 102
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 10 EURUSD.e 2015.01.23 12:33:30 0.48 1.12434 3.12 -1.08 0.00 998.92 [sl 1.12434]
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 9 EURUSD.e 2015.01.23 12:43:36 0.08 1.12361 0.00 -0.18 0.00 1000.96 200
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 8 EURUSD.e 2015.01.23 12:43:36 0.16 1.12355 0.00 -0.36 0.00 1000.78 201
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 7 EURUSD.e 2015.01.23 12:43:42 0.24 1.12346 0.00 -0.54 0.00 1000.42 202
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 6 EURUSD.e 2015.01.23 12:44:24 0.48 1.12346 2.64 -1.08 0.00 999.88 [sl 1.12345]
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 5 EURUSD.e 2015.01.23 13:09:33 0.08 1.12406 0.00 -0.18 0.00 1001.44 100
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 4 EURUSD.e 2015.01.23 13:10:27 0.16 1.12417 0.00 -0.36 0.00 1001.26 101
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 3 EURUSD.e 2015.01.23 13:10:30 0.24 1.12426 0.00 -0.54 0.00 1000.90 102
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 2 EURUSD.e 2015.01.23 13:10:56 0.48 1.12454 16.48 -1.08 0.00 1000.36 [sl 1.12455]
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - D: 1 EURUSD.e 2015.01.23 13:11:54 0.09 1.12399 0.00 -0.20 0.00 1015.76 200
        2015.01.23 12:15:02.918	EXPERT (EURUSD.e,M1)	DEBUG - BALANCE NOW 1015.56*/

    } // if (HistorySelect(from_date,to_date))
    
    return (order_cnt+deal_cnt);

} // int m_GetHistoryInfo( datetime from_date, datetime to_date )


/*

//+------------------------------------------------------------------+
Processing of trade events in Expert Advisor using the OnTrade() function
    http://www.mql5.com/en/articles/40
//+------------------------------------------------------------------+



 mt-setup.pl testerrun -symbol=EURUSD -expert=expert -period=H1 -account=AL5D01 -propkey=A
   C:\fx\install\logs\log-ontrade-transaction-20130825.zip

order 
2013.08.22,00:01,3,EURUSD,sell stop,2.20 / 2.20,1.33412,,,2013.08.22 08:58,filled,867
2013.08.22,08:58,4,EURUSD,buy,2.20 / 2.20,1.33370,,,2013.08.22 08:58,filled,sl 1.33370
2013.08.22,00:01,2,EURUSD,buy stop,2.20 / 2.20,1.33451,,,2013.08.22 09:28,filled,867
2013.08.22,09:28,6,EURUSD,sell,2.20 / 2.20,1.33508,,,2013.08.22 09:28,filled,sl 1.33508
2013.08.22,08:59,5,EURUSD,sell stop,2.30 / 2.30,1.33101,,,2013.08.22 11:53,filled,867
2013.08.22,11:54,8,EURUSD,buy,2.30 / 2.30,1.33096,,,2013.08.22 11:54,filled,sl 1.33096
2013.08.22,09:28,7,EURUSD,buy stop,2.30 / 2.30,1.33304,,,2013.08.22 14:30,filled,867
2013.08.22,14:32,10,EURUSD,sell,2.30 / 2.30,1.33243,,,2013.08.22 14:32,filled,
2013.08.22,14:33,11,EURUSD,buy stop,2.30 / 2.30,1.33464,,,2013.08.22 14:36,filled,867
2013.08.22,14:38,12,EURUSD,sell,2.30 / 2.30,1.33378,,,2013.08.22 14:38,filled,
2013.08.22,14:39,13,EURUSD,buy stop,2.20 / 2.20,1.33588,,,2013.08.22 17:06,filled,867
2013.08.22,17:07,14,EURUSD,sell,2.20 / 2.20,1.33696,,,2013.08.22 17:07,filled,sl 1.33696

deal
2013.08.22,09:28,4,EURUSD,buy,in,2.20,1.33451,2,0.00,0.00,0.00,10000.00,867
2013.08.22,08:58,2,EURUSD,sell,in,2.20,1.33412,3,0.00,0.00,0.00,10000.00,867
2013.08.22,08:58,3,EURUSD,buy,out,2.20,1.33370,4,0.00,0.00,92.40,10092.40,sl 1.33370
2013.08.22,11:53,6,EURUSD,sell,in,2.30,1.33101,5,0.00,0.00,0.00,10092.40,867
2013.08.22,09:28,5,EURUSD,sell,out,2.20,1.33508,6,0.00,0.00,125.40,10217.80,sl 1.33508
2013.08.22,14:30,8,EURUSD,buy,in,2.30,1.33304,7,0.00,0.00,0.00,10217.80,867
2013.08.22,11:54,7,EURUSD,buy,out,2.30,1.33096,8,0.00,0.00,11.50,10229.30,sl 1.33096
2013.08.22,14:32,9,EURUSD,sell,out,2.30,1.33243,10,0.00,0.00,-140.30,10089.00,
2013.08.22,14:36,10,EURUSD,buy,in,2.30,1.33464,11,0.00,0.00,0.00,10089.00,867
2013.08.22,14:38,11,EURUSD,sell,out,2.30,1.33378,12,0.00,0.00,-197.80,9891.20,
2013.08.22,17:06,12,EURUSD,buy,in,2.20,1.33588,13,0.00,0.00,0.00,9891.20,867
2013.08.22,17:07,13,EURUSD,sell,out,2.20,1.33696,14,0.00,0.00,237.60,10128.80,sl 1.33696


Orders                                                  
Open Time         Order Symbol  Type        Volume      Price   S/L T/P Time                State       Comment 
2013.08.22 00:01    3   EURUSD  sell stop   2.20 / 2.20 1,33412         2013.08.22 08:58    filled      867 
2013.08.22 08:58    4   EURUSD  buy         2.20 / 2.20 1,33370         2013.08.22 08:58    filled      sl 1.33370  
2013.08.22 00:01    2   EURUSD  buy stop    2.20 / 2.20 1,33451         2013.08.22 09:28    filled      867 
2013.08.22 09:28    6   EURUSD  sell        2.20 / 2.20 1,33508         2013.08.22 09:28    filled      sl 1.33508  
2013.08.22 08:59    5   EURUSD  sell stop   2.30 / 2.30 1,33101         2013.08.22 11:53    filled      867 
2013.08.22 11:54    8   EURUSD  buy         2.30 / 2.30 1,33096         2013.08.22 11:54    filled      sl 1.33096  
2013.08.22 09:28    7   EURUSD  buy stop    2.30 / 2.30 1,33304         2013.08.22 14:30    filled      867 
2013.08.22 14:32    10  EURUSD  sell        2.30 / 2.30 1,33243         2013.08.22 14:32    filled      
2013.08.22 14:33    11  EURUSD  buy stop    2.30 / 2.30 1,33464         2013.08.22 14:36    filled      867 
2013.08.22 14:38    12  EURUSD  sell        2.30 / 2.30 1,33378         2013.08.22 14:38    filled      
2013.08.22 14:39    13  EURUSD  buy stop    2.20 / 2.20 1,33588         2013.08.22 17:06    filled      867 
2013.08.22 17:07    14  EURUSD  sell        2.20 / 2.20 1,33696         2013.08.22 17:07    filled      sl 1.33696  
2013.08.22 17:08    15  EURUSD  buy stop    2.30 / 2.30 1,33670         2013.08.22 23:59    canceled    867 
2013.08.22 11:54    9   EURUSD  sell stop   2.30 / 2.30 1,33459         2013.08.22 23:59    canceled    867 

Deals                                                   
Time               Deal Symbol  Type    Direction   Volume  Price   Order   Commission  Swap    Profit  Balance Comment 
2013.08.22 00:00    1   balance                     0,00    0,00            10 000,00   10 000,00       
2013.08.22 09:28    4   EURUSD  buy     in          2.20    1,33451 2       0,00        0,00    0,00    10 000,00   867 
2013.08.22 08:58    2   EURUSD  sell    in          2.20    1,33412 3       0,00        0,00    0,00    10 000,00   867 
2013.08.22 08:58    3   EURUSD  buy     out         2.20    1,33370 4       0,00        0,00    92,40   10 092,40   sl 1.33370  
2013.08.22 11:53    6   EURUSD  sell    in          2.30    1,33101 5       0,00        0,00    0,00    10 092,40   867 
2013.08.22 09:28    5   EURUSD  sell    out         2.20    1,33508 6       0,00        0,00    125,40  10 217,80   sl 1.33508  
2013.08.22 14:30    8   EURUSD  buy     in          2.30    1,33304 7       0,00        0,00    0,00    10 217,80   867 
2013.08.22 11:54    7   EURUSD  buy     out         2.30    1,33096 8       0,00        0,00    11,50   10 229,30   sl 1.33096  
2013.08.22 14:32    9   EURUSD  sell    out         2.30    1,33243 10      0,00        0,00    -140,30 10 089,00       
2013.08.22 14:36    10  EURUSD  buy     in          2.30    1,33464 11      0,00        0,00    0,00    10 089,00   867 
2013.08.22 14:38    11  EURUSD  sell    out         2.30    1,33378 12      0,00        0,00    -197,80 9 891,20        
2013.08.22 17:06    12  EURUSD  buy     in          2.20    1,33588 13      0,00        0,00    0,00    9 891,20    867 
2013.08.22 17:07    13  EURUSD  sell    out         2.20    1,33696 14      0,00        0,00    237,60  10 128,80   sl 1.33696  

order #3  sell stop
deal  #2    in
order #4  buy
deal  #3    out

FP  0   12:39:20    Core 1  2013.08.22 08:58:00   order modified [#2 buy stop 2.20 EURUSD at 1.33622]
NK  0   12:39:20    Core 1  2013.08.22 08:58:00   order modified [#3 sell stop 2.20 EURUSD at 1.33412]

FH  0   12:39:20    Core 1  2013.08.22 08:58:24   order [#3 sell stop 2.20 EURUSD at 1.33412] triggered
GO  0   12:39:20    Core 1  2013.08.22 08:58:24   deal #2 sell 2.20 EURUSD at 1.33412 done (based on order #3)
RO  0   12:39:20    Core 1  2013.08.22 08:58:24   deal performed [#2 sell 2.20 EURUSD at 1.33412]
LF  0   12:39:20    Core 1  2013.08.22 08:58:24   order performed sell 2.20 at 1.33412 [#3 sell stop 2.20 EURUSD at 1.33412]
FG  0   12:39:20    Core 1  2013.08.22 08:58:24   TRADE_TRANSACTION_DEAL_ADD EURUSD Deal# 2 Deal type: DEAL_TYPE_SELL Order# 3 Order type: ORDER_TYPE_BUY 2.2 at 1.33412
OP  0   12:39:20    Core 1  2013.08.22 08:58:24   TRADE_TRANSACTION_ORDER_DELETE EURUSD Deal# 0 Deal type: DEAL_TYPE_BUY Order# 3 Order type: ORDER_TYPE_SELL_STOP 2.2 at 1.33412

RR  0   12:39:20    Core 1  2013.08.22 08:58:33   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33411]
QE  0   12:39:20    Core 1  2013.08.22 08:58:34   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33408]
KI  0   12:39:20    Core 1  2013.08.22 08:58:34   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33404]
NL  0   12:39:20    Core 1  2013.08.22 08:58:34   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33401]
JO  0   12:39:20    Core 1  2013.08.22 08:58:35   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33398]
HS  0   12:39:20    Core 1  2013.08.22 08:58:35   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33394]
LF  0   12:39:20    Core 1  2013.08.22 08:58:36   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33391]
KI  0   12:39:20    Core 1  2013.08.22 08:58:36   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33387]
CM  0   12:39:20    Core 1  2013.08.22 08:58:37   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33384]
NP  0   12:39:20    Core 1  2013.08.22 08:58:37   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33381]
KD  0   12:39:20    Core 1  2013.08.22 08:58:37   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33377]
EG  0   12:39:20    Core 1  2013.08.22 08:58:38   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33374]
OJ  0   12:39:20    Core 1  2013.08.22 08:58:38   position modified [sell 2.20 EURUSD 1.33412 sl: 1.33370]

IN  0   12:39:20    Core 1  2013.08.22 08:58:59   stop loss triggered sell 2.20 EURUSD 1.33412 sl: 1.33370 [#4 buy 2.20 EURUSD at 1.33370]
HS  0   12:39:20    Core 1  2013.08.22 08:58:59   deal #3 buy 2.20 EURUSD at 1.33370 done (based on order #4)
NQ  0   12:39:20    Core 1  2013.08.22 08:58:59   deal performed [#3 buy 2.20 EURUSD at 1.33370]
MF  0   12:39:20    Core 1  2013.08.22 08:58:59   order performed buy 2.20 at 1.33370 [#4 buy 2.20 EURUSD at 1.33370]
CI  0   12:39:20    Core 1  2013.08.22 08:58:59   TRADE_TRANSACTION_DEAL_ADD EURUSD Deal# 3 Deal type: DEAL_TYPE_BUY Order# 4 Order type: ORDER_TYPE_BUY 2.2 at 1.3337
PR  0   12:39:20    Core 1  2013.08.22 08:58:59   TRADE_TRANSACTION_ORDER_DELETE EURUSD Deal# 0 Deal type: DEAL_TYPE_BUY Order# 4 Order type: ORDER_TYPE_BUY 2.2 at 1.3337

*/

//+------------------------------------------------------------------+
//|   m_LogPositionBySymbol                                          |
//+------------------------------------------------------------------+
int m_LogPositionBySymbol( CSymbol& s )
{
    //
    //  TODO not working in tester mode:
    //  POSITION_TIME_MSC is always 0
    //
    //  TODO not implemented yet:
    //  POSITION_TIME_UPDATE, POSITION_TIME_UPDATE_MSC, POSITION_MAGIC, POSITION_PRICE_CURRENT, POSITION_SWAP, POSITION_COMMISSION
    //
    int cnt = 0;
    if( PositionSelect(s.SYMBOL) )
    {
        cnt++;
        m_log_history_to_sql(   s, "ABC_P", g_time_local,
                                PositionGetInteger(POSITION_TIME_MSC),PositionGetInteger(POSITION_TIME),
                                PositionGetInteger(POSITION_IDENTIFIER),0,EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),"",
                                PositionGetDouble(POSITION_VOLUME),PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP),PositionGetDouble(POSITION_PROFIT),0.0,
                                PositionGetString(POSITION_COMMENT),
                                "", PositionGetDouble(POSITION_COMMISSION), PositionGetDouble(POSITION_SWAP)
                            );
    }
    return cnt;
} // int m_LogPositionBySymbol( string symbol )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_LogOrdersByIndex
//+------------------------------------------------------------------+
// TODO not used anymore - but maybe comments and ABC_O logging is still useful
int m_LogOrdersByIndex( CSymbol& s, int tot_orders_prev, int tot_orders )
{
    
    //
    //  TODO not working in tester mode:
    //  ORDER_TIME_SETUP_MSC is always 0
    //
    //  TODO not implemented yet:
    //  ORDER_TIME_EXPIRATION, ORDER_TIME_DONE, ORDER_TIME_DONE_MSC, ORDER_TYPE_FILLING, ORDER_TYPE_TIME, ORDER_MAGIC,
    //  ORDER_POSITION_ID, ORDER_VOLUME_CURRENT, ORDER_PRICE_CURRENT, ORDER_PRICE_STOPLIMIT
    //
    
    int cnt = 0;
    for(int pos=tot_orders_prev; pos<tot_orders; pos++)
    {
        ulong ticket = OrderGetTicket(pos);
        if(OrderSelect(ticket))
        {
            if(OrderGetString(ORDER_SYMBOL)!=s.SYMBOL)
            {
                continue;
            }
            cnt ++;
            m_log_history_to_sql(   s, "ABC_O", g_time_local,
                                    OrderGetInteger(ORDER_TIME_SETUP_MSC),OrderGetInteger(ORDER_TIME_SETUP),
                                    ticket,0,EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)),EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)),
                                    OrderGetDouble(ORDER_VOLUME_INITIAL),OrderGetDouble(ORDER_PRICE_OPEN),OrderGetDouble(ORDER_SL),OrderGetDouble(ORDER_TP),0.0,0.0,
                                    OrderGetString(ORDER_COMMENT),
                                    ""
                                );

        } // if(OrderSelect(ticket))  
    } // for(int pos=0; pos<tot_orders(); pos++)
    return (cnt);
} // int m_LogOrdersByIndex( int tot_orders_prev, int tot_orders )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_LogHistoryOrders
//+------------------------------------------------------------------+
int m_LogHistoryOrders( CSymbol& s, datetime a_start, datetime a_end, bool a_log = true )
{
    // http://www.mql5.com/en/articles/138
    //
    // Get total orders in history
    //

    //
    //  TODO not working in tester mode:
    //  ORDER_TIME_DONE_MSC is always 0
    //
    //  TODO not implemented yet:
    //  ORDER_TIME_EXPIRATION, ORDER_TIME_SETUP, ORDER_TIME_SETUP_MSC, ORDER_TYPE_FILLING, ORDER_TYPE_TIME, ORDER_MAGIC,
    //  ORDER_POSITION_ID, ORDER_VOLUME_CURRENT, ORDER_PRICE_CURRENT, ORDER_PRICE_STOPLIMIT
    //
    
    int order_cnt = 0;
    if( true == HistorySelect(a_start, a_end) )    
    {
        int total = HistoryOrdersTotal();
    
        for (int j=0; j<total; j++)
        {
            ulong o_ticket = HistoryOrderGetTicket(j);
            if (o_ticket>0)
            {
                if( s.SYMBOL != HistoryOrderGetString(o_ticket,ORDER_SYMBOL) )
                {
                    continue;
                }
                order_cnt++;
                if( true == a_log )
                {
                    
                    m_log_history_to_sql(   s, "ABC_H", g_time_local,
                                            HistoryOrderGetInteger(o_ticket,ORDER_TIME_DONE_MSC),HistoryOrderGetInteger(o_ticket,ORDER_TIME_DONE),
                                            o_ticket,0,EnumToString((ENUM_ORDER_TYPE)HistoryOrderGetInteger(o_ticket,ORDER_TYPE)),EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(o_ticket,ORDER_STATE)),
                                            HistoryOrderGetDouble(o_ticket,ORDER_VOLUME_INITIAL),HistoryOrderGetDouble(o_ticket,ORDER_PRICE_OPEN),HistoryOrderGetDouble(o_ticket,ORDER_SL),HistoryOrderGetDouble(o_ticket,ORDER_TP),0.0,0.0,
                                            HistoryOrderGetString(o_ticket,ORDER_COMMENT),
                                            ""
                                        );
                } // if( true == a_log )
            } // if (h_ticket>0)
        } // for (int j=0; j<tot_hist_orders; j++)
    }
    else
    {
        //printf("ERROR HISTORY SELECT1 ( %s %s %s ) [%s]", SYMBOL,TimeToString(a_start), TimeToString(a_end), GetLastError());
    } // if( true == HistorySelect(a_start, a_end) )    
    return (order_cnt);
} // int m_LogHistoryOrders( string a_symbol, datetime a_start, datetime a_end, bool a_log = true )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_LogHistoryDeals
//+------------------------------------------------------------------+
int m_LogHistoryDeals( CSymbol& s, datetime a_start, datetime a_end, bool a_log = true )
{
    //
    // Get total deals in history
    //

    //
    //  TODO not working in tester mode:
    //  DEAL_TIME_MSC is always 0
    //
    //  TODO not implemented yet:
    //  DEAL_MAGIC, DEAL_POSITION_ID, DEAL_COMMISSION, DEAL_SWAP
    //

    int deal_cnt = 0;
    if( true == HistorySelect(a_start, a_end) )    
    {
        int total = HistoryDealsTotal();
    
        for (int j=0; j<total; j++)
        {
            ulong d_ticket = HistoryDealGetTicket(j);
            if (d_ticket>0)  
            {
                if( s.SYMBOL != HistoryDealGetString(d_ticket,DEAL_SYMBOL) )
                {
                    continue;
                }
    
                deal_cnt++;
                if( true == a_log )
                {
                    m_log_history_to_sql(   s, "ABC_D", g_time_local,
                                            HistoryDealGetInteger(d_ticket,DEAL_TIME_MSC),HistoryDealGetInteger(d_ticket,DEAL_TIME),
                                            HistoryDealGetInteger(d_ticket,DEAL_ORDER),d_ticket,EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(d_ticket,DEAL_TYPE)),EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d_ticket,DEAL_ENTRY)),
                                            HistoryDealGetDouble(d_ticket,DEAL_VOLUME),HistoryDealGetDouble(d_ticket,DEAL_PRICE),0.0,0.0,HistoryDealGetDouble(d_ticket,DEAL_PROFIT),0.0,
                                            HistoryDealGetString(d_ticket,DEAL_COMMENT),
                                            "", HistoryDealGetDouble(d_ticket,DEAL_COMMISSION), HistoryDealGetDouble(d_ticket,DEAL_SWAP)
                                        );
                } // if( true == a_log )
            } // if (d_ticket>0)
        } // for (int j=0; j<tot_deals; j++)
    }
    else
    {
        //printf("DEBUG ERROR HISTORY SELECT2 ( %s %s %s ) [%s]", SYMBOL,TimeToString(a_start), TimeToString(a_end), GetLastError());
    } // if( true == HistorySelect(a_start, a_end) )     
    return (deal_cnt);
    
} // int m_LogHistoryDeals( string a_symbol, datetime a_start, datetime a_end, bool a_log = true )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  g_InitHistoryProcessor - initialization of the counters of positions, orders and deals
//+------------------------------------------------------------------+
void g_InitHistoryProcessor(CSymbol& s)
{
    s.g_history_start_date_d = g_time_current-1;
    s.g_history_start_date_o = g_time_current-1;
    ResetLastError();
    s.g_history_started=true;
    
} // void g_InitHistoryProcessor()
//+------------------------------------------------------------------+
  
//+------------------------------------------------------------------+
//| g_HistoryProcessor - processing changes in trade and history
//+------------------------------------------------------------------+
void g_HistoryProcessor(CSymbol& s)
{
    datetime end_date = g_time_current-1;
    int cnt_d=m_LogHistoryDeals (s, s.g_history_start_date_d, end_date );
    if( 0 < cnt_d )
    {
        //printf("DEBUG cnt_d ( S:%s F:%s T:%s )", SYMBOL,TimeToString(g_history_start_date_d,TIME_DATE|TIME_SECONDS), TimeToString(g_time_current,TIME_DATE|TIME_SECONDS));
      /*2014.11.27 16:13:20.175	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:13:19 T:2014.11.27 17:13:20 )
        2014.11.27 16:13:19.878	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:13:19 T:2014.11.27 17:13:19 )
        2014.11.27 16:13:19.581	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:13:19 T:2014.11.27 17:13:19 )
        2014.11.27 16:13:19.456	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:13:19 T:2014.11.27 17:13:19 )
        2014.11.27 16:13:19.441	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:13:19 T:2014.11.27 17:13:19 )
        2014.11.27 16:13:19.425	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:13:19 T:2014.11.27 17:13:19 )
        2014.11.27 16:13:19.409	EXPERT (EURUSD,M1)	cnt_d ( S:EURUSD F:2014.11.27 17:12:33 T:2014.11.27 17:13:19 )*/
        // TODO add one more second here, to avoid the multiple output of the cnt_d into MYSQL, see log above
        // this should be fixed. this workaround is only temporary, as some deals and orders could be lost
        // a HistorySelect that uses MilliSeconds as input would be desired here
        s.g_history_start_date_d = end_date+1;
    }
    
    int cnt_o=m_LogHistoryOrders(s, s.g_history_start_date_o, end_date );
    if( 0 < cnt_o )
    {
        //printf("DEBUG cnt_o ( S:%s F:%s T:%s )", SYMBOL,TimeToString(g_history_start_date_o,TIME_DATE|TIME_SECONDS), TimeToString(g_time_current,TIME_DATE|TIME_SECONDS));
        s.g_history_start_date_o = end_date+1;
    }

//--- get current values
    // TODO - a bit ugly - fix that the TOTALS are SYMBOL dependant
    //int cnt_o=m_LogOrdersByIndex(SYMBOL);
    int cnt_p=(int)(PositionsTotal()&&PositionSelect(s.SYMBOL));
//--- change in the number of open positions
    if( (cnt_p != s.g_history_p_cnt) && (s.g_history_p_cnt < cnt_p ) )
    {
        int cnt = m_LogPositionBySymbol( s );
        if( 0 == cnt ) dbg(s, "ERROR HISTORY CNT=0 m_LogPositionBySymbol( "+s.SYMBOL+" ) ["+IntegerToString(GetLastError())+"]" );
        //--- update value
        s.g_history_p_cnt=cnt_p;
    } // if( cnt_p != g_history_p_cnt )
    

} // void g_HistoryProcessor()
//+------------------------------------------------------------------+


//
// WATCHER FUNCTIONS
//
//+------------------------------------------------------------------+
//| WATCHER FUNCTIONS                                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_InitWatcherData
//+------------------------------------------------------------------+
void m_InitWatcherData( CSymbol& s ) 
{

    // generic
    s.g_watcher_data.update = false;
        
    // open position
    s.g_watcher_data.posopenbuycnt = 0;
    s.g_watcher_data.posopensellcnt = 0;
    s.g_watcher_data.posopentime = 0;
    s.g_watcher_data.posopenprice = 0;
    s.g_watcher_data.posopenprofit = 0;
    s.g_watcher_data.posopencomment = "";
    
    // pending orders buy
    s.g_watcher_data.ordbuycnt = 0;
    s.g_watcher_data.ordbuytime = 0;
    s.g_watcher_data.ordbuyprice = 0;
    s.g_watcher_data.ordbuycomment = "";

    // pending orders sell
    s.g_watcher_data.ordsellcnt = 0;
    s.g_watcher_data.ordselltime = 0;
    s.g_watcher_data.ordsellprice = 0;
    s.g_watcher_data.ordsellcomment = "";
    
    // account data
    s.g_watcher_data.accbalance = 0;
    s.g_watcher_data.accequity = 0;
    s.g_watcher_data.accmargin = 0;
    s.g_watcher_data.accfreemargin = 0;
    s.g_watcher_data.accprofit = 0;
    s.g_watcher_data.accprofit_prev = 0;
    
    // statistic data
    //s.g_watcher_data.stat_cnt = 0;
    //s.g_watcher_data.stat_avg = 0;
    //ArrayResize(s.g_watcher_data.stat_avg_arr, 1000);
    //ArrayInitialize(s.g_watcher_data.stat_avg_arr, 0 );


} // void m_InitWatcherData( SWatcherData& wd ) 


//+------------------------------------------------------------------+
//|   m_LogWatcherData
//+------------------------------------------------------------------+
void m_LogWatcherData( CSymbol& s, bool a_ignore_update_flag = false ) 
{
    if( (false == a_ignore_update_flag) && (false == s.g_watcher_data.update) )
    {
        return;
    }
    double inc = 0;
    if( 0 != s.g_watcher_data.accprofit_prev )
    {
        inc = (s.g_watcher_data.accprofit-s.g_watcher_data.accprofit_prev)/s.g_watcher_data.accprofit_prev*100;
    }
    string log = "pbuy("+IntegerToString(s.g_watcher_data.posopenbuycnt)+") psell("+IntegerToString(s.g_watcher_data.posopensellcnt)+") obuy("+IntegerToString(s.g_watcher_data.ordbuycnt)+") osell("+IntegerToString(s.g_watcher_data.ordsellcnt)+ 
                 ") bal("+nds(s,s.g_watcher_data.accbalance,0)+") equ("+nds(s,s.g_watcher_data.accequity,0) +") pro("+nds(s,s.g_watcher_data.accprofit,0)+
                 ") mar("+nds(s,s.g_watcher_data.accmargin,0)+") freemar("+nds(s,s.g_watcher_data.accfreemargin,0) + 
                 //") cnt("+IntegerToString(s.g_watcher_data.stat_cnt)+") avg("+nds(s,s.g_watcher_data.stat_avg,0) + 
                 ") cnt("+IntegerToString(s.g_watcher_data.stat_cnt)+") inc("+nds(s,inc,0) + 
                 ")";
    Log2Sql( s, "WATCHER", 0, log );

} // void m_LogWatcherData( SWatcherData& wd ) 

//+------------------------------------------------------------------+
//|   m_GetWatcherData
//+------------------------------------------------------------------+
void m_GetWatcherData( CSymbol& s ) 
{

    // init the watcher data
    s.g_watcher_data.update = false;

    // fill in the values for the open position
    if( false == PositionSelect(s.SYMBOL)) 
    {
        if( (0 < s.g_watcher_data.posopenbuycnt) || (0 < s.g_watcher_data.posopensellcnt) )
        {
            s.g_watcher_data.update = true;
        }
        s.g_watcher_data.posopenbuycnt = 0;
        s.g_watcher_data.posopensellcnt = 0;
        s.g_watcher_data.posopentime = (datetime) 0;
        s.g_watcher_data.posopenprice = 0.0;
        s.g_watcher_data.posopenprofit = 0.0;
        s.g_watcher_data.posopencomment = "";
    }
    else
    {
        if( (0 == s.g_watcher_data.posopenbuycnt) && (0 == s.g_watcher_data.posopensellcnt) )
        {
            s.g_watcher_data.update = true;
        }
        if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
        {
            s.g_watcher_data.posopenbuycnt = 1;
        }
        else
        {
            s.g_watcher_data.posopensellcnt = 1;
        }
        s.g_watcher_data.posopentime = (datetime)PositionGetInteger(POSITION_TIME);
        s.g_watcher_data.posopenprice = PositionGetDouble(POSITION_PRICE_OPEN);
        s.g_watcher_data.posopenprofit = PositionGetDouble(POSITION_PROFIT);
        s.g_watcher_data.posopencomment = PositionGetString(POSITION_COMMENT);
    
    } // if( false == PositionSelect(SYMBOL)) 


    // fill in the values for the pending orders
    int buycnt = 0;
    int sellcnt = 0;
    for(int pos=0; pos<OrdersTotal(); pos++)
    {
        if(OrderSelect(OrderGetTicket(pos)))
        {
            if(OrderGetString(ORDER_SYMBOL)!=s.SYMBOL) 
            {
                continue;
            }

            datetime td = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
            datetime ts = (datetime)OrderGetInteger(ORDER_TIME_SETUP);  
            datetime tmod = 0;
            // the pending order was setup and the price was already modified
            if( (0 != td)  && (0 != ts))
            {
               tmod = td;
            } 
            // the pending order was setup only
            else if ( 0 != ts )
            {
               tmod = ts + (datetime)g_pending_order_expiry_time_s;
            }
            // generic error with the pending order times 
            else
            {
               string log = "SYSTEM ERROR - WATCHER CAN NOT REMOVE EXPIRED PENDING ORDERS - Time Setup: " 
               + TimeToString(ts, TIME_DATE|TIME_SECONDS)
               + " Time Expired: " + TimeToString(tmod, TIME_DATE|TIME_SECONDS) 
               + " < Time Now: " + TimeToString(g_time_current, TIME_DATE|TIME_SECONDS);
               Log2Sql( s, "SYSTEM", -42, log );
            }
            
            if(   (OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP)
                ||(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_LIMIT) ) 
            {
                buycnt++;
                s.g_watcher_data.ordbuyprice = OrderGetDouble(ORDER_PRICE_CURRENT);
                s.g_watcher_data.ordbuytime  = tmod;
                s.g_watcher_data.ordbuycomment = OrderGetString(ORDER_COMMENT);
                // check that expert advisor is still alive 
                // and modifies the pending orders every PERIOD seconds
                if( (0 != s.g_watcher_data.ordbuytime) && (s.g_watcher_data.ordbuytime < g_time_current ) )
                {
                    string log = "SYSTEM ERROR - WATCHER REMOVES EXPIRED PENDING ORDERS - Time Setup: " 
                     + TimeToString(ts, TIME_DATE|TIME_SECONDS)
                     + " Time Modify: " + TimeToString(td, TIME_DATE|TIME_SECONDS) 
                     + " Time Expired: " + TimeToString(tmod, TIME_DATE|TIME_SECONDS) 
                     + " < Time Now: " + TimeToString(g_time_current, TIME_DATE|TIME_SECONDS);
                    Log2Sql( s, "SYSTEM", -42, log );
                    //m_RemovePendingOrders();
                }
            } // if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP)
            if(    (OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP)
                || (OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT) )
            {
                sellcnt++;
                s.g_watcher_data.ordsellprice = OrderGetDouble(ORDER_PRICE_CURRENT);
                s.g_watcher_data.ordselltime  = tmod;
                s.g_watcher_data.ordsellcomment = OrderGetString(ORDER_COMMENT);
                // check that expert advisor is still alive 
                // and modifies the pending orders every PERIOD seconds
                if( (0 != s.g_watcher_data.ordselltime) && (s.g_watcher_data.ordselltime < g_time_current ) )
                {
                    string log = "SYSTEM ERROR - WATCHER REMOVES EXPIRED PENDING ORDERS - Time Setup: " 
                     + TimeToString(ts, TIME_DATE|TIME_SECONDS)
                     + " Time Modify: " + TimeToString(td, TIME_DATE|TIME_SECONDS) 
                     + " Time Expired: " + TimeToString(tmod, TIME_DATE|TIME_SECONDS) 
                     + " < Time Now: " + TimeToString(g_time_current, TIME_DATE|TIME_SECONDS);
                    Log2Sql( s, "SYSTEM", -42, log );
                    //m_RemovePendingOrders();
                }
            } // if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP)
        } // if(OrderSelect(OrderGetTicket(pos)))
    } // for(int pos=0; pos<OrdersTotal(); pos++)
    
    if( buycnt != s.g_watcher_data.ordbuycnt ) s.g_watcher_data.update = true; 
    s.g_watcher_data.ordbuycnt = buycnt;
    if( sellcnt != s.g_watcher_data.ordsellcnt ) s.g_watcher_data.update = true; 
    s.g_watcher_data.ordsellcnt = sellcnt;
    
    
    // fill in the account values
    // TODO IMPORTANT - implement MARGIN CALL - if balance/equity drops within one day then stop trading
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    double equ = AccountInfoDouble(ACCOUNT_EQUITY);
    if( bal != s.g_watcher_data.accbalance ) s.g_watcher_data.update = true;
    if( (bal != equ) && (s.g_watcher_data.accbalance==s.g_watcher_data.accequity) ) s.g_watcher_data.update = true;
    if( (bal == equ) && (s.g_watcher_data.accbalance!=s.g_watcher_data.accequity) ) s.g_watcher_data.update = true;
    s.g_watcher_data.accbalance = bal;
    s.g_watcher_data.accequity = equ;
    s.g_watcher_data.accmargin = AccountInfoDouble(ACCOUNT_MARGIN);
    s.g_watcher_data.accfreemargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
    s.g_watcher_data.accprofit_prev = s.g_watcher_data.accprofit;
    s.g_watcher_data.accprofit = AccountInfoDouble(ACCOUNT_PROFIT);

    // 
    if( false == PositionSelect(s.SYMBOL)) 
    {
        // statistic data
        s.g_watcher_data.stat_cnt = 0;
        s.g_watcher_data.stat_avg = 0;
        ArrayResize(s.g_watcher_data.stat_avg_arr, 1000);
        ArrayInitialize(s.g_watcher_data.stat_avg_arr, 0 );
    }
    else
    {
        // TODO a bit ugly - review and fix me
        // TODO fix me MQL2DLL 64-bit version
        // TODO fixme array overflow
        /*if( 1000 <= s.g_watcher_data.stat_cnt )
        {
            s.g_watcher_data.stat_cnt = 0;
            dbg(s, "!!!! WATCHER STAT ARR OVERFLOW !!!! " );
        }
        s.g_watcher_data.stat_avg_arr[s.g_watcher_data.stat_cnt] = s.g_watcher_data.accprofit;
        s.g_watcher_data.stat_cnt++;
        double avg = 0;
        for(int cnt = 0; cnt <s.g_watcher_data.stat_cnt; cnt++ )
        {
            avg = avg + s.g_watcher_data.stat_avg_arr[cnt];
        }
        s.g_watcher_data.stat_avg = avg/s.g_watcher_data.stat_cnt;*/
    }

} // void m_GetWatcherData( SWatcherData& wd ) 


//
// TRADING FUNCTIONS
//
//+------------------------------------------------------------------+
//| TRADING FUNCTIONS                                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_GetVolumeOfPendingOrder
//+------------------------------------------------------------------+
double m_GetVolumeOfPendingOrder(CSymbol& s, ENUM_ORDER_TYPE a_order_type, int a_magic = -1 ) 
{
    double vol = 0;
    int cnt = 0;
    for(int pos=0; pos<OrdersTotal(); pos++)
    {
        if(OrderSelect(OrderGetTicket(pos)))
        {
            if(( 0 < a_magic) && (OrderGetInteger(ORDER_MAGIC)!=a_magic))
            {
                continue;
            }
            if(OrderGetString(ORDER_SYMBOL)!=s.SYMBOL) 
            {
                continue;
            }
            if(OrderGetInteger(ORDER_TYPE)==a_order_type)
            {
                cnt ++;
                vol = vol + OrderGetDouble(ORDER_VOLUME_CURRENT);
            }
        } // if(OrderSelect(OrderGetTicket(pos)))
    } // for(int pos=0; pos<OrdersTotal(); pos++)
    return (vol);
} // double m_GetVolumeOfPendingOrder(ENUM_ORDER_TYPE a_order_type, int a_magic )


//+------------------------------------------------------------------+
//|   m_CntOrderPending                                              |
//+------------------------------------------------------------------+
int m_CntOrderPending(CSymbol& s, ENUM_ORDER_TYPE a_order_type, int a_magic = -1 ) 
{
    int cnt = 0;
    for(int pos=0; pos<OrdersTotal(); pos++)
    {
        if(OrderSelect(OrderGetTicket(pos)))
        {
            if(( 0 < a_magic) && (OrderGetInteger(ORDER_MAGIC)!=a_magic))
            {
                continue;
            }
            if(OrderGetString(ORDER_SYMBOL)!=s.SYMBOL) 
            {
                continue;
            }
            if(OrderGetInteger(ORDER_TYPE)==a_order_type)
            {
                cnt++;
            }
        } // if(OrderSelect(OrderGetTicket(pos)))
    } // for(int pos=0; pos<OrdersTotal(); pos++)
    return (cnt);
} // int m_CntOrderPending(ENUM_ORDER_TYPE a_order_type, int a_magic )


//+------------------------------------------------------------------+
//|   m_CntOrderTotalBySymbol                                        |
//+------------------------------------------------------------------+
int m_CntOrderTotalBySymbol( CSymbol& s ) {
    int cnt = 0;
    for(int pos=0; pos<OrdersTotal(); pos++){
        if(OrderSelect(OrderGetTicket(pos))){
            if(OrderGetString(ORDER_SYMBOL)!=s.SYMBOL) continue; 
            cnt++;
        }
    }
    return (cnt);
} // int m_CntOrderTotalBySymbol( string asymbol )

//+------------------------------------------------------------------+
//|   Modify an open position                                        |
//+------------------------------------------------------------------+
int m_ModifyOpenPosition( CSymbol& s, double sl, double tp, int a_magic, double order_sl, double order_tp)
//+------------------------------------------------------------------+
{
    int ret = -1;
       
    MqlTradeRequest m_trade_request;            // parameters trading query
    MqlTradeResult m_trade_result;              // trade result of the trade query
    MqlTradeCheckResult m_trade_check_result;   // trade check result of the trade query
    ZeroMemory(m_trade_request);
    ZeroMemory(m_trade_result);
    ZeroMemory(m_trade_check_result);

    // TODO document this and make this optional
    // if hedge account then set position
    //m_trade_request.position=PositionGetInteger(POSITION_TICKET);
    // if no hedge account then set order number
    m_trade_request.order  = s.m_position_id;
    m_trade_request.action = TRADE_ACTION_SLTP;
    m_trade_request.symbol = s.SYMBOL;
    m_trade_request.sl     = sl;
    m_trade_request.tp     = tp;
    m_trade_request.magic  = a_magic;
    string comment = g_computername + " ASK/BID/SL " + nds(s,s.ASK) + "/" + nds(s,s.BID) + "/" + nds(s,sl);
    //m_trade_request.comment = comment;
    
    if( OrderCheck(m_trade_request,m_trade_check_result) == false ){
        string log = StringFormat("ERROR[%d][%s] OrderCheck m_ModifyOpenPosition(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d]",
            m_trade_check_result.retcode,m_trade_check_result.comment,comment, s.SYMBOL, 
            s.m_order_volume, s.m_position_id, EnumToString((ENUM_ORDER_TYPE)s.m_order_type),
            s.m_order_open_price,s.ASK,s.BID,sl,tp,a_magic);    
        Log2Sql( s, "ORDER", m_trade_check_result.retcode, log );
        
    } else {
        bool br = OrderSend(m_trade_request,m_trade_result);
        // TRADE_RETCODE_DONE == 10009  TRADE_RETCODE_PLACED == 10008
        if( (true == br) && ( (TRADE_RETCODE_DONE == m_trade_result.retcode) || ( TRADE_RETCODE_PLACED == m_trade_result.retcode) ) ){
            ret = 0;
            if( PositionSelect(s.SYMBOL) )
            {
                double price = PositionGetDouble(POSITION_PRICE_OPEN);
              m_log_history_to_sql(   s, "ABC_S", g_time_local,
                PositionGetInteger(POSITION_TIME_UPDATE_MSC),PositionGetInteger(POSITION_TIME_UPDATE),
                PositionGetInteger(POSITION_IDENTIFIER),0,EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),"",
                PositionGetDouble(POSITION_VOLUME),price,sl,tp,PositionGetDouble(POSITION_PROFIT),0.0,
                /*PositionGetString(POSITION_COMMENT)*/ comment,
                "", PositionGetDouble(POSITION_COMMISSION), PositionGetDouble(POSITION_SWAP)
                );
                
                dbg(s, "ModifyOpenPosition M:" + IntegerToString(a_magic) + " PRICE: " + nds(s,price) + " SL: " + nds(s,order_sl) + " -> " + nds(s,sl) + " ASK/BID " + nds(s, s.ASK) + "/" + nds(s, s.BID)  + " T:" + EnumToString((ENUM_ORDER_TYPE) s.m_order_type));
                
            } // if( PositionSelect(SYMBOL) )
          
        } else {
            string log = StringFormat("ERROR[%d] [%s] OrderSend m_ModifyOpenPosition(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d]",
                m_trade_result.retcode,m_trade_result.comment,comment, s.SYMBOL, 
                s.m_order_volume, s.m_position_id, EnumToString((ENUM_ORDER_TYPE)s.m_order_type),
                s.m_order_open_price,s.ASK,s.BID,sl,tp,a_magic);    
            Log2Sql( s, "ORDER", m_trade_result.retcode, log );
        
        } // if( (TRADE_RETCODE_DONE == m_trade_result.retcode) || ( TRADE_RETCODE_PLACED == m_trade_result.retcode) )
    } // if( OrderCheck(m_request,check) == false )
    return (ret);      
}


//+------------------------------------------------------------------+
//|   Modify a single pending order
//+------------------------------------------------------------------+
void m_ModifyPendingOrder(CSymbol& s, double a_price, int a_price_points, int a_sl_points, int a_tp_points, int a_magic ) {
//+------------------------------------------------------------------+

    //--- Processing pending orders
    for(int pos=0; pos<OrdersTotal(); pos++)
    {
        s.m_order_ticket=OrderGetTicket(pos);

        if(OrderSelect(s.m_order_ticket))
        {
            if( OrderGetString(ORDER_SYMBOL)!=s.SYMBOL )
            {
                continue;
            }
            // modify only the order marked by the magic value
            if( OrderGetInteger(ORDER_MAGIC)!=a_magic )
            {
                continue;
            }
            
            s.m_order_type=OrderGetInteger(ORDER_TYPE);
            s.m_order_open_price=OrderGetDouble(ORDER_PRICE_OPEN);
            
            datetime time_setup;      // time pending order was setup
            time_setup =(datetime)OrderGetInteger(ORDER_TIME_SETUP);
            
            //
            double price = s.m_order_open_price;
            double sl = OrderGetDouble(ORDER_SL);
            double tp = OrderGetDouble(ORDER_TP);
        
            if( -1 == a_price_points )
            {
        	    // TODO a but ugly - clean up
   	            // if a_price == 0.0 then use ASK/BID
   	            // if a_price == -1 then do not open a order (just pending order expiry update)
   	            // else open order with usually o0 price
                  //dbg( "UPDATE pending order expiry: " + nds(price) + " " + nds(OrderGetDouble(ORDER_PRICE_CURRENT)) + " " + nds(sl) + " " + nds(tp) );
            }
            else
            {
                if( a_price_points < s.m_order_stop_level ){ 
                    a_price_points = s.m_order_stop_level; 
                }
                if( a_sl_points != 0 ){  
                    if( a_sl_points < s.m_order_stop_level ) {
                        a_sl_points = s.m_order_stop_level;
                    }
                }
                if( a_tp_points != 0 ){  
                    if( a_tp_points < s.m_order_stop_level ) {
                        a_tp_points = s.m_order_stop_level;
                    }
                }
            
                //--- Adjust the price of orders
                // buy stop
                if( s.m_order_type == ORDER_TYPE_BUY_STOP ) {
                    if( 0.0 < a_price ) {
                        price = g_CalcPricePendOrder(s, a_price, (ENUM_ORDER_TYPE)s.m_order_type, a_price_points );
                    } else {
                        price=NormalizeDouble(s.ASK + a_price_points*s.POINT, s.DIGITS);
                    }                    
                    if( a_sl_points != 0 ) sl=NormalizeDouble(price-a_sl_points*s.POINT-s.m_order_spread,s.DIGITS);
                    if( a_tp_points != 0 ) tp=NormalizeDouble(price+a_tp_points*s.POINT+s.m_order_spread,s.DIGITS);
            
                // sell stop
                } else if ( s.m_order_type == ORDER_TYPE_SELL_STOP ) {
                    if( 0.0 < a_price ) {
                        price = g_CalcPricePendOrder(s, a_price, (ENUM_ORDER_TYPE)s.m_order_type, a_price_points );
                    } else {
                        price= NormalizeDouble(s.BID - a_price_points * s.POINT,s.DIGITS);
                    }
                    if( a_sl_points != 0 ) sl=NormalizeDouble(price+a_sl_points*s.POINT+s.m_order_spread,s.DIGITS);
                    if( a_tp_points != 0 ) tp=NormalizeDouble(price-a_tp_points*s.POINT-s.m_order_spread,s.DIGITS);
                    
                // buy limit
                } else if( s.m_order_type == ORDER_TYPE_BUY_LIMIT ) {
                    if( 0.0 < a_price ) {
                        price=NormalizeDouble(a_price - a_price_points*s.POINT, s.DIGITS);
                    } else {
                        price= NormalizeDouble(s.ASK - a_price_points * s.POINT,s.DIGITS);
                    }
                    // TODO check if that sl/tp formula is correct
                    if( a_sl_points != 0 ) sl=NormalizeDouble(price-a_sl_points*s.POINT-s.m_order_spread,s.DIGITS);
                    if( a_tp_points != 0 ) tp=NormalizeDouble(price+a_tp_points*s.POINT+s.m_order_spread,s.DIGITS);
                
                // sell limit
                } else if ( s.m_order_type == ORDER_TYPE_SELL_LIMIT ) {
                    if( 0.0 < a_price ) {
                        price=NormalizeDouble(a_price + a_price_points*s.POINT, s.DIGITS);
                    } else {
                        price=NormalizeDouble(s.BID + a_price_points * s.POINT,s.DIGITS);
                    }
                    // TODO check if that sl/tp formula is correct
                    if( a_sl_points != 0 ) sl=NormalizeDouble(price+a_sl_points*s.POINT+s.m_order_spread,s.DIGITS);
                    if( a_tp_points != 0 ) tp=NormalizeDouble(price-a_tp_points*s.POINT-s.m_order_spread,s.DIGITS);
                    
                } else {
                    dbg(s, "ERROR m_ModifyPendingOrders wrong order type " + EnumToString((ENUM_ORDER_TYPE)s.m_order_type) );
                }
                //
            } // if( -1 == a_price_points )
                        
                        
            MqlTradeRequest m_trade_request;            // parameters trading query
            MqlTradeResult m_trade_result;              // trade result of the trade query
            MqlTradeCheckResult m_trade_check_result;   // trade check result of the trade query
            ZeroMemory(m_trade_request);
            ZeroMemory(m_trade_result);
            ZeroMemory(m_trade_check_result);
            m_trade_request.price = price;
            m_trade_request.sl=sl;
            m_trade_request.tp=tp;
            m_trade_request.action     = TRADE_ACTION_MODIFY;
            m_trade_request.order      = s.m_order_ticket;
            m_trade_request.type       = (ENUM_ORDER_TYPE)s.m_order_type;
            m_trade_request.type_time  = ORDER_TIME_SPECIFIED/*ORDER_TIME_GTC*/;
            m_trade_request.type_filling = /*ORDER_FILLING_RETURN*/ORDER_FILLING_IOC;
            datetime tc = g_time_current;
            m_trade_request.expiration   = tc + (datetime)g_pending_order_expiry_time_s;
            //dbg(s, "Expiration: " + TimeToString(m_trade_request.expiration, TIME_DATE|TIME_SECONDS) );
            
            if( OrderCheck(m_trade_request,m_trade_check_result) == false ){
                if( TRADE_RETCODE_NO_CHANGES != m_trade_check_result.retcode ) {  // retcode != 10025
                    string log = StringFormat("ERROR[%d] [%s] OrderCheck m_ModifyPendingOrder(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d] EXPIRATION[%s]",
                        m_trade_check_result.retcode,m_trade_check_result.comment,IntegerToString(a_magic), s.SYMBOL, 
                        0, s.m_order_ticket, EnumToString((ENUM_ORDER_TYPE)s.m_order_type),
                        price,s.ASK,s.BID,sl,tp,a_magic,TimeToString(m_trade_request.expiration,TIME_DATE|TIME_SECONDS));    
                    Log2Sql( s, "ORDER", m_trade_check_result.retcode, log );
                    
                } else {
                    // log the MOD after pending order has no changes in price, but still we need this info
                    // even if no trade request has been made; change order comment to "LOGMOD"
                    // TODO as the trade server hasn't been updated yet, some of the states of the OderGetValue
                    // variables may be uncertain. Best to replace them with local values like m_order_type
                    // instead of OrderGetInteger(ORDER_TYPE)
                    m_log_history_to_sql(   s, "ABC_M", g_time_local,
                                            OrderGetInteger(ORDER_TIME_DONE_MSC),OrderGetInteger(ORDER_TIME_DONE),
                                            s.m_order_ticket,0,EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)),EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)),
                                            OrderGetDouble(ORDER_VOLUME_INITIAL),price,OrderGetDouble(ORDER_SL),OrderGetDouble(ORDER_TP),0.0,0.0,
                                            OrderGetString(ORDER_COMMENT) + " LOGMOD",
                                            ""
                                        );
                }
            } else{
                bool br = OrderSend(m_trade_request,m_trade_result);
                // TRADE_RETCODE_DONE == 10009  TRADE_RETCODE_PLACED == 10008
                if( (true == br) && ( (TRADE_RETCODE_DONE == m_trade_result.retcode) || ( TRADE_RETCODE_PLACED == m_trade_result.retcode) ) ){
                    if( VERBOSE) dbg(s, "Modify Pending Order "+EnumToString((ENUM_ORDER_TYPE)s.m_order_type)+" #"+IntegerToString(m_trade_result.order));
                    // log the MOD after pending order has been successfully modified
                    // TODO as the trade server hasn't been updated yet, some of the states of the OderGetValue
                    // variables may be uncertain. Best to replace them with local values like m_order_type
                    // instead of OrderGetInteger(ORDER_TYPE)
                    m_log_history_to_sql(   s, "ABC_M", g_time_local,
                                            OrderGetInteger(ORDER_TIME_DONE_MSC),OrderGetInteger(ORDER_TIME_DONE),
                                            s.m_order_ticket,0,EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)),EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)),
                                            OrderGetDouble(ORDER_VOLUME_INITIAL),price,OrderGetDouble(ORDER_SL),OrderGetDouble(ORDER_TP),0.0,0.0,
                                            OrderGetString(ORDER_COMMENT),
                                            ""
                                        );
                    dbg(s, "ModifyPendingOrder M:" + IntegerToString(a_magic) + " PRICE: " + nds(s,price) + " PIVOTP: " + nds(s,a_price) + " PP: " + IntegerToString(a_price_points) + " ASK/BID " + nds(s, s.ASK) + "/" + nds(s, s.BID)  + " T:" + EnumToString((ENUM_ORDER_TYPE) s.m_order_type));
                }else{
                    string log = StringFormat("ERROR[%d] [%s] OrderCheck m_ModifyPendingOrder(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d] EXPIRATION[%s]",
                        m_trade_result.retcode,m_trade_result.comment,IntegerToString(a_magic), s.SYMBOL, 
                        0, s.m_order_ticket, EnumToString((ENUM_ORDER_TYPE)s.m_order_type),
                        price,s.ASK,s.BID,sl,tp,a_magic,TimeToString(m_trade_request.expiration,TIME_DATE|TIME_SECONDS));    
                    Log2Sql( s, "ORDER", m_trade_result.retcode, log );
                }
            } // if( OrderCheck(m_trade_request,m_trade_check_result) == false )                

        }// if(OrderSelect(m_order_ticket))

     }// for(int pos=0; pos<OrdersTotal(); pos++)
} // void m_ModifyPendingOrder(int a_price_points, int a_sl_points, int a_tp_points, int a_magic )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   Remove pending orders                                          |
//+------------------------------------------------------------------+
void m_RemovePendingOrders( CSymbol& s, string a_log, ENUM_ORDER_TYPE a_order_type = -1, int a_magic = -1 ) 
{
//+------------------------------------------------------------------+

    int round_cnt = 1;

    //--- do until all pending orders are deleted
    while( OrdersTotal() && ( 10 > round_cnt ) ) {
    
        if( VERBOSE ) dbg(s, "ROUND # "+IntegerToString(round_cnt)+" of m_RemovePendingOrders" );
        round_cnt++;
        for(int pos=0; pos<OrdersTotal(); pos++) {
        
            s.m_order_ticket=OrderGetTicket(pos);
    
            if(OrderSelect(s.m_order_ticket))
            {
                if( s.SYMBOL != OrderGetString(ORDER_SYMBOL) )
                {
                    continue;
                }
                if( -1 != a_magic )
                {
                    if( a_magic != OrderGetInteger(ORDER_MAGIC) )
                    {
                        continue;
                    }
                }
                s.m_order_type=OrderGetInteger(ORDER_TYPE);
                if( -1 != a_order_type )
                {
                    if( a_order_type != s.m_order_type ) 
                    {
                        continue;
                    }
                }
                
                //dbg(s, "REMOVE " + s.SYMBOL + " SELECT # " + IntegerToString((int)s.m_order_ticket) );
                s.m_order_open_price=OrderGetDouble(ORDER_PRICE_OPEN);
                //datetime time_setup;      // time pending order was setup
                //time_setup =(datetime)OrderGetInteger(ORDER_TIME_SETUP);
                
                // remove the pending order
                MqlTradeRequest m_trade_request;            // parameters trading query
                MqlTradeResult m_trade_result;              // trade result of the trade query
                MqlTradeCheckResult m_trade_check_result;   // trade check result of the trade query
                ZeroMemory(m_trade_request);
                ZeroMemory(m_trade_result);
                ZeroMemory(m_trade_check_result);
                m_trade_request.action     = TRADE_ACTION_REMOVE;
                m_trade_request.order      = s.m_order_ticket;
                m_trade_request.type_time  = ORDER_TIME_GTC;
                m_trade_request.expiration = 0;


                if( OrderCheck(m_trade_request,m_trade_check_result) == false ){
                    if( TRADE_RETCODE_NO_CHANGES != m_trade_check_result.retcode ) {  // retcode != 10025
                        string log = StringFormat("ERROR[%d] [%s] OrderCheck m_RemovePendingOrders(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d]",
                            m_trade_check_result.retcode,m_trade_check_result.comment,IntegerToString(a_magic), s.SYMBOL, 
                            0, s.m_order_ticket, EnumToString((ENUM_ORDER_TYPE)s.m_order_type),
                            0,s.ASK,s.BID,0,0,a_magic);    
                        Log2Sql( s, "ORDER", m_trade_check_result.retcode, log );
                    
                    }
                } else{
                    bool br = OrderSend(m_trade_request,m_trade_result);
                    // TRADE_RETCODE_DONE == 10009  TRADE_RETCODE_PLACED == 10008
                    if( (true == br) && ( (TRADE_RETCODE_DONE == m_trade_result.retcode) || ( TRADE_RETCODE_PLACED == m_trade_result.retcode) ) ){
                        if( VERBOSE) dbg(s, "Remove Pending Order "+EnumToString((ENUM_ORDER_TYPE)s.m_order_type)+" #"+IntegerToString(m_trade_result.order));
                        if( VERBOSE) dbg(s, "REMOVE DONE # " + IntegerToString(s.m_order_ticket) );
                        m_log_history_to_sql(   s, "ABC_O", g_time_local,
                                    OrderGetInteger(ORDER_TIME_SETUP_MSC),OrderGetInteger(ORDER_TIME_SETUP),
                                    s.m_order_ticket,0,EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)),"ORDER_STATE_CANCELED",
                                    OrderGetDouble(ORDER_VOLUME_INITIAL),OrderGetDouble(ORDER_PRICE_OPEN),OrderGetDouble(ORDER_SL),OrderGetDouble(ORDER_TP),0.0,0.0,
                                    OrderGetString(ORDER_COMMENT) + " " + a_log,
                                    ""
                                );
                       
                    }else{
                        string log = StringFormat("ERROR[%d] [%s] OrderSend m_RemovePendingOrders(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d]",
                            m_trade_result.retcode,m_trade_result.comment,IntegerToString(a_magic), s.SYMBOL, 
                            0, s.m_order_ticket, EnumToString((ENUM_ORDER_TYPE)s.m_order_type),
                            0,s.ASK,s.BID,0,0,a_magic);    
                        Log2Sql( s, "ORDER", m_trade_result.retcode, log );
                    }
                } // if( OrderCheck(m_trade_request,m_trade_check_result) == false )         
    
            }// if(OrderSelect(m_order_ticket))
        }// for(int pos=0; pos<OrdersTotal(); pos++)
        Sleep( 1000 );
    } // while( OrdersTotal() ) {
     
} // void m_RemovePendingOrders( ENUM_ORDER_TYPE a_order_type = -1, int a_magic = -1 ) 

//+------------------------------------------------------------------+
//|  g_CalcPrice
//+------------------------------------------------------------------+
double g_CalcPricePendOrder(CSymbol& s, double a_price, ENUM_ORDER_TYPE a_order_type, int a_price_points ) 
{
    double price = 0;
    if( a_order_type == ORDER_TYPE_BUY_STOP ) {
        price=NormalizeDouble(a_price + a_price_points*s.POINT, s.DIGITS);
        // if last digit is 0x01, then change the price
        // in case if( askprice > price )
        // otherwise the order won't be created
        // TODO do not misuse MARKET_VOLATILITY_FACTOR var for this. be carefule and use own one
        if( 0x01 == ( 0x01 & (char)MARKET_VOLATILITY_FACTOR ) )
        {
            double askprice=NormalizeDouble(s.ASK /*+ STEP_PEND_POINT*s.POINT*/, s.DIGITS);
            if( askprice > price )
            {
                price=NormalizeDouble(s.ASK + a_price_points*s.POINT, s.DIGITS);
            }
        }
        if( 0x02 == ( 0x02 & (char)MARKET_VOLATILITY_FACTOR ) )
        {
            double askprice=NormalizeDouble(s.ASK /*+ STEP_PEND_POINT*s.POINT*/, s.DIGITS);
            if( askprice > price )
            {
                price=NormalizeDouble(s.ASK + STEP_PEND_POINT*s.POINT, s.DIGITS);
            }
        }
    // sell stop
    } else if ( a_order_type == ORDER_TYPE_SELL_STOP ) {
        price= NormalizeDouble(a_price - a_price_points * s.POINT,s.DIGITS);
        // if last digit is 0x01, then change the price
        // in case if( bidprice < price )
        // otherwise the order won't be created
        // TODO do not misuse MARKET_VOLATILITY_FACTOR var for this. be careful and use own one
        if( 0x01 == ( 0x01 & (char)MARKET_VOLATILITY_FACTOR ) )
        {
            double bidprice=NormalizeDouble(s.BID /*- STEP_PEND_POINT*s.POINT*/, s.DIGITS);
            if( bidprice < price )
            {
                price= NormalizeDouble(s.BID - a_price_points * s.POINT,s.DIGITS);
            }
        }
        if( 0x02 == ( 0x02 & (char)MARKET_VOLATILITY_FACTOR ) )
        {
            double bidprice=NormalizeDouble(s.BID /*- STEP_PEND_POINT*s.POINT*/, s.DIGITS);
            if( bidprice < price )
            {
                price= NormalizeDouble(s.BID - STEP_PEND_POINT * s.POINT,s.DIGITS);
            }
        }
    } 
    return price;
} // double g_CalcPricePendOrder(CSymbol& s, double a_price, ENUM_ORDER_TYPE a_order_type, int a_price_points ) 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   Open the pending order                                         |
//+------------------------------------------------------------------+
int g_OpenOrder(CSymbol& s, double a_price, ENUM_ORDER_TYPE a_order_type, int a_price_points, int a_sl_points, int a_tp_points, double a_lot, int a_magic ) 
{
    double lot_max  = SymbolInfoDouble(s.SYMBOL, SYMBOL_VOLUME_MAX);
    int ret = -42;
    do
    {
        if( (a_lot - lot_max ) > 0 )
        {
            ret = g_OpenOrder_sub(s, a_price, a_order_type, a_price_points, a_sl_points, a_tp_points, lot_max, a_magic);    
            a_lot = a_lot-lot_max; 
            // TODO review - HACK in testermode it takes too long to process if the loop is on, hence only do one recursion.
            if( true == TESTERMODE ) a_lot = 0;          
        }
        else
        {
            // last recursion
            ret = g_OpenOrder_sub(s, a_price, a_order_type, a_price_points, a_sl_points, a_tp_points, a_lot, a_magic);    
            a_lot = 0;
        }
    }    
    while( a_lot > 0 );
    
    return( ret );
} // int g_OpenOrder(double a_price, ENUM_ORDER_TYPE a_order_type, int a_price_points, int a_sl_points, int a_tp_points, double a_lot, int a_magic ) 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   Open the pending order                                         |
//+------------------------------------------------------------------+
int g_OpenOrder_sub(CSymbol& s, double a_price, ENUM_ORDER_TYPE a_order_type, int a_price_points, int a_sl_points, int a_tp_points, double a_lot, int a_magic ) 
{

    string s_order_type = EnumToString(a_order_type);
    double price = 0;
    double sl = 0;
    double tp = 0;

    if( a_price_points < s.m_order_stop_level ){ 
        a_price_points = s.m_order_stop_level; 
    }
    if( a_sl_points != 0 ){  
        if( a_sl_points < s.m_order_stop_level ) {
            a_sl_points = s.m_order_stop_level;
        }
    }
    if( a_tp_points != 0 ){  
        if( a_tp_points < s.m_order_stop_level ) {
            a_tp_points = s.m_order_stop_level;
        }
    }

    if( 0.0 != a_price ) 
    {
        //--- Adjust the price of orders
        // buy stop
        if( a_order_type == ORDER_TYPE_BUY_STOP ) {
            price = g_CalcPricePendOrder(s, a_price, a_order_type, a_price_points );
            if( a_sl_points != 0 ) sl=NormalizeDouble(price-a_sl_points*s.POINT,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price+a_tp_points*s.POINT,s.DIGITS);
    
        // sell stop
        } else if ( a_order_type == ORDER_TYPE_SELL_STOP ) {
            price = g_CalcPricePendOrder(s, a_price, a_order_type, a_price_points );
            if( a_sl_points != 0 ) sl=NormalizeDouble(price+a_sl_points*s.POINT,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price-a_tp_points*s.POINT,s.DIGITS);
            
        // buy limit
        } else if( a_order_type == ORDER_TYPE_BUY_LIMIT ) {
            price= NormalizeDouble(a_price - a_price_points * s.POINT,s.DIGITS);
            // TODO check if that sl/tp formula is correct
            if( a_sl_points != 0 ) sl=NormalizeDouble(price-a_sl_points*s.POINT,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price+a_tp_points*s.POINT,s.DIGITS);
        
        // sell limit
        } else if ( a_order_type == ORDER_TYPE_SELL_LIMIT ) {
            price=NormalizeDouble(a_price + a_price_points * s.POINT,s.DIGITS);
            // TODO check if that sl/tp formula is correct
            if( a_sl_points != 0 ) sl=NormalizeDouble(price+a_sl_points*s.POINT,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price-a_tp_points*s.POINT,s.DIGITS);
            
        } else {
            dbg(s, "ERROR g_OpenOrder wrong order type " + s_order_type );
        }
    } 
    else
    {
        //--- Adjust the price of orders
        // buy stop
        if( a_order_type == ORDER_TYPE_BUY_STOP ) {
            price=NormalizeDouble(s.ASK + a_price_points*s.POINT, s.DIGITS);
            if( a_sl_points != 0 ) sl=NormalizeDouble(price-a_sl_points*s.POINT-s.m_order_spread,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price+a_tp_points*s.POINT+s.m_order_spread,s.DIGITS);
    
        // sell stop
        } else if ( a_order_type == ORDER_TYPE_SELL_STOP ) {
            price= NormalizeDouble(s.BID - a_price_points * s.POINT,s.DIGITS);
            if( a_sl_points != 0 ) sl=NormalizeDouble(price+a_sl_points*s.POINT+s.m_order_spread,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price-a_tp_points*s.POINT-s.m_order_spread,s.DIGITS);
            
        // buy limit
        } else if( a_order_type == ORDER_TYPE_BUY_LIMIT ) {
            price= NormalizeDouble(s.ASK - a_price_points * s.POINT,s.DIGITS);
            // TODO check if that sl/tp formula is correct
            if( a_sl_points != 0 ) sl=NormalizeDouble(price-a_sl_points*s.POINT-s.m_order_spread,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price+a_tp_points*s.POINT+s.m_order_spread,s.DIGITS);
        
        // sell limit
        } else if ( a_order_type == ORDER_TYPE_SELL_LIMIT ) {
            price=NormalizeDouble(s.BID + a_price_points * s.POINT,s.DIGITS);
            // TODO check if that sl/tp formula is correct
            if( a_sl_points != 0 ) sl=NormalizeDouble(price+a_sl_points*s.POINT+s.m_order_spread,s.DIGITS);
            if( a_tp_points != 0 ) tp=NormalizeDouble(price-a_tp_points*s.POINT-s.m_order_spread,s.DIGITS);
            
        } else {
            dbg(s, "ERROR g_OpenOrder wrong order type " + s_order_type );
        }
    } // if( 0.0 == a_price ) 

          
    MqlTradeRequest m_trade_request;            // parameters trading query
    MqlTradeResult m_trade_result;              // trade result of the trade query
    MqlTradeCheckResult m_trade_check_result;   // trade check result of the trade query
    ZeroMemory(m_trade_request);
    ZeroMemory(m_trade_result);
    ZeroMemory(m_trade_check_result);
    m_trade_request.price=price;
    m_trade_request.sl=sl;
    m_trade_request.tp=tp;
    m_trade_request.action       = TRADE_ACTION_PENDING;
    m_trade_request.symbol       = s.SYMBOL;
    m_trade_request.volume       = a_lot;
    //m_trade_request.deviation    = g_order_slippage;
    m_trade_request.type         = a_order_type;
    m_trade_request.type_filling = ORDER_FILLING_RETURN;
    m_trade_request.type_time    = ORDER_TIME_SPECIFIED/*ORDER_TIME_GTC*/;
    m_trade_request.comment      = IntegerToString(a_magic);
    m_trade_request.magic        = a_magic;
    datetime tc = g_time_current;
    m_trade_request.expiration   = tc + (datetime)g_pending_order_expiry_time_s;
    //dbg(s, "Expiration: " + TimeToString(m_trade_request.expiration, TIME_DATE|TIME_SECONDS) );

    int ret = 0;
    if( false == OrderCheck(m_trade_request,m_trade_check_result) ) {
        string log = StringFormat("ERROR[%d] [%s] OrderCheck g_OpenOrder(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d] EXPIRATION[%s]",
            m_trade_check_result.retcode,m_trade_check_result.comment,IntegerToString(a_magic), s.SYMBOL, 
            a_lot, s.m_position_id, EnumToString((ENUM_ORDER_TYPE)a_order_type),
            price,s.ASK,s.BID,sl,tp,a_magic,TimeToString(m_trade_request.expiration, TIME_DATE|TIME_SECONDS));    
        Log2Sql( s, "ORDER", m_trade_check_result.retcode, log );
        ret =-1;
    } else {
        bool br = OrderSend(m_trade_request,m_trade_result);
        // TRADE_RETCODE_DONE == 10009  TRADE_RETCODE_PLACED == 10008
        if( (true == br) && ( (TRADE_RETCODE_DONE == m_trade_result.retcode) || ( TRADE_RETCODE_PLACED == m_trade_result.retcode) ) ){

            // TODO the original implementation lies within m_LogOrdersByIndex which is not used anymore
            // checkout if HISTORYPROCESSOR can replace this call. If so, then remove this log statement.
            m_log_history_to_sql(   s, "ABC_O", g_time_local,
                                    //OrderGetInteger(ORDER_TIME_SETUP_MSC),OrderGetInteger(ORDER_TIME_SETUP),
                                    // TODO maybe find a better time
                                    g_time_current*1000,g_time_current,
                                    m_trade_result.order,0,EnumToString((ENUM_ORDER_TYPE)a_order_type),"ORDER_STATE_PLACED",
                                    a_lot,price,sl,tp,0.0,0.0,
                                    IntegerToString(a_magic),
                                    ""
                                );
            
            dbg(s, "OpenOrder M:" + IntegerToString(a_magic) + " PRICE: " + nds(s,price) + " PIVOTP: " + nds(s,a_price) + " PP: " + IntegerToString(a_price_points) + " ASK/BID " + nds(s, s.ASK) + "/" + nds(s, s.BID)  + " T:" + EnumToString((ENUM_ORDER_TYPE) a_order_type));
        } else {
            string log = StringFormat("ERROR[%d] [%s] OrderSend g_OpenOrder(%s) %s VOL[%1.2f] ORDER[%d] TYPE[%s] PRICE[%1.5f] ASK[%1.5f] BID[%1.5f] SL[%1.5f] TP[%1.5f] MAGIC[%d] EXPIRATION[%s]",
                m_trade_result.retcode,m_trade_result.comment,IntegerToString(a_magic), s.SYMBOL, 
                a_lot, s.m_position_id, EnumToString((ENUM_ORDER_TYPE)a_order_type),
                price,s.ASK,s.BID,sl,tp,a_magic,TimeToString(m_trade_request.expiration, TIME_DATE|TIME_SECONDS));    
            Log2Sql( s, "ORDER", m_trade_result.retcode, log );
            ret =-2;
        }
    } // if( false == OrderCheck(m_trade_request,m_trade_check_result) ) 
    return (ret);
} // int g_OpenOrder_sub(double a_price, ENUM_ORDER_TYPE a_order_type, int a_price_points, int a_sl_points, int a_tp_points, double a_lot, int a_magic ) 
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+  
//|   Calculation of the free margin                                 |
//|   Applies only for standard Forex symbol                         |
//+------------------------------------------------------------------+  
bool  m_OrderCalcMargin(string    symbol,      // Symbol name
                        double    volume,      // Lots
                        double    price,       // Open price
                        double&   margin)      // output value
{
    string first    = StringSubstr(symbol,0,3);
    string second   = StringSubstr(symbol,3,3);
    margin = 0.0;
    
    string currency = AccountInfoString (ACCOUNT_CURRENCY); // MT5
    long  leverage  = AccountInfoInteger(ACCOUNT_LEVERAGE); // MT5
    double contract = SymbolInfoDouble  (symbol,SYMBOL_TRADE_CONTRACT_SIZE); // MT5
    //string currency = AccountCurrency(); // MT4
    //int leverage = AccountLeverage(); // MT4
    //double contract = MarketInfo(symbol, MODE_LOTSIZE); // MT4
    
    //---   
    if(StringLen(symbol) != 6) {
        if(StringLen(symbol) == 8) {
            if( '.' != StringGetCharacter(symbol,6) ) {
                dbg("OrderCalcMargin: "+symbol+" - must be a standard forex symbol by type: XXXYYY.Z");
                return(false);
            }
        } else {
            dbg("OrderCalcMargin: "+symbol+" - must be a standard forex symbol by type: XXXYYY");
            return(false);
        }
    }
    //--- 
    if( price <= 0.0 || contract <= 0) {
        dbg("OrderCalcMargin: No market information for "+symbol);
        return(false);
    }
    //---
    if(first == currency) {  
        margin=contract * volume / leverage; // USDxxx
        return(true);
    }
    //---   
    if((second == currency)) {
        margin=contract * price * volume / leverage; // xxxUSD
        return(true);
    }
    //---
    dbg("OrderCalcMargin: impossible to calculate for "+symbol);
    return(false);
} // bool  m_OrderCalcMargin
//+------------------------------------------------------------------+



  
//+------------------------------------------------------------------+
//|   Calculation of the lot value                                   |
//+------------------------------------------------------------------+
bool m_Calculate_Lot(CSymbol& s, double& a_lot_value, int& a_max_pend_number) {
//+------------------------------------------------------------------+

    /*input*/ bool          ORDER_LOT_TYPE_FIXED        =   false;// ORDER_LOT_TYPE_FIXED type
    /*input*/ bool          ORDER_LOT_CORRECTION        =   true; // ORDER_LOT_CORRECTION of ORDER_LOT size

    double acc_free_margin=AccountInfoDouble(ACCOUNT_FREEMARGIN);
    double calc_margin;
    double price=s.BID;
    
    if(ORDER_LOT_TYPE_FIXED)
    {
        //--- Correction of lot size
        if(ORDER_LOT_CORRECTION)
        {
            if( true == OrderCalcMargin(ORDER_TYPE_BUY,s.SYMBOL,ORDER_LOT,price,calc_margin) ) {
            // TODO AHE implement OrderCalcMargin for currencies other than account currency
            //  e.g. ACOUNT CURRENCY: USD SYMBOL: EURGBP
            //if( true == m_OrderCalcMargin(SYMBOL,ORDER_LOT,price,calc_margin) ) {
                //--- Lot size correction of up to 90% of free margin
                if( 0 < calc_margin && acc_free_margin<calc_margin) {
                    a_lot_value=ORDER_LOT*acc_free_margin*0.9/calc_margin;
                    dbg(s, "Adjusted value of the lot value: "+nds(a_lot_value,2));
                }
            }
        } // if(ORDER_LOT_CORRECTION)
    }
    else
    {
        //--- value of free margin for open position
        if( true == OrderCalcMargin(ORDER_TYPE_BUY,s.SYMBOL,1,price,calc_margin) ) {
        // TODO AHE implement OrderCalcMargin for currencies other than account currency
        //  e.g. ACOUNT CURRENCY: USD SYMBOL: EURGBP
        //if( true == m_OrderCalcMargin(SYMBOL,1,price,calc_margin) ) {
            //Print("1: ", a_lot_value, " - ", calc_margin);
            if( 0 < calc_margin ) {
                a_lot_value=acc_free_margin*0.01*ORDER_LOT/calc_margin;
                //Print("2: ", a_lot_value, " - ", calc_margin);
            }
        }
    } // if(ORDER_LOT_TYPE_FIXED)
    if( 0 < a_lot_value ) 
    {
        // real accounts sometime have a too high leverage of up to 500
        /*if( (100 < AccountInfoInteger(ACCOUNT_LEVERAGE)) && (false == TESTERMODE) )
        {
            a_lot_value = a_lot_value / (AccountInfoInteger(ACCOUNT_LEVERAGE)/100);
        }*/
        if( 0 < a_max_pend_number )
        {
            a_lot_value = a_lot_value / a_max_pend_number;
        }
        a_lot_value = m_NormalizeLot(s, a_lot_value);
        if( (0.0 == a_lot_value) && (1<a_max_pend_number) )
        {
            a_max_pend_number = a_max_pend_number/2;
            m_Calculate_Lot(s,a_lot_value,a_max_pend_number);
        }
    }
    if( 0 < a_lot_value ) 
    {
        return (true);
    }
    else
    {
        return (false);
    }
} // bool m_Calculate_Lot(CSymbol& s, double& a_lot_value, int& a_max_pend_number) {
//+------------------------------------------------------------------+
  
//+------------------------------------------------------------------+
//|   Normalization of the lot size                                  |
//+------------------------------------------------------------------+
double m_NormalizeLot(CSymbol& s, double lot_value)
{
    double lot_min  = SymbolInfoDouble(s.SYMBOL, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(s.SYMBOL, SYMBOL_VOLUME_STEP);
    int norm;
    
    /*if(lot_value <= lot_min ) lot_value = lot_min;               // checking for minimum lot size
    else if(lot_value >= lot_max ) lot_value = lot_max;          // checking the maximum lot size 
    else(lot_value = MathFloor(lot_value/ lot_step) * lot_step); // rounding to the nearest*/
    if( 0.0 != lot_step ) 
    {
        lot_value = MathFloor(lot_value / lot_step) * lot_step;
    }
    
    // TODO tidy this one up - not used anymore 
    //norm=(int)NormalizeDouble(MathCeil(MathLog10(1/lot_step)),0);// coefficient for NormalizeDouble
    ///
    if( 0.1 > lot_value )
        norm = 2;
    else if( 10 > lot_value ) 
        norm = 1;
    else
        norm = 0;
    ///
    lot_value = (NormalizeDouble(lot_value,norm));                     // normalization
    // TODO this is only needed for the championschip
    //   because there the maximum lot size over all 
    // orders and positions is limited to 15.
    /*double vo = m_GetVolumeOfOrders();
    double vp = m_GetVolumeOfPositions();
    if( (lot_value + vo +vp ) > 15.0 )
    {
        lot_value = lot_value - vo - vp;
    } */
    if( lot_value < lot_min )
    {
        lot_value = 0;
    }
    return lot_value;   
} // double m_NormalizeLot(double lot_value)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Close specified opened position                                  |
//+------------------------------------------------------------------+
bool m_PositionClose(CSymbol& s, int a_magic, string a_comment, bool a_force = false )
{

    // TODO - document this properly
    // if this is zero, then do not close open positions
    // and just keep them open forever
    if( (0 == OPEN_POSITION_CLOSE_TIME_MIN) && (false==a_force) )
    {
        return false;
    }

    // only the master is currently allowed to close a position
    // TODO implement else case - set STOP_LOSS in else case to close the position
    if( false == g_is_master )
    {
        dbg(s, g_computername + " currently not allowed to close a position" );
        return false;
    }

    double vol = 0;
    bool   partial_close=false;
    int    retry_count  =10;
    //uint   retcode      =TRADE_RETCODE_REJECT;
    //--- m_trade_check_result stopped
    if(IsStopped()) 
    {
        return(false);
    }
    do
    {
        double price = 0;
        ENUM_ORDER_TYPE type;
        //--- m_trade_check_result
        if(PositionSelect(s.SYMBOL))
        {
            if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
            {
                //--- prepare m_trade_request for close BUY position
                type =ORDER_TYPE_SELL;
                price=SymbolInfoDouble(s.SYMBOL,SYMBOL_BID);
            }
            else
            {
                //--- prepare m_trade_request for close SELL position
                type =ORDER_TYPE_BUY;
                price=SymbolInfoDouble(s.SYMBOL,SYMBOL_ASK);
            }
        }
        else
        {
            //--- position not found
            return(false);
        } // if(PositionSelect(symbol))
        
        //--- setting m_trade_request
        MqlTradeRequest m_trade_request;            // parameters trading query
        MqlTradeResult m_trade_result;              // trade result of the trade query
        MqlTradeCheckResult m_trade_check_result;   // trade check result of the trade query
        ZeroMemory(m_trade_request);
        ZeroMemory(m_trade_result);
        ZeroMemory(m_trade_check_result);
        ZeroMemory(g_trade_result);
        m_trade_request.type =type;
        m_trade_request.price=price;
        m_trade_request.action      =TRADE_ACTION_DEAL;
        m_trade_request.symbol      =s.SYMBOL;
        m_trade_request.magic       =a_magic;
        //m_trade_request.deviation   =g_order_slippage;
        m_trade_request.comment = a_comment;
        m_trade_request.type_filling=/*ORDER_FILLING_RETURN*/ORDER_FILLING_IOC;
        m_trade_request.volume      =PositionGetDouble(POSITION_VOLUME);
        //--- m_trade_check_result volume
        double max_volume=SymbolInfoDouble(s.SYMBOL,SYMBOL_VOLUME_MAX);
        if(m_trade_request.volume>max_volume)
        {
            m_trade_request.volume=max_volume;
            partial_close=true;
        }
        else 
        {
            partial_close=false;
        }
        
        bool ret = false;
        //--- order check
        if( false == OrderCheck(m_trade_request,m_trade_check_result) )
        {
            string log = StringFormat("ERROR[%d] [%s] OrderCheck m_PositionClose(%s) %s TYPE[%d] PRICE[%f] ASK[%f] BID[%f]",
                m_trade_check_result.retcode,m_trade_check_result.comment,a_comment, s.SYMBOL,EnumToString((ENUM_ORDER_TYPE)type),price,s.ASK,s.BID);    
            Log2Sql( s, "ORDER", m_trade_check_result.retcode, log );
                           
        }
        else
        {
            //--- order send
            ret = OrderSend(m_trade_request,m_trade_result);
            // TRADE_RETCODE_DONE == 10009  TRADE_RETCODE_PLACED == 10008
            if( (true == ret) && ((TRADE_RETCODE_DONE == m_trade_result.retcode) || ( TRADE_RETCODE_PLACED == m_trade_result.retcode)) )
            {
                // TODO XLS ALGO hack - use global variable here to not change the interface
                g_trade_result = m_trade_result;
                //dbg(s, "SUCCESS OrderSend g_PositionClose #",m_trade_result.order);
            } else {
                string log = StringFormat("ERROR[%d] [%s] OrderSend m_PositionClose(%s) %1.2f %s at %1.5f sl:%1.5f tp:%1.5f ask:%1.5f bid:%1.5f", 
                    m_trade_result.retcode,m_trade_result.comment, a_comment, m_trade_request.volume, s.SYMBOL, m_trade_request.price, m_trade_request.sl, m_trade_request.tp, s.ASK, s.BID );
                Log2Sql( s, "ORDER", m_trade_result.retcode, log );
            }
        }
        if( false == ret )
        {
            if(--retry_count!=0) 
            {
                continue;
            }
            return(false);
        }
        
        //--- WARNING. If position volume exceeds the maximum volume allowed for deal,
        //--- and when the asynchronous trade mode is on, for safety reasons, position is closed not completely,
        //--- but partially. It is decreased by the maximum volume allowed for deal.
        // TODO investigate async mode
        //if(m_async_mode) break;
        if( true == partial_close )
        {
            Sleep(1000);
        }
        
    } while(partial_close);
    //--- ok
    return(true);
} // bool m_PositionClose(const string symbol, int a_magic, string comment, double a_volume = 0.0 )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_GetVolumeOfOrders                                           
//+------------------------------------------------------------------+
double m_GetVolumeOfOrders() {
    double vol = 0;
    for(int pos=0; pos<OrdersTotal(); pos++){
        if(OrderSelect(OrderGetTicket(pos))){
            vol = vol + OrderGetDouble(ORDER_VOLUME_CURRENT);
        }
    }
    return vol;
} // double m_GetVolumeOfOrders()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_GetVolumeOfPositions                                             
//+------------------------------------------------------------------+
double m_GetVolumeOfPositions() {
    double vol = 0;
    for(int pos=0; pos<PositionsTotal(); pos++){
        if(PositionSelect(PositionGetSymbol(pos))){
            vol = vol + PositionGetDouble(POSITION_VOLUME);
        }
    }
    return vol;
} // double m_GetVolumeOfPositions()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_WorkWithPendingOrders                                           
//+------------------------------------------------------------------+
void m_WorkWithPendingOrders(CSymbol& s, ENUM_ORDER_TYPE a_ot, double a_price, double a_lot, int a_firststep, int a_tstep, int a_onumber )
{

    // set the generic SLTP in points
	int slp    =  0;//g_open_positions_close_level;
	int tpp    =  0; if( 4 == s.DIGITS ) { tpp = tpp / 10; }
    // set the price offset for pending order
	int pp     = 0;
    double lot_total = 0;
    
    // TODO review me - is this still needed
    //int pend_num = STEP_PEND_NUMBER;
    //bool bres = m_Calculate_Lot(s,a_lot,pend_num);
    //// sanity check
    //if( (false == bres) || (0.0 == a_lot) ) {
    //    a_lot = m_GetVolumeOfPendingOrder( s, a_ot );
    //}

	//--- Processing of pending orders
	// TODO in ECN network a SL can't be applied modified when an order is opened
	//  -> investigate: what is better 1) open the order then one timeframe later apply the SL or
	//       2) modify all existings SL, then open the orders, here the new orders don't have a SL applied to them
	for( int cnt = 0 ; cnt < a_onumber; cnt ++ ) 
	{
	
	    if( 0 == cnt ){
	        pp = a_firststep;
	    } else {
	        int diff = a_tstep;
	        if( 4 == s.DIGITS ) { diff = diff / 10; if( 1 > diff ){ diff = 1;} }
	        pp = pp + diff;
	    }
	
        double lot = a_lot;
        if( 1 == LOT_1_DEF_2_ASC_3_DESC ) {
            lot = a_lot;
        } else if( 2 == LOT_1_DEF_2_ASC_3_DESC ) {
            lot = a_lot*(cnt+1);
        } else if( 3 == LOT_1_DEF_2_ASC_3_DESC ) {
            lot = a_lot*(10-cnt);
        }
        // sanity check
        if( lot == 0 ) {
            if( VERBOSE) dbg(s, "ERROR Calculate_Lot LOT=(0) no money "+s.SYMBOL);
            return;
        }
        // normalise lot for the LOT BALANCE UPDATE algorithm
        lot = NormalizeDouble( lot, 2 );
        
        // TODO FIXME later
        // normally the line below should give the correct lot size depending on 
        // the number of pending orders, but it does not for (LOT_1_DEF_2_ASC_3_DESC)
        // ASC and DSC; only for DEF it works. 
        // double lot = m_Calculate_Lot(s,STEP_PEND_NUMBER);
        // As a worekaround at the moment restrict to the 
        // lot_total number here, once it is reached.
        lot_total += lot;
	
    	// MAGIC_A
    	if( ORDER_TYPE_BUY_STOP == a_ot ) 
    	{
    	    int magica = MAGIC_PEND_START_A + cnt;
    	    int magicb = MAGIC_PEND_START_B + cnt;
    	    // a) either create a new pending order if none exists, 
        	if( 0 == m_CntOrderPending(s, a_ot, magica) ) 
        	{
   	            //printf("g_OpenOrder %s %d %d %d %d %d",EnumToString((ENUM_ORDER_TYPE)ota),cnt,magica,pp,slp,tpp);               
                int ret = g_OpenOrder(s, a_price,a_ot,pp,slp,tpp,lot, magica);
                if( 0 == ret )
                {
                } // if( E_ALGOPARAM_NOLOTBALANCE != g_algoparam )
                
                // if there is an order to be opened then modify the opposite pending order
                // otherwise the SL will be too high, as the gap is too wide between
                // the opposite orders in the moder no pending orders modify
            } else {
                m_ModifyPendingOrder(s, a_price,pp,slp,tpp, magica);
            } // if( 0 == m_CntOrderPending(s, a_ot, magica) ) 
        } // if( ORDER_TYPE_BUY_STOP == a_ot ) 

    	// MAGIC_B
    	if( ORDER_TYPE_SELL_STOP == a_ot ) {
    	    int magicb = MAGIC_PEND_START_B + cnt;
    	    int magica = MAGIC_PEND_START_A + cnt;
    	    // a) either create a new pending order if none exists, 
        	if( 0 == m_CntOrderPending(s, a_ot, magicb) ) 
        	{
   	            //printf("g_OpenOrder %s %d %d %d %d %d",EnumToString((ENUM_ORDER_TYPE)ota),cnt,magica,pp,slp,tpp);               
                int ret = g_OpenOrder(s, a_price,a_ot,pp,slp,tpp,lot, magicb);
                if( 0 == ret )
                {
                } // if( E_ALGOPARAM_NOLOTBALANCE != g_algoparam )
            } else {
                // if there is an order to be opened then modify the opposite pending order
              	m_ModifyPendingOrder(s, a_price,pp,slp,tpp, magicb);
        	} // if( 0 == m_CntOrderPending(a_ot, magicb) ) 
        } // if( ORDER_TYPE_SELL_STOP == a_ot )


        // TODO refactor code here
    	if( ORDER_TYPE_BUY_LIMIT == a_ot ) 
    	{
    	    int magica = MAGIC_PEND_START_A + cnt;
    	    int magicb = MAGIC_PEND_START_B + cnt;
    	    // a) either create a new pending order if none exists, 
        	if( 0 == m_CntOrderPending(s, a_ot, magica) ) 
        	{
   	            //printf("g_OpenOrder %s %d %d %d %d %d",EnumToString((ENUM_ORDER_TYPE)ota),cnt,magica,pp,slp,tpp);               
                int ret = g_OpenOrder(s, a_price,a_ot,pp,slp,tpp,lot, magica);
                if( 0 == ret )
                {
                    // aim for LOT BALANCE  
                    // make sure that the opposite order of the opposite magic number has the same lot size
                    // as it happens once the balance is increasing the lot size is increasing as well
                    // then it might happen that there is still an old existing pending order with a lower
                    // lot size than the newly created pending order with higher lot size after balance increase
                    // eg. new BUY_STOP 100 0.02  and old SELL_STOP 200 0.01
                    //     remove SELL_STOP 200 0.01 and create SELL_STOP 200 0.02
                    /*double lot_of_opposite_order = m_GetVolumeOfPendingOrder( s, ORDER_TYPE_SELL_LIMIT, magicb );
                    lot_of_opposite_order = NormalizeDouble( lot_of_opposite_order, 2 );
                    if( (0 < lot_of_opposite_order) && (lot != lot_of_opposite_order) )
                    {
                        m_RemovePendingOrders( s, "LOT_BALANCE", ORDER_TYPE_SELL_LIMIT, magicb );
                        ret = g_OpenOrder(s, a_price,ORDER_TYPE_SELL_LIMIT,pp,slp,tpp,lot, magicb);
                        // TODO implement a wait after g_OpenOrder to check if order has really been opened 
                        //  important for LOT BALANCE UPDATE ERROR
                        double lot_after_change = lot; // m_GetVolumeOfPendingOrder( ORDER_TYPE_SELL_LIMIT, magicb );
                        lot_after_change = NormalizeDouble( lot_after_change, 2 );
                        if( (0 != ret) || ( lot != lot_after_change ) ) 
                        {
                            lot_after_change = 0; // remove me after working on the above TODO
                            string log = StringFormat( "LOT BALANCE UPDATE ERROR MAGICB(%d)LOT(%.2f/%.2f) != MAGICA(%d)LOT(%.2f)",  magicb, lot_of_opposite_order, lot_after_change, magica, lot);
                            Log2Sql( s, "ORDER", -31, log );
                        }
                        else
                        {
                            string log = StringFormat( "LOT BALANCE UPDATE SUCCESS MAGICB(%d)LOT(%.2f/%.2f) == MAGICA(%d)LOT(%.2f)",  magicb, lot_of_opposite_order, lot_after_change,  magica, lot);
                            Log2Sql( s, "ORDER", 0, log );
                        }
                    } // if( (0 < lot_of_opposite_order) && (lot != lot_of_opposite_order) )*/
                } // if( E_ALGOPARAM_NOLOTBALANCE != g_algoparam )
                
                // if there is an order to be opened then modify the opposite pending order
                // otherwise the SL will be too high, as the gap is too wide between
                // the opposite orders in the moder no pending orders modify
                //m_ModifyPendingOrder(s, a_price,pp,slp,tpp, magicb);
                
        	} // if( 0 == m_CntOrderPending(a_ot, magica) ) 
        } // if( ORDER_TYPE_BUY_LIMIT == a_ot ) 

    	if( ORDER_TYPE_SELL_LIMIT == a_ot ) {
    	    int magicb = MAGIC_PEND_START_B + cnt;
    	    int magica = MAGIC_PEND_START_A + cnt;
    	    // a) either create a new pending order if none exists, 
        	if( 0 == m_CntOrderPending(s, a_ot, magicb) ) 
        	{
   	            //printf("g_OpenOrder %s %d %d %d %d %d",EnumToString((ENUM_ORDER_TYPE)ota),cnt,magica,pp,slp,tpp);               
                int ret = g_OpenOrder(s, a_price,a_ot,pp,slp,tpp,lot, magicb);
                if( 0 == ret )
                {
                    // aim for LOT BALANCE  
                    // make sure that the opposite order of the opposite magic number has the same lot size
                    // as it happens once the balance is increasing the lot size is increasing as well
                    // then it might happen that there is still an old existing pending order with a lower
                    // lot size than the newly created pending order with higher lot size after balance increase
                    // eg. new BUY_STOP 100 0.02  and old SELL_STOP 200 0.01
                    //     remove SELL_STOP 200 0.01 and create SELL_STOP 200 0.02
                    /*double lot_of_opposite_order = m_GetVolumeOfPendingOrder( s, ORDER_TYPE_BUY_LIMIT, magica );
                    lot_of_opposite_order = NormalizeDouble( lot_of_opposite_order, 2 );
                    if( (0 < lot_of_opposite_order) && (lot != lot_of_opposite_order) )
                    {
                        m_RemovePendingOrders( s, "LOT_BALANCE", ORDER_TYPE_BUY_LIMIT, magica );
                        ret = g_OpenOrder(s, a_price,ORDER_TYPE_BUY_LIMIT,pp,slp,tpp,lot, magica );
                        // TODO implement a wait after g_OpenOrder to check if order has really been opened 
                        //  important for LOT BALANCE UPDATE ERROR
                        double lot_after_change = lot; // m_GetVolumeOfPendingOrder( ORDER_TYPE_BUY_LIMIT, magica );
                        lot_after_change = NormalizeDouble( lot_after_change, 2 );
                        if( (0 != ret) || ( lot != lot_after_change ) ) 
                        {
                            lot_after_change = 0; // remove me after working on the above TODO
                            string log = StringFormat( "LOT BALANCE UPDATE ERROR MAGICA(%d)LOT(%.2f/%.2f) != MAGICB(%d)LOT(%.2f)",  magica, lot_of_opposite_order, lot_after_change, magicb, lot);
                            Log2Sql( s, "ORDER", -31, log );
                        }
                        else
                        {
                            string log = StringFormat( "LOT BALANCE UPDATE SUCCESS MAGICA(%d)LOT(%.2f/%.2f) == MAGICB(%d)LOT(%.2f)",  magica, lot_of_opposite_order, lot_after_change,  magicb, lot);
                            Log2Sql( s, "ORDER", 0, log );
                        }
                    } // if( (0 < lot_of_opposite_order) && (lot != lot_of_opposite_order) )*/
                } // if( E_ALGOPARAM_NOLOTBALANCE != g_algoparam )
                
                // if there is an order to be opened then modify the opposite pending order
                // otherwise the SL will be too high, as the gap is too wide between
                // the opposite orders in the moder no pending orders modify
               	//m_ModifyPendingOrder(s, a_price,pp,slp,tpp, magica);
                    
        	} // if( 0 == m_CntOrderPending(a_ot, magicb) ) 
        	
        } // if( ORDER_TYPE_SELL_LIMIT == a_ot )


    } // for( int cnt = 0 ; cnt < MAGIC_PEND_NUMBER ; cnt ++ )
		
} // void m_WorkWithPendingOrders
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_PositionOpenBuy                                           
//+------------------------------------------------------------------+
bool m_PositionOpenBuy(CSymbol& s, double a_volume, string a_comment= "" )
{
    return(m_PositionOpen(s, POSITION_TYPE_BUY, a_volume, a_comment));
} // bool m_PositionOpenBuy(double a_volume)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_PositionOpenSell                                           
//+------------------------------------------------------------------+
bool m_PositionOpenSell(CSymbol& s, double a_volume, string a_comment = "" )
{
    return(m_PositionOpen(s, POSITION_TYPE_SELL, a_volume, a_comment));
} // bool m_PositionOpenSell(double a_volume)
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_PositionOpen                                           
//+------------------------------------------------------------------+
bool m_PositionOpen(CSymbol& s, ENUM_POSITION_TYPE a_type, double a_volume, string a_comment)
{
   MqlTradeRequest request;//={0};
   MqlTradeResult result={0};
   MqlTradeCheckResult check={0};
   
   for(int i=0;i<10;i++)
     {
      //dbg(s, "O: " + EnumToString( (ENUM_POSITION_TYPE) Type ));
      if(a_volume<=0) break;
         
      if(a_type==POSITION_TYPE_SELL)
        {
         request.type=ORDER_TYPE_SELL;
         request.price=SymbolInfoDouble(s.SYMBOL,SYMBOL_BID);
         if( "" != a_comment )
            request.comment=a_comment;
         else
            request.comment=IntegerToString(300);
        }
      if(a_type==POSITION_TYPE_BUY)
        {
         request.type=ORDER_TYPE_BUY;
         request.price=SymbolInfoDouble(s.SYMBOL,SYMBOL_ASK);
         if( "" != a_comment )
            request.comment=a_comment;
         else
            request.comment=IntegerToString(400);
        }
        
        
      request.action = TRADE_ACTION_DEAL;
      request.symbol = s.SYMBOL;
      request.volume = MathMin(a_volume,SymbolInfoDouble(s.SYMBOL,SYMBOL_VOLUME_MAX));
      request.sl = 0.0;
      request.tp = 0.0;
      request.type_filling=ORDER_FILLING_IOC;
      if(!OrderCheck(request,check))
        {
         if(check.margin_level<100) a_volume-=SymbolInfoDouble(s.SYMBOL,SYMBOL_VOLUME_STEP);
         dbg(s, "OrderCheck Code: "+IntegerToString(check.retcode)+ " " + check.comment);
         continue;
        }
      if(!OrderSend(request,result) || result.deal==0)
        {
         dbg(s, "OrderSend Code: "+IntegerToString(result.retcode));
         if(result.retcode==TRADE_RETCODE_TRADE_DISABLED) break;
         if(result.retcode==TRADE_RETCODE_MARKET_CLOSED) break;
         if(result.retcode==TRADE_RETCODE_NO_MONEY) break;
         if(result.retcode==TRADE_RETCODE_TOO_MANY_REQUESTS) Sleep(5000);
         if(result.retcode==TRADE_RETCODE_FROZEN) break;
         if(result.retcode==TRADE_RETCODE_CONNECTION) Sleep(15000);
         if(result.retcode==TRADE_RETCODE_LIMIT_VOLUME) break;
        }
      else a_volume-=result.volume;
      Sleep(1000);
     }
   if(!PositionSelect(s.SYMBOL)) return(false);
   return(true);
} // bool m_PositionOpen(ENUM_POSITION_TYPE a_type, double a_volume)
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_CheckTrailingStop
//+------------------------------------------------------------------+
void m_CheckTrailingStop(CSymbol& s)
{
    s.m_order_stop_level =(int)SymbolInfoInteger(s.SYMBOL,SYMBOL_TRADE_STOPS_LEVEL);
    // TODO SL review me - and correct with correct value
    if( k_order_stop_level_min > s.m_order_stop_level )
    {
        s.m_order_stop_level = k_order_stop_level_min;
    }
    if(s.g_open_positions_trailing_stop<s.m_order_stop_level) s.g_open_positions_trailing_stop=s.m_order_stop_level;
    if(s.g_open_positions_trailing_step<s.m_order_stop_level) s.g_open_positions_trailing_step=s.m_order_stop_level;
    if( s.g_open_positions_trailing_step >= s.g_open_positions_trailing_stop )
    {
        s.g_open_positions_trailing_stop = 2*s.g_open_positions_trailing_step;
    }
    if( (0==s.g_open_positions_trailing_step) || (0==s.g_open_positions_trailing_stop) )
    {
        s.g_open_positions_trailing_stop  = TRAILING_STOP;
        s.g_open_positions_trailing_step  = TRAILING_STEP;
    }
} // void m_CheckTrailingStop()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_WorkWithPositions
//+------------------------------------------------------------------+
bool m_WorkWithPositions( CSymbol& s, e_workwithpositions a_wwp_profits = E_WWP_TRAILING_STOP, e_workwithpositions a_wwp_losses = E_WWP_PREV_CLOSE ) 
{

    if( false == PositionSelect(s.SYMBOL)) {
        // there is no position open; just return
        
        // reset trailing parameters if there is no open position
        s.g_open_positions_trailing_stop  = TRAILING_STOP;
        s.g_open_positions_trailing_step  = TRAILING_STEP;
        m_CheckTrailingStop(s);
        s.g_sl = 0.0;
        
        return ( false );
    }
    
    s.m_order_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    s.m_order_current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    s.m_order_profit=PositionGetDouble(POSITION_PROFIT);
    s.m_order_type       = (int)PositionGetInteger(POSITION_TYPE);
    s.m_order_time = (datetime)PositionGetInteger(POSITION_TIME);
    s.m_order_volume = PositionGetDouble(POSITION_VOLUME);
    s.m_position_id = PositionGetInteger(POSITION_IDENTIFIER);
    double vol = PositionGetDouble(POSITION_VOLUME);
    double sl=PositionGetDouble(POSITION_SL);
    double tp=PositionGetDouble(POSITION_TP);
    
    double task = s.ASK;
    double tbid = s.BID;
    if( (E_ALGOPARAM_SLDF == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
    {
        task = s.g_avg_ticks_ask;
        tbid = s.g_avg_ticks_bid;
        if( (0.0 >= s.g_avg_ticks_ask) || (0.0 >= s.g_avg_ticks_bid) ) {
            task = s.ASK;
            tbid = s.BID;
        }
    }
    if( (E_ALGOPARAM_CL == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
    {
        sl = s.g_sl;
    }
    double order_sl=sl;
    double order_tp=tp;
    
    // EXPERTSL - remove opposite pending orders, if SL still is NULL
    // TODO make this removal optional
    /*if( 0 == sl )
    {
        // if there is an open position, then don't create a new pending order or modfiy it
        if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
        {
            if( E_ALGODIRECTION_STOP == g_algodirection )                
            {
                if( 0 < m_CntOrderPending(s, ORDER_TYPE_SELL_STOP) )
                {
                    m_RemovePendingOrders(s, "POSITION CANCEL PENDING", ORDER_TYPE_SELL_STOP);
                }
            }
            else
            {
                if( 0 < m_CntOrderPending(s, ORDER_TYPE_SELL_LIMIT) )
                {
                    m_RemovePendingOrders(s, "POSITION CANCEL PENDING", ORDER_TYPE_SELL_LIMIT);
                }
            }
        } // if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
        if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
        {
            if( E_ALGODIRECTION_STOP == g_algodirection )                
            {
                if( 0 < m_CntOrderPending(s, ORDER_TYPE_BUY_STOP) )
                {
                    m_RemovePendingOrders(s, "POSITION CANCEL PENDING", ORDER_TYPE_BUY_STOP);
                }
            }
            else
            {
                if( 0 < m_CntOrderPending(s, ORDER_TYPE_BUY_LIMIT) )
                {
                    m_RemovePendingOrders(s, "POSITION CANCEL PENDING", ORDER_TYPE_BUY_LIMIT);
                }
            }
        } // if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
    } // if( (E_ALGOPARAM_SL == g_algoparam) && ( 0 == sl ) )*/

    //
    // position is in loss
    //
    if( (0 > s.m_order_profit) && ( E_WWP_NO_SL != a_wwp_losses)  )
    {
    
        // check if an open position has expired
        if( ( 0 != OPEN_POSITION_CLOSE_TIME_MIN ) && ((s.m_order_time + OPEN_POSITION_CLOSE_TIME_MIN*60 ) < g_time_current) )
        //if( (s.m_order_time + PeriodSeconds(s.PERIOD)) < g_time_current  ) 
        {
            string log = StringFormat( "%s POS EXPIRED - ClosePosition(%s at %.2f) after (%d)min PROFIT(%.2f) OPENPRICE(%.5f) ASK/BID(%.5f/%.5f)", 
                        g_computername, s.SYMBOL, vol, OPEN_POSITION_CLOSE_TIME_MIN, s.m_order_profit, s.m_order_open_price, s.ASK, s.BID);
            m_PositionClose(s,MAGIC_POSITION, log);
            Log2Sql( s, "ORDER", 0, log );
            return ( true );
        }    

        // check if the SL has failed on an open position
        double price_diff_in_points = 0;
        double sl_in_points = SL_POINTS;
        if( 0 == SL_POINTS )
        {
            sl_in_points = s.sl_level;
        }
        if(s.m_order_type==POSITION_TYPE_BUY)
        {
            price_diff_in_points = (s.m_order_open_price - s.m_order_current_price)/s.POINT;
        }// end POSITION_TYPE_BUY    
        else if(s.m_order_type==POSITION_TYPE_SELL)
        {
            price_diff_in_points = (s.m_order_current_price - s.m_order_open_price)/s.POINT; 
        }// end POSITION_TYPE_SELL
        // try to close position via setting a new sl
        if( (0 < price_diff_in_points) && (0 < sl_in_points) && (sl_in_points < price_diff_in_points) )
        {
            string log = StringFormat( "%s SL FAILED - ClosePosition(%s at %.2f) after (%d)min PROFIT(%.2f) OPENPRICE(%.5f) ASK/BID(%.5f/%.5f)", 
                        g_computername, s.SYMBOL, vol, OPEN_POSITION_CLOSE_TIME_MIN, s.m_order_profit, s.m_order_open_price, s.ASK, s.BID);
            Log2Sql( s, "ORDER", 0, log );
            sl = 0;
        }

        // EXPERTSL - remove opposite pending orders and set a SL instead
        if( 0 == sl )
        {
            int tsl = (int)SymbolInfoInteger(s.SYMBOL,SYMBOL_TRADE_STOPS_LEVEL);
            double sl_price = 0;
            if( 0 < SL_POINTS )
            {
                sl_price = SL_POINTS*s.POINT;
                if( SL_POINTS < tsl )
                    sl_price = tsl*s.POINT;
            }
            else
            {
                sl_price = 1*s.sl_level*s.POINT;
                if( s.sl_level < tsl )
                    sl_price = tsl*s.POINT;
            }
            double tp_price = 0;
            if( 0 < TP_POINTS )
            {
                tp_price = TP_POINTS*s.POINT;
                if( TP_POINTS < tsl )
                    tp_price = tsl*s.POINT;
            }
            else
            {
                tp_price = 1*s.sl_level*s.POINT;
                if( s.sl_level < tsl )
                    tp_price = tsl*s.POINT;
            }
            
            //--- STOP LOSS
            if(s.m_order_type==POSITION_TYPE_BUY)
            {
                // SL
                sl = NormalizeDouble(s.m_order_open_price-sl_price,s.DIGITS);
                //sl = NormalizeDouble(iOpen(s.SYMBOL,s.PERIOD,2),s.DIGITS);
                // TODO SL review me
                if( (s.m_order_current_price - s.m_order_stop_level*s.POINT) < sl )
                {
                    sl = NormalizeDouble((s.m_order_current_price - 2*s.m_order_stop_level*s.POINT),s.DIGITS);
                }
                string log = "SL BUY SET:  " + nds(s,sl) + " - OPEN " + nds(s,s.m_order_open_price) + " - CURRENT " + nds(s,s.m_order_current_price) + " ASK/BID " + nds(s,s.ASK) + "/" +  nds(s,s.BID);
                Log2Sql( s, "WATCHER", 0, log );
                // TP
                if( 0 < tp_price )
                {
                    tp = NormalizeDouble(s.m_order_open_price+tp_price,s.DIGITS);
                }
            }// end POSITION_TYPE_BUY    
            else if(s.m_order_type==POSITION_TYPE_SELL)
            {
                // SL
                sl = NormalizeDouble(s.m_order_open_price+sl_price,s.DIGITS);
                //sl = NormalizeDouble(iOpen(s.SYMBOL,s.PERIOD,1),s.DIGITS);
                // TODO SL review me
                if( (s.m_order_current_price - s.m_order_stop_level*s.POINT) > sl )
                {
                    sl = NormalizeDouble((s.m_order_current_price + 2*s.m_order_stop_level*s.POINT),s.DIGITS);
                }
                string log = "SL SELL SET: " + nds(s,sl) + " - OPEN " + nds(s,s.m_order_open_price) + " - CURRENT " + nds(s,s.m_order_current_price) + " ASK/BID " + nds(s,s.ASK) + "/" +  nds(s,s.BID);
                Log2Sql( s, "WATCHER", 0, log );
                // TP
                if( 0 < tp_price )
                {
                    tp = NormalizeDouble(s.m_order_open_price-tp_price,s.DIGITS);
                }
                
            }// end POSITION_TYPE_SELL
            // if neither sl nor tp has changed, then return
            // OR if the calculated sl and tp has the same value as the current order then return
            if( (sl == 0.0) || (tp == 0.0) ) 
            {
                // TODO FIXME 
                Print( "ERRORSL FIX ME LOSS" );
                //continue;           
            }
            else if ( (sl == order_sl) && (tp == order_tp) )
            {
                //continue;           
            }
            else
            {
                if( (E_ALGOPARAM_CL == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
                {
                    s.g_sl = sl;
                }
                if( (E_ALGOPARAM_SL == g_algoparam) || (E_ALGOPARAM_SLDF == g_algoparam) )
                {
                    m_ModifyOpenPosition(s, sl,tp,MAGIC_POSITION, order_sl, order_tp);
                }
            }
        } // if( 0 < sl )

        
    } // if( 0 > m_order_profit ) 
    
    //
    // position is in profit - trailing stop
    //
    if( (0 < s.m_order_profit) && ( E_WWP_NO_SL != a_wwp_profits ) ) 
    {
    
        double tp_price = 0;
        if( 0 < TP_POINTS )
        {
           tp_price = TP_POINTS*s.POINT;
        }
    
        //--- 1. Trailing Stop
        if(s.m_order_type==POSITION_TYPE_BUY)
        {
            double target=NormalizeDouble(MathMax(s.m_order_open_price,sl)+s.g_open_positions_trailing_stop*s.POINT,s.DIGITS);
            //  if (20 >= TRAILING_STOP)           if (20 < TRAILING_STOP)
            if( ((s.BID>tbid) && (tbid>target)) || ((s.BID==tbid) && (tbid>target)) )
            {
                sl = NormalizeDouble(task-MathMax(s.g_open_positions_trailing_step,s.m_order_stop_level)*s.POINT-s.m_order_spread,s.DIGITS);
                if( (s.m_order_current_price - s.m_order_stop_level*s.POINT) < sl )
                {
                   sl = NormalizeDouble((s.m_order_current_price - 2*s.m_order_stop_level*s.POINT),s.DIGITS);
                }
                if( sl != order_sl ) {
                    string log = "SL BUY SET:  " + nds(s,sl) + " - BID " + nds(s,s.BID) + " > TBID " + nds(s,tbid) + " > TARGET " + nds(s,target);
                    Log2Sql( s, "WATCHER", 0, log );
                }
            }
            // TP
            if( 0 < tp_price )
            {
                tp = NormalizeDouble(s.m_order_open_price+tp_price,s.DIGITS);
            }
            
        }// end POSITION_TYPE_BUY    
        else if(s.m_order_type==POSITION_TYPE_SELL)
        {
            // set sl to 1000000, otherwise the MathMin function will fail
            if( sl == 0 ) sl = 1000000;
            double target=NormalizeDouble(MathMin(s.m_order_open_price,sl)-s.g_open_positions_trailing_stop*s.POINT,s.DIGITS);
            //  if (20 >= TRAILING_STOP)           if (20 < TRAILING_STOP)
            if( ((s.ASK<task) && (task<target)) || ((s.ASK==task) && (task<target)) )
            {
                sl=NormalizeDouble(tbid+MathMax(s.g_open_positions_trailing_step,s.m_order_stop_level)*s.POINT+s.m_order_spread,s.DIGITS);
                if( (s.m_order_current_price - s.m_order_stop_level*s.POINT) > sl )
                {
                   sl = NormalizeDouble((s.m_order_current_price + 2*s.m_order_stop_level*s.POINT),s.DIGITS);
                }
                if( sl != order_sl ) {
                    string log = "SL SELL SET: " + nds(s,sl) + " - ASK " + nds(s,s.ASK) + " < TASK " + nds(s,task) + " < TARGET " + nds(s,target);
                    Log2Sql( s, "WATCHER", 0, log );
                }
            }
            else                 
            {
                // reset sl to 0 from 1000000, otherwise TRADE_ACTION_SLTP will be called unnecessary
                sl = 0;
            }
            // TP
            if( 0 < tp_price )
            {
                tp = NormalizeDouble(s.m_order_open_price-tp_price,s.DIGITS);
            }
            
        }// end POSITION_TYPE_SELL
        // if neither sl nor tp has changed, then return
        // OR if the calculated sl and tp has the same value as the current order then return
        if( (sl == 0.0) || (tp == 0.0) ) 
        {
            // TODO FIXME 
            Print( "ERRORSL FIX ME PROFIT" );
            //continue;           
        }
        else if ( (sl == order_sl) && (tp == order_tp) )
        {
            //continue;           
        }
        else
        {

            if( (E_ALGOPARAM_CL == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
            {
                s.g_sl = sl;
            }
            if( (E_ALGOPARAM_SL == g_algoparam) || (E_ALGOPARAM_SLDF == g_algoparam) )
            {
                m_ModifyOpenPosition(s, sl,tp,MAGIC_POSITION, order_sl, order_tp);
            }
        
        } // if( (sl == 0.0) && (tp == 0.0) ) 

    } // else if( 0 <= m_order_profit )

    if( (E_ALGOPARAM_CL == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
    {
        if( 0 < s.g_sl )
        {
            if(s.m_order_type==POSITION_TYPE_BUY)
            {
                if( tbid < s.g_sl )
                {
                    string plog = "SL BUY [" + nds(s,s.g_sl) + "]";
                    m_PositionClose(s, 456, plog, true );
                    string log = "SL BUY CLO:  BID " + nds(s,s.BID) + " TBID " + nds(s,tbid) + " < SL " + nds(s,s.g_sl);
                    Log2Sql( s, "WATCHER", 0, log );
                }
            }
            else if(s.m_order_type==POSITION_TYPE_SELL)
            {
                if( task > s.g_sl )
                {
                    string plog = "SL SELL [" + nds(s,s.g_sl) + "]";
                    m_PositionClose(s, 456, plog, true );
                    string log = "SL SELL CLO: ASK " + nds(s,s.BID) + " TASK " + nds(s,tbid) + " > SL " + nds(s,s.g_sl);
                    Log2Sql( s, "WATCHER", 0, log );
                }
            }
        } // if( 0 < s.g_sl )
    } // if( (E_ALGOPARAM_CL == g_algoparam) || (E_ALGOPARAM_CLDF == g_algoparam) )
       
    return (true);

} // int m_WorkWithPositions()
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| iLogTicks
//+------------------------------------------------------------------+
void iLogTicks(CSymbol& s)
{

    if( true == s.iCalcNewTick() ) {
        s.g_avg_ticks_ask = iCustPriceDF(s,0,I_PRICE_TICK_ASK,0);
        s.g_avg_ticks_bid = iCustPriceDF(s,0,I_PRICE_TICK_BID,0);
    } else {
return;
    }
    
    datetime DT = g_time_local; //tick.time;
    uint tc = GetTickCount();
    long ms = tc - s.TICKCOUNT;
    s.TICKCOUNT = tc;

    // datetime ms - dtms
    // TIME - subtract one hour for certain accounts
    //   still TODO otimemsc adjustment
    if(( true == ADJUSTTIME ) && ( true == TESTERMODE )){
        DT = m_HourDec( DT );
    } // if(( true == ADJUSTTIME ) && ( true == TESTERMODE ))
    
    string aid = "0";
    string adatetime = "";
    // Interface to float.js library - The timestamps must be specified as Javascript timestamps, as milliseconds since January 1, 1970 00:00. This is like Unix timestamps, but in milliseconds instead of seconds (remember to multiply with 1000!).
    int len = StringConcatenate(adatetime, IntegerToString(DT), m_GetMilliSecondsAsString( TESTERMODE ) );
    string adate = TimeToString(DT,TIME_DATE);
    string atime = TimeToString(DT,TIME_SECONDS);
    string aask  = nds(s, s.ASK);
    string abid  = nds(s, s.BID);

    string avolume = IntegerToString( s.VOL/*tick.volume*/ );
    long tvol = iTickVolume( s.SYMBOL, s.PERIOD, 0 );
    s.CVOL++;
    if( s.PREVVOL > tvol ){
        s.CVOL = 1;
    }
    s.PREVVOL = tvol;
    string atvol = IntegerToString( tvol ); // CopyTickVolume
    long rvol = iRealVolume( s.SYMBOL, s.PERIOD, 0 );
    string arvol = IntegerToString( rvol ); // CopyRealVolume
    string ams = IntegerToString( ms );
    string scvol = IntegerToString( s.CVOL );

//17:28:54 mysql EURUSD,H1: Query: INSERT INTO TICKS (id,datetime,date,time,bid,ask,volume,tvol,rvol,ms ) VALUES (0,1363024800,2013.03.11,18:00:00,1,1,899,27485,27485,-1265769421) 
//17:28:54 mysql EURUSD,H1: Returned error: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '.11,18:00:00,1,1,899,27485,27485,-1265769421)' at line 1

    // attention interface here - 10 points diff - TODO maybe change from T1 to T10 here
    string tb = s.g_table_ticks + "_T1";
    string create = "";
    StringConcatenate(create,"CREATE TABLE IF NOT EXISTS ",s.g_db_ticks,".",tb," ( id INT(10) NOT NULL AUTO_INCREMENT, datetime BIGINT, date VARCHAR(12), time VARCHAR(12), bid DEC(15,5), ask DEC(15,5), volume INT(10), tvol INT(10), rvol BIGINT, ms INT(10), cvol INT(10), PRIMARY KEY (id), INDEX datetime (datetime) )");
    string query = "";
    StringConcatenate(query,"INSERT INTO ",s.g_db_ticks,".",tb," (id,datetime,date,time,bid,ask,volume,tvol,rvol,ms,cvol ) VALUES (",aid,",",adatetime,",'",adate,"','",atime,"',",abid,",",aask,",",avolume,",",atvol,",",arvol,",",ms,",",scvol,") ");
    m_sql_query( query, s.g_db_ticks, tb, create );
    
    // log the ticks digital filters TD
    aask  = nds(s, s.g_avg_ticks_ask);
    abid  = nds(s, s.g_avg_ticks_bid);
    string tb1 = s.g_table_ticks + "_TD";
    string create1 = "";
    StringConcatenate(create1,"CREATE TABLE IF NOT EXISTS ",s.g_db_ticks,".",tb1," ( id INT(10) NOT NULL AUTO_INCREMENT, datetime BIGINT, date VARCHAR(12), time VARCHAR(12), bid DEC(15,5), ask DEC(15,5), volume INT(10), tvol INT(10), rvol BIGINT, ms INT(10), cvol INT(10), PRIMARY KEY (id), INDEX datetime (datetime) )");
    string query1 = "";
    StringConcatenate(query1,"INSERT INTO ",s.g_db_ticks,".",tb1," (id,datetime,date,time,bid,ask,volume,tvol,rvol,ms,cvol ) VALUES (",aid,",",adatetime,",'",adate,"','",atime,"',",abid,",",aask,",",avolume,",",atvol,",",arvol,",",ms,",",scvol,") ");
    m_sql_query( query1, s.g_db_ticks, tb1, create1 );
    
} // void iLogTicks()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| iLogPeriod
//+------------------------------------------------------------------+
int iLogPeriod(CSymbol& s,ENUM_TIMEFRAMES timeframe, int shift) 
{
    
    // datetime ms - dtms
    datetime dt, dtc;
    if( 0 < shift )
    {
        // datetime ms - dtms
        dt  = iTime( s.SYMBOL, timeframe, shift );
        if( 0 == dt ) {
            return (1);
        } 
        dtc = iTime( s.SYMBOL, timeframe, shift-1 );
        if( 0 == dtc ) {
            return (2);
        } 
    }
    else if( 0 == shift )
    {
        dt  = iTime( s.SYMBOL, timeframe, shift );
        if( 0 == dt ) {
            return (3);
        } 
        dtc = g_time_current;
        if( 0 == dtc ) {
            return (4);
        } 
        //Print( "LOGPERIOD " + EnumToString((ENUM_TIMEFRAMES)timeframe) + " " + TimeToString(dt) + " " + TimeToString(dtc)  );
    }
    else
    {
        return (5);
    } // if( 0 < shift )
    
    // TIME - subtract one hour for certain accounts
    if( true == ADJUSTTIME ){
        dt  = m_HourDec( dt );
        dtc = m_HourDec( dtc );
    }
    
    string aid = "0";
    string adatetime = "";
    // Interface to float.js library - The timestamps must be specified as Javascript timestamps, as milliseconds since January 1, 1970 00:00. This is like Unix timestamps, but in milliseconds instead of seconds (remember to multiply with 1000!).
    int len = StringConcatenate(adatetime, IntegerToString(dt), m_GetMilliSecondsAsString( TESTERMODE ) );
    string adate = TimeToString(dt,TIME_DATE);
    string atime = TimeToString(dt,TIME_SECONDS);
    string adatetimec = "";
    len = StringConcatenate(adatetimec, IntegerToString(dtc), m_GetMilliSecondsAsString( TESTERMODE ) );
    string adatec = TimeToString(dtc,TIME_DATE);
    string atimec = TimeToString(dtc,TIME_SECONDS);
    double ask = SymbolInfoDouble(s.SYMBOL,SYMBOL_ASK);
    if( 0.0 == ask ) {
        return (3);
    } 
    string aask  = nds(s,ask);
    double bid = SymbolInfoDouble(s.SYMBOL,SYMBOL_BID);
    if( 0.0 == bid ) {
        return (4);
    } 
    string abid  = nds(s,bid);
    /*
    // TODO what is the difference between MqlTick and SymbolInfo
    string aasks  = nds(s,tick.ask);
    string abids  = nds(s,tick.bid);
    printf("%s  ASK[%s] BID[%s]ASKS[%s] BIDS[%s]",EnumToString((ENUM_TIMEFRAMES)timeframe, aask, abid, avol, aasks, abids, avols);
    */
    double o = iOpen(s.SYMBOL,timeframe,shift);
    if( 0.0 == o ) {
        return (5);
    } 
    string aopen = nds(s,o);
    
    double h = iHigh(s.SYMBOL,timeframe,shift);
    if( 0.0 == h ) {
        return (6);
    } 
    string ahigh = nds(s,h);
    
    double l = iLow(s.SYMBOL,timeframe,shift);
    if( 0.0 == l ) {
        return (7);
    } 
    string alow  = nds(s,l);

    double c = iClose(s.SYMBOL,timeframe,shift);
    if( 0.0 == c ) {
        return (8);
    } 
    string aclose= nds(s,c);
    
    // sanity check
    if( E_ALGOPARAM_TICKSNORMALISE == g_algoparam ) 
    {
        if( true == s.g_is_normalised )
        {
            m_LogNormalise( s, timeframe, dtc, o, c, h, l );
        }
    }
    
    long tvol = iTickVolume( s.SYMBOL, timeframe, shift );
    string atvol = IntegerToString( tvol ); // CopyTickVolume
    long rvol = iRealVolume( s.SYMBOL, timeframe, shift );
    string arvol = IntegerToString( rvol ); // CopyRealVolume

    string aperiod = ConvertPeriodToString(timeframe);
    
    string tb = s.g_table_ticks + "_" + aperiod;
    string query = "";
    StringConcatenate(query,"INSERT INTO ",s.g_db_ticks,".",tb," (id,datetime,date,time,cdatetime,cdate,ctime,bid,ask,open,high,low,close,tvol,rvol ) VALUES (",aid,",",adatetime,",'",adate,"','",atime,"',",adatetimec,",'",adatec,"','",atimec,"',",abid,",",aask,",",aopen,",",ahigh,",",alow,",",aclose,",",atvol,",",arvol,") ");
    string create = "";     
    StringConcatenate(create,"CREATE TABLE IF NOT EXISTS ",s.g_db_ticks,".",tb," ( id INT(10) NOT NULL AUTO_INCREMENT, datetime BIGINT, date VARCHAR(12), time VARCHAR(12), cdatetime BIGINT, cdate VARCHAR(12), ctime VARCHAR(12), bid DEC(15,5), ask DEC(15,5), open DEC(15,5), high DEC(15,5), low DEC(15,5), close DEC(15,5), tvol INT(10), rvol BIGINT, PRIMARY KEY (id), INDEX datetime (datetime) )");
    m_sql_query( query, s.g_db_ticks, tb, create );

    return (0);
} // int iLogPeriod(string asymbol,ENUM_TIMEFRAMES timeframe, int shift) 


//+------------------------------------------------------------------+
//| m_logNewBar_M1
//+------------------------------------------------------------------+
void m_LogNewBar_M1(CSymbol& s) { 
    datetime dt = iTime(s.SYMBOL,PERIOD_M1,0);
    if( 0 == dt ) {
        return;
    } 
    if( s.LASTBAR_M1!=dt ) {
        if( 0 == iLogPeriod(s,PERIOD_M1,1) ) {
            s.LASTBAR_M1 =dt; 
        } 
        // return a shift of one
        //
        // TODO - Real Time Issue - Due to 1s EventTimer the new bar is one second too late discovered
        //   this should be detected in the OnStart (tick function) instead
        //
        //2013.10.02 14:26:30	Core 1	2013.09.18 22:45:01   PERIOD_M15 22:30:00 - 1.35278 - 1.35415 - 1.35236 - 1.35255
        //2013.10.02 14:26:30	Core 1	2013.09.18 22:45:01   PERIOD_M5 22:40:00 - 1.35311 - 1.35311 - 1.35236 - 1.35255
        //2013.10.02 14:26:30	Core 1	2013.09.18 22:45:01   PERIOD_M1 22:44:00 - 1.35249 - 1.35259 - 1.35249 - 1.35255
    }
} // void m_logNewBar_M1()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_LogNewBar_M5
//+------------------------------------------------------------------+
void m_LogNewBar_M5(CSymbol& s) { 
    datetime dt = iTime(s.SYMBOL,PERIOD_M5,0);
    if( 0 == dt ) {
        return;
    } 
    if( s.LASTBAR_M5!=dt ) {
        dbg(s, " M5 " + TimeToString( dt ));
        if( 0 == iLogPeriod(s,PERIOD_M5,1) ) {
            s.LASTBAR_M5 =dt; 
        }
    }
} // void m_LogNewBar_M5() 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_LogNewBar_M15
//+------------------------------------------------------------------+
void m_LogNewBar_M15(CSymbol& s) { 
    datetime dt = iTime(s.SYMBOL,PERIOD_M15,0);
    if( 0 == dt ) {
        return;
    } 
    if( s.LASTBAR_M15!=dt ) {
        dbg(s, " M15 " + TimeToString( dt ));
        if( 0 == iLogPeriod(s,PERIOD_M15,1) ) {
            s.LASTBAR_M15 =dt; 
        }
    }
} // void m_LogNewBar_M15() 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_LogNewBar_H1
//+------------------------------------------------------------------+
void m_LogNewBar_H1(CSymbol& s) { 
    datetime dt = iTime(s.SYMBOL,PERIOD_H1,0);
    if( 0 == dt ) {
        return;
    } 
    if( s.LASTBAR_H1 != dt ) {
        dbg(s, " H1 " + TimeToString( dt ));
        if( 0 == iLogPeriod(s,PERIOD_H1,1) ) {
            s.LASTBAR_H1 =dt; 
        }
    }
} // void m_LogNewBar_H1()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_LogNewBar_H4
//+------------------------------------------------------------------+
void m_LogNewBar_H4(CSymbol& s) { 
    datetime dt = iTime(s.SYMBOL,PERIOD_H4,0);
    if( 0 == dt ) {
        return;
    } 
    if( s.LASTBAR_H4 != dt ) {
        dbg(s, " H4 " + TimeToString( dt ));
        if( 0 == iLogPeriod(s,PERIOD_H4,1) ) {
            s.LASTBAR_H4 =dt; 
        }
    }
} // void m_LogNewBar_H4()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| m_LogNewBar_D1
//+------------------------------------------------------------------+
void m_LogNewBar_D1(CSymbol& s) { 
    datetime dt = iTime(s.SYMBOL,PERIOD_D1,0);
    if( 0 == dt ) {
        return;
    } 
    if( s.LASTBAR_D1 != dt ) {
        dbg(s, " D1 " + TimeToString( dt ));
        if( 0 == iLogPeriod(s,PERIOD_D1,1) ) {
            s.LASTBAR_D1 =dt; 
        }
    }
} // void m_LogNewBar_D1()
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

/*
// TODO move this code into the MT4 library
// TimeTest references:
//  http://forum.mql4.com/9900
//  http://msdn.microsoft.com/en-us/library/ms725473%28v=vs.85%29.aspx

#import "kernel32.dll"
    void GetLocalTime(int& TimeArray[]);
    void GetSystemTime(int& TimeArray[]);
    int  GetTimeZoneInformation(int& TZInfoArray[]);
#import

13:26:25 ticks EURUSD,M1: 1) SystemTime: 2013.07.29 11:26:25:336
13:26:25 ticks EURUSD,M1: 2) TimeLocal:  2013.07.29 13:26:25
13:26:25 ticks EURUSD,M1: 3) TimeCurrent 2013.07.29 14:26:25
13:26:25 ticks EURUSD,M1: 4) LocalTime:  2013.07.29 13:26:25:336
13:26:25 ticks EURUSD,M1: 5) Difference between your local time and GMT is: -60 minutes
13:26:25 ticks EURUSD,M1: 6) Current difference between your local time and GMT is: -120 minutes
13:26:25 ticks EURUSD,M1: 7) Greenwich mean time is: 2013.07.29 11:26:25
13:26:25 ticks EURUSD,M1: 8) Standard time is: 0.10.05 03:00:00
13:26:25 ticks EURUSD,M1: 9) Daylight savings time is: 0.03.05 02:00:00
13:26:25 ticks EURUSD,M1: 1) SystemTime: 2013.07.29 11:26:25:586
13:26:25 ticks EURUSD,M1: 2) TimeLocal:  2013.07.29 13:26:25
13:26:25 ticks EURUSD,M1: 3) TimeCurrent 2013.07.29 14:26:25
13:26:25 ticks EURUSD,M1: 4) LocalTime:  2013.07.29 13:26:25:586
13:26:25 ticks EURUSD,M1: 5) Difference between your local time and GMT is: -60 minutes
13:26:25 ticks EURUSD,M1: 6) Current difference between your local time and GMT is: -120 minutes
13:26:25 ticks EURUSD,M1: 7) Greenwich mean time is: 2013.07.29 11:26:25
13:26:25 ticks EURUSD,M1: 8) Standard time is: 0.10.05 03:00:00
13:26:25 ticks EURUSD,M1: 9) Daylight savings time is: 0.03.05 02:00:00

int TimeTest()
  {
   int    TimeArray[4];
   int    TZInfoArray[43];
   int    nYear,nMonth,nDay,nHour,nMin,nSec,nMilliSec;
   string sMilliSec;
   GetSystemTime(TimeArray);
//---- parse date and time from array
   nYear=TimeArray[0]&0x0000FFFF;
   nMonth=TimeArray[0]>>16;
   nDay=TimeArray[1]>>16;
   nHour=TimeArray[2]&0x0000FFFF;
   nMin=TimeArray[2]>>16;
   nSec=TimeArray[3]&0x0000FFFF;
   nMilliSec=TimeArray[3]>>16;
//---- format date and time items
   sMilliSec=1000+nMilliSec;
   sMilliSec=StringSubstr(sMilliSec,1);
   string time_string=FormatDateTime(nYear,nMonth,nDay,nHour,nMin,nSec);
   dbg("1) SystemTime: ",time_string,":",sMilliSec);
//----
   dbg("2) TimeLocal:  ",TimeToStr(TimeLocal(),TIME_DATE),  " ", TimeToStr(TimeLocal(),TIME_SECONDS));
   dbg("3) TimeCurrent ",TimeToStr(TimeCurrent(),TIME_DATE)," ", TimeToStr(TimeCurrent(),TIME_SECONDS));
//----
   GetLocalTime(TimeArray);
//---- parse date and time from array
   nYear=TimeArray[0]&0x0000FFFF;
   nMonth=TimeArray[0]>>16;
   nDay=TimeArray[1]>>16;
   nHour=TimeArray[2]&0x0000FFFF;
   nMin=TimeArray[2]>>16;
   nSec=TimeArray[3]&0x0000FFFF;
   nMilliSec=TimeArray[3]>>16;
//---- format date and time items
   sMilliSec=1000+nMilliSec;
   sMilliSec=StringSubstr(sMilliSec,1);
   time_string=FormatDateTime(nYear,nMonth,nDay,nHour,nMin,nSec);
   dbg("4) LocalTime:  ",time_string,":",sMilliSec);
//---- shift with daylight savings
   int gmt_shift=0;
   int ret=GetTimeZoneInformation(TZInfoArray);
   if(ret!=0) gmt_shift=TZInfoArray[0];
   dbg("5) Difference between your local time and GMT is: ",gmt_shift," minutes");
   if(ret==2) gmt_shift+=TZInfoArray[42];
   dbg("6) Current difference between your local time and GMT is: ",gmt_shift," minutes");
//---- GMT
   datetime local_time=StrToTime(time_string);
   dbg("7) Greenwich mean time is: ",TimeToStr(local_time+gmt_shift*60,TIME_DATE|TIME_SECONDS));
//---- winter time (nYear remains the current)
   nYear=TimeArray[17]&0x0000FFFF;
   nMonth=TZInfoArray[17]>>16;
   nDay=TZInfoArray[18]>>16;
   nHour=TZInfoArray[19]&0x0000FFFF;
   nMin=TZInfoArray[19]>>16;
   nSec=TZInfoArray[20]&0x0000FFFF;
   time_string=FormatDateTime(nYear,nMonth,nDay,nHour,nMin,nSec);
   dbg("8) Standard time is: ",time_string);
//---- summer time (nYear remains the current)
   nYear=TimeArray[38]&0x0000FFFF;
   nMonth=TZInfoArray[38]>>16;
   nDay=TZInfoArray[39]>>16;
   nHour=TZInfoArray[40]&0x0000FFFF;
   nMin=TZInfoArray[40]>>16;
   nSec=TZInfoArray[41]&0x0000FFFF;
   time_string=FormatDateTime(nYear,nMonth,nDay,nHour,nMin,nSec);
   dbg("9) Daylight savings time is: ",time_string);
   return(0);
  }
  
string FormatDateTime(int nYear,int nMonth,int nDay,int nHour,int nMin,int nSec)
  {
   string sMonth,sDay,sHour,sMin,sSec;
   sMonth=100+nMonth;
   sMonth=StringSubstr(sMonth,1);
   sDay=100+nDay;
   sDay=StringSubstr(sDay,1);
   sHour=100+nHour;
   sHour=StringSubstr(sHour,1);
   sMin=100+nMin;
   sMin=StringSubstr(sMin,1);
   sSec=100+nSec;
   sSec=StringSubstr(sSec,1);
   return(StringConcatenate(nYear,".",sMonth,".",sDay," ",sHour,":",sMin,":",sSec));
  }

*/

/*
//+------------------------------------------------------------------+
//| Replace all occurrences of a substring in the specified string   |
//+------------------------------------------------------------------+
string m_StringReplace(string m_string, string substring, string newstring)
{
    int    result=0,len,pos=0;
    string tmp;
    //---
    len=StringLen(substring);
    pos=StringFind(m_string,substring,pos);
    //dbg( "STRINGF: ["+pos+"]["+m_string+"]["+substring+"]["+newstring+"]");
    while( pos >= 0 )
    {
        tmp=StringSubstr(m_string,0,pos)+newstring;
        m_string=tmp+StringSubstr(m_string,pos+len);
        // to eliminate possible loops
        pos+=StringLen(newstring);
        result++;
        pos=StringFind(m_string,substring,pos);
    }
    //--- result
    string repstring = "";
    if( 0 < result ) {
        repstring = m_string;
    }
    return( repstring );
} // string m_StringReplace(string m_string, string substring, string newstring)
*/

/*

bool isNewBar_H1() { 
    datetime dt = iTime(SYMBOL,PERIOD_H1,0);
    if(LASTBAR_H1!=dt){ 

        string DELIM = " - ";
        
        // SHIFT 0 at new bar - equals dt = iTime(SYMBOL,PERIOD_H1,0);
        string w = "H1a " + TimeToString(iTime(SYMBOL,PERIOD_H1,0),TIME_SECONDS) + DELIM + nds(s,iOpen(SYMBOL,PERIOD_H1,0)) + DELIM + nds(s,iHigh(SYMBOL,PERIOD_H1,0)) + DELIM + nds(s,iLow(SYMBOL,PERIOD_H1,0)) + DELIM + nds(s,iClose(SYMBOL,PERIOD_H1,0)) ;
        dbg(w);
        
        // SHIFT 1 at new bar - equals LASTBAR_H1 = iTime(SYMBOL,PERIOD_H1,1);
               w = "H1b " + TimeToString(iTime(SYMBOL,PERIOD_H1,1),TIME_SECONDS) + DELIM + nds(s,iOpen(SYMBOL,PERIOD_H1,1)) + DELIM + nds(s,iHigh(SYMBOL,PERIOD_H1,1)) + DELIM + nds(s,iLow(SYMBOL,PERIOD_H1,1)) + DELIM + nds(s,iClose(SYMBOL,PERIOD_H1,1)) ;
        dbg(w);
        
        LASTBAR_H1 =dt; 
        return (true); 
    } 
    return(false); 
} // bool isNewBar() 


JO	0	13:55:01	Core 1	EURUSD,M1 (MetaQuotes-Demo): every tick generating
IE	0	13:55:01	Core 1	EURUSD,M1: testing of Experts\ticks.ex5 from 2013.09.18 00:00 to 2013.09.19 00:00 started with inputs:
MF	0	13:55:01	Core 1	  USEDATABASE=false
PS	0	13:55:01	Core 1	  DATABASE=DATABASE
LN	0	13:55:01	Core 1	  TABLE=TABLE
II	0	13:55:01	Core 1	  MYSQLHOST=localhost
GM	0	13:55:01	Core 1	  MYSQLUSER=username
FR	0	13:55:01	Core 1	  MYSQLPASS=password
KI	0	13:55:01	Core 1	  MYSQLPORT=3306
HN	0	13:55:01	Core 1	2013.09.18 00:00:00   Time GMT: 2013.09.18 00:00
PF	0	13:55:01	Core 1	2013.09.18 00:00:00   Time CUR: 2013.09.18 00:00
RM	0	13:55:01	Core 1	2013.09.18 00:00:00   Time LOC: 2013.09.18 00:00
MD	0	13:55:01	Core 1	2013.09.18 00:00:00   Time TRA: 2013.09.18 00:00
MQ	0	13:55:01	Core 1	2013.09.18 00:00:00   Time DST: 0
IF	0	13:55:01	Core 1	2013.09.18 00:00:00   Time OFF: 0
GP	0	13:55:01	Core 1	2013.09.18 00:00:00   ACCOUNT_NAME:    Tester
HK	0	13:55:01	Core 1	2013.09.18 00:00:00   ACCOUNT_SERVER:  MetaQuotes-Demo
CQ	0	13:55:01	Core 1	2013.09.18 00:00:00   ACCOUNT_COMPANY: MetaQuotes Software Corp.
QJ	0	13:55:01	Core 1	2013.09.18 00:00:00   STARTUP - Expert[TICKS] Version[0.13] Error[0] USEDATABASE[0]
DF	0	13:55:01	Core 1	EURUSD,H1: history cached from 2012.01.02 00:00

        // SHIFT 0 at new bar - equals dt = iTime(SYMBOL,PERIOD_H1,0);
RL	0	13:55:01	Core 1	2013.09.18 00:00:01   H1a 00:00:00 - 1.33578 - 1.33578 - 1.33578 - 1.33578
        // SHIFT 1 at new bar - equals LASTBAR_H1 = iTime(SYMBOL,PERIOD_H1,1);
MP	0	13:55:01	Core 1	2013.09.18 00:00:01   H1b 23:00:00 - 1.33584 - 1.33593 - 1.33544 - 1.33578

ED	0	13:55:01	Core 1	2013.09.18 01:00:00   H1a 01:00:00 - 1.33564 - 1.33564 - 1.33564 - 1.33564
FH	0	13:55:01	Core 1	2013.09.18 01:00:00   H1b 00:00:00 - 1.33578 - 1.33583 - 1.33562 - 1.33563
IL	0	13:55:01	Core 1	2013.09.18 02:00:00   H1a 02:00:00 - 1.33563 - 1.33563 - 1.33563 - 1.33563
NS	0	13:55:01	Core 1	2013.09.18 02:00:00   H1b 01:00:00 - 1.33564 - 1.33572 - 1.33554 - 1.33563
MG	0	13:55:01	Core 1	2013.09.18 03:00:00   H1a 03:00:00 - 1.33493 - 1.33493 - 1.33493 - 1.33493
PK	0	13:55:01	Core 1	2013.09.18 03:00:00   H1b 02:00:00 - 1.33563 - 1.33563 - 1.33468 - 1.33494
QO	0	13:55:01	Core 1	2013.09.18 04:00:00   H1a 04:00:00 - 1.33482 - 1.33482 - 1.33482 - 1.33482
FS	0	13:55:01	Core 1	2013.09.18 04:00:00   H1b 03:00:00 - 1.33493 - 1.33510 - 1.33471 - 1.33483
EG	0	13:55:01	Core 1	2013.09.18 05:00:00   H1a 05:00:00 - 1.33520 - 1.33520 - 1.33520 - 1.33520
QK	0	13:55:01	Core 1	2013.09.18 05:00:00   H1b 04:00:00 - 1.33482 - 1.33520 - 1.33475 - 1.33520
IO	0	13:55:01	Core 1	2013.09.18 06:00:00   H1a 06:00:00 - 1.33516 - 1.33516 - 1.33516 - 1.33516
IR	0	13:55:01	Core 1	2013.09.18 06:00:00   H1b 05:00:00 - 1.33520 - 1.33538 - 1.33499 - 1.33517
MF	0	13:55:01	Core 1	2013.09.18 07:00:00   H1a 07:00:00 - 1.33586 - 1.33586 - 1.33586 - 1.33586
LJ	0	13:55:01	Core 1	2013.09.18 07:00:00   H1b 06:00:00 - 1.33516 - 1.33592 - 1.33515 - 1.33587
QN	0	13:55:01	Core 1	2013.09.18 08:00:00   H1a 08:00:00 - 1.33579 - 1.33579 - 1.33579 - 1.33579
LR	0	13:55:01	Core 1	2013.09.18 08:00:00   H1b 07:00:00 - 1.33586 - 1.33639 - 1.33580 - 1.33582
EF	0	13:55:01	Core 1	2013.09.18 09:00:00   H1a 09:00:00 - 1.33573 - 1.33573 - 1.33573 - 1.33573
GJ	0	13:55:01	Core 1	2013.09.18 09:00:00   H1b 08:00:00 - 1.33579 - 1.33628 - 1.33544 - 1.33572
IN	0	13:55:01	Core 1	2013.09.18 10:00:00   H1a 10:00:00 - 1.33508 - 1.33508 - 1.33507 - 1.33507
DM	0	13:55:01	Core 1	2013.09.18 10:00:00   H1b 09:00:00 - 1.33573 - 1.33610 - 1.33485 - 1.33508
MQ	0	13:55:01	Core 1	2013.09.18 11:00:00   H1a 11:00:00 - 1.33503 - 1.33503 - 1.33503 - 1.33503
GE	0	13:55:01	Core 1	2013.09.18 11:00:00   H1b 10:00:00 - 1.33508 - 1.33588 - 1.33444 - 1.33503
QI	0	13:55:01	Core 1	2013.09.18 12:00:00   H1a 12:00:00 - 1.33554 - 1.33554 - 1.33554 - 1.33554
LM	0	13:55:01	Core 1	2013.09.18 12:00:00   H1b 11:00:00 - 1.33503 - 1.33589 - 1.33495 - 1.33553
EQ	0	13:55:01	Core 1	2013.09.18 13:00:00   H1a 13:00:00 - 1.33514 - 1.33514 - 1.33514 - 1.33514
ME	0	13:55:01	Core 1	2013.09.18 13:00:00   H1b 12:00:00 - 1.33554 - 1.33569 - 1.33460 - 1.33514
II	0	13:55:01	Core 1	2013.09.18 14:00:00   H1a 14:00:00 - 1.33534 - 1.33534 - 1.33534 - 1.33534
GL	0	13:55:01	Core 1	2013.09.18 14:00:00   H1b 13:00:00 - 1.33514 - 1.33549 - 1.33498 - 1.33533
MP	0	13:55:01	Core 1	2013.09.18 15:00:00   H1a 15:00:00 - 1.33469 - 1.33469 - 1.33469 - 1.33469
ED	0	13:55:01	Core 1	2013.09.18 15:00:00   H1b 14:00:00 - 1.33534 - 1.33552 - 1.33431 - 1.33468
QH	0	13:55:01	Core 1	2013.09.18 16:00:00   H1a 16:00:00 - 1.33474 - 1.33475 - 1.33474 - 1.33475
FL	0	13:55:01	Core 1	2013.09.18 16:00:00   H1b 15:00:00 - 1.33469 - 1.33491 - 1.33411 - 1.33473
EP	0	13:55:01	Core 1	2013.09.18 17:00:00   H1a 17:00:00 - 1.33463 - 1.33463 - 1.33463 - 1.33463
GD	0	13:55:01	Core 1	2013.09.18 17:00:00   H1b 16:00:00 - 1.33474 - 1.33529 - 1.33380 - 1.33462
IH	0	13:55:01	Core 1	2013.09.18 18:00:00   H1a 18:00:00 - 1.33503 - 1.33503 - 1.33503 - 1.33503
RO	0	13:55:01	Core 1	2013.09.18 18:00:00   H1b 17:00:00 - 1.33463 - 1.33583 - 1.33442 - 1.33503
MS	0	13:55:01	Core 1	2013.09.18 19:00:00   H1a 19:00:00 - 1.33578 - 1.33578 - 1.33578 - 1.33578
HG	0	13:55:01	Core 1	2013.09.18 19:00:00   H1b 18:00:00 - 1.33503 - 1.33596 - 1.33490 - 1.33578
QK	0	13:55:01	Core 1	2013.09.18 20:00:00   H1a 20:00:00 - 1.33740 - 1.33740 - 1.33740 - 1.33740
FO	0	13:55:01	Core 1	2013.09.18 20:00:00   H1b 19:00:00 - 1.33578 - 1.33830 - 1.33574 - 1.33728
ES	0	13:55:01	Core 1	2013.09.18 21:00:00   H1a 21:00:00 - 1.35069 - 1.35073 - 1.35069 - 1.35073
FG	0	13:55:01	Core 1	2013.09.18 21:00:00   H1b 20:00:00 - 1.33740 - 1.35102 - 1.33740 - 1.35071
IK	0	13:55:01	Core 1	2013.09.18 22:00:00   H1a 22:00:00 - 1.35064 - 1.35064 - 1.35064 - 1.35064
FN	0	13:55:01	Core 1	2013.09.18 22:00:00   H1b 21:00:00 - 1.35069 - 1.35112 - 1.34929 - 1.35063
MR	0	13:55:01	Core 1	2013.09.18 23:00:00   H1a 23:00:00 - 1.35212 - 1.35212 - 1.35212 - 1.35212
LF	0	13:55:01	Core 1	2013.09.18 23:00:00   H1b 22:00:00 - 1.35064 - 1.35415 - 1.35040 - 1.35212
FH	0	13:55:01	Core 1	final balance 10000.00

*/

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

/*
//+------------------------------------------------------------------+
//| OnMillisecondTimer
//+------------------------------------------------------------------+
void OnMillisecondTimer(CSymbol& s) 
{
    // sanity checks    
    if( 0 == g_time_local ) return;
    if( 0 == g_time_current ) return;
    if( 0 == s.ASK ) return;
    if( 0 == s.BID ) return;
    if( false == m_TradingAllowed() ) 
    {
        return;
    }

    // eval o0
    double o0 = iOpen(s.SYMBOL,s.PERIOD,0);
    if( 0.0 == o0 )
    {
      return;
    }
    if( 0.0 == s.g_o0prev )
    {
        s.g_o0prev = o0;
    }
    double AVG = NormalizeDouble( s.BID + (s.ASK-s.BID)/2 , s.DIGITS );
    if( 0.0 == s.g_avgprev )
    {
        s.g_avgprev = AVG;
    }
    
    int spread = s.SPREADPOINTS;//(int)SymbolInfoInteger(SYMBOL,SYMBOL_SPREAD);
    long ticks = s.VOL;//iTickVolume(SYMBOL,PERIOD,0);
    //datetime t0 = (datetime)SymbolInfoInteger(SYMBOL,SYMBOL_TIME);
    
    if( NormalizeDouble( o0,s.DIGITS ) != NormalizeDouble( s.g_o0prev,s.DIGITS ) )
    {
        if( NormalizeDouble( o0,s.DIGITS ) == NormalizeDouble( s.BID,s.DIGITS ) )
        {
            s.g_o0prev = o0;
            bool mod = false;
            string smod = "---";
            double compare = 1 / (MathPow( 10, (double)(s.DIGITS-1) ) );
            double diff = NormalizeDouble( AVG, s.DIGITS-1) - NormalizeDouble( s.g_avgprev, s.DIGITS-1);
            if( NormalizeDouble(compare,s.DIGITS-1) < NormalizeDouble(MathAbs(diff),s.DIGITS-1) ) 
            {
                smod = "MOD";
                mod = true;
            }
            // TODO make this work 
            // currently then pending order expiry time had to be updated
            // otherwise the orders will expire
            // this might help to make this work to maybe get less
            // demo accounts expired (trade disabled ...)
            //if( true == mod ) 
            {
                AlgorithmExpertSl( s, true, false, false, AVG );
            }
            printf( "%s T[%s] AVGA/AVGB/ASK/BID/O0/SPREAD/TICKS %s/%s/%s/%s/%s/%d/%d", 
                smod, TimeToString(g_time_local,TIME_SECONDS),
                nds(s, AVG,s.DIGITS-1),nds(s, AVG,s.DIGITS),nds(s, s.ASK,s.DIGITS), nds(s, s.BID,s.DIGITS), nds(s, o0,s.DIGITS), spread, ticks 
                 );
            s.g_avgprev = AVG;
        } // if( NormalizeDouble( o0,DIGITS ) == NormalizeDouble( BID,DIGITS ) )
    } // if( NormalizeDouble( o0,DIGITS ) != NormalizeDouble( g_o0prev,DIGITS ) )
    
       
    //14:23:01.563	EXPERT (EURUSD,M1)	T1 [15:23:01] T2 [15:23:01] ASK/BID/O0 1.24354/1.24347/1.24347
    //14:23:00.391	EXPERT (USDJPY,M1)	T1 [15:23:00] T2 [15:23:00] ASK/BID/O0 118.475/118.468/118.468
         
    //11:09:59.912	EXPERT (USDJPY,M1)	T1 [12:09:59] T2 [12:09:59] ASK/BID/O0 118.667/118.660/118.648
    //11:10:00.022	EXPERT (USDJPY,M1)	T1 [12:10:00] T2 [12:09:59] ASK/BID/O0 118.667/118.660/118.648
    //11:10:01.006	EXPERT (USDJPY,M1)	T1 [12:10:01] T2 [12:10:00] ASK/BID/O0 118.667/118.660/118.660
    //11:10:01.116	EXPERT (USDJPY,M1)	T1 [12:10:01] T2 [12:10:00] ASK/BID/O0 118.665/118.658/118.660
    
    //11:10:00.116	EXPERT (EURUSD,M1)	T1 [12:10:00] T2 [12:09:59] ASK/BID/O0 1.24318/1.24311/1.24330
    //11:10:00.225	EXPERT (EURUSD,M1)	T1 [12:10:00] T2 [12:09:59] ASK/BID/O0 1.24318/1.24311/1.24330
    //11:10:01.209	EXPERT (EURUSD,M1)	T1 [12:10:01] T2 [12:10:01] ASK/BID/O0 1.24318/1.24311/1.24311
    //11:10:01.319	EXPERT (EURUSD,M1)	T1 [12:10:01] T2 [12:10:01] ASK/BID/O0 1.24328/1.24322/1.24311
      
} // OnMillisecondTimer
//+------------------------------------------------------------------+
*/


//+------------------------------------------------------------------+
//|   m_Write2SharedMemory
//+------------------------------------------------------------------+
uint m_Write2SharedMemory(CSymbol& s, string& str_tx, string& str_rx )
{

    uint rx_err = -1;
    uint tx_err = -1;
    int id = 0 + 2*s.g_node_index;
    int type = 0;
    uint len = MQL2DLL::SM_writeWC( GSM_HANDLE, id, type, str_tx );
    if( (0<len) && (ERROR_INVALID_HANDLE != len) )
    {
        tx_err = ERROR_SUCCESS;    
    }
    else
    {
        if( 0 < VERBOSE ) dbg(s, "SM TX ERR: " + IntegerToString(ERROR_INVALID_HANDLE) + " B: " + str_tx);
        GSM_HANDLE = MQL2DLL::SM_openWC( g_computername, ACCKEY, PROPKEY, CONTKEY );
    }

    id = id+1;
    type = 0;
    str_rx = MQL2DLL::SM_readWC( GSM_HANDLE, id, type, len );
    if( (0<len) && (ERROR_INVALID_HANDLE != len) )
    {
        rx_err = ERROR_SUCCESS;    
    }
    else
    {
        if( 0 < VERBOSE ) dbg(s, "SM RX ERR: " + IntegerToString(ERROR_INVALID_HANDLE) + " B: " + str_rx);
        GSM_HANDLE = MQL2DLL::SM_openWC( g_computername, ACCKEY, PROPKEY, CONTKEY );
    }
    
    //dbg(s, "H" + IntegerToString(GSM_HANDLE) + " L" + IntegerToString(len) + " " +str_tx );

    if( (ERROR_SUCCESS==rx_err) && (ERROR_SUCCESS==tx_err) )
    {
        return (ERROR_SUCCESS);
    }
    return (-1);    
} // uint m_Write2SharedMemory(CSymbol& s, string& str_tx, string& str_rx )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_Write2Socket
//+------------------------------------------------------------------+
uint m_Write2Socket(CSymbol& s, string& str_tx, string& str_rx )
{

    uint rx_err = -1;
    uint tx_err = -1;
    switch(g_socket_inptype)
    {
        case DATA_STRING: //write string
        {
            tx_err=SocketWriteString(g_socket_client_handle,str_tx);
            if(tx_err!=ERROR_SUCCESS)
            {
                dbg(s, "SOCKET ERR: " + SocketErrorString(tx_err));
                SocketOpen(g_socket_client_handle,g_socket_host,g_socket_port);
            }
        }
        break;
        
        case DATA_STRUCT: //write struct
        {
            MqlTick last_tick;
            if(!SymbolInfoTick(s.SYMBOL,last_tick))return(-1);
            tx_err=SocketWriteStruct(g_socket_client_handle,s.SYMBOL,last_tick);
            if(tx_err!=ERROR_SUCCESS)
            {
                dbg(s, "SOCKET ERR: " + SocketErrorString(tx_err));
                SocketOpen(g_socket_client_handle,g_socket_host,g_socket_port);
            }
        }
        break;
    }// end switch
    
    //str_rx = SocketReceiveString(g_socket_client_handle);
    str_rx = SocketReceiveString(g_socket_client_handle,rx_err);
    if( (ERROR_SUCCESS==rx_err) && (ERROR_SUCCESS==tx_err) )
    {
        return (ERROR_SUCCESS);
    }
    return (-1);    
} // uint m_Write2Socket(CSymbol& s, string& str_tx, string& str_rx )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_Write2UnresolvedExternal
//+------------------------------------------------------------------+
uint m_Write2UnresolvedExternal(CSymbol& s, string& str_tx, string& str_rx )
{
    str_rx = SocketReceiveString(g_socket_client_handle);
    return (-1);    
} // uint m_Write2UnresolvedExternal(CSymbol& s, string& str_tx, string& str_rx )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_Write2Host
//+------------------------------------------------------------------+
uint m_Write2Host(CSymbol& s, string& str_tx, string& str_rx )
{
    uint err = -1;
    if( 0 == g_use_socket )
    {
        err = m_Write2SharedMemory(s,str_tx,str_rx);
    }
    if( 1 == g_use_socket )
    {
        err = m_Write2Socket(s,str_tx,str_rx);
    }
    if( 2 == g_use_socket )
    {
        err = m_Write2UnresolvedExternal(s,str_tx,str_rx);
    }
    return (err);    
} // uint m_Write2Host(CSymbol& s, string& str_tx, string& str_rx )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_GetShiftSinceDayStarted
//+------------------------------------------------------------------+
int m_GetShiftSinceDayStarted(CSymbol& s, int index )
{
    string slog = StringFormat( "ERROR m_GetShiftSinceDayStarted3(period = %s )", EnumToString((ENUM_TIMEFRAMES)s.g_normalise[index].period) ) ;
    
    MqlDateTime tm;
    datetime t0 = iTime(s.SYMBOL, s.g_normalise[index].period,0);
    if( true == ADJUSTTIME ){
        t0 = m_HourDec(t0);
    }
    TimeToStruct( t0, tm );
    
    int shift = 0;
    
    switch(index)
    {
    
        case N_INDEX_M1:
            shift = tm.hour*60 + tm.min/1; 
            break;
        case N_INDEX_M5: 
            shift = tm.hour*12 + tm.min/5; 
            break;
        case N_INDEX_M15: 
            shift = tm.hour*4 + tm.min/15; 
            break;
        case N_INDEX_M30: 
            shift = tm.hour*2 + tm.min/30; 
            break;
        case N_INDEX_H1:
            shift = tm.hour; 
            break;
        case N_INDEX_H4: 
            shift = tm.hour/4; 
            break;
        case N_INDEX_D1: 
            shift = 0; 
            break;
        default:
            dbg(s, slog );
            break;
            
    } // switch(aTf)
    
    return (shift);
    
} // int m_GetShiftSinceDayStarted(CSymbol& s )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceDayStarted for Indicators
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceDayStarted( int shift )
{
    string slog = StringFormat( "ERROR m_GetShiftSinceDayStarted(period = %s )", EnumToString((ENUM_TIMEFRAMES)Period()) ) ;
    
    MqlDateTime tm;
    datetime t0 = iTime(Symbol(),Period(),shift);
    TimeToStruct( t0, tm );
   
    switch(Period())
    {
    
        case PERIOD_M1:
            shift = tm.hour*60 + tm.min/1; 
            break;
        case PERIOD_M5: 
            shift = tm.hour*12 + tm.min/5; 
            break;
        case PERIOD_M15: 
            shift = tm.hour*4 + tm.min/15; 
            break;
        case PERIOD_H1:
            shift = tm.hour; 
            break;
        case PERIOD_H4: 
            shift = tm.hour/4; 
            break;
        case PERIOD_D1: 
            shift = 0; 
            break;
        default:
            Print(slog );
            break;
            
    } // switch(aTf)
    
    return (shift);
    
} // int m_indiGetShiftSinceDayStarted( int shift )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_GetNormtIndexFromTF
//+------------------------------------------------------------------+
int m_GetNormtIndexFromTF(ENUM_TIMEFRAMES tf)
{
    string slog = StringFormat( "ERROR m_GetNormtIndexFromTF(period = %s )", EnumToString((ENUM_TIMEFRAMES)tf) ) ;
    switch(tf)
    {
    
        case PERIOD_M1:
            return N_INDEX_M1; 
            break;
        case PERIOD_M5: 
            return N_INDEX_M5; 
            break;
        case PERIOD_M15: 
            return N_INDEX_M15; 
            break;
        case PERIOD_M30: 
            return N_INDEX_M30; 
            break;
        case PERIOD_H1:
            return N_INDEX_H1; 
            break;
        case PERIOD_H4: 
            return N_INDEX_H4; 
            break;
        case PERIOD_D1: 
            return N_INDEX_D1; 
            break;
        default:
            Print(slog);
            break;
            
    } // switch(aTf)
    
    return 0;
    
} // int m_GetNormtIndexFromTF(CSymbol& s )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_InitNormalise
//+------------------------------------------------------------------+
void m_InitNormalise(CSymbol& s, datetime dt, int index )
{
    string sym = StringSubstr( s.SYMBOL, 0 , 6 );
    
    string fname;
    ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
    
    MqlDateTime t;
    TimeToStruct(dt,t);
    string fulldate = StringFormat( "%04d%02d%02d", t.year, t.mon, t.day );
    string yeardate = StringFormat( "%04d0101",     t.year  );
    string mydate   = yeardate;
    
    int train_cnt = 0;
    int bars_per_period_per_day = 0;
    
    switch(index)
    {
    
        case N_INDEX_M1: 
            tf= PERIOD_M1;
            // 1 day
            train_cnt = N_TRAIN_CNT_IN_MIN / (PeriodSeconds(tf)/60);
            bars_per_period_per_day = 24*60;
            mydate = fulldate;
            break;
        case N_INDEX_M5: 
            tf= PERIOD_M5;
            // 1 day
            train_cnt = N_TRAIN_CNT_IN_MIN / (PeriodSeconds(tf)/60);
            bars_per_period_per_day = 24*12;
            mydate = fulldate;
            break;
        case N_INDEX_M15: 
            tf= PERIOD_M15;
            // 1 day
            train_cnt = N_TRAIN_CNT_IN_MIN / (PeriodSeconds(tf)/60);
            bars_per_period_per_day = 24*4;
            mydate = fulldate;
            break;

        case N_INDEX_M30: 
            tf= PERIOD_M30;
            // 1 day
            train_cnt = N_TRAIN_CNT_IN_MIN / (PeriodSeconds(tf)/60);
            bars_per_period_per_day = 24*2;
            mydate = fulldate;
            break;
            
        case N_INDEX_H1: 
            tf= PERIOD_H1;
            // 5 days
            train_cnt = 24*5;
            bars_per_period_per_day = 24*1;
            mydate = yeardate;
            break;
        case N_INDEX_H4: 
            tf= PERIOD_H4;
            // 5 days
            train_cnt = 6*5;
            bars_per_period_per_day = 24/4;
            mydate = yeardate;
            break;
        case N_INDEX_D1: 
            tf= PERIOD_D1;
            // 2 weeks
            train_cnt = 10;
            bars_per_period_per_day = 1;
            mydate = yeardate;
            break;
            
        default: 
            return;
    } // switch(index)
        
    fname = mydate + "_" + ConvertPeriodToString(tf) + "_" + sym;
    s.g_normalise[index].fname     = fname;
    s.g_normalise[index].period    = tf;
    s.g_normalise[index].train_cnt = train_cnt;
    s.g_normalise[index].max       = 0.0;
    s.g_normalise[index].min       = 0.0;
    s.g_normalise[index].first     = 0.0;
    s.g_normalise[index].factor    = 0.0;
    s.g_normalise[index].bars_per_period_per_day = bars_per_period_per_day; 
    s.g_normalise[index].shift_since_day_started = 0;

} // void m_InitNormalise(CSymbol& s, datetime dt, int index )

//+------------------------------------------------------------------+
//|   m_InitAlgoNormalise
//+------------------------------------------------------------------+
void m_InitAlgoNormalise(CSymbol& s, int index )
{
    
    //
    // Normalise Trading Algo start
    //
    //
    // constants    
    //
    s.g_normt.yentry = MARKET_VOLATILITY_FACTOR;
    s.g_normt.yexit  = 2*s.g_normt.yentry;
    // constants of states
    // 1) trailing stops
    s.g_normt.SP16 =  +8*s.g_normt.yexit;   //  1.6;
    s.g_normt.SP8  =  +4*s.g_normt.yexit;   //  0.8;
    s.g_normt.SP4  =  +2*s.g_normt.yexit;   //  0.4;
    s.g_normt.SP2  =  +1*s.g_normt.yexit;   //  0.2;
    s.g_normt.SP1  =  +1*s.g_normt.yentry;  //  0.1;
    s.g_normt.S0   =  0.0;        //  0.0;
    s.g_normt.SM1  =  -1*s.g_normt.yentry;  // -0.1;
    s.g_normt.SM2  =  -1*s.g_normt.yexit;   // -0.2;
    s.g_normt.SM4  =  -2*s.g_normt.yexit;   // -0.4;
    s.g_normt.SM8  =  -4*s.g_normt.yexit;   // -0.8;
    s.g_normt.SM16 =  -8*s.g_normt.yexit;   // -1.6;
    // 2) state of deals
    s.g_normt.SREADY   = "READY";
    
    // old states
    s.g_normt.SIN12    = "IN12";
    s.g_normt.SOUT1    = "OUT1";
    s.g_normt.SOUT12   = "OUT12";
    
    // new states
    s.g_normt.SIN12B   = "IN12B";
    s.g_normt.SOUT1B   = "OUT1B";
    s.g_normt.SOUT12B  = "OUT12B";
    s.g_normt.SIN12S   = "IN12S";
    s.g_normt.SOUT1S   = "OUT1S";
    s.g_normt.SOUT12S  = "OUT12S";
    
    s.g_normt.SEND     = "END";

    //
    // VARS
    //
    ArrayResize(s.g_normt.INP1,s.g_normalise[index].bars_per_period_per_day+1);
    ArrayResize(s.g_normt.INP2,s.g_normalise[index].bars_per_period_per_day+1);
    ArrayResize(s.g_normt.AMP1,s.g_normalise[index].bars_per_period_per_day+1);
    ArrayResize(s.g_normt.TM1, s.g_normalise[index].bars_per_period_per_day+1);
    ArrayInitialize(s.g_normt.INP1,0);
    ArrayInitialize(s.g_normt.INP2,0);
    ArrayInitialize(s.g_normt.AMP1,0);
    ArrayInitialize(s.g_normt.TM1, 0);
    
    // init var of trailing stop
    s.g_normt.sts      = s.g_normt.S0;
    // init var of state of deals
    s.g_normt.sd       = s.g_normt.SREADY;
    s.g_normt.sdold    = s.g_normt.SREADY;
    // init P1
    s.g_normt.pentry1 = 0;
    s.g_normt.pexit1  = 0;
    s.g_normt.psum1   = 0;
    // init P2
    s.g_normt.pentry2 = 0;
    s.g_normt.pexit2  = 0;
    s.g_normt.psum2   = 0;

    //
    // Normalise Trading Algo end
    //

} // void m_InitAlgoNormalise(CSymbol& s, int index )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_DoNormalise
//+------------------------------------------------------------------+
void m_DoNormalise( CSymbol& s, datetime dt, int index, bool aNewDayHasStarted )
{

    double d;
    int shiftStart, shiftEnd;
    ENUM_TIMEFRAMES tf = s.g_normalise[index].period;

    if( true == aNewDayHasStarted )
    {
        s.g_normalise[index].shift_since_day_started =  0;
        shiftStart = 0;
        shiftEnd   = s.g_normalise[index].train_cnt;
    }
    else
    {
        MqlDateTime tm;
        datetime t0 = iTime(s.SYMBOL, s.PERIOD,0);
        if( true == ADJUSTTIME ){
            t0 = m_HourDec(t0);
        }
        TimeToStruct( t0, tm );
        s.g_normalise[index].shift_since_day_started = m_GetShiftSinceDayStarted(s, index);
        shiftStart = s.g_normalise[index].shift_since_day_started;
        shiftEnd   = s.g_normalise[index].train_cnt + s.g_normalise[index].shift_since_day_started;
    } // if( false == aNewDayHasStarted )

    
    // TODO handle error here due to later repeatition
    int b = Bars(s.SYMBOL, tf );
    if( b < shiftEnd )
    {
        string error = "Error: " + s.SYMBOL + " TF: " + EnumToString((ENUM_TIMEFRAMES)tf) + " Bar count " + IntegerToString(b) + " is lower than required: " + IntegerToString(shiftEnd);
        dbg(s,error);
    }
    
    // calculate the neutral value "first"
    s.g_normalise[index].first = iClose(s.SYMBOL, tf, shiftStart);
    // calculate max and min   
    s.g_normalise[index].max = s.g_normalise[index].first; s.g_normalise[index].min = s.g_normalise[index].first;
    //for (int i = shift; i >= 0; i--) {
    for ( int i = shiftStart; i <= shiftEnd; i++ ) {
        d = iClose(s.SYMBOL, tf, i);
        if(s.g_normalise[index].max<d) s.g_normalise[index].max=d;
        if(s.g_normalise[index].min>d) s.g_normalise[index].min=d;
    }
    // calculate the factor
    d = MathMax(MathAbs(s.g_normalise[index].max - s.g_normalise[index].first), MathAbs(s.g_normalise[index].min - s.g_normalise[index].first));
    s.g_normalise[index].factor = N_COEFF/d;
    
    // TODO investigate difference in results between MATLAB and MT5
    // 2016.07.01 13:15:24	Core 1	2016.04.13 00:15:00   DBG EURUSD.e - 2016.04.13 00:15:00 20160413_M15_EURUSD  FIRST: 1.13870 MAX: 1.14531 MIN: 1.13606 FACTOR: 113.46 COEFF: 0.75000 IDX: 2 NEWDAY: 1 SHIFT: 0 BARS: 96
    //s.g_normalise[index].first = 1.13870;
    //s.g_normalise[index].max = 1.14531;
    //s.g_normalise[index].min = 1.13606;
    //s.g_normalise[index].factor = 113.46;
    
    //if(VERBOSE)
    {
        datetime t0 = iTime(s.SYMBOL,tf,shiftStart );
        if( true == ADJUSTTIME ){
            t0 = m_HourDec(t0);
        }
        dbg(s, TimeToString( t0, TIME_DATE | TIME_SECONDS ) + " " + s.g_normalise[index].fname + " " +
            " FIRST: " + nds(s,s.g_normalise[index].first) + " MAX: "+ nds(s,s.g_normalise[index].max) + 
            " MIN: "   + nds(s,s.g_normalise[index].min) + " FACTOR: "+ nds(s,s.g_normalise[index].factor,2)  + 
            " COEFF: " + nds(s,N_COEFF,5) +
            " IDX: "   + IntegerToString(index)+
            " NEWDAY: "+ IntegerToString(aNewDayHasStarted) +
            " SHIFT: " + IntegerToString(s.g_normalise[index].shift_since_day_started ) + 
            " BARS: "  + IntegerToString(s.g_normalise[index].bars_per_period_per_day)
            );
        // EURUSD CURR MAX: 1.34759 NEU: 1.34533 MIN: 1.34505 FACTOR: 331.86 COEFF: 0.75000
    }
    s.g_is_normalised = true;
   
} // void m_DoNormalise( CSymbol& s, datetime dt, int index, bool aNewDayHasStarted )
//+------------------------------------------------------------------+
 
//+------------------------------------------------------------------+
//| dbg2
//+------------------------------------------------------------------+
void dbg2(CSymbol& s, int ai, datetime atm, string asdold, string asdnew, double aclose, double apentry1, double apexit1, double apsum1, double apentry2, double apexit2, double apsum2  )
{
    //if( VERBOSE )
    {
        string tmstr = TimeToString(atm, TIME_DATE|TIME_SECONDS); //datestr(datenum("1970", "yyyy") + atm / 86400 );
        string str = StringFormat( "%s|i=%04d|%-5s->%-5s|c=%.4f|ps=%+4.3f|pe1=%+4.3f|px1=%+4.3f|ps1=%+4.3f|pe2=%+4.3f|px2=%+4.3f|ps2=%+4.3f", tmstr, ai, asdold, asdnew, aclose, apsum1+apsum2, apentry1, apexit1, apsum1, apentry2, apexit2, apsum2  ); 
        Print("DBG "+s.SYMBOL+" - " + str); 
    }
} // void dbg2(s, CSymbol& s, int ai, datetime atm, string asdold, string asdnew, double aclose, double apentry1, double apexit1, double apsum1, double apentry2, double apexit2, double apsum2  )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_LogNormalise
//+------------------------------------------------------------------+
void m_LogNormalise( CSymbol& s, ENUM_TIMEFRAMES tf, datetime dt, double open, double close, double high, double low )
{
    
    int index = m_GetNormtIndexFromTF(tf);
    // sanity check - there are no results yet
    if( 
        (0 == s.g_normalise[index].factor) &&
        (0 == s.g_normalise[index].first)  &&
        (0 == s.g_normalise[index].max)    &&
        (0 == s.g_normalise[index].min)
    )
    {
        return;
    }
    MqlDateTime t;
    TimeToStruct(dt,t);
    // if day of week is saturday (6) or sunday (0)
    if( 0==t.day_of_week )
    {
        if( (PERIOD_M1==tf) || (PERIOD_M5==tf) || (PERIOD_M15==tf) || (PERIOD_H1==tf) || (PERIOD_H4==tf) || (PERIOD_D1==tf) )
        {
            return;
        }
    }

    
    //--- write the actual price to a CSV file
    ResetLastError();
    // TODO INTERFACE
    string fname = s.g_normalise[index].fname + ".csv";
    int handle=FileOpen(fname,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_CSV ,';');
    if(handle!=INVALID_HANDLE)
    {
        double nopen  = m_Price2Neural( s, index, open );
        double nclose = m_Price2Neural( s, index, close );
        double nhigh  = m_Price2Neural( s, index, high );
        double nlow   = m_Price2Neural( s, index, low );
        if( true == FileSeek ( handle, 0, SEEK_END ) ) 
        {
            if( true == FileIsEnding( handle ) )
            {
                FileWrite( handle,/*TimeToString(dt,TIME_DATE|TIME_SECONDS),*/IntegerToString(dt),
                    nds(s,s.ASK), nds(s,s.BID), 
                    nds(s,open),nds(s,close),nds(s,high),nds(s,low),
                    nds(s,nopen),nds(s,nclose),nds(s,nhigh),nds(s,nlow) 
                    );
                FileFlush( handle );
            }
        }
        FileClose( handle);
    }
    else
    {
        // TODO - re-think the error handling here
    } // if(handle!=INVALID_HANDLE)
    
    //_Log( s, "log.txt", "abc" );
    

} // void m_LogNormalise( CSymbol& s, int index, datetime dt, double open, double, close, double high, double low )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  m_Price2Neural
//+------------------------------------------------------------------+
double m_Price2Neural( CSymbol& s, int index, double price )
{
    //double neural = (price-s.g_normalise[index].first)*s.g_normalise[index].factor;
    double neural = (price-iOpen(s.SYMBOL,PERIOD_D1/*D1*/,0))/s.POINT;
    //return (m_Clamp(neural));
    return (neural);
} // double m_Price2Neural( double price, int index )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_Neural2Price
//+------------------------------------------------------------------+
double m_Neural2Price( CSymbol& s, int index, double neural )
{
   //double price = (neural/s.g_normalise[index].factor)+s.g_normalise[index].first;
   double price = neural*s.POINT+iOpen(s.SYMBOL,PERIOD_D1/*D1*/,0);
   return (price);
} // double m_Neural2Price( double neural, int index )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_Clamp
//+------------------------------------------------------------------+
double m_Clamp( double d )
{
    d = MathMin( d, 1 );
    d = MathMax( d, -1 );
    return(d);
} // double m_Clamp( double d )
//+------------------------------------------------------------------+



//
// UTILITY FUNCTIONS PER ALGORITHM
//
//+------------------------------------------------------------------+
//| UTILITY FUNCTIONS PER ALGORITHM
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_CalcOpenPrice(CSymbol& s) 
//+------------------------------------------------------------------+
double m_CalcOpenPrice(CSymbol& s) 
{

    // TODO review me
    //double open_price =  NormalizeDouble( iOpen(s.SYMBOL,Period(),0) , s.DIGITS ); 
    double open_price =  NormalizeDouble( (s.BID + (s.ASK-s.BID)/2) , s.DIGITS ); 
    return open_price;

} // m_CalcOpenPrice(CSymbol& s)




























//+------------------------------------------------------------------+
//| m_DoAlgoNormalise2
//+------------------------------------------------------------------+
void m_DoAlgoNormalise2( CSymbol& s, int shift, bool aNewDayHasStarted )
{
    // sanity checks
    // sanity checks for arrays
    if( 1 > shift )
    {
return;
    }
    
    //
    // AMP FOR TS
    //
    
    // > SP16
    if( s.g_normt.INP1[shift] > s.g_normt.SP16 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SP16;
    
    // < SM16
    } else if( s.g_normt.INP1[shift] < s.g_normt.SM16 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SM16;

    // > SP8
    } else if( s.g_normt.INP1[shift] > s.g_normt.SP8 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SP8;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SP16 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SP16;
        }
    
    // < SM8
    } else if( s.g_normt.INP1[shift] < s.g_normt.SM8 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SM8;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SM16 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SM16;
        }
    
    // > SP4
    } else if( s.g_normt.INP1[shift] > s.g_normt.SP4 ) { 
        
        s.g_normt.AMP1[shift] = s.g_normt.SP4;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SP8 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SP8;
        }
    
    // < SM4
    } else if( s.g_normt.INP1[shift] < s.g_normt.SM4 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SM4;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SM8 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SM8;
        }
    
    // > SP2
    } else if( s.g_normt.INP1[shift] > s.g_normt.SP2 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SP2;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SP4 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SP4;
        }
    
    // < SM2
    } else if( s.g_normt.INP1[shift] < s.g_normt.SM2 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SM2;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SM4 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SM4;
        }

    // > SP1
    } else if( s.g_normt.INP1[shift] > s.g_normt.SP1 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SP1;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SP2 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SP2;
        }
        
    // < SM1
    } else if( s.g_normt.INP1[shift] < s.g_normt.SM1 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.SM1;
        if( s.g_normt.AMP1[shift-1] == s.g_normt.SM2 ) {
            s.g_normt.AMP1[shift] = s.g_normt.SM2;
        }
        
    // > S0
    } else if( s.g_normt.INP1[shift] > s.g_normt.S0 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.S0;
        if( (s.g_normt.AMP1[shift-1] == s.g_normt.SP1) || (s.g_normt.AMP1[shift-1] == s.g_normt.SP2) ) {
            s.g_normt.AMP1[shift] = s.g_normt.SP1;
        }
        
    // < S0
    } else if( s.g_normt.INP1[shift] < s.g_normt.S0 ) {
        
        s.g_normt.AMP1[shift] = s.g_normt.S0;
        if( (s.g_normt.AMP1[shift-1] == s.g_normt.SM1) || (s.g_normt.AMP1[shift-1] == s.g_normt.SM2) ) {
            s.g_normt.AMP1[shift] = s.g_normt.SM1;
        }
    } else {        
    
        s.g_normt.AMP1[shift] = s.g_normt.S0;
        
    } // if( s.g_normt.INP1[shift] > SP16 )
    
    
    
    //
    // SREADY
    //
    if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SREADY ) )
    {
    
        // SREADY -> SIN12B
        // > SP1
        if( s.g_normt.INP1[shift] > s.g_normt.SP1 ) 
        {
            
            s.g_normt.pentry1 = s.g_normt.INP1[shift];
            s.g_normt.pentry2 = s.g_normt.INP1[shift];
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SIN12B;
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pexit1  = 0;
            s.g_normt.pexit2  = 0;
            
        } // if( s.g_normt.INP1[shift] > s.g_normt.SP1 ) 
        
        // SREADY -> SIN12S
        // < SM1
        if( s.g_normt.INP1[shift] < s.g_normt.SM1 ) 
        {
            
            s.g_normt.pentry1 = s.g_normt.INP1[shift];
            s.g_normt.pentry2 = s.g_normt.INP1[shift];
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SIN12S;
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pexit1  = 0;
            s.g_normt.pexit2  = 0;
    
        } // if( s.g_normt.INP1[shift] < s.g_normt.SM1 ) 
    
    } // SREADY
    
    //
    // B
    //
    // SIN12B
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SIN12B ) )
    {

        // SIN12B -> SREADY
        // < S0
        if( s.g_normt.INP1[shift] < s.g_normt.S0 ) 
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SREADY;
            // calc losses
            s.g_normt.pexit1= s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pentry1-s.g_normt.pexit1);
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pentry2-s.g_normt.pexit2);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
            s.g_normt.pentry2 = 0;
            s.g_normt.pexit2  = 0;
            
        } // if( s.g_normt.INP1[shift] < s.g_normt.S0 )

        // SIN12S -> SOUT1B
        // > SP2
        if( s.g_normt.INP1[shift] > s.g_normt.SP2 ) 
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SOUT1B;
            // calc losses
            s.g_normt.pexit1 = s.g_normt.INP1[shift];
            s.g_normt.psum1  = s.g_normt.psum1 + (s.g_normt.pexit1-s.g_normt.pentry1);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, 
                        s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
        
        } // if( s.g_normt.INP1[shift] > s.g_normt.SP2 )      
    
    } // SIN12B

    // SOUT1B    
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT1B ) )
    {
    
        // SOUT1B -> SREADY
        // < S0
        if( s.g_normt.INP1[shift] < s.g_normt.S0 ) 
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SREADY;
            // calc losses
            s.g_normt.pexit1= s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pentry1-s.g_normt.pexit1);
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pentry2-s.g_normt.pexit2);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
            s.g_normt.pentry2 = 0;
            s.g_normt.pexit2  = 0;
            
        } // if( s.g_normt.INP1[shift] < s.g_normt.S0 ) 
        
        // SOUT1B -> SOUT12B
        if( true == SOUT1TRAILINGSTOP )
        {
            if( s.g_normt.AMP1[shift] < s.g_normt.AMP1[shift-1] ) 
            {
                // set state
                s.g_normt.sdold = s.g_normt.sd;
                s.g_normt.sd = s.g_normt.SOUT12B;
                s.g_normt.pexit2= s.g_normt.INP1[shift];
                s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pentry2-s.g_normt.pentry2);
                // dbg message
                dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
                // reset vars
                s.g_normt.pentry1 = 0;
                s.g_normt.pexit1  = 0;
                s.g_normt.pentry2 = 0;
                s.g_normt.pexit2  = 0;
            } // if( s.g_normt.AMP1[shift] < s.g_normt.AMP1[shift-1] ) 
        } // if( true == SOUT1TRAILINGSTOP )
            
    } // SOUT1B 
    
    // SOUT12B
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT12B ) )
    {

        // SOUT12B -> SREADY
        // < S0
        if( s.g_normt.INP1[shift] < s.g_normt.S0 ) 
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SREADY;
            // calc losses
            s.g_normt.pexit1= s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pentry1-s.g_normt.pexit1);
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pentry2-s.g_normt.pexit2);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
            s.g_normt.pentry2 = 0;
            s.g_normt.pexit2  = 0;
            
        } // if( s.g_normt.INP1[shift] < s.g_normt.S0 ) 
    
    } // SOUT12B

    //
    // S
    //
    // SIN12S
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SIN12S ) )
    {
        // SIN12S -> SREADY
        // > S0
        if( s.g_normt.INP1[shift] > s.g_normt.S0 )
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SREADY;
            // calc losses
            s.g_normt.pexit1= s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pexit1-s.g_normt.pentry1);
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pexit2-s.g_normt.pentry2);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
            s.g_normt.pentry2 = 0;
            s.g_normt.pexit2  = 0;
                
        }  // if( s.g_normt.INP1[shift] > s.g_normt.S0 )
        
        // SIN12S -> SOUT1S
        // < SM2
        if( s.g_normt.INP1[shift] < s.g_normt.SM2 ) 
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SOUT1S;
            // calc losses
            s.g_normt.pexit1 = s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 + (s.g_normt.pentry1-s.g_normt.pexit1);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
                
        } // if( s.g_normt.INP1[shift] < s.g_normt.SM2 ) 
    
    } // SIN12S

    // SOUT1S    
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT1S ) )
    {

        // SOUT1S -> SREADY
        // > S0
        if( s.g_normt.INP1[shift] > s.g_normt.S0 )
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SREADY;
            // calc losses
            s.g_normt.pexit1= s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pexit1-s.g_normt.pentry1);
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pexit2-s.g_normt.pentry2);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
            s.g_normt.pentry2 = 0;
            s.g_normt.pexit2  = 0;
                
        }  // if( s.g_normt.INP1[shift] > s.g_normt.S0 )       
        
        if( true == SOUT1TRAILINGSTOP )
        {
            if( s.g_normt.AMP1[shift] > s.g_normt.AMP1[shift-1] ) 
            {
                // set state
                s.g_normt.sdold = s.g_normt.sd;
                s.g_normt.sd = s.g_normt.SOUT12S;
                s.g_normt.pexit2= s.g_normt.INP1[shift];
                s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pexit2-s.g_normt.pentry2);
                // dbg message
                dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
                // reset vars
                s.g_normt.pentry1 = 0;
                s.g_normt.pexit1  = 0;
                s.g_normt.pentry2 = 0;
                s.g_normt.pexit2  = 0;
            } // if( s.g_normt.AMP1[shift] > s.g_normt.AMP1[shift-1] ) 
        } // if( true == SOUT1TRAILINGSTOP )
    
    } // SOUT1S
    
    // SOUT12S
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT12S ) )
    {

        // SOUT12S -> SREADY
        // > S0
        if( s.g_normt.INP1[shift] > s.g_normt.S0 )
        {
            
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SREADY;
            // calc losses
            s.g_normt.pexit1= s.g_normt.INP1[shift];
            s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pexit1-s.g_normt.pentry1);
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pexit2-s.g_normt.pentry2);
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
            // reset vars
            s.g_normt.pentry1 = 0;
            s.g_normt.pexit1  = 0;
            s.g_normt.pentry2 = 0;
            s.g_normt.pexit2  = 0;
                
        }  // if( s.g_normt.INP1[shift] > s.g_normt.S0 )       
    
    } // SOUT12S
    
    //
    // SEND
    //
    else if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SEND ) )
    {

        // SEND -> SREADY
        // set state
        s.g_normt.sdold = s.g_normt.sd;
        s.g_normt.sd = s.g_normt.SREADY;
    
    } // SEND
    
    //
    // ERROR
    //
    else
    {
        Print( "ERROR STATE m_DoAlgoNormalise2 [" + s.g_normt.sd + "]" );
return;        
    } // if( 0 == StringCompare( s.g_normt.sd, s.g_normt.SREADY ) )   
    
    
    // a new day has arrived
    if( true == aNewDayHasStarted )
    {
        // if deal still open
        if(    (0 == StringCompare( s.g_normt.SIN12B, s.g_normt.sd )) || (0 == StringCompare( s.g_normt.SOUT1B, s.g_normt.sd ))  
            || (0 == StringCompare( s.g_normt.SIN12S, s.g_normt.sd )) || (0 == StringCompare( s.g_normt.SOUT1S, s.g_normt.sd )) ) 
        {
            // set state
            s.g_normt.sdold = s.g_normt.sd;
            s.g_normt.sd = s.g_normt.SEND;
            // calc losses - TODO review make me easier - depending on state
            if( 0 != s.g_normt.pentry1 ) {
                s.g_normt.pexit1= s.g_normt.INP1[shift];
                if( s.g_normt.S0 < s.g_normt.pentry1 ) {
                    if( s.g_normt.pexit1 > s.g_normt.pentry1 ) {
                        s.g_normt.psum1 = s.g_normt.psum1 + (s.g_normt.pexit1-s.g_normt.pentry1);
                    } else {
                        s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pentry1-s.g_normt.pexit1);
                    }
                }
                if( s.g_normt.S0 > s.g_normt.pentry1 ) {
                    if( s.g_normt.pexit1 < s.g_normt.pentry1 ) {
                        s.g_normt.psum1 = s.g_normt.psum1 + (s.g_normt.pentry1-s.g_normt.pexit1);
                    } else {
                        s.g_normt.psum1 = s.g_normt.psum1 - (s.g_normt.pexit1-s.g_normt.pentry1);
                    }
                }
            }
            s.g_normt.pexit2= s.g_normt.INP1[shift];
            if( s.g_normt.S0 < s.g_normt.pentry2 ) {
                if( s.g_normt.pexit2 > s.g_normt.pentry2 ) {
                    s.g_normt.psum2 = s.g_normt.psum2 + (s.g_normt.pexit2-s.g_normt.pentry2);
                } else {
                    s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pentry2-s.g_normt.pexit2);
                }
            }
            if( s.g_normt.S0 > s.g_normt.pentry2 ) {
                if( s.g_normt.pexit2 < s.g_normt.pentry2 ) {
                    s.g_normt.psum2 = s.g_normt.psum2 + (s.g_normt.pentry2-s.g_normt.pexit2);
                } else {
                    s.g_normt.psum2 = s.g_normt.psum2 - (s.g_normt.pexit2-s.g_normt.pentry2);
                }
            }
            // dbg message
            dbg2(s,shift, s.g_normt.TM1[shift], s.g_normt.sdold, s.g_normt.sd, s.g_normt.INP2[shift], s.g_normt.pentry1, s.g_normt.pexit1, s.g_normt.psum1, s.g_normt.pentry2, s.g_normt.pexit2, s.g_normt.psum2 );
        } // if(    (0 == StringCompare( s.g_normt.SIN12B, s.g_normt.sd )) || (0 == StringCompare( s.g_normt.SOUT1B, s.g_normt.sd )) ) 
        
        // return values
        s.g_normt.sum  += s.g_normt.psum1+s.g_normt.psum2;
        s.g_normt.sum1 += s.g_normt.psum1;
        s.g_normt.sum2 += s.g_normt.psum2;
        string adate = TimeToString( s.g_normt.TM1[shift] , TIME_DATE | TIME_SECONDS );  // mydate = sprintf( '%04d%02d%02d', years, months, days);
        string retstr = StringFormat("(%03d,%4.1f,%4.1f,%4.1f)[%4.3f,%4.3f,%4.3f,this] = myfft3( %s,%3s,%s,adjusttime=%d,asout1trailingstop=%d );",
                s.g_test_day_cnt, s.g_normt.sum, s.g_normt.sum1, s.g_normt.sum2, 
                s.g_normt.psum1+s.g_normt.psum2, s.g_normt.psum1, s.g_normt.psum2, 
                adate, EnumToString((ENUM_TIMEFRAMES)s.PERIOD), 
                s.SYMBOL, ADJUSTTIMEENABLED, SOUT1TRAILINGSTOP ); 
        dbg( s, retstr ); 
    } // if( true == aNewDayHasStarted ) 
    
        
    datetime t0 = iTime(s.SYMBOL, s.PERIOD, 0);
    if( true == ADJUSTTIME )
    {
        t0 = m_HourDec( t0 );
    }
    // TODO NORM review me the TM1 comparison
    if( (0 != StringCompare( s.g_normt.sdold, s.g_normt.sd ))
        && ( t0 == s.g_normt.TM1[shift] ) )
    {
        string retstr = StringFormat("STATE CHANGE: %6s -> %6s  p=%s t=%s",
                s.g_normt.sdold, s.g_normt.sd, nds(s,s.g_normt.INP2[shift]), 
                TimeToString( s.g_normt.TM1[shift], TIME_DATE|TIME_SECONDS ) ); 
        dbg( s, retstr ); 
        
        // -> SEND
        // -> SOUT12
        // -> SREADY
        // close any open position in the new states END, OUT12 and READY
        if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SEND ))
            || (0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT12B ))
            || (0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT12S ))
            || (0 == StringCompare( s.g_normt.sd, s.g_normt.SREADY ))
          )
        {
            m_PositionClose( s, MAGIC_POSITION, s.g_normt.sd, true );
        } // if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SEND ))
        
        // -> SIN12B
        if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SIN12B )) )
        {
            double lot = 0.0; int pend_num = 2;
            if( true == m_Calculate_Lot(s,lot,pend_num) )
            {
                lot = 0.02;
                m_PositionOpenBuy (s,lot,s.g_normt.sd);
            }
        } // if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SIN12B )) )
        
        // -> SIN12S
        if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SIN12S )) )
        {
            double lot = 0.0; int pend_num = 2;
            if( true == m_Calculate_Lot(s,lot,pend_num) )
            {
                lot = 0.02;
                m_PositionOpenSell(s,lot,s.g_normt.sd);
            }
        } // if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SIN12S )) )
        
        // -> SOUT1B
        if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT1B )) )
        { 
            double lot = 0.0;
            if( true == PositionSelect(s.SYMBOL) )
            {
                if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
                {
                    lot = PositionGetDouble(POSITION_VOLUME)/2;
                    lot = 0.01;
                    m_PositionOpenSell(s,lot,s.g_normt.sd);
                }
            }
        } // if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT1B )) )
        
        // -> SOUT1S
        if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT1S )) )
        { 
            double lot = 0.01;
            if( true == PositionSelect(s.SYMBOL) )
            {
                if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
                {
                    lot = PositionGetDouble(POSITION_VOLUME)/2;
                    lot = 0.01;
                    m_PositionOpenBuy (s,lot,s.g_normt.sd);
                }
            }
        } // if(    (0 == StringCompare( s.g_normt.sd, s.g_normt.SOUT1S )) )
        
    } // if( (0 != StringCompare( s.g_normt.sdold, s.g_normt.sd ))
        
    // a new day has arrived
    if( true == aNewDayHasStarted )
    {
        int nind = m_GetNormtIndexFromTF(s.PERIOD);
        m_InitNormalise( s, g_time_local, nind );
        m_InitAlgoNormalise( s, nind );
        m_DoNormalise( s, g_time_local, nind, true /*aNewDayHasStarted*/ );
    
    } // if( true == newday)
    
    // TODO NORM - review - reset the states
    s.g_normt.sdold = s.g_normt.sd;

} // void m_DoAlgoNormalise2( CSymbol& s, int shift, aNewDayHasStarted )
//+------------------------------------------------------------------+


// TODO DUPLICATE - implement me in library
bool FilterSymbols( const string a_symbol )
{
    // TODO on demo account somehow the symbol is not ECN anymore
    // only slect ECN tradable symbols - EURUSD.e
    
    int tsl = (int)SymbolInfoInteger(a_symbol,SYMBOL_TRADE_STOPS_LEVEL);
    if( 0 < tsl ) 
    {
        // e.g. AUDCHF got 60 points of stoplevel return here and don't use the symbol
        return (true);
    }
    else
    {
        int len = StringLen(a_symbol);
        if( 6 != len )
        {
            return (true);
        }

        // basic table to exclude roboforex stuff
        if( 0 == StringCompare( a_symbol, "EURPLN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURTRY" ) ){ return (true); }
        //if( 0 == StringCompare( a_symbol, "USDCNH" ) ){ return (true); }
        //if( 0 == StringCompare( a_symbol, "USDMXN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDPLN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDTRY" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDRUB" ) ){ return (true); }
        //if( 0 == StringCompare( a_symbol, "USDZAR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAGUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAUUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GLDUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAUEUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAGEUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XPTUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XPDUSD" ) ){ return (true); }
        
        // extended table to exclude mt5 metatrader stuff
        if( 0 == StringCompare( a_symbol, "USDSEK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDHKD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDSGD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDNOK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDDKK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCZK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDHUF" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDRUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURCZK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURDKK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURHKD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURHUF" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURMXN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURNOK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURRUB" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURSEK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURZAR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPNOK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPPLN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPSEK" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPSGD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPZAR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NZDSGD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "SGDJPY" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "RGBITR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "IGST03" ) ){ return (true); }
        

        if( 0 == StringCompare( a_symbol, "BTCUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "ETHUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XRPUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "DSHUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "LTCUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EOSUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "BTCEUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "ETHEUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "LKOD.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "OGZD.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "MNOD.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "SBER.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NVTK.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "MGNT.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "SVST.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "ATAD.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "ROSN.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "PLZL.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "SGGD.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "FIVE.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NLMK.L" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBXUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "LTCBTC" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "ETHBTC" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XBTUSD" ) ){ return (true); }
        
        return (false);
    }
    
    int len = StringLen(a_symbol);
    
    if( 8 == len )
    {
        if(
           ( 'e' != StringGetCharacter(a_symbol,len-1) )
         ||( '.' != StringGetCharacter(a_symbol,len-2) )
        )
        {
            return (true);
        }
        
        // basic table - but less performance at M15 OPT(0/0/1)
        if( 0 == StringCompare( a_symbol, "AUDCAD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "AUDNZD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "CADCHF.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "CHFJPY.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURCHF.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPNZD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPAUD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NZDCAD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NZDJPY.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCAD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCHF.e" ) ){ return (true); }
    
        // extended table
        if( 0 == StringCompare( a_symbol, "EURPLN.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURTRY.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCNH.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDMXN.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDPLN.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDTRY.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDRUB.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDZAR.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAGUSD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAUUSD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GLDUSD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAUEUR.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAGEUR.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XPTUSD.e" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XPDUSD.e" ) ){ return (true); }
        
    }
    else if ( 6 == len )
    {
        // basic table - but less performance at M15 OPT(0/0/1)
        if( 0 == StringCompare( a_symbol, "AUDCAD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "AUDNZD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "CADCHF" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "CHFJPY" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURCHF" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPNZD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GBPAUD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NZDCAD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "NZDJPY" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCAD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCHF" ) ){ return (true); }
    
        // extended table
        if( 0 == StringCompare( a_symbol, "EURPLN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "EURTRY" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDCNH" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDMXN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDPLN" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDTRY" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDRUB" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "USDZAR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAGUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAUUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "GLDUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAUEUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XAGEUR" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XPTUSD" ) ){ return (true); }
        if( 0 == StringCompare( a_symbol, "XPDUSD" ) ){ return (true); }
    }
    else
    {
        return (true);
    }
    
    
    return (false);
} // bool FilterSymbols( const string a_symbol )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|     m_GetLastDealHistory() 
//+------------------------------------------------------------------+
bool m_GetFromLastDealHistory( CSymbol& s, long lDtStart, string & sStatus, long & lTradeDt, double & dTradeOP, double & dDiff, double & dVolume ) 
{

    bool bRet = false;
    long lDtEnd = lDtStart + PeriodSeconds(s.PERIOD) -1;
    /*if( g_time_current < lDtEnd ) {
        lDtEnd = g_time_current;
    }*/
    int deal_cnt = 0;
    
    if( true == HistorySelect(lDtStart, lDtEnd) )    
    {
        int total = HistoryDealsTotal();
    
        for (int j=0; j<total; j++)
        {
            ulong d_ticket = HistoryDealGetTicket(j);
            if (d_ticket>0)  
            {
                if( s.SYMBOL != HistoryDealGetString(d_ticket,DEAL_SYMBOL) )
                {
                    continue;
                }
    
                deal_cnt++;
                lTradeDt = (long)HistoryDealGetInteger(d_ticket,DEAL_TIME);
                dTradeOP = HistoryDealGetDouble(d_ticket,DEAL_PRICE);
                dDiff    = HistoryDealGetDouble(d_ticket,DEAL_PROFIT);
                dVolume  = HistoryDealGetDouble(d_ticket,DEAL_VOLUME);
                ENUM_DEAL_TYPE dType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(d_ticket,DEAL_TYPE);
                if( (ENUM_DEAL_TYPE)DEAL_TYPE_BUY == (ENUM_DEAL_TYPE)dType ){
                    sStatus = "B";
                }
                if( (ENUM_DEAL_TYPE)DEAL_TYPE_SELL == (ENUM_DEAL_TYPE)dType ){
                    sStatus = "S";
                }
                m_log_history_to_sql(   s, "ABC_D", g_time_local,
                                        HistoryDealGetInteger(d_ticket,DEAL_TIME_MSC),lTradeDt,
                                        HistoryDealGetInteger(d_ticket,DEAL_ORDER),d_ticket,EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(d_ticket,DEAL_TYPE)),EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d_ticket,DEAL_ENTRY)),
                                        dVolume,dTradeOP,0.0,0.0,dDiff,0.0,
                                        HistoryDealGetString(d_ticket,DEAL_COMMENT),
                                        "", HistoryDealGetDouble(d_ticket,DEAL_COMMISSION), HistoryDealGetDouble(d_ticket,DEAL_SWAP)
                                    );
            } // if (d_ticket>0)
        } // for (int j=0; j<tot_deals; j++)
    } // if( true == HistorySelect(lDtStart, lDtEnd) )    
    
    if( 1 == deal_cnt ){
        bRet = true;
    }
    
    return ( bRet );
    
} // bool m_GetFromLastDealHistory( CSymbol& s, long lDtStart, long & lTradeDt, double & dTradeOP, double & dDiff, double & dVolume ) 
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+  
//|     m_update_03_EXE_2
//|       NOTE: s.g_t0_03_Exe = t02Exes.DT;
//|         is set within the function

//+------------------------------------------------------------------+  
void m_update_03_EXE_2( CSymbol& s, const long t0 )
{

    CSVTable_Sig_or_Exe t02Sigx[];
    int t0_index = -1;
    long lret_last_t0 = m_Read_SIG_or_EXE_CSV_File(s.g_02_SIGx_fN, t02Sigx, t0, t0_index );
    int t02SigxSize = ArraySize(t02Sigx);
    CSVTable_Sig_or_Exe t03Exex[];
    ArrayResize(t03Exex,t02SigxSize +1 );     
    string line;
    
    if( (0 < t02SigxSize) && ( 0 != lret_last_t0) ) {
    
        // TODO implement some error handling here with
        //   lret_last_t0, t0, t0_index 
        //   but for now just go on and add the one line
        int fH_03_EXEx = INVALID_HANDLE;
        fH_03_EXEx=FileOpen(s.g_03_EXEx_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_TXT);
        if(fH_03_EXEx!=INVALID_HANDLE) {
            //FileSeek ( fhandle, 0, SEEK_END );
            // INTERFACE to CSV
            //  DT            STAT	TradeDT	    TradeOP     DIFF    SUMUP
            //  1590760800    B	    1590757200	1,11327		-22		31
            
            //
            // first write the existing t02Sigx[i]
            //
            for( int i = 0; i < t02SigxSize; i++ ) {
            
                t03Exex[i].DT = t02Sigx[i].DT;
                t03Exex[i].STAT = "";
                t03Exex[i].TradeDT = 0;
                t03Exex[i].TradeOP = 0;
                t03Exex[i].DIFF = 0;

                double tradedLot = 0.0;
                if( true == m_GetFromLastDealHistory(s,t03Exex[i].DT,t03Exex[i].STAT,t03Exex[i].TradeDT,t03Exex[i].TradeOP,t03Exex[i].DIFF,tradedLot) ) {
                } else {
                    t03Exex[i].STAT = "";
                    t03Exex[i].TradeDT = 0;
                    t03Exex[i].TradeOP = 0;
                    t03Exex[i].DIFF = 0;
                }
            
                if( 0 == i ) {
                    t03Exex[i].SUMUP = 100;
                } 
                if( 0 < i ) {
                    t03Exex[i].SUMUP = t03Exex[i].DIFF + t03Exex[i-1].SUMUP;
                    
                    // change to STAT "E" exit
                    //
                    // TODO make understandable or document
                    //  for now compare with previous entry of 02_SIGx
                    
                    if( ("S" == t03Exex[i].STAT) && ("B" == t02Sigx[i-1].STAT) && (0.01 == tradedLot) ){
                        t03Exex[i].STAT = "E";
                    }
                    if( ("B" == t03Exex[i].STAT) && ("S" == t02Sigx[i-1].STAT) && (0.01 == tradedLot) ){
                        t03Exex[i].STAT = "E";
                    }
                    
                }    
                
            
                line = StringFormat( "%s;%s;%s;%s;%s;%s\n",
                        IntegerToString(t03Exex[i].DT),
                        t03Exex[i].STAT,
                        IntegerToString(t03Exex[i].TradeDT),
                        nds(s,t03Exex[i].TradeOP),
                        nds(s,t03Exex[i].DIFF,2),
                        nds(s,t03Exex[i].SUMUP,2) );
                FileWriteString( fH_03_EXEx, line );
                FileFlush( fH_03_EXEx );
                
            } // for( int i = 0; i < t02SigxSize; i++ )

            FileClose(fH_03_EXEx);

            //
            // at the end write the new t03Exes
            //
            int fH_03_EXEs = INVALID_HANDLE;
            fH_03_EXEs=FileOpen(s.g_03_EXEs_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_TXT);
            if(fH_03_EXEs!=INVALID_HANDLE) {
                FileWriteString( fH_03_EXEs, line );
                FileClose(fH_03_EXEs);
            } // if(fH_03_EXEs!=INVALID_HANDLE)*/

            /*            
            //
            // at the end write the new t03Exes
            //
            line = StringFormat( "%s;%s;%s;%s;%s;%s\n",
                    IntegerToString(t03Exes.DT),
                    t03Exes.STAT,
                    IntegerToString(t03Exes.TradeDT),
                    nds(s,t03Exes.TradeOP),
                    nds(s,t03Exes.DIFF,2),
                    nds(s,t03Exes.SUMUP,2) );
            FileWriteString( fH_03_EXEx, line );
            FileClose(fH_03_EXEx);

            int fH_03_EXEs = INVALID_HANDLE;
            fH_03_EXEs=FileOpen(s.g_03_EXEs_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_TXT);
            if(fH_03_EXEs!=INVALID_HANDLE) {
                FileWriteString( fH_03_EXEs, line );
                FileClose(fH_03_EXEs);
            } // if(fH_03_EXEs!=INVALID_HANDLE)
            */
            
            // write 03_EXE_T0
            int fH_03_EXE_T0=FileOpen(s.g_03_EXE_T0_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
            if( fH_03_EXE_T0!=INVALID_HANDLE) {
                FileWrite( fH_03_EXE_T0, IntegerToString(t0) );
                FileClose( fH_03_EXE_T0);
            }
            
            // write 03_EXE_TC
            int fH_03_EXE_TC=FileOpen(s.g_03_EXE_TC_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
            if( fH_03_EXE_TC!=INVALID_HANDLE) {
                FileWrite( fH_03_EXE_TC, IntegerToString((datetime)TimeCurrent()) );
                FileClose( fH_03_EXE_TC);
            }

            //
            // TODO implement error handling here
            //      we know that there has been an update
            //      but we don't know the status result
            //
            s.g_03_EXE_t0 = lret_last_t0;
            
        } // if(fH_03_EXEx!=INVALID_HANDLE)*/
        
    }  // if( (0 < t02SigxSize) && ( 0 != lret_last_t0) )

} // void m_update_03_EXE_2( CSymbol& s, const long t0, CSVTable_Sig_or_Exe& t03Exes )
//+------------------------------------------------------------------+  




//+------------------------------------------------------------------+  
//|     m_update_03_EXE
//|       NOTE: s.g_t0_03_Exe = t02Exes.DT;
//|         is set within the function

//+------------------------------------------------------------------+  
void m_update_03_EXE( CSymbol& s, const long t0, CSVTable_Sig_or_Exe& t02Exes )
{

    CSVTable_Sig_or_Exe t02Exex[];
    int t0_index = -1;
    long lret_last_t0 = m_Read_SIG_or_EXE_CSV_File(s.g_03_EXEx_fN, t02Exex, t0, t0_index );
    int t02ExexSize = ArraySize(t02Exex);
    if( 0 == t02ExexSize ) {
        t02Exes.SUMUP = 100;
    } 
    if( 0 < t02ExexSize ) {
        t02Exes.SUMUP = t02Exes.DIFF + t02Exex[t02ExexSize-1].SUMUP;
    }    
    if( (0 < t02ExexSize) || ( (0 == t02ExexSize) && (0 == lret_last_t0) ) ) {
    
        // TODO implement some error handling here with
        //   lret_last_t0, t0, t0_index 
        //   but for now just go on and add the one line
        int fH_03_EXEx = INVALID_HANDLE;
        fH_03_EXEx=FileOpen(s.g_03_EXEx_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_TXT);
        if(fH_03_EXEx!=INVALID_HANDLE) {
            //FileSeek ( fhandle, 0, SEEK_END );
            // INTERFACE to CSV
            //  DT            STAT	TradeDT	    TradeOP     DIFF    SUMUP
            //  1590760800    B	    1590757200	1,11327		-22		31
            
            //
            // first write the existing t02Exex[i]
            //
            string line;
            for( int i = 0; i < t02ExexSize; i++ ) {
                line = StringFormat( "%s;%s;%s;%s;%s;%s\n",
                        IntegerToString(t02Exex[i].DT),
                        t02Exex[i].STAT,
                        IntegerToString(t02Exex[i].TradeDT),
                        nds(s,t02Exex[i].TradeOP),
                        nds(s,t02Exex[i].DIFF,2),
                        nds(s,t02Exex[i].SUMUP,2) );
                FileWriteString( fH_03_EXEx, line );
                FileFlush( fH_03_EXEx );
            } // for( int i = 0; i < t02ExexSize; i++ )
            
            //
            // at the end write the new t02Exes
            //
            line = StringFormat( "%s;%s;%s;%s;%s;%s\n",
                    IntegerToString(t02Exes.DT),
                    t02Exes.STAT,
                    IntegerToString(t02Exes.TradeDT),
                    nds(s,t02Exes.TradeOP),
                    nds(s,t02Exes.DIFF,2),
                    nds(s,t02Exes.SUMUP,2) );
            FileWriteString( fH_03_EXEx, line );
            FileClose(fH_03_EXEx);

            int fH_03_EXEs = INVALID_HANDLE;
            fH_03_EXEs=FileOpen(s.g_03_EXEs_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_TXT);
            if(fH_03_EXEs!=INVALID_HANDLE) {
                FileWriteString( fH_03_EXEs, line );
                FileClose(fH_03_EXEs);
            } // if(fH_03_EXEs!=INVALID_HANDLE)*/
            
            // write 03_EXE_T0
            int fH_03_EXE_T0=FileOpen(s.g_03_EXE_T0_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
            if( fH_03_EXE_T0!=INVALID_HANDLE) {
                FileWrite( fH_03_EXE_T0, IntegerToString(t0) );
                FileClose( fH_03_EXE_T0);
            }
            
            // write 03_EXE_TC
            int fH_03_EXE_TC=FileOpen(s.g_03_EXE_TC_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
            if( fH_03_EXE_TC!=INVALID_HANDLE) {
                FileWrite( fH_03_EXE_TC, IntegerToString((datetime)TimeCurrent()) );
                FileClose( fH_03_EXE_TC);
            }

            //
            // TODO implement error handling here
            //      we know that there has been an update
            //      but we don't know the status result
            //
            s.g_03_EXE_t0 = t02Exes.DT;
            
        } // if(fH_03_EXEx!=INVALID_HANDLE)*/
        
    }  // if( (0 < t02ExexSize) || ( (0 == t02ExexSize) && (0 < lret_last_t0) ) ) 

} // void m_update_03_EXE( CSymbol& s, const long t0, CSVTable_Sig_or_Exe& t02Exes )
//+------------------------------------------------------------------+  

//+------------------------------------------------------------------+  
//|     m_update_01_CSV
//|         int start = rates_total-10; //4*5*24*60;
//|         for H1 - 20 years of data available
//|         TODO make this period dependant
//|           since start of week
//|           here PERIOD_H1 for two+ weeks
//|         TODO built-in external option to make this
//|           go back into history and fetch certain 
//|           dates of pre-defines history data 
//|         int start = 24*5;
//|         
//|         NOTE: s.g_t0_01_Csv = t0; will be updated inside m_update_01_CSV
//|         
//+------------------------------------------------------------------+  
void m_update_01_CSV( CSymbol& s )
{

    // reset last possible fHandle error
    ResetLastError();
    
    string sFullDate = "";
    int fH_01_CSVx = INVALID_HANDLE;
    
    //
    // prepare symbol and period name for file names
    //
     
    string sPeriod = ConvertPeriodToString( s.PERIOD );
    string sSymbol = s.SYMBOL;
    // convert EURUSD_custom to EURUSD for the CSV filenames
    StringReplace(sSymbol,"_custom",""); 
    
    //
    // reset file names
    //
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
    
    
    //int start = rates_total-10; //4*5*24*60;
    // for H1 - 20 years
    // TODO make this period dependant
    // since start of week
    // here PERIOD_H1 for two+ weeks
    // TODO built-in external option to make this
    //   go back into history and fetch certain 
    //   dates of pre-defines history data 
    int start = 24*5;
    
    // TODO give this variable a better name - what does it do
    // fill up the remaining elements - fill up counter - for H1 up to 120
    int fill_up_cnt = 0;    
    
    for( int shift= start-1; shift >= 0; shift-- )
    {
    
        datetime dt_now  = iTime(s.SYMBOL,s.PERIOD,shift);
        datetime dt_prev = iTime(s.SYMBOL,s.PERIOD,shift+1);
        MqlDateTime t_now, t_prev;
        TimeToStruct(dt_now,t_now);
        TimeToStruct(dt_prev,t_prev);
        // skip Sunday (0) and Saturday(6)
        if( (0 == t_now.day_of_week ) || (6 == t_now.day_of_week )  )
        {
            continue;
        }
        else
        {
            fill_up_cnt++;
            // if previous was Sunday(0) and now is Monday(1) 
            // then start creating a new file
            if( (1 != t_prev.day_of_week ) && (1 == t_now.day_of_week ) ) {  
            
                // in case there was a file open (e.g. from previous week for H1), just close it
                if(fH_01_CSVx!=INVALID_HANDLE) {
                    FileClose( fH_01_CSVx);
                    fH_01_CSVx = INVALID_HANDLE;
                }
                
                //
                // set file names after a new fulldate has been reached MOnday at 00:00:00
                //
                sFullDate = StringFormat( "%04d%02d%02d", t_now.year, t_now.mon, t_now.day );
                // c:\TEMP\2d\rfx\mt\vm1\mt1\MQL5\Files\H1\20200525\01_CSVx\EURUSD.csv
                // c:\TEMP\2d\rfx\mt\vm1\mt1\Tester\Agent-127.0.0.1-3000\MQL5\Files\H1\20200525\01_CSVx\EURUSD.csv
                s.g_01_CSVs_fN = sPeriod + "\\" + sFullDate + "\\01_CSVs\\" + sSymbol + ".csv";
                s.g_01_CSVx_fN = sPeriod + "\\" + sFullDate + "\\01_CSVx\\" + sSymbol + ".csv";
                s.g_02_SIGs_fN = sPeriod + "\\" + sFullDate + "\\02_SIGs\\" + sSymbol + ".csv";
                s.g_02_SIGx_fN = sPeriod + "\\" + sFullDate + "\\02_SIGx\\" + sSymbol + ".csv";
                s.g_03_EXEs_fN = sPeriod + "\\" + sFullDate + "\\03_EXEs\\" + sSymbol + ".csv";
                s.g_03_EXEx_fN = sPeriod + "\\" + sFullDate + "\\03_EXEx\\" + sSymbol + ".csv";
                // c:\TEMP\2d\rfx\mt\vm1\mt1\MQL5\Files\H1\20200525\01_CSV_T0
                // c:\TEMP\2d\rfx\mt\vm1\mt1\Tester\Agent-127.0.0.1-3000\MQL5\Files\H1\20200525\01_CSV_T0
                s.g_01_CSV_TC_fN = sPeriod + "\\" + sFullDate + "\\01_CSV_TC";
                s.g_01_CSV_T0_fN = sPeriod + "\\" + sFullDate + "\\01_CSV_T0";
                s.g_02_SIG_TC_fN = sPeriod + "\\" + sFullDate + "\\02_SIG_TC";
                s.g_02_SIG_T0_fN = sPeriod + "\\" + sFullDate + "\\02_SIG_T0";
                s.g_03_EXE_TC_fN = sPeriod + "\\" + sFullDate + "\\03_EXE_TC";
                s.g_03_EXE_T0_fN = sPeriod + "\\" + sFullDate + "\\03_EXE_T0";
                
                fH_01_CSVx=FileOpen(s.g_01_CSVx_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_CSV ,';');
                // INTERFACE START
                if(fH_01_CSVx!=INVALID_HANDLE) {
                    FileWrite( fH_01_CSVx,"dt", "open", "high", "low", "close"/*, "tick", "vol", "spread"*/ );
                }
                fill_up_cnt = 1;
            } // if( (0 == t_prev.day_of_week ) && (1 == t_now.day_of_week ) )
                
            string s_dt    = IntegerToString( (long)dt_now );  // s_dt = TimeToString( iTime(s.SYMBOL,s.PERIOD,shift, TIME_DATE | TIME_MINUTES );
            string s_open  = nds(s, iOpen ( s.SYMBOL, s.PERIOD, shift) );
            string s_high  = nds(s, iHigh ( s.SYMBOL, s.PERIOD, shift) );
            string s_low   = nds(s, iLow  ( s.SYMBOL, s.PERIOD, shift) );
            string s_close = nds(s, iClose( s.SYMBOL, s.PERIOD, shift) );
            string s_tick  = IntegerToString( (long)iTickVolume(s.SYMBOL,s.PERIOD,shift) );
            string s_vol   = IntegerToString( (long)iVolume(s.SYMBOL,s.PERIOD,shift) );
            string s_spread= IntegerToString( (long)iSpread(s.SYMBOL,s.PERIOD,shift) );
            if(fH_01_CSVx!=INVALID_HANDLE) {
                FileWrite( fH_01_CSVx, s_dt, s_open, s_high, s_low, s_close/*, s_tick, s_vol, s_spread*/ );
                // INTERFACE END
                FileFlush( fH_01_CSVx );
            } // if(fH_01_CSVx!=INVALID_HANDLE)

            // write CSV data of t0 to 01_CSVx\EURUSD.csv and update the one-liner 01_CSVs\EURUSD.csv
            if( 0 == shift ) {
            
            
                // fill up the remaining elements
                if( PERIOD_H1 == s.PERIOD )           
                if(fH_01_CSVx!=INVALID_HANDLE) {
                    for( int j = fill_up_cnt; j < 120 ; j++ ) { 
                        FileWrite( fH_01_CSVx, 0, s_close, s_close, s_close, s_close/*, s_tick, s_vol, s_spread*/ );
                    }
                    FileFlush( fH_01_CSVx );
                } // if(fH_01_CSVx!=INVALID_HANDLE)
                
                // write 01_CSVs
                int fH_01_CSVs=FileOpen(s.g_01_CSVs_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_CSV ,';');
                if( fH_01_CSVs != INVALID_HANDLE ) {
                    FileWrite( fH_01_CSVs, s_dt, s_open, s_high, s_low, s_close/*, s_tick, s_vol, s_spread*/ );
                    FileClose( fH_01_CSVs);
                }
                
                // write 01_CSV_T0
                int fH_01_CSV_T0=FileOpen(s.g_01_CSV_T0_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
                if( fH_01_CSV_T0!=INVALID_HANDLE) {
                    FileWrite( fH_01_CSV_T0, s_dt );
                    FileClose( fH_01_CSV_T0);
                }
                
                // write 01_CSV_TC
                int fH_01_CSV_TC=FileOpen(s.g_01_CSV_TC_fN,FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
                if( fH_01_CSV_TC!=INVALID_HANDLE) {
                    FileWrite( fH_01_CSV_TC, IntegerToString((datetime)TimeCurrent()) );
                    FileClose( fH_01_CSV_TC);
                }

                // TODO error handling - make this dependant on maybe an existing file handle
                //                       meaning if file does not exists then do not update status
                // set to done - no more polling and writing
                s.g_01_CSV_t0 = dt_now;
                dbg(s, "CSV:     " + TimeToString(dt_now, TIME_DATE|TIME_SECONDS) );

            } // if( 0 == shift )
                
        } // if( (0 == t_now.day_of_week ) || (6 == t_now.day_of_week )  )
        
    } // for( int shift= start-1; shift >= 0; shift-- )
    
    if(fH_01_CSVx!=INVALID_HANDLE) {
        FileClose( fH_01_CSVx);
    }
    //Print( " Failed to open file: " + s_filename + " Error: " + IntegerToString(GetLastError()) );

} // void m_update_01_CSV( CSymbol& s )
//+------------------------------------------------------------------+  



//+------------------------------------------------------------------+
//|     m_execute_SIG_from_CSV
//|     execute a "line" from 02_SIGx CSV file
//|     returns: true if success
//|              false in case of error
//|     params:
//|         CSVTable_Sig_or_Exe tCsv
//|         line of CSV to be executed
//|     
//|     
//+------------------------------------------------------------------+
bool m_execute_SIG_from_CSV( CSymbol& s, CSVTable_Sig_or_Exe& tSigCsv, CSVTable_Sig_or_Exe& tExeCsv )
{
    bool bRet = false;
    double lot = ORDER_LOT;
    double tradedLot = 0;
    long t0 = tSigCsv.DT;
    
    // initialise tExeCsv
    tExeCsv.DT = t0;
    tExeCsv.STAT = tSigCsv.STAT;
    tExeCsv.TradeDT = 0;
    tExeCsv.TradeOP = 0;
    tExeCsv.DIFF = 0;
    tExeCsv.SUMUP = 0;
    
    // INTERFACE to CSV
    //  DT            STAT	TradeDT	    TradeOP     DIFF    SUMUP
    //  1590760800    B	    1590757200	1,11327		-22		31

 
    if ( "B" == tSigCsv.STAT ) {
        
        if( false == PositionSelect(s.SYMBOL) ) 
        {
            dbg(s, "BUY: 1x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            bRet = true;
            m_PositionOpenBuy(s,lot);
            if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                dbg(s, "BUY: HE1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            if( lot != tradedLot) {
                dbg(s, "BUY: EV1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            
        }
        else if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
        {
            dbg(s, "BUY: 2x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            bRet = true;
            m_PositionOpenBuy(s,2*lot);
            if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                dbg(s, "BUY: HE2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            if( 2*lot != tradedLot ) { // PositionGetDouble(POSITION_VOLUME)
                dbg(s, "BUY: EV2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }

        }
        else if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
        {
            dbg(s, "BUY: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        }
        else
        {
            dbg(s, "BUY: XXX " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        } // if( false == PositionSelect(s.SYMBOL) ) 

    } else if ( "S" == tSigCsv.STAT ) {

        if( false == PositionSelect(s.SYMBOL) ) 
        {
            dbg(s, "SEL: 1x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            bRet = true;
            m_PositionOpenSell(s,lot);
            if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                dbg(s, "SEL: HE1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            if( lot != tradedLot ) {
                dbg(s, "SEL: EV1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            
        }
        else if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
        {
            dbg(s, "SEL: 2x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            bRet = true;
            m_PositionOpenSell(s,2*lot);
            if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                dbg(s, "SEL: HE2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            if( 2*lot != tradedLot ) {
                dbg(s, "SEL: EV2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            
        }
        else if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
        {
            dbg(s, "SEL: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        }
        else
        {
            dbg(s, "SEL: XXX " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        } // if( false == PositionSelect(s.SYMBOL) )  
                           
    } else if ( "E" == tSigCsv.STAT ) {
      
        if( false == PositionSelect(s.SYMBOL) ) 
        {
            dbg(s, "EXI: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        }
        else if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
        {
            dbg(s, "EXI: SEL " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            bRet = true;
            m_PositionClose(s,123,"CLOSE",true);
            if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                dbg(s, "EXI: HE1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            if( lot != g_trade_result.volume ) {
                dbg(s, "EXI: EVS " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            
        }
        else if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
        {
            dbg(s, "EXI: BUY " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            bRet = true;
            m_PositionClose(s,123,"CLOSE",true);
            if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                dbg(s, "EXI: HE2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;
            }
            if( lot !=tradedLot ) {
                dbg(s, "EXI: EVB " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = false;                    
            }
            
        }
        else
        {
            dbg(s, "EXI: XXX " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        } // if( false == PositionSelect(s.SYMBOL) )  
        
        
    } else if ( "" == tSigCsv.STAT ) {

        if( true == PositionSelect(s.SYMBOL) ) 
        {
            dbg(s, " XI: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            m_PositionClose(s,123,"CLOSE",true);
        }
        
        
        //
        // no S,B or E, just do nothing and everything is fine
        //
        
        
        dbg(s, "___:     " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        tExeCsv.TradeDT = tSigCsv.TradeDT;
        tExeCsv.TradeOP = tSigCsv.TradeOP;
        bRet = true;


    } else { // ERROR
        // TODO rework error handling
        dbg(s, "ERR: 1   " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        
    } // if ( "B" == tSigCsv.STAT )
     
    
    return (bRet);
} // bool m_execute_SIG_from_CSV( CSymbol& s, CSVTable_Sig_or_Exe& tSigCsv, CSVTable_Sig_or_Exe& tExeCsv )
//+------------------------------------------------------------------+


//
// TODO rework me 
//   make one for test_mode and one function for test_account
//


//+------------------------------------------------------------------+
//|     m_execute_SIG_from_CSV2
//|     execute a "line" from 02_SIGx CSV file
//|     returns: true if success
//|              false in case of error
//|     params:
//|         CSVTable_Sig_or_Exe tCsv
//|         line of CSV to be executed
//|     
//|     
//+------------------------------------------------------------------+
bool m_execute_SIG_from_CSV2( CSymbol& s, CSVTable_Sig_or_Exe& tSigCsv, CSVTable_Sig_or_Exe& tExeCsv )
{
    bool bRet = false;
    double lot = ORDER_LOT;
    double tradedLot = 0;
    long t0 = tSigCsv.DT;
    
    // initialise tExeCsv
    tExeCsv.DT = t0;
    tExeCsv.STAT = tSigCsv.STAT;
    tExeCsv.TradeDT = 0;
    tExeCsv.TradeOP = 0;
    tExeCsv.DIFF = 0;
    tExeCsv.SUMUP = 0;
    
    // INTERFACE to CSV
    //  DT            STAT	TradeDT	    TradeOP     DIFF    SUMUP
    //  1590760800    B	    1590757200	1,11327		-22		31

    if( (tSigCsv.DT == tSigCsv.TradeDT) && (0!=tSigCsv.TradeDT) ) {

        if ( "B" == tSigCsv.STAT ) {
            
            if( false == PositionSelect(s.SYMBOL) ) 
            {
                dbg(s, "BUY: 1x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = true;
                m_PositionOpenBuy(s,lot);
                if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                    dbg(s, "BUY: HE1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                if( lot != tradedLot) {
                    dbg(s, "BUY: EV1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                
            }
            else if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
            {
                dbg(s, "BUY: 2x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = true;
                m_PositionOpenBuy(s,2*lot);
                if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                    dbg(s, "BUY: HE2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                if( 2*lot != tradedLot ) { // PositionGetDouble(POSITION_VOLUME)
                    dbg(s, "BUY: EV2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }

            }
            else if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
            {
                dbg(s, "BUY: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            }
            else
            {
                dbg(s, "BUY: XXX " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            } // if( false == PositionSelect(s.SYMBOL) ) 

        } else if ( "S" == tSigCsv.STAT ) {

            if( false == PositionSelect(s.SYMBOL) ) 
            {
                dbg(s, "SEL: 1x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = true;
                m_PositionOpenSell(s,lot);
                if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                    dbg(s, "SEL: HE1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                if( lot != tradedLot ) {
                    dbg(s, "SEL: EV1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                
            }
            else if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
            {
                dbg(s, "SEL: 2x  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = true;
                m_PositionOpenSell(s,2*lot);
                if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                    dbg(s, "SEL: HE2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                if( 2*lot != tradedLot ) {
                    dbg(s, "SEL: EV2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                
            }
            else if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
            {
                dbg(s, "SEL: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            }
            else
            {
                dbg(s, "SEL: XXX " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            } // if( false == PositionSelect(s.SYMBOL) )  
                               
        } else if ( "E" == tSigCsv.STAT ) {
          
            if( false == PositionSelect(s.SYMBOL) ) 
            {
                dbg(s, "EXI: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            }
            else if( POSITION_TYPE_SELL == PositionGetInteger(POSITION_TYPE) )
            {
                dbg(s, "EXI: SEL " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = true;
                m_PositionClose(s,123,"CLOSE",true);
                if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                    dbg(s, "EXI: HE1 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                if( lot != g_trade_result.volume ) {
                    dbg(s, "EXI: EVS " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                
            }
            else if( POSITION_TYPE_BUY == PositionGetInteger(POSITION_TYPE) )
            {
                dbg(s, "EXI: BUY " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                bRet = true;
                m_PositionClose(s,123,"CLOSE",true);
                if( false == m_GetFromLastDealHistory(s,t0,tExeCsv.STAT,tExeCsv.TradeDT,tExeCsv.TradeOP,tExeCsv.DIFF,tradedLot) ) {
                    dbg(s, "EXI: HE2 " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;
                }
                if( lot !=tradedLot ) {
                    dbg(s, "EXI: EVB " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
                    bRet = false;                    
                }
                
            }
            else
            {
                dbg(s, "EXI: XXX " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            } // if( false == PositionSelect(s.SYMBOL) )  

        } else { // ERROR
            // TODO rework error handling
            dbg(s, "ERR: 1   " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            
        } // if ( "B" == tSigCsv.STAT )
     
    } else if( 0!=tSigCsv.DT ) {
        
        if( true == PositionSelect(s.SYMBOL) ) 
        {
            dbg(s, " XI: ERR " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
            m_PositionClose(s,123,"CLOSE",true);
        }
        
        
        //
        // no S,B or E, just do nothing and everything is fine
        //
        
        
        dbg(s, "___:     " + TimeToString(t0, TIME_DATE|TIME_SECONDS) );
        tExeCsv.TradeDT = tSigCsv.TradeDT;
        tExeCsv.TradeOP = tSigCsv.TradeOP;
        bRet = true;
    
    } else {
        // TODO rework error handling
        dbg(s, "ERR: 2 t0:  " + TimeToString(t0, TIME_DATE|TIME_SECONDS) + " TradeDt: " + TimeToString(tSigCsv.TradeDT, TIME_DATE|TIME_SECONDS)  );
        
    } // if( (tSigCsv.DT == tSigCsv.TradeDT) && (0!=tSigCsv.TradeDT) )
    
    return (bRet);
} // bool m_execute_SIG_from_CSV2( CSymbol& s, CSVTable_Sig_or_Exe& tSigCsv, CSVTable_Sig_or_Exe& tExeCsv )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|     m_Read_SIG_or_EXE_CSV_File
//|     reads a SIG or EXE CSV file with sFname 
//|     into the table tCsv[]
//|     returns: the epoch datetime t0 of the last element read
//|                 or 0 in error case or file does not exists
//|     params:
//|         string sFname
//|             EXE or SIG filename            
//|         CSVTable_02Sigx& tCsv[]
//|             CSV table of all elements (rowsxcols)
//|         long& t0
//|             t0 element to be found
//|         int& t0_index
//|             index of t0 element to be found in table
//|             -1 if element is not found
//+------------------------------------------------------------------+
long m_Read_SIG_or_EXE_CSV_File( string sFname, CSVTable_Sig_or_Exe& tCsv[], long t0, int& t0_index )
{

    // set to not found
    t0_index = -1;
    
    // set to last t0 - meaning there was an error or file does not exists
    long lRetLastT0 = 0;

    int i=0;
    int fhandle = INVALID_HANDLE;
    
    // reset last possible fHandle error
    ResetLastError();
    fhandle=FileOpen(sFname,FILE_SHARE_READ|FILE_READ|FILE_ANSI);
    if(fhandle!=INVALID_HANDLE) 
    {
        while(FileIsEnding(fhandle) == false)
        {
        
            string lineContent = FileReadString(fhandle);
            // TODO fix me  - find better way in system NOT to deal with floating point commas
            //  FROM:
            //  1590386400;E;1590386400;1,08875;0;67
            //  TO:
            //  1590386400;E;1590386400;1.08875;0;67
            StringReplace(lineContent,",","."); 
            string str_arr_split[];                     // An array to get strings
            string s_sep=";";                           // A separator as a character
            //--- Get the separator code
            ushort u_sep=StringGetCharacter(s_sep,0);   // The code of the separator character
            //--- Split the string to substrings
            int num_str_split=StringSplit(lineContent,u_sep,str_arr_split);
            if( 6 == num_str_split )
            {
            // INTERFACE to CSV
            //  DT            STAT	TradeDT	    TradeOP     DIFF    SUMUP
            //  1590760800    B	    1590757200	1,11327		-22		31
                ArrayResize(tCsv,ArraySize(tCsv) +1 );     
                //tCsv[i].INDEX   
                tCsv[i].DT      = (long)StringToInteger(str_arr_split[0]);
                tCsv[i].STAT    = str_arr_split[1];
                tCsv[i].TradeDT = (long)StringToInteger(str_arr_split[2]);
                tCsv[i].TradeOP = StringToDouble(str_arr_split[3]);
                tCsv[i].DIFF    = StringToDouble((string)str_arr_split[4]);
                tCsv[i].SUMUP   = StringToDouble(str_arr_split[5]);
                lRetLastT0      = tCsv[i].DT;
                if( t0 == tCsv[i].DT ) {
                    t0_index = i;                    
                }
                i++;
            } // if( 6 == num_str_split )
        } // while(FileIsEnding(fhandle) == false)
        FileClose(fhandle);   
    } // if(fhandle!=INVALID_HANDLE) 

    return (lRetLastT0);
} //m_Read_SIG_or_EXE_CSV_File( string sFname, CSVTable_Sig_or_Exe& tCsv[], long& t0, int& t0_index )
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|   m_WorkWithPositions2
//+------------------------------------------------------------------+
bool m_WorkWithPositions2( CSymbol& s, e_workwithpositions a_wwp_profits = E_WWP_TRAILING_STOP, e_workwithpositions a_wwp_losses = E_WWP_PREV_CLOSE ) 
{

    if( false == PositionSelect(s.SYMBOL)) {
        // there is no position open; just return
        
        // reset trailing parameters if there is no open position
        s.g_open_positions_trailing_stop  = TRAILING_STOP;
        s.g_open_positions_trailing_step  = TRAILING_STEP;
        m_CheckTrailingStop(s);
        s.g_sl = 0.0;
        
        return ( false );
    }
    
    s.m_order_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    s.m_order_current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    s.m_order_profit=PositionGetDouble(POSITION_PROFIT);
    s.m_order_type       = (int)PositionGetInteger(POSITION_TYPE);
    s.m_order_time = (datetime)PositionGetInteger(POSITION_TIME);
    s.m_order_volume = PositionGetDouble(POSITION_VOLUME);
    s.m_position_id = PositionGetInteger(POSITION_IDENTIFIER);
    double vol = PositionGetDouble(POSITION_VOLUME);
    double sl=PositionGetDouble(POSITION_SL);
    double tp=PositionGetDouble(POSITION_TP);
    
    double task = s.ASK;
    double tbid = s.BID;
    double order_sl=sl;
    double order_tp=tp;

    if( 0.0 == s.g_sl )
    {
        s.g_sl = s.m_order_open_price;
    }

    int tsl = (int)SymbolInfoInteger(s.SYMBOL,SYMBOL_TRADE_STOPS_LEVEL);
    double sl_price = 0;
    if( 0 < SL_POINTS )
    {
        sl_price = SL_POINTS*s.POINT;
        if( SL_POINTS < tsl )
            sl_price = tsl*s.POINT;
    }
    else
    {
        sl_price = 1*s.sl_level*s.POINT;
        if( s.sl_level < tsl )
            sl_price = tsl*s.POINT;
    }
    double tp_price = 0;
    if( 0 < TP_POINTS )
    {
        tp_price = TP_POINTS*s.POINT;
        if( TP_POINTS < tsl )
            tp_price = tsl*s.POINT;
    }
    else
    {
        tp_price = 1*s.sl_level*s.POINT;
        if( s.sl_level < tsl )
            tp_price = tsl*s.POINT;
    }
    

    
    
    //--- 1. Trailing Stop
    if(s.m_order_type==POSITION_TYPE_BUY)
    {
    
        double sl3 = NormalizeDouble((s.g_sl + 3*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double sl2 = NormalizeDouble((s.g_sl + 2*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double sl1 = NormalizeDouble((s.g_sl + 1*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double sl0 = NormalizeDouble((s.g_sl + 0*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double slm1 = NormalizeDouble((s.g_sl - 10*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
    
        // SL
        if(
               ( sl3 < s.m_order_current_price )
            && ( sl2 > order_sl )
        )
        {
           sl = sl2;
        }
        else if(
               ( sl2 < s.m_order_current_price )
            && ( sl1 > order_sl )
        )
        {
           sl = sl1;
        }
        else if(
               ( sl1 < s.m_order_current_price )
            && ( sl0 > order_sl )
        )
        {
           sl = sl0;
        }
        else if(
               ( sl0 < s.m_order_current_price )
            && ( 0.0 == order_sl )
        )
        {
           sl = slm1;
        }
    
        // TP
        if( 0 < tp_price )
        {
            tp = NormalizeDouble(s.g_sl+tp_price,s.DIGITS);
        }
        
    }// end POSITION_TYPE_BUY    
    else if(s.m_order_type==POSITION_TYPE_SELL)
    {
        double sl3 = NormalizeDouble((s.g_sl - 3*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double sl2 = NormalizeDouble((s.g_sl - 2*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double sl1 = NormalizeDouble((s.g_sl - 1*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double sl0 = NormalizeDouble((s.g_sl - 0*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
        double slp1 = NormalizeDouble((s.g_sl + 10*s.g_open_positions_trailing_stop*s.POINT), s.DIGITS);
    
        // SL
        if(
               ( sl3 > s.m_order_current_price )
            && ( sl2 < order_sl )
        )
        {
           sl = sl2;
        }
        else if(
               ( sl2 > s.m_order_current_price )
            && ( sl1 < order_sl )
        )
        {
           sl = sl1;
        }
        else if(
               ( sl1 > s.m_order_current_price )
            && ( sl0 < order_sl )
        )
        {
           sl = sl0;
        }
        else if(
               ( sl0 > s.m_order_current_price )
            && ( 0 == order_sl )
        )
        {
           sl = slp1;
        }
        
        // TP
        if( 0 < tp_price )
        {
            tp = NormalizeDouble(s.m_order_open_price-tp_price,s.DIGITS);
        }
        
    }// end POSITION_TYPE_SELL
    
    if( sl != order_sl ) {
        string log = "SL SET PROFIT: " + nds(s,sl) + " - G_SL " + nds(s,s.g_sl) + " - OPEN " + nds(s,order_sl/*s.m_order_open_price*/) + " - CURRENT " + nds(s,s.m_order_current_price) + " ASK/BID " + nds(s,s.ASK) + "/" +  nds(s,s.BID);
        Log2Sql( s, "WATCHER", 0, log );
        m_ModifyOpenPosition(s, sl,tp,MAGIC_POSITION, order_sl, order_tp);
    }
    

       
    return (true);

} // int m_WorkWithPositions2()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExtractHighLowFromMqlTickArray( const MqlTick& mqltickarray[], int& OC, int& HL, long& DELTA_MSC)
{
    double high = 0;
    double low  = 1000000000;
    int size = ArraySize( mqltickarray );
    DELTA_MSC = 0;

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
        DELTA_MSC = (long)(t0.time_msc - tstart.time_msc);
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
