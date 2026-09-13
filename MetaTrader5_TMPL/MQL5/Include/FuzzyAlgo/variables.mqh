//+------------------------------------------------------------------+
//|                                                    variables.mqh |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link "https://www.fuzzyalgo.com"

// I N C L U D E S
#include <FuzzyAlgo/TickCache.mqh>

// T Y P E D E F S
enum ENUM_PERIOD_TYPE
{
    ENUM_PERIOD_TYPE_NONE,
    ENUM_PERIOD_TYPE_PRO,
    ENUM_PERIOD_TYPE_DAY,
    ENUM_PERIOD_TYPE_REF,
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
//input string I_SYMBOLS = "EURUSD:EURGBP:GBPJPY:NZDUSD";
input string I_SYMBOLS = "EURUSD";
// input string I_PERIODS = "PRO:T15:T30:T60:T_AVG:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
//input string I_PERIODS = "REF:DAY:S300:S900:S3600";
input string I_PERIODS = "PRO:REF:DAY:S3600";
// input string I_PERIODS = "S300:S14400:S86400";
//  input string I_PERIODS = "T300:T900:T3600";
input string I_HOSTS = "vm1.localhost:vm2.localhost:vm3.localhost"; // hosts where the forex expert is running
// static inputs
input ENUM_COPY_TICKS I_COPY_TICKS_FLAG = COPY_TICKS_TIME_MS; // COPY_TICKS_INFO COPY_TICKS_TRADE COPY_TICKS_ALL
// Debug is a level, not a bool: 0 = off, 1 = existing sPeriodVars::print() period
// debug line, 2 = also emit the RTFP (real-time fingerprint) tick-cache
// diagnostic prints in init_ticks_arr_g's REF/S... branches (see comments at
// those call sites and docs/repository-notes.md's Tick cache section for what RTFP is for).
// Level 2 is chatty (one Print per tick-array sample) - fine for a short
// closed-market comparison run, too noisy to leave on by default.
input int I_DEBUG = 0;                                        // enable debug output (0=off, 1=period debug, 2=+tick-cache RTFP diagnostics)
input bool I_USE_TICK_CACHE = false;                           // replay ticks from CSV cache instead of CopyTicks(Range) - closed-market/backtest use only, flip to false before live/EA use
input int I_EVENT_TIMER_INTERVAL_MSC = 1000;                  // Event Timer Interval in milliseconds

// input string PERIODS = "T60:T300:T900:T3600:T_AVG:S60:S300:S900:S3600:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG:S15:S30:S60:S300:S_AVG:SUM_AVG"; // periods are seperated by colon. T for Ticks and S for seconds
// input string PERIODS = "T15:T30:T60:T300:T_AVG";            // periods are seperated by colon. T for Ticks and S for seconds

// G L O B A L S
struct sData;
struct sConfig;

int string_split_g(const string &in_string_to_split, const string &in_seperator, string &out_split_array[])
{
    ushort u_sep = StringGetCharacter(in_seperator, 0);                       //--- Get the separator code
    int num_splits = StringSplit(in_string_to_split, u_sep, out_split_array); //--- Split the string to substrings
    if (num_splits != ArraySize(out_split_array))
        Print("@TODO throw exception here - string_split_g " + in_string_to_split + " " + in_seperator);
    return num_splits;
}

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
    // (c0-c1)/point is a single arithmetic result, not an accumulated sum, but
    // a native in-memory double and a CSV-round-tripped double (tick cache)
    // can still differ by ~1 ULP, which the /point division amplifies ~10^5x
    // (point ~0.00001 for 5-digit EURUSD) - enough to land on the opposite
    // side of an integer/half-integer boundary. A plain (int) truncation cast
    // flipped native-vs-cache OC by 1 in exactly this scenario; MathRound
    // fixes the boundary-straddle cases where both sides' true values agree.
    // A handful of survivors (raw values sitting almost exactly on a .5
    // boundary) were NOT a rounding artifact but a genuine raw-value
    // difference, root-caused to TickCache.mqh writing bid/ask/last at
    // SYMBOL_DIGITS precision instead of a full round-trip precision - see
    // TICK_CACHE_ROUNDTRIP_DIGITS_G in TickCache.mqh and docs/repository-notes.md's
    // Tick cache section ("OC/HL had the same class of native-vs-cache mismatch").
    out_data.OC = (int)MathRound((out_data.c0 - out_data.c1) / point);
    out_data.VOLS = size1;
    if (ENUM_PERIOD_TYPE_SECONDS_S == in_period_type)
        out_data.TD = in_period_num;
    else
        out_data.TD = (int)(out_data.t0 - out_data.t1) / 1000;
    out_data.TT = 0.0;
    if (0.0 != out_data.VOLS)
        out_data.TT = int((out_data.TD * 1000) / out_data.VOLS);
    out_data.VOLS_TD = 0.0;
    if (0.0 != out_data.TD)
        out_data.VOLS_TD = (double)((double)out_data.VOLS / (double)out_data.TD);
    out_data.SUM_POS = 0;
    out_data.SUM_NEG = 0;

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

