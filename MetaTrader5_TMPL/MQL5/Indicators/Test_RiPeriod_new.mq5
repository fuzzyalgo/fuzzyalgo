//+------------------------------------------------------------------+ 
//|                            PercentageCrossoverChannel_System.mq5 | 
//|                           +             Copyright © 2009, Vic2008 | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2009, Vic2008"
#property link ""
#property description "Test RiPeriod"
#property version   "1.00"
#property indicator_chart_window 

//25 local buffers plus 80 RiPeriod buffers ( 85 => 5 periods * 17 buffers )
//  110 buffers = 25 local plus 85 RiPeriod buffers

#property indicator_buffers 120//50//40//35//10
#property indicator_plots   120//50//40//35//10

//+-----------------------------------+
//|  Inputs
//+-----------------------------------+
input double BO_PERCENT=0.3; //BO - BREAK_OUT in percent
//+-----------------------------------+


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


#include <RiPeriod.mqh>

CRiPeriod rip( Symbol(), Period(), BO_PERCENT );


//---- global buffers
double BuyBuff[], SellBuff[];
double Up1Buffer[],Dn1Buffer[];
double Up2Buffer[],Dn2Buffer[];
double ExtOpenBuffer1[],ExtHighBuffer1[],ExtLowBuffer1[],ExtCloseBuffer1[],ExtColorBuffer1[];
double ExtOpenBuffer2[],ExtHighBuffer2[],ExtLowBuffer2[],ExtCloseBuffer2[],ExtColorBuffer2[];
double ExtOpenBuffer3[],ExtHighBuffer3[],ExtLowBuffer3[],ExtCloseBuffer3[],ExtColorBuffer3[];
double ExtOpenBuffer4[],ExtHighBuffer4[],ExtLowBuffer4[],ExtCloseBuffer4[],ExtColorBuffer4[];
double BoMiddle[];

//---- global variables
double plusvar1,minusvar1;
int min_rates_total;

