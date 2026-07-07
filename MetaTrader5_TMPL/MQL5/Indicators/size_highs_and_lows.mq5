//+------------------------------------------------------------------+
//|                                          SIZE_HIGHS_AND_LOWS.mq5 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2011, tol64."
#property link        "https://login.mql5.com/en/users/tol64"
#property description "email: hello.tol64@gmail.com"
#property version     "1.00"
//--- properties  
#property indicator_separate_window
//---
#property indicator_buffers 6
#property indicator_plots   6
//---
#property indicator_type1  DRAW_HISTOGRAM
#property indicator_type2  DRAW_HISTOGRAM
#property indicator_type3  DRAW_LINE
#property indicator_type4  DRAW_LINE
#property indicator_type5  DRAW_HISTOGRAM
#property indicator_type6  DRAW_HISTOGRAM
//---
#property indicator_color1 clrGold
#property indicator_color2 clrLime
#property indicator_color3 clrGold
#property indicator_color4 clrLime
#property indicator_color5 clrChocolate
#property indicator_color6 clrSeaGreen

//--- input parameters
input int minHighPeriod=14; // Period Max High
input int minLowPeriod=14;  // Period Max Low
//--- buffers
double HighBuffer[],LowBuffer[];
double maxHighBuffer[];
double maxLowBuffer[];
//--- color buffers
double ColorHighBuffer[],ColorLowBuffer[];
//--- global variables
int minH=0,minL=0;
//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- checking of input parameters
   if(minHighPeriod<=0)
     {
      minH=14;
      printf("Incorrect input parameter minHighPeriod = %d. Indicator will use value %d for calculations.",minHighPeriod,minH);
     }
   else { minH=minHighPeriod; }
//---
   if(minLowPeriod<=0)
     {
      minL=14;
      printf("Incorrect input parameter minLowPeriod = %d. Indicator will use value %d for calculations.",minLowPeriod,minL);
     }
   else { minL=minLowPeriod; }
//--- indicator short name
   string short_name="SIZE HIGHS / LOWS:";

//--- set short name
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- buffers for calculations and plot
   SetIndexBuffer(0,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,maxHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,maxLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ColorHighBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,ColorLowBuffer,INDICATOR_COLOR_INDEX);
//--- precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//--- set plot draw begin (0 1 2 3...N )
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,minHighPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,minLowPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,minHighPeriod);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,minLowPeriod);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,minHighPeriod);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,minLowPeriod);
//--- line style
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID);
//--- line width
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,4);
//---
   PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,4);
//---
   PlotIndexSetInteger(2,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,1);
