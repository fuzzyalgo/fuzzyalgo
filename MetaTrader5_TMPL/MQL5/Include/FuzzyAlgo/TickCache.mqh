//+------------------------------------------------------------------+
//|                                                    TickCache.mqh |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link "https://www.fuzzyalgo.com"

// Two complementary batching layers, both keyed by "one symbol's ticks for
// one calendar day, from day-start up to some point":
//
// 1) sTickDayCache/g_tick_day_caches (use_cache=true): caches a full
//    calendar day's ticks for a symbol to CSV under
//    MQL5/Files/FuzzyAlgo/ticks_cache/ so a closed-market/backtest run
//    (doLive=false in TestVariables.mq5) can replay the same day's ticks
//    across many time_msc samples without re-issuing CopyTicksRange/
//    CopyTicks against the terminal's tick store at all after the first
//    load. Immutable once loaded - a historical day's ticks never change.
//
// 2) sLiveTickBuffer/g_live_tick_buffers (use_cache=false): a per-symbol
//    in-memory buffer covering [day_start(now), now] for live runs. Unlike
//    (1) it keeps growing as time passes, so it's refreshed (one native
//    CopyTicksRange call) whenever a strictly newer time_msc is seen, but
//    every period branch (PRO/REF/DAY/S...) called with the SAME time_msc
//    within one sample reuses it - collapsing what would otherwise be N
//    native calls per symbol per sample (one per period) down to 1.
//
// Both are sliced via the same TickCacheLowerBound_g binary search, so
// CopyTicksRange_g presents one drop-in-replacement API to callers
// (variables.mqh's init_ticks_arr_g) regardless of which mode is active.

//+------------------------------------------------------------------+
//| Midnight-to-next-midnight bounds (ms) for in_time_msc's calendar |
//| day. Shared by variables.mqh's DAY branch and this file's cache  |
//| keying, so both agree on what "a day" means.                     |
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

//+------------------------------------------------------------------+
//| Live-mode counterpart of sTickDayCache/g_tick_day_caches. That   |
//| cache is for closed-market/backtest days and is immutable once   |
//| loaded (a historical day's ticks never change). Live "today" is  |
//| the opposite - it keeps growing as time passes - so this buffer  |
//| holds "today's ticks from day-start up to the last time_msc we   |
//| fetched", and is refreshed (one native CopyTicksRange call) only |
//| when a NEW time_msc is seen; every period branch in               |
//| init_ticks_arr_g that runs for that same time_msc (PRO/REF/DAY/  |
//| S...) reuses the buffer via TickCacheLowerBound_g slicing instead |
//| of each issuing its own native call. See CopyTicksRange_g below   |
//| and docs/design-decisions.md's tick-fetch batching notes for why |
//| this exists.                                                       |
//+------------------------------------------------------------------+
struct sLiveTickBuffer
{
    string symbol;
    long day_start_msc;
    long last_to_msc; // the `to_msc` this buffer's ticks[] was last fetched up to
    MqlTick ticks[];
};

sLiveTickBuffer g_live_tick_buffers[];

//+------------------------------------------------------------------+
//| Finds (or creates) symbol's live buffer slot. If the calendar    |
//| day has rolled over since it was last used, resets it to the new |
//| day. If it's already fetched up to (>=) to_msc - i.e. this is    |
//| not the first period-branch call for this exact time_msc sample -|
//| returns immediately with no native call. Otherwise issues exactly|
//| one native CopyTicksRange(symbol, day_start_msc, to_msc) and      |
//| stores the result. Returns the buffer's index, or -1 on a real   |
//| fetch error (previous buffer contents are left intact so a       |
//| transient failure doesn't wipe out otherwise-usable data).       |
//+------------------------------------------------------------------+
int FindOrRefreshLiveBuffer_g(const string symbol, const long to_msc, const ENUM_COPY_TICKS flags, const int debug)
{
    long day_start_msc, day_end_msc;
    GetDayBoundsMsc_g(to_msc, day_start_msc, day_end_msc);

    int num_buffers = ArraySize(g_live_tick_buffers);
    int idx = -1;
    for (int cnt = 0; cnt < num_buffers; cnt++)
        if (g_live_tick_buffers[cnt].symbol == symbol)
        {
            idx = cnt;
            break;
        }

    if (0 > idx)
    {
        ArrayResize(g_live_tick_buffers, num_buffers + 1);
        idx = num_buffers;
        g_live_tick_buffers[idx].symbol = symbol;
        g_live_tick_buffers[idx].day_start_msc = day_start_msc;
        g_live_tick_buffers[idx].last_to_msc = 0;
    }

    // Calendar day rolled over since this symbol's buffer was last filled -
    // drop it so it gets rebuilt from the new day's start instead of mixing
    // ticks from two different days in one ticks[] array.
    if (g_live_tick_buffers[idx].day_start_msc != day_start_msc)
    {
        g_live_tick_buffers[idx].day_start_msc = day_start_msc;
        g_live_tick_buffers[idx].last_to_msc = 0;
        ArrayFree(g_live_tick_buffers[idx].ticks);
    }

    // Already fetched up to (or past) this exact to_msc - every period
    // branch (PRO/REF/DAY/S...) for this symbol at this time_msc shares one
    // fetch. Strictly newer to_msc values (the next sample) still refetch.
    if (g_live_tick_buffers[idx].last_to_msc >= to_msc)
        return idx;

    MqlTick fresh[];
    int size1 = CopyTicksRange(symbol, fresh, flags, day_start_msc, to_msc);
    if (0 > size1)
        return -1; // real fetch error - leave previous buffer contents usable

    ArrayCopy(g_live_tick_buffers[idx].ticks, fresh);
    g_live_tick_buffers[idx].last_to_msc = to_msc;

    if (0 < debug)
        Print("[LiveTickBuffer] ", symbol, " to_msc=", to_msc, " ticks=", size1);

    return idx;
} // int FindOrRefreshLiveBuffer_g

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
//| already used for CSV output in Ticks.mq5. Prices are normalized  |
//| to the symbol's point grid before writing; volume fields retain  |
//| two decimal places. ReadTicksFromCsv_g repeats price             |
//| normalization so old and newly-created cache files have the same |
//| in-memory representation.                                        |
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
                                  DoubleToString(NormalizeDouble(arr[cnt].bid, digits), digits),
                                  DoubleToString(NormalizeDouble(arr[cnt].ask, digits), digits),
                                  DoubleToString(NormalizeDouble(arr[cnt].last, digits), digits),
                                  DoubleToString((double)arr[cnt].volume, 2),
                                  arr[cnt].flags,
                                  DoubleToString(arr[cnt].volume_real, 2));
        FileWriteString(file_handle, row);
    }
    FileClose(file_handle);
    return size1;
} // int WriteTicksToCsv_g

