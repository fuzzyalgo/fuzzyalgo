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


#
# global(g) config/parameters variables
#
gTimezoneUTC = timezone.utc
gTdOffset= timedelta(hours=2)   # TODO recognise me - summer time 3h and winter time 2h

# normal operation
#gTicksPerPeriod = 1600  #  10hours * 36000secs/hours -> 36000 ticks per period
#gTimeDelta = timedelta( seconds=(gTicksPerPeriod*3/2) )   # TODO config var 10 hours -> related to 36000 (gTicksPerPeriod) elements for ticks array
#gDtTo   = datetime.now(gTimezoneUTC) + gTdOffset

# investigate a certain time
gTicksPerPeriod = 100  #  
gTimeDelta = timedelta( minutes=240 )
gDtTo   = datetime(2025, 1, 3, 17, 0, 1, 0, tzinfo=gTimezoneUTC)



#
# global(g) variables
#
gAccount = 'RF5D03'
gDtFrom = gDtTo - gTimeDelta
print( "\nFrom: ", gDtFrom, " To: ", gDtTo )
gDtTo_epoch_ms = int(gDtTo.timestamp()*1000)
print( "\ngDtTo.timestamp() ", gDtTo.timestamp(), " gDtTo_epoch_ms: ", gDtTo_epoch_ms)



#
# get ticks
#
import algotrader as at
from algotrader._utils import _sprintf


# global handle to algotrader object
gH = at.Algotrader(gAccount)
gH.mt5_init()


_start = time.time()
_npa = gH.mt5.copy_ticks_range( gSym, gDtFrom, gDtTo , gH.mt5.COPY_TICKS_ALL)
_deltams = int((time.time()-_start)*1000)


print( "\nlen(_npa) ", len(_npa), " deltams(_npa): ", _deltams, "\n", _npa )

# 3600 seconds per hour time 10 hours requested (gTicksPerPeriod)
# assuming there shall be at least one tick per hour
if -1 == gTicksPerPeriod:
    gTicksPerPeriod = len(_npa)
if gTicksPerPeriod > len(_npa):
    print( " try another time when there are more ticks ")
    

#
# data handling numpy and pandas
#
import numpy as np
import pandas as pd


#
# utilities
#
# https://stackoverflow.com/questions/30399534/shift-elements-in-a-numpy-array
#
def np_array_shift(xs, n):
    e = np.empty_like(xs)
    if n >= 0:
        #e[:n] = np.nan
        e[n:] = xs[:-n]
    else:
        #e[n:] = np.nan
        e[:n] = xs[-n:]
    return e



_start = time.time()

#_npa = _npa[0:gTicksPerPeriod]
_npa = _npa[(len(_npa)-gTicksPerPeriod):]
_npa = np.flip(_npa)

# #print( "\n _npa.dtype: ", _npa.dtype )
# # check for nan
# for n in _npa.dtype.names:
#     # print( "\t", n)
#     if np.isnan(np.sum(_npa[n])):
#         strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",gSym, n, str(_npa[n]))
#         raise( ValueError( strerror))


# _npa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')]

# https://numpy.org/doc/stable/reference/generated/numpy.dtype.html

#
# before
#
#  _npa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')]
 
dtype = _npa.dtype
_names = []
_formats = []
for n in _npa.dtype.names:
    _names.append(n)
    _formats.append(_npa.dtype[n])

# add price    
_names.append('price')
_formats.append(np.dtype(np.float64))  #  '<f8'
# add spread
_names.append('spread')
_formats.append(np.dtype(np.int64))   #  '<u4'
# add tdmsc
_names.append('tdmsc')
_formats.append(np.dtype(np.int64))   #  '<u4'
#
# TODO epoch to time string conversion takes too long
#
# # add np_time_msc
_names.append('np_time_msc')
# # # https://numpy.org/doc/stable/reference/generated/numpy.dtype.html
_formats.append(np.dtype('<S25')) 



#
# after
#
# _names:    ['time', 'bid', 'ask', 'last', 'volume', 'time_msc', 'flags', 'volume_real', 'price', 'spread', 'tdmsc']  
# _formats:  [dtype('int64'), dtype('float64'), dtype('float64'), dtype('float64'), dtype('uint64'), dtype('int64'), dtype('uint32'), dtype('float64'), dtype('float64'), dtype('uint32'), dtype('uint32')]
# 
#  gNpa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8'), ('price', '<f8'), ('spread', '<u4'), ('tdmsc', '<u4')]
 

dtype = np.dtype({'names':_names, 'formats':_formats})
# create empty gNpa array
gNpa = np.zeros(gTicksPerPeriod, dtype=dtype)

# copy _npa array into gNpa
for n in _npa.dtype.names:
    gNpa[n] = _npa[n]


