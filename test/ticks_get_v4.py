# -*- coding: utf-8 -*-
"""
Created on Sat Feb 25 15:07:51 2023

@author: G6
"""

#
# datetime
#
from datetime import timezone
from datetime import datetime
from datetime import timedelta
import time

#
# get ticks (MT5)
#
import os
import json
#import algotrader as at
from algotrader._utils import _sprintf

#
# data handling numpy and pandas
#
import numpy as np
import pandas as pd

#
# fuzzy stuff
#
import skfuzzy as fuzz


#
# graphics
#
import matplotlib.pyplot as plt


#
# globals
#
cAccount = 'RF5D03'
cSym = 'EURUSD'
#cSym = 'EURGBP'

# TODO make me optional, for example
gYear  = 2023
gMonth = 6
gDay   = 9
gDay   = 0   # -> get hist today live




gPeriodArray = [28800,14400,7200,3600,1800,900,450,225,120,60,30,15]
gPeriodArray = [      14400,7200,3600,1800,900,450,225,120,60,30,15]
gPeriodArray = [                 3600,1800,900,450,225,120,60,30,15]

gPeriodArray = [28800,14400,7200                                   ]
gPeriodArray = [                 3600,1800,900                     ]
gPeriodArray = [                               450,225,120         ]
gPeriodArray = [                                           60,30,15]

gPeriodArray = [28800,14400,7200,3600,1800,900,450,225,120,60,30,15]

gPeriodArray = [                 3600,1800,900                     ]
gPeriodArray = [                               450,225,120         ]
gPeriodArray = [7200,3600,1800,900,450,225,120,60,30,15]



gTimezoneUTC = timezone.utc
gTdOffset= timedelta(hours=3)   # TODO recognise me - summer time 3h and winter time 2h
gDtNow   = datetime.now(gTimezoneUTC) + gTdOffset

gNpa = None

gStrH =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 


'''
https://www.geeksforgeeks.org/python-design-patterns/
https://www.geeksforgeeks.org/polymorphism-in-python/
'''

#
# CONFIG
#
class Mt5Config(object):

    def __init__( self, _symbolsArray, _periodsArray ):
        # verbose
        self.gVerbose = 0
        # all symbols array
        self.gSymbolsAll = ['AUDCAD','AUDCHF','AUDJPY','AUDNZD','AUDUSD','CADCHF','CADJPY','CHFJPY','EURAUD','EURCAD','EURCHF','EURGBP','EURJPY','EURNZD','EURUSD','GBPAUD','GBPCAD','GBPCHF','GBPJPY','GBPNZD','GBPUSD','NZDCAD','NZDCHF','NZDJPY','NZDUSD','USDCAD','USDCHF','USDJPY']
        # all periods array
        self.gPeriodsAll = [
            [28800,14400,7200,3600,1800,900,450,225,120,60,30,15],
            [      14400,7200,3600,1800,900,450,225,120,60,30,15],
            [                 3600,1800,900,450,225,120,60,30,15],
            [28800,14400,7200                                   ],
            [                 3600,1800,900                     ],
            [                               450,225,120         ],
            [                                           60,30,15]
                        ]
        
        # initialise cf_config
        self.cf_config = {}
        self.cf_config['ARGS']    = {}
        self.cf_config['ACCOUNT'] = {}
        self.cf_config['SYMBOLS'] = {}
        
        if None != _periodsArray:
            self.cf_config['ARGS']['PERIODS'] = _periodsArray
        else:
            self.cf_config['ARGS']['PERIODS'] = self.gPeriodsAll
        
        if None != _symbolsArray:
            self.cf_config['ARGS']['SYMBOLS'] = _symbolsArray
        else:
            self.cf_config['ARGS']['SYMBOLS'] = self.gSymbolsAll
        


class Mt5LiveConfig(Mt5Config):

    def __init__( self, _account, _symbolsArray = None, _periodsArray = None ):
        super(Mt5LiveConfig, self ).__init__( _symbolsArray, _periodsArray )

        # TODO this shall be read from self.cf_accounts[_account]['path']  
        # but at this point the path for cf_accounts is unknown
        # hence hardcode it here - find a better way later
        _dir_appdata =  os.getenv('APPDATA') 
        _package_name = _sprintf("MetaTrader5_%s",_account)
        _path_mt5 = _dir_appdata +  "\\" + _package_name
        _path_mt5_user =  os.getenv('USERNAME') + '@' + os.getenv('COMPUTERNAME')

        # fn for created config json file _cf_fn
        _cf_fn = _path_mt5 + "\\config\\cf_" + _account + "_" + _path_mt5_user + ".json"

        # load symbol settings 
        _cf_sym_json_fn = _path_mt5 + "\\config\\cf_symbols_" + _path_mt5_user + ".json"
        with open(_cf_sym_json_fn, 'r') as f: _cf_sym = json.load(f)
        self.cf_config['SYMBOLS'] = _cf_sym
        
        # load account settings
        _cf_acc_json_fn = _path_mt5 + "\\config\\cf_accounts_" + _path_mt5_user + ".json"
        with open(_cf_acc_json_fn, 'r') as f: _cf_acc = json.load(f)
        _cf_acc[_account]['account_name']   =  _account
        _cf_acc[_account]['package_name']   =  _package_name
        _cf_acc[_account]['path']           =  _path_mt5 + "\\" + _cf_acc[_account]['terminal_fn']
        _cf_acc[_account]['path_acc_json']  =  _cf_acc_json_fn
        _cf_acc[_account]['path_sym_json']  =  _cf_sym_json_fn
        _cf_acc[_account]['path_cnf_json']  =  _cf_fn
        _cf_acc[_account]['path_base_name'] =  _path_mt5
        _cf_acc[_account]['path_hist_db']   =  _sprintf("%s\\MQL5\\data\\%s\\%s", _path_mt5, _path_mt5_user, _account )
        _cf_acc[_account]['path_dir_appdata'] =  _dir_appdata
        _cf_acc[_account]['user_name'] =  _path_mt5_user
        self.cf_config['ACCOUNT'] = _cf_acc[_account]

        # store created config json file _cf_fn
        with open( _cf_fn, 'w') as f: json.dump(self.cf_config, f, indent=3)        
        



class Mt5HistConfig(Mt5Config):

    def __init__( self, _account, _symbolsArray, _periodsArray, _path_sym_json_fn, _path_hist_db_dir ):
        super(Mt5LiveConfig, self ).__init__( _symbolsArray, _periodsArray   )
        
        _package_name  = _sprintf("MetaTrader5_%s",_account)
        _path_mt5_user = os.getenv('USERNAME') + '@' + os.getenv('COMPUTERNAME')
        
        # load symbol settings 
        _cf_sym_json_fn = _path_mt5 + "\\config\\cf_symbols_" + _path_mt5_user + ".json"
        with open(_cf_sym_json_fn, 'r') as f: _cf_sym = json.load(f)
        self.cf_config['SYMBOLS'] = _cf_sym
        
        _cf_acc['account_name']   =  _account
        _cf_acc['package_name']   =  _package_name
        _cf_acc['path_sym_json']  =  _path_sym_json_fn
        _cf_acc['path_hist_db']   =  _path_hist_db_dir
        _cf_acc['user_name']      =  _path_mt5_user
        self.cf_config['ACCOUNT'] = _cf_acc[_account]

#
# TIME
#

class RequestTime(object):

    def __init__( self, _termObj ):
        # verbose
        self.gVerbose = None
        
        # bases
        self.gTimezoneUTC = timezone.utc
        self.gTdOffset    = timedelta(hours=3)   # TODO recognise me - summer time 3h and winter time 2h
        self.gDtNow       = datetime.now(gTimezoneUTC) + self.gTdOffset

        #self.gYear        = 0
        #self.gMonth       = 0
        #self.gDay         = 0
        
        self.gDtFrom      = None
        self.gDtTo        = None
        
        self.gDtTo_epoch_ms = None
        
        # the minimum numbers of ticks to be retrieved
        self.hTERM = _termObj.hTERM
        self.hCNF  = _termObj.hCNF
        self.minimum_number_of_ticks_to_get = 0
        for _periodArray in self.hCNF.cf_config['ARGS']['PERIODS']:
            self.minimum_number_of_ticks_to_get = max( self.minimum_number_of_ticks_to_get, int((np.array(_periodArray).max()*2+2)) )
        """    
        print('self.minimum_number_of_ticks_to_get',self.minimum_number_of_ticks_to_get, _periodArray, self.hCNF.cf_config['ARGS']['PERIODS'])
        self.minimum_number_of_ticks_to_get 
            57602 
            [60, 30, 15] 
            [[28800, 14400, 7200, 3600, 1800, 900, 450, 225, 120, 60, 30, 15], [14400, 7200, 3600, 1800, 900, 450, 225, 120, 60, 30, 15], [3600, 1800, 900, 450, 225, 120, 60, 30, 15], [28800, 14400, 7200], [3600, 1800, 900], [450, 225, 120], [60, 30, 15]]
        """
        
    def verbose( self ):
        if None == self.gVerbose:
            raise( ValueError("gVerbose must be implemented into child class") )
        return self.gVerbose
        


class LiveTime(RequestTime):

    def __init__( self, _termObj ):
        super(LiveTime, self ).__init__( _termObj )
        
        self.gVerbose = 0

    
    # TODO find better names
    def update_day( self, _sym ):
    
        self.gDtNow         = datetime.now(gTimezoneUTC) + self.gTdOffset
        self.gDtTo          = self.gDtNow
        self.gDtFrom        = datetime( self.gDtTo.year, self.gDtTo.month, self.gDtTo.day, 1, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)
        return self.get_ticks( _sym, True )

    def update_ticks( self, _sym, _multi_factor = 1 ):
    
        self.gDtNow         = datetime.now(gTimezoneUTC) + self.gTdOffset
        self.gDtTo          = self.gDtNow
        _timeDelta          = timedelta( seconds=(self.minimum_number_of_ticks_to_get*3*_multi_factor) )   
        self.gDtFrom        = self.gDtTo - _timeDelta
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)
        return self.get_ticks( _sym, False  )

    # =============================================================================
    #  def get_ticks( self, _wholeDay = False ):
    #     
    # =============================================================================
    def get_ticks( self, _sym, _wholeDay = False ):
    # =============================================================================

        #
        # sanity check
        #
        weekDaysMapping = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        
        if ( 5 <= self.gDtTo.weekday() ) or ( 5 <= self.gDtFrom.weekday() ) :
            strerror = _sprintf("mt5_get_ticks _sym[%s] _npa len=0 - check request time from: [%s - %s] to: [%s - %s]",_sym, weekDaysMapping[self.gDtFrom.weekday()], self.gDtFrom, weekDaysMapping[self.gDtTo.weekday()], self.gDtTo )
            raise( ValueError( strerror))

        #if 0 < self.verbose(): 
        #    print( "\nFrom: ", weekDaysMapping[self.gDtFrom.weekday()], self.gDtFrom, " To: ", weekDaysMapping[self.gDtTo.weekday()], self.gDtTo )
        #    print( "\nself.gDtTo.timestamp() ", self.gDtTo.timestamp(), " self.gDtTo_epoch_ms: ", self.self.gDtTo_epoch_ms)


        #
        # get ticks
        #
        _start = time.time()
        _npa = self.hTERM.copy_ticks_range( _sym, self.gDtFrom, self.gDtTo , self.hTERM.COPY_TICKS_ALL)
        # In[933]: self.hTERM.last_error()
        # Out[933]: (1, 'Success')        
        if 1 != self.hTERM.last_error()[0]:
            strerror = _sprintf("mt5_get_ticks_01 _sym[%s] self.hTERM.copy_ticks_range error [%d][%s] ",_sym, self.hTERM.last_error()[0], self.hTERM.last_error()[1])
            raise( ValueError( strerror))

        if 0 == len(_npa):
            strerror = _sprintf("mt5_get_ticks_02 _sym[%s] _npa len=0 - check request time from: [%s] to: [%s] OR connection to internet",_sym, self.gDtFrom, self.gDtTo)
            raise( ValueError( strerror))

        if True == _wholeDay:
            if self.minimum_number_of_ticks_to_get > len(_npa):
                strerror = _sprintf("mt5_get_ticks_03 _sym[%s] _npa len=[%d] - try another time when there are more ticks self.minimum_number_of_ticks_to_get[%d] - check request time from: [%s] to: [%s]",_sym, len(_npa), self.minimum_number_of_ticks_to_get, self.gDtFrom, self.gDtTo)
                raise( ValueError( strerror))

        if False == _wholeDay:
            if self.minimum_number_of_ticks_to_get > len(_npa):
                # TODO optimise me like in WHILE routine in algorithm.py
                gTimeDelta = timedelta( hours=22 )
                self.gDtFrom = self.gDtTo - gTimeDelta
                _npa = self.hTERM.copy_ticks_range( _sym, self.gDtFrom, self.gDtTo , self.hTERM.COPY_TICKS_ALL)
                if 1 != self.hTERM.last_error()[0]:
                    strerror = _sprintf("mt5_get_ticks_04 _sym[%s] self.hTERM.copy_ticks_range error [%d][%s] ",_sym, self.hTERM.last_error()[0], self.hTERM.last_error()[1])
                    raise( ValueError( strerror))
                if (0 == len(_npa)) or self.minimum_number_of_ticks_to_get > len(_npa) :
                    strerror = _sprintf("mt5_get_ticks_05 _sym[%s] _npa len=[%d] - try another time when there are more ticks self.minimum_number_of_ticks_to_get[%d]  - check request time from: [%s] to: [%s] OR connection to internet",_sym, len(_npa), self.minimum_number_of_ticks_to_get, self.gDtFrom, self.gDtTo)
                    raise( ValueError( strerror))
            # TODO sort me out FLIP
            _npa = _npa[(len(_npa)-self.minimum_number_of_ticks_to_get):]
            #_npa = np.flip(_npa)

        # check for nan
        # _npa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')]
        for n in _npa.dtype.names:
            # print( "\t", n)  
            if np.isnan(np.sum(_npa[n])):
                strerror = _sprintf("mt5_get_ticks_05 _sym[%s] _npa len=[%d] - NAN ERROR within column[%s] %s with _npa.dtye: %s",_sym, len(_npa), n, str(_npa[n]), str(_npa.dtype))
                raise( ValueError( strerror))

        _deltams = int((time.time()-_start)*1000)
        self.gDeltaMs1 = _deltams
        if 0 < self.verbose(): 
            print( "\nlen(_npa) ", len(_npa), " deltams(_npa): ", _deltams, "\n", _npa )

        return _npa
            
    # END def get_ticks( self, _wholeDay = False ):
    # =============================================================================