//+------------------------------------------------------------------+
//| Reads filename back into out_arr[] and canonicalizes prices to   |
//| the symbol's point grid. Assumes the file exists - caller's job  |
//| to have checked TickCacheFileExists_g first.                     |
//+------------------------------------------------------------------+
int ReadTicksFromCsv_g(const string filename, MqlTick &out_arr[], const int digits)
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
        out_arr[cnt].bid = NormalizeDouble(StringToDouble(fields[1]), digits);
        out_arr[cnt].ask = NormalizeDouble(StringToDouble(fields[2]), digits);
        out_arr[cnt].last = NormalizeDouble(StringToDouble(fields[3]), digits);
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
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    string filename = TickCacheFilePath_g(symbol, day_start_msc);
    return ReadTicksFromCsv_g(filename, out_arr, digits);
} // int LoadTickCacheFile_g

//+------------------------------------------------------------------+
//| Orchestrator: finds symbol+day in the in-memory cache, else      |
//| loads it from CSV (creating the CSV first if it doesn't exist    |
//| yet), appends a new sTickDayCache slot, and returns its index.   |
//+------------------------------------------------------------------+
int FindOrLoadDayCache_g(const string symbol, const long in_time_msc, const ENUM_COPY_TICKS flags, const int debug)
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
    // refreshed" from "cache correctly rebuilt". Gated behind the caller's
    // debug level (variables.mqh's sConfig.DEBUG, threaded in explicitly)
    // since this fires once per symbol+day per script execution - cheap, but
    // still noise once the cache layer is trusted.
    if (0 < debug)
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
//| Drop-in replacement for the native CopyTicksRange.                |
//|                                                                    |
//| use_cache==true  (closed-market/backtest): slices from the       |
//| symbol+day's cached tick array (g_tick_day_caches, loaded once    |
//| from CSV) instead of hitting the terminal's tick store.           |
//|                                                                    |
//| use_cache==false (live): slices from the symbol's live buffer     |
//| (g_live_tick_buffers, FindOrRefreshLiveBuffer_g above) instead of |
//| calling native CopyTicksRange directly. That buffer only ever     |
//| covers [day_start(to_msc), to_msc] - every period branch in       |
//| init_ticks_arr_g runs with the same to_msc==in_time_msc within    |
//| one sample, so this collapses N native calls per symbol per       |
//| sample (one per period) down to exactly 1. If from_msc falls      |
//| before the buffer's day_start (e.g. a PRO position opened on an   |
//| earlier calendar day), falls back to a direct native call for     |
//| that one request only - the buffer itself is not widened for it,  |
//| so it doesn't grow unboundedly across days.                       |
//|                                                                    |
//| Neither branch falls back to native on a same-day cache/buffer    |
//| problem (load failure, etc.) - surfaced as a negative return      |
//| rather than silently masked.                                      |
//+------------------------------------------------------------------+
int CopyTicksRange_g(const string symbol, MqlTick &out[], const ENUM_COPY_TICKS flags, const long from_msc, const long to_msc, const bool use_cache, const int debug)
{
    if (!use_cache)
    {
        long live_day_start_msc, live_day_end_msc;
        GetDayBoundsMsc_g(to_msc, live_day_start_msc, live_day_end_msc);
        if (from_msc < live_day_start_msc)
            return CopyTicksRange(symbol, out, flags, from_msc, to_msc);

        int live_idx = FindOrRefreshLiveBuffer_g(symbol, to_msc, flags, debug);
        if (0 > live_idx)
            return -1;

        int live_from_idx = TickCacheLowerBound_g(g_live_tick_buffers[live_idx].ticks, from_msc);
        int live_to_idx = TickCacheLowerBound_g(g_live_tick_buffers[live_idx].ticks, to_msc + 1);
        int live_count = live_to_idx - live_from_idx;
        if (0 >= live_count)
            return 0;

        return ArrayCopy(out, g_live_tick_buffers[live_idx].ticks, 0, live_from_idx, live_count);
    }

    long day_start_msc, day_end_msc;
    GetDayBoundsMsc_g(from_msc, day_start_msc, day_end_msc);
    if (to_msc > day_end_msc)
        return -1;

    int idx = FindOrLoadDayCache_g(symbol, from_msc, flags, debug);
    if (0 > idx)
        return -1;

    int from_idx = TickCacheLowerBound_g(g_tick_day_caches[idx].ticks, from_msc);
    int to_idx = TickCacheLowerBound_g(g_tick_day_caches[idx].ticks, to_msc + 1);
    int count = to_idx - from_idx;
    if (0 >= count)
        return 0;

    return ArrayCopy(out, g_tick_day_caches[idx].ticks, 0, from_idx, count);
} // int CopyTicksRange_g
