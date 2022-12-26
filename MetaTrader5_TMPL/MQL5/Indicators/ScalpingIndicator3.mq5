#property copyright "Copyright 2014, Andre Howe"
#property link      "andrehowe.com"


#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4   
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
  
const string gIndicatorName = "ScalpingIndicator3";

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1	   "Int"
#property indicator_type1		DRAW_HISTOGRAM
#property indicator_style1	   STYLE_SOLID
#property indicator_width1	   2
#property indicator_color1	   clrGreen

#property indicator_label2	   "Si1"
#property indicator_type2		DRAW_COLOR_HISTOGRAM
//#property indicator_type2		DRAW_COLOR_LINE
#property indicator_color2	   clrNONE, clrLightGray, clrGreen, 0xFFCCCC, 0xFF9999, 0xFF6666, 0xFF3333, 0xFF0000, 0xCCCCFF, 0x9999FF, 0x6666FF, 0x3333FF, 0x0000FF
#property indicator_style2	   STYLE_SOLID
#property indicator_width2	   3



enum ColorEnum
{
    eClrNone = 0,
    eClrGray,
    eClrGreen,
    eClrBlue1,
    eClrBlue2,
    eClrBlue3,
    eClrBlue4,
    eClrBlue5,
    eClrRed1,
    eClrRed2,
    eClrRed3,
    eClrRed4,
    eClrRed5,
};


//extern int intensity = 18;
//extern int periods = 800;
input int intensity = 240;
input int periods = 400;

double	ValueBuff[ ];
double	ColorBuff[ ];
double  IntBuff[];

