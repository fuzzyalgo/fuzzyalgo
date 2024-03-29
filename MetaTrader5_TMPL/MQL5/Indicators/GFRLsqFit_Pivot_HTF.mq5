//+---------------------------------------------------------------------+
//|                                       GFRLsqFit_Pivot_HTF.mq5 |
//|                                  Copyright © 2017, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
#property copyright "Copyright © 2017, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "GFRLsqFit Bands Pivot"
//---- ????? ?????? ??????????
#property version   "1.60"
//+--------------------------------------------+
//|  ????????? ????????? ??????????            |
//+--------------------------------------------+
//---- ????????? ?????????? ? ??????? ????
#property indicator_chart_window 
#property indicator_buffers 0
#property indicator_plots   0
//+--------------------------------------------+
//|  ?????????? ????????                       |
//+--------------------------------------------+
#define INDICATOR_NAME      "GFRLsqFit_Pivot_HTF"     // ??? ??????????
#define RESET               0                               // ????????? ??? ???????? ????????? ??????? ?? ???????? ??????????
//+--------------------------------------------+
//|  ??????? ????????? ??????????              |
//+--------------------------------------------+
//input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;    
input string Symbols_Sirname="GFRLsqFit_Pivot_"; 

input uint s1_Samples=4;
input uint s2_Samples=20;
input uint s3_Samples=60;
input uint s4_Samples=240;


input color Up_Color=clrBlue; 
input color Dn_Color=clrRed;
input uint SignalBar=0;   
input uint SignalLen=15;     
//---- ????? ??????? ?????
input color  Middle_color=clrSpringGreen;//clrBlue;
input color  Upper_color1=clrMediumSeaGreen;
input color  Lower_color1=clrRed;
input color  Upper_color2=clrDodgerBlue;
input color  Lower_color2=clrMagenta;
//+-----------------------------------+
//---- ?????????? ????? ?????????? ?????? ??????? ??????
int min_rates_total,min_rates_1;
//---- ?????????? ?????????? ??????????
string AvgName,UpDnName,UpName,MiddleName,DnName;
//---- ?????????? ???????? ??? ????????? ?????
string upper_name1,middle_name,lower_name1,upper_name2,lower_name2;
int PerSignalLen;
//--- ?????????? ????????????? ?????????? ??? ??????? ???????????
int Ind_Handle;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
    Ind_Handle=iCustom(Symbol(),Period(),"GRFLsqFit",s1_Samples,s2_Samples,s3_Samples,s4_Samples);
    //Ind_Handle_M1_Ticks=iCustom(Symbol()/*+"_ticks"*/,PERIOD_M1,"GRFLsqFit",s1_Samples,s2_Samples,s3_Samples,s4_Samples);
    if(Ind_Handle==INVALID_HANDLE)
    {
        Print(" BARS GFRLsqFit failed");
        return(INIT_FAILED);
    }
  
//---- ????????????? ?????????? ?????? ??????? ??????
   min_rates_total=int(SignalLen);

//---- ????????????? ??????????
   UpName=Symbols_Sirname+"Upper Band";
   MiddleName=Symbols_Sirname+"Middle Band";
   DnName=Symbols_Sirname+"Lower Band";
   UpDnName=Symbols_Sirname+"Upper Lower Band";
   AvgName=Symbols_Sirname+"Average Band";
   // TODO FIXME find constant length per Period() depending on input SignalLen
   //  for now set PerSignalLen to 5h -> 5*60min*60sec
   PerSignalLen=15*60;//5*60*60;//int(SignalLen)*PeriodSeconds();
   PerSignalLen=int(SignalLen)*PeriodSeconds();
//---- ????????????? ????????
   upper_name1=Symbols_Sirname+" upper text lable 1";
   middle_name=Symbols_Sirname+" middle text lable";
   lower_name1=Symbols_Sirname+" lower text lable 1";
   upper_name2=Symbols_Sirname+" upper text lable 2";
   lower_name2=Symbols_Sirname+" lower text lable 2";

//--- ???????? ????? ??? ??????????? ? ????????? ??????? ? ?? ??????????? ?????????
   IndicatorSetString(INDICATOR_SHORTNAME,INDICATOR_NAME);
//--- ??????????? ???????? ??????????? ???????? ??????????
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
   
//--- ?????????? ?????????????
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(0,Symbols_Sirname,-1,-1);
//----
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // ?????????? ??????? ? ????? ?? ??????? ????
                const int prev_calculated,// ?????????? ??????? ? ????? ?? ?????????? ????
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
    //Print("1");
  

    if(rates_total<min_rates_total) 
        return(RESET);

    if( BarsCalculated(Ind_Handle)<Bars(Symbol(),Period())  ) 
        return(prev_calculated);
        
    static double Up1[1],Up2[1],Middle[1],Dn1[1],Dn2[1];

