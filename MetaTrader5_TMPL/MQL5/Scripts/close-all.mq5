//+------------------------------------------------------------------+
//|                                                    Close-All.mq5 |
//|                                        Copyright © 2018, Amr Ali |
//|                             https://www.mql5.com/en/users/amrali |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Amr Ali"
#property link      "https://www.mql5.com/en/users/amrali"
#property version   "9.100"
#property description "A script to close all market positions and/or pending orders."
#property script_show_inputs
//---
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayLong.mqh>
//---
CTrade         m_trade;      // trading object
CPositionInfo  m_position;   // position info object
COrderInfo     m_order;      // order info object
CArrayLong     m_arr_tickets;// array tickets
//---
enum ENUM_CLOSE_MODE
  {
   CLOSE_MODE_ALL,           // Positions and Pending Orders
   CLOSE_MODE_POSITIONS,     // Positions Only
   CLOSE_MODE_ORDERS         // Pending Orders
  };
enum ENUM_CLOSE_SYMBOL
  {
   CLOSE_SYMBOL_ALL,         // All Symbols
   CLOSE_SYMBOL_CHART        // Current Chart Symbol
  };
enum ENUM_CLOSE_PROFIT
  {
   CLOSE_PROFIT_ALL,         // All Winning and Losing Positions
   CLOSE_PROFIT_PROFITONLY,  // Winning Positions Only
   CLOSE_PROFIT_LOSSONLY     // Losing Positions Only
  };
//--- input parameters
input ENUM_CLOSE_MODE   InpCloseMode   = CLOSE_MODE_ALL;   // Type
input ENUM_CLOSE_SYMBOL InpCloseSymbol = CLOSE_SYMBOL_CHART; // Symbols
input ENUM_CLOSE_PROFIT InpCloseProfit = CLOSE_PROFIT_ALL; // Profit / Loss
input string            xx2;                               // ============
input uint              RTOTAL         = 5;                // Retries
input uint              SLEEPTIME      = 1000;             // Sleep Time (msec)
input bool              InpAsyncMode   = true;             // Asynchronous Mode
input bool              InpDisAlgo     = false;            // Disable AlgoTrading Button
//+------------------------------------------------------------------+
//| script start function                                            |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- preliminary checks for trading functions
   if(CheckTradingPermission()==false)
     {
      return;
     }
//--- initialize common information
   m_trade.SetDeviationInPoints(INT_MAX);
   m_trade.SetAsyncMode(InpAsyncMode);
   m_trade.SetMarginMode();
   m_trade.LogLevel(LOG_LEVEL_ERRORS);

//--- close positions and/or delete pending orders
   switch((ENUM_CLOSE_MODE)InpCloseMode)
     {
      case CLOSE_MODE_ALL:
         ClosePositions();
         DeletePendingOrders();
         break;

      case CLOSE_MODE_POSITIONS:
         ClosePositions();
         break;

      case CLOSE_MODE_ORDERS:
         DeletePendingOrders();
         break;
     }

//--- disable the 'algo-trading' button
   if(InpDisAlgo)
     {
      AlgoTradingStatus(false);
     }
  }
