//=====================================================================
//	RSI T3 indicator.
//=====================================================================
#property copyright		"Alextp."
#property link				"atopunov@mail.ru"
#property version			"1.1"
#property description	"RSI T3 Indicator"
//---------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers	5
#property indicator_plots		2
//---------------------------------------------------------------------
#property indicator_label1	   "RSI T3"
#property indicator_type1	   DRAW_COLOR_HISTOGRAM
#property indicator_color1	   clrNONE, clrBlue, clrRed, clrLime
#property indicator_style1	   STYLE_SOLID
#property indicator_width1	   2
//---------------------------------------------------------------------
#property indicator_label2	   "MA"
#property indicator_type2		DRAW_COLOR_LINE
#property indicator_color2	   clrNONE, clrBlack
#property indicator_style2	   STYLE_SOLID
#property indicator_width2	   1
//=====================================================================
//	External parameters:
//=====================================================================
input int									RSI_Period = 14;
input ENUM_APPLIED_PRICE	         RSI_Price_Type = PRICE_TYPICAL;
input int									T3_Period = 5;
input double							   Koeff_B = 0.618;
//---------------------------------------------------------------------

//---------------------------------------------------------------------
double	RSIBuff[ ];
double	MRSIBuff[ ];
double	MRSIColorBuff[ ];
double	MABuff[ ];
double	MAColorBuff[ ];
//---------------------------------------------------------------------

//---------------------------------------------------------------------
int				rsi_handler;
//---------------------------------------------------------------------
int				rsi_bars_calculated = 0;																		// number of values in the RSI indicator
//---------------------------------------------------------------------
double		e1 = 0.0;
double		e2 = 0.0;
double		e3 = 0.0;
double		e4 = 0.0;
double		e5 = 0.0;
double		e6 = 0.0;
double		b2, b3;
double		c1, c2, c3, c4;
double		w1, w2;
int			n;
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
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );

	IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));
	IndicatorSetString( INDICATOR_SHORTNAME, "RSI T3( RSI_Period = " + string( RSI_Period ) + ", T3_Period = " + string( T3_Period ) + " )" );

	rsi_handler = iRSI( Symbol( ), Period( ), RSI_Period, RSI_Price_Type );
	if( rsi_handler == INVALID_HANDLE )
	{
		Print( "Failed to create the RSI indicator" );
		return( -1 );
	}

	b2 = Koeff_B * Koeff_B;
	b3 = b2 * Koeff_B;
	c1 = -b3;
	c2 = ( 3.0 * ( b2 + b3 ));
	c3 = -3.0 * ( 2.0 * b2 + Koeff_B + b3 );
	c4 = ( 1.0 + 3.0 * Koeff_B + b3 + 3.0 * b2 );

	n = T3_Period;
	if( n < 1 )
	{
		n = 1;
	}
	else
	{
		n = ( n + 1 ) / 2;
	}

	w1 = 2.0 / ( n + 1.0 );
	w2 = 1.0 - w1;
	
	ChartRedraw( );

	return( 0 );
}

//---------------------------------------------------------------------
//	Indicator calculation event handler:
//---------------------------------------------------------------------
int				start;
int				values_to_copy;
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
			e1 = w1 * RSIBuff[ i ] + w2 * e1;
			e2 = w1 * e1 + w2 * e2;
			e3 = w1 * e2 + w2 * e3;
			e4 = w1 * e3 + w2 * e4;
			e5 = w1 * e4 + w2 * e5;
			e6 = w1 * e5 + w2 * e6;
			MRSIBuff[ i ] = c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3;

			MABuff[ i ] = MRSIBuff[ i ];
			//MAColorBuff[ i ] = 1;

			if( MRSIBuff[ i ] > 55 )
			{
				MRSIColorBuff[ i ] = 1;
			}
			else if( MRSIBuff[ i ] < 45 )
			{
				MRSIColorBuff[ i ] = 2;
			}
			else
			{
				MRSIColorBuff[ i ] = 3;
			}
		}
		MRSIBuff[ rates_total - 1 ] = 0.0;
		MRSIColorBuff[ rates_total - 1 ] = 0;
		MABuff[ rates_total - 1 ] = MRSIBuff[ rates_total - 1 ];
		//MAColorBuff[ rates_total - 1 ] = 0;
	}

	return( rates_total );
}

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void
OnDeinit( const int _reason )
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
int
CheakNewBar( string _symbol, ENUM_TIMEFRAMES _period, datetime& _last_dt )
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
