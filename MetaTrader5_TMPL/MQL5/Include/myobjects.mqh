//+------------------------------------------------------------------+
//|                                                    myobjects.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| |
//+------------------------------------------------------------------+
void CreateRectangle
(
    long     chart_id,
    string   name,
    int      nwin,
    datetime time1,
    double   price1,
    datetime time2,
    double   price2,
    color    Color,
    int      style,
    int      width,
    string   text
)
//----
{
//----
    ObjectCreate(chart_id, name, OBJ_RECTANGLE, nwin, time1, price1, time2, price2);
    ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    ObjectSetInteger(chart_id, name, OBJPROP_STYLE, style);
    ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, width);
    ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
    ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
    ObjectSetInteger(chart_id, name, OBJPROP_SELECTED, true);
    ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, true);
    ObjectSetInteger(chart_id, name, OBJPROP_FILL, true);
//----

} // void CreateRectangle
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| |
//+------------------------------------------------------------------+
void SetRectangle
(
    long     chart_id,
    string   name,
    int      nwin,
    datetime time1,
    double   price1,
    datetime time2,
    double   price2,
    color    Color,
    int      style,
    int      width,
    string   text
)
//----
{
//----
    if(ObjectFind(chart_id, name) == -1) CreateRectangle(chart_id, name, nwin, time1, price1, time2, price2, Color, style, width, text);
    else
    {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectMove(chart_id, name, 0, time1, price1);
        ObjectMove(chart_id, name, 1, time2, price2);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    }
//----

} // void SetRectangle
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  RightPrice creation                                             |
//+------------------------------------------------------------------+
void CreateRightPrice(long chart_id,   // chart ID
                      string   name,            // object name
                      int      nwin,            // window index
                      datetime time,            // price level time
                      double   price,           // price level
                      color    Color,           // Text color
                      string   Font             // Text font
                     )
//----
{
//----
    ObjectCreate(chart_id, name, OBJ_ARROW_RIGHT_PRICE, nwin, time, price);
    ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    ObjectSetString(chart_id, name, OBJPROP_FONT, Font);
    ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
    ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, 2);
//----

} // void CreateRightPrice
//+------------------------------------------------------------------+

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
    if(ObjectFind(chart_id, name) == -1) CreateRightPrice(chart_id, name, nwin, time, price, Color, Font);
    else ObjectMove(chart_id, name, 0, time, price);
//----

} // void SetRightPrice
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  RightPrice creation                                             |
//+------------------------------------------------------------------+
void CreateRightText(long chart_id,// chart ID
                     string   name,              // object name
                     int      nwin,              // window index
                     datetime time,              // price level time
                     double   price,             // price level
                     color    Color,             // Text color
                     string   Font,               // Text font
                     string   Text               // Text text
                    )
//----
{
//----
    ObjectCreate(chart_id, name, OBJ_TEXT, nwin, time, price);
    ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    ObjectSetString(chart_id, name, OBJPROP_FONT, Font);
    ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
    ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, 2);
    ObjectSetString(chart_id, name, OBJPROP_TEXT, Text);
//----

} // void CreateRightText
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  RightPrice reinstallation                                       |
//+------------------------------------------------------------------+
void SetRightText(long chart_id,// chart ID
                  string   name,              // object name
                  int      nwin,              // window index
                  datetime time,              // price level time
                  double   price,             // price level
                  color    Color,             // Text color
                  string   Font,               // Text font
                  string   Text               // Text text
                 )
//----
{
//----
    if(ObjectFind(chart_id, name) == -1)
        CreateRightText(chart_id, name, nwin, time, price, Color, Font, Text);
    else
    {
        ObjectMove(chart_id, name, 0, time, price);
        ObjectSetString(chart_id, name, OBJPROP_TEXT, Text);
    }
//----

} // void SetRightText

//+------------------------------------------------------------------+
//|  |
//+------------------------------------------------------------------+
void CreateTline
(
    long     chart_id,
    string   name,
    int      nwin,
    datetime time1,
    double   price1,
    datetime time2,
    double   price2,
    color    Color,
    int      style,
    int      width,
    string   text
)
//----
{
//----
    ObjectCreate(chart_id, name, OBJ_TREND, nwin, time1, price1, time2, price2);
    ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    ObjectSetInteger(chart_id, name, OBJPROP_STYLE, style);
    ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, width);
    ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
    ObjectSetInteger(chart_id, name, OBJPROP_BACK, false);
    ObjectSetInteger(chart_id, name, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(chart_id, name, OBJPROP_RAY, false);
    ObjectSetInteger(chart_id, name, OBJPROP_SELECTED, true);
    ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, true);
//----

} // void CreateTline
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  |
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
    if(ObjectFind(chart_id, name) == -1) CreateTline(chart_id, name, nwin, time1, price1, time2, price2, Color, style, width, text);
    else
    {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectMove(chart_id, name, 0, time1, price1);
        ObjectMove(chart_id, name, 1, time2, price2);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    }
//----

} // void SetTline
//+------------------------------------------------------------------+
