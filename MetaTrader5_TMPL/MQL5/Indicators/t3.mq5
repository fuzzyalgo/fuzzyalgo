/*
 * The indicator uses the SmoothAlgorithms.mqh library 
 * it must be placed to  terminal_data_folder\MQL5\Include
 */
//+------------------------------------------------------------------+ 
//|                                                           T3.mq4 | 
//|                           Copyright © 2010,     Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- version
#property version   "1.00"
//---- draw indicator in a separated window
#property indicator_chart_window 
//---- one indicator buffer is used
#property indicator_buffers 1 
//---- one graphic plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator plot settings          |
//+-----------------------------------+
//---- draw as a line
#property indicator_type1   DRAW_LINE
//---- line color (Red)
#property indicator_color1 Red
//---- line style (solid line)
#property indicator_style1  STYLE_SOLID
//---- line width
#property indicator_width1  1
//---- line label
#property indicator_label1  "T3"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
enum Applied_price_ // applied price
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPLE,         //PRICE_SIMPLE
   PRICE_QUARTER_,       //PRICE_QUARTER
   PRICE_TRENDFOLLOW0_,  //PRICE_TRENDFOLLOW0
   PRICE_TRENDFOLLOW1_   //PRICE_TRENDFOLLOW1
  };
//---- indicator inputs
input int T3Period=14;                   //Period of T3 average
input double b_=70;                      //Coefficient x100
input  Applied_price_  IPC=PRICE_CLOSE_; //Applied price
/* used for the calculation of the indicator values ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPLE, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
input int T3Shift=0;    // Horizontal shift in bars
input int PriceShift=0; // Vertical shift in points
//+-----------------------------------+
//---- indicator buffers
double Ind_Buffer[];
//----
double dPriceShift;
//+------------------------------------------------------------------+
// CT3 class, iPriceSeries(),iPriceSeriesAlert() functions are used  |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+
//| T3 indicator initialization function                             |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- set Ind_Buffer[] array as an indicator buffer
   SetIndexBuffer(0,Ind_Buffer,INDICATOR_DATA);
//---- set plot shift (horizontal shift in bars)
   PlotIndexSetInteger(0,PLOT_SHIFT,T3Shift);
//---- set plot draw begin
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
//--- indicator label, shown in the DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"T3");
//---- set empty values
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"T3( T3Period = ",T3Period,", b = ",b_,")");
//---- set indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- declaration of CT3 class object
   CT3 T3_;
//---- set alerts
   T3_.MALengthCheck("T3Period",T3Period);
//---- set vertical shift
   dPriceShift=_Point*PriceShift;
//---- initialization end
  }
//+------------------------------------------------------------------+
//| T3 iteration function                                            | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // rates total
                const int prev_calculated,// number of bars, calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- bars checking
   if(rates_total<0)return(0);

//---- declaration of variables of integer type
   int first,bar;

//---- declaration of variables of double type
   double series,t3;

//---- calculation of starting bar index (first)
   if(prev_calculated>rates_total || prev_calculated<=0) // at first call
      first=0; // starting bar index
   else first=prev_calculated-1; // starting bar index for new bars

//---- declaration of CT3 class object
   static CT3 T3_;

//---- main loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- call of PriceSeries
      series=PriceSeries(IPC,bar,open,low,high,close);

      //---- call of T3Series 
      //---- Length is constant for the bar (Din = 0).  
      t3=T3_.T3Series(0,prev_calculated,rates_total,0,b_,T3Period,series,bar,false);

      //---- set value
      Ind_Buffer[bar]=t3+dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+