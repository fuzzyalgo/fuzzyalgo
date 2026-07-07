//+------------------------------------------------------------------+
//|                                          SIZE_HIGHS_AND_LOWS.mq5 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2011, tol64."
#property link        "https://login.mql5.com/en/users/tol64"
#property description "email: hello.tol64@gmail.com"
#property version     "1.00"
//--- properties  
#property indicator_chart_window
//---
#property indicator_buffers 9
#property indicator_plots   3
//---
#property indicator_type1  DRAW_LINE
#property indicator_type2  DRAW_LINE
#property indicator_type3  DRAW_ARROW
#property indicator_type4  DRAW_HISTOGRAM
#property indicator_type5  DRAW_HISTOGRAM
#property indicator_type6  DRAW_LINE
#property indicator_type7  DRAW_LINE
#property indicator_type8  DRAW_HISTOGRAM
#property indicator_type9  DRAW_HISTOGRAM
//---
#property indicator_color1 clrBlue
#property indicator_color2 clrRed
#property indicator_color3 clrBlack 
#property indicator_color4 clrLime
#property indicator_color5 clrGold
#property indicator_color6 clrLime
#property indicator_color7 clrBlack
#property indicator_color8 clrChocolate
#property indicator_color9 clrSeaGreen

//--- input parameters
input int InputAlgoPeriod=0; // Input Algo Period

//--- buffers
double maxHighBufferMainChart[],maxLowBufferMainChart[];
double HighBuffer[],LowBuffer[];
double maxHighBuffer[];
double maxLowBuffer[];
double maxDeltaBuffer[];
//--- color buffers
double ColorHighBuffer[],ColorLowBuffer[];
//--- global variables
int gAlgoPeriod=60;
//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
void OnInit()
{

    if( 0 < InputAlgoPeriod )
    {
        gAlgoPeriod=InputAlgoPeriod;
    }
    else
    {
        switch(Period())
        {
        
            case PERIOD_M1:
                gAlgoPeriod=60;
                break;
            case PERIOD_M5: 
                gAlgoPeriod=12;
                break;
            case PERIOD_M15: 
                gAlgoPeriod=4;
                break;
            case PERIOD_M30: 
                gAlgoPeriod=4;
                break;
            case PERIOD_H1:
                gAlgoPeriod=3;
                break;
            case PERIOD_H4: 
                gAlgoPeriod=2;
                break;
            case PERIOD_D1: 
                gAlgoPeriod=1;
                break;
            default:
                gAlgoPeriod=4;
                break;
        } // switch(Period())
    }
  
//--- indicator short name
   string short_name="Period: " + IntegerToString(gAlgoPeriod) + " SIZE HIGHS / LOWS3:";

//--- set short name
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- buffers for calculations and plot
   SetIndexBuffer(0,maxHighBufferMainChart,INDICATOR_DATA);
   SetIndexBuffer(1,maxLowBufferMainChart,INDICATOR_DATA);
   SetIndexBuffer(2,maxDeltaBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,maxHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,maxLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,ColorHighBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8,ColorLowBuffer,INDICATOR_COLOR_INDEX);
//--- precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);


//--- set plot draw begin (0 1 2 3...N )
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(8,PLOT_DRAW_BEGIN,gAlgoPeriod);
//--- line style
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_DASHDOTDOT);
//--- line width
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);
//---
   PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_DASHDOTDOT);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,1);

   PlotIndexSetInteger(2,PLOT_ARROW,0x6e);
   /*PlotIndexSetInteger(1,PLOT_ARROW,0x6e);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,6);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,6);*/


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
//---
   PlotIndexSetInteger(6,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(6,PLOT_LINE_WIDTH,4);
//---
   PlotIndexSetInteger(7,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(7,PLOT_LINE_WIDTH,4);
//---
   PlotIndexSetInteger(8,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(8,PLOT_LINE_WIDTH,4);
   
   
//--- indicator label
   PlotIndexSetString(0,PLOT_LABEL,"Price Max Size Highs");
   PlotIndexSetString(1,PLOT_LABEL,"Price Max Size Lows");
   PlotIndexSetString(2,PLOT_LABEL,"Size Highs");
   PlotIndexSetString(3,PLOT_LABEL,"Size Lows");
   PlotIndexSetString(4,PLOT_LABEL,"Max Size Highs");
   PlotIndexSetString(5,PLOT_LABEL,"Max Size Lows");
   PlotIndexSetString(6,PLOT_LABEL,"Max Delta Buffer");
   PlotIndexSetString(7,PLOT_LABEL,"");
   PlotIndexSetString(8,PLOT_LABEL,"");
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
   if(rates_total<=gAlgoPeriod) { return(0); }
   if(rates_total<=gAlgoPeriod) { return(0); }
//--- preliminary calculations
   if(prev_calculated==0) // first call
     {
      //--- set empty values
      maxHighBufferMainChart[0]=EMPTY_VALUE;
      maxLowBufferMainChart[0]=EMPTY_VALUE;
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
         HighBuffer[i]=ND_dgt(Close[i],_Digits)-ND_dgt(Open[i],_Digits);
         maxHighBuffer[i]=ND_dgt(Highest(HighBuffer,gAlgoPeriod,i),_Digits);
         ColorHighBuffer[i]=HighBuffer[i];
         
         LowBuffer[i]=0.0;
         maxLowBuffer[i]=ND_dgt(Lowest(LowBuffer,gAlgoPeriod,i),_Digits);
         ColorLowBuffer[i]=LowBuffer[i];
         
        }
      else if(Close[i]<Open[i]) // bearish candle
        {
         LowBuffer[i]=ND_dgt(Close[i],_Digits)-ND_dgt(Open[i],_Digits);
         maxLowBuffer[i]=ND_dgt(Lowest(LowBuffer,gAlgoPeriod,i),_Digits);
         ColorLowBuffer[i]=LowBuffer[i];

         HighBuffer[i]=0.0;
         maxHighBuffer[i]=ND_dgt(Highest(HighBuffer,gAlgoPeriod,i),_Digits);
         ColorHighBuffer[i]=HighBuffer[i];
        
        }
      else // Doji
        {
         HighBuffer[i]=0.0;
         //---
         maxHighBuffer[i]=maxHighBuffer[i-1];
         //---
         ColorHighBuffer[i]=EMPTY_VALUE;
         
         LowBuffer[i]=0.0;
         //---
         maxLowBuffer[i]=maxLowBuffer[i-1];
         //---
         ColorLowBuffer[i]=EMPTY_VALUE;
         
        }
        
      if( maxHighBuffer[i] > maxHighBuffer[i-1] )
      {
        //maxHighBufferMainChart[i] = Close[i];
        maxHighBufferMainChart[i] = High[i];
      }
      else
      {
        maxHighBufferMainChart[i] = maxHighBufferMainChart[i-1];
      }
      
      if( maxLowBuffer[i] < maxLowBuffer[i-1] )
      {
        //maxLowBufferMainChart[i] = Close[i];
        maxLowBufferMainChart[i] = Low[i];
      }
      else
      {
        maxLowBufferMainChart[i] = maxLowBufferMainChart[i-1];
      }
        
      //maxDeltaBuffer[i]=(maxHighBufferMainChart[i] + maxLowBufferMainChart[i])/2;
      maxDeltaBuffer[i] = Close[i];
       
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
