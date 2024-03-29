//+------------------------------------------------------------------+
//|                                                     RiPeriod.mqh |
//|                                      Copyright 2017, Andre Howe. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Andre Howe."
#property link      "http://www.mql5.com"

#include <Object.mqh>
#include <Arrays/List.mqh>

#include "RiPeriodBuffer.mqh"

//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+

enum ENUM_PERIODS 
{
    IDX_PERIOD_M1,
    IDX_PERIOD_M5,
    IDX_PERIOD_M15,
    IDX_PERIOD_H1,
    IDX_PERIOD_H4,
    IDX_PERIOD_MAX,
};

enum ENUM_MATRIX_LEN 
{
    IDX_SHIFT_0,
    IDX_SHIFT_1,
    IDX_SHIFT_2,
    IDX_SHIFT_3,
    IDX_SHIFT_4,
    IDX_SHIFT_IDX0,
    IDX_SHIFT_IDX1,
    IDX_SHIFT_IDX2,
    IDX_SHIFT_IDX3,
    MAX_MATRIX_LEN
};

struct STradeSignals
{
    bool buyint;
    bool sellint;
    bool buybo;
    bool sellbo;
};

//+------------------------------------------------------------------+
 
 
//+------------------------------------------------------------------+
class CRiPeriod : public CObject
{
private:
    const string            m_symbol;       // Indicator calculation symbol
    const ENUM_TIMEFRAMES   m_period;       // Indicator calculation period
    const double            m_bo_percent;   // breakout value in percent
    datetime                m_last_time;    // The time of the last known bar
    bool                    m_configured_and_loaded;  // 
    int                     m_access_index[IDX_PERIOD_MAX];
    
/*    
    // start indicator data
    CRiBuffInt              m_rates_total;
    CRiBuffInt              m_prev_calculated;
    CRiMaxMin               m_Time;
    CRiMaxMin               m_Open;
    CRiMaxMin               m_High;
    CRiMaxMin               m_Low;
    CRiMaxMin               m_Close;
    CRiMaxMin               m_TickVolume;
    CRiMaxMin               m_Volume;
    CRiMaxMin               m_Spread;
    // stop indicator data
    
    // start index data
    CRiBuffInt              m_idx_0;
    CRiBuffInt              m_idx_1;
    CRiBuffInt              m_idx_2;
    CRiBuffInt              m_idx_3;
    // stop index data
*/    
    CList*                  m_list;

    // start period data
    /*CPeriodBuffer           m_M1;          
    CPeriodBuffer           m_M5;          
    CPeriodBuffer           m_M15;          
    CPeriodBuffer           m_H1;          
    CPeriodBuffer           m_H4; */         
    // stop period data
    
    
    SPeriodBuffer           m_Matrix[IDX_PERIOD_MAX][MAX_MATRIX_LEN];
    

private:

    bool    IsNewBar(void);
    int     iBarShift(  
                string symbol,
                ENUM_TIMEFRAMES timeframe,
                datetime starttime,
                datetime stoptime
                );
    datetime iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift);
    int CheckLoadHistory(string a_symbol,ENUM_TIMEFRAMES a_period, datetime a_from_date);
    string ConvertPeriodToString( ENUM_TIMEFRAMES timeframe );
    string StringFormatResultBuffer( SPeriodBuffer& sb, int& output  );
    bool AnalyseMatrixSub( SPeriodBuffer& s0, SPeriodBuffer& s1, 
                           SPeriodBuffer& s2, SPeriodBuffer& s3,
                           SPeriodBuffer& s4,
                           SPeriodBuffer& sidx0, SPeriodBuffer& sidx1, 
                           SPeriodBuffer& sidx2, SPeriodBuffer& sidx3 );
    ~CRiPeriod();
   
public:

    CRiPeriod(const string symbol, const ENUM_TIMEFRAMES period, const double bo_percent );
    int ConfigAndLoad( int& plot_index, int& idx_buf_index );
    void AddChartData(
            const int       idx,
            const int       a_rates_total,
            const int       a_prev_calculated,
            const datetime  &a_Time[],
            const double    &a_Open[],
            const double    &a_High[],
            const double    &a_Low[],
            const double    &a_Close[],
            const long      &a_TickVolume[],
            const long      &a_Volume[],
            const int       &a_Spread[]    
                    );
   double Get(ENUM_TIMEFRAMES period, ENUM_BUF_IDX buf_index, int shift_index  );
   bool   LoadMatrix(  int shift_index );
   bool   AnalyseMatrix();
   STradeSignals GetResultofMatrix(); 
                    
};