gNpa['price']  = ( gNpa['ask'] + gNpa['bid'] ) / 2
gNpa['spread'] = ( gNpa['ask'] - gNpa['bid'] ) / 0.00001 
gNpa['tdmsc']  = ( gNpa['time_msc'] - np_array_shift(gNpa['time_msc'], -1) )
# TODO don't set to zero for fooling min() function 
# otherwise the index -1 will always be the minimum if set to zero
# also don't set to NaN - otherwise the NaN check does not work
gNpa['tdmsc'][-1] = 1000

#
# TODO epoch to time string conversion takes too long
#
# # https://numpy.org/doc/stable/reference/arrays.datetime.html
# # gNpa['np_time_msc']  = 'NaT'
gNpa['np_time_msc']  = _npa['time_msc'].astype('datetime64[ms]')
#gNpa['time']  = _npa['time_msc'].astype('datetime64[ms]')

# gDf  = pd.DataFrame(gNpa)
# gDf['time']=pd.to_datetime(gDf['time_msc'], unit='ms')
# gDf['price']  = round(( gDf.ask + gDf.bid ) / 2,       5 )
# gDf['spread'] = ( gDf.ask - gDf.bid ) / 0.00001 
# gDf['tdmsc']  = (gDf.time_msc - gDf.shift(-1).time_msc)



# print( "\n gNpa.dtype: ", gNpa.dtype )
# check for nan
for n in gNpa.dtype.names:
    # print( "\t", n)
    if 'np_time_msc' != n:
        if np.isnan(np.sum(gNpa[n])):
            strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",gSym, n, str(gNpa[n]))
            raise( ValueError( strerror))


# # https://pyopengl.sourceforge.net/pydoc/numpy.lib.recfunctions.html
# from numpy.lib import recfunctions as rfn

# # # create numpy array
# gNpa_f8 = np.zeros(gTicksPerPeriod, dtype='<f8')
# gNpa_u8 = np.zeros(gTicksPerPeriod, dtype='<u8')


# gNpa = rfn.append_fields(gNpa, 'price',  gNpa_f8, usemask = False )
# gNpa = rfn.append_fields(gNpa, 'spread', gNpa_u8, usemask = False )
# gNpa = rfn.append_fields(gNpa, 'tdmsc',  gNpa_u8, usemask = False )


# print( "\n gNpa.dtype: ", gNpa.dtype )
# # check for nan
# for n in gNpa.dtype.names:
#     print( "\t", n)
#     if np.isnan(np.sum(gNpa[n])):
#         strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",gSym, n, str(gNpa[n]))
#         raise( ValueError( strerror))


# gDf  = pd.DataFrame(gNpa)
# gDf['time']=pd.to_datetime(gDf['time_msc'], unit='ms')
# gDf['price']  = round(( gDf.ask + gDf.bid ) / 2,       5 )
# gDf['spread'] = ( gDf.ask - gDf.bid ) / 0.00001 
# gDf['tdmsc']  = (gDf.time_msc - gDf.shift(-1).time_msc)

# idxstart = gDf.index[0]
# idxend = gDf.index[-1]
# gDf.loc[idxend,'tdmsc'] = 0

# # TODO build WATCHER when has the last tick occured
gTimeLastTickMS = gDtTo_epoch_ms - gNpa['time_msc'][0]


_deltams = int((time.time()-_start)*1000)
print( "\nlen(gNpa) ", len(gNpa), " deltams(gNpa): ", _deltams, " gTimeLastTickMS: ", gTimeLastTickMS, "\n", gNpa )

