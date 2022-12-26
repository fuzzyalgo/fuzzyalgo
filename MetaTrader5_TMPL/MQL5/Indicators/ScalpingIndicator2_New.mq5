#property copyright "Copyright 2014, Andre Howe"
#property link      "andrehowe.com"


#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4   
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
  
const string gIndicatorName = "ScalpingIndicator2_New";

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_color1 Blue
#property indicator_color2 Red
//#property indicator_color3 Yellow
//#property indicator_color7 Green

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_LINE


#property indicator_width1  6
#property indicator_width2  6

#property indicator_label1  "84"
#property indicator_label2  "88"
#property indicator_label3  "Si1"


input int Count    = 10;
input int Freq     = 5;



double g_ibuf_88[];
double g_ibuf_92[];
double Si1Buff[];

enum ColorEnum
{
    eClrNone = 0,
    eClrBlue,
    eClrRed,
    eClrGreen,
};


int OnInit( )
{
	Comment( "" );

    //--- set maximum and minimum for subwindow 
    // TODO comment
    //IndicatorSetDouble(INDICATOR_MINIMUM,-10.0);
    IndicatorSetDouble(INDICATOR_MINIMUM,0);
    IndicatorSetDouble(INDICATOR_MAXIMUM,10);

    SetIndexBuffer(0, g_ibuf_88,INDICATOR_DATA);
    SetIndexBuffer(1, g_ibuf_92,INDICATOR_DATA);
    SetIndexBuffer(2, Si1Buff,INDICATOR_DATA);
   
	PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );
   
    ArraySetAsSeries( g_ibuf_88, true );
    ArraySetAsSeries( g_ibuf_92, true );
    ArraySetAsSeries( Si1Buff, true );
   
    IndicatorSetString(INDICATOR_SHORTNAME,gIndicatorName+"("+string(Freq)+","+string(Count)+")");
   
    return (0);
} // int OnInit( )

