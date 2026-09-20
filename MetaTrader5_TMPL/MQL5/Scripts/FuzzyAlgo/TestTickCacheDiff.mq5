//+------------------------------------------------------------------+
//|                                          TestTickCacheDiff.mq5   |
//|                             Copyright 2000-2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

#include <FuzzyAlgo/variables.mqh>

// Diagnostic: for a fixed set of [from_msc, to_msc] windows (matching the
// S3600 windows at timestamps where TestVariables.mq5's true/false runs
// disagreed), fetch ticks both natively (CopyTicksRange) and via the cache
// (CopyTicksRange_g with use_cache=true), then diff the two raw tick arrays
// directly - no OC/HL derivation involved - to isolate whether the mismatch
// is in the cache's slicing logic itself.

// Second diagnostic (NativeVsNativeCheck): calls native CopyTicksRange twice
// for the same historical window, seconds apart, with no caching involved at
// all. If these two calls ever disagree with each other, the terminal's local
// tick store for that day is not fully settled yet / is being mutated by a
// background broker sync - which would explain TestVariables.mq5 true/false
// runs disagreeing minutes apart even though TestTickCacheDiff (native vs
// cache within one execution) always matches exactly.
void NativeVsNativeCheck(const string symbol, const int digits, const long from_msc, const long to_msc, const string label)
{
    MqlTick first_arr[];
    int first_size = CopyTicksRange(symbol, first_arr, COPY_TICKS_TIME_MS, from_msc, to_msc);

    Sleep(3000);

    MqlTick second_arr[];
    int second_size = CopyTicksRange(symbol, second_arr, COPY_TICKS_TIME_MS, from_msc, to_msc);

    Print("--- native-vs-native ", label, " [", from_msc, ", ", to_msc, "] first=", first_size, " second=", second_size);

    if (first_size != second_size)
        Print("  SIZE MISMATCH first=", first_size, " second=", second_size);

    int min_size = MathMin(first_size, second_size);
    int diff_count = 0;
    for (int i = 0; i < min_size; i++)
    {
        double first_bid = StringToDouble(DoubleToString(first_arr[i].bid, digits));
        double second_bid = StringToDouble(DoubleToString(second_arr[i].bid, digits));
        double first_ask = StringToDouble(DoubleToString(first_arr[i].ask, digits));
        double second_ask = StringToDouble(DoubleToString(second_arr[i].ask, digits));
        if (first_arr[i].time_msc != second_arr[i].time_msc ||
            first_bid != second_bid ||
            first_ask != second_ask ||
            first_arr[i].flags != second_arr[i].flags)
        {
            diff_count++;
            if (diff_count <= 5)
                Print("  DIFF[", i, "] first(t=", first_arr[i].time_msc, " bid=", first_bid,
                      " ask=", first_ask, " flags=", first_arr[i].flags, ") second(t=", second_arr[i].time_msc,
                      " bid=", second_bid, " ask=", second_ask, " flags=", second_arr[i].flags, ")");
        }
    }

    if (0 == diff_count && first_size == second_size)
        Print("  NATIVE-VS-NATIVE MATCH exactly (", first_size, " ticks)");
} // void NativeVsNativeCheck

// Mirrors init_data_from_ticks_arr_g's c0/c1/OC and high/low/HL derivation
// (variables.mqh) exactly, but returns the raw undivided/uncast doubles
// plus the index of the tick that produced the high/low extreme - so a
// native-vs-cache OC/HL difference can be pinned to one specific tick
// instead of just "some tick in this window differs".
void ComputeOcHlRaw_g(const MqlTick &arr[], const double point,
                       double &out_c0, double &out_c1, double &out_oc_raw,
                       double &out_high, double &out_low, double &out_hl_raw,
                       int &out_high_idx, int &out_low_idx)
{
    int size1 = ArraySize(arr);
    out_c0 = (arr[size1 - 1].ask + arr[size1 - 1].bid) / 2;
    out_c1 = (arr[0].ask + arr[0].bid) / 2;
    out_oc_raw = (out_c0 - out_c1) / point;

    out_high = 0;
    out_low = 1000000000;
    out_high_idx = -1;
    out_low_idx = -1;
    for (int cnt = 0; cnt < size1; cnt++)
    {
        if (out_high < arr[cnt].ask)
        {
            out_high = arr[cnt].ask;
            out_high_idx = cnt;
        }
        if (out_low > arr[cnt].bid)
        {
            out_low = arr[cnt].bid;
            out_low_idx = cnt;
        }
    }
    out_hl_raw = (out_high - out_low) / point;
} // void ComputeOcHlRaw_g

