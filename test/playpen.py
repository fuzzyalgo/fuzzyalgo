# -*- coding: utf-8 -*-
"""
Created on Mon Jan  6 14:08:18 2025

@author: G6
"""


import algotrader as at
from algotrader._utils import _sprintf
gAccount = 'RF5D03'
gSym = 'EURUSD'
gVol = 0.01



from datetime import timezone
from datetime import datetime
from datetime import timedelta
import time




gH = at.Algotrader(gAccount)

# check if connection to MetaTrader 5 successful
if not gH.mt5_init():
    raise( "E: mt5_init failed") 


gDtTo   = None
if None == gDtTo:
    gDtTo = datetime.now(timezone.utc) + gH.tdOffset

## 2025-01-07_17:00:02
# gDtTo   = datetime(2025, 1, 7, 17, 0, 2, 0, tzinfo=timezone.utc)
# gH.g_c0[gSym] = 1.03905

# # 2025-01-10_15:30:02
# gDtTo   = datetime(2025, 1, 10, 15, 30, 2, 0, tzinfo=timezone.utc)
# gH.g_c0[gSym] = 1.03043


#gH.g_c0[gSym] = 1.02191

if None == gH.g_c0[gSym]:
    gH.set_gc0()

# 
# START gH.run_now()
#

if None == gDtTo:
    gDtTo = datetime.now(timezone.utc) + gH.tdOffset

if None == gSym:
    gSym = gH.cf_symbols_default
    

start = time.time()

gH.get_date_range(gDtTo)
print( gH.gDt)
gH.get_ticks_and_rates(gSym)
dfana = gH.analyse_df(gSym)
gH.print_analyse_df( dfana )

op, dfbs = gH.mt5_cnt_orders_and_positions( gSym )
print( dfbs )

buy_or_sell = 'neutral'
if 1 < dfana.PS.SUMROW and 1 < dfana.OC.SUMROW:
    buy_or_sell = 'buy'

if -1 > dfana.PS.SUMROW and -1 > dfana.OC.SUMROW:
    buy_or_sell = 'sell'

if 'buy' == buy_or_sell:
    if 1 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        print(buy_or_sell, ' - do nothing')    
    elif 0 == dfbs.cnt.POS_BUY and 1 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_reverse( gSym )
    elif 0 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_buy(gSym, gVol)
    else:
        gH.set_gc0()
        gH.mt5_position_close(gSym)    
        gH.mt5_position_buy(gSym, gVol)

elif 'sell' == buy_or_sell:
    if 0 == dfbs.cnt.POS_BUY and 1 == dfbs.cnt.POS_SELL:
        print(buy_or_sell, ' - do nothing')    
    elif 1 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_reverse( gSym )
    elif 0 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_sell(gSym, gVol)
    else:
        gH.set_gc0()
        gH.mt5_position_close(gSym)    
        gH.mt5_position_sell(gSym, gVol)

elif 'neutral' == buy_or_sell:
    print(buy_or_sell, ' - do nothing')    


gH.mt5_position_sltp_follow2( gSym, 20 )

#self.get_ticks_and_rates2(sym)

endticks = time.time()

# #gH.run_analyse_kalman(gDtTo, gSym )
# gH.print_fig_all_periods_per_sym()
# # #gH.print_fig_all_periods_and_all_syms()
# # # gH.print_past_entries_per_sym()
# # # #gH.print_fig_all_periods_and_one_sym_and_all_times()

    
#write_pickle_raw( 'file.pickle', gH.gDF )
#clear_ticks(  gDtTo )

end = time.time()
dt_to_str =   str(gDtTo.strftime("%Y%m%d_%H%M%S"))  
print( _sprintf("%s TOTAL TIME [%.2gs %.2gs %.2gs]\n", dt_to_str, (end-start), (endticks-start), (end-endticks)   ))

# 
# END gH.run_now()
#
