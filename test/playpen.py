# -*- coding: utf-8 -*-
"""
Created on Mon Jan  6 14:08:18 2025

@author: G6

"""

# C:\code\fuzzyalgo>C:/apps/miniforge3/Scripts/activate
# (base) C:\code\fuzzyalgo>C:/apps/miniforge3/Scripts/activate fuzzyalgo-py39
# (base) C:\code\fuzzyalgo>C:/apps/miniforge3/envs/fuzzyalgo-py39/python.exe c:/code/fuzzyalgo/test/playpen.py


import time
_start = time.time()
_startPy = time.time()


import algotrader as at
from algotrader._utils import _sprintf
gAccount = 'RF5D03'
gVol = 0.1

from datetime import timezone
from datetime import datetime
from datetime import timedelta

_deltamsPy = int((time.time()-_startPy)*1000)


_startMt5 = time.time()


gH = at.Algotrader(gAccount)

# check if connection to MetaTrader 5 successful
if not gH.mt5_init():
    raise( "E: mt5_init failed") 


gDtTo   = None
if None == gDtTo:
    gDtTo = datetime.now(timezone.utc) + gH.tdOffset

## 2025-01-07_17:00:02
# gDtTo   = datetime(2025, 1, 7, 17, 0, 2, 0, tzinfo=timezone.utc)
# gH.g_c0['EURUSD'] = 1.03905

# # 2025-01-10_15:30:02
# gDtTo   = datetime(2025, 1, 10, 15, 30, 2, 0, tzinfo=timezone.utc)
# gH.g_c0['EURUSD'] = 1.03043

# # 2025-03-28 15:00:00+00:00
# gDtTo   = datetime(2025, 3, 28, 15, 0, 0, 0, tzinfo=timezone.utc)
# gH.g_c0['EURUSD'] = 1.07889

#gDtTo   = datetime(2025, 4, 3, 18, 0, 0, 0, tzinfo=timezone.utc)
#gH.g_c0['EURUSD'] = 1.10418


for sym in gH.cf_symbols[gH.gACCOUNT]: 
    if None == gH.g_c0[sym]:
        gH.set_gc0_price(sym)

# 
# START gH.run_now()
#

if None == gDtTo:
    gDtTo = datetime.now(timezone.utc) + gH.tdOffset

    
_deltamsMt5 = int((time.time()-_startMt5)*1000)


'''
gDtTo   = datetime(2025, 1, 7, 16, 59, 55, 0, tzinfo=timezone.utc)
gH.g_c0['EURUSD'] = 1.03905

gDtTo   = datetime(2025, 1, 10, 15, 30, 0, 0, tzinfo=timezone.utc)
gH.g_c0['EURUSD'] = 1.03043

gDtTo   = datetime(2025, 3, 7, 15, 29, 0, 0, tzinfo=timezone.utc)
gH.g_c0['EURUSD'] = 1.08543
'''


rangenumber = 1
timeoffsetInS = 0




for cnt in range( rangenumber ):

    #gDtTo   = datetime(2025, 3, 7, 15, 29, 0, 0, tzinfo=timezone.utc)
    #gH.g_c0['EURUSD'] = 1.08543
    ##gDtTo = datetime.now(timezone.utc) + gH.tdOffset
    tdoffset = timedelta(seconds=(cnt*timeoffsetInS))
    dt = gDtTo + tdoffset
    gH.get_date_range(dt)
    for sym in gH.cf_symbols[gH.gACCOUNT]: 
        print('SYMBOL',sym)
        _startTicks = time.time()
        gH.get_ticks_and_rates(sym)
        _deltamsTicks = int((time.time()-_startTicks)*1000)
        #gH.get_ticks_and_rates2(sym)
        
        _startAna = time.time()
        dfana = gH.analyse_df(sym)
        gH.print_analyse_df( dfana )
        outstr = _sprintf( "%5d %s %5d %5d %6.1f ", cnt, gH.gDt['dt_to'], dfana.DELTA.SUMROW, 
                                                                          (dfana.OC.SUMROW+dfana.PS.SUMROW)/2, 
                                                                          dfana.SUMCOL.SUMROW )
        print( outstr )
        # dfana[['DELTA','PS','OC','HL','TD','VOLS','TT','HL/TD','HL/VOLS','SUMCOL']]
        _deltamsAna = int((time.time()-_startAna)*1000)
        
        gH.mt5_position_sltp_follow2( sym )
        
        _startPlot = time.time()
        gH.print_fig_all_periods_per_sym_NEW( sym )
        #gH.print_fig_all_periods_per_sym( sym )
        _deltamsPlot = int((time.time()-_startPlot)*1000)


_deltams = int((time.time()-_start)*1000)
print( " deltams(ALL): ", _deltams, " deltams(PY): ", _deltamsPy, " deltams(MT5): ", _deltamsMt5, " deltams(TICKS): ", _deltamsTicks, " deltams(ANA): ", _deltamsAna, " deltams(PLOT): ", _deltamsPlot )


''' 
gSym = 'EURUSD'

op, dfbs = gH.mt5_cnt_orders_and_positions( gSym )
print( dfbs )

bs_threshold = 20

buy_or_sell = 'neutral'
if 1*bs_threshold < dfana.PS.SUMROW and 1*bs_threshold < dfana.OC.SUMROW:
    buy_or_sell = 'buy'

if -1*bs_threshold > dfana.PS.SUMROW and -1*bs_threshold > dfana.OC.SUMROW:
    buy_or_sell = 'sell'

if 'buy' == buy_or_sell:
    if 1 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        print(buy_or_sell, ' - do nothing')    
    elif 0 == dfbs.cnt.POS_BUY and 1 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_reverse( gSym )
        gH.mt5_pending_order_remove(gSym)
        gH.mt5_pending_order_sell_limit(\
            gSym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = gH.g_c0[gSym])
    elif 0 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_buy(gSym, gVol)
        gH.mt5_pending_order_remove(gSym)
        gH.mt5_pending_order_sell_limit(\
            gSym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = gH.g_c0[gSym])
    else:
        gH.set_gc0()
        gH.mt5_position_close(gSym)    
        gH.mt5_position_buy(gSym, gVol)
        gH.mt5_pending_order_remove(gSym)
        gH.mt5_pending_order_sell_limit(\
            gSym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = gH.g_c0[gSym])

elif 'sell' == buy_or_sell:
    if 0 == dfbs.cnt.POS_BUY and 1 == dfbs.cnt.POS_SELL:
        print(buy_or_sell, ' - do nothing')    
    elif 1 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_reverse( gSym )
        gH.mt5_pending_order_remove(gSym)
        gH.mt5_pending_order_buy_limit(\
            gSym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = gH.g_c0[gSym])
    elif 0 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
        gH.set_gc0()
        gH.mt5_position_sell(gSym, gVol)
        gH.mt5_pending_order_remove(gSym)
        gH.mt5_pending_order_buy_limit(\
            gSym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = gH.g_c0[gSym])
    else:
        gH.set_gc0()
        gH.mt5_position_close(gSym)    
        gH.mt5_position_sell(gSym, gVol)
        gH.mt5_pending_order_remove(gSym)
        gH.mt5_pending_order_buy_limit(\
            gSym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = gH.g_c0[gSym])

elif 'neutral' == buy_or_sell:
    print(buy_or_sell, ' - do nothing')    


gH.mt5_position_sltp_follow2( gSym )

#self.get_ticks_and_rates2(sym)

endticks = time.time()

# #gH.run_analyse_kalman(gDtTo, gSym )
gH.print_fig_all_periods_per_sym()
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
'''