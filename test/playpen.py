# -*- coding: utf-8 -*-
"""
Created on Mon Jan  6 14:08:18 2025

@author: G6
"""


import algotrader as at
from algotrader._utils import _sprintf
gAccount = 'RF5D03'
gSym = 'EURUSD'



from datetime import timezone
from datetime import datetime
from datetime import timedelta
import time




gH = at.Algotrader(gAccount)

# check if connection to MetaTrader 5 successful
if not gH.mt5_init():
    raise( "E: mt5_init failed") 


gDtTo   = datetime.now(timezone.utc) + gH.tdOffset
gDtTo   = None
if None == gDtTo:
    gDtTo = datetime.now(timezone.utc) + gH.tdOffset

# gDtTo   = datetime(2025, 1, 3, 17, 2, 50, 0, tzinfo=timezone.utc)

gH.g_c0[gSym] = 1.03900


# 
# START gH.run_now()
#

if None == gDtTo:
    gDtTo = datetime.now(timezone.utc) + gH.tdOffset

if None == gSym:
    gSym = gH.cf_symbols_default
    

start = time.time()

gH.get_date_range(gDtTo)
gH.get_ticks_and_rates(gSym)
ret = gH.analyse_df(gSym)
gH.print_analyse_df( ret )
#self.get_ticks_and_rates2(sym)

endticks = time.time()


gH.print_fig_all_periods_per_sym()
gH.print_fig_all_periods_and_all_syms()
gH.print_past_entries_per_sym()
#gH.print_fig_all_periods_and_one_sym_and_all_times()

    
#write_pickle_raw( 'file.pickle', gH.gDF )
#clear_ticks(  gDtTo )

end = time.time()
dt_to_str =   str(gDtTo.strftime("%Y%m%d_%H%M%S"))  
print( _sprintf("%s TOTAL TIME [%.2gs %.2gs %.2gs]\n", dt_to_str, (end-start), (endticks-start), (end-endticks)   ))

# 
# END gH.run_now()
#