// Runs ComputeOcHlRaw_g on both native_arr and cache_arr for one window and
// prints exactly where they disagree: the raw OC/HL doubles, the truncated
// vs MathRound'd int that PrintRow would have displayed pre/post the
// truncation->MathRound fix, and - if HL's extreme-tick index differs
// between native and cache - the specific tick (time/ask/bid, both sides)
// responsible, at full precision so a CSV round-trip ULP difference is
// visible even when the digits-normalized text would look identical.
void CompareOcHlDerivation(const string &label, const MqlTick &native_arr[], const MqlTick &cache_arr[], const double point, const int digits)
{
    double native_c0, native_c1, native_oc_raw, native_high, native_low, native_hl_raw;
    int native_high_idx, native_low_idx;
    ComputeOcHlRaw_g(native_arr, point, native_c0, native_c1, native_oc_raw, native_high, native_low, native_hl_raw, native_high_idx, native_low_idx);

    double cache_c0, cache_c1, cache_oc_raw, cache_high, cache_low, cache_hl_raw;
    int cache_high_idx, cache_low_idx;
    ComputeOcHlRaw_g(cache_arr, point, cache_c0, cache_c1, cache_oc_raw, cache_high, cache_low, cache_hl_raw, cache_high_idx, cache_low_idx);

    int oc_trunc_native = (int)native_oc_raw;
    int oc_trunc_cache = (int)cache_oc_raw;
    int oc_round_native = (int)MathRound(native_oc_raw);
    int oc_round_cache = (int)MathRound(cache_oc_raw);
    int hl_trunc_native = (int)native_hl_raw;
    int hl_trunc_cache = (int)cache_hl_raw;
    int hl_round_native = (int)MathRound(native_hl_raw);
    int hl_round_cache = (int)MathRound(cache_hl_raw);

    Print("  OC_HL_DERIVED ", label,
          " OC_raw(native=", DoubleToString(native_oc_raw, 12), " cache=", DoubleToString(cache_oc_raw, 12), ")",
          " OC_trunc(native=", oc_trunc_native, " cache=", oc_trunc_cache, ")",
          " OC_round(native=", oc_round_native, " cache=", oc_round_cache, ")");
    Print("  OC_HL_DERIVED ", label,
          " HL_raw(native=", DoubleToString(native_hl_raw, 12), " cache=", DoubleToString(cache_hl_raw, 12), ")",
          " HL_trunc(native=", hl_trunc_native, " cache=", hl_trunc_cache, ")",
          " HL_round(native=", hl_round_native, " cache=", hl_round_cache, ")");

    if (oc_trunc_native != oc_trunc_cache)
        Print("  >>> OC TRUNCATION FLIP would have occurred here (fixed by MathRound if OC_round now matches)");
    if (hl_trunc_native != hl_trunc_cache)
        Print("  >>> HL TRUNCATION FLIP would have occurred here (fixed by MathRound if HL_round now matches)");
    if (oc_round_native != oc_round_cache)
        Print("  >>> OC STILL DIFFERS AFTER ROUNDING - not a truncation artifact, real tick-set/precision difference");
    if (hl_round_native != hl_round_cache)
        Print("  >>> HL STILL DIFFERS AFTER ROUNDING - not a truncation artifact, real tick-set/precision difference");

    // c0/c1 come straight from the window's last/first tick - if OC differs,
    // print those endpoint ticks at full precision (both sides) so a CSV
    // round-trip ULP difference is visible even past what `digits` shows.
    if (oc_trunc_native != oc_trunc_cache || oc_round_native != oc_round_cache)
    {
        int size1_native = ArraySize(native_arr);
        int size1_cache = ArraySize(cache_arr);
        Print("  OC endpoint c0 (last tick) native: t=", native_arr[size1_native - 1].time_msc,
              " ask=", DoubleToString(native_arr[size1_native - 1].ask, 12),
              " bid=", DoubleToString(native_arr[size1_native - 1].bid, 12));
        Print("  OC endpoint c0 (last tick) cache:  t=", cache_arr[size1_cache - 1].time_msc,
              " ask=", DoubleToString(cache_arr[size1_cache - 1].ask, 12),
              " bid=", DoubleToString(cache_arr[size1_cache - 1].bid, 12));
        Print("  OC endpoint c1 (first tick) native: t=", native_arr[0].time_msc,
              " ask=", DoubleToString(native_arr[0].ask, 12),
              " bid=", DoubleToString(native_arr[0].bid, 12));
        Print("  OC endpoint c1 (first tick) cache:  t=", cache_arr[0].time_msc,
              " ask=", DoubleToString(cache_arr[0].ask, 12),
              " bid=", DoubleToString(cache_arr[0].bid, 12));
    }

    // HL's high/low come from whichever tick had the max ask / min bid - if
    // that's a DIFFERENT tick index between native and cache (not just a
    // precision difference on the same tick), print both candidates from
    // both sides so the actual culprit tick is identifiable.
    if (hl_trunc_native != hl_trunc_cache || hl_round_native != hl_round_cache)
    {
        Print("  HL high(ask) native: idx=", native_high_idx, " t=", native_arr[native_high_idx].time_msc,
              " ask=", DoubleToString(native_arr[native_high_idx].ask, 12));
        Print("  HL high(ask) cache:  idx=", cache_high_idx, " t=", cache_arr[cache_high_idx].time_msc,
              " ask=", DoubleToString(cache_arr[cache_high_idx].ask, 12));
        Print("  HL low(bid) native:  idx=", native_low_idx, " t=", native_arr[native_low_idx].time_msc,
              " bid=", DoubleToString(native_arr[native_low_idx].bid, 12));
        Print("  HL low(bid) cache:   idx=", cache_low_idx, " t=", cache_arr[cache_low_idx].time_msc,
              " bid=", DoubleToString(cache_arr[cache_low_idx].bid, 12));

        if (native_high_idx != cache_high_idx || native_arr[native_high_idx].time_msc != cache_arr[cache_high_idx].time_msc)
            Print("  >>> HL high-tick INDEX/TIME differs between native and cache - different tick selected as the max, not just a precision wobble on the same tick");
        if (native_low_idx != cache_low_idx || native_arr[native_low_idx].time_msc != cache_arr[cache_low_idx].time_msc)
            Print("  >>> HL low-tick INDEX/TIME differs between native and cache - different tick selected as the min, not just a precision wobble on the same tick");
    }
} // void CompareOcHlDerivation