        if (0.0 < out_ticks_arr[cnt])
            out_data.SUM_POS += out_ticks_arr[cnt];
        if (0.0 > out_ticks_arr[cnt])
            out_data.SUM_NEG += out_ticks_arr[cnt];

    } // for (int cnt = 0; cnt < size1; cnt++)

    // Same ULP-amplification-via-/point issue as OC above, and the same
    // two-part fix: MathRound handles the boundary-straddle cases, full CSV
    // round-trip precision (TickCache.mqh) handles the genuine raw-value
    // differences that rounding alone can't paper over.
    out_data.HL = (int)MathRound((high - low) / point);
    out_data.SPREAD = spread;

    out_data.OC_HL = 0.0;
    if (0.0 != out_data.HL)
        out_data.OC_HL = (double)((double)out_data.OC / (double)out_data.HL);
    out_data.HL_TD = 0.0;
    if (0.0 != out_data.TD)
        out_data.HL_TD = (double)((double)out_data.HL / (double)out_data.TD);
    out_data.SUMCOL = MathAbs(out_data.OC_HL) + out_data.VOLS_TD + out_data.HL_TD;

    // bounded net-flow share in [-1, 1]: (pos + neg) / (pos - neg).
    // sum_neg <= 0, so the denominator is pos + |neg| (total tick magnitude).
    out_data.NETFLOW = 0.0;
    double netflow_total = out_data.SUM_POS - out_data.SUM_NEG;
    if (0.0 != netflow_total)
        out_data.NETFLOW = (out_data.SUM_POS + out_data.SUM_NEG) / netflow_total;

    return ret;
    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // bool init_data_from_ticks_arr_g
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| in_conf is threaded in explicitly (not read off an inherited/    |
//| locally-constructed sConfigVars) so a caller can build two       |
//| independent sGlobalVars graphs in one script run that differ in  |
//| a single sConfig field (e.g. USE_TICK_CACHE) - see sGlobalVars's |
//| 3-arg constructor below and docs/design-decisions.md's "sConfig  |
//| composition over inheritance" section for why this replaced      |
//| inheritance.                                                     |
//+------------------------------------------------------------------+
bool init_ticks_arr_g(
    const datetime &in_time_msc,
    const string &in_symbol,
    const int &in_period_num,
    const ENUM_PERIOD_TYPE &in_period_type,
    double &out_ticks_arr[],
    sData &out_data,
    const sConfig &in_conf)
{

    bool ret = false;
    MqlTick in_array[];
    int size1 = 0;

    if (ENUM_PERIOD_TYPE_DAY == in_period_type)
    {

        long start_time_day_msc, end_time_day_msc;
        GetDayBoundsMsc_g(in_time_msc, start_time_day_msc, end_time_day_msc);

        // string str = StringFormat("%s.%03d | %s.%03d",
        //                           TimeToString(start_time_day_msc / 1000, TIME_DATE | TIME_SECONDS),
        //                           start_time_day_msc % 1000,
        //                           TimeToString(in_time_msc / 1000, TIME_DATE | TIME_SECONDS),
        //                           in_time_msc % 1000);
        // Print(str);

        size1 = CopyTicksRange_g(in_symbol, in_array, in_conf.COPY_TICKS_FLAG, start_time_day_msc, in_time_msc, in_conf.USE_TICK_CACHE, in_conf.DEBUG);
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
        }

    } // if (ENUM_PERIOD_TYPE_SECONDS_S == period_type )

    else if (ENUM_PERIOD_TYPE_PRO == in_period_type)
    {
        // PRO mirrors REF's fixed-anchor/growing-window architecture, but
        // the anchor is the currently open position's opening time/price
        // instead of a fixed historical timestamp. Unlike REF's anchor
        // (fetched once via sRefPoint and copied into every sample's
        // sData.d before init_ticks_arr_g runs), a position can open or
        // close between samples, so the anchor is looked up live here via
        // PositionSelect(in_symbol) on every call rather than being
        // threaded in from outside. Netting-account assumption: at most
        // one open position per symbol, so PositionSelect(symbol) alone
        // is enough to find it; a hedging account with multiple positions
        // per symbol would need PositionsTotal()+PositionGetSymbol(i)
        // enumeration instead, which is not implemented here.
        //
        // Same three states as REF:
        //   1) no open position for in_symbol - handled in the `if` below,
        //      everything stays 0 except c0, which still gets the current
        //      price via a single-tick lookup.
        //   2) position just opened, in_time_msc == open time: zero-width
        //      window, PRODLT (if displayed) prints 0.
        //   3) in_time_msc > open time: real window [open_time, in_time_msc],
        //      OC/HL/SUM_POS/SUM_NEG/NETFLOW accumulate the same way REF's do.
        datetime start_time_pro_msc = 0;
        if (PositionSelect(in_symbol))
        {
            start_time_pro_msc = (datetime)PositionGetInteger(POSITION_TIME_MSC);
            out_data.time_msc_pro = (long)start_time_pro_msc;
            out_data.c0_pro = PositionGetDouble(POSITION_PRICE_OPEN);
        }
        else
        {
            out_data.time_msc_pro = 0;
            out_data.c0_pro = 0.0;
        }

        if (0 >= start_time_pro_msc || in_time_msc <= start_time_pro_msc)
        {
            // No open position, or no time has elapsed since it opened -
            // same reasoning as REF's skip branch: no window to sum over,
            // and CopyTicksRange with from<=0 or from>=to risks corrupting
            // subsequent tick fetches, so it's skipped. c0 still gets the
            // current price via a single-tick lookup.
            MqlTick tarr[];
            int len = CopyTicks_g(in_symbol, tarr, COPY_TICKS_TIME_MS, in_time_msc, 1, in_conf.USE_TICK_CACHE, in_conf.DEBUG);
            if (0 < len)
                out_data.c0 = (tarr[0].ask + tarr[0].bid) / 2;
            ret = true;
        }
        else
        {
            size1 = CopyTicksRange_g(in_symbol, in_array, in_conf.COPY_TICKS_FLAG, start_time_pro_msc, in_time_msc, in_conf.USE_TICK_CACHE, in_conf.DEBUG);
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
            }
        }

    } // if (ENUM_PERIOD_TYPE_PRO == in_period_type)

    else if (ENUM_PERIOD_TYPE_REF == in_period_type)
    {
        // REF computes OC/HL/SUM_POS/SUM_NEG/NETFLOW relative to a fixed
        // sRefPoint anchor instead of a fixed-duration window like DAY/S...:
        // the window is [ref_point_time, in_time_msc], so it grows over
        // time rather than sliding. Three states to expect in the printed
        // output:
        //   1) in_time_msc <= ref point (or ref point unset): no window has
        //      elapsed yet - handled in the `if` branch below, everything
        //      stays 0 except c0 (see comment there).
        //   2) in_time_msc == ref point: zero-width window, REFDLT prints 0.
        //   3) in_time_msc > ref point: real window, values accumulate
        //      monotonically in magnitude (SUM_POS/SUM_NEG only grow) as
        //      in_time_msc advances further from the anchor. A sustained
        //      one-directional price move can make SUM_POS (or SUM_NEG)
        //      freeze for many samples in a row while the other side keeps
        //      moving - that's not staleness, it just means no ticks in
        //      that direction occurred in the window; same characteristic
        //      already documented for DAY's SUM_POS/SUM_NEG in docs/known-issues.md.

        // out_data.time_msc_ref is already set by sSymbolVars::init before
        // sDataVars::init/init_ticks_arr_g runs, so it's valid here.
        datetime start_time_ref_msc = (datetime)out_data.time_msc_ref;

        if (0 >= start_time_ref_msc || in_time_msc <= start_time_ref_msc)
        {
            // No ref point established yet, or no time has elapsed since it -
            // there's no window to sum OC/HL/SUM_POS/SUM_NEG/NETFLOW over, so
            // those stay at their zero-initialized defaults. Calling
            // CopyTicksRange here (from<=0 or from>=to) risks corrupting
            // subsequent tick fetches for the rest of the run, so it's
            // skipped - but c0 is still the current price regardless of
            // whether any window has elapsed, so fetch it via a single-tick
            // lookup (same pattern as sRefPoint's constructor) rather than
            // leaving it at 0.
            MqlTick tarr[];
            int len = CopyTicks_g(in_symbol, tarr, COPY_TICKS_TIME_MS, in_time_msc, 1, in_conf.USE_TICK_CACHE, in_conf.DEBUG);
            if (0 < len)
                out_data.c0 = (tarr[0].ask + tarr[0].bid) / 2;
            ret = true;
        }
        else
        {
            size1 = CopyTicksRange_g(in_symbol, in_array, in_conf.COPY_TICKS_FLAG, start_time_ref_msc, in_time_msc, in_conf.USE_TICK_CACHE, in_conf.DEBUG);

            // RTFP ("real-time fingerprint") - diagnostic only, gated behind
            // I_DEBUG>=2. Used to bisect a true/false-cache SUM_POS/SUM_NEG
            // mismatch down to "same raw ticks in, same raw sums out" (this
            // block) vs "different display of the same raw sums" (the RAW
            // block after init_data_from_ticks_arr_g below). bid_sum/ask_sum/
            // time_sum are order-independent (FP addition is commutative to
            // within ~1 ULP), so a match here only proves the tick *set* is
            // identical - it can't catch an order-dependent accumulation
            // difference, which is why the RAW block below exists too. Kept
            // permanently (not deleted after the bug was fixed) since the
            // same mismatch class can recur if the cache or native fetch path
            // changes again - see docs/repository-notes.md's Tick cache section.
            if (1 < in_conf.DEBUG)
            {
                double fp_bid_sum = 0.0;
                double fp_ask_sum = 0.0;
                long fp_time_sum = 0;
                for (int fp_i = 0; fp_i < size1; fp_i++)
                {
                    fp_bid_sum += in_array[fp_i].bid;
                    fp_ask_sum += in_array[fp_i].ask;
                    fp_time_sum += in_array[fp_i].time_msc;
                }
                Print("  RTFP REF cache=", in_conf.USE_TICK_CACHE, " ", in_symbol, " ", TimeToString(in_time_msc / 1000, TIME_SECONDS),
                      " from=", (long)start_time_ref_msc, " to=", (long)in_time_msc, " size=", size1,
                      " first_t=", (size1 > 0 ? in_array[0].time_msc : 0),
                      " last_t=", (size1 > 0 ? in_array[size1 - 1].time_msc : 0),
                      " time_sum=", fp_time_sum, " bid_sum=", DoubleToString(fp_bid_sum, 12),
                      " ask_sum=", DoubleToString(fp_ask_sum, 12));
            }
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

                // RTFP RAW - the undisplayed SUM_POS/SUM_NEG doubles, printed
                // at full precision (12 decimals, no rounding) right after
                // they're computed. SUM_POS/SUM_NEG are theoretically always
                // whole numbers (each tick contributes one whole point-unit),
                // but summing thousands of per-tick deltas accumulates ~1e-8
                // of FP noise - normally harmless, but it previously flipped
                // the *displayed* integer when it landed on the wrong side of
                // a .0/.5 boundary combined with a truncating (int) cast in
                // PrintRow. This print is what proved that: two runs whose
                // RTFP (aggregate) fingerprint above matched exactly could
                // still show a raw SUM_NEG of -12182.999999998943 vs
                // -12183.000000001766 - same value, opposite side of -12183.0.
                // Fixed by rounding instead of truncating in PrintRow (see
                // comment there); this print is kept so the same class of
                // mismatch is diagnosable again without re-deriving the
                // technique from scratch.
                if (1 < in_conf.DEBUG)
                    Print("  RTFP REF RAW cache=", in_conf.USE_TICK_CACHE, " ", in_symbol, " ", TimeToString(in_time_msc / 1000, TIME_SECONDS),
                          " SUM_POS=", DoubleToString(out_data.SUM_POS, 12),
                          " SUM_NEG=", DoubleToString(out_data.SUM_NEG, 12));
            }
        }

    } // if (ENUM_PERIOD_TYPE_REF == in_period_type)

    else if (ENUM_PERIOD_TYPE_SECONDS_S == in_period_type)
    {

        size1 = CopyTicksRange_g(in_symbol, in_array, in_conf.COPY_TICKS_FLAG, in_time_msc - in_period_num * 1000, in_time_msc, in_conf.USE_TICK_CACHE, in_conf.DEBUG);

        // RTFP - see the matching comment in the REF branch above for what
        // this is and why it's kept behind I_DEBUG>=2 rather than deleted.
        if (1 < in_conf.DEBUG)
        {
            double fp_bid_sum = 0.0;
            double fp_ask_sum = 0.0;
            long fp_time_sum = 0;
            for (int fp_i = 0; fp_i < size1; fp_i++)
            {
                fp_bid_sum += in_array[fp_i].bid;
                fp_ask_sum += in_array[fp_i].ask;
                fp_time_sum += in_array[fp_i].time_msc;
            }
            Print("  RTFP S", in_period_num, " cache=", in_conf.USE_TICK_CACHE, " ", in_symbol, " ", TimeToString(in_time_msc / 1000, TIME_SECONDS),
                  " from=", (long)(in_time_msc - in_period_num * 1000), " to=", (long)in_time_msc, " size=", size1,
                  " first_t=", (size1 > 0 ? in_array[0].time_msc : 0),
                  " last_t=", (size1 > 0 ? in_array[size1 - 1].time_msc : 0),
                  " time_sum=", fp_time_sum, " bid_sum=", DoubleToString(fp_bid_sum, 12),
                  " ask_sum=", DoubleToString(fp_ask_sum, 12));
        }
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

            // RTFP RAW - see the matching comment in the REF branch above.
            if (1 < in_conf.DEBUG)
                Print("  RTFP S", in_period_num, " RAW cache=", in_conf.USE_TICK_CACHE, " ", in_symbol, " ", TimeToString(in_time_msc / 1000, TIME_SECONDS),
                      " SUM_POS=", DoubleToString(out_data.SUM_POS, 12),
                      " SUM_NEG=", DoubleToString(out_data.SUM_NEG, 12));
        }

    } // if (ENUM_PERIOD_TYPE_SECONDS_S == period_type )

    else if (ENUM_PERIOD_TYPE_TICKS_T == in_period_type)
    {

        MqlTick src_array[];
        int src_size = 0;
        for (int inc_cnt = 5; inc_cnt < 15; inc_cnt++)
        {
            src_size = CopyTicksRange_g(in_symbol, src_array, in_conf.COPY_TICKS_FLAG, in_time_msc - inc_cnt * in_period_num * 1000, in_time_msc, in_conf.USE_TICK_CACHE, in_conf.DEBUG);
            if (src_size > in_period_num)
                break;
        }

        if (src_size > in_period_num)
        {

            MqlTick in_array[];
            ArrayCopy(in_array, src_array, 0, (src_size - in_period_num), in_period_num);
            size1 = ArraySize(in_array);
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
            } // if ( period_num == dst_size)
        }

    } // if (ENUM_PERIOD_TYPE_SECONDS_T == period_type )

    if (false == ret)
    {
        string str = StringFormat("@TODO throw exception here - init_data_from_ticks_arr_g %s.%03d  %s %5d %s ticks: %5d",
                                  TimeToString(in_time_msc / 1000, TIME_SECONDS),
                                  in_time_msc % 1000,
                                  in_symbol,
                                  in_period_num,
                                  EnumToString(in_period_type),
                                  size1);
        Print(str);
    }

    return ret;
    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
} // bool init_ticks_arr_g
//+------------------------------------------------------------------+

