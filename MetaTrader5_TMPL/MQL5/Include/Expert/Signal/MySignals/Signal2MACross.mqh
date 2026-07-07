//+------------------------------------------------------------------+
//|                                               Signal2MACross.mqh |
//|                                    Copyright (c) 2018, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>

// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of 2 MAs crosses                                   |
//| Type=SignalAdvanced                                              |
//| Name=2MA Cross                                                   |
//| ShortName=2MACross                                               |
//| Class=Signal2MACross                                             |
//| Page=signal_2mac                                                 |
//| Parameter=SlowPeriod,int,11,Slow MA period                       |
//| Parameter=FastPeriod,int,7,Fast Ma period                        |
//| Parameter=MAMethod,ENUM_MA_METHOD,MODE_LWMA,Method of averaging  |
//| Parameter=MAPrice,ENUM_APPLIED_PRICE,PRICE_OPEN,Price type       |
//| Parameter=Shift,int,0,Shift                                      |
//+------------------------------------------------------------------+
// wizard description end

//+------------------------------------------------------------------+
//| Class Signal2MACross.                                            |
//| Purpose: Generator of trade signals based on 2 MAs crosses.      |
//+------------------------------------------------------------------+
class Signal2MACross : public CExpertSignal
{
  protected:
    CiMA              m_maSlow;         // object-indicator
    CiMA              m_maFast;         // object-indicator
    
    // adjustable parameters
    int               m_slow;
    int               m_fast;
    ENUM_MA_METHOD    m_method;
    ENUM_APPLIED_PRICE m_type;
    int               m_shift;
    
    // "weights" of market models (0-100)
    int               m_pattern_0;      // model 0 "fast MA crosses slow MA"

  public:
                      Signal2MACross(void);
                     ~Signal2MACross(void);
                     
    // parameters setters
    void              SlowPeriod(int value) { m_slow = value; }
    void              FastPeriod(int value) { m_fast = value; }
    void              MAMethod(ENUM_MA_METHOD value) { m_method = value; }
    void              MAPrice(ENUM_APPLIED_PRICE value) { m_type = value; }
    void              Shift(int value) { m_shift = value; }
    
    // adjusting "weights" of market models
    void              Pattern_0(int value) { m_pattern_0 = value; }
    
    // verification of settings
    virtual bool      ValidationSettings(void);
    
    // creating the indicator and timeseries
    virtual bool      InitIndicators(CIndicators *indicators);
    
    // checking if the market models are formed
    virtual int       LongCondition(void);
    virtual int       ShortCondition(void);

  protected:
    // initialization of the indicators
    bool              InitMAs(CIndicators *indicators);
    
    // helper functions to read indicators' data
    double            FastMA(int ind) { return(m_maFast.Main(ind)); }
    double            SlowMA(int ind) { return(m_maSlow.Main(ind)); }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
Signal2MACross::Signal2MACross(void) : m_slow(11), m_fast(7), m_method(MODE_LWMA), m_type(PRICE_OPEN), m_shift(0), m_pattern_0(100)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
Signal2MACross::~Signal2MACross(void)
{
}

//+------------------------------------------------------------------+
//| Validation settings protected data                               |
//+------------------------------------------------------------------+
bool Signal2MACross::ValidationSettings(void)
{
  if(!CExpertSignal::ValidationSettings()) return(false);
  return(true);
}

//+------------------------------------------------------------------+
//| Create indicators                                                |
//+------------------------------------------------------------------+
bool Signal2MACross::InitIndicators(CIndicators *indicators)
{
  if(indicators == NULL) return(false);
  if(!CExpertSignal::InitIndicators(indicators)) return(false);
  if(!InitMAs(indicators)) return(false);
  return(true);
}

//+------------------------------------------------------------------+
//| Create MA indicators                                             |
//+------------------------------------------------------------------+
bool Signal2MACross::InitMAs(CIndicators *indicators)
{
  if(indicators == NULL) return(false);

  // initialize object
  if(!m_maFast.Create(m_symbol.Name(), m_period, m_fast, m_shift, m_method, m_type)
  || !m_maSlow.Create(m_symbol.Name(), m_period, m_slow, m_shift, m_method, m_type))
  {
    printf(__FUNCTION__ + ": error initializing object");
    return(false);
  }
  
  // add object to collection
  if(!indicators.Add(GetPointer(m_maFast))
  || !indicators.Add(GetPointer(m_maSlow)))
  {
    printf(__FUNCTION__ + ": error adding object");
    return(false);
  }
  
  return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow                                    |
//+------------------------------------------------------------------+
int Signal2MACross::LongCondition(void)
{
  int result = 0;
  int idx = StartIndex();
  
  if(FastMA(idx) > SlowMA(idx))
  {
    result = m_pattern_0;
  }
  return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall                                    |
//+------------------------------------------------------------------+
int Signal2MACross::ShortCondition(void)
{
  int result = 0;
  int idx = StartIndex();

  if(FastMA(idx) < SlowMA(idx))
  {
    result = m_pattern_0;
  }
  return(result);
}
//+------------------------------------------------------------------+