//+------------------------------------------------------------------+
//| Check for permission to perform automated trading                |
//+------------------------------------------------------------------+
bool CheckTradingPermission()
  {
   if(!MQLInfoInteger(MQL_TESTER))
     {
      //--- Terminal - internet connection
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
        {
         Alert("Error: No connection to the trade server!");
         return(false);
        }
      //--- Account - server connection
      if(!AccountInfoInteger(ACCOUNT_LOGIN))
        {
         Alert("Error: Trade information is not downloaded (not connected).");
         return(false);
        }
      //--- Terminal - Checking for permission to perform automated trading in the terminal
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
         Alert("Error: Automated trading is not allowed in the terminal settings, or 'Algo Trading' button is disabled.");
         return(false);
        }
      //--- Expert - Checking if trading is allowed for a certain running Expert Advisor/script
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         Alert("Error: Live trading is not allowed in the program properties of '", MQLInfoString(MQL_PROGRAM_NAME), "'");
         return(false);
        }
      //---
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
        {
         Alert("Error: Trading is not allowed for the account ", AccountInfoInteger(ACCOUNT_LOGIN), " [investor mode].");
         return(false);
        }
      //---
      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        {
         Alert("Error: Expert advisors are not allowed for the account ", AccountInfoInteger(ACCOUNT_LOGIN), " at the trade server.");
         return(false);
        }
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Close market positions                                           |
//+------------------------------------------------------------------+
void ClosePositions()
  {
//---
   for(uint retry=0; retry<RTOTAL && !IsStopped(); retry++)
     {
      bool result = true;
      //--- Collect and Close Method (FIFO-Compliant, for US brokers)
      //--- Tickets are processed starting with the oldest one.
      m_arr_tickets.Shutdown();
      for(int i=0; i<PositionsTotal() && !IsStopped(); i++)
        {
         ResetLastError();
         if(!m_position.SelectByIndex(i))
           {
            PrintFormat("> Error: selecting position with index #%d failed. Error Code: %d",i,GetLastError());
            result = false;
            continue;
           }
         if(InpCloseSymbol==CLOSE_SYMBOL_CHART && m_position.Symbol()!=Symbol())
           {
            continue;
           }
         if(InpCloseProfit==CLOSE_PROFIT_PROFITONLY && (m_position.Swap()+m_position.Profit()<=0))
           {
            continue;
           }
         if(InpCloseProfit==CLOSE_PROFIT_LOSSONLY && (m_position.Swap()+m_position.Profit()>=0))
           {
            continue;
           }
         //--- build array of position tickets to be processed
         if(!m_arr_tickets.Add(m_position.Ticket()))
           {
            PrintFormat("> Error: adding position ticket #%I64u failed.",m_position.Ticket());
            result = false;
           }
        }

      //--- now process the list of tickets stored in the array
      for(int i=0; i<m_arr_tickets.Total() && !IsStopped(); i++)
        {
         ResetLastError();
         ulong m_curr_ticket = m_arr_tickets.At(i);
         if(!m_position.SelectByTicket(m_curr_ticket))
           {
            PrintFormat("> Error: selecting position ticket #%I64u failed. Error Code: %d",m_curr_ticket,GetLastError());
            result = false;
            continue;
           }
         //--- check freeze level
         int freeze_level = (int)SymbolInfoInteger(m_position.Symbol(),SYMBOL_TRADE_FREEZE_LEVEL);
         double point = SymbolInfoDouble(m_position.Symbol(),SYMBOL_POINT);
         bool TP_check = (MathAbs(m_position.PriceCurrent() - m_position.TakeProfit()) > freeze_level * point);
         bool SL_check = (MathAbs(m_position.PriceCurrent() - m_position.StopLoss()) > freeze_level * point);
         if(!TP_check || !SL_check)
           {
            PrintFormat("> Error: closing position ticket #%I64u on %s is prohibited. Position TP or SL is too close to activation price.",m_position.Ticket(),m_position.Symbol());
            result = false;
            continue;
           }
         //--- trading object
         m_trade.SetExpertMagicNumber(m_position.Magic());
         m_trade.SetTypeFillingBySymbol(m_position.Symbol());
         //--- close positions
         if(m_trade.PositionClose(m_position.Ticket()) && (m_trade.ResultRetcode()==TRADE_RETCODE_DONE || m_trade.ResultRetcode()==TRADE_RETCODE_PLACED))
           {
            PrintFormat("Position ticket #%I64u on %s to be closed.",m_position.Ticket(),m_position.Symbol());
            PlaySound("expert.wav");
           }
         else
           {
            PrintFormat("> Error: closing position ticket #%I64u on %s failed. Retcode=%u (%s)",m_position.Ticket(),m_position.Symbol(),m_trade.ResultRetcode(),m_trade.ResultComment());
            result = false;
           }
        }

      if(result)
         break;
      Sleep(SLEEPTIME);
      PlaySound("timeout.wav");
     }
  }
