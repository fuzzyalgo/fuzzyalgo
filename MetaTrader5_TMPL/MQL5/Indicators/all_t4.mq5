//=====================================================================
//	T4 indicator.
//=====================================================================
#property copyright     "Copyright 2017, Andre Howe"
#property link          "andrehowe.com"
#property version       "1.1"
#property description   "ALL T4 Indicator"
//---------------------------------------------------------------------
#property indicator_separate_window
//#property indicator_chart_window
#property indicator_buffers 16
#property indicator_plots   16
//---------------------------------------------------------------------



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
    eClrMax
};

const color gColours[]={clrNONE, clrLightGray, clrGreen, 0xFFCCCC, 0xFF9999, 0xFF6666, 0xFF3333, 0xFF0000, 0xCCCCFF, 0x9999FF, 0x6666FF, 0x3333FF, 0x0000FF}; 

//=====================================================================
//	External parameters:
//=====================================================================
input string                FROM_TO_DATE    = "DD.MM.YYYY-DD.MM.YYYY";
input int                   SR_PERIOD       = 1;     // SR_PERIOD - if NULL calculate shift since day has started
input double                BO_PERCENT1     = 0.1;   // BO_PERCENT1 - breakout percentage
input double                BO_PERCENT2     = 0.2;   // BO_PERCENT2 - breakout percentage
input double                BO_PERCENT3     = 0.3;   // BO_PERCENT3 - breakout percentage

const string gIndicatorName = "ALL_T4";
const string gIndicatorInitString = gIndicatorName + " ( " + string( FROM_TO_DATE ) + " / " + string( SR_PERIOD ) + 
	                  " / " + string( BO_PERCENT1 ) + " / " + string( BO_PERCENT2 ) + " / " + string( BO_PERCENT3 ) + " ) ";


//#include <library.mqh>

//---------------------------------------------------------------------
double	BuyBuff[ ];
double	SellBuff[ ];
double	ValueDateTime[ ];
double	ValueBuffBoMiddle1[ ];
double	ValueBuffBoMiddle2[ ];
double	ValueBuffBoMiddle3[ ];
double	ValueBuffCmp1Bo1[ ];
double	ColorBuffCmp1Bo1[ ];
double	ValueBuffCmp1Bo2[ ];
double	ColorBuffCmp1Bo2[ ];
double	ValueBuffCmp1Bo3[ ];
double	ColorBuffCmp1Bo3[ ];
double	ValueBuffCmp2Diff[ ];
double	ColorBuffCmp2Diff[ ];
double	ValueBuffCmp3Int[ ];
double	ColorBuffCmp3Int[ ];

// TODO why is atrx_period = 0 working now 2017.07.07
// but not one year ago 2016.02.16 
//  atrx_period = 1 is on 2016.02.16 the first value)
// find out, fixme and document.
//if( KMidnightIndex > atrx_period )
//    reset some values
const int KMidnightIndex = 1;


//---------------------------------------------------------------------