// Free function, not a method on sConfig - it never reads `c` (only its own
// parameters), so it doesn't belong on the config struct. Left over from
// when sConfig's predecessor (sConfigVars) was inherited by every struct in
// this hierarchy and this was just an inherited method; the composition
// refactor (docs/design-decisions.md) pulled it out to file scope along with everything
// else that didn't actually need config state.
void get_period_num_and_type_g(const string &in_period_key, int &out_period_num, ENUM_PERIOD_TYPE &out_period_type)
{
    // defaults
    out_period_type = ENUM_PERIOD_TYPE_NONE;
    out_period_num = 0;

    // explicit fixed tokens
    if (in_period_key == "PRO")
    {
        out_period_type = ENUM_PERIOD_TYPE_PRO;
        return;
    }
    if (in_period_key == "DAY")
    {
        out_period_type = ENUM_PERIOD_TYPE_DAY;
        return;
    }
    if (in_period_key == "REF")
    {
        out_period_type = ENUM_PERIOD_TYPE_REF;
        return;
    }
    if (in_period_key == "T_AVG")
    {
        out_period_type = ENUM_PERIOD_TYPE_AVERAGE_T;
        return;
    }
    if (in_period_key == "S_AVG")
    {
        out_period_type = ENUM_PERIOD_TYPE_AVERAGE_S;
        return;
    }
    if (in_period_key == "SUM_AVG")
    {
        out_period_type = ENUM_PERIOD_TYPE_AVERAGE_SUM;
        return;
    }

    // generic T... and S... handling (case-insensitive first letter)
    if (StringLen(in_period_key) >= 2)
    {
        string prefix = StringSubstr(in_period_key, 0, 1);
        if (prefix == "t")
            prefix = "T";
        if (prefix == "s")
            prefix = "S";

        string rest = StringSubstr(in_period_key, 1);
        bool digits_only = StringLen(rest) > 0;
        int ch;
        for (int i = 0; i < StringLen(rest) && digits_only; ++i)
        {
            ch = StringGetCharacter(rest, i);
            if (ch < '0' || ch > '9')
                digits_only = false;
        }

        if (digits_only)
        {
            int num = (int)StringToInteger(rest);
            if (prefix == "T")
            {
                out_period_type = ENUM_PERIOD_TYPE_TICKS_T;
                out_period_num = num;
                return;
            }
            if (prefix == "S")
            {
                out_period_type = ENUM_PERIOD_TYPE_SECONDS_S;
                out_period_num = num;
                return;
            }
        }
    }

    // unknown token
    PrintFormat("get_period_num_and_type_g: unknown period key '%s'", in_period_key);
}

