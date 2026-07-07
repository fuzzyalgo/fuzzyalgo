//------------------------------------------------------------------
#property copyright   "© mladen, 2017, mladenfx@gmail.com"
#property link        "www.forex-station.com"
//------------------------------------------------------------------

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//#property indicator_width1   1
//#property indicator_label1  "Daily open line"
//#property indicator_type1   DRAW_ARROW
//#property indicator_style1  STYLE_SOLID
//#property indicator_width1	   1
//#property indicator_color1  clrGold

input int TimeExit_Bars  = 5;  // Number of Bars to exit for M1, M5, M15, M30 and H1
input int TimeShift = 0; // Time shift (in hours)
input int TimeExit = 4; 
double openLine[];
//
//
//
//
//


int OnInit() 
{
	IndicatorSetString( INDICATOR_SHORTNAME, "daily_open_line( time shift in hours = " + string( TimeShift ) + " )" );
	IndicatorSetInteger( INDICATOR_DIGITS, Digits( ));

	PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetString (0,PLOT_LABEL,"ODL("+IntegerToString(TimeShift)+")");     
    PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);//ARROW); 
    //PlotIndexSetInteger(0,PLOT_ARROW,233);
    PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID); 
    PlotIndexSetInteger(0,PLOT_LINE_WIDTH,5); 
    PlotIndexSetInteger(0,PLOT_SHOW_DATA,true); 
    if( 0 == TimeShift )
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrOrange );
    else if( 4 == TimeShift )
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrRed );
    else if( 8 == TimeShift )
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrGreen );
    else if( 12 == TimeShift )
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrViolet );
    else if( 16 == TimeShift )
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrTurquoise );
    else if( 20 == TimeShift )
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrBlue );
    else
        PlotIndexSetInteger(0,PLOT_LINE_COLOR, clrBrown );

    SetIndexBuffer(0,openLine,INDICATOR_DATA); return(0); 
    ArraySetAsSeries(openLine,false);
	
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{

    if (Bars(_Symbol,_Period)<rates_total)
    { 
        return(-1);
    }
    


    int dailyCnt = -1;
    
    // Print( rates_total + " : " + (prev_calculated-TimeExit_Bars-1) + " : " + (int)MathMax(prev_calculated-TimeExit_Bars-1,0) );
    
    // ah for M1 this would be 
    int max_bars_since_new_day_started = 24*60;
    for (int i=(int)MathMax(prev_calculated-max_bars_since_new_day_started-1,0); i<rates_total && !IsStopped(); i++)
    {
        if( (PERIOD_M1 == Period()) || (PERIOD_M5 == Period()) || (PERIOD_M15 == Period()) || (PERIOD_M30 == Period()) || (PERIOD_H1 == Period()) )
        {
        
            if( 0 == i ) 
            {
                openLine[i] = close[i];
                //Print( TimeToString( time[0], TIME_DATE | TIME_SECONDS ) );
            }
            if( 0 < i ) 
            {

                // a new day has started            
                string stime0 = TimeToString( time[i]  ,TIME_DATE );
                string stime1 = TimeToString( time[i-1],TIME_DATE );
                if(stime1 != stime0)
                {
                    //Print( TimeToString( time[i] ,TIME_DATE | TIME_SECONDS ) );
                    openLine[i] = close[i];
                    dailyCnt = 0;
                } // if(stime1==stime0)
                
                if( 0 <= dailyCnt )
                {
                    //Print( "(dailyCnt % TimeExit_Bars) " + dailyCnt + " " + TimeExit_Bars + " = " + (dailyCnt % TimeExit_Bars) );
                    if( 0 == (dailyCnt % TimeExit_Bars) )
                    {
                        openLine[i] = close[i];
                    }
                    else
                    {
                        openLine[i] = openLine[i-1];
                    }
                    dailyCnt++;
                }
                else
                {
                    openLine[i] = openLine[i-1];
                }
                 
            } // if( 0 < i )
            
        }
        else // for all other periods than M1
        {
        
            if( 0 == i ) 
            {
                openLine[i] = close[i]; // open[i];
            }
            if( 0 < i ) 
            {
                //openLine[i] = (stime1==stime0) ? openLine[i-1] : open[i];
                // entry condition
                string stime0 = TimeToString( time[i]  -TimeShift*3600,TIME_DATE );
                string stime1 = TimeToString( time[i-1]-TimeShift*3600,TIME_DATE );
    
                if(stime1==stime0)
                {
                    openLine[i] = openLine[i-1];
                    if( 0 != TimeExit )
                    {
                        // exit condition
                        string stime0e = TimeToString( time[i]  -TimeShift*3600-TimeExit*3600,TIME_DATE );
                        string stime1e = TimeToString( time[i-1]-TimeShift*3600-TimeExit*3600,TIME_DATE );
                        if(stime1e!=stime0e)
                        {
                            openLine[i] = 0.0;
                        }
                    } // if( 0 != TimeExit ) 
                }
                else
                {
                    // entry condition
                    // if(stime1==stime0)
                    openLine[i] = close[i]; // open[i];
                } // if(stime1==stime0)
                 
            } // if( 0 < i )
            
        } // if( (PERIOD_M1 == Period()) || (PERIOD_M5 == Period()) || (PERIOD_M15 == Period()) || (PERIOD_M30 == Period()) || (PERIOD_H1 == Period()) )
        
    } // for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
    
    return(rates_total);
    
} // int OnCalculate(const int rates_total,






