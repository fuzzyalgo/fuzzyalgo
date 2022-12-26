//+------------------------------------------------------------------+ 
//|                                                 ATR_Breakout.mq5 | 
//|                                                 Copyright © 2018 | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2018"
#property link ""
#property description "ATR_Breakout"
#property version   "1.00"
#property indicator_chart_window 
#property indicator_buffers 12
#property indicator_plots   12

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrMediumBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "BUY-EXIT"

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "BUY"

#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label3  "SELL-SL"

#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrPeachPuff
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label4  "BO-MIDDLE"

#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrGray
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
#property indicator_label5  "BUY-SL"

#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrDeepPink
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
#property indicator_label6  "SELL"

#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrPurple
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1
#property indicator_label7  "SELL-EXIT"

#property indicator_type8 DRAW_COLOR_CANDLES
#property indicator_color8 clrDeepPink,clrPurple,clrLime,clrMediumBlue,clrDodgerBlue
#property indicator_style8 STYLE_SOLID
#property indicator_width8 2
#property indicator_label8 "BO-BARS"


//+-----------------------------------+
//|  Inputs
//+-----------------------------------+
input int ATR_Threshold=40; //percent
//+-----------------------------------+

//---- global buffers
double BuyExitBuffer[];
double BuyBuffer[];
double SellSlBuffer[];
double BoMiddle[];
double BuySlBuffer[];
double SellBuffer[];
double SellExitBuffer[];

double ExtOpenBuffer[],ExtHighBuffer[],ExtLowBuffer[],ExtCloseBuffer[],ExtColorBuffer[];

//---- global variables
int min_rates_total;

static double Middle_prev = 0;
static double dAtr_prev = 0;