//+------------------------------------------------------------------+
//| Subscribe to value adding/changing notifications                 |
//+------------------------------------------------------------------+
CRiPeriod::CRiPeriod(const string symbol, const ENUM_TIMEFRAMES period, const double bo_percent  ) : 
                            m_symbol(symbol), 
                            m_period(period), 
                            m_bo_percent(bo_percent),
                            m_last_time(0), 
                            m_configured_and_loaded(false),
                            m_list(NULL)
{
    if( NULL != m_list ) delete m_list;
    m_list=new CList;

    switch( m_period )
    {
        case PERIOD_M1:
                m_list.Add( new CPeriodBuffer( m_period,   ConvertPeriodToString( m_period ),   1,   IDX_PERIOD_M1,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_M5,  ConvertPeriodToString( PERIOD_M5 ),  5,   IDX_PERIOD_M5,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_M15, ConvertPeriodToString( PERIOD_M15 ), 15,  IDX_PERIOD_M15, bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H1,  ConvertPeriodToString( PERIOD_H1 ),  60,  IDX_PERIOD_H1,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H4,  ConvertPeriodToString( PERIOD_H4 ),  240, IDX_PERIOD_H4,  bo_percent  ) );
            break;
            
        case PERIOD_M5:
                m_list.Add( new CPeriodBuffer( m_period,   ConvertPeriodToString( m_period ),   1,   IDX_PERIOD_M5,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_M15, ConvertPeriodToString( PERIOD_M15 ), 3,   IDX_PERIOD_M15, bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H1,  ConvertPeriodToString( PERIOD_H1 ),  12,  IDX_PERIOD_H1,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H4,  ConvertPeriodToString( PERIOD_H4 ),  48,  IDX_PERIOD_H4,  bo_percent  ) );
            break;

        case PERIOD_M15:
                m_list.Add( new CPeriodBuffer( m_period,   ConvertPeriodToString( m_period ),   1,   IDX_PERIOD_M15, bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H1,  ConvertPeriodToString( PERIOD_H1 ),  4,   IDX_PERIOD_H1,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H4,  ConvertPeriodToString( PERIOD_H4 ),  16,  IDX_PERIOD_H4,  bo_percent  ) );
            break;

        case PERIOD_H1:
                m_list.Add( new CPeriodBuffer( m_period,   ConvertPeriodToString( m_period ),   1,   IDX_PERIOD_H1,  bo_percent  ) );
                m_list.Add( new CPeriodBuffer( PERIOD_H4,  ConvertPeriodToString( PERIOD_H4 ),  4,   IDX_PERIOD_H4,  bo_percent  ) );
            break;

        case PERIOD_H4:
                m_list.Add( new CPeriodBuffer( m_period,   ConvertPeriodToString( m_period ),   1,   IDX_PERIOD_H4,  bo_percent  ) );
            break;
            
    };  
    
    for( int cnt = 0; cnt < IDX_PERIOD_MAX; cnt++ )
    {
        m_access_index[cnt] = -1;   
    }    
    int total = m_list.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        m_access_index[b.GetPeriodIdx()] = cnt;
    }    
      
    
}

CRiPeriod::~CRiPeriod()
{
    if( NULL != m_list )
    {
        delete m_list;
        m_list = NULL;
    }
}

