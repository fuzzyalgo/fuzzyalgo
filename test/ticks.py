# -*- coding: utf-8 -*-
"""
Created on Sat Feb 25 15:07:51 2023

@author: G6
"""

#
# globals
#
gSym = 'EURUSD'

#
# datetime
#

from datetime import timezone
from datetime import datetime
from datetime import timedelta
import time


gTimezoneUTC = timezone.utc
gTdOffset= timedelta(hours=2)   # TODO recognise me - summer time 3h and winter time 2h

gDtTo   = datetime.now(gTimezoneUTC) + gTdOffset
gDtTo   = datetime(2023, 2, 24, 10, 3, 18, 374863, tzinfo=gTimezoneUTC)

# TODO config var 10 hours -> related to 36000 elements for ticks array
gDtFrom = gDtTo - timedelta( hours=10 )


print( "\nFrom: ", gDtFrom, " To: ", gDtTo )

gDtTo_epoch_ms = int(gDtTo.timestamp()*1000)

print( "\ngDtTo.timestamp() ", gDtTo.timestamp(), " gDtTo_epoch_ms: ", gDtTo_epoch_ms)

#
# get ticks
#
import algotrader as at
from algotrader._utils import _sprintf


# global handle to algotrader object
gH = at.Algotrader('RF5D03')
gH.mt5_init()


_start = time.time()
gNpa = gH.mt5.copy_ticks_range( gSym, gDtFrom, gDtTo , gH.mt5.COPY_TICKS_ALL)
_deltams = int((time.time()-_start)*1000)


print( "\nlen(gNpa) ", len(gNpa), " deltams(gNpa): ", _deltams, "\n", gNpa )

# 3600 seconds per hour time 10 hours requested 
# assuming there shall be at least one tick per hour
# TODO config var 36000 ticks related to 10 hours

if 36000 > len(gNpa):
    print( " try another time when there are more ticks ")
    

#
# data handling numpy and pandas
#
import numpy as np
import pandas as pd

_start = time.time()

#gNpa = gNpa[0:36000]
gNpa = gNpa[(len(gNpa)-36000):]
gNpa = np.flip(gNpa)
gDf  = pd.DataFrame(gNpa)
gDf['time']=pd.to_datetime(gDf['time_msc'], unit='ms')
gDf['price']  = round(( gDf.ask + gDf.bid ) / 2,       5 )
gDf['spread'] = ( gDf.ask - gDf.bid ) / 0.00001 
gDf['tdmsc']  = (gDf.time_msc - gDf.shift(-1).time_msc)

idxstart = gDf.index[0]
idxend = gDf.index[-1]
gDf.loc[idxend,'tdmsc'] = 0


# TODO build WATCHER when has the last tick occured
gTimeLastTickMS = gDtTo_epoch_ms - gDf['time_msc'][0]

_deltams = int((time.time()-_start)*1000)
print( "\nlen(gNpa) ", len(gNpa), " deltams(gNpa): ", _deltams, " gTimeLastTickMS: ", gTimeLastTickMS, "\n", gNpa )
print()
print( gDf )