//---
   PlotIndexSetInteger(3,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(3,PLOT_LINE_WIDTH,1);
//---
   PlotIndexSetInteger(4,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(4,PLOT_LINE_WIDTH,4);
//---
   PlotIndexSetInteger(5,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(5,PLOT_LINE_WIDTH,4);
//--- indicator label
   PlotIndexSetString(0,PLOT_LABEL,"Size Highs");
   PlotIndexSetString(1,PLOT_LABEL,"Size Lows");
   PlotIndexSetString(2,PLOT_LABEL,"Max Size Highs");
   PlotIndexSetString(3,PLOT_LABEL,"Max Size Lows");
   PlotIndexSetString(4,PLOT_LABEL,"");
   PlotIndexSetString(5,PLOT_LABEL,"");
//--- levels
   IndicatorSetInteger(INDICATOR_LEVELS,12);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,clrSilver);
//---
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,vDgtMlt(_Digits*2)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,vDgtMlt(_Digits*4)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,vDgtMlt(_Digits*6)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,3,vDgtMlt(_Digits*8)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,4,vDgtMlt(_Digits*10)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,5,vDgtMlt(_Digits*12)*_Point);
//---
   IndicatorSetDouble(INDICATOR_LEVELVALUE,6,-vDgtMlt(_Digits*2)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,7,-vDgtMlt(_Digits*4)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,8,-vDgtMlt(_Digits*6)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,9,-vDgtMlt(_Digits*8)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,10,-vDgtMlt(_Digits*10)*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,11,-vDgtMlt(_Digits*12)*_Point);
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
   int i,limit;
//--- checking of bars
   if(rates_total<=minHighPeriod) { return(0); }
   if(rates_total<=minLowPeriod) { return(0); }
//--- preliminary calculations
   if(prev_calculated==0) // first call
     {
      //--- set empty values
      HighBuffer[0]=EMPTY_VALUE; LowBuffer[0]=EMPTY_VALUE;
      maxHighBuffer[0]=EMPTY_VALUE; maxLowBuffer[0]=EMPTY_VALUE;
      ColorHighBuffer[0]=EMPTY_VALUE; ColorLowBuffer[0]=EMPTY_VALUE;
      //---
      limit=1;
     }
   else { limit=prev_calculated-1; }

//--- calculation
   for(i=limit; i<rates_total; i++)
     {
      //--- size of highs
      if(Close[i]>Open[i]) // bullish candle
        {
         //--- calculate the body
         HighBuffer[i]=ND_dgt(High[i],_Digits)-ND_dgt(Close[i],_Digits);
         maxHighBuffer[i]=ND_dgt(Highest(HighBuffer,minHighPeriod,i),_Digits);
         //---
         if(Close[i]<Open[i])
           {
            ColorHighBuffer[i]=HighBuffer[i];
           }
         else if(Close[i]>Open[i])
           {
            ColorHighBuffer[i]=EMPTY_VALUE;
           }
         else
           {
            ColorHighBuffer[i]=EMPTY_VALUE;
           }
        }
      else if(Close[i]<Open[i]) // bearish candle
        {
         //--- calculate the body
         HighBuffer[i]=ND_dgt(High[i],_Digits)-ND_dgt(Open[i],_Digits);
         //HighBuffer[i]=ND_dgt(Close[i],_Digits)-ND_dgt(Open[i],_Digits);
         maxHighBuffer[i]=ND_dgt(Highest(HighBuffer,minHighPeriod,i),_Digits);
         //---
         if(Close[i]<Open[i])
           {
            ColorHighBuffer[i]=HighBuffer[i];
           }
         else if(Close[i]>Open[i])
           {
            ColorHighBuffer[i]=EMPTY_VALUE;
           }
         else
           {
            ColorHighBuffer[i]=EMPTY_VALUE;
           }
        }
      else // Doji
        {
         HighBuffer[i]=0.0;
         //---
         maxHighBuffer[i]=maxHighBuffer[i-1];
         //---
         ColorHighBuffer[i]=EMPTY_VALUE;
        }

      //--- size of Lows
      if(Close[i]>Open[i]) // bullish candle
        {
         //--- calculate body of the candle
         LowBuffer[i]=ND_dgt(Low[i],_Digits)-ND_dgt(Open[i],_Digits);
         //LowBuffer[i]=ND_dgt(Close[i],_Digits)-ND_dgt(Open[i],_Digits);
         maxLowBuffer[i]=ND_dgt(Lowest(LowBuffer,minLowPeriod,i),_Digits);
         //---
         if(Close[i]>Open[i])
           {
            ColorLowBuffer[i]=LowBuffer[i];
           }
         else if(Close[i]<Open[i])
           {
            ColorLowBuffer[i]=EMPTY_VALUE;
           }
         else
           {
            ColorLowBuffer[i]=EMPTY_VALUE;
           }
        }
      else if(Close[i]<Open[i]) // bearish
        {
         //--- calculate body of the candle
         LowBuffer[i]=ND_dgt(Low[i],_Digits)-ND_dgt(Close[i],_Digits);
         maxLowBuffer[i]=ND_dgt(Lowest(LowBuffer,minLowPeriod,i),_Digits);
         //---
         if(Close[i]>Open[i])
           {
            ColorLowBuffer[i]=LowBuffer[i];
           }
         else if(Close[i]<Open[i])
           {
            ColorLowBuffer[i]=EMPTY_VALUE;
           }
         else
           {
            ColorLowBuffer[i]=EMPTY_VALUE;
           }
        }
      else // Doji case
        {
         LowBuffer[i]=0.0;
         //---
         maxLowBuffer[i]=maxLowBuffer[i-1];
         //---
         ColorLowBuffer[i]=EMPTY_VALUE;
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
   int i=0;
   double res;
//---
   res=array[fromIndex];
//---
   for(i=fromIndex; i>fromIndex-range && i>=0; i--)
     {
      if(res<array[i]) res=array[i];
     }
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| Get lowest value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double &array[],int range,int fromIndex)
  {
   int i=0;
   double res;
//---
   res=array[fromIndex];
//---
   for(i=fromIndex;i>fromIndex-range && i>=0;i--)
     {
      if(res>array[i]) res=array[i];
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
