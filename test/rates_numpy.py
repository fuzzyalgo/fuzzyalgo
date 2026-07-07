# -*- coding: utf-8 -*-
"""
Created on Sat Feb 25 15:07:51 2023

@author: G6
"""

import numpy as np
from numpy.lib import recfunctions as rfn

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
gTdOffset= timedelta(hours=3)   # TODO recognise me - summer time 3h and winter time 2h
gTimeDelta = timedelta( minutes=240 )

#
# time of request
#
gYear = 2025

# guardian news paper headlines from 02.04.2025 displaying one day earlier 01.04.2025
# https://www.theguardian.com/theguardian/2025/apr/02
gMonth = 4
gDay = 1

# guardian news paper headlines from 03.04.2025 displaying one day earlier 02.04.2025
# https://www.theguardian.com/theguardian/2025/apr/03
# https://www.theguardian.com/politics/2025/apr/02/trump-hits-uk-with-10-tariffs-as-he-ignites-global-trade-war#top-of-blog
gMonth = 4
gDay = 2

# Trump liberation day 2025.04.03 put up trading tariffs
# https://www.theguardian.com/business/2025/apr/03/global-markets-turmoil-trump-tariffs-wall-street-downturn#top-of-blog
gMonth = 4
gDay = 3

# Trump liberation day 2025.04.04 follow on effects
# https://www.theguardian.com/us-news/live/2025/apr/04/us-business-stock-markets-nyse-blog-trump-tariffs-asian-markets#top-of-blog
gMonth = 4
gDay = 4

# Trump liberation day 2025.04.04 continues having effects
# https://www.theguardian.com/business/blog/live/2025/apr/07/global-stock-markets-brace-donald-trump-us-tariffs-business-live-updates-news#top-of-blog
# https://www.theguardian.com/commentisfree/2025/apr/07/donald-trump-world-economy-shock-us#top-of-blog
gMonth = 4
gDay = 7

# https://www.theguardian.com/business/live/2025/apr/08/stock-markets-nikkei-dow-ftse-100-asian-market-today-trump-china-tariffs-threat-business-news-live-latest-updates#top-of-blog
# https://www.theguardian.com/business/2025/apr/08/how-liberation-day-rout-compares-with-other-notorious-stock-market-crises#top-of-blog
gMonth = 4
gDay = 8

# https://www.theguardian.com/business/live/2025/apr/09/stock-share-markets-us-china-trade-trump-tariffs-business-news-live-updates#top-of-blog
# https://www.theguardian.com/us-news/2025/apr/09/trump-tariffs-pause-china#top-of-blog
gMonth = 4
gDay = 9

# https://www.theguardian.com/business/live/2025/apr/10/trump-tariffs-us-china-eu-trade-war-markets-latest-news-updates#top-of-blog
# https://www.theguardian.com/us-news/2025/apr/10/donald-trump-ignites-insider-trading-accusations-after-global-tariffs-u-turn#top-of-blog
# https://x.com/LJKawa/status/1910325059735998736
gMonth = 4
gDay = 10

# https://www.theguardian.com/business/live/2025/apr/11/donald-trump-tariffs-trade-war-us-china-markets-latest-news-updates#top-of-blog
gMonth = 4
gDay = 11

# https://www.theguardian.com/us-news/live/2025/apr/14/donald-trump-tariffs-china-smartphones-computers-semiconductors-immigration-us-politics-live-updates#top-of-blog
# https://www.theguardian.com/world/live/2025/apr/14/ukraine-russia-war-zelenskyy-trump-putin-europe-latest-live-news#top-of-blog
gMonth = 4
gDay = 14

# https://www.theguardian.com/theguardian/2025/apr/16
# https://www.theguardian.com/world/live/2025/apr/15/donald-trump-volodymyr-zelenskyy-vladimir-putin-ukraine-russia-europe-news-live-updates#top-of-blog
gMonth = 4
gDay = 15

# https://www.theguardian.com/politics/live/2025/apr/16/rachel-reeves-economy-trade-tariffs-china-labour-conservatives-lib-dems-reform-uk-politics-live#top-of-blog
# https://www.theguardian.com/business/live/2025/apr/16/asian-shares-gold-nvidia-stock-price-uk-inflation-slows-business-live#top-of-blog
gMonth = 4
gDay = 16

# https://www.theguardian.com/world/live/2025/apr/17/us-envoys-paris-meeting-ukraine-meloni-trump-europe-latest-updates-news#top-of-blog
gMonth = 4
gDay = 17

# https://www.theguardian.com/world/live/2025/apr/18/russia-ukraine-war-peace-talks-us-marco-rubio-zelenskyy-trump#top-of-blog
gMonth = 4
gDay = 18

# https://www.theguardian.com/world/live/2025/apr/21/pope-francis-dead-dies-catholic-church-latest-news-updates
# https://www.theguardian.com/business/2025/apr/21/us-stock-market-trump-fed-chair-jerome-powell
gMonth = 4
gDay = 21