//+------------------------------------------------------------------+
//| CRiPeriod::LoadMatrix()
//+------------------------------------------------------------------+
bool CRiPeriod::LoadMatrix( int shift_index )  
{ 
    bool bSuccess = false;
    
    //SPeriodBuffer           m_Matrix[IDX_PERIOD_MAX][MAX_MATRIX_LEN];

    //
    // load Matrix
    //
    int total = m_list.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        
        //IDX_SHIFT_0,
        int shift = shift_index + 0 *    b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_0] = b.GetStruct( shift );
        
        //IDX_SHIFT_1,
        shift = shift_index + 1 *    b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_1] = b.GetStruct( shift );
        
        //IDX_SHIFT_2,
        shift = shift_index + 2 *    b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_2] = b.GetStruct( shift );

        //IDX_SHIFT_3,
        shift = shift_index + 3 *    b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_3] = b.GetStruct( shift );

        //IDX_SHIFT_4,
        shift = shift_index + 4 *    b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_4] = b.GetStruct( shift );
        
        //IDX_SHIFT_IDX0,
        shift = shift_index + b.GetShiftSinceDayStarted(0) * b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX0] = b.GetStruct( shift );
        
        //IDX_SHIFT_IDX1,
        shift = shift_index + b.GetShiftSinceWeekStarted(0) * b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX1] = b.GetStruct( shift );
        
        //IDX_SHIFT_IDX2,
        shift = shift_index + b.GetShiftSinceMonthStarted(0) * b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX2] = b.GetStruct( shift );
        
        //IDX_SHIFT_IDX3,
        shift = shift_index + b.GetShiftSinceYearStarted(0) * b.GetPeriod();
        m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX3] = b.GetStruct( shift );
    }    

    bSuccess = true;    
    return bSuccess;
} // bool CRiPeriod::LoadMatrix( int shift_index )  
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| CRiPeriod::AnalyseMatrixSub( SPeriodBuffer& s0, SPeriodBuffer& s1, SPeriodBuffer& s2 )
//+------------------------------------------------------------------+
bool CRiPeriod::AnalyseMatrixSub(   SPeriodBuffer& s0, SPeriodBuffer& s1, 
                                    SPeriodBuffer& s2, SPeriodBuffer& s3,
                                    SPeriodBuffer& s4,
                                    SPeriodBuffer& sidx0, SPeriodBuffer& sidx1, 
                                    SPeriodBuffer& sidx2, SPeriodBuffer& sidx3 )

