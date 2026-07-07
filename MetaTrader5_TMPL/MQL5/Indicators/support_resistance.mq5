//+------------------------------------------------------------------+
//|                                       Dynamic Resistance Support |
//|             Copyright 2014, Michael Schmidt root@shellsangles.de |
//|                                             http://www.xvirt.net |
//+------------------------------------------------------------------+
#property copyright   "2014, Michael Schmidt root@shellsangles.de"
#property link        "http://www.xvirt.net"
#property description "Dynamic Resistance Support"
//---
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_width1  1
#property indicator_width2  1
#property indicator_color1  clrBlue
#property indicator_color2  clrRed
#property indicator_label1  "Resistance"
#property indicator_label2  "Support"

//--- global variables
double ExtResistanceBuffer[];
double ExtSupportBuffer[];
double avgCandleHeight;

input int RATES_TOTAL = 0; // RATES_TOTAL - if zero use all indicator rates_total, otherwise set this value
input int AVG_CANDLE_HEIGHT = 0; // AVG_CANDLE_HEIGHT - if zero calc candle height, otherwise set this value
input int SR_SHIFT = 0; // SR_SHIFT - if zero shift to daily period seperator, otherwise set this value

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
//--- setup buffers
    PlotIndexSetInteger(0,PLOT_ARROW,159);
    PlotIndexSetInteger(1,PLOT_ARROW,159);
    SetIndexBuffer(0,ExtResistanceBuffer,INDICATOR_DATA);
    SetIndexBuffer(1,ExtSupportBuffer,INDICATOR_DATA);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
  
    static bool	error = true;
    int start;
    int my_rates_total;
    if( 0 == RATES_TOTAL )
    {
        my_rates_total = rates_total;
    }
    else
    {
        my_rates_total = RATES_TOTAL;
    }
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

    //
    // generic part support and resistance start
    //  
    double accurency = 75.0;
    int backlook = 100;
    if( 0 == start )
    {
        if( 0 == AVG_CANDLE_HEIGHT )
        {
            avgCandleHeight=getAvgCandleHeight(my_rates_total,High,Low);
            printf("Calculated average candle height for this time frame is %.4f",avgCandleHeight);
        }
        else
        {
            avgCandleHeight = AVG_CANDLE_HEIGHT*Point();
            printf("Set average candle height for this time frame is %.5f",avgCandleHeight);
        }
        // TODO review dont know understand the next line
        // it does not work without it
        start = rates_total - my_rates_total;
        if( 1 > start ) start = 1;
    }
    
    for(int i=start;i<rates_total;i++)
    {
        int matches=0;
        double matchSumUpper=0.0;
        double matchSumLower=0.0;
        double matchAvgUpper=0.0;
        double matchAvgLower=0.0;
        double iUpper=High[i]+avgCandleHeight;
        double iLower=Low[i]-avgCandleHeight;
        ExtResistanceBuffer[i]=ExtResistanceBuffer[i-1];
        ExtSupportBuffer[i]=ExtSupportBuffer[i-1];
        //--- skip candles which are abnormal high
        if(!isNormalCandle(High[i],Low[i]))
        {
            continue;
        }
        //--- look back for candles in the same range
        if( 0 == SR_SHIFT )
        {
            backlook = m_IndiGetShiftSinceDayStarted(rates_total-i);
            if( backlook < i )
            {
                ExtResistanceBuffer[i]=High[i-backlook]+avgCandleHeight;
                ExtSupportBuffer[i]=Low[i-backlook]-avgCandleHeight;
            }
            continue;
        }
        else if( 1 == SR_SHIFT )
        {
            backlook = m_IndiGetShiftSinceWeekStarted(rates_total-i);
            if( backlook < i )
            {
                ExtResistanceBuffer[i]=High[i-backlook]+avgCandleHeight;
                ExtSupportBuffer[i]=Low[i-backlook]-avgCandleHeight;
            }
            continue;
        }
        else
        {
            backlook = SR_SHIFT;
        }
        for(int k=i-1;k>=i-backlook && k>=0;k--)
        {
            if(High[k]<=iUpper && Low[k]>=iLower)
            {
                matches++;
                matchSumUpper+=High[k];
                matchSumLower+=Low[k];
            }
        }
        // --- set new resistance level
        if( (0 < matches) && (0 < backlook) )
        if(matches/(double)backlook*100>=accurency)
        {
            matchAvgUpper=matchSumUpper/(double)matches;
            matchAvgLower=matchSumLower/(double)matches;
            if(matchAvgUpper>ExtResistanceBuffer[i] || matchAvgLower<ExtSupportBuffer[i])
            {
                ExtResistanceBuffer[i]=matchAvgUpper+avgCandleHeight;
                ExtSupportBuffer[i]=matchAvgLower-avgCandleHeight;
            }
        }
    } // for(int i=start;i<my_rates_total;i++)
    //
    // generic part support and resistance end
    //  
  
    return(rates_total);
}
  
