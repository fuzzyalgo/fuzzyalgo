//=====================================================================
//	T4 indicator.
//=====================================================================
#property copyright     "Copyright 2017, Andre Howe"
#property link          "andrehowe.com"
#property version       "1.1"
#property description   "ALL T6 Indicator"
//---------------------------------------------------------------------
//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 14
#property indicator_plots   14
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
input int                   SR_PERIOD       = 1;      // SR_PERIOD - if NULL calculate shift since day has started
input double                BO_PERCENT1     = 0.01;   // BO_PERCENT1 - breakout percentage
input double                BO_PERCENT2     = 0.02;   // BO_PERCENT2 - breakout percentage
input double                BO_PERCENT3     = 0.03;   // BO_PERCENT2 - breakout percentage

const string gIndicatorName = "ALL_T6";

//#include <library.mqh>

//---------------------------------------------------------------------
double	BuyBuff[ ];
double	SellBuff[ ];
double	ExitBuff[ ];
double	ValueDateTime[ ];
double	ValueBuffBoMiddle1[ ];
double	ColorBuffBoMiddle1[ ];
double	ValueBuffBoMiddle2[ ];
double	ColorBuffBoMiddle2[ ];
double	ValueBuffBoMiddle3[ ];
double	ColorBuffBoMiddle3[ ];
double	ValueBuffBoMiddleFillWin1[ ];
double	ValueBuffBoMiddleFillWin2[ ];
double	ValueBuffBoMiddleFillLoss1[ ];
double	ValueBuffBoMiddleFillLoss2[ ];


//---------------------------------------------------------------------


