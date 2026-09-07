//+------------------------------------------------------------------+
//|                                                    TickCache.mqh |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link "https://www.fuzzyalgo.com"

// Caches a full calendar day's ticks for a symbol to CSV under
// MQL5/Files/FuzzyAlgo/ticks_cache/ so a closed-market/backtest run
// (doLive=false in TestVariables.mq5) can replay the same day's ticks
// without re-issuing CopyTicksRange/CopyTicks against the terminal's tick
// store on every sample. Not intended for live use - see CopyTicksRange_g's
// scope-limit note below.

//+------------------------------------------------------------------+
//| Midnight-to-next-midnight bounds (ms) for in_time_msc's calendar |
//| day. Shared by variables.mqh's DAY branch and this file's cache  |
//| keying, so both agree on what "a day" means.                    |
//+------------------------------------------------------------------+
void GetDayBoundsMsc_g(const long in_time_msc, long &out_start_msc, long &out_end_msc)
{
    MqlDateTime tm;
    TimeToStruct(in_time_msc / 1000, tm);
    tm.hour = 0;
    tm.min = 0;
    tm.sec = 0;
    out_start_msc = (long)StructToTime(tm) * 1000;
    out_end_msc = out_start_msc + 24 * 3600 * 1000;
} // void GetDayBoundsMsc_g

struct sTickDayCache
{
    string symbol;
    long day_start_msc;
    long day_end_msc;
    MqlTick ticks[];
};

// file-scope in-memory cache, one slot per symbol+day already loaded this
// script execution (lost on OnStart return - the CSV on disk is what
// survives across runs)
sTickDayCache g_tick_day_caches[];

// Mirrors variables.mqh's I_DEBUG (sConfigVars's constructor sets this from
// I_DEBUG since TickCache.mqh has no direct access to that input - it's
// #included before I_DEBUG is declared). 0=off, >=1 enables the
// FindOrLoadDayCache_g load Print below. Declared here (not read from
// I_DEBUG directly) because #include textually inserts this file's contents
// before I_DEBUG's declaration in variables.mqh, so a direct reference from
// this file would be "used before declared".
int g_tick_cache_debug_g = 0;

//+------------------------------------------------------------------+
//| Single source of truth for the cache file path, so write/exists/ |
//| read all agree on where a given symbol+day lives.                |
//+------------------------------------------------------------------+
string TickCacheFilePath_g(const string symbol, const long day_start_msc)
{
    string date_str = TimeToString(day_start_msc / 1000, TIME_DATE);
    StringReplace(date_str, ".", "");
    return StringFormat("FuzzyAlgo\\ticks_cache\\%s_%s.csv", symbol, date_str);
} // string TickCacheFilePath_g

//+------------------------------------------------------------------+
//| Answers "does a CSV for this symbol+day already exist" without   |
//| touching the terminal's tick store or the in-memory cache.       |
//+------------------------------------------------------------------+
bool TickCacheFileExists_g(const string symbol, const long day_start_msc)
{
    return FileIsExist(TickCacheFilePath_g(symbol, day_start_msc));
} // bool TickCacheFileExists_g

//+------------------------------------------------------------------+
//| Writes arr[] to filename as CSV (header + one row per tick),     |
//| following the FileOpen(FILE_WRITE|FILE_CSV|FILE_ANSI) pattern    |
//| already used for CSV output in Ticks.mq5.                       |
//+------------------------------------------------------------------+
int WriteTicksToCsv_g(const string filename, const MqlTick &arr[], const int digits)
{
    FolderCreate("FuzzyAlgo\\ticks_cache");

    int file_handle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI);
    if (INVALID_HANDLE == file_handle)
        return -1;

    FileWriteString(file_handle, "time_msc,bid,ask,last,volume,flags,volume_real\n");
    int size1 = ArraySize(arr);
    for (int cnt = 0; cnt < size1; cnt++)
    {
        string row = StringFormat("%I64d,%s,%s,%s,%s,%u,%s\n",
                                  arr[cnt].time_msc,
                                  DoubleToString(arr[cnt].bid, digits),
                                  DoubleToString(arr[cnt].ask, digits),
                                  DoubleToString(arr[cnt].last, digits),
                                  DoubleToString((double)arr[cnt].volume, 1),
                                  arr[cnt].flags,
                                  DoubleToString(arr[cnt].volume_real, 1));
        FileWriteString(file_handle, row);
    }
    FileClose(file_handle);
    return size1;
} // int WriteTicksToCsv_g

