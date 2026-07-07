//=====================================================================
//	CCI T4 indicator.
//=====================================================================
#property copyright "Copyright 2014, Andre Howe"
#property link      "andrehowe.com"
#property version			"1.1"
#property description	"ALL T7 Indicator"
//---------------------------------------------------------------------
#property indicator_separate_window
//#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   7
//---------------------------------------------------------------------

#property indicator_type1	   DRAW_NONE
#property indicator_label1     "Buy"

#property indicator_type2	   DRAW_NONE
#property indicator_label2     "Sell"

#property indicator_type3	   DRAW_NONE
#property indicator_label3     "Exit"


#property indicator_label4	   "CMP1"
//#property indicator_type4		DRAW_COLOR_HISTOGRAM
#property indicator_type4		DRAW_COLOR_LINE
#property indicator_color4	   clrNONE, clrLightGray, clrGreen, 0xFFCCCC, 0xFF9999, 0xFF6666, 0xFF3333, 0xFF0000, 0xCCCCFF, 0x9999FF, 0x6666FF, 0x3333FF, 0x0000FF
#property indicator_style4	   STYLE_SOLID
#property indicator_width4	   1

#property indicator_label5	   "CMP2"
#property indicator_type5		DRAW_COLOR_HISTOGRAM
//#property indicator_type5		DRAW_COLOR_LINE
#property indicator_color5	   clrNONE, clrLightGray, clrGreen, 0xFFCCCC, 0xFF9999, 0xFF6666, 0xFF3333, 0xFF0000, 0xCCCCFF, 0x9999FF, 0x6666FF, 0x3333FF, 0x0000FF
#property indicator_style5	   STYLE_SOLID
#property indicator_width5	   2

enum ColorEnum
{
    eClrNone = 0,
    eClrGray,
    eClrGreen,
    eClrBlue1,
    eClrBlue2,
    eClrBlue3,
    eClrBlue4,
    eClrBlue5,
    eClrRed1,
    eClrRed2,
    eClrRed3,
    eClrRed4,
    eClrRed5,
};

//=====================================================================
//	External parameters:
//=====================================================================
input string                 FROM_TO_DATE  = "DD.MM.YYYY-DD.MM.YYYY";
input int                    AVG_CANDLE_HEIGHT = 0;// AVG_CANDLE_HEIGHT - if zero calc candle height, otherwise set this value
input int                    SL_LEVEL  = 5; // SL_LEVEL - if AVG_CANDLE_HEIGHT(0), then set double
input int                    SR_PERIOD = 0;  // SR_PERIOD - if NULL calculate shift since day has started
/*input */int                    ATRX_lvl  = 300;


/*int							 Period1 = 5;
int							 Period2 = 15;
int							 Period3 = 60;
int							 Period4 = 240;
*/
/*
int							 Period1 = 2;
int							 Period2 = SL_LEVEL;
int							 Period3 = 18;
int							 Period4 = 54;
*/

int							 Period1 = 15;
int							 Period2 = 60;
int							 Period3 = 120;
int							 Period4 = 240;

const string gIndicatorName = "ALL_T7";

//#include <library.mqh>

//---------------------------------------------------------------------
double	BuyBuff[ ];
double	SellBuff[ ];
double	ExitBuff[ ];
double	ValueBuff[ ];
double	ColorBuff[ ];
double	ValueBuff1[ ];
double	ColorBuff1[ ];
double	Ma1Buff[ ];
double	Ma2Buff[ ];
double	Ma3Buff[ ];
double	Ma4Buff[ ];

//---------------------------------------------------------------------