//+------------------------------------------------------------------+    
//| Custom indicator indicator initialization function               | 
//+------------------------------------------------------------------+  
void OnInit() {

   min_rates_total=2;

   SetIndexBuffer(0,BuyExitBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_SHIFT,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(1,PLOT_SHIFT,0);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(2,SellSlBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(2,PLOT_SHIFT,0);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(3,BoMiddle,INDICATOR_DATA);
   PlotIndexSetInteger(3,PLOT_SHIFT,0);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(4,BuySlBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(4,PLOT_SHIFT,0);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(5,SellBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(5,PLOT_SHIFT,0);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(6,SellExitBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(6,PLOT_SHIFT,0);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);

   SetIndexBuffer(7,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(8,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(9,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(10,ExtCloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(11,ExtColorBuffer,INDICATOR_COLOR_INDEX);


   string shortname;
   StringConcatenate(shortname,"ATR_Breakout(ATR_Threshold = ",ATR_Threshold,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
}
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // ?????????? ??????? ? ????? ?? ??????? ????
                const int prev_calculated,// ?????????? ??????? ? ????? ?? ?????????? ????
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
//---- ???????? ?????????? ????? ?? ????????????? ??? ???????
   if(rates_total<min_rates_total) return(0);

//---- ?????????? ????? ??????????
   int first,bar;
   double Middle;
   double dAtr;
   static int BoCntUp =0;
   static int BoCntDn =0;
   

   if(prev_calculated==0) 
     {
      //first=rates_total-240; 
      first=1;
      Middle_prev=open[first-1];
      dAtr_prev= 0;
     }
   else 
     {
      first=prev_calculated-1;
     }


    for(bar=first; bar<rates_total && !IsStopped(); bar++) {

        ExtOpenBuffer[bar]=NULL;
        ExtCloseBuffer[bar]=NULL;
        ExtHighBuffer[bar]=NULL;
        ExtLowBuffer[bar]=NULL;

        double atr = (high[bar-1]-low[bar-1])/Point();
        bool bPosOpen = false;

        // Is Position Open?
        bPosOpen = false;//IsPositionOpen(bar,open[bar]);
        if( true == bPosOpen )
        {
            // ... Yes
            
            CheckAndSetSl(bar);

            // Is Position to Exit?
            if( true == IsPositionToExit(bar) )
            {
                // ... Yes
                Middle=open[bar];
                dAtr = atr;
            }
            else
            {
                // ... No
                Middle=Middle_prev;
                dAtr=dAtr_prev;
                
            } // Is Position to Exit?
            
            
        }
        else
        {
            // ... No
            
            // ATR Breakout?
            if( ATR_Threshold < atr ){
                // ... Yes
                
                Middle=open[bar];
                dAtr = atr;
                ExtOpenBuffer[bar-1]=open[bar-1];
                ExtCloseBuffer[bar-1]=close[bar-1];
                ExtHighBuffer[bar-1]=high[bar-1];
                ExtLowBuffer[bar-1]=low[bar-1];
                ExtColorBuffer[bar-1]=2;
                
            } else {
                // ... No
                
                Middle=Middle_prev;
                dAtr=dAtr_prev;
                
            } // ATR Breakout?
            
        } // Is Position Open?


        BoMiddle[bar] = Middle;

        if( (Middle+2*dAtr*Point()) < high[bar] ) {
            ExtOpenBuffer[bar]=open[bar];
            ExtCloseBuffer[bar]=close[bar];
            ExtHighBuffer[bar]=high[bar];
            ExtLowBuffer[bar]=low[bar];
            ExtColorBuffer[bar]=3;
        }else if( (Middle+dAtr*Point()) < high[bar] ) {
            ExtOpenBuffer[bar]=open[bar];
            ExtCloseBuffer[bar]=close[bar];
            ExtHighBuffer[bar]=high[bar];
            ExtLowBuffer[bar]=low[bar];
            ExtColorBuffer[bar]=4;
        }

        if( (Middle-2*dAtr*Point()) > low[bar] ) {
            ExtOpenBuffer[bar]=open[bar];
            ExtCloseBuffer[bar]=close[bar];
            ExtHighBuffer[bar]=high[bar];
            ExtLowBuffer[bar]=low[bar];
            ExtColorBuffer[bar]=1;
        }else     

        if( (Middle-dAtr*Point()) > low[bar] ) {
            ExtOpenBuffer[bar]=open[bar];
            ExtCloseBuffer[bar]=close[bar];
            ExtHighBuffer[bar]=high[bar];
            ExtLowBuffer[bar]=low[bar];
            ExtColorBuffer[bar]=0;
        }
        
        if(bar<rates_total-1) {
            Middle_prev=Middle;
            dAtr_prev=dAtr;
        }



    } // for(bar=first; bar<rates_total && !IsStopped(); bar++)
    
//---- ?????? ?????????? ?????? limit ??? ????? ????????? ?????
   // TODO don't understand this line of code
   //if(prev_calculated>rates_total || prev_calculated<=0) first+=int(Shift);
//---- ???????? ???? ????????? ????? ??????????
    for(bar=first; bar<rates_total && !IsStopped(); bar++) {
    
        
    }
//----    
    return(rates_total);
  }
//+------------------------------------------------------------------+


bool IsPositionOpen( int shift, double open )
{
    bool ret = false;
    if( (0 == Middle_prev) || (0 == dAtr_prev) )
    {
        return (ret);
    }
    if( 0 == BuyBuffer[shift-1] )
    {
        if( (Middle_prev+dAtr_prev*Point()) < open ) {
            BuyBuffer[shift]=Middle_prev+dAtr_prev*Point();
            BuySlBuffer[shift]=Middle_prev-dAtr_prev*Point();
            ret = true;
        }
    }
    else
    { 
        BuyBuffer[shift] = BuyBuffer[shift-1];
        ret = true;
    }
    if( 0 == SellBuffer[shift-1] )
    {
        if( (Middle_prev+dAtr_prev*Point()) > open ) {
            SellBuffer[shift]=Middle_prev-dAtr_prev*Point();
            SellSlBuffer[shift]=Middle_prev+dAtr_prev*Point();
            ret = true;
        }
    }
    else
    {
        SellBuffer[shift] = SellBuffer[shift-1];
        ret = true;
    }
    
    
    return ( ret );
}
//+------------------------------------------------------------------+

bool IsPositionToExit( int shift )
{
    bool ret = false;
    return (ret );
}
//+------------------------------------------------------------------+

bool CheckAndSetSl( int shift )
{
    bool ret = false;
    return (ret );
}
//+------------------------------------------------------------------+