class HistTime(RequestTime):

    def __init__( self, _termObj ):
        super(HistTime, self).__init__( _termObj )

    # TODO find better names
    def update_day( self, _year, _month, _day ):

        self.gDtTo          = datetime( _year, _month, _day, 23, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        self.gDtFrom        = datetime( _year, _month, _day,  1, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)

    def update_ticks( self, _year, _month, _day, _hour, _min, _sec, _multi_factor = 1 ):
    
        self.gDtTo          = datetime( _year, _month, _day,  _hour, _min, _sec, 0, tzinfo=self.gTimezoneUTC)
        _timeDelta          = timedelta( seconds=(self.minimum_number_of_ticks_to_get*3*_multi_factor) )   
        self.gDtFrom        = self.gDtTo - _timeDelta
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)

#
# Terminal 
#

class Mt5Terminal(object):
    
    def __init__( self ):
        self.gACCOUNT = None
        self.gVerbose = None
        print( "Terminal Init")

    def account( self ):
        if None == self.gACCOUNT:
            raise( ValueError("gACCOUNT must be implemented into child class") )
        return self.gACCOUNT

    def verbose( self ):
        if None == self.gVerbose:
            raise( ValueError("gVerbose must be implemented into child class") )
        return self.gVerbose

class MT5LiveTerminal(Mt5Terminal):

    def __init__(self, _configObj ):
        # https://stackoverflow.com/questions/17062889/why-are-parent-constructors-not-called-when-instantiating-a-class#:~:text=You%20need%20to%20invoke%20the%20base%20constructor%20in,can%20use%20this%20line%20as%20well%20print%20%27B%27
        # Mt5Terminal.__init__(self)
        super(MT5LiveTerminal, self).__init__() # you can use this line as well

        print( "MT5LiveTerminal Init")
        
        self.hCNF = _configObj
        self.gACCOUNT = self.hCNF.cf_config['ACCOUNT']['account_name']
        self.gVerbose = 0

        #  https://stackoverflow.com/questions/6677424/how-do-i-import-variable-packages-in-python-like-using-variable-variables-i
        # import MetaTrader5 as mt5
        _package_name = self.hCNF.cf_config['ACCOUNT']['package_name']
        self.hTERM = __import__(_package_name)
        
        self.term_init()

    # =============================================================================
    #  def term_init( self ):
    #     
    # =============================================================================
    def term_init( self ):
    # =============================================================================

        ret = False    
    
        # connect to MetaTrader 5
        self.hTERM.shutdown()
        ret = self.hTERM.initialize( \
                path     = self.hCNF.cf_config['ACCOUNT']['path'],\
                login    = self.hCNF.cf_config['ACCOUNT']['login'],\
                password = self.hCNF.cf_config['ACCOUNT']['password'],\
                server   = self.hCNF.cf_config['ACCOUNT']['server'],\
                portable = bool(self.hCNF.cf_config['ACCOUNT']['portable']) )
        
        if not ret:
            print("initialize() failed")
            print()
            self.hTERM.shutdown()
            raise ValueError( _sprintf("ERROR: Initialize [%s] ", self.hCNF.cf_config['ACCOUNT']['path']) )

        else:
            # request connection status and parameters
            # TODO check that AccountInfo and TerminalInfo are as requested
            # AccountInfo(login=67008870, trade_mode=0, leverage=500, limit_orders=500, margin_so_mode=0, trade_allowed=True, trade_expert=True, margin_mode=0, currency_digits=2, fifo_close=False, balance=264.23, credit=0.0, profit=0.0, equity=264.23, margin=0.0, margin_free=264.23, margin_level=0.0, margin_so_call=60.0, margin_so_so=40.0, margin_initial=0.0, margin_maintenance=0.0, assets=0.0, liabilities=0.0, commission_blocked=0.0, name='Andre Howe', server='RoboForex-ECN', currency='USD', company='RoboForex Ltd')
            # TerminalInfo(community_account=False, community_connection=False, connected=True, dlls_allowed=True, trade_allowed=True, tradeapi_disabled=False, email_enabled=False, ftp_enabled=False, notifications_enabled=False, mqid=False, build=2755, maxbars=100000, codepage=0, ping_last=42214, community_balance=0.0, retransmission=0.0, company='MetaQuotes Software Corp.', name='MetaTrader 5', language='English', path='C:\\OneDrive\\rfx\\mt\\I7\\RF5D01', data_path='C:\\OneDrive\\rfx\\mt\\I7\\RF5D01', commondata_path='C:\\Users\\Andre\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common')
            # (500, 2755, '15 Jan 2021')
            if 1 < self.verbose():            
                print(self.hTERM.account_info())
                print(self.hTERM.terminal_info())
                # get data on MetaTrader 5 version
                print(self.hTERM.version())
                print()

        # attempt to enable the display of the EURJPY symbol in MarketWatch
        for _sym in self.hCNF.cf_config['ARGS']['SYMBOLS']:
            selected=self.hTERM.symbol_select(_sym)
            if not selected:
                print("Failed to select: " + _sym)
                self.hTERM.shutdown()
                raise( ValueError(  _sprintf("Symbol could not be selected: %s",_sym ) ) )

        # display symbol properties
        for _sym in self.hCNF.cf_config['ARGS']['SYMBOLS']:
            symbol_info=self.hTERM.symbol_info(_sym)
            if None != symbol_info:
                self.hCNF.cf_config['SYMBOLS'][_sym]['points'] = symbol_info.point
                self.hCNF.cf_config['SYMBOLS'][_sym]['digits'] = symbol_info.digits
                #self.hCNF.cf_config['SYMBOLS'][_sym]['info']   = symbol_info
                #print(self.hCNF.cf_config['SYMBOLS'][_sym])
            else:
                raise( ValueError(  _sprintf("Symbol info could not be retrieved: %s",_sym ) ) )

        return ret        
            
    # END  def term_init( self ):
    # =============================================================================

    # =============================================================================
    #  def term_cnt_orders_and_positions( self, _symbol, gc0 = None ):
    #     
    #    example usage:
    #      mt5_orders, abc = self.hTERM.term_cnt_orders_and_positions(_sym)
    #      profitm = mt5_orders['order_pos_buy_profitm'] + mt5_orders['order_pos_sell_profitm']
    #      profit  = mt5_orders['order_pos_buy_profit']  + mt5_orders['order_pos_sell_profit']
    #
    #   cnt orders
    # =============================================================================
    def term_cnt_orders_and_positions( self, _symbol, gc0 = None ):
    # =============================================================================


        # mt5 settings    
        points = self.hTERM.symbol_info (_symbol).point
        digits = self.hTERM.symbol_info (_symbol).digits

        # gc0 params check
        ask      = self.hTERM.symbol_info_tick(_symbol).ask
        bid      = self.hTERM.symbol_info_tick(_symbol).bid
        time_msc = int(self.hTERM.symbol_info_tick(_symbol).time_msc)
        if None == gc0 :
            gc0 = round( ((ask + bid ) / 2), digits)
    
        # display data on active orders on GBPUSD 
        orders=self.hTERM.orders_get(symbol=_symbol) 
        if orders is None: 
            print("error code={}".format(self.hTERM.last_error())) 
            return None

        positions=self.hTERM.positions_get(symbol=_symbol)
        if positions is None: 
            print("error code={}".format(self.hTERM.last_error())) 
            return None
        
        total                 = len(orders) + len(positions)
        order_pend_buy        = 0
        order_pend_buy_vol    = 0
        order_pend_buy_price  = 0
        order_pend_buy_time_msc = 0
        order_pend_buy_ticket = 0
        order_pend_sell       = 0
        order_pend_sell_vol   = 0
        order_pend_sell_price = 0
        order_pend_sell_time_msc = 0
        order_pend_sell_ticket = 0
        order_pos_buy         = 0
        order_pos_buy_vol     = 0
        order_pos_buy_price0  = 0
        order_pos_buy_price_max   = 0
        order_pos_buy_price_min   = 1000000
        order_pos_buy_profit  = 0
        order_pos_buy_profitm = 0
        order_pos_buy_time    = 0
        order_pos_buy_ticket  = 0
        order_pos_buy_magic   = 0
        order_pos_buy_sl      = 0
        order_pos_buy_tp      = 0
        order_pos_sell        = 0
        order_pos_sell_vol    = 0
        order_pos_sell_price0 = 0
        order_pos_sell_price_max  = 0
        order_pos_sell_price_min  = 1000000
        order_pos_sell_profit = 0
        order_pos_sell_profitm = 0
        order_pos_sell_time   = 0
        order_pos_sell_ticket = 0
        order_pos_sell_magic  = 0
        order_pos_sell_sl     = 0
        order_pos_sell_tp     = 0

        for order in orders:
            if 1 < self.verbose(): print( order )
            if (self.hTERM.ORDER_TYPE_BUY_STOP   == order.type) or \
               (self.hTERM.ORDER_TYPE_BUY_LIMIT  == order.type):
                order_pend_buy       = order_pend_buy + 1
                order_pend_buy_vol   = order.volume_current
                order_pend_buy_price = round(order.price_open, digits)
                order_pend_buy_time_msc = order.time_setup_msc
                order_pend_buy_ticket = order.ticket
            
            if (self.hTERM.ORDER_TYPE_SELL_STOP  == order.type) or \
               (self.hTERM.ORDER_TYPE_SELL_LIMIT == order.type): 
                order_pend_sell       = order_pend_sell + 1
                order_pend_sell_vol   = order.volume_current
                order_pend_sell_price = round( order.price_open, digits )
                order_pend_sell_time_msc = order.time_setup_msc
                order_pend_sell_ticket = order.ticket

        for position in positions:
            if 1 < self.verbose(): print( position )
            if (self.hTERM.ORDER_TYPE_BUY == position.type):
                order_pos_buy         = order_pos_buy + 1
                order_pos_buy_vol     = round( order_pos_buy_vol + position.volume, 2 )
                #order_pos_buy_price0  = round( position.price_current, digits )
                order_pos_buy_price0  = round( position.price_open, digits )
                po = round( position.price_open, digits )
                if order_pos_buy_price_max < po:
                    order_pos_buy_price_max = po
                if order_pos_buy_price_min > po:
                    order_pos_buy_price_min = po
                order_pos_buy_profit  = order_pos_buy_profit + (position.price_current-position.price_open)/points
                order_pos_buy_profitm = round( order_pos_buy_profitm + position.profit, 2)
                order_pos_buy_time    = position.time
                order_pos_buy_ticket  = position.ticket
                order_pos_buy_magic   = position.magic
                order_pos_buy_sl      = round( position.sl, digits )
                order_pos_buy_tp      = round( position.tp, digits )
                
                '''
                # TradePosition(ticket=189164460, time=1611745214, time_msc=1611745214598, 
                time_update=1611745214, time_update_msc=1611745214598, 
                type=1, magic=456, identifier=189164460, reason=3, 
                volume=0.01, price_open=142.506, sl=0.0, tp=0.0, price_current=142.513, 
                swap=0.0, profit=-0.07, symbol='GBPJPY', comment='BPO', external_id='')
    
                sell signal:  {'total': 1, 'order_pend_buy': 0, 'order_pend_buy_vol': 0.0, 'order_pend_buy_price': 0.0, 
                               'order_pend_sell': 0, 'order_pend_sell_vol': 0.0, 'order_pend_sell_price': 0.0, 
                               
                               'order_pos_buy': 0, 'order_pos_buy_vol': 0.0, 'order_pos_buy_price_max': 0.0,
                               'order_pos_buy_time': 0, 'order_pos_buy_ticket': 0, 'order_pos_buy_magic': 0,
                               'order_pos_buy_price_min': 0.0, 'order_pos_sell': 1, 'order_pos_sell_vol': 0.01, 
                               
                               'order_pos_sell_price_min': 1.5718, 'order_pos_sell_time': 1636628351,
                               'order_pos_sell_ticket': 218451402, 'order_pos_sell_magic': 0, 
                               'order_pos_sell_price_max': 1.5717}
                               
                sell signal:  {'total': 165, 'order_pend_buy': 0, 'order_pend_buy_vol': 0.0, 'order_pend_buy_price': 0.0, 
                               'order_pend_sell': 0, 'order_pend_sell_vol': 0.0, 'order_pend_sell_price': 0.0, 
                               
                               'order_pos_buy': 79, 'order_pos_buy_vol': 0.79, 'order_pos_buy_price_min': 1.12867, 'order_pos_buy_price_max': 1.13053, 'order_pos_buy_profit': -9034, 
                               'order_pos_buy_time': 1637326106, 'order_pos_buy_ticket': 219587856, 'order_pos_buy_magic': 0, 'order_pos_buy_sl': 0, 'order_pos_buy_tp': 0, 
                               
                               'order_pos_sell': 86, 'order_pos_sell_vol': 0.86, 'order_pos_sell_price_max': 1.1302, 'order_pos_sell_price_min': 1.12841, 'order_pos_sell_profit': 6021, 
                               'order_pos_sell_time': 1637325963, 'order_pos_sell_ticket': 219587619, 'order_pos_sell_magic': 0, 'order_pos_sell_sl': 0, 'order_pos_sell_tp': 0}
    
                '''

            if (self.hTERM.ORDER_TYPE_SELL == position.type):
                order_pos_sell        = order_pos_sell + 1
                order_pos_sell_vol    = round( order_pos_sell_vol + position.volume, 2)
                #order_pos_sell_price0 = round( position.price_current, digits )
                order_pos_sell_price0 = round( position.price_open, digits )
                po = round( position.price_open, digits )
                if order_pos_sell_price_max < po:
                    order_pos_sell_price_max = po
                if order_pos_sell_price_min > po:
                    order_pos_sell_price_min = po
                order_pos_sell_profit = order_pos_sell_profit + (position.price_open-position.price_current)/points
                order_pos_sell_profitm = round( order_pos_sell_profitm + position.profit, 2 )
                order_pos_sell_time   = position.time
                order_pos_sell_ticket = position.ticket
                order_pos_sell_magic  = position.magic
                order_pos_sell_sl      = round( position.sl, digits )
                order_pos_sell_tp      = round( position.tp, digits )

        if total != ( order_pend_buy + order_pend_sell + order_pos_buy + order_pos_sell ) :
            # TODO raise ERROR here
            print( ' XXX ERROR cnt orders ' ) 
            
        retdict = dict( \
                total                 = int(  total), \
                order_pend_buy        = int(  order_pend_buy), \
                order_pend_buy_vol    = float(order_pend_buy_vol), \
                order_pend_buy_price  = float(order_pend_buy_price), \
                order_pend_buy_time_msc  = int(order_pend_buy_time_msc), \
                order_pend_buy_ticket  = int(order_pend_buy_ticket), \
                order_pend_sell       = int(  order_pend_sell), \
                order_pend_sell_vol   = float(order_pend_sell_vol), \
                order_pend_sell_price = float(order_pend_sell_price), \
                order_pend_sell_time_msc = int(order_pend_sell_time_msc), \
                order_pend_sell_ticket  = int(order_pend_sell_ticket), \
                order_pos_buy         = int(  order_pos_buy), \
                order_pos_buy_vol     = float(order_pos_buy_vol), \
                order_pos_buy_price0  = float(order_pos_buy_price0),\
                order_pos_buy_price_min = float(order_pos_buy_price_min),\
                order_pos_buy_price_max = float(order_pos_buy_price_max), \
                order_pos_buy_profit  = int(order_pos_buy_profit),\
                order_pos_buy_profitm = float(order_pos_buy_profitm),\
                order_pos_buy_time    = int(order_pos_buy_time),\
                order_pos_buy_ticket  = int(order_pos_buy_ticket),\
                order_pos_buy_magic   = int(order_pos_buy_magic),\
                order_pos_buy_sl      = int(order_pos_buy_sl),\
                order_pos_buy_tp      = int(order_pos_buy_tp),\
                order_pos_sell        = int(  order_pos_sell), \
                order_pos_sell_vol    = float(order_pos_sell_vol), \
                order_pos_sell_price0 = float(order_pos_sell_price0), \
                order_pos_sell_price_min  = float(order_pos_sell_price_min), \
                order_pos_sell_price_max  = float(order_pos_sell_price_max),\
                order_pos_sell_profit = int(order_pos_sell_profit),\
                order_pos_sell_profitm = float(order_pos_sell_profitm),\
                order_pos_sell_time   = int(order_pos_sell_time),\
                order_pos_sell_ticket = int(order_pos_sell_ticket),\
                order_pos_sell_magic  = int(order_pos_sell_magic),\
                order_pos_sell_sl     = int(order_pos_sell_sl),\
                order_pos_sell_tp     = int(order_pos_sell_tp),\
             )
         
        
        # create numpy array
        #key_list = list(['POS_BUY_TP','POS_BUY_SL','POS_BUY','PEND_BUY','c0','PEND_SELL','POS_SELL','POS_SELL_SL','POS_SELL_TP'] )
        key_list = list( ['POS_BUY','PEND_BUY','c0','PEND_SELL','POS_SELL'] )
        key_list_len = len( key_list )
        dtype = np.dtype([('cnt', '<i8'), ('profit', '<i8'), ('sl', '<i8'), ('tp', '<i8'), ('delta', '<i8'), ('price', '<i8'),\
                          ('time', '<i8'),('ticket', '<i8') ])

        dtype = np.dtype([('cnt', '<i8'), ('profit', '<i8'), ('delta', '<i8'), ('price', '<i8'),\
                          ('time', '<i8'),('ticket', '<i8') ])
        
        npa = np.zeros(key_list_len, dtype=dtype)
        df =  pd.DataFrame(npa, index=key_list)
        
            
        #df['SUMCOL'] = 0
        #df.loc['SUMROW']  = 0

        if 0 < retdict['order_pos_buy']:
            df.loc['POS_BUY', 'cnt']    = retdict['order_pos_buy']
            df.loc['POS_BUY', 'profit'] = retdict['order_pos_buy_profit']
            if 0.0 < retdict['order_pos_buy_sl']:
                df.loc['POS_BUY', 'sl']     = int( ( retdict['order_pos_buy_sl'] - retdict['order_pos_buy_price0'] ) / points )
            if 0.0 < retdict['order_pos_buy_tp']:
                df.loc['POS_BUY', 'tp']     = int( ( retdict['order_pos_buy_tp'] - retdict['order_pos_buy_price0'] ) / points )
            df.loc['POS_BUY', 'delta']  = int( ( retdict['order_pos_buy_price0'] - gc0 ) / points )
            df.loc['POS_BUY', 'price']  = retdict['order_pos_buy_price0']
            df.loc['POS_BUY', 'time']   = retdict['order_pos_buy_time']*1000
            df.loc['POS_BUY', 'ticket'] = retdict['order_pos_buy_ticket']
        
        if 0 < retdict['order_pend_buy']:
            df.loc['PEND_BUY', 'cnt']    = retdict['order_pend_buy']
            df.loc['PEND_BUY', 'delta']  = int( ( retdict['order_pend_buy_price'] - gc0 ) / points )
            df.loc['PEND_BUY', 'price']  = retdict['order_pend_buy_price']
            df.loc['PEND_BUY', 'time']   = retdict['order_pend_buy_time_msc']*1000
            df.loc['PEND_BUY', 'ticket'] = retdict['order_pend_buy_ticket']

        cnt = 0
        delta = 0
        price = 0
        if 0.0 < ask and 0.0 < bid :
            cnt = 1
            price    = round( (bid + (ask - bid ) / 2), digits )
            delta    = int(( price - gc0 ) / points )
        df.loc['c0', 'cnt']    = cnt
        df.loc['c0', 'delta']  = delta
        df.loc['c0', 'price']  = price
        df.loc['c0', 'time']   = time_msc
        
        if 0 < retdict['order_pend_sell']:
            df.loc['PEND_SELL','cnt']    = retdict['order_pend_sell']
            df.loc['PEND_SELL','delta']  = int(( retdict['order_pend_sell_price'] - gc0 ) / points )
            df.loc['PEND_SELL','price']  = retdict['order_pend_sell_price']
            df.loc['PEND_SELL','time']   = retdict['order_pend_sell_time_msc']*1000
            df.loc['PEND_SELL','ticket'] = retdict['order_pend_sell_ticket']

        if 0 < retdict['order_pos_sell']:
            df.loc['POS_SELL', 'cnt']    = retdict['order_pos_sell']
            df.loc['POS_SELL', 'profit'] = retdict['order_pos_sell_profit']
            if 0.0 < retdict['order_pos_sell_sl']:
                df.loc['POS_SELL', 'sl']     = int( ( retdict['order_pos_sell_sl'] - retdict['order_pos_sell_price0'] ) / points )
            if 0.0 < retdict['order_pos_sell_tp']:
                df.loc['POS_SELL', 'tp']     = int( ( retdict['order_pos_sell_tp'] - retdict['order_pos_sell_price0'] ) / points )
            df.loc['POS_SELL', 'delta']  = int( ( retdict['order_pos_sell_price0'] - gc0 ) / points )
            df.loc['POS_SELL', 'price']  = retdict['order_pos_sell_price0']
            df.loc['POS_SELL', 'time']   = retdict['order_pos_sell_time']*1000
            df.loc['POS_SELL', 'ticket'] = retdict['order_pos_sell_ticket']

        #df.insert(0,"DTMS",pd.to_datetime(df['time'], unit='ms'))
        df['time'] = pd.to_datetime(df['time'], unit='ms')
        
        
        # self.set_df('DB',_symbol,df)    
        print( df )
        
        return retdict, df
        
        # at0.term_cnt_orders_and_positions( 'GBPJPY' )
        # TradePosition(ticket=189164460, time=1611745214, time_msc=1611745214598, time_update=1611745214, time_update_msc=1611745214598, type=1, magic=456, identifier=189164460, reason=3, volume=0.01, price_open=142.506, sl=0.0, tp=0.0, price_current=142.513, swap=0.0, profit=-0.07, symbol='GBPJPY', comment='BPO', external_id='')
        # Out[3]: 
        # {'total': 1,
        #  'order_pend_buy': 0,
        #  'order_pend_sell': 0,
        #  'order_pos_buy': 0,
        #  'order_pos_sell': 1}

        # at0.term_cnt_orders_and_positions( 'GBPJPY' )
        # TradeOrder(ticket=189164951, time_setup=1611745564, time_setup_msc=1611745564529, time_done=0, time_done_msc=0, time_expiration=1611705600, type=4, type_time=1, type_filling=2, state=1, magic=123, position_id=0, position_by_id=0, reason=3, volume_initial=0.01, volume_current=0.01, price_open=142.491, sl=0.0, tp=0.0, price_current=142.484, price_stoplimit=0.0, symbol='GBPJPY', comment='BPO', external_id='')
        # TradeOrder(ticket=189164952, time_setup=1611745564, time_setup_msc=1611745564570, time_done=0, time_done_msc=0, time_expiration=1611705600, type=5, type_time=1, type_filling=2, state=1, magic=456, position_id=0, position_by_id=0, reason=3, volume_initial=0.01, volume_current=0.01, price_open=142.471, sl=0.0, tp=0.0, price_current=142.475, price_stoplimit=0.0, symbol='GBPJPY', comment='BPO', external_id='')
        # Out[6]: 
        # {'total': 2,
        #  'order_pend_buy': 1,
        #  'order_pend_sell': 1,
        #  'order_pos_buy': 0,
        #  'order_pos_sell': 0}
            
        # at0.term_cnt_orders_and_positions( 'GBPJPY' )
        # TradeOrder(ticket=189164951, time_setup=1611745564, time_setup_msc=1611745564529, time_done=0, time_done_msc=0, time_expiration=1611705600, type=4, type_time=1, type_filling=2, state=1, magic=123, position_id=0, position_by_id=0, reason=3, volume_initial=0.01, volume_current=0.01, price_open=142.491, sl=0.0, tp=0.0, price_current=142.471, price_stoplimit=0.0, symbol='GBPJPY', comment='BPO', external_id='')
        # TradePosition(ticket=189164952, time=1611745581, time_msc=1611745581123, time_update=1611745581, time_update_msc=1611745581123, type=1, magic=456, identifier=189164952, reason=3, volume=0.01, price_open=142.469, sl=0.0, tp=0.0, price_current=142.471, swap=0.0, profit=-0.02, symbol='GBPJPY', comment='BPO', external_id='')
        # Out[7]: 
        # {'total': 2,
        #  'order_pend_buy': 1,
        #  'order_pend_sell': 0,
        #  'order_pos_buy': 0,
        #  'order_pos_sell': 1}

    #  def term_cnt_orders_and_positions( self, _symbol, gc0 = None ):
    # =============================================================================


