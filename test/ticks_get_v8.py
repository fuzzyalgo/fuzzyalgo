# -*- coding: utf-8 -*-
"""
Created on Sat Feb 25 15:07:51 2023

@author: G6
"""

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

"""
# TODO make me optional, for example
"""
cHourStart = 1
cYear  = 2023
cMonth = 6
cDay   = 23
cDay   = 0   # -> get hist today live

gH = None

cPeriodArray_0 = [28800,14400,7200,3600,1800,900,450,225,120,60,30,15]
cPeriodArray_1 = [28800,14400,7200                                   ]
cPeriodArray_2 = [                 3600,1800,900                     ]
cPeriodArray_3 = [                               450,225,120         ]
cPeriodArray_4 = [                                           60,30,15]

cPeriodArray_21 = [                 10000                     ]
cPeriodArray_32 = [                               1000         ]
cPeriodArray_43 = [                                           100]

cPeriodArray_22 = [                 1000                   ]

cPeriodArray   = [cPeriodArray_1,cPeriodArray_2,cPeriodArray_3,cPeriodArray_4]
cPeriodArray   = [cPeriodArray_21,cPeriodArray_32,cPeriodArray_43]
#cPeriodArray   = [cPeriodArray_22]

cPeriodArray_0 = [                 3600,1800,900                     ]

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
        self.gDtNow       = datetime.now(self.gTimezoneUTC) + self.gTdOffset

        self.gDtFrom      = None
        self.gDtTo        = None
        
        self.gDtTo_epoch_ms = None
        
        # the minimum numbers of ticks to be retrieved
        self.hTERM = _termObj.hTERM
        self.hCNF  = _termObj.hCNF
        self.minimum_number_of_ticks_to_get = 0
        self.period_array_maximum = 0
        for _periodArray in self.hCNF.cf_config['ARGS']['PERIODS']:
            self.period_array_maximum = max( self.period_array_maximum, int(np.array(_periodArray).max()) )
        self.minimum_number_of_ticks_to_get = int(self.period_array_maximum*2+2) 
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
        
        # on a Monday (idx=>0) just go back to 01AM same Monday latest
        if ( 0 == self.gDtTo.weekday() ) and ( 0 != self.gDtFrom.weekday() ) :
            self.gDtFrom = datetime( self.gDtTo.year,self.gDtTo.month,self.gDtTo.day, cHourStart, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        
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



class LiveTime(RequestTime):

    def __init__( self, _termObj ):
        super(LiveTime, self ).__init__( _termObj )
        
        self.gVerbose = 0

    
    # TODO find better names
    def update_day( self, _sym ):
    
        self.gDtNow         = datetime.now(self.gTimezoneUTC) + self.gTdOffset
        self.gDtTo          = self.gDtNow
        self.gDtFrom        = datetime( self.gDtTo.year, self.gDtTo.month, self.gDtTo.day, cHourStart, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)
        return self.get_ticks( _sym, True )

    def update_ticks( self, _sym, _multi_factor = 1 ):
    
        self.gDtNow         = datetime.now(self.gTimezoneUTC) + self.gTdOffset
        self.gDtTo          = self.gDtNow
        _timeDelta          = timedelta( seconds=(self.minimum_number_of_ticks_to_get*3*_multi_factor) )   
        self.gDtFrom        = self.gDtTo - _timeDelta
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)
        return self.get_ticks( _sym, False  )




class HistTime(RequestTime):

    def __init__( self, _termObj ):
        super(HistTime, self).__init__( _termObj )
        
        self.gVerbose = 0

    # TODO find better names
    def update_day( self, _sym, _year, _month, _day ):

        self.gDtTo          = datetime( _year, _month, _day, 23, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        self.gDtFrom        = datetime( _year, _month, _day, cHourStart, 0, 0, 0, tzinfo=self.gTimezoneUTC)
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)
        return self.get_ticks( _sym, True )

    def update_ticks( self, _sym, _year, _month, _day, _hour, _min, _sec, _multi_factor = 1 ):
    
        self.gDtTo          = datetime( _year, _month, _day,  _hour, _min, _sec, 0, tzinfo=self.gTimezoneUTC)
        _timeDelta          = timedelta( seconds=(self.minimum_number_of_ticks_to_get*3*_multi_factor) )   
        self.gDtFrom        = self.gDtTo - _timeDelta
        self.gDtTo_epoch_ms = int(self.gDtTo.timestamp()*1000)
        return self.get_ticks( _sym, False  )

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
    #  def term_export_ticks( self, _np_array, _sym, _year, _month, _day ):
    #     
    # =============================================================================
    def term_export_ticks( self, _np_array, _sym, _year, _month, _day ):
    # =============================================================================

        _path = _sprintf("%s\\%04d\\%02d\\%02d", self.hCNF.cf_config['ACCOUNT']['path_hist_db'], _year, _month, _day)
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

    # END def term_export_ticks( self, _np_array, _sym, _year, _month, _day ):
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
        self.cf_config['ARGS']['PERIODS'] = cPeriodArray_0
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
        _fn   = _sprintf("%s\\%s.old.npz", _path, _sym)
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

        gTimezoneUTC = timezone.utc
        gTdOffset= timedelta(hours=3)   # TODO recognise me - summer time 3h and winter time 2h
        gDtNow   = datetime.now(gTimezoneUTC) + gTdOffset
    
        # the minimum numbers of ticks to be retrieved
        _minimum_number_of_ticks_to_get = int((np.array(_periodArray).max()*2+2))

        # Live-Modus
        if 0 == cDay:
            gDtTo = gDtNow
        # History-Modus
        else:
            gDtTo = datetime( cYear, cMonth, cDay, 23, 0, 0, 0, tzinfo=gTimezoneUTC)
        
        # get the whole ticks of the day starting at 01 AM
        if True == _wholeDay:
            gTimeDelta = timedelta( hours=22 )
            gDtFrom = datetime( gDtTo.year,gDtTo.month,gDtTo.day, cHourStart, 0, 0, 0, tzinfo=gTimezoneUTC)

        if False == _wholeDay:
            gTimeDelta = timedelta( seconds=(_minimum_number_of_ticks_to_get*3) )   
            gDtFrom = gDtTo - gTimeDelta

        self.gDtTo_epoch_ms = int(gDtTo.timestamp()*1000)

        #
        # sanity check
        #
        weekDaysMapping = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        
        # on a Monday (idx=>0) just go back to 01AM same Monday latest
        if ( 0 == gDtTo.weekday() ) and ( 0 != gDtFrom.weekday() ) :
            gDtFrom = datetime( gDtTo.year,gDtTo.month,gDtTo.day, cHourStart, 0, 0, 0, tzinfo=gTimezoneUTC)
        
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
# =============================================================================
#  def np_array_shift(xs, n):
#     
# =============================================================================

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

# END def np_array_shift(xs, n):
# =============================================================================



# =============================================================================
#  def MinMaxScaler( _data ):
#     
# =============================================================================
def MinMaxScaler( _data, n = None ):

    """
    # https://machinelearningknowledge.ai/sklearn-feature-scaling-with-standardscaler-minmaxscaler-robustscaler-and-maxabsscaler/?utm_content=cmp-true

    # min max normalization
    sklearn.preprocessing.MinMaxScaler() 
    _npa_norm  = ( x - min(_npa) ) / ( max(_npa) - min( _npa) ) 
    
    # runfile('C:/OneDrive/rfx/git/fuzzyalgo/test/ticks_get_v7.py', wdir='C:/OneDrive/rfx/git/fuzzyalgo/test')
    
    %timeit MinMaxScaler(gNpa1_out['oc_1000'], 10000)
        25.4 ms ± 605 µs per loop (mean ± std. dev. of 7 runs, 10 loops each)

    %timeit MinMaxScaler(gNpa1_out['oc_1000'])
        5.43 ms ± 17.7 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
    """

    _out = None
    
    # https://stackoverflow.com/questions/16807011/python-how-to-identify-if-a-variable-is-an-array-or-a-scalar
    if True == isinstance(_data, np.ndarray):
        _data = pd.Series(_data)
    
    if None == n:
        _min = _data.min()
        _max = _data.max()
        _hl = _max - _min
        _out = np.round((_data-_min)/_hl*100,0)
    else:
        _max = pd.Series(_data).rolling(n).max()
        _min = pd.Series(_data).rolling(n).min()
        _out = np.round(((_data-_min)/(_max-_min))*100,0)
    
    return _out

# END def MinMaxScaler( _data ):
# =============================================================================


# =============================================================================
#  def MaxAbsScaler( _data, n ):
#     
# =============================================================================
def MaxAbsScaler( _data, n = None):
    """Create a triangular membership function with a _data series and its max, min and median"""

    """

    # https://machinelearningknowledge.ai/sklearn-feature-scaling-with-standardscaler-minmaxscaler-robustscaler-and-maxabsscaler/?utm_content=cmp-true

    # min max normalization
    sklearn.preprocessing.MinMaxScaler() 
    _npa_norm  = ( x - min(_npa) ) / ( max(_npa) - min( _npa) ) 

    # MaxAbs scaler
    sklearn.preprocessing.MaxAbsScaler() 
    _npa_norm = x / max( abs ( _npa ))

    # https://stackoverflow.com/questions/17794266/how-to-get-the-highest-element-in-absolute-value-in-a-numpy-matrix
    max( abs ( _npa )) ->
        _npa
        Out[98]: array([  2,   1,   4,   7,   9,   4,   0,  -2, -23])

        max(_npa.min(), _npa.max(), key=abs)
        Out[97]: -23

        _npa/23
        Out[100]: 
        array([ 0.08695652,  0.04347826,  0.17391304,  0.30434783,  0.39130435,
                0.17391304,  0.        , -0.08695652, -1.        ])

    _npa = gNpa1['oc_3600']
    norm_df = pd.DataFrame( _npa )        
    norm_df['min'] = pd.Series(_npa).rolling(n).min()
    norm_df['max'] = pd.Series(_npa).rolling(n).max()
    norm_df['max_abs'] = np.absolute(pd.Series(_npa).rolling(n).max())
    norm_df['min_abs'] = np.absolute(pd.Series(_npa).rolling(n).min())         
    _norm_npa = norm_df.loc[:, ['max_abs','min_abs']].max(axis=1).to_numpy().astype(np.float64)    
    norm_df['max_of_max_abs_and_min_abs'] = _norm_npa
    norm_df['X'] = _npa
    norm_df['NORM'] = np.round(_npa/_norm_npa*100,0)
    
    Out[283]: array([ nan,  nan,  nan, ..., 32.5, 32.5, 32.5])    
    
    # runfile('C:/OneDrive/rfx/git/fuzzyalgo/test/ticks_get_v7.py', wdir='C:/OneDrive/rfx/git/fuzzyalgo/test')
    
    %timeit MaxAbsScaler(gNpa1_out['oc_1000'], 10000)
        29.7 ms ± 612 µs per loop (mean ± std. dev. of 7 runs, 10 loops each)

    %timeit MaxAbsScaler(gNpa1_out['oc_1000'],)
        5.18 ms ± 24.8 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
    
    """
    
    _out = None
    
    # https://stackoverflow.com/questions/16807011/python-how-to-identify-if-a-variable-is-an-array-or-a-scalar
    if True == isinstance(_data, np.ndarray):
        _data = pd.Series(_data)
    
    if None == n:
        _max_abs = max(_data.min(), _data.max(), key=abs)
        _out = np.round( _data / _max_abs * 100, 0 )
        
    else:
        norm_df = pd.DataFrame( _data )        
        norm_df['max_abs'] = np.absolute(pd.Series(_data).rolling(n).max())
        norm_df['min_abs'] = np.absolute(pd.Series(_data).rolling(n).min())         
        _norm_npa = norm_df.loc[:, ['max_abs','min_abs']].max(axis=1).to_numpy().astype(np.float64)    
        _out = np.round(_data/_norm_npa*100,0)
    
    return _out

