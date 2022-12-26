//+------------------------------------------------------------------+
//|                                                  Kalman_indy.mq5 |
//|                                              Copyright 2017, DNG |
//|                                 http://www.mql5.com/ru/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, DNG"
#property link      "http://www.mql5.com/ru/users/dng"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
//--- plot Kalman
#property indicator_label1  "Forecast"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Correction"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//#property indicator_label3  "Buy"
//#property indicator_type3   DRAW_ARROW
//#property indicator_color3  clrBlue
//#property indicator_style3  STYLE_SOLID
//#property indicator_width3  2
//#property indicator_label4  "Sell"
//#property indicator_type4   DRAW_ARROW
//#property indicator_color4  clrRed
//#property indicator_style4  STYLE_SOLID
//#property indicator_width4  2
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include "..\\Experts\\Kalman_Gizlyk\\Kalman.mqh"
//+------------------------------------------------------------------+
//|   input parameters                                               |
//+------------------------------------------------------------------+
input int      bars  =  6420;
input int      shift =  100;
//+------------------------------------------------------------------+
//|   indicator buffers                                              |
//+------------------------------------------------------------------+
double         KalmanBuffer[];
double         KalmanBuffer2[];
//double         KalmanBufferBuy[];
//double         KalmanBufferSell[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CKalman  *kalman;
int last_signal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,KalmanBuffer,INDICATOR_DATA);
   ArraySetAsSeries(KalmanBuffer,true);
   ArrayInitialize(KalmanBuffer,EMPTY_VALUE);
   PlotIndexSetInteger(0,PLOT_SHIFT,0);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(1,KalmanBuffer2,INDICATOR_DATA);
   ArraySetAsSeries(KalmanBuffer2,true);
   ArrayInitialize(KalmanBuffer2,EMPTY_VALUE);
   PlotIndexSetInteger(1,PLOT_SHIFT,-1);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   kalman=new CKalman(bars,shift,_Symbol,PERIOD_CURRENT);
   last_signal=0;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---
   if(prev_calculated==rates_total || rates_total<=(bars+shift))
      return prev_calculated;
  
   ArraySetAsSeries(close,true);
   for(int i=(int)fmin((rates_total-fmax(prev_calculated,bars*0.7)),shift)-1;i>=0;i--)
     {
      KalmanBuffer2[i]=NormalizeDouble(kalman.Correction(close[i]),_Digits);
      KalmanBuffer[i]=NormalizeDouble(kalman.Forecast(),_Digits);
//      if(KalmanBuffer[i]==0 || KalmanBuffer2[i]==0)
//         continue;
//     
//      if(last_signal!=1 && KalmanBuffer[i+1]<KalmanBuffer2[i])
//        {
//         KalmanBufferBuy[i]=open[i];
//         last_signal=1;
//        }
//      else
//         if(last_signal!=-1 && KalmanBuffer[i+1]>KalmanBuffer2[i])
//           {
//            KalmanBufferSell[i]=open[i];
//            last_signal=-1;
//           }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
   delete kalman;
  }
//+------------------------------------------------------------------+
