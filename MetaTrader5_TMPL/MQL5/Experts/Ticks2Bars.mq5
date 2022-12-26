//+------------------------------------------------------------------+
//|                                                   Ticks2Bars.mq5 |
//|                               Copyright (c) 2018-2019, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                        https://www.mql5.com/en/blogs/post/719145 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018-2019, Marketeer"
#property link      "https://www.mql5.com/en/users/marketeer"
#property version   "1.0"
#property description "Ticks2Bars\n"
#property description "Non-trading expert, generating bar chart from ticks - 1 bar per 1 tick."

/*
https://www.mql5.com/en/blogs/post/719145
https://www.mql5.com/en/blogs/post/718632
https://www.mql5.com/en/blogs/post/718430
https://www.mql5.com/en/blogs/post/748035
*/

// I N C L U D E S

#include <Symbol2.mqh>


// T Y P E D E F S

enum BAR_RENDER_MODE
{
  OHLC,
  HighLow
};

// I N P U T S

input int Limit = 1000;
input bool Reset = true;
input bool LoopBack = true;
input bool EmulateTicks = true;
input BAR_RENDER_MODE RenderBars = OHLC;


// G L O B A L S

string symbolName;
bool firstRun;
bool stopAll;
bool justCreated;
datetime lastTime;

MqlRates rates[];


// A P P L I C A T I O N

void reset()
{
  ResetLastError();
  int deleted = CustomRatesDelete(symbolName, 0, LONG_MAX);
  int err = GetLastError();
  if(err != ERR_SUCCESS)
  {
    Alert("CustomRatesDelete failed, ", err);
    stopAll = true;
    return;
  }
  else
  {
    Print("Rates deleted: ", deleted);
  }
  
  ResetLastError();
  deleted = CustomTicksDelete(symbolName, 0, LONG_MAX);
  if(deleted == -1)
  {
    Print("CustomTicksDelete failed ", GetLastError());
    stopAll = true;
    return;
  }
  else
  {
    Print("Ticks deleted: ", deleted);
  }

  // wait for changes to take effect in background (asynchronously)
  int size;
  do
  {
    Sleep(1000);

    MqlTick array[];
    Print( "C3" );
    size = CopyTicks(symbolName, array, COPY_TICKS_ALL, 0, 10);
    Print( "C4" );
    Print("Remaining ticks: ", size);
  } while(size > 0);
  // NB.
  // still this can not work everytime as expected
  // if getting ERR_CUSTOM_TICKS_WRONG_ORDER or similar error - the last resort
  // is to wipe out the custom symbol manually from GUI, and then restart this EA
}

bool apply(const datetime cursor, const MqlTick &t, MqlRates &r)
{
  static MqlTick p;
  
  // eliminate strange things
  if(t.ask == 0 || t.bid == 0 || t.ask < t.bid) return false;
  
  r.high = t.ask;
  r.low = t.bid;
  
  if(t.last != 0)
  {
    if(RenderBars == OHLC)
    {
      if(t.last > p.last)
      {
        r.open = r.low;
        r.close = r.high;
      }
      else
      {
        r.open = r.high;
        r.close = r.low;
      }
    }
    else
    {
      r.open = r.close = (r.high + r.low) / 2;
    }
    
    if(t.last < t.bid) r.low = t.last;
    if(t.last > t.ask) r.high = t.last;
    r.close = t.last;
  }
  else
  {
    if(RenderBars == OHLC)
    {
      if((t.ask + t.bid) / 2 > (p.ask + p.bid) / 2)
      {
        r.open = r.low;
        r.close = r.high;
      }
      else
      {
        r.open = r.high;
        r.close = r.low;
      }
    }
    else
    {
      r.open = r.close = (r.high + r.low) / 2;
    }
  }
  
  r.time = cursor;
  r.spread = (int)((t.ask - t.bid)/_Point);
  r.tick_volume = 1;
  r.real_volume = (long)t.volume;

  p = t;
  return true;
}

void fillArray()
{
  MqlTick array[];
  //Print( "C1" );
  int size = CopyTicks(_Symbol, array, COPY_TICKS_ALL, 0, Limit);
  //int size = CopyTicksRange(_Symbol, array, COPY_TICKS_ALL, 1665761400000, 1665763200000);
  /*
  15:00
  1665759600000
  15:30
  1665761400000
  16:00
  1665763200000
  Date and time (GMT): Friday, 14 October 2022 15:30:00
  Date and time (your time zone): Friday, 14 October 2022 17:30:00 GMT+02:00
  */
  //Print( "C2" );
  if(size == -1)
  {
    Print("CopyTicks failed: ", GetLastError());
    stopAll = true;
  }
  else
  {
    Print("Ticks start at ", array[0].time, "'", array[0].time_msc % 1000);
    MqlRates r[];
    ArrayResize(r, size);
    datetime start = (datetime)(((long)TimeCurrent() / 60 * 60) - (size - 1) * 60);
    datetime cursor = start;
    int j = 0;
    for(int i = 0; i < size; i++)
    {
      if(apply(cursor, array[i], r[j]))
      {
        cursor += 60;
        j++;
      }
    }
    if(j < size)
    {
      Print("Shrinking to ", j);
      ArrayResize(r, j);
    }
    if(CustomRatesUpdate(symbolName, r) == 0)
    {
      Print("CustomRatesUpdate failed: ", GetLastError());
      stopAll = true;
    }
  }
}

