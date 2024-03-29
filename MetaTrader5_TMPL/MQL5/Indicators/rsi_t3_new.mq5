//=====================================================================
//	CCI MIX indicator.
//=====================================================================
#property copyright		"Andr� Howe"
#property link			"onepmail@gmail.com"
#property version		"001.001"
#property description	"CCI MIX indicator."
//---------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers	5
#property indicator_plots		2
//---------------------------------------------------------------------
#property indicator_label1	   "RSI T3"
#property indicator_type1	   DRAW_COLOR_ARROW
#property indicator_color1	   clrNONE, clrBlue, clrRed, clrLime,clrLightBlue,clrPink
#property indicator_style1	   STYLE_SOLID
#property indicator_width1	   2
//---------------------------------------------------------------------
#property indicator_label2	   "MA"
#property indicator_type2		DRAW_COLOR_ARROW
#property indicator_color2	   clrNONE, clrBlack
#property indicator_style2	   STYLE_SOLID
#property indicator_width2	   1
//=====================================================================
//	External parameters:
//=====================================================================
input int                       RSI_Period = 5;
input ENUM_APPLIED_PRICE        RSI_Price_Type = PRICE_CLOSE;
//---------------------------------------------------------------------

//---------------------------------------------------------------------
double  RSIBuff[ ];
double  MRSIBuff[ ];
double  MRSIColorBuff[ ];
double  MABuff[ ];
double  MAColorBuff[ ];
//---------------------------------------------------------------------

//---------------------------------------------------------------------
int     rsi_handler;
//---------------------------------------------------------------------
int rsi_bars_calculated = 0;
// number of values in the RSI indicator
//---------------------------------------------------------------------



//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int
OnInit( )
{
    Comment( "" );

    SetIndexBuffer( 0, MRSIBuff, INDICATOR_DATA );
    SetIndexBuffer( 1, MRSIColorBuff, INDICATOR_COLOR_INDEX );
    SetIndexBuffer( 2, MABuff, INDICATOR_DATA );
    SetIndexBuffer( 3, MAColorBuff, INDICATOR_COLOR_INDEX );
    SetIndexBuffer( 4, RSIBuff, INDICATOR_CALCULATIONS );

    PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );

    PlotIndexSetInteger(0,PLOT_ARROW,0x6e);
    PlotIndexSetInteger(0,PLOT_LINE_WIDTH,3);

    PlotIndexSetInteger(1,PLOT_ARROW,0x6e);
    PlotIndexSetInteger(1,PLOT_LINE_WIDTH,3);


    IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));
    IndicatorSetString( INDICATOR_SHORTNAME, "RSI T3 new( RSI_Period = " + string( RSI_Period ) + " )" );

    rsi_handler = iRSI( Symbol( ), Period( ), RSI_Period, RSI_Price_Type );
    if( rsi_handler == INVALID_HANDLE )
    {
        Print( "Failed to create the RSI indicator" );
        return( -1 );
    }

    ChartRedraw( );

    return( 0 );
}

//---------------------------------------------------------------------
//  Indicator calculation event handler:
//---------------------------------------------------------------------
int start;
int values_to_copy;
//---------------------------------------------------------------------
int
OnCalculate( const int rates_total,
             const int prev_calculated,
             const datetime& time[ ], 
             const double& open[ ], 
             const double& high[ ], 
             const double& low[ ], 
             const double& close[ ], 
             const long& tick_volume[ ], 
             const long& volume[ ], 
             const int& spread[ ] )
{
    static datetime	last_bar_datetime_chart = 0;
    static bool	error = true;

    if( prev_calculated == 0)
    {
        error = true;
    }
    if( error )
    {
        start = 0;
        error = false;
    }
    else
    {
        start = prev_calculated - 1;
    }

    if( CopyBuffer( rsi_handler, 0, 0, rates_total - start, RSIBuff ) == -1 )
    {
        error = true;
        return( rates_total );
    }

    if( prev_calculated == 0 || CheakNewBar( Symbol( ), Period( ), last_bar_datetime_chart ) == 1 )
    {
        for( int i = start; i < rates_total - 1; i++ )
        {

            MAColorBuff[ i ] = 1;

            if( RSIBuff[ i ] > 55 )
            {
                if( RSIBuff[ i ] > 70 )
                    MRSIColorBuff[ i ] = 1;
                else
                    MRSIColorBuff[ i ] = 4;
            }
            else if( RSIBuff[ i ] < 45 )
            {
                if( RSIBuff[ i ] < 30 )
                    MRSIColorBuff[ i ] = 2;
                else
                    MRSIColorBuff[ i ] = 5;
            }
            else
            {
                MRSIColorBuff[ i ] = 3;
            }
            MRSIBuff[ i ]=50.0;
            MABuff[ i ]=51.0;
        }
        MRSIBuff[ rates_total - 1 ] = 0.0;
        MRSIColorBuff[ rates_total - 1 ] = 0;
        MABuff[ rates_total - 1 ] = MRSIBuff[ rates_total - 1 ];
        MAColorBuff[ rates_total - 1 ] = 0;
    }

    return( rates_total );
}

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit( const int _reason )
{
    if( rsi_handler != INVALID_HANDLE )
    {
        IndicatorRelease( rsi_handler );
    }

    ChartRedraw( );
}

//---------------------------------------------------------------------
//	Returns a sign of appearance of a new bar:
//---------------------------------------------------------------------
int CheakNewBar( string _symbol, ENUM_TIMEFRAMES _period, datetime& _last_dt )
{
    datetime curr_time = ( datetime )SeriesInfoInteger( _symbol, _period, SERIES_LASTBAR_DATE );
    if( curr_time > _last_dt )
    {
        _last_dt = curr_time;
        return( 1 );
    }

    return( 0 );
}
//---------------------------------------------------------------------
