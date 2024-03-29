//+------------------------------------------------------------------+
//|                                                        MyMACD.mq5 
//|                   Copyright 2018, André Howe
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2018, André Howe"
#property link        "http://www.andrehowe.com"
#property description "Moving Average Convergence/Divergence"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_color1  Silver
#property indicator_color2  Red
#property indicator_color3  Blue
#property indicator_width1  1
#property indicator_width2  2
#property indicator_width3  2
//#property indicator_label1  "MACD"
#property indicator_label2  "SignalFast"
#property indicator_label3  "SignalSlow"
//--- input parameters
input int                InpFastSMA=4;               // Fast EMA period
input int                InpSlowSMA=16;               // Slow EMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_OPEN; // Applied price
//--- indicator buffers
double                   ExtMacdBuffer[];
double                   ExtSignal1Buffer[];
double                   ExtSignal2Buffer[];
double                   ExtFastMaBuffer[];
double                   ExtSlowMaBuffer[];
//--- MA handles
int                      ExtFastMaHandle;
int                      ExtSlowMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignal1Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtSignal2Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
//--- sets first bar from what index will be drawn
   //PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpFastSMA-1);
   //PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpSlowSMA-1);
//--- name for Indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"MyMACD("+string(InpFastSMA)+","+string(InpSlowSMA)+")");
//--- get MA handles
   ExtFastMaHandle=iMA(NULL,0,InpFastSMA,0,MODE_SMA,InpAppliedPrice);
   ExtSlowMaHandle=iMA(NULL,0,InpSlowSMA,0,MODE_SMA,InpAppliedPrice);
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- check for data
   if(rates_total<InpFastSMA)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtFastMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtSlowMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtSlowMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//--- get Fast EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtFastMaHandle,0,0,to_copy,ExtFastMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error",GetLastError());
      return(0);
     }
//--- get SlowSMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtSlowMaHandle,0,0,to_copy,ExtSlowMaBuffer)<=0)
     {
      Print("Getting slow SMA is failed! Error",GetLastError());
      return(0);
     }
//---
   int limit;
   if(prev_calculated==0)
       // TODO FIXME and calculate me
      limit=1000;
   else limit=prev_calculated-1;
//--- calculate MACD
   for(int i=limit;i<rates_total && !IsStopped();i++){
      ExtMacdBuffer[i]=(ExtFastMaBuffer[i]-ExtSlowMaBuffer[i])/Point();
      //ExtSignal1Buffer[i] = ExtMacdBuffer[i];
      //ExtSignal2Buffer[i] = ExtMacdBuffer[i];
   }   
//--- calculate Signal
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpFastSMA,ExtMacdBuffer,ExtSignal1Buffer);
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSlowSMA,ExtMacdBuffer,ExtSignal2Buffer);
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
