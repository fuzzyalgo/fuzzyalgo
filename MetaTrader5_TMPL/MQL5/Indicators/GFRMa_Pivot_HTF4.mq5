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
#define INDICATOR_NAME      "GFRMa_Pivot_HTF3"
#define RESET               0
//+--------------------------------------------+
//| |
//+--------------------------------------------+

#include <myobjects.mqh>

//input string Symbols_Sirname = "GFRMa_Pivot_";

input uint SignalLen = 15;
uint kInputSampleAvgInSecs = SignalLen*PeriodSeconds();

input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE;
input ENUM_MA_METHOD     ma_method     = MODE_SMA;
input ENUM_STO_PRICE     sto_price     = STO_CLOSECLOSE;


color Up_Color = clrBlue;
color Dn_Color = clrRed;
color  Middle_color = clrSpringGreen; //clrBlue;

int hMA1    = INVALID_HANDLE;
int hCCI1   = INVALID_HANDLE;
int hRSI1   = INVALID_HANDLE;
int hStoch1 = INVALID_HANDLE;
int hSHL1   = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{

    ObjectsDeleteAll(0);
    ChartRedraw(0);

    hMA1 = iMA( Symbol(), Period(), SignalLen, 0, ma_method, applied_price );
    //hMA1=iCustom(Symbol(),Period(),"GRFLsqFit",s1_Samples,s2_Samples,s3_Samples,s4_Samples);
    //Ind_Handle_S1_M1_Ticks=iCustom(Symbol()/*+"_ticks"*/,PERIOD_M1,"GRFLsqFit",s1_Samples,s2_Samples,s3_Samples,s4_Samples);
    if(hMA1 == INVALID_HANDLE)
    {
        Print(" BARS hMA1 failed");
        return(INIT_FAILED);
    }

    hCCI1 = iCCI( Symbol(), Period(), SignalLen, applied_price );
    if(hCCI1 == INVALID_HANDLE)
    {
        Print(" BARS hCCI1 failed");
        return(INIT_FAILED);
    }

    hRSI1 = iRSI( Symbol(), Period(), SignalLen, applied_price );
    if(hRSI1 == INVALID_HANDLE)
    {
        Print(" BARS hRSI1 failed");
        return(INIT_FAILED);
    }

    hStoch1 = iStochastic( Symbol(), Period(), SignalLen,3,3, ma_method, sto_price );
    if(hStoch1 == INVALID_HANDLE)
    {
        Print(" BARS hStoch1 failed");
        return(INIT_FAILED);
    }

    hSHL1=iCustom(Symbol(),Period(),"size_highs_and_lows4",SignalLen);
    if(hSHL1 == INVALID_HANDLE)
    {
        Print(" BARS hMA1 failed");
        return(INIT_FAILED);
    }


    IndicatorSetString (INDICATOR_SHORTNAME, INDICATOR_NAME);
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

    if(INVALID_HANDLE != hMA1)
    {
        IndicatorRelease(hMA1);
    }
    if(INVALID_HANDLE != hCCI1)
    {
        IndicatorRelease(hCCI1);
    }
    if(INVALID_HANDLE != hRSI1)
    {
        IndicatorRelease(hRSI1);
    }
    if(INVALID_HANDLE != hStoch1)
    {
        IndicatorRelease(hStoch1);
    }
    if(INVALID_HANDLE != hSHL1)
    {
        IndicatorRelease(hSHL1);
    }

    ObjectsDeleteAll(0);
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

    if(rates_total < (int)SignalLen+10)
        return(RESET);


    if( BarsCalculated(hMA1)    < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(hCCI1)   < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(hRSI1)   < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(hStoch1) < Bars(Symbol(), Period())  )
        return(prev_calculated);
    if( BarsCalculated(hSHL1)   < Bars(Symbol(), Period())  )
        return(prev_calculated);

    MqlTick array[];
    uint gCopyTicksFlags = COPY_TICKS_INFO; // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL
    int size1    = CopyTicksRange(  Symbol(), 
                                    array, gCopyTicksFlags, 
                                    (TimeCurrent() - kInputSampleAvgInSecs   ) * 1000, 
                                    (TimeCurrent() - 0) * 1000 );
    int oc1   = 0;
    int hl1   = 0;
    double high1 = 0;
    double low1  = 1000000000;
    ExtractHighLowFromMqlTickArray( array, oc1, hl1, high1, low1 );
    int size_delta1 = (size1*hl1)/(int)kInputSampleAvgInSecs;
    
    static double iCCI1[1], iMa1[1], Middle[1], iRSI1[1], 
                  iStochMain1[1], iStochSignal1[1],
                  iHSLhighs1[1], iHSLlows1[1];

    if(CopyBuffer(hMA1, 0, 0, 1, iMa1) <= 0)
        return(RESET);
    if(CopyBuffer(hCCI1, 0, 0, 1, iCCI1) <= 0)
        return(RESET);
    if(CopyBuffer(hRSI1, 0, 0, 1, iRSI1) <= 0)
        return(RESET);

    // The buffer numbers: 0 - MAIN_LINE, 1 - SIGNAL_LINE.
    if(CopyBuffer(hStoch1, MAIN_LINE,   0, 1, iStochMain1)   <= 0)
        return(RESET);
    if(CopyBuffer(hStoch1, SIGNAL_LINE, 0, 1, iStochSignal1) <= 0)
        return(RESET);

    // The buffer numbers: 0 - price max sizes highs, 1 - price max sizes lows.
    if(CopyBuffer(hSHL1, 0, 0, 1, iHSLhighs1) <= 0)
        return(RESET);
    if(CopyBuffer(hSHL1, 1, 0, 1, iHSLlows1)  <= 0)
        return(RESET);

    int bar0 = rates_total - 1;
    int bar1 = rates_total - int(MathMax(SignalLen - 1, 0));
    MqlTick tick;
    SymbolInfoTick( Symbol(), tick );
    double ask = tick.ask;
    double bid = tick.bid;
    Middle[0]  = (ask+bid)/2;
    int spread1 = (int)((ask-bid)/ _Point);
    int ma1 = (int)((Middle[0]-iMa1[0] ) / _Point);
    
    int iHSLdelta = (int)MathAbs((iHSLhighs1[0]-iHSLlows1[0] ) / _Point);
    int iHSLBreakoutDelta = 0;
    if( (Middle[0] > iHSLhighs1[0]) &&  (Middle[0] > iHSLlows1[0]) ) {
    
        iHSLBreakoutDelta = (int)((Middle[0]-iHSLhighs1[0])/_Point);
        if( iHSLlows1[0] > iHSLhighs1[0] ) {
            iHSLBreakoutDelta = (int)((Middle[0]-iHSLlows1[0])/_Point);
        } 
    
    } else if( (Middle[0] < iHSLhighs1[0]) &&  (Middle[0] < iHSLlows1[0]) ) {

        iHSLBreakoutDelta = (int)((Middle[0]-iHSLlows1[0])/_Point);
        if( iHSLlows1[0] > iHSLhighs1[0] ) {
            iHSLBreakoutDelta = (int)((Middle[0]-iHSLhighs1[0])/_Point);
        } 
    
    } else {
            
    } // if( (Middle[0] > iHSLhighs1[0]) &&  (Middle[0] > iHSLlows1[0]) )
    
    
    string fmt = StringFormat("s: %4d*%3d  v: %6d  sto: %4d/%4d  rsi: %4d  cci: %4d  ma: %4d  oc: %4d  shl: %4d  hl: %4d  sd: %4d  shld: %4d  spread: %2d  highs: %1.5f  lows: %1.5f", 
                                PeriodSeconds(), 
                                SignalLen,
                                size1, 
                                (int)iStochMain1[0]-50,
                                (int)iStochSignal1[0]-50,
                                (int)iRSI1[0]-50,
                                (int)iCCI1[0],
                                ma1, 
                                oc1, 
                                iHSLBreakoutDelta,
                                hl1,
                                size_delta1,
                                iHSLdelta,
                                spread1,
                                iHSLhighs1[0],
                                iHSLlows1[0]);
    Print( fmt );

    //
    // calc offset for chart display
    //
    long offset = (long)(SignalLen/PeriodSeconds())*4;
    if( 1 > offset ) offset = 1;
    //Print( PeriodSeconds(), SignalLen, offset);

    //
    // green middle line
    //
    SetTline(0, "GreenMiddleLine", 0, 
        time[bar0] + 5 * PeriodSeconds()*offset, Middle[0], 
        time[bar0] -SignalLen * PeriodSeconds(), Middle[0], 
        Middle_color, STYLE_SOLID, 3, "GreenMiddleLine");
    //SetRightPrice(0, upper_name1, 0, time[bar0], iCCI1[0], Upper_color1, "Georgia");
    //SetRightPrice(0, lower_name1, 0, time[bar0], iRSI1[0], Lower_color1, "Georgia");

    //2024.06.05 13:03:07.924	GFRMa_Pivot_HTF3 (EURUSD,M1)	s:   60*15  v:    654  sto:   50/  20  rsi:    6  cci:   55  ma:    1  oc:    7  hl:   20  sd:   14
    //2024.06.05 13:03:07.938	GFRMa_Pivot_HTF3 (EURUSD,M5)	s:  300*15  v:   4415  sto:   36/  30  rsi:   -8  cci:   -4  ma:   -1  oc:  -75  hl:  123  sd:  120
    //2024.06.05 13:03:07.946	GFRMa_Pivot_HTF3 (EURUSD,M15)	s:  900*15  v:  16908  sto:  -28/ -40  rsi:  -11  cci:  -74  ma:  -32  oc:  -55  hl:  150  sd:  187
    //2024.06.05 13:03:07.952	GFRMa_Pivot_HTF3 (EURUSD,H1)	s: 3600*15  v:  40016  sto:  -39/ -30  rsi:  -10  cci: -137  ma:  -87  oc: -114  hl:  221  sd:  163


    //
    // stochastic main rectangle
    // 
    double stomain = (Middle[0]-((iStochMain1[0]-50)* _Point));
    if( 0 < ((int)iStochMain1[0]-50) )
        SetRectangle(0, "iStoMain1", 0, 
                        time[bar0]-14*PeriodSeconds()*offset, stomain, 
                        time[bar0]-12*PeriodSeconds()*offset, Middle[0], 
                        Up_Color, STYLE_SOLID, 1, "iStoMain1");
    else
        SetRectangle(0, "iStoMain1", 0, 
                        time[bar0]-14*PeriodSeconds()*offset, stomain, 
                        time[bar0]-12*PeriodSeconds()*offset, Middle[0], 
                        Dn_Color, STYLE_SOLID, 1, "iStoMain1");
                
    fmt = StringFormat("STOM%4d", (int)iStochMain1[0]-50);
    SetRightText (0, "iStoMain1Txt", 0, 
        time[bar0]-14*PeriodSeconds()*offset, stomain - (0*_Point), clrBlack, "Courier", fmt);

    //
    // stochastic signal rectangle
    // 
    double stosignal = (Middle[0]-((iStochSignal1[0]-50)* _Point));
    if( 0 < ((int)iStochSignal1[0]-50) )
        SetRectangle(0, "iStoSignal1", 0, 
                        time[bar0]-12*PeriodSeconds()*offset, stosignal, 
                        time[bar0]-10*PeriodSeconds()*offset, Middle[0], 
                        Up_Color, STYLE_SOLID, 1, "iStoSignal1");
    else
        SetRectangle(0, "iStoSignal1", 0, 
                        time[bar0]-12*PeriodSeconds()*offset, stosignal, 
                        time[bar0]-10*PeriodSeconds()*offset, Middle[0], 
                        Dn_Color, STYLE_SOLID, 1, "iStoSignal1");

    fmt = StringFormat("STOS%4d", (int)iStochSignal1[0]-50);
    SetRightText (0, "iStoSignal1Txt", 0, 
        time[bar0]-12*PeriodSeconds()*offset, stosignal - (0*_Point), clrBlack, "Courier", fmt);

    //
    // rsi rectangle
    //
    double rsi = (Middle[0]-((iRSI1[0]-50)* _Point));
    if( 0 < ((int)iRSI1[0]-50) )
        SetRectangle(0, "iRSI1", 0, 
                        time[bar0]-10*PeriodSeconds()*offset, rsi, 
                        time[bar0]-8*PeriodSeconds()*offset, Middle[0], 
                        Up_Color, STYLE_SOLID, 1, "iRSI1");
    else
        SetRectangle(0, "iRSI1", 0, 
                        time[bar0]-10*PeriodSeconds()*offset, rsi, 
                        time[bar0]-8*PeriodSeconds()*offset, Middle[0], 
                        Dn_Color, STYLE_SOLID, 1, "iRSI1");

    fmt = StringFormat("RSI %4d", (int)iRSI1[0]-50);
    SetRightText (0, "iRSI1Txt", 0, 
        time[bar0]-10*PeriodSeconds()*offset, rsi - (0*_Point), clrBlack, "Courier", fmt);

    //
    // cci rectangle
    //
    double cci = (Middle[0]-(iCCI1[0]* _Point));
    if( 0 < (int)iCCI1[0] )
        SetRectangle(0, "iCCI1", 0, 
                        time[bar0]-8*PeriodSeconds()*offset, cci, 
                        time[bar0]-6*PeriodSeconds()*offset, Middle[0], 
                        Up_Color, STYLE_SOLID, 1, "iCCI1");
    else
        SetRectangle(0, "iCCI1", 0, 
                        time[bar0]-8*PeriodSeconds()*offset, cci, 
                        time[bar0]-6*PeriodSeconds()*offset, Middle[0],
                        Dn_Color, STYLE_SOLID, 1, "iCCI1");
                        
    fmt = StringFormat("CCI %4d", (int)iCCI1[0]);
    SetRightText (0, "iCCI1Txt", 0, 
        time[bar0]-8*PeriodSeconds()*offset, cci - (0*_Point), clrBlack, "Courier", fmt);

    //
    // ma rectangle
    //
    if( iMa1[0] < Middle[0] )
        SetRectangle(0, "iMA1", 0, 
                        time[bar0]-6*PeriodSeconds()*offset, iMa1[0], 
                        time[bar0]-4*PeriodSeconds()*offset, Middle[0], 
                        Up_Color, STYLE_SOLID, 1, "iMA1");
    else
        SetRectangle(0, "iMA1", 0, 
                        time[bar0]-6*PeriodSeconds()*offset, iMa1[0], 
                        time[bar0]-4*PeriodSeconds()*offset, Middle[0], 
                        Dn_Color, STYLE_SOLID, 1, "iMA1");

    fmt = StringFormat("MA  %4d", ma1);
    SetRightText (0, "iMa1Txt", 0, 
        time[bar0]-6*PeriodSeconds()*offset, iMa1[0] - (0*_Point), clrBlack, "Courier", fmt);

    //
    // oc recatangle
    //
    if( 0 < oc1 )
        SetRectangle(0, "iOC1", 0, 
                        time[bar0]-4*PeriodSeconds()*offset, array[0].ask, 
                        time[bar0]-2*PeriodSeconds()*offset, Middle[0],
                        Up_Color, STYLE_SOLID, 1, "iOC1");
    else
        SetRectangle(0, "iOC1", 0, 
                        time[bar0]-4*PeriodSeconds()*offset, array[0].ask, 
                        time[bar0]-2*PeriodSeconds()*offset, Middle[0],
                        Dn_Color, STYLE_SOLID, 1, "iOC1");

    fmt = StringFormat("OC  %4d", oc1);
    SetRightText (0, "iOc1Txt", 0, 
        time[bar0]-4*PeriodSeconds()*offset, array[0].ask - (0*_Point), clrBlack, "Courier", fmt);


    //
    // shl (size high low custom) rectangle
    //  breakout - outside of high and low - the delta between high/low and middle
    //
    double hsl = 0;
    if( (Middle[0] > iHSLhighs1[0]) &&  (Middle[0] > iHSLlows1[0]) ) {
    
        hsl = iHSLhighs1[0];
        if( iHSLlows1[0] > iHSLhighs1[0] ) {
            hsl = iHSLlows1[0];
        } 
        SetRectangle(0, "iHSL",   0, 
                            time[bar0]-2*PeriodSeconds()*offset, hsl , 
                            time[bar0]-0*PeriodSeconds()*offset, Middle[0] , 
                            Up_Color, STYLE_SOLID, 1, "iHSL");
    
    } else if( (Middle[0] < iHSLhighs1[0]) &&  (Middle[0] < iHSLlows1[0]) ) {

        hsl = iHSLlows1[0];
        if( iHSLlows1[0] > iHSLhighs1[0] ) {
            hsl = iHSLhighs1[0];
        } 
        SetRectangle(0, "iHSL",   0, 
                            time[bar0]-2*PeriodSeconds()*offset, hsl , 
                            time[bar0]-0*PeriodSeconds()*offset, Middle[0] , 
                            Dn_Color, STYLE_SOLID, 1, "iHSL");
    
    } else {
    
        if( 0 == ObjectFind( 0, "iHSL") )
            ObjectDelete( 0,    "iHSL");
        if( 0 == ObjectFind( 0, "iSHL1Txt") )
            ObjectDelete( 0,    "iSHL1Txt");
            
    } // if( (Middle[0] > iHSLhighs1[0]) &&  (Middle[0] > iHSLlows1[0]) )

    if( 0 == ObjectFind( 0, "iHSL") ) {
        fmt = StringFormat("SHL %4d", iHSLBreakoutDelta);
        SetRightText (0, "iSHL1Txt", 0, 
            time[bar0]-2*PeriodSeconds()*offset, hsl, clrBlack, "Courier", fmt);
    }


    //
    // hl rectangle
    // 
    SetRectangle(0, "HlRectangle", 0, 
                        time[bar0]+2*PeriodSeconds()*offset, (Middle[0] - (hl1*_Point)/2), 
                        time[bar0]+3*PeriodSeconds()*offset, (Middle[0] + (hl1*_Point)/2), 
                        clrLightGreen, STYLE_SOLID, 1, "HlRectangle");
                        
    fmt = StringFormat("%4d", hl1);
    SetRightText (0, "HlRectangleTxt", 0, 
            time[bar0]+2*PeriodSeconds()*offset, (Middle[0] + (hl1*_Point)/2), clrBlack, "Courier", fmt);
                        
    //
    // sd rectangle
    // 
    SetRectangle(0, "SdRectangle",   0, 
                        time[bar0]+3*PeriodSeconds()*offset, (Middle[0] - (size_delta1*_Point)/2 ), 
                        time[bar0]+4*PeriodSeconds()*offset, (Middle[0] + (size_delta1*_Point)/2 ), 
                        clrGreen, STYLE_SOLID, 1, "SdRectangle");

    fmt = StringFormat("%4d", size_delta1);
    SetRightText (0, "SdRectangleTxt", 0, 
            time[bar0]+3*PeriodSeconds()*offset, (Middle[0] + (size_delta1*_Point)/2), clrBlack, "Courier", fmt);

    //
    // shl (size high low custom) rectangle
    //    the delta between high and low
    // 
    SetRectangle(0, "ShlRectangle",   0, 
                        time[bar0]+4*PeriodSeconds()*offset, (Middle[0] - (iHSLdelta*_Point)/2 ), 
                        time[bar0]+5*PeriodSeconds()*offset, (Middle[0] + (iHSLdelta*_Point)/2 ), 
                        clrYellowGreen, STYLE_SOLID, 1, "ShlRectangle");

    fmt = StringFormat("%4d", iHSLdelta);
    SetRightText (0, "ShlRectangleTxt", 0, 
            time[bar0]+4*PeriodSeconds()*offset, (Middle[0] + (iHSLdelta*_Point)/2), clrBlack, "Courier", fmt);

    //
    // spread rectangle
    //
    SetRectangle(0, "SpreadRectangle",   0, 
                        time[bar0]+5*PeriodSeconds()*offset, ask , 
                        time[bar0]+6*PeriodSeconds()*offset, bid , 
                        clrYellow, STYLE_SOLID, 1, "SpreadRectangle");

    fmt = StringFormat("%4d", spread1);
    SetRightText (0, "SpreadRectangleTxt", 0, 
            time[bar0]+5*PeriodSeconds()*offset, ask, clrBlack, "Courier", fmt);

    //fmt = StringFormat("%3d %3d %3d", hl1, (int)(size1/hl1), oc1);
    //SetRightText (0, middle_name+"1", 0, time[bar0]-10*PeriodSeconds(), Middle[0] + (0*_Point), clrBlack, "Courier", fmt);



    if(PositionSelect(_Symbol))
    {
        int _color = clrWhite;
        int _colorLine = clrWhite;
        double pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        double pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        long pos_open_time = PositionGetInteger(POSITION_TIME);
        long posOpenDT = ((TimeCurrent() - pos_open_time)*hl1)/kInputSampleAvgInSecs;
        //Print((long)TimeCurrent(), " ", pos_open_time, " ", TimeCurrent()-pos_open_time, " ", posOpenDT);
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
        SetTline(0, "OPLine", 0, 
            pos_open_time, pos_open_price, 
            time[bar0] + 3 * PeriodSeconds()*offset, pos_open_price, 
            _colorLine, STYLE_SOLID, 3, "OPLine");
        SetRightPrice(0, "OPpriceTxt", 0,  
            time[bar0] + 3 * PeriodSeconds()*offset, pos_open_price, 
            _colorLine, "Georgia");
        SetRectangle(0, "OpenPrice", 0, 
            time[bar0]+0*PeriodSeconds()*offset, pos_open_price, 
            time[bar0]+1*PeriodSeconds()*offset, Middle[0]/*pos_open_price_last*/,
             _color, STYLE_SOLID, 1, "OpenPrice");
        
        if( Middle[0] >  pos_open_price ) {
            SetRectangle(0, "OpenPriceTime", 0, 
                time[bar0]+0*PeriodSeconds()*offset, pos_open_price, 
                time[bar0]+1*PeriodSeconds()*offset, pos_open_price-posOpenDT*_Point, 
                clrGreenYellow, STYLE_SOLID, 1, "OpenPriceTime");
        } else {
            SetRectangle(0, "OpenPriceTime", 0, 
                time[bar0]+0*PeriodSeconds()*offset, pos_open_price, 
                time[bar0]+1*PeriodSeconds()*offset, pos_open_price+posOpenDT*_Point, 
                clrGreenYellow, STYLE_SOLID, 1, "OpenPriceTime");
        }
        
        MqlTick array2[];
        int size2    = CopyTicksRange(  Symbol(), 
                                        array2, COPY_TICKS_INFO, 
                                        (pos_open_time * 1000 ), 
                                        (TimeCurrent() * 1000 ));
        int oc2   = 0;
        int hl2   = 0;
        double high2 = 0;
        double low2  = 1000000000;
        ExtractHighLowFromMqlTickArray( array2, oc2, hl2, high2, low2 );
        int size_delta2 = (size2*hl2)/(int)kInputSampleAvgInSecs;
        //string fmt2 = StringFormat("%4d  v: %6d  oc: %4d  hl: %4d  sd: %4d", PeriodSeconds(), size2, oc2, hl2,size_delta2);
        //Print( fmt2 );
        SetRectangle(0, "OpenPriceHigh", 0, 
            time[bar0]+1*PeriodSeconds()*offset, pos_open_price, 
            time[bar0]+2*PeriodSeconds()*offset, high2, 
            clrBlueViolet, STYLE_SOLID, 1, "OpenPriceHigh");
        SetRectangle(0, "OpenPriceLow" , 0, 
            time[bar0]+1*PeriodSeconds()*offset, pos_open_price, 
            time[bar0]+2*PeriodSeconds()*offset, low2,  
            clrViolet, STYLE_SOLID, 1, "OpenPriceLow");

    }
    else
    {
        if( 0 == ObjectFind( 0, "OPLine") )
            ObjectDelete( 0,    "OPLine");
        if( 0 == ObjectFind( 0, "OPpriceTxt") )
            ObjectDelete( 0,    "OPpriceTxt");
        if( 0 == ObjectFind( 0, "OpenPrice") )
            ObjectDelete( 0,    "OpenPrice");
        if( 0 == ObjectFind( 0, "OpenPriceTime") )
            ObjectDelete( 0,    "OpenPriceTime");
        if( 0 == ObjectFind( 0, "OpenPriceHigh") )
            ObjectDelete( 0,    "OpenPriceHigh");
        if( 0 == ObjectFind( 0, "OpenPriceLow") )
            ObjectDelete( 0,    "OpenPriceLow");

    } // if(PositionSelect(_Symbol))

//----
    //Print("2");
    //ChartRedraw(0);

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExtractHighLowFromMqlTickArray( const MqlTick& mqltickarray[], int& OC, int& HL, double& high, double& low )
{
    //double high = 0;
    //double low  = 1000000000;
    int size = ArraySize( mqltickarray );

    HL = 0;
    OC = 0;

    if( 0 < size )
    {
        MqlTick t0 = mqltickarray[size - 1];
        if(t0.ask == 0 || t0.bid == 0 || t0.ask < t0.bid)
            return;
        MqlTick tstart = mqltickarray[0];
        if(tstart.ask == 0 || tstart.bid == 0 || tstart.ask < tstart.bid)
            return;
        OC = (int)(( ((t0.ask + t0.bid) / 2 ) - ((tstart.ask + tstart.bid) / 2 ) ) / _Point);
    }
    else
    {
        return;
    }

    for( int cnt = 0; cnt < size; cnt++ )
    {
        MqlTick t = mqltickarray[cnt];
        // sanity check
        if(t.ask == 0 || t.bid == 0 || t.ask < t.bid)
            continue;
        if( high < t.ask )
            high = t.ask;
        if( low  > t.bid )
            low  = t.bid;

    } // for( cnt = 0; cnt < size; cnt++ )

    HL = (int)(( high - low ) / _Point);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void ExtractHighLowFromMqlTickArray( const MqlTick& mqltickarray[], int& OC, int& HL)
//+------------------------------------------------------------------+