void OnStart()
{
    string symbol = "EURUSD";
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    // to_msc values matching TestVariables.mq5's mismatched rows - the
    // original set (15:02/15:03/15:04/15:21/15:30/15:33/15:40/15:41) plus
    // 15:14 and 15:16, added after a fresh-cache cache=false/cache=true
    // comparison (stale-CSV ruled out) still showed S3600 OC/SUM_NEG/SUM_POS
    // off by 1 at those two timestamps.
    // window_mode "S3600": rolling 1-hour window [to-3600s, to] - matches
    // S3600's definition. window_mode "REF": fixed anchor at 15:00:00.000
    // growing to `to` - matches REF's definition. These are DIFFERENT
    // windows at the same `to_msc` (S3600 mismatches were previously
    // verified tick-identical here, but REF's actual window shape - fixed
    // anchor, not rolling - was never tested until now).
    string labels[] = {"15:02:00", "15:03:00", "15:04:00", "15:14:00", "15:16:00", "15:21:00", "15:30:00", "15:33:00", "15:40:00", "15:41:00"};
    int hh[] = {15, 15, 15, 15, 15, 15, 15, 15, 15, 15};
    int mm[] = {2, 3, 4, 14, 16, 21, 30, 33, 40, 41};
    string window_modes[] = {"S3600", "REF"};

    MqlDateTime ref_tm = {};
    ref_tm.year = 2026;
    ref_tm.mon = 9;
    ref_tm.day = 4;
    ref_tm.hour = 15;
    ref_tm.min = 0;
    ref_tm.sec = 0;
    long ref_anchor_msc = StructToTime(ref_tm) * 1000;

    for (int w = 0; w < ArraySize(labels); w++)
    for (int wm = 0; wm < ArraySize(window_modes); wm++)
    {
        MqlDateTime tm = {};
        tm.year = 2026;
        tm.mon = 9;
        tm.day = 4;
        tm.hour = hh[w];
        tm.min = mm[w];
        tm.sec = 0;
        long to_msc = StructToTime(tm) * 1000;
        long from_msc = ("S3600" == window_modes[wm]) ? (to_msc - 3600 * 1000) : ref_anchor_msc;
        string label = labels[w] + " [" + window_modes[wm] + "]";

        if (from_msc >= to_msc)
            continue; // REF mode at to==anchor: zero-width, skip

        NativeVsNativeCheck(symbol, digits, from_msc, to_msc, label);

        // Confirms whether cache_arr below comes from a CSV that already
        // existed on disk (a frozen snapshot from a PAST script execution,
        // possibly minutes/hours old) vs one built fresh in this same call
        // (which would make native-vs-cache trivially match regardless of
        // any cross-time variance in native CopyTicksRange).
        long day_start_msc, day_end_msc;
        GetDayBoundsMsc_g(from_msc, day_start_msc, day_end_msc);
        bool cache_preexisted = TickCacheFileExists_g(symbol, day_start_msc);
        Print("  cache_preexisted=", cache_preexisted);

        MqlTick native_arr[];
        int native_size = CopyTicksRange(symbol, native_arr, COPY_TICKS_TIME_MS, from_msc, to_msc);

        // Fingerprint of THIS execution's native result, cheap to eyeball-diff
        // against the same line from a SEPARATE script execution minutes/hours
        // later - the comparison NativeVsNativeCheck (3s apart, same execution)
        // structurally cannot make. If native CopyTicksRange for this exact
        // historical window ever returns a different fingerprint across two
        // separate runs, that is direct proof of cross-execution native drift.
        double bid_sum = 0.0;
        long time_sum = 0;
        for (int i = 0; i < native_size; i++)
        {
            bid_sum += native_arr[i].bid;
            time_sum += native_arr[i].time_msc;
        }
        Print("  NATIVE FINGERPRINT ", label, " size=", native_size,
              " first_t=", (native_size > 0 ? native_arr[0].time_msc : 0),
              " last_t=", (native_size > 0 ? native_arr[native_size - 1].time_msc : 0),
              " time_sum=", time_sum, " bid_sum=", DoubleToString(bid_sum, 8));

        MqlTick cache_arr[];
        int cache_size = CopyTicksRange_g(symbol, cache_arr, COPY_TICKS_TIME_MS, from_msc, to_msc, true, I_DEBUG);

        Print("=== window ", label, " [", from_msc, ", ", to_msc, "] native=", native_size, " cache=", cache_size);

        if (native_size != cache_size)
        {
            Print("  SIZE MISMATCH native=", native_size, " cache=", cache_size);
        }

        int min_size = MathMin(native_size, cache_size);
        int diff_count = 0;
        int raw_diff_count = 0;
        for (int i = 0; i < min_size; i++)
        {
            // Compare both sides on the symbol's point grid, matching
            // TickCache.mqh's persisted price representation.
            double native_bid = StringToDouble(DoubleToString(native_arr[i].bid, digits));
            double native_ask = StringToDouble(DoubleToString(native_arr[i].ask, digits));
            double cache_bid = StringToDouble(DoubleToString(cache_arr[i].bid, digits));
            double cache_ask = StringToDouble(DoubleToString(cache_arr[i].ask, digits));
            if (native_arr[i].time_msc != cache_arr[i].time_msc ||
                native_bid != cache_bid ||
                native_ask != cache_ask ||
                native_arr[i].flags != cache_arr[i].flags)
            {
                diff_count++;
                if (diff_count <= 5)
                    Print("  DIFF[", i, "] native(t=", native_arr[i].time_msc, " bid=", native_bid,
                          " ask=", native_ask, " flags=", native_arr[i].flags, ") cache(t=", cache_arr[i].time_msc,
                          " bid=", cache_bid, " ask=", cache_ask, " flags=", cache_arr[i].flags, ")");
            }

            // Raw (un-rounded) comparison - catches precision lost in the CSV
            // round-trip that the digits-normalized check above cannot see,
            // since it normalizes native through the same DoubleToString(digits)
            // step before comparing.
            if (native_arr[i].bid != cache_arr[i].bid || native_arr[i].ask != cache_arr[i].ask)
            {
                raw_diff_count++;
                if (raw_diff_count <= 5)
                    Print("  RAWDIFF[", i, "] native(bid=", DoubleToString(native_arr[i].bid, 12),
                          " ask=", DoubleToString(native_arr[i].ask, 12), ") cache(bid=", DoubleToString(cache_arr[i].bid, 12),
                          " ask=", DoubleToString(cache_arr[i].ask, 12), ")");
            }
        }
        if (0 < raw_diff_count)
            Print("  RAW PRECISION DIFF COUNT: ", raw_diff_count, " / ", min_size);

        if (native_size > cache_size)
        {
            for (int i = cache_size; i < native_size && i < cache_size + 5; i++)
                Print("  EXTRA in native[", i, "]: t=", native_arr[i].time_msc, " bid=", native_arr[i].bid, " ask=", native_arr[i].ask);
            Print("  first native tick: t=", native_arr[0].time_msc, " last native tick: t=", native_arr[native_size - 1].time_msc);
        }
        else if (cache_size > native_size)
        {
            for (int i = native_size; i < cache_size && i < native_size + 5; i++)
                Print("  EXTRA in cache[", i, "]: t=", cache_arr[i].time_msc, " bid=", cache_arr[i].bid, " ask=", cache_arr[i].ask);
            Print("  first cache tick: t=", cache_arr[0].time_msc, " last cache tick: t=", cache_arr[cache_size - 1].time_msc);
        }

        if (0 == diff_count && native_size == cache_size)
            Print("  MATCH exactly (", native_size, " ticks)");

        // Raw ticks can match exactly (diff_count==0 above) while the
        // OC/HL derived from them still disagree - e.g. HL's high/low tick
        // is picked via a strict `<`/`>` comparison (init_data_from_ticks_arr_g,
        // variables.mqh), so a native-vs-cache tie at the true extreme (two
        // ticks with the same ask, one from native's in-memory double, one
        // from the cache's CSV-round-tripped double) can make each side pick
        // a DIFFERENT tick as "the" high/low if float ordering differs by
        // ~1 ULP - which then differs by point-multiples once divided by
        // `point`. This call finds and reports that, independent of whether
        // the raw-tick diff above fired.
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        if (0 < native_size && 0 < cache_size)
            CompareOcHlDerivation(label, native_arr, cache_arr, point, digits);

    } // for (int w ..., int wm ...)

} // void OnStart()
//+------------------------------------------------------------------+
