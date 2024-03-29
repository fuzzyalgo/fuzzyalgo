//=====================================================================
//	CCI T3 indicator.
//=====================================================================
#property copyright "Copyright 2014, André Howe"
#property link      "andrehowe.com"
#property version       "1.1"
#property description   "ALL T3 Indicator"
//---------------------------------------------------------------------
#property indicator_separate_window
//#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   5
//---------------------------------------------------------------------

#property indicator_type1	   DRAW_NONE
#property indicator_label1     "Buy"

#property indicator_type2	   DRAW_NONE
#property indicator_label2     "Sell"

#property indicator_type3	   DRAW_NONE
#property indicator_label3     "Exit"


#property indicator_label4	   "ATRX1"
#property indicator_type4		DRAW_COLOR_HISTOGRAM
//#property indicator_type4		DRAW_COLOR_LINE
#property indicator_color4	   clrNONE, clrBlue, clrRed, clrLightGray, clrBlueViolet, clrPink,clrGreen
#property indicator_style4	   STYLE_SOLID
#property indicator_width4	   2

//=====================================================================
//	External parameters:
//=====================================================================
input string                 FROM_TO_DATE  = "DD.MM.YYYY-DD.MM.YYYY";
input int                    AVG_CANDLE_HEIGHT = 0;// AVG_CANDLE_HEIGHT - if zero calc candle height, otherwise set this value
input int                    SL_LEVEL  = 0; // SL_LEVEL - if AVG_CANDLE_HEIGHT(0), then set double
input int                    SR_PERIOD = 0;  // SR_PERIOD - if NULL calculate shift since day has started
input int                    ATRX_lvl  = 100;


int							 CCI1_Period = 15;
int							 CCI2_Period = 60;
ENUM_APPLIED_PRICE	         CCI_Price_Type = PRICE_OPEN;
int                          CCI_lvl     = 10; // CCI_lvl typically 99;
//---------------------------------------------------------------------

const string gIndicatorName = "ALL_T3";

//#include <library.mqh>

//---------------------------------------------------------------------
double	BuyBuff[ ];
double	SellBuff[ ];
double	ExitBuff[ ];
double	ValueBuff[ ];
double	ColorBuff[ ];
double	CCI1Buff[ ];
double	CCI2Buff[ ];
double  ResistanceBuff[];   // resistance - support resistance buffer
double  SupportBuff[];      // support    - support resistance buffer
double	Ma1Buff[ ];
double	Ma2Buff[ ];

//---------------------------------------------------------------------

//---------------------------------------------------------------------
int				cci1_handler;
int				cci2_handler;
int				s_r1_handler;
int				ma1_handler;
int				ma2_handler;
//---------------------------------------------------------------------
int				cci_bars_calculated = 0;																		// number of values in the CCI indicator