// Top-level, self-contained config struct - each of sDataVars/sRefPoint/
// sSymbolVars/sGlobalVars holds one as an explicit `sConfig c;` member
// (composition), not as a base class (the old sConfigVars was inherited by
// all four). Composition lets a caller build/copy/override a whole sConfig
// value and hand it to any of those structs' constructors explicitly - the
// cache-comparison harness (docs/design-decisions.md) needs exactly this: two sGlobalVars
// graphs in one run whose sConfig differs only in USE_TICK_CACHE, which is
// now just `sConfig cfg2 = cfg; cfg2.USE_TICK_CACHE = true;`. Inheritance
// couldn't do this - every inherited sConfigVars unconditionally rebuilt
// itself from the compiled-in I_* inputs on construction, so overriding a
// single field for one instance would have meant threading a new raw
// parameter through every layer (sDataVars::init -> sSymbolVars::init ->
// init_ticks_arr_g), one new parameter per flag that ever needed varying.
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
    bool USE_TICK_CACHE;

    sConfig()
    {
        ACCOUNT = I_ACCOUNT;
        SYMBOLS = I_SYMBOLS;
        PERIODS = I_PERIODS;
        HOSTS = I_HOSTS;

        COPY_TICKS_FLAG = I_COPY_TICKS_FLAG;
        DEBUG = I_DEBUG;
        EVENT_TIMER_INTERVAL_MSC = I_EVENT_TIMER_INTERVAL_MSC;
        USE_TICK_CACHE = I_USE_TICK_CACHE;

        SYMBOLS_num = string_split_g(SYMBOLS, ":", SYMBOLS_arr);
        PERIODS_num = string_split_g(PERIODS, ":", PERIODS_arr);
        HOSTS_num = string_split_g(HOSTS, ":", HOSTS_arr);

    }; // sConfig() constructor

}; // struct sConfig