int
OnCalculate(const int rates_total,
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

   /*double ld_8;
   double ld_16;
   double ld_80;
   double ld_32 = 0;
   double ld_40 = 0;
   double ld_64 = 0;
   double l_low_88 = 0;
   double l_high_96 = 0;*/
   
    static datetime	last_bar_datetime_chart = 0;
    
    if( prev_calculated == 0)
    {
        last_bar_datetime_chart = 0;
        ObjectsDeleteAll(0, gIndicatorName);
        ChartRedraw( );
    	
    } // if( prev_calculated == 0)
    int start = rates_total-prev_calculated;
    if( rates_total <= start )
    {
        start = rates_total - 1;
    }
    if( rates_total > (100+1) )
    {
        if( 100 > start )
        {
            start = 100;
        }
    }
   
   
    int li_0 = Count;
    if( li_0 > rates_total ) {
        li_0 = rates_total - 10;
    }
   
   
   
    double ld_40 = 0.0;
    double ld_64 = 0.0;
    for (int li_104 = li_0; li_104 >= 0; li_104--) 
    {
        //double l_high_96 = High[ArrayMaximum(High, li_104, Freq)];
        //double l_low_88  = Low [ArrayMinimum(Low,  li_104, Freq)];
        //double ld_80     = (High[li_104] + Low[li_104]) / 2.0;
        
        double l_high_96 = Close[ArrayMaximum(Close, li_104, Freq)];
        double l_low_88  = Close[ArrayMinimum(Close, li_104, Freq)];
        double ld_80     = Close[li_104];

        
        //double pivot=( Close[li_104+1]+Close[li_104+2]+Close[li_104+3] )/3;
        //double A=(Close[li_104+0]-((l_high_96 + l_low_88 + pivot)/3))/Point();
        //Si1Buff[li_104] = A;
        
        // AddStoch XLS STO =((G5-MIN(F5:F5))/(MAX(E5:E5)-MIN(F5:F5)+0.000001)-0.5)*100
        // Si1Buff[li_104] = ((G5-MIN(F5:F5))/(MAX(E5:E5)-MIN(F5:F5)+0.000001)-0.5)*100
        Si1Buff[li_104] = ((ld_80-l_low_88)/(l_high_96-l_low_88+0.000001)-0.5)*100;
        
        
        /*
        double idiv = (l_high_96 - l_low_88);
        double ld_32 = 0.0;
        if( 0.0 != idiv ) ld_32 = 0.66 * ((ld_80 - l_low_88) / idiv - 0.5) + 0.05 * ld_40;
        ld_32 = MathMin(MathMax(ld_32, -0.999), 0.999);
        Si1Buff[li_104] = MathLog((ld_32 + 1.0) / (1 - ld_32)) / 2.0 + ld_64 / 2.0;
        //if( 0.0 != idiv ) Si1Buff[li_104] = ((ld_80 - l_low_88) / idiv - 0.5);
        ld_40 = ld_32;
        ld_64 = Si1Buff[li_104];
        */
    } // for (int li_104 = li_0; li_104 >= 0; li_104--) 
   

    double valPrev = 0;
       
    bool li_108 = true;
    for (int li_104 = li_0 - 2; li_104 >= 0; li_104--) 
    {
        double ld_16 = Si1Buff[li_104];
        double ld_8 = Si1Buff[li_104 + 1];
        if ((ld_16 < 0.0 && ld_8 > 0.0) || ld_16 < 0.0) li_108 = false;
        if ((ld_16 > 0.0 && ld_8 < 0.0) || ld_16 > 0.0) li_108 = true;
        if (!li_108) {
            // TODO comment
            //g_ibuf_92[li_104] = ld_16;
            g_ibuf_92[li_104] = -1*ld_16;
            g_ibuf_88[li_104] = 0.0;
        } else {
            g_ibuf_88[li_104] = ld_16;
            g_ibuf_92[li_104] = 0.0;
        }
        
        
        double val = g_ibuf_88[li_104] + g_ibuf_92[li_104];
        //
        // method zero
        // reset integral at midnight
        //
        
        // uncomment here
        /*MqlDateTime tm0, tm1;
        datetime t0 = Time[li_104];
        TimeToStruct( t0, tm0 );
        datetime t1 = Time[li_104+1];
        TimeToStruct( t1, tm1 );
        if( (23 == tm1.hour) && (0 == tm0.hour) )
            IntBuff[li_104+1] = 0;
        IntBuff[li_104] = IntBuff[li_104+1] + val;*/
        
        //
        // method one
        // reset integral every % mod bars
        //
        /*if( 0 == ( li_104 % 8 ) ) 
            IntBuff[li_104+1] = 0;
        IntBuff[li_104] = IntBuff[li_104+1] +val;*/
        
        //
        // method two
        // generate integral with either
        // positive or negative values only
        //
        /*if( (0 < valPrev) && ( 0 < val ) )
        {
            IntBuff[li_104] = IntBuff[li_104+1] +val;
        }
        if( (0 > valPrev) && ( 0 > val ) )
        {
            IntBuff[li_104] = IntBuff[li_104+1] +val;
        }
        if( (0 > valPrev) && ( 0 < val ) )
        {
            IntBuff[li_104] = val;
        }
        if( (0 < valPrev) && ( 0 > val ) )
        {
            IntBuff[li_104] = val;
        }*/
        
        valPrev = val;


        //
        // give it a colur
        //
        // uncomment here
        /*if( IntBuff[li_104] > IntBuff[li_104+1] )
            IntColBuff[li_104] = eClrBlue;
        else if( IntBuff[li_104] < IntBuff[li_104+1] )
            IntColBuff[li_104] = eClrRed;
        else
            IntColBuff[li_104] = eClrGreen;*/
        
        
        /*
        double val = Si1Buff[li_104] + Si2Buff[li_104] + Si3Buff[li_104] + Si4Buff[li_104] ;
        if( (val>0) )
        {
            g_ibuf_88[li_104]=val;
            g_ibuf_92[li_104]=0.0;
        }
        
        if( (val<0) )
        {
           g_ibuf_92[li_104]=val;
           g_ibuf_88[li_104]=0.0;
        }
        */
        
    }
       
    return (rates_total);
}