//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int
OnInit( )
{
	Comment( "" );

    SetIndexBuffer( 0, BuyBuff,INDICATOR_DATA );
    SetIndexBuffer( 1, SellBuff,INDICATOR_DATA );
    SetIndexBuffer( 2, ExitBuff,INDICATOR_DATA );
	SetIndexBuffer( 3, ValueBuff,INDICATOR_DATA );
	SetIndexBuffer( 4, ColorBuff,INDICATOR_COLOR_INDEX );
	SetIndexBuffer( 5, CCI1Buff, INDICATOR_CALCULATIONS );
	SetIndexBuffer( 6, CCI2Buff, INDICATOR_CALCULATIONS );
	SetIndexBuffer( 7, ResistanceBuff, INDICATOR_DATA );
	SetIndexBuffer( 8, SupportBuff,    INDICATOR_DATA );
	SetIndexBuffer( 9, Ma1Buff,    INDICATOR_CALCULATIONS );
	SetIndexBuffer( 10,Ma2Buff,    INDICATOR_CALCULATIONS );

    ArraySetAsSeries( BuyBuff, true );
    ArraySetAsSeries( SellBuff, true );
    ArraySetAsSeries( ExitBuff, true );
    ArraySetAsSeries( ValueBuff, true );
    ArraySetAsSeries( ColorBuff, true );
    ArraySetAsSeries( CCI1Buff, true );
    ArraySetAsSeries( CCI2Buff, true );
    ArraySetAsSeries( ResistanceBuff, true );
    ArraySetAsSeries( SupportBuff, true );
    ArraySetAsSeries( Ma1Buff, true );
    ArraySetAsSeries( Ma2Buff, true );
    
	PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 3, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 5, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 6, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 7, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 8, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 9, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 10, PLOT_EMPTY_VALUE, 0.0 );

	IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));
	IndicatorSetString( INDICATOR_SHORTNAME, "ALL T3( CCI1 = " + string( CCI1_Period ) + " CCI2 = " + string( CCI2_Period )  + " )" );

	//cci1_handler = iCustom( Symbol( ), Period( ), "cci_t3", CCI1_Period, CCI_Price_Type,5, 0.618 );
	cci1_handler = iCCI(Symbol( ), Period( ), CCI1_Period, CCI_Price_Type );
	if( cci1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the CCI1 indicator" );
		return( -1 );
	}
	//cci2_handler = iCustom( Symbol( ), Period( ), "cci_t3", CCI2_Period, CCI_Price_Type,5, 0.618 );
	cci2_handler = iCCI(Symbol( ), Period( ), CCI2_Period, CCI_Price_Type );
	if( cci2_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the CCI2 indicator" );
		return( -1 );
	}

	s_r1_handler = iCustom( Symbol( ), Period( ), "support_resistance", 0,AVG_CANDLE_HEIGHT,SR_PERIOD );
	if( s_r1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the S_R1 indicator" );
		return( -1 );
	}
	
	
	ma1_handler = iMA(Symbol( ), Period( ), CCI1_Period, 0, MODE_SMA, CCI_Price_Type );
	if( ma1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA1 indicator" );
		return( -1 );
	}

	ma2_handler = iMA(Symbol( ), Period( ), CCI2_Period, 0, MODE_SMA, CCI_Price_Type );
	if( ma2_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA1 indicator" );
		return( -1 );
	}
	
	ChartRedraw( );

	return( 0 );
}

