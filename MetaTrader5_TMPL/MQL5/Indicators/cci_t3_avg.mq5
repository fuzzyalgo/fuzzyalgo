//=====================================================================
//	CCI T3 AVG indicator.
//=====================================================================
#property copyright     "Copyright 2022, André Howe"
#property link          "andrehowe.com"
#property version       "1.1"
#property description	"CCI T3 AVG Indicator"
//---------------------------------------------------------------------
#property indicator_separate_window
//#property indicator_chart_window
#property indicator_buffers	    8
#property indicator_plots		2
//---------------------------------------------------------------------
#property indicator_label1	   "CCI T3"
#property indicator_type1		DRAW_COLOR_HISTOGRAM
//#property indicator_type1		DRAW_COLOR_LINE
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
input int						CCI_Period1 = 5;
input int						CCI_Period2 = 15;
input int						CCI_Period3 = 60;
input int						CCI_Period4 = 240;

input int						CCI_Level1 = 80;
input int						CCI_Level2 = 80;
input int						CCI_Level3 = 80;
input int						CCI_Level4 = 80;

input ENUM_APPLIED_PRICE        CCI_Price_Type = PRICE_CLOSE;
input int			            T3_Period = 5;
input double                    Koeff_B = 0.618;
//---------------------------------------------------------------------

//---------------------------------------------------------------------
double	MCCIBuff[ ];
double	MCCIColorBuff[ ];
double	MABuff[ ];
double	MAColorBuff[ ];
double	CCIBuff1[ ];
double	CCIBuff2[ ];
double	CCIBuff3[ ];
double	CCIBuff4[ ];
//---------------------------------------------------------------------

//---------------------------------------------------------------------
int	    cci_handler1;
int	    cci_handler2;
int	    cci_handler3;
int	    cci_handler4;
//---------------------------------------------------------------------
int		cci_bars_calculated = 0;	// number of values in the CCI indicator
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int OnInit( )
{
	Comment( "" );

	SetIndexBuffer( 0, MCCIBuff,        INDICATOR_DATA );
	SetIndexBuffer( 1, MCCIColorBuff,   INDICATOR_COLOR_INDEX );
	SetIndexBuffer( 2, MABuff,          INDICATOR_DATA );
	SetIndexBuffer( 3, MAColorBuff,     INDICATOR_COLOR_INDEX );
	SetIndexBuffer( 4, CCIBuff1,        INDICATOR_CALCULATIONS );
	SetIndexBuffer( 5, CCIBuff2,        INDICATOR_CALCULATIONS );
	SetIndexBuffer( 6, CCIBuff3,        INDICATOR_CALCULATIONS );
	SetIndexBuffer( 7, CCIBuff4,        INDICATOR_CALCULATIONS );

	PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );

	IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));
	IndicatorSetString(  INDICATOR_SHORTNAME, "CCI T3 AVG( CCI_Period1 = " + string( CCI_Period1 ) + ", T3_Period = " + string( T3_Period ) + " )" );

	// cci_handler1 = iCCI( Symbol( ), Period( ), CCI_Period1, CCI_Price_Type );
	cci_handler1 = iCustom( Symbol(), Period(), "cci_t3", CCI_Period1, CCI_Price_Type, T3_Period, Koeff_B );
	if( cci_handler1 == INVALID_HANDLE )
	{
		Print( "Failed to create the cci_t3 indicator" );
		return( -1 );
	}

	cci_handler2 = iCustom( Symbol(), Period(), "cci_t3", CCI_Period2, CCI_Price_Type, T3_Period, Koeff_B );
	if( cci_handler2 == INVALID_HANDLE )
	{
		Print( "Failed to create the cci_t3 indicator" );
		return( -1 );
	}

	cci_handler3 = iCustom( Symbol(), Period(), "cci_t3", CCI_Period3, CCI_Price_Type, T3_Period, Koeff_B );
	if( cci_handler3 == INVALID_HANDLE )
	{
		Print( "Failed to create the cci_t3 indicator" );
		return( -1 );
	}

	cci_handler4 = iCustom( Symbol(), Period(), "cci_t3", CCI_Period4, CCI_Price_Type, T3_Period, Koeff_B );
	if( cci_handler4 == INVALID_HANDLE )
	{
		Print( "Failed to create the cci_t3 indicator" );
		return( -1 );
	}
	
	ChartRedraw( );

	return( 0 );
	
} // int OnInit( )

