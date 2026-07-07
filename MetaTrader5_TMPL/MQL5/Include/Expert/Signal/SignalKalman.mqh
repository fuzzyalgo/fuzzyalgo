//+------------------------------------------------------------------+
//|                                                 SignalKalman.mqh |
//|                                              Copyright 2017, DNG |
//|                                      https://forex-start.ucoz.ua |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, DNG"
#property link      "https://forex-start.ucoz.ua"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <..\\Experts\\Kalman_Gizlyk\\Kalman.mqh>
// wizard description start
//+---------------------------------------------------------------------------+
//| Description of the class                                                  |
//| Title=Signals of Kalman's filter degign by DNG                            |
//| Type=SignalAdvanced                                                       |
//| Name=Signals of Kalman's filter degign by DNG                             |
//| ShortName=Kalman_Filter                                                 |
//| Class=CSignalKalman                                                       |
//| Page=http://www.mql5.com/ru/articles/3886                                 |
//| Parameter=TimeFrame,ENUM_TIMEFRAMES,PERIOD_H1,Timeframe                   |
//| Parameter=HistoryBars,uint,3000,Bars in history to analysis               |
//| Parameter=ShiftPeriod,uint,0,Period for shift                             |
//+---------------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalKalman: public CExpertSignal
  {
private:
   ENUM_TIMEFRAMES   ce_Timeframe;  //Timframe
   uint              ci_HistoryBars;//Bars in history to analysis
   uint              ci_ShiftPeriod;//Period for shift
   CKalman          *Kalman;        //Class of Kalman's filter
   //---
   datetime          cdt_LastCalcIndicators;
   
   double            cd_forecast;   // Forecast value
   double            cd_corretion;  // Corrected value
   //---
   bool              CalculateIndicators(void);
       
public:
                     CSignalKalman();
                    ~CSignalKalman();
   //---
   void              TimeFrame(ENUM_TIMEFRAMES value);
   void              HistoryBars(uint value);
   void              ShiftPeriod(uint value);
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalKalman::CSignalKalman(void):    ci_HistoryBars(3000),
                                       ci_ShiftPeriod(0),
                                       cdt_LastCalcIndicators(0)
  {
   ce_Timeframe=m_period;
   
   if(CheckPointer(m_symbol)!=POINTER_INVALID)
      Kalman=new CKalman(ci_HistoryBars,ci_ShiftPeriod,m_symbol.Name(),ce_Timeframe);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalKalman::~CSignalKalman()
  {
   if(CheckPointer(m_close)!=POINTER_INVALID)
      delete m_close;
   if(CheckPointer(m_open)!=POINTER_INVALID)
      delete m_open;
   if(CheckPointer(m_high)!=POINTER_INVALID)
      delete m_high;
   if(CheckPointer(m_low)!=POINTER_INVALID)
      delete m_low;
   if(CheckPointer(Kalman)!=POINTER_INVALID)
      delete Kalman;
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalKalman::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(ci_HistoryBars<200)
     {
      PrintFormat("Too short historical period. Minimal historical period is 200 bars. HistoryBars=%d", ci_HistoryBars);
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalKalman::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer is performed in the method of the parent class
//---
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- initialize close serias
   if(CheckPointer(m_close)==POINTER_INVALID)
     {
      if(!InitClose(indicators))
         return false;
     }
////--- initialize open serias
//   if(CheckPointer(m_open)==POINTER_INVALID)
//     {
//      if(!InitOpen(indicators))
//         return false;
//     }
////--- initialize high serias
//   if(CheckPointer(m_high)==POINTER_INVALID)
//     {
//      if(!InitHigh(indicators))
//         return false;
//     }
////--- initialize low serias
//   if(CheckPointer(m_low)==POINTER_INVALID)
//     {
//      if(!InitLow(indicators))
//         return false;
//     }
//--- create and initialize Spectrum and Filters
   
   if(CheckPointer(Kalman)==POINTER_INVALID)
     {
      Kalman=new CKalman(ci_HistoryBars,ci_ShiftPeriod,m_symbol.Name(),ce_Timeframe);
     }
   
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalKalman::TimeFrame(ENUM_TIMEFRAMES value)
  {
   ce_Timeframe=value;
   if(CheckPointer(Kalman)!=POINTER_INVALID)
      delete Kalman;
   Kalman=new CKalman(ci_HistoryBars,ci_ShiftPeriod,m_symbol.Name(),ce_Timeframe);
   
   if(CheckPointer(m_close)!=POINTER_INVALID)
      m_close.Create(m_symbol.Name(),ce_Timeframe);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalKalman::HistoryBars(uint value)
  {
   ci_HistoryBars=value;
   if(CheckPointer(Kalman)!=POINTER_INVALID)
      delete Kalman;
   Kalman=new CKalman(ci_HistoryBars,ci_ShiftPeriod,m_symbol.Name(),ce_Timeframe);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalKalman::ShiftPeriod(uint value)
  {
   ci_ShiftPeriod=value;
   if(CheckPointer(Kalman)!=POINTER_INVALID)
      delete Kalman;
   Kalman=new CKalman(ci_HistoryBars,ci_ShiftPeriod,m_symbol.Name(),ce_Timeframe);
   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSignalKalman::CalculateIndicators(void)
  {
   //--- Check time of last calculation
   datetime current=(datetime)SeriesInfoInteger(m_symbol.Name(),ce_Timeframe,SERIES_LASTBAR_DATE);
   if(current==cdt_LastCalcIndicators)
      return true;                  // Exit if data alredy calculated on this bar
   
   if(cd_corretion==QNaN)
     {
      if(CheckPointer(Kalman)==POINTER_INVALID)
        {
         Kalman=new CKalman(ci_HistoryBars,ci_ShiftPeriod,m_symbol.Name(),ce_Timeframe);
         if(CheckPointer(Kalman)==POINTER_INVALID)
           {
            return false;
           }
        }
      else
         Kalman.Clear_AR_Flag();
     }

   //--- Calculate indicators data
   int shift=StartIndex();
   int bars=Bars(m_symbol.Name(),ce_Timeframe,current,cdt_LastCalcIndicators);
   if(bars>(int)fmax(ci_ShiftPeriod,1))
     {
      bars=(int)fmax(ci_ShiftPeriod,1);
      Kalman.Clear_AR_Flag();
     }
   double close[];
   if(m_close.GetData(shift,bars+1,close)<=0)
     {
      return false;
     }
  
   for(uint i=bars;i>0;i--)
     {
      cd_forecast=Kalman.Forecast();
      cd_corretion=Kalman.Correction(close[i]);
     }
  
   if(cd_forecast==EMPTY_VALUE || cd_forecast==0 || cd_corretion==EMPTY_VALUE || cd_corretion==0)
      return false;
  
   cdt_LastCalcIndicators=current;
  //---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalKalman::LongCondition(void)
  {
   if(!CalculateIndicators())
      return 0;
   int result=0;
   //--- 
   if(cd_corretion>cd_forecast)
      result=80;
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalKalman::ShortCondition(void)
  {
   if(!CalculateIndicators())
      return 0;
   int result=0;
   //--- 
   if(cd_corretion<cd_forecast)
      result=80;
   return result;
  }
//+------------------------------------------------------------------+
