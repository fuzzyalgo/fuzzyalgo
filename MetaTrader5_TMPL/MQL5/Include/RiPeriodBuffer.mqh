//+------------------------------------------------------------------+
//|                                                   RingBuffer.mqh |
//|                                    Copyright 2017  Andre Howe    |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Andre Howe"
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| 
//+------------------------------------------------------------------+

#include <Object.mqh>


enum ENUM_BUF_IDX 
{
    IDX_DATETIME = 0,
    IDX_CLOSE,
    
    IDX_BO1,
    IDX_BO1_INT0,
    IDX_BO1_INT1,
    IDX_BO1_INT2,
    IDX_BO1_INT3,
    
    IDX_BO2,
    IDX_BO2_INT0,
    IDX_BO2_INT1,
    IDX_BO2_INT2,
    IDX_BO2_INT3,
    
    IDX_BO3,
    IDX_BO3_INT0,
    IDX_BO3_INT1,
    IDX_BO3_INT2,
    IDX_BO3_INT3,
    
    IDX_DIFF,
    IDX_MAX
};

const string gStrBufIdxArr[] = {
    "DT",
    "CLOSE",
    "BO1",
    "BO1-INT0",
    "BO1-INT1",
    "BO1-INT2",
    "BO1-INT3",
    "BO2",
    "BO2-INT0",
    "BO2-INT1",
    "BO2-INT2",
    "BO2-INT3",
    "BO3",
    "BO3-INT0",
    "BO3-INT1",
    "BO3-INT2",
    "BO3-INT3",
    "DIFF",
};

struct SPeriodBuffer
{
    double SHIFTIDX;
    double PERIOD;

    //
    // ENUM_BUF_IDX buffer structure start
    //
    double DATETIME;
    double CLOSE;
    double BO1;
    double BO1INT0;
    double BO1INT1;
    double BO1INT2;
    double BO1INT3;
    double BO2;
    double BO2INT0;
    double BO2INT1;
    double BO2INT2;
    double BO2INT3;
    double BO3;
    double BO3INT0;
    double BO3INT1;
    double BO3INT2;
    double BO3INT3;
    double DIFF;
    //
    // ENUM_BUF_IDX buffer structure end
    //

    //
    // result buffer start
    //
    double BUY0;
    double SELL0;
    double EXIT0;

    double BUY1;
    double SELL1;
    double EXIT1;

    double BUY2;
    double SELL2;
    double EXIT2;

    double BUY3;
    double SELL3;
    double EXIT3;

    //
    // result buffer end
    //
    
};


class CPeriodBuffer : public CObject
{
private:
    bool            m_configured;
    int             m_max_total;
    int             m_period;
    int             m_period_idx;
    ENUM_TIMEFRAMES m_period_tf;
    string          m_period_str;

    double    BO_PERCENT1;   // BO_PERCENT1 - breakout percentage
    double    BO_PERCENT2;   // BO_PERCENT2 - breakout percentage
    double    BO_PERCENT3;   // BO_PERCENT3 - breakout percentage

    
    double         m_buf0[];
    double         m_buf1[];
    double         m_buf2[];
    double         m_buf3[];
    double         m_buf4[];
    double         m_buf5[];
    double         m_buf6[];
    double         m_buf7[];
    double         m_buf8[];
    double         m_buf9[];
    double         m_buf10[];
    double         m_buf11[];
    double         m_buf12[];
    double         m_buf13[];
    double         m_buf14[];
    double         m_buf15[];
    double         m_buf16[];
    double         m_buf17[];
    double         m_buf18[];
    double         m_buf19[];
    
public:
    CPeriodBuffer(ENUM_TIMEFRAMES tf, string tf_str, int period, int period_idx, double bo_percent);
    int            ConfigBuffers( int& plot_index, int& idx_buf_index );
    void           Set( ENUM_BUF_IDX buf_index, int shift_index, const double value );
    double         Get( ENUM_BUF_IDX buf_index, int shift_index );
    SPeriodBuffer  GetStruct( int shift_index );
    int            GetPeriod   ( void ) { return m_period; };
    int            GetPeriodIdx( void ) { return m_period_idx; };
    string         GetPeriodStr( void ) { return m_period_str; };
    int            CalcValues( int shift_index );
   
