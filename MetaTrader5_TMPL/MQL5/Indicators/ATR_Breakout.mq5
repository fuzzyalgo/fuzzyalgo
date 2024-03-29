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
#property indicator_buffers 10
#property indicator_plots   10

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrMediumSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "BUY"

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrMagenta
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "SELL"

#property indicator_type3   DRAW_FILLING
#property indicator_color3  clrWhiteSmoke
//#property indicator_color3  clrWhite
#property indicator_label3  "EXIT"

#property indicator_type4 DRAW_COLOR_CANDLES
#property indicator_color4 clrDeepPink,clrPurple,clrLime,clrMediumBlue,clrDodgerBlue
#property indicator_style4 STYLE_SOLID
#property indicator_width4 2
#property indicator_label4 "BO-BARS"

#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrPeachPuff
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
#property indicator_label5  "BO-MIDDLE"


//+-----------------------------------+
//|  Inputs
//+-----------------------------------+
input int ATR_Threshold=40; //percent
//+-----------------------------------+

//---- global buffers
double Up1Buffer[],Dn1Buffer[];
double Up2Buffer[],Dn2Buffer[];
double ExtOpenBuffer[],ExtHighBuffer[],ExtLowBuffer[],ExtCloseBuffer[],ExtColorBuffer[];
double BoMiddle[];

//---- global variables
int min_rates_total;

//+------------------------------------------------------------------+    
//| Custom indicator indicator initialization function               | 
//+------------------------------------------------------------------+  
void OnInit()
  {

   min_rates_total=2;

//---- ??????????? ????????????? ??????? ? ???????????? ?????
   SetIndexBuffer(0,Up1Buffer,INDICATOR_DATA);

//---- ??????????? ????????????? ??????? ? ???????????? ?????
   SetIndexBuffer(1,Dn1Buffer,INDICATOR_DATA);

//---- ??????????? ????????????? ??????? ? ???????????? ?????
   SetIndexBuffer(2,Up2Buffer,INDICATOR_DATA);

//---- ??????????? ????????????? ??????? ? ???????????? ?????
   SetIndexBuffer(3,Dn2Buffer,INDICATOR_DATA);

//---- ??????????? ????????????? ??????? IndBuffer ? ???????????? ?????
   SetIndexBuffer(4,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,ExtCloseBuffer,INDICATOR_DATA);

//---- ??????????? ????????????? ??????? ? ????????, ????????? ?????   
   SetIndexBuffer(8,ExtColorBuffer,INDICATOR_COLOR_INDEX);

   SetIndexBuffer(9,BoMiddle,INDICATOR_DATA);


//---- ????????????? ?????? ?????????? 1 ?? ??????????? ?? Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,0);
//---- ????????????? ?????? ?????? ??????? ????????? ?????????? 1 ?? min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- ????????????? ?????? ?????????? 2 ?? ??????????? ?? Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,0);
//---- ????????????? ?????? ?????? ??????? ????????? ?????????? 2 ?? min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- ????????????? ?????? ?????????? 3 ?? ??????????? ?? Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,0);
//---- ????????????? ?????? ?????? ??????? ????????? ?????????? 3 ?? min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- ????????????? ?????? ?????????? 3 ?? ??????????? ?? Shift
   PlotIndexSetInteger(3,PLOT_SHIFT,0);
//---- ????????????? ?????? ?????? ??????? ????????? ?????????? 4 ?? min_rates_total
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- ????????? ???????? ??????????, ??????? ?? ????? ?????? ?? ???????
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);

   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);

//---- ????????????? ?????????? ??? ????????? ????? ??????????
   string shortname;
   StringConcatenate(shortname,"ATR_Breakout(ATR_Threshold = ",ATR_Threshold,")");
//--- ???????? ????? ??? ??????????? ? ????????? ??????? ? ?? ??????????? ?????????
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- ??????????? ???????? ??????????? ???????? ??????????
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- ?????????? ?????????????
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
   static double Middle_prev;
   double dAtr;
   static double dAtr_prev;
   static int BoCntUp =0;
   static int BoCntDn =0;
   

//---- ?????? ?????????? ?????? first ??? ????? ????????? ?????
   if(prev_calculated==0) // ???????? ?? ?????? ????? ??????? ??????????
     {
      first=1; // ????????? ????? ??? ??????? ???? ?????
      Middle_prev=open[first-1];
      dAtr_prev= 0;
     }
   else // ????????? ????? ??? ??????? ????? ?????
     {
      first=prev_calculated-1;
     }

//---- ???????? ???? ??????? ??????? ????? ??????
    for(bar=first; bar<rates_total && !IsStopped(); bar++) {

        ExtOpenBuffer[bar]=NULL;
        ExtCloseBuffer[bar]=NULL;
        ExtHighBuffer[bar]=NULL;
        ExtLowBuffer[bar]=NULL;

        double atr = (high[bar-1]-low[bar-1])/Point();
        if( ATR_Threshold < atr ){
            Middle=open[bar];
            dAtr = atr;
            
            ExtOpenBuffer[bar-1]=open[bar-1];
            ExtCloseBuffer[bar-1]=close[bar-1];
            ExtHighBuffer[bar-1]=high[bar-1];
            ExtLowBuffer[bar-1]=low[bar-1];
            ExtColorBuffer[bar-1]=2;
            
        } else {
            Middle=Middle_prev;
            dAtr=dAtr_prev;
        }

        BoMiddle[bar] = Middle;
        /*Up1Buffer[bar]=Middle+dAtr*Point();
        Dn1Buffer[bar]=Middle-dAtr*Point();
        Up2Buffer[bar]=Middle+2*dAtr*Point();
        Dn2Buffer[bar]=Middle-2*dAtr*Point();*/


        if(bar<rates_total-1) {
            Middle_prev=Middle;
            dAtr_prev=dAtr;
        }

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
