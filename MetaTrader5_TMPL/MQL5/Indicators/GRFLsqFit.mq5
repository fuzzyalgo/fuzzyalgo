//+------------------------------------------------------------------+
//|                                               GRFLeadingEdge.mq5 | 
//|                                  Copyright © 2007, GammaRatForex | 
//|                                   http://www.gammarat.com/Forex/ | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, GammaRatForex"
#property link "http://www.gammarat.com/Forex/"
/*
 * LSQ line fitting to the a number of samples.
 * The trendline is the leading point in the fit;
 * the bands are calculated somewhat differently, check the math below and adapt to 
 * your own needs as appropriate
 * also the point estimate is given by the geometric mean
 * MathPow(HCCC,.025) (see function "get_avg" below) rather than 
 * more standard estimates.
 * It's computationally fairly intensive
 */

#property version   "1.00"
#property indicator_chart_window 
#property indicator_buffers 4
#property indicator_plots   4
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID // STYLE_DASHDOTDOT 
#property indicator_width1  2

#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_color3  clrLimeGreen
#property indicator_color4  clrBrown
//#property indicator_style2 STYLE_SOLID // STYLE_DASHDOT
//#property indicator_style3 STYLE_SOLID // STYLE_DOT
//#property indicator_style4 STYLE_SOLID // STYLE_DASH
#property indicator_style2 STYLE_DOT
#property indicator_style3 STYLE_DASH
#property indicator_style4 STYLE_DASH
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  0

input uint s1_Samples=4;
input uint s2_Samples=20;
input uint s3_Samples=60;
input uint s4_Samples=240;
/*input*/ uint  LookAhead=0;
//+-----------------------------------+


struct LSQFitS 
{
    uint   samples;
    double a[2][2];
    double b[2][2];
    double base_det;
    double buffer[];
};

LSQFitS gLsq1;
LSQFitS gLsq2;
LSQFitS gLsq3;
LSQFitS gLsq4;