int IndicatorCountedMQL4(const int prev_calculated)
  {
   if(prev_calculated>0) return(prev_calculated-1);
   if(prev_calculated==0) return(0);
   return(0);
  }
  
  
int iHighestMQL4(string symbol,
                 ENUM_TIMEFRAMES timeframe,
                 int type,
                 int count=WHOLE_ARRAY,
                 int start=0)
  {
   if(start<0) return(-1);
   //ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(count<=0) count=Bars(symbol,timeframe);
   if(type<=MODE_OPEN)
     {
      double Open[];
      ArraySetAsSeries(Open,true);
      CopyOpen(symbol,timeframe,start,count,Open);
      return(ArrayMaximum(Open,0,count)+start);
     }
   if(type==MODE_LOW)
     {
      double Low[];
      ArraySetAsSeries(Low,true);
      CopyLow(symbol,timeframe,start,count,Low);
      return(ArrayMaximum(Low,0,count)+start);
     }
   if(type==MODE_HIGH)
     {
      double High[];
      ArraySetAsSeries(High,true);
      CopyHigh(symbol,timeframe,start,count,High);
      return(ArrayMaximum(High,0,count)+start);
     }
   if(type==MODE_CLOSE)
     {
      double Close[];
      ArraySetAsSeries(Close,true);
      CopyClose(symbol,timeframe,start,count,Close);
      return(ArrayMaximum(Close,0,count)+start);
     }
   if(type==MODE_VOLUME)
     {
      long Volume[];
      ArraySetAsSeries(Volume,true);
      CopyTickVolume(symbol,timeframe,start,count,Volume);
      return(ArrayMaximum(Volume,0,count)+start);
     }
   if(type>=MODE_TIME)
     {
      datetime Time[];
      ArraySetAsSeries(Time,true);
      CopyTime(symbol,timeframe,start,count,Time);
      return(ArrayMaximum(Time,0,count)+start);
      //---
     }
   return(0);
  }
  
int iLowestMQL4(string symbol,
                ENUM_TIMEFRAMES timeframe,
                int type,
                int count=WHOLE_ARRAY,
                int start=0)
  {
   if(start<0) return(-1);
   //ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(count<=0) count=Bars(symbol,timeframe);
   if(type<=MODE_OPEN)
     {
      double Open[];
      ArraySetAsSeries(Open,true);
      CopyOpen(symbol,timeframe,start,count,Open);
      return(ArrayMinimum(Open,0,count)+start);
     }
   if(type==MODE_LOW)
     {
      double Low[];
      ArraySetAsSeries(Low,true);
      CopyLow(symbol,timeframe,start,count,Low);
      return(ArrayMinimum(Low,0,count)+start);
     }
   if(type==MODE_HIGH)
     {
      double High[];
      ArraySetAsSeries(High,true);
      CopyHigh(symbol,timeframe,start,count,High);
      return(ArrayMinimum(High,0,count)+start);
     }
   if(type==MODE_CLOSE)
     {
      double Close[];
      ArraySetAsSeries(Close,true);
      CopyClose(symbol,timeframe,start,count,Close);
      return(ArrayMinimum(Close,0,count)+start);
     }
   if(type==MODE_VOLUME)
     {
      long Volume[];
      ArraySetAsSeries(Volume,true);
      CopyTickVolume(symbol,timeframe,start,count,Volume);
      return(ArrayMinimum(Volume,0,count)+start);
     }
   if(type>=MODE_TIME)
     {
      datetime Time[];
      ArraySetAsSeries(Time,true);
      CopyTime(symbol,timeframe,start,count,Time);
      return(ArrayMinimum(Time,0,count)+start);
     }
//---
   return(0);
  }
      
//---------------------------------------------------------------------
//	Returns a sign of appearance of a new bar:
//---------------------------------------------------------------------
int CheckNewBar( string _symbol, ENUM_TIMEFRAMES _period, datetime& _last_dt )
{
	datetime	curr_time = ( datetime )SeriesInfoInteger( _symbol, _period, SERIES_LASTBAR_DATE );
	if( curr_time > _last_dt )
	{
		_last_dt = curr_time;
		return( 1 );
	}

	return( 0 );
}
  