# https://www.theguardian.com/business/live/2025/apr/22/us-dollar-yen-pound-gold-stock-markets-trump-attack-powell-imf-growth-forecast-business-live
gMonth = 4
gDay = 22


# https://www.theguardian.com/world/live/2025/may/07/new-pope-conclave-catholic-cardinals-papacy-vote-white-black-smoke-latest-live-news
gMonth = 5
gDay = 7


# https://www.theguardian.com/us-news/live/2025/may/08/donald-trump-trade-deal-us-politics-live-news-latest
# https://www.theguardian.com/world/live/2025/may/08/ve-day-80th-anniversary-victory-europe-uk-live-latest-news
# https://www.theguardian.com/world/live/2025/may/08/new-pope-conclave-vatican-white-black-smoke-papacy-catholic-cardinals
# pope got elected
# https://www.theguardian.com/world/live/2025/may/08/new-pope-conclave-vatican-white-black-smoke-papacy-catholic-cardinals#top-of-blog
gMonth = 5
gDay = 8

# https://www.theguardian.com/world/live/2025/may/09/pope-leo-xiv-to-hold-first-mass-pontiff-catholics-celebrate-live
# https://www.theguardian.com/world/live/2025/may/09/russia-victory-day-parade-putin-zelenskyy-ukraine-france-poland-latest-news-updates
# https://www.theguardian.com/politics/live/2025/may/09/us-uk-trade-deal-jobs-donald-trump-tariffs-keir-starmer-uk-politics-live
# https://www.theguardian.com/business/live/2025/may/09/bank-of-england-uk-europe-trade-brexit-us-china-stock-markets-business-live-news
gMonth = 5
gDay = 9


# https://www.theguardian.com/world/live/2025/may/12/russia-ukraine-war-zelenskyy-putin-trump-europe-live-latest-news
# https://www.theguardian.com/business/live/2025/may/12/us-china-trade-war-talks-stock-markets-oil-dollar-gold-business-live-news
# https://www.theguardian.com/us-news/live/2025/may/12/donald-trump-luxury-plane-us-china-trade-deal-tariff-latest-us-politics-news-live
# https://www.theguardian.com/politics/live/2025/may/12/immigration-keir-starmer-labour-reform-visa-foreign-workers-uk-politics-latest-live-news
# https://www.theguardian.com/world/live/2025/may/12/israel-gaza-hamas-edan-alexander-hostage-donald-trump-latest-live-news
gMonth = 5
gDay = 12


# guardian news paper headlines from 14.05.2025 displaying one day earlier 13.05.2025
# https://www.theguardian.com/theguardian/2025/may/14
gMonth = 5
gDay = 13


# https://www.theguardian.com/us-news/live/2025/may/14/donald-trump-syria-middle-east-gulf-latest-us-politics-news-updates-live
# https://www.theguardian.com/world/2025/may/14/israel-hits-gaza-hospitals-in-deadly-strikes-after-pause-to-allow-release-of-edan-alexander
# https://www.theguardian.com/politics/live/2025/may/14/keir-starmer-kemi-badenoch-pmqs-immigration-energy-assisted-dying-uk-politics-news-live-updates
# https://www.theguardian.com/world/live/2025/may/14/ukraine-russia-vladimir-putin-volodymyr-zelenskyy-peace-talks-turkey-latest-live-news-updates
gMonth = 5
gDay = 14


# https://www.theguardian.com/world/live/2025/may/19/europe-live-far-right-simion-concedes-as-centrist-wins-romanian-presidential-election
# https://www.theguardian.com/world/live/2025/may/19/poland-romania-portugal-election-results-latest-live-news-europe
# https://www.theguardian.com/world/live/2025/may/19/gaza-israel-aid-war-latest-live-news
# https://www.theguardian.com/us-news/live/2025/may/19/donald-trump-vladimir-putin-volodymyr-zelenskyy-ukraine-russia-us-politics-news-live
gMonth = 5
gDay = 19




# use live time
gDtTo   = datetime.now(gTimezoneUTC) + gTdOffset
# use historical time
gDtTo   = datetime(gYear, gMonth, gDay, 23, 55, 0, 0, tzinfo=gTimezoneUTC)
#ä caluculate gDtFrom from gDtTo as start of the day
gDtFrom = datetime(gDtTo.year, gDtTo.month, gDtTo.day, 0, 0, 0, 0, tzinfo=gTimezoneUTC)


#
# global(g) variables
#
gAccount = 'RF5D03'
print( "\nFrom: ", gDtFrom, " To: ", gDtTo )


#
# get ticks and rates
#
import algotrader as at
from algotrader._utils import _sprintf


# global handle to algotrader object
gH = at.Algotrader(gAccount)
gH.mt5_init()

# Define the number of decimal places for each field
digits = 5
digits_volume_real = 2