//---------------------------------------------------------------------
//	Indicator calculation event handler:
//---------------------------------------------------------------------
//---------------------------------------------------------------------
int
OnCalculate(const int rates_total,
            const int prev_calculated,
            const datetime &Time[],
            const double &Open[],
            const double &High[],
            const double &Low[],
            const double &Close[],
            const long &TickVolume[],
            const long &Volume[],
            const int &Spread[])
{

    ArraySetAsSeries( Time, true );
    bool is =ArrayGetAsSeries( Time );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Open, true );
    is =ArrayGetAsSeries( Open );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( High, true );
    is =ArrayGetAsSeries( High );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Low, true );
    is =ArrayGetAsSeries( Low );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Close, true );
    is =ArrayGetAsSeries( Close );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( TickVolume, true );
    is =ArrayGetAsSeries( TickVolume );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Volume, true );
    is =ArrayGetAsSeries( Volume );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Spread, true );
    is =ArrayGetAsSeries( Spread );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }

    //int				values_to_copy;
	static datetime	last_bar_datetime_chart = 0;
	
    if( prev_calculated == 0)
    {
        last_bar_datetime_chart = 0;
        ObjectsDeleteAll(0, gIndicatorName);
        ChartRedraw( );
    	
    } // if( prev_calculated == 0)
    int start = rates_total-prev_calculated;
    // TODO explain 12 here, see below
    if( rates_total <= (start+12) )
    {
        start = rates_total - 1 - 12;
    }
    if( rates_total > (100+1+12) )
    {
        if( 100 > start )
        {
            start = 100;
        }
    }
    // TODO FIXME INDICATOR START
    //if( true == TESTERMODE )
    //{
    //    start = 100;
    //}
    //start = 30*24*60;
    if( MQL5InfoInteger(MQL5_TESTER) )
    {
        start = 100;
    }
    
	if( CopyBuffer( cci1_handler, 0, 0, rates_total - 1, CCI1Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( cci2_handler, 0, 0, rates_total - 1, CCI2Buff ) == -1 )
	{
		return( rates_total );
	}

	if( CopyBuffer( s_r1_handler, 0, 0, rates_total - 1, ResistanceBuff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( s_r1_handler, 1, 0, rates_total - 1, SupportBuff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( ma1_handler, 0, 0, rates_total - 1, Ma1Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( ma2_handler, 0, 0, rates_total - 1, Ma2Buff ) == -1 )
	{
		return( rates_total );
	}
	
	int buycnt = 0;
	int sellcnt = 0;

    //Print( " start: " + IntegerToString(start ) + " prev_calculated: " + IntegerToString(prev_calculated )  + " rates_total: " + IntegerToString(rates_total ));

    if( (0 == prev_calculated) || ((1==CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ))&&(0<start)) )
    {
        for( int i = start-12; i > 0; i-- )
		{
		
            ExitBuff[i] = 0.0;
            SellBuff[i] = 0.0;
            BuyBuff[i] = 0.0;
    		ValueBuff[i] = 0.0;
    		ColorBuff[i] = 0;
		    
            bool buyflag = false;
            bool sellflag = false;
            bool exitflag = false;
            bool buyflag2 = false;
            bool sellflag2 = false;
            double CCI_buy = +1*CCI_lvl;
            double CCI_sell = -1*CCI_lvl;
            
            double cl = Open[i];
            
            int atrx_period = SR_PERIOD;
            if( 0 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceDayStarted2(i);
                if( 0 == atrx_period )
                {
                    buycnt = 0;
            	    sellcnt = 0;
                    continue;
                }
            }
            if( 1 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceWeekStarted(i);
                if( 0 == atrx_period )
                {
                    buycnt = 0;
            	    sellcnt = 0;
                    continue;
                }
            }
            
            if( (atrx_period<(rates_total-i)) && (0<atrx_period) )
            {
                double max=High[ArrayMaximum(High,i+1,atrx_period)];
                double min=Low[ArrayMinimum(Low,i+1,atrx_period)];
                double atr = (max-min)/Point();
                cl = atr;
            }
            if( 1 == i ) Comment(IntegerToString(atrx_period));
            
            if(    (CCI_buy<CCI1Buff[i]) && (CCI_buy<CCI2Buff[i])  
                && (Ma1Buff[i]>Ma2Buff[i])
                && (ATRX_lvl<cl) 
                && (Low[i] > ResistanceBuff[i] ) 
                //&& ( 0 == buycnt )
                )
            {
                BuyBuff[i] = Open[i];
                buyflag = true;
                buycnt++;
            }
            if(    
                   (CCI_sell>CCI1Buff[i]) && (CCI_sell>CCI2Buff[i])  
                && (Ma1Buff[i]<Ma2Buff[i])
                && (ATRX_lvl<cl) 
                && (High[i] < SupportBuff[i]) 
                //&& ( 0 == sellcnt )
                )
            {
                SellBuff[i] = Open[i];
                sellflag = true;
                sellcnt++;
            }
            
            if(    
                    ((Ma1Buff[i]>Ma2Buff[i]) && (Ma1Buff[i+1]<Ma2Buff[i+1]))
                 || ((Ma1Buff[i]<Ma2Buff[i]) && (Ma1Buff[i+1]>Ma2Buff[i+1]))
                )
            {
                //exitflag = true;
                //ExitBuff[i] = Open[i];
                
            }

            /*if(    (Ma1Buff[i]>Ma2Buff[i]) && (Ma1Buff[i+1]<Ma2Buff[i+1])
                )
            {
                buyflag = true;
            }
            if(    (Ma1Buff[i]<Ma2Buff[i]) && (Ma1Buff[i+1]>Ma2Buff[i+1])
                )
            {
                sellflag = true;
            }*/
            
            
            if
                (   
                     ( Open[i] - Open[i+1]  > 0.0001 )  
                  && ( Open[i] - Open[i+3]  > 0.0001 )  
                  && ( Open[i] - Open[i+6]  > 0.0001 )  
                  // TODO explain 12 here
                  && ( Open[i] - Open[i+12] > 0.001 )  
                )
            {
                buyflag2 = true;
            }
            else if
                (   
                     ( Open[i+1]  - Open[i] > 0.0001 )  
                  && ( Open[i+3]  - Open[i] > 0.0001 )  
                  && ( Open[i+6]  - Open[i] > 0.0001 )  
                  && ( Open[i+12] - Open[i] > 0.001 )  
                )
            {
                sellflag2 = true;
            }


			ColorBuff[ i ] = 3;
			ValueBuff[ i ] = cl;
            // buy
			//if( true == buyflag )
			{
    			if( true == buyflag2 )
    			{
       				ColorBuff[ i ] = 1;
    				ValueBuff[ i ] = cl;
    			}
    			else
    			{
       				//ColorBuff[ i ] = 4;
    				ValueBuff[ i ] = cl;
    			}
			}
			// sell
			//else if( true == sellflag )
			{
    			if( true == sellflag2 )
    			{
       				ColorBuff[ i ] = 2;
    				ValueBuff[ i ] = cl;
    			}
    			else
    			{
       				//ColorBuff[ i ] = 5;
    				ValueBuff[ i ] = cl;
    			}
			}
			// neutral
			/*else
			{
				ColorBuff[ i ] = 3;
				ValueBuff[ i ] = cl;
			}*/
			if( true == exitflag )
			{
   				ColorBuff[ i ] = 6;
				ValueBuff[ i ] = cl;
			}
			
		} // for( int i = start; i < rates_total - 1; i++ )
		ValueBuff[ rates_total - 1 ] = 0.0;
		ColorBuff[ rates_total - 1 ] = 0;
		
	} // if( prev_calculated == 0 || CheakNewBar( Symbol( ), Period( ), last_bar_datetime_chart ) == 1 )

	return( rates_total );
}

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void
OnDeinit( const int _reason )
{
	if( cci1_handler != INVALID_HANDLE )
	{
		IndicatorRelease( cci1_handler );
	}
	if( cci2_handler != INVALID_HANDLE )
	{
		IndicatorRelease( cci2_handler );
	}
	if( s_r1_handler != INVALID_HANDLE )
	{
		IndicatorRelease( s_r1_handler );
	}
	if( ma1_handler != INVALID_HANDLE )
	{
		IndicatorRelease( ma1_handler );
	}
	if( ma2_handler != INVALID_HANDLE )
	{
		IndicatorRelease( ma2_handler );
	}

	ChartRedraw( );
}

//---------------------------------------------------------------------
//	Returns a sign of appearance of a new bar:
//---------------------------------------------------------------------
int CheckNewBar( string _symbol, ENUM_TIMEFRAMES _period, datetime& _last_dt )
{
	datetime	curr_time = ( datetime )SeriesInfoInteger( _symbol, _period, SERIES_LASTBAR_DATE );
	if( curr_time > _last_dt )
	{
		_last_dt = curr_time;
		return( 1 );
	}

	return( 0 );
}
//---------------------------------------------------------------------

//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceDayStarted
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceDayStarted2( int shift )
{
    MqlDateTime tm;
    datetime starttime = iTime(Symbol(),Period(),shift);
    TimeToStruct( starttime, tm );
    
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    shift = iBarShift(Symbol(),Period(),starttime,stoptime);
    return (shift);
    
} // int m_indiGetShiftSinceDayStarted2( int shift )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceWeekStarted
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceWeekStarted( int shift )
{
    MqlDateTime tm;
    datetime t0 = iTime(Symbol(),Period(),shift);
    TimeToStruct( t0, tm );
    int days = 0;
    days = tm.day_of_week -1;
    if( 0 > days ) days = 0;
    if( 4 < days ) days = 4;
    datetime starttime = t0;
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    stoptime = stoptime - (datetime)(days*24*60*60);
    shift = iBarShift(Symbol(),Period(),starttime,stoptime);
    return (shift);
    
} // int m_indiGetShiftSinceWeekStarted( int shift )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| get the bar shift from time
//+------------------------------------------------------------------+
int iBarShift(  string symbol,
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
} // int iBarShiftMQL4(string symbol
//+------------------------------------------------------------------+

/*
datetime iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift) {
    if(shift < 0) return(0);
    datetime Arr[];
    if(CopyTime(asymbol, timeframe, shift, 1, Arr)>0)
        return(Arr[0]);
    else 
        return(0);
} // datetime iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift)
*/
