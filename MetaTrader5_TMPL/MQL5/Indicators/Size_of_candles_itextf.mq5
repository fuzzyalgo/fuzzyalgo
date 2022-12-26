//+------------------------------------------------------------------+
//|                                       Size of candles (text).mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.001"
#property description " "
#property description "The size of the candles in the form of text above each bar"
#property description "---"
#property description "Calculation of candles size: the \"Minuend\" minus the \"Subtrahend\""
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0
//---
enum OHLC
  {
   Open=0,  // Open 
   High=1,  // High
   Low=2,   // Low 
   Close=3, // Close
  };
//--- input parameters
input uint     InpNumberOfBars=15;          // Number of bars (do not use "0")
input OHLC     InpMinuend     = Low;        // Minuend
input OHLC     InpSubtrahend  = High;         // Subtrahend
//---
string         m_prefix="size_candles_";     // prefix for object
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
string         m_arr_names[];                // array of names of objects OBJ_TEXT
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpNumberOfBars==0)
     {
      Print("\"Number of bars\"==0. Do not use \"0\"");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_prefix+=EnumToString(Period())+"_";
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   //if(Digits()==3 || Digits()==5)
   //   digits_adjust=10;
   m_adjusted_point=Point()*digits_adjust;
//---
   DeleteAll();

   ResetLastError();
   if(ArrayResize(m_arr_names,InpNumberOfBars)==-1)
     {
      Print(__FUNCTION__," ArrayResize error");
      return(INIT_SUCCEEDED);
     }
   ArraySetAsSeries(m_arr_names,true);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteAll();
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(volume,true);
   ArraySetAsSeries(spread,true);

   if(prev_calculated==0 || prev_calculated!=rates_total)
     {
      DeleteAll();

      ResetLastError();
      ArrayFree(m_arr_names);
      if(ArrayResize(m_arr_names,InpNumberOfBars)==-1)
        {
         Print(__FUNCTION__,", prev_calculated==0, ArrayResize error");
         return(0);
        }
      //--- create the texts 
      int limit=(int)InpNumberOfBars-1;
      for(int i=limit;i>=0;i--)
        {
         string name=m_prefix+"high_"+TimeToString(time[i]);
         string text=Calculate(time[i], open[i], high[i], low[i], close[i], tick_volume[i], volume[i], spread[i]);
         if(!TextCreate(0,name,0,time[i],high[i],text))
            return(0);
         m_arr_names[i]=name;
        }
      //---
      return(rates_total);
     }
   // for last bar with index0 calculate real time spread
   // for all other bars take the one passed to the indicator by mt5
   int s = spread[0];
   datetime t = time[0];
   MqlTick last_tick; 
   if(SymbolInfoTick(Symbol(),last_tick)) 
   { 
      // long last_tick.time_msc // TODO later with time
      s = (int)((last_tick.ask-last_tick.bid) / m_adjusted_point);
      t = last_tick.time;
   }    
   
   double   price_   = ObjectGetDouble(0,m_arr_names[0],OBJPROP_PRICE,0);
   long     time_    = ObjectGetInteger(0,m_arr_names[0],OBJPROP_TIME,0);
   string   text     = Calculate(t,open[0],high[0],low[0],close[0],tick_volume[0],volume[0],s);
   TextChange(0,m_arr_names[0],text);
   //Print(text);
   if(high[0]>price_)
     {
      TextMove(0,m_arr_names[0],time_,high[0]);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+ 
//| Creating Text object                                             | 
//+------------------------------------------------------------------+ 
bool TextCreate(const long              chart_ID=0,               // chart's ID 
                const string            name="Text",              // object name 
                const int               sub_window=0,             // subwindow index 
                datetime                time=0,                   // anchor point time 
                double                  price=0,                  // anchor point price 
                const string            text="Text",              // the text itself 
                const double            angle=90.0,               // text slope 
                const string            font="Lucida Console",    // font 
                const int               font_size=10,             // font size 
                const color             clr=clrBlue,              // color 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT,// anchor type 
                const bool              back=false,               // in the background 
                const bool              selection=false,          // highlight to move 
                const bool              hidden=true,              // hidden in the object list 
                const long              z_order=0)                // priority for mouse click 
  {
//--- set anchor point coordinates if they are not set 
//ChangeTextEmptyPoint(time,price);
//--- reset the error value 
   ResetLastError();
//--- create Text object 
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the anchor point                                            | 
//+------------------------------------------------------------------+ 
bool TextMove(const long   chart_ID=0,  // chart's ID 
              const string name="Text", // object name 
              datetime     time=0,      // anchor point time coordinate 
              double       price=0)     // anchor point price coordinate 
  {
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

//--- reset the error value 
   ResetLastError();
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Change the object text                                           | 
//+------------------------------------------------------------------+ 
bool TextChange(const long   chart_ID=0,  // chart's ID 
                const string name="Text", // object name 
                const string text="Text") // text 
  {
//--- reset the error value 
   ResetLastError();
//--- change object text 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteAll()
  {
   long           chart_id=0;           // Chart identifier. 0 means the current chart
   const string   prefix=m_prefix;   // Prefix in object names
   int            sub_window  = 0;           // Number of the chart subwindow. 0 means the main chart window
   int            object_type = OBJ_TEXT;    // Type of the object
   ObjectsDeleteAll(chart_id,prefix,sub_window,object_type);
//Print(__FUNCTION__);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Calculate(const datetime& time, const double& open,const double& high,const double& low,const double& close, const long& tick_volume, const long& volume, const int& spread )
  {
  /*
   double minuend=0.0;
   switch(InpMinuend)
     {
      case  Open:
         minuend=open;
         break;
      case  High:
         minuend=high;
         break;
      case  Low:
         minuend=low;
         break;
      case  Close:
         minuend=close;
         break;
     }
   double subtrahend=0.0;
   switch(InpSubtrahend)
     {
      case  Open:
         subtrahend=open;
         break;
      case  High:
         subtrahend=high;
         break;
      case  Low:
         subtrahend=low;
         break;
      case  Close:
         subtrahend=close;
         break;
     }
   */  
   double hl = MathAbs(high-low)/m_adjusted_point;
   double oc = (close-open)/m_adjusted_point;
   string text= "  " + TimeToString(time,TIME_SECONDS) + " s" + IntegerToString(spread) + " v" +  IntegerToString(tick_volume) + " h" + DoubleToString(hl,0) + " c" + DoubleToString(oc,0);
//---
   return(text);
  }
//+------------------------------------------------------------------+