//+------------------------------------------------------------------+
//| Delete pending orders                                            |
//+------------------------------------------------------------------+
void DeletePendingOrders()
  {
//---
   for(uint retry=0; retry<RTOTAL && !IsStopped(); retry++)
     {
      bool result = true;
      //--- Collect and Close Method (FIFO-Compliant, for US brokers)
      //--- Tickets are processed starting with the oldest one.
      m_arr_tickets.Shutdown();
      for(int i=0; i<OrdersTotal() && !IsStopped(); i++)
        {
         ResetLastError();
         if(!m_order.SelectByIndex(i))
           {
            PrintFormat("> Error: selecting order with index #%d failed. Error Code: %d",i,GetLastError());
            result = false;
            continue;
           }
         if(InpCloseSymbol==CLOSE_SYMBOL_CHART && m_position.Symbol()!=Symbol())
           {
            continue;
           }
         //--- build array of order tickets to be processed
         if(!m_arr_tickets.Add(m_order.Ticket()))
           {
            PrintFormat("> Error: adding order ticket #%I64u failed.",m_order.Ticket());
            result = false;
           }
        }

      //--- now process the list of tickets stored in the array
      for(int i=0; i<m_arr_tickets.Total() && !IsStopped(); i++)
        {
         ResetLastError();
         ulong m_curr_ticket = m_arr_tickets.At(i);
         if(!m_order.Select(m_curr_ticket))
           {
            PrintFormat("> Error: selecting order ticket #%I64u failed. Error Code: %d",m_curr_ticket,GetLastError());
            result = false;
            continue;
           }
         //--- check freeze level
         int freeze_level = (int)SymbolInfoInteger(m_order.Symbol(),SYMBOL_TRADE_FREEZE_LEVEL);
         double point = SymbolInfoDouble(m_order.Symbol(),SYMBOL_POINT);
         bool Activ_check = (MathAbs(m_order.PriceCurrent() - m_order.PriceOpen()) > freeze_level * point);
         if(!Activ_check)
           {
            PrintFormat("> Error: deleting order ticket #%I64u on %s is prohibited. Order open price is too close to activation price.",m_order.Ticket(),m_order.Symbol());
            result = false;
            continue;
           }
         //--- delete orders
         if(m_trade.OrderDelete(m_order.Ticket()) && (m_trade.ResultRetcode()==TRADE_RETCODE_DONE || m_trade.ResultRetcode()==TRADE_RETCODE_PLACED))
           {
            PrintFormat("Order ticket #%I64u on %s to be deleted.",m_order.Ticket(),m_order.Symbol());
            PlaySound("expert.wav");
           }
         else
           {
            PrintFormat("> Error: deleting order ticket #%I64u on %s failed. Retcode=%u (%s)",m_order.Ticket(),m_order.Symbol(),m_trade.ResultRetcode(),m_trade.ResultComment());
            result = false;
           }
        }

      if(result)
         break;
      Sleep(SLEEPTIME);
      PlaySound("timeout.wav");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define MT_WMCMD_EXPERTS   32851
#define WM_COMMAND 0x0111
#define GA_ROOT    2
//#include <WinAPI\winapi.mqh>
//+------------------------------------------------------------------+
//| Toggle auto-trading button                                       |
//+------------------------------------------------------------------+
void AlgoTradingStatus(bool Enable)
  {
   bool Status = (bool) TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);

   if(Enable != Status)
     {
      //HANDLE hChart = (HANDLE) ChartGetInteger(ChartID(), CHART_WINDOW_HANDLE);
      //PostMessageW(GetAncestor(hChart, GA_ROOT), WM_COMMAND, MT_WMCMD_EXPERTS, 0);
     }
  }
//+------------------------------------------------------------------+