class Terminal(object):
    
    def __init__( self ):
        self.gACCOUNT = None
        self.gVerbose = None
        self.gSymbol  = None
        self.gDigits  = None
        self.gPoint   = None
        print( "Terminal Init")

    def account( self ):
        if None == self.gACCOUNT:
            raise( ValueError("gACCOUNT must be implemented into child class") )
        return self.gACCOUNT

    def verbose( self ):
        if None == self.gVerbose:
            raise( ValueError("gVerbose must be implemented into child class") )
        return self.gVerbose

    def symbol( self ):
        if None == self.gSymbol:
            raise( ValueError("gSymbol must be implemented into child class") )
        return self.gSymbol

    def digits( self ):
        if None == self.gDigits:
            raise( ValueError("gDigits must be implemented into child class") )
        return self.gDigits

    def point( self ):
        if None == self.gPoint:
            raise( ValueError("gPoint must be implemented into child class") )
        return self.gPoint


class MT5(Terminal):

    def __init__(self, account = None, symbol = None ):
        # https://stackoverflow.com/questions/17062889/why-are-parent-constructors-not-called-when-instantiating-a-class#:~:text=You%20need%20to%20invoke%20the%20base%20constructor%20in,can%20use%20this%20line%20as%20well%20print%20%27B%27
        # Terminal.__init__(self)
        super(MT5, self).__init__() # you can use this line as well

        print( "MT5 Init")

        self.gVerbose = 0
        
        if None == account:
            self.gACCOUNT = 'RF5D03'
        else:
            self.gACCOUNT = account

        if None == symbol:
            self.gSymbol = 'EURUSD'
        else:
            self.gSymbol = symbol
            
        # TODO this shall be read from self.cf_accounts[self.gACCOUNT]['path']  
        # but at this point the path for cf_accounts is unknown
        # hence hardcode it here - find a better way later
        _dir_appdata =  os.getenv('APPDATA') 
        _package_name = _sprintf("MetaTrader5_%s",self.gACCOUNT)
        _path_mt5 = _dir_appdata +  "\\" + _package_name
        _path_mt5_user =  os.getenv('USERNAME') + '@' + os.getenv('COMPUTERNAME')

        # initialise ACCOUNTS config cf_accounts
        # KsACCOUNTS = ['RF5D01','RF5D02']
        self.cf_config = {}
        self.cf_config['ARGS'] = {}
        self.cf_config['ACCOUNT'] = {}
        self.cf_config['SYMBOLS'] = {}

        # fn for created config json file _cf_fn
        _cf_fn = _path_mt5 + "\\config\\cf_" + self.gACCOUNT + "_" + _path_mt5_user + ".json"

        # load symbol settings 
        _cf_sym_json_fn = _path_mt5 + "\\config\\cf_symbols_" + _path_mt5_user + ".json"
        with open(_cf_sym_json_fn, 'r') as f: _cf_sym = json.load(f)
        
        # load account settings
        _cf_acc_json_fn = _path_mt5 + "\\config\\cf_accounts_" + _path_mt5_user + ".json"
        with open(_cf_acc_json_fn, 'r') as f: _cf_acc = json.load(f)
        _cf_acc[self.gACCOUNT]['account_name']   =  self.gACCOUNT
        _cf_acc[self.gACCOUNT]['package_name']   =  _package_name
        _cf_acc[self.gACCOUNT]['path']           =  _path_mt5 + "\\" + _cf_acc[self.gACCOUNT]['terminal_fn']
        _cf_acc[self.gACCOUNT]['path_acc_json']  =  _cf_acc_json_fn
        _cf_acc[self.gACCOUNT]['path_sym_json']  =  _cf_sym_json_fn
        _cf_acc[self.gACCOUNT]['path_cnf_json']  =  _cf_fn
        _cf_acc[self.gACCOUNT]['path_base_name'] =  _path_mt5
        _cf_acc[self.gACCOUNT]['path_hist_db']   =  _sprintf("%s\\MQL5\\data\\%s\\%s", _path_mt5, _path_mt5_user, self.gACCOUNT )
        _cf_acc[self.gACCOUNT]['path_dir_appdata'] =  _dir_appdata
        _cf_acc[self.gACCOUNT]['user_name'] =  _path_mt5_user

        # store created config json file _cf_fn
        self.cf_config['ARGS']['PERIODS'] = gPeriodArray
        self.cf_config['ARGS']['SYMBOLS'] = [ cSym ]
        self.cf_config['ACCOUNT'] = _cf_acc[self.gACCOUNT]
        self.cf_config['SYMBOLS'] = _cf_sym
        with open( _cf_fn, 'w') as f: json.dump(self.cf_config, f, indent=3)        

        #  https://stackoverflow.com/questions/6677424/how-do-i-import-variable-packages-in-python-like-using-variable-variables-i
        # import MetaTrader5 as mt5
        self.mt5 = __import__(_package_name)

    # =============================================================================
    #  def mt5_init( self ):
    #     
    # =============================================================================
    def mt5_init( self ):
    # =============================================================================

        ret = False    
    
        # connect to MetaTrader 5
        self.mt5.shutdown()
        ret = self.mt5.initialize( \
                path     = self.cf_config['ACCOUNT']['path'],\
                login    = self.cf_config['ACCOUNT']['login'],\
                password = self.cf_config['ACCOUNT']['password'],\
                server   = self.cf_config['ACCOUNT']['server'],\
                portable = bool(self.cf_config['ACCOUNT']['portable']) )
        
        if not ret:
            print("initialize() failed")
            print()
            self.mt5.shutdown()
            raise ValueError( _sprintf("ERROR: Initialize [%s] ", self.cf_accounts[self.gACCOUNT]['path']) )

        else:
            # request connection status and parameters
            # TODO check that AccountInfo and TerminalInfo are as requested
            # AccountInfo(login=67008870, trade_mode=0, leverage=500, limit_orders=500, margin_so_mode=0, trade_allowed=True, trade_expert=True, margin_mode=0, currency_digits=2, fifo_close=False, balance=264.23, credit=0.0, profit=0.0, equity=264.23, margin=0.0, margin_free=264.23, margin_level=0.0, margin_so_call=60.0, margin_so_so=40.0, margin_initial=0.0, margin_maintenance=0.0, assets=0.0, liabilities=0.0, commission_blocked=0.0, name='Andre Howe', server='RoboForex-ECN', currency='USD', company='RoboForex Ltd')
            # TerminalInfo(community_account=False, community_connection=False, connected=True, dlls_allowed=True, trade_allowed=True, tradeapi_disabled=False, email_enabled=False, ftp_enabled=False, notifications_enabled=False, mqid=False, build=2755, maxbars=100000, codepage=0, ping_last=42214, community_balance=0.0, retransmission=0.0, company='MetaQuotes Software Corp.', name='MetaTrader 5', language='English', path='C:\\OneDrive\\rfx\\mt\\I7\\RF5D01', data_path='C:\\OneDrive\\rfx\\mt\\I7\\RF5D01', commondata_path='C:\\Users\\Andre\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common')
            # (500, 2755, '15 Jan 2021')
            if 1 < self.verbose():            
                print(self.mt5.account_info())
                print(self.mt5.terminal_info())
                # get data on MetaTrader 5 version
                print(self.mt5.version())
                print()

        # attempt to enable the display of the EURJPY symbol in MarketWatch
        selected=self.mt5.symbol_select(self.symbol())
        if not selected:
            print("Failed to select: " + self.symbol())
            self.mt5.shutdown()
            raise( ValueError(  _sprintf("Symbol could not be selected: %s",self.symbol() ) ) )

        # display symbol properties
        symbol_info=self.mt5.symbol_info(self.symbol())
        if None != symbol_info:
            # display the terminal data 'as is'    
            #print(symbol_info)
            self.gDigits = symbol_info.digits
            self.gPoint = symbol_info.point
        else:
            raise( ValueError(  _sprintf("Symbol info could not be retrieved: %s",self.symbol() ) ) )

        return ret        
            
    # END  def mt5_init( self ):
    # =============================================================================


    # =============================================================================
    #  def mt5_export_ticks( self, _np_array, _sym, _year, _month, _day ):
    #     
    # =============================================================================
    def mt5_export_ticks( self, _np_array, _sym, _year, _month, _day ):
    # =============================================================================

        _path = _sprintf("%s\\%04d\\%02d\\%02d", self.cf_config['ACCOUNT']['path_hist_db'], _year, _month, _day)
        _fn   = _sprintf("%s\\%s.npz", _path, _sym)
        if not os.path.isdir(_path):
            os.makedirs(_path)
        if not os.path.exists(_fn):
            np.savez_compressed( _fn, _npa=_np_array, allow_pickle=False, fix_imports=False )
            # check if it has been saved correctly
            _npaz_test = np.load( _fn, allow_pickle=False, fix_imports=False )
            if True == ((_np_array==_npaz_test['_npa']).all()):
                print( 'saved ok' )
            else:
                print( 'save array error ' )

    # END def mt5_export_ticks( self, _np_array, _sym, _year, _month, _day ):
    # =============================================================================


    # =============================================================================
    #  def mt5_get_ticks( self, _sym, _periodArray, _wholeDay = False ):
    #     
    # =============================================================================
    def mt5_get_ticks( self, _sym, _periodArray, _wholeDay = False ):
    # =============================================================================
    
        # the minimum numbers of ticks to be retrieved
        _minimum_number_of_ticks_to_get = int((np.array(_periodArray).max()*2+2))

        # Live-Modus
        if 0 == gDay:
            gDtTo = gDtNow
        # History-Modus
        else:
            gDtTo = datetime( gYear, gMonth, gDay, 23, 0, 0, 0, tzinfo=gTimezoneUTC)
        
        # get the whole ticks of the day starting at 01 AM
        if True == _wholeDay:
            gTimeDelta = timedelta( hours=22 )
            gDtFrom = datetime( gDtTo.year,gDtTo.month,gDtTo.day, 1, 0, 0, 0, tzinfo=gTimezoneUTC)

        if False == _wholeDay:
            gTimeDelta = timedelta( seconds=(_minimum_number_of_ticks_to_get*3) )   
            gDtFrom = gDtTo - gTimeDelta

        self.gDtTo_epoch_ms = int(gDtTo.timestamp()*1000)

        #
        # sanity check
        #
        weekDaysMapping = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        
        if ( 5 <= gDtTo.weekday() ) or ( 5 <= gDtFrom.weekday() ) :
            strerror = _sprintf("mt5_get_ticks _sym[%s] _npa len=0 - check request time from: [%s - %s] to: [%s - %s]",_sym, weekDaysMapping[gDtFrom.weekday()], gDtFrom, weekDaysMapping[gDtTo.weekday()], gDtTo )
            raise( ValueError( strerror))

        if 0 < self.verbose(): 
            print( "\nFrom: ", weekDaysMapping[gDtFrom.weekday()], gDtFrom, " To: ", weekDaysMapping[gDtTo.weekday()], gDtTo )
            print( "\ngDtTo.timestamp() ", gDtTo.timestamp(), " gDtTo_epoch_ms: ", self.gDtTo_epoch_ms)


        #
        # get ticks
        #
        _start = time.time()
        _npa = self.mt5.copy_ticks_range( _sym, gDtFrom, gDtTo , self.mt5.COPY_TICKS_ALL)
        # In[933]: self.hTERM.last_error()
        # Out[933]: (1, 'Success')        
        if 1 != self.mt5.last_error()[0]:
            strerror = _sprintf("mt5_get_ticks_01 _sym[%s] self.mt5.copy_ticks_range error [%d][%s] ",_sym, self.mt5.last_error()[0], self.mt5.last_error()[1])
            raise( ValueError( strerror))

        if 0 == len(_npa):
            strerror = _sprintf("mt5_get_ticks_02 _sym[%s] _npa len=0 - check request time from: [%s] to: [%s] OR connection to internet",_sym, gDtFrom, gDtTo)
            raise( ValueError( strerror))

        if True == _wholeDay:
            if _minimum_number_of_ticks_to_get > len(_npa):
                strerror = _sprintf("mt5_get_ticks_03 _sym[%s] _npa len=[%d] - try another time when there are more ticks _minimum_number_of_ticks_to_get[%d] - check request time from: [%s] to: [%s]",_sym, len(_npa), _minimum_number_of_ticks_to_get, gDtFrom, gDtTo)
                raise( ValueError( strerror))

        if False == _wholeDay:
            if _minimum_number_of_ticks_to_get > len(_npa):
                # TODO optimise me like in WHILE routine in algorithm.py
                gTimeDelta = timedelta( hours=22 )
                gDtFrom = gDtTo - gTimeDelta
                _npa = self.mt5.copy_ticks_range( _sym, gDtFrom, gDtTo , self.mt5.COPY_TICKS_ALL)
                if 1 != self.mt5.last_error()[0]:
                    strerror = _sprintf("mt5_get_ticks_04 _sym[%s] self.mt5.copy_ticks_range error [%d][%s] ",_sym, self.mt5.last_error()[0], self.mt5.last_error()[1])
                    raise( ValueError( strerror))
                if (0 == len(_npa)) or _minimum_number_of_ticks_to_get > len(_npa) :
                    strerror = _sprintf("mt5_get_ticks_05 _sym[%s] _npa len=[%d] - try another time when there are more ticks _minimum_number_of_ticks_to_get[%d]  - check request time from: [%s] to: [%s] OR connection to internet",_sym, len(_npa), _minimum_number_of_ticks_to_get, gDtFrom, gDtTo)
                    raise( ValueError( strerror))
            # TODO sort me out FLIP
            _npa = _npa[(len(_npa)-_minimum_number_of_ticks_to_get):]
            #_npa = np.flip(_npa)

        # check for nan
        # _npa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')]
        for n in _npa.dtype.names:
            # print( "\t", n)  
            if np.isnan(np.sum(_npa[n])):
                strerror = _sprintf("mt5_get_ticks_05 _sym[%s] _npa len=[%d] - NAN ERROR within column[%s] %s with _npa.dtye: %s",_sym, len(_npa), n, str(_npa[n]), str(_npa.dtype))
                raise( ValueError( strerror))

        _deltams = int((time.time()-_start)*1000)
        self.gDeltaMs1 = _deltams
        if 0 < self.verbose(): 
            print( "\nlen(_npa) ", len(_npa), " deltams(_npa): ", _deltams, "\n", _npa )

        return _npa
            
    # END def mt5_get_ticks( self, _sym, _periodArray, _wholeDay = False ):
    # =============================================================================
            
            
    # =============================================================================
    #  def mt5_cnt_orders_and_positions( self, gc0 = None ):
    #     
    #    example usage:
    #      mt5_orders, abc = self.hTERM.mt5_cnt_orders_and_positions(self.symbol())
    #      profitm = mt5_orders['order_pos_buy_profitm'] + mt5_orders['order_pos_sell_profitm']
    #      profit  = mt5_orders['order_pos_buy_profit']  + mt5_orders['order_pos_sell_profit']
    #
    #   cnt orders
    # =============================================================================
    def mt5_cnt_orders_and_positions( self, gc0 = None ):
    # =============================================================================

        sym = self.symbol()
        
        # mt5 settings    
        points = self.mt5.symbol_info (sym).point
        digits = self.mt5.symbol_info (sym).digits

        # gc0 params check
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        time_msc = int(self.mt5.symbol_info_tick(sym).time_msc)
        if None == gc0 :
            gc0 = round( ((ask + bid ) / 2), digits)
    
        # display data on active orders on GBPUSD 
        orders=self.mt5.orders_get(symbol=sym) 
        if orders is None: 
            print("error code={}".format(self.mt5.last_error())) 
            return None

        positions=self.mt5.positions_get(symbol=sym)
        if positions is None: 
            print("error code={}".format(self.mt5.last_error())) 
            return None
        
        
        
        
        total                 = len(orders) + len(positions)
        order_pend_buy        = 0
        order_pend_buy_vol    = 0
        order_pend_buy_price  = 0
        order_pend_buy_time_msc = 0
        order_pend_buy_ticket = 0
        order_pend_sell       = 0
        order_pend_sell_vol   = 0
        order_pend_sell_price = 0
        order_pend_sell_time_msc = 0
        order_pend_sell_ticket = 0
        order_pos_buy         = 0
        order_pos_buy_vol     = 0
        order_pos_buy_price0  = 0
        order_pos_buy_price_max   = 0
        order_pos_buy_price_min   = 1000000
        order_pos_buy_profit  = 0
        order_pos_buy_profitm = 0
        order_pos_buy_time    = 0
        order_pos_buy_ticket  = 0
        order_pos_buy_magic   = 0
        order_pos_buy_sl      = 0
        order_pos_buy_tp      = 0
        order_pos_sell        = 0
        order_pos_sell_vol    = 0
        order_pos_sell_price0 = 0
        order_pos_sell_price_max  = 0
        order_pos_sell_price_min  = 1000000
        order_pos_sell_profit = 0
        order_pos_sell_profitm = 0
        order_pos_sell_time   = 0
        order_pos_sell_ticket = 0
        order_pos_sell_magic  = 0
        order_pos_sell_sl     = 0
        order_pos_sell_tp     = 0

        for order in orders:
            if 1 < self.verbose(): print( order )
            if (self.mt5.ORDER_TYPE_BUY_STOP   == order.type) or \
               (self.mt5.ORDER_TYPE_BUY_LIMIT  == order.type):
                order_pend_buy       = order_pend_buy + 1
                order_pend_buy_vol   = order.volume_current
                order_pend_buy_price = round(order.price_open, digits)
                order_pend_buy_time_msc = order.time_setup_msc
                order_pend_buy_ticket = order.ticket
            
            if (self.mt5.ORDER_TYPE_SELL_STOP  == order.type) or \
               (self.mt5.ORDER_TYPE_SELL_LIMIT == order.type): 
                order_pend_sell       = order_pend_sell + 1
                order_pend_sell_vol   = order.volume_current
                order_pend_sell_price = round( order.price_open, digits )
                order_pend_sell_time_msc = order.time_setup_msc
                order_pend_sell_ticket = order.ticket

        for position in positions:
            if 1 < self.verbose(): print( position )
            if (self.mt5.ORDER_TYPE_BUY == position.type):
                order_pos_buy         = order_pos_buy + 1
                order_pos_buy_vol     = round( order_pos_buy_vol + position.volume, 2 )
                #order_pos_buy_price0  = round( position.price_current, digits )
                order_pos_buy_price0  = round( position.price_open, digits )
                po = round( position.price_open, digits )
                if order_pos_buy_price_max < po:
                    order_pos_buy_price_max = po
                if order_pos_buy_price_min > po:
                    order_pos_buy_price_min = po
                order_pos_buy_profit  = order_pos_buy_profit + (position.price_current-position.price_open)/points
                order_pos_buy_profitm = round( order_pos_buy_profitm + position.profit, 2)
                order_pos_buy_time    = position.time
                order_pos_buy_ticket  = position.ticket
                order_pos_buy_magic   = position.magic
                order_pos_buy_sl      = round( position.sl, digits )
                order_pos_buy_tp      = round( position.tp, digits )
                
                '''
                # TradePosition(ticket=189164460, time=1611745214, time_msc=1611745214598, 
                time_update=1611745214, time_update_msc=1611745214598, 
                type=1, magic=456, identifier=189164460, reason=3, 
                volume=0.01, price_open=142.506, sl=0.0, tp=0.0, price_current=142.513, 
                swap=0.0, profit=-0.07, symbol='GBPJPY', comment='BPO', external_id='')
    
                sell signal:  {'total': 1, 'order_pend_buy': 0, 'order_pend_buy_vol': 0.0, 'order_pend_buy_price': 0.0, 
                               'order_pend_sell': 0, 'order_pend_sell_vol': 0.0, 'order_pend_sell_price': 0.0, 
                               
                               'order_pos_buy': 0, 'order_pos_buy_vol': 0.0, 'order_pos_buy_price_max': 0.0,
                               'order_pos_buy_time': 0, 'order_pos_buy_ticket': 0, 'order_pos_buy_magic': 0,
                               'order_pos_buy_price_min': 0.0, 'order_pos_sell': 1, 'order_pos_sell_vol': 0.01, 
                               
                               'order_pos_sell_price_min': 1.5718, 'order_pos_sell_time': 1636628351,
                               'order_pos_sell_ticket': 218451402, 'order_pos_sell_magic': 0, 
                               'order_pos_sell_price_max': 1.5717}
                               
                sell signal:  {'total': 165, 'order_pend_buy': 0, 'order_pend_buy_vol': 0.0, 'order_pend_buy_price': 0.0, 
                               'order_pend_sell': 0, 'order_pend_sell_vol': 0.0, 'order_pend_sell_price': 0.0, 
                               
                               'order_pos_buy': 79, 'order_pos_buy_vol': 0.79, 'order_pos_buy_price_min': 1.12867, 'order_pos_buy_price_max': 1.13053, 'order_pos_buy_profit': -9034, 
                               'order_pos_buy_time': 1637326106, 'order_pos_buy_ticket': 219587856, 'order_pos_buy_magic': 0, 'order_pos_buy_sl': 0, 'order_pos_buy_tp': 0, 
                               
                               'order_pos_sell': 86, 'order_pos_sell_vol': 0.86, 'order_pos_sell_price_max': 1.1302, 'order_pos_sell_price_min': 1.12841, 'order_pos_sell_profit': 6021, 
                               'order_pos_sell_time': 1637325963, 'order_pos_sell_ticket': 219587619, 'order_pos_sell_magic': 0, 'order_pos_sell_sl': 0, 'order_pos_sell_tp': 0}
    
                '''

            if (self.mt5.ORDER_TYPE_SELL == position.type):
                order_pos_sell        = order_pos_sell + 1
                order_pos_sell_vol    = round( order_pos_sell_vol + position.volume, 2)
                #order_pos_sell_price0 = round( position.price_current, digits )
                order_pos_sell_price0 = round( position.price_open, digits )
                po = round( position.price_open, digits )
                if order_pos_sell_price_max < po:
                    order_pos_sell_price_max = po
                if order_pos_sell_price_min > po:
                    order_pos_sell_price_min = po
                order_pos_sell_profit = order_pos_sell_profit + (position.price_open-position.price_current)/points
                order_pos_sell_profitm = round( order_pos_sell_profitm + position.profit, 2 )
                order_pos_sell_time   = position.time
                order_pos_sell_ticket = position.ticket
                order_pos_sell_magic  = position.magic
                order_pos_sell_sl      = round( position.sl, digits )
                order_pos_sell_tp      = round( position.tp, digits )

        if total != ( order_pend_buy + order_pend_sell + order_pos_buy + order_pos_sell ) :
            # TODO raise ERROR here
            print( ' XXX ERROR cnt orders ' ) 
            
        retdict = dict( \
                total                 = int(  total), \
                order_pend_buy        = int(  order_pend_buy), \
                order_pend_buy_vol    = float(order_pend_buy_vol), \
                order_pend_buy_price  = float(order_pend_buy_price), \
                order_pend_buy_time_msc  = int(order_pend_buy_time_msc), \
                order_pend_buy_ticket  = int(order_pend_buy_ticket), \
                order_pend_sell       = int(  order_pend_sell), \
                order_pend_sell_vol   = float(order_pend_sell_vol), \
                order_pend_sell_price = float(order_pend_sell_price), \
                order_pend_sell_time_msc = int(order_pend_sell_time_msc), \
                order_pend_sell_ticket  = int(order_pend_sell_ticket), \
                order_pos_buy         = int(  order_pos_buy), \
                order_pos_buy_vol     = float(order_pos_buy_vol), \
                order_pos_buy_price0  = float(order_pos_buy_price0),\
                order_pos_buy_price_min = float(order_pos_buy_price_min),\
                order_pos_buy_price_max = float(order_pos_buy_price_max), \
                order_pos_buy_profit  = int(order_pos_buy_profit),\
                order_pos_buy_profitm = float(order_pos_buy_profitm),\
                order_pos_buy_time    = int(order_pos_buy_time),\
                order_pos_buy_ticket  = int(order_pos_buy_ticket),\
                order_pos_buy_magic   = int(order_pos_buy_magic),\
                order_pos_buy_sl      = int(order_pos_buy_sl),\
                order_pos_buy_tp      = int(order_pos_buy_tp),\
                order_pos_sell        = int(  order_pos_sell), \
                order_pos_sell_vol    = float(order_pos_sell_vol), \
                order_pos_sell_price0 = float(order_pos_sell_price0), \
                order_pos_sell_price_min  = float(order_pos_sell_price_min), \
                order_pos_sell_price_max  = float(order_pos_sell_price_max),\
                order_pos_sell_profit = int(order_pos_sell_profit),\
                order_pos_sell_profitm = float(order_pos_sell_profitm),\
                order_pos_sell_time   = int(order_pos_sell_time),\
                order_pos_sell_ticket = int(order_pos_sell_ticket),\
                order_pos_sell_magic  = int(order_pos_sell_magic),\
                order_pos_sell_sl     = int(order_pos_sell_sl),\
                order_pos_sell_tp     = int(order_pos_sell_tp),\
             )
         
        
        # create numpy array
        #key_list = list(['POS_BUY_TP','POS_BUY_SL','POS_BUY','PEND_BUY','c0','PEND_SELL','POS_SELL','POS_SELL_SL','POS_SELL_TP'] )
        key_list = list( ['POS_BUY','PEND_BUY','c0','PEND_SELL','POS_SELL'] )
        key_list_len = len( key_list )
        dtype = np.dtype([('cnt', '<i8'), ('profit', '<i8'), ('sl', '<i8'), ('tp', '<i8'), ('delta', '<i8'), ('price', '<i8'),\
                          ('time', '<i8'),('ticket', '<i8') ])

        dtype = np.dtype([('cnt', '<i8'), ('profit', '<i8'), ('delta', '<i8'), ('price', '<i8'),\
                          ('time', '<i8'),('ticket', '<i8') ])
        
        npa = np.zeros(key_list_len, dtype=dtype)
        df =  pd.DataFrame(npa, index=key_list)
        
            
        #df['SUMCOL'] = 0
        #df.loc['SUMROW']  = 0

        if 0 < retdict['order_pos_buy']:
            df.loc['POS_BUY', 'cnt']    = retdict['order_pos_buy']
            df.loc['POS_BUY', 'profit'] = retdict['order_pos_buy_profit']
            if 0.0 < retdict['order_pos_buy_sl']:
                df.loc['POS_BUY', 'sl']     = int( ( retdict['order_pos_buy_sl'] - retdict['order_pos_buy_price0'] ) / points )
            if 0.0 < retdict['order_pos_buy_tp']:
                df.loc['POS_BUY', 'tp']     = int( ( retdict['order_pos_buy_tp'] - retdict['order_pos_buy_price0'] ) / points )
            df.loc['POS_BUY', 'delta']  = int( ( retdict['order_pos_buy_price0'] - gc0 ) / points )
            df.loc['POS_BUY', 'price']  = retdict['order_pos_buy_price0']
            df.loc['POS_BUY', 'time']   = retdict['order_pos_buy_time']*1000
            df.loc['POS_BUY', 'ticket'] = retdict['order_pos_buy_ticket']
        
        if 0 < retdict['order_pend_buy']:
            df.loc['PEND_BUY', 'cnt']    = retdict['order_pend_buy']
            df.loc['PEND_BUY', 'delta']  = int( ( retdict['order_pend_buy_price'] - gc0 ) / points )
            df.loc['PEND_BUY', 'price']  = retdict['order_pend_buy_price']
            df.loc['PEND_BUY', 'time']   = retdict['order_pend_buy_time_msc']*1000
            df.loc['PEND_BUY', 'ticket'] = retdict['order_pend_buy_ticket']

        cnt = 0
        delta = 0
        price = 0
        if 0.0 < ask and 0.0 < bid :
            cnt = 1
            price    = round( (bid + (ask - bid ) / 2), digits )
            delta    = int(( price - gc0 ) / points )
        df.loc['c0', 'cnt']    = cnt
        df.loc['c0', 'delta']  = delta
        df.loc['c0', 'price']  = price
        df.loc['c0', 'time']   = time_msc
        
        if 0 < retdict['order_pend_sell']:
            df.loc['PEND_SELL','cnt']    = retdict['order_pend_sell']
            df.loc['PEND_SELL','delta']  = int(( retdict['order_pend_sell_price'] - gc0 ) / points )
            df.loc['PEND_SELL','price']  = retdict['order_pend_sell_price']
            df.loc['PEND_SELL','time']   = retdict['order_pend_sell_time_msc']*1000
            df.loc['PEND_SELL','ticket'] = retdict['order_pend_sell_ticket']

        if 0 < retdict['order_pos_sell']:
            df.loc['POS_SELL', 'cnt']    = retdict['order_pos_sell']
            df.loc['POS_SELL', 'profit'] = retdict['order_pos_sell_profit']
            if 0.0 < retdict['order_pos_sell_sl']:
                df.loc['POS_SELL', 'sl']     = int( ( retdict['order_pos_sell_sl'] - retdict['order_pos_sell_price0'] ) / points )
            if 0.0 < retdict['order_pos_sell_tp']:
                df.loc['POS_SELL', 'tp']     = int( ( retdict['order_pos_sell_tp'] - retdict['order_pos_sell_price0'] ) / points )
            df.loc['POS_SELL', 'delta']  = int( ( retdict['order_pos_sell_price0'] - gc0 ) / points )
            df.loc['POS_SELL', 'price']  = retdict['order_pos_sell_price0']
            df.loc['POS_SELL', 'time']   = retdict['order_pos_sell_time']*1000
            df.loc['POS_SELL', 'ticket'] = retdict['order_pos_sell_ticket']

        #df.insert(0,"DTMS",pd.to_datetime(df['time'], unit='ms'))
        df['time'] = pd.to_datetime(df['time'], unit='ms')
        
        
        # self.set_df('DB',sym,df)    
        print( df )
        
        return retdict, df
        
        # at0.mt5_cnt_orders_and_positions( 'GBPJPY' )
        # TradePosition(ticket=189164460, time=1611745214, time_msc=1611745214598, time_update=1611745214, time_update_msc=1611745214598, type=1, magic=456, identifier=189164460, reason=3, volume=0.01, price_open=142.506, sl=0.0, tp=0.0, price_current=142.513, swap=0.0, profit=-0.07, symbol='GBPJPY', comment='BPO', external_id='')
        # Out[3]: 
        # {'total': 1,
        #  'order_pend_buy': 0,
        #  'order_pend_sell': 0,
        #  'order_pos_buy': 0,
        #  'order_pos_sell': 1}

        # at0.mt5_cnt_orders_and_positions( 'GBPJPY' )
        # TradeOrder(ticket=189164951, time_setup=1611745564, time_setup_msc=1611745564529, time_done=0, time_done_msc=0, time_expiration=1611705600, type=4, type_time=1, type_filling=2, state=1, magic=123, position_id=0, position_by_id=0, reason=3, volume_initial=0.01, volume_current=0.01, price_open=142.491, sl=0.0, tp=0.0, price_current=142.484, price_stoplimit=0.0, symbol='GBPJPY', comment='BPO', external_id='')
        # TradeOrder(ticket=189164952, time_setup=1611745564, time_setup_msc=1611745564570, time_done=0, time_done_msc=0, time_expiration=1611705600, type=5, type_time=1, type_filling=2, state=1, magic=456, position_id=0, position_by_id=0, reason=3, volume_initial=0.01, volume_current=0.01, price_open=142.471, sl=0.0, tp=0.0, price_current=142.475, price_stoplimit=0.0, symbol='GBPJPY', comment='BPO', external_id='')
        # Out[6]: 
        # {'total': 2,
        #  'order_pend_buy': 1,
        #  'order_pend_sell': 1,
        #  'order_pos_buy': 0,
        #  'order_pos_sell': 0}
            
        # at0.mt5_cnt_orders_and_positions( 'GBPJPY' )
        # TradeOrder(ticket=189164951, time_setup=1611745564, time_setup_msc=1611745564529, time_done=0, time_done_msc=0, time_expiration=1611705600, type=4, type_time=1, type_filling=2, state=1, magic=123, position_id=0, position_by_id=0, reason=3, volume_initial=0.01, volume_current=0.01, price_open=142.491, sl=0.0, tp=0.0, price_current=142.471, price_stoplimit=0.0, symbol='GBPJPY', comment='BPO', external_id='')
        # TradePosition(ticket=189164952, time=1611745581, time_msc=1611745581123, time_update=1611745581, time_update_msc=1611745581123, type=1, magic=456, identifier=189164952, reason=3, volume=0.01, price_open=142.469, sl=0.0, tp=0.0, price_current=142.471, swap=0.0, profit=-0.02, symbol='GBPJPY', comment='BPO', external_id='')
        # Out[7]: 
        # {'total': 2,
        #  'order_pend_buy': 1,
        #  'order_pend_sell': 0,
        #  'order_pos_buy': 0,
        #  'order_pos_sell': 1}

    #  def mt5_cnt_orders_and_positions( self, gc0 = None ):
    # =============================================================================

