//+------------------------------------------------------------------+
//|                                                     All4MA.mq5 
//|                   Copyright 2018, André Howe
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2018, André Howe"
#property link        "http://www.andrehowe.com"
#property description "Moving Average Convergence/Divergence"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   6
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color1  Red
#property indicator_color2  Blue
#property indicator_color3  Green
#property indicator_color4  Black
#property indicator_color5  Silver
#property indicator_color6  Gold
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  1
#property indicator_width6  1
#property indicator_label1  "MA01"
#property indicator_label2  "MA02"
#property indicator_label3  "MA03"
#property indicator_label4  "MA04"
#property indicator_label5  "MASigB"
#property indicator_label6  "MASigS"
//--- input parameters
input int                InpKPeriod1=5;        
input int                InpKPeriod2=15;       
input int                InpKPeriod3=60;       
input int                InpKPeriod4=240;       
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_OPEN; // Applied price
//--- indicator buffers
double                   ExtMa01Buffer[];
double                   ExtMa02Buffer[];
double                   ExtMa03Buffer[];
double                   ExtMa04Buffer[];
double                   ExtMaSigBufferB[];
double                   ExtMaSigBufferS[];
//--- MA handles
int                      ExtMa01Handle;
int                      ExtMa02Handle;
int                      ExtMa03Handle;
int                      ExtMa04Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMa01Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMa02Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtMa03Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtMa04Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtMaSigBufferB,INDICATOR_DATA);
   SetIndexBuffer(5,ExtMaSigBufferS,INDICATOR_DATA);
   ArraySetAsSeries( ExtMa01Buffer, true );
   ArraySetAsSeries( ExtMa02Buffer, true );
   ArraySetAsSeries( ExtMa03Buffer, true );
   ArraySetAsSeries( ExtMa04Buffer, true );
   ArraySetAsSeries( ExtMaSigBufferB, true );
   ArraySetAsSeries( ExtMaSigBufferS, true );
   
    PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetDouble( 5, PLOT_EMPTY_VALUE, 0.0 );
   
//--- sets first bar from what index will be drawn
   //PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKPeriod1-1);
   //PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpKPeriod2-1);
//--- name for Indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"All4MA("+string(InpKPeriod1)+","+string(InpKPeriod2)+","+string(InpKPeriod3)+","+string(InpKPeriod4)+")");
//--- get MA handles
   ExtMa01Handle=iMA(NULL,0,InpKPeriod1,0,MODE_SMA,InpAppliedPrice);
   ExtMa02Handle=iMA(NULL,0,InpKPeriod2,0,MODE_SMA,InpAppliedPrice);
   ExtMa03Handle=iMA(NULL,0,InpKPeriod3,0,MODE_SMA,InpAppliedPrice);
   ExtMa04Handle=iMA(NULL,0,InpKPeriod4,0,MODE_SMA,InpAppliedPrice);
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
   if(rates_total<InpKPeriod1)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtMa01Handle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtMa01Handle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtMa02Handle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtMa02Handle is calculated (",calculated,"bars ). Error",GetLastError());
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
//--- get MA01 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtMa01Handle,0,0,to_copy,ExtMa01Buffer)<=0)
     {
      Print("Getting MA01 buffer failed! Error",GetLastError());
      return(0);
     }
//--- get MA02 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtMa02Handle,0,0,to_copy,ExtMa02Buffer)<=0)
     {
      Print("Getting MA02 buffer failed! Error",GetLastError());
      return(0);
     }
//--- get MA03 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtMa03Handle,0,0,to_copy,ExtMa03Buffer)<=0)
     {
      Print("Getting MA03 buffer failed! Error",GetLastError());
      return(0);
     }
//--- get MA04 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtMa04Handle,0,0,to_copy,ExtMa04Buffer)<=0)
     {
      Print("Getting MA04 buffer failed! Error",GetLastError());
      return(0);
     }
//---
   //int limit=10000;
   int limit;
   if(prev_calculated==0)
       // TODO FIXME and calculate me
      limit=40000;
   else limit=prev_calculated-1;
   
    if( limit > Bars(_Symbol,_Period) - InpKPeriod4 -1 )
    {
        limit = Bars(_Symbol,_Period) - InpKPeriod4 -1 ;
    }
     
   for( int i = limit; i >= 0; i-- )
   {
       if(IsStopped()) return(0); //Checking for stop flag
/*   
        if(
            ( ExtMa01Buffer[i] > ExtMa01Buffer[i+1] ) &&
            ( ExtMa02Buffer[i] > ExtMa02Buffer[i+1] ) &&
            ( ExtMa03Buffer[i] > ExtMa03Buffer[i+1] ) &&
            ( ExtMa04Buffer[i] > ExtMa04Buffer[i+1] ) &&
            ( ExtMa01Buffer[i] > ExtMa02Buffer[i] ) && ( ExtMa02Buffer[i] > ExtMa03Buffer[i] ) && ( ExtMa03Buffer[i] > ExtMa04Buffer[i] )
        )
        {
            ExtMaSigBuffer[i] = ExtMa01Buffer[i]; 
        }

        if(
            ( ExtMa01Buffer[i] < ExtMa01Buffer[i+1] ) &&
            ( ExtMa02Buffer[i] < ExtMa02Buffer[i+1] ) &&
            ( ExtMa03Buffer[i] < ExtMa03Buffer[i+1] ) &&
            ( ExtMa04Buffer[i] < ExtMa04Buffer[i+1] ) &&
            ( ExtMa01Buffer[i] < ExtMa02Buffer[i] ) && ( ExtMa02Buffer[i] < ExtMa03Buffer[i] ) && ( ExtMa03Buffer[i] < ExtMa04Buffer[i] )
        )
        {
            ExtMaSigBuffer[i] = ExtMa01Buffer[i]; 
        }
*/
        if(
            ( ExtMa03Buffer[i] > ExtMa03Buffer[i+1] ) &&
            ( ExtMa04Buffer[i] > ExtMa04Buffer[i+1] ) &&
            ( ExtMa03Buffer[i] > ExtMa04Buffer[i] )
        )
        {
            ExtMaSigBufferB[i] = ExtMa01Buffer[i]; 
        }

        if(
            ( ExtMa03Buffer[i] < ExtMa03Buffer[i+1] ) &&
            ( ExtMa04Buffer[i] < ExtMa04Buffer[i+1] ) &&
            ( ExtMa03Buffer[i] < ExtMa04Buffer[i] )
        )
        {
            ExtMaSigBufferS[i] = ExtMa01Buffer[i]; 
        }

   }   


//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
