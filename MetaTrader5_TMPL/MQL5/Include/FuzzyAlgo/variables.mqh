//+------------------------------------------------------------------+
//|                                                    variables.mqh |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link "https://www.fuzzyalgo.com"

// I N C L U D E S

// T Y P E D E F S
enum ENUM_PERIOD_TYPE
{
    ENUM_PERIOD_TYPE_NONE,
    ENUM_PERIOD_TYPE_PRO,
    ENUM_PERIOD_TYPE_SECONDS_S,
    ENUM_PERIOD_TYPE_TICKS_T,
    ENUM_PERIOD_TYPE_AVERAGE_S,
    ENUM_PERIOD_TYPE_AVERAGE_T,
    ENUM_PERIOD_TYPE_AVERAGE_SUM,
    ENUM_PERIOD_TYPE_MAX
};

// I N P U T S
// dynamic inputs
input string I_ACCOUNT = "RF5D03"; // forex account name
input string I_SYMBOLS = "EURUSD:EURGBP:GBPJPY:NZDUSD";
input string I_PERIODS = "PRO:T15:T30:T60:T_AVG:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
input string I_HOSTS = "vm1.localhost:vm2.localhost:vm3.localhost";             // hosts where the forex expert is running
// static inputs
input ENUM_COPY_TICKS I_COPY_TICKS_FLAG = COPY_TICKS_TIME_MS; // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL
input int I_DEBUG = 0;                                        // enable debug output
input int I_EVENT_TIMER_INTERVAL_MSC = 1000;                  // Event Timer Interval in milliseconds

// input string PERIODS = "T60:T300:T900:T3600:T_AVG:S60:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG:S15:S30:S60:S300:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG";            // periods are seperated by colon. T for Ticks and S for seconds

// G L O B A L S
struct sData;

