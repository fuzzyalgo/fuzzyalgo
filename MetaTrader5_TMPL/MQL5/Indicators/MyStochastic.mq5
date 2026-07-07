//+------------------------------------------------------------------+
//|                                                   Stochastic.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_color2  Red
#property indicator_style2  STYLE_SOLID
#property indicator_width1  2
#property indicator_width2  2

//--- input parameters
input int InpKPeriod=16;  // K period
input int InpDPeriod=1;  // D period
input int InpSlowing=3;  // Slowing
//--- indicator buffers
double    ExtClampBuffer[];
double    ExtSignalBuffer[];
double    ExtHighesBuffer[];
double    ExtLowesBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtClampBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtHighesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtLowesBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- set levels
   IndicatorSetInteger(INDICATOR_LEVELS,8);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,-10);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,10);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-20);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,3,20);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,4,-30);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,5,30);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,6,-40);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,7,40);
//--- set maximum and minimum for subwindow 
   IndicatorSetDouble(INDICATOR_MINIMUM,-100);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"MyStoch2("+(string)InpKPeriod+","+(string)InpDPeriod+","+(string)InpSlowing+")");
   PlotIndexSetString(0,PLOT_LABEL,"Clamp");
   PlotIndexSetString(1,PLOT_LABEL,"Signal");
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpKPeriod+InpSlowing-2);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKPeriod+InpDPeriod);
   
	PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
   
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Stochastic Oscillator                                            |
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
   int i,k,start;
//--- check for bars count
   if(rates_total<=InpKPeriod+InpDPeriod+InpSlowing)
      return(0);
   double IntSum = 0;   
//---
   start=InpKPeriod-1;
   if(start+1<prev_calculated) start=prev_calculated-2;
   else
     {
      for(i=0;i<start;i++)
        {
         ExtLowesBuffer[i]=0.0;
         ExtHighesBuffer[i]=0.0;
        }
     }
//--- calculate HighesBuffer[] and ExtHighesBuffer[]
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      double dmin=1000000.0;
      double dmax=-1000000.0;
      for(k=i-InpKPeriod+1;k<=i;k++)
        {
         if(dmin>low[k])  dmin=low[k];
         if(dmax<high[k]) dmax=high[k];
        }
      ExtLowesBuffer[i]=dmin;
      ExtHighesBuffer[i]=dmax;
     }
//--- %K
   start=InpKPeriod-1+InpSlowing-1;
   if(start+1<prev_calculated) start=prev_calculated-2;
   else
     {
      for(i=0;i<start;i++) ExtClampBuffer[i]=0.0;
     }
//--- main cycle
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      double sumlow=0.0;
      double sumhigh=0.0;
      for(k=(i-InpSlowing+1);k<=i;k++)
        {
         sumlow +=(close[k]-ExtLowesBuffer[k]);
         sumhigh+=(ExtHighesBuffer[k]-ExtLowesBuffer[k]);
        }
      if(sumhigh==0.0) ExtSignalBuffer[i]=50.0;
      else             ExtSignalBuffer[i]=(sumlow/sumhigh-0.5)*100;
     }
//--- signal
   start=InpKPeriod+InpDPeriod+InpSlowing;
   if(start+1<prev_calculated) start=prev_calculated-2;
   else
     {
      for(i=0;i<start;i++) ExtSignalBuffer[i]=0.0;
     }
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      double avg = 0;
      //clamp = 50*(Dn-$D$2)/0.01 

      avg = 0;
      for(k=0;k<InpSlowing;k++) 
        avg+=50*(close[i-k]-close[i-InpKPeriod-k])/0.001;
      //ExtClampBuffer[i]=avg/InpSlowing;
           
      avg = 0;
      for(k=0;k<InpSlowing;k++) 
        avg+=ExtSignalBuffer[i-k];
      ExtSignalBuffer[i]=avg/InpSlowing;
      
      /*
      double PSum = ExtClampBuffer[i]*0.2;
      IntSum = (ExtClampBuffer[i-1]-ExtClampBuffer[i]+IntSum)*0.1;
      double PDSum = (ExtClampBuffer[i]-ExtClampBuffer[i-1])/5;
      
        MqlDateTime tm0, tm1;
        datetime t0 = time[i];
        TimeToStruct( t0, tm0 );
        datetime t1 = time[i-1];
        TimeToStruct( t1, tm1 );
        if( (23 == tm1.hour) && (0 == tm0.hour) )
            ExtSignalBuffer[i-1] = 0;
        ExtSignalBuffer[i] = ExtSignalBuffer[i-1] + PSum + IntSum + PDSum;*/
        
      
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