#
# time
#
# https://numpy.org/doc/stable/reference/arrays.datetime.html
tnow = np.array(gDtTo_epoch_ms).astype('datetime64[ms]')
topen=gNpa['time_msc'][0].astype('datetime64[ms]')
tclose=gNpa['time_msc'][-1].astype('datetime64[ms]')
print()
print( gSym, "TIME ", gTimeLastTickMS, "ms" 
           "  t:", tnow, 
          "  t0:", topen,
          "  tn:", tclose,
          "  d_h:", round((gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000/3600, 1),
          "  d_m:", int((  gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000/60),
          "  d_s:", int((  gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000),
          "  d_ms:", int(   gNpa['time_msc'][0] - gNpa['time_msc'][-1])
          )

#
# price OC
#
oc = int( round( ( gNpa['price'][0] - gNpa['price'][-1] ) / 0.00001, 0 ) )
print( gSym, "PRICE  OC: ", oc, " open: ", gNpa['price'][0], "@", topen, " close: ", gNpa['price'][-1] , "@", tclose )


#
# price HL
#
idxmax=gNpa['price'].argmax(axis=0)
idxmin=gNpa['price'].argmin(axis=0)
thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
hl =  int( round( ( gNpa['price'][idxmax] - gNpa['price'][idxmin] ) / 0.00001, 0 ) )
print( gSym, "PRICE  HL: ", hl, " high: ", gNpa['price'][idxmax], "@", thigh, " low: ", gNpa['price'][idxmin] , "@", tlow )

#
# spread HL
#
idxmax=gNpa['spread'].argmax(axis=0)
idxmin=gNpa['spread'].argmin(axis=0)
spread_thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
spread_tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
spread_hl =  gNpa['spread'][idxmax] - gNpa['spread'][idxmin]
print( gSym, "SPREAD HL: ", spread_hl, " high: ", gNpa['spread'][idxmax], "@", spread_thigh, " low: ", gNpa['spread'][idxmin] , "@", spread_tlow )

#
# tdmsc HL
#
idxmax=gNpa['tdmsc'].argmax(axis=0)
idxmin=gNpa['tdmsc'].argmin(axis=0)
tdmsc_thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
tdmsc_tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
tdmsc_hl =  gNpa['tdmsc'][idxmax] - gNpa['tdmsc'][idxmin]
print( gSym, "TDMSC  HL: ", tdmsc_hl, " high: ", gNpa['tdmsc'][idxmax], "@", tdmsc_thigh, " low: ", gNpa['tdmsc'][idxmin] , "@", tdmsc_tlow )




lent = len(gNpa)
#gNpa = gNpa[0:lent]
gNpa = np.flip(gNpa)


gNpaPrice0 = gNpa['price'][0]
    
gNPAoffset = gNpaPrice0 * np.ones(len(gNpa))
gNpaRealTrack = (gNpa['price'] - gNPAoffset)/0.00001


#
# calc track (full)
#

myarray = gNpaRealTrack
# print( myarray )
# [   0.    1.   21.  -14.  -24.   -6.  -35.  -35.  -55. -105.]
myarray = np.round(myarray)
# print( myarray )
# [   0.    1.   21.  -14.  -24.   -6.  -35.  -35.  -55. -105.]
myarray = myarray.astype(int)
# print( myarray )
# [   0    1   21  -14  -24   -6  -35  -35  -55 -105]

pcmax = myarray.max() - myarray.min()
x = np.arange(lent)
y = myarray
pcm = 0
if 0 != pcmax:
    #pcm = (np.polyfit(x,y,1)[0] ) / lent
    pcm = round( (np.polyfit(x,y,1)[0] * lent) / pcmax, 1)
pcmreal = float("%.1f" % pcm)
pcmrealraw = np.polyfit(x,y,1)[0]
pcmaxreal = int(pcmax) #/gH.mt5.symbol_info (sym).point) 
myarraytrack = myarray

'''
gDtTo.strftime("%Y.%m.%d %H:%M:%S")
print( '\n', gAccount, sym, gPeriod, 50 * '-' )
for idx in range(0,lent,1):
    outstr = _sprintf("  %02d %9.3f %6d %6d ", idx, gNPA['close'][idx], myarraytrack[idx], myarraypred[idx] )
    print( outstr )
'''

outstr = _sprintf("\tpcm: %4.2f / %4.1f - pcmax: %3d", pcmrealraw, pcmreal, pcmaxreal )
print( outstr )





import matplotlib.pyplot as plt
gFontSize = 10
gLabelXstr        = "X"
gLabelYstr        = "Y"


tclose = gNpa['time_msc'][-1].astype('datetime64[ms]')
topen = gNpa['time_msc'][0].astype('datetime64[ms]')

fig = plt.figure()
gTitleStr = _sprintf("%s( %s - %s %s - %s  )",\
  gAccount, gTicksPerPeriod, gSym, tclose, topen )
fig.suptitle(gTitleStr, fontsize=gFontSize)

# if (33 + 10) < lencmp:
#     upper, mid, lower = talib.BBANDS(np.squeeze(gRealTrack[sym]), 
 	        #                       nbdevup=1, nbdevdn=1, timeperiod=33)
#     for cnt in range(0,33,1):
 	        #           mid[cnt] = 0
#     plt.plot(upper, label="Upper band", linewidth=0.3)
#     plt.plot(mid,   label='Middle band',linewidth=0.3)
#     plt.plot(lower, label='Lower band', linewidth=0.3)

t = np.arange(0, len(gNpa), 1)

plt.plot(t, gNpaRealTrack, label='price', color='r', linewidth=0.5)

# plt.plot(t, gNpa['price'], label='price', color='r', linewidth=0.1)
# plt.plot(t, gNpaPricePrediction1, label='prediction', color='b', linewidth=0.5)


plt.xlabel( "X", fontsize=gFontSize)
plt.ylabel( "Y", fontsize=gFontSize)
plt.legend()
plt.show()