    int     GetShiftSinceDayStarted( int shift );
    int     GetShiftSinceWeekStarted( int shift );
    int     GetShiftSinceMonthStarted( int shift );
    int     GetShiftSinceYearStarted( int shift );
   
};

//+------------------------------------------------------------------+
//| Constructor2                                                      |
//+------------------------------------------------------------------+
CPeriodBuffer::CPeriodBuffer(ENUM_TIMEFRAMES tf, string tf_str, int period, int period_idx, const double bo_percent) :   
                                    m_configured(false),
                                    m_max_total(0),
                                    m_period(0),
                                    m_period_idx(0)
{

    BO_PERCENT3 = bo_percent;
    BO_PERCENT2 = NormalizeDouble( bo_percent*0.6666, 2 );
    BO_PERCENT1 = NormalizeDouble( bo_percent*0.3333, 2 );

    // convert the timeframe into minutes
    m_period_tf = tf;
    m_period = period; //PeriodSeconds( m_period_tf ) / 60;
    m_period_str = tf_str;
    m_period_idx = period_idx;
    
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Configure2
//+------------------------------------------------------------------+
int CPeriodBuffer::ConfigBuffers( int& plot_index, int& idx_buf_index )
{

    // IDX_DATETIME - m_buf0
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_DATETIME] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf0,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf0,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_CLOSE - m_buf4
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_CLOSE] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf1,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf1,     true );
    plot_index++;
    idx_buf_index++;


    // IDX_BO1 - m_buf2
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO1] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf2,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf2,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO1_INT0 - m_buf3
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO1_INT0] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf3,        INDICATOR_DATA );
    ArraySetAsSeries    (m_buf3,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO1_INT1 - m_buf4
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO1_INT1] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf4,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf4,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO1_INT2 - m_buf5
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO1_INT2] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf5,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf5,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO1_INT3 - m_buf6
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO1_INT3] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf6,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf6,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO2 - m_buf7
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO2] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf7,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf7,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO2_INT0 - m_buf8
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO2_INT0] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf8,        INDICATOR_DATA );
    ArraySetAsSeries    (m_buf8,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO2_INT1 - m_buf9
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO2_INT1] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf9,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf9,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO2_INT2 - m_buf10
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO2_INT2] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf10,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf10,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO2_INT3 - m_buf11
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO2_INT3] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf11,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf11,     true );
    plot_index++;
    idx_buf_index++;


    // IDX_BO3 - m_buf12
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO3] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf12,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf12,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO3_INT0 - m_buf13
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO3_INT0] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf13,        INDICATOR_DATA );
    ArraySetAsSeries    (m_buf13,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO3_INT1 - m_buf14
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO3_INT1] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf14,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf14,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO3_INT2 - m_buf15
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO3_INT2] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf15,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf15,     true );
    plot_index++;
    idx_buf_index++;

    // IDX_BO3_INT3 - m_buf16
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_BO3_INT3] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf16,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf16,     true );
    plot_index++;
    idx_buf_index++;


    // IDX_DIFF - m_buf17
    PlotIndexSetString  (plot_index, PLOT_LABEL,        m_period_str + "_" + gStrBufIdxArr[IDX_DIFF] );     
    PlotIndexSetInteger (plot_index, PLOT_DRAW_TYPE,    DRAW_NONE); 
    PlotIndexSetInteger (plot_index, PLOT_SHOW_DATA,    true); 
    //PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE,  0.0 );
    SetIndexBuffer      (idx_buf_index, m_buf17,         INDICATOR_DATA );
    ArraySetAsSeries    (m_buf17,     true );
    plot_index++;
    idx_buf_index++;

    m_configured = true;
    // return no error if the system is configured
    if( true == m_configured )
        return 0;
    else
        return -1;
} // int CPeriodBuffer::ConfigBuffers( int& plot_index, int& idx_buf_index )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Set                                                     
//+------------------------------------------------------------------+
void CPeriodBuffer::Set( ENUM_BUF_IDX buf_index, int shift_index, const double value )
{
    double high = 0;
    double low  = 0;
    double pivot= 0;
    double A    = 0;

    switch( buf_index )
    {
        case IDX_DATETIME: 
                m_buf0[shift_index] = value;
            break;
        case IDX_CLOSE: 
                m_buf1[shift_index] = value;
            break;
        case IDX_BO1: 
                m_buf2[shift_index] = value;
            break;
        case IDX_BO1_INT0: 
                m_buf3[shift_index] = value;
            break;
        case IDX_BO1_INT1: 
                m_buf4[shift_index] = value;
            break;
        case IDX_BO1_INT2: 
                m_buf5[shift_index] = value;
            break;
        case IDX_BO1_INT3: 
                m_buf6[shift_index] = value;
            break;
            
        case IDX_BO2: 
                m_buf7[shift_index] = value;
            break;
        case IDX_BO2_INT0: 
                m_buf8[shift_index] = value;
            break;
        case IDX_BO2_INT1: 
                m_buf9[shift_index] = value;
            break;
        case IDX_BO2_INT2: 
                m_buf10[shift_index] = value;
            break;
        case IDX_BO2_INT3: 
                m_buf11[shift_index] = value;
            break;
            
        case IDX_BO3: 
                m_buf12[shift_index] = value;
            break;
        case IDX_BO3_INT0: 
                m_buf13[shift_index] = value;
            break;
        case IDX_BO3_INT1: 
                m_buf14[shift_index] = value;
            break;
        case IDX_BO3_INT2: 
                m_buf15[shift_index] = value;
            break;
        case IDX_BO3_INT3: 
                m_buf16[shift_index] = value;
            break;
            
        case IDX_DIFF: 
                m_buf17[shift_index] = value;
            break;
        // TODO implement error handling
        //if( false == m_configured )
        //    return -1;
        //default:
        //    return -1;
    };
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get                                                     
//+------------------------------------------------------------------+
double CPeriodBuffer::Get( ENUM_BUF_IDX buf_index, int shift_index )
{
    double value = 0.0;
    
    switch( buf_index )
    {
        case IDX_DATETIME: 
                value = m_buf0[shift_index];
            break;
        case IDX_CLOSE: 
                value = m_buf1[shift_index];
            break;
            
        case IDX_BO1: 
                value = m_buf2[shift_index];
            break;
        case IDX_BO1_INT0: 
                value = m_buf3[shift_index];
            break;
        case IDX_BO1_INT1: 
                value = m_buf4[shift_index];
            break;
        case IDX_BO1_INT2: 
                value = m_buf5[shift_index];
            break;
        case IDX_BO1_INT3: 
                value = m_buf6[shift_index];
            break;
            
        case IDX_BO2: 
                value = m_buf7[shift_index];
            break;
        case IDX_BO2_INT0: 
                value = m_buf8[shift_index];
            break;
        case IDX_BO2_INT1: 
                value = m_buf9[shift_index];
            break;
        case IDX_BO2_INT2: 
                value = m_buf10[shift_index];
            break;
        case IDX_BO2_INT3: 
                value = m_buf11[shift_index];
            break;
            
        case IDX_BO3: 
                value = m_buf12[shift_index];
            break;
        case IDX_BO3_INT0: 
                value = m_buf13[shift_index];
            break;
        case IDX_BO3_INT1: 
                value = m_buf14[shift_index];
            break;
        case IDX_BO3_INT2: 
                value = m_buf15[shift_index];
            break;
        case IDX_BO3_INT3: 
                value = m_buf16[shift_index];
            break;
            
        case IDX_DIFF: 
                value = m_buf17[shift_index];
            break;
        // TODO implement error handling
        //default:
        //    return -1;
    };
    return value;
}
//+------------------------------------------------------------------+

SPeriodBuffer CPeriodBuffer::GetStruct( int shift_index )
{
    SPeriodBuffer value;
    
    value.SHIFTIDX  = shift_index;
    value.PERIOD    = GetPeriod();
    
    value.DATETIME  = m_buf0[shift_index];
    value.CLOSE     = m_buf1[shift_index];
    
    value.BO1       = m_buf2[shift_index];
    value.BO1INT0   = m_buf3[shift_index];
    value.BO1INT1   = m_buf4[shift_index];
    value.BO1INT2   = m_buf5[shift_index];
    value.BO1INT3   = m_buf6[shift_index];
    
    value.BO2       = m_buf7[shift_index];
    value.BO2INT0   = m_buf8[shift_index];
    value.BO2INT1   = m_buf9[shift_index];
    value.BO2INT2   = m_buf10[shift_index];
    value.BO2INT3   = m_buf11[shift_index];
    
    value.BO3       = m_buf12[shift_index];
    value.BO3INT0   = m_buf13[shift_index];
    value.BO3INT1   = m_buf14[shift_index];
    value.BO3INT2   = m_buf15[shift_index];
    value.BO3INT3   = m_buf16[shift_index];
    
    value.DIFF      = m_buf17[shift_index];
    
    // clear result buffer
    value.BUY0      = 0.0;
    value.SELL0     = 0.0;
    value.EXIT0     = 0.0;
    value.BUY1      = 0.0;
    value.SELL1     = 0.0;
    value.EXIT1     = 0.0;
    value.BUY2      = 0.0;
    value.SELL2     = 0.0;
    value.EXIT2     = 0.0;
    value.BUY3      = 0.0;
    value.SELL3     = 0.0;
    value.EXIT3     = 0.0;
    
    return value;
}



//+------------------------------------------------------------------+
//| CalcValues                                                     
//+------------------------------------------------------------------+
int  CPeriodBuffer::CalcValues( int shift_index )
{

    int delta_to_prev_period = 1;//GetPeriod();
    int shift_prev = shift_index + GetPeriod()/* - 1*/;

    //
    // CMP1 - BO_PERCENT1
    //
    double price, Middle_prev; 
    double var1= BO_PERCENT1 /100;
    double plusvar=1+var1;
    double minusvar=1-var1;
    double Middle = 0; 
    price =       Get( IDX_CLOSE, shift_index );
    Middle_prev = Get( IDX_BO1,   shift_prev  );
    // calculate BO-MIDDLE
    if((price*minusvar)>Middle_prev) 
    {
        Middle=price*minusvar;
    }
    else if(price*plusvar<Middle_prev)
    {
        Middle=price*plusvar;
    }
    else
    { 
        Middle=Middle_prev;
    }
    // calculate BO-UP
    //Middle = Middle + Middle * var1;
    // calculate BO-DOWN
    //Middle = Middle - Middle * var1;
    Set( IDX_BO1, shift_index, Middle );

    //
    // CMP1 - BO_PERCENT2
    //
    var1= BO_PERCENT2 /100;
    plusvar=1+var1;
    minusvar=1-var1;
    Middle = 0; 
    price       = Get( IDX_CLOSE, shift_index );
    Middle_prev = Get( IDX_BO2,   shift_prev );
    // calculate BO-MIDDLE
    if((price*minusvar)>Middle_prev) 
    {
        Middle=price*minusvar;
    }
    else if(price*plusvar<Middle_prev)
    {
        Middle=price*plusvar;
    }
    else
    { 
        Middle=Middle_prev;
    }
    // calculate BO-UP
    //Middle = Middle + Middle * var1;
    // calculate BO-DOWN
    //Middle = Middle - Middle * var1;
    Set( IDX_BO2, shift_index, Middle );

    //
    // CMP1 - BO_PERCENT3
    //
    var1= BO_PERCENT3 /100;
    plusvar=1+var1;
    minusvar=1-var1;
    Middle = 0; 
    price       = Get( IDX_CLOSE, shift_index );
    Middle_prev = Get( IDX_BO3,   shift_prev  );
    // calculate BO-MIDDLE
    if((price*minusvar)>Middle_prev) 
    {
        Middle=price*minusvar;
    }
    else if(price*plusvar<Middle_prev)
    {
        Middle=price*plusvar;
    }
    else
    { 
        Middle=Middle_prev;
    }
    // calculate BO-UP
    //Middle = Middle + Middle * var1;
    // calculate BO-DOWN
    //Middle = Middle - Middle * var1;
    Set( IDX_BO3, shift_index, Middle );
    
    
    //
    // CMP2 - differential            
    //
    double close0, close1, diff;
    close0 = Get( IDX_CLOSE, shift_index );
    close1 = Get( IDX_CLOSE, shift_prev  );
    diff = ((close0 - close1)/Point());
    Set( IDX_DIFF,  shift_index, diff );

    
    //
    // CMP3 - CMP-BOX but called INTX
    // 
    int idx_0 = GetShiftSinceDayStarted(   0 );
    int idx_1 = GetShiftSinceWeekStarted(  0 );
    int idx_2 = GetShiftSinceMonthStarted( 0 );
    // TODO check that idx_3 is smaller than rates_total
    //  some symbols only load limited data
    //  there shall be a loading sequence somewhere
    //  telling indicator to load at least one year of data
    //  this could be fixed as well that this data is loaded
    //int idx_3 = idx_2; //GetShiftSinceYearStarted(  0 );
    int idx_3 = GetShiftSinceYearStarted(  0 );

    double bo1, bo0;

    ENUM_BUF_IDX IDX_BO = IDX_BO1;
    
    /*double bo1 = Get( IDX_BO, shift_index+idx_0 );
    double bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO1_INT0, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_1 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO1_INT1, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_2 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO1_INT2, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_3 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO1_INT3, shift_index, (bo0 - bo1)/Point() );*/

    double high = 0;
    double low  = 0;
    double pivot= 0;
    double A    = 0;
    high = m_buf1[ArrayMaximum(m_buf1, shift_index, delta_to_prev_period*240)];
    low  = m_buf1[ArrayMinimum(m_buf1, shift_index, delta_to_prev_period*240)];
    pivot=( m_buf1[shift_index+1]+m_buf1[shift_index+2]+m_buf1[shift_index+3] )/3;
    A=(m_buf1[shift_index+0]-((high + low + pivot)/3))/Point();
    //pivot=( m_buf1[shift_index+0]+m_buf1[shift_index+1]+m_buf1[shift_index+2] )/3;
    //A=(pivot-((high + low)/2))/Point();
    Set( IDX_BO1_INT0, shift_index, A );

    high = m_buf1[ArrayMaximum(m_buf1, shift_index, delta_to_prev_period*60)];
    low  = m_buf1[ArrayMinimum(m_buf1, shift_index, delta_to_prev_period*60)];
    pivot=( m_buf1[shift_index+1]+m_buf1[shift_index+2]+m_buf1[shift_index+3] )/3;
    A=(m_buf1[shift_index+0]-((high + low + pivot)/3))/Point();
    //pivot=( m_buf1[shift_index+0]+m_buf1[shift_index+1]+m_buf1[shift_index+2] )/3;
    //A=(pivot-((high + low)/2))/Point();
    Set( IDX_BO1_INT1, shift_index, A );

    high = m_buf1[ArrayMaximum(m_buf1, shift_index, delta_to_prev_period*15)];
    low  = m_buf1[ArrayMinimum(m_buf1, shift_index, delta_to_prev_period*15)];
    pivot=( m_buf1[shift_index+1]+m_buf1[shift_index+2]+m_buf1[shift_index+3] )/3;
    A=(m_buf1[shift_index+0]-((high + low + pivot)/3))/Point();
    //pivot=( m_buf1[shift_index+0]+m_buf1[shift_index+1]+m_buf1[shift_index+2] )/3;
    //A=(pivot-((high + low)/2))/Point();
    Set( IDX_BO1_INT2, shift_index, A );

    high = m_buf1[ArrayMaximum(m_buf1, shift_index, delta_to_prev_period*5)];
    low  = m_buf1[ArrayMinimum(m_buf1, shift_index, delta_to_prev_period*5)];
    pivot=( m_buf1[shift_index+1]+m_buf1[shift_index+2]+m_buf1[shift_index+3] )/3;
    A=(m_buf1[shift_index+0]-((high + low + pivot)/3))/Point();
    //pivot=( m_buf1[shift_index+0]+m_buf1[shift_index+1]+m_buf1[shift_index+2] )/3;
    //A=(pivot-((high + low)/2))/Point();
    Set( IDX_BO1_INT3, shift_index, A );

    IDX_BO = IDX_BO2;
    
    bo1 = Get( IDX_BO, shift_index+idx_0 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO2_INT0, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_1 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO2_INT1, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_2 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO2_INT2, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_3 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO2_INT3, shift_index, (bo0 - bo1)/Point() );

    IDX_BO = IDX_BO3;
    
    bo1 = Get( IDX_BO, shift_index+idx_0 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO3_INT0, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_1 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO3_INT1, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_2 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO3_INT2, shift_index, (bo0 - bo1)/Point() );

    bo1 = Get( IDX_BO, shift_index+idx_3 );
    bo0 = Get( IDX_BO, shift_index );
    Set( IDX_BO3_INT3, shift_index, (bo0 - bo1)/Point() );
  
    
    return 0;
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   CPeriodBuffer::GetShiftSinceDayStarted
//+------------------------------------------------------------------+
int CPeriodBuffer::GetShiftSinceDayStarted( int shift )
{
    /*MqlDateTime tm;
    datetime starttime = iTime(m_symbol, m_period,shift);
    TimeToStruct( starttime, tm );
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    shift = iBarShift(m_symbol, m_period,starttime,stoptime);*/
    
    shift = 24 * 3600/PeriodSeconds(m_period_tf);
    return (shift);
    
} // int CPeriodBuffer::GetShiftSinceDayStarted( int shift )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   CPeriodBuffer::GetShiftSinceWeekStarted
//+------------------------------------------------------------------+
int CPeriodBuffer::GetShiftSinceWeekStarted( int shift )
{
    /*MqlDateTime tm;
    datetime t0 = iTime(m_symbol, m_period,shift);
    TimeToStruct( t0, tm );
    int days = 0;
    days = tm.day_of_week -1;
    if( 0 > days ) days = 0;
    if( 4 < days ) days = 4;
    datetime starttime = t0;
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    stoptime = stoptime - (datetime)(days*24*60*60);
    shift = iBarShift(m_symbol, m_period,starttime,stoptime);*/
    
    shift = 24*5 * 3600/PeriodSeconds(m_period_tf);
    return (shift);
    
} // int CPeriodBuffer::GetShiftSinceWeekStarted( int shift )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   CPeriodBuffer::GetShiftSinceMonthStarted
//+------------------------------------------------------------------+
int CPeriodBuffer::GetShiftSinceMonthStarted( int shift )
{
    /*datetime starttime = iTime(m_symbol, m_period,shift);
    MqlDateTime tm;
    TimeToStruct( starttime, tm );
    tm.day  = 1;
    tm.hour = 0;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    TimeToStruct( stoptime, tm );
    // on Sunday forward to Monday
    if( 0 == tm.day_of_week )
        tm.day  = tm.day+1;
    // on Saturday forward to Monday
    if( 6 == tm.day_of_week )
        tm.day  = tm.day+2;
    stoptime = StructToTime( tm );
    //Print( "i: " + string (shift ) + " startdt: " + string (starttime ) + " enddt: " + string (stoptime ));
    shift = iBarShift(m_symbol, m_period,starttime,stoptime);*/
    
    shift = 24*5*4 * 3600/PeriodSeconds(m_period_tf);
    return (shift);
    
} // int CPeriodBuffer::GetShiftSinceMonthStarted( int shift )
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   CPeriodBuffer::GetShiftSinceYearStarted
//+------------------------------------------------------------------+
int CPeriodBuffer::GetShiftSinceYearStarted( int shift )
{
    /*datetime starttime = iTime(m_symbol, m_period,shift);
    MqlDateTime tm;
    TimeToStruct( starttime, tm );
    tm.mon  = 1;
    tm.day  = 2;
    tm.hour = 12;
    tm.sec  = 0;
    tm.min  = 0;
    datetime stoptime = StructToTime( tm );
    TimeToStruct( stoptime, tm );
    // on Sunday forward to Monday
    if( 0 == tm.day_of_week )
        tm.day  = tm.day+1;
    // on Saturday forward to Monday
    if( 6 == tm.day_of_week )
        tm.day  = tm.day+2;
    stoptime = StructToTime( tm );
    //Print( "i: " + string (shift ) + " startdt: " + string (starttime ) + " enddt: " + string (stoptime ));
    shift = iBarShift(m_symbol, m_period,starttime,stoptime);*/
    
    shift = 24*5*4*12 * 3600/PeriodSeconds(m_period_tf);
    return (shift);
    
} // int CPeriodBuffer::GetShiftSinceYearStarted( int shift )
//+------------------------------------------------------------------+

