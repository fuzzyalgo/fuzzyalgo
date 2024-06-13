//+------------------------------------------------------------------+
//|                                          SIZE_HIGHS_AND_LOWS.mq5 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2011, tol64."
#property link        "https://login.mql5.com/en/users/tol64"
#property description "email: hello.tol64@gmail.com"
#property version     "1.00"
//--- properties  
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   2
//---
#property indicator_type1  DRAW_LINE
#property indicator_type2  DRAW_LINE
//---
#property indicator_color1 clrBlue
#property indicator_color2 clrRed

//--- input parameters
input int SignalLen=15; // Input Algo Period

//--- buffers
double maxHighBufferMainChart[],maxLowBufferMainChart[];
double HighBuffer[],LowBuffer[];
double maxHighBuffer[];
double maxLowBuffer[];

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
void OnInit()
{

  
//--- indicator short name
   string short_name="Period: " + IntegerToString(SignalLen) + " SIZE HIGHS / LOWS4:";
//--- precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- set short name
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//--- buffers for calculations and plot
   SetIndexBuffer(0,maxHighBufferMainChart,INDICATOR_DATA);
   SetIndexBuffer(1,maxLowBufferMainChart,INDICATOR_DATA);
   SetIndexBuffer(2,HighBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,LowBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,maxHighBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,maxLowBuffer,INDICATOR_CALCULATIONS);
//--- set plot draw begin (0 1 2 3...N )
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,SignalLen);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,SignalLen);
//--- line style
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_DASHDOTDOT);
//--- line width
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);
//---
   PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_DASHDOTDOT);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,1);
//--- indicator label
   PlotIndexSetString(0,PLOT_LABEL,"Price Max Size Highs");
   PlotIndexSetString(1,PLOT_LABEL,"Price Max Size Lows");
   
  }
//+------------------------------------------------------------------+
//| Calculate                                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,     // rates total
                const int prev_calculated, // bars, processed at the previous call
                const datetime &Time[],    // time
                const double &Open[],      // open
                const double &High[],      // high
                const double &Low[],       // low
                const double &Close[],     // close
                const long &TickVolume[],  // tick volume
                const long &Volume[],      // trade volume
                const int &Spread[])       // spread
  {
   int cnt;
   int limit = rates_total-1*(int)SignalLen-2;
    //--- checking of bars
    if(rates_total < (int)SignalLen+10)
        return(0);

//--- calculation
   for(cnt=limit; cnt<rates_total; cnt++)
     {
      //--- size of highs
      if(Close[cnt]>Open[cnt]) // bullish candle
        {
         //--- calculate the body
         HighBuffer[cnt]=ND_dgt(Close[cnt],_Digits)-ND_dgt(Open[cnt],_Digits);
         maxHighBuffer[cnt]=ND_dgt(Highest(HighBuffer,SignalLen,cnt),_Digits);
         
         LowBuffer[cnt]=0.0;
         maxLowBuffer[cnt]=ND_dgt(Lowest(LowBuffer,SignalLen,cnt),_Digits);
         
        }
      else if(Close[cnt]<Open[cnt]) // bearish candle
        {
         LowBuffer[cnt]=ND_dgt(Close[cnt],_Digits)-ND_dgt(Open[cnt],_Digits);
         maxLowBuffer[cnt]=ND_dgt(Lowest(LowBuffer,SignalLen,cnt),_Digits);

         HighBuffer[cnt]=0.0;
         maxHighBuffer[cnt]=ND_dgt(Highest(HighBuffer,SignalLen,cnt),_Digits);
        
        }
      else // Doji
        {
         HighBuffer[cnt]=0.0;
         //---
         maxHighBuffer[cnt]=maxHighBuffer[cnt-1];
         //---
         LowBuffer[cnt]=0.0;
         //---
         maxLowBuffer[cnt]=maxLowBuffer[cnt-1];
         //---
        
        }
        
      if( maxHighBuffer[cnt] > maxHighBuffer[cnt-1] )
      {
        maxHighBufferMainChart[cnt] = High[cnt];
      }
      else
      {
        maxHighBufferMainChart[cnt] = maxHighBufferMainChart[cnt-1];
      }
      
      if( maxLowBuffer[cnt] < maxLowBuffer[cnt-1] )
      {
        maxLowBufferMainChart[cnt] = Low[cnt];
      }
      else
      {
        maxLowBufferMainChart[cnt] = maxLowBufferMainChart[cnt-1];
      }
        
       
   }
//--- return prev_calculated
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Get highest value for range                                      |
//+------------------------------------------------------------------+
double Highest(const double &array[],int range,int fromIndex)
  {
   int cnt=0;
   double res;
//---
   res=array[fromIndex];
//---
   for(cnt=fromIndex; cnt>fromIndex-range && cnt>=0; cnt--)
     {
      if(res<array[cnt]) res=array[cnt];
     }
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| Get lowest value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double &array[],int range,int fromIndex)
  {
   int cnt=0;
   double res;
//---
   res=array[fromIndex];
//---
   for(cnt=fromIndex;cnt>fromIndex-range && cnt>=0;cnt--)
     {
      if(res>array[cnt]) res=array[cnt];
     }
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| Convertion of value depending on digits (3/5)                    |
//+------------------------------------------------------------------+
int vDgtMlt(int value)
  {
   if(_Digits==3 || _Digits==5) { return(value*=10); } else { return(value); }
  }
//+------------------------------------------------------------------+
//| Conversion from double to string (digit)                         |
//+------------------------------------------------------------------+
string DS_dgt(double aValue,int digit)
  {
   return(DoubleToString(aValue,digit));
  }
//+------------------------------------------------------------------+
//| Normalization of values (digit)                                  |
//+------------------------------------------------------------------+
double ND_dgt(double aValue,int digit)
  {
   return(NormalizeDouble(aValue,digit));
  }
//+------------------------------------------------------------------+
//| Normalization and conversion to string (digit)                   |
//+------------------------------------------------------------------+
string DSNDdgt(double aValue,int digit)
  {
   return(DS_dgt(ND_dgt(aValue,digit),digit));
  }
//-------------------------------------------------------------------+