#
# utilities
#
# https://stackoverflow.com/questions/30399534/shift-elements-in-a-numpy-array
#
'''
gNpa['time_msc']
Out[25]: 
array([1681913721865, 1681913721641, 1681913720681, 1681913720617,
       1681913720554, 1681913720457, 1681913719688, 1681913718313,
       1681913717641, 1681913717321, 1681913717257, 1681913716297,
       1681913713960, 1681913713865, 1681913712713, 1681913712650],
      dtype=int64)

np_array_shift(gNpa['time_msc'], 0)
np_array_shift n=0 - implement me
Out[26]: 
array([1681913721865, 1681913721641, 1681913720681, 1681913720617,
       1681913720554, 1681913720457, 1681913719688, 1681913718313,
       1681913717641, 1681913717321, 1681913717257, 1681913716297,
       1681913713960, 1681913713865, 1681913712713, 1681913712650],
      dtype=int64)

np_array_shift(gNpa['time_msc'], 1)
Out[27]: 
array([            0, 1681913721865, 1681913721641, 1681913720681,
       1681913720617, 1681913720554, 1681913720457, 1681913719688,
       1681913718313, 1681913717641, 1681913717321, 1681913717257,
       1681913716297, 1681913713960, 1681913713865, 1681913712713],
      dtype=int64)

np_array_shift(gNpa['time_msc'], -1)
Out[28]: 
array([1681913721641, 1681913720681, 1681913720617, 1681913720554,
       1681913720457, 1681913719688, 1681913718313, 1681913717641,
       1681913717321, 1681913717257, 1681913716297, 1681913713960,
       1681913713865, 1681913712713, 1681913712650,             0],
      dtype=int64)
'''      
def np_array_shift(xs, n):
    
    if 0 == n:
        print( "np_array_shift n=0 - implement me" )
        return xs

    #e = np.empty_like(xs)
    e = np.zeros_like(xs)
    if 0 < n:
        #e[:n] = np.nan
        e[n:] = xs[:-n]
    if 0 > n:
        #e[n:] = np.nan
        e[:n] = xs[-n:]
    return e