{ 
    bool bSuccess = false;
    
///
///
///
    double pivotA=( s1.CLOSE+s2.CLOSE+s3.CLOSE )/3;
    double A=( s0.CLOSE - pivotA)/Point();
    
    double pivotB=( s2.CLOSE+s3.CLOSE+s4.CLOSE )/3;
    double B=( s1.CLOSE - pivotB)/Point();
    
    double cmpval = 0;

    // working for m15    
    switch( (int)s0.PERIOD ) {
        case 1:
            cmpval = 50;
            break;
        case 4:
            cmpval = 100;
            break;
        case 16:
            cmpval = 400;
            break;
        default:
            cmpval = 0;
            break;            
    }
    
    cmpval = 25;
    if( 0 == cmpval ) {
        return false;
    }
    double diffcmpval = 25;
    
    double s0diff = ( s0.CLOSE - s1.CLOSE ) / Point();

	//if( (A>1*cmpval) && (A>B)  )
	if( (A>1*cmpval) && (A>B) && ( +1*diffcmpval < s0diff) )
	{
	    if( 0 < s0.BO1INT0 )
            s0.BUY0 = s0.BO1INT0;
	    if( 0 < s0.BO1INT1 )
            s0.BUY1 = s0.BO1INT1;
	    if( 0 < s0.BO1INT2 )
            s0.BUY2 = s0.BO1INT2;
	    if( 0 < s0.BO1INT3 )
            s0.BUY3 = s0.BO1INT3;
	}
	//if( (A<-1*cmpval) && (A<B) )
	if( (A<-1*cmpval) && (A<B) && ( -1*diffcmpval > s0diff) )
	{
	    if( 0 > s0.BO1INT0 )
            s0.SELL0 = s0.BO1INT0;
	    if( 0 > s0.BO1INT1 )
            s0.SELL1 = s0.BO1INT1;
	    if( 0 > s0.BO1INT2 )
            s0.SELL2 = s0.BO1INT2;
	    if( 0 > s0.BO1INT3 )
            s0.SELL3 = s0.BO1INT3;
        /*if( -100 > ((s0.BO1INT0+s0.BO1INT1+s0.BO1INT2+s0.BO1INT3)/4) ) {
            s0.SELL0 = 1;
            s0.SELL1 = 1;
            s0.SELL2 = 1;
            s0.SELL3 = 1;
        }*/
	}


/*
        if( 5 < ((s0.BO1INT0+s0.BO1INT1+s0.BO1INT2+s0.BO1INT3)/4) ) {
            s0.BUY0 = 1;
            s0.BUY1 = 1;
            s0.BUY2 = 1;
            s0.BUY3 = 1;
        }   

        if( -5 > ((s0.BO1INT0+s0.BO1INT1+s0.BO1INT2+s0.BO1INT3)/4) ) {
            s0.SELL0 = 1;
            s0.SELL1 = 1;
            s0.SELL2 = 1;
            s0.SELL3 = 1;
        }
*/




///
///
///


///
/*

    //if( ( s0.BO1 > s1.BO1 ) && ( s0.BO2 > s1.BO2 ) && ( s0.BO3 > s1.BO3 ) )
    //if( ( s0.BO1 > s0.BO3 ) && ( s2.BO1 < s2.BO3 ) )
    if( (s0.BO1 > s1.BO1) && (s0.BO1 > s1.BO3) ) 
    {
        // breakout buy 
        s0.BUY0 = 1;
        s0.BUY1 = 1;
        s0.BUY2 = 1;
        
        // IDX0
        if( ( s0.BO1INT0 > s0.BO2INT0 ) && ( s0.BO2INT0 > s0.BO3INT0 ) 
            //&& ( 0 < s0.BO3INT0 ) 
        )
        {
            s0.BUY0 = 1;
        }
        // IDX1
        if( ( s0.BO1INT1 > s0.BO2INT1 ) && ( s0.BO2INT1 > s0.BO3INT1 )
            //&& ( 0 < s0.BO3INT1 ) 
         )
        {
            s0.BUY1 = 1;
        }
        // IDX2
        if( ( s0.BO1INT2 > s0.BO2INT2 ) && ( s0.BO2INT2 > s0.BO3INT2 ) 
            //&& ( 0 < s0.BO3INT2 ) 
        )
        {
            s0.BUY2 = 1;
        }
        // IDX3
        if( ( s0.BO1INT3 > s0.BO2INT3 ) && ( s0.BO2INT3 > s0.BO3INT3 ) 
            //&& ( 0 < s0.BO3INT3 ) 
        )
        {
            s0.BUY3 = 1;
        }
    } // if( ( s0.BO1 > s1.BO1 ) && ( s0.BO2 > s1.BO2 ) && ( s0.BO3 > s1.BO3 ) )

    //if( ( s0.BO1 < s1.BO1 ) && ( s0.BO2 < s1.BO2 ) && ( s0.BO3 < s1.BO3 ) )
    //if( ( s0.BO1 < s0.BO3 ) && ( s2.BO1 > s2.BO3 ) )
    if( (s0.BO1 < s1.BO1) && (s0.BO1 < s1.BO3) ) 
    {
        // breakout sell
        s0.SELL0 = 1;
        s0.SELL1 = 1;
        s0.SELL2 = 1;
        
        // IDX0
        if( ( s0.BO1INT0 < s0.BO2INT0 ) && ( s0.BO2INT0 < s0.BO3INT0 ) 
            //&& ( 0 > s0.BO3INT0 ) 
        )
        {
            s0.SELL0 = 1;
        }
        // IDX1
        if( ( s0.BO1INT1 < s0.BO2INT1 ) && ( s0.BO2INT1 < s0.BO3INT1 ) 
            //&& ( 0 > s0.BO3INT1 ) 
        )
        {
            s0.SELL1 = 1;
        }
        // IDX2
        if( ( s0.BO1INT2 < s0.BO2INT2 ) && ( s0.BO2INT2 < s0.BO3INT2 ) 
            //&& ( 0 > s0.BO3INT2 ) 
        )
        {
            s0.SELL2 = 1;
        }
        // IDX3
        if( ( s0.BO1INT3 < s0.BO2INT3 ) && ( s0.BO2INT3 < s0.BO3INT3 ) 
            //&& ( 0 > s0.BO3INT3 ) 
        )
        {
            s0.SELL3 = 1;
        }
    } // if( ( s0.BO1 < s1.BO1 ) && ( s0.BO2 < s1.BO2 ) && ( s0.BO3 < s1.BO3 ) )
*/
///    
    bSuccess = true;    
    return bSuccess;
} // bool CRiPeriod::AnalyseMatrixSub(   SPeriodBuffer& s0, SPeriodBuffer& s1, SPeriodBuffer& s2,
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CRiPeriod::AnalyseMatrix()
//+------------------------------------------------------------------+
bool CRiPeriod::AnalyseMatrix()  
{ 
    bool bSuccess = false;
    //SPeriodBuffer           m_Matrix[IDX_PERIOD_MAX][MAX_MATRIX_LEN];
    
    int total = m_list.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        AnalyseMatrixSub( 
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_0],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_1],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_2],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_3],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_4],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX0],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX1],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX2],
            m_Matrix[b.GetPeriodIdx()][IDX_SHIFT_IDX3]
            );
    }    
    
    bSuccess = true;    
    return bSuccess;
} // bool CRiPeriod::AnalyseMatrix()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Helper CRiPeriod::StringFormatResultBuffer()
//+------------------------------------------------------------------+
string CRiPeriod::StringFormatResultBuffer( SPeriodBuffer& sb, int& output  )  
{
    string line = "";
    output = 0;
    
    // print IDX0
    if( 0 != sb.BUY0 )
    {
        line = line + " +" + DoubleToString(sb.BUY0,0);
        output++;
    }
    else if( 0 != sb.SELL0 )
    {
        line = line + " " + DoubleToString(sb.SELL0,0);
        output--;
    }
    else if( 0 != sb.EXIT0 )
    {
        line = line + " E ";
        //output++;
    }
    else
    {
        line = line + "   ";
    }

    // print IDX1
    if( 0 != sb.BUY1 )
    {
        line = line + " +" + DoubleToString(sb.BUY1,0);
        output++;
    }
    else if( 0 != sb.SELL1 )
    {
        line = line + " " + DoubleToString(sb.SELL1,0);
        output--;
    }
    else if( 0 != sb.EXIT1 )
    {
        line = line + " E ";
        //output++;
    }
    else
    {
        line = line + "   ";
    }

    // print IDX2
    if( 0 != sb.BUY2 )
    {
        line = line + " +" + DoubleToString(sb.BUY2,0);
        output++;
    }
    else if( 0 != sb.SELL2 )
    {
        line = line + " " + DoubleToString(sb.SELL2,0);
        output--;
    }
    else if( 0 != sb.EXIT2 )
    {
        line = line + " E ";
        //output++;
    }
    else
    {
        line = line + "   ";
    }

    // print IDX3
    if( 0 != sb.BUY3 )
    {
        line = line + " +" + DoubleToString(sb.BUY3,0);
        output++;
    }
    else if( 0 != sb.SELL3 )
    {
        line = line + " " + DoubleToString(sb.SELL3,0);
        output--;
    }
    else if( 0 != sb.EXIT3 )
    {
        line = line + " E ";
        //output++;
    }
    else
    {
        line = line + "   ";
    }
        
    line = StringFormat( "%03d - 0x%04x - %s", (int)sb.PERIOD, MathAbs(output), line );
    
    return line;
} // string CRiPeriod::StringFormatResultBuffer( SPeriodBuffer& sb, int& output  )  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| STradeSignals CRiPeriod::GetResultofMatrix()  
//+------------------------------------------------------------------+
STradeSignals CRiPeriod::GetResultofMatrix()  
{ 
    STradeSignals ts;
    ts.buybo   = false;
    ts.buyint  = false;
    ts.sellbo  = false;
    ts.sellint = false;
    
    
    //SPeriodBuffer           m_Matrix[IDX_PERIOD_MAX][MAX_MATRIX_LEN];

    //
    // print Matrix
    //
    int output1[IDX_PERIOD_MAX] = {};
    string line1[IDX_PERIOD_MAX];
    int output = 0;
    int period_idx_first_element = 0;
    
    double diff[IDX_PERIOD_MAX] = {};
    bool bdiff = true;
    
    int total = m_list.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        if( 0 == cnt ) period_idx_first_element = b.GetPeriodIdx();
        output1[cnt] = 0;
        
        ///
        diff[cnt] =  m_Matrix[b.GetPeriodIdx()][0].DIFF;
        if( 0 < cnt )
        {
            if( 0 < output1[0])
            {
                if( diff[cnt-1] > diff[cnt] )
                {
                    //bdiff = false;
                }
            }
            if( 0 > output1[0])
            {
                if( diff[cnt-1] < diff[cnt] )
                {
                    //bdiff = false;
                }
            }
        }
        ///
        
        line1[cnt] = StringFormatResultBuffer( m_Matrix[b.GetPeriodIdx()][0], output1[cnt] );
        if( 4 <= output1[cnt] )
        {
            output++;
        }
        if( -4 >= output1[cnt] )
        {
            output--;
        }
    }    
    
    //
    // print SUM footer
    // 
    string footer;
    footer = StringFormat( "SUM - 0x%04x - %s - %s", MathAbs(output),
                    TimeToString(   (datetime)(m_Matrix[period_idx_first_element][0].DATETIME+60)), 
                    DoubleToString( m_Matrix[period_idx_first_element][0].CLOSE,Digits()) );

    //if( (+1*total == output) && (4 == output1[0]) )
    //if( (0 < output1[0]) && (true == bdiff) )
    //if( (0 < output1[0]) && (150 < diff[0]) )
    if( +1*total == output)
    //if( 1 < output)
    {
        ts.buybo = true;
    }
    //if( (-1*total == output) && (-4 == output1[0]) )
    //if( (0 > output1[0]) && (true == bdiff) )
    //if( (0 > output1[0]) && (-150 > diff[0]) )
    if( -1*total == output)
    //if( -1 > output)
    {
        ts.sellbo = true;
    }

    // TODO make print optional
    if( ts.buybo || ts.sellbo ) 
    {    
        for( int cnt = 0; cnt < total; cnt++ )
        {
            //Print( line1[ cnt ] );
        }    
        //Print( footer );
    }                    

    return ts;
} // STradeSignals CRiPeriod::GetResultofMatrix()  
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| CRiPeriod::Get()
//+------------------------------------------------------------------+
double CRiPeriod::Get(ENUM_TIMEFRAMES period, ENUM_BUF_IDX buf_index, int shift_index )  
{ 
    double value = 0.0;
    int cnt = -1;
    
    switch( period )
    {
        case PERIOD_M1: 
                cnt = m_access_index[IDX_PERIOD_M1];
            break;
        case PERIOD_M5: 
                cnt = m_access_index[IDX_PERIOD_M5];
            break;
        case PERIOD_M15: 
                cnt = m_access_index[IDX_PERIOD_M15];
            break;
        case PERIOD_H1: 
                cnt = m_access_index[IDX_PERIOD_H1];
            break;
        case PERIOD_H4: 
                cnt = m_access_index[IDX_PERIOD_H4];
            break;
        // TODO implement error handling    
        //default:
        //    return -1;
    };
    if( (0 <= cnt ) && ( cnt < m_list.Total() ) )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        value = b.Get(  buf_index, shift_index ); 
    }
    return value;
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| CRiPeriod::ConfigAndLoad()
//+------------------------------------------------------------------+
int CRiPeriod::ConfigAndLoad( int& plot_index, int& idx_buf_index )
{

    int err = 0;
    
    //
    // Load history  
    //
    datetime dtto   = TimeLocal();
    datetime dtfrom = TimeLocal();
    MqlDateTime mdtfrom;
    TimeToStruct( dtfrom, mdtfrom );
    mdtfrom.day = 1;
    mdtfrom.mon = 1;
    //mdtfrom.year = mdtfrom2.year-1;
    dtfrom = StructToTime( mdtfrom );
    string s_loadh;
    err=CheckLoadHistory(m_symbol,m_period,dtfrom); 
    switch(err) 
    { 
        case -1 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Unknown symbol " + m_symbol;                 break; 
        case -2 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Requested bars more than max bars in chart"; break; 
        case -3 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Program was stopped";                        break; 
        case -4 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Indicator shouldn't load its own data";      break; 
        case -5 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Load failed";                                break; 
        case  0 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Loaded OK";                                  break; 
        case  1 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Loaded previously";                          break; 
        case  2 : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Loaded previously and built";                break; 
        default : s_loadh = m_symbol + " " + string(m_period) + " " + string(dtfrom) + " Unknown result"; 
    } 
    Print(s_loadh);
    if( 0 > err )
    {
        return (err);
    }
    else
    {
        err = 0;
    }

    //
    // initialise the period in minutes
    //
    int total = m_list.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        b.ConfigBuffers(   plot_index, idx_buf_index );
    }    
    
    if( 0 == err )
    {
        m_configured_and_loaded = true;
    }
    return err;

} // void CRiPeriod::ConfigAndLoad
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
void CRiPeriod::AddChartData(
        // chart data index
        // TODO might be rates_total - 1 here as well
        // in case the timeseries doesn't work out with the indexing
        const int       idx,
        
        // chart data
        const int       a_rates_total,
        const int       a_prev_calculated,
        const datetime  &a_Time[],
        const double    &a_Open[],
        const double    &a_High[],
        const double    &a_Low[],
        const double    &a_Close[],
        const long      &a_TickVolume[],
        const long      &a_Volume[],
        const int       &a_Spread[]    
                )
{

    if( false == m_configured_and_loaded )
    {
return;
    }

    if( false == IsNewBar() )
    {
//return;
    }
    
    if( a_rates_total <= idx )
        return;

    if( a_rates_total <= (idx+240) )
        return;

    
    int period;
    double dt, open, high, low, close;

    // PERIOD_M1
    
    int total = m_list.Total();
    for( int cnt = 0; cnt < total; cnt++ )
    {
        CPeriodBuffer* b = (CPeriodBuffer*)m_list.GetNodeAtIndex(cnt);
        
        period = b.GetPeriod();
        
        // base period == 1
        if( 1 == period )
        {
            dt     = (double)a_Time[idx];
            open   = a_Open[idx];
            high   = a_High[idx];
            low    = a_Low[idx];
            close  = a_Close[idx]; 
        }
        else
        {
            dt      = (double)a_Time[idx+period-1];
            open    = a_Open [idx+period-1];
            high    = a_High [ArrayMaximum(a_High,idx,period)];
            low     = a_Low  [ArrayMinimum(a_Low ,idx,period)];
            close   = a_Close[idx]; 
        }
        
        b.Set( IDX_DATETIME, idx, dt );
        //b.Set( IDX_OPEN,     idx, open );
        //b.Set( IDX_HIGH,     idx, high );
        //b.Set( IDX_LOW,      idx, low );
        b.Set( IDX_CLOSE,    idx, close );
        //b.Set( IDX_IDX0,     idx, idx_0 );
        //b.Set( IDX_IDX1,     idx, idx_1 );
        //b.Set( IDX_IDX2,     idx, idx_2 );
        //b.Set( IDX_IDX3,     idx, idx_3 );
        b.CalcValues( idx );
    } // for( int cnt = 0; cnt < total; cnt++ )
    
} // void CRiPeriod::AddChartData
//+------------------------------------------------------------------+
   
                

