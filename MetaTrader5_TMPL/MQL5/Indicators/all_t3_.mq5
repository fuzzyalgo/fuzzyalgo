//=====================================================================
//	ALL T3 indicator.
//=====================================================================
#property copyright "Copyright 2011 - 2016, Andre Howe"
#property link      "http://andrehowe.com"
#property version			"1.1"
#property description	"ALL T3 Indicator"
//---------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   9
//---------------------------------------------------------------------

#property indicator_type1	   DRAW_ARROW
#property indicator_color1	   clrBlue
#property indicator_style1	   STYLE_SOLID
#property indicator_width1	   1
#property indicator_label1     "Buy"

#property indicator_type2	   DRAW_ARROW
#property indicator_color2	   clrRed
#property indicator_style2	   STYLE_SOLID
#property indicator_width2	   1
#property indicator_label2     "Sell"

#property indicator_type3	   DRAW_ARROW
#property indicator_color3	   clrGreen
#property indicator_style3	   STYLE_SOLID
#property indicator_width3	   1
#property indicator_label3     "Exit"

#property indicator_type4	   DRAW_ARROW
#property indicator_color4	   clrBlue
#property indicator_style4	   STYLE_SOLID
#property indicator_width4	   1
#property indicator_label4     "Res-D1"

#property indicator_type5	   DRAW_ARROW
#property indicator_color5	   clrRed
#property indicator_style5	   STYLE_SOLID
#property indicator_width5	   1
#property indicator_label5     "Sup-D1"

#property indicator_type6	   DRAW_ARROW
#property indicator_color6	   clrGray
#property indicator_style6	   STYLE_SOLID
#property indicator_width6	   1
#property indicator_label6     "Res-W1"

#property indicator_type7	   DRAW_ARROW
#property indicator_color7	   clrGray
#property indicator_style7	   STYLE_SOLID
#property indicator_width7	   1
#property indicator_label7     "Sup-W1"


#property indicator_type8	   DRAW_ARROW
#property indicator_color8	   clrViolet
#property indicator_style8	   STYLE_SOLID
#property indicator_width8	   1
#property indicator_label8     "MA1"

#property indicator_type9	   DRAW_ARROW
#property indicator_color9	   clrPink
#property indicator_style9	   STYLE_SOLID
#property indicator_width9	   1
#property indicator_label9     "MA2"



//=====================================================================
//	External parameters:
//=====================================================================
input string                         FROM_TO_DATE  = "DD.MM.YYYY-DD.MM.YYYY";
input int                            AVG_CANDLE_HEIGHT = 0;// AVG_CANDLE_HEIGHT - if zero calc candle height, otherwise set this value
input int                            SL_LEVEL = 0; // SL_LEVEL - if AVG_CANDLE_HEIGHT(0), then set double
input int                            SR_PERIOD = 0;  // SR_PERIOD - if NULL calculate shift since day has started

//---------------------------------------------------------------------

//#include <library.mqh>

//---------------------------------------------------------------------
double	BuyBuff[ ];
double	SellBuff[ ];
double	ExitBuff[ ];
double  ResistanceD1Buff[];   // resistance - support resistance buffer
double  SupportD1Buff[];      // support    - support resistance buffer
double  ResistanceW1Buff[];   // resistance - support resistance buffer
double  SupportW1Buff[];      // support    - support resistance buffer
double	Ma1Buff[];
double	Ma2Buff[];
double	Sto1Buff[];
double	Sto2Buff[];

int				ma1_handler;
int				ma2_handler;
int				sto_handler;


//--- global variables
double gAvgCandleHeight = 0;
int gSlLevel = 0;
int gPeriodD1Prev = 0;
int gPeriodW1Prev = 0;
int gPeriodMNPrev = 0;
int gPeriodY1Prev = 0;
datetime gFromDateTime = NULL;
datetime gToDateTime = NULL;
int gCommissionInPoints = 5;
//--- global variables

const string gIndicatorName = "ALL_T3_";
bool TESTERMODE = false;

//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int OnInit()
{

    TESTERMODE = MQL5InfoInteger(MQL5_TESTER);
    
    // init global vars
    gAvgCandleHeight = 0;
    gSlLevel = 0;
    gPeriodD1Prev = 0;
    gPeriodW1Prev = 0;
    gFromDateTime = NULL;
    gToDateTime = NULL;
    GetFromToDatetimeFromInput(FROM_TO_DATE, gFromDateTime, gToDateTime);
    
    // init global vars
    
    //Comment( "" );
    ObjectsDeleteAll(0, gIndicatorName);
    
    SetIndexBuffer( 0, BuyBuff,INDICATOR_DATA );
    SetIndexBuffer( 1, SellBuff,INDICATOR_DATA );
    SetIndexBuffer( 2, ExitBuff,INDICATOR_DATA );
    SetIndexBuffer( 3, ResistanceD1Buff, INDICATOR_DATA );
    SetIndexBuffer( 4, SupportD1Buff,    INDICATOR_DATA );
    SetIndexBuffer( 5, ResistanceW1Buff, INDICATOR_DATA );
    SetIndexBuffer( 6, SupportW1Buff,    INDICATOR_DATA );
	SetIndexBuffer( 7, Ma1Buff,    INDICATOR_DATA );
	SetIndexBuffer( 8, Ma2Buff,    INDICATOR_DATA );
	SetIndexBuffer( 9, Sto1Buff,    INDICATOR_CALCULATIONS );
	SetIndexBuffer(10, Sto2Buff,    INDICATOR_CALCULATIONS );
    
    ArraySetAsSeries( BuyBuff, true );
    ArraySetAsSeries( SellBuff, true );
    ArraySetAsSeries( ExitBuff, true );
    ArraySetAsSeries( ResistanceD1Buff, true );
    ArraySetAsSeries( SupportD1Buff, true );
    ArraySetAsSeries( ResistanceW1Buff, true );
    ArraySetAsSeries( SupportW1Buff, true );
    ArraySetAsSeries( Ma1Buff, true );
    ArraySetAsSeries( Ma2Buff, true );
    ArraySetAsSeries( Sto1Buff, true );
    ArraySetAsSeries( Sto2Buff, true );
    
    
    bool is =ArrayGetAsSeries( BuyBuff );
    if( false == is ){ return (-100); }
    is = ArrayGetAsSeries( SellBuff );
    if( false == is ){ return (-101); }
    is = ArrayGetAsSeries( ExitBuff );
    if( false == is ){ return (-102); }
    is = ArrayGetAsSeries( ResistanceD1Buff );
    if( false == is ){ return (-103); }
    is = ArrayGetAsSeries( SupportD1Buff );
    if( false == is ){ return (-104); }
    is = ArrayGetAsSeries( ResistanceW1Buff );
    if( false == is ){ return (-105); }
    is = ArrayGetAsSeries( SupportW1Buff );
    if( false == is ){ return (-106); }
    is = ArrayGetAsSeries( Ma1Buff );
    if( false == is ){ return (-107); }
    is = ArrayGetAsSeries( Ma2Buff );
    if( false == is ){ return (-108); }
    is = ArrayGetAsSeries( Sto1Buff );
    if( false == is ){ return (-109); }
    is = ArrayGetAsSeries( Sto2Buff );
    if( false == is ){ return (-109); }
    
    
    PlotIndexSetInteger(0,PLOT_ARROW,139);
    PlotIndexSetInteger(1,PLOT_ARROW,139);
    PlotIndexSetInteger(2,PLOT_ARROW,139);
    PlotIndexSetInteger(3,PLOT_ARROW,159);
    PlotIndexSetInteger(4,PLOT_ARROW,159);
    PlotIndexSetInteger(5,PLOT_ARROW,159);
    PlotIndexSetInteger(6,PLOT_ARROW,159);
    PlotIndexSetInteger(7,PLOT_ARROW,159);
    PlotIndexSetInteger(8,PLOT_ARROW,159);
    
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
    PlotIndexSetDouble(10, PLOT_EMPTY_VALUE, 0.0 );
    
    
    IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));
    IndicatorSetString( INDICATOR_SHORTNAME, gIndicatorName + "( IP = " + string( FROM_TO_DATE ) + " AVG = " + string( AVG_CANDLE_HEIGHT )  + " SL = " + string( SL_LEVEL ) + " SR = " + string( SR_PERIOD ) + " )" );
    
    
	ma1_handler = iMA(Symbol( ), Period( ), 5, 0, MODE_EMA, PRICE_TYPICAL );
	if( ma1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA1 indicator" );
		return( -1 );
	}

	ma2_handler = iMA(Symbol( ), Period( ), 60, 0, MODE_SMA, PRICE_CLOSE );
	if( ma2_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the MA1 indicator" );
		return( -1 );
	}

	sto_handler = iStochastic(Symbol( ), Period( ), 5, 3, 3, MODE_SMA, STO_LOWHIGH );
	if( sto_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the STO indicator" );
		return( -1 );
	}
    
    ObjectsDeleteAll(0, gIndicatorName);
    ChartRedraw( );
    
    return( 0 );
}