//+------------------------------------------------------------------+    
//| Custom indicator indicator initialization function               | 
//+------------------------------------------------------------------+  
void OnInit()
{
    Print( "init1 " );
    
    min_rates_total=2;
    double var1=BO_PERCENT/100;
    plusvar1=1+var1;
    minusvar1=1-var1;
    
    int plot_index = 0;
    int idx_buf_index = 0;
    
    PlotIndexSetString (plot_index,PLOT_LABEL,"BUY");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_ARROW); 
    PlotIndexSetInteger(plot_index,PLOT_ARROW,233);
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,6); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, clrBlue );
    plot_index++;  	
    SetIndexBuffer(idx_buf_index,BuyBuff,INDICATOR_DATA);
    ArraySetAsSeries(BuyBuff,true);
    idx_buf_index++;

    PlotIndexSetString (plot_index,PLOT_LABEL,"SELL");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_ARROW); 
    PlotIndexSetInteger(plot_index,PLOT_ARROW,234);
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,6); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, clrRed );
    plot_index++;  	
    SetIndexBuffer(idx_buf_index,SellBuff,INDICATOR_DATA);
    ArraySetAsSeries(SellBuff,true);
    idx_buf_index++;
    
    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-UP");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_LINE); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, clrMediumSeaGreen ); 
    plot_index++; 	
    SetIndexBuffer(idx_buf_index,Up1Buffer,INDICATOR_DATA);
    ArraySetAsSeries(Up1Buffer,true);
    idx_buf_index++;
    
    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-DN");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_LINE); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, clrMagenta );  	
    plot_index++;
    SetIndexBuffer(idx_buf_index,Dn1Buffer,INDICATOR_DATA);
    ArraySetAsSeries(Dn1Buffer,true);
    idx_buf_index++;

    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-MIDDLE");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_LINE); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, clrPeachPuff );
    plot_index++;  	
    SetIndexBuffer(idx_buf_index,BoMiddle,INDICATOR_DATA);
    ArraySetAsSeries(BoMiddle,true);
    idx_buf_index++;

    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-FILL");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_FILLING); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, clrWhiteSmoke );  	
    plot_index++;
    SetIndexBuffer(idx_buf_index,Up2Buffer,INDICATOR_DATA);
    ArraySetAsSeries(Up2Buffer,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,Dn2Buffer,INDICATOR_DATA);
    ArraySetAsSeries(Dn2Buffer,true);
    idx_buf_index++;
    
    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-BAR1");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
    plot_index++;
    SetIndexBuffer(idx_buf_index,ExtOpenBuffer1,INDICATOR_DATA);
    ArraySetAsSeries(ExtOpenBuffer1,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtHighBuffer1,INDICATOR_DATA);
    ArraySetAsSeries(ExtHighBuffer1,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtLowBuffer1,INDICATOR_DATA);
    ArraySetAsSeries(ExtLowBuffer1,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtCloseBuffer1,INDICATOR_DATA);
    ArraySetAsSeries(ExtCloseBuffer1,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtColorBuffer1,INDICATOR_COLOR_INDEX);
    ArraySetAsSeries(ExtColorBuffer1,true);
    idx_buf_index++;
    

    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-BAR2");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
    plot_index++;
    SetIndexBuffer(idx_buf_index,ExtOpenBuffer2,INDICATOR_DATA);
    ArraySetAsSeries(ExtOpenBuffer2,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtHighBuffer2,INDICATOR_DATA);
    ArraySetAsSeries(ExtHighBuffer2,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtLowBuffer2,INDICATOR_DATA);
    ArraySetAsSeries(ExtLowBuffer2,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtCloseBuffer2,INDICATOR_DATA);
    ArraySetAsSeries(ExtCloseBuffer2,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtColorBuffer2,INDICATOR_COLOR_INDEX);
    ArraySetAsSeries(ExtColorBuffer2,true);
    idx_buf_index++;

    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-BAR3");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
    plot_index++;
    SetIndexBuffer(idx_buf_index,ExtOpenBuffer3,INDICATOR_DATA);
    ArraySetAsSeries(ExtOpenBuffer3,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtHighBuffer3,INDICATOR_DATA);
    ArraySetAsSeries(ExtHighBuffer3,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtLowBuffer3,INDICATOR_DATA);
    ArraySetAsSeries(ExtLowBuffer3,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtCloseBuffer3,INDICATOR_DATA);
    ArraySetAsSeries(ExtCloseBuffer3,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtColorBuffer3,INDICATOR_COLOR_INDEX);
    ArraySetAsSeries(ExtColorBuffer3,true);
    idx_buf_index++;

    PlotIndexSetString (plot_index,PLOT_LABEL,"BO-BAR4");     
    PlotIndexSetInteger(plot_index,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(plot_index,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(plot_index,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(plot_index,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(plot_index,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
    plot_index++;
    SetIndexBuffer(idx_buf_index,ExtOpenBuffer4,INDICATOR_DATA);
    ArraySetAsSeries(ExtOpenBuffer4,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtHighBuffer4,INDICATOR_DATA);
    ArraySetAsSeries(ExtHighBuffer4,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtLowBuffer4,INDICATOR_DATA);
    ArraySetAsSeries(ExtLowBuffer4,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtCloseBuffer4,INDICATOR_DATA);
    ArraySetAsSeries(ExtCloseBuffer4,true);
    idx_buf_index++;
    SetIndexBuffer(idx_buf_index,ExtColorBuffer4,INDICATOR_COLOR_INDEX);
    ArraySetAsSeries(ExtColorBuffer4,true);
    idx_buf_index++;

    
    string shortname;
    StringConcatenate(shortname,"Test RI Period (BO_PERCENT = ",BO_PERCENT,")");
    IndicatorSetString(INDICATOR_SHORTNAME,shortname);
    IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
    
    Print( "#1  plot_index: " + string( plot_index) + " idx_buf_index: " + string( idx_buf_index ) );
    int err = rip.ConfigAndLoad( plot_index, idx_buf_index );
    Print( "#2  plot_index: " + string( plot_index) + " idx_buf_index: " + string( idx_buf_index ) );
    
    ChartRedraw();

    Print( "init2 " + string(err) );
} // void OnInit()

//+------------------------------------------------------------------+  
//| 
//+------------------------------------------------------------------+  
void LogData(const int   rates_total,
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
    ResetLastError();
    
    datetime dt_now  = 0;
    datetime dt_prev = 0;
    MqlDateTime t_now;
    MqlDateTime t_prev;
    int fhandle = INVALID_HANDLE;
    int fhandle_001 = INVALID_HANDLE;
    int fhandle_000_TimeOpen = INVALID_HANDLE;
    int fhandle_000_TimeNow  = INVALID_HANDLE;
    string fulldate;
    string s_filename;
    
    
    //int start = rates_total-10; //4*5*24*60;
    // for H1 - 20 years
    // TODO make this period dependant
    // since start of week
    // here PERIOD_H1 for two+ weeks
    int start = 24*5;
    if( start > rates_total )
        start = rates_total-10;
    
    int cnt = 0;    
    
    for( int i= start-1; i >= 0; i-- )
    {
    
        dt_now = Time[i];
        dt_prev = Time[i+1];
        TimeToStruct(dt_now,t_now);
        TimeToStruct(dt_prev,t_prev);
        // skip Sunday (0) and Saturday(6)
        if( (0 == t_now.day_of_week ) || (6 == t_now.day_of_week )  )
        {
            continue;
        }
        else
        {
            cnt++;
            // if previous was Sunday(0) and now is Monday(1) 
            // then start creating a new file
            if( (1 != t_prev.day_of_week ) && (1 == t_now.day_of_week ) ) {            
                if(fhandle!=INVALID_HANDLE) {
                    FileClose( fhandle);
                    fhandle = INVALID_HANDLE;
                }
                fulldate = StringFormat( "%04d%02d%02d", t_now.year, t_now.mon, t_now.day );
                //// c:\OneDrive\rfx\1d\rfx\mt\vm1\mt1\MQL5\Files\20200608_H1_EURUSD.csv
                ////string s_filename = fulldate +  "_" + ConvertPeriodToString( Period()) + "_" + Symbol() + ".csv";
                // c:\OneDrive\rfx\1d\rfx\mt\vm1\mt1\MQL5\Files\H1\20200608\EURUSD.csv
                s_filename = ConvertPeriodToString( Period()) + "\\" + fulldate + "\\01_CSVx\\" + Symbol() + ".csv";
                fhandle=FileOpen(s_filename,FILE_SHARE_READ|FILE_READ|FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_CSV ,';');
                // INTERFACE START
                if(fhandle!=INVALID_HANDLE) {
                    FileWrite( fhandle,"dt", "open", "high", "low", "close"/*, "tick", "vol", "spread"*/ );
                }
                cnt = 1;
            } // if( (0 == t_prev.day_of_week ) && (1 == t_now.day_of_week ) )
                
            string s_dt    = IntegerToString( dt_now );
            //s_dt = TimeToString( Time[i], TIME_DATE | TIME_MINUTES );
            string s_open  = DoubleToString( Open [i], Digits() );
            string s_high  = DoubleToString( High [i], Digits() );
            string s_low   = DoubleToString( Low  [i], Digits() );
            string s_close = DoubleToString( Close[i], Digits() );
            /*string s_tick  = IntegerToString( (long)TickVolume[i] );
            string s_vol   = IntegerToString( (long)Volume[i] );
            string s_spread= IntegerToString( (long)Spread[i] );*/
            if(fhandle!=INVALID_HANDLE) {
                FileWrite( fhandle, s_dt, s_open, s_high, s_low, s_close/*, s_tick, s_vol, s_spread*/ );
                // INTERFACE END
                FileFlush( fhandle );
            } // if(fhandle!=INVALID_HANDLE)

            // write CSV data of t0 to 0001_EURUSD.csv                
            if( 0 == i ) {
            
                  // fill up the remaining elements
                  if( PERIOD_H1 == Period() )           
                  if(fhandle!=INVALID_HANDLE) {
                     for( int j = cnt; j <= 120 ; j++ ) { 
                        FileWrite( fhandle, 0, s_close, s_close, s_close, s_close/*, s_tick, s_vol, s_spread*/ );
                     }
                     FileFlush( fhandle );
                  } // if(fhandle!=INVALID_HANDLE)
            
            
                s_filename = ConvertPeriodToString( Period()) + "\\" + fulldate + "\\01_CSVs\\" + Symbol() + ".csv";
                fhandle_001=FileOpen(s_filename,FILE_SHARE_READ|FILE_READ|FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_CSV ,';');
                if(fhandle_001!=INVALID_HANDLE) {
                    FileWrite( fhandle_001, s_dt, s_open, s_high, s_low, s_close/*, s_tick, s_vol, s_spread*/ );
                    FileClose( fhandle_001);
                }

                s_filename = ConvertPeriodToString( Period()) + "\\" + fulldate + "\\01_CSV_T0";
                fhandle_000_TimeOpen=FileOpen(s_filename,FILE_SHARE_READ|FILE_READ|FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
                if(fhandle_000_TimeOpen!=INVALID_HANDLE) {
                    FileWrite( fhandle_000_TimeOpen, s_dt );
                    FileClose( fhandle_000_TimeOpen);
                }
                
                s_filename = ConvertPeriodToString( Period()) + "\\" + fulldate + "\\01_CSV_NOW";
                fhandle_000_TimeNow=FileOpen(s_filename,FILE_SHARE_READ|FILE_READ|FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI );
                if(fhandle_000_TimeNow!=INVALID_HANDLE) {
                    FileWrite( fhandle_000_TimeNow, IntegerToString((datetime)TimeCurrent()) );
                    FileClose( fhandle_000_TimeNow);
                }
            } // if( 0 == i )
                
        } // for( int i= start-1; i >= 0; i-- )
    }
    if(fhandle!=INVALID_HANDLE) {
        FileClose( fhandle);
    }
    //Print( " Failed to open file: " + s_filename + " Error: " + IntegerToString(GetLastError()) );



} // int LogData(const int   rates_total


//+------------------------------------------------------------------+
bool m_TradingAllowed(datetime date)
  {
    MqlDateTime t;
    TimeToStruct(date,t);
    
    // open trading at 1AM on Monday morning
    if( t.day_of_week == 1 && t.hour >= 1 ){
        return (true);
    }
    // trading is always allowed from Tue (2) to Thu (4) :  Sun => (0)
    if( (2 <= t.day_of_week) && (4 >= t.day_of_week) ){
        return (true);
    }
    // close everything on Friday at 9PM (20:59:59)
    if( t.day_of_week == 5 && t.hour <= 20 ){
        return (true);
    }
    
    return (false);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int   rates_total,
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
    
    
    double Middle;
    static double Middle_prev;
    static int BoCntUp =0;
    static int BoCntDn =0;
    static datetime	last_bar_datetime_chart = 0;
 
    if(rates_total<min_rates_total) 
    {
        return(0);
    }
   
    if( prev_calculated == 0)
    {
        //LogData( rates_total, prev_calculated, Time, Open, High, Low, Close, TickVolume, Volume, Spread );
        last_bar_datetime_chart = 0;
        ObjectsDeleteAll(0);
        ChartRedraw( );
    	
    } // if( prev_calculated == 0)
    int start = rates_total-prev_calculated;
    
    // TODO FIXME INDICATOR START
    //if( true == TESTERMODE )
    //{
    //    start = 100;
    //}
    // TODO adapt for PERIOD dependency
    //   here set for PERIOD_H1 for one quarter (3 month)
    start = 5*24*4*3;
    
    //start = 24*60; 
    if( MQL5InfoInteger(MQL5_TESTER) )
    {
        start = 100;
    }   
    
    //
    // TODO explain 12 here, see below
    //
    if( rates_total < (start+24*5*4*12) )
    {
        start = rates_total - 24*5*4*12 - 12 -1;
    }
    
    //if( rates_total   > (100+1+12) )
    {
        if( 100 > start )
        {
            start = 100;
        }
    }

    if( 0 == prev_calculated)
    {
        if( 0<start ) 
        Middle_prev=Close[start];
    }

    if(    (0 == prev_calculated) 
        || ((1==CheckNewBar( Symbol( ), PERIOD_M1, last_bar_datetime_chart ))&&(0<start)) 
        )
    {
    
        Print( " start: " + IntegerToString(start ) + " prev_calculated: " + IntegerToString(prev_calculated )  + " rates_total: " + IntegerToString(rates_total ));
        LogData( rates_total, prev_calculated, Time, Open, High, Low, Close, TickVolume, Volume, Spread );
        
        // TODO FIXME .DE30Cash    
        if( 0 == StringCompare( ".DE30Cash", Symbol() ) )
        {
            return(rates_total);
        }
        
        if( 0<start ) 
        for( int bar = start; (bar >= 0) && !IsStopped(); bar-- )
        //for(bar=first; bar<rates_total && !IsStopped(); bar++)
        {
            if((Open[bar]*minusvar1)>Middle_prev)
            { 
                Middle=Open[bar]*minusvar1;
            }
            else
            {
             if(Open[bar]*plusvar1<Middle_prev) 
                Middle=Open[bar]*plusvar1;
             else 
                Middle=Middle_prev;
            }
            
            BoMiddle[bar] = Middle;
            Up1Buffer[bar]=Up2Buffer[bar]=Middle+(Middle/100) * BO_PERCENT;
            Dn1Buffer[bar]=Dn2Buffer[bar]=Middle-(Middle/100) * BO_PERCENT;
            
            if(bar<rates_total-1) Middle_prev=Middle;
            
            //Print( string( Time[bar] ) + " prev: " + string( prev_calculated)  + " total: " + string( rates_total) + " start: " + string( start) + " bar: " + string( bar)   );
            if( 0<start ) 
            if( rates_total > (start+24*5*4*12) )
            rip.AddChartData( bar,
                    rates_total, 
                    prev_calculated,
                    Time,
                    Open,
                    High,
                    Low,
                    Close,
                    TickVolume,
                    Volume,
                    Spread
            );
        
        }
         
        if( 0<start ) 
        if( rates_total > (start+24*5*4*12) )
        for( int bar = start; (bar >= 0) && !IsStopped(); bar-- )
        //for(bar=first; bar<rates_total && !IsStopped(); bar++)
        {
            if( rip.LoadMatrix( bar ) )
            {
                if( rip.AnalyseMatrix() )
                {
                    STradeSignals ts = rip.GetResultofMatrix();
                    if( ts.buybo )
                    {   
                        BuyBuff[bar] = Close[bar];
                    }
                    if( ts.sellbo )
                    {   
                        SellBuff[bar] = Close[bar];
                    }
                }
            }
/*        
            double open, high, low, close;
            int clr=eClrGray;
            ENUM_TIMEFRAMES tf = PERIOD_H4;
            open  = rip.Get( tf, IDX_OPEN,  bar );
            high  = rip.Get( tf, IDX_HIGH,  bar );
            low   = rip.Get( tf, IDX_LOW,   bar );
            close = rip.Get( tf, IDX_CLOSE, bar );
            ExtOpenBuffer1[bar] = open;
            ExtHighBuffer1[bar] = high;
            ExtLowBuffer1[bar]  = low;
            ExtCloseBuffer1[bar]= open;
            if( open > close )
                clr = eClrRed1;
            else
                clr = eClrBlue1;
            ExtColorBuffer1[bar]=clr;
            
            
            clr=eClrGray;
            tf = PERIOD_H1;
            open  = rip.Get( tf, IDX_OPEN,  bar );
            high  = rip.Get( tf, IDX_HIGH,  bar );
            low   = rip.Get( tf, IDX_LOW,   bar );
            close = rip.Get( tf, IDX_CLOSE, bar );
            ExtOpenBuffer2[bar] = open;
            ExtHighBuffer2[bar] = high;
            ExtLowBuffer2[bar]  = low;
            ExtCloseBuffer2[bar]= open;
            if( open > close )
                clr = eClrRed2;
            else
                clr = eClrBlue2;
            ExtColorBuffer2[bar]=clr;
            
            
            clr=eClrGray;
            tf = PERIOD_M15;
            open  = rip.Get( tf, IDX_OPEN,  bar );
            high  = rip.Get( tf, IDX_HIGH,  bar );
            low   = rip.Get( tf, IDX_LOW,   bar );
            close = rip.Get( tf, IDX_CLOSE, bar );
            ExtOpenBuffer3[bar] = open;
            ExtHighBuffer3[bar] = high;
            ExtLowBuffer3[bar]  = low;
            ExtCloseBuffer3[bar]= open;
            if( open > close )
                clr = eClrRed3;
            else
                clr = eClrBlue3;
            ExtColorBuffer3[bar]=clr;


            clr=eClrGray;
            tf = PERIOD_M5;
            open  = rip.Get( tf, IDX_OPEN,  bar );
            high  = rip.Get( tf, IDX_HIGH,  bar );
            low   = rip.Get( tf, IDX_LOW,   bar );
            close = rip.Get( tf, IDX_CLOSE, bar );
            ExtOpenBuffer4[bar] = open;
            ExtHighBuffer4[bar] = high;
            ExtLowBuffer4[bar]  = low;
            ExtCloseBuffer4[bar]= open;
            if( open > close )
                clr = eClrRed5;
            else
                clr = eClrBlue5;
            ExtColorBuffer4[bar]=clr;
*/            
            
        }
    } // if( (0 == prev_calculated) || ((1==CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ))&&(0<start)) )
   
    
//----    
    return(rates_total);
}
//+------------------------------------------------------------------+

//---------------------------------------------------------------------
//	Returns a sign of appearance of a new bar:
//---------------------------------------------------------------------
int CheckNewBar( string _symbol, ENUM_TIMEFRAMES _period, datetime& _last_dt )
{
	//datetime	curr_time = ( datetime )SeriesInfoInteger( _symbol, _period, SERIES_LASTBAR_DATE );
	datetime	curr_time = ( datetime )TimeLocal();
	
//--- if it is the first call of the function
   if( 0 == _last_dt ) 
     {
      //--- set the time and exit
		_last_dt = curr_time;
		return( 1 );
     }
     	
	if( curr_time > _last_dt + PeriodSeconds(_period) )
	{
		_last_dt = curr_time;
		return( 1 );
	}

	return( 0 );
}


// TODO duplicate - create indicator library
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