# END def MaxAbsScaler( _data, n ):
# =============================================================================



# =============================================================================
#  def get_fuzzy_membership( _data, data_step = 0.1 ):
#     
# =============================================================================
def get_fuzzy_membership( _data, data_step = 0.1 ):
    """Create a triangular membership function with a _data series and its max, min and median"""
    
    low        = _data.min()
    high       = _data.max()
    mid        = np.median(np.arange(low, high, data_step))   
    universe   = np.arange (np.floor(low), np.ceil(high), data_step)
    trimf_lowE = fuzz.trimf(universe, [ low, low,  mid])
    trimf_low  = fuzz.trimf(universe, [ low, (low+mid)/2, mid])
    trimf_mid  = fuzz.trimf(universe, [ low, mid,  high])
    trimf_high = fuzz.trimf(universe, [ mid, (mid+high)/2, high])
    trimf_highE= fuzz.trimf(universe, [ mid, high, high])

    """Assign fuzzy membership to each observation in the _data series and return a dataframe of the result"""
    
    new_df = pd.DataFrame(_data)
    new_df['-2'] = fuzz.interp_membership(universe, trimf_lowE, _data)
    new_df['-1'] = fuzz.interp_membership(universe, trimf_low,  _data)
    new_df[ '0'] = fuzz.interp_membership(universe, trimf_mid,  _data)
    new_df['+1'] = fuzz.interp_membership(universe, trimf_high, _data)
    new_df['+2'] = fuzz.interp_membership(universe, trimf_highE,_data)
    #new_df['membership'] = new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1)
    ## for np ->  new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1).to_numpy().astype(np.float64)
    #new_df['degree'] = new_df.loc[:, ['-2', '-1', '0', '+1', '+2']].max(axis = 1)
    ## for np ->  new_df.loc[:, ['-2', '-1', '0', '+1', '+2']].max(axis = 1).to_numpy()
    #return new_df
    return new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1).to_numpy().astype(np.float64)

# END def get_fuzzy_membership( _data, data_step = 0.1 ):
# =============================================================================


