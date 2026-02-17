//+------------------------------------------------------------------+
//|                                                    variables.mqh |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link      "https://www.fuzzyalgo.com"

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
input string ACCOUNT = "RF5D03"; // forex account name 
input string SYMBOLS = "EURUSD:EURGBP:GBPJPY:NZDUSD";
input string PERIODS = "PRO:T15:T30:T60:T_AVG:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T60:T300:T900:T3600:T_AVG:S60:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG:S15:S30:S60:S300:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG";            // periods are seperated by colon. T for Ticks and S for seconds


// G L O B A L S

struct sConfigVars
{

    string account;
    string symbols;
    string periods;

}; // struct sConfigVars

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
        //if (0 < Debug)
        {
            Print(str);
        }
    } // void print()

}; // struct sDataVars


struct sSymbolVars 
{

    string symbol;
    string periods;
    sDataVars sData[];

    void init(      const string& _symbol,
                    const string& _periods) 
    {
        symbol= _symbol;
        periods = _periods;
        Print( "SYM: " + symbol + " " + periods );
    }
    
}; // struct sSymbolVars;


struct sGlobalVars 
{

    string account;
    string symbols;
    string periods;
    sSymbolVars sSym[];

    //--- Constructor
    sGlobalVars(    const string& _account,
                    const string& _symbols,
                    const string& _periods ): 
                        account(_account),
                        symbols(_symbols),
                        periods(_periods)
    {
        Print( account + " " + symbols + " " + periods );
        
        string s_sep=":";              // A separator as a character
        string str_symbol_split[];     // An array to get strings
        ushort u_sep=StringGetCharacter(s_sep,0);//--- Get the separator code
        int num_symbols=StringSplit(symbols,u_sep,str_symbol_split); //--- Split the string to substrings
        ArrayFree(sSym);
        if( 0 == num_symbols )
        {
            ArrayResize(sSym, 1);
            sSym[0].init(Symbol(), periods);
        }
        else
        {
            ArrayResize(sSym, num_symbols);
            for( int cnt = 0; cnt < num_symbols; cnt++ )
            {
                sSym[0].init(str_symbol_split[cnt], periods);
            } // for( int cnt = 0; cnt < num_symbols; cnt++ )
        }
    } // sGlobalVars
    
    //--- Destructor
    ~sGlobalVars() {}
         
}; // struct sGlobalVars;