//+------------------------------------------------------------------+
//| Returns true if for the given symbol and timeframe there is      |
//| a new bar.                                                       |
//+------------------------------------------------------------------+
bool CRiPeriod::IsNewBar(void)
{
    datetime time[];
    if(CopyTime(m_symbol, m_period, 0, 1, time) < 1)
    {
        return false;
    }
    if(m_last_time == time[0])
    {
        return false;
    }
    m_last_time = time[0];
    return ( true );
} // bool CRiPeriod::IsNewBar(void)
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| get the bar shift from time
//+------------------------------------------------------------------+
int CRiPeriod::iBarShift(  string symbol,
                ENUM_TIMEFRAMES timeframe,
                datetime starttime,
                datetime stoptime
                )
{
    datetime Arr[];
    if(CopyTime(symbol,timeframe,starttime,stoptime,Arr)>0)
    {
        if(ArraySize(Arr)>2) 
        {
            return(ArraySize(Arr)-1);
        }
        //if(starttime<stoptime)
        if(stoptime<starttime)
        {
            return(1);
        }
        else 
        {
            return(0);
        }
    }
    else 
    {
        return(-1);
    }
} // int CRiPeriod::iBarShift
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+
datetime CRiPeriod::iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift) 
{
    if(shift < 0) return(0);
    datetime Arr[];
    if(CopyTime(asymbol, timeframe, shift, 1, Arr)>0)
        return(Arr[0]);
    else 
        return(0);
} // datetime iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift)
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| CheckLoadHistory
//+------------------------------------------------------------------+
int CRiPeriod::CheckLoadHistory(string a_symbol,ENUM_TIMEFRAMES a_period, datetime a_from_date) 
{ 
  
  
   string s_dttl = TimeToString( TimeLocal(), TIME_DATE | TIME_SECONDS );
   datetime first_date=0; 
   datetime times[100]; 
//--- check a_symbol & a_period 
   if(a_symbol==NULL || a_symbol=="") a_symbol=Symbol(); 
   if(a_period==PERIOD_CURRENT)       a_period=Period(); 
//--- check if a_symbol is selected in the Market Watch 
   if(!SymbolInfoInteger(a_symbol,SYMBOL_SELECT)) 
     { 
      if(GetLastError()==ERR_MARKET_UNKNOWN_SYMBOL) return(-1); 
      SymbolSelect(a_symbol,true); 
     } 
//--- check if data is present 
   SeriesInfoInteger(a_symbol,a_period,SERIES_FIRSTDATE,first_date); 
   if(first_date>0 && first_date<=a_from_date) return(1); 
//--- don't ask for load of its own data if it is an indicator 
   if(MQL5InfoInteger(MQL5_PROGRAM_TYPE)==PROGRAM_INDICATOR && Period()==a_period && Symbol()==a_symbol) 
      return(-4); 
//--- second attempt 
   if(SeriesInfoInteger(a_symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,first_date)) 
     { 
      //--- there is loaded data to build timeseries 
      if(first_date>0) 
        { 
         //--- force timeseries build 
         CopyTime(a_symbol,a_period,first_date+PeriodSeconds(a_period),1,times); 
         //--- check date 
         if(SeriesInfoInteger(a_symbol,a_period,SERIES_FIRSTDATE,first_date)) 
            if(first_date>0 && first_date<=a_from_date) return(2); 
        } 
     } 
//--- max bars in chart from terminal options 
   int max_bars=TerminalInfoInteger(TERMINAL_MAXBARS); 
//--- load a_symbol history info 
   datetime first_server_date=0; 
   while(!SeriesInfoInteger(a_symbol,PERIOD_M1,SERIES_SERVER_FIRSTDATE,first_server_date) && !IsStopped()) 
      Sleep(5); 
//--- fix start date for loading 
   if(first_server_date>a_from_date) a_from_date=first_server_date; 
   if(first_date>0 && first_date<first_server_date) 
      Print("Warning: first server date ",first_server_date," for ",a_symbol, 
            " does not match to first series date ",first_date); 
//--- load data step by step 
   int fail_cnt=0; 
   while(!IsStopped()) 
     { 
      //--- wait for timeseries build 
      while(!SeriesInfoInteger(a_symbol,a_period,SERIES_SYNCHRONIZED) && !IsStopped()) 
         Sleep(5); 
      //--- ask for built bars 
      int bars=Bars(a_symbol,a_period); 
      if(bars>0) 
        { 
         if(bars>max_bars)
         {
            Print( a_symbol + " " + ConvertPeriodToString(a_period) + " " + s_dttl + " ERROR - BARS LOADED: "+ IntegerToString(bars) + " >= TERMINAL_MAXBARS: " + IntegerToString(max_bars) );
            return(-2); 
         }
         //--- ask for first date 
         if(SeriesInfoInteger(a_symbol,a_period,SERIES_FIRSTDATE,first_date)) 
            if(first_date>0 && first_date<=a_from_date) return(0); 
        } 
      //--- copying of next part forces data loading 
      int count_to_be_copied = 100;
      int copied=CopyTime(a_symbol,a_period,bars,count_to_be_copied,times); 
      Print( a_symbol + " " + ConvertPeriodToString(a_period) + " " + s_dttl + 
                " FORCE DATA LOADING - BARS: "+ IntegerToString(bars) + " COPIED: " + IntegerToString(copied) + 
                " CHART START TIME: " + TimeToString(times[0]) + " FROM_DATE: " + TimeToString( a_from_date ) 
            );
      if(copied>=count_to_be_copied) 
        { 
         //--- check for data 
         if(times[0]<=a_from_date)  return(0); 
         if(bars+copied>=max_bars)  return(-2); 
         fail_cnt=0; 
        } 
      else 
        { 
         //--- no more than 1 failed attempts 
         fail_cnt++; 
         if(fail_cnt>=1) return(-5); 
         Sleep(10); 
        } 
     } 
//--- stopped 
   return(-3); 
} // int CRiPeriod::CheckLoadHistory(string a_symbol,ENUM_TIMEFRAMES a_period, datetime a_from_date) 
//+------------------------------------------------------------------+ 

// TODO duplicate - create indicator library
//+------------------------------------------------------------------+
//| ConvertPeriodToString
//+------------------------------------------------------------------+
string CRiPeriod::ConvertPeriodToString( ENUM_TIMEFRAMES timeframe ) 
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
} // string CRiPeriod::ConvertPeriodToString( ENUM_TIMEFRAMES timeframe )
//+------------------------------------------------------------------+
