//+---------------------------------------------------------------------+
//|                                       GFRMa_Pivot_HTF.mq5           |
//|                                  Copyright © 2017, Nikolay Kositsin |
//|                                 Khabarovsk,   farria@mail.redcom.ru |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2017, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "GFRMa Bands Pivot"
#property version   "1.60"
//+--------------------------------------------+
//|  |
//+--------------------------------------------+

#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
//+--------------------------------------------+
//| |
//+--------------------------------------------+
#define INDICATOR_NAME      "GFRMa_Pivot_HTF"
#define RESET               0
//+--------------------------------------------+
//| |
//+--------------------------------------------+

#include <myobjects.mqh>

input string Symbols_Sirname = "GFRMa_Pivot_";

input uint s1_Samples = 4;
input uint s2_Samples = 8;
input uint s3_Samples = 16;
input uint s4_Samples = 32;

input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;
input ENUM_MA_METHOD     ma_method     = MODE_SMA;


input color Up_Color = clrBlue;
input color Dn_Color = clrRed;
input uint SignalBar = 0;
input uint SignalLen = 15;

input color  Middle_color = clrSpringGreen; //clrBlue;
input color  Upper_color1 = clrMediumSeaGreen;
input color  Lower_color1 = clrRed;
input color  Upper_color2 = clrDodgerBlue;
input color  Lower_color2 = clrMagenta;

int min_rates_total, min_rates_1;

string AvgName, UpDnName, UpName, MiddleName, DnName;

string upper_name1, middle_name, lower_name1, upper_name2, lower_name2;
int PerSignalLen;

int Ind_Handle_S1 = INVALID_HANDLE;
int Ind_Handle_S2 = INVALID_HANDLE;
int Ind_Handle_S3 = INVALID_HANDLE;
int Ind_Handle_S4 = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    Ind_Handle_S1 = iMA( Symbol(), Period(), s1_Samples, 0, ma_method, applied_price );
    //Ind_Handle_S1=iCustom(Symbol(),Period(),"GRFLsqFit",s1_Samples,s2_Samples,s3_Samples,s4_Samples);
    //Ind_Handle_S1_M1_Ticks=iCustom(Symbol()/*+"_ticks"*/,PERIOD_M1,"GRFLsqFit",s1_Samples,s2_Samples,s3_Samples,s4_Samples);
    if(Ind_Handle_S1 == INVALID_HANDLE)
    {
        Print(" BARS Ind_Handle_S1 failed");
        return(INIT_FAILED);
    }

    Ind_Handle_S2 = iMA( Symbol(), Period(), s2_Samples, 0, ma_method, applied_price );
    if(Ind_Handle_S2 == INVALID_HANDLE)
    {
        Print(" BARS Ind_Handle_S2 failed");
        return(INIT_FAILED);
    }

    Ind_Handle_S3 = iMA( Symbol(), Period(), s3_Samples, 0, ma_method, applied_price );
    if(Ind_Handle_S3 == INVALID_HANDLE)
    {
        Print(" BARS Ind_Handle_S3 failed");
        return(INIT_FAILED);
    }

    Ind_Handle_S4 = iMA( Symbol(), Period(), s4_Samples, 0, ma_method, applied_price );
    if(Ind_Handle_S4 == INVALID_HANDLE)
    {
        Print(" BARS Ind_Handle_S4 failed");
        return(INIT_FAILED);
    }

    min_rates_total = int(SignalLen);
    UpName = Symbols_Sirname + "Upper Band";
    MiddleName = Symbols_Sirname + "Middle Band";
    DnName = Symbols_Sirname + "Lower Band";
    UpDnName = Symbols_Sirname + "Upper Lower Band";
    AvgName = Symbols_Sirname + "Average Band";
    // TODO FIXME find constant length per Period() depending on input SignalLen
    //  for now set PerSignalLen to 5h -> 5*60min*60sec
    PerSignalLen = 15 * 60; //5*60*60;//int(SignalLen)*PeriodSeconds();
    PerSignalLen = int(SignalLen) * PeriodSeconds();
    upper_name1 = Symbols_Sirname + " upper text lable 1";
    middle_name = Symbols_Sirname + " middle text lable";
    lower_name1 = Symbols_Sirname + " lower text lable 1";
    upper_name2 = Symbols_Sirname + " upper text lable 2";
    lower_name2 = Symbols_Sirname + " lower text lable 2";

    IndicatorSetString(INDICATOR_SHORTNAME, INDICATOR_NAME);
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

    return(INIT_SUCCEEDED);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // int OnInit()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

    if(INVALID_HANDLE != Ind_Handle_S1)
    {
        IndicatorRelease(Ind_Handle_S1);
    }
    if(INVALID_HANDLE != Ind_Handle_S2)
    {
        IndicatorRelease(Ind_Handle_S2);
    }
    if(INVALID_HANDLE != Ind_Handle_S3)
    {
        IndicatorRelease(Ind_Handle_S3);
    }
    if(INVALID_HANDLE != Ind_Handle_S4)
    {
        IndicatorRelease(Ind_Handle_S4);
    }

    ObjectsDeleteAll(0, Symbols_Sirname, -1, -1);
    ChartRedraw(0);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void OnDeinit(const int reason)
