//+------------------------------------------------------------------+
//|                                         SIZE_HIGHS_AND_LOWS4.mq5 |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2024, André Howe"
#property link          "andrehowe.com"
#property description   "GFRMa_Pivot_HTF4.mq5"
#property version       "1.0"
//+--------------------------------------------+
//|  |
//+--------------------------------------------+

#property indicator_chart_window
#property indicator_buffers 18
#property indicator_plots   18
//---
#property indicator_type13  DRAW_LINE
#property indicator_type14  DRAW_LINE
//---
#property indicator_color13 clrBlue
#property indicator_color14 clrRed
//+--------------------------------------------+
//| |
//+--------------------------------------------+
#define INDICATOR_NAME      "GFRMa_Pivot_HTF4"
//+--------------------------------------------+
//| |
//+--------------------------------------------+

input uint SignalNumber     = 1;
input uint SignalLen        = 15;
uint kInputSampleAvgInSecs  = SignalLen*PeriodSeconds();

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

//--- buffers
double vb[], sto1b[], sto2b[], rsib[], ccib[], mab[], ocb[], shlb[], hlb[], sdb[], shldb[], spreadb[];
double highs[],lows[];
double HighBuffer[],LowBuffer[];
double maxHighBuffer[], maxLowBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{

    ObjectsDeleteAll(0);
    ChartRedraw(0);
    
    if( 0 == SignalNumber ) {
        GlobalVariablesDeleteAll();
    }

    if( 0 < SignalNumber ) {

        hMA1 = iMA( Symbol(), Period(), SignalLen, 0, ma_method, applied_price );
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
    
    }// if( 0 < SignalNumber ) 

    //--- buffers for calculations and plot
    //double vb[], sto1b[], sto2b[], rsib[], ccib[], mab[], ocb[], shlb[], hlb[], sdb[], shldb[], spreadb[];
    SetIndexBuffer( 0,vb,       INDICATOR_DATA);
    SetIndexBuffer( 1,sto1b,    INDICATOR_DATA);
    SetIndexBuffer( 2,sto2b,    INDICATOR_DATA);
    SetIndexBuffer( 3,rsib,     INDICATOR_DATA);
    SetIndexBuffer( 4,ccib,     INDICATOR_DATA);
    SetIndexBuffer( 5,mab,      INDICATOR_DATA);
    SetIndexBuffer( 6,ocb,      INDICATOR_DATA);
    SetIndexBuffer( 7,shlb,     INDICATOR_DATA);
    SetIndexBuffer( 8,hlb,      INDICATOR_DATA);
    SetIndexBuffer( 9,sdb,      INDICATOR_DATA);
    SetIndexBuffer(10,shldb,    INDICATOR_DATA);
    SetIndexBuffer(11,spreadb,  INDICATOR_DATA);
    SetIndexBuffer(12,highs,    INDICATOR_DATA);
    SetIndexBuffer(13,lows,     INDICATOR_DATA);
    SetIndexBuffer(14,HighBuffer,INDICATOR_CALCULATIONS);
    SetIndexBuffer(15,LowBuffer,INDICATOR_CALCULATIONS);
    SetIndexBuffer(16,maxHighBuffer,INDICATOR_CALCULATIONS);
    SetIndexBuffer(17,maxLowBuffer,INDICATOR_CALCULATIONS);
    //--- set plot draw begin (0 1 2 3...N )
    PlotIndexSetInteger(12,PLOT_DRAW_BEGIN,SignalLen);
    PlotIndexSetInteger(13,PLOT_DRAW_BEGIN,SignalLen);
    //--- line style
    PlotIndexSetInteger(12,PLOT_LINE_STYLE,STYLE_DASHDOTDOT);
    //--- line width
    PlotIndexSetInteger(12,PLOT_LINE_WIDTH,1);
    //---
    PlotIndexSetInteger(13,PLOT_LINE_STYLE,STYLE_DASHDOTDOT);
    PlotIndexSetInteger(13,PLOT_LINE_WIDTH,1);


    //--- indicator label
    PlotIndexSetString( 0,PLOT_LABEL,"v");
    PlotIndexSetString( 1,PLOT_LABEL,"sto1");
    PlotIndexSetString( 2,PLOT_LABEL,"sto2");
    PlotIndexSetString( 3,PLOT_LABEL,"rsi");
    PlotIndexSetString( 4,PLOT_LABEL,"cci");
    PlotIndexSetString( 5,PLOT_LABEL,"ma");
    PlotIndexSetString( 6,PLOT_LABEL,"oc");
    PlotIndexSetString( 7,PLOT_LABEL,"shl");
    PlotIndexSetString( 8,PLOT_LABEL,"hl");
    PlotIndexSetString( 9,PLOT_LABEL,"sd");
    PlotIndexSetString(10,PLOT_LABEL,"shld");
    PlotIndexSetString(11,PLOT_LABEL,"spread");
    PlotIndexSetString(12,PLOT_LABEL,"highs");
    PlotIndexSetString(13,PLOT_LABEL,"lows");
    
	PlotIndexSetDouble( 0,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 1,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 2,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 3,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 4,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 5,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 6,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 7,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 8,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 9,  PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 10, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 11, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 12, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 13, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 14, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 15, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 16, PLOT_EMPTY_VALUE, EMPTY_VALUE );
	PlotIndexSetDouble( 17, PLOT_EMPTY_VALUE, EMPTY_VALUE );

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

    if( 0 < SignalNumber ) {

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
      
    } // if( 0 < SignalNumber )

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


    //--- checking of bars
    if(rates_total < (60*24))
        return(0);
    int bar0 = rates_total - 1;

    //
    // variables start
    //
    static double iCCI1[1], iMa1[1], Middle[1], iRSI1[1], 
                  iStochMain1[1], iStochSignal1[1],
                  iHSLhighs1[1], iHSLlows1[1];
                  
    
    MqlTick tickArray1[];
    int size1    = CopyTicksRange(  Symbol(), 
                    tickArray1, COPY_TICKS_INFO, // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL 
                    (TimeCurrent() - kInputSampleAvgInSecs   ) * 1000, 
                    (TimeCurrent() - 0) * 1000 );
    int oc1   = 0;
    int hl1   = 0;
    double high1 = 0;
    double low1  = 1000000000;
    ExtractHighLowFromMqlTickArray( tickArray1, oc1, hl1, high1, low1 );
    int size_delta1 = (size1*hl1)/(int)kInputSampleAvgInSecs;

    MqlTick tick;
    SymbolInfoTick( Symbol(), tick );
    double ask = tick.ask;
    double bid = tick.bid;
    Middle[0]  = (ask+bid)/2;
    int spread1 = (int)((ask-bid)/ _Point);
    int ma1 = 0;
    int iHSLdelta = 0;
    int iHSLBreakoutDelta = 0;

    //
    // variables end
    //
    

    if( 0 < SignalNumber ) {
    
        int cnt;
        int limit = rates_total-1*(int)SignalLen-10;
    
        //--- start SIZE HIGHS / LOWS4 calculations
        for(cnt=limit+1; cnt<rates_total; cnt++) {
            //--- size of highs
            if(close[cnt]>open[cnt]) {// bullish candle
                //--- calculate the body
                HighBuffer[cnt]=ND_dgt(close[cnt],_Digits)-ND_dgt(open[cnt],_Digits);
                maxHighBuffer[cnt]=ND_dgt(Highest(HighBuffer,SignalLen,cnt),_Digits);
                LowBuffer[cnt]=0.0;
                maxLowBuffer[cnt]=ND_dgt(Lowest(LowBuffer,SignalLen,cnt),_Digits);
                
            } else if(close[cnt]<open[cnt]) { // bearish candle
                LowBuffer[cnt]=ND_dgt(close[cnt],_Digits)-ND_dgt(open[cnt],_Digits);
                maxLowBuffer[cnt]=ND_dgt(Lowest(LowBuffer,SignalLen,cnt),_Digits);
                HighBuffer[cnt]=0.0;
                maxHighBuffer[cnt]=ND_dgt(Highest(HighBuffer,SignalLen,cnt),_Digits);
                
            } else {
                HighBuffer[cnt]=0.0;
                maxHighBuffer[cnt]=maxHighBuffer[cnt-1];
                LowBuffer[cnt]=0.0;
                maxLowBuffer[cnt]=maxLowBuffer[cnt-1];
                
            } // if(close[cnt]>open[cnt])
            
            if( maxHighBuffer[cnt] > maxHighBuffer[cnt-1] ) {
                highs[cnt] = high[cnt];
                
            } else {
                highs[cnt] = highs[cnt-1];
                
            }
            
            if( maxLowBuffer[cnt] < maxLowBuffer[cnt-1] ) {
                lows[cnt] = low[cnt];
                
            } else {
                lows[cnt] = lows[cnt-1];
            }
            
        } // for(cnt=limit; cnt<rates_total; cnt++)
        //--- end SIZE HIGHS / LOWS4 calculations
    
    
        if(CopyBuffer(hMA1, 0, 0, 1, iMa1) <= 0)
            return(0);
        if(CopyBuffer(hCCI1, 0, 0, 1, iCCI1) <= 0)
            return(0);
        if(CopyBuffer(hRSI1, 0, 0, 1, iRSI1) <= 0)
            return(0);
    
        // The buffer numbers: 0 - MAIN_LINE, 1 - SIGNAL_LINE.
        if(CopyBuffer(hStoch1, MAIN_LINE,   0, 1, iStochMain1)   <= 0)
            return(0);
        if(CopyBuffer(hStoch1, SIGNAL_LINE, 0, 1, iStochSignal1) <= 0)
            return(0);
            
        /*hSHL1=iCustom(Symbol(),Period(),"size_highs_and_lows4",SignalLen);
        if(hSHL1 == INVALID_HANDLE) {
            // The buffer numbers: 0 - price max sizes highs, 1 - price max sizes lows.
            if(CopyBuffer(hSHL1, 0, 0, 1, iHSLhighs1) <= 0)
                Print(" hSHL1 failed");
            if(CopyBuffer(hSHL1, 1, 0, 1, iHSLlows1)  <= 0)
                Print(" hSHL1 failed");
        }*/
    
        iHSLhighs1[0] = highs[rates_total-1];
        iHSLlows1 [0] = lows [rates_total-1];
    
        ma1 = (int)((Middle[0]-iMa1[0] ) / _Point);
        
        iHSLdelta = (int)MathAbs((iHSLhighs1[0]-iHSLlows1[0] ) / _Point);
        iHSLBreakoutDelta = 0;
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
        
    } // if( 0 < SignalNumber ) 
    
    if( 0 == SignalNumber ) {
    
        string strnum = IntegerToString(SignalNumber);
        string strlen = IntegerToString(SignalLen);
        uint idx = SignalNumber;
        uint cnt = 0; 
        
        struct sGlobVar { 
            string key;
            double val;
        }; 
        sGlobVar globVarArr[5][16]; 
        
        for( idx = 1; idx < 5; idx++ ) {
        
            cnt = 0; 
            globVarArr[idx][cnt].key = "SignalNumber_"+IntegerToString(idx)+"_SignalLen";
            bool OK = GlobalVariableGet(globVarArr[idx][cnt].key, globVarArr[idx][cnt].val );
            if( false == OK ) {
                Print( "ERROR: could not get GlobalVariableGet for: " + globVarArr[idx][cnt].key);
                continue;
            }
            
            strlen = DoubleToString(globVarArr[idx][cnt].val,0);
            cnt++;

            globVarArr[idx][cnt++].key = strlen + "_s";
            globVarArr[idx][cnt++].key = strlen + "_v";
            globVarArr[idx][cnt++].key = strlen + "_sto_main";
            globVarArr[idx][cnt++].key = strlen + "_sto_signal";
            globVarArr[idx][cnt++].key = strlen + "_rsi";
            globVarArr[idx][cnt++].key = strlen + "_cci";
            globVarArr[idx][cnt++].key = strlen + "_ma";
            globVarArr[idx][cnt++].key = strlen + "_oc";
            globVarArr[idx][cnt++].key = strlen + "_shl";
            globVarArr[idx][cnt++].key = strlen + "_hl";
            globVarArr[idx][cnt++].key = strlen + "_sd";
            globVarArr[idx][cnt++].key = strlen + "_shld";
            globVarArr[idx][cnt++].key = strlen + "_spread";
            globVarArr[idx][cnt++].key = strlen + "_highs";
            globVarArr[idx][cnt++].key = strlen + "_lows";

            for( cnt = 1; cnt < 16; cnt ++ ) {
                bool OK = GlobalVariableGet(globVarArr[idx][cnt].key, globVarArr[idx][cnt].val );
                if( false == OK ) Print( "ERROR: could not get GlobalVariableGet for: " + globVarArr[idx][cnt].key);
            } // for( cnt = 0; cnt < 15; cnt ++ )
        
        } // for( idx = 1; idx < 5; idx++ )
        
        cnt = 0; 
        idx = SignalNumber;

        // write the SignalLen into the global index of the SignalNumber    
        //  n: 4  -> SignalNumber: 4 and SignalLen: 240 -->   SignalNumber_4_SignalLen: 240
        globVarArr[idx][cnt].key = "SignalNumber_"+strnum+"_SignalLen";
        globVarArr[idx][cnt].val = SignalLen;
        cnt++;
        
        // 1.) TotalSeconds - s:   60*240   -   PeriodSeconds()*SignalLen - (EURUSD,M1) -> 60 seconds period
        globVarArr[idx][cnt].key = strlen + "_s";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        cnt++;
        
        // 2.) ticks per TotalSeconds - v:   9970 
        globVarArr[idx][cnt].key = strlen + "_v";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        size1 = (int)globVarArr[idx][cnt].val;
        cnt++;
    
        // 3.) sto main per TotalSeconds - sto:   45/  46
        globVarArr[idx][cnt].key = strlen + "_sto_main";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iStochMain1[0] = (int)globVarArr[idx][cnt].val + 50;
        cnt++;
    
        // 4.) sto signal per TotalSeconds - sto:   45/  46
        globVarArr[idx][cnt].key = strlen + "_sto_signal";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iStochSignal1[0] = (int)globVarArr[idx][cnt].val + 50;
        cnt++;
    
        // 5.) rsi per TotalSeconds - rsi:    4
        globVarArr[idx][cnt].key = strlen + "_rsi";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iRSI1[0] = (int)globVarArr[idx][cnt].val + 50;
        cnt++;
    
        // 6.) cci per TotalSeconds - cci:  173
        globVarArr[idx][cnt].key = strlen + "_cci";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iCCI1[0] = (int)globVarArr[idx][cnt].val;
        cnt++;
    
        // 7.) ma per TotalSeconds - ma:   38
        globVarArr[idx][cnt].key = strlen + "_ma";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        ma1 = (int)globVarArr[idx][cnt].val;
        cnt++;
    
        // 8.) oc per TotalSeconds - oc:   75
        globVarArr[idx][cnt].key = strlen + "_oc";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        oc1 = (int)globVarArr[idx][cnt].val;
        cnt++;
    
        // 9.) shl per TotalSeconds - shl:    0
        globVarArr[idx][cnt].key = strlen + "_shl";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iHSLBreakoutDelta = (int)globVarArr[idx][cnt].val; 
        cnt++;
    
        // 10.) hl per TotalSeconds - hl:   89
        globVarArr[idx][cnt].key = strlen + "_hl";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        hl1 = (int)globVarArr[idx][cnt].val; 
        cnt++;
    
        // 11.) sd per TotalSeconds - sd:   61
        globVarArr[idx][cnt].key = strlen + "_sd";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        size_delta1 = (int)globVarArr[idx][cnt].val; 
        cnt++;
    
        // 12.) shld per TotalSeconds - shld:  150
        globVarArr[idx][cnt].key = strlen + "_shld";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iHSLdelta = (int)globVarArr[idx][cnt].val; 
        cnt++;
    
        // 13.) spread per TotalSeconds - spread:  2
        globVarArr[idx][cnt].key = strlen + "_spread";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        spread1 = (int)globVarArr[idx][cnt].val; 
        cnt++;
    
        // 14.) highs per TotalSeconds - highs: 1.07205
        globVarArr[idx][cnt].key = strlen + "_highs";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iHSLhighs1[0] = globVarArr[idx][cnt].val; 
        highs[rates_total-1] = globVarArr[idx][cnt].val; 
        cnt++;
    
        // 15.) lows per TotalSeconds - lows: 1.07055
        globVarArr[idx][cnt].key = strlen + "_lows";
        globVarArr[idx][cnt].val = (globVarArr[1][cnt].val+globVarArr[2][cnt].val+globVarArr[3][cnt].val+globVarArr[4][cnt].val)/4;
        iHSLlows1[0] = globVarArr[idx][cnt].val; 
        lows[rates_total-1] = globVarArr[idx][cnt].val; 
        cnt++;
    
        for( cnt = 0; cnt < 16; cnt ++ ) {
            datetime dtc = GlobalVariableSet(globVarArr[idx][cnt].key, globVarArr[idx][cnt].val );
            if( 0 == dtc ) Print( "ERROR: could not set GlobalVariableSet for: " + globVarArr[idx][cnt].key);
        }
    } // if( 0 == SignalNumber )
    
        
    //double vb[], sto1b[], sto2b[], rsib[], ccib[], mab[], ocb[], shlb[], hlb[], sdb[], shldb[], spreadb[];
    vb[rates_total-1]       = size1;
    sto1b[rates_total-1]    = iStochMain1[0]-50;
    sto2b[rates_total-1]    = iStochSignal1[0]-50;
    rsib[rates_total-1]     = iRSI1[0]-50;
    ccib[rates_total-1]     = iCCI1[0];
    mab[rates_total-1]      = ma1;
    ocb[rates_total-1]      = oc1;
    shlb[rates_total-1]     = iHSLBreakoutDelta;
    hlb[rates_total-1]      = hl1;
    sdb[rates_total-1]      = size_delta1;
    shldb[rates_total-1]    = iHSLdelta;
    spreadb[rates_total-1]  = spread1;
    
    /* // move below open order analysis down below
    string fmt = StringFormat("n: %d  s: %4d*%3d  v: %6d  sto: %4d/%4d  rsi: %4d  cci: %4d  ma: %4d  oc: %4d  shl: %4d  hl: %4d  sd: %4d  shld: %4d  spread: %2d  highs: %1.5f  lows: %1.5f", 
                                SignalNumber,
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
    */
    
    /*
    //
    // set global variables
    //
    2024.06.21 08:12:50.238	GFRMa_Pivot_HTF4 (EURUSD,M1) n: 4  s:   60*240  v:   9970  sto:   45/  46  rsi:    4  cci:  173  ma:   38  oc:   75  shl:    0  hl:   89  sd:   61  shld:  150  spread:  2  highs: 1.07205  lows: 1.07055
    2024.06.21 08:12:50.245	GFRMa_Pivot_HTF4 (EURUSD,M1) n: 3  s:   60* 60  v:   3762  sto:   42/  43  rsi:    7  cci:  113  ma:   19  oc:   23  shl:    0  hl:   60  sd:   62  shld:   39  spread:  2  highs: 1.07205  lows: 1.07165
    2024.06.21 08:12:50.247	GFRMa_Pivot_HTF4 (EURUSD,M1) n: 2  s:   60* 15  v:   1759  sto:   40/  43  rsi:   13  cci:  111  ma:   17  oc:   28  shl:    0  hl:   42  sd:   82  shld:   39  spread:  2  highs: 1.07205  lows: 1.07165
    2024.06.21 08:12:50.248	GFRMa_Pivot_HTF4 (EURUSD,M1) n: 1  s:   60*  4  v:    517  sto:   25/  36  rsi:   17  cci:    0  ma:    1  oc:   22  shl:    0  hl:   26  sd:   56  shld:    8  spread:  2  highs: 1.07205  lows: 1.07196
    
    */  
      
    if( 0 < SignalNumber ) {
    
        string strnum = IntegerToString(SignalNumber);
        string strlen = IntegerToString(SignalLen);
        uint idx = SignalNumber;
        uint cnt = 0; 
        
        struct sGlobVar { 
            string key;
            double val;
        }; 
        sGlobVar globVarArr[5][16]; 
        
        // write the SignalLen into the global index of the SignalNumber    
        //  n: 4  -> SignalNumber: 4 and SignalLen: 240 -->   SignalNumber_4_SignalLen: 240
        globVarArr[idx][cnt].key = "SignalNumber_"+strnum+"_SignalLen";
        globVarArr[idx][cnt].val = SignalLen;
        cnt++;
        
        // 1.) TotalSeconds - s:   60*240   -   PeriodSeconds()*SignalLen - (EURUSD,M1) -> 60 seconds period
        globVarArr[idx][cnt].key = strlen + "_s";
        globVarArr[idx][cnt].val = (PeriodSeconds()*SignalLen);
        cnt++;
        
        // 2.) ticks per TotalSeconds - v:   9970 
        globVarArr[idx][cnt].key = strlen + "_v";
        globVarArr[idx][cnt].val = (size1);
        cnt++;
    
        // 3.) sto main per TotalSeconds - sto:   45/  46
        globVarArr[idx][cnt].key = strlen + "_sto_main";
        globVarArr[idx][cnt].val = ((int)iStochMain1[0]-50);
        cnt++;
    
        // 4.) sto signal per TotalSeconds - sto:   45/  46
        globVarArr[idx][cnt].key = strlen + "_sto_signal";
        globVarArr[idx][cnt].val = ((int)iStochSignal1[0]-50);
        cnt++;
    
        // 5.) rsi per TotalSeconds - rsi:    4
        globVarArr[idx][cnt].key = strlen + "_rsi";
        globVarArr[idx][cnt].val = ((int)iRSI1[0]-50);
        cnt++;
    
        // 6.) cci per TotalSeconds - cci:  173
        globVarArr[idx][cnt].key = strlen + "_cci";
        globVarArr[idx][cnt].val = ((int)iCCI1[0]);
        cnt++;
    
        // 7.) ma per TotalSeconds - ma:   38
        globVarArr[idx][cnt].key = strlen + "_ma";
        globVarArr[idx][cnt].val = (ma1);
        cnt++;
    
        // 8.) oc per TotalSeconds - oc:   75
        globVarArr[idx][cnt].key = strlen + "_oc";
        globVarArr[idx][cnt].val = (oc1);
        cnt++;
    
        // 9.) shl per TotalSeconds - shl:    0
        globVarArr[idx][cnt].key = strlen + "_shl";
        globVarArr[idx][cnt].val = (iHSLBreakoutDelta);
        cnt++;
    
        // 10.) hl per TotalSeconds - hl:   89
        globVarArr[idx][cnt].key = strlen + "_hl";
        globVarArr[idx][cnt].val = (hl1);
        cnt++;
    
        // 11.) sd per TotalSeconds - sd:   61
        globVarArr[idx][cnt].key = strlen + "_sd";
        globVarArr[idx][cnt].val = (size_delta1);
        cnt++;
    
        // 12.) shld per TotalSeconds - shld:  150
        globVarArr[idx][cnt].key = strlen + "_shld";
        globVarArr[idx][cnt].val = (iHSLdelta);
        cnt++;
    
        // 13.) spread per TotalSeconds - spread:  2
        globVarArr[idx][cnt].key = strlen + "_spread";
        globVarArr[idx][cnt].val = (spread1);
        cnt++;
    
        // 14.) highs per TotalSeconds - highs: 1.07205
        globVarArr[idx][cnt].key = strlen + "_highs";
        globVarArr[idx][cnt].val = (iHSLhighs1[0]);
        cnt++;
    
        // 15.) lows per TotalSeconds - lows: 1.07055
        globVarArr[idx][cnt].key = strlen + "_lows";
        globVarArr[idx][cnt].val = (iHSLlows1[0]);
        cnt++;
    
        for( cnt = 0; cnt < 16; cnt ++ ) {
            datetime dtc = GlobalVariableSet(globVarArr[idx][cnt].key, globVarArr[idx][cnt].val );
            if( 0 == dtc ) Print( "ERROR: could not set GlobalVariableSet for: " + globVarArr[idx][cnt].key);
        }


    } // if( 0 < SignalNumber )

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
                
    string fmt = StringFormat("STOM%4d", (int)iStochMain1[0]-50);
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
    double iMA1 = Middle[0]- ma1* _Point;
    if( iMA1 < Middle[0] )
        SetRectangle(0, "iMA1", 0, 
                        time[bar0]-6*PeriodSeconds()*offset, iMA1, 
                        time[bar0]-4*PeriodSeconds()*offset, Middle[0], 
                        Up_Color, STYLE_SOLID, 1, "iMA1");
    else
        SetRectangle(0, "iMA1", 0, 
                        time[bar0]-6*PeriodSeconds()*offset, iMA1, 
                        time[bar0]-4*PeriodSeconds()*offset, Middle[0], 
                        Dn_Color, STYLE_SOLID, 1, "iMA1");

    fmt = StringFormat("MA  %4d", ma1);
    SetRightText (0, "iMa1Txt", 0, 
        time[bar0]-6*PeriodSeconds()*offset, iMA1 - (0*_Point), clrBlack, "Courier", fmt);

    //
    // oc recatangle
    //
    if( 0 < size1 ) { // only call if there have been any ticks
        double iOC1 = Middle[0]- oc1* _Point;
        if( 0 < oc1 )
            SetRectangle(0, "iOC1", 0, 
                            time[bar0]-4*PeriodSeconds()*offset, iOC1,
                            time[bar0]-2*PeriodSeconds()*offset, Middle[0],
                            Up_Color, STYLE_SOLID, 1, "iOC1");
        else
            SetRectangle(0, "iOC1", 0, 
                            time[bar0]-4*PeriodSeconds()*offset, iOC1,
                            time[bar0]-2*PeriodSeconds()*offset, Middle[0],
                            Dn_Color, STYLE_SOLID, 1, "iOC1");
    
        fmt = StringFormat("OC  %4d", oc1);
        SetRightText (0, "iOc1Txt", 0, 
            time[bar0]-4*PeriodSeconds()*offset, iOC1 - (0*_Point), clrBlack, "Courier", fmt);
    } // if( 0 < size1 )


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


    string posFmt = "";
    if( 0 == SignalNumber )                                
        posFmt = "----   secs:      0  price:       0  points:      0  pointshigh:      0  pointslow:      0";

    if(PositionSelect(_Symbol))
    {
        
        string BoS = "----";
        int _color = clrWhite;
        int _colorLine = clrWhite;
        double pos_open_price =  PositionGetDouble(POSITION_PRICE_OPEN);
        double pos_open_price_last =  PositionGetDouble(POSITION_PRICE_CURRENT);
        long pos_open_time = PositionGetInteger(POSITION_TIME);
        long pos_open_time_delta = TimeCurrent() - pos_open_time;
        long posOpenDT = ((TimeCurrent() - pos_open_time)*hl1)/kInputSampleAvgInSecs;
        //Print((long)TimeCurrent(), " ", pos_open_time, " ", TimeCurrent()-pos_open_time, " ", posOpenDT);
        long pos_open_price_delta = 0;
        ENUM_POSITION_TYPE pos_open_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if( POSITION_TYPE_BUY == pos_open_type )
        {
            BoS = "BUY ";
            pos_open_price_delta = (long)((pos_open_price_last - pos_open_price) / _Point);
            _color = clrBlue;
            _colorLine = clrBlue;
            if( 0 > pos_open_price_delta )
                _color = clrYellow;
        }

        if( POSITION_TYPE_SELL == pos_open_type )
        {
            BoS = "SELL ";
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
        
        MqlTick tickArray2[];
        int size2    = CopyTicksRange(  Symbol(), 
                                        tickArray2, COPY_TICKS_INFO, 
                                        (pos_open_time * 1000 ), 
                                        (TimeCurrent() * 1000 ));
        double high2 = 0;
        double low2  = 1000000000;
        if( 0 < size2 ) { // only call if there have been any ticks
            int oc2   = 0;
            int hl2   = 0;
            ExtractHighLowFromMqlTickArray( tickArray2, oc2, hl2, high2, low2 );
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
        } // if( 0 < size2 )


        int pos_open_price_high = 0;
        int pos_open_price_low  = 0;
        if( POSITION_TYPE_BUY == pos_open_type ) {
            pos_open_price_high = (int)MathAbs((pos_open_price - high2)  / _Point);
            pos_open_price_low  = (int)MathAbs((pos_open_price - low2) / _Point);
        } else {
            pos_open_price_high = (int)MathAbs((pos_open_price - low2)  / _Point);
            pos_open_price_low  = (int)MathAbs((pos_open_price - high2) / _Point);
        }
        if( 0 == SignalNumber )                                
            posFmt = StringFormat("%s  secs: %6d  price: %1.5f  points: %6d  pointshigh: %6d  pointslow: %6d", 
                BoS,
                pos_open_time_delta,
                pos_open_price,
                pos_open_price_delta,
                pos_open_price_high,
                -1*pos_open_price_low  );

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


    fmt = StringFormat("n: %d  s: %4d*%3d  v: %6d  sto: %4d/%4d  rsi: %4d  cci: %4d  ma: %4d  oc: %4d  shl: %4d  hl: %4d  sd: %4d  shld: %4d  spread: %2d  highs: %1.5f  lows: %1.5f   %s", 
                                SignalNumber,
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
                                iHSLlows1[0],
                                posFmt);
                                
    //if( 0 == SignalNumber )                                
    Print( fmt );


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
void ExtractHighLowFromMqlTickArray( const MqlTick& aTickArray[], int& aOC, int& aHL, double& aHigh, double& aLow )
{
    //double aHigh = 0;
    //double aLow  = 1000000000;
    int size = ArraySize( aTickArray );

    aHL = 0;
    aOC = 0;

    if( 0 < size )
    {
        MqlTick t0 = aTickArray[size - 1];
        if(t0.ask == 0 || t0.bid == 0 || t0.ask < t0.bid)
            return;
        MqlTick tstart = aTickArray[0];
        if(tstart.ask == 0 || tstart.bid == 0 || tstart.ask < tstart.bid)
            return;
        aOC = (int)(( ((t0.ask + t0.bid) / 2 ) - ((tstart.ask + tstart.bid) / 2 ) ) / _Point);
    }
    else
    {
        return;
    }

    for( int cnt = 0; cnt < size; cnt++ )
    {
        MqlTick t = aTickArray[cnt];
        // sanity check
        if(t.ask == 0 || t.bid == 0 || t.ask < t.bid)
            continue;
        if( aHigh < t.ask )
            aHigh = t.ask;
        if( aLow  > t.bid )
            aLow  = t.bid;

    } // for( cnt = 0; cnt < size; cnt++ )

    aHL = (int)(( aHigh - aLow ) / _Point);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
} // void ExtractHighLowFromMqlTickArray( const MqlTick& aTickArray[], int& aOC, int& aHL, double& aHigh, double& aLow )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get highest value for range                                      |
//+------------------------------------------------------------------+
double Highest(const double &aTickArray[],int range,int fromIndex)
{
    int cnt=0;
    double res;
    //---
    res=aTickArray[fromIndex];
    //---
    for(cnt=fromIndex; cnt>fromIndex-range && cnt>=0; cnt--)
    {
        if(res<aTickArray[cnt]) res=aTickArray[cnt];
    }
    //---
    return(res);
}
//+------------------------------------------------------------------+
//| Get lowest value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double &aTickArray[],int range,int fromIndex)
{
    int cnt=0;
    double res;
    //---
    res=aTickArray[fromIndex];
    //---
    for(cnt=fromIndex;cnt>fromIndex-range && cnt>=0;cnt--)
    {
        if(res>aTickArray[cnt]) res=aTickArray[cnt];
    }
    //---
    return(res);
}
//+------------------------------------------------------------------+
//| Convertion of value depending on digits (3/5)                    |
//+------------------------------------------------------------------+
int vDgtMlt(int value)
{
    if(_Digits==3 || _Digits==5) { return(value*=10); } else { return(value); }
}
//+------------------------------------------------------------------+
//| Conversion from double to string (digit)                         |
//+------------------------------------------------------------------+
string DS_dgt(double aValue,int digit)
{
    return(DoubleToString(aValue,digit));
}
//+------------------------------------------------------------------+
//| Normalization of values (digit)                                  |
//+------------------------------------------------------------------+
double ND_dgt(double aValue,int digit)
{
    return(NormalizeDouble(aValue,digit));
}
//+------------------------------------------------------------------+
//| Normalization and conversion to string (digit)                   |
//+------------------------------------------------------------------+
string DSNDdgt(double aValue,int digit)
{
    return(DS_dgt(ND_dgt(aValue,digit),digit));
}
//-------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CreateRectangle                                                  |
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
//| SetRectangle                                                     |
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
    if(ObjectFind(chart_id, name) == -1) {
        CreateRectangle(chart_id, name, nwin, time1, price1, time2, price2, Color, style, width, text);
    } else {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectMove(chart_id, name, 0, time1, price1);
        ObjectMove(chart_id, name, 1, time2, price2);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    }
//----

} // void SetRectangle
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  CreateRightPrice                                                |
//+------------------------------------------------------------------+
void CreateRightPrice
(
    long chart_id,   // chart ID
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
//|  SetRightPrice                                                   |
//+------------------------------------------------------------------+
void SetRightPrice
(
    long chart_id,// chart ID
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
    if(ObjectFind(chart_id, name) == -1) {
        CreateRightPrice(chart_id, name, nwin, time, price, Color, Font);
    } else { 
        ObjectMove(chart_id, name, 0, time, price);
    }
//----

} // void SetRightPrice
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  CreateRightText                                                 |
//+------------------------------------------------------------------+
void CreateRightText
(
    long chart_id,// chart ID
    string   name,              // object name
    int      nwin,              // window index
    datetime time,              // price level time
    double   price,             // price level
    color    Color,             // Text color
    string   Font,              // Text font
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
//|  SetRightText                                                    |
//+------------------------------------------------------------------+
void SetRightText
(
    long chart_id,// chart ID
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
    if(ObjectFind(chart_id, name) == -1) {
        CreateRightText(chart_id, name, nwin, time, price, Color, Font, Text);
    } else {
        ObjectMove(chart_id, name, 0, time, price);
        ObjectSetString(chart_id, name, OBJPROP_TEXT, Text);
    }
//----

} // void SetRightText
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  CreateTline                                                     |
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
//|  SetTline                                                        |
//+------------------------------------------------------------------+
void SetTline
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
    if(ObjectFind(chart_id, name) == -1) {
        CreateTline(chart_id, name, nwin, time1, price1, time2, price2, Color, style, width, text);
    } else {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectMove(chart_id, name, 0, time1, price1);
        ObjectMove(chart_id, name, 1, time2, price2);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, Color);
    }
//----

} // void SetTline
//+------------------------------------------------------------------+