int OnInit( )
{
	Comment( "" );

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- set levels
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,-50);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,+50);
//--- set maximum and minimum for subwindow 
   IndicatorSetDouble(INDICATOR_MINIMUM,-100);
   IndicatorSetDouble(INDICATOR_MAXIMUM,+100);

	SetIndexBuffer( 0, IntBuff,INDICATOR_DATA );
	SetIndexBuffer( 1, ValueBuff,INDICATOR_DATA );
	SetIndexBuffer( 2, ColorBuff,INDICATOR_COLOR_INDEX );
	PlotIndexSetDouble( 0, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 1, PLOT_EMPTY_VALUE, 0.0 );
	PlotIndexSetDouble( 2, PLOT_EMPTY_VALUE, 0.0 );
    ArraySetAsSeries( IntBuff, true );
    ArraySetAsSeries( ValueBuff, true );
    ArraySetAsSeries( ColorBuff, true );
   
    IndicatorSetString(INDICATOR_SHORTNAME,gIndicatorName+"("+string(intensity)+","+string(periods)+")");
   
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
   
   
    int li_0 = 0;
    if (periods > Bars(Symbol(),Period()) || periods == 0) li_0 = Bars(Symbol(),Period()) - intensity;
    else li_0 = periods - intensity;
    // todo fixme
    // TODO FIXME INDICATOR START
    //if( true == TESTERMODE )
    //{
    //    start = 100;
    //}
    li_0 = /*10**/2*5*24*60;//start;
    li_0 = 60*24*50;
    
    //li_0 = 200;
    if( li_0 > rates_total ) {
        li_0 = rates_total - 10;
    }

    
    int Period1 = (int)(intensity*1.0);
    int Period2 = (int)(intensity*0.75);
    int Period3 = (int)(intensity*0.5);
    int Period4 = (int)(intensity*0.25); 
    
    int Factor = 1; 
    
    double valPrev = 0;
    
    ///
    double aPrev = 0.0;
    double a1Prev = 0.0;
    ///
    
    for (int i = li_0; i >= 0; i--) 
    {
    
        int mpa = Period1;
        int mpb = 1;
        double max=High[ArrayMaximum(High,i,Factor*mpa)];
        double min=Low[ArrayMinimum(Low,i,Factor*mpa)];
        double pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        double A=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();
        // TODO review
        A=(Close[i+0*mpb]- pivot)/Point();
        
        ///
        /*double ld_80 = Close[i];//(High[i] + Low[i]) / 2.0;
        double idiv = (max - min);
        double ld_32 = 0.0;
        if( 0.0 != idiv ) ld_32 = 0.66 * ((ld_80 - min) / idiv - 0.5) + 0.05 * a1Prev;
        ld_32 = MathMin(MathMax(ld_32, -0.999), 0.999);
        A = MathLog((ld_32 + 1.0) / (1 - ld_32)) / 2.0 + aPrev / 2.0;
        a1Prev = ld_32;
        aPrev = A;*/
        ///

        mpa = Period2;
        mpb = 1;
        max=High[ArrayMaximum(High,i,Factor*mpa)];
        min=Low[ArrayMinimum(Low,i,Factor*mpa)];
        pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        double B=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();

        mpa = Period3;
        mpb = 1;
        max=High[ArrayMaximum(High,i,Factor*mpa)];
        min=Low[ArrayMinimum(Low,i,Factor*mpa)];
        pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        double C=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();

        mpa = Period4;
        mpb = 1;
        max=High[ArrayMaximum(High,i,Factor*mpa)];
        min=Low[ArrayMinimum(Low,i,Factor*mpa)];
        pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        double D=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();
    
    
     /*       
        int mpa = Period1;
        int mpb = 1;
        double max=Close[ArrayMaximum(Close,i,Factor*mpa)];
        double min=Close[ArrayMinimum(Close,i,Factor*mpa)];
        double pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        //double A=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();
        double A=(Close[i+0*mpb]-((max + min )/2))/Point();

        mpa = Period2;
        mpb = 1;
        max=Close[ArrayMaximum(Close,i,Factor*mpa)];
        min=Close[ArrayMinimum(Close,i,Factor*mpa)];
        pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        //double B=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();
        double B=(Close[i+0*mpb]-((max + min )/2))/Point();

        mpa = Period3;
        mpb = 1;
        max=Close[ArrayMaximum(Close,i,Factor*mpa)];
        min=Close[ArrayMinimum(Close,i,Factor*mpa)];
        pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        //double C=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();
        double C=(Close[i+0*mpb]-((max + min )/2))/Point();

        mpa = Period4;
        mpb = 1;
        max=Close[ArrayMaximum(Close,i,Factor*mpa)];
        min=Close[ArrayMinimum(Close,i,Factor*mpa)];
        pivot=( Close[i+1*mpb]+Close[i+2*mpb]+Close[i+3*mpb] )/3;
        //double D=(Close[i+0*mpb]-((max + min + pivot)/3))/Point();
        double D=(Close[i+0*mpb]-((max + min )/2))/Point();
      */  
        
        
        
        /*if( (A>0) && (B>0) && (C>0) && (D>0) )
        {
            g_ibuf_88[i]=MathMin(A,B);
        }
        
        if( (A<0) && (B<0) && (C<0) && (D<0) )
        {
            g_ibuf_92[i]=MathMax(A,B);
        }*/
        
		ValueBuff[i] = 0.0;
		ColorBuff[i] = 0;

        //double val = A/*+B+C+D*/;
        double val = (A+B+C+D)/4;
        
        
        ValueBuff[i] = val;
        if( (val>0) )
        {
            if ( val < valPrev )
			{
			    ColorBuff[ i ] = eClrGray;  
			}        
			// TODO review
			//else if( (A>0) && (B>0) && (C>0) && (D>0) )
			else if( A>100) 
			{
			    ColorBuff[ i ] = eClrBlue5;  
			}
            else
            {
    			ColorBuff[ i ] = eClrBlue2;
            }
        }
        
        if( (val<-0) )
        {
            if ( val > valPrev )
			{
			    ColorBuff[ i ] = eClrGray;  
			}
			// TODO review
			//else if( (A<0) && (B<0) && (C<0) && (D<0) )
			else if( A<-100)
			{
    			ColorBuff[ i ] = eClrRed5;
			}
			else
			{
    			ColorBuff[ i ] = eClrRed2;
			}
			
        }
        
        
        //
        // method zero
        // reset integral at midnight
        //
        
        /*MqlDateTime tm0, tm1;
        datetime t0 = Time[i];
        TimeToStruct( t0, tm0 );
        datetime t1 = Time[i+1];
        TimeToStruct( t1, tm1 );
        if( (23 == tm1.hour) && (0 == tm0.hour) )
            IntBuff[i+1] = 0;
        IntBuff[i] = IntBuff[i+1] + val;*/
        
        //
        // method one
        // reset integral every % mod bars
        //
        if( 0 == ( i % 5 ) ) 
            IntBuff[i+1] = 0;
        IntBuff[i] = IntBuff[i+1] +val;
        
        /*
        //
        // method two
        // generate integral with either
        // positive or negative values only
        //
        if( (0 < valPrev) && ( 0 < val ) )
        {
            IntBuff[i] = IntBuff[i+1] +val;
        }
        if( (0 > valPrev) && ( 0 > val ) )
        {
            IntBuff[i] = IntBuff[i+1] +val;
        }
        if( (0 > valPrev) && ( 0 < val ) )
        {
            IntBuff[i] = val;
        }
        if( (0 < valPrev) && ( 0 > val ) )
        {
            IntBuff[i] = val;
        }
        */
        
        valPrev = val;

        
            //g_ibuf_92[i]=(C);
            //g_ibuf_88[i]=(D);
        
    } // for (int i = li_0; i >= 0; i--) 
           
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
  
//+------------------------------------------------------------------+
//| get the bar shift from time
//+------------------------------------------------------------------+
int iBarShift(  string symbol,
                ENUM_TIMEFRAMES timeframe,
                datetime starttime,
                datetime stoptime
                )
{
    datetime Arr[];
    if(CopyTime(symbol,timeframe,starttime,stoptime,Arr)>0)
    {
        if(ArraySize(Arr)>2) 
        {
            return(ArraySize(Arr)-1);
        }
        //if(starttime<stoptime)
        if(stoptime<starttime)
        {
            return(1);
        }
        else 
        {
            return(0);
        }
    }
    else 
    {
        return(-1);
    }
} // int iBarShiftMQL4(string symbol
//+------------------------------------------------------------------+
  