void shift()
{
  ResetLastError();
  int length = CopyRates(symbolName, PERIOD_M1, 0, Limit, rates);
  if(length <= 0)
  {
    Print("CopyRates failed: ", GetLastError(), " length: ", length);
    stopAll = true;
  }
  else
  {
    for(int i = 0; i < length; i++)
    {
      rates[i].time -= 60;
    }

    if(CustomRatesDelete(symbolName, 0, rates[0].time - 60) == -1)
    {
      Print("Not deleted: ", GetLastError());
    }
    
    if(CustomRatesUpdate(symbolName, rates) == -1)
    {
      Print("Not shifted: ", GetLastError());
      stopAll = true;
    }
  }
}

void add(datetime time = 0)
{
  MqlTick t;
  if(SymbolInfoTick(_Symbol, t))
  {
    if(time == 0) time = (datetime)((long)TimeCurrent() / 60 * 60);
    
    t.time = time;
    t.time_msc = time * 1000;

    MqlRates r[1];
    if(apply(time, t, r[0]))
    {
      if(EmulateTicks)
      {
        MqlTick ta[1];
        ta[0] = t;
        ta[0].time += 60; // forward tick (next temporary bar) to activate EA (if any)
        ta[0].time_msc = ta[0].time * 1000;
        if(CustomTicksAdd(symbolName, ta) == -1)
        {
          Print("Not ticked:", GetLastError(), " ", (long)ta[0].time);
          ArrayPrint(ta);
          stopAll = true;
        }
        // remove the temporary tick
        CustomTicksDelete(symbolName, ta[0].time_msc, LONG_MAX);
      }
      if(CustomRatesUpdate(symbolName, r) == -1)
      {
        Print("Not updated: ", GetLastError());
        ArrayPrint(r);
        stopAll = true;
      }
    }
  }
}


// E V E N T   H A N D L E R S

int OnInit(void)
{
  stopAll = false;
  justCreated = false;
  
  if(SymbolInfoInteger(_Symbol, SYMBOL_CUSTOM))
  {
    Alert("" + _Symbol + " is a custom symbol. Only built-in symbol can be used as a host.");
    return INIT_FAILED;
  }
  
  symbolName = Symbol() + "_ticks";

  if(!SymbolSelect(symbolName, true))
  {
    const SYMBOL Symb(symbolName);
    Symb.CloneProperties(_Symbol);
    justCreated = true;
    
    if(!SymbolSelect(symbolName, true))
    {
      Alert("Can't select symbol:", symbolName, " err:", GetLastError());
      return INIT_FAILED;
    }
  }
  
  EventSetTimer(1);
  firstRun = true;
  
  return INIT_SUCCEEDED;
}

void OnTimer()
{
  OnTick();
}

void OnTick(void)
{
  //Print( "1" );

  if(stopAll) return;

  //Print( "2" );
  
  if(firstRun)
  {
    if(!TerminalInfoInteger(TERMINAL_CONNECTED))
    {
      Print("Waiting for connection...");
      return;
    }
    // NB! Since some MT5 build function SeriesInfoInteger(SERIES_SYNCHRONIZED) does not work properly anymore
    // and returns false always, so replaced with SymbolIsSynchronized
    // if(!SeriesInfoInteger(_Symbol, _Period, SERIES_SYNCHRONIZED))
    if(!SymbolIsSynchronized(_Symbol))
    {
      Print("Unsynchronized, skipping ticks...");
      return;
    }
    EventKillTimer();

    if(Reset) reset();
    
    if(Limit > 0)
    {
      fillArray();
      Print("Buffer filled in for ", symbolName);
    }
    
    Print( "3" );
    if(justCreated)
    {
      Print( "4" );
      long id = ChartOpen(symbolName, PERIOD_M1);
      Print( "5" );
      if(id == 0)
      {
        Alert("Can't open new chart for ", symbolName, ", code: ", GetLastError());
      }
      else
      {
        Sleep(1000);
        ChartSetSymbolPeriod(id, symbolName, PERIOD_M1);
        ChartSetInteger(id, CHART_MODE, CHART_CANDLES);
      }
      justCreated = false;
    }
    
    firstRun = false;
    lastTime = (datetime)((long)TimeCurrent() / 60 * 60);
    return;
  }
  
  if(LoopBack && Limit > 0)
  {
    shift();
    add();
  }
  else
  {
    lastTime += 60;
    add(lastTime);
  }
}

void OnDeinit(const int reason)
{
  Comment("");
  return;
}