//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int
OnInit( )
{
	Comment( "" );
	Print( "init1");

    //--- set indicator levels
    IndicatorSetInteger(INDICATOR_LEVELS,2); 
    IndicatorSetDouble(INDICATOR_LEVELVALUE,0,-100); 
    IndicatorSetDouble(INDICATOR_LEVELVALUE,1,100); 
    //--- set maximum and minimum for subwindow  
    IndicatorSetDouble(INDICATOR_MINIMUM,-300); 
    IndicatorSetDouble(INDICATOR_MAXIMUM, 300); 
   
    PlotIndexSetString (0,PLOT_LABEL,"Buy");     
    PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(0,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     0, BuyBuff,             INDICATOR_DATA );
    
    PlotIndexSetString (1,PLOT_LABEL,"Sell");     
    PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(1,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     1, SellBuff,            INDICATOR_DATA );

    PlotIndexSetString (2,PLOT_LABEL,"Exit");     
    PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(2,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     2, ExitBuff,            INDICATOR_DATA );
    
    PlotIndexSetString (3,PLOT_LABEL,"BO-DATETIME");     
    PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(3,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     3, ValueDateTime,       INDICATOR_DATA );
    
    
    PlotIndexSetString (4,PLOT_LABEL,"BO-MIDDLE-" + string( BO_PERCENT1 ) );     
    PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_COLOR_LINE); 
    PlotIndexSetInteger(4,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(4,PLOT_LINE_WIDTH,0); 
    PlotIndexSetInteger(4,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(4,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(4,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     4, ValueBuffBoMiddle1,     INDICATOR_DATA );
	SetIndexBuffer(     5, ColorBuffBoMiddle1,     INDICATOR_COLOR_INDEX );

    PlotIndexSetString (5,PLOT_LABEL,"BO-MIDDLE-" + string( BO_PERCENT2 ) );     
    PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_COLOR_LINE); 
    PlotIndexSetInteger(5,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(5,PLOT_LINE_WIDTH,0); 
    PlotIndexSetInteger(5,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(5,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(5,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     6, ValueBuffBoMiddle2,     INDICATOR_DATA );
	SetIndexBuffer(     7, ColorBuffBoMiddle2,     INDICATOR_COLOR_INDEX );

    PlotIndexSetString (6,PLOT_LABEL,"BO-MIDDLE-" + string( BO_PERCENT3 ) );     
    PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_COLOR_LINE); 
    PlotIndexSetInteger(6,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(6,PLOT_LINE_WIDTH,0); 
    PlotIndexSetInteger(6,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(6,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(6,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     8, ValueBuffBoMiddle3,     INDICATOR_DATA );
	SetIndexBuffer(     9, ColorBuffBoMiddle3,     INDICATOR_COLOR_INDEX );

    PlotIndexSetString (7,PLOT_LABEL,"BO-FILL-WIN" );
    PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_FILLING); 
    PlotIndexSetInteger(7,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(7,PLOT_LINE_WIDTH,3); 
    PlotIndexSetInteger(7,PLOT_SHOW_DATA,true); 
	//PlotIndexSetDouble( 7, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetInteger(7,PLOT_COLOR_INDEXES,2); 
    PlotIndexSetInteger(7,PLOT_LINE_COLOR, 0,  gColours[eClrBlue1]);  	
    PlotIndexSetInteger(7,PLOT_LINE_COLOR, 1,  gColours[eClrGray]);  	
   
	SetIndexBuffer(    10, ValueBuffBoMiddleFillWin1,     INDICATOR_DATA );
	SetIndexBuffer(    11, ValueBuffBoMiddleFillWin2,     INDICATOR_DATA );

    PlotIndexSetString (8,PLOT_LABEL,"BO-FILL-LOSS" );
    PlotIndexSetInteger(8,PLOT_DRAW_TYPE,DRAW_FILLING); 
    PlotIndexSetInteger(8,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(8,PLOT_LINE_WIDTH,3); 
    PlotIndexSetInteger(8,PLOT_SHOW_DATA,true); 
	//PlotIndexSetDouble( 8, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetInteger(8,PLOT_COLOR_INDEXES,2); 
    PlotIndexSetInteger(8,PLOT_LINE_COLOR, 0,  gColours[eClrGray]);  	
    PlotIndexSetInteger(8,PLOT_LINE_COLOR, 1,  gColours[eClrRed1]);  	
   
	SetIndexBuffer(     12, ValueBuffBoMiddleFillLoss1,     INDICATOR_DATA );
	SetIndexBuffer(     13, ValueBuffBoMiddleFillLoss2,    INDICATOR_DATA );


    ArraySetAsSeries( BuyBuff,              true );
    ArraySetAsSeries( SellBuff,             true );
    ArraySetAsSeries( ExitBuff,             true );
    ArraySetAsSeries( ValueDateTime,        true );
    ArraySetAsSeries( ValueBuffBoMiddle1,   true );
    ArraySetAsSeries( ColorBuffBoMiddle1,   true );
    ArraySetAsSeries( ValueBuffBoMiddle2,   true );
    ArraySetAsSeries( ColorBuffBoMiddle2,   true );
    ArraySetAsSeries( ValueBuffBoMiddle3,   true );
    ArraySetAsSeries( ColorBuffBoMiddle3,   true );
    ArraySetAsSeries( ValueBuffBoMiddleFillWin1,true );
    ArraySetAsSeries( ValueBuffBoMiddleFillWin2,true );
    ArraySetAsSeries( ValueBuffBoMiddleFillLoss1,true );
    ArraySetAsSeries( ValueBuffBoMiddleFillLoss2,true );
    
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
	IndicatorSetString(  INDICATOR_SHORTNAME, gIndicatorName + " ( " + string( FROM_TO_DATE ) + " / " + string( SR_PERIOD ) + 
	                    " / " + string( BO_PERCENT1 ) + " / " + string( BO_PERCENT2 ) + " / " + string( BO_PERCENT3 ) + " ) " );

    //s.g_sr_handler = iCustom( s.SYMBOL, s.PERIOD, "all_t6", FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2 );
    //       handler = iCustom( Symbol(), Period(), "all_t4", "DD.MM.YYYY-DD.MM.YYYY",0,0.1,0.2 );
	
	Print( "init2");
	
	
	ChartRedraw( );

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
	static int Bo1upcnt = 0;
	static int Bo1dncnt = 0;
	static int Bo2upcnt = 0;
	static int Bo2dncnt = 0;
	static int Bo3upcnt = 0;
	static int Bo3dncnt = 0;
	static double gMiddle = 0;
	static double gForward = 0;
	static int gMiddleBuyCnt = 0;
	static int gMiddleSellCnt = 0;
	
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
    //start = 4*5*24*60; 
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
    
    
        for( int i = start-12; i >= 0; i-- )
        {
            // TODO implement the laoding of history data here
    		//if( i >= (ArraySize( ValueBuffBoMiddle1 )) )
    		//{
    		//    //continue;
    		//}
            SellBuff[i]         = 0.0;
            BuyBuff[i]          = 0.0;
            ExitBuff[i]          = 0.0;
            ValueDateTime[i]    = (double)Time[i];
            ValueBuffBoMiddle1[i]= 0.0;
            ColorBuffBoMiddle1[i]  = 0.0;
            ValueBuffBoMiddle2[i]= 0.0;
            ColorBuffBoMiddle2[i]  = 0.0;
            ValueBuffBoMiddle3[i]= 0.0;
            ColorBuffBoMiddle3[i]  = 0.0;
            ValueBuffBoMiddleFillWin1[i]  = 0.0;
            ValueBuffBoMiddleFillWin2[i]  = 0.0;
            ValueBuffBoMiddleFillLoss1[i]  = 0.0;
            ValueBuffBoMiddleFillLoss2[i]  = 0.0;
            
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
                atrx_period = m_IndiGetShiftSinceDayStarted2(i);
                if( 0 == atrx_period )
                {
                   //continue;
                }
            }
            if( 1 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceWeekStarted(i);
                if( 0 == atrx_period )
                {
                   //continue;
                }
            }
            if( 2 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceMonthStarted(i);
                if( 0 == atrx_period )
                {
                   //continue;
                }
            }
            if( 3 == SR_PERIOD )
            {
                atrx_period = m_IndiGetShiftSinceYearStarted(i);
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
                Bo1dncnt = 0;
                Bo1upcnt++;
            }
            if( ValueBuffBoMiddle1[i] < ValueBuffBoMiddle1[i+1] )
            {
                Bo1upcnt = 0;
                Bo1dncnt++;
            }
            
            if(   
                (Bo1upcnt)
                )
            {
                Bo1buyflag = true;
            }
            if(    
                (Bo1dncnt)
                )
            {
                Bo1sellflag = true;
            }
            
            if(    
                    (1==Bo1upcnt)
                 || (1==Bo1dncnt)
                )
            {
                Bo1exitflag = true;
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
                Bo2dncnt = 0;
                Bo2upcnt++;
            }
            if( ValueBuffBoMiddle2[i] < ValueBuffBoMiddle2[i+1] )
            {
                Bo2upcnt = 0;
                Bo2dncnt++;
            }
            
            if(   
                (Bo2upcnt)
                )
            {
                Bo2buyflag = true;
            }
            if(    
                (Bo2dncnt)
                )
            {
                Bo2sellflag = true;
            }
            
            if(    
                    (1==Bo2upcnt)
                 || (1==Bo2dncnt)
                )
            {
                Bo2exitflag = true;
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
                Bo3dncnt = 0;
                if( 0 == Bo3upcnt )
                {
                    gMiddle = Close[i];
                }
                Bo3upcnt++;
            }
            if( ValueBuffBoMiddle3[i] < ValueBuffBoMiddle3[i+1] )
            {
                Bo3upcnt = 0;
                if( 0 == Bo3dncnt )
                {
                    gMiddle = Close[i];
                }
                Bo3dncnt++;
            }
            
            if(   
                (Bo3upcnt)
                )
            {
                Bo3buyflag = true;
            }
            if(    
                (Bo3dncnt)
                )
            {
                Bo3sellflag = true;
            }
            
            if(    
                    (1==Bo3upcnt)
                 || (1==Bo3dncnt)
                )
            {
                Bo3exitflag = true;
            }
            
            //
            // END PercentageCrossover.mq5
            //


    
            // BO1
            // buy
            if( true == Bo1buyflag )
            {
           	    ColorBuffBoMiddle1[ i ] = eClrBlue1;
            }
            // sell
            else if( true == Bo1sellflag )
            {
       	        ColorBuffBoMiddle1[ i ] = eClrRed1;
            }
            // neutral
            else
            {
            	ColorBuffBoMiddle1[ i ] = eClrGray;
            }
            if( true == Bo1exitflag )
            {
            	ColorBuffBoMiddle1[ i ] = eClrGreen;
            }

            // BO2
            // buy
            if( true == Bo2buyflag )
            {
           	    ColorBuffBoMiddle2[ i ] = eClrBlue1;
            }
            // sell
            else if( true == Bo2sellflag )
            {
       	        ColorBuffBoMiddle2[ i ] = eClrRed1;
            }
            // neutral
            else
            {
            	ColorBuffBoMiddle2[ i ] = eClrGray;
            }
            if( true == Bo2exitflag )
            {
            	ColorBuffBoMiddle2[ i ] = eClrGreen;
            }

            // BO3
            // buy
            if( true == Bo3buyflag )
            {
           	    ColorBuffBoMiddle3[ i ] = eClrBlue1;
            }
            // sell
            else if( true == Bo3sellflag )
            {
       	        ColorBuffBoMiddle3[ i ] = eClrRed1;
            }
            // neutral
            else
            {
            	ColorBuffBoMiddle3[ i ] = eClrGray;
            }
            if( true == Bo3exitflag )
            {
            	ColorBuffBoMiddle3[ i ] = eClrGreen;
            }
            /*
            if( 
                    (true == Bo1buyflag)&&(true == Bo3buyflag)&&(true == Bo3buyflag) 
                &&  ( ValueBuffBoMiddle1[ i ] >= ValueBuffBoMiddle2[ i ] )
                &&  ( ValueBuffBoMiddle2[ i ] >= ValueBuffBoMiddle3[ i ] )
              )
            {
           	    ColorBuffBoMiddle1[ i ] = eClrBlue5;
           	    ColorBuffBoMiddle2[ i ] = eClrBlue5;
           	    ColorBuffBoMiddle3[ i ] = eClrBlue5;
                
                if( 0 == gMiddleBuyCnt )
                {
                    gMiddle = Close[i];
                }
                gMiddleBuyCnt++;
                ValueBuffBoMiddleFillWin1[i] = Close[i];
                ValueBuffBoMiddleFillWin2[i] = gMiddle;
           	    
            }
            else
            {
                gMiddleBuyCnt = 0;
            }
            
            if( 
                    (true == Bo1sellflag)&&(true == Bo3sellflag)&&(true == Bo3sellflag) 
                &&  ( ValueBuffBoMiddle1[ i ] <= ValueBuffBoMiddle2[ i ] )
                &&  ( ValueBuffBoMiddle2[ i ] <= ValueBuffBoMiddle3[ i ] )
              )
            {
           	    ColorBuffBoMiddle1[ i ] = eClrRed5;
           	    ColorBuffBoMiddle2[ i ] = eClrRed5;
           	    ColorBuffBoMiddle3[ i ] = eClrRed5;
                
                if( 0 == gMiddleSellCnt )
                {
                    gMiddle = Close[i];
                }
                gMiddleSellCnt++;
                
                ValueBuffBoMiddleFillLoss1[i] = Close[i];
                ValueBuffBoMiddleFillLoss2[i] = gMiddle;
           	    
            }
            else
            {
                gMiddleSellCnt = 0;
            }
            */

            if( 
                      Bo3upcnt
              )
            {
                //if( 1 == Bo3upcnt )
                //{
                //    gMiddle = Close[i];
                //}
                
           	    ColorBuffBoMiddle1[ i ] = eClrBlue1;
           	    ColorBuffBoMiddle2[ i ] = eClrBlue1;
           	    ColorBuffBoMiddle3[ i ] = eClrBlue1;
                if( 
                        (true == Bo1buyflag)&&(true == Bo3buyflag)&&(true == Bo3buyflag) 
                    &&  ( ValueBuffBoMiddle1[ i ] >= ValueBuffBoMiddle2[ i ] )
                    &&  ( ValueBuffBoMiddle2[ i ] >= ValueBuffBoMiddle3[ i ] )
                  )
                {
               	    ColorBuffBoMiddle1[ i ] = eClrBlue5;
               	    ColorBuffBoMiddle2[ i ] = eClrBlue5;
               	    ColorBuffBoMiddle3[ i ] = eClrBlue5;
               	    
                }
                else
                {
                    //gMiddle = 0.0;
                }
                    
                    if( 0.0 != gMiddle )
                    {
                        ValueBuffBoMiddleFillWin1[i] = Close[i];
                        ValueBuffBoMiddleFillWin2[i] = gMiddle;
                        if( High[i] - gMiddle > 300*Point() )
                        {
                            ValueBuffBoMiddleFillWin1[i] = High[i];
                            gMiddle = 0.0;
                        }
                    }           	    
            }
            
            if( 
                      Bo3dncnt    
              )
            {
                //if( 1 == Bo3dncnt )
                //{
                //    gMiddle = Close[i];
                //}
                
           	    ColorBuffBoMiddle1[ i ] = eClrRed1;
           	    ColorBuffBoMiddle2[ i ] = eClrRed1;
           	    ColorBuffBoMiddle3[ i ] = eClrRed1;
                
                if( 
                        (true == Bo1sellflag)&&(true == Bo3sellflag)&&(true == Bo3sellflag) 
                    &&  ( ValueBuffBoMiddle1[ i ] <= ValueBuffBoMiddle2[ i ] )
                    &&  ( ValueBuffBoMiddle2[ i ] <= ValueBuffBoMiddle3[ i ] )
                  )
                {
               	    ColorBuffBoMiddle1[ i ] = eClrRed5;
               	    ColorBuffBoMiddle2[ i ] = eClrRed5;
               	    ColorBuffBoMiddle3[ i ] = eClrRed5;
               	    
                    
                }
                else
                {
                    //gMiddle = 0.0;
                }
           	    
                    if( 0.0 != gMiddle )
                    {
                        ValueBuffBoMiddleFillLoss1[i] = Close[i];
                        ValueBuffBoMiddleFillLoss2[i] = gMiddle;
                        if( gMiddle - Low[i] > 300*Point() )
                        {
                            ValueBuffBoMiddleFillLoss1[i] = Low[i];
                            gMiddle = 0.0;
                        }    
                    }
            }
            else
            {
                gMiddleSellCnt = 0;
            }


            /*
            // MIDDLE
            if( 
                (
                  (ValueBuffBoMiddle1[i]   > ValueBuffBoMiddle2[i]   )
               && (ValueBuffBoMiddle1[i+1] <= ValueBuffBoMiddle2[i+1] ) )
               ||
                (
                  (ValueBuffBoMiddle1[i]   < ValueBuffBoMiddle2[i]   )
               && (ValueBuffBoMiddle1[i+1] >= ValueBuffBoMiddle2[i+1] ) )
              )
            {
                gMiddle = Close[i];
                for( int fwd = i-1; fwd > 0; fwd -- )
                {
                    if( 
                        (
                          (ValueBuffBoMiddle1[fwd]   > ValueBuffBoMiddle2[fwd]   )
                       && (ValueBuffBoMiddle1[fwd+1] <= ValueBuffBoMiddle2[fwd+1] ) )
                       ||
                        (
                          (ValueBuffBoMiddle1[fwd]   < ValueBuffBoMiddle2[fwd]   )
                       && (ValueBuffBoMiddle1[fwd+1] >= ValueBuffBoMiddle2[fwd+1] ) )
                      )
                    {
                        gForward = Close[fwd];
                        break;
                    }
                    
                }
            }
            
            // WIN
            if( 
                 (ValueBuffBoMiddle1[i]   > ValueBuffBoMiddle2[i])
              && (Close[i]>gMiddle)
               )
            {
                ValueBuffBoMiddleFillWin1[i] = Close[i];
                if (Close[i]>gForward)
                    ValueBuffBoMiddleFillWin1[i] = gForward;
                ValueBuffBoMiddleFillWin2[i] = gMiddle;
            }

            if( 
                 (ValueBuffBoMiddle1[i]   < ValueBuffBoMiddle2[i])
              && (Close[i]<gMiddle)
               )
            {
                ValueBuffBoMiddleFillWin1[i] = Close[i];
                if (Close[i]<gForward)
                    ValueBuffBoMiddleFillWin1[i] = gForward;
                ValueBuffBoMiddleFillWin2[i] = gMiddle;
            }

            // LOSS
            if( 
                 (ValueBuffBoMiddle1[i]   > ValueBuffBoMiddle2[i])
              && (Close[i]<=gMiddle)
               )
            {
                ValueBuffBoMiddleFillLoss1[i] = Close[i];
                ValueBuffBoMiddleFillLoss2[i] = gMiddle;
            }

            if( 
                 (ValueBuffBoMiddle1[i]   < ValueBuffBoMiddle2[i])
              && (Close[i]>=gMiddle)
               )
            {
                ValueBuffBoMiddleFillLoss1[i] = Close[i];
                ValueBuffBoMiddleFillLoss2[i] = gMiddle;
            }
*/
                      
			
        } // for( int i = start; i < rates_total - 1; i++ )

		
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
    datetime t0 = iTime(Symbol(),Period(),shift);
    
    datetime starttime = t0;
    
    MqlDateTime tm;
    TimeToStruct( t0, tm );
    tm.day  = 1;
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    
    shift = iBarShift(Symbol(),Period(),starttime,stoptime);
    
    return (shift);
    
} // int m_IndiGetShiftSinceMonthStarted( int shift )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceYearStarted
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceYearStarted( int shift )
{
    datetime t0 = iTime(Symbol(),Period(),shift);
    
    datetime starttime = t0;
    
    MqlDateTime tm;
    TimeToStruct( t0, tm );
    tm.mon  = 1;
    tm.day  = 1;
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    
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