int string_split_g(const string &in_string_to_split, const string &in_seperator, string &out_split_array[])
{
    ushort u_sep = StringGetCharacter(in_seperator, 0);                       //--- Get the separator code
    int num_splits = StringSplit(in_string_to_split, u_sep, out_split_array); //--- Split the string to substrings
    if ((num_splits != ArraySize(out_split_array)) || (0 >= num_splits))
        Print("@TODO throw exception here - string_split_g " + in_string_to_split + " " + in_seperator);
    return num_splits;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void get_period_num_and_type_g(const string &in_period_key, int &out_period_num, ENUM_PERIOD_TYPE &out_period_type)
{

    if ("PRO" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_PRO;
        out_period_num = 0;
    }
    else if ("T15" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
        out_period_num = 15;
    }
    else if ("T30" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
        out_period_num = 30;
    }
    else if ("T60" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
        out_period_num = 60;
    }
    else if ("T300" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
        out_period_num = 300;
    }
    else if ("T900" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
        out_period_num = 900;
    }
    else if ("T3600" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
        out_period_num = 3600;
    }
    else if ("T_AVG" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_AVERAGE_T;
        out_period_num = 0;
    }
    else if ("S15" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
        out_period_num = 15;
    }
    else if ("S30" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
        out_period_num = 30;
    }
    else if ("S60" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
        out_period_num = 60;
    }
    else if ("S300" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
        out_period_num = 300;
    }
    else if ("S900" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
        out_period_num = 900;
    }
    else if ("S3600" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
        out_period_num = 3600;
    }
    else if ("S_AVG" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_AVERAGE_S;
        out_period_num = 0;
    }
    else if ("SUM_AVG" == in_period_key)
    {
        out_period_type = ENUM_PERIOD_TYPE_AVERAGE_SUM;
        out_period_num = 0;
    }
    else
    {
        Print("@TODO throw exception here - get_period_num_and_type_g " + in_period_key);
    }

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // void get_period_num_and_type_g( const string &in_period_key, int & out_period_num, ENUM_PERIOD_TYPE& out_period_type )
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool init_data_from_ticks_arr_g(
    const datetime &in_time_msc,
    const string &in_symbol,
    const int &in_period_num,
    const ENUM_PERIOD_TYPE &in_period_type,
    const MqlTick &in_array[],
    double &out_ticks_arr[],
    sData &out_data)
{
    // local variables
    int spread = 0;
    double high = 0;
    double low = 1000000000;

    // set c0, c1, t0, t1, OC
    bool ret = true;
    int size1 = ArraySize(in_array);
    double point = SymbolInfoDouble(in_symbol, SYMBOL_POINT);
    out_data.c0 = (in_array[size1 - 1].ask + in_array[size1 - 1].bid) / 2;
    out_data.t0 = in_array[size1 - 1].time_msc;
    out_data.c1 = (in_array[0].ask + in_array[0].bid) / 2;
    out_data.t1 = in_array[0].time_msc;
    out_data.OC = (int)((out_data.c0 - out_data.c1) / point);
    out_data.VOLS = size1;

    ArrayResize(out_ticks_arr, size1);
    double p1 = out_data.c1;
    for (int cnt = 0; cnt < size1; cnt++)
    {

        // sanity check
        if (in_array[cnt].ask == 0 || in_array[cnt].bid == 0 || in_array[cnt].ask < in_array[cnt].bid)
        {
            Print("@TODO throw exception here - init_ticks_arr_g ASK | BID" + in_symbol + " " + IntegerToString(in_period_num) + " " + EnumToString(in_period_type) + " " + DoubleToString(in_array[cnt].ask) + " " + DoubleToString(in_array[cnt].bid));
            ret = false;
            continue;
        }

        // set ticks_arr
        double p0 = ((in_array[cnt].ask + in_array[cnt].bid) / 2);
        out_ticks_arr[cnt] = ((p0 - p1) / point);

        // set HL & SPREAD
        if (high < in_array[cnt].ask)
            high = in_array[cnt].ask;
        if (low > in_array[cnt].bid)
            low = in_array[cnt].bid;
        int s = (int)((in_array[cnt].ask - in_array[cnt].bid) / point);
        if (spread < s)
            spread = s;
        out_data.HL = (int)((high - low) / point);
        out_data.SPREAD = spread;

    } // for (int cnt = 0; cnt < size1; cnt++)

    return ret;
    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // bool init_data_from_ticks_arr_g
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool init_ticks_arr_g(
    const datetime &in_time_msc,
    const string &in_symbol,
    const int &in_period_num,
    const ENUM_PERIOD_TYPE &in_period_type,
    double &out_ticks_arr[],
    sData &out_data)
{

    sConfigVars conf;
    bool ret = true;

    if (ENUM_PERIOD_TYPE_SECONDS_S == in_period_type)
    {

        ret = false;
        MqlTick in_array[];
        int size1 = CopyTicksRange(in_symbol, in_array, conf.c.COPY_TICKS_FLAG, in_time_msc - in_period_num * 1000, in_time_msc);
        if (0 < size1)
        {

            ret = init_data_from_ticks_arr_g(
                in_time_msc,
                in_symbol,
                in_period_num,
                in_period_type,
                in_array,
                out_ticks_arr,
                out_data);
            if (false == ret)
                Print("@TODO throw exception here - init_ticks_arr_g " + in_symbol + " " + IntegerToString(in_period_num) + " " + EnumToString(in_period_type));

        } // if (0 < size1)

    } // if (ENUM_PERIOD_TYPE_SECONDS_S == period_type )

    else if (ENUM_PERIOD_TYPE_TICKS_T == in_period_type)
    {

        ret = false;
        MqlTick src_array[];
        int src_size = 0;
        for (int inc_cnt = 5; inc_cnt < 15; inc_cnt++)
        {
            src_size = CopyTicksRange(in_symbol, src_array, conf.c.COPY_TICKS_FLAG, in_time_msc - inc_cnt * in_period_num * 1000, in_time_msc);
            if (src_size > in_period_num)
                break;
        }

        if (src_size > in_period_num)
        {

            MqlTick in_array[];
            ArrayCopy(in_array, src_array, 0, (src_size - in_period_num), in_period_num);
            int size1 = ArraySize(in_array);
            if (in_period_num == size1)
            {

                ret = init_data_from_ticks_arr_g(
                    in_time_msc,
                    in_symbol,
                    in_period_num,
                    in_period_type,
                    in_array,
                    out_ticks_arr,
                    out_data);
                if (false == ret)
                    Print("@TODO throw exception here - init_ticks_arr_g " + in_symbol + " " + IntegerToString(in_period_num) + " " + EnumToString(in_period_type));

            } // if ( period_num == dst_size)

        } // if (size1 > period_num)

    } // if (ENUM_PERIOD_TYPE_SECONDS_T == period_type )

    return ret;
    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // bool init_ticks_arr_g
//+------------------------------------------------------------------+

struct sConfigVars
{
    struct sConfig
    {
        // dynamic inputs
        string ACCOUNT;

        string SYMBOLS;
        int SYMBOLS_num;
        string SYMBOLS_arr[];

        string PERIODS;
        int PERIODS_num;
        string PERIODS_arr[];

        string HOSTS;
        int HOSTS_num;
        string HOSTS_arr[];

        // static inputs
        ENUM_COPY_TICKS COPY_TICKS_FLAG;
        int DEBUG;
        int EVENT_TIMER_INTERVAL_MSC;
    } c; // sConfig c;

    void get_period_num_and_type(const string &in_period_key, int &out_period_num, ENUM_PERIOD_TYPE &out_period_type)
    {
        get_period_num_and_type_g(in_period_key, out_period_num, out_period_type);
    }

    sConfigVars()
    {
        c.ACCOUNT = I_ACCOUNT;
        c.SYMBOLS = I_SYMBOLS;
        c.PERIODS = I_PERIODS;
        c.HOSTS = I_HOSTS;

        c.COPY_TICKS_FLAG = I_COPY_TICKS_FLAG;
        c.DEBUG = I_DEBUG;
        c.EVENT_TIMER_INTERVAL_MSC = I_EVENT_TIMER_INTERVAL_MSC;

        c.SYMBOLS_num = string_split_g(c.SYMBOLS, ":", c.SYMBOLS_arr);
        c.PERIODS_num = string_split_g(c.PERIODS, ":", c.PERIODS_arr);
        c.HOSTS_num = string_split_g(c.HOSTS, ":", c.HOSTS_arr);

    }; // sConfigVars() constructor

}; // struct sConfigVars

struct sData
{
    int DELTA;
    int PS;
    int OC;
    int HL;
    int VOLS;
    int TD;
    int TT;
    int SPREAD;
    double OC_HL;
    double VOLS_TD;
    double HL_TD;
    double SUMCOL;

    long t0;
    long t1;
    double c0;
    double c1;

    long daily_open_t0;
    double daily_open_c0;
    long id_pro_chart;

    sData()
    {

        DELTA = 0;
        PS = 0;
        OC = 0;
        HL = 0;
        VOLS = 0;
        TD = 0;
        TT = 0;
        SPREAD = 0;
        OC_HL = 0;
        VOLS_TD = 0;
        HL_TD = 0;
        SUMCOL = 0;

        c0 = 0.0;
        t0 = 0;
        c1 = 0.0;
        t1 = 0;

        daily_open_t0 = 0;
        daily_open_c0 = 0.0;
        id_pro_chart = 0;

        Print("sData");
    };
};

struct sDataVars : sConfigVars
{

    datetime time_msc;

    string symbol;
    int symbol_idx;
    string period;
    int period_idx;
    int period_num;
    ENUM_PERIOD_TYPE period_type;

    sData d;

    /*
    int DELTA;
    int PS;
    int OC;
    int HL;
    int VOLS;
    int TD;
    int TT;
    int SPREAD;
    double OC_HL;
    double VOLS_TD;
    double HL_TD;
    double SUMCOL;

    long t0;
    long t1;
    double c0;
    double c1;

    long daily_open_t0;
    double daily_open_c0;
    long id_pro_chart;
    */

    string str_txt;

    double ticks_arr[];

    void print()
    {
        if (0 < c.DEBUG)
        {
            string str = StringFormat("sym: %s num: %4d key: %10s type: %s", symbol, period_num, period, EnumToString(period_type));
            Print(str);
        }
    }; // void print()

    void init(const datetime &_time_msc, const string &_symbol, const int &_symbol_idx, const string &_period, const int &_period_idx)
    {

        time_msc = _time_msc;
        symbol = _symbol;
        symbol_idx = _symbol_idx;
        period = _period;
        period_idx = _period_idx;
        get_period_num_and_type(period, period_num, period_type);

        str_txt = "";

        if (false == init_ticks_arr_g(
                         time_msc,
                         symbol,
                         period_num,
                         period_type,
                         ticks_arr,
                         d))
            Print("@TODO throw exception here - init_ticks_arr_g " + symbol + " " + IntegerToString(period_num) + " " + EnumToString(period_type));

        print();
    };

    sDataVars() {
    };

}; // struct sDataVars

struct sSymbolVars : sConfigVars
{

    datetime time_msc;

    string symbol;
    int symbol_idx;
    sDataVars sData[];

    void init(const datetime &_time_msc, const string &_symbol, const int &_symbol_idx)
    {
        time_msc = _time_msc;

        symbol = _symbol;
        symbol_idx = _symbol_idx;

        for (int cnt = 0; cnt < c.PERIODS_num; cnt++)
        {
            sData[cnt].init(time_msc, symbol, symbol_idx, c.PERIODS_arr[cnt], cnt);
        } // for( int cnt = 0; cnt < num_symbols; cnt++ )
    }

    sSymbolVars()
    {
        ArrayResize(sData, c.PERIODS_num);
    }

}; // struct sSymbolVars;

struct sGlobalVars : sConfigVars
{

    datetime time_msc;
    sSymbolVars sSym[];

    // empty default constructor - used for ArrayResize with non initialised sGlobalVars
    sGlobalVars() : time_msc(0)
    {
    }

    sGlobalVars(const datetime &_tmsc) : time_msc(_tmsc)
    {
        ArrayResize(sSym, c.SYMBOLS_num);
        for (int cnt = 0; cnt < c.SYMBOLS_num; cnt++)
        {
            sSym[cnt].init(time_msc, c.SYMBOLS_arr[cnt], cnt);
        } // for( int cnt = 0; cnt < num_symbols; cnt++ )
    }

}; // struct sGlobalVars;

//+------------------------------------------------------------------+
//| CRingTryGet.mqh                                                  |
//+------------------------------------------------------------------+

template <typename T>
struct CRingTryGet
{
private:
    T m_buf[]; // circular storage
    int m_capacity;
    int m_head;
    int m_count;
    bool m_indexNewest;

    int Tail() const
    {
        if (m_count == 0)
            return 0;
        int t = m_head - m_count;
        if (t < 0)

            t += m_capacity;
        return t;
    }

    int MapLogicalToPhysical(const int index) const
    {
        if (index < 0 || index >= m_count)
            return -1;
        if (m_indexNewest)
        {
            int newest = m_head - 1;
            if (newest < 0)
                newest += m_capacity;
            int pos = newest - index;
            if (pos < 0)
                pos += m_capacity;
            return pos;
        }
        else
        {
            int tail = Tail();
            int pos = tail + index;
            if (pos >= m_capacity)
                pos -= m_capacity;
            return pos;
        }
    }

public:
    CRingTryGet()
    {
        m_capacity = 0;
        m_head = 0;
        m_count = 0;
        m_indexNewest = true;
    }

    bool init(const int &capacity, const bool &indexNewest)
    {
        if (capacity <= 0)
            return false;
        m_capacity = capacity;
        ArrayResize(m_buf, m_capacity);
        m_head = 0;
        m_count = 0;
        m_indexNewest = indexNewest;
        return true;
    }

    int Capacity() const { return m_capacity; }
    int Count() const { return m_count; }

    // O(1) add
    void Add(const T &item)
    {
        m_buf[m_head] = item;
        m_head++;
        if (m_head >= m_capacity)
            m_head = 0;
        if (m_count < m_capacity)
            m_count++;
    }

    // Overwrite last (update current tick)
    void Last(const T &item)
    {
        if (m_count == 0)
        {
            Add(item);
            return;
        }
        int pos = m_head - 1;
        if (pos < 0)
            pos += m_capacity;
        m_buf[pos] = item;
    }

    // TryGet pattern: returns true and fills out when index valid
    bool TryGet(const int index, T &out) const
    {
        int phys = MapLogicalToPhysical(index);
        if (phys < 0)
            return false;
        out = m_buf[phys]; // single copy
        return true;
    }

    /*
        // PtrAt non-const: returns pointer to internal element or NULL if invalid
        T *PtrAt(const int index)
        {
            int phys = MapLogicalToPhysical(index);
            if (phys < 0)
                return NULL;
            return &m_buf[phys];
        }

        // PtrAt const overload: for read-only access from const contexts
        const T *PtrAt(const int index) const
        {
            int phys = MapLogicalToPhysical(index);
            if (phys < 0)
                return NULL;
            return &m_buf[phys];
        }
    */
    // Example helper: extract a primitive field without copying whole T
    // Adapt the body to your T layout for fastest access.
    bool TryGetField_OC(const int index, double &outValue) const
    {
        int phys = MapLogicalToPhysical(index);
        if (phys < 0)
            return false;
        // Example: assume T has sSym[] and sData[] and OC inside sData
        // Replace with your pre-indexed fast lookup for production
        for (int s = 0; s < ArraySize(m_buf[phys].sSym); s++)
        {
            for (int p = 0; p < ArraySize(m_buf[phys].sSym[s].sData); p++)
            {
                // choose the right symbol/period condition here
                outValue = (double)m_buf[phys].sSym[s].sData[p].d.OC;
                return true;
            }
        }
        return false;
    }

    // Build an int index snapshot logical->physical (cheap)
    void GetIndexSnapshot(int &outIdx[]) const
    {
        ArrayResize(outIdx, m_count);
        for (int i = 0; i < m_count; i++)
            outIdx[i] = MapLogicalToPhysical(i);
    }
};
//+------------------------------------------------------------------+

/*

CRingTryGet<sGlobalVars> ring;
bool res = ring.init(50, true);


// Example reading loop using TryGet (safe copy)
void ProcessCopy()
{
    sGlobalVars tmp;
    for (int i = 0; i < ring.Count(); i++)
    {
        if (ring.TryGet(i, tmp))
        {
            // use tmp safely; single copy per element
            tmp.sSym[0].sData[0].print();
        }
    }
};


// Example reading loop using PtrAt (zero-copy)
void ProcessPtr()
{
    for (int i = 0; i < ring.Count(); i++)
    {
        const sGlobalVars *p = ring.PtrAt(i);
        if (p != NULL)
        {
            // read fields directly without copying
            p.sSym[0].sData[0].print();
        }
    }
}

// Example building primitive OC array newest->oldest
void BuildOCArray(double &out[])
{
    int idx[];
    ring.GetIndexSnapshot(idx); // cheap int array
    ArrayResize(out, ArraySize(idx));
    for (int i = 0; i < ArraySize(idx); i++)
    {
        double v;
        if (ring.TryGetField_OC(i, v))
            out[i] = v;
        else
            out[i] = 0.0;
    }
}

*/
