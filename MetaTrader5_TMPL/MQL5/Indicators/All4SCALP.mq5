//+------------------------------------------------------------------+
//|                                                     All4SCALP.mq5 
//|                   Copyright 2018, André Howe
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2018, André Howe"
#property link        "http://www.andrehowe.com"
#property description "Moving Average Convergence/Divergence"
//--- indicator settings
//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_ARROW //DRAW_HISTOGRAM
#property indicator_type6   DRAW_ARROW //DRAW_HISTOGRAM
#property indicator_type7   DRAW_ARROW //DRAW_LINE
#property indicator_color1  Red
#property indicator_color2  Blue
#property indicator_color3  Green
#property indicator_color4  Black
#property indicator_color5  Blue
#property indicator_color6  Red
#property indicator_color7  Orange
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  2
#property indicator_label1  "SCALP01"
#property indicator_label2  "SCALP02"
#property indicator_label3  "SCALP03"
#property indicator_label4  "SCALP04"
#property indicator_label5  "SCALPSIGB"
#property indicator_label6  "SCALPSIGS"
#property indicator_label7  "BO"
//--- input parameters
input int                InpKPeriod1=5;        
input int                InpKPeriod2=10;       
input int                InpKPeriod3=15;       
input int                InpKPeriod4=20;       
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
input double             BO_PERCENT=0.03;
//--- indicator buffers
double                   ExtScalp01Buffer[];
double                   ExtScalp02Buffer[];
double                   ExtScalp03Buffer[];
double                   ExtScalp04Buffer[];
double                   ExtScalpSigBufferB[];
double                   ExtScalpSigBufferS[];
double                   ExtScalpBo[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtScalp01Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtScalp02Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtScalp03Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtScalp04Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtScalpSigBufferB,INDICATOR_DATA);
   SetIndexBuffer(5,ExtScalpSigBufferS,INDICATOR_DATA);
   SetIndexBuffer(6,ExtScalpBo,INDICATOR_DATA);
   ArraySetAsSeries( ExtScalp01Buffer, true );
   ArraySetAsSeries( ExtScalp02Buffer, true );
   ArraySetAsSeries( ExtScalp03Buffer, true );
   ArraySetAsSeries( ExtScalp04Buffer, true );
   ArraySetAsSeries( ExtScalpSigBufferB, true );
   ArraySetAsSeries( ExtScalpSigBufferS, true );
   ArraySetAsSeries( ExtScalpBo, true );
   
    PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetDouble( 5, PLOT_EMPTY_VALUE, 0.0 );
    PlotIndexSetDouble( 6, PLOT_EMPTY_VALUE, 0.0 );
   
   
//--- sets first bar from what index will be drawn
   //PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKPeriod1-1);
   //PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpKPeriod2-1);
//--- name for Indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"All4SCALP("+string(InpKPeriod1)+","+string(InpKPeriod2)+","+string(InpKPeriod3)+","+string(InpKPeriod4)+","+string(BO_PERCENT)+")");
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(
            const int rates_total,
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

    ArraySetAsSeries( Time, true );
    bool is =ArrayGetAsSeries( Time );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Open, true );
    is =ArrayGetAsSeries( Open );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( High, true );
    is =ArrayGetAsSeries( High );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Low, true );
    is =ArrayGetAsSeries( Low );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Close, true );
    is =ArrayGetAsSeries( Close );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( TickVolume, true );
    is =ArrayGetAsSeries( TickVolume );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Volume, true );
    is =ArrayGetAsSeries( Volume );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }
    ArraySetAsSeries( Spread, true );
    is =ArrayGetAsSeries( Spread );
    if( false == is ){ Print("ArrayGetAsSeries(false)"); return (0); }


//--- check for data
   if(rates_total<InpKPeriod1)
      return(0);
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
    
    
   int limit;
   if(prev_calculated==0)
       // TODO FIXME and calculate me
      limit=1000;
   else limit=prev_calculated-1;