struct sData
{
    // generic
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

    // prices and time
    long t0;
    long t1;
    double c0;
    double c1;

    // ref_point
    long time_msc_ref;
    double c0_ref;

    // pro (open position) anchor - looked up live via PositionSelect in
    // init_ticks_arr_g's PRO branch, NOT pre-copied from a struct the way
    // time_msc_ref/c0_ref are for REF (see that branch for why).
    long time_msc_pro;
    double c0_pro;

    // fft
    double SUM_POS;
    double SUM_NEG;
    double NETFLOW;

    sData()
    {

        // generic
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

        // prices and time
        c0 = 0.0;
        t0 = 0;
        c1 = 0.0;
        t1 = 0;

        // fft
        SUM_POS = 0.0;
        SUM_NEG = 0.0;
        NETFLOW = 0.0;

        // ref_point
        time_msc_ref = 0;
        c0_ref = 0;

        // pro
        time_msc_pro = 0;
        c0_pro = 0.0;
    };
};

struct sDataVars
{

    sConfig c;
    datetime time_msc;
    sData d;

    string symbol;
    int symbol_idx;
    string period;
    int period_idx;
    int period_num;
    ENUM_PERIOD_TYPE period_type;

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

    // in_conf is threaded in explicitly, not read off an inherited config -
    // see init_ticks_arr_g's comment above for why (sConfig composition
    // refactor, docs/design-decisions.md).
    void init(const datetime &_time_msc,
              const string &_symbol,
              const int &_symbol_idx,
              const string &_period,
              const int &_period_idx,
              const sConfig &in_conf)
    {

        c = in_conf;
        time_msc = _time_msc;
        symbol = _symbol;
        symbol_idx = _symbol_idx;
        period = _period;
        period_idx = _period_idx;
        get_period_num_and_type_g(period, period_num, period_type);

        str_txt = "";

        bool ret = init_ticks_arr_g(
            time_msc,
            symbol,
            period_num,
            period_type,
            ticks_arr,
            d,
            in_conf);
        if (false == ret)
        {
            string str = StringFormat("@TODO throw exception here - init_ticks_arr_g %s.%03d  %s %5d %s",
                                      TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                      time_msc % 1000,
                                      symbol,
                                      period_num,
                                      EnumToString(period_type));
            Print(str);
        }
    };

    sDataVars() : time_msc(0), d() {
                  };

}; // struct sDataVars

struct sRefPoint
{
    sConfig c;
    long time_msc_ref;
    string time_msc_ref_str;
    double c0_ref[];
    string str_ref[];

    // Leaves time_msc_ref=0 and every c0_ref[]=0.0 - i.e. "no ref point
    // established". Only meant for placeholder/uninitialized use (see
    // sGlobalVars's single-arg constructor). Does NOT fetch any prices -
    // use sRefPoint(tref) below to actually establish a reference point.
    sRefPoint() : time_msc_ref(0)
    {
        time_msc_ref_str = "";
        ArrayResize(c0_ref, c.SYMBOLS_num);
        ArrayResize(str_ref, c.SYMBOLS_num);
        for (int cnt = 0; cnt < c.SYMBOLS_num; cnt++)
        {
            c0_ref[cnt] = 0.0;
            str_ref[cnt] = "";
        }
    };