int min_rates_total;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
{
    ChartRedraw();
    
    gLsq1.samples  = s1_Samples;
    gLsq1.base_det = 1;
    gLsq2.samples  = s2_Samples;
    gLsq2.base_det = 1;
    gLsq3.samples  = s3_Samples;
    gLsq3.base_det = 1;
    gLsq4.samples  = s4_Samples;
    gLsq4.base_det = 1;

    
    min_rates_total=int(s4_Samples);
    
    SetIndexBuffer(0,gLsq1.buffer,INDICATOR_DATA);
    SetIndexBuffer(1,gLsq2.buffer,INDICATOR_DATA);
    SetIndexBuffer(2,gLsq3.buffer,INDICATOR_DATA);
    SetIndexBuffer(3,gLsq4.buffer,INDICATOR_DATA);
    
    PlotIndexSetInteger(0,PLOT_SHIFT,0);
    PlotIndexSetInteger(1,PLOT_SHIFT,0);
    PlotIndexSetInteger(2,PLOT_SHIFT,0);
    PlotIndexSetInteger(3,PLOT_SHIFT,0);
    
    PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
    PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
    PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
    PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
    
    PlotIndexSetString(0,PLOT_LABEL,"LSQ " + IntegerToString(gLsq1.samples));
    PlotIndexSetString(1,PLOT_LABEL,"LSQ " + IntegerToString(gLsq2.samples));
    PlotIndexSetString(2,PLOT_LABEL,"LSQ " + IntegerToString(gLsq3.samples));
    PlotIndexSetString(3,PLOT_LABEL,"LSQ " + IntegerToString(gLsq4.samples));
    
    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
    PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
    PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
    
    PlotIndexSetInteger(0,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(1,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(2,PLOT_SHOW_DATA,true); 
    PlotIndexSetInteger(3,PLOT_SHOW_DATA,true); 
    
    IndicatorSetString(INDICATOR_SHORTNAME,"LSQ Fit");
    IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
    
} // void OnInit()

//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    
                const int prev_calculated,
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
    if(rates_total<min_rates_total) return(0);

    // clear the buffers
    if(  0 == prev_calculated )
    {
        for (int i=0; i<rates_total && !IsStopped(); i++)
        {
            gLsq1.buffer[i] = 0.0;
            gLsq2.buffer[i] = 0.0;
            gLsq3.buffer[i] = 0.0;
            gLsq4.buffer[i] = 0.0;
        }
    }    
    
    CalcLSQLineFit( gLsq1, 
                   rates_total, prev_calculated,
                   time, open, high, low, close,
                   tick_volume, volume, spread );


    CalcLSQLineFit( gLsq2, 
                   rates_total, prev_calculated,
                   time, open, high, low, close,
                   tick_volume, volume, spread );
                   
    CalcLSQLineFit( gLsq3, 
                   rates_total, prev_calculated,
                   time, open, high, low, close,
                   tick_volume, volume, spread );
                   
    CalcLSQLineFit( gLsq4, 
                   rates_total, prev_calculated,
                   time, open, high, low, close,
                   tick_volume, volume, spread );

    
    //----     
    return(rates_total);
   
} // int OnCalculate(
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
void CalcLSQLineFit(
                LSQFitS& lsq,
                const int rates_total,    
                const int prev_calculated,
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
    
    double c0,c1,alpha,beta;
    int first,bar;
    
    //Print(prev_calculated);
    //Print(rates_total);
    
    if(prev_calculated>rates_total || prev_calculated<=0) 
    {
        /*for (int i=0; i<rates_total && !IsStopped(); i++)
        {
            gLsq1.buffer[i] = 0.0;
            gLsq2.buffer[i] = 0.0;
            gLsq3.buffer[i] = 0.0;
            gLsq4.buffer[i] = 0.0;
        }*/
    
        first=min_rates_total; 
        ArrayInitialize(lsq.a,0);
        for(uint iii=0; iii<lsq.samples; iii++)
        {
            lsq.a[0][0]+=iii*iii;
            lsq.a[0][1]+=iii;
            lsq.a[1][0]+=iii;
            lsq.a[1][1]++;
        }
        
        lsq.base_det=det2(lsq.a);
    }
    else 
    {
        first=prev_calculated-1;
         
    } // if(prev_calculated>rates_total || prev_calculated<=0) 
    
    //first = (int)(rates_total-lsq.samples);
    for(bar=first; bar<rates_total && !IsStopped(); bar++)
    {
        c0=0;
        c1=0;
        for(uint kkk=0; kkk<lsq.samples; kkk++)
        {
            double res=get_avg(bar-kkk,open, high, low, close );
            c0+=kkk*res;
            c1+=res;
        }
        
        ArrayCopy(lsq.b,lsq.a);
        lsq.b[0][0]=c0;
        lsq.b[1][0]=c1;
        alpha=det2(lsq.b)/lsq.base_det;
        
        ArrayCopy(lsq.b,lsq.a);
        lsq.b[0][1]=c0;
        lsq.b[1][1]=c1;
        beta=det2(lsq.b)/lsq.base_det;
        
        lsq.buffer[bar]=(beta-alpha*LookAhead)*_Point;
        
    } // for(bar=first; bar<rates_total && !IsStopped(); bar++)
    
   
} // void CalcLSQLineFit(
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_avg(int index, const double &Open[], const double &High[], const double &Low[], const double &Close[])
{
//----
    return(MathPow((High[index]*Low[index]*Close[index]*Close[index]),1/4.0)/_Point);
    //return(MathPow((Open[index]*Open[index]*Open[index]*Open[index]),1/4.0)/_Point);
    //return(MathPow((Close[index]*Close[index]*Close[index]*Close[index]),1/4.0)/_Point);
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+       
double det2(double &arr[][2])
{
//----
    return(arr[0][0]*arr[1][1]-arr[1][0]*arr[0][1]);
}
//+------------------------------------------------------------------+