//+------------------------------------------------------------------+
//| Reads filename back into out_arr[]. Assumes the file exists -    |
//| caller's job to have checked TickCacheFileExists_g first.        |
//+------------------------------------------------------------------+
int ReadTicksFromCsv_g(const string filename, MqlTick &out_arr[])
{
    int file_handle = FileOpen(filename, FILE_READ | FILE_CSV | FILE_ANSI);
    if (INVALID_HANDLE == file_handle)
        return -1;

    FileReadString(file_handle); // skip header row

    // Doubling-capacity growth: resizing the array by 1 on every row (the
    // previous approach) forces MQL5 to reallocate and copy the whole array
    // on every single row - O(n^2) over a ~72k-row day, which is what made
    // a cache load take "ages" compared to one native CopyTicksRange call.
    // Growing capacity by doubling means at most O(log n) reallocations.
    int capacity = 4096;
    ArrayResize(out_arr, capacity);
    int cnt = 0;
    string fields[];
    while (!FileIsEnding(file_handle))
    {
        string line = FileReadString(file_handle);
        if (0 == StringLen(line))
            continue;

        int num_fields = string_split_g(line, ",", fields);
        if (7 != num_fields)
            continue;

        if (cnt == capacity)
        {
            capacity *= 2;
            ArrayResize(out_arr, capacity);
        }

        out_arr[cnt].time_msc = (long)StringToInteger(fields[0]);
        out_arr[cnt].time = (datetime)(out_arr[cnt].time_msc / 1000);
        out_arr[cnt].bid = StringToDouble(fields[1]);
        out_arr[cnt].ask = StringToDouble(fields[2]);
        out_arr[cnt].last = StringToDouble(fields[3]);
        out_arr[cnt].volume = (ulong)StringToDouble(fields[4]);
        out_arr[cnt].flags = (uint)StringToInteger(fields[5]);
        out_arr[cnt].volume_real = StringToDouble(fields[6]);
        cnt++;
    }
    FileClose(file_handle);
    ArrayResize(out_arr, cnt);
    return cnt;
} // int ReadTicksFromCsv_g

//+------------------------------------------------------------------+
//| Fetches the whole day's ticks natively and writes them to CSV.   |
//| Always overwrites - callers wanting create-if-missing must check |
//| TickCacheFileExists_g first. Returns the tick count written, or  |
//| a negative value if the native fetch returned nothing.           |
//+------------------------------------------------------------------+
int CreateTickCacheFile_g(const string symbol, const long day_start_msc, const long day_end_msc, const ENUM_COPY_TICKS flags)
{
    MqlTick arr[];
    int size1 = CopyTicksRange(symbol, arr, flags, day_start_msc, day_end_msc);
    if (0 >= size1)
        return -1;

    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    string filename = TickCacheFilePath_g(symbol, day_start_msc);
    return WriteTicksToCsv_g(filename, arr, digits);
} // int CreateTickCacheFile_g

//+------------------------------------------------------------------+
//| Reads an existing cache CSV into out_arr[]. Assumes the file     |
//| exists - caller's job to have called TickCacheFileExists_g /     |
//| CreateTickCacheFile_g first.                                     |
//+------------------------------------------------------------------+
int LoadTickCacheFile_g(const string symbol, const long day_start_msc, MqlTick &out_arr[])
{
    string filename = TickCacheFilePath_g(symbol, day_start_msc);
    return ReadTicksFromCsv_g(filename, out_arr);
} // int LoadTickCacheFile_g

//+------------------------------------------------------------------+
//| Orchestrator: finds symbol+day in the in-memory cache, else      |
//| loads it from CSV (creating the CSV first if it doesn't exist    |
//| yet), appends a new sTickDayCache slot, and returns its index.   |
//+------------------------------------------------------------------+
int FindOrLoadDayCache_g(const string symbol, const long in_time_msc, const ENUM_COPY_TICKS flags)
{
    long day_start_msc, day_end_msc;
    GetDayBoundsMsc_g(in_time_msc, day_start_msc, day_end_msc);

    int num_caches = ArraySize(g_tick_day_caches);
    for (int cnt = 0; cnt < num_caches; cnt++)
        if (g_tick_day_caches[cnt].symbol == symbol && g_tick_day_caches[cnt].day_start_msc == day_start_msc)
            return cnt;

    bool existed = TickCacheFileExists_g(symbol, day_start_msc);
    if (!existed)
        if (0 > CreateTickCacheFile_g(symbol, day_start_msc, day_end_msc, flags))
            return -1;

    MqlTick ticks[];
    int loaded = LoadTickCacheFile_g(symbol, day_start_msc, ticks);
    if (0 > loaded)
        return -1;

    // Confirms whether this symbol+day was loaded from a pre-existing CSV
    // (existed=true, a frozen snapshot possibly from a much earlier run) vs
    // freshly fetched+written this call (existed=false) - useful when
    // diagnosing cross-run staleness, e.g. distinguishing "cache never
    // refreshed" from "cache correctly rebuilt". Gated behind g_tick_cache_debug_g
    // (mirrors I_DEBUG) since this fires once per symbol+day per script
    // execution - cheap, but still noise once the cache layer is trusted.
    if (0 < g_tick_cache_debug_g)
        Print("[TickCache] ", symbol, " day_start=", day_start_msc, " existed=", existed, " loaded=", loaded, " ticks");

    ArrayResize(g_tick_day_caches, num_caches + 1);
    g_tick_day_caches[num_caches].symbol = symbol;
    g_tick_day_caches[num_caches].day_start_msc = day_start_msc;
    g_tick_day_caches[num_caches].day_end_msc = day_end_msc;
    ArrayCopy(g_tick_day_caches[num_caches].ticks, ticks);

    return num_caches;
} // int FindOrLoadDayCache_g