//+------------------------------------------------------------------+

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

    if(rates_total < min_rates_total)
        return(RESET);


    if( BarsCalculated(Ind_Handle_S1) < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(Ind_Handle_S2) < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(Ind_Handle_S3) < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(Ind_Handle_S4) < Bars(Symbol(), Period())  )
        return(prev_calculated);


    static double Up1[1], Up2[1], Middle[1], Dn1[1], Dn2[1];

    if(CopyBuffer(Ind_Handle_S1, 0, SignalBar, 1, Up2) <= 0)
        return(RESET);
    if(CopyBuffer(Ind_Handle_S2, 0, SignalBar, 1, Up1) <= 0)
        return(RESET);
    if(CopyBuffer(Ind_Handle_S3, 0, SignalBar, 1, Dn1) <= 0)
        return(RESET);
    if(CopyBuffer(Ind_Handle_S4, 0, SignalBar, 1, Dn2) <= 0)
        return(RESET);

    int bar0 = rates_total - 1;
    int bar1 = rates_total - int(MathMax(SignalLen - 1, 0));

    //Up2[0] = open[bar0]; //(Up2[0] + Up1[0] + Dn2[0] + Dn1[0])/4;
    //Up1[0] = close[bar0]; //(Up2[0] + Up1[0] + Dn2[0] + Dn1[0])/4;

    Middle[0] = close[bar0]; //(Up2[0] + Up1[0] + Dn2[0] + Dn1[0])/4;

    datetime _width_factor = 1;

    datetime time0 = time[bar0];
    datetime time1 = time0 - _width_factor * PeriodSeconds(); //-PerSignalLen/2;
    if( Up1[0] < Up2[0] )
        SetRectangle(0, UpName, 0, time1, Up1[0], time0, Up2[0], Up_Color, STYLE_SOLID, 1, UpName);
    else
        SetRectangle(0, UpName, 0, time1, Up1[0], time0, Up2[0], Dn_Color, STYLE_SOLID, 1, UpName);

    datetime time2 = time1 - _width_factor * PeriodSeconds();
    if( Dn1[0] < Up1[0] )
        SetRectangle(0, UpDnName, 0, time2, Dn1[0], time1, Up1[0], Up_Color, STYLE_SOLID, 1, UpDnName);
    else
        SetRectangle(0, UpDnName, 0, time2, Dn1[0], time1, Up1[0], Dn_Color, STYLE_SOLID, 1, UpDnName);


    datetime time3 = time2 - _width_factor * PeriodSeconds(); //-PerSignalLen/2;
    if( Dn2[0] < Dn1[0] )
        SetRectangle(0, DnName, 0, time3, Dn1[0], time2, Dn2[0], Up_Color, STYLE_SOLID, 1, DnName);
    else
        SetRectangle(0, DnName, 0, time3, Dn1[0], time2, Dn2[0], Dn_Color, STYLE_SOLID, 1, DnName);

    int avg1 = (int)((Up2[0] - Up1[0]) / _Point);
    int avg2 = (int)((Up1[0] - Dn1[0]) / _Point);
    int avg3 = (int)((Dn1[0] - Dn2[0]) / _Point);
    int avgp = (int)(( avg1 + avg2 + avg3 ) / 3);
    //Print( avg1 + " " + avg2 + " " + avg3 + " " + avgp );

    double avg  = avgp * _Point  + Dn2[0];

    datetime time4 = time3 - _width_factor * PeriodSeconds(); //-PerSignalLen/2;
    if( 0 < avgp )
        SetRectangle(0, AvgName, 0, time4, Dn2[0]/*Middle[0]*/, time3, avg, Up_Color, STYLE_SOLID, 1, AvgName);
    else
        SetRectangle(0, AvgName, 0, time4, Dn2[0]/*Middle[0]*/, time3, avg, Dn_Color, STYLE_SOLID, 1, AvgName);

    datetime timep = time0 + 3 * PeriodSeconds();
    datetime time5 = time4 - _width_factor * PeriodSeconds();
    SetTline(0, MiddleName, 0, time5, Middle[0], timep, Middle[0], Middle_color, STYLE_SOLID, 3, MiddleName);


    //SetRightPrice(0, upper_name1, 0, time[bar0], Up1[0], Upper_color1, "Georgia");
    //SetRightPrice(0, lower_name1, 0, time[bar0], Dn1[0], Lower_color1, "Georgia");

    SetRightPrice(0, middle_name, 0, timep, Middle[0], Middle_color, "Georgia");

    /*
    string avg_txt = TimeToString(TimeCurrent(), TIME_SECONDS ) + " / " +
                     "ma: " + IntegerToString(avgp) + " / " +
                     IntegerToString(avg3) + " / " +
                     IntegerToString(avg2) + " / " +
                     IntegerToString(avg1) + " / " +
                     "v: " + IntegerToString(tick_volume[bar0]) + " / " +
                     "s: " + IntegerToString(spread[bar0]);
    SetRightText(0, middle_name + "2", 0, time4 - 6 * PeriodSeconds(), Dn1[0], clrBlue, "Courier", avg_txt);

    string c0_str = DoubleToString(close[bar0], Digits());
    int idUp2 = int( (close[bar0] - Up2[0] ) / Point() );
    int idUp1 = int( (close[bar0] - Up1[0] ) / Point() );
    int idDn1 = int( (close[bar0] - Dn1[0] ) / Point() );
    int idDn2 = int( (close[bar0] - Dn2[0] ) / Point() );
    int avg_delta = (( idUp2 + idUp1 + idDn1 + idDn2 ) / 4);
    string close_txt = TimeToString(TimeCurrent(), TIME_SECONDS ) + " / " +
                       "d: " + IntegerToString(avg_delta) + " / " +
                       IntegerToString(idUp2) + " / " +
                       IntegerToString(idUp1) + " / " +
                       IntegerToString(idDn1) + " / " +
                       IntegerToString(idDn2) + " / " +
                       "c: " + c0_str ;
    SetRightText(0, middle_name + "3", 0, time4 - 6 * PeriodSeconds(), Middle[0], clrBlue, "Courier", close_txt);
    */

    //SetRightPrice(0, upper_name2, 0, time[bar0], Up2[0], Upper_color2, "Georgia");
    //SetRightPrice(0, lower_name2, 0, time[bar0], Dn2[0], Lower_color2, "Georgia");

    //string sBS = "";
    if(PositionSelect(_Symbol))
    {
        int _color = clrWhite;
        int _colorLine = clrWhite;
        double pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        double pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        long pos_open_time = PositionGetInteger(POSITION_TIME);
        long pos_open_price_delta = 0;
        ENUM_POSITION_TYPE pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if( POSITION_TYPE_BUY == pos_open_type )
        {
            pos_open_price_delta = (long)((pos_open_price_last - pos_open_price) / _Point);
            _color = clrBlue;
            _colorLine = clrBlue;
            if( 0 > pos_open_price_delta )
                _color = clrYellow;
        }

        if( POSITION_TYPE_SELL == pos_open_type )
        {
            pos_open_price_delta = (long)((pos_open_price - pos_open_price_last) / _Point);
            _color = clrRed;
            _colorLine = clrRed;
            if( 0 > pos_open_price_delta )
                _color = clrYellow;
        }
        SetTline(0, MiddleName + "OP", 0, pos_open_time, pos_open_price, timep, pos_open_price, _colorLine, STYLE_SOLID, 3, MiddleName + "OP");
        SetRightPrice(0, middle_name + "OP", 0, timep, pos_open_price, _colorLine, "Georgia");
        SetRectangle(0, "OpenPrice", 0, time5, pos_open_price, time4, Middle[0]/*pos_open_price_last*/, _color, STYLE_SOLID, 1, "OpenPrice");

    }
    else
    {
        if( 0 == ObjectFind( 0, MiddleName + "OP") )
            ObjectDelete( 0,    MiddleName + "OP");
        if( 0 == ObjectFind( 0, middle_name + "OP") )
            ObjectDelete( 0,    middle_name + "OP");
        if( 0 == ObjectFind( 0, "OpenPrice") )
            ObjectDelete( 0,    "OpenPrice");

    } // if(PositionSelect(_Symbol))

//----
    //Print("2");
    ChartRedraw(0);

    // TODO don't do this when _Ticks Symbol
    /*
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
    */

    return(rates_total);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // int OnCalculate(const int rates_total,
//+------------------------------------------------------------------+