    sRefPoint(const long &_tref) : time_msc_ref(_tref)
    {
        ArrayResize(c0_ref, c.SYMBOLS_num);
        ArrayResize(str_ref, c.SYMBOLS_num);
        time_msc_ref_str = StringFormat("%s.%03d",
                                        TimeToString(time_msc_ref / 1000, TIME_SECONDS),
                                        time_msc_ref % 1000);

        for (int cnt = 0; cnt < c.SYMBOLS_num; cnt++)
        {
            string sym = c.SYMBOLS_arr[cnt];
            long digits = SymbolInfoInteger(sym, SYMBOL_DIGITS);
            MqlTick tarr[];
            int len = CopyTicks(sym, tarr, COPY_TICKS_TIME_MS, time_msc_ref, 1);
            if (0 < len)
            {
                // OK
                c0_ref[cnt] = (tarr[0].ask + tarr[0].bid) / 2;
                c0_ref[cnt] = NormalizeDouble(c0_ref[cnt], (int)digits);
                str_ref[cnt] = StringFormat("OK  %s %s delta ms: %6d price: %s",
                                            sym,
                                            time_msc_ref_str,
                                            (int)(tarr[0].time_msc - time_msc_ref),
                                            DoubleToString(c0_ref[cnt], (int)digits));
                Print(str_ref[cnt]);
            }
            else
            {
                // ERROR case - @TODO make this work in case of error
                c0_ref[cnt] = 0;
                str_ref[cnt] = StringFormat("XX  %s %s delta ms: %6d price: %s",
                                            sym,
                                            time_msc_ref_str,
                                            0,
                                            DoubleToString(c0_ref[cnt], (int)digits));
                Print(str_ref[cnt]);
            } // if (0 < len)

        } // for( int cnt = 0; cnt < num_symbols; cnt++ )

    }; // sRefPoint(  const long& _tref )

}; // struct sRefPoint

struct sSymbolVars
{

    sConfig c;
    datetime time_msc;

    string symbol;
    int symbol_idx;
    sDataVars sData[];

    // in_conf threaded through to each sData[cnt].init below - same
    // explicit-override rationale as sDataVars::init above.
    void init(const datetime &_time_msc,
              const string &_symbol,
              const int &_symbol_idx,
              const sRefPoint &ref_point,
              const sConfig &in_conf)
    {
        c = in_conf;
        time_msc = _time_msc;

        symbol = _symbol;
        symbol_idx = _symbol_idx;

        for (int cnt = 0; cnt < c.PERIODS_num; cnt++)
        {
            sData[cnt].d.time_msc_ref = ref_point.time_msc_ref;
            sData[cnt].d.c0_ref = ref_point.c0_ref[symbol_idx];
            sData[cnt].init(time_msc, symbol, symbol_idx, c.PERIODS_arr[cnt], cnt, in_conf);
        } // for( int cnt = 0; cnt < num_symbols; cnt++ )
    }

    sSymbolVars() : time_msc(0), symbol_idx(-1)
    {
        ArrayResize(sData, c.PERIODS_num);
    }

    //+------------------------------------------------------------------+
    //| Prints a column-header line matching PrintRow's layout. Field    |
    //| widths here MUST stay in sync with the StringFormat calls in     |
    //| PrintRow below, or columns will drift out of alignment.          |
    //+------------------------------------------------------------------+
    void PrintRowHeader()
    {
        string head = StringFormat("%-19s.%-3s %-6s", "TIME", "MS", "SYM");

        string periods_str = "";
        for (int p = 0; p < c.PERIODS_num; p++)
        {
            periods_str += StringFormat(" | %-5s %7s %7s %8s %7s %9s %9s",
                                        sData[p].period,
                                        "OC", "HL", "OC/HL", "NETFLOW", "SUMPOS", "SUMNEG");
        }

        string foot = StringFormat(" | %10s %8s", "C0", "LAT_US");

        Print(head + periods_str + foot);
    } // void PrintRowHeader()

    //+------------------------------------------------------------------+
    //| Prints one debug line for this symbol at time_msc. Loops over    |
    //| all configured periods. latency_us defaults to -1 for the        |
    //| ring-buffer dump (no real latency to report); the live loop      |
    //| passes the measured tick latency in microseconds (GetMicrosecond-|
    //| Count(), not GetTickCount64() - see TestVariables.mq5's live     |
    //| loop for why). Every 100th call reprints the column header via   |
    //| PrintRowHeader.                                                  |
    //+------------------------------------------------------------------+
    void PrintRow(const long latency_us = -1)
    {
        static int print_count = 0;
        if (0 == print_count % 100)
            PrintRowHeader();
        print_count++;

        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

        string head = StringFormat("%-19s.%03d %-6s",
                                   TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                   time_msc % 1000,
                                   symbol);

        string periods_str = "";
        for (int p = 0; p < c.PERIODS_num; p++)
        {
            // SUM_POS/SUM_NEG are theoretically always whole numbers (each
            // tick contributes one whole point-unit to the running delta
            // sum), but summing thousands of per-tick doubles accumulates
            // ~1e-8 of FP noise. A plain (int) cast truncates, so noise
            // landing on either side of a .0/.5 boundary displayed a
            // different integer depending on summation order - this is what
            // caused the intermittent +/-1 SUM_POS/SUM_NEG mismatch between
            // I_USE_TICK_CACHE=true and =false runs (native fetch vs cache
            // slice reconstruct ticks in a subtly different order for ticks
            // sharing identical/adjacent time_msc). MathRound fixes the
            // *display* only - the underlying noise is still there and
            // harmless, since both sides round to the same integer. See
            // docs/repository-notes.md's Tick cache section for the full root-cause writeup
            // and the RTFP diagnostic (I_DEBUG>=2 in init_ticks_arr_g) that
            // proved it. OC/HL don't need this - they're single-arithmetic
            // values, not summed across the window, so they never accumulate
            // this noise.
            periods_str += StringFormat(" | %-5s %7d %7d %8.1f %7.2f %9d %9d",
                                        sData[p].period,
                                        (int)sData[p].d.OC,
                                        (int)sData[p].d.HL,
                                        sData[p].d.OC_HL,
                                        sData[p].d.NETFLOW,
                                        (int)MathRound(sData[p].d.SUM_POS),
                                        (int)MathRound(sData[p].d.SUM_NEG));
        }

        string foot = StringFormat(" | %10.5f %8d",
                                   sData[0].d.c0,
                                   (int)latency_us);

        Print(head + periods_str + foot);
    } // void PrintRow(const long latency_us)

}; // struct sSymbolVars

