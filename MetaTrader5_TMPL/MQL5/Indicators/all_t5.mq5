//=====================================================================
//	T5 indicator.
//=====================================================================
#property copyright     "Copyright 2017, Andre Howe"
#property link          "andrehowe.com"
#property version       "1.1"
#property description   "ALL T5 Indicator"
//---------------------------------------------------------------------
//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 46
#property indicator_plots   46
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
input int                   SR_PERIOD       = 0;      // SR_PERIOD - if NULL calculate shift since day has started
input double                BO_PERCENT1     = 0.01;   // BO_PERCENT1 - breakout percentage
input double                BO_PERCENT2     = 0.02;   // BO_PERCENT2 - breakout percentage
input double                BO_PERCENT3     = 0.03;   // BO_PERCENT3 - breakout percentage

const string gIndicatorName                 = "ALL_T5";
const string gIndicatorToLoadName           = "ALL_T4";

//#include <library.mqh>

//---------------------------------------------------------------------
double	BuyBuff[ ];
double	SellBuff[ ];
double	ValueDateTime[ ];
double	ValueBuffBoMiddle[ ];
double	ValueBuffCmp1Bo[ ];
double	ColorBuffCmp1Bo[ ];
double	ValueBuffCmp2Diff[ ];
double	ColorBuffCmp2Diff[ ];
double	ValueBuffCmp3Int[ ];
double	ColorBuffCmp3Int[ ];

double  M1_DateTime[];
double  M1_BoMiddle1[];
double  M1_BoMiddle2[];
double  M1_BoMiddle3[];
double  M1_Cmp1Bo1[];
double  M1_Cmp1Bo2[];
double  M1_Cmp1Bo3[];
double  M1_Cmp2Diff[];
double  M1_Cmp3Int[];
double  M5_DateTime[];
double  M5_BoMiddle1[];
double  M5_BoMiddle2[];
double  M5_BoMiddle3[];
double  M5_Cmp1Bo1[];
double  M5_Cmp1Bo2[];
double  M5_Cmp1Bo3[];
double  M5_Cmp2Diff[];
double  M5_Cmp3Int[];
double  M15_DateTime[];
double  M15_BoMiddle1[];
double  M15_BoMiddle2[];
double  M15_BoMiddle3[];
double  M15_Cmp1Bo1[];
double  M15_Cmp1Bo2[];
double  M15_Cmp1Bo3[];
double  M15_Cmp2Diff[];
double  M15_Cmp3Int[];
double  H1_DateTime[];
double  H1_BoMiddle1[];
double  H1_BoMiddle2[];
double  H1_BoMiddle3[];
double  H1_Cmp1Bo1[];
double  H1_Cmp1Bo2[];
double  H1_Cmp1Bo3[];
double  H1_Cmp2Diff[];
double  H1_Cmp3Int[];

int     m1_handler;
int     m5_handler;
int     m15_handler;
int     h1_handler;

//---------------------------------------------------------------------