'''
Config
    Account
    Interface
        File|Db3|Mt5
    Mode
        Live|History
    Time
        Live|History|Steps
    Time-Live
        tzinfo
        to
        from
        delta
        offset
    Time-History
        tzinfo
        to
        from
        delta
    Time-Steps
        tzinfo
        to
        from
        delta
    Period
        16
        160
        1600
        16000
    Symbols-Account
        EURUSD  
            digits
            points

    
BaseC0
    _c0
    get()
    set()

Ticks


Trade
    


'''

def get_fuzzy_membership( data, data_step = 0.1 ):
    """Create a triangular membership function with a data series and its max, min and median"""
    
    low        = data.min()
    high       = data.max()
    mid        = np.median(np.arange(low, high, data_step))   
    universe   = np.arange (np.floor(low), np.ceil(high), data_step)
    trimf_lowE = fuzz.trimf(universe, [ low, low,  mid])
    trimf_low  = fuzz.trimf(universe, [ low, (low+mid)/2, mid])
    trimf_mid  = fuzz.trimf(universe, [ low, mid,  high])
    trimf_high = fuzz.trimf(universe, [ mid, (mid+high)/2, high])
    trimf_highE= fuzz.trimf(universe, [ mid, high, high])

    """Assign fuzzy membership to each observation in the data series and return a dataframe of the result"""
    
    new_df = pd.DataFrame(data)
    new_df['-2'] = fuzz.interp_membership(universe, trimf_lowE, data)
    new_df['-1'] = fuzz.interp_membership(universe, trimf_low,  data)
    new_df[ '0'] = fuzz.interp_membership(universe, trimf_mid,  data)
    new_df['+1'] = fuzz.interp_membership(universe, trimf_high, data)
    new_df['+2'] = fuzz.interp_membership(universe, trimf_highE,data)
    #new_df['membership'] = new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1)
    ## for np ->  new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1).to_numpy().astype(np.float64)
    #new_df['degree'] = new_df.loc[:, ['-2', '-1', '0', '+1', '+2']].max(axis = 1)
    ## for np ->  new_df.loc[:, ['-2', '-1', '0', '+1', '+2']].max(axis = 1).to_numpy()
    #return new_df
    return new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1).to_numpy().astype(np.float64)



