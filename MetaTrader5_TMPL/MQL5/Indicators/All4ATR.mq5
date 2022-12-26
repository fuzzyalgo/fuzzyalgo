//+------------------------------------------------------------------+
//|                                                     All4ATR.mq5 
//|                   Copyright 2018, André Howe
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2018, André Howe"
#property link        "http://www.andrehowe.com"
#property description "Moving Average Convergence/Divergence"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   5
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_color1  Red
#property indicator_color2  Blue
#property indicator_color3  Green
#property indicator_color4  Black
#property indicator_color5  Silver
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  3
#property indicator_label1  "ATR01"
#property indicator_label2  "ATR02"
#property indicator_label3  "ATR03"
#property indicator_label4  "ATR04"
#property indicator_label5  "ATRSIG"
//--- input parameters
input int                InpKPeriod1=5;        
input int                InpKPeriod2=15;       
input int                InpKPeriod3=60;       
input int                InpKPeriod4=240;       
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_OPEN; // Applied price
//--- indicator buffers
double                   ExtAtr01Buffer[];
double                   ExtAtr02Buffer[];
double                   ExtAtr03Buffer[];
double                   ExtAtr04Buffer[];
double                   ExtAtrSigBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtAtr01Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtAtr02Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtAtr03Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtAtr04Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtAtrSigBuffer,INDICATOR_DATA);
   ArraySetAsSeries( ExtAtr01Buffer, true );
   ArraySetAsSeries( ExtAtr02Buffer, true );
   ArraySetAsSeries( ExtAtr03Buffer, true );
   ArraySetAsSeries( ExtAtr04Buffer, true );
   ArraySetAsSeries( ExtAtrSigBuffer, true );
//--- sets first bar from what index will be drawn
   //PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKPeriod1-1);
   //PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpKPeriod2-1);
//--- name for Indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"All4ATR("+string(InpKPeriod1)+","+string(InpKPeriod2)+","+string(InpKPeriod3)+","+string(InpKPeriod4)+")");
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
      limit=40000;
   else limit=prev_calculated-1;
   
    if( limit > Bars(_Symbol,_Period) - InpKPeriod4 -1 )
    {
        limit = Bars(_Symbol,_Period) - InpKPeriod4 -1 ;
    }
   
//--- calculate MACD
   //limit=10000;
   double max, min, atr;
   for( int i = limit; i >= 0; i-- )
   //for(int i=limit;i<rates_total && !IsStopped();i++)
   {
       if(IsStopped()) return(0); //Checking for stop flag
   
        max=High[ArrayMaximum(High,i+1,InpKPeriod1)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod1)];
        atr = (max-min)/Point();
        ExtAtr01Buffer[i] = atr;
        
        max=High[ArrayMaximum(High,i+1,InpKPeriod2)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod2)];
        atr = (max-min)/Point();
        ExtAtr02Buffer[i] = atr;
        
        max=High[ArrayMaximum(High,i+1,InpKPeriod3)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod3)];
        atr = (max-min)/Point();
        ExtAtr03Buffer[i] = atr;

        max=High[ArrayMaximum(High,i+1,InpKPeriod4)];
        min=Low[ArrayMinimum(Low,i+1,InpKPeriod4)];
        atr = (max-min)/Point();
        ExtAtr04Buffer[i] = atr;

   }   

   for( int i = limit; i >= 0; i-- )
   {
       if(IsStopped()) return(0); //Checking for stop flag
   
        if(
            ( ExtAtr01Buffer[i] > ExtAtr01Buffer[i+1] ) &&
            ( ExtAtr02Buffer[i] > ExtAtr02Buffer[i+1] ) &&
            ( ExtAtr03Buffer[i] > ExtAtr03Buffer[i+1] ) &&
            ( ExtAtr04Buffer[i] > ExtAtr04Buffer[i+1] ) 
        )
        {
            ExtAtrSigBuffer[i] = ExtAtr04Buffer[i]; 
        }

   }   
     
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