struct sGlobalVars
{

    sConfig c;
    datetime time_msc;
    sRefPoint ref_point;
    sSymbolVars sSym[];

    // empty default constructor - used for ArrayResize with non initialised sGlobalVars
    sGlobalVars() : time_msc(0)
    {
        // Print( " sGlobalVars(): ", time_msc);
    }

    // CAUTION: ref_point() default-constructs with time_msc_ref=0 (see
    // sRefPoint's default ctor below) - i.e. this sGlobalVars has NO real
    // reference point. If I_PERIODS includes "REF", every sData slot's
    // time_msc_ref ends up 0 too (sSymbolVars::init copies it straight from
    // ref_point). Previously this made init_ticks_arr_g's REF branch call
    // CopyTicksRange(symbol, arr, flag, 0, now) - an epoch-to-now range -
    // which hung and corrupted subsequent tick fetches for the rest of the
    // run (every period type, every symbol, failing with ticks: -1). The
    // guard in init_ticks_arr_g's REF branch (0 >= start_time_ref_msc) now
    // makes that safe, but this constructor still yields a REF period that
    // is unconditionally zero forever - only use it where REF's value is
    // genuinely irrelevant (e.g. TestVariables.mq5's throwaway `g` object,
    // used solely to print the symbol/period/host lists). For anything that
    // needs a working REF period, use the two-arg constructor below with a
    // properly constructed sRefPoint(tref).
    sGlobalVars(const datetime &_tmsc) : time_msc(_tmsc), ref_point()
    {
        sGlobalVarsImpl();
    }

    sGlobalVars(const datetime &_tmsc, const sRefPoint &_ref_point) : time_msc(_tmsc), ref_point(_ref_point)
    {
        sGlobalVarsImpl();
    }

    // Explicit-config overload - lets a caller build a fully independent
    // sGlobalVars graph whose sConfig differs from the compiled-in I_*
    // inputs (e.g. a cache=true vs cache=false comparison harness building
    // two graphs in one OnStart() run). The 0/1/2-arg constructors above
    // are unaffected - they still default-construct c from I_* every time.
    sGlobalVars(const datetime &_tmsc, const sRefPoint &_ref_point, const sConfig &_conf) : time_msc(_tmsc), ref_point(_ref_point)
    {
        c = _conf;
        sGlobalVarsImpl();
    }

    void sGlobalVarsImpl()
    {

        ArrayResize(sSym, c.SYMBOLS_num);
        for (int cnt = 0; cnt < c.SYMBOLS_num; cnt++)
        {
            sSym[cnt].init(time_msc, c.SYMBOLS_arr[cnt], cnt, ref_point, c);
        } // for( int cnt = 0; cnt < num_symbols; cnt++ )
    }

}; // struct sGlobalVars;