//+------------------------------------------------------------------+
//| Calculate average candle height                                  |
//+------------------------------------------------------------------+
double getAvgCandleHeight(const int rates_total,const double &High[],const double &Low[])
  {
   double sum=0.0;
   int rt = rates_total;
   if( 10 > rt ) rt = 10;
   for(int i=0;i<rt-1;i++)
     {
      sum+=High[i]-Low[i];
     }
   return sum/(rt-1);
  }
//+------------------------------------------------------------------+
//| Check for abnormal high candle                                   |
//+------------------------------------------------------------------+
bool isNormalCandle(const double high,const double low)
  {
   if(high-low>avgCandleHeight*2.0)
     {
      return false;
     }
   return true;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceDayStarted for Indicators
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceDayStarted( int shift )
{
    string slog = StringFormat( "ERROR m_GetShiftSinceDayStarted(period = %s )", EnumToString((ENUM_TIMEFRAMES)Period()) ) ;
    
    MqlDateTime tm;
    datetime t0 = iTime(Symbol(),Period(),shift);
    TimeToStruct( t0, tm );
   
    switch(Period())
    {
    
        case PERIOD_M1:
            shift = tm.hour*60 + tm.min/1; 
            break;
        case PERIOD_M5: 
            shift = tm.hour*12 + tm.min/5; 
            break;
        case PERIOD_M15: 
            shift = tm.hour*4 + tm.min/15; 
            break;
        case PERIOD_M30: 
            shift = tm.hour*2 + tm.min/30; 
            break;
        case PERIOD_H1:
            shift = tm.hour; 
            break;
        case PERIOD_H4: 
            shift = tm.hour/4; 
            break;
        case PERIOD_D1: 
            shift = 0; 
            break;
        default:
            Print(slog );
            break;
            
    } // switch(aTf)
    
    return (shift);
    
} // int m_indiGetShiftSinceDayStarted( int shift )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   m_IndiGetShiftSinceWeekStarted for Indicators
//+------------------------------------------------------------------+
int m_IndiGetShiftSinceWeekStarted( int shift )
{
    string slog = StringFormat( "ERROR m_GetShiftSinceWeekStarted(period = %s )", EnumToString((ENUM_TIMEFRAMES)Period()) ) ;
    
    MqlDateTime tm;
    datetime t0 = iTime(Symbol(),Period(),shift);
    TimeToStruct( t0, tm );
    int days = 0;
    days = tm.day_of_week -1;
    if( 0 > days ) days = 0;
    if( 4 < days ) days = 4;
   
    switch(Period())
    {
    
        case PERIOD_M1:
            shift = days*24*60 + tm.hour*60 + tm.min/1; 
            break;
        case PERIOD_M5: 
            shift = days*24*12 + tm.hour*12 + tm.min/5; 
            break;
        case PERIOD_M15: 
            shift = days*24*4 + tm.hour*4 + tm.min/15; 
            break;
        case PERIOD_M30: 
            shift = days*24*2 + tm.hour*2 + tm.min/30; 
            break;
        case PERIOD_H1:
            shift = days*24 + tm.hour; 
            break;
        case PERIOD_H4: 
            shift = days*6 + tm.hour/4; 
            break;
        case PERIOD_D1: 
            shift = days + 0; 
            break;
        default:
            Print(slog );
            break;
            
    } // switch(aTf)
    
    return (shift);
    
} // int m_indiGetShiftSinceWeekStarted( int shift )
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