/*
    if(CopyBuffer(Ind_Handle,1,SignalBar,1,Up2)<=0) return(RESET);
    if(CopyBuffer(Ind_Handle,2,SignalBar,1,Up1)<=0) return(RESET);
    if(CopyBuffer(Ind_Handle,0,SignalBar,1,Middle)<=0) return(RESET);
    if(CopyBuffer(Ind_Handle,3,SignalBar,1,Dn1)<=0) return(RESET);
    if(CopyBuffer(Ind_Handle,4,SignalBar,1,Dn2)<=0) return(RESET);
*/
/*
    if(CopyBuffer(Ind_Handle_M1_Ticks,3,SignalBar,1,Up2)<=0) 
        return(RESET);
    if(CopyBuffer(Ind_Handle_M5_Ticks,3,SignalBar,1,Up1)<=0) 
        return(RESET);
    if(CopyBuffer(Ind_Handle_M15_Ticks,3,SignalBar,1,Dn1)<=0) 
        return(RESET);
    if(CopyBuffer(Ind_Handle,3,SignalBar,1,Dn2)<=0) 
        return(RESET);
*/
    if(CopyBuffer(Ind_Handle,0,SignalBar,1,Up2)<=0) 
        return(RESET);
    if(CopyBuffer(Ind_Handle,1,SignalBar,1,Up1)<=0) 
        return(RESET);
    if(CopyBuffer(Ind_Handle,2,SignalBar,1,Dn1)<=0) 
        return(RESET);
    if(CopyBuffer(Ind_Handle,3,SignalBar,1,Dn2)<=0) 
        return(RESET);


    
    int bar0=rates_total-1;
    int bar1=rates_total-int(MathMax(SignalLen-1,0));

    //Up2[0] = open[bar0]; //(Up2[0] + Up1[0] + Dn2[0] + Dn1[0])/4;
    //Up1[0] = close[bar0]; //(Up2[0] + Up1[0] + Dn2[0] + Dn1[0])/4;
    
    Middle[0] = close[bar0]; //(Up2[0] + Up1[0] + Dn2[0] + Dn1[0])/4;

    datetime time0=time[bar0];
    datetime time1=time0-2*PeriodSeconds();//-PerSignalLen/2;
    if( Up1[0] < Up2[0] )
        SetRectangle(0,UpName,0,time1,Up1[0],time0,Up2[0],Up_Color,STYLE_SOLID,1,UpName);
    else
        SetRectangle(0,UpName,0,time1,Up1[0],time0,Up2[0],Dn_Color,STYLE_SOLID,1,UpName);

    datetime time2=time1-2*PeriodSeconds();
    if( Dn1[0] < Up1[0] )
        SetRectangle(0,UpDnName,0,time2,Dn1[0],time1,Up1[0],Up_Color,STYLE_SOLID,1,UpDnName);
    else
        SetRectangle(0,UpDnName,0,time2,Dn1[0],time1,Up1[0],Dn_Color,STYLE_SOLID,1,UpDnName);

    
    datetime time3=time2-2*PeriodSeconds();//-PerSignalLen/2;
    if( Dn2[0] < Dn1[0] )
        SetRectangle(0,DnName,0,time3,Dn1[0],time2,Dn2[0],Up_Color,STYLE_SOLID,1,DnName);
    else
        SetRectangle(0,DnName,0,time3,Dn1[0],time2,Dn2[0],Dn_Color,STYLE_SOLID,1,DnName);
    
    int avg1 = (int)((Up2[0]-Up1[0])/_Point);
    int avg2 = (int)((Up1[0]-Dn1[0])/_Point);
    int avg3 = (int)((Dn1[0]-Dn2[0])/_Point);
    int avgp = (int)(( avg1 + avg2 + avg3 ) / 3);
    //Print( avg1 + " " + avg2 + " " + avg3 + " " + avgp );
    double avg  = avgp*_Point  + Middle[0];
    datetime time4=time3-2*PeriodSeconds();//-PerSignalLen/2;
    if( 0 < avgp )
        SetRectangle(0,AvgName,0,time4,Middle[0],time3,avg,Up_Color,STYLE_SOLID,1,AvgName);
    else
        SetRectangle(0,AvgName,0,time4,Middle[0],time3,avg,Dn_Color,STYLE_SOLID,1,AvgName);
   
    SetTline(0,MiddleName,0,time3,Middle[0],time0,Middle[0],Middle_color,STYLE_SOLID,3,MiddleName);


    SetRightPrice(0,upper_name1,0,time[bar0],Up1[0],Upper_color1,"Georgia");
    SetRightPrice(0,lower_name1,0,time[bar0],Dn1[0],Lower_color1,"Georgia");
    
    datetime timep=time0+3*PeriodSeconds();
    //SetRightPrice(0,middle_name,0,time[bar0],Middle[0],Middle_color,"Georgia");
    SetRightPrice(0,middle_name,0,timep,Middle[0],clrBlue/*Middle_color*/,"Georgia");
    
    SetRightPrice(0,upper_name2,0,time[bar0],Up2[0],Upper_color2,"Georgia");
    SetRightPrice(0,lower_name2,0,time[bar0],Dn2[0],Lower_color2,"Georgia");
    