//+------------------------------------------------------------------+
//| Cache-comparison harness (docs/design-decisions.md's "Cache=false|
//| vs cache=true validation harness"). Diffs one (symbol, period)   |
//| slot's derived data between a native-fetch sGlobalVars graph and |
//| a cache-fetch one, following                                     |
//| TestTickCacheDiff.mq5's diff-reporting shape (first-N DIFF[i]     |
//| lines, a count, then a final MATCH/MISMATCH line) - but at the    |
//| level that actually matters for correctness: the per-tick delta   |
//| array (ticks_arr) and the derived sData fields, not just the raw  |
//| MqlTick[] TestTickCacheDiff.mq5 already covers.                   |
//+------------------------------------------------------------------+
int CompareDataVars_g(const sDataVars &a, const sDataVars &b, const string &context)
{
    int mismatches = 0;

    int size_a = ArraySize(a.ticks_arr);
    int size_b = ArraySize(b.ticks_arr);
    if (size_a != size_b)
    {
        Print("  ", context, " SIZE MISMATCH ticks_arr native=", size_a, " cached=", size_b);
        return 1;
    }

    int diff_count = 0;
    for (int i = 0; i < size_a; i++)
    {
        if (a.ticks_arr[i] != b.ticks_arr[i])
        {
            diff_count++;
            if (diff_count <= 5)
                Print("  ", context, " DIFF[", i, "] ticks_arr native=", DoubleToString(a.ticks_arr[i], 12),
                      " cached=", DoubleToString(b.ticks_arr[i], 12));
        }
    }
    if (0 < diff_count)
    {
        Print("  ", context, " ticks_arr DIFF COUNT: ", diff_count, " / ", size_a);
        mismatches += diff_count;
    }

    // exact-int fields - single arithmetic/count results, no accumulation
    // noise, so native and cache must agree bit-for-bit.
    if (a.d.OC != b.d.OC)
    {
        Print("  ", context, " OC MISMATCH native=", a.d.OC, " cached=", b.d.OC);
        mismatches++;
    }
    if (a.d.HL != b.d.HL)
    {
        Print("  ", context, " HL MISMATCH native=", a.d.HL, " cached=", b.d.HL);
        mismatches++;
    }
    if (a.d.VOLS != b.d.VOLS)
    {
        Print("  ", context, " VOLS MISMATCH native=", a.d.VOLS, " cached=", b.d.VOLS);
        mismatches++;
    }
    if (a.d.TD != b.d.TD)
    {
        Print("  ", context, " TD MISMATCH native=", a.d.TD, " cached=", b.d.TD);
        mismatches++;
    }
    if (a.d.SPREAD != b.d.SPREAD)
    {
        Print("  ", context, " SPREAD MISMATCH native=", a.d.SPREAD, " cached=", b.d.SPREAD);
        mismatches++;
    }

    // SUM_POS/SUM_NEG: MathRound-to-int equality, matching PrintRow's
    // established display-equivalence contract (see PrintRow's comment on
    // why raw doubles can differ by ~1e-8 while still rounding identically).
    int sum_pos_native = (int)MathRound(a.d.SUM_POS);
    int sum_pos_cached = (int)MathRound(b.d.SUM_POS);
    if (sum_pos_native != sum_pos_cached)
    {
        Print("  ", context, " SUM_POS MISMATCH native=", sum_pos_native, " cached=", sum_pos_cached,
              " (raw native=", DoubleToString(a.d.SUM_POS, 12), " cached=", DoubleToString(b.d.SUM_POS, 12), ")");
        mismatches++;
    }
    else if (a.d.SUM_POS != b.d.SUM_POS)
    {
        // RTFP-style informational note, not a failure - rounded values agree.
        Print("  ", context, " SUM_POS raw differs but rounds equal: native=", DoubleToString(a.d.SUM_POS, 12),
              " cached=", DoubleToString(b.d.SUM_POS, 12));
    }

    int sum_neg_native = (int)MathRound(a.d.SUM_NEG);
    int sum_neg_cached = (int)MathRound(b.d.SUM_NEG);
    if (sum_neg_native != sum_neg_cached)
    {
        Print("  ", context, " SUM_NEG MISMATCH native=", sum_neg_native, " cached=", sum_neg_cached,
              " (raw native=", DoubleToString(a.d.SUM_NEG, 12), " cached=", DoubleToString(b.d.SUM_NEG, 12), ")");
        mismatches++;
    }
    else if (a.d.SUM_NEG != b.d.SUM_NEG)
    {
        Print("  ", context, " SUM_NEG raw differs but rounds equal: native=", DoubleToString(a.d.SUM_NEG, 12),
              " cached=", DoubleToString(b.d.SUM_NEG, 12));
    }

    // small-epsilon equality for ratios/sums derived from the fields above
    double eps = 1e-9;
    if (eps < MathAbs(a.d.NETFLOW - b.d.NETFLOW))
    {
        Print("  ", context, " NETFLOW MISMATCH native=", DoubleToString(a.d.NETFLOW, 12), " cached=", DoubleToString(b.d.NETFLOW, 12));
        mismatches++;
    }
    if (eps < MathAbs(a.d.OC_HL - b.d.OC_HL))
    {
        Print("  ", context, " OC_HL MISMATCH native=", DoubleToString(a.d.OC_HL, 12), " cached=", DoubleToString(b.d.OC_HL, 12));
        mismatches++;
    }
    if (eps < MathAbs(a.d.VOLS_TD - b.d.VOLS_TD))
    {
        Print("  ", context, " VOLS_TD MISMATCH native=", DoubleToString(a.d.VOLS_TD, 12), " cached=", DoubleToString(b.d.VOLS_TD, 12));
        mismatches++;
    }
    if (eps < MathAbs(a.d.HL_TD - b.d.HL_TD))
    {
        Print("  ", context, " HL_TD MISMATCH native=", DoubleToString(a.d.HL_TD, 12), " cached=", DoubleToString(b.d.HL_TD, 12));
        mismatches++;
    }
    if (eps < MathAbs(a.d.SUMCOL - b.d.SUMCOL))
    {
        Print("  ", context, " SUMCOL MISMATCH native=", DoubleToString(a.d.SUMCOL, 12), " cached=", DoubleToString(b.d.SUMCOL, 12));
        mismatches++;
    }

    // exact equality - endpoint prices/times, no accumulation involved
    if (a.d.c0 != b.d.c0)
    {
        Print("  ", context, " c0 MISMATCH native=", DoubleToString(a.d.c0, 12), " cached=", DoubleToString(b.d.c0, 12));
        mismatches++;
    }
    if (a.d.c1 != b.d.c1)
    {
        Print("  ", context, " c1 MISMATCH native=", DoubleToString(a.d.c1, 12), " cached=", DoubleToString(b.d.c1, 12));
        mismatches++;
    }
    if (a.d.t0 != b.d.t0)
    {
        Print("  ", context, " t0 MISMATCH native=", a.d.t0, " cached=", b.d.t0);
        mismatches++;
    }
    if (a.d.t1 != b.d.t1)
    {
        Print("  ", context, " t1 MISMATCH native=", a.d.t1, " cached=", b.d.t1);
        mismatches++;
    }

    if (0 == mismatches)
        Print("  ", context, " MATCH exactly (", size_a, " ticks)");
    else
        Print("  ", context, " MISMATCH (", mismatches, " diffs)");

    return mismatches;
} // int CompareDataVars_g

//+------------------------------------------------------------------+
//| Loops every symbol x every period in two sGlobalVars graphs,     |
//| diffing each (symbol, period) slot via CompareDataVars_g and     |
//| summing the mismatch count. Prints one overall line for this     |
//| sample (0 = full match) and returns the total.                   |
//+------------------------------------------------------------------+
int CompareGlobalVars_g(const sGlobalVars &a, const sGlobalVars &b, const string &context)
{
    int total = 0;
    int num_symbols = ArraySize(a.sSym);
    for (int s = 0; s < num_symbols; s++)
    {
        int num_periods = ArraySize(a.sSym[s].sData);
        for (int p = 0; p < num_periods; p++)
        {
            string ctx = StringFormat("%s %s %s", context, a.sSym[s].symbol, a.sSym[s].sData[p].period);
            total += CompareDataVars_g(a.sSym[s].sData[p], b.sSym[s].sData[p], ctx);
        }
    }
    Print(context, " TOTAL mismatches across all symbol x period: ", total);
    return total;
} // int CompareGlobalVars_g

//+------------------------------------------------------------------+
//| sRingBuf.mqh                                                     |
//+------------------------------------------------------------------+

template <typename T>
struct sRingBuf
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
    sRingBuf()
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
    void AddBuf(const T &item)
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
            AddBuf(item);
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
}; // sRingBuf
//+------------------------------------------------------------------+

/*

sRingBuf<sGlobalVars> ring;
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
