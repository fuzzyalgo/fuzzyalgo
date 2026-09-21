//+------------------------------------------------------------------+
//|                                              TestDayBounds.mq5 |
//| Prints GetDayBoundsMsc_g's input/output and the replay loop's    |
//| day-boundary stop, so results can be read and checked by eye.    |
//+------------------------------------------------------------------+
#include <FuzzyAlgo/variables.mqh>

long MakeMsc(int y, int mo, int d, int h, int mi, int s)
{
    MqlDateTime tm = {};
    tm.year = y; tm.mon = mo; tm.day = d;
    tm.hour = h; tm.min = mi; tm.sec = s;
    return (long)StructToTime(tm) * 1000;
}

// Prints GetDayBoundsMsc_g's input and both outputs as strings, and states
// whether start/end match the expected values.
void CheckDayBounds(const string label, const long in_time_msc,
                    const long expect_start_msc, const long expect_end_msc)
{
    long start_msc, end_msc;
    GetDayBoundsMsc_g(in_time_msc, start_msc, end_msc);

    bool ok = (start_msc == expect_start_msc) && (end_msc == expect_end_msc);

    PrintFormat("%-28s in=%s  ->  start=%s  end=%s  [%s]",
                label,
                TimeToStringMsc_g(in_time_msc),
                TimeToStringMsc_g(start_msc),
                TimeToStringMsc_g(end_msc),
                ok ? "OK" : "FAIL");
}

// Reproduces TestVariables.mq5's exact loop condition:
//   time_msc = in_time_msc + min_cnt * 60 * 1000;
//   if (!doLive && time_msc >= replay_day_end_msc) break;
// Prints the anchor, the computed day bounds, and the last sample processed
// plus the first sample rejected, all as strings.
void CheckReplayLoopStop(const long in_time_msc)
{
    long day_start_msc, day_end_msc;
    GetDayBoundsMsc_g(in_time_msc, day_start_msc, day_end_msc);

    int min_cnt = 0;
    long last_time_msc = in_time_msc;
    long time_msc = in_time_msc;
    while (time_msc < day_end_msc)
    {
        last_time_msc = time_msc;
        min_cnt++;
        time_msc = in_time_msc + min_cnt * 60 * 1000;
    }
    long first_rejected_msc = time_msc;

    PrintFormat("ReplayLoop anchor=%s  day_start=%s  day_end=%s",
                TimeToStringMsc_g(in_time_msc),
                TimeToStringMsc_g(day_start_msc),
                TimeToStringMsc_g(day_end_msc));
    PrintFormat("ReplayLoop last_processed=%s  first_rejected=%s",
                TimeToStringMsc_g(last_time_msc),
                TimeToStringMsc_g(first_rejected_msc));
}

void OnStart()
{
    CheckDayBounds("MidDay",
                   MakeMsc(2026, 9, 4, 12, 0, 0),
                   MakeMsc(2026, 9, 4, 0, 0, 0),
                   MakeMsc(2026, 9, 4, 23, 59, 59));

    CheckDayBounds("AtMidnight",
                   MakeMsc(2026, 9, 4, 0, 0, 0),
                   MakeMsc(2026, 9, 4, 0, 0, 0),
                   MakeMsc(2026, 9, 4, 23, 59, 59));

    CheckDayBounds("JustBeforeMidnight",
                   MakeMsc(2026, 9, 4, 23, 59, 59) + 999,
                   MakeMsc(2026, 9, 4, 0, 0, 0),
                   MakeMsc(2026, 9, 4, 23, 59, 59));

    CheckReplayLoopStop(MakeMsc(2026, 9, 4, 23, 55, 0)); // 5 min before midnight
}