//----
    //Print("2");
    ChartRedraw(0);

    if( 0 == prev_calculated )
    {
        //---    
        string name= Symbols_Sirname + "CSS_"+EnumToString(Period())+".gif"; 
        //--- Show the name on the chart as a comment 
        //Comment(name); 
        //--- Save the chart screenshot in a file in the terminal_directory\MQL5\Files\ 
        if(ChartScreenShot(0,name,800,600,ALIGN_LEFT)) 
           Print("We've saved the screenshot ",name); 
        //---    
    }
   
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  ???????? ??????????????                                         |
//+------------------------------------------------------------------+
void CreateRectangle
(
 long     chart_id,      // ????????????? ???????
 string   name,          // ??? ???????
 int      nwin,          // ?????? ????
 datetime time1,         // ????? 1 ???????? ??????
 double   price1,        // 1 ??????? ???????
 datetime time2,         // ????? 2 ???????? ??????
 double   price2,        // 2 ??????? ???????
 color    Color,         // ???? ?????
 int      style,         // ????? ?????
 int      width,         // ??????? ?????
 string   text           // ?????
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_RECTANGLE,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
   ObjectSetInteger(chart_id,name,OBJPROP_FILL,true);
//----
  }
//+------------------------------------------------------------------+
//|  ?????????????  ??????????????                                   |
//+------------------------------------------------------------------+
void SetRectangle
(
 long     chart_id,      // ????????????? ???????
 string   name,          // ??? ???????
 int      nwin,          // ?????? ????
 datetime time1,         // ????? 1 ???????? ??????
 double   price1,        // 1 ??????? ???????
 datetime time2,         // ????? 2 ???????? ??????
 double   price2,        // 2 ??????? ???????
 color    Color,         // ???? ?????
 int      style,         // ????? ?????
 int      width,         // ??????? ?????
 string   text           // ?????
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRectangle(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//|  RightPrice creation                                             |
//+------------------------------------------------------------------+
void CreateRightPrice(long chart_id,// chart ID
                      string   name,              // object name
                      int      nwin,              // window index
                      datetime time,              // price level time
                      double   price,             // price level
                      color    Color,             // Text color
                      string   Font               // Text font
                      )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW_RIGHT_PRICE,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,2);
//----
  }
//+------------------------------------------------------------------+
//|  RightPrice reinstallation                                       |
//+------------------------------------------------------------------+
void SetRightPrice(long chart_id,// chart ID
                   string   name,              // object name
                   int      nwin,              // window index
                   datetime time,              // price level time
                   double   price,             // price level
                   color    Color,             // Text color
                   string   Font               // Text font
                   )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color,Font);
   else ObjectMove(chart_id,name,0,time,price);
//----
  }
//+------------------------------------------------------------------+
//|  ???????? ????????? ?????                                        |
//+------------------------------------------------------------------+
void CreateTline
(
 long     chart_id,      // ????????????? ???????
 string   name,          // ??? ???????
 int      nwin,          // ?????? ????
 datetime time1,         // ????? 1 ???????? ??????
 double   price1,        // 1 ??????? ???????
 datetime time2,         // ????? 2 ???????? ??????
 double   price2,        // 2 ??????? ???????
 color    Color,         // ???? ?????
 int      style,         // ????? ?????
 int      width,         // ??????? ?????
 string   text           // ?????
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,false);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//----
  }
//+------------------------------------------------------------------+
//|  ????????????? ????????? ?????                                   |
//+------------------------------------------------------------------+
void SetTline
(
 long     chart_id,      // ????????????? ???????
 string   name,          // ??? ???????
 int      nwin,          // ?????? ????
 datetime time1,         // ????? 1 ???????? ??????
 double   price1,        // 1 ??????? ???????
 datetime time2,         // ????? 2 ???????? ??????
 double   price2,        // 2 ??????? ???????
 color    Color,         // ???? ?????
 int      style,         // ????? ?????
 int      width,         // ??????? ?????
 string   text           // ?????
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