//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int
OnInit( )
{
	Comment( "" );
	Print( "init1 " + gIndicatorInitString );

    //--- set indicator levels
    IndicatorSetInteger(INDICATOR_LEVELS,2); 
    IndicatorSetDouble(INDICATOR_LEVELVALUE,0,-1000); 
    IndicatorSetDouble(INDICATOR_LEVELVALUE,1,1000); 
    //--- set maximum and minimum for subwindow  
    IndicatorSetDouble(INDICATOR_MINIMUM,-2000); 
    IndicatorSetDouble(INDICATOR_MAXIMUM, 2000); 
   
    PlotIndexSetString (0,PLOT_LABEL,"Buy");     
    PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(0,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     0, BuyBuff,             INDICATOR_DATA );
    
    PlotIndexSetString (1,PLOT_LABEL,"Sell");     
    PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(1,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     1, SellBuff,            INDICATOR_DATA );
    
    PlotIndexSetString (2,PLOT_LABEL,"BO-DATETIME");     
    PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(2,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     2, ValueDateTime,       INDICATOR_DATA );
    
    PlotIndexSetString (3,PLOT_LABEL,"BO-MIDDLE-" + string( BO_PERCENT1 ) );     
    PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(3,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     3, ValueBuffBoMiddle1,   INDICATOR_DATA );

    PlotIndexSetString (4,PLOT_LABEL,"BO-MIDDLE-" + string( BO_PERCENT2 ) );     
    PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(4,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     4, ValueBuffBoMiddle2,   INDICATOR_DATA );

    PlotIndexSetString (5,PLOT_LABEL,"BO-MIDDLE-" + string( BO_PERCENT3 ) );     
    PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(5,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     5, ValueBuffBoMiddle3,   INDICATOR_DATA );

    
    PlotIndexSetString (6,PLOT_LABEL,"CMP1-BO-" + string( BO_PERCENT1 ) );     
    PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_COLOR_ARROW); 
    PlotIndexSetInteger(6,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(6,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(6,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(6,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(6,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     6, ValueBuffCmp1Bo1,     INDICATOR_DATA );
	SetIndexBuffer(     7, ColorBuffCmp1Bo1,     INDICATOR_COLOR_INDEX );

    PlotIndexSetString (7,PLOT_LABEL,"CMP1-BO-" + string( BO_PERCENT2 ) );     
    PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_COLOR_ARROW); 
    PlotIndexSetInteger(7,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(7,PLOT_LINE_WIDTH,2); 
    PlotIndexSetInteger(7,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(7,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(7,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     8, ValueBuffCmp1Bo2,     INDICATOR_DATA );
	SetIndexBuffer(     9, ColorBuffCmp1Bo2,     INDICATOR_COLOR_INDEX );

    PlotIndexSetString (8,PLOT_LABEL,"CMP1-BO-" + string( BO_PERCENT3 ) );     
    PlotIndexSetInteger(8,PLOT_DRAW_TYPE,DRAW_COLOR_ARROW); 
    PlotIndexSetInteger(8,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(8,PLOT_LINE_WIDTH,3); 
    PlotIndexSetInteger(8,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(8,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(8,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     10, ValueBuffCmp1Bo3,     INDICATOR_DATA );
	SetIndexBuffer(     11, ColorBuffCmp1Bo3,     INDICATOR_COLOR_INDEX );
	
	
    PlotIndexSetString (9,PLOT_LABEL,"CMP2-DIFF");     
    PlotIndexSetInteger(9,PLOT_DRAW_TYPE,DRAW_COLOR_HISTOGRAM); 
    PlotIndexSetInteger(9,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(9,PLOT_LINE_WIDTH,2); 
    PlotIndexSetInteger(9,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(9,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(9,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
	SetIndexBuffer(     12, ValueBuffCmp2Diff,   INDICATOR_DATA );
	SetIndexBuffer(     13, ColorBuffCmp2Diff,   INDICATOR_COLOR_INDEX );
	
    PlotIndexSetString (10,PLOT_LABEL,"CMP3-INT");     
    PlotIndexSetInteger(10,PLOT_DRAW_TYPE,DRAW_COLOR_LINE); 
    PlotIndexSetInteger(10,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(10,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(10,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(10,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(10,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
	SetIndexBuffer(     14, ValueBuffCmp3Int,    INDICATOR_DATA );
	SetIndexBuffer(     15, ColorBuffCmp3Int,    INDICATOR_COLOR_INDEX );

    ArraySetAsSeries( BuyBuff,              true );
    ArraySetAsSeries( SellBuff,             true );
    ArraySetAsSeries( ValueDateTime,        true );
    ArraySetAsSeries( ValueBuffBoMiddle1,    true );
    ArraySetAsSeries( ValueBuffBoMiddle2,    true );
    ArraySetAsSeries( ValueBuffBoMiddle3,    true );
    ArraySetAsSeries( ValueBuffCmp1Bo1,      true );
    ArraySetAsSeries( ColorBuffCmp1Bo1,      true );
    ArraySetAsSeries( ValueBuffCmp1Bo2,      true );
    ArraySetAsSeries( ColorBuffCmp1Bo2,      true );
    ArraySetAsSeries( ValueBuffCmp1Bo3,      true );
    ArraySetAsSeries( ColorBuffCmp1Bo3,      true );
    ArraySetAsSeries( ValueBuffCmp2Diff,    true );
    ArraySetAsSeries( ColorBuffCmp2Diff,    true );
    ArraySetAsSeries( ValueBuffCmp3Int,     true );
    ArraySetAsSeries( ColorBuffCmp3Int,     true );
    
	/*PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 3, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 5, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 6, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 7, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 8, PLOT_EMPTY_VALUE, 0.0 );*/



	IndicatorSetInteger( INDICATOR_DIGITS,  Digits( ));
	IndicatorSetString(  INDICATOR_SHORTNAME, gIndicatorInitString );

    //s.g_sr_handler = iCustom( s.SYMBOL, s.PERIOD, "all_t4", FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2,BO_PERCENT3 );
    //       handler = iCustom( Symbol(), Period(), "all_t4", "DD.MM.YYYY-DD.MM.YYYY",0,0.1,0.2,0.3 );
	
	ChartRedraw( );
	Print( "init2 " + gIndicatorInitString);

	return( 0 );
}

//---------------------------------------------------------------------
//	Indicator calculation event handler:
//---------------------------------------------------------------------
//---------------------------------------------------------------------
int
OnCalculate(const int       rates_total,
            const int       prev_calculated,
            const datetime  &Time[],
            const double    &Open[],
            const double    &High[],
            const double    &Low[],
            const double    &Close[],
            const long      &TickVolume[],
            const long      &Volume[],
            const int       &Spread[])
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
    //start = 4* 3*24*60;
    start = 10*4*5*24*60; 
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

    //Print( " start: " + IntegerToString(start ) + " prev_calculated: " + IntegerToString(prev_calculated )  + " rates_total: " + IntegerToString(rates_total ));

    if( (0 == prev_calculated) || ((1==CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ))&&(0<start)) )
    {
    
        ///
        double aPrev = 0.0;
        double a1Prev = 0.0;
        ///
    
        for( int i = start-12; i >= 0; i-- )
        {
            // TODO implement the laoding of history data here
    		//if( i >= (ArraySize( ValueBuffBoMiddle1 )) )
    		//{
    		//    //continue;
    		//}
            SellBuff[i]         = 0.0;
            BuyBuff[i]          = 0.0;
            ValueDateTime[i]    = (double)Time[i];
            ValueBuffBoMiddle1[i]= 0.0;
            ValueBuffBoMiddle2[i]= 0.0;
            ValueBuffBoMiddle3[i]= 0.0;
            ValueBuffCmp1Bo1[i]  = 0.0;
            ColorBuffCmp1Bo1[i]  = 0.0;
            ValueBuffCmp1Bo2[i]  = 0.0;
            ColorBuffCmp1Bo2[i]  = 0.0;
            ValueBuffCmp1Bo3[i]  = 0.0;
            ColorBuffCmp1Bo3[i]  = 0.0;
            ValueBuffCmp2Diff[i]= 0.0;
            ColorBuffCmp2Diff[i]= 0.0;
            ValueBuffCmp3Int[i] = 0.0;
            ColorBuffCmp3Int[i] = 0.0;
            
            bool Bo1buyflag        = false;
            bool Bo1sellflag       = false;
            bool Bo1exitflag       = false;
            bool Bo2buyflag        = false;
            bool Bo2sellflag       = false;
            bool Bo2exitflag       = false;
            bool Bo3buyflag        = false;
            bool Bo3sellflag       = false;
            bool Bo3exitflag       = false;
            
            double cl           = Close[i];
            
            int atrx_period     = SR_PERIOD;
            if( 0 == SR_PERIOD )
            {
                //atrx_period = m_IndiGetShiftSinceDayStarted2(i);
                // 24 hours -> 1 day
                atrx_period = 24 * 3600/PeriodSeconds();
                if( 0 == atrx_period )
                {
                   //continue;
                }
            }
            if( 1 == SR_PERIOD )
            {
                //atrx_period = m_IndiGetShiftSinceWeekStarted(i);
                // 24h * 5 days -> 1 week
                atrx_period = 24*5 *3600/PeriodSeconds();
                if( 0 == atrx_period )
                {
                   //continue;
                }
            }
            if( 2 == SR_PERIOD )
            {
                //atrx_period = m_IndiGetShiftSinceMonthStarted(i);
                // 24h * 5 days * 4 weeks -> 1 month
                atrx_period = 24*5*4 *3600/PeriodSeconds();
                if( 0 == atrx_period )
                {
                   //continue;
                }
            }
            if( 3 == SR_PERIOD )
            {
                //atrx_period = m_IndiGetShiftSinceYearStarted(i);
                // 24h * 5 days * 4 weeks * 12 month -> 1 year
                atrx_period = 24*5*4*12 *3600/PeriodSeconds();
                if( 0 == atrx_period )
                {
                   //continue;
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

            // BO1
            //
            // START PercentageCrossover.mq5
            // calculate BO-MIDDLE - breakout middle line
            // depending on BO_PERCENT1
            //
            
            double var1= BO_PERCENT1 /100;
            double plusvar=1+var1;
            double minusvar=1-var1;
            double Middle = 0; 
            double price = Close[i];  
            // calculate BO-MIDDLE
            if((price*minusvar)>ValueBuffBoMiddle1[i+1]) 
            {
                Middle=price*minusvar;
            }
            else if(price*plusvar<ValueBuffBoMiddle1[i+1])
            {
                Middle=price*plusvar;
            }
            else
            { 
                Middle=ValueBuffBoMiddle1[i+1];
            }
            // calculate BO-UP
            //Middle = Middle + Middle * var1;
            // calculate BO-DOWN
            //Middle = Middle - Middle * var1;
            ValueBuffBoMiddle1[i]=Middle;  

            if( ValueBuffBoMiddle1[i] > ValueBuffBoMiddle1[i+1] )
            {
                Bo1buyflag = true;
            }
            if( ValueBuffBoMiddle1[i] < ValueBuffBoMiddle1[i+1] )
            {
                Bo1sellflag = true;
            }
            
            //
            // END PercentageCrossover.mq5
            //

            // BO2
            //
            // START PercentageCrossover.mq5
            // calculate BO-MIDDLE - breakout middle line
            // depending on BO_PERCENT2
            //
            
            var1= BO_PERCENT2 /100;
            plusvar=1+var1;
            minusvar=1-var1;
            Middle = 0; 
            price = Close[i];  
            // calculate BO-MIDDLE
            if((price*minusvar)>ValueBuffBoMiddle2[i+1]) 
            {
                Middle=price*minusvar;
            }
            else if(price*plusvar<ValueBuffBoMiddle2[i+1])
            {
                Middle=price*plusvar;
            }
            else
            { 
                Middle=ValueBuffBoMiddle2[i+1];
            }
            // calculate BO-UP
            //Middle = Middle + Middle * var1;
            // calculate BO-DOWN
            //Middle = Middle - Middle * var1;
            ValueBuffBoMiddle2[i]=Middle;  

            if( ValueBuffBoMiddle2[i] > ValueBuffBoMiddle2[i+1] )
            {
                Bo2buyflag = true;
            }
            if( ValueBuffBoMiddle2[i] < ValueBuffBoMiddle2[i+1] )
            {
                Bo2sellflag = true;
            }
            
            //
            // END PercentageCrossover.mq5
            //


            // BO3
            //
            // START PercentageCrossover.mq5
            // calculate BO-MIDDLE - breakout middle line
            // depending on BO_PERCENT2
            //
            
            var1= BO_PERCENT3 /100;
            plusvar=1+var1;
            minusvar=1-var1;
            Middle = 0; 
            price = Close[i];  
            // calculate BO-MIDDLE
            if((price*minusvar)>ValueBuffBoMiddle3[i+1]) 
            {
                Middle=price*minusvar;
            }
            else if(price*plusvar<ValueBuffBoMiddle3[i+1])
            {
                Middle=price*plusvar;
            }
            else
            { 
                Middle=ValueBuffBoMiddle3[i+1];
            }
            // calculate BO-UP
            //Middle = Middle + Middle * var1;
            // calculate BO-DOWN
            //Middle = Middle - Middle * var1;
            ValueBuffBoMiddle3[i]=Middle;  

            if( ValueBuffBoMiddle3[i] > ValueBuffBoMiddle3[i+1] )
            {
                Bo3buyflag = true;
            }
            if( ValueBuffBoMiddle3[i] < ValueBuffBoMiddle3[i+1] )
            {
                Bo3sellflag = true;
            }
            
            //
            // END PercentageCrossover.mq5
            //



            //
            // CMP1 - proportional
            //
            
            if( KMidnightIndex > atrx_period )
            {
                ValueBuffCmp1Bo1[i]   = 0.0;
                ValueBuffCmp1Bo2[i]   = 0.0;
                ValueBuffCmp1Bo3[i]   = 0.0;
            }
            else
            {
                if( (i+atrx_period) < rates_total )
                {
                    ValueBuffCmp1Bo1[i] = (ValueBuffBoMiddle1[i]-ValueBuffBoMiddle1[i+atrx_period])/Point();
                    ValueBuffCmp1Bo2[i] = (ValueBuffBoMiddle2[i]-ValueBuffBoMiddle2[i+atrx_period])/Point();
                    ValueBuffCmp1Bo3[i] = (ValueBuffBoMiddle3[i]-ValueBuffBoMiddle3[i+atrx_period])/Point();
                }
            }
    
            // BO1
            // buy
            if( true == Bo1buyflag )
            {
           	    ColorBuffCmp1Bo1[ i ] = eClrBlue1;
            }
            // sell
            else if( true == Bo1sellflag )
            {
       	        ColorBuffCmp1Bo1[ i ] = eClrRed1;
            }
            // neutral
            else
            {
            	ColorBuffCmp1Bo1[ i ] = eClrGray;
            }
            if( true == Bo1exitflag )
            {
            	ColorBuffCmp1Bo1[ i ] = eClrGreen;
            }

            // BO2
            // buy
            if( true == Bo2buyflag )
            {
           	    ColorBuffCmp1Bo2[ i ] = eClrBlue1;
            }
            // sell
            else if( true == Bo2sellflag )
            {
       	        ColorBuffCmp1Bo2[ i ] = eClrRed1;
            }
            // neutral
            else
            {
            	ColorBuffCmp1Bo2[ i ] = eClrGray;
            }
            if( true == Bo2exitflag )
            {
            	ColorBuffCmp1Bo2[ i ] = eClrGreen;
            }

            // BO3
            // buy
            if( true == Bo3buyflag )
            {
           	    ColorBuffCmp1Bo3[ i ] = eClrBlue1;
            }
            // sell
            else if( true == Bo3sellflag )
            {
       	        ColorBuffCmp1Bo3[ i ] = eClrRed1;
            }
            // neutral
            else
            {
            	ColorBuffCmp1Bo3[ i ] = eClrGray;
            }
            if( true == Bo3exitflag )
            {
            	ColorBuffCmp1Bo3[ i ] = eClrGreen;
            }
            
            bool buyint  = false;
            bool sellint = false;
            bool buybo   = false;
            bool sellbo  = false;
            
            
            if( 
                    (true == Bo1buyflag)&&(true == Bo3buyflag)&&(true == Bo3buyflag) 
                &&  ( ValueBuffCmp1Bo1[ i ] > ValueBuffCmp1Bo2[ i ] )
                &&  ( ValueBuffCmp1Bo2[ i ] > ValueBuffCmp1Bo3[ i ] )
                // TODO make this optional
                //&&  ( 0 < ValueBuffCmp1Bo3[ i ] )
              )
            {
           	    ColorBuffCmp1Bo1[ i ] = eClrBlue5;
           	    ColorBuffCmp1Bo2[ i ] = eClrBlue5;
           	    ColorBuffCmp1Bo3[ i ] = eClrBlue5;
           	    buybo = true;
            }
            if( 
                    (true == Bo1sellflag)&&(true == Bo3sellflag)&&(true == Bo3sellflag) 
                &&  ( ValueBuffCmp1Bo1[ i ] < ValueBuffCmp1Bo2[ i ] )
                &&  ( ValueBuffCmp1Bo2[ i ] < ValueBuffCmp1Bo3[ i ] )
                // TODO make this optional
                //&&  ( 0 > ValueBuffCmp1Bo3[ i ] )
              )
            {
           	    ColorBuffCmp1Bo1[ i ] = eClrRed5;
           	    ColorBuffCmp1Bo2[ i ] = eClrRed5;
           	    ColorBuffCmp1Bo3[ i ] = eClrRed5;
           	    sellbo = true;
            }
            

            //
            // CMP2 - differential            
            //
            ValueBuffCmp2Diff[ i ] = (Close[i] - Close[i+1])/Point();
            ColorBuffCmp2Diff[ i ] = eClrGray;
            

            //
            // CMP3 - integral
            // 
            if( KMidnightIndex > atrx_period )
            {
                ValueBuffCmp3Int[i]  = 0.0;
            }
            else
            {
                ValueBuffCmp3Int[ i ] = ValueBuffCmp2Diff[ i ] + ValueBuffCmp3Int[ i+1 ];
                ColorBuffCmp3Int[ i ] = eClrGreen;
            }
            
            
            if( (true == buyint) || (true == buybo) )
            {
                BuyBuff[i] = Close[i];
                if (true == buyint) 
                {
                    ValueBuffCmp2Diff[ i ] = +1000;
                    ColorBuffCmp2Diff[ i ] = eClrGreen;
                }
                else if ( true == buybo)
                {
                    //ValueBuffCmp2Diff[ i ] = +2000;
                    ColorBuffCmp2Diff[ i ] = eClrBlue5;
                }
            }
             
            if( (true == sellint) || (true == sellbo) )
            {
                SellBuff[i] = Close[i];
                if( true == sellint)
                {
                    ValueBuffCmp2Diff[ i ] = -1000;
                    ColorBuffCmp2Diff[ i ] = eClrGreen;
                }
                else if (true == sellbo)
                {
                    //ValueBuffCmp2Diff[ i ] = -2000;
                    ColorBuffCmp2Diff[ i ] = eClrRed5;
                }
                
            } // if( (true == buyint) || (true == buybo) )  
            
                      
			
        } // for( int i = start; i < rates_total - 1; i++ )

        ValueBuffCmp1Bo1[ rates_total - 1 ] = 0.0;
        ColorBuffCmp1Bo1[ rates_total - 1 ] = 0.0;
		
    } // if( prev_calculated == 0 || CheakNewBar( Symbol( ), Period( ), last_bar_datetime_chart ) == 1 )

	return( rates_total );
}

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void
OnDeinit( const int _reason )
{

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
//|   m_IndiGetShiftSinceMonthStarted
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceMonthStarted( int shift )
{
    datetime starttime = iTime(Symbol(),Period(),shift);
    MqlDateTime tm;
    TimeToStruct( starttime, tm );
    tm.day  = 1;
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    TimeToStruct( stoptime, tm );
    // on Sunday forward to Monday
    if( 0 == tm.day_of_week )
        tm.day  = tm.day+1;
    // on Saturday forward to Monday
    if( 6 == tm.day_of_week )
        tm.day  = tm.day+2;
    stoptime = StructToTime( tm );
    //Print( "i: " + string (shift ) + " startdt: " + string (starttime ) + " enddt: " + string (stoptime ));
    shift = iBarShift(Symbol(),Period(),starttime,stoptime);
    
    return (shift);
    
} // int m_IndiGetShiftSinceMonthStarted( int shift )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceYearStarted
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceYearStarted( int shift )
{
    datetime starttime = iTime(Symbol(),Period(),shift);
    MqlDateTime tm;
    TimeToStruct( starttime, tm );
    tm.mon  = 1;
    tm.day  = 2;
    tm.hour = 12;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    TimeToStruct( stoptime, tm );
    // on Sunday forward to Monday
    if( 0 == tm.day_of_week )
        tm.day  = tm.day+1;
    // on Saturday forward to Monday
    if( 6 == tm.day_of_week )
        tm.day  = tm.day+2;
    stoptime = StructToTime( tm );
    //Print( "i: " + string (shift ) + " startdt: " + string (starttime ) + " enddt: " + string (stoptime ));
    shift = iBarShift(Symbol(),Period(),starttime,stoptime);
    return (shift);
    
} // int m_IndiGetShiftSinceYearStarted( int shift )
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