//--- calculate MACD
   limit=100000;
   double max, min, scalp;
   for( int i = limit; i >= 0; i-- )
   //for(int i=limit;i<rates_total && !IsStopped();i++)
   {
       if(IsStopped()) return(0); //Checking for stop flag
   
        max=High[ArrayMaximum(High,i+1,InpKPeriod1)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod1)];
        scalp = (max+min)/2;
        ExtScalp01Buffer[i] = scalp;
        
        max=High[ArrayMaximum(High,i+1,InpKPeriod2)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod2)];
        scalp = (max+min)/2;
        ExtScalp02Buffer[i] = scalp;
        
        max=High[ArrayMaximum(High,i+1,InpKPeriod3)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod3)];
        scalp = (max+min)/2;
        ExtScalp03Buffer[i] = scalp;

        max=High[ArrayMaximum(High,i+1,InpKPeriod4)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod4)];
        scalp = (max+min)/2;
        ExtScalp04Buffer[i] = scalp;

        //
        // CMP1 - BO_PERCENT3
        //
        double var1= BO_PERCENT /100;
        double plusvar=1+var1;
        double minusvar=1-var1;
        double Middle = 0; 
        double price       = Open[i];
        double Middle_prev = ExtScalpBo[i+1];
        // calculate BO-MIDDLE
        if((price*minusvar)>Middle_prev) 
        {
            Middle=price*minusvar;
        }
        else if(price*plusvar<Middle_prev)
        {
            Middle=price*plusvar;
        }
        else
        { 
            Middle=Middle_prev;
        }
        ExtScalpBo[i] = Middle;
   }   
 /*  
*/   
   
   
   for( int i = limit; i >= 0; i-- )
   {
       if(IsStopped()) return(0); //Checking for stop flag
/*       
        if(
            ( ExtScalp04Buffer[i] > ExtScalp04Buffer[i+1] ) 
        )
        {
            ExtScalpSigBufferB[i] = Close[i];//ExtScalp01Buffer[i]; 
        }

        if(
            ( ExtScalp04Buffer[i] < ExtScalp04Buffer[i+1] ) 
        )
        {
            ExtScalpSigBufferS[i] = Close[i];//ExtScalp04Buffer[i]; 
        }
 */  
/*
    //if( ExtScalpBo[i] <  Open[i] )
    if( ExtScalp01Buffer[i] <  Open[i] )
    if( ExtScalp02Buffer[i] <  ExtScalp01Buffer[i] )
    if( ExtScalpBo[i] >  ExtScalp04Buffer[i] )
        ExtScalpSigBufferB[i] = Open[i];//ExtScalp01Buffer[i]; 
    //if( ExtScalpBo[i] >  Open[i] )
    if( ExtScalp01Buffer[i] >  Open[i] )
    if( ExtScalp02Buffer[i] >  ExtScalp01Buffer[i] )
    if( ExtScalpBo[i] <-  ExtScalp04Buffer[i] )
        ExtScalpSigBufferS[i] = Open[i];//ExtScalp04Buffer[i]; 
*/        
/* 
        if(
            ( ExtScalp01Buffer[i] > ExtScalp01Buffer[i+1] ) 
            &&( ExtScalp02Buffer[i] > ExtScalp02Buffer[i+1] ) 
            &&( ExtScalp03Buffer[i] > ExtScalp03Buffer[i+1] ) 
            &&( ExtScalp04Buffer[i] > ExtScalp04Buffer[i+1] ) 
            &&((ExtScalp01Buffer[i] >= ExtScalp02Buffer[i])&&(ExtScalp02Buffer[i] >= ExtScalp03Buffer[i])&&(ExtScalp03Buffer[i] >= ExtScalp04Buffer[i]))
            //&&( ExtScalp01Buffer[i] > ExtScalp02Buffer[i] )
            //&&( ExtScalp02Buffer[i] > ExtScalp04Buffer[i] )
        )
        {
            //if( ExtScalpBo[i] <  Open[i] )
            //if( ExtScalpBo[i] <  ExtScalp02Buffer[i] )
                ExtScalpSigBufferB[i] = Open[i];//ExtScalp01Buffer[i]; 
        }

        if(
            ( ExtScalp01Buffer[i] < ExtScalp01Buffer[i+1] ) 
            &&( ExtScalp02Buffer[i] < ExtScalp02Buffer[i+1] ) 
            &&( ExtScalp03Buffer[i] < ExtScalp03Buffer[i+1] ) 
            &&( ExtScalp04Buffer[i] < ExtScalp04Buffer[i+1] ) 
            &&((ExtScalp01Buffer[i] <= ExtScalp02Buffer[i])&&(ExtScalp02Buffer[i] <= ExtScalp03Buffer[i])&&(ExtScalp03Buffer[i] <= ExtScalp04Buffer[i]))
            //&&( ExtScalp01Buffer[i] < ExtScalp02Buffer[i] )
            //&&( ExtScalp02Buffer[i] < ExtScalp04Buffer[i] )
        )
        {
            //if( ExtScalpBo[i] >  Open[i] )
            //if( ExtScalpBo[i] >  ExtScalp02Buffer[i] )
                ExtScalpSigBufferS[i] = Open[i];//ExtScalp04Buffer[i]; 
        }
*/   
/*
        if(
            ( ExtScalp01Buffer[i] > ExtScalp01Buffer[i+1] ) 
            &&( ExtScalp02Buffer[i] > ExtScalp02Buffer[i+1] ) 
            &&( ExtScalpBo[i] > ExtScalpBo[i+1] ) 
            &&((ExtScalp01Buffer[i] >= ExtScalp02Buffer[i])&&(ExtScalp02Buffer[i] >= ExtScalpBo[i]))
        )
        {
            ExtScalpSigBufferB[i] = Open[i];//ExtScalp01Buffer[i]; 
        }

        if(
            ( ExtScalp01Buffer[i] < ExtScalp01Buffer[i+1] ) 
            &&( ExtScalp02Buffer[i] < ExtScalp02Buffer[i+1] ) 
            &&( ExtScalpBo[i] < ExtScalpBo[i+1] ) 
            &&((ExtScalp01Buffer[i] <= ExtScalp02Buffer[i])&&(ExtScalp02Buffer[i] <= ExtScalpBo[i]))
        )
        {
            ExtScalpSigBufferS[i] = Open[i];//ExtScalp04Buffer[i]; 
        }
*/


  
        if(
           /* ( ExtScalp01Buffer[i] > ExtScalp01Buffer[i+1] ) 
            &&*/( ExtScalpBo[i] > ExtScalpBo[i+1] ) 
            //&&( ExtScalp02Buffer[i] > ExtScalp02Buffer[i+1] ) 
            //&&( ExtScalp03Buffer[i] > ExtScalp03Buffer[i+1] ) 
            //&&( ExtScalp04Buffer[i] > ExtScalp04Buffer[i+1] ) 
            //&&((ExtScalp01Buffer[i] < ExtScalp02Buffer[i])&&(ExtScalp02Buffer[i] < ExtScalp03Buffer[i])&&(ExtScalp03Buffer[i] < ExtScalp04Buffer[i]))
            //&&( ExtScalp01Buffer[i] > ExtScalp03Buffer[i] )
            //&&( ExtScalp03Buffer[i] > ExtScalp04Buffer[i] )
        )
        {
            ExtScalpSigBufferB[i] = Open[i];//ExtScalp01Buffer[i]; 
        }

        if(
           /* ( ExtScalp01Buffer[i] < ExtScalp01Buffer[i+1] ) 
            &&*/( ExtScalpBo[i] < ExtScalpBo[i+1] ) 
            //&&( ExtScalp02Buffer[i] < ExtScalp02Buffer[i+1] ) 
            //&&( ExtScalp03Buffer[i] < ExtScalp03Buffer[i+1] ) 
            //&&( ExtScalp04Buffer[i] < ExtScalp04Buffer[i+1] ) 
            //&&((ExtScalp01Buffer[i] > ExtScalp02Buffer[i])&&(ExtScalp02Buffer[i] > ExtScalp03Buffer[i])&&(ExtScalp03Buffer[i] > ExtScalp04Buffer[i]))
            //&&( ExtScalp01Buffer[i] < ExtScalp03Buffer[i] )
            //&&( ExtScalp03Buffer[i] < ExtScalp04Buffer[i] )
        )
        {
            ExtScalpSigBufferS[i] = Open[i];//ExtScalp04Buffer[i]; 
        }
       
 /*   
        if(
            ( ExtScalp01Buffer[i] > ExtScalp02Buffer[i] ) &&
            ( ExtScalp02Buffer[i] > ExtScalp03Buffer[i] ) &&
            ( ExtScalp03Buffer[i] > ExtScalp04Buffer[i] )
        )
        {
            ExtScalpSigBufferB[i] = Close[i];//ExtScalp01Buffer[i]; 
        }

        if(
            ( ExtScalp01Buffer[i] < ExtScalp02Buffer[i] ) &&
            ( ExtScalp02Buffer[i] < ExtScalp03Buffer[i] ) &&
            ( ExtScalp03Buffer[i] < ExtScalp04Buffer[i] )
        )
        {
            ExtScalpSigBufferS[i] = Close[i];//ExtScalp04Buffer[i]; 
        }
*/        
   }   
   
     
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