//+------------------------------------------------------------------+
//| Binary-searches cache_ticks[] (sorted ascending by time_msc, the |
//| same order CopyTicksRange returns) for the first index with      |
//| time_msc >= target. Returns ArraySize(cache_ticks) if none.      |
//+------------------------------------------------------------------+
int TickCacheLowerBound_g(const MqlTick &cache_ticks[], const long target_msc)
{
    int lo = 0;
    int hi = ArraySize(cache_ticks);
    while (lo < hi)
    {
        int mid = (lo + hi) / 2;
        if (cache_ticks[mid].time_msc < target_msc)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
} // int TickCacheLowerBound_g

//+------------------------------------------------------------------+
//| Drop-in replacement for the native CopyTicksRange. When          |
//| use_cache is true, slices from the symbol+day's cached tick      |
//| array instead of hitting the terminal's tick store - never falls |
//| back to native, so any cache problem (window spanning two        |
//| calendar days, load failure) is surfaced as a negative return     |
//| rather than silently masked.                                     |
//+------------------------------------------------------------------+
int CopyTicksRange_g(const string symbol, MqlTick &out[], const ENUM_COPY_TICKS flags, const long from_msc, const long to_msc, const bool use_cache)
{
    if (!use_cache)
        return CopyTicksRange(symbol, out, flags, from_msc, to_msc);

    long day_start_msc, day_end_msc;
    GetDayBoundsMsc_g(from_msc, day_start_msc, day_end_msc);
    if (to_msc > day_end_msc)
        return -1;

    int idx = FindOrLoadDayCache_g(symbol, from_msc, flags);
    if (0 > idx)
        return -1;

    int from_idx = TickCacheLowerBound_g(g_tick_day_caches[idx].ticks, from_msc);
    int to_idx = TickCacheLowerBound_g(g_tick_day_caches[idx].ticks, to_msc + 1);
    int count = to_idx - from_idx;
    if (0 >= count)
        return 0;

    return ArrayCopy(out, g_tick_day_caches[idx].ticks, 0, from_idx, count);
} // int CopyTicksRange_g

//+------------------------------------------------------------------+
//| Drop-in replacement for the native CopyTicks. Only ever called   |
//| with count==1 in this codebase (single latest-tick-at-or-after   |
//| lookups for c0). When use_cache is true, any count other than 1, |
//| a window outside the cached day, or a cache load failure is       |
//| surfaced as a negative return - no native fallback.              |
//+------------------------------------------------------------------+
int CopyTicks_g(const string symbol, MqlTick &out[], const ENUM_COPY_TICKS flags, const long from_msc, const int count, const bool use_cache)
{
    if (!use_cache)
        return CopyTicks(symbol, out, flags, from_msc, count);

    if (1 != count)
        return -1;

    long day_start_msc, day_end_msc;
    GetDayBoundsMsc_g(from_msc, day_start_msc, day_end_msc);
    if (from_msc > day_end_msc || from_msc < day_start_msc)
        return -1;

    int idx = FindOrLoadDayCache_g(symbol, from_msc, flags);
    if (0 > idx)
        return -1;

    int from_idx = TickCacheLowerBound_g(g_tick_day_caches[idx].ticks, from_msc);
    if (from_idx >= ArraySize(g_tick_day_caches[idx].ticks))
        return 0;

    return ArrayCopy(out, g_tick_day_caches[idx].ticks, 0, from_idx, 1);
} // int CopyTicks_g
//+------------------------------------------------------------------+