//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int
OnInit( )
{
	Comment( "" );
	Print( "init1");
/*
    //--- set indicator levels
    IndicatorSetInteger(INDICATOR_LEVELS,2); 
    IndicatorSetDouble(INDICATOR_LEVELVALUE,0,-100); 
    IndicatorSetDouble(INDICATOR_LEVELVALUE,1,100); 
    //--- set maximum and minimum for subwindow  
    IndicatorSetDouble(INDICATOR_MINIMUM,-300); 
    IndicatorSetDouble(INDICATOR_MAXIMUM, 300); 
*/
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
    
    PlotIndexSetString (3,PLOT_LABEL,"BO-MIDDLE");     
    PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(3,PLOT_SHOW_DATA,true); 
    SetIndexBuffer(     3, ValueBuffBoMiddle,   INDICATOR_DATA );
    
    PlotIndexSetString (4,PLOT_LABEL,"CMP1-BO");     
    PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_COLOR_LINE); 
    PlotIndexSetInteger(4,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(4,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(4,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(4,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(4,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
   
	SetIndexBuffer(     4, ValueBuffCmp1Bo,     INDICATOR_DATA );
	SetIndexBuffer(     5, ColorBuffCmp1Bo,     INDICATOR_COLOR_INDEX );
	
    PlotIndexSetString (5,PLOT_LABEL,"CMP2-DIFF");     
    PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_COLOR_ARROW ); //_HISTOGRAM); 
    PlotIndexSetInteger(5,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(5,PLOT_LINE_WIDTH,5); 
    PlotIndexSetInteger(5,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(5,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(5,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
	SetIndexBuffer(     6, ValueBuffCmp2Diff,   INDICATOR_DATA );
	SetIndexBuffer(     7, ColorBuffCmp2Diff,   INDICATOR_COLOR_INDEX );
	
    PlotIndexSetString (6,PLOT_LABEL,"CMP3-INT");     
    PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_COLOR_LINE); 
    PlotIndexSetInteger(6,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(6,PLOT_LINE_WIDTH,1); 
    PlotIndexSetInteger(6,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(6,PLOT_COLOR_INDEXES,eClrMax); 
	for( int cnt = eClrNone; cnt < eClrMax; cnt++ )
        PlotIndexSetInteger(6,PLOT_LINE_COLOR, cnt,  gColours[cnt] );  	
	SetIndexBuffer(     8, ValueBuffCmp3Int,    INDICATOR_DATA );
	SetIndexBuffer(     9, ColorBuffCmp3Int,    INDICATOR_COLOR_INDEX );
	
    //
    // period M1
    //	
    PlotIndexSetString (7,PLOT_LABEL,"M1-DATETIME");     
    PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(7,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     10, M1_DateTime,        INDICATOR_DATA );
	
    PlotIndexSetString (8,PLOT_LABEL,"M1-BO-MID-" + string( BO_PERCENT1 ) );     
    PlotIndexSetInteger(8,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(8,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     11, M1_BoMiddle1,        INDICATOR_DATA );

    PlotIndexSetString (9,PLOT_LABEL,"M1-BO-MID-" + string( BO_PERCENT2 ) );     
    PlotIndexSetInteger(9,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(9,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     12, M1_BoMiddle2,        INDICATOR_DATA );

    PlotIndexSetString (10,PLOT_LABEL,"M1-BO-MID-" + string( BO_PERCENT3 ) );     
    PlotIndexSetInteger(10,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(10,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     13, M1_BoMiddle3,        INDICATOR_DATA );
	
    PlotIndexSetString (11,PLOT_LABEL,"M1-CMP1-BO-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(11,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(11,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     14, M1_Cmp1Bo1,          INDICATOR_DATA );

    PlotIndexSetString (12,PLOT_LABEL,"M1-CMP1-BO-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(12,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(12,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     15, M1_Cmp1Bo2,          INDICATOR_DATA );

    PlotIndexSetString (13,PLOT_LABEL,"M1-CMP1-BO-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(13,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(13,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     16, M1_Cmp1Bo3,          INDICATOR_DATA );
	
    PlotIndexSetString (14,PLOT_LABEL,"M1-CMP2-DIFF");     
    PlotIndexSetInteger(14,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(14,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     17, M1_Cmp2Diff,        INDICATOR_DATA );
	
    PlotIndexSetString (15,PLOT_LABEL,"M1-CMP3-INT");     
    PlotIndexSetInteger(15,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(15,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     18, M1_Cmp3Int,         INDICATOR_DATA );
	
    PlotIndexSetString (16,PLOT_LABEL,"M5-DATETIME");     
    PlotIndexSetInteger(16,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(16,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     19, M5_DateTime,        INDICATOR_DATA );

    PlotIndexSetString (17,PLOT_LABEL,"M5-BO-MID-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(17,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(17,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     20, M5_BoMiddle1,        INDICATOR_DATA );

    PlotIndexSetString (18,PLOT_LABEL,"M5-BO-MID-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(18,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(18,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     21, M5_BoMiddle2,        INDICATOR_DATA );
	
    PlotIndexSetString (19,PLOT_LABEL,"M5-BO-MID-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(19,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(19,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     22, M5_BoMiddle3,        INDICATOR_DATA );
	
    PlotIndexSetString (20,PLOT_LABEL,"M5-CMP1-BO-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(20,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(20,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     23, M5_Cmp1Bo1,          INDICATOR_DATA );

    PlotIndexSetString (21,PLOT_LABEL,"M5-CMP1-BO-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(21,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(21,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     24, M5_Cmp1Bo2,          INDICATOR_DATA );

    PlotIndexSetString (22,PLOT_LABEL,"M5-CMP1-BO-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(22,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(22,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     25, M5_Cmp1Bo3,          INDICATOR_DATA );
	
    PlotIndexSetString (23,PLOT_LABEL,"M5-CMP2-DIFF");     
    PlotIndexSetInteger(23,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(23,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     26, M5_Cmp2Diff,        INDICATOR_DATA );
	
    PlotIndexSetString (24,PLOT_LABEL,"M5-CMP3-INT");     
    PlotIndexSetInteger(24,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(24,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     27, M5_Cmp3Int,         INDICATOR_DATA );
	
    PlotIndexSetString (25,PLOT_LABEL,"M15-DATETIME");     
    PlotIndexSetInteger(25,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(25,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     28, M15_DateTime,       INDICATOR_DATA );
	
    PlotIndexSetString (26,PLOT_LABEL,"M15-BO-MID-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(26,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(26,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     29, M15_BoMiddle1,       INDICATOR_DATA );
	
    PlotIndexSetString (27,PLOT_LABEL,"M15-BO-MID-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(27,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(27,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     30, M15_BoMiddle2,       INDICATOR_DATA );
	
    PlotIndexSetString (28,PLOT_LABEL,"M15-BO-MID-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(28,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(28,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     31, M15_BoMiddle3,       INDICATOR_DATA );
	
    PlotIndexSetString (29,PLOT_LABEL,"M15-CMP1-BO-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(29,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(29,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     32, M15_Cmp1Bo1,         INDICATOR_DATA );

    PlotIndexSetString (30,PLOT_LABEL,"M15-CMP1-BO-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(30,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(30,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     33, M15_Cmp1Bo2,         INDICATOR_DATA );
	
    PlotIndexSetString (31,PLOT_LABEL,"M15-CMP1-BO-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(31,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(31,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     34, M15_Cmp1Bo3,         INDICATOR_DATA );
	
    PlotIndexSetString (32,PLOT_LABEL,"M15-CMP2-DIFF");     
    PlotIndexSetInteger(32,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(32,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     35, M15_Cmp2Diff,       INDICATOR_DATA );
	
    PlotIndexSetString (33,PLOT_LABEL,"M15-CMP3-INT");     
    PlotIndexSetInteger(33,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(33,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     36, M15_Cmp3Int,        INDICATOR_DATA );
	
    PlotIndexSetString (34,PLOT_LABEL,"H1-DATETIME");     
    PlotIndexSetInteger(34,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(34,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     37, H1_DateTime,        INDICATOR_DATA );
	
	
    PlotIndexSetString (35,PLOT_LABEL,"H1-BO-MID-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(35,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(35,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     38, H1_BoMiddle1,        INDICATOR_DATA );
	
    PlotIndexSetString (36,PLOT_LABEL,"H1-BO-MID-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(36,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(36,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     39, H1_BoMiddle2,        INDICATOR_DATA );
	
    PlotIndexSetString (37,PLOT_LABEL,"H1-BO-MID-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(37,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(37,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     40, H1_BoMiddle3,        INDICATOR_DATA );
	
	
    PlotIndexSetString (38,PLOT_LABEL,"H1-CMP1-BO-" + string( BO_PERCENT1 ));     
    PlotIndexSetInteger(38,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(38,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     41, H1_Cmp1Bo1,          INDICATOR_DATA );
	
    PlotIndexSetString (39,PLOT_LABEL,"H1-CMP1-BO-" + string( BO_PERCENT2 ));     
    PlotIndexSetInteger(39,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(39,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     42, H1_Cmp1Bo2,          INDICATOR_DATA );
	
    PlotIndexSetString (40,PLOT_LABEL,"H1-CMP1-BO-" + string( BO_PERCENT3 ));     
    PlotIndexSetInteger(40,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(40,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     43, H1_Cmp1Bo3,          INDICATOR_DATA );
	
	
    PlotIndexSetString (41,PLOT_LABEL,"H1-CMP2-DIFF");     
    PlotIndexSetInteger(41,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(41,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     44, H1_Cmp2Diff,        INDICATOR_DATA );
	
    PlotIndexSetString (42,PLOT_LABEL,"H1-CMP3-INT");     
    PlotIndexSetInteger(42,PLOT_DRAW_TYPE,DRAW_NONE); 
    PlotIndexSetInteger(42,PLOT_SHOW_DATA,true); 
	SetIndexBuffer(     45, H1_Cmp3Int,         INDICATOR_DATA );


    ArraySetAsSeries( BuyBuff,              true );
    ArraySetAsSeries( SellBuff,             true );
    ArraySetAsSeries( ValueDateTime,        true );
    ArraySetAsSeries( ValueBuffBoMiddle,    true );
    ArraySetAsSeries( ValueBuffCmp1Bo,      true );
    ArraySetAsSeries( ColorBuffCmp1Bo,      true );
    ArraySetAsSeries( ValueBuffCmp2Diff,    true );
    ArraySetAsSeries( ColorBuffCmp2Diff,    true );
    ArraySetAsSeries( ValueBuffCmp3Int,     true );
    ArraySetAsSeries( ColorBuffCmp3Int,     true );
    ArraySetAsSeries( M1_DateTime,          true );
    ArraySetAsSeries( M1_BoMiddle1,         true );
    ArraySetAsSeries( M1_BoMiddle2,         true );
    ArraySetAsSeries( M1_BoMiddle3,         true );
    ArraySetAsSeries( M1_Cmp1Bo1,           true );
    ArraySetAsSeries( M1_Cmp1Bo2,           true );
    ArraySetAsSeries( M1_Cmp1Bo3,           true );
    ArraySetAsSeries( M1_Cmp2Diff,          true );
    ArraySetAsSeries( M1_Cmp3Int,           true );
    ArraySetAsSeries( M5_DateTime,          true );
    ArraySetAsSeries( M5_BoMiddle1,         true );
    ArraySetAsSeries( M5_BoMiddle2,         true );
    ArraySetAsSeries( M5_BoMiddle3,         true );
    ArraySetAsSeries( M5_Cmp1Bo1,           true );
    ArraySetAsSeries( M5_Cmp1Bo2,           true );
    ArraySetAsSeries( M5_Cmp1Bo3,           true );
    ArraySetAsSeries( M5_Cmp2Diff,          true );
    ArraySetAsSeries( M5_Cmp3Int,           true );
    ArraySetAsSeries( M15_DateTime,         true );
    ArraySetAsSeries( M15_BoMiddle1,         true );
    ArraySetAsSeries( M15_BoMiddle2,         true );
    ArraySetAsSeries( M15_BoMiddle3,         true );
    ArraySetAsSeries( M15_Cmp1Bo1,           true );
    ArraySetAsSeries( M15_Cmp1Bo2,           true );
    ArraySetAsSeries( M15_Cmp1Bo3,           true );
    ArraySetAsSeries( M15_Cmp2Diff,         true );
    ArraySetAsSeries( M15_Cmp3Int,          true );
    ArraySetAsSeries( H1_DateTime,          true );
    ArraySetAsSeries( H1_BoMiddle1,          true );
    ArraySetAsSeries( H1_BoMiddle2,          true );
    ArraySetAsSeries( H1_BoMiddle3,          true );
    ArraySetAsSeries( H1_Cmp1Bo1,            true );
    ArraySetAsSeries( H1_Cmp1Bo2,            true );
    ArraySetAsSeries( H1_Cmp1Bo3,            true );
    ArraySetAsSeries( H1_Cmp2Diff,          true );
    ArraySetAsSeries( H1_Cmp3Int,           true );

	/*PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 3, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 5, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 6, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 7, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 8, PLOT_EMPTY_VALUE, 0.0 );*/

	IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));
	IndicatorSetString( INDICATOR_SHORTNAME, gIndicatorName + " ( " + string( FROM_TO_DATE ) + " / " + string( SR_PERIOD ) + " / " + string( BO_PERCENT1 ) + " / " + string( BO_PERCENT2 )+ " / " + string( BO_PERCENT3 )+ " ) " );

    //s.g_sr_handler = iCustom( s.SYMBOL, s.PERIOD, "all_t5", FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2,BO_PERCENT3 );
    //       handler = iCustom( Symbol(), Period(), "all_t5", "DD.MM.YYYY-DD.MM.YYYY",0,0.1,0.2,0.3 );
	
	m1_handler = iCustom( Symbol(), PERIOD_M1, gIndicatorToLoadName, 
	                        FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2,BO_PERCENT3 );
	if( m1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the period M1 indicator: " + gIndicatorToLoadName);
		return( -1 );
	}
	
	m5_handler = iCustom( Symbol(), PERIOD_M5, gIndicatorToLoadName, 
	                        FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2,BO_PERCENT3 );
	if( m5_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the period M5 indicator: " + gIndicatorToLoadName);
		return( -1 );
	}
	
	m15_handler = iCustom( Symbol(), PERIOD_M15, gIndicatorToLoadName,
	                        FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2,BO_PERCENT3 );
	if( m15_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the period M15 indicator: " + gIndicatorToLoadName);
		return( -1 );
	}
	
	h1_handler = iCustom( Symbol(), PERIOD_H1, gIndicatorToLoadName,
	                        FROM_TO_DATE,SR_PERIOD,BO_PERCENT1,BO_PERCENT2,BO_PERCENT3 );
	if( h1_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the period H1 indicator: " + gIndicatorToLoadName);
		return( -1 );
	}
	
	ChartRedraw( );
	
	Print( "init2");

	return( 0 );
}

//---------------------------------------------------------------------
//	Indicator calculation event handler:
//---------------------------------------------------------------------
//---------------------------------------------------------------------
int OnCalculate(const int       rates_total,
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
	static int upcnt = 0;
	static int dncnt = 0;

	int cnt_super_lock = 0;
	int cnt_match_lock = 0;
	
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
    // TODO fixme - currently for testing only
    start = 4*5*24*60; 
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

    // copy values for period M1    
	if( CopyBuffer( m1_handler, 2, 0, rates_total - 1, M1_DateTime ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 3, 0, rates_total - 1, M1_BoMiddle1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 4, 0, rates_total - 1, M1_BoMiddle2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 5, 0, rates_total - 1, M1_BoMiddle3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 6, 0, rates_total - 1, M1_Cmp1Bo1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 8, 0, rates_total - 1, M1_Cmp1Bo2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 10, 0, rates_total - 1, M1_Cmp1Bo3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 12, 0, rates_total - 1, M1_Cmp2Diff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m1_handler, 14, 0, rates_total - 1, M1_Cmp3Int ) == -1 )
	{
		return( rates_total );
	}

    // copy values for period M5    
	if( CopyBuffer( m5_handler, 2, 0, rates_total - 1, M5_DateTime ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 3, 0, rates_total - 1, M5_BoMiddle1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 4, 0, rates_total - 1, M5_BoMiddle2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 5, 0, rates_total - 1, M5_BoMiddle3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 6, 0, rates_total - 1, M5_Cmp1Bo1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 8, 0, rates_total - 1, M5_Cmp1Bo2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 10, 0, rates_total - 1, M5_Cmp1Bo3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 12, 0, rates_total - 1, M5_Cmp2Diff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m5_handler, 14, 0, rates_total - 1, M5_Cmp3Int ) == -1 )
	{
		return( rates_total );
	}

    // copy values for period M15    
	if( CopyBuffer( m15_handler, 2, 0, rates_total - 1, M15_DateTime ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 3, 0, rates_total - 1, M15_BoMiddle1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 4, 0, rates_total - 1, M15_BoMiddle2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 5, 0, rates_total - 1, M15_BoMiddle3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 6, 0, rates_total - 1, M15_Cmp1Bo1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 8, 0, rates_total - 1, M15_Cmp1Bo2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 10, 0, rates_total - 1, M15_Cmp1Bo3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 12, 0, rates_total - 1, M15_Cmp2Diff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( m15_handler, 14, 0, rates_total - 1, M15_Cmp3Int ) == -1 )
	{
		return( rates_total );
	}

    // copy values for period H1    
	if( CopyBuffer( h1_handler, 2, 0, rates_total - 1, H1_DateTime ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 3, 0, rates_total - 1, H1_BoMiddle1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 4, 0, rates_total - 1, H1_BoMiddle2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 5, 0, rates_total - 1, H1_BoMiddle3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 6, 0, rates_total - 1, H1_Cmp1Bo1 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 8, 0, rates_total - 1, H1_Cmp1Bo2 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 10, 0, rates_total - 1, H1_Cmp1Bo3 ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 12, 0, rates_total - 1, H1_Cmp2Diff ) == -1 )
	{
		return( rates_total );
	}
	if( CopyBuffer( h1_handler, 14, 0, rates_total - 1, H1_Cmp3Int ) == -1 )
	{
		return( rates_total );
	}


    //Print( " start: " + IntegerToString(start ) + " prev_calculated: " + IntegerToString(prev_calculated )  + " rates_total: " + IntegerToString(rates_total ));

    if( (0 == prev_calculated) || ((1==CheckNewBar( Symbol( ), Period( ), last_bar_datetime_chart ))&&(0<start)) )
    {
    
        for( int i = start-12; i > 0; i-- )
        {
            
            /*
            BuyBuff[i]          = 0.0;
            SellBuff[i]         = 0.0;
            ValueDateTime[i]    = 0.0;
            ValueBuffBoMiddle[i]= 0.0;
            ValueBuffCmp1Bo[i]  = 0.0;
            ColorBuffCmp1Bo[i]  = 0.0;
            ValueBuffCmp2Diff[i]= 0.0;
            ColorBuffCmp2Diff[i]= 0.0;
            ValueBuffCmp3Int[i] = 0.0;
            ColorBuffCmp3Int[i] = 0.0;
            
            M1_DateTime[i]      = 0.0;
            M1_BoMiddle1[i]     = 0.0;
            M1_BoMiddle2[i]     = 0.0;
            M1_BoMiddle3[i]     = 0.0;
            M1_Cmp1Bo1[i]       = 0.0;
            M1_Cmp1Bo2[i]       = 0.0;
            M1_Cmp1Bo3[i]       = 0.0;
            M1_Cmp2Diff[i]      = 0.0;
            M1_Cmp3Int[i]       = 0.0;
            M5_DateTime[i]      = 0.0;
            M5_BoMiddle1[i]     = 0.0;
            M5_BoMiddle2[i]     = 0.0;
            M5_BoMiddle3[i]     = 0.0;
            M5_Cmp1Bo1[i]       = 0.0;
            M5_Cmp1Bo2[i]       = 0.0;
            M5_Cmp1Bo3[i]       = 0.0;
            M5_Cmp2Diff[i]      = 0.0;
            M5_Cmp3Int[i]       = 0.0;
            M15_DateTime[i]     = 0.0;
            M15_BoMiddle1[i]    = 0.0;
            M15_BoMiddle2[i]    = 0.0;
            M15_BoMiddle3[i]    = 0.0;
            M15_Cmp1Bo1[i]      = 0.0;
            M15_Cmp1Bo2[i]      = 0.0;
            M15_Cmp1Bo3[i]      = 0.0;
            M15_Cmp2Diff[i]     = 0.0;
            M15_Cmp3Int[i]      = 0.0;
            H1_DateTime[i]      = 0.0;
            H1_BoMiddle1[i]     = 0.0;
            H1_BoMiddle2[i]     = 0.0;
            H1_BoMiddle3[i]     = 0.0;
            H1_Cmp1Bo1[i]       = 0.0;
            H1_Cmp1Bo2[i]       = 0.0;
            H1_Cmp1Bo3[i]       = 0.0;
            H1_Cmp2Diff[i]      = 0.0;
            H1_Cmp3Int[i]       = 0.0;
            */
            
            int atrx_period     = SR_PERIOD;
            double atrx = 0;
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
                atrx = (max-min)/Point();
            }
            if( 1 == i ) Comment(IntegerToString(atrx_period));
            
            
            datetime dtM1  = (datetime)M1_DateTime[i];            
            datetime dtM5  = (datetime)M5_DateTime[i];            
            datetime dtM15 = (datetime)M15_DateTime[i];            
            datetime dtH1  = (datetime)H1_DateTime[i]; 
            MqlDateTime tmM1; 
            TimeToStruct( dtM1, tmM1 );
            MqlDateTime tmM5; 
            TimeToStruct( dtM5, tmM5 );
            MqlDateTime tmM15; 
            TimeToStruct( dtM15, tmM15 );
            MqlDateTime tmH1; 
            TimeToStruct( dtH1, tmH1 );
            

            if( (tmM1.min == 0) || (tmM1.min == 15) || (tmM1.min == 30) || (tmM1.min == 45) )
            {
                int M1_index  = i;
                int M5_index  = i;
                int M15_index = i;
                int H1_index  = i;
                
                // M5_index
                for( ; M5_index>=0; M5_index--)
                {
                    if( dtM1 == (datetime)M5_DateTime[M5_index] )
                    {
                        break;
                    } 
                } // for( ; M5_index>=0; M5_index--)

                // M15_index
                for( ; M15_index>=0; M15_index--)
                {
                    if( dtM1 == (datetime)M15_DateTime[M15_index] )
                    {
                        break;
                    } 
                } // for( ; M15_index>=0; M15_index--)

                // H1_index
                tmM1.min = 0;
                datetime dt = StructToTime( tmM1 );
                for( ; H1_index>=0; H1_index--)
                {
                    if( dt == (datetime)H1_DateTime[H1_index] )
                    {
                        break;
                    } 
                } // for( ; H1_index>=0; H1_index--)

                for( int cnt = M1_index; (cnt >M1_index-15) && ( cnt ); cnt-- )
                {
                    // decrease 5 minutes later
                    if( (cnt == (M1_index - 5)) )
                    {
                        if( M5_index )
                            M5_index--;
                        
                    }
                    // decrease 10 minutes later
                    if( (cnt == (M1_index - 10)) )
                    {
                        if( M5_index )
                            M5_index--;
                        
                    }
                    bool bMatchM1 = false;
                    bool bMatchM5 = false;
                    bool bMatchM15= false;
                    bool bMatchH1 = false;
                    string bStrM1 = " ";
                    string bStrM5 = " ";
                    string bStrM15= " ";
                    string bStrH1 = " ";
                    
//
//  start comment bo/diff/bo comparison
//                    
/*

                    // match PERIOD_M1
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( M1_Cmp2Diff[cnt] < M1_Cmp3Int[cnt] ) 
                        && ( M1_Cmp2Diff[cnt] > M1_Cmp1Bo1[cnt]  ) 
            
                        // check that values are positive            
                        && ( 0 < M1_Cmp1Bo1[cnt] )
                        && ( 0 < M1_Cmp2Diff[cnt] )
                        && ( 0 < M1_Cmp3Int[cnt] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is above the BO-MIDDLE line
                        //&& ( Close[i] > ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchM1 = true;
                        bStrM1   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( M1_Cmp2Diff[cnt] > M1_Cmp3Int[cnt] ) 
                        && ( M1_Cmp2Diff[cnt] < M1_Cmp1Bo1[cnt] ) 
                        
                        // check that values are negative            
                        && ( 0 > M1_Cmp1Bo1[cnt] )
                        && ( 0 > M1_Cmp2Diff[cnt] )
                        && ( 0 > M1_Cmp3Int[cnt] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is below the BO-MIDDLE line
                        //&& ( Close[i] < ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchM1 = true;
                        bStrM1   = "S";
                    }  // match PERIOD_M1

                    
                    // match PERIOD_M5
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( M5_Cmp2Diff[M5_index] < M5_Cmp3Int[M5_index] ) 
                        && ( M5_Cmp2Diff[M5_index] > M5_Cmp1Bo1[M5_index]  ) 
            
                        // check that values are positive            
                        && ( 0 < M5_Cmp1Bo1[M5_index] )
                        && ( 0 < M5_Cmp2Diff[M5_index] )
                        && ( 0 < M5_Cmp3Int[M5_index] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is above the BO-MIDDLE line
                        //&& ( Close[i] > ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchM5 = true;
                        bStrM5   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( M5_Cmp2Diff[M5_index] > M5_Cmp3Int[M5_index] ) 
                        && ( M5_Cmp2Diff[M5_index] < M5_Cmp1Bo1[M5_index] ) 
                        
                        // check that values are negative            
                        && ( 0 > M5_Cmp1Bo1[M5_index] )
                        && ( 0 > M5_Cmp2Diff[M5_index] )
                        && ( 0 > M5_Cmp3Int[M5_index] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is below the BO-MIDDLE line
                        //&& ( Close[i] < ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchM5 = true;
                        bStrM5   = "S";
                    }  // match PERIOD_M5  

                    
                    // match PERIOD_M15
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( M15_Cmp2Diff[M15_index] < M15_Cmp3Int[M15_index] ) 
                        && ( M15_Cmp2Diff[M15_index] > M15_Cmp1Bo1[M15_index]  ) 
            
                        // check that values are positive            
                        && ( 0 < M15_Cmp1Bo1[M15_index] )
                        && ( 0 < M15_Cmp2Diff[M15_index] )
                        && ( 0 < M15_Cmp3Int[M15_index] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is above the BO-MIDDLE line
                        //&& ( Close[i] > ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchM15 = true;
                        bStrM15   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( M15_Cmp2Diff[M15_index] > M15_Cmp3Int[M15_index] ) 
                        && ( M15_Cmp2Diff[M15_index] < M15_Cmp1Bo1[M15_index] ) 
                        
                        // check that values are negative            
                        && ( 0 > M15_Cmp1Bo1[M15_index] )
                        && ( 0 > M15_Cmp2Diff[M15_index] )
                        && ( 0 > M15_Cmp3Int[M15_index] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is below the BO-MIDDLE line
                        //&& ( Close[i] < ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchM15 = true;
                        bStrM15   = "S";
                    }   // match PERIOD_M15 
                    
                   
                    // match PERIOD_H1
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( H1_Cmp2Diff[H1_index] < H1_Cmp3Int[H1_index] ) 
                        && ( H1_Cmp2Diff[H1_index] > H1_Cmp1Bo1[H1_index]  ) 
            
                        // check that values are positive            
                        && ( 0 < H1_Cmp1Bo1[H1_index] )
                        && ( 0 < H1_Cmp2Diff[H1_index] )
                        && ( 0 < H1_Cmp3Int[H1_index] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is above the BO-MIDDLE line
                        //&& ( Close[i] > ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchH1 = true;
                        bStrH1   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( H1_Cmp2Diff[H1_index] > H1_Cmp3Int[H1_index] ) 
                        && ( H1_Cmp2Diff[H1_index] < H1_Cmp1Bo1[H1_index] ) 
                        
                        // check that values are negative            
                        && ( 0 > H1_Cmp1Bo1[H1_index] )
                        && ( 0 > H1_Cmp2Diff[H1_index] )
                        && ( 0 > H1_Cmp3Int[H1_index] )
                        
                        // TODO do we need this info, if yes then we need to retrieve it
                        //// check that close is below the BO-MIDDLE line
                        //&& ( Close[i] < ValueBuffBoMiddle[i] )
                    
                    )
                    {
                        bMatchH1 = true;
                        bStrH1   = "S";
                    }   // match PERIOD_H1 

*/                    
//
//  end comment bo/diff/bo comparison
//                    



                    // match PERIOD_M1
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( M1_BoMiddle1[cnt]   > M1_BoMiddle2[cnt] ) 
                        && ( M1_BoMiddle1[cnt+1] < M1_BoMiddle2[cnt+1]  ) 
                    
                    )
                    {
                        bMatchM1 = true;
                        bStrM1   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( M1_BoMiddle1[cnt]   < M1_BoMiddle2[cnt] ) 
                        && ( M1_BoMiddle1[cnt+1] > M1_BoMiddle2[cnt+1] ) 
                        
                    )
                    {
                        bMatchM1 = true;
                        bStrM1   = "S";
                    }  // match PERIOD_M1

                    
                    // match PERIOD_M5
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( M5_BoMiddle1[M5_index]   > M5_BoMiddle2[M5_index] ) 
                        && ( M5_BoMiddle1[M5_index+1] < M5_BoMiddle2[M5_index+1]  ) 
            
                    )
                    {
                        bMatchM5 = true;
                        bStrM5   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( M5_BoMiddle1[M5_index]   < M5_BoMiddle2[M5_index] ) 
                        && ( M5_BoMiddle1[M5_index+1] > M5_BoMiddle2[M5_index+1] ) 
                        
                    )
                    {
                        bMatchM5 = true;
                        bStrM5   = "S";
                    }  // match PERIOD_M5  

                    
                    // match PERIOD_M15
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( M15_BoMiddle1[M15_index]   > M15_BoMiddle2[M15_index] ) 
                        && ( M15_BoMiddle1[M15_index+1] < M15_BoMiddle2[M15_index+1]  ) 
            
                    )
                    {
                        bMatchM15 = true;
                        bStrM15   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( M15_BoMiddle1[M15_index]   < M15_BoMiddle2[M15_index] ) 
                        && ( M15_BoMiddle1[M15_index+1] > M15_BoMiddle2[M15_index+1] ) 
                        
                    )
                    {
                        bMatchM15 = true;
                        bStrM15   = "S";
                    }   // match PERIOD_M15 
                    
                   
                    // match PERIOD_H1
                    if
                    (   
                        // check that values are in order CMP1-BO < CMP2-DIFF < CMP3-INT
                           ( H1_BoMiddle1[H1_index]   > H1_BoMiddle2[H1_index] ) 
                        && ( H1_BoMiddle1[H1_index+1] < H1_BoMiddle2[H1_index+1]  ) 
            
                    )
                    {
                        bMatchH1 = true;
                        bStrH1   = "B";
                    }
                    else 
                    if
                    (   
                        // check that values are in order CMP1-BO > CMP2-DIFF > CMP3-INT
                           ( H1_BoMiddle1[H1_index]   < H1_BoMiddle2[H1_index] ) 
                        && ( H1_BoMiddle1[H1_index+1] > H1_BoMiddle2[H1_index+1] ) 
                        
                    )
                    {
                        bMatchH1 = true;
                        bStrH1   = "S";
                    }   // match PERIOD_H1 



                    ValueBuffCmp1Bo [cnt] = M1_BoMiddle1[cnt];
                    ColorBuffCmp1Bo [cnt] = eClrRed5;
                    ValueBuffCmp3Int[cnt] = M1_BoMiddle3[cnt];
                    ColorBuffCmp3Int[cnt] = eClrBlue5;

                    // TODO automate the switch between the different periods 
                    //ValueBuffCmp1Bo[H1_index] = H1_BoMiddle1[H1_index];
                    //ColorBuffCmp1Bo[H1_index] = eClrRed5;
                    //ValueBuffCmp3Int[H1_index] = H1_BoMiddle3[H1_index];
                    //ColorBuffCmp3Int[H1_index] = eClrBlue5;
                    
                    if( /*(0 < atrx ) &&*/ ((true == bMatchM1) || (true == bMatchM5) || (true == bMatchM15)) )
                    {
                    
                        if( bMatchM1 )
                        //if( bMatchM5 )
                        //if( bMatchM15)
                        //if( bMatchH1 )
                        //if( bMatchM1 && bMatchM5 )
                        //if( bMatchM1 && bMatchM15 )
                        //if( bMatchM5 && bMatchM15 )
                        //if( bMatchM15 && bMatchH1 )
                        //if( bMatchM1 && bMatchM5 && bMatchM15  )
                        //if( bMatchM1 && bMatchM5 && bMatchM15 && bMatchH1 )
                        {
                            // seperate window
                            //ValueBuffCmp2Diff[cnt] = M1_Cmp2Diff[cnt];
                            // main chart window
                            
                            ValueBuffCmp2Diff[cnt] = Close[cnt];
                            if( 0 < M1_Cmp2Diff[cnt] )
                                ColorBuffCmp2Diff[cnt] = eClrBlue5;
                            else
                                ColorBuffCmp2Diff[cnt] = eClrRed5;
                            
                            // TODO automate the switch between the different periods 
                            //ValueBuffCmp2Diff[H1_index] = Close[H1_index];
                            //if( 0 < H1_Cmp2Diff[H1_index] )
                            //    ColorBuffCmp2Diff[H1_index] = eClrBlue5;
                            //else
                            //    ColorBuffCmp2Diff[H1_index] = eClrRed5;
                                
                            if( bMatchH1 )
                            {
                                cnt_super_lock++;
                                string str1 = StringFormat( "%s SUPER-LOCK-%s #%03d @ %s @ %s",
                                        Symbol(), bStrM1, cnt_super_lock, TimeToString((datetime)M1_DateTime[cnt], TIME_DATE|TIME_MINUTES), DoubleToString(Close[cnt],Digits()) );
                                Print( str1 );
                            }
                            else
                            {
                                cnt_match_lock++;
                                string str2 = StringFormat( "%s MATCH-LOCK-%s #%03d @ %s @ %s",
                                        Symbol(), bStrM1, cnt_match_lock, TimeToString((datetime)M1_DateTime[cnt], TIME_DATE|TIME_MINUTES), DoubleToString(Close[cnt],Digits()) );
                                Print( str2 );
                            }
                        }
                        
                        /*string str1 = StringFormat( "  M1:%03d/%s/%s      M5:%03d/%s/%s      M15:%03d/%s/%s      H1:%03d/%s/%s", 
                                    cnt,      TimeToString((datetime)M1_DateTime[cnt],          TIME_MINUTES), bStrM1,
                                    M5_index, TimeToString((datetime)M5_DateTime[M5_index],     TIME_MINUTES), bStrM5,
                                    M15_index,TimeToString((datetime)M15_DateTime[M15_index],   TIME_MINUTES), bStrM15,
                                    H1_index, TimeToString((datetime)H1_DateTime[H1_index],     TIME_DATE|TIME_MINUTES), bStrH1 );
                        Print( str1 );
                        string str2 = StringFormat( "     %+04d/%+04d/%+04d      %+04d/%+04d/%+04d       %+04d/%+04d/%+04d      %+04d/%+04d/%+04d", 
                                    (int)M1_Cmp1Bo1[cnt],        (int)M1_Cmp2Diff[cnt],        (int)M1_Cmp3Int[cnt],
                                    (int)M5_Cmp1Bo1[M5_index],   (int)M5_Cmp2Diff[M5_index],   (int)M5_Cmp3Int[M5_index],
                                    (int)M15_Cmp1Bo1[M15_index], (int)M15_Cmp2Diff[M15_index], (int)M15_Cmp3Int[M15_index],
                                    (int)H1_Cmp1Bo1[H1_index],   (int)H1_Cmp2Diff[H1_index],   (int)H1_Cmp3Int[H1_index] );
                        Print( str2 );*/
                        
                    }
                }
                
            } // if( (tmM1.min == 0) || (tmM1.min == 15) || (tmM1.min == 30) || (tmM1.min == 45) )


               
            
			
        } // for( int i = start; i < rates_total - 1; i++ )

    } // if( prev_calculated == 0 || CheakNewBar( Symbol( ), Period( ), last_bar_datetime_chart ) == 1 )

	return( rates_total );
}

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit( const int _reason )
{
	if( m1_handler != INVALID_HANDLE )
	{
		IndicatorRelease( m1_handler );
	}
	if( m5_handler != INVALID_HANDLE )
	{
		IndicatorRelease( m5_handler );
	}
	if( m15_handler != INVALID_HANDLE )
	{
		IndicatorRelease( m15_handler );
	}
	if( h1_handler != INVALID_HANDLE )
	{
		IndicatorRelease( h1_handler );
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