# Set NumPy print options to display floats with 'digits' decimal places
np.set_printoptions(precision=digits, floatmode='fixed', suppress=True)

# numpy rates dtypes
#      dtype=[('time', '<i8'), ('open', '<f8'), ('high', '<f8'), ('low', '<f8'), ('close', '<f8'), ('tick_volume', '<u8'), ('spread', '<i4'), ('real_volume', '<u8')])

# numpy tick dtypes
#      dtype=[('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')])


_start = time.time()
gNpaM1 = gH.mt5.copy_rates_range( gSym, gH.mt5.TIMEFRAME_M1, gDtFrom, gDtTo )
_deltams = int((time.time()-_start)*1000)
print( "\nM1 len(gNpaM1) ", len(gNpaM1), " deltams(gNpaM1): ", _deltams, "\n", gNpaM1 )

new_column_data = np.array((gNpaM1['time']*1000).astype('datetime64[ms]'), dtype='datetime64[ms]')

# Append the new column to gNpa
gNpaM1 = rfn.append_fields(gNpaM1, 'datetime64[ms]', new_column_data, usemask=False)

# Reorder the fields to make 'new_column' the first column
gNpaM1 = gNpaM1[['datetime64[ms]'] + [name for name in gNpaM1.dtype.names if name != 'datetime64[ms]']]


gNpaM1['time'] = np.array(gNpaM1['time']*1000)

# Define the output file path
output_file = "gNpa_M1_export.csv"

fmt = [
    f'%.{digits}f' if gNpaM1.dtype[name].kind == 'f' else '%s'
    for name in gNpaM1.dtype.names
]

# Save the NumPy array as a TAB-delimited CSV file with formatted floating-point numbers
np.savetxt(output_file, gNpaM1, delimiter="\t", fmt=fmt, header="\t".join(gNpaM1.dtype.names), comments='')


_start = time.time()
gNpa = gH.mt5.copy_ticks_range( gSym, gDtFrom, gDtTo , gH.mt5.COPY_TICKS_ALL)
_deltams = int((time.time()-_start)*1000)
print( "\nTICKS len(gNpa) ", len(gNpa), " deltams(gNpa): ", _deltams, "\n", gNpa )

# Example: Adding a new column 'new_column' of type datetime64[ms]
#new_column_data = np.array([np.datetime64('2025-03-30T00:00:00.000')] * len(gNpa), dtype='datetime64[ms]')
new_column_data = np.array(gNpa['time_msc'].astype('datetime64[ms]'), dtype='datetime64[ms]')

# Append the new column to gNpa
gNpa = rfn.append_fields(gNpa, 'datetime64[ms]', new_column_data, usemask=False)

# Reorder the fields to make 'new_column' the first column
gNpa = gNpa[['datetime64[ms]'] + [name for name in gNpa.dtype.names if name != 'datetime64[ms]']]

# Round the 'bid' and 'ask' fields to 'digits' decimal places
gNpa['bid'] = np.around(gNpa['bid'], decimals=digits)
gNpa['ask'] = np.around(gNpa['ask'], decimals=digits)

# Set NumPy print options to display floats with 'digits' decimal places
np.set_printoptions(precision=digits, floatmode='fixed', suppress=True)

# Print the updated array to verify the formatting
print("\nUpdated gNpa with 'bid' and 'ask' rounded to 5 decimal places:\n", gNpa)


# Define the output file path
output_file = "gNpa_Ticks_export.csv"

# Create a format string for each field in the dtype
fmt = [
    f'%.{digits}f' if name in ['bid', 'ask'] else
    f'%.{digits_volume_real}f' if name == 'volume_real' else
    '%s'
    for name in gNpa.dtype.names
]

# Save the NumPy array as a TAB-delimited CSV file with formatted floating-point numbers
np.savetxt(output_file, gNpa, delimiter="\t", fmt=fmt, header="\t".join(gNpa.dtype.names), comments='')

print(f"gNpa has been exported to {output_file}")

# Define the output binary file path
output_binary_file = "gNpa_export.npy"

# Repack the fields to fix the dtype layout
gNpa = rfn.repack_fields(gNpa)

# Save the NumPy array as a binary file
np.save(output_binary_file, gNpa)

print(f"gNpa has been exported as a binary file to {output_binary_file}")

# Load the binary file
gNpa_loaded = np.load(output_binary_file, allow_pickle=True)
print("Loaded gNpa from binary file:\n", gNpa_loaded)


# Define the output binary file path
output_binary_file = "gNpa_export.bin"

# Save the NumPy array as a binary file using tofile
gNpa.view(np.recarray).tofile(output_binary_file)

print(f"gNpa has been exported as a binary file to {output_binary_file}")

# Load the binary file
gNpa_loaded = np.fromfile(output_binary_file, dtype=gNpa.dtype)

print("Loaded gNpa from binary file:\n", gNpa_loaded)