# =============================================================================
#  def MainFunction( _sym, _periodArray, _npa, gH ):
#     
# =============================================================================
def MainFunction( _sym, _periodArray, _npa, gH ):

    #global gH
    #global gNpa
    #global gDict
    
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
    for n in _periodArray:
        # add cnt_n
        _names.append('cnt_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_d_s')
    _formats.append(np.dtype('<S3')) 
    for n in _periodArray:
        # add d_s_n
        _names.append('d_s_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_d_sf')
    _formats.append(np.dtype('<S3')) 
    for n in _periodArray:
        # add d_sf_n
        _names.append('d_sf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_cnt_d_s')
    _formats.append(np.dtype('<S7')) 
    for n in _periodArray:
        # add cnt/d_s_n
        _names.append('cnt_d_s_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_oc')
    _formats.append(np.dtype('<S2')) 
    for n in _periodArray:
        # add oc_n
        _names.append('oc_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_ocf')
    _formats.append(np.dtype('<S3')) 
    for n in _periodArray:
        # add oc_n
        _names.append('ocf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_hl')
    _formats.append(np.dtype('<S2')) 
    for n in _periodArray:
        # add hl_n
        _names.append('hl_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_oc_hl')
    _formats.append(np.dtype('<S5')) 
    for n in _periodArray:
        # add oc/hl_n
        _names.append('oc_hl_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_priced')
    _formats.append(np.dtype('<S6')) 
    for n in _periodArray:
        # add priced
        _names.append('priced_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_pricedf')
    _formats.append(np.dtype('<S7')) 
    for n in _periodArray:
        # add pricedf
        _names.append('pricedf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_spread')
    _formats.append(np.dtype('<S6')) 
    for n in _periodArray:
        # add spread
        _names.append('spread_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_tdmsc')
    _formats.append(np.dtype('<S5')) 
    for n in _periodArray:
        # add tdmsc
        _names.append('tdmsc_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'


    _names.append('B_mean')
    _formats.append(np.dtype('<S4')) 

    _names.append('cnt_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('d_s_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('d_sf_mean')
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
    _names.append('d_sf_median')
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
    for n in _periodArray:

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
    for n in _periodArray:
        gNpa['cnt_'+str(n)]  = n 
    
    gNpa['B_d_s']  = 'd_s'
    for n in _periodArray:
        gNpa['d_s_'+str(n)]  = (( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift( n ) ) / 1000 )
        #_d_s = pd.Series(gNpa['d_s_'+str(n)])
        #gNpa['d_sf_'+str(n)]  = MinMaxScaler( _d_s )

    gNpa['B_cnt_d_s']  = 'cnt/d_s'
    for n in _periodArray:
        gNpa['cnt_d_s_'+str(n)]  = np.round( gNpa['cnt_'+str(n)] / gNpa['d_s_'+str(n)], decimals = 2 )
        
    gNpa['B_oc']  = 'oc'
    gNpa['B_ocf'] = 'ocf'
    for n in _periodArray:
        _oc  = ( pd.Series(gNpa['price']) - pd.Series(gNpa['price']).shift( n ) ) / gH.point()
        # https://stackoverflow.com/questions/5124376/convert-nan-value-to-zero
        _oc[np.isnan(_oc)] = 0
        gNpa['oc_'+str(n)]   = _oc
        ##gNpa['ocf_'+str(n)]  = get_fuzzy_membership( _oc )
        #gNpa['ocf_'+str(n)]  = MaxAbsScaler( _oc, n )
        
        
    gNpa['B_hl']  = 'hl'
    for n in _periodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['hl_'+str(n)]  = (( pd.Series(gNpa['price']).rolling( n ).max() - pd.Series(gNpa['price']).rolling( n ).min() ) / gH.point() )

    gNpa['B_oc_hl']  = 'oc/hl'
    for n in _periodArray:
        gNpa['oc_hl_'+str(n)]  = np.round( gNpa['oc_'+str(n)] / gNpa['hl_'+str(n)], decimals = 2 )

    gNpa['B_priced']  = 'priced'
    gNpa['B_pricedf']  = 'pricedf'
    for n in _periodArray:
        #_priced = np.round(((pd.Series(gNpa['price']) - (pd.Series(gNpa['price']).rolling( n ).max() + pd.Series(gNpa['price']).rolling( n ).min())/2))/gH.point(), decimals=0)
        _npaPrice0 = gNpa['price'][0]
        _nPAoffset = _npaPrice0 * np.ones(len(gNpa))
        _priced = (gNpa['price'] - _nPAoffset)/gH.point()  # gNpaRealTrack
        # https://stackoverflow.com/questions/5124376/convert-nan-value-to-zero
        _priced[np.isnan(_priced)] = 0
        gNpa['priced_'+str(n)]   = _priced
        #gNpa['pricedf_'+str(n)]  = get_fuzzy_membership( _priced )
        gNpa['pricedf_'+str(n)]  = MaxAbsScaler( _priced, n )


    gNpa['B_spread']  = 'spread'
    for n in _periodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['spread_'+str(n)]  = pd.Series(gNpa['spread']).rolling( n ).max() 

    gNpa['B_tdmsc']  = 'tdmsc'
    for n in _periodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['tdmsc_'+str(n)]  = pd.Series(gNpa['tdmsc']).rolling( n ).max() 



    gNpa['B_mean']  = 'mean'

    per_arr_str = []
    for n in _periodArray: 
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
    for n in _periodArray: 
        per_arr_str.append('d_s_'+str(n))
    gNpa['d_s_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('d_sf_'+str(n))
    gNpa['d_sf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('cnt_d_s_'+str(n))
    gNpa['cnt_d_s_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )
    
    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_'+str(n))
    gNpa['oc_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('ocf_'+str(n))
    gNpa['ocf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('hl_'+str(n))
    gNpa['hl_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_hl_'+str(n))
    gNpa['oc_hl_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('priced_'+str(n))
    gNpa['priced_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('pricedf_'+str(n))
    gNpa['pricedf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('spread_'+str(n))
    gNpa['spread_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('tdmsc_'+str(n))
    gNpa['tdmsc_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 




    gNpa['B_median']  = 'median'

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('cnt_'+str(n))
    gNpa['cnt_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('d_s_'+str(n))
    gNpa['d_s_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('d_sf_'+str(n))
    gNpa['d_sf_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('cnt_d_s_'+str(n))
    gNpa['cnt_d_s_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )
    
    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_'+str(n))
    gNpa['oc_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('ocf_'+str(n))
    gNpa['ocf_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('hl_'+str(n))
    gNpa['hl_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_hl_'+str(n))
    gNpa['oc_hl_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('priced_'+str(n))
    gNpa['priced_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('pricedf_'+str(n))
    gNpa['pricedf_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('spread_'+str(n))
    gNpa['spread_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
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

    # _headerStr =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 
    # print( _headerStr )
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


    if 0 < gH.verbose(): 

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
    
    return gNpa

# END def MainFunction( _sym, _periodArray, _npa, gH ):
# =============================================================================










































































# =============================================================================
#  def Term_MainFunction( _sym, _periodArray, _npa, _timeObj ):
#     
# =============================================================================
def Term_MainFunction( _sym, _periodArray, _npa, _timeObj ):
# =============================================================================

    _dtTo_epoch_ms = _timeObj.gDtTo_epoch_ms
    _digits = _timeObj.hCNF.cf_config['SYMBOLS'][_sym]['digits']
    _point  = _timeObj.hCNF.cf_config['SYMBOLS'][_sym]['points']
    _account_name = _timeObj.hCNF.cf_config['ACCOUNT']['account_name']
    _verbose = _timeObj.verbose() 
    _dtTo_epoch_ms = _timeObj.gDtTo_epoch_ms
    _deltaMs1 = _timeObj.gDeltaMs1

    #global gH
    gH = None
    #global gNpa
    #global gDict
    gDict = None
    
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
    for n in _periodArray:
        # add cnt_n
        _names.append('cnt_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_d_s')
    _formats.append(np.dtype('<S3')) 
    for n in _periodArray:
        # add d_s_n
        _names.append('d_s_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_d_sf')
    _formats.append(np.dtype('<S3')) 
    for n in _periodArray:
        # add d_sf_n
        _names.append('d_sf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_cnt_d_s')
    _formats.append(np.dtype('<S7')) 
    for n in _periodArray:
        # add cnt/d_s_n
        _names.append('cnt_d_s_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_oc')
    _formats.append(np.dtype('<S2')) 
    for n in _periodArray:
        # add oc_n
        _names.append('oc_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_ocf')
    _formats.append(np.dtype('<S3')) 
    for n in _periodArray:
        # add oc_n
        _names.append('ocf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_hl')
    _formats.append(np.dtype('<S2')) 
    for n in _periodArray:
        # add hl_n
        _names.append('hl_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_oc_hl')
    _formats.append(np.dtype('<S5')) 
    for n in _periodArray:
        # add oc/hl_n
        _names.append('oc_hl_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_priced')
    _formats.append(np.dtype('<S6')) 
    for n in _periodArray:
        # add priced
        _names.append('priced_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_pricedf')
    _formats.append(np.dtype('<S7')) 
    for n in _periodArray:
        # add pricedf
        _names.append('pricedf_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_spread')
    _formats.append(np.dtype('<S6')) 
    for n in _periodArray:
        # add spread
        _names.append('spread_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'

    _names.append('B_tdmsc')
    _formats.append(np.dtype('<S5')) 
    for n in _periodArray:
        # add tdmsc
        _names.append('tdmsc_'+str(n))
        _formats.append(np.dtype(np.float64))   #  '<f8'


    _names.append('B_mean')
    _formats.append(np.dtype('<S4')) 

    _names.append('cnt_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('d_s_mean')
    _formats.append(np.dtype(np.float64))   #  '<f8'
    _names.append('d_sf_mean')
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
    _names.append('d_sf_median')
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
    gNpa['spread'] = ( gNpa['ask'] - gNpa['bid'] ) / _point 
    gNpa['tdmsc']  = ( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift(1) ) 
    #gNpa['tdmsc']  = ( gNpa['time_msc'] - np_array_shift(gNpa['time_msc'] , +1)  )
    # TODO don't set to zero for fooling min() function 
    # otherwise the index -1 will always be the minimum if set to zero
    # also don't set to NaN - otherwise the NaN check does not work
    gNpa['tdmsc'][0] = 0

    """
    for n in _periodArray:

        gNpa['cnt_'+str(n)]  = n 

        gNpa['d_s_'+str(n)]  = np.round(( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift( n ) ) / 1000)

        gNpa['cnt/d_s_'+str(n)]  = np.round( gNpa['cnt_'+str(n)] / gNpa['d_s_'+str(n)], decimals = 2 )
        

        gNpa['oc_'+str(n)]  = ( pd.Series(gNpa['price']) - pd.Series(gNpa['price']).shift( n ) ) / _point
        # oc = int( round( ( gNpa['price'][0] - gNpa['price'][-1] ) / _point, 0 ) )
        
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['hl_'+str(n)]  = (( pd.Series(gNpa['price']).rolling( n ).max() - pd.Series(gNpa['price']).rolling( n ).min() ) / _point )

        gNpa['oc/hl_'+str(n)]  = np.round( gNpa['oc_'+str(n)] / gNpa['hl_'+str(n)], decimals = 2 )
    """

    gNpa['B_cnt']  = 'cnt'
    for n in _periodArray:
        gNpa['cnt_'+str(n)]  = n 
    
    gNpa['B_d_s']  = 'd_s'
    for n in _periodArray:
        gNpa['d_s_'+str(n)]  = (( pd.Series(gNpa['time_msc']) - pd.Series(gNpa['time_msc']).shift( n ) ) / 1000 )
        #_d_s = pd.Series(gNpa['d_s_'+str(n)])
        #gNpa['d_sf_'+str(n)]  = MinMaxScaler( _d_s )

    gNpa['B_cnt_d_s']  = 'cnt/d_s'
    for n in _periodArray:
        gNpa['cnt_d_s_'+str(n)]  = np.round( gNpa['cnt_'+str(n)] / gNpa['d_s_'+str(n)], decimals = 2 )
        
    gNpa['B_oc']  = 'oc'
    gNpa['B_ocf'] = 'ocf'
    for n in _periodArray:
        _oc  = ( pd.Series(gNpa['price']) - pd.Series(gNpa['price']).shift( n ) ) / _point
        # https://stackoverflow.com/questions/5124376/convert-nan-value-to-zero
        _oc[np.isnan(_oc)] = 0
        gNpa['oc_'+str(n)]   = _oc
        ##gNpa['ocf_'+str(n)]  = get_fuzzy_membership( _oc )
        #gNpa['ocf_'+str(n)]  = MaxAbsScaler( _oc, n )
        
    gNpa['B_hl']  = 'hl'
    for n in _periodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['hl_'+str(n)]  = (( pd.Series(gNpa['price']).rolling( n ).max() - pd.Series(gNpa['price']).rolling( n ).min() ) / _point )

    gNpa['B_oc_hl']  = 'oc/hl'
    for n in _periodArray:
        gNpa['oc_hl_'+str(n)]  = np.round( gNpa['oc_'+str(n)] / gNpa['hl_'+str(n)], decimals = 2 )

    gNpa['B_priced']  = 'priced'
    gNpa['B_pricedf']  = 'pricedf'
    for n in _periodArray:
        #_priced = np.round(((pd.Series(gNpa['price']) - (pd.Series(gNpa['price']).rolling( n ).max() + pd.Series(gNpa['price']).rolling( n ).min())/2))/_point, decimals=0)
        _npaPrice0 = gNpa['price'][0]
        _nPAoffset = _npaPrice0 * np.ones(len(gNpa))
        _priced = (gNpa['price'] - _nPAoffset)/_point # gNpaRealTrack
        gNpa['priced_'+str(n)]   = _priced
        # https://stackoverflow.com/questions/5124376/convert-nan-value-to-zero
        _priced[np.isnan(_priced)] = 0
        ##gNpa['pricedf_'+str(n)]  = get_fuzzy_membership( _priced )
        gNpa['pricedf_'+str(n)]  = MaxAbsScaler( _priced, n )


    gNpa['B_spread']  = 'spread'
    for n in _periodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['spread_'+str(n)]  = pd.Series(gNpa['spread']).rolling( n ).max() 

    gNpa['B_tdmsc']  = 'tdmsc'
    for n in _periodArray:
        # https://stackoverflow.com/questions/43288542/max-in-a-sliding-window-in-numpy-array
        gNpa['tdmsc_'+str(n)]  = pd.Series(gNpa['tdmsc']).rolling( n ).max() 



    gNpa['B_mean']  = 'mean'

    per_arr_str = []
    for n in _periodArray: 
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
    for n in _periodArray: 
        per_arr_str.append('d_s_'+str(n))
    gNpa['d_s_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('d_sf_'+str(n))
    gNpa['d_sf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('cnt_d_s_'+str(n))
    gNpa['cnt_d_s_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )
    
    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_'+str(n))
    gNpa['oc_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('ocf_'+str(n))
    gNpa['ocf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('hl_'+str(n))
    gNpa['hl_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_hl_'+str(n))
    gNpa['oc_hl_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('priced_'+str(n))
    gNpa['priced_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('pricedf_'+str(n))
    gNpa['pricedf_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('spread_'+str(n))
    gNpa['spread_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('tdmsc_'+str(n))
    gNpa['tdmsc_'+'mean'] = np.round( np.mean( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1), decimals = 0 ) 




    gNpa['B_median']  = 'median'

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('cnt_'+str(n))
    gNpa['cnt_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('d_s_'+str(n))
    gNpa['d_s_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('d_sf_'+str(n))
    gNpa['d_sf_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('cnt_d_s_'+str(n))
    gNpa['cnt_d_s_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )
    
    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_'+str(n))
    gNpa['oc_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('ocf_'+str(n))
    gNpa['ocf_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('hl_'+str(n))
    gNpa['hl_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('oc_hl_'+str(n))
    gNpa['oc_hl_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 2 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('priced_'+str(n))
    gNpa['priced_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('pricedf_'+str(n))
    gNpa['pricedf_'+'median'] = np.round( np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1 ), decimals = 0 )

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('spread_'+str(n))
    gNpa['spread_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)

    per_arr_str = []
    for n in _periodArray: 
        per_arr_str.append('tdmsc_'+str(n))
    gNpa['tdmsc_'+'median'] = np.median( pd.DataFrame( gNpa[ per_arr_str ] ).to_numpy(), axis = 1)


    # gDf  = pd.DataFrame(gNpa)
    # gDf['time']=pd.to_datetime(gDf['time_msc'], unit='ms')
    # gDf['price']  = round(( gDf.ask + gDf.bid ) / 2,       5 )
    # gDf['spread'] = ( gDf.ask - gDf.bid ) / _point
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
    # gDf['spread'] = ( gDf.ask - gDf.bid ) / _point
    # gDf['tdmsc']  = (gDf.time_msc - gDf.shift(-1).time_msc)

    # idxstart = gDf.index[0]
    # idxend = gDf.index[-1]
    # gDf.loc[idxend,'tdmsc'] = 0

    # # TODO build WATCHER when has the last tick occured
    _TimeLastTickMS = _dtTo_epoch_ms - gNpa['time_msc'][0]
    _deltams = int((time.time()-_start)*1000)
    _deltams2 = _deltams

    if 0 < _verbose: 
        print( "\nlen(gNpa) ", len(gNpa), " deltams(gNpa): ", _deltams, " _TimeLastTickMS: ", _TimeLastTickMS, "\n", gNpa )

    #
    # time
    #
    # https://numpy.org/doc/stable/reference/arrays.datetime.html
    tnow = np.array(_dtTo_epoch_ms).astype('datetime64[ms]')
    topen=gNpa['time_msc'][0].astype('datetime64[ms]')
    tclose=gNpa['time_msc'][-1].astype('datetime64[ms]')
    d_s = int((  gNpa['time_msc'][0] - gNpa['time_msc'][-1])/1000)
    if 0 < _verbose: 
        print()
        print( _sym, "TIME ", _TimeLastTickMS, "ms" 
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
    oc = int( round( ( gNpa['price'][0] - gNpa['price'][-1] ) / _point, 0 ) )

    if 0 < _verbose: 
        print( _sym, "PRICE  OC: ", oc, " open: ", gNpa['price'][0], "@", topen, " close: ", gNpa['price'][-1] , "@", tclose )


    #
    # price HL
    #
    idxmax=gNpa['price'].argmax(axis=0)
    idxmin=gNpa['price'].argmin(axis=0)
    thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
    tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
    hl =  int( round( ( gNpa['price'][idxmax] - gNpa['price'][idxmin] ) / _point, 0 ) )

    if 0 < _verbose: 
        print( _sym, "PRICE  HL: ", hl, " high: ", gNpa['price'][idxmax], "@", thigh, " low: ", gNpa['price'][idxmin] , "@", tlow )

    #
    # spread HL
    #
    idxmax=gNpa['spread'].argmax(axis=0)
    idxmin=gNpa['spread'].argmin(axis=0)
    spread_thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
    spread_tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
    spread_hl =  gNpa['spread'][idxmax] - gNpa['spread'][idxmin]

    if 0 < _verbose: 
        print( _sym, "SPREAD HL: ", spread_hl, " high: ", gNpa['spread'][idxmax], "@", spread_thigh, " low: ", gNpa['spread'][idxmin] , "@", spread_tlow )

    #
    # tdmsc HL
    #
    idxmax=gNpa['tdmsc'].argmax(axis=0)
    idxmin=gNpa['tdmsc'].argmin(axis=0)
    tdmsc_thigh=gNpa['time_msc'][idxmax].astype('datetime64[ms]')
    tdmsc_tlow =gNpa['time_msc'][idxmin].astype('datetime64[ms]')
    tdmsc_hl =  gNpa['tdmsc'][idxmax] - gNpa['tdmsc'][idxmin]

    if 0 < _verbose: 
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
    gNpaRealTrack = (gNpa['price'] - gNPAoffset)/_point

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

    if 0 < _verbose: 
        outstr = _sprintf("\tpcm: %4.2f / %4.1f - pcmax: %3d", pcmrealraw, pcmreal, pcmaxreal )
        print( outstr )


    _deltams = int((time.time()-_start0)*1000)

    oc_hl = 0
    if 0 != hl:
        oc_hl = round((oc/hl),1)
    lent_d_s = 0
    if 0 != d_s:
        lent_d_s = round(lent/d_s,1)

    # _headerStr =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 
    # print( _headerStr )
    # SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl
    # EURUSD   837    670   -147    -0.2   -0.4   79574   62388      1.3        42          1         20         36    
    _strc = _sprintf( "%s %5d  %5d  %5d    %+0.1f   %+0.1f  %6d  %6d      %0.1f     %5d      %5d      %5d      %5d", 
                    _sym,
                    _TimeLastTickMS,
                    hl,     
                    oc,
                    oc_hl,
                    pcmreal,
                    lent,
                    d_s,
                    lent_d_s,
                    _deltams,
                    _deltaMs1,
                    _deltams2,
                    spread_hl
              )
    print( _strc )


    if 0 < _verbose: 

        gFontSize = 10
        gLabelXstr        = "X"
        gLabelYstr        = "Y"


        tclose = gNpa['time_msc'][-1].astype('datetime64[ms]')
        topen = gNpa['time_msc'][0].astype('datetime64[ms]')

        fig = plt.figure()
        gTitleStr = ""
        gTitleStr = _sprintf("%s %d %s ( %s - %s )",\
          _account_name, len(_npa), _sym, str(topen), str(tclose) )
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
    
    return gNpa

# END def Term_MainFunction( _sym, _periodArray, _npa, _timeObj ):
# =============================================================================


gNpa1_out = None
gNpa2_out = None
gNpa3_out = None
gNpa4_out = None



# =============================================================================
#  def test_live():
#     
# =============================================================================
def test_live():

    global cDay
    if 0 != cDay:
        cDay = 0

    global gNpa1_out, gNpa2_out, gNpa3_out, gNpa4_out
    
    #
    #
    #

    _headerStr =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 


    # global handle gH to old algotrader object
    gH = MT5(cAccount, cSym)
    gH.mt5_init()

    # global handle to new object
    gConf = Mt5LiveConfig(cAccount, [cSym], [cPeriodArray_0])
    gTerm = MT5LiveTerminal( gConf )
    gTime = LiveTime( gTerm )

    # get ticks - cPeriodArray_0.max()
    _npa1 = gTime.update_ticks(cSym)
    _npa3 = gH.mt5_get_ticks( cSym, cPeriodArray_0  )
    print( 'update_ticks - from: ', gTime.gDtFrom, '  to: ', gTime.gDtTo, " len: ", len(_npa1) )
    _cmp1 = ((_npa1==_npa3).all())
    print("\tlen: ",len(_npa3), " cmp OK: ", _cmp1, _npa3[0])
    if False == _cmp1:
        raise( ValueError(" !!! _npa1 !=_ npa3 ") )


    # get ticks - wholeDay = True
    _npa2 = gTime.update_day(cSym)
    _npa4 = gH.mt5_get_ticks( cSym, cPeriodArray_0, True )
    print( 'update_day   - from: ', gTime.gDtFrom, '  to: ', gTime.gDtTo, " len: ", len(_npa2) )
    _cmp2 = ((_npa2==_npa4).all())
    print("\tlen: ",len(_npa4), " cmp OK: ", _cmp2, _npa4[0])
    if False == _cmp2:
        raise( ValueError(" !!! _npa2 !=_ npa4 ") )


    # cnt order sizes and compare between the systems
    _mt5_orders1, _abc1 = gTerm.term_cnt_orders_and_positions( cSym, 1.08070 )
    _profit1  = _mt5_orders1['order_pos_buy_profit']  + _mt5_orders1['order_pos_sell_profit']

    _mt5_orders2, _abc2 = gH.mt5_cnt_orders_and_positions( 1.08070 )
    _profit2  = _mt5_orders2['order_pos_buy_profit']  + _mt5_orders2['order_pos_sell_profit']

    if _mt5_orders1 != _mt5_orders2:
        raise( ValueError(" !!! _mt5_orders1 != _mt5_orders2 ") )

    #if _abc1 != _abc2:
    #    raise( ValueError(" !!! _abc1 != _abc2 ") )

    if _profit1 != _profit2:
        raise( ValueError(" !!! _profit1 != _profit2 ") )


    print()
    print( _headerStr )
    print()
    _npa1_out = Term_MainFunction( cSym, cPeriodArray_0, _npa1, gTime)
    _npa2_out = Term_MainFunction( cSym, cPeriodArray_0, _npa2, gTime)
    print()
    print( _headerStr )
    print()



    print()
    print( _headerStr )
    print()
    _npa3_out = MainFunction( cSym, cPeriodArray_0, _npa3, gH)
    _npa4_out = MainFunction( cSym, cPeriodArray_0, _npa4, gH)
    print()
    print( _headerStr )
    print()

    #gNpa1_out = pd.DataFrame(_npa1_out)
    #gNpa2_out = pd.DataFrame(_npa2_out)
    #gNpa3_out = pd.DataFrame(_npa3_out)
    #gNpa4_out = pd.DataFrame(_npa4_out)

    gNpa1_out = _npa1_out
    gNpa2_out = _npa2_out
    gNpa3_out = _npa3_out
    gNpa4_out = _npa4_out

    # compare numpy arrays  -  note: NAN comparison makes a false result  
    # https://stackoverflow.com/questions/10580676/comparing-two-numpy-arrays-for-equality-element-wise
    _len1 = len(_npa1_out) - gTime.period_array_maximum
    _len1 = gTime.period_array_maximum
    _cmp1 = ((_npa1_out[:_len1]==_npa3_out[:_len1]).all())
    print("_npa1_out len: ",len(_npa1_out), " cmp OK: ", _cmp1, _npa1_out[0])
    if False == _cmp1:
        raise( ValueError(" !!! _npa1_out !=_npa3_out ") )

    _len2 = len(_npa2_out) - gTime.period_array_maximum
    _len2 = gTime.period_array_maximum
    _cmp2 = ((_npa2_out[:_len2]==_npa4_out[:_len2]).all())
    print("_npa2_out len: ",len(_npa2_out), " cmp OK: ", _cmp2, _npa2_out[0])
    if False == _cmp2:
        raise( ValueError(" !!! _npa2_out !=_ npa4_out ") )

    _len3 = len(_npa3_out) - gTime.period_array_maximum
    _len3 = gTime.period_array_maximum
    _cmp3 = ((_npa2_out[:_len3]==_npa3_out[:_len3]).all())
    print("_npa3_out len: ",len(_npa3_out), " cmp OK: ", _cmp3, _npa3_out[0])
    #if False == _cmp3:
    #    raise( ValueError(" !!! _npa3_out !=_npa4_out ") )

    """
    #
    # export gNpa to CSV
    #
    pd.DataFrame( _npa1_out ).to_csv('_npa1_out.csv')
    pd.DataFrame( _npa2_out ).to_csv('_npa2_out.csv')
    pd.DataFrame( _npa3_out ).to_csv('_npa3_out.csv')
    pd.DataFrame( _npa4_out ).to_csv('_npa4_out.csv')
    """
    

    #
    # test code I
    #

    _o = LiveTime( gTerm )
    _npa1 = _o.update_day(cSym)
    print( 'from: ', _o.gDtFrom, '  to: ', _o.gDtTo )
    _npa2 = gH.mt5.copy_ticks_range( gH.gSymbol, _o.gDtFrom, _o.gDtTo , gH.mt5.COPY_TICKS_ALL)
    print("len: ",len(_npa1), " cmp OK: ", ((_npa1==_npa2).all()), _npa1[0])


    #
    # test code II
    #
    _o = LiveTime( gTerm )
    _npa1 = _o.update_ticks(cSym)
    print( 'from: ', _o.gDtFrom, '  to: ', _o.gDtTo )
    _npa2 = gH.mt5_get_ticks( cSym, cPeriodArray_0  )
    print("len: ",len(_npa1), " cmp OK: ", ((_npa1==_npa2).all()), _npa1[0])

    #
    # test code III
    #
    _o = HistTime( gTerm )
    _npa1 = _o.update_day( cSym, 2023, 6, 9 )
    gTerm.term_export_ticks( _npa1, gH.gSymbol, 2023, 6, 9 )
    print( 'from: ', _o.gDtFrom, '  to: ', _o.gDtTo )
    _npa2 = gH.mt5.copy_ticks_range( gH.gSymbol, _o.gDtFrom, _o.gDtTo , gH.mt5.COPY_TICKS_ALL)
    gH.mt5_export_ticks( _npa2, gH.gSymbol, 2023, 6, 9 )
    print("len: ",len(_npa1), " cmp OK: ", ((_npa1==_npa2).all()), _npa1[0])

    #
    # test code IV
    #
    _o = HistTime( gTerm )
    _npa1 = _o.update_ticks( cSym, 2023, 6, 9, 12, 0, 0 )
    print( 'from: ', _o.gDtFrom, '  to: ', _o.gDtTo )
    _npa2 = gH.mt5_get_ticks( cSym, cPeriodArray_0  )
    print("len: ",len(_npa1), " cmp OK: ", ((_npa1==_npa2).all()), _npa1[0])

# END def test_live():
# =============================================================================
    
    
# =============================================================================
#  def test_hist():
#     
# =============================================================================
def test_hist():

    global cDay
    if 0 == cDay:
        cDay = 23

    _year = cYear
    _month = cMonth
    _day = cDay

    _headerStr =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 
    
    # global handle gH to old algotrader object
    gH = MT5(cAccount, cSym)
    gH.mt5_init()

    # global handle to new object
    gConf = Mt5LiveConfig(cAccount, [cSym], [cPeriodArray_0])
    gTerm = MT5LiveTerminal( gConf )
    #_o = LiveTime( gTerm )

    #
    # test code III
    #
    _o = HistTime( gTerm )
    _npa1 = _o.update_day( cSym, _year, _month, _day )
    gTerm.term_export_ticks( _npa1, gH.gSymbol, _year, _month, _day )
    print( 'from: ', _o.gDtFrom, '  to: ', _o.gDtTo )
    #_npa2 = gH.mt5.copy_ticks_range( gH.gSymbol, _o.gDtFrom, _o.gDtTo , gH.mt5.COPY_TICKS_ALL)
    _npa2 = gH.mt5_get_ticks( cSym, cPeriodArray_0, True )
    gH.mt5_export_ticks( _npa2, gH.gSymbol, _year, _month, _day )
    print("len: ",len(_npa1), " cmp OK: ", ((_npa1==_npa2).all()), _npa1)


    print()
    print( _headerStr )
    print()
    _npa1_out = Term_MainFunction( cSym, cPeriodArray_0, _npa1, _o)
    _npa2_out = MainFunction( cSym, cPeriodArray_0, _npa2, gH)
    print()
    print( _headerStr )
    print()

    # compare numpy arrays  -  note: NAN comparison makes a false result  
    # https://stackoverflow.com/questions/10580676/comparing-two-numpy-arrays-for-equality-element-wise
    _len1 = len(_npa1_out) - _o.period_array_maximum
    _cmp1 = ((_npa1_out[:_len1]==_npa2_out[:_len1]).all())
    print("_npa1_out len: ",len(_npa1_out), " cmp OK: ", _cmp1, _npa1_out[0])
    if False == _cmp1:
        raise( ValueError(" !!! _npa1_out !=_ npa3_out ") )


# END def test_hist():
# =============================================================================



# =============================================================================
#  def main():
#     
# =============================================================================
def main():

    global gNpa1_out, gNpa2_out

    _year = cYear
    _month = cMonth
    _day = cDay
    #_month = 4
    #_day = 27
    _month = 7
    _day = 26
    cSym = 'EURUSD'
    #cSym = 'GBPJPY'
    
    _syma = ['GBPJPY','EURUSD']
    _periodArray_110 = [        3000,2000,1000]
    _periodArray_111 = [        300,200,100]
    _periodArray_112 = [        30,20,10]
    _periodArray_21 = [                 10000                     ]
    _periodArray_32 = [                               1000         ]
    _periodArray_43 = [                                           10]
    _periodArray   = [_periodArray_43]
    cPeriodArray = _periodArray
    


    _headerStr =  "SYMBOL    ms     hl     oc   oc/hl    pcm     cnt     d_s  cnt/d_s  delta_ms  delta_ms1  delta_ms2  spread hl" 
    
    # global handle to new object
    #gConf = Mt5LiveConfig( cAccount, [cSym], cPeriodArray )
    #gTerm = MT5LiveTerminal( gConf )
    #_o = LiveTime( gTerm )
    #_npa1 = _o.update_day( cSym )
    #gTerm.term_export_ticks( _npa1, cSym, _o.gDtTo.year, _o.gDtTo.month, _o.gDtTo.day )


    #gConf = Mt5LiveConfig( cAccount, [cSym], cPeriodArray )
    #gConf = Mt5LiveConfig( cAccount, None, cPeriodArray )
    gConf = Mt5LiveConfig( cAccount, _syma, cPeriodArray )
    gTerm = MT5LiveTerminal( gConf )
    _o = HistTime( gTerm )
    _account_name = _o.hCNF.cf_config['ACCOUNT']['account_name']

    #for cSym in gConf.gSymbolsAll:
    for cSym in gConf.cf_config['ARGS']['SYMBOLS']:
    

        _npa1 = _o.update_day( cSym, _year, _month, _day )
        print( 'from: ', _o.gDtFrom, '  to: ', _o.gDtTo )


        """
        dtype=[('time', '<i8'), ('time_msc', '<i8'), ('np_time_msc', 'S25'), 
                ('bid', '<f8'), ('ask', '<f8'), ('price', '<f8'), ('spread', '<i8'), ('tdmsc', '<i8'), 
            ('B_cnt', 'S3'), ('cnt_60', '<f8'), ('cnt_30', '<f8'), ('cnt_15', '<f8'), 
            ('B_d_s', 'S3'), ('d_s_60', '<f8'), ('d_s_30', '<f8'), ('d_s_15', '<f8'), 
            ('B_cnt_d_s', 'S7'), ('cnt_d_s_60', '<f8'), ('cnt_d_s_30', '<f8'), ('cnt_d_s_15', '<f8'), 
            ('B_oc', 'S2'), ('oc_60', '<f8'), ('oc_30', '<f8'), ('oc_15', '<f8'), 
            ('B_ocf', 'S3'), ('ocf_60', '<f8'), ('ocf_30', '<f8'), ('ocf_15', '<f8'), 
            ('B_hl', 'S2'), ('hl_60', '<f8'), ('hl_30', '<f8'), ('hl_15', '<f8'), 
            ('B_oc_hl', 'S5'), ('oc_hl_60', '<f8'), ('oc_hl_30', '<f8'), ('oc_hl_15', '<f8'), 
            ('B_priced', 'S6'), ('priced_60', '<f8'), ('priced_30', '<f8'), ('priced_15', '<f8'), 
            ('B_pricedf', 'S7'), ('pricedf_60', '<f8'), ('pricedf_30', '<f8'), ('pricedf_15', '<f8'), 
            ('B_spread', 'S6'), ('spread_60', '<f8'), ('spread_30', '<f8'), ('spread_15', '<f8'), 
            ('B_tdmsc', 'S5'), ('tdmsc_60', '<f8'), ('tdmsc_30', '<f8'), ('tdmsc_15', '<f8'), 
            ('B_mean', 'S4'), ('cnt_mean', '<f8'), ('d_s_mean', '<f8'), ('cnt_d_s_mean', '<f8'), ('oc_mean', '<f8'), ('ocf_mean', '<f8'), 
                ('hl_mean', '<f8'), ('oc_hl_mean', '<f8'), ('priced_mean', '<f8'), ('pricedf_mean', '<f8'), ('spread_mean', '<f8'), ('tdmsc_mean', '<f8'), 
            ('B_median', 'S6'), ('cnt_median', '<f8'), ('d_s_median', '<f8'), ('cnt_d_s_median', '<f8'), ('oc_median', '<f8'), ('ocf_median', '<f8'), 
                ('hl_median', '<f8'), ('oc_hl_median', '<f8'), ('priced_median', '<f8'), ('pricedf_median', '<f8'), ('spread_median', '<f8'), ('tdmsc_median', '<f8')]
        """

        _npaa = []

        print()
        print( _headerStr )
        print()

        for per in cPeriodArray:
        
            print(per)
            _npa1_out = Term_MainFunction( cSym, per, _npa1, _o)
            gNpa1_out = _npa1_out
            print()
            
            _len1 = len(_npa1_out) - _o.period_array_maximum
            #_len1 = 15000
            _npaa.append( _npa1_out[:_len1] )
            #_npaa.append( _npa1_out )


        tclose = _npaa[0]['time_msc'][-1].astype('datetime64[ms]')
        topen  = _npaa[0]['time_msc'][0].astype('datetime64[ms]')

        fig = plt.figure()
        gTitleStr = _sprintf("%s %d %s ( %s - %s )",\
          _account_name, len(_npaa[0]), cSym, str(topen), str(tclose) )
        fig.suptitle(gTitleStr, fontsize=10)


        cnt = 0
        for _npa in _npaa:
        
            _npa = np.flip(_npa)
            #_npa = _npa[52200:52400]
            #_npa = _npa[116000:118000]
            #_npa = _npa[54900:55150]
            # 27.04.2023
            #_npa = _npa[54900:55200]
            #_npa = _npa[60000:65000]
            t = np.arange(0, len(_npa), 1)

            if 0 == cnt:
                yp = np.ones(len(_npa))*50
                plt.plot(t, yp, label='+50', linewidth=0.1)
                ym = np.ones(len(_npa))*-50
                plt.plot(t, ym, label='-50', linewidth=0.1)
                #y0 = np.zeros(len(_npa))
                #plt.plot(t, y0, label=None, linewidth=0.5)
                
                key = 'priced_mean'
                ar1 = _npa[key]
                ar2 = -1*_npa[key]
                plt.plot(t, ar1-150,  linewidth=0.2)
                #plt.plot(t, ar2,  linewidth=0.2)
            cnt = cnt+1
            
            _cnt_median = int(_npa[0]['cnt_median'])
            
            #if 1000 == _cnt_median:
            key = 'cnt_d_s_median'
            arcds = np.array( (-100+_npa[key]*20) )
            arcds[arcds<200]=0
            plt.plot(t, arcds, label=key+'_'+str(_cnt_median), linewidth=0.5)
            #key = 'd_s_median'
            ##plt.plot(t, (_npa[key]/10), label=key+'_'+str(_cnt_median), linewidth=0.5)

            #if 1000 < _cnt_median:
            key1 = 'hl_mean'
            key2 = 'oc_mean'
            #plt.plot(t, _npa[key1], linewidth=0.1)
            
            ar01 = np.array(_npa[key2])
            ar02 = np.array(_npa[key2])
            ar01[ar01< 40]=0
            ar02[ar02>-40]=0
            plt.plot(t, ar01, linewidth=0.5)
            plt.plot(t, ar02, linewidth=0.5)


            """
            ar3 = np.array(_npa[key2]+_npa[key1])
            ar4 = np.array(_npa[key2]-_npa[key1])
            ar3[ar3<50]=0
            ar4[ar4>-50]=0
            plt.plot(t, ar3, linewidth=0.5)
            plt.plot(t, ar4, linewidth=0.5)
            """
       
        # for _npa in _npaa:

        plt.xlabel( "X", fontsize=10)
        plt.ylabel( "Y", fontsize=10)
        plt.legend()
        plt.show()
    
    # for cSym in gConf.gSymbolsAll:


# END def main():
# =============================================================================


if __name__ == "__main__":

    main()
    
    #test_live()

    #test_hist()






"""

	2023.06.23 16:44:56   DBG          -       p:1.08934  oc:  -605  s:    -4  t:      0  d:      0 +1.78  oc1:     -1  hl1:      9  dmsc1:   3135  cnt_ds:    -36
	2023.06.23 16:44:56   DBG          -       p:1.08936  oc:  -603  s:    -7  t:      0  d:      0 +1.78  oc1:      0  hl1:      9  dmsc1:   2560  cnt_ds:    -21
	2023.06.23 16:44:59   DBG          -       p:1.08935  oc:  -604  s:    -8  t:      0  d:      0 +1.78  oc1:      1  hl1:      9  dmsc1:   4480  cnt_ds:    -55
	2023.06.23 16:44:59   DBG          -       p:1.08934  oc:  -605  s:    -5  t:      0  d:      0 +1.78  oc1:     -2  hl1:      9  dmsc1:   4256  cnt_ds:    -53
	2023.06.23 16:45:00   DBG          -       p:1.08937  oc:  -602  s:   -11  t:      0  d:      0 +1.78  oc1:      1  hl1:     11  dmsc1:   4577  cnt_ds:    -56
	2023.06.23 16:45:00   DBG          -       p:1.08943  oc:  -596  s:    -1  t:      0  d:      0 +1.78  oc1:     11  hl1:     12  dmsc1:   4576  cnt_ds:    -56
	2023.06.23 16:45:00   DBG          -       p:1.08991  oc:  -548  s:     0  t:      0  d:      0 +1.78  oc1:     58  hl1:     59  dmsc1:   3968  cnt_ds:    -49 BUY
	2023.06.23 16:45:00   DBG          -       p:1.09021  oc:  -518  s:    -5  t:      0  d:      0 +1.78  oc1:     86  hl1:     92  dmsc1:   3970  cnt_ds:    -49
	2023.06.23 16:45:00   DBG          -       p:1.09023  oc:  -516  s:    -8  t:      0  d:      0 +1.78  oc1:     87  hl1:     96  dmsc1:   3586  cnt_ds:    -44
	2023.06.23 16:45:00   DBG          -       p:1.09025  oc:  -514  s:    -2  t:      0  d:      0 +1.78  oc1:     90  hl1:     96  dmsc1:   3585  cnt_ds:    -44
	2023.06.23 16:45:00   DBG          -       p:1.09023  oc:  -516  s:    -4  t:      0  d:      0 +1.78  oc1:     87  hl1:     96  dmsc1:   3552  cnt_ds:    -43 CLOSE
	2023.06.23 16:45:00   DBG          -       p:1.09026  oc:  -513  s:    -5  t:      0  d:      0 +1.78  oc1:     90  hl1:     97  dmsc1:    960  cnt_ds:    108
	2023.06.23 16:45:00   DBG          -       p:1.09023  oc:  -516  s:    -3  t:      0  d:      0 +1.78  oc1:     88  hl1:     97  dmsc1:    960  cnt_ds:    108
	2023.06.23 16:45:00   DBG          -       p:1.09022  oc:  -517  s:    -9  t:      0  d:      0 +1.78  oc1:     85  hl1:     97  dmsc1:    640  cnt_ds:    212
	2023.06.23 16:45:00   DBG          -       p:1.09022  oc:  -517  s:    -5  t:      0  d:      0 +1.78  oc1:     78  hl1:     86  dmsc1:    641  cnt_ds:    212
	2023.06.23 16:45:00   DBG          -       p:1.09021  oc:  -518  s:     0  t:      0  d:      0 +1.78  oc1:     29  hl1:     38  dmsc1:    641  cnt_ds:    212
	2023.06.23 16:45:00   DBG          -       p:1.09022  oc:  -517  s:    -1  t:      0  d:      0 +1.78  oc1:      0  hl1:     11  dmsc1:    640  cnt_ds:    212
	2023.06.23 16:45:00   DBG          -       p:1.09026  oc:  -513  s:    -2  t:      0  d:      0 +1.78  oc1:      2  hl1:     11  dmsc1:    671  cnt_ds:    198
	2023.06.23 16:45:01   DBG          -       p:1.09024  oc:  -515  s:     0  t:      0  d:      0 +1.78  oc1:      0  hl1:     11  dmsc1:    608  cnt_ds:    228
	2023.06.23 16:45:01   DBG          -       p:1.09023  oc:  -516  s:    -4  t:      0  d:      0 +1.78  oc1:      0  hl1:     11  dmsc1:    609  cnt_ds:    228
	2023.06.23 16:45:01   DBG          -       p:1.09026  oc:  -513  s:    -4  t:      0  d:      0 +1.78  oc1:      0  hl1:     11  dmsc1:    608  cnt_ds:    228
	2023.06.23 16:45:01   DBG          -       p:1.09025  oc:  -514  s:    -5  t:      0  d:      0 +1.78  oc1:      2  hl1:     10  dmsc1:    608  cnt_ds:    228
	2023.06.23 16:45:01   DBG          -       p:1.09024  oc:  -515  s:    -4  t:      0  d:      0 +1.78  oc1:      2  hl1:     10  dmsc1:    608  cnt_ds:    228
	2023.06.23 16:45:01   DBG          -       p:1.09024  oc:  -515  s:     0  t:      0  d:      0 +1.78  oc1:      2  hl1:      8  dmsc1:    607  cnt_ds:    229
	2023.06.23 16:45:01   DBG          -       p:1.09027  oc:  -512  s:    -1  t:      0  d:      0 +1.78  oc1:      5  hl1:      7  dmsc1:    607  cnt_ds:    229
	2023.06.23 16:45:01   DBG          -       p:1.09027  oc:  -512  s:    -4  t:      0  d:      0 +1.78  oc1:      5  hl1:      8  dmsc1:    607  cnt_ds:    229
	2023.06.23 16:45:01   DBG          -       p:1.09028  oc:  -511  s:    -6  t:      0  d:      0 +1.78  oc1:      2  hl1:     10  dmsc1:    576  cnt_ds:    247
	2023.06.23 16:45:01   DBG          -       p:1.09028  oc:  -511  s:    -4  t:      0  d:      0 +1.78  oc1:      3  hl1:     10  dmsc1:    608  cnt_ds:    228
	2023.06.23 16:45:01   DBG          -       p:1.09026  oc:  -513  s:    -1  t:      0  d:      0 +1.78  oc1:      2  hl1:     10  dmsc1:    768  cnt_ds:    160
	2023.06.23 16:45:01   DBG          -       p:1.09022  oc:  -517  s:     0  t:      0  d:      0 +1.78  oc1:     -3  hl1:      9  dmsc1:    800  cnt_ds:    150
	2023.06.23 16:45:02   DBG          -       p:1.09022  oc:  -517  s:    -4  t:      0  d:      0 +1.78  oc1:     -2  hl1:     11  dmsc1:    800  cnt_ds:    150
	2023.06.23 16:45:02   DBG          -       p:1.09019  oc:  -520  s:     0  t:      0  d:      0 +1.78  oc1:     -5  hl1:     12  dmsc1:    801  cnt_ds:    149

	2023.07.07 15:29:55   DBG          -       p:1.08839  oc:   -77  s:   -12  t:      0  d:      0 +0.00  oc1:     -1  hl1:     19  dmsc1:   3584  cnt_ds:    -44
	2023.07.07 15:29:58   DBG          -       p:1.08840  oc:   -76  s:   -16  t:      0  d:      0 +0.00  oc1:      2  hl1:     19  dmsc1:   5441  cnt_ds:    -63
	2023.07.07 15:29:58   DBG          -       p:1.08841  oc:   -75  s:   -12  t:      0  d:      0 +0.00  oc1:      3  hl1:     18  dmsc1:   5570  cnt_ds:    -64
	2023.07.07 15:29:59   DBG          -       p:1.08846  oc:   -70  s:   -17  t:      0  d:      0 +0.00  oc1:      6  hl1:     22  dmsc1:   4351  cnt_ds:    -54
	2023.07.07 15:29:59   DBG          -       p:1.08846  oc:   -70  s:   -17  t:      0  d:      0 +0.00  oc1:      4  hl1:     22  dmsc1:   4352  cnt_ds:    -54
	2023.07.07 15:29:59   DBG          -       p:1.08846  oc:   -70  s:   -16  t:      0  d:      0 +0.00  oc1:      5  hl1:     22  dmsc1:   4256  cnt_ds:    -53
	2023.07.07 15:29:59   DBG          -       p:1.08846  oc:   -70  s:   -14  t:      0  d:      0 +0.00  oc1:      7  hl1:     22  dmsc1:   4161  cnt_ds:    -51
	2023.07.07 15:29:59   DBG          -       p:1.08845  oc:   -71  s:   -14  t:      0  d:      0 +0.00  oc1:      6  hl1:     22  dmsc1:   3871  cnt_ds:    -48
	2023.07.07 15:29:59   DBG          -       p:1.08848  oc:   -68  s:    -8  t:      0  d:      0 +0.00  oc1:      9  hl1:     22  dmsc1:   3680  cnt_ds:    -45
	2023.07.07 15:29:59   DBG          -       p:1.08873  oc:   -43  s:   -62  t:      0  d:      0 +0.00  oc1:     34  hl1:     72  dmsc1:   3648  cnt_ds:    -45
	2023.07.07 15:29:59   DBG          - BUY   p:1.08892  oc:   -24  s:   -94  t:      0  d:     94 -0.86  oc1:     51  hl1:    107  dmsc1:   1567  cnt_ds:     27  BUY
	2023.07.07 15:29:59   DBG          - BUY   p:1.08900  oc:   -16  s:   -99  t:      0  d:     89 -0.82  oc1:     58  hl1:    114  dmsc1:   1375  cnt_ds:     45
	2023.07.07 15:30:00   DBG          - BUY   p:1.08918  oc:     2  s:   -99  t:      1  d:     70 -0.65  oc1:     72  hl1:    130  dmsc1:    961  cnt_ds:    108
	2023.07.07 15:30:00   DBG          - BUY   p:1.08962  oc:    46  s:   -99  t:      1  d:     26 -0.25  oc1:    116  hl1:    174  dmsc1:   1121  cnt_ds:     78
	2023.07.07 15:30:00   DBG          - BUY   p:1.08984  oc:    68  s:  -100  t:      1  d:      5 -0.05  oc1:    138  hl1:    196  dmsc1:   1185  cnt_ds:     68
	2023.07.07 15:30:00   DBG          - BUY   p:1.08988  oc:    72  s:   -99  t:      1  d:      1 -0.01  oc1:    141  hl1:    200  dmsc1:   1280  cnt_ds:     56
	2023.07.07 15:30:00   DBG          - BUY   p:1.09021  oc:   105  s:  -100  t:      1  d:    -31 +0.29  oc1:    175  hl1:    233  dmsc1:   1313  cnt_ds:     52
	2023.07.07 15:30:00   DBG          - BUY   p:1.09031  oc:   115  s:   -93  t:      1  d:    -44 +0.41  oc1:    182  hl1:    235  dmsc1:   1280  cnt_ds:     56
	2023.07.07 15:30:00   DBG          - BUY   p:1.09036  oc:   120  s:   -99  t:      1  d:    -46 +0.43  oc1:    163  hl1:    243  dmsc1:   1407  cnt_ds:     42 CLOSE
	2023.07.07 15:30:01   DBG          - BUY   p:1.09011  oc:    95  s:  -100  t:      2  d:    -21 +0.20  oc1:    119  hl1:    241  dmsc1:   1504  cnt_ds:     32
	2023.07.07 15:30:01   DBG          - BUY   p:1.09025  oc:   109  s:   -99  t:      2  d:    -35 +0.33  oc1:    124  hl1:    235  dmsc1:   1505  cnt_ds:     32
	2023.07.07 15:30:01   DBG          - BUY   p:1.09007  oc:    91  s:  -100  t:      2  d:    -17 +0.17  oc1:     88  hl1:    217  dmsc1:   1472  cnt_ds:     35
	2023.07.07 15:30:01   DBG          - BUY   p:1.08957  oc:    41  s:  -100  t:      2  d:     32 -0.29  oc1:     -4  hl1:    178  dmsc1:   1441  cnt_ds:     38
	2023.07.07 15:30:01   DBG          - BUY   p:1.09000  oc:    84  s:  -100  t:      2  d:    -10 +0.10  oc1:     15  hl1:    178  dmsc1:   1567  cnt_ds:     27
	2023.07.07 15:30:02   DBG          - BUY   p:1.09014  oc:    98  s:   -96  t:      3  d:    -25 +0.24  oc1:     25  hl1:    178  dmsc1:   1503  cnt_ds:     33
	2023.07.07 15:30:02   DBG          - BUY   p:1.08958  oc:    42  s:   -99  t:      3  d:     31 -0.28  oc1:    -62  hl1:    178  dmsc1:   1567  cnt_ds:     27 SELL (IGNORE)
	2023.07.07 15:30:02   DBG          - BUY   p:1.09025  oc:   109  s:   -99  t:      3  d:    -35 +0.33  oc1:     -5  hl1:    178  dmsc1:   1824  cnt_ds:      9
	2023.07.07 15:30:02   DBG          - BUY   p:1.09006  oc:    90  s:   -99  t:      3  d:    -17 +0.16  oc1:    -29  hl1:    178  dmsc1:   1857  cnt_ds:      7
	2023.07.07 15:30:02   DBG          - BUY   p:1.09008  oc:    92  s:   -95  t:      3  d:    -20 +0.19  oc1:     -3  hl1:    167  dmsc1:   1792  cnt_ds:     11
	2023.07.07 15:30:03   DBG          - BUY   p:1.09004  oc:    88  s:   -93  t:      4  d:    -17 +0.17  oc1:    -21  hl1:    167  dmsc1:   1728  cnt_ds:     15
	2023.07.07 15:30:03   DBG          - BUY   p:1.09020  oc:   104  s:   -99  t:      4  d:    -31 +0.28  oc1:     13  hl1:    167  dmsc1:   1760  cnt_ds:     13
	2023.07.07 15:30:03   DBG          - BUY   p:1.09013  oc:    97  s:   -99  t:      4  d:    -24 +0.22  oc1:     55  hl1:    167  dmsc1:   1822  cnt_ds:      9 BUY (IGNORE)
	2023.07.07 15:30:03   DBG          - BUY   p:1.09007  oc:    91  s:  -100  t:      4  d:    -17 +0.17  oc1:      7  hl1:    166  dmsc1:   1728  cnt_ds:     15
	2023.07.07 15:30:03   DBG          - BUY   p:1.09008  oc:    92  s:   -95  t:      4  d:    -20 +0.19  oc1:     -6  hl1:    166  dmsc1:   1793  cnt_ds:     11
	2023.07.07 15:30:03   DBG          - BUY   p:1.09009  oc:    93  s:   -87  t:      4  d:    -25 +0.24  oc1:     51  hl1:    166  dmsc1:   1633  cnt_ds:     22 
	2023.07.07 15:30:03   DBG          - BUY   p:1.09007  oc:    91  s:   -80  t:      4  d:    -26 +0.25  oc1:    -18  hl1:    118  dmsc1:   1377  cnt_ds:     45
	2023.07.07 15:30:04   DBG          - BUY   p:1.09009  oc:    93  s:   -84  t:      5  d:    -27 +0.26  oc1:      2  hl1:    113  dmsc1:   1216  cnt_ds:     64
	2023.07.07 15:30:04   DBG          - BUY   p:1.09029  oc:   113  s:   -91  t:      5  d:    -43 +0.40  oc1:     21  hl1:    117  dmsc1:   1185  cnt_ds:     68
	2023.07.07 15:30:04   DBG          - BUY   p:1.09041  oc:   125  s:   -89  t:      5  d:    -56 +0.52  oc1:     37  hl1:    128  dmsc1:   1152  cnt_ds:     73
	2023.07.07 15:30:04   DBG          - BUY   p:1.09041  oc:   125  s:   -85  t:      5  d:    -58 +0.54  oc1:     20  hl1:    128  dmsc1:    991  cnt_ds:    101
	2023.07.07 15:30:04   DBG          - BUY   p:1.09043  oc:   127  s:   -87  t:      5  d:    -59 +0.55  oc1:     29  hl1:    130  dmsc1:    801  cnt_ds:    149
	2023.07.07 15:30:04   DBG          - BUY   p:1.09059  oc:   143  s:   -79  t:      5  d:    -79 +0.73  oc1:     51  hl1:    141  dmsc1:    738  cnt_ds:    171 
	2023.07.07 15:30:04   DBG          - BUY   p:1.09071  oc:   155  s:   -39  t:      5  d:   -112 +1.03  oc1:     63  hl1:    138  dmsc1:    675  cnt_ds:    196
	2023.07.07 15:30:04   DBG          - BUY   p:1.09078  oc:   162  s:   -18  t:      5  d:   -129 +1.19  oc1:     69  hl1:    133  dmsc1:    676  cnt_ds:    195
	2023.07.07 15:30:04   DBG          - BUY   p:1.09081  oc:   165  s:   -17  t:      5  d:   -132 +1.22  oc1:     73  hl1:    131  dmsc1:    708  cnt_ds:    182
	2023.07.07 15:30:04   DBG          - BUY   p:1.09083  oc:   167  s:   -22  t:      5  d:   -132 +1.22  oc1:     73  hl1:    131  dmsc1:    707  cnt_ds:    182
	2023.07.07 15:30:04   DBG          - BUY   p:1.09081  oc:   165  s:   -18  t:      5  d:   -132 +1.22  oc1:     51  hl1:    114  dmsc1:    707  cnt_ds:    182
	2023.07.07 15:30:04   DBG          - BUY   p:1.09093  oc:   177  s:   -11  t:      5  d:   -147 +1.36  oc1:     52  hl1:    102  dmsc1:    707  cnt_ds:    182
	2023.07.07 15:30:04   DBG          - BUY   p:1.09101  oc:   185  s:   -22  t:      5  d:   -150 +1.38  oc1:     60  hl1:    114  dmsc1:    708  cnt_ds:    182
	2023.07.07 15:30:05   DBG          - BUY   p:1.09102  oc:   186  s:   -25  t:      6  d:   -149 +1.38  oc1:     58  hl1:    114  dmsc1:    708  cnt_ds:    182
	2023.07.07 15:30:05   DBG          - BUY   p:1.09098  oc:   182  s:   -15  t:      6  d:   -150 +1.38  oc1:     39  hl1:     95  dmsc1:    643  cnt_ds:    211
	2023.07.07 15:30:05   DBG          - BUY   p:1.09105  oc:   189  s:    -7  t:      6  d:   -161 +1.48  oc1:     33  hl1:     62  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:05   DBG          -       p:1.09158  oc:   242  s:   -26  t:      0  d:      0 +1.48  oc1:     79  hl1:    102  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:05   DBG          -       p:1.09153  oc:   237  s:    -7  t:      0  d:      0 +1.48  oc1:     72  hl1:     99  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:05   DBG          -       p:1.09148  oc:   232  s:     0  t:      0  d:      0 +1.48  oc1:     65  hl1:     99  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:05   DBG          -       p:1.09156  oc:   240  s:    -7  t:      0  d:      0 +1.48  oc1:     75  hl1:     99  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:05   DBG          -       p:1.09165  oc:   249  s:   -11  t:      0  d:      0 +1.48  oc1:     72  hl1:     83  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:05   DBG          -       p:1.09155  oc:   239  s:    -4  t:      0  d:      0 +1.48  oc1:     53  hl1:     82  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:05   DBG          -       p:1.09161  oc:   245  s:    -1  t:      0  d:      0 +1.48  oc1:     58  hl1:     82  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:05   DBG          -       p:1.09159  oc:   243  s:    -9  t:      0  d:      0 +1.48  oc1:     61  hl1:     80  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:05   DBG          -       p:1.09160  oc:   244  s:    -7  t:      0  d:      0 +1.48  oc1:     55  hl1:     69  dmsc1:    609  cnt_ds:    228
	2023.07.07 15:30:05   DBG          -       p:1.09178  oc:   262  s:    -7  t:      0  d:      0 +1.48  oc1:     19  hl1:     36  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:05   DBG          -       p:1.09185  oc:   269  s:    -5  t:      0  d:      0 +1.48  oc1:     31  hl1:     39  dmsc1:    607  cnt_ds:    229
	2023.07.07 15:30:05   DBG          -       p:1.09182  oc:   266  s:   -10  t:      0  d:      0 +1.48  oc1:     33  hl1:     39  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:05   DBG          -       p:1.09172  oc:   256  s:   -18  t:      0  d:      0 +1.48  oc1:     15  hl1:     35  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:06   DBG          -       p:1.09168  oc:   252  s:   -22  t:      0  d:      0 +1.48  oc1:      2  hl1:     35  dmsc1:    672  cnt_ds:    197
	2023.07.07 15:30:06   DBG          -       p:1.09177  oc:   261  s:   -14  t:      0  d:      0 +1.48  oc1:     22  hl1:     35  dmsc1:    672  cnt_ds:    197
	2023.07.07 15:30:06   DBG          -       p:1.09182  oc:   266  s:   -17  t:      0  d:      0 +1.48  oc1:     21  hl1:     36  dmsc1:    672  cnt_ds:    197
	2023.07.07 15:30:06   DBG          -       p:1.09181  oc:   265  s:   -14  t:      0  d:      0 +1.48  oc1:     21  hl1:     36  dmsc1:    640  cnt_ds:    212
	2023.07.07 15:30:06   DBG          -       p:1.09178  oc:   262  s:   -21  t:      0  d:      0 +1.48  oc1:     17  hl1:     34  dmsc1:    640  cnt_ds:    212
	2023.07.07 15:30:06   DBG          -       p:1.09171  oc:   255  s:   -31  t:      0  d:      0 +1.48  oc1:     -6  hl1:     35  dmsc1:    673  cnt_ds:    197
	2023.07.07 15:30:06   DBG          -       p:1.09162  oc:   246  s:   -51  t:      0  d:      0 +1.48  oc1:    -23  hl1:     55  dmsc1:    673  cnt_ds:    197
	2023.07.07 15:30:06   DBG          -       p:1.09150  oc:   234  s:   -60  t:      0  d:      0 +1.48  oc1:    -31  hl1:     71  dmsc1:    704  cnt_ds:    184
	2023.07.07 15:30:06   DBG          -       p:1.09161  oc:   245  s:   -31  t:      0  d:      0 +1.48  oc1:    -10  hl1:     71  dmsc1:    704  cnt_ds:    184
	2023.07.07 15:30:06   DBG          -       p:1.09170  oc:   254  s:   -18  t:      0  d:      0 +1.48  oc1:      2  hl1:     71  dmsc1:    640  cnt_ds:    212
	2023.07.07 15:30:06   DBG          -       p:1.09171  oc:   255  s:   -29  t:      0  d:      0 +1.48  oc1:     -5  hl1:     71  dmsc1:    671  cnt_ds:    198
	2023.07.07 15:30:06   DBG          -       p:1.09166  oc:   250  s:   -19  t:      0  d:      0 +1.48  oc1:    -15  hl1:     71  dmsc1:    704  cnt_ds:    184
	2023.07.07 15:30:07   DBG          -       p:1.09160  oc:   244  s:   -20  t:      0  d:      0 +1.48  oc1:    -21  hl1:     68  dmsc1:    800  cnt_ds:    150
	2023.07.07 15:30:07   DBG          -       p:1.09138  oc:   222  s:   -29  t:      0  d:      0 +1.48  oc1:    -39  hl1:     68  dmsc1:    800  cnt_ds:    150
	2023.07.07 15:30:07   DBG          -       p:1.09115  oc:   199  s:    -9  t:      0  d:      0 +1.48  oc1:    -56  hl1:     76  dmsc1:    766  cnt_ds:    161 SELL (IGNORE)
	2023.07.07 15:30:07   DBG          -       p:1.09117  oc:   201  s:   -25  t:      0  d:      0 +1.48  oc1:    -44  hl1:     82  dmsc1:    800  cnt_ds:    150
	2023.07.07 15:30:07   DBG          -       p:1.09113  oc:   197  s:    -8  t:      0  d:      0 +1.48  oc1:    -37  hl1:     82  dmsc1:    768  cnt_ds:    160
	2023.07.07 15:30:07   DBG          -       p:1.09121  oc:   205  s:   -22  t:      0  d:      0 +1.48  oc1:    -39  hl1:     82  dmsc1:    768  cnt_ds:    160
	2023.07.07 15:30:07   DBG          -       p:1.09124  oc:   208  s:   -28  t:      0  d:      0 +1.48  oc1:    -45  hl1:     82  dmsc1:    768  cnt_ds:    160
	2023.07.07 15:30:07   DBG          -       p:1.09126  oc:   210  s:   -19  t:      0  d:      0 +1.48  oc1:    -45  hl1:     82  dmsc1:    769  cnt_ds:    160
	2023.07.07 15:30:07   DBG          -       p:1.09134  oc:   218  s:   -18  t:      0  d:      0 +1.48  oc1:    -32  hl1:     72  dmsc1:    736  cnt_ds:    171
	2023.07.07 15:30:07   DBG          -       p:1.09140  oc:   224  s:   -24  t:      0  d:      0 +1.48  oc1:    -19  hl1:     65  dmsc1:    735  cnt_ds:    172
	2023.07.07 15:30:07   DBG          -       p:1.09138  oc:   222  s:   -24  t:      0  d:      0 +1.48  oc1:      0  hl1:     48  dmsc1:    767  cnt_ds:    160
	2023.07.07 15:30:08   DBG          -       p:1.09140  oc:   224  s:   -19  t:      0  d:      0 +1.48  oc1:     25  hl1:     48  dmsc1:    770  cnt_ds:    159
	2023.07.07 15:30:08   DBG          -       p:1.09171  oc:   255  s:   -26  t:      0  d:      0 +1.48  oc1:     53  hl1:     79  dmsc1:    736  cnt_ds:    171 BUY (IGNORE)
	2023.07.07 15:30:08   DBG          -       p:1.09185  oc:   269  s:   -36  t:      0  d:      0 +1.48  oc1:     72  hl1:     95  dmsc1:    736  cnt_ds:    171
	2023.07.07 15:30:08   DBG          -       p:1.09178  oc:   262  s:   -22  t:      0  d:      0 +1.48  oc1:     56  hl1:     93  dmsc1:    736  cnt_ds:    171 
	2023.07.07 15:30:08   DBG          -       p:1.09171  oc:   255  s:    -8  t:      0  d:      0 +1.48  oc1:     46  hl1:     93  dmsc1:    736  cnt_ds:    171
	2023.07.07 15:30:08   DBG          -       p:1.09175  oc:   259  s:   -22  t:      0  d:      0 +1.48  oc1:     49  hl1:     87  dmsc1:    703  cnt_ds:    184
	2023.07.07 15:30:08   DBG          -       p:1.09182  oc:   266  s:   -23  t:      0  d:      0 +1.48  oc1:     48  hl1:     79  dmsc1:    703  cnt_ds:    184
	2023.07.07 15:30:08   DBG          -       p:1.09180  oc:   264  s:   -22  t:      0  d:      0 +1.48  oc1:     39  hl1:     78  dmsc1:    608  cnt_ds:    228
	2023.07.07 15:30:08   DBG          -       p:1.09167  oc:   251  s:   -19  t:      0  d:      0 +1.48  oc1:     29  hl1:     78  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:08   DBG          -       p:1.09151  oc:   235  s:   -18  t:      0  d:      0 +1.48  oc1:     10  hl1:     73  dmsc1:    575  cnt_ds:    247
	2023.07.07 15:30:08   DBG          -       p:1.09140  oc:   224  s:   -13  t:      0  d:      0 +1.48  oc1:    -31  hl1:     70  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:08   DBG          -       p:1.09139  oc:   223  s:   -14  t:      0  d:      0 +1.48  oc1:    -45  hl1:     70  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:08   DBG          -       p:1.09140  oc:   224  s:   -14  t:      0  d:      0 +1.48  oc1:    -38  hl1:     60  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:08   DBG          -       p:1.09140  oc:   224  s:   -15  t:      0  d:      0 +1.48  oc1:    -30  hl1:     60  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:08   DBG          -       p:1.09139  oc:   223  s:   -14  t:      0  d:      0 +1.48  oc1:    -35  hl1:     60  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:08   DBG          -       p:1.09138  oc:   222  s:   -14  t:      0  d:      0 +1.48  oc1:    -43  hl1:     62  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:09   DBG          -       p:1.09151  oc:   235  s:    -4  t:      0  d:      0 +1.48  oc1:    -28  hl1:     59  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09164  oc:   248  s:   -19  t:      0  d:      0 +1.48  oc1:     -2  hl1:     45  dmsc1:    577  cnt_ds:    246
	2023.07.07 15:30:09   DBG          -       p:1.09155  oc:   239  s:   -10  t:      0  d:      0 +1.48  oc1:      4  hl1:     42  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09149  oc:   233  s:   -15  t:      0  d:      0 +1.48  oc1:      9  hl1:     42  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09148  oc:   232  s:   -18  t:      0  d:      0 +1.48  oc1:      8  hl1:     42  dmsc1:    575  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09147  oc:   231  s:   -17  t:      0  d:      0 +1.48  oc1:      7  hl1:     42  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09136  oc:   220  s:   -26  t:      0  d:      0 +1.48  oc1:     -4  hl1:     51  dmsc1:    576  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09129  oc:   213  s:   -12  t:      0  d:      0 +1.48  oc1:    -10  hl1:     51  dmsc1:    575  cnt_ds:    247
	2023.07.07 15:30:09   DBG          -       p:1.09131  oc:   215  s:   -16  t:      0  d:      0 +1.48  oc1:     -7  hl1:     51  dmsc1:    575  cnt_ds:    247


"""