//---------------------------------------------------------------------
//	Indicator calculation event handler:
//---------------------------------------------------------------------
int				start;
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

	if( CopyBuffer( cci_handler1, 0, 0, rates_total - start, CCIBuff1 ) == -1 )
	{
		error = true;
		return( rates_total );
	}

	if( CopyBuffer( cci_handler2, 0, 0, rates_total - start, CCIBuff2 ) == -1 )
	{
		error = true;
		return( rates_total );
	}
	
	if( CopyBuffer( cci_handler3, 0, 0, rates_total - start, CCIBuff3 ) == -1 )
	{
		error = true;
		return( rates_total );
	}
	
	if( CopyBuffer( cci_handler4, 0, 0, rates_total - start, CCIBuff4 ) == -1 )
	{
		error = true;
		return( rates_total );
	}

	if( prev_calculated == 0 || CheakNewBar( Symbol(), Period(), last_bar_datetime_chart ) == 1 )
	{
		for( int i = start; i < rates_total - 1; i++ )
		{
			double cci_t3_avg = ( CCIBuff1[ i ] + CCIBuff2[ i ] + CCIBuff3[ i ] + CCIBuff4[ i ] ) / (4);
			/*
			double cci_t3_avg_max = MathMax( MathMax( CCIBuff1[ i ], CCIBuff2[ i ]),  MathMax( CCIBuff3[ i ] , CCIBuff4[ i ] ));
			double cci_t3_avg_min = MathMin( MathMin( CCIBuff1[ i ], CCIBuff2[ i ]),  MathMin( CCIBuff3[ i ] , CCIBuff4[ i ] ));
			if( 40 < CCIBuff4[ i ] )
			{
    			cci_t3_avg = 0;//cci_t3_avg_max;
			}
			else if( -40 > CCIBuff4[ i ] )
			{
    			cci_t3_avg = 0;//cci_t3_avg_min;
			}
			else
    			cci_t3_avg = cci_t3_avg;
    		*/
			
			
			MABuff[ i ]      = cci_t3_avg;
			MAColorBuff[ i ] = 1;

			if((         CCI_Level1 < CCIBuff1[ i ] ) && 
			   (         CCI_Level2 < CCIBuff2[ i ] ) &&
			   (         CCI_Level3 < CCIBuff3[ i ] ) &&
			   (         CCI_Level4 < CCIBuff4[ i ] )    )
			{
			    MCCIBuff[ i ]      = cci_t3_avg;
				MCCIColorBuff[ i ] = 1;
			}
			else 
			if((      -1*CCI_Level1 > CCIBuff1[ i ] ) &&
			   (      -1*CCI_Level2 > CCIBuff2[ i ] ) &&
			   (      -1*CCI_Level3 > CCIBuff3[ i ] ) &&
			   (      -1*CCI_Level4 > CCIBuff4[ i ] )    )
			{
			    MCCIBuff[ i ]      = cci_t3_avg;
				MCCIColorBuff[ i ] = 2;
			}
			else
			{
			    MCCIBuff[ i ]      = 0;//cci_t3_avg;
				MCCIColorBuff[ i ] = 3;
			}
			
			
			if( MCCIBuff[ i ] > 50.0 )
			{
				MCCIColorBuff[ i ] = 1;
			}
			else if( MCCIBuff[ i ] < -50.0 )
			{
				MCCIColorBuff[ i ] = 2;
			}
			else
			{
    			//MABuff[ i ]      = 0.0;
    			//MCCIBuff[ i ]    = 0.0;-
				MCCIColorBuff[ i ] = 3;
			}
			
			
		}
		MCCIBuff[ rates_total - 1 ] = 0.0;
		MCCIColorBuff[ rates_total - 1 ] = 0;
		MABuff[ rates_total - 1 ] = MCCIBuff[ rates_total - 1 ];
		//MAColorBuff[ rates_total - 1 ] = 0;
	}

	return( rates_total );
}

//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit( const int _reason )
{
	if( cci_handler1 != INVALID_HANDLE )
	{
		IndicatorRelease( cci_handler1 );
	}

	if( cci_handler2 != INVALID_HANDLE )
	{
		IndicatorRelease( cci_handler2 );
	}
	
	if( cci_handler3 != INVALID_HANDLE )
	{
		IndicatorRelease( cci_handler3 );
	}
	
	if( cci_handler4 != INVALID_HANDLE )
	{
		IndicatorRelease( cci_handler4 );
	}


	ChartRedraw( );
}

//---------------------------------------------------------------------
//	Returns a sign of appearance of a new bar:
//---------------------------------------------------------------------
int CheakNewBar( string _symbol, ENUM_TIMEFRAMES _period, datetime& _last_dt )
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
