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

void OnStart()
{
    string symbol = "EURUSD";
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    // to_msc values matching TestVariables.mq5's mismatched rows
    // (2026.09.04 15:02/15:03/15:04/15:21/15:30/15:33/15:40/15:41).
    // window_mode "S3600": rolling 1-hour window [to-3600s, to] - matches
    // S3600's definition. window_mode "REF": fixed anchor at 15:00:00.000
    // growing to `to` - matches REF's definition. These are DIFFERENT
    // windows at the same `to_msc` (S3600 mismatches were previously
    // verified tick-identical here, but REF's actual window shape - fixed
    // anchor, not rolling - was never tested until now).
    string labels[] = {"15:02:00", "15:03:00", "15:04:00", "15:21:00", "15:30:00", "15:33:00", "15:40:00", "15:41:00"};
    int hh[] = {15, 15, 15, 15, 15, 15, 15, 15};
    int mm[] = {2, 3, 4, 21, 30, 33, 40, 41};
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
        int cache_size = CopyTicksRange_g(symbol, cache_arr, COPY_TICKS_TIME_MS, from_msc, to_msc, true);

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
            double native_bid = StringToDouble(DoubleToString(native_arr[i].bid, digits));
            double native_ask = StringToDouble(DoubleToString(native_arr[i].ask, digits));
            if (native_arr[i].time_msc != cache_arr[i].time_msc ||
                native_bid != cache_arr[i].bid ||
                native_ask != cache_arr[i].ask ||
                native_arr[i].flags != cache_arr[i].flags)
            {
                diff_count++;
                if (diff_count <= 5)
                    Print("  DIFF[", i, "] native(t=", native_arr[i].time_msc, " bid=", native_bid,
                          " ask=", native_ask, " flags=", native_arr[i].flags, ") cache(t=", cache_arr[i].time_msc,
                          " bid=", cache_arr[i].bid, " ask=", cache_arr[i].ask, " flags=", cache_arr[i].flags, ")");
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

    } // for (int w ..., int wm ...)

} // void OnStart()
//+------------------------------------------------------------------+