//---------------------------------------------------------------------
int				ma1_handler;
int				ma2_handler;
int				ma3_handler;
int				ma4_handler;


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
	SetIndexBuffer( 5, ValueBuff1,INDICATOR_DATA );
	SetIndexBuffer( 6, ColorBuff1,INDICATOR_COLOR_INDEX );
	SetIndexBuffer( 7, Ma1Buff,    INDICATOR_CALCULATIONS );
	SetIndexBuffer( 8, Ma2Buff,    INDICATOR_CALCULATIONS );
	SetIndexBuffer( 9, Ma3Buff,    INDICATOR_CALCULATIONS );
	SetIndexBuffer( 10, Ma4Buff,    INDICATOR_CALCULATIONS );

    ArraySetAsSeries( BuyBuff, true );
    ArraySetAsSeries( SellBuff, true );
    ArraySetAsSeries( ExitBuff, true );
    ArraySetAsSeries( ValueBuff, true );
    ArraySetAsSeries( ColorBuff, true );
    ArraySetAsSeries( ValueBuff1, true );
    ArraySetAsSeries( ColorBuff1, true );
    ArraySetAsSeries( Ma1Buff, true );
    ArraySetAsSeries( Ma2Buff, true );
    ArraySetAsSeries( Ma3Buff, true );
    ArraySetAsSeries( Ma4Buff, true );
    
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
	IndicatorSetString( INDICATOR_SHORTNAME, "ALL T7( Periods = " + string( Period1 ) + " / " + string( Period2 )  + " / " + string( Period3 ) + " / " + string( Period4 ) + " )" );

	//s_r1_handler = iCustom( Symbol( ), Period( ), "support_resistance", 0,AVG_CANDLE_HEIGHT,SR_PERIOD );
	
	
	ma1_handler = iMA(Symbol( ), Period( ), Period1, 0, MODE_SMA, PRICE_OPEN );
	if( ma1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA1 indicator" );
		return( -1 );
	}
	ma2_handler = iMA(Symbol( ), Period( ), Period2, 0, MODE_SMA, PRICE_OPEN );
	if( ma2_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA2 indicator" );
		return( -1 );
	}
	ma3_handler = iMA(Symbol( ), Period( ), Period3, 0, MODE_SMA, PRICE_OPEN );
	if( ma3_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA3 indicator" );
		return( -1 );
	}

	ma4_handler = iMA(Symbol( ), Period( ), Period4, 0, MODE_SMA, PRICE_OPEN );
	if( ma4_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA4 indicator" );
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
    
    // TODO FIXME INDICATOR START
    //if( true == TESTERMODE )
    //{
    //    start = 100;
    //}
    start = 4* 3*24*60;
    if( MQL5InfoInteger(MQL5_TESTER) )
    {
        start = 100;
    }   
    
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

    
    
	if( CopyBuffer( ma1_handler, 0, 0, rates_total - 1, Ma1Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( ma2_handler, 0, 0, rates_total - 1, Ma2Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( ma3_handler, 0, 0, rates_total - 1, Ma3Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( ma4_handler, 0, 0, rates_total - 1, Ma4Buff ) == -1 )
	{
		return( rates_total );
	}

    //Print( " start: " + IntegerToString(start ) + " prev_calculated: " + IntegerToString(prev_calculated )  + " rates_total: " + IntegerToString(rates_total ));

    if( (0 == prev_calculated) || ((1==CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ))&&(0<start)) )
    {
    
        ///
        double aPrev = 0.0;
        double a1Prev = 0.0;
        ///
    
        for( int i = start-12; i > 0; i-- )
        {
            // TODO implement the laoding of history data here
    		//if( i >= (ArraySize( ExitBuff )) )
    		//{
    		//    //continue;
    		//}
            ExitBuff[i]   = 0.0;
            SellBuff[i]   = 0.0;
            BuyBuff[i]    = 0.0;
            //ValueBuff[i]  = 0.0;
            ColorBuff[i]  = 0;
            ValueBuff1[i] = 0.0;
            ColorBuff1[i] = 0;
            
            bool buyflag = false;
            bool sellflag = false;
            bool exitflag = false;
            bool buyflag2 = false;
            bool sellflag2 = false;
            
            double cl = Close[i];
            
            int atrx_period = SR_PERIOD;
            if( 0 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceDayStarted2(i);
                if( 0 == atrx_period )
                {
                   continue;
                }
            }
            if( 1 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceWeekStarted(i);
                if( 0 == atrx_period )
                {
                   continue;
                }
            }
            
            if( (atrx_period<(rates_total-i)) && (0<atrx_period) )
            {
                double max=High[ArrayMaximum(High,i,atrx_period)];
                double min=Low[ArrayMinimum(Low,i,atrx_period)];
                double atr = (max-min)/Point();
                cl = atr;
            }
            if( 1 == i ) Comment(IntegerToString(atrx_period));
            
            if(   
                (Ma1Buff[i]>Ma2Buff[i])
                //( (Ma1Buff[i]>Ma2Buff[i]) && (Ma2Buff[i]>Ma3Buff[i]) && (Ma3Buff[i]>Ma4Buff[i]) )
                //&& (ATRX_lvl<cl) 
                //&& (Low[i] > Ma1Buff[atrx_period]+/*AVG_CANDLE_HEIGHT*/40*Point() /*-->ResistanceBuff[i]*/ ) 
                )
            {
                //BuyBuff[i] = Close[i];
                buyflag = true;
            }
            if(    
                (Ma1Buff[i]<Ma2Buff[i])
                //( (Ma1Buff[i]<Ma2Buff[i]) && (Ma2Buff[i]<Ma3Buff[i]) && (Ma3Buff[i]<Ma4Buff[i]) )
                //&& (ATRX_lvl<cl) 
                //&& (High[i] < Ma1Buff[atrx_period]-/*AVG_CANDLE_HEIGHT*/40*Point()/*-->SupportBuff[i]*/) 
                )
            {
                //SellBuff[i] = Close[i];
                sellflag = true;
            }
            
            if(    
                    ((Ma1Buff[i]>Ma2Buff[i]) && (Ma1Buff[i+1]<Ma2Buff[i+1]))
                 || ((Ma1Buff[i]<Ma2Buff[i]) && (Ma1Buff[i+1]>Ma2Buff[i+1]))
                )
            {
                exitflag = true;
                //ExitBuff[i] = Close[i];
                
            }
            
            //ValueBuff[ i ] =  = Ma1Buff[i] + Ma2Buff[i] + Ma3Buff[i] + Ma4Buff[i];
            //ValueBuff[ i ] =  = (Ma1Buff[i] - Ma4Buff[i])/Point();
            //ValueBuff[ i ] = (Ma1Buff[i] - Ma2Buff[i])/Point();
            //ValueBuff[ i ] = (((Ma1Buff[i]+Ma2Buff[i]+Ma3Buff[i])/3) - Ma4Buff[i])/Point();
            
            
            int factor1 = Period2;
            double factor2 = 1;
            // factor = Ma2Period * current Period in Minutes
            double factor4 = factor1 * PeriodSeconds( Period() ) / 60;
                        
            double avg = getAvgCandleHeight(factor1,High, Low, i )/Point();
            double val = 0;
            //if ( 0 < (Ma1Buff[i]-Ma1Buff[atrx_period+i]) )
            //if ( 0 < (Close[i]-((Ma1Buff[atrx_period+i]+Ma2Buff[atrx_period+i]+Ma3Buff[atrx_period+i]+Ma4Buff[atrx_period+i])/4)) )
            //if ( 0 < (Close[i]-Close[atrx_period+i]) )
            //if ( 0 < (Ma1Buff[i]-Ma4Buff[i]) )
            if ( Ma2Buff[i] < Close[i] )
            {
                val = factor2*avg;
            }
            else if ( Ma2Buff[i] > Close[i] )
            {
                val = -factor2*avg;
            }
            
            // differential
            //val = (Ma1Buff[i] - Ma4Buff[i])/Point() + ValueBuff[ i+1 ];
            
            //ExitBuff[i]   = avg;
            // PercentageCrossover.mq5
            double var1=/*percent*/ 0.1 /100;
            double plusvar=1+var1;
            double minusvar=1-var1;
            double Middle = 0; 
            double price = Close[i];  
            if((price*minusvar)>ExitBuff[i+1]) 
            {
                Middle=price*minusvar;
            }
            else if(price*plusvar<ExitBuff[i+1])
            {
                Middle=price*plusvar;
            }
            else
            { 
                Middle=ExitBuff[i+1];
            }
            ExitBuff[i]=Middle;  
            
            //if( 100 < cl )
            //if( factor4 < MathAbs(avg) )
            {
                ValueBuff[ i ] = val;
            }
            
            ///
            /*double max=Ma4Buff[ArrayMaximum(Ma1Buff,i,60)];
            double min=Ma4Buff[ArrayMinimum(Ma1Buff,i,60)];
            double ld_80 = Ma1Buff[i] - Ma4Buff[i];//Close[i];//(High[i] + Low[i]) / 2.0;
            double idiv = (max - min);
            double ld_32 = 0.0;
            if( 0.0 != idiv ) ld_32 = 0.66 * ((ld_80 - min) / idiv - 0.5) + 0.05 * a1Prev;
            ld_32 = MathMin(MathMax(ld_32, -0.999), 0.999);
            cl = MathLog((ld_32 + 1.0) / (1 - ld_32)) / 2.0 + aPrev / 2.0;
            a1Prev = ld_32;
            aPrev = cl;*/
            ///
                

            ValueBuff1[ i ] = (((2*Close[i]+High[i]+Low[i])/4) - Ma1Buff[i])/Point();
            ValueBuff1[ i ] = (Close[i] - Ma2Buff[i])/Point();
            //ValueBuff1[ i ] = (Ma1Buff[i] - Ma2Buff[i])/Point();
            //ValueBuff1[ i ] = (Ma1Buff[i]-Ma1Buff[atrx_period+i])/Point();
            //ValueBuff1[ i ] = (Close[i]-Close[atrx_period+i])/Point();
            
            // integral
            //ValueBuff1[ i ] = (ValueBuff[ i ] - ValueBuff[ i+1 ])/1;
            
            ColorBuff1[ i ] = eClrGray;
    
            // buy
            if( true == buyflag )
            {
            	ColorBuff[ i ] = eClrBlue1;
            	if ( (Ma1Buff[i]>Ma2Buff[i]) && (Ma2Buff[i]>Ma3Buff[i]) && (Ma3Buff[i]>Ma4Buff[i]) )
            	    {
            	    ColorBuff[ i ] = eClrBlue5;
            	    }
            }
            // sell
            else if( true == sellflag )
            {
            	ColorBuff[ i ] = eClrRed1;
            	if ( (Ma1Buff[i]<Ma2Buff[i]) && (Ma2Buff[i]<Ma3Buff[i]) && (Ma3Buff[i]<Ma4Buff[i]) )
            	    {
            	        ColorBuff[ i ] = eClrRed5;
            	    }
            }
            // neutral
            else
            {
            	ColorBuff[ i ] = eClrGray;
            }
            if( true == exitflag )
            {
            	ColorBuff[ i ] = eClrGreen;
            }
            
            /*double factor3 = 0.0001;
            if
            (   
                 ( Close[i] - Close[i+1]  > factor3 )  
              && ( Close[i] - Close[i+5]  > factor3 )  
              //&& ( Close[i] - Close[i+15] > factor3 )  
              //&& ( Close[i] - Close[i+30] > factor3 )  
              //&& ( Close[i] - Close[i+60] > factor3 )  
              && ( ValueBuff1[i] > 1.5*ValueBuff[i] ) 
              && ( Ma1Buff[i]>Ma4Buff[i] )  
              //&& ( Close[i] - Ma4Buff[i+atrx_period]> factor3 )  
            )
            {
                ColorBuff1[ i ] = eClrBlue5;//ColorBuff[ i ];
                BuyBuff[i] = Close[i];
            }
            else 
            if
            (   
                 ( Close[i+1]  - Close[i] > factor3 )  
              && ( Close[i+5]  - Close[i] > factor3 )  
              //&& ( Close[i+15] - Close[i] > factor3 )  
              //&& ( Close[i+30] - Close[i] > factor3 )  
              //&& ( Close[i+60] - Close[i] > factor3 )  
              && ( ValueBuff1[i] < 1.5*ValueBuff[i] ) 
              && ( Ma1Buff[i]<Ma4Buff[i] ) 
              //&& ( Ma4Buff[i+atrx_period] - Close[i]> factor3 )  
            )
            {
                ColorBuff1[ i ] = eClrRed5;//ColorBuff[ i ];
                SellBuff[i] = Close[i];
            }*/  

            factor4 = 2;
            /*
            
             Period Sec    Factor
               M1   60s    4
               M5   300s   3
               M15  900s   2
               H1   3600s  1.5
            */
            
            double factor5 = MathAbs(ValueBuff[i]); // /*50;//*/avg;
            
            switch( Period() )
            {
                case PERIOD_M1:
                    factor4 = 2;
                break;
                case PERIOD_M5:
                    factor4 = 1.5;
                break;
                case PERIOD_M15:
                    factor4 = 1.1;
                break;
                case PERIOD_H1:
                    factor4 = 0.9;
                break;
            }
           

            //if( factor4 < MathAbs(avg) )
            
        	if ( (Ma1Buff[i]>Ma2Buff[i]) && (Ma2Buff[i]>Ma3Buff[i]) && (Ma3Buff[i]>Ma4Buff[i]) )
        	    {
        	    ColorBuff1[ i ] = eClrGreen;
        	    }
        	if ( (Ma1Buff[i]<Ma2Buff[i]) && (Ma2Buff[i]<Ma3Buff[i]) && (Ma3Buff[i]<Ma4Buff[i]) )
        	    {
        	        ColorBuff1[ i ] = eClrGreen;
        	    }


            if
            (   

               /*( factor4*ValueBuff[i] < ValueBuff1[i] ) 
            && (( 0 < ValueBuff[i] ) && ( 0 < ValueBuff1[i] ))
            && ( factor5 < (ValueBuff1[i] -ValueBuff1[i+1]) ) */
            
            /*   ( factor4*ValueBuff[i] < ValueBuff1[i] ) 
            && (( 0 < ValueBuff[i] ) && ( 0 < ValueBuff1[i] ))
            //&& ( factor5 < (ValueBuff1[i] -ValueBuff1[i+1]) )
            &&*/ (Ma1Buff[i]>Ma1Buff[i+1]) && (Ma1Buff[i+1]>Ma1Buff[i+2]) 
            && (Ma2Buff[i]>Ma2Buff[i+1]) && (Ma2Buff[i+1]>Ma2Buff[i+2]) 
            //&& Open[i] > Ma4Buff[i]
            && Ma1Buff[i] > Ma4Buff[i]
 
            )
            {
                ColorBuff1[ i ] = eClrBlue5;//ColorBuff[ i ];
                BuyBuff[i] = Close[i];
            }
            else 
            if
            (   
 
            /*  ( factor4*ValueBuff[i] > ValueBuff1[i] ) 
            && (( 0 > ValueBuff[i] ) && ( 0 > ValueBuff1[i] ))   
            //&& ( -1*factor5 > (ValueBuff1[i] -ValueBuff1[i+1]) )
            &&*/ (Ma1Buff[i]<Ma1Buff[i+1]) && (Ma1Buff[i+1]<Ma1Buff[i+2]) 
            && (Ma2Buff[i]<Ma2Buff[i+1]) && (Ma2Buff[i+1]<Ma2Buff[i+2]) 
            //&& Open[i] < Ma4Buff[i]
            && Ma1Buff[i] < Ma4Buff[i]

            )
            {
                ColorBuff1[ i ] = eClrRed5;//ColorBuff[ i ];
                SellBuff[i] = Close[i];
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
	if( ma1_handler != INVALID_HANDLE )
	{
		IndicatorRelease( ma1_handler );
	}
	if( ma2_handler != INVALID_HANDLE )
	{
		IndicatorRelease( ma2_handler );
	}
	if( ma3_handler != INVALID_HANDLE )
	{
		IndicatorRelease( ma3_handler );
	}
	if( ma4_handler != INVALID_HANDLE )
	{
		IndicatorRelease( ma4_handler );
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
    /*
    MqlDateTime tm;
    datetime starttime = iTime(Symbol(),Period(),shift);
    TimeToStruct( starttime, tm );
    
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    shift = iBarShift(Symbol(),Period(),starttime,stoptime);
    */
    shift = 24 * 3600/PeriodSeconds(Period());
    return (shift);
    
} // int m_indiGetShiftSinceDayStarted2( int shift )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceWeekStarted
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceWeekStarted( int shift )
{
    /*
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
    */
    shift = 24*5 * 3600/PeriodSeconds(Period());
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


datetime iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift) {
    if(shift < 0) return(0);
    datetime Arr[];
    if(CopyTime(asymbol, timeframe, shift, 1, Arr)>0)
        return(Arr[0]);
    else 
        return(0);
} // datetime iTime(string asymbol,ENUM_TIMEFRAMES timeframe,int shift)


//+------------------------------------------------------------------+
//| Calculate average candle height                                  |
//+------------------------------------------------------------------+
double getAvgCandleHeight(const int rates_total,const double &High[],const double &Low[], const int shift = 0)
  {
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   double sum=0.0;
   int rt = rates_total;
   if( 10 > rt ) rt = 10;
   for(int i=0;i<rt-1;i++)
     {
        // TODO implement the laoding of history data here
        if( (shift+i) >= (ArraySize( High )) )
        {
            continue;
        }
        if( (shift+i) >= (ArraySize( Low )) )
        {
            continue;
        }
      sum+=High[shift+i]-Low[shift+i];
     }
   return sum/(rt-1);
  }