//---------------------------------------------------------------------
//	Indicator calculation event handler:
//---------------------------------------------------------------------
//---------------------------------------------------------------------
int OnCalculate(const int rates_total,
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
    

    static datetime	last_bar_datetime_chart = 0;
    
    static bool firsttimebuy = false;
    static bool firsttimesell = false;
    static double buyprice = 0;
    static datetime buytime = 0;
    static double sellprice = 0;
    static datetime selltime = 0;
    
    static int sumbuy = 0;
    static int sumbuywin = 0;
    static int sumbuyloss = 0;
    static int sumsell = 0;
    static int sumsellwin = 0;
    static int sumsellloss = 0;
    
    static int cntbuy = 0;
    static int cntbuywin = 0;
    static int cntbuyloss = 0;
    static int cntsell = 0;
    static int cntsellwin = 0;
    static int cntsellloss = 0;
        
    int my_rates_total = rates_total;
    if( prev_calculated == 0)
    {
        last_bar_datetime_chart = 0;
        
        firsttimebuy = false;
        firsttimesell = false;
        buyprice = 0;
        buytime = 0;
        sellprice = 0;
        selltime = 0;
        
        sumbuy = 0;
        sumbuywin = 0;
        sumbuyloss = 0;
        sumsell = 0;
        sumsellwin = 0;
        sumsellloss = 0;
        
        cntbuy = 0;
        cntbuywin = 0;
        cntbuyloss = 0;
        cntsell = 0;
        cntsellwin = 0;
        cntsellloss = 0;
        
        //ObjectsDeleteAll(0, gIndicatorName);
        //ChartRedraw( );
    	
    } // if( prev_calculated == 0)
    //
    // generic part support and resistance start
    //  

    int start = rates_total-prev_calculated;
    if( rates_total <= start )
    {
        start = rates_total - 1;
    }
    
	if( CopyBuffer( ma1_handler, 0, 0, rates_total - 1, Ma1Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( ma2_handler, 0, 0, rates_total - 1, Ma2Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( sto_handler, 0, 0, rates_total - 1, Sto1Buff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( sto_handler, 1, 0, rates_total - 1, Sto2Buff ) == -1 )
	{
		return( rates_total );
	}

    if( (0 == prev_calculated) || ((1==CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ))&&(0<start)) )
    {
        int buycnt = 0;
        int sellcnt = 0;
        
        for( int i = start; i > 0; i-- )
		{
         BuyBuff[i]           = 0.0;
         SellBuff[i]          = 0.0;
         ExitBuff[i]          = 0.0;
         ResistanceD1Buff[i]  = 0;
         SupportD1Buff[i]     = 0;
         ResistanceW1Buff[i]  = 0;
         SupportW1Buff[i]     = 0;
         
		
         bool buyflag = false;
         bool sellflag = false;
         double suplvl = 0;
         double reslvl = 0; 
         double atrxlvl = 0;
         double atrxlvlD1 = 0;
         
         if( true == CheckDatetimeAndSkipSeries(Time[i]) )
         {
            continue;
         }
         
         int periodD1 = 10;
         int periodW1 = 10;
         int periodMN = 10;
         int periodY1 = 10;
         periodD1 = m_IndiGetShiftSinceDayStarted(i);
         periodW1 = m_IndiGetShiftSinceWeekStarted(i);
         periodMN = m_IndiGetShiftSinceMonthStarted(i);
         periodY1 = m_IndiGetShiftSinceYearStarted(i);
         if( 0 == prev_calculated)
         {
         }
         else
         {
         }
         
         // sanity check for array out of range
         if( (rates_total-1) < (i+periodD1 )) continue;
         if( (rates_total-1) < (i+periodW1 )) continue;
         if( 1 == SR_PERIOD )
         {
             if( (rates_total-1) < (i+periodMN )) continue;
         }             
         if( 2 == SR_PERIOD )
         {
             if( (rates_total-1) < (i+periodMN )) continue;
             if( (rates_total-1) < (i+periodY1 )) continue;
         }             
         
         if( 0 == SR_PERIOD )
         {
             // TODO FIXME
             if( 0 == periodD1 )
             {
                buycnt = 0;
                sellcnt = 0;
             }
             double max=High[ArrayMaximum(High,i,periodD1)];
             double min=Low[ArrayMinimum(Low,i,periodD1)];
             double atr = (max-min)/Point();
             atrxlvl = atr;
             if( periodD1 < gPeriodD1Prev )
             {
                 if( 0 == AVG_CANDLE_HEIGHT )
                 {
                     // gPeriodD1 shall contain zero in this case
                     // gPeriodD1Prev shall contain for e.g. M15 96 -> 24*4*1  24h*4Bars per hour * 1 day
                     gAvgCandleHeight=getAvgCandleHeight(rates_total, i,gPeriodD1Prev,High,Low);
                     gSlLevel = 2*(int)(gAvgCandleHeight/Point());
                     //printf("Calculated average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
                 else
                 {
                     gAvgCandleHeight = AVG_CANDLE_HEIGHT*Point();
                     gSlLevel = SL_LEVEL;
                     //printf("Set average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
             }
             gPeriodD1Prev = periodD1;
         }
         
         else if( 1 == SR_PERIOD )
         {
             if( 0 == periodW1 )
             {
                buycnt = 0;
                sellcnt = 0;
             }
             double max=High[ArrayMaximum(High,i,periodW1)];
             double min=Low[ArrayMinimum(Low,i,periodW1)];
             double atr = (max-min)/Point();
             atrxlvl = atr;
             
             // TODO clean me up
             max=High[ArrayMaximum(High,i,periodD1)];
             min=Low[ArrayMinimum(Low,i,periodD1)];
             atr = (max-min)/Point();
             atrxlvlD1 = atr;
             
             if( periodW1 < gPeriodW1Prev )
             {
                 if( 0 == AVG_CANDLE_HEIGHT )
                 {
                     // gPeriodW1 shall contain zero in this case
                     // gPeriodW1Prev shall contain for e.g. M15 480 -> 24*4*5  24h*4Bars per hour * 5 days
                     gAvgCandleHeight=getAvgCandleHeight(rates_total, i,gPeriodW1Prev,High,Low);
                     gSlLevel = 2*(int)(gAvgCandleHeight/Point());
                     //printf("Calculated average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
                 else
                 {
                     gAvgCandleHeight = AVG_CANDLE_HEIGHT*Point();
                     gSlLevel = SL_LEVEL;
                     //printf("Set average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
             }
             gPeriodW1Prev = periodW1;
         }
             
         else if( 2 == SR_PERIOD )
         {
             double max=High[ArrayMaximum(High,i,periodMN)];
             double min=Low[ArrayMinimum(Low,i,periodMN)];
             double atr = (max-min)/Point();
             atrxlvl = atr;
             if( periodMN < gPeriodMNPrev )
             {
                 if( 0 == AVG_CANDLE_HEIGHT )
                 {
                     // gPeriodMN shall contain zero in this case
                     // gPeriodMNPrev shall contain for e.g. M15 480 -> 24*4*5  24h*4Bars per hour * 5 days
                     gAvgCandleHeight=getAvgCandleHeight(rates_total, i,gPeriodMNPrev,High,Low);
                     gSlLevel = 2*(int)(gAvgCandleHeight/Point());
                     //printf("Calculated average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
                 else
                 {
                     gAvgCandleHeight = AVG_CANDLE_HEIGHT*Point();
                     gSlLevel = SL_LEVEL;
                     //printf("Set average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
             }
             gPeriodMNPrev = periodMN;
         } 

         else if( 3 == SR_PERIOD )
         {
             double max=High[ArrayMaximum(High,i,periodY1)];
             double min=Low[ArrayMinimum(Low,i,periodY1)];
             double atr = (max-min)/Point();
             atrxlvl = atr;
             if( periodY1 < gPeriodY1Prev )
             {
                 if( 0 == AVG_CANDLE_HEIGHT )
                 {
                     // gPeriodY1 shall contain zero in this case
                     // gPeriodY1Prev shall contain for e.g. M15 480 -> 24*4*5  24h*4Bars per hour * 5 days
                     gAvgCandleHeight=getAvgCandleHeight(rates_total, i,gPeriodY1Prev,High,Low);
                     gSlLevel = 2*(int)(gAvgCandleHeight/Point());
                     //printf("Calculated average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
                 else
                 {
                     gAvgCandleHeight = AVG_CANDLE_HEIGHT*Point();
                     gSlLevel = SL_LEVEL;
                     //printf("Set average candle height for this time frame is %.5f %d %d",gAvgCandleHeight, (int)(gAvgCandleHeight/Point()), gSlLevel);
                 }
             }
             gPeriodY1Prev = periodY1;
         } // if( 0 == SR_PERIOD )
         
         // if full configuration and setup has not happen yet so far
         //   then skip the rest.            
         if( (0 == gAvgCandleHeight) || ( 0 == gSlLevel ) ) continue;
         
             
         ////Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " SD1 " + DoubleToString(SupportD1Buff[i],Digits())+ " SW1 " + DoubleToString(SupportW1Buff[i],Digits())+ " i " + its(i)  + " D1 " + its(periodD1) + " W1 " + its(periodW1) );
         
         if( 0 == SR_PERIOD )
         {
             ResistanceD1Buff[i]=Ma2Buff[i+periodD1]+gAvgCandleHeight;
             SupportD1Buff[i]=Ma2Buff[i+periodD1]-gAvgCandleHeight;
             ResistanceW1Buff[i]=Ma2Buff[i+periodW1]+gAvgCandleHeight;
             SupportW1Buff[i]=Ma2Buff[i+periodW1]-gAvgCandleHeight;
         
             //ResistanceD1Buff[i]=High[i+periodD1]+gAvgCandleHeight;
             //SupportD1Buff[i]=Low[i+periodD1]-gAvgCandleHeight;
             //ResistanceW1Buff[i]=High[i+periodW1]+gAvgCandleHeight;
             //SupportW1Buff[i]=Low[i+periodW1]-gAvgCandleHeight;
             
             suplvl = SupportD1Buff[i];
             reslvl = ResistanceD1Buff[i];
         }
         else if( 1 == SR_PERIOD )
         {
             ResistanceD1Buff[i]=Ma2Buff[i+periodD1]+gAvgCandleHeight;
             SupportD1Buff[i]=Ma2Buff[i+periodD1]-gAvgCandleHeight;
             ResistanceW1Buff[i]=Ma2Buff[i+periodW1]+gAvgCandleHeight;
             SupportW1Buff[i]=Ma2Buff[i+periodW1]-gAvgCandleHeight;
         
             //ResistanceD1Buff[i]=High[i+periodD1]+gAvgCandleHeight;
             //SupportD1Buff[i]=Low[i+periodD1]-gAvgCandleHeight;
             //ResistanceW1Buff[i]=High[i+periodW1]+gAvgCandleHeight;
             //SupportW1Buff[i]=Low[i+periodW1]-gAvgCandleHeight;
         
             suplvl = SupportW1Buff[i];
             reslvl = ResistanceW1Buff[i];
         }

         else if( 2 == SR_PERIOD )
         {
         
             ResistanceD1Buff[i]=Ma2Buff[i+periodW1]+gAvgCandleHeight;
             SupportD1Buff[i]=Ma2Buff[i+periodW1]-gAvgCandleHeight;
             ResistanceW1Buff[i]=Ma2Buff[i+periodMN]+gAvgCandleHeight;
             SupportW1Buff[i]=Ma2Buff[i+periodMN]-gAvgCandleHeight;
         
             //ResistanceD1Buff[i]=High[i+periodW1]+gAvgCandleHeight;
             //SupportD1Buff[i]=Low[i+periodW1]-gAvgCandleHeight;
             //ResistanceW1Buff[i]=High[i+periodMN]+gAvgCandleHeight;
             //SupportW1Buff[i]=Low[i+periodMN]-gAvgCandleHeight;
         
             suplvl = SupportW1Buff[i];
             reslvl = ResistanceW1Buff[i];
         }   
         
         else if( 3 == SR_PERIOD )
         {
         
             ResistanceD1Buff[i]=Ma2Buff[i+periodMN]+gAvgCandleHeight;
             SupportD1Buff[i]=Ma2Buff[i+periodMN]-gAvgCandleHeight;
             ResistanceW1Buff[i]=Ma2Buff[i+periodY1]+gAvgCandleHeight;
             SupportW1Buff[i]=Ma2Buff[i+periodY1]-gAvgCandleHeight;
         
             //ResistanceD1Buff[i]=High[i+periodMN]+gAvgCandleHeight;
             //SupportD1Buff[i]=Low[i+periodMN]-gAvgCandleHeight;
             //ResistanceW1Buff[i]=High[i+periodY1]+gAvgCandleHeight;
             //SupportW1Buff[i]=Low[i+periodY1]-gAvgCandleHeight;
         
             suplvl = SupportW1Buff[i];
             reslvl = ResistanceW1Buff[i];
         } // if( 0 == SR_PERIOD )
         
         if( true == firsttimebuy )
         {
             /*if( (0!=buyprice)  && ((Ma1Buff[i]<Ma2Buff[i]) && (Ma1Buff[i+1]>=Ma2Buff[i+1])) ) 
             {
                 if( (Close[i]<buyprice) )
                 {
                     sumbuyloss = sumbuyloss + (int)((buyprice-Close[i])/Point()) + gCommissionInPoints;
                     cntbuyloss++;
                     ExitBuff[i] = Close[i];
                     firsttimebuy = false;
                     string str = gIndicatorName + " buyloss #" + its(cntbuyloss) + " P:" + its((int)((buyprice-Close[i])/Point())+ gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                     TrendCreate(str,buytime,buyprice,Time[i],Close[i],clrGreen );
                     buyprice = 0;
                     buytime = 0;
                     continue;
                 }
                 else
                 // (Close[i]>buyprice)
                 {
                     sumbuywin = sumbuywin + (int)((Close[i]-buyprice)/Point()) - gCommissionInPoints;
                     cntbuywin++;
                     ExitBuff[i] = Close[i];
                     firsttimebuy = false;
                     string str = gIndicatorName + " buywin #" + its(cntbuywin) + " P:" + its((int)((Close[i]-buyprice)/Point()) - gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                     TrendCreate(str,buytime,buyprice,Time[i],Close[i],clrBlue );
                     buyprice = 0;
                     buytime = 0;
                     //Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " " + DoubleToString(Close[i],Digits()) + " " + DoubleToString(buyprice,Digits()) );
                     continue;
                 }
                 
             }*/
             
             if( (0!=buyprice) && ((Close[i]-buyprice)/Point() > gSlLevel) ) 
             {
                 sumbuywin = sumbuywin + (int)((Close[i]-buyprice)/Point()) - gCommissionInPoints;
                 cntbuywin++;
                 ExitBuff[i] = Close[i];
                 firsttimebuy = false;
                 string str = gIndicatorName + " buywin #" + its(cntbuywin) + " P:" + its((int)((Close[i]-buyprice)/Point()) - gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                 TrendCreate(str,buytime,buyprice,Time[i],Close[i],clrBlue );
                 buyprice = 0;
                 buytime = 0;
                 //Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " " + DoubleToString(Close[i],Digits()) + " " + DoubleToString(buyprice,Digits()) );
                 continue;
             }
             
         
         
             //if( (0!=buyprice) && (Ma2Buff[i] < suplvl) )
             if( (0!=buyprice) && (Ma2Buff[i] > Close[i]) )
             {
                 sumbuyloss = sumbuyloss + (int)((buyprice-Close[i])/Point()) + gCommissionInPoints;
                 cntbuyloss++;
                 ExitBuff[i] = Close[i];
                 firsttimebuy = false;
                 string str = gIndicatorName + " buyloss #" + its(cntbuyloss) + " P:" + its((int)((buyprice-Close[i])/Point())+ gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                 TrendCreate(str,buytime,buyprice,Time[i],Close[i],clrGreen );
                 buyprice = 0;
                 buytime = 0;
                 continue;
             }
         /*    if( (0!=buyprice) && ((Close[i]-buyprice)/Point() > gSlLevel) ) 
             {
                 sumbuywin = sumbuywin + (int)((Close[i]-buyprice)/Point()) - gCommissionInPoints;
                 cntbuywin++;
                 ExitBuff[i] = Close[i];
                 firsttimebuy = false;
                 string str = gIndicatorName + " buywin #" + its(cntbuywin) + " P:" + its((int)((Close[i]-buyprice)/Point()) - gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                 //TrendCreate(str,buytime,buyprice,Time[i],Close[i],clrBlue );
                 buyprice = 0;
                 buytime = 0;
                 //Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " " + DoubleToString(Close[i],Digits()) + " " + DoubleToString(buyprice,Digits()) );
                 continue;
             }
         */    
         } // if( true == firsttimebuy )
         
         if( true == firsttimesell )
         {
         
             //if( (0!=sellprice) && (Ma2Buff[i] > reslvl) )
             if( (0!=sellprice) && (Ma2Buff[i] < Close[i]) )
             {
                 sumsellloss = sumsellloss + (int)((Close[i]-sellprice)/Point()) + gCommissionInPoints;
                 cntsellloss++;
                 ExitBuff[i] = Close[i];
                 firsttimesell = false;
                 string str = gIndicatorName + " sellloss #" + its(cntsellloss) + " P:" + its((int)((Close[i]-sellprice)/Point()) + gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                 TrendCreate(str,selltime,sellprice,Time[i],Close[i],clrViolet );
                 sellprice = 0;
                 selltime = 0;
                 continue;
             }
         /*    if( (0!=sellprice) && ((sellprice-Close[i])/Point() > gSlLevel) ) 
             {
                 sumsellwin = sumsellwin + (int)((sellprice-Close[i])/Point()) - gCommissionInPoints;
                 cntsellwin++;
                 ExitBuff[i] = Close[i];
                 firsttimesell = false;
                 string str = gIndicatorName + " sellwin #" + its(cntsellwin) + " P:" + its((int)((sellprice-Close[i])/Point())- gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                 //TrendCreate( str,selltime,sellprice,Time[i],Close[i],clrRed );
                 sellprice = 0;
                 selltime = 0;
                 //Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " " + DoubleToString(Close[i],Digits()) + " " + DoubleToString(buyprice,Digits()) );
                 continue;
             }
         */
            /* if( (0!=sellprice) && ((Ma1Buff[i]>Ma2Buff[i]) && (Ma1Buff[i+1]<=Ma2Buff[i+1]))  ) 
             {
                 if( sellprice<Close[i] ) 
                 {
                     sumsellloss = sumsellloss + (int)((Close[i]-sellprice)/Point()) + gCommissionInPoints;
                     cntsellloss++;
                     ExitBuff[i] = Close[i];
                     firsttimesell = false;
                     string str = gIndicatorName + " sellloss #" + its(cntsellloss) + " P:" + its((int)((Close[i]-sellprice)/Point()) + gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                     TrendCreate(str,selltime,sellprice,Time[i],Close[i],clrViolet );
                     sellprice = 0;
                     selltime = 0;
                     continue;
                 }
                 else // (sellprice>Close[i])
                 {
                     sumsellwin = sumsellwin + (int)((sellprice-Close[i])/Point()) - gCommissionInPoints;
                     cntsellwin++;
                     ExitBuff[i] = Close[i];
                     firsttimesell = false;
                     string str = gIndicatorName + " sellwin #" + its(cntsellwin) + " P:" + its((int)((sellprice-Close[i])/Point())- gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                     TrendCreate( str,selltime,sellprice,Time[i],Close[i],clrRed );
                     sellprice = 0;
                     selltime = 0;
                     //Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " " + DoubleToString(Close[i],Digits()) + " " + DoubleToString(buyprice,Digits()) );
                     continue;
                 }                 
             }*/
             
             if( (0!=sellprice) && ((sellprice-Close[i])/Point() > gSlLevel) ) 
             {
                 sumsellwin = sumsellwin + (int)((sellprice-Close[i])/Point()) - gCommissionInPoints;
                 cntsellwin++;
                 ExitBuff[i] = Close[i];
                 firsttimesell = false;
                 string str = gIndicatorName + " sellwin #" + its(cntsellwin) + " P:" + its((int)((sellprice-Close[i])/Point())- gCommissionInPoints) + " T:" + its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss) + " TCNT:" + its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss); 
                 TrendCreate( str,selltime,sellprice,Time[i],Close[i],clrRed );
                 sellprice = 0;
                 selltime = 0;
                 //Print( TimeToString(iTime(Symbol(),Period(),i),TIME_DATE|TIME_SECONDS) + " " + DoubleToString(Close[i],Digits()) + " " + DoubleToString(buyprice,Digits()) );
                 continue;
             }
             
         } // if( true == firsttimesell )

        // TODO fixme
        /*MqlDateTime mdt;
        TimeToStruct( Time[i], mdt );
        if( ( 2 > mdt.hour ) || ( 21 < mdt.hour ) )
        {
          continue;
        }*/

                     
        /*if( 
         (Low[i] > (reslvl+gAvgCandleHeight) ) 
         )
        {
         buyflag = true;
        }
        if( 
         (High[i] < (suplvl-gAvgCandleHeight) ) 
         )
        {
         sellflag = true;
        }*/
         
        /*if( Low[i] > (reslvl+gAvgCandleHeight) )         
        if
            (   
                 ( Close[i] - Close[i+1]  > 0.0001 )  
              && ( Close[i] - Close[i+3]  > 0.0001 )  
              && ( Close[i] - Close[i+6]  > 0.0001 )  
              && ( Close[i] - Close[i+12] > 0.0001 )  
            )*/
        if( 
            //    ( (Ma1Buff[i]>Ma2Buff[i]) && (Ma1Buff[i+1]<=Ma2Buff[i+1]))             
                ( (Ma1Buff[i]>Ma2Buff[i]) ) 
            &&  (  Close[i] > Ma1Buff[i] )
            //&&  ( atrxlvl > 400 )
            //&&  ( (Ma1Buff[i]-Ma2Buff[i])/Point() > 50 )
            /*&& (
                    ( (0 == SR_PERIOD) && (Ma2Buff[i] > ResistanceD1Buff[i]) )    
                ||  ( (1 == SR_PERIOD) && (Ma2Buff[i] > ResistanceW1Buff[i]) )    
               )*/
            
            /*&&  ( 
                       (Sto1Buff[i]   > Sto2Buff[i] ) 
                    //&& (Sto1Buff[i+1] < Sto2Buff[i+1] ) 
                    && (Sto1Buff[i]   < 80 ) 
                    //&& (Sto2Buff[i]   < 80 ) 
                )*/        
        )
        /*if
            (   
                 ( Close[i+0] - Open[i+0]  > 0.000 )  
              && ( Close[i+1] - Open[i+1]  > 0.000 )  
              && ( Close[i+2] - Open[i+2]  > 0.000 )  
            )*/
        {
            //sellcnt = 0;
            //if( 0 == buycnt )
                buyflag = true;
            buycnt++;
        }
        
        /*if( High[i] < (suplvl-gAvgCandleHeight) ) 
        if
            (   
                 ( Close[i+1]  - Close[i] > 0.0001 )  
              && ( Close[i+3]  - Close[i] > 0.0001 )  
              && ( Close[i+6]  - Close[i] > 0.0001 )  
              && ( Close[i+12] - Close[i] > 0.0001 )  
            )*/
        if( 
            //    ( (Ma1Buff[i]<Ma2Buff[i]) && (Ma1Buff[i+1]>=Ma2Buff[i+1]) )              
                ( (Ma1Buff[i]<Ma2Buff[i]) ) 
            &&  (  Close[i] < Ma1Buff[i] )
            //&&  ( atrxlvl > 400 )
            //&&  ( (Ma2Buff[i]-Ma1Buff[i])/Point() > 50 )
            /*&&  (
                     ( (0 == SR_PERIOD) && (Ma2Buff[i] < SupportD1Buff[i]) )
                 ||  ( (1 == SR_PERIOD) && (Ma2Buff[i] < SupportW1Buff[i]) )
                )*/  
            /*&&  ( 
                       (Sto1Buff[i]   < Sto2Buff[i] ) 
                    //&& (Sto1Buff[i+1] > Sto2Buff[i+1] ) 
                    && (Sto1Buff[i]   > 20 ) 
                    //&& (Sto2Buff[i]   > 20 ) 
                )*/        
            
        )
        /*if
            (   
                 ( Open[i+0] - Close[i+0]  > 0.000 )  
              && ( Open[i+1] - Close[i+1]  > 0.000 )  
              && ( Open[i+2] - Close[i+2]  > 0.000 )  
            )*/
            
        {
            //buycnt = 0;
            //if( 0 == sellcnt )
                sellflag = true;
            sellcnt++;
        }
         

            // buy
			if( true == buyflag )
			{
			    if(( false == firsttimebuy ) && ( false == firsttimesell ))
			    //if( (0.0==buyprice) || ((0.0!=buyprice)&&(Close[i]>buyprice)) )
			    {
    				BuyBuff[ i ] = Close[i];
    				buyprice = Close[i];
    				buytime = Time[i];
    				firsttimebuy = true;
    				firsttimesell = false;
			    }
			}
			// sell
			if( true == sellflag )
			{
			    if(( false == firsttimesell ) && ( false == firsttimebuy ))
			    //if( (0.0==sellprice) || ((0.0!=sellprice)&&(Close[i]<sellprice)) )
			    {
    				SellBuff[ i ] = Close[i];
    				sellprice = Close[i];
    				selltime = Time[i];
    				firsttimebuy = false;
    				firsttimesell = true;
			    }
			}
			// neutral
			else
			{
				//ColorBuff[ i ] = 0;
				//ValueBuff[ i ] = Close[i];
			}
			
			// TODO clean me up
            /* if( 0.0 != buyprice )
             {
                 ResistanceD1Buff[i]=buyprice;
                 SupportD1Buff[i]=buyprice-100*Point();
             }
             if( 0.0 != sellprice )
             {
                 SupportD1Buff[i]=sellprice;
                 ResistanceD1Buff[i]=sellprice+100*Point();
             }*/
			
		} // for( int i = start; i < rates_total - 1; i++ )

        if( false == TESTERMODE )
        {
            string s_symbol  = Symbol();
            string s_period  = ConvertPeriodToString(Period());
            string s_time    = TimeToString(Time[0],TIME_DATE|TIME_MINUTES);
    
            datetime dtfrom = gFromDateTime;
            datetime dtto   = gToDateTime;
            // TODO indicator duplicate - minus one year
            if( NULL == dtfrom )
            {
                datetime dt2 = TimeLocal();
                MqlDateTime mdt2;
                TimeToStruct( dt2, mdt2 );
                mdt2.year = mdt2.year-1;
                dtfrom = StructToTime( mdt2 );
            }
            if( NULL == dtto )
            {
                dtto = TimeLocal();
            }    
            string s_para_from  = TimeToString(dtfrom,TIME_DATE);  
            string s_para_to    = TimeToString(dtto  ,TIME_DATE);  
            string s_para_avg   = its( AVG_CANDLE_HEIGHT );
            string s_para_sl    = its( SL_LEVEL );
            string s_para_sr    = its( SR_PERIOD );
            Print( s_symbol + " " + s_period + " " + s_time
              + " PARA "
              + " FROMDATE "            + s_para_from
              + " TODATE "              + s_para_to
              + " AVG_CANDLE_HEIGHT "   + s_para_avg
              + " SL_LEVEL "            + s_para_sl
              + " SR_PERIOD "           + s_para_sr
              );
              
            // INTERFACE START          
            string s_filedelim  = "_";
            string s_filename   = s_symbol + s_filedelim + s_period + s_filedelim + s_para_from + s_filedelim + s_para_to + 
                                  s_filedelim + s_para_avg + s_filedelim + s_para_sl + s_filedelim + s_para_sr + ".csv";
            // INTERFACE END
            
            string s_cnt    = its(cntsellwin+cntsellloss + cntbuywin+cntbuyloss);
            string s_cntw   = its(cntbuywin+cntsellwin);
            string s_cntl   = its(cntbuyloss+cntsellloss); 
            string s_cntb   = its(cntbuywin+cntbuyloss); 
            string s_cntwb  = its(cntbuywin); 
            string s_cntlb  = its(cntbuyloss); 
            string s_cnts   = its(cntsellwin+cntsellloss);
            string s_cntws  = its(cntsellwin); 
            string s_cntls  = its(cntsellloss); 
            Print( s_symbol + " " + s_period + " " + s_time
              + " CNT "     + s_cnt
              + " CNTW "    + s_cntw
              + " CNTL "    + s_cntl
              + " CNTB "    + s_cntb
              + " CNTWB "   + s_cntwb
              + " CNTLB "   + s_cntlb
              + " CNTS "    + s_cnts
              + " CNTWS "   + s_cntws
              + " CNTLS "   + s_cntls
              );
              
            string s_avg    = ((0==cntsellwin)&&(0==cntsellloss)&&(0==cntbuywin)&&(0==cntbuyloss))?"N/A":its((sumsellwin+sumsellloss + sumbuywin+sumbuyloss)/(cntsellwin+cntsellloss + cntbuywin+cntbuyloss));
            string s_avgw   = ((0==cntbuywin)&&(0==cntsellwin))?"N/A":its((sumbuywin+sumsellwin)/(cntbuywin+cntsellwin));
            string s_avgl   = ((0==cntbuyloss)&&(0==cntsellloss))?"N/A":its((sumbuyloss+sumsellloss)/(cntbuyloss+cntsellloss));
            string s_avgb   = ((0==cntbuywin)&&(0==cntbuyloss))?"N/A":its((sumbuywin+sumbuyloss)/(cntbuywin+cntbuyloss));
            string s_avgwb  = (0==cntbuywin)?"N/A":its(sumbuywin/cntbuywin);
            string s_avglb  = (0==cntbuyloss)?"N/A":its(sumbuyloss/cntbuyloss);
            string s_avgs   = ((0==cntsellwin)&&(0==cntsellloss))?"N/A":its((sumsellwin+sumsellloss)/(cntsellwin+cntsellloss));
            string s_avgws  = (0==cntsellwin)?"N/A":its(sumsellwin/cntsellwin);
            string s_avgls  = (0==cntsellloss)?"N/A":its(sumsellloss/cntsellloss);
            Print( s_symbol + " " + s_period + " " + s_time
              + " AVG "     + s_avg
              + " AVGW "    + s_avgw
              + " AVGL "    + s_avgl 
              + " AVGB "    + s_avgb
              + " AVGWB "   + s_avgwb
              + " AVGLB "   + s_avglb
              + " AVGS "    + s_avgs
              + " AVGWS "   + s_avgws
              + " AVGLS "   + s_avgls
              );
    
            string s_prp    = ((0==sumbuyloss)&&(0==sumsellloss))?"N/A":DoubleToString((double)(sumbuywin+sumsellwin)/(sumbuyloss+sumsellloss),2);
            string s_prpb   = (0==sumbuyloss)?"N/A":DoubleToString((double)(sumbuywin)/(sumbuyloss),2);
            string s_prps   = (0==sumsellloss)?"N/A":DoubleToString((double)(sumsellwin)/(sumsellloss),2);
            string s_set_or_calc = AVG_CANDLE_HEIGHT ? "SET" : "CALC";
            string s_avgcalc= its((int)(gAvgCandleHeight/Point())); 
            string s_slcalc = its(gSlLevel);
            string s_pc     = its(prev_calculated);
            string s_rt     = its(rates_total);
            Print( s_symbol + " " + s_period + " " + s_time
              + " PRP "     + s_prp
              + " PRPB "    + s_prpb
              + " PRPS "    + s_prps
              + " "         + s_set_or_calc
              + " AVGCALC " + s_avgcalc
              + " SLCALC "  + s_slcalc
              + " PC "      + s_pc
              + " RT "      + s_rt
              );
    
            string s_sum    = its(sumsellwin-sumsellloss + sumbuywin-sumbuyloss);
            string s_sumw   = its(sumbuywin+sumsellwin); 
            string s_suml   = its(sumbuyloss+sumsellloss); 
            string s_sumb   = its(sumbuywin-sumbuyloss); 
            string s_sumwb  = its(sumbuywin); 
            string s_sumlb  = its(sumbuyloss); 
            string s_sums   = its(sumsellwin-sumsellloss);
            string s_sumws  = its(sumsellwin); 
            string s_sumls  = its(sumsellloss); 
            Print( s_symbol + " " + s_period + " " + s_time
              + " SUM "     + s_sum
              + " SUMW "    + s_sumw
              + " SUML "    + s_suml
              + " SUMB "    + s_sumb
              + " SUMWB "   + s_sumwb
              + " SUMLB "   + s_sumlb
              + " SUMS "    + s_sums
              + " SUMWS "   + s_sumws
              + " SUMLS "   + s_sumls
              );
        
            ResetLastError();  
            int fhandle=FileOpen(s_filename,FILE_SHARE_READ|FILE_READ|FILE_SHARE_WRITE|FILE_WRITE|FILE_ANSI|FILE_CSV ,';');
            if(fhandle!=INVALID_HANDLE)
            {
                //if( true == FileSeek ( handle, 0, SEEK_END ) ) 
                {
                    //if( true == FileIsEnding( handle ) )
                    {
                        string s_dttl = TimeToString( TimeLocal(), TIME_DATE | TIME_SECONDS );
    
                        // INTERFACE START
                        FileWrite( fhandle,
                            "timelocal", "symbol", "period", "opentime", "fromdate", "todate", "avg_candle_height", "sl_level", "sr_period",
                            "CNT","CNTW","CNTL","CNTB","CNTWB","CNTLB","CNTS","CNTWS","CNTLS",
                            "AVG","AVGW","AVGL","AVGB","AVGWB","AVGLB","AVGS","AVGWS","AVGLS",
                            "PRP","PRPB","PRPS","SETORCALC","AVGCALC","SLCALC","PC","RT",
                            "SUM","SUMW","SUML","SUMB","SUMWB","SUMLB","SUMS","SUMWS","SUMLS"
                            );
                            
                        FileWrite( fhandle,
                            s_dttl, s_symbol, s_period, s_time, s_para_from, s_para_to, s_para_avg, s_para_sl, s_para_sr,
                            s_cnt, s_cntw, s_cntl, s_cntb, s_cntwb, s_cntlb, s_cnts, s_cntws, s_cntls,  
                            s_avg, s_avgw, s_avgl, s_avgb, s_avgwb, s_avglb, s_avgs, s_avgws, s_avgls,
                            s_prp, s_prpb, s_prps, s_set_or_calc, s_avgcalc, s_slcalc, s_pc, s_rt,
                            s_sum, s_sumw, s_suml, s_sumb, s_sumwb, s_sumlb, s_sums, s_sumws, s_sumls
                            );
                        // INTERFACE END
    
                        FileFlush( fhandle );
                    } //if( true == FileIsEnding( handle ) )
                } //if( true == FileSeek ( handle, 0, SEEK_END ) ) 
                FileClose( fhandle);
            }
            else
            {
                Print( " Failed to open file: " + s_filename + " Error: " + its(GetLastError()) );
            } // if(fhandle!=INVALID_HANDLE)
        } // if( false == TESTERMODE )
                  
		
	} // if( prev_calculated == 0 || CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ) == 1 )

	return( rates_total );
} // int OnCalculate(const int rates_total,
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit( const int _reason )
{
	//Comment( "" );
	ObjectsDeleteAll(0, gIndicatorName);
	ChartRedraw( );
}

// TODO duplicate - create indicator library
//---------------------------------------------------------------------
//	its - Integer To String
//---------------------------------------------------------------------
string its( int _int )
{
	return( IntegerToString( _int ) );
}
//---------------------------------------------------------------------

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
int m_IndiGetShiftSinceDayStarted( int shift )
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
    
} // int m_indiGetShiftSinceDayStarted( int shift )
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
double getAvgCandleHeight(const int rates_total, const int start, const int count,const double &High[],const double &Low[])
{
    double sum=0.0;
    int cnt = 0;
    for(int i=0;i<count;i++)
    {
        if( rates_total > (start+i) )
        {
            sum+=High[start+i]-Low[start+i];
            cnt++;
        }
    }
    return sum/cnt;
}
//+------------------------------------------------------------------+

bool TrendCreate(
/*                 const long            chart_ID=0,        // chart's ID 
                 const string          name="TrendLine",  // line name 
                 const int             sub_window=0,      // subwindow index 
                 datetime              time1=0,           // first point time 
                 double                price1=0,          // first point price 
                 datetime              time2=0,           // second point time 
                 double                price2=0,          // second point price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            ray_left=false,    // line's continuation to the left 
                 const bool            ray_right=false,   // line's continuation to the right 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click */
                 const string          name,  // line name 
                 datetime              time1,           // first point time 
                 double                price1,          // first point price 
                 datetime              time2,           // second point time 
                 double                price2,          // second point price 
                 const color           clr        // line color 
            )                 
  { 
                 const long            chart_ID=0;        // chart's ID 
                 const int             sub_window=0;      // subwindow index 
                 const ENUM_LINE_STYLE style=STYLE_SOLID; // line style 
                 const int             width=3;           // line width 
                 const bool            back=false;        // in the background 
                 const bool            selection=false;    // highlight to move 
                 const bool            ray_left=false;    // line's continuation to the left 
                 const bool            ray_right=false;   // line's continuation to the right 
                 const bool            hidden=false;       // hidden in the object list 
                 const long            z_order=0;         // priority for mouse click 
  
  
    return (false);
  
    if( (0==time1) || (0==price1) || (0==time2) || (0==price2) )
    {
        Print( "ERROR TrendCreate: " + IntegerToString(time1) + " " + DoubleToString(price1) + " " + IntegerToString(time2) + " " + DoubleToString(price2) );
        return (false);
    }
     // return(false); 
//--- set anchor points' coordinates if they are not set 
   //ChangeTrendEmptyPoints(time1,price1,time2,price2); 
//--- reset the error value 
   ResetLastError(); 
//--- create a trend line by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a trend line! Error code = ",GetLastError()); 
      return(false); 
     } 
    TextCreate(name,time2,price2,clr);
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left); 
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 

bool TextCreate(
/*
                const long              chart_ID=0,               // chart's ID 
                const string            name="Text",              // object name 
                const int               sub_window=0,             // subwindow index 
                datetime                time=0,                   // anchor point time 
                double                  price=0,                  // anchor point price 
                const string            text="Text",              // the text itself 
                const string            font="Arial",             // font 
                const int               font_size=10,             // font size 
                const color             clr=clrRed,               // color 
                const double            angle=0.0,                // text slope 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type 
                const bool              back=false,               // in the background 
                const bool              selection=false,          // highlight to move 
                const bool              hidden=true,              // hidden in the object list 
                const long              z_order=0                 // priority for mouse click 
*/                
                string            name,              // object name 
                datetime                time,                   // anchor point time 
                double                  price,                   // anchor point price 
                const color             clr               // color 
                )
  { 
                const long              chart_ID=0;               // chart's ID 
                const int               sub_window=0;             // subwindow index 
                const string            font="Arial";             // font 
                const int               font_size=10;             // font size 
                const double            angle=0.0;                // text slope 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER; // anchor type 
                const bool              back=false;               // in the background 
                const bool              selection=false;          // highlight to move 
                const bool              hidden=false;              // hidden in the object list 
                const long              z_order=0;                 // priority for mouse click 
  
//--- set anchor point coordinates if they are not set 
//   ChangeTextEmptyPoint(time,price); 
//--- reset the error value 
   ResetLastError(); 
//--- create Text object 
   name = name + " ";
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create \"Text\" object! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set the text 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,name); 
//--- set text font 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
//--- set font size 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
//--- set the slope angle of the text 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle); 
//--- set anchor type 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
//--- set color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the object by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 

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


//+------------------------------------------------------------------+
//| CheckDatetimeAndSkipSeries()
//+------------------------------------------------------------------+
bool CheckDatetimeAndSkipSeries(datetime a_dt)
{

    MqlDateTime mdt;
    TimeToStruct( a_dt, mdt );
    //
    // skip 24.06.2016 brexit referendum
    //
    //if( ( 2016 == mdt.year ) && ( 24 == mdt.day ) && ( 6 == mdt.mon ) ) 
    //{
    //  return (true);
    //}
    //if( ( 2016 == mdt.year ) && ( 23 == mdt.day ) && ( 6 == mdt.mon ) )
    //{
    //  return (true);
    //}
    
    if( ( 1 > mdt.hour ) || ( 22 < mdt.hour ) )
    {
      return (true);
    }
    

    // 1) if not testermode is set
    // 2) or in testermode, if the user has set set from_to_date    
    if(( false == TESTERMODE ) || ((true==TESTERMODE)&&("DD.MM.YYYY-DD.MM.YYYY" != FROM_TO_DATE)) )
    {
        // Default Setting - normal operation
        // INDICATOR_PERIOD parameter is not set
        // TODO indicator duplicate (minus one year)
        if( (NULL == gFromDateTime) && (NULL == gToDateTime) ) 
        {
            datetime dt2 = iTime(Symbol(),Period(),0);
            MqlDateTime mdt2;
            TimeToStruct( dt2, mdt2 );
            // start from the beginning of the month
            mdt2.day = 1;
            // start from the beginning of the year
            //mdt2.day = 1;
            //mdt2.mon = 1;
            // start from minus one year
            //mdt2.year = mdt2.year-1;
            datetime dtb;
            dtb = StructToTime( mdt2 );
            if( a_dt < dtb )
            {
                return (true);
            }
        }
        else
        {
            if( NULL != gFromDateTime )
            {
                if( a_dt < gFromDateTime )
                {
                    return (true);
                }
            }    
            if( NULL != gToDateTime )
            {
                if( a_dt > gToDateTime )
                {
                    return (true);
                }
            }    
        } // if( (NULL gFromDate) && (NULL == gToDate) ) 
    } // if( false == TESTERMODE )
      
    return (false);      
} // bool CheckDatetimeAndSkipSeries(datetime a_dt)
//+------------------------------------------------------------------+

// TODO duplicate - create indicator library
//+------------------------------------------------------------------+
//| GetFromToDatetimeFromInput()
//+------------------------------------------------------------------+
void GetFromToDatetimeFromInput(const string a_str_from_to_date, datetime& a_from_datetime, datetime& a_to_datetime)
{


    // convert FROM_TO_DATE into gFromDateTime and gToDateTime
    // FROM_TO_DATE  = "DD.MM.YYYY-DD.MM.YYYY";
    //string str_input = FROM_TO_DATE;
    // sanity check
    if( NULL == a_str_from_to_date ) return;
    if( ""   == a_str_from_to_date ) return;
    if( "DD.MM.YYYY-DD.MM.YYYY" == a_str_from_to_date ) return;
        
    string str_arr_split[];                     // An array to get strings
    string s_sep="-";                           // A separator as a character
    //--- Get the separator code
    ushort u_sep=StringGetCharacter(s_sep,0);   // The code of the separator character
    //--- Split the string to substrings
    int num_str_split=StringSplit(a_str_from_to_date,u_sep,str_arr_split);
    if( 2 == num_str_split )
    {
        string str_arr_fromdate[];
        string str_arr_todate[];
        s_sep = ".";
        u_sep = StringGetCharacter(s_sep,0);
        num_str_split=StringSplit(str_arr_split[0],u_sep,str_arr_fromdate);
        if( 3 == num_str_split )
        {
            MqlDateTime mdt;
            mdt.hour=0;
            mdt.min=0;
            mdt.sec=0;
            mdt.day=(int)StringToInteger(str_arr_fromdate[0]);
            mdt.mon=(int)StringToInteger(str_arr_fromdate[1]);
            mdt.year=(int)StringToInteger(str_arr_fromdate[2]);
            a_from_datetime = StructToTime( mdt );
        }
        num_str_split=StringSplit(str_arr_split[1],u_sep,str_arr_todate);
        if( 3 == num_str_split )
        {
            MqlDateTime mdt;
            mdt.hour=0;
            mdt.min=0;
            mdt.sec=0;
            mdt.day=(int)StringToInteger(str_arr_todate[0]);
            mdt.mon=(int)StringToInteger(str_arr_todate[1]);
            mdt.year=(int)StringToInteger(str_arr_todate[2]);
            a_to_datetime = StructToTime( mdt );
        }
        
    }
    
    //Print( "FromTime: " + TimeToString(gFromDateTime) + " ToTime: " + TimeToString(gToDateTime) );
    
} // GetFromToDatetimeFromInput
//+------------------------------------------------------------------+


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