def MainFunction( _sym, _npa ):

    global gH
    global gNpa
    global gDict
    global gPeriodArray
    
    _start0 = time.time()
    _start = time.time()
    #
    # before
    #
    #  _npa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')]
    # https://numpy.org/doc/stable/reference/generated/numpy.dtype.html
     
    dtype = _npa.dtype
    _names = []
    _formats = []

    """
    In[511]: _npa
    Out[511]: 
    array([(1685926800, 1.07068, 1.07094, 0., 0, 1685926800106, 134, 0.),
           (1685926800, 1.07067, 1.07097, 0., 0, 1685926800555, 134, 0.),
           (1685926800, 1.07067, 1.07096, 0., 0, 1685926800842,   4, 0.), ...,
           (1685993208, 1.07144, 1.07144, 0., 0, 1685993208566,   6, 0.),
           (1685993209, 1.07145, 1.07145, 0., 0, 1685993209238,   6, 0.),
           (1685993209, 1.07144, 1.07148, 0., 0, 1685993209686,   6, 0.)],
          dtype=[('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8')])

    # automatic append MT5 tick types here_
    for n in _npa.dtype.names:
        _names.append(n)
        _formats.append(_npa.dtype[n])

    """  

    # add time    
    _names.append('time')
    _formats.append(np.dtype(np.int64))  #  '<i8'

    # add time_msc   
    _names.append('time_msc')
    _formats.append(np.dtype(np.int64))  #  '<i8'

    #
    # TODO epoch to time string conversion takes too long
    #
    # # add np_time_msc
    _names.append('np_time_msc')
    # # # https://numpy.org/doc/stable/reference/generated/numpy.dtype.html
    _formats.append(np.dtype('<S25')) 
    

    # add bid    
    _names.append('bid')
    _formats.append(np.dtype(np.float64))  #  '<f8'

    # add ask    
    _names.append('ask')
    _formats.append(np.dtype(np.float64))  #  '<f8'

    # add price    
    _names.append('price')
    _formats.append(np.dtype(np.float64))  #  '<f8'
    
    # add spread
    _names.append('spread')
    _formats.append(np.dtype(np.int64))   #  '<i8'
    
    # add tdmsc
    _names.append('tdmsc')
    _formats.append(np.dtype(np.int64))   #  '<i8'
    
    _names.append('B_cnt')
    _formats.append(np.dtype('<S3')) 
    for n in gPeriodArray:
        # add cnt_n
        _names.append('cnt_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_d_s')
    _formats.append(np.dtype('<S3')) 
    for n in gPeriodArray:
        # add d_s_n
        _names.append('d_s_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_cnt_d_s')
    _formats.append(np.dtype('<S7')) 
    for n in gPeriodArray:
        # add cnt/d_s_n
        _names.append('cnt_d_s_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_oc')
    _formats.append(np.dtype('<S2')) 
    for n in gPeriodArray:
        # add oc_n
        _names.append('oc_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_ocf')
    _formats.append(np.dtype('<S3')) 
    for n in gPeriodArray:
        # add oc_n
        _names.append('ocf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_hl')
    _formats.append(np.dtype('<S2')) 
    for n in gPeriodArray:
        # add hl_n
        _names.append('hl_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_oc_hl')
    _formats.append(np.dtype('<S5')) 
    for n in gPeriodArray:
        # add oc/hl_n
        _names.append('oc_hl_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_priced')
    _formats.append(np.dtype('<S6')) 
    for n in gPeriodArray:
        # add priced
        _names.append('priced_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_pricedf')
    _formats.append(np.dtype('<S7')) 
    for n in gPeriodArray:
        # add pricedf
        _names.append('pricedf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_spread')
    _formats.append(np.dtype('<S6')) 
    for n in gPeriodArray:
        # add spread
        _names.append('spread_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_tdmsc')
    _formats.append(np.dtype('<S5')) 
    for n in gPeriodArray:
        # add tdmsc
        _names.append('tdmsc_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'


    _names.append('B_mean')
    _formats.append(np.dtype('<S4')) 

    _names.append('cnt_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('d_s_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('cnt_d_s_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('oc_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('ocf_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('hl_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('oc_hl_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('priced_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('pricedf_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('spread_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('tdmsc_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_median')
    _formats.append(np.dtype('<S6')) 

    _names.append('cnt_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('d_s_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('cnt_d_s_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('oc_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('ocf_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('hl_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('oc_hl_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('priced_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('pricedf_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('spread_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('tdmsc_median')
    _formats.append(np.dtype(np.float64))   #  '<f8'



    #
    # after
    #
    # _names:    ['time', 'bid', 'ask', 'last', 'volume', 'time_msc', 'flags', 'volume_real', 'price', 'spread', 'tdmsc']  
    # _formats:  [dtype('int64'), dtype('float64'), dtype('float64'), dtype('float64'), dtype('uint64'), dtype('int64'), dtype('uint32'), dtype('float64'), dtype('float64'), dtype('uint32'), dtype('uint32')]
    # 
    #  gNpa.dtype:  [('time', '<i8'), ('bid', '<f8'), ('ask', '<f8'), ('last', '<f8'), ('volume', '<u8'), ('time_msc', '<i8'), ('flags', '<u4'), ('volume_real', '<f8'), ('price', '<f8'), ('spread', '<u4'), ('tdmsc', '<u4')]
     

    dtype = np.dtype({'names':_names, 'formats':_formats})
    # create empty gNpa array
    gNpa = np.zeros(len(_npa), dtype=dtype)

    """
    # automatically copy _npa array into gNpa
    for n in _npa.dtype.names:
        gNpa[n] = _npa[n]
    # print( "\n gNpa.dtype: ", gNpa.dtype )
    """
    
    items_to_copy = ['time','time_msc','bid','ask']
    for n in items_to_copy:
        gNpa[n] = _npa[n]

    #
    # TODO epoch to time string conversion takes too long
    #
    # # https://numpy.org/doc/stable/reference/arrays.datetime.html
    # # gNpa['np_time_msc']  = 'NaT'
    gNpa['np_time_msc']  = _npa['time_msc'].astype('datetime64[ms]')
    #gNpa['time']  = _npa['time_msc'].astype('datetime64[ms]')
    

    gNpa['price']  =  ( gNpa['ask'] + gNpa['bid'] ) / 2
    gNpa['spread'] = ( gNpa['ask'] - gNpa['bid'] ) / gH.point() 
    gNpa['tdmsc']  = ( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift(1) ) 
    #gNpa['tdmsc']  = ( gNpa['time_msc'] - np_array_shift(gNpa['time_msc'] , +1)  )
    # TODO don't set to zero for fooling min() function 
    # otherwise the index -1 will always be the minimum if set to zero
    # also don't set to NaN - otherwise the NaN check does not work
    gNpa['tdmsc'][0] = 0

    """
    for n in gPeriodArray:

        gNpa['cnt_'+str(n)]  = n 

        gNpa['d_s_'+str(n)]  = np.round(( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift( n ) ) / 1000)

        gNpa['cnt/d_s_'+str(n)]  = np.round( gNpa['cnt_'+str(n)] / gNpa['d_s_'+str(n)], decimals = 2 )
        

        gNpa['oc_'+str(n)]  = ( pd.Series(gNpa['price']) - pd.Series(gNpa['price']).shift( n ) ) / gH.point()
        # oc = int( round( ( gNpa['price'][0] - gNpa['price'][-1] ) / gH.point(), 0 ) )
        
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['hl_'+str(n)]  = (( pd.Series(gNpa['price']).rolling( n ).max() - pd.Series(gNpa['price']).rolling( n ).min() ) / gH.point() )

        gNpa['oc/hl_'+str(n)]  = np.round( gNpa['oc_'+str(n)] / gNpa['hl_'+str(n)], decimals = 2 )
    """

    gNpa['B_cnt']  = 'cnt'
    for n in gPeriodArray:
        gNpa['cnt_'+str(n)]  = n 
    
    gNpa['B_d_s']  = 'd_s'
    for n in gPeriodArray:
        gNpa['d_s_'+str(n)]  = (( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift( n ) ) / 1000 )

    gNpa['B_cnt_d_s']  = 'cnt/d_s'
    for n in gPeriodArray:
        gNpa['cnt_d_s_'+str(n)]  = np.round( gNpa['cnt_'+str(n)] / gNpa['d_s_'+str(n)], decimals = 2 )
        
    gNpa['B_oc']  = 'oc'
    gNpa['B_ocf'] = 'ocf'
    for n in gPeriodArray:
        #gNpa['oc_'+str(n)]  = ( pd.Series(gNpa['price']) - pd.Series(gNpa['price']).shift( n ) ) / gH.point()
        ## oc = int( round( ( gNpa['price'][0] - gNpa['price'][-1] ) / gH.point(), 0 ) )
        _oc  = ( pd.Series(gNpa['price']) - pd.Series(gNpa['price']).shift( n ) ) / gH.point()
        gNpa['oc_'+str(n)]   = _oc
        gNpa['ocf_'+str(n)]  = get_fuzzy_membership( _oc )
        
    gNpa['B_hl']  = 'hl'
    for n in gPeriodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['hl_'+str(n)]  = (( pd.Series(gNpa['price']).rolling( n ).max() - pd.Series(gNpa['price']).rolling( n ).min() ) / gH.point() )

    gNpa['B_oc_hl']  = 'oc/hl'
    for n in gPeriodArray:
        gNpa['oc_hl_'+str(n)]  = np.round( gNpa['oc_'+str(n)] / gNpa['hl_'+str(n)], decimals = 2 )

    gNpa['B_priced']  = 'priced'
    gNpa['B_pricedf']  = 'pricedf'
    for n in gPeriodArray:
        #gNpa['priced_'+str(n)]  = np.round(((pd.Series(gNpa['price']) - (pd.Series(gNpa['price']).rolling( n ).max() + pd.Series(gNpa['price']).rolling( n ).min())/2))/gH.point(), decimals=0)
        # TODO next line ist not working, why? workaroung is to pass in _priced
        #gNpa['pricedf_'+str(n)]  = get_fuzzy_membership( (gNpa['priced_'+str(n)]))
        _priced = np.round(((pd.Series(gNpa['price']) - (pd.Series(gNpa['price']).rolling( n ).max() + pd.Series(gNpa['price']).rolling( n ).min())/2))/gH.point(), decimals=0)
        gNpa['priced_'+str(n)]   = _priced
        gNpa['pricedf_'+str(n)]  = get_fuzzy_membership( _priced )


    gNpa['B_spread']  = 'spread'
    for n in gPeriodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['spread_'+str(n)]  = pd.Series(gNpa['spread']).rolling( n ).max() 

    gNpa['B_tdmsc']  = 'tdmsc'
    for n in gPeriodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['tdmsc_'+str(n)]  = pd.Series(gNpa['tdmsc']).rolling( n ).max() 



    gNpa['B_mean']  = 'mean'

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('cnt_'+str(n))
    gNpa['cnt_'+'mean'] = np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1, dtype=np.int64)
    """
    #  https://stackoverflow.com/questions/7842157/how-to-convert-numpy-recarray-to-numpy-array
    print( per_arr_str )
      ['cnt_28800', 'cnt_14400', 'cnt_7200', 'cnt_3600', 'cnt_1800', 'cnt_900', 'cnt_450', 'cnt_225', 'cnt_120', 'cnt_60', 'cnt_30', 'cnt_15']
      
    In[226] gNpa[ per_arr_str ]
    Out[226]: 
    array([(28800., 14400., 7200., 3600., 1800., 900., 450., 225., 120., 60., 30., 15.),
           (28800., 14400., 7200., 3600., 1800., 900., 450., 225., 120., 60., 30., 15.),
           (28800., 14400., 7200., 3600., 1800., 900., 450., 225., 120., 60., 30., 15.),
           ...,
           (28800., 14400., 7200., 3600., 1800., 900., 450., 225., 120., 60., 30., 15.),
           (28800., 14400., 7200., 3600., 1800., 900., 450., 225., 120., 60., 30., 15.),
           (28800., 14400., 7200., 3600., 1800., 900., 450., 225., 120., 60., 30., 15.)],
          dtype={'names': ['cnt_28800', 'cnt_14400', 'cnt_7200', 'cnt_3600', 'cnt_1800', 'cnt_900', 'cnt_450', 'cnt_225', 'cnt_120', 'cnt_60', 'cnt_30', 'cnt_15'], 'formats': ['<f8', '<f8', '<f8', '<f8', '<f8', '<f8', '<f8', '<f8', '<f8', '<f8', '<f8', '<f8'], 'offsets': [84, 92, 100, 108, 116, 124, 132, 140, 148, 156, 164, 172], 'itemsize': 727})

    In[231]  pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(dtype=np.int64)
    Out[231]: 
    array([[28800, 14400,  7200, ...,    60,    30,    15],
           [28800, 14400,  7200, ...,    60,    30,    15],
           [28800, 14400,  7200, ...,    60,    30,    15],
           ...,
           [28800, 14400,  7200, ...,    60,    30,    15],
           [28800, 14400,  7200, ...,    60,    30,    15],
           [28800, 14400,  7200, ...,    60,    30,    15]], dtype=int64)
       
         
    In[231]  np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 0, dtype=np.int64)
    Out[238]: 
    array([28800, 14400,  7200,  3600,  1800,   900,   450,   225,   120,
              60,    30,    15], dtype=int64)

    In[231]  np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1, dtype=np.int64)
    Out[239]: array([4800, 4800, 4800, ..., 4800, 4800, 4800], dtype=int64)
         
    """ 

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('d_s_'+str(n))
    gNpa['d_s_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('cnt_d_s_'+str(n))
    gNpa['cnt_d_s_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )
    
    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('oc_'+str(n))
    gNpa['oc_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('ocf_'+str(n))
    gNpa['ocf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('hl_'+str(n))
    gNpa['hl_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('oc_hl_'+str(n))
    gNpa['oc_hl_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('priced_'+str(n))
    gNpa['priced_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('pricedf_'+str(n))
    gNpa['pricedf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('spread_'+str(n))
    gNpa['spread_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('tdmsc_'+str(n))
    gNpa['tdmsc_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 




    gNpa['B_median']  = 'median'

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('cnt_'+str(n))
    gNpa['cnt_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('d_s_'+str(n))
    gNpa['d_s_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('cnt_d_s_'+str(n))
    gNpa['cnt_d_s_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )
    
    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('oc_'+str(n))
    gNpa['oc_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('ocf_'+str(n))
    gNpa['ocf_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('hl_'+str(n))
    gNpa['hl_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('oc_hl_'+str(n))
    gNpa['oc_hl_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('priced_'+str(n))
    gNpa['priced_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('pricedf_'+str(n))
    gNpa['pricedf_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('spread_'+str(n))
    gNpa['spread_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in gPeriodArray: 
        per_arr_str.append('tdmsc_'+str(n))
    gNpa['tdmsc_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)


    # gDf  = pd.DataFrame(gNpa)
    # gDf['time']=pd.to_datetime(gDf['time_msc'], unit='ms')
    # gDf['price']  = round(( gDf.ask + gDf.bid ) / 2,       5 )
    # gDf['spread'] = ( gDf.ask - gDf.bid ) / gH.point()
    # gDf['tdmsc']  = (gDf.time_msc - gDf.shift(-1).time_msc)


    # TODO sort me out FLIP
    gNpa = np.flip(gNpa)
    

    gDict = {}
    gDict['EURUSD'] = {}
    gDict['EURUSD']['in'] = {}
    gDict['EURUSD']['out'] = {}
    gDict['EURUSD']['in'] = _npa
    gDict['EURUSD']['out'] = gNpa


    # # https://pyopengl.sourceforge.net/pydoc/numpy.lib.recfunctions.html
    # from numpy.lib import recfunctions as rfn

    # # # create numpy array
    # gNpa_f8 = np.zeros(len(_npa), dtype='<f8')
    # gNpa_u8 = np.zeros(len(_npa), dtype='<u8')


    # gNpa = rfn.append_fields(gNpa, 'price',  gNpa_f8, usemask = False )
    # gNpa = rfn.append_fields(gNpa, 'spread', gNpa_u8, usemask = False )
    # gNpa = rfn.append_fields(gNpa, 'tdmsc',  gNpa_u8, usemask = False )


    # print( "\n gNpa.dtype: ", gNpa.dtype )
    # # check for nan
    # for n in gNpa.dtype.names:
    #     print( "\t", n)
    #     if np.isnan(np.sum(gNpa[n])):
    #         strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",_sym, n, str(gNpa[n]))
    #         raise( ValueError( strerror))


    # gDf  = pd.DataFrame(gNpa)
    # gDf['time']=pd.to_datetime(gDf['time_msc'], unit='ms')
    # gDf['price']  = round(( gDf.ask + gDf.bid ) / 2,       5 )
    # gDf['spread'] = ( gDf.ask - gDf.bid ) / gH.point()
    # gDf['tdmsc']  = (gDf.time_msc - gDf.shift(-1).time_msc)

    # idxstart = gDf.index[0]
    # idxend = gDf.index[-1]
    # gDf.loc[idxend,'tdmsc'] = 0

    # # TODO build WATCHER when has the last tick occured
    gTimeLastTickMS = gH.gDtTo_epoch_ms - gNpa['time_msc'][0]
    _deltams = int((time.time()-_start)*1000)
    gDeltaMs2 = _deltams

    if 0 < gH.verbose(): 
        print( "\nlen(gNpa) ", len(gNpa), " deltams(gNpa): ", _deltams, " gTimeLastTickMS: ", gTimeLastTickMS, "\n", gNpa )

    #
    # time
    #
    # https://numpy.org/doc/stable/reference/arrays.datetime.html
    tnow = np.array(gH.gDtTo_epoch_ms).astype('datetime64[ms]')
    topen=gNpa['time_msc'][0].astype('datetime64[ms]')
    tclose=gNpa['time_msc'][-1].astype('datetime64[ms]')
    d_s = int((  gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000)
    if 0 < gH.verbose(): 
        print()
        print( _sym, "TIME ", gTimeLastTickMS, "ms" 
                   "  t:", tnow, 
                  "  t0:", topen,
                  "  tn:", tclose,
                  "  d_h:", round((gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000/3600, 1),
                  "  d_m:", int((  gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000/60),
                  "  d_s:", int((  gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000),
                  "  d_ms:", int(  gNpa['time_msc'][0] - gNpa['time_msc'][-1])
                  )

    #
    # price OC
    #
    oc = int( round( ( gNpa['price'][0] - gNpa['price'][-1] ) / gH.point(), 0 ) )

    if 0 < gH.verbose(): 
        print( _sym, "PRICE  OC: ", oc, " open: ", gNpa['price'][0], "@", topen, " close: ", gNpa['price'][-1] , "@", tclose )


    #
    # price HL
    #
    idxmax=gNpa['price'].argmax(axis=0)
    idxmin=gNpa['price'].argmin(axis=0)
    thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
    tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
    hl =  int( round( ( gNpa['price'][idxmax] - gNpa['price'][idxmin] ) / gH.point(), 0 ) )

    if 0 < gH.verbose(): 
        print( _sym, "PRICE  HL: ", hl, " high: ", gNpa['price'][idxmax], "@", thigh, " low: ", gNpa['price'][idxmin] , "@", tlow )

    #
    # spread HL
    #
    idxmax=gNpa['spread'].argmax(axis=0)
    idxmin=gNpa['spread'].argmin(axis=0)
    spread_thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
    spread_tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
    spread_hl =  gNpa['spread'][idxmax] - gNpa['spread'][idxmin]

    if 0 < gH.verbose(): 
        print( _sym, "SPREAD HL: ", spread_hl, " high: ", gNpa['spread'][idxmax], "@", spread_thigh, " low: ", gNpa['spread'][idxmin] , "@", spread_tlow )

    #
    # tdmsc HL
    #
    idxmax=gNpa['tdmsc'].argmax(axis=0)
    idxmin=gNpa['tdmsc'].argmin(axis=0)
    tdmsc_thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
    tdmsc_tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
    tdmsc_hl =  gNpa['tdmsc'][idxmax] - gNpa['tdmsc'][idxmin]

    if 0 < gH.verbose(): 
        print( _sym, "TDMSC  HL: ", tdmsc_hl, " high: ", gNpa['tdmsc'][idxmax], "@", tdmsc_thigh, " low: ", gNpa['tdmsc'][idxmin] , "@", tdmsc_tlow )


    #
    # calc track (full) - pcm aka np.polyfit
    #
    lent = len(gNpa)
    #gNpa = gNpa[0:lent]
    '''
    TODO explain here why flip again?!
    the last/newest/latest element is now not on index 0 anymore
    on index 0 is now the oldest element
    - otherwise PCM calculation wrong - or had to be adjusted by multiplying it by -1
    - the matplot diagram would look mirrored
    '''
    # TODO sort me out FLIP
    gNpa = np.flip(gNpa)
    
    gNpaPrice0 = gNpa['price'][0]
    gNPAoffset = gNpaPrice0 * np.ones(len(gNpa))
    gNpaRealTrack = (gNpa['price'] - gNPAoffset)/gH.point()

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
    pcmraw = 0
    # 1.) don't divide by zero and 2.) at least 2 entries are required for polyfit
    if (0 != pcmax) and (1<lent):
        pcmraw = np.polyfit(x,y,1)[0]
        pcm = round( (pcmraw * lent) / pcmax, 1)
    pcmreal = float("%.1f" % pcm)
    pcmrealraw = pcmraw
    pcmaxreal = int(pcmax) 
    myarraytrack = myarray

    '''
    gDtTo.strftime("%Y.%m.%d %H:%M:%S")
    print( '\n', gH.gACCOUNT, sym, gPeriod, 50 * '-' )
    for idx in range(0,lent,1):
        outstr = _sprintf("  %02d %9.3f %6d %6d ", idx, gNPA['close'][idx], myarraytrack[idx], myarraypred[idx] )
        print( outstr )
    '''

    if 0 < gH.verbose(): 
        outstr = _sprintf("\tpcm: %4.2f / %4.1f - pcmax: %3d", pcmrealraw, pcmreal, pcmaxreal )
        print( outstr )


    _deltams = int((time.time()-_start0)*1000)

    oc_hl = 0
    if 0 != hl:
        oc_hl = round((oc/hl),1)
    lent_d_s = 0
    if 0 != d_s:
        lent_d_s = round(lent/d_s,1)

    # gStrH =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 
    # print( gStrH )
    # SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl
    # EURUSD   837    670   -147    -0.2   -0.4   79574   62388      1.3        42          1         20         36    
    _strc = _sprintf( "%s %5d  %5d  %5d    %+0.1f   %+0.1f  %6d  %6d      %0.1f     %5d      %5d      %5d      %5d", 
                    _sym,
                    gTimeLastTickMS,
                    hl,     
                    oc,
                    oc_hl,
                    pcmreal,
                    lent,
                    d_s,
                    lent_d_s,
                    _deltams,
                    gH.gDeltaMs1,
                    gDeltaMs2,
                    spread_hl
              )
    print( _strc )


    #if 0 < gH.verbose(): 

    gFontSize = 10
    gLabelXstr        = "X"
    gLabelYstr        = "Y"


    tclose = gNpa['time_msc'][-1].astype('datetime64[ms]')
    topen = gNpa['time_msc'][0].astype('datetime64[ms]')

    fig = plt.figure()
    gTitleStr = ""
    gTitleStr = _sprintf("%s %d %s ( %s - %s )",\
      gH.gACCOUNT, len(_npa), _sym, str(topen), str(tclose) )
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
    
    
    # TODO sort me out FLIP
    gNpa = np.flip(gNpa)
    

# END def MainFunction( _sym = 'EURUSD', _TicksPerPeriod  = 0, _TimeDelta = 0 ):





# global handle to algotrader object
#gConf  = Mt5LiveConfig(cAccount, [cSym], [gPeriodArray])
gConf = Mt5LiveConfig(cAccount, [cSym], [gPeriodArray])
gTerm = MT5LiveTerminal( gConf )
gTime = LiveTime( gTerm )
_npa = gTime.update_day(cSym)
print( 'from: ', gTime.gDtFrom, '  to: ', gTime.gDtTo, " len: ", len(_npa),_npa )
#MainFunction( cSym, _npa)
mt5_orders, abc = gTerm.term_cnt_orders_and_positions( cSym, 1.08070 )
profit  = mt5_orders['order_pos_buy_profit']  + mt5_orders['order_pos_sell_profit']



gH = MT5(cAccount, cSym)
gH.mt5_init()

mt5_orders, abc = gH.mt5_cnt_orders_and_positions( 1.08070 )
profit  = mt5_orders['order_pos_buy_profit']  + mt5_orders['order_pos_sell_profit']


print()
print( gStrH )
print()



# get ticks - gPeriodArray.max()
_npa = gH.mt5_get_ticks( cSym, gPeriodArray  )
MainFunction( cSym, _npa)


# get ticks - all for the day starting with 1AM | _wholeDay = True
_npa = gH.mt5_get_ticks( cSym, gPeriodArray, True )
MainFunction( cSym, _npa)

"""
print()

MainFunction( cSym, 28800)
MainFunction( cSym, 14400)
MainFunction( cSym, 7200)
MainFunction( cSym, 3600)
MainFunction( cSym, 1800)
MainFunction( cSym, 900)
MainFunction( cSym, 450)
MainFunction( cSym, 225)
MainFunction( cSym, 120)
MainFunction( cSym, 60)
MainFunction( cSym, 30)
MainFunction( cSym, 15)

print()

MainFunction( cSym, 0, 28800)
MainFunction( cSym, 0, 14400)
MainFunction( cSym, 0, 7200)
MainFunction( cSym, 0, 3600)
MainFunction( cSym, 0, 1800)
MainFunction( cSym, 0, 900)
MainFunction( cSym, 0, 450)
MainFunction( cSym, 0, 225)
MainFunction( cSym, 0, 120)
MainFunction( cSym, 0, 60)
MainFunction( cSym, 0, 30)
MainFunction( cSym, 0, 15)

"""

'''


print()

MainFunction( cSym, 10000)
MainFunction( cSym, 1000)
MainFunction( cSym, 100)
MainFunction( cSym, 10)

print()

MainFunction( cSym, 0,10000)
MainFunction( cSym, 0,1000)
MainFunction( cSym, 0,100)
MainFunction( cSym, 0,10)
#MainFunction( cSym, 0,1)

#
#
#

print()

MainFunction( cSym, 16000)
MainFunction( cSym, 1600)
MainFunction( cSym, 160)
MainFunction( cSym, 16)

print()

MainFunction( cSym, 0,10000)
MainFunction( cSym, 0,1000)
MainFunction( cSym, 0,100)
MainFunction( cSym, 0,10)
#MainFunction( cSym, 0,1)

'''

print()
print( gStrH )
print()



"""

#
# test code I
#
lt = LiveTime( gPeriodArray )
lt.update_day()
print( 'from: ', lt.gDtFrom, '  to: ', lt.gDtTo )
_npa = gH.mt5.copy_ticks_range( gH.gSymbol, lt.gDtFrom, lt.gDtTo , gH.mt5.COPY_TICKS_ALL)
print(len(_npa),_npa)


#
# test code II
#
lt = LiveTime( gPeriodArray )
lt.update_ticks()
print( 'from: ', lt.gDtFrom, '  to: ', lt.gDtTo )
_npa = gH.mt5.copy_ticks_range( gH.gSymbol, lt.gDtFrom, lt.gDtTo , gH.mt5.COPY_TICKS_ALL)
print(len(_npa),_npa)


#
# test code III
#
lt = HistTime( gPeriodArray )
lt.update_day( 2023, 6, 9 )
print( 'from: ', lt.gDtFrom, '  to: ', lt.gDtTo )
_npa = gH.mt5.copy_ticks_range( gH.gSymbol, lt.gDtFrom, lt.gDtTo , gH.mt5.COPY_TICKS_ALL)
print(len(_npa),_npa)

#
# test code IV
#
lt = HistTime( gPeriodArray )
lt.update_ticks( 2023, 6, 9, 12,0,0 )
print( 'from: ', lt.gDtFrom, '  to: ', lt.gDtTo )
_npa = gH.mt5.copy_ticks_range( gH.gSymbol, lt.gDtFrom, lt.gDtTo , gH.mt5.COPY_TICKS_ALL)
print(len(_npa),_npa)


#
# test code III
#
lt = HistTime( gPeriodArray )
lt.update_day( 2023, 6, 9 )
print( 'from: ', lt.gDtFrom, '  to: ', lt.gDtTo )
_npa = gH.mt5.copy_ticks_range( gH.gSymbol, lt.gDtFrom, lt.gDtTo , gH.mt5.COPY_TICKS_ALL)
gH.mt5_export_ticks( _npa, gH.gSymbol, 2023, 6, 9 )
print(len(_npa),_npa)

"""

#
# export gNpa to CSV
#
# pd.DataFrame( gNpa ).to_csv('gNpa.csv')

