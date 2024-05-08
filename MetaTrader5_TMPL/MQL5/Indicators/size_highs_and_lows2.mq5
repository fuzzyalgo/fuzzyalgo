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

//--- input parameters
input int InputAlgoPeriod=0; // Input Algo Period

//--- buffers
double HighBuffer[],LowBuffer[];
double maxHighBuffer[];
double maxLowBuffer[];
double maxDeltaBuffer[];
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
   string short_name="Period: " + IntegerToString(gAlgoPeriod) + " SIZE HIGHS / LOWS2:";

//--- set short name
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   
//--- Set the line drawing    
    PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
    PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
    PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
    PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_LINE);
    PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_LINE);
   
   
//--- Set line color    
    PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrChocolate);    
    PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrSeaGreen);    
    PlotIndexSetInteger(2,PLOT_LINE_COLOR,clrGold);    
    PlotIndexSetInteger(3,PLOT_LINE_COLOR,clrLime);    
    PlotIndexSetInteger(4,PLOT_LINE_COLOR,clrBlack);    
   
//--- buffers for calculations and plot
   SetIndexBuffer(0,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,maxHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,maxLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,maxDeltaBuffer,INDICATOR_DATA);
//--- precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

    PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
    //PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );
    //PlotIndexSetDouble( 3, PLOT_EMPTY_VALUE, 0.0 );
    //PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE, 0.0 );


//--- set plot draw begin (0 1 2 3...N )
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,gAlgoPeriod);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,gAlgoPeriod);
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
   PlotIndexSetInteger(4,PLOT_LINE_WIDTH,1);
//---
   
   
   
//--- indicator label
   PlotIndexSetString(0,PLOT_LABEL,"Size Highs");
   PlotIndexSetString(1,PLOT_LABEL,"Size Lows");
   PlotIndexSetString(2,PLOT_LABEL,"Max Size Highs");
   PlotIndexSetString(3,PLOT_LABEL,"Max Size Lows");
   PlotIndexSetString(4,PLOT_LABEL,"Max Delta Buffer");
   
   //IndicatorSetDouble(INDICATOR_MAXIMUM,0.002); 
   //IndicatorSetDouble(INDICATOR_MINIMUM,-0.002); 
   
//--- levels
   IndicatorSetInteger(INDICATOR_LEVELS,5);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,clrSilver);
//---
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,0*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,100*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-100*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,3,50*_Point);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,4,-50*_Point);
   
   
   ChartRedraw();
   
  }
  
//---------------------------------------------------------------------
//	Indicator deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit( const int _reason )
{
    ChartRedraw();
}
  
//+------------------------------------------------------------------+
//| Calculate                                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,     // rates total
                const int prev_calculated, // bars, processed at the previous call
                const datetime &Time[],    // time
                const double    &Open[],      // open
                const double    &High[],      // high
                const double    &Low[],       // low
                const double    &Close[],     // close
                const long      &TickVolume[],  // tick volume
                const long      &Volume[],      // trade volume
                const int       &Spread[])       // spread
  {
   int i,limit;
//--- checking of bars
   if(rates_total<=gAlgoPeriod) { return(0); }
   if(rates_total<=gAlgoPeriod) { return(0); }
//--- preliminary calculations
   if(prev_calculated==0) // first call
     {
      //--- set empty values
      HighBuffer[0]=EMPTY_VALUE; LowBuffer[0]=EMPTY_VALUE;
      maxHighBuffer[0]=EMPTY_VALUE; maxLowBuffer[0]=EMPTY_VALUE;
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
         LowBuffer[i]=0.0;
        }
      else /*if(Close[i]<Open[i]) // bearish candle*/
        {
         LowBuffer[i]=ND_dgt(Close[i],_Digits)-ND_dgt(Open[i],_Digits);
         HighBuffer[i]=0.0;
        }
        
      maxHighBuffer[i]=ND_dgt(Highest(HighBuffer,gAlgoPeriod,i),_Digits);
      maxLowBuffer[i]=ND_dgt(Lowest(LowBuffer,gAlgoPeriod,i),_Digits);
      maxDeltaBuffer[i]=maxHighBuffer[i] + maxLowBuffer[i];
       
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
/*int vDgtMlt(int value)
  {
   if(_Digits==3 || _Digits==5) { return(value*=10); } else { return(value); }
  }*/
//+------------------------------------------------------------------+
//| Conversion from double to string (digit)                         |
//+------------------------------------------------------------------+
/*string DS_dgt(double aValue,int digit)
  {
   return(DoubleToString(aValue,digit));
  }*/
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
/*string DSNDdgt(double aValue,int digit)
  {
   return(DS_dgt(ND_dgt(aValue,digit),digit));
  }*/
//-------------------------------------------------------------------+
