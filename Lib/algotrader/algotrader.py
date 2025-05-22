# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
# usage:
# import sys
# import algotrader as at
# at0 = at.Algotrader()
# at0.run_now(datetime(2021,1,15,17, tzinfo=timezone.utc), 'GBPJPY')


from datetime import datetime
from datetime import timezone
from datetime import timedelta


import sys, traceback
import os
import time
import pandas as pd
import numpy as np
import json
import logging 

# pip install scikit-fuzzy
import skfuzzy.control as ctrl

# pip install filterpy
# https://github.com/rlabbe/filterpy
from filterpy.kalman import KalmanFilter as KalmanFilterFilterPy
from filterpy.common import Q_discrete_white_noise


#import MetaTrader5 as mt5

#
# TODO convert this into a class/classes
#  together with
# print_fig_all_periods_and_one_sym_and_all_times
# print_fig_all_periods_and_all_syms
# print_past_entries_per_sym
# print_fig_all_periods_per_sym
# clear_ax_fig_all_periods_per_sym
# close_fig_all_periods_per_sym
# save_fig_all_periods_per_sym
# open_fig_all_periods_per_sym
#
from algotrader._mpf   import _calc_subplot_rows_x_cols
from algotrader._mpf   import _mpf_figure_open
from algotrader._mpf   import _mpf_figure_show
from algotrader._mpf   import _mpf_figure_close
from algotrader._mpf   import _mpf_figure_save
from algotrader._mpf   import _mpf_plot
from algotrader._utils import _sprintf




"""
    File name         : KalmanFilter.py
    File Description  : 1-D Object Tracking using Kalman Filter
    Author            : Rahmad Sadli
    Website Link      : https://machinelearningspace.com/object-tracking-simple-implementation-of-kalman-filter-in-python/
    Date created      : 15/02/2020
    Date last modified: 16/02/2020
    Python Version    : 3.7
"""

class KalmanFilter(object):
    def __init__(self, dt, u, std_acc, std_meas):
        self.dt = dt
        self.u = u
        self.std_acc = std_acc

        self.A = np.matrix([[1, self.dt],
                            [0, 1]])
        self.B = np.matrix([[(self.dt**2)/2], [self.dt]])

        self.H = np.matrix([[1, 0]])

        self.Q = np.matrix([[(self.dt**4)/4, (self.dt**3)/2],
                            [(self.dt**3)/2, self.dt**2]]) * self.std_acc**2

        self.R = std_meas**2

        self.P = np.eye(self.A.shape[1])
        
        self.x = np.matrix([[0], [0]])

        #print(self.Q)


    def predict(self):
        # Ref :Eq.(9) and Eq.(10)

        # Update time state
        self.x = np.dot(self.A, self.x) + np.dot(self.B, self.u)

        # Calculate error covariance
        # P= A*P*A' + Q
        self.P = np.dot(np.dot(self.A, self.P), self.A.T) + self.Q
        return self.x

    def update(self, z):
        # Ref :Eq.(11) , Eq.(11) and Eq.(13)
        # S = H*P*H'+R
        S = np.dot(self.H, np.dot(self.P, self.H.T)) + self.R

        # Calculate the Kalman Gain
        # K = P * H'* inv(H*P*H'+R)
        K = np.dot(np.dot(self.P, self.H.T), np.linalg.inv(S))  # Eq.(11)

        self.x = np.round(self.x + np.dot(K, (z - np.dot(self.H, self.x))))  # Eq.(12)

        I = np.eye(self.H.shape[1])
        self.P = (I - (K * self.H)) * self.P  # Eq.(13)



class Algotrader():
    
    def __init__(self, account= None, symbol=None, args = None, df = None, usePid = False, useScalp=False):

        if None == symbol:
            self.gSymbol = 'GBPJPY'
        else:
            self.gSymbol = symbol
        
    
        self.goLive = False    
    
        self.gDt = {}
    
        self.KDtCountBasic = int(10)
        self.KDtCount = self.KDtCountBasic
        
        # use legacy function run_now which calculates rates
        self.gUseRates = False
        self.gUseScalp = False
        self.gScalpOffset = 0
        self.gScalpKeyArr = []
        self.set_use_scalp( useScalp )

        if None == account:
            self.gACCOUNT = 'RF5D01'
        else:
            self.gACCOUNT = account
          
        # TODO consolidate create CONFIG CLASS that reads path_mt5_bin and path_mt5_config
        dir_appdata =  os.getenv('APPDATA') 
        path_mt5 = dir_appdata +  "\\MetaTrader5_" + self.gACCOUNT
        path_mt5_user =  os.getenv('USERNAME') + '@' + os.getenv('COMPUTERNAME')
        
        # initialise ACCOUNTS config cf_accounts
        # KsACCOUNTS = ['RF5D01','RF5D02']
        self.cf_accounts = {}
        cf_fn = path_mt5 + "\\config\\cf_accounts_" + path_mt5_user + ".json"
        with open(cf_fn, 'r') as f: self.cf_accounts = json.load(f)
        
        # initialise PERIODS config cf_periods
        # KsPERIOD = ['T89','T233','M1','M5','M15','H1']
        self.cf_periods = {}
        cf_fn = path_mt5 + "\\config\\cf_periods_" + path_mt5_user + ".json"
        with open(cf_fn, 'r') as f: self.cf_periods = json.load(f)
        
        # initialise SYMBOLS config cf_symbols
        # KsCurAll = ['AUDCAD','AUDCHF','AUDJPY','AUDNZD','AUDUSD','CADCHF','CADJPY','CHFJPY','EURAUD','EURCAD','EURCHF','EURGBP','EURJPY','EURNZD','EURUSD','GBPAUD','GBPCAD','GBPCHF','GBPJPY','GBPNZD','GBPUSD','NZDCAD','NZDCHF','NZDJPY','NZDUSD','USDCAD','USDCHF','USDJPY']
        #self.cf_symbols = {}
        #with open('cf_symbols.json', 'r') as f: self.cf_symbols = json.load(f)
        cf_fn = path_mt5 + "\\config\\cf_symbols_" + path_mt5_user + ".json"
        self.set_cf_symbols(cf_fn)
        self.cf_symbols_default = 'EURUSD'
        #self.cf_symbols_all =    ['AUDCAD','AUDCHF','AUDJPY','AUDNZD','AUDUSD','CADCHF','CADJPY','CHFJPY','EURAUD','EURCAD','EURCHF','EURGBP','EURJPY','EURNZD','EURUSD','GBPAUD','GBPCAD','GBPCHF','GBPJPY','GBPNZD','GBPUSD','NZDCAD','NZDCHF','NZDJPY','NZDUSD','USDCAD','USDCHF','USDJPY']

        # initialise PID params config cf_pid_params
        self.gUsePid = False
        self.set_use_pid( usePid )
        self.cf_pid_params = {}
        cf_fn = path_mt5 + "\\config\\cf_pid_params_" + path_mt5_user + ".json"
        with open(cf_fn, 'r') as f: self.cf_pid_params = json.load(f)
        
        self.gNpa = []
        
        if None == df:
            self.gDF  = {}
        else:
            self.gDF  = df
            
        # gDF keys
        self.gDFkeys = []
        # forwards iterator
        self.gDFiterfor = None
        # reversed iterator
        self.gDFiterrev = None
        
        self.g_fig_all_periods_per_sym = {}
        self.g_c0 = {}
        for sym in self.cf_symbols[self.gACCOUNT]: 
            self.g_c0[sym] = None

        # some options
        self.gGlobalFig = False
        self.gCrazyFigPattern = False
        if False == self.gGlobalFig and True == self.gCrazyFigPattern:
            raise ValueError( "ERROR: self.gGlobalFig[False] does not work with self.gCrazyFigPattern[True]: ")
        self.gShowFig = True
        self.gSaveFig = True
        self.gVerbose = 0
        self.gTightLayout = True
        self.gShowNonTrading = True
        self.gDateFormatMS = '%H:%M:%S.%f'
        self.gDateFormatS  = '%H:%M:%S'
        self.gDateFormat   = self.gDateFormatS
        
        self.offset = 25
        
        self.talib = __import__("talib")
        #  https://stackoverflow.com/questions/6677424/how-do-i-import-variable-packages-in-python-like-using-variable-variables-i
        # import MetaTrader5 as mt5
        package = _sprintf("MetaTrader5_%s",self.gACCOUNT)
        #package = "MetaTrader5"
        self.mt5 = __import__(package)
        # xcopy c:\apps\anaconda3\Lib\site-packages\MetaTrader5 c:\apps\anaconda3\Lib\site-packages\MetaTrader5_RF5D01\*
        # srcDir = 'c:\apps\anaconda3\Lib\site-packages\MetaTrader5'
        # targetDir = 'c:\apps\anaconda3\Lib\site-packages\MetaTrader5_RF5D01'

        self.screen = None
        self.screen_first_row = 1
        self.screen_first_ana_row = 5
        self.screen_first_col = 1
        
        self.perarr=[\
                ['T3','T5','T8','T13','T21','T34'],\
                ['T5','T8','T13','T21','T34','T55'],\
                ['T8','T13','T21','T34','T55','T89'],\
                ['T13','T21','T34','T55','T89','T144'],\
                ['T21','T34','T55','T89','T144','T233'],\
                ['T34','T55','T89','T144','T233','T377'],\
                ['T55','T89','T144','T233','T377','T610'],\
                ['T89','T144','T233','T377','T610','T987'],\
                ['T144','T233','T377','T610','T987','T1597']\
               ]

        # self.perarr=[\
        #         ['T1'],\
        #         ['T2'],\
        #         ['T3']\
        #         ]

        # self.perarr=[\
        #         # ['T3'],\
        #         ['T13'],\
        #         ['T34']\
        #         ]
        
        # winter time
        #self.tdOffset= timedelta(hours=2)
        # summer time
        self.tdOffset= timedelta(hours=3)
        # =============================================================================
    	# one hour ahead of 'Europe/Berlin' and timezone of RFX trade server
    	# timezone=pytz.timezone('Europe/Helsinki')
    	# gTdOffset/timedelta(hours=2) is the timedelta from UTC to Helsinki to the current trading time
        # =============================================================================
        #
        # import pytz
        # timezone.utc=pytz.timezone('Etc/UTC')
        # gTimezoneEET=pytz.timezone('EET')
        #
        # print( timezone.utc )
        # Etc/UTC
        # =============================================================================
        # # python datetime to epoch timestamp in sec
        # dt_from = datetime(2020,11,20,22,tzinfo=timezone.utc)
        #     # print( dt_from )
        #     # 2020-11-20 22:00:00+00:00
        # epoch = int(dt_from.timestamp())
        #     # print( epoch )
        #     # 1605909600
        # dt_from = datetime.fromtimestamp(epoch, timezone.utc)
        #     # print( dt_from )
        #     # 2020-11-20 22:00:00+00:00
        # =============================================================================
    
        # =============================================================================
        # https://www.robomarkets.com/beginners/info/forex-trading-hours/
        # When talking about trading hours on the Forex market, 
        # it is common practice to use the UTC time zone – 
        # the Universal Time Coordinated. The server time in RoboMarkets 
        # terminals differs from the UTC by 2 hours (UTC+2). 
        # When several countries switch to daylight saving time (DST) in spring, 
        # the difference gets bigger (UTC+3).
        # Schedule of forex trading hours. The time zone is UTC+2 (Eastern European Time, EET):
        # 
        # dteet=datetime(2020,11,20,22,tzinfo=gTimezoneEET)
        # 
        # dtutc=datetime(2020,11,20,22,tzinfo=timezone.utc)
        # 
        # dtutc.timestamp()
        # 1605909600.0
        # 
        # dteet.timestamp()
        # 1605902400.0
        #     
        # datetime.fromtimestamp(1605902400,timezone.utc)
        # Out[58]: datetime.datetime(2020, 11, 20, 20, 0, tzinfo=<StaticTzInfo 'Etc/UTC'>)
        #
        # datetime.fromtimestamp(1605902400,gTimezoneEET)
        # Out[59]: datetime.datetime(2020, 11, 20, 22, 0, tzinfo=<DstTzInfo 'EET' EET+2:00:00 STD>)
        #
        # datetime.fromtimestamp(1605909600,timezone.utc)
        # Out[60]: datetime.datetime(2020, 11, 20, 22, 0, tzinfo=<StaticTzInfo 'Etc/UTC'>)
        #
        # datetime.fromtimestamp(1605909600,gTimezoneEET)
        # Out[61]: datetime.datetime(2020, 11, 21, 0, 0, tzinfo=<DstTzInfo 'EET' EET+2:00:00 STD>)    
        #
        #
        # dtutcnow=datetime.now(timezone.utc)
        # 
        # dteetnow=datetime.now(gTimezoneEET)
        # 
        # dtutcnow
        #     datetime.datetime(2020, 11, 29, 15, 20, 53, 615673, tzinfo=<StaticTzInfo 'Etc/UTC'>)
        # 
        # dtutcnow.timestamp()
        #     1606663253.615673
        # 
        # dteetnow
        #     datetime.datetime(2020, 11, 29, 17, 21, 3, 141693, tzinfo=<DstTzInfo 'EET' EET+2:00:00 STD>)
        # 
        # dteetnow.timestamp()
        #     1606663263.141693
        # 
        # =============================================================================

        # at logging
        dt_start     = datetime.now(timezone.utc) + self.tdOffset
        # TODO make me optional - with hours and minutes or not
        #self.dt_start_str = str(dt_start.strftime("%Y%m%d_%H%M%S"))  
        self.dt_start_str = str(dt_start.strftime("%Y%m%d"))  
        # TODO consolidate create CONFIG CLASS that reads path_mt5_bin and path_mt5_config
        path_mt5_log = dir_appdata +  "/MetaTrader5_" + self.gACCOUNT + "/MQL5/logs/"
        log_filename = path_mt5_log + self.dt_start_str + ".log"
        #format_str = '%(asctime)s: %(message)s'
        format_str = '%(message)s'
        # https://stackoverflow.com/questions/15199816/python-logging-multiple-files-using-the-same-logger
        # https://stackoverflow.com/questions/17035077/logging-to-multiple-log-files-from-different-classes-in-python
        #atlog.basicConfig(filename=log_filename, level=logging.DEBUG, format=format_str)
        self.set_logger( name = 'atlog', filename = log_filename, level = logging.INFO, format = format_str )
        self.atlog = logging.getLogger('atlog')
        

        # at kalman logging
        dt_start     = datetime.now(timezone.utc) + self.tdOffset
        dtstr = str(dt_start.strftime("%Y%m%d_"))  
        log_filename = path_mt5_log + dtstr + self.gACCOUNT + "_kalman.log"
        format_str = '%(message)s'
        #atlogkalman.basicConfig(filename=log_filename, level=atlogkalman.DEBUG, format=format_str)
        self.set_logger( name = 'atlogkalman', filename = log_filename, level = logging.INFO, format = format_str, use_stdout = False )
        self.atlogkalman = logging.getLogger('atlogkalman')
        
        
        #
        # fuzzy init
        #
        universe_x1 = np.linspace(-2, 2, 5)
        universe_x2 = np.linspace(-2, 2, 5)
        universe_x3 = np.linspace(-100, 100, 5)
        universe_y1 = np.linspace(-1, 1, 11)

        # Create the three fuzzy variables - two inputs, one output
        x1 = ctrl.Antecedent(universe_x1, 'x1')
        x2 = ctrl.Antecedent(universe_x2, 'x2')
        x3 = ctrl.Antecedent(universe_x3, 'x3')
        y1 = ctrl.Consequent(universe_y1, 'y1')
        names = ['n', 'z', 'p']
        x1.automf(names=names)
        x2.automf(names=names)
        x3.automf(names=names)
        y1.automf(names=names)
        
        rule0 = ctrl.Rule(antecedent=  ( (x1['n'] & x2['n'] & x3['n']) ),
                          consequent=     y1['n'], label='rule n')

        rule1 = ctrl.Rule(antecedent=((x1['n'] & x2['p'] & (x3['n']|x3['z']|x3['p'])) |
                                      (x1['p'] & x2['n'] & (x3['n']|x3['z']|x3['p'])) |
                                      (x1['p'] & x2['p'] & (x3['n']|x3['z']        )) |
                                      (x1['n'] & x2['n'] & (x3['p']|x3['z']        )) |
                                      (x1['z'] & x2['z'] & (x3['n']|x3['z']|x3['p'])) |
                                      (x1['n'] & x2['z'] & (x3['n']|x3['z']|x3['p'])) |
                                      (x1['p'] & x2['z'] & (x3['n']|x3['z']|x3['p'])) |
                                      (x1['z'] & x2['p'] & (x3['n']|x3['z']|x3['p'])) |
                                      (x1['z'] & x2['n'] & (x3['n']|x3['z']|x3['p']))  ),
                          consequent=y1['z'], label='rule z')

        rule2 = ctrl.Rule(antecedent=  ( (x1['p'] & x2['p'] & x3['p']) ),
                          consequent=     y1['p'], label='rule p')
                          
        system = ctrl.ControlSystem(rules=[rule0, rule1, rule2])
        self.fuzzy_sim = ctrl.ControlSystemSimulation(system)

        self.mplus          = -1
        self.minus          = 1
        self.dfpcmax        = 50
        self.mplus_change   = False
        self.mplus_hedge    = False
        self.verbose        = 0
        self.dt_step        = timedelta( seconds = (5 *60) )
        self.dt_from        = datetime.now(timezone.utc) + self.tdOffset
        self.dt_to          = self.dt_from + self.dt_step
        self.deltabreakplus = 50
        self.deltabreakminus= -20
        self.active         = False
        
        if None != args:
            self.mplus          = args['mplus']
            self.minus          = args['minus']
            self.dfpcmax        = args['dfpcmax']
            self.mplus_change   = args['mplus_change']
            self.mplus_hedge    = args['mplus_hedge']
            self.verbose        = args['verbose']
            self.dt_step        = args['dt_step']
            self.dt_from        = args['dt_from']
            self.dt_to          = args['dt_to']
            self.deltabreakplus = args['deltabreakplus']
            self.deltabreakminus= args['deltabreakminus']
            self.active       = True
            
            
        self.fuzzy_prev = 0.0
        
        
        self.up_dn_str_prev = ""
        self.up_dn_str_high = 0
        self.up_dn_str_low  = 1000
        
        
        # 1-D Kalman filter settings
        self.gKalmanDt         = 0.01
        self.gKalmanU          = 2
        self.gKalmanStdDevAcc  = 0.25
        self.gKalmanStdDevMeas = 1.2
        self.gKalmanChartIntervalInSeconds = 60

        self.gKalmanDt         = 0.1
        self.gKalmanU          = 2
        self.gKalmanStdDevAcc  = 0.25
        self.gKalmanStdDevMeas = 1.2
        self.gKalmanChartIntervalInSeconds = 60

        self.gKalmanDt         = 0.01
        self.gKalmanU          = 2
        self.gKalmanStdDevAcc  = 25
        self.gKalmanStdDevMeas = 1.2
        self.gKalmanChartIntervalInSeconds = 60
       
        
        
    # END def __init__(self, account= None, usePid = False, useScalp=False):
    # =============================================================================



    # =============================================================================
    # def set_logger( self, name = r'pylog', filename= r'pylog.log', level=logging.INFO, format = r'%(asctime)s : %(message)s' ):
    #     
    # =============================================================================
    def set_logger( self, name = r'pylog', filename= r'pylog.log', level=logging.DEBUG, format = r'%(asctime)s : %(message)s', use_stdout = False ):
        
        l = logging.getLogger(name)
        l.setLevel(level)
        l.propagate = False
        
        formatter = logging.Formatter(format)
        
        fileHandler = logging.FileHandler(filename, mode='a')
        fileHandler.setFormatter(formatter)
        l.addHandler(fileHandler)
        
        if True == use_stdout:
            streamHandler = logging.StreamHandler()
            streamHandler.setFormatter(formatter)
            l.addHandler(streamHandler)    

        

    # END def set_logger( self, name = r'pylog', filename= r'pylog.log', level=logging.INFO, format = r'%(asctime)s : %(message)s' ):
    # =============================================================================

    # =============================================================================
    # def set_cf_symbols( self, cf_filename ):
    #     
    # =============================================================================
    def set_cf_symbols( self, cf_filename ):

        # initialise SYMBOLS config cf_symbols
        # KsCurAll = ['AUDCAD','AUDCHF','AUDJPY','AUDNZD','AUDUSD','CADCHF','CADJPY','CHFJPY','EURAUD','EURCAD','EURCHF','EURGBP','EURJPY','EURNZD','EURUSD','GBPAUD','GBPCAD','GBPCHF','GBPJPY','GBPNZD','GBPUSD','NZDCAD','NZDCHF','NZDJPY','NZDUSD','USDCAD','USDCHF','USDJPY']
        self.cf_symbols = {}
        with open( cf_filename, 'r') as f: self.cf_symbols = json.load(f)
        
    # END def set_cf_symbols( self, cf_filename ):
    # =============================================================================


    # =============================================================================
    # def set_cf_periods( self, cf_filename ):
    #     
    # =============================================================================
    def set_cf_periods( self, cf_filename = None, cf_periods_name = None, cf_periods_arr = None ):
        
        # cf_periods_04.json
        # "NAME": "04",
        # "RF5D01":{
        #    "T3804":{
        #       "type" : "dynamic",
        #       "seconds" : 0,
        #       "minutes" : 0,
        #       "volume" : 3804
        #    }
        # },
        self.cf_periods = {}
        
        if None != cf_filename:
            # initialise PERIODS config cf_periods
            # KsPERIOD = ['T89','T233','M1','M5','M15','H1']
            with open( cf_filename, 'r') as f: self.cf_periods = json.load(f)

        else:

            # if all parameters are None, load the default cf_periods file            
            if (None == cf_periods_name):
                with open( 'cf_periods.json', 'r') as f: self.cf_periods = json.load(f)

            else:
                self.cf_periods['NAME'] = cf_periods_name
                self.cf_periods[self.gACCOUNT] = {}
                
                # =============================================================================
                #     per_count =  cf_periods[gACCOUNT][per]['volume']
                #     # per_count = 233 - split from T233
                #     # "T233".split("T")         -> ['', '233']
                #     # "T233".split("T")[1]      -> '233'
                #     # int("T233".split("T")[1]) -> 233
                #     per_count = int(per.split("T")[1])
                # =============================================================================
                for per in cf_periods_arr: 
                    self.cf_periods[self.gACCOUNT][per] = {}
                    self.cf_periods[self.gACCOUNT][per]['type'] = 'dynamic'
                    self.cf_periods[self.gACCOUNT][per]['minutes'] = 0
                    value = int(per.split(per[0])[1])
                    if   'T' == per[0]:
                        self.cf_periods[self.gACCOUNT][per]['volume'] = value
                        self.cf_periods[self.gACCOUNT][per]['seconds'] = 0
                    elif 'S' == per[0]:
                        self.cf_periods[self.gACCOUNT][per]['volume'] = 0
                        self.cf_periods[self.gACCOUNT][per]['seconds'] = value
                    else:
                        raise(ValueError('cf_periods set T or S for now'))

        #print(self.cf_periods)
        
    # END def set_cf_periods( self, cf_filename ):
    # =============================================================================
        

    # =============================================================================
    # def set_use_scalp( self, _use_scalp ):
    #     
    # =============================================================================
    def set_use_scalp( self, _use_scalp ):
 
        if True == _use_scalp:
            self.gUseScalp = _use_scalp
            self.gScalpKeyArr = [3,5,8,13,21,34]
            # points to the last element and adds one
            # -> here 34 + 1 => 35
            self.gScalpOffset = self.gScalpKeyArr[len(self.gScalpKeyArr)-1]+1
            self.KDtCount = self.KDtCountBasic + self.gScalpOffset
        else:
            self.gUseScalp = _use_scalp
            self.gScalpKeyArr = []
            self.gScalpOffset = 0
            self.KDtCount = self.KDtCountBasic
    
    # END def set_use_scalp( self, _use_scalp ):
    # =============================================================================

    # =============================================================================
    # def set_use_pid( self, _use_pid ):
    #     
    # =============================================================================
    def set_use_pid( self, _use_pid ):
 
        if True == _use_pid:
            self.gUsePid = _use_pid
        else:
            self.gUsePid = _use_pid
    
    # END def set_use_pid( self, _use_pid ):
    # =============================================================================
        
    # =============================================================================
    # def set_df_rates( dt_from, per, sym, df ):
    #     
    # =============================================================================
    def set_df_rates( self, dt_from, per, sym, df ):
 
        # https://datatofish.com/check-nan-pandas-dataframe/
        count_nan_in_df = df.isnull().sum().sum()
        if 0 < count_nan_in_df:
            self.gNpa = df
            print( df.isnull().sum() )
            raise ValueError( _sprintf("ERROR: count_nan_in_df[%d]: ", count_nan_in_df) )
 
        if 'RATES'      not in self.gDF:                             self.gDF['RATES'] = {}
        if str(dt_from) not in self.gDF['RATES']:                    self.gDF['RATES'][str(dt_from)] = {}
        if per          not in self.gDF['RATES'][str(dt_from)]:      self.gDF['RATES'][str(dt_from)][per] = {}
        if sym          not in self.gDF['RATES'][str(dt_from)][per]: self.gDF['RATES'][str(dt_from)][per][sym] = {}
        self.gDF['RATES'][str(dt_from)][per][sym] = df    
    
    # END def set_df_rates( dt_from, per, sym, df ):
    # =============================================================================
    
    
    # =============================================================================
    # def get_df_rates( dt_from, per, sym ):
    #     
    # =============================================================================
    def get_df_rates( self, dt_from = None, per = None, sym = None ):
    
        df = {}
        if (None == dt_from) and (None == per) and (None == sym) :
            df = self.gDF
            
        else:
            if 'RATES' in self.gDF: 
                if str(dt_from) in self.gDF['RATES']: 
                    if per in      self.gDF['RATES'][str(dt_from)]: 
                        if sym in  self.gDF['RATES'][str(dt_from)][per]: 
                            df =   self.gDF['RATES'][str(dt_from)][per][sym]
                        else:
                            print( _sprintf("ERROR get_df_rates(%s, %s, %s) SYMBOL not found", str(dt_from), per, sym ) )
                    else:
                        print(     _sprintf("ERROR get_df_rates(%s, %s, %s) PERIOD not found", str(dt_from), per, sym ) )
                else:
                    print(         _sprintf("ERROR get_df_rates(%s, %s, %s) DT_FROM not found", str(dt_from), per, sym ) )
            else:
                print(             _sprintf("ERROR get_df_rates(%s, %s, %s) RATES   not found", str(dt_from), per, sym ) )
            
        return df
    
    # END def get_df_rates( dt_from, per, sym ):
    # =============================================================================

    
    # =============================================================================
    # def set_df(self, key, sym, df):
    #     
    # =============================================================================
    def set_df(self, key, sym, df):

        if key not in self.gDF: self.gDF[key] = {}
        self.gDF[key][sym] = df
    
    # END def set_df(self, key, sym, df):
    # =============================================================================
    
    # =============================================================================
    # def get_df( dt_from,key, sym ):
    #     
    # =============================================================================
    def get_df( self, key = None, sym = None ):
    
        df = {}
        if (None == key) and (None == sym) :
            df = self.gDF
            
        else:
            if key in self.gDF: 
                if sym in self.gDF[key]: 
                    df = self.gDF[key][sym]
                # TODO make optional - log verbose
                # else:
                #     print( _sprintf("ERROR get_df(%s, %s) SYMBOL[%s] not found", key, sym, sym ) )
            # TODO make optional - log verbose
            # else:
            #     print(     _sprintf("ERROR get_df(%s, %s) KEY[%s] not found", key, sym, key ) )
        
        return df
    
    # END def get_df( dt_from, key, sym ):
    # =============================================================================
    
    
    # =============================================================================
    # def get_df_keys(self):
    #     
    # =============================================================================
    def get_df_keys(self):
    
        self.gDFkeys    = list(self.gDF.keys())
        # forwards iterator
        self.gDFiterfor = iter(self.gDFkeys)
        #gDF_index       = next(self.gDFiterfor)        
        #print( gDF_index )
        # reversed iterator
        self.gDFiterrev = reversed(self.gDFkeys)
        gDF_index       = next(self.gDFiterrev)
        #print( gDF_index )
       
        #print( self.gDFkeys )
        return self.gDFkeys
    
    # END def get_df_keys(self):
    # =============================================================================

    # =============================================================================
    # def get_next_key(self):
    #     
    # =============================================================================
    def get_next_key(self):

        gDF_index = None
        try:
            gDF_index = next(self.gDFiterfor)
        except StopIteration:
            self.gDFkeys    = list(self.gDF.keys())
            self.gDFiterfor = iter(self.gDFkeys)
            gDF_index       = next(self.gDFiterfor)

        if None != gDF_index:        
            print( gDF_index )
        else:
            if 0 < len(self.gDF):
                print( "get_df_next ERROR" )
            else:
                print( "gDF is still empty " )
                
        return gDF_index
    
    # END def get_next_key(self):
    # =============================================================================


    # =============================================================================
    # def get_prev_key(self):
    #     
    # =============================================================================
    def get_prev_key(self):
        
        gDF_index = None
        try:
            gDF_index = next(self.gDFiterrev)
        except StopIteration:
            self.gDFkeys    = list(self.gDF.keys())
            self.gDFiterrev = reversed(self.gDFkeys)
            gDF_index       = next(self.gDFiterrev)

        if None != gDF_index:        
            print( gDF_index )
        else:
            if 0 < len(self.gDF):
                print( "get_df_prev ERROR" )
            else:
                print( "gDF is still empty " )
                
        return gDF_index
    
    # END def get_prev_key(self):
    # =============================================================================



    # =============================================================================
    # def get_df_next(self):
    #     
    # =============================================================================
    def get_df_next(self):

        df = {}
        gDF_index = None
        try:
            gDF_index = next(self.gDFiterfor)
        except StopIteration:
            self.gDFkeys    = list(self.gDF.keys())
            self.gDFiterfor = iter(self.gDFkeys)
            gDF_index       = next(self.gDFiterfor)

        if None != gDF_index:        
            print( gDF_index )
            df = self.gDF[gDF_index]
        else:
            if 0 < len(self.gDF):
                print( "get_df_next ERROR" )
            else:
                print( "gDF is still empty " )
                
        return df
    
    # END def get_df_next(self):
    # =============================================================================


    # =============================================================================
    # def get_df_prev(self):
    #     
    # =============================================================================
    def get_df_prev(self):

        df = {}
        gDF_index = None
        try:
            gDF_index = next(self.gDFiterrev)
        except StopIteration:
            self.gDFkeys    = list(self.gDF.keys())
            self.gDFiterrev = reversed(self.gDFkeys)
            gDF_index       = next(self.gDFiterrev)

        if None != gDF_index:        
            print( gDF_index )
            df = self.gDF[gDF_index]
        else:
            if 0 < len(self.gDF):
                print( "get_df_prev ERROR" )
            else:
                print( "gDF is still empty " )
                
        return df
    
    # END def get_df_prev(self):
    # =============================================================================

    
    # =============================================================================
    # def get_date_range(dt_to):
    #     
    # =============================================================================
    def get_date_range(self, dt_to):
        
        # =============================================================================
        #     self.gDt = {}
        #     self.gDt['dt_from']    = dt_to - timedelta(seconds=(max_seconds*self.gDt['dt_count']))
        #     self.gDt['dt_to']      = dt_to
        #     self.gDt['dt_count']   = 0
        #     self.gDt['dt_volume']  = 0
        #     self.gDt['dt_seconds'] = 0
        # 
        #     dt_from  = self.gDt['dt_from']
        #     dt_to    = self.gDt['dt_to']
        #     dt_count = self.gDt['dt_count']
        #     dt_vol   = self.gDt['dt_volume']
        #     dt_secs  = self.gDt['dt_seconds']
        # =============================================================================
    
        max_seconds = 0
        max_volume = 0
        for per in self.cf_periods[self.gACCOUNT]:
            sec = self.cf_periods[self.gACCOUNT][per]['seconds']
            if max_seconds <  sec:
                max_seconds = sec
                
            vol = self.cf_periods[self.gACCOUNT][per]['volume']
            if max_volume <  vol:
                max_volume = vol
                
        self.gDt['dt_count'] = self.KDtCount
        self.gDt['dt_volume'] = max_volume
        self.gDt['dt_seconds'] = max_seconds
        self.gDt['dt_to'] = dt_to
        if 0 == max_seconds:
            max_seconds = 3600
        self.gDt['dt_from'] = self.gDt['dt_to']  - timedelta(seconds=(max_seconds*self.gDt['dt_count']))
    
        #
        # TODO FIXME make this optional DT_TO starts at beginning of the day
        #
        self.gDt['dt_from'] = dt_to.replace(hour=0, minute=5, second=0, microsecond=0)
    
    
    # def get_date_range():
    # =============================================================================


    # =============================================================================
    # def get_pcm_and_price(sym):
    #     
    # =============================================================================
    def get_pcm_and_price(self, sym):
    
        dt_from  = self.gDt['dt_from']
        dt_to    = self.gDt['dt_to']
        
        # TODO FIXME make this optional DT_TO starts at beginning of the day
        fail_cnt = 0
        while True:
            # TICKS
            npa = self.mt5.copy_ticks_range(sym,dt_from ,dt_to , self.mt5.COPY_TICKS_ALL)
            print(sym,dt_from,dt_to,npa)
            if None != npa:
                len_npa = len(npa)    # end of numpy array
                if (0 < len_npa):
                    if( 30 < len_npa):
                        break
                    else:
                        dt_from = dt_from - timedelta(seconds=(60)) 
                else:
                    dt_from = dt_from - timedelta(seconds=(60)) 
            else:
                dt_from = dt_from - timedelta(seconds=(60)) 

            fail_cnt = fail_cnt + 1
            if 60 < fail_cnt:
                strerror = _sprintf("copy_ticks_range error [sym:%s lennpa: %d dt_from:%s dt_to:%s]",sym,len_npa,dt_from ,dt_to)
                raise( ValueError( strerror))

        # while True:
    
        self.gNpa = npa
        
        # https://stackoverflow.com/questions/51272894/finding-and-recording-the-maximum-values-of-slices-of-a-numpy-array
        # a = npa['ask']
        # b = npa['bid']
        # price = (a+b)/2
        # import numpy as np
        #  for T3  => ticks = 3 * count = 10 -> 30
        #   taking the last 30 elements of the array
        # np.maximum.reduceat(a, np.r_[(len(a)-30):len(a):30])
        
        
        str_ask = 'ask'
        str_bid = 'bid'
        
        #
        # T3  3 * 10 counts
        #
        lent = 30
        npa = np.delete(npa,np.s_[0:(len(npa)-lent):],axis=0)
        pcmax = npa[str_ask].max() - npa[str_bid].min()
        x = np.arange(lent)
        y = (npa[str_ask] + npa[str_bid]) / 2
        pcm = (np.polyfit(x,y,1)[0] * lent) / pcmax
        pcm30 = float("%.1f" % pcm)
        pcmax30 = int(pcmax/self.mt5.symbol_info (sym).point) 

        #
        # T2  2 * 10 counts
        #
        lent = 20
        npa = np.delete(npa,np.s_[0:(len(npa)-lent):],axis=0)
        pcmax = npa[str_ask].max() - npa[str_bid].min()
        x = np.arange(lent)
        y = (npa[str_ask] + npa[str_bid]) / 2
        pcm = (np.polyfit(x,y,1)[0] * lent) / pcmax
        pcm20 = float("%.1f" % pcm)
        pcmax20 = int(pcmax/self.mt5.symbol_info (sym).point) 

        #
        # T1  1 * 10 counts
        #
        lent = 10
        npa = np.delete(npa,np.s_[0:(len(npa)-lent):],axis=0)
        pcmax = npa[str_ask].max() - npa[str_bid].min()
        x = np.arange(lent)
        y = (npa[str_ask] + npa[str_bid]) / 2
        pcm = (np.polyfit(x,y,1)[0] * lent) / pcmax
        pcm10 = float("%.1f" % pcm)
        pcmax10 = int(pcmax/self.mt5.symbol_info (sym).point) 

        pcm = (pcm10+pcm20+pcm30)/3
        pcmax = (pcmax10+pcmax20+pcmax30)/3


        len_npa = len(npa) - 1    # end of numpy array
        price = (npa[len_npa][str_ask] + npa[len_npa][str_bid])/2
        
        #
        # sanity checks
        #
        dt_to_epoch = int(dt_to.timestamp())
        npa_epoch   = npa[len_npa]['time']
        dt_to_dt    = dt_to
        npa_dt      = datetime.fromtimestamp(npa_epoch, timezone.utc)
        fuzzy_cnt = dt_to_epoch - npa_epoch
        
        # check that retrieved ticks from mt5 are actual and not too old
        if self.get_ticks_max_gap_in_secs( 'TICKS' ) < fuzzy_cnt :
            strerror = _sprintf("get_ticks ERROR1 sym:%s fuzzy_cnt:%d dt_to_epoch:%d npa_epoch:%d dt_to_dt:%s npa_dt:%s TICKS kaputt",sym, fuzzy_cnt, dt_to_epoch, npa_epoch, dt_to_dt, npa_dt)
            raise( ValueError( strerror))

        # check that retrieved ticks from mt5 are not newer
        if dt_to_epoch < npa_epoch:
            strerror = _sprintf("get_ticks ERROR2 sym:%s fuzzy_cnt:%d dt_to_epoch:%d npa_epoch:%d dt_to_dt:%s npa_dt:%s TICKS kaputt",sym, fuzzy_cnt, dt_to_epoch, npa_epoch, dt_to_dt, npa_dt)
            raise( ValueError( strerror))
            
    
        # check for nan
        for n in npa.dtype.names:
            if np.isnan(np.sum(npa[n])):
                strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",sym, n, str(npa[n]))
                raise( ValueError( strerror))
    
        return price, pcmax, pcm
    
    # END def get_pcm_and_price(sym):
    # =============================================================================




    # =============================================================================
    # def get_price(sym, dt_from, dt_count ):
    #     
    # =============================================================================
    def get_price(self, sym, dt_from, dt_count ):
    
        # TODO FIXME make this optional DT_TO starts at beginning of the day
        fail_cnt = 0
        while True:
            # TICKS
            npa = self.mt5.copy_ticks_from(sym, dt_from , dt_count, self.mt5.COPY_TICKS_ALL)
            self.gNpa = npa
            len_npa = len(npa)    # end of numpy array
            if (0 < len_npa):
                break
            else:
                fail_cnt = fail_cnt + 1
                if 60 < fail_cnt:
                    strerror = _sprintf("copy_ticks_range error [sym:%s lennpa: %d dt_from:%s ]",sym,len_npa,dt_from )
                    raise( ValueError( strerror))
    
        self.gNpa = npa
        
        # https://stackoverflow.com/questions/51272894/finding-and-recording-the-maximum-values-of-slices-of-a-numpy-array
        # a = npa['ask']
        # b = npa['bid']
        # price = (a+b)/2
        # import numpy as np
        #  for T3  => ticks = 3 * count = 10 -> 30
        #   taking the last 30 elements of the array
        # np.maximum.reduceat(a, np.r_[(len(a)-30):len(a):30])
        
        
        str_ask = 'ask'
        str_bid = 'bid'
        

        len_npa = len(npa) - 1    # end of numpy array
        price = (npa[len_npa][str_ask] + npa[len_npa][str_bid])/2
        
        #
        # sanity checks
        #
        dt_to_epoch = int(dt_from.timestamp())
        npa_epoch   = npa[len_npa]['time']
        dt_to_dt    = dt_from
        npa_dt      = datetime.fromtimestamp(npa_epoch, timezone.utc)
        fuzzy_cnt   = abs( dt_to_epoch - npa_epoch )
        
        # check that retrieved ticks from mt5 are actual and not too old
        if self.get_ticks_max_gap_in_secs( 'LIVE' ) < fuzzy_cnt :
            strerror = _sprintf("get_ticks ERROR1 sym:%s fuzzy_cnt:%d dt_to_epoch:%d npa_epoch:%d dt_to_dt:%s npa_dt:%s TICKS kaputt",sym, fuzzy_cnt, dt_to_epoch, npa_epoch, dt_to_dt, npa_dt)
            raise( ValueError( strerror))
    
        # check for nan
        for n in npa.dtype.names:
            if np.isnan(np.sum(npa[n])):
                strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",sym, n, str(npa[n]))
                raise( ValueError( strerror))
    
        return price
    
    # END def get_price(sym, dt_from, dt_count ):
    # =============================================================================




    # =============================================================================
    # def get_ticks(sym):
    #     
    # =============================================================================
    def get_ticks(self, sym):
    
        dt_from  = self.gDt['dt_from']
        dt_to    = self.gDt['dt_to']

        #
        # TODO FIXME make this optional DT_TO starts at beginning of the day
        #
        #dt_count = self.gDt['dt_count']
        #dt_vol   = self.gDt['dt_volume']
        #dt_sec   = self.gDt['dt_seconds']
        #while_cnt = 0
        #
        #while True:
        #    # TICKS
        #    npa = self.mt5.copy_ticks_range(sym,dt_from ,dt_to , self.mt5.COPY_TICKS_ALL)
        #    #npa = self.mt5.copy_ticks_from(sym,dt_to ,(dt_vol*dt_count+10) , self.mt5.COPY_TICKS_ALL)
        #    # if len from numpy ticks array is larger than 2330 e.g. for T233 by 10 counts
        #    len_t   = dt_vol*dt_count # T233 -> 2330 for count = 10
        #    len_npa = len(npa) - 1    # end of numpy array
        #    #print(len_t, len_npa, dt_from, dt_to)
        #    # if in period is no TICK period e.g. M1, M5
        #    if (0 == len_t):
        #        if (0 < len_npa):
        #            break
        #        else:
        #            raise -42
        #    # if in period there is TICK period e.g. M1, T233
        #    else:
        #        if len_t < len_npa:
        #            # do not delete here - but keep this code and make
        #            #  it maybe TODO optional later
        #            # npa = np.delete(npa,np.s_[0:(len_npa-len_t):],axis=0)
        #            break
        #        else:
        #            # TODO re-work me - T periods
        #            # in scalping mode, when there are only 
        #            # T periods, then set dt_sec to dt_vol
        #            # because dt_sec is empty for T periods
        #            if (0==dt_sec) and (True==self.gUseScalp):
        #                dt_sec=dt_vol
        #            while_cnt = while_cnt + 1
        #            dt_from = dt_from - timedelta(seconds=(dt_sec*dt_count*while_cnt))

        
        # TODO FIXME make this optional DT_TO starts at beginning of the day
        fail_cnt = 0
        while True:
            # TICKS
            len_npa = 0
            npa = self.mt5.copy_ticks_range(sym,dt_from ,dt_to , self.mt5.COPY_TICKS_ALL)
            #if type(None) == type(npa):
            if type(npa) is np.ndarray:
                len_npa = len(npa) - 1    # end of numpy array
            if (0 < len_npa):
                break
            else:
                fail_cnt = fail_cnt + 1
                if 10 < fail_cnt:
                    strerror = _sprintf("copy_ticks_range error [sym:%s lennpa: %d dt_from:%s dt_to:%s]",sym,len_npa,dt_from ,dt_to)
                    raise( ValueError( strerror))
    
        #self.gNpa = npa
        
        #
        # sanity checks
        #
        dt_to_epoch = int(dt_to.timestamp())
        npa_epoch   = npa[len_npa]['time']
        dt_to_dt    = dt_to
        npa_dt      = datetime.fromtimestamp(npa_epoch, timezone.utc)
        fuzzy_cnt = dt_to_epoch - npa_epoch
        
        # check that retrieved ticks from mt5 are actual and not too old
        if self.get_ticks_max_gap_in_secs( 'TICKS' ) < fuzzy_cnt :
            strerror = _sprintf("get_ticks ERROR1 sym:%s fuzzy_cnt:%d dt_to_epoch:%d npa_epoch:%d dt_to_dt:%s npa_dt:%s TICKS kaputt",sym, fuzzy_cnt, dt_to_epoch, npa_epoch, dt_to_dt, npa_dt)
            raise( ValueError( strerror))

        # check that retrieved ticks from mt5 are not newer
        if dt_to_epoch < npa_epoch:
            strerror = _sprintf("get_ticks ERROR2 sym:%s fuzzy_cnt:%d dt_to_epoch:%d npa_epoch:%d dt_to_dt:%s npa_dt:%s TICKS kaputt",sym, fuzzy_cnt, dt_to_epoch, npa_epoch, dt_to_dt, npa_dt)
            raise( ValueError( strerror))
            
    
        # check for nan
        for n in npa.dtype.names:
            if np.isnan(np.sum(npa[n])):
                strerror = _sprintf("NAN ERROR sym[%s] within column[%s] %s",sym, n, str(npa[n]))
                raise( ValueError( strerror))
    
        # TODO make this optional via verbose flag    
        df = pd.DataFrame(npa)
        # df['time']=pd.to_datetime(df['time'], unit='s')
        # df.insert(0,"DT",pd.to_datetime(df['time'], unit='s'))
        df.insert(0,"DTMS",pd.to_datetime(df['time_msc'], unit='ms'))
        
        df['spread']  = ( df.ask  - df.bid ) / self.cf_symbols[self.gACCOUNT][sym]['points']
        # df['SPREAD']  = df.ask  - df.bid 
        df['tdmsc']      =(df.time_msc - df.shift(1).time_msc)
        df.loc[0,'tdmsc'] = 0
        
        df['price'] = ( df.ask + df.bid ) / 2
    
        # =============================================================================
        #  example usage of time_delta_to_msc function
        #         #df['TD']      =(df.DTMS - df.shift(1).DTMS)
        #         #diff = df.iloc[start].TD
        #         #npa[ari]['td_msc']   = time_delta_to_msc(diff)
        # =============================================================================

        # reverse the array
        df = df[::-1]
        # df['index']=df.reindex(list(np.arange(2332,0,-1)),columns='index')
        # df.reset_index(inplace=True, drop=True)
        # df.reset_index(level=0, inplace=True)
        # df[::-1].reset_index()
        
        df.reset_index(inplace=True,drop=False)
        df.set_index(['DTMS'],drop=False,inplace=True)


        
        # df.reindex(index=list(np.arange(0,891,1)), columns=['index2'])
        
        # Orig - remove later once the below thing works
        # key = "zzz_" + per + "_" + sym
        # print(key)
        # self.gDF[key] = df
        
        self.set_df( 'TICKS', sym, df )
        return df
    
        # =============================================================================
        #     print (df.dtypes)
        #     DTMS            datetime64[ns]
        #     time                     int64
        #     bid                    float64
        #     ask                    float64
        #     last                   float64
        #     volume                  uint64
        #     time_msc                 int64
        #     flags                   uint32
        #     volume_real            float64
        #     spread                 float64
        #     tdmsc          timedelta64[ns]
        #     dtype: object
        # =============================================================================
    
    
    # END def get_ticks(sym):
    # =============================================================================


    # =============================================================================
    # def get_ticks_max_gap_in_secs( self, per ):
    #     
    # =============================================================================
    def get_ticks_max_gap_in_secs( self, per ):
    
        # 7 minutes trading break at EFX-ECN
        # from 23:58 to 00:05
        # hence 7 x 60 secs -> 420
        ret = 420
        # if there is a period which SECS are below 120
        # then set RET to value below SECS value
        # here for per M1 with SEC = 60 set it to 58
        if 'M1' == per:
            ret = 58

        if 'LIVE' == per:
            ret = 1000

        if 'TICKS' == per:
            if True == self.goLive:
                ret = 1200
            if False == self.goLive:
                ret = 1200
                            
        # TODO re-work T period
        # for scalping the TICKS kaputt
        # does not work for T3600
        #if True == self.gUseScalp:
        #    ret = 1234567890
            
        return ret
    
    # END def get_ticks_max_gap_in_secs( self, per ):
    # =============================================================================


    # =============================================================================
    # def copy_rates_from(sym,per,dt_from,count):
    #     
    # =============================================================================
    def copy_rates_from(self, sym,per,dt_from,count):
        
        
        # =============================================================================
        #     # dt_from_rates = dt_from
        #     # npa =   self.mt5.copy_rates_from    (sym, get_mt5_TIMEFRAME_from_String(per), dt_from_rates, count)
        #     
        #     secs = self.cf_periods[self.gACCOUNT][per]['seconds']
        #     dt_from_ticks = dt_from - timedelta( seconds =(secs*count))
        #     dt_to_ticks   = dt_from
        #     npa =   self.mt5.copy_rates_range    (sym, get_mt5_TIMEFRAME_from_String(per), dt_from_ticks, dt_to_ticks)
        # =============================================================================
        
        df    = self.get_df( 'TICKS', sym )
        lendf = len(df)
        if 0 >= lendf :
            raise ValueError("copy_rates_from: df does not exists " + sym + " "  + per + " " + str(dt_from) + " " + str(len) )
        
        secs = int(self.cf_periods[self.gACCOUNT][per]['seconds'])
        vol  = int(self.cf_periods[self.gACCOUNT][per]['volume'])
        # sanity check    
        if (0 !=  secs)  and  (0 != vol) :
            raise ValueError("copy_rates_from: please implement " + per + " " + str(secs) + " " + str(vol) )

        # TODO re-enable maybe later once T60 cmp with S60 is needed again    
        # if 0 < vol :
        #     for locper in self.cf_periods[self.gACCOUNT]:        
        #         perTsec = int(self.cf_periods[self.gACCOUNT][locper]['seconds'])
        #         if vol == perTsec : 
        #             start = dt_from
        #             end   = dt_from - timedelta(seconds=(count * perTsec ))
        #             strstart = start.strftime("%Y-%m-%d %H:%M:%S")
        #             strend   = end.  strftime("%Y-%m-%d %H:%M:%S")
        #             df = df.loc[strstart:strend]
        #             lendf    = len(df)
        #             if 0 >= lendf :
        #                 raise ValueError("copy_rates_from: df does not exists " + sym + " "  + per + " " + str(dt_from) + " " + str(lendf) )
        #             # e.g. for T60 -> M1    
        #             count = int( lendf / vol )
        #             if self.gVerbose: print( _sprintf("%s %s [%s : %s] %d %d ",per, locper, strstart,strend,count, lendf) )
        #             break        

        if 0 <vol:
            df    = df.iloc[0:((vol*count))]
            if 'T3600' != per:
                if len(df) != count*vol:
                    raise ValueError(_sprintf("copy_rates_from: len(df) != count*vol - %d != %d ", len(df), count*vol) )
                
    
        if 0 < secs :
            start = dt_from
            end   = dt_from - timedelta(seconds=(count * secs ))
            strstart = start.strftime("%Y-%m-%d %H:%M:%S.000")
            strend   = end.  strftime("%Y-%m-%d %H:%M:%S.000")
            #df = df.loc[strend:strstart]
            # https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.loc.html
            df.loc[(df.DTMS >= strend) & (df.DTMS <= strstart)]
            
            '''
            df
            Out[60]: 
                                     index                    DTMS  ...    tdmsc     price
            DTMS                                                    ...                   
            2025-01-07 15:26:11.206  58492 2025-01-07 15:26:11.206  ...    223.0  1.040155
            2025-01-07 15:26:10.983  58491 2025-01-07 15:26:10.983  ...    288.0  1.040160
            2025-01-07 15:26:10.695  58490 2025-01-07 15:26:10.695  ...    385.0  1.040155
            2025-01-07 15:26:10.310  58489 2025-01-07 15:26:10.310  ...    384.0  1.040160
            2025-01-07 15:26:09.926  58488 2025-01-07 15:26:09.926  ...    383.0  1.040165
                                   ...                     ...  ...      ...       ...
            2025-01-07 00:05:41.060      4 2025-01-07 00:05:41.060  ...    225.0  1.038680
            2025-01-07 00:05:40.835      3 2025-01-07 00:05:40.835  ...    255.0  1.038645
            2025-01-07 00:05:40.580      2 2025-01-07 00:05:40.580  ...    512.0  1.038650
            2025-01-07 00:05:40.068      1 2025-01-07 00:05:40.068  ...  31649.0  1.038775
            2025-01-07 00:05:08.419      0 2025-01-07 00:05:08.419  ...      0.0  1.038875
            
            [58493 rows x 13 columns]
            
            df.loc[(df.DTMS >= strend) & (df.DTMS <= strstart)]
            Out[61]: 
                                     index                    DTMS  ...   tdmsc     price
            DTMS                                                    ...                  
            2025-01-07 15:26:11.206  58492 2025-01-07 15:26:11.206  ...   223.0  1.040155
            2025-01-07 15:26:10.983  58491 2025-01-07 15:26:10.983  ...   288.0  1.040160
            2025-01-07 15:26:10.695  58490 2025-01-07 15:26:10.695  ...   385.0  1.040155
            2025-01-07 15:26:10.310  58489 2025-01-07 15:26:10.310  ...   384.0  1.040160
            2025-01-07 15:26:09.926  58488 2025-01-07 15:26:09.926  ...   383.0  1.040165
                                   ...                     ...  ...     ...       ...
            2025-01-07 15:25:16.966  58364 2025-01-07 15:25:16.966  ...   736.0  1.040260
            2025-01-07 15:25:16.230  58363 2025-01-07 15:25:16.230  ...   159.0  1.040255
            2025-01-07 15:25:16.071  58362 2025-01-07 15:25:16.071  ...   992.0  1.040250
            2025-01-07 15:25:15.079  58361 2025-01-07 15:25:15.079  ...  2945.0  1.040250
            2025-01-07 15:25:12.134  58360 2025-01-07 15:25:12.134  ...   192.0  1.040255
            
            [133 rows x 13 columns]
            
            strstart
            Out[62]: '2025-01-07 15:26:12.000'
            
            
            strend
            Out[64]: '2025-01-07 15:25:12.000'
            
            '''            
            
            # TODO TICKS kaputt  -  limit the size of df here for smaller periods
            ## do NOT set lendf here !!! as the .index of the partial df.loc[strstart:strend]
            ##  is still the same as of the total df
            ## lendf    = len(df)
            if 0 >= len(df) :
                print( _sprintf("%s [%s : %s] %d %d ",per, strstart, strend, count, len(df)) )
                raise ValueError("copy_rates_from: df does not exists " + sym + " "  + per + " " + str(dt_from) + " " + str(lendf) )
            
            if self.gVerbose: print( _sprintf("%s [%s : %s] %d %d ",per, strstart, strend, count, len(df)) )
    
        # if 0 < secs :


        # #
        # # start cleanup kalman code later
        # #
        # dfkal = df[::-1]['price']
        # #self.gNpa = gNPA
        # #gNPAoffset = gNpaPrice[len(gNPA)-1] * np.ones(len(gNPA))
        # # if None == gNpaPrice0[sym]:
        # #     gNpaPrice0[sym] = gNpaPrice[0]
        # # TODO do not remember the first ever price
        # gNpaPrice0 = dfkal[0]
            
        # gNPAoffset = gNpaPrice0 * np.ones(len(df))
        # #t = np.arange(0, len(gNPA), 1)
        # points = self.cf_symbols[self.gACCOUNT][sym]['points']
        # gRealTrack = (dfkal - gNPAoffset)/points
        # #gRealTrack = gNpaPrice

        # # take algo system settings here        
        # self.gKalmanDt         = 0.01
        # self.gKalmanU          = 2
        # self.gKalmanStdDevAcc  = 25
        # self.gKalmanStdDevMeas = 1.2
        # self.gKalmanChartIntervalInSeconds = 60
        # gPredictions = self.calc_kalman_predictions(gRealTrack)
        
        # tarr = np.squeeze(np.flip(gPredictions))
        # tarr = np.around( tarr )
            
        # df.insert(2, 'pd', tarr)
        # print( per, (vol*count), len(df), df['pd'])

        # #
        # # end cleanup kalman code later
        # #



        # TODO TICKS kaputt
        fuzzy_cnt = 0

        # create numpy array
        dtype = np.dtype([('time', '<i8'), ('time_msc', '<i8'), ('volume', '<u8'),\
                          ('open', '<f8'), ('high', '<f8'), ('low', '<f8'), ('close', '<f8'),\
                          ('openbid', '<f8'), ('highbid', '<f8'), ('lowbid', '<f8'), ('closebid', '<f8'),\
                          ('openspread', '<f8'), ('highspread', '<f8'), ('lowspread', '<f8'), ('closespread', '<f8'),\
                          ('opentdmsc', '<f8'), ('hightdmsc', '<f8'), ('lowtdmsc', '<f8'), ('closetdmsc', '<f8'),\
                          ('pdopen', '<f8'), ('pdhigh', '<f8'), ('pdlow', '<f8'), ('pdclose', '<f8') ])
        npa = np.zeros(count, dtype=dtype)
        # =============================================================================
        #     adjust dtypes    
        #     T233_AUDCAD
        #     [('time', '<i8'), ('time_msc', '<i8'), ('volume', '<u8'), ('open', '<f8'), ('high', '<f8'), ('low', '<f8'), ('close', '<f8'), ('openbid', '<f8'), ('highbid', '<f8'), ('lowbid', '<f8'), ('closebid', '<f8'), ('openspread', '<f8'), ('highspread', '<f8'), ('lowspread', '<f8'), ('closespread', '<f8'), ('opentdmsc', '<f8'), ('hightdmsc', '<f8'), ('lowtdmsc', '<f8'), ('closetdmsc', '<f8')])
        #     M1_AUDCAD    
        #     [('time', '<i8'), ('open', '<f8'), ('high', '<f8'), ('low', '<f8'), ('close', '<f8'), ('tick_volume', '<u8'), ('spread', '<i4'), ('real_volume', '<u8')]
        # =============================================================================
        
        cnt = 0
        
        while cnt < count:
    
            if 0 < vol :
                # =============================================================================
                #         start      = cnt * vol
                #         end        = cnt * vol + vol - 1
                #         dfstart    = df.iloc[start]
                #         dfend      = df.iloc[end]
                #         dfstartend = df.iloc[start:end]
                # =============================================================================
                start      = cnt * vol
                end        = cnt * vol + vol - 1
                
                #
                # TODO FIXME make this optional DT_TO starts at beginning of the day
                #
                if lendf <= start:
                    break
                if lendf <= end:
                    end = lendf-1
                    
                strstart = df.iloc[start]['DTMS'].strftime("%Y-%m-%d %H:%M:%S")
                strend   = df.iloc[end  ]['DTMS'].strftime("%Y-%m-%d %H:%M:%S")
                
                dfstart    = df.iloc[start]
                dfend      = df.iloc[end]
                # add exception for vol = 1,  where start == end
                if (1 == vol) and (start==end):
                    dfstartend = df.iloc[start]
                elif (start==end):
                    # TODO FIXME this shall not happen in first place, where is the data?
                    dfstartend = df.iloc[start]
                else:                    
                    dfstartend = df.iloc[start:(end+1)]
                if 1 < self.gVerbose: print( _sprintf(" cnt[%d] vol[%d] start[%d] : end[%s]",cnt, vol, start,end))
                # TODO TICKS kaputt
                # https://stackoverflow.com/questions/944700/how-can-i-check-for-nan-values
                fuzzy_cnt = 0
                num = dfstartend.tdmsc.max()
                if num == num:
                    fuzzy_cnt = int(num/1000)
                if self.get_ticks_max_gap_in_secs( per ) < fuzzy_cnt :
                    break
    
            # END if 0 < vol :
    
            if 0 < secs :
                # =============================================================================
                # strst=(dt_from-timedelta(seconds=0)).strftime("%Y-%m-%d %H:%M:%S")
                # Out[47]: '2020-12-11 17:00:00'
                # 
                # stren=(dt_from-timedelta(seconds=60)).strftime("%Y-%m-%d %H:%M:%S")
                # Out[48]: '2020-12-11 16:59:00'
                # 
                # df.loc[strst:stren]
                # Out[51]: 
                #                          index                    DTMS  ...  spread    tdmsc
                # DTMS                                                    ...                 
                # 2020-12-11 16:59:58.307   4870 2020-12-11 16:59:58.307  ...     3.0   1226.0
                # 2020-12-11 16:59:57.081   4869 2020-12-11 16:59:57.081  ...     2.0     63.0
                # ...
                # 2020-12-11 16:59:03.264   4835 2020-12-11 16:59:03.264  ...     3.0   3012.0
                # 2020-12-11 16:59:00.252   4834 2020-12-11 16:59:00.252  ...     3.0   1095.0
                # 
                # [37 rows x 12 columns]
                # =============================================================================
        
                start = dt_from - timedelta(seconds=(cnt * secs))
                end   = dt_from - timedelta(seconds=(cnt * secs + secs))
                # datetime.datetime(2020, 12, 11, 17, 0, tzinfo=<StaticTzInfo 'Etc/UTC'>)
                # '2020-12-11 17:00:00'
                if 1 < self.gVerbose: print( _sprintf(" START[%s] END[%s]",start, end))
                
                startidx = 0
                endidx   = 0
                
                fuzzy_cnt = 0
                while True:
                    strstart = (start-timedelta(seconds=fuzzy_cnt)).strftime("%Y-%m-%d %H:%M:%S")
                    lenstrstart = len(df.loc[strstart])
                    if 1 < self.gVerbose: print( _sprintf("  start %d - %s",lenstrstart,strstart))
                    if 0 < lenstrstart :
                        if 1 < self.gVerbose: print( _sprintf("   S %d %d %d - %s",cnt, lenstrstart, fuzzy_cnt, strstart))
                        # example for M1  -  secs = 60
                        # 0 '2020-12-11 17:00:00'
                        # 1 '2020-12-11 16:59:58'
                        # 2 '2020-12-11 16:59:58'
                        '''
                        # TODO
                        #  improve partial key indexing performance
                        #  Indexing for entries in a series or dataframe with a multi-index has dramatically worse performance when using partial keys.  
                        # https://github.com/pandas-dev/pandas/issues/38650
                        # https://github.com/pandas-dev/pandas/issues/45681
                        %timeit gH.gDF['TICKS']['EURUSD'].loc['2025-04-30 17:29'].iloc[-1]['index']
                            1.38 ms ± 22.6 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
                        
                        %timeit gH.gDF['TICKS']['EURUSD'].loc['2025-04-30 17:29:32'].iloc[-1]['index']
                            1.37 ms ± 12.4 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
                        '''
                        startidx = df.loc[strstart].iloc[lenstrstart-1]['index']
                        startidx = lendf - startidx - 1
                        break
                    fuzzy_cnt = fuzzy_cnt + 1
                    # TODO TICKS kaputt
                    if self.get_ticks_max_gap_in_secs( per ) < fuzzy_cnt:
                        break
        
                fuzzy_cnt = 0
                while True:
                    strend = (end+timedelta(seconds=fuzzy_cnt)).strftime("%Y-%m-%d %H:%M:%S")
                    
                    if start < end+timedelta(seconds=fuzzy_cnt):
                        # S1 [2021-01-21 18:16:39 : 2021-01-21 18:16:29] 10 37 
                        #  START[2021-01-21 18:16:39.940781+00:00] END[2021-01-21 18:16:38.940781+00:00]
                        #   start 0 - 2021-01-21 18:16:39
                        #   start 0 - 2021-01-21 18:16:38
                        #   start 3 - 2021-01-21 18:16:37
                        #    S 0 3 2 - 2021-01-21 18:16:37
                        #   end   0 - 2021-01-21 18:16:38
                        #   end   0 - 2021-01-21 18:16:39
                        #   end   0 - 2021-01-21 18:16:40
                        #   end   0 - 2021-01-21 18:16:41
                        #   end   0 - 2021-01-21 18:16:42
                        #   end   0 - 2021-01-21 18:16:43
                        #   end   0 - 2021-01-21 18:16:44
                        #   end   0 - 2021-01-21 18:17:25
                        endidx = startidx
                        break
                    
                    lenstrend = len(df.loc[strend]) 
                    if 1 < self.gVerbose: print( _sprintf("  end   %d - %s",lenstrend,strend))
                    if 0 < lenstrend :
                        if 1 < self.gVerbose: print( _sprintf("   E %d %d %d - %s",cnt, lenstrstart, fuzzy_cnt, strend))
                        # example for M1  -  secs = 60
                        # 0 '2020-12-11 16:59:00'
                        # 1 '2020-12-11 16:59:01'
                        # 2 '2020-12-11 16:59:02'
                        endidx = df.loc[strend].iloc[lenstrend-1]['index']
                        endidx = lendf - endidx - 1
                        break
                    fuzzy_cnt = fuzzy_cnt + 1
                    # TODO TICKS kaputt
                    if self.get_ticks_max_gap_in_secs( per ) < fuzzy_cnt:
                        break
                  
                # TODO TICKS kaputt
                if self.get_ticks_max_gap_in_secs( per ) < fuzzy_cnt:
                    break
    
                    
                # =============================================================================
                # df.loc['2020-12-11 16:57:00']
                # Out[63]: 
                #                          index                    DTMS  ...  spread  tdmsc
                # DTMS                                                    ...               
                # 2020-12-11 16:57:00.824   4684 2020-12-11 16:57:00.824  ...     3.0   69.0
                # 2020-12-11 16:57:00.755   4683 2020-12-11 16:57:00.755  ...     1.0   51.0
                # 2020-12-11 16:57:00.704   4682 2020-12-11 16:57:00.704  ...     2.0  191.0
                # 2020-12-11 16:57:00.513   4681 2020-12-11 16:57:00.513  ...     3.0   47.0
                # 2020-12-11 16:57:00.466   4680 2020-12-11 16:57:00.466  ...     2.0  142.0
                # 2020-12-11 16:57:00.324   4679 2020-12-11 16:57:00.324  ...     3.0  276.0
                # 2020-12-11 16:57:00.048   4678 2020-12-11 16:57:00.048  ...     4.0  133.0
                # 
                # [7 rows x 12 columns]            
                #      
                # len(df.loc['2020-12-11 16:57:00'])
                # Out[79]: 7
                # 
                # df.loc['2020-12-11 16:57:00'].iloc[7-1]
                # Out[81]: 
                # index                                4678
                # DTMS           2020-12-11 16:57:00.048000
                # time                           1607705820
                # bid                               103.996
                # ask                                   104
                # last                                    0
                # volume                                  0
                # time_msc                    1607705820048
                # flags                                 130
                # volume_real                             0
                # spread                                  4
                # tdmsc                                 133
                # Name: 2020-12-11 16:57:00.048000, dtype: object
                # 
                # df.loc['2020-12-11 16:57:00'].iloc[7-1]['index']
                # Out[82]: 4678
                # 
                # len(df)
                # Out[83]: 4871
                # 
                # df.iloc[4871-4678-1]
                # Out[84]: 
                # index                                4678
                # DTMS           2020-12-11 16:57:00.048000
                # time                           1607705820
                # bid                               103.996
                # ask                                   104
                # last                                    0
                # volume                                  0
                # time_msc                    1607705820048
                # flags                                 130
                # volume_real                             0
                # spread                                  4
                # tdmsc                                 133
                # Name: 2020-12-11 16:57:00.048000, dtype: object
                # 
                # =============================================================================
                
                if 1 < self.gVerbose: print( '    RES: '  + str(cnt) + '  '  + str(startidx) + ' : ' + str(endidx) + '  -  ' + strstart + ' : ' + strend )
                dfstart    = df.iloc[startidx]
                dfend      = df.iloc[endidx]

                # # TODO TICKS kaputt
                # if strstart == strend:
                #     strerror = _sprintf("CONTINUE strstart[%s] == strend[%s] within range[%s:%s]",strstart, strend, start, end)
                #     print( strerror )
                #     continue
                if strstart == strend:
                    if startidx == endidx:
                        dfstartend = df.iloc[startidx]
                    else:
                        strerror = _sprintf("CONTINUE strstart[%s] == strend[%s] within range[%s:%s]",strstart, strend, start, end)
                        raise( ValueError( strerror))
                elif startidx == endidx:
                    dfstartend = df.iloc[endidx]
                elif startidx > endidx:
                    dfstartend = df.iloc[endidx]
                    # S5 [2021-01-15 08:27:00 : 2021-01-15 08:26:10] 10 62 
                    # START 2021-01-15 08:27:00+00:00 2021-01-15 08:26:55+00:00
                    # 0 - 2021-01-15 08:27:00
                    # 1 - 2021-01-15 08:26:59
                    # S 0 1 1 - 2021-01-15 08:26:59
                    # E 0 1 1 - 2021-01-15 08:26:56
                    # 0  0 : 5  -  2021-01-15 08:26:59 : 2021-01-15 08:26:56
                    # START 2021-01-15 08:26:55+00:00 2021-01-15 08:26:50+00:00
                    # 0 - 2021-01-15 08:26:55
                    # 2 - 2021-01-15 08:26:54
                    # S 1 2 1 - 2021-01-15 08:26:54
                    # E 1 2 0 - 2021-01-15 08:26:50
                    # 1  7 : 11  -  2021-01-15 08:26:54 : 2021-01-15 08:26:50
                    # START 2021-01-15 08:26:50+00:00 2021-01-15 08:26:45+00:00
                    # 1 - 2021-01-15 08:26:50
                    # S 2 1 0 - 2021-01-15 08:26:50
                    # E 2 1 0 - 2021-01-15 08:26:45
                    # 2  11 : 21  -  2021-01-15 08:26:50 : 2021-01-15 08:26:45
                    # START 2021-01-15 08:26:45+00:00 2021-01-15 08:26:40+00:00
                    # 1 - 2021-01-15 08:26:45
                    # S 3 1 0 - 2021-01-15 08:26:45
                    # E 3 1 0 - 2021-01-15 08:26:40
                    # 3  21 : 23  -  2021-01-15 08:26:45 : 2021-01-15 08:26:40
                    # START 2021-01-15 08:26:40+00:00 2021-01-15 08:26:35+00:00
                    # 1 - 2021-01-15 08:26:40
                    # S 4 1 0 - 2021-01-15 08:26:40
                    # E 4 1 0 - 2021-01-15 08:26:35
                    # 4  23 : 26  -  2021-01-15 08:26:40 : 2021-01-15 08:26:35
                    # START 2021-01-15 08:26:35+00:00 2021-01-15 08:26:30+00:00
                    # 1 - 2021-01-15 08:26:35
                    # S 5 1 0 - 2021-01-15 08:26:35
                    # E 5 1 4 - 2021-01-15 08:26:34
                    # 5  26 : 29  -  2021-01-15 08:26:35 : 2021-01-15 08:26:34
                    # START 2021-01-15 08:26:30+00:00 2021-01-15 08:26:25+00:00
                    # 0 - 2021-01-15 08:26:30
                    # 1 - 2021-01-15 08:26:29
                    # S 6 1 1 - 2021-01-15 08:26:29
                    # E 6 1 0 - 2021-01-15 08:26:25
                    # 6  30 : 40  -  2021-01-15 08:26:29 : 2021-01-15 08:26:25
                    # START 2021-01-15 08:26:25+00:00 2021-01-15 08:26:20+00:00
                    # 3 - 2021-01-15 08:26:25
                    # S 7 3 0 - 2021-01-15 08:26:25
                    # E 7 3 2 - 2021-01-15 08:26:22
                    # 7  40 : 44  -  2021-01-15 08:26:25 : 2021-01-15 08:26:22
                    # START 2021-01-15 08:26:20+00:00 2021-01-15 08:26:15+00:00
                    # 0 - 2021-01-15 08:26:20
                    # 0 - 2021-01-15 08:26:19
                    # 0 - 2021-01-15 08:26:18
                    # 0 - 2021-01-15 08:26:17
                    # 0 - 2021-01-15 08:26:16
                    # 0 - 2021-01-15 08:26:15
                    # 2 - 2021-01-15 08:26:14
                    # S 8 2 6 - 2021-01-15 08:26:14
                    # E 8 2 7 - 2021-01-15 08:26:22
                    # 8  46 : 44  -  2021-01-15 08:26:14 : 2021-01-15 08:26:22
                    # START 2021-01-15 08:26:15+00:00 2021-01-15 08:26:10+00:00
                    # 0 - 2021-01-15 08:26:15
                    # 2 - 2021-01-15 08:26:14
                    # S 9 2 1 - 2021-01-15 08:26:14
                    # E 9 2 0 - 2021-01-15 08:26:10
                    # 9  46 : 61  -  2021-01-15 08:26:14 : 2021-01-15 08:26:10
                    #
                    #     at0.run_now(datetime(2021,1,15,8,27, tzinfo=timezone.utc), 'GBPJPY')
                    
                else:    
                    # normal case
                    dfstartend = df.iloc[startidx:endidx]
                
                
            # END if 0 < secs :
            
            # TODO TICKS kaputt
            # =============================================================================
            # additional to the above TICKS gap errors the following cases are not #
            # detected by fuzzy_cnt. hence re-check the df on the broad general basis
            # and print error 
            # T300 M5  [2020-12-24 19:00:00 : 2020-12-24 18:10:00] 7 2278 
            # T300     [2020-12-24 19:00:00 : 2020-12-24 18:10:00] 7 2278 TICKS kaputt
            # T900 M15 [2020-12-24 19:00:00 : 2020-12-24 16:30:00] 2 2278 
            # T900     [2020-12-24 19:00:00 : 2020-12-24 16:30:00] 2 2278 TICKS kaputt
            # =============================================================================
            
            # TODO TICKS kaputt
            # https://stackoverflow.com/questions/944700/how-can-i-check-for-nan-values
            fuzzy_cnt = 0
            num = dfstartend.tdmsc.max()
            if num == num:
                fuzzy_cnt = int(num/1000)
            # TODO re-work me in a different way
            if self.get_ticks_max_gap_in_secs( 'TICKS' ) < fuzzy_cnt :
                if self.goLive: print( _sprintf("%s %s [%s : %s] %d %d %d TICKS kaputt", sym, per, strstart,strend,len(npa), lendf, fuzzy_cnt) )
    
            time      = dfend.time
            time_msc  = dfend.time_msc
            if 0 < vol :
                volume    = vol
            if 0 < secs :
                volume    = len(dfstartend)
            
            # closeask  = dfstart.ask
            # highask   = dfstartend.ask.max()
            # lowask    = dfstartend.ask.min()
            # openask   = dfend.ask
            closeprice= dfstartend.iloc[0].price
            highprice = dfstartend.price.max()
            lowprice  = dfstartend.price.min()
            openprice = dfstartend.iloc[-1].price
            #if per == 'T5':
            #    print(openprice,highprice,lowprice, closeprice)
            #    print(dfstartend)
            
            closebid  = dfstart.bid
            highbid   = dfstartend.bid.max()
            lowbid    = dfstartend.bid.min()
            openbid   = dfend.bid
    
            closespread = dfstart.spread
            highspread  = dfstartend.spread.max()
            lowspread   = dfstartend.spread.min()
            openspread  = dfend.spread
    
            closetdmsc  = dfstart.tdmsc
            hightdmsc   = dfstartend.tdmsc.max()
            lowtdmsc    = dfstartend.tdmsc.min()
            opentdmsc   = dfend.tdmsc
    
            #arr_reversed_idx
            ari = count - 1 - cnt
            npa[ari]['time']     = time
            npa[ari]['time_msc'] = time_msc
            npa[ari]['volume']   = volume
            
            # npa[ari]['open']     = openask
            # npa[ari]['high']     = highask
            # npa[ari]['low']      = lowask
            # npa[ari]['close']    = closeask
            npa[ari]['open']     = openprice
            npa[ari]['high']     = highprice
            npa[ari]['low']      = lowprice
            npa[ari]['close']    = closeprice
    
            npa[ari]['openbid']  = openbid
            npa[ari]['highbid']  = highbid
            npa[ari]['lowbid']   = lowbid
            npa[ari]['closebid'] = closebid
    
            npa[ari]['openspread']  = openspread
            npa[ari]['highspread']  = highspread
            npa[ari]['lowspread']   = lowspread
            npa[ari]['closespread'] = closespread
    
            npa[ari]['opentdmsc']  = opentdmsc
            npa[ari]['hightdmsc']  = hightdmsc
            npa[ari]['lowtdmsc']   = lowtdmsc
            npa[ari]['closetdmsc'] = closetdmsc

            # npa[ari]['pdopen']     = openask
            # npa[ari]['pdhigh']     = highask
            # npa[ari]['pdlow']      = lowask
            # npa[ari]['pdclose']    = closeask
            npa[ari]['pdopen']     = openprice
            npa[ari]['pdhigh']     = highprice
            npa[ari]['pdlow']      = lowprice
            npa[ari]['pdclose']    = closeprice
            
            #print ( per + " " + str(cnt)  + " " + str(count) )
            cnt   = cnt + 1
    
        # while cnt < count
    
        # np.isnan(np.sum(npa['time']))
        # npa.dtype
        # Out[133]: dtype([('time', '<i8'), ('time_msc', '<i8'), ('volume', '<u8'), ('open', '<f8'), ('high', '<f8'), ('low', '<f8'), ('close', '<f8'), ('openbid', '<f8'), ('highbid', '<f8'), ('lowbid', '<f8'), ('closebid', '<f8'), ('openspread', '<f8'), ('highspread', '<f8'), ('lowspread', '<f8'), ('closespread', '<f8'), ('opentdmsc', '<f8'), ('hightdmsc', '<f8'), ('lowtdmsc', '<f8'), ('closetdmsc', '<f8')])        
        # https://stackoverflow.com/questions/32256037/numpy-genfromtxt-iterate-over-columns
        # for n in npa.dtype.names: print(n)
        # check for nan
        for n in npa.dtype.names:
            if np.isnan(np.sum(npa[n])):
                print( start, end, df.iloc[start:end], dfstart, dfstartend, dfend )
                self.gNpa = df
                strerror = _sprintf("NAN ERROR per[%s] strstart[%s] strend[%s] within range[%s:%s] within column[%s] %s",per, strstart, strend, start, end, n, str(npa[n]))
                raise( ValueError( strerror))
           
        
        # TODO TICKS kaputt
        # =============================================================================
        # debug pickle file : 20201224_190000_ticks_gap.zip at UTC tz
        # all cases for secs and vol period frames where fuzzy_cnt
        # has detected an TICKS gap error
        # T3600 H1 [2020-12-24 19:00:00 : 2020-12-24 09:00:00] 12 44044 
        # T3600    [2020-12-24 19:00:00 : 2020-12-24 09:00:00] 0  44044 TICKS kaputt
        # M5       [2020-12-24 19:00:00 : 2020-12-24 18:10:00] 10 2278 
        # M5       [2020-12-24 18:25:00 : 2020-12-24 18:22:00] 7  44044 TICKS kaputt
        # M15      [2020-12-24 19:00:00 : 2020-12-24 16:30:00] 10 2278 
        # M15      [2020-12-24 18:30:00 : 2020-12-24 18:17:00] 2  44044 TICKS kaputt
        # H1       [2020-12-24 19:00:00 : 2020-12-24 09:00:00] 10 44044 
        # H1       [2020-12-24 18:59:59 : 2020-12-24 18:02:00] 0  44044 TICKS kaputt    
        # =============================================================================
        if self.get_ticks_max_gap_in_secs( per ) < fuzzy_cnt:
            # count -> lennpa -> len(npa)
            npa = np.delete(npa,np.s_[0:(count-cnt):],axis=0)
    
        # TODO TICKS kaputt - keep this order with lennpa
        lennpa = len(npa)
    
        # TODO TICKS kaputt - keep this order with creating df
        df = {}
        if 0 < lennpa :
            df = pd.DataFrame(npa)
            df.insert(0,"TDms",(df.shift(-1).time_msc-df.time_msc))
            df.loc[(lennpa-1),'TDms'] = int((dt_from.timestamp()*1000)-df.loc[(lennpa-1),'time_msc'])
            df.insert(0,"TDs", (df.shift(-1).time-df.time))
            df.loc[(lennpa-1),'TDs'] = int(dt_from.timestamp()-df.loc[(lennpa-1),'time'])

            lenprev = len(df) 
        
            # TODO comment the EXCEL funcs here - do we still need them
            # df = self.set_excel_func_to_df(df,self.cf_symbols[self.gACCOUNT][sym],sym,per)
            # # P - Popen, Phigh, Plow, Pclose
            # idx = 0   # 0 points at first element
            # dfidx = df.close
            # gc0 = dfidx.loc[idx]
            # points = self.cf_symbols[self.gACCOUNT][sym]['points']
            # df['Popen']  = ( df.open  - gc0 ) / points
            # df['Phigh']  = ( df.high  - gc0 ) / points
            # df['Plow']   = ( df.low   - gc0 ) / points
            # df['Pclose'] = ( df.close - gc0 ) / points
            ## df.loc[0,'Popen']=0
            ## df.loc[0,'Phigh']=0
            ## df.loc[0,'Plow']=0
            ## df.loc[0,'Pclose']=0
            
            # TODO NORMalise
            points = self.cf_symbols[self.gACCOUNT][sym]['points']
            gc0 = 0
            if None != self.g_c0[sym]:
                gc0 = self.g_c0[sym]
                df['Popen']  = ( df.open  - gc0 ) / points
                df['Phigh']  = ( df.high  - gc0 ) / points
                df['Plow']   = ( df.low   - gc0 ) / points
                df['Pclose'] = ( df.close - gc0 ) / points
            else:
                df['Popen']  = gc0
                df['Phigh']  = gc0
                df['Plow']   = gc0
                df['Pclose'] = gc0
        
            lenpost = len(df) 
            if lenprev != lenpost:
                raise ValueError( _sprintf("ERROR: lenprev[%d] != lenpost[%d]: ", lenprev, lenpost) )

            if True == self.gUseScalp:
                # remove the ScalpOffset from the df
                # meaning removes row 0..34
                df = df[self.gScalpOffset:]
            
           
            # mod index
            # convert to itself (column) from epoch to datetime string 
            df.insert(0,"DT",pd.to_datetime(df['time_msc'], unit='ms'))
            df.reset_index(level=0, inplace=False)
            df.set_index(['DT'],drop=False,inplace=False)

            # orig index
            #df.insert(0,"DT",pd.to_datetime(df['time'], unit='s'))
            #df.reset_index(level=0, inplace=True)
            #df.set_index(['DT'],drop=False,inplace=True)
            
            #
            # datetime closing time value df.DTC  (nb datetime opening value is df.DT)
            #
            # https://stackoverflow.com/questions/13703720/converting-between-datetime-timestamp-and-datetime64
            # https://stackoverflow.com/questions/22800079/converting-time-zone-pandas-dataframe
            dfdtc = pd.to_datetime(df['time_msc'].shift(-1), unit='ms')
            dfdtc[dfdtc.index[-1]] = pd.to_datetime(dt_from).tz_convert(None)
            df.insert(1,"DTC",dfdtc)
            '''
            df.DT
            Out[224]: 
            DT
            2025-01-07 16:50:02.745   2025-01-07 16:50:02.745
            2025-01-07 16:50:46.425   2025-01-07 16:50:46.425
            2025-01-07 16:52:06.585   2025-01-07 16:52:06.585
            2025-01-07 16:53:08.164   2025-01-07 16:53:08.164
            2025-01-07 16:54:20.133   2025-01-07 16:54:20.133
            2025-01-07 16:55:34.244   2025-01-07 16:55:34.244
            2025-01-07 16:56:23.012   2025-01-07 16:56:23.012
            2025-01-07 16:57:29.636   2025-01-07 16:57:29.636
            2025-01-07 16:58:31.492   2025-01-07 16:58:31.492
            2025-01-07 16:59:23.204   2025-01-07 16:59:23.204
            Name: DT, dtype: datetime64[ns]
            
            df.DTC
            Out[225]: 
            DT
            2025-01-07 16:50:02.745   2025-01-07 16:50:46.424999936
            2025-01-07 16:50:46.425   2025-01-07 16:52:06.584999936
            2025-01-07 16:52:06.585   2025-01-07 16:53:08.164000000
            2025-01-07 16:53:08.164   2025-01-07 16:54:20.132999936
            2025-01-07 16:54:20.133   2025-01-07 16:55:34.244000000
            2025-01-07 16:55:34.244   2025-01-07 16:56:23.012000000
            2025-01-07 16:56:23.012   2025-01-07 16:57:29.636000000
            2025-01-07 16:57:29.636   2025-01-07 16:58:31.492000000
            2025-01-07 16:58:31.492   2025-01-07 16:59:23.204000000
            2025-01-07 16:59:23.204   2025-01-07 17:00:02.000000000
            Name: DTC, dtype: datetime64[ns]
            '''
            
            # example test for retrieving df on ipython console
            # df = gH.gDF['RATES']['2025-01-07 17:00:02+00:00']['T100']['EURUSD']
            
            #
            # start cleanup kalman code later
            #
            dfkal = df['Pclose']
            #self.gNpa = gNPA
            #gNPAoffset = gNpaPrice[len(gNPA)-1] * np.ones(len(gNPA))
            # if None == gNpaPrice0[sym]:
            #     gNpaPrice0[sym] = gNpaPrice[0]
            # TODO do not remember the first ever price
            gNpaPrice0 = dfkal[0]
                
            gNPAoffset = gNpaPrice0 * np.ones(len(df))
            #t = np.arange(0, len(gNPA), 1)
            #gRealTrack = (dfkal - gNpaPrice0)/points
            gRealTrack = (dfkal - gNpaPrice0)
    
            #
            # start filterpy
            #
            # https://github.com/rlabbe/filterpy
            my_filter = KalmanFilterFilterPy(dim_x=2, dim_z=1)
            # Initialize the filter's matrices.
            
            my_filter.x = np.array([[2.],
                            [0.]])       # initial state (location and velocity)
            
            my_filter.F = np.array([[1.,1.],
                            [0.,1.]])    # state transition matrix
            
            my_filter.H = np.array([[1.,0.]])    # Measurement function
            my_filter.P *= 1000.                 # covariance matrix
            my_filter.R = 5                      # state uncertainty
            my_filter.Q = Q_discrete_white_noise(dim=2, dt=0.1, var=0.1) # process uncertainty

            # filter data with Kalman filter, than run smoother on it
            # https://github.com/rlabbe/Kalman-and-Bayesian-Filters-in-Python/blob/master/13-Smoothing.ipynb
            mu, cov, _, _ = my_filter.batch_filter(gRealTrack)
            M, P, C, _ = my_filter.rts_smoother(mu, cov)
            
            # measurement values
            index = 0
            # velocity values
            #index = 1

            # KF values
            tarr = np.squeeze(mu[:, index])
            tarr = np.around( tarr )
            tarr = tarr + gNpaPrice0
            #tarr = tarr.astype( np.int64)
            df.insert(2, 'pd', tarr)

            # RTS smoother
            tarr = np.squeeze(M[:, index])
            tarr = np.around( tarr )
            tarr = tarr + gNpaPrice0
            #tarr = tarr.astype( np.int64)
            df.insert(2, 'ps', tarr)
            

            #print( sym, per, gRealTrack, df['pd'], df['ps'], df.close[0] )

            #
            # end cleanup kalman code later
            #
            
            
            
            self.set_df_rates( dt_from, per, sym, df )
        
        return df
    
    # def copy_rates_from(sym,per,dt_from,count):
    # =============================================================================

    # =============================================================================
    # def _calculate_atr(atr_length, highs, lows, closes):
    #     
    # =============================================================================
    def _calculate_atr( self, atr_length, highs, lows, closes):
        """Calculate the average true range
        atr_length : time period to calculate over
        all_highs : list of highs
        all_lows : list of lows
        all_closes : list of closes
        """
        if atr_length < 1:
            raise ValueError("Specified atr_length may not be less than 1")
        elif atr_length >= len(closes):
            raise ValueError("Specified atr_length is larger than the length of the dataset: " + str(len(closes)))
        atr = 0
        for i in range(len(highs)-atr_length, len(highs)):
            high = highs[i]
            low = lows[i]
            close_prev = closes[i-1]
            tr = max(abs(high-low), abs(high-close_prev), abs(low-close_prev))
            atr += tr
        return atr/atr_length
    # def _calculate_atr(atr_length, highs, lows, closes):
    # =============================================================================
    
    
    # =============================================================================
    # def _calculate_atr(self, atr_length, highs, lows, closes):
    #     
    # =============================================================================
    def calculate_atr( self, df ):
    
        #dates   = mdates.date2num(df.index.to_pydatetime())
        #opens   = df['Popen'].values
        highs   = df['Phigh'].values
        lows    = df['Plow'].values
        closes  = df['Pclose'].values
        
    
        lendata = len(closes)
        atr_length = lendata - 1
        if 1 > atr_length:
            # special case - lendata == 1
            if 1 == lendata:
                df['ATR'] = [ 0 ]
        else:
            
            brick_size = self._calculate_atr(atr_length, highs, lows, closes)
            cdiff = [] # holds the differences between each close and the previously created brick / the brick size
            prev_close_brick = closes[0]
        
            # print( atr_length )
            # print( closes )
            # print( highs )
            # print( lows )
            # print( _sprintf("lendata2: %d brick_size: %d  CLOSES: ", lendata, int(brick_size)) )
            
            for i in range(lendata):
                brick_diff = int((closes[i] - prev_close_brick) / brick_size)
                cdiff.extend([brick_diff])
                #print( _sprintf("i: %d brick_diff: %d closes[i]: %d prev_close_brick %d", i, brick_diff, closes[i], prev_close_brick) )
                prev_close_brick += brick_diff *brick_size
        
            df['ATR'] = cdiff
    
            # lencdiff = len(cdiff)
            # print( _sprintf("lencdiff: %d CDIFF: ", lencdiff) )
            # print( cdiff )
            
    # def _calculate_atr(atr_length, highs, lows, closes):
    # =============================================================================
    

    # =============================================================================
    # def set_excel_func_to_df(df,cf_sym,sym,per):
    #     
    # =============================================================================
    def set_excel_func_to_df(self, df,cf_sym,sym,per):
        
        lendf = len(df)
        
        # # # P - Popen, Phigh, Plow, Pclose
        # idx = 0   # 0 points at first element
        # dfidx = df.close
        # df['Popen']  = ( df.open  - dfidx.loc[idx] ) / cf_sym['points']
        # df['Phigh']  = ( df.high  - dfidx.loc[idx] ) / cf_sym['points']
        # df['Plow']   = ( df.low   - dfidx.loc[idx] ) / cf_sym['points']
        # df['Pclose'] = ( df.close - dfidx.loc[idx] ) / cf_sym['points']
        # # df.loc[0,'Popen']=0
        # # df.loc[0,'Phigh']=0
        # # df.loc[0,'Plow']=0
        # # df.loc[0,'Pclose']=0

        #
        #
        # for documentation see below
        #
        #
        
        # # P - Popen, Phigh, Plow, Pclose
        idx = 0   # 0 points at first element
        idx_is_set = False
        dfidx = df.close

        for cnt in range( len(dfidx) ):
            
            if ( False == idx_is_set ) and (0 < df.open.loc[cnt]):
                idx = cnt
                idx_is_set = True
                
            if 0 < df.open.loc[cnt]:
                df.loc[cnt,'Popen']  = ( df.open.loc[cnt]  - dfidx.loc[idx] ) / cf_sym['points']
                df.loc[cnt,'Phigh']  = ( df.high.loc[cnt]  - dfidx.loc[idx] ) / cf_sym['points']
                df.loc[cnt,'Plow']   = ( df.low.loc[cnt]   - dfidx.loc[idx] ) / cf_sym['points']
                df.loc[cnt,'Pclose'] = ( df.close.loc[cnt] - dfidx.loc[idx] ) / cf_sym['points']
            else:
                df.loc[cnt,'Popen']  = 0
                df.loc[cnt,'Phigh']  = 0
                df.loc[cnt,'Plow']   = 0
                df.loc[cnt,'Pclose'] = 0
                
        # =============================================================================
        # print( "x"*30 )
        # print( "per: " + per )
        # print( "idx: " + str(idx) )
        # print( dfidx )
        # print( df.Popen )
        # print( df.Phigh )
        # print( df.Plow )
        # print( df.Pclose )
        # 
        # xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        # per: T377
        # idx: 7
        # 0    0.00000
        # 1    0.00000
        # 2    0.00000
        # 3    0.00000
        # 4    0.00000
        # 5    0.00000
        # 6    0.00000
        # 7    1.17780
        # 8    1.17767
        # 9    1.17766
        # Name: close, dtype: float64
        # 0     0.0
        # 1     0.0
        # 2     0.0
        # 3     0.0
        # 4     0.0
        # 5     0.0
        # 6     0.0
        # 7     6.0
        # 8     3.0
        # 9   -17.0
        # Name: Popen, dtype: float64
        # 0     0.0
        # 1     0.0
        # 2     0.0
        # 3     0.0
        # 4     0.0
        # 5     0.0
        # 6     0.0
        # 7     5.0
        # 8     7.0
        # 9    18.0
        # Name: Phigh, dtype: float64
        # 0     0.0
        # 1     0.0
        # 2     0.0
        # 3     0.0
        # 4     0.0
        # 5     0.0
        # 6     0.0
        # 7   -12.0
        # 8   -23.0
        # 9   -28.0
        # Name: Plow, dtype: float64
        # 0     0.0
        # 1     0.0
        # 2     0.0
        # 3     0.0
        # 4     0.0
        # 5     0.0
        # 6     0.0
        # 7     0.0
        # 8   -13.0
        # 9   -14.0
        # Name: Pclose, dtype: float64
        # 
        # =============================================================================
        

        #
        # WA scalper implementation
        # Si1Buff[li_104] = ((ld_80-l_low_88)/(l_high_96-l_low_88+0.000001)-0.5)*100;
        #
        if True == self.gUseScalp:
            # take the last element from the scalp array 
            # and start pandas calculations there
            _start = self.gScalpOffset-1
            # _lensc = len(df)
            for keynum in self.gScalpKeyArr: 
                keyH  = 'H'  + str(keynum)
                # df.loc[_start:_lensc,keyH] = df['Pclose'].rolling(keynum).max()
                df[keyH] = df['Pclose'].rolling(keynum).max()
                df.loc[0:_start,     keyH] = 0
                df[keyH] = df[keyH].astype(int)

                keyL  = 'L'  + str(keynum)
                # df.loc[_start:_lensc,keyL] = df['Pclose'].rolling(keynum).min()
                df[keyL] = df['Pclose'].rolling(keynum).min()
                df.loc[0:_start,     keyL] = 0
                df[keyL] = df[keyL].astype(int)

            for keynum in self.gScalpKeyArr: 
                keyH  = 'H'  + str(keynum)
                keyL  = 'L'  + str(keynum)
                keySC = 'SC' + str(keynum)
                # df.loc[_start:_lensc,keySC] = ((df['Pclose']-df[keyL])/(df[keyH]-df[keyL]+0.000001)-0.5)*100
                df[keySC] = ((df['Pclose']-df[keyL])/(df[keyH]-df[keyL]+0.000001)-0.5)*100
                df.loc[0:_start,     keySC] = 0
                df[keySC] = df[keySC].astype(int)
            

        if False == self.gUsePid:
            return df


        # PID1, PID2, PID3, PID4  

        # I - Iopen, Ihigh, Ilow, Iclose
        df['Iopen']  = df.Popen. cumsum()
        df['Ihigh']  = df.Phigh. cumsum()
        df['Ilow']   = df.Plow.  cumsum()
        df['Iclose'] = df.Pclose.cumsum()
        
        # set first index to zero - then start calculating remaining values
        # df['Ihigh']=np.zeros(120)
        # df.loc[1:119,['Ihigh']]=df.Phigh.loc[1:119].cumsum()
    
        # D - Dopen, Dhigh, Dlow, Dclose
        dfidx = df.Pclose
        df['Dopen']  = df.Popen  - dfidx.shift(1)
        df['Dhigh']  = df.Phigh  - dfidx.shift(1)
        df['Dlow']   = df.Plow   - dfidx.shift(1)
        df['Dclose'] = df.Pclose - dfidx.shift(1)
        df.loc[0,'Dopen']=0
        df.loc[0,'Dhigh']=0
        df.loc[0,'Dlow']=0
        df.loc[0,'Dclose']=0

            
        # PID1, PID2, PID3, PID4  
        # for key in self.cf_pid_params[self.gACCOUNT]:
        #     df[key] = df.Popen*self.cf_pid_params[self.gACCOUNT][key]['KP'] + df.Iopen*self.cf_pid_params[self.gACCOUNT][key]['KI'] + df.Dopen*self.cf_pid_params[self.gACCOUNT][key]['KD']
    
        for key in self.cf_pid_params[self.gACCOUNT]:
            df[key] = df.Pclose*self.cf_pid_params[self.gACCOUNT][key]['KP'] + df.Iclose*self.cf_pid_params[self.gACCOUNT][key]['KI'] + df.Dclose*self.cf_pid_params[self.gACCOUNT][key]['KD']
    
        # =============================================================================
        #     # PID1WF, PID2WF, PID3WF, PID4WF
        #     for key in self.cf_pid_params[self.gACCOUNT]:
        #         df[key+'WF'] = df[key].cumsum()
        # 
        #     # PID1WF1, PID2WF1, PID3WF1, PID4WF1
        #     for key in self.cf_pid_params[self.gACCOUNT]:
        #         df[key+'WF1'] = df[key].shift(1).cumsum()
        #         df.loc[0,key+'WF1'] = 0
        # =============================================================================
    
        # PID1x, PID2x, PID3x, PID4x
        for key in self.cf_pid_params[self.gACCOUNT]:
            
            df[key+'_MAX_ALL'] = df[key].cummax()
            # df.loc[0,key+'_MAX_ALL'] = 0
            # if 3 < lendf:
            #     df.loc[1,key+'_MAX_ALL'] = 0
            #     df.loc[2,key+'_MAX_ALL'] = 0
            df[key+'_MIN_ALL'] = df[key].cummin()
            # df.loc[0,key+'_MIN_ALL'] = 0
            # if 3 < lendf:
            #     df.loc[1,key+'_MIN_ALL'] = 0
            #     df.loc[2,key+'_MIN_ALL'] = 0
            df[key+'_MAX_MIN_ALL_2'] = ( df[key+'_MAX_ALL'] + df[key+'_MIN_ALL'] ) / 2
            df[key+'_MAX_MIN_ALL_2_1'] = df[key+'_MAX_MIN_ALL_2'].shift(1)
            df.loc[0,key+'_MAX_MIN_ALL_2_1'] = df.loc[0,key+'_MAX_MIN_ALL_2']
            
            # df[key+'_MAX_MIN_ALL_2_D'] = df[key+'_MAX_MIN_ALL_2'] - df[key+'_MAX_MIN_ALL_2'].shift(1)
            # df.loc[0,key+'_MAX_MIN_ALL_2_D'] = 0
            # df[key+'_MAX_MIN_ALL_2_D_WF'] = df[key+'_MAX_MIN_ALL_2_D'].cumsum()
            # df.loc[0,key+'_MAX_MIN_ALL_2_D_WF'] = 0
            # df[key+'_MAX_MIN_ALL_2_D_WF1'] = df[key+'_MAX_MIN_ALL_2_D'].shift(1).cumsum()
            # df.loc[0,key+'_MAX_MIN_ALL_2_D_WF1'] = 0
    
            df[key+'_MAX_P4'] = df[key].rolling(4).max()
            if 3 < lendf:
                df.loc[0,key+'_MAX_P4'] = df.loc[0:0,key].max()
                df.loc[1,key+'_MAX_P4'] = df.loc[0:1,key].max()
                df.loc[2,key+'_MAX_P4'] = df.loc[0:2,key].max()
            else:
                for idx in range(0,lendf): 
                    df.loc[idx,key+'_MAX_P4'] = df.loc[0:idx,key].max()
                
            df[key+'_MIN_P4'] = df[key].rolling(4).min()
            if 3 < lendf:
                df.loc[0,key+'_MIN_P4'] = df.loc[0:0,key].min()
                df.loc[1,key+'_MIN_P4'] = df.loc[0:1,key].min()
                df.loc[2,key+'_MIN_P4'] = df.loc[0:2,key].min()
            else:
                for idx in range(0,lendf): 
                    df.loc[idx,key+'_MIN_P4'] = df.loc[0:idx,key].min()
            
            df[key+'_MAX_MIN_P4_2'] = ( df[key+'_MAX_P4'] + df[key+'_MIN_P4'] ) / 2
            df[key+'_MAX_MIN_P4_2_1'] = df[key+'_MAX_MIN_P4_2'].shift(1)
            df.loc[0,key+'_MAX_MIN_P4_2_1'] = df.loc[0,key+'_MAX_MIN_P4_2']
            # df[key+'_MAX_MIN_P4_2_D'] = df[key+'_MAX_MIN_P4_2'] - df[key+'_MAX_MIN_P4_2'].shift(1)
            # df.loc[0,key+'_MAX_MIN_P4_2_D'] = 0
            # df[key+'_MAX_MIN_P4_2_D_WF'] = df[key+'_MAX_MIN_P4_2_D'].cumsum()
            # df.loc[0,key+'_MAX_MIN_P4_2_D_WF'] = 0
            # df[key+'_MAX_MIN_P4_2_D_WF1'] = df[key+'_MAX_MIN_P4_2_D'].shift(1).cumsum()
            # df.loc[0,key+'_MAX_MIN_P4_2_D_WF1'] = 0
    
    
        df['PID4MAX']   = df.loc[:,['PID1_MAX_MIN_ALL_2','PID2_MAX_MIN_ALL_2','PID3_MAX_MIN_ALL_2']].max(axis=1)
        df['PID4MIN']   = df.loc[:,['PID1_MAX_MIN_ALL_2','PID2_MAX_MIN_ALL_2','PID3_MAX_MIN_ALL_2']].min(axis=1)
        df['PID4MAXMIN2'] = ( df['PID4MAX'] + df['PID4MIN'] ) / 2
        df['PID4MAXMIN2_1'] = df['PID4MAXMIN2'].shift(1)
        df.loc[0,'PID4MAXMIN2_1'] = df.loc[0,'PID4MAXMIN2']
    
        self.calculate_atr(df)    
    
        return df
    
    # END: def set_excel_func_to_df(df,cf_sym,sym,per)
    # =============================================================================


    # =============================================================================
    # def set_excel_func_to_df0(self, df,cf_sym,sym,per):
    #     
    # =============================================================================
    def set_excel_func_to_df0(self, df,cf_sym,sym,per):
        
        lendf = len(df)
        
        # # P - Popen, Phigh, Plow, Pclose
        # idx = 0   # 0 points at first element
        # dfidx = df.open
        # df['Popen']  = ( df.open  - dfidx.loc[idx] ) / cf_sym['points']
        # df['Phigh']  = ( df.high  - dfidx.loc[idx] ) / cf_sym['points']
        # df['Plow']   = ( df.low   - dfidx.loc[idx] ) / cf_sym['points']
        # df['Pclose'] = ( df.close - dfidx.loc[idx] ) / cf_sym['points']
        # df.loc[0,'Popen']=0
    
        # P - Popen, Phigh, Plow, Pclose
        idx = len(df) - 1  # 0 points at last element
        dfidx = df.close
        df['Popen']  = ( df.open  - dfidx.loc[idx] ) / cf_sym['points']
        df['Phigh']  = ( df.high  - dfidx.loc[idx] ) / cf_sym['points']
        df['Plow']   = ( df.low   - dfidx.loc[idx] ) / cf_sym['points']
        df['Pclose'] = ( df.close - dfidx.loc[idx] ) / cf_sym['points']
        # 0 points at last element
        df['Pclose0'] = ( df.close - df.close.loc[0] ) / cf_sym['points']
        #df.loc[0,'Pclose0']=0
    
    
        # I - Iopen, Ihigh, Ilow, Iclose
        df['Iopen']  = df.Popen. cumsum()
        df['Ihigh']  = df.Phigh. cumsum()
        df['Ilow']   = df.Plow.  cumsum()
        #df['Iclose'] = df.Pclose.cumsum()
        # 0 points at last element
        df['Iclose'] = df.Pclose0.cumsum()
        #df.loc[0,'Iclose']=df.loc[0,'Pclose']
        
        # set first index to zero - then start calculating remaining values
        # df['Ihigh']=np.zeros(120)
        # df.loc[1:119,['Ihigh']]=df.Phigh.loc[1:119].cumsum()
    
        # D - Dopen, Dhigh, Dlow, Dclose
        df['Dopen']  = df.Popen  - df.Popen.shift(1)
        df['Dhigh']  = df.Phigh  - df.Popen.shift(1)
        df['Dlow']   = df.Plow   - df.Popen.shift(1)
        df['Dclose'] = df.Pclose - df.Popen.shift(1)
        df.loc[0,'Dopen']=0
        df.loc[0,'Dhigh']=0
        df.loc[0,'Dlow']=0
        #df.loc[0,'Dclose']=0
        # 0 points at last element
        df.loc[0,'Dclose']=df.loc[0,'Pclose']
        
        # PID1, PID2, PID3, PID4  
        # for key in self.cf_pid_params[self.gACCOUNT]:
        #     df[key] = df.Popen*self.cf_pid_params[self.gACCOUNT][key]['KP'] + df.Iopen*self.cf_pid_params[self.gACCOUNT][key]['KI'] + df.Dopen*self.cf_pid_params[self.gACCOUNT][key]['KD']
    
        for key in self.cf_pid_params[self.gACCOUNT]:
            df[key] = df.Pclose*self.cf_pid_params[self.gACCOUNT][key]['KP'] + df.Iclose*self.cf_pid_params[self.gACCOUNT][key]['KI'] + df.Dclose*self.cf_pid_params[self.gACCOUNT][key]['KD']
    
    # =============================================================================
    #     # PID1WF, PID2WF, PID3WF, PID4WF
    #     for key in self.cf_pid_params[self.gACCOUNT]:
    #         df[key+'WF'] = df[key].cumsum()
    # 
    #     # PID1WF1, PID2WF1, PID3WF1, PID4WF1
    #     for key in self.cf_pid_params[self.gACCOUNT]:
    #         df[key+'WF1'] = df[key].shift(1).cumsum()
    #         df.loc[0,key+'WF1'] = 0
    # =============================================================================
    
        # PID1x, PID2x, PID3x, PID4x
        for key in self.cf_pid_params[self.gACCOUNT]:
            
            df[key+'_MAX_ALL'] = df[key].cummax()
            # df.loc[0,key+'_MAX_ALL'] = 0
            # if 3 < lendf:
            #     df.loc[1,key+'_MAX_ALL'] = 0
            #     df.loc[2,key+'_MAX_ALL'] = 0
            df[key+'_MIN_ALL'] = df[key].cummin()
            # df.loc[0,key+'_MIN_ALL'] = 0
            # if 3 < lendf:
            #     df.loc[1,key+'_MIN_ALL'] = 0
            #     df.loc[2,key+'_MIN_ALL'] = 0
            df[key+'_MAX_MIN_ALL_2'] = ( df[key+'_MAX_ALL'] + df[key+'_MIN_ALL'] ) / 2
            df[key+'_MAX_MIN_ALL_2_1'] = df[key+'_MAX_MIN_ALL_2'].shift(1)
            df.loc[0,key+'_MAX_MIN_ALL_2_1'] = df.loc[0,key+'_MAX_MIN_ALL_2']
            
            # df[key+'_MAX_MIN_ALL_2_D'] = df[key+'_MAX_MIN_ALL_2'] - df[key+'_MAX_MIN_ALL_2'].shift(1)
            # df.loc[0,key+'_MAX_MIN_ALL_2_D'] = 0
            # df[key+'_MAX_MIN_ALL_2_D_WF'] = df[key+'_MAX_MIN_ALL_2_D'].cumsum()
            # df.loc[0,key+'_MAX_MIN_ALL_2_D_WF'] = 0
            # df[key+'_MAX_MIN_ALL_2_D_WF1'] = df[key+'_MAX_MIN_ALL_2_D'].shift(1).cumsum()
            # df.loc[0,key+'_MAX_MIN_ALL_2_D_WF1'] = 0
    
            df[key+'_MAX_P4'] = df[key].rolling(4).max()
            df.loc[0,key+'_MAX_P4'] = 0
            if 3 < lendf:
                df.loc[1,key+'_MAX_P4'] = 0
                df.loc[2,key+'_MAX_P4'] = 0
            df[key+'_MIN_P4'] = df[key].rolling(4).min()
            df.loc[0,key+'_MIN_P4'] = 0
            if 3 < lendf:
                df.loc[1,key+'_MIN_P4'] = 0
                df.loc[2,key+'_MIN_P4'] = 0
            df[key+'_MAX_MIN_P4_2'] = ( df[key+'_MAX_P4'] + df[key+'_MIN_P4'] ) / 2
            df[key+'_MAX_MIN_P4_2_1'] = df[key+'_MAX_MIN_P4_2'].shift(1)
            df.loc[0,key+'_MAX_MIN_P4_2_1'] = 0
            # df[key+'_MAX_MIN_P4_2_D'] = df[key+'_MAX_MIN_P4_2'] - df[key+'_MAX_MIN_P4_2'].shift(1)
            # df.loc[0,key+'_MAX_MIN_P4_2_D'] = 0
            # df[key+'_MAX_MIN_P4_2_D_WF'] = df[key+'_MAX_MIN_P4_2_D'].cumsum()
            # df.loc[0,key+'_MAX_MIN_P4_2_D_WF'] = 0
            # df[key+'_MAX_MIN_P4_2_D_WF1'] = df[key+'_MAX_MIN_P4_2_D'].shift(1).cumsum()
            # df.loc[0,key+'_MAX_MIN_P4_2_D_WF1'] = 0
    
        return df
    
    # END: def set_excel_func_to_df0(df,cf_sym,sym,per)
        
    # =============================================================================
    
    
    
    # =============================================================================
    # def set_excel_func_to_df_orig(df,cf_sym,sym,per):
    #     
    # =============================================================================
    def set_excel_func_to_df_orig(self, df,cf_sym,sym,per):
        
        lendf = len(df)
        
        # P - Popen, Phigh, Plow, Pclose
        df['Popen']  = ( df.open  - df.open.loc[0] ) / cf_sym['points']
        df['Phigh']  = ( df.high  - df.open.loc[0] ) / cf_sym['points']
        df['Plow']   = ( df.low   - df.open.loc[0] ) / cf_sym['points']
        df['Pclose'] = ( df.close - df.open.loc[0] ) / cf_sym['points']
        df.loc[0,'Popen']=0
        df.loc[0,'Phigh']=0
        df.loc[0,'Plow']=0
        df.loc[0,'Pclose']=0
        
        # I - Iopen, Ihigh, Ilow, Iclose
        df['Iopen']  = df.Popen. cumsum()
        df['Ihigh']  = df.Phigh. cumsum()
        df['Ilow']   = df.Plow.  cumsum()
        df['Iclose'] = df.Pclose.cumsum()
        # set first index to zero - then start calculating remaining values
        # df['Ihigh']=np.zeros(120)
        # df.loc[1:119,['Ihigh']]=df.Phigh.loc[1:119].cumsum()
    
        # D - Dopen, Dhigh, Dlow, Dclose
        df['Dopen']  = df.Popen  - df.Popen.shift(1)
        df['Dhigh']  = df.Phigh  - df.Popen.shift(1)
        df['Dlow']   = df.Plow   - df.Popen.shift(1)
        df['Dclose'] = df.Pclose - df.Popen.shift(1)
        df.loc[0,'Dopen']=0
        df.loc[0,'Dhigh']=0
        df.loc[0,'Dlow']=0
        df.loc[0,'Dclose']=0
        
        # PID1, PID2, PID3, PID4  
        for key in self.cf_pid_params[self.gACCOUNT]:
            df[key] = df.Popen*self.cf_pid_params[self.gACCOUNT][key]['KP'] + df.Iopen*self.cf_pid_params[self.gACCOUNT][key]['KI'] + df.Dopen*self.cf_pid_params[self.gACCOUNT][key]['KD']
    
        # PID1WF, PID2WF, PID3WF, PID4WF
        for key in self.cf_pid_params[self.gACCOUNT]:
            df[key+'WF'] = df[key].cumsum()
    
        # PID1WF1, PID2WF1, PID3WF1, PID4WF1
        for key in self.cf_pid_params[self.gACCOUNT]:
            df[key+'WF1'] = df[key].shift(1).cumsum()
            df.loc[0,key+'WF1'] = 0
    
        # PID1x, PID2x, PID3x, PID4x
        for key in self.cf_pid_params[self.gACCOUNT]:
            
            df[key+'_MAX_ALL'] = df[key].cummax()
            df.loc[0,key+'_MAX_ALL'] = 0
            if 3 < lendf:
                df.loc[1,key+'_MAX_ALL'] = 0
                df.loc[2,key+'_MAX_ALL'] = 0
            df[key+'_MIN_ALL'] = df[key].cummin()
            df.loc[0,key+'_MIN_ALL'] = 0
            if 3 < lendf:
                df.loc[1,key+'_MIN_ALL'] = 0
                df.loc[2,key+'_MIN_ALL'] = 0
            df[key+'_MAX_MIN_ALL_2'] = ( df[key+'_MAX_ALL'] + df[key+'_MIN_ALL'] ) / 2
            df[key+'_MAX_MIN_ALL_2_D'] = df[key+'_MAX_MIN_ALL_2'] - df[key+'_MAX_MIN_ALL_2'].shift(1)
            df.loc[0,key+'_MAX_MIN_ALL_2_D'] = 0
            df[key+'_MAX_MIN_ALL_2_D_WF'] = df[key+'_MAX_MIN_ALL_2_D'].cumsum()
            df.loc[0,key+'_MAX_MIN_ALL_2_D_WF'] = 0
            df[key+'_MAX_MIN_ALL_2_D_WF1'] = df[key+'_MAX_MIN_ALL_2_D'].shift(1).cumsum()
            df.loc[0,key+'_MAX_MIN_ALL_2_D_WF1'] = 0
    
    
            df[key+'_MAX_P4'] = df[key].rolling(4).max()
            df.loc[0,key+'_MAX_P4'] = 0
            if 3 < lendf:
                df.loc[1,key+'_MAX_P4'] = 0
                df.loc[2,key+'_MAX_P4'] = 0
            df[key+'_MIN_P4'] = df[key].rolling(4).min()
            df.loc[0,key+'_MIN_P4'] = 0
            if 3 < lendf:
                df.loc[1,key+'_MIN_P4'] = 0
                df.loc[2,key+'_MIN_P4'] = 0
            df[key+'_MAX_MIN_P4_2'] = ( df[key+'_MAX_P4'] + df[key+'_MIN_P4'] ) / 2
            df[key+'_MAX_MIN_P4_2_D'] = df[key+'_MAX_MIN_P4_2'] - df[key+'_MAX_MIN_P4_2'].shift(1)
            df.loc[0,key+'_MAX_MIN_P4_2_D'] = 0
            df[key+'_MAX_MIN_P4_2_D_WF'] = df[key+'_MAX_MIN_P4_2_D'].cumsum()
            df.loc[0,key+'_MAX_MIN_P4_2_D_WF'] = 0
            df[key+'_MAX_MIN_P4_2_D_WF1'] = df[key+'_MAX_MIN_P4_2_D'].shift(1).cumsum()
            df.loc[0,key+'_MAX_MIN_P4_2_D_WF1'] = 0
    
        return df
    
    # END: def set_excel_func_to_df_orig(df,cf_sym,sym,per)
    # =============================================================================
    
    
    
    # =============================================================================
    # def set_gc0:
    #     
    # =============================================================================
    def set_gc0(self):
    
        # first reset the values
        for sym in self.cf_symbols[self.gACCOUNT]: 
            self.g_c0[sym] = None
            
        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            raise ValueError("mt5_init({}}) failed at set_gc0, exit") 
        
        for sym in self.cf_symbols[self.gACCOUNT]: 
            self.set_gc0_price(sym)
                
    # END: def set_gc0(self):
    # =============================================================================

    # =============================================================================
    # def set_gc0_price(self, sym):
    #     
    # =============================================================================
    def set_gc0_price(self, sym):
    
        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            raise ValueError("mt5_init({}}) failed at set_gc0, exit") 
        
        sym_info = self.mt5.symbol_info (sym) 
        if None is sym_info: 
            raise ValueError(sym + " mt5_init({}}) failed at set_gc0, exit") 
          
        # if the sym is unavailable in MarketWatch, add it 
        if not sym_info.visible: 
            print(sym, "is not visible, trying to switch on") 
            if not self.mt5.symbol_select(sym,True): 
                raise ValueError(sym + "symbol_select({}}) failed at set_gc0, exit") 

        # calculate the price            
        #point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        #symbol_info_dict = self.mt5.symbol_info(sym)._asdict()
        #for prop in symbol_info_dict:
        #    print("  {}={}".format(prop, symbol_info_dict[prop]))
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        if 0.0 < ask and 0.0 < bid :
            price    = round( (bid + (ask - bid ) / 2), digits )
            self.g_c0[sym] = price
            #if 0 < self.verbose:
            print( sym, price, "set new base line - start point - gc0 price")
                
    # END: def set_gc0_price(self, sym):
    # =============================================================================


    # =============================================================================
    # def get_ticks_and_rates(self, sym):
    #     
    # =============================================================================
    def get_ticks_and_rates(self, sym):
    
        start = time.time()
        
        dt_count = self.gDt['dt_count']
        dt_to    = self.gDt['dt_to']
    
        dt_to_str =   str(dt_to.strftime("%Y%m%d_%H%M%S"))  
        if self.gVerbose: print( _sprintf("%s %s START",sym, dt_to_str ) )
        
        self.get_ticks(sym)
    
        endticks = time.time()
    
        # RATES
        for per in self.cf_periods[self.gACCOUNT]:
            # print(sym + str(dt_to.strftime("_%Y%m%d_%H%M%S_SYM_")) + per)
            df = self.copy_rates_from(sym,per,dt_to,dt_count)
            lendf    = len(df)
            if 0 >= lendf :
                # print("get_ticks_and_rates: df does not exists " + sym + " "  + per + " " + str(dt_to) + " len(" + str(lendf) + ")")
                # TODO TICKS kaputt - uncomment for the moment till TICKS are fixed
                raise ValueError("get_ticks_and_rates: df does not exists " + sym + " "  + per + " " + str(dt_to) + " len(" + str(lendf) + ")")
        
        # # analyse DF
        # self.analyse_df(sym)
        
        end = time.time()
        if self.gVerbose: print( _sprintf("%s %s END [%.2gs / %.1gs / %.2gs]",sym, dt_to_str, (end-start), (endticks-start), (end-endticks) ))
        
    # END def get_ticks_and_rates(self, sym): 
    # =============================================================================



    # =============================================================================
    # def get_ticks_and_rates2(sym):
    #     
    # =============================================================================
    def get_ticks_and_rates2(self, sym):
    
        start = time.time()
        
        dt_count = self.gDt['dt_count']
        dt_to    = self.gDt['dt_to']
    
        dt_to_str =   str(dt_to.strftime("%Y%m%d_%H%M%S"))  
        if self.gVerbose: print( _sprintf("%s %s START",sym, dt_to_str ) )
        
        self.get_ticks(sym)
    
        endticks = time.time()
    
        # #RATES
        # cnt = 1
        # for per in self.perarr:
        #     per_idx_str = '0' + str(cnt)
        #     self.set_cf_periods(None, per_idx_str, per)
            
        #     for per in self.cf_periods[self.gACCOUNT]:
        #         # print(sym + str(dt_to.strftime("_%Y%m%d_%H%M%S_SYM_")) + per)
        #         df = self.copy_rates_from(sym,per,dt_to,dt_count)
        #         lendf    = len(df)
        #         if 0 >= lendf :
        #             # print("get_ticks_and_rates2: df does not exists " + sym + " "  + per + " " + str(dt_to) + " len(" + str(lendf) + ")")
        #             # TODO TICKS kaputt - uncomment for the moment till TICKS are fixed
        #             raise ValueError("get_ticks_and_rates2: df does not exists " + sym + " "  + per + " " + str(dt_to) + " len(" + str(lendf) + ")")
            
        #     cnt = cnt + 1
        # # for per in self.perarr:

        #for per in self.perarr:  print(per)
        #['T3', 'T5', 'T8', 'T13', 'T21', 'T34']
        #['T5', 'T8', 'T13', 'T21', 'T34', 'T55']
        #['T8', 'T13', 'T21', 'T34', 'T55', 'T89']
        #['T13', 'T21', 'T34', 'T55', 'T89', 'T144']
        #['T21', 'T34', 'T55', 'T89', 'T144', 'T233']            
        
        perH = {}
        for per in self.perarr: 
            #print( per )
            for peridx in per:
                if peridx not in perH:
                    # print( peridx )
                    # T3, T5, T8, T13, T21, T34, T55, T89, T144, T233, T377
                    perH[peridx] = peridx
                    # print(sym + str(dt_to.strftime("_%Y%m%d_%H%M%S_SYM_")) + per)
                    self.set_cf_periods(None, 'FF', per)
                    df = self.copy_rates_from(sym,peridx,dt_to,dt_count)
                    lendf    = len(df)
                    if 0 >= lendf :
                        # print("get_ticks_and_rates2: df does not exists " + sym + " "  + per + " " + str(dt_to) + " len(" + str(lendf) + ")")
                        # TODO TICKS kaputt - uncomment for the moment till TICKS are fixed
                        raise ValueError("get_ticks_and_rates2: df does not exists " + sym + " "  + per + " " + str(dt_to) + " len(" + str(lendf) + ")")

        # analyse DF
        cnt = 1
        for per in self.perarr:
            per_idx_str = '0' + str(cnt)
            if cnt > 9: per_idx_str = str(cnt)
            self.set_cf_periods(None, per_idx_str, per)
            self.analyse_df2(sym)
            cnt = cnt + 1
            
        # TODO make this work again
        #if True == self.gUsePid:
        #    self.trade_df_pid(sym)
            
        end = time.time()
        if self.gVerbose: print( _sprintf("%s %s END [%.2gs / %.1gs / %.2gs]",sym, dt_to_str, (end-start), (endticks-start), (end-endticks) ))
        
    # END def get_ticks_and_rates2(sym): 
    # =============================================================================

    # =============================================================================
    # import threading
    # def get_all_ticks_and_rates2():
    # 
    #     #for sym in self.cf_symbols[self.gACCOUNT]: 
    #     #    get_ticks_and_rates(sym)
    #     
    #     start = time.time()
    #     t = {}
    #     for sym in self.cf_symbols[self.gACCOUNT]: 
    #         t[sym] = threading.Thread(target=get_ticks_and_rates, args=(sym,))
    #         #t[sym].setDaemon(True)
    #         t[sym].start()
    # 
    #     print( ' hi there 1' )
    #     for sym in self.cf_symbols[self.gACCOUNT]: 
    #         t[sym].join()
    #     print( ' hi there 2' )
    #     
    #     end = time.time()
    #     print( "%.2gs" % (end-start) )
    # =============================================================================


    # =============================================================================
    # def analyse_df(self, sym):
    #     
    # =============================================================================
    def analyse_df(self,sym):
    
        lenper = len(self.cf_periods[self.gACCOUNT])
        dt_to    = self.gDt['dt_to']
        points   = self.cf_symbols[self.gACCOUNT][sym]['points']
        
        # create numpy array
        dtype = np.dtype([('sec', '<u8'), ('vol', '<u8'), ('cnt', '<u8'),\
                          ('t1', '<i8'),  ('t0', '<i8'),  ('dt_to', '<i8'),\
                          ('c1', '<f8'), ('c0', '<f8'),('ps1', '<f8'), ('ps0', '<f8'),\
                          ('DELTA', '<i8'), ('PS', '<i8'), ('OC', '<i8'), ('HL', '<i8'), ('TD', '<i8'), ('VOLS', '<i8'),\
                          ('TT', '<i8'), ('HL/TD', '<f8'), ('HL/VOLS', '<f8'), ('VOLS/TD', '<f8'), ('OC/HL', '<f8'), ('SPREAD', '<i8'), ('SUMCOL', '<f8') ])
                          
        npa = np.zeros(lenper, dtype=dtype)
        dfana = pd.DataFrame(npa, index=list(self.cf_periods[self.gACCOUNT].keys()))
        dfana['SUMCOL'] = 0.0
        dfana.loc['SUMROW']  = 0
        # =============================================================================
        # print( dfana )
        #         sec  vol  cnt  t1  t0  dt_to  ...  TD  VOLS  TT  HL/TD  HL/VOLS  SUMCOL
        # T8      0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T13     0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T21     0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T34     0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T55     0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T89     0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T144    0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # T233    0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # SUMROW  0.0  0.0  0.0   0   0      0  ...   0     0   0    0.0      0.0       0
        # =============================================================================
        
    
        # RATES
        for per in self.cf_periods[self.gACCOUNT]:
            # print(per)
    
            #print(sym + str(dt_to.strftime("_%Y%m%d_%H%M%S_SYM_")) + per)
            df = self.get_df_rates( dt_to, per, sym )
            # usually lendf -> 10.0
            lendf    = len(df)
            if 0 >= lendf :
                #print("analyse_df: df does not exists " + sym + " "  + per + " " + str(dt_to) + " " + str(lendf) )
                continue
            
            
            c1 = df.iloc[0].close
            c0 = df.iloc[lendf-1].close
            # print( c1 )
            # print( c0 )

            
            DELTA = int(0.0)
            if None != self.g_c0[sym]:
                DELTA = int( (c0 - self.g_c0[sym]) / points ) 

            # count=10
            ps1 = df.iloc[0].ps
            ps0 = df.iloc[lendf-1].ps
            #print( int( round( ps0 - ps1 )), ps1,ps0 )
            #PS = int( round( ps0 - ps1 ))
            # count = -1 last element
            # TODO clean up source here ps vs pd
            ps1 = df.iloc[-2].pd
            ps0 = df.iloc[-1].pd
            PS = PS = int( round( ps0 - ps1 ))
            
            #print(df[['close','pd'])
            
            # count=10
            #OC = int( (c0 -c1)/points ) 
            # count = -1 last element
            OC = int( (df.iloc[-1].close - df.iloc[-2].close)/points ) 
            
            # count=10
            #HL = int((df.high.max() - df.low.min())/points) # int(df.iloc[lendf-2].Pclose)
            # count = -1 last element
            HL = int((df.iloc[-1].high.max() - df.iloc[-1].low.min())/points)
            
            # count=10
            #TD = int((df.iloc[lendf-1].time_msc + df.iloc[lendf-1].TDms - df.iloc[0].time_msc)/1000) # int(df.iloc[lendf-1].Pclose)
            # count = -1 last element
            TD = (round((df.iloc[lendf-1].time_msc + df.iloc[lendf-1].TDms - df.iloc[-2].time_msc)/1000)) 
            
            # count=10
            VOLS = df.volume.sum()
            # count = -1 last element
            VOLS = df.iloc[lendf-1].volume
            
            # print( OC )
            # print( HL )
            # print( TD )
            # print( VOLS )
            # TODO correct MATH here ( round )
            if 0 == TD:
                HL_TD = round((HL/0.1),1)
            else:
                HL_TD = round((HL/TD),1)
            # print( HL_TD )
            TT =  int(round(TD/VOLS*1000))  
            # print( TT )
            HL_VOLS = round((HL/VOLS), 1)
            # print( HL_VOLS )

            if 0 == TD:
                VOLS_TD = round((VOLS/0.1),1)
            else:
                VOLS_TD = round((VOLS/TD),1)

            if 0 == HL:
                OC_HL = 0
            else:
                OC_HL = round((abs(OC)/HL),1)
                
            SPREAD = int(round(df.iloc[-1].highspread))
            
            dfana.loc[per,'sec']        = self.cf_periods[self.gACCOUNT][per]['seconds']
            dfana.loc[per,'vol']        = self.cf_periods[self.gACCOUNT][per]['volume']
            dfana.loc[per,'cnt']        = int(lendf)
            dfana.loc[per,'DELTA']      = DELTA
            dfana.loc[per,'PS']         = PS
            dfana.loc[per,'OC']         = OC
            dfana.loc[per,'HL']         = HL
            dfana.loc[per,'TD']         = TD
            dfana.loc[per,'c1']         = c1
            dfana.loc[per,'c0']         = c0
            dfana.loc[per,'ps1']        = ps1
            dfana.loc[per,'ps0']        = ps0
            dfana.loc[per,'VOLS']       = VOLS
            dfana.loc[per,'TT']         = TT
            dfana.loc[per,'HL/TD']      = HL_TD
            dfana.loc[per,'HL/VOLS']    = HL_VOLS
            dfana.loc[per,'VOLS/TD']    = VOLS_TD
            dfana.loc[per,'OC/HL']      = OC_HL
            dfana.loc[per,'SPREAD']     = SPREAD
            dfana.loc[per,'SUMCOL']     = round(dfana.loc[per,'OC/HL'] + dfana.loc[per,'VOLS/TD'],1)
            
            #print(dfana[['VOLS/TD','OC/HL','HL/TD']])
            
            
            # TODO implement topen and tclose
            # now  t0 -> tclose, which is gDF[DTindex] -> e.g. GBPJPY 20210111_172422 END
            #  and t1 -> topen from MT5 system
            t1 = int(df.iloc[0].time_msc)
            dfana.loc[per,'t1']       = t1
            t0 = int(df.iloc[lendf-1].time_msc)
            dfana.loc[per,'t0']       = t0
            

        # END for per in self.cf_periods[self.gACCOUNT]:
            
        # TODO implement topen and tclose
        # now  t0 -> tclose, which is gDF[DTindex] -> e.g. GBPJPY 20210111_172422 END
        #  and t1 -> topen from MT5 system
        dfana['dt_to'] = int(dt_to.timestamp()*1000) # convert to milli secs
        dfana.loc['SUMROW','sec']       = int(dfana['sec'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','vol']       = int(dfana['vol'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','cnt']       = int(dfana['cnt'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','t0']        = int(dfana['t0'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','t1']        = int(dfana['t1'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','c1']        = dfana['c1'].iloc[0:lenper].sum()/lenper
        dfana.loc['SUMROW','c0']        = dfana['c0'].iloc[0:lenper].sum()/lenper
        dfana.loc['SUMROW','ps1']       = dfana['ps1'].iloc[0:lenper].sum()/lenper
        dfana.loc['SUMROW','ps0']       = dfana['ps0'].iloc[0:lenper].sum()/lenper
        dfana.loc['SUMROW','DELTA']     = int(dfana['DELTA'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','PS']        = int(dfana['PS'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','OC']        = int(dfana['OC'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','HL']        = int(dfana['HL'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','TD']        = int(dfana['TD'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','VOLS']      = int(dfana['VOLS'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','TT']        = int(round(dfana['TT'].iloc[0:lenper].sum()/lenper,1))
        dfana.loc['SUMROW','HL/TD']     = round(dfana['HL/TD'].iloc[0:lenper].sum()/lenper,1)
        dfana.loc['SUMROW','HL/VOLS']   = round(dfana['HL/VOLS'].iloc[0:lenper].sum()/lenper,1)
        dfana.loc['SUMROW','VOLS/TD']   = round(dfana['VOLS/TD'].iloc[0:lenper].sum()/lenper,1)
        dfana.loc['SUMROW','OC/HL']     = round(dfana['OC/HL'].iloc[0:lenper].sum()/lenper,1)
        dfana.loc['SUMROW','SPREAD']    = int(round(dfana['SPREAD'].iloc[0:lenper].sum()/lenper))
            
        sumrow = dfana['SUMCOL'].iloc[0:lenper].sum()/lenper
        sumcol = dfana.loc['SUMROW','VOLS/TD'] + dfana.loc['SUMROW','OC/HL'] 
        dfana.loc['SUMROW','SUMCOL']    = round(sumrow,1)
        dfana.loc['SUMROW','SUMCOL']    = round(sumcol,1)
        # TODO fixme one day - precision calculation error
        #if round(sumrow,1) == round(sumcol,1):
        #    dfana.loc['SUMROW','SUMCOL']  = round(sumrow,1)
        #else:
        #    raise ValueError( sprintf("ERROR: sumrow[%d] != sumcol[%d]: ", sumrow, sumcol) )
    
        self.gNpa = dfana
        # gDF[str(dt_to)]['ANA'] = dfana
        self.set_df_rates( dt_to, 'ANA', sym, dfana )
        
        # =============================================================================
        if self.gVerbose: print( dfana[['DELTA','PS','OC','HL','TD','VOLS','TT','HL/TD','HL/VOLS','SUMCOL']] )
        if self.gVerbose: print( list(round(dfana['SUMCOL'],1)) )
        if self.gVerbose: print( list(dfana['OC']) )
        if self.gVerbose: print( dfana.loc['SUMROW','OC'], dfana.loc['SUMROW','SUMCOL'] )
        #         OC   HL   TD  VOLS   TT  HL/TD  HL/VOLS  SUMCOL
        # T8     -30   36   22    80  275    1.6      0.4     2.0
        # T13    -12   36   39   130  300    0.9      0.3     1.2
        # T21      4   44   64   210  305    0.7      0.2     0.9
        # T34    -18   48   98   340  288    0.5      0.1     0.6
        # T55    -36   60  163   550  296    0.4      0.1     0.5
        # T89    -68   86  254   890  285    0.3      0.1     0.4
        # T144    23  113  380  1440  264    0.3      0.1     0.4
        # T233    26  163  651  2330  279    0.3      0.1     0.4
        # SUMROW -13   73  208   746  286    0.6      0.2     0.8
        # [2.0, 1.2, 0.9, 0.6, 0.5, 0.4, 0.4, 0.4, 0.8]
        # [-30, -12, 4, -18, -36, -68, 23, 26, -13]
        # -13 0.8
        # =============================================================================
        
        return dfana
    
    
    # END def analyse_df(self,sym):
    # =============================================================================

    # =============================================================================
    # def print_analyse_df(self, dfana):
    #     
    # =============================================================================
    def print_analyse_df(self,dfana):
    
        print( dfana[['DELTA','PS','OC','HL','TD','TT','SPREAD','OC/HL','VOLS/TD','HL/TD','SUMCOL']] )
    
    # END def print_analyse_df(self,dfana):
    # =============================================================================


    # =============================================================================
    # def analyse_df2(self,sym):
    #     
    # =============================================================================
    def analyse_df2(self, sym):
    
        lenper = len(self.cf_periods[self.gACCOUNT])
        dt_to    = self.gDt['dt_to']
        
        # create numpy array
        dtype = np.dtype([
            ('sec', '<u8'), ('vol', '<u8'), ('cnt', '<u8'), ('t1', '<i8'), ('t0', '<i8'),\
            ('pop', '<f8'), ('ppop', '<i8'), ('podir', '<i8'), ('opp', '<f8'), ('popp', '<f8'), ('opdir', '<i8'),\
            ('c1', '<f8'), ('c0', '<f8'), ('pc1', '<i8'), ('pc0', '<i8'),\
            ('pcmax', '<i8'), ('pcm', '<f8'),\
            ('SC3', '<i8'), ('SC5', '<i8'), ('SC8', '<i8'), ('SC13', '<i8'), ('SC21', '<i8'), ('SC34', '<i8'),\
            ('CNTA', '<i8'), ('CNT1', '<i8'), ('SUMCOLSC', '<i8'),\
            ('pc0popD', '<i8'), ('pc0oppD', '<i8'),\
            ('pid1', '<i8'), ('pid0', '<i8'), ('pidmax', '<i8'), ('pidm', '<f8'),\
            ('pid0popD', '<i8'), ('pid0oppD', '<i8'),\
            ('piddelta', '<i8'), ('piddir', '<i8'), ('pcdir', '<i8'), ('pdir', '<i8'), ('SUMCOL', '<i8')\
        ])

        npa = np.zeros(lenper, dtype=dtype)
        dfana = pd.DataFrame(npa, index=list(self.cf_periods[self.gACCOUNT].keys()))
        dfana['SUMCOL'] = 0
        dfana.loc['SUMROW']  = 0
        # =============================================================================
        #  print( df )
        #         pc1  pc0   c1   c0  pid1  pid0  piddelta  piddir  pcdir  pdir  SUMCOL
        # T60       0    0  0.0  0.0     0     0         0       0      0     0       0
        # T300      0    0  0.0  0.0     0     0         0       0      0     0       0
        # T900      0    0  0.0  0.0     0     0         0       0      0     0       0
        # T3600     0    0  0.0  0.0     0     0         0       0      0     0       0
        # M1        0    0  0.0  0.0     0     0         0       0      0     0       0
        # M5        0    0  0.0  0.0     0     0         0       0      0     0       0
        # M15       0    0  0.0  0.0     0     0         0       0      0     0       0
        # H1        0    0  0.0  0.0     0     0         0       0      0     0       0
        # SUMROW    0    0  0.0  0.0     0     0         0       0      0     0       0  
        # =============================================================================
        
    
        # RATES
        for per in self.cf_periods[self.gACCOUNT]:
            # print('analyse_df2', per)
    
            #print(sym + str(dt_to.strftime("_%Y%m%d_%H%M%S_SYM_")) + per)
            df = self.get_df_rates( dt_to, per, sym )
            lendf    = len(df)
            if 0 >= lendf :
                #print("analyse_df2: df does not exists " + sym + " "  + per + " " + str(dt_to) + " " + str(lendf) )
                continue
            
            # print( per )            
            # print( df[['SC3','SC5','SC8','SC13','SC21','SC34']].iloc[-1:] )
            
            c1   = df.iloc[lendf-2].close
            c0   = df.iloc[lendf-1].close

            pc1   = int(df.iloc[lendf-2].Pclose)
            pc0   = int(df.iloc[lendf-1].Pclose)
            #pcmax = (df.Pclose.max() - df.Pclose.min())
            pcmax = (df.Phigh.max() - df.Plow.min())
            
            x = np.arange(lendf)
            y = df.Pclose
            # TODO review me - maybe set pcm to null instead?
            if 0.0 == pcmax: pcmax = 0.00000000001
            pcm = (np.polyfit(x,y,1)[0] * lendf) / pcmax
            pcm = float("%.1f" % pcm)


            # print( c0 )                
            # print( pdir )
            
            dfana.loc[per,'sec']        = self.cf_periods[self.gACCOUNT][per]['seconds']
            dfana.loc[per,'vol']        = self.cf_periods[self.gACCOUNT][per]['volume']
            dfana.loc[per,'cnt']        = int(lendf)
            dfana.loc[per,'c1']         = c1
            dfana.loc[per,'c0']         = c0
            dfana.loc[per,'pc1']        = pc1
            dfana.loc[per,'pc0']        = pc0
            dfana.loc[per,'pcmax']      = int(pcmax)
            dfana.loc[per,'pcm']        = pcm
            # TODO implement topen and tclose
            # now  t0 -> tclose, which is self.gDF[DTindex] -> e.g. GBPJPY 20210111_172422 END
            #  and t1 -> topen from MT5 system
            t1 = int(df.iloc[lendf-1].time)
            dfana.loc[per,'t1']       = t1

            if True == self.gUseScalp:
                # print( df[['SC3','SC5','SC8','SC13','SC21','SC34']].iloc[-1:] )
                dfana.loc[per,'SC3']        = df['SC3'].iloc[lendf-1]
                dfana.loc[per,'SC5']        = df['SC5'].iloc[lendf-1]
                dfana.loc[per,'SC8']        = df['SC8'].iloc[lendf-1]
                dfana.loc[per,'SC13']       = df['SC13'].iloc[lendf-1]
                dfana.loc[per,'SC21']       = df['SC21'].iloc[lendf-1]
                dfana.loc[per,'SC34']       = df['SC34'].iloc[lendf-1]
                dfana.loc[per,'SUMCOLSC']     = int(dfana.loc[per,'SC3':'SC34'].median())
                # =============================================================================
                #     df
                #     Out[283]: 
                #               sec  vol   cnt          t1          t0  ...  SC8  SC13  SC21  SC34  SUMCOLSC
                #     S60      60.0  0.0  10.0  1612867887  1612867945  ...  -54    16     2   -15     -34
                #     S300    300.0  0.0  10.0  1612867645  1612867945  ...  -20   -26   -26   -35     -23
                #     S900    900.0  0.0  10.0  1612867047  1612867945  ...  -50   -50   -50   -50     -50
                #     SUMROW    0.0  0.0  10.0  1612867526  1612867945  ...  -41   -20   -24   -33     -34
                #     
                #     [4 rows x 24 columns]
                #     
                #     df.loc['S60','SC3':'SC34'].lt(-1).sum()
                #     Out[284]: 4
                #     
                #     df.loc['S60','SC3':'SC34']
                #     Out[285]: 
                #     SC3    -54.0
                #     SC5    -54.0
                #     SC8    -54.0
                #     SC13    16.0
                #     SC21     2.0
                #     SC34   -15.0
                #     Name: S60, dtype: float64
                #     
                #     df.loc['S60','SC3':'SC34'].gt(1).sum()
                #     Out[286]: 2
                #     
                #     df.loc['S60','SC3':'SC34'].lt(-1).sum()
                #     Out[287]: 4
                #     
                #     df.loc['S60','SC3':'SC34'].gt(1).sum() - df.loc['S60','SC3':'SC34'].lt(-1).sum() 
                #     Out[288]: -2
                #            
                #     df.loc['S60','SC3':'SC34'].gt(5).sum() - df.loc['S60','SC3':'SC34'].lt(-5).sum()
                #     Out[351]: -6            
                # =============================================================================
                sumpos = dfana.loc[per,'SC3':'SC34'].gt(1).sum()
                sumneg = dfana.loc[per,'SC3':'SC34'].lt(-1).sum()
                dfana.loc[per,'CNT1']     = int(sumpos - sumneg)
                dfana.loc[per,'CNTA']     = 0
                if 6 == sumpos:
                    dfana.loc[per,'CNTA'] = 1
                if 6 == sumneg:
                    dfana.loc[per,'CNTA'] = -1
            # END if True == self.gUseScalp:
            
            if True == self.gUsePid:
            
                pid1 = int(df.iloc[lendf-2].PID4MAXMIN2)
                pid0 = int(df.iloc[lendf-1].PID4MAXMIN2)
                pidmax = int(df.PID4MAXMIN2.max() - df.PID4MAXMIN2.min())
                # np.polyfit(x,y,1)   |-  np.polyfit(x,y,1)[0]
                # Out[59]: array([-17.21212121,   3.25454545])
                x = np.arange(lendf)
                y = df.PID4MAXMIN2
                # ymax =max(pidmax,pcmax)
                # pidm = (np.polyfit(x,y,1)[0] * lendf) / ymax
                pidm = (np.polyfit(x,y,1)[0] * lendf) / pcmax
                pidm = float("%.1f" % pidm)
                piddelta = pc0 - pid0
                piddir = 0
                pcdir = 0
                if pid1 < pid0:
                    piddir = 1
                if pid1 > pid0:
                    piddir = -1
                if pid0 < pc0:
                    pcdir = 1
                if pid0 > pc0:
                    pcdir = -1
                pdir = 0
                if ( 1 == piddir ) and (1 == pcdir ):
                    pdir = 1
                if ( -1 == piddir ) and (-1 == pcdir ):
                    pdir = -1
                    
                dfana.loc[per,'pid1']       = pid1
                dfana.loc[per,'pid0']       = pid0
                dfana.loc[per,'pidmax']     = int(pidmax)
                dfana.loc[per,'pidm']       = pidm
                dfana.loc[per,'piddelta']   = piddelta
                dfana.loc[per,'piddir']     = piddir
                dfana.loc[per,'pcdir']      = pcdir
                dfana.loc[per,'pdir']       = pdir
                dfana.loc[per,'SUMCOL']     = dfana.loc[per,'piddir'] + dfana.loc[per,'pcdir'] + dfana.loc[per,'pdir']
                    
            # END if True == self.gUsePid:
            

        # END for per in self.cf_periods[self.gACCOUNT]:
            
        # TODO implement topen and tclose
        # now  t0 -> tclose, which is self.gDF[DTindex] -> e.g. GBPJPY 20210111_172422 END
        #  and t1 -> topen from MT5 system
        dfana['t0'] = int(dt_to.timestamp())
        dfana.loc['SUMROW','t1']    = int(dfana['t1'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','cnt']   = int(dfana['cnt'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','c1']    = dfana['c1'].iloc[0:lenper].sum()/lenper
        dfana.loc['SUMROW','c0']    = dfana['c0'].iloc[0:lenper].sum()/lenper
        dfana.loc['SUMROW','pc1']   = int(dfana['pc1'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','pc0']   = int(dfana['pc0'].iloc[0:lenper].sum()/lenper)
        dfana.loc['SUMROW','pcmax'] = int(dfana['pcmax'].iloc[0:lenper].sum()/lenper)
        tmp = dfana['pcm'].iloc[0:lenper].sum()/lenper
        tmp = float("%.1f" % tmp)
        dfana.loc['SUMROW','pcm']   = tmp

        if True == self.gUseScalp:
            dfana.loc['SUMROW','SC3']   = int(dfana['SC3'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','SC5']   = int(dfana['SC5'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','SC8']   = int(dfana['SC8'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','SC13']  = int(dfana['SC13'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','SC21']  = int(dfana['SC21'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','SC34']  = int(dfana['SC34'].iloc[0:lenper].sum()/lenper)
            #dfana.loc['SUMROW','SUMCOLSC']    = int(dfana.loc[per,'SC3':'SC34'].median())
            dfana.loc['SUMROW','SUMCOLSC']    = int(dfana['SUMCOLSC'].iloc[0:lenper].median())
            dfana.loc['SUMROW','CNT1']      = int(dfana['CNT1'].iloc[0:lenper].median())
            dfana.loc['SUMROW','CNTA']      = int(dfana['CNTA'].iloc[0:lenper].median())
        # END if True == self.gUseScalp:
        
        if True == self.gUsePid:

            dfana.loc['SUMROW','pid1']  = int(dfana['pid1'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','pid0']  = int(dfana['pid0'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','pidmax']= int(dfana['pidmax'].iloc[0:lenper].sum()/lenper)
            
            tmp = dfana['pidm'].iloc[0:lenper].sum()/lenper
            tmp = float("%.1f" % tmp)
            dfana.loc['SUMROW','pidm'] = tmp
            
            dfana.loc['SUMROW','piddelta'] = int(dfana['piddelta'].iloc[0:lenper].sum()/lenper)
            dfana.loc['SUMROW','piddir']= int(dfana['piddir'].iloc[0:lenper].sum())
            dfana.loc['SUMROW','pcdir'] = int(dfana['pcdir'].iloc[0:lenper].sum())
            dfana.loc['SUMROW','pdir']  = int(dfana['pdir'].iloc[0:lenper].sum())
                
            sumrow = dfana['SUMCOL'].iloc[0:lenper].sum()
            sumcol = dfana.loc['SUMROW','piddir'] + dfana.loc['SUMROW','pcdir'] + dfana.loc['SUMROW','pdir']
            if sumrow == sumcol:
                # orig
                dfana.loc['SUMROW','SUMCOL']  = int(round(sumrow/lenper))
                # float - makes everything else float
                #dfana.loc['SUMROW','SUMCOL']  = float("%.1f" % (sumrow/lenper))
                #dfana.loc['SUMROW','SUMCOL']  = int(sumrow)
            else:
                raise ValueError( _sprintf("ERROR: sumrow[%d] != sumcol[%d]: ", sumrow, sumcol) )
        
        # END if True == self.gUsePid:

        per_name_str = 'ANA_XY'
        per_name_screen_idx = 1
        if 'NAME' in self.cf_periods:
            per_name_str = 'ANA_' + self.cf_periods['NAME']
            per_name_screen_idx = int(self.cf_periods['NAME'])
        self.set_df_rates( dt_to, per_name_str, sym, dfana )

        # print(list(gH.cf_periods[gH.gACCOUNT]))
        # ['T610', 'T987', 'T1597']
        
        # if (False == self.gUseScalp) and (False == self.gUsePid):

        #     if self.gVerbose: print( dfana[['pcmax','pcm']] )
        #     anastr = _sprintf("%s\t%s\t%9.05f\t%4d\t%+1.01f",\
        #                     sym,\
        #                     per_name_str,\
        #                     dfana.loc['SUMROW','c0'],\
        #                     dfana.loc['SUMROW','pcmax'],\
        #                     dfana.loc['SUMROW','pcm'],\
        #                     )   
        #     if None != self.screen:
        #         self.screen.addstr( (self.screen_first_ana_row+per_name_screen_idx), self.screen_first_col, anastr)
        #         self.screen.refresh()
        #     print( anastr )
        # # END if (False == self.gUseScalp) and (False == self.gUsePid):
                        
                        
        # if (True == self.gUseScalp) and (False == self.gUsePid):
        #     if self.gVerbose: print( dfana[['pcmax','pcm','SC3','SC5','SC8','SC13','SC21','SC34','SUMCOLSC','CNT1','CNTA']] )
        #     anastr=  _sprintf("%s\t%s\t%9.05f\t%4d\t%+1.01f\t%4d\t%4d\t%4d",\
        #                     sym,\
        #                     per_name_str,\
        #                     dfana.loc['SUMROW','c0'],\
        #                     dfana.loc['SUMROW','pcmax'],\
        #                     dfana.loc['SUMROW','pcm'],\
        #                     dfana.loc['SUMROW','CNTA'],\
        #                     dfana.loc['SUMROW','CNT1'],\
        #                     dfana.loc['SUMROW','SUMCOLSC']
        #                     )            
        #     if None != self.screen:
        #         self.screen.addstr( (self.screen_first_ana_row+per_name_screen_idx), self.screen_first_col, anastr)
        #         self.screen.refresh()
        #     print( anastr )
        # # END if (True == self.gUseScalp) and (False == self.gUsePid):
                        
                        
        # if (False == self.gUseScalp) and (True == self.gUsePid):
        #     #if self.gVerbose: print( dfana[['cnt','pc0','pcmax','pcm','pid0','pidmax','pidm','piddelta','piddir','pcdir','pdir','SUMCOL']] )
        #     if self.gVerbose: print( dfana[['cnt','c0','pc0','pcmax','pcm','pid0','pidmax','pidm','piddelta','SUMCOL']] )
        #     if self.gVerbose: print( list(dfana['SUMCOL']) )
        #     anastr = _sprintf("%s\t%s\t%9.05f\t%4d\t%+1.01f\t%4d\t%+1.01f\t%4d\t%4d",\
        #                     sym,\
        #                     per_name_str,\
        #                     dfana.loc['SUMROW','c0'],\
        #                     dfana.loc['SUMROW','pcmax'],\
        #                     dfana.loc['SUMROW','pcm'],\
        #                     dfana.loc['SUMROW','pidmax'],\
        #                     dfana.loc['SUMROW','pidm'],\
        #                     dfana.loc['SUMROW','piddelta'],\
        #                     dfana.loc['SUMROW','SUMCOL']\
        #                     )      
        #     if None != self.screen:
        #         self.screen.addstr( (self.screen_first_ana_row+per_name_screen_idx), self.screen_first_col, anastr)
        #         self.screen.refresh()
        #     print( anastr )
                            
            
            # =============================================================================
            #  print( dfana[['cnt','c1','c0','pc0','pid0','piddir','pcdir','pdir','SUMCOL']] )
            #          cnt          c1        c0  pc0  pid0  piddir  pcdir  pdir  SUMCOL
            # T60     88.0  140.495000  140.5040    0   -82       0      1     0       1
            # S60     10.0  140.469000  140.4950    3    -5       0      1     0       1
            # T120    85.0  140.489000  140.5040    8   -33       0      1     0       1
            # S120    10.0  140.434000  140.4950    1    -3       1      1     1       3
            # T180    86.0  140.484000  140.5040   46    46       0      0     0       0
            # S180    10.0  140.434000  140.4950   24     6       1      1     1       3
            # T240    79.0  140.480000  140.5040   78    84       1     -1     0       0
            # S240    10.0  140.460000  140.4950   78    27       0      1     0       1
            # SUMROW  47.0  140.468125  140.4995   29     5       3      5     2      10
            # =============================================================================
        
        # END if (False == self.gUseScalp) and (True == self.gUsePid):
                        
                        
        # if (True == self.gUseScalp) and (True == self.gUsePid):
        #     if self.gVerbose: print( dfana[['pcmax','pcm','SC3','SC5','SC8','SC13','SC21','SC34','SUMCOLSC','CNT1','CNTA']] )
        #     if self.gVerbose: print( dfana[['cnt','c0','pc0','pcmax','pcm','pid0','pidmax','pidm','piddelta','SUMCOL']] )
        #     if self.gVerbose: print( list(dfana['SUMCOL']) )
        #     anastr = _sprintf("%s\t%s\t%9.05f\t%4d\t%+1.01f\t%4d\t%+1.01f\t%4d\t%4d\t%4d\t%4d\t%4d",\
        #                     sym,\
        #                     per_name_str,\
        #                     dfana.loc['SUMROW','c0'],\
        #                     dfana.loc['SUMROW','pcmax'],\
        #                     dfana.loc['SUMROW','pcm'],\
        #                     dfana.loc['SUMROW','pidmax'],\
        #                     dfana.loc['SUMROW','pidm'],\
        #                     dfana.loc['SUMROW','piddelta'],\
        #                     dfana.loc['SUMROW','SUMCOL'],\
        #                     dfana.loc['SUMROW','CNTA'],\
        #                     dfana.loc['SUMROW','CNT1'],\
        #                     dfana.loc['SUMROW','SUMCOLSC']
        #                     )
        #     if None != self.screen:
        #         self.screen.addstr( (self.screen_first_ana_row+per_name_screen_idx), self.screen_first_col, anastr)
        #         self.screen.refresh()
        #     print( anastr )
        # # END if (True == self.gUseScalp) and (True == self.gUsePid):

        dfsum = {}
            
        # create numpy array with len 1
        dtype = np.dtype([
            ('peridx', '<U6'), ('per', '<U40'), ('c0', '<f8'),\
            ('pcmax', '<i8'), ('pcm', '<f8'),\
            ('pidmax', '<i8'), ('pidm', '<f8'),\
            ('piddelta', '<i8'), ('SUMCOL', '<i8'),\
            ('CNTA', '<i8'), ('CNT1', '<i8'), ('SUMCOLSC', '<i8'),\
        ])
        npa = np.zeros(1, dtype=dtype)
        
        npa[0]['peridx']    = per_name_str
        npa[0]['per']       = str(list(self.cf_periods[self.gACCOUNT]))
        npa[0]['c0']        = dfana.loc['SUMROW','c0']
        npa[0]['pcmax']     = dfana.loc['SUMROW','pcmax']
        npa[0]['pcm']       = dfana.loc['SUMROW','pcm']
        npa[0]['pidmax']    = dfana.loc['SUMROW','pidmax']
        npa[0]['pidm']      = dfana.loc['SUMROW','pidm']
        npa[0]['piddelta']  = dfana.loc['SUMROW','piddelta']
        npa[0]['SUMCOL']    = dfana.loc['SUMROW','SUMCOL']
        npa[0]['CNTA']      = dfana.loc['SUMROW','CNTA']
        npa[0]['CNT1']      = dfana.loc['SUMROW','CNT1']
        npa[0]['SUMCOLSC']  = dfana.loc['SUMROW','SUMCOLSC']

        dfsum =  pd.DataFrame(npa)
        
        # convert to itself (column) from epoch to datetime string 
        # df['time']=pd.to_datetime(df['time'], unit='s')
        dfsum.insert(0,"DT",pd.to_datetime(dt_to))
        #dfsum.reset_index(level=0, inplace=True)
        dfsum.set_index(['DT'],drop=True,inplace=True)
        
        # write result for symbol only
        self.append_df( 'SUM_ANA', sym, dfsum )
        self.append_df( ('SUM_' + per_name_str) , sym, dfsum )
        
        # write result for all symbols into one table
        #dfsum.insert(0,"sym",sym)
        #self.append_df(  'SUM_ALL' , None, dfsum )
        #self.append_df( ('SUM_ALL_' + per_name_str) , None, dfsum )
        
    
    # END def analyse_df2(self,sym):
    # =============================================================================

    
    # =============================================================================
    # def append_df(self, key, sym, df):
    #     
    # =============================================================================
    def append_df(self, key, sym, df):

        
        # https://stackoverflow.com/questions/75543788/pandas-concat-doesnt-work-dataframe-object-has-no-attribute-concat-pandas
        
        # if all symbols have to be written into one single table
        if None == sym:
            if key not in self.gDF: 
                self.gDF[key] = df
            else:
                self.gDF[key] = pd.concat([self.gDF[key], df])
    
        # if sym get their own table
        else:
            if key not in self.gDF: self.gDF[key] = {}
            if sym not in self.gDF[key]: 
                self.gDF[key][sym] = df
            else:
                
                self.gDF[key][sym] = pd.concat([self.gDF[key][sym], df ])
            
    
    # END def append_df(self, key, sym, df):
    # =============================================================================

    

    # =============================================================================
    # def trade_df_pid(sym):
    #     
    # =============================================================================
    def trade_df_pid(self, sym):
    
        lenper = len(self.cf_periods[self.gACCOUNT])
        dt_to    = self.gDt['dt_to']
        dfana = self.get_df_rates( dt_to, 'ANA', sym )
        #bs = dfana.loc['SUMROW','SUMCOL']
        points = self.cf_symbols[self.gACCOUNT][sym]['points']

        # dtype = np.dtype([
        #     ('sec', '<u8'), ('vol', '<u8'), ('cnt', '<u8'), ('t1', '<i8'), ('t0', '<i8'),\
        #     ('pop', '<f8'), ('ppop', '<i8'), ('podir', '<i8'), ('opp', '<f8'), ('popp', '<f8'), ('opdir', '<i8'),\
        #     ('c1', '<f8'), ('c0', '<f8'), ('pc1', '<i8'), ('pc0', '<i8'),\
        #     ('pcmax', '<i8'), ('pcm', '<f8'),\
        #     ('pc0popD', '<i8'), ('pc0oppD', '<i8'),\
        #     ('pid1', '<i8'), ('pid0', '<i8'), ('pidmax', '<i8'), ('pidm', '<f8'),\
        #     ('pid0popD', '<i8'), ('pid0oppD', '<i8'),\
        #     ('piddelta', '<i8'), ('piddir', '<i8'), ('pcdir', '<i8'), ('pdir', '<i8')\
        # ])
        
        dt_to_prev = None
        gDFkeys = list(self.gDF.keys())
        
        if 1 < len(gDFkeys):
            dt_to_prev = gDFkeys[len(gDFkeys)-2]
            dfana_prev = self.get_df_rates( dt_to_prev, 'ANA', sym )
            
            # RATES
            for per in self.cf_periods[self.gACCOUNT]:
                # print(per)
                dfana.loc[per,'pop']   = dfana_prev.loc[per,'pop']
                dfana.loc[per,'podir'] = dfana_prev.loc[per,'podir']
                dfana.loc[per,'opp']   = dfana_prev.loc[per,'opp']
                dfana.loc[per,'opdir'] = dfana_prev.loc[per,'opdir']
            
            if 0 < self.gVerbose: print( _sprintf(" [%s] -> [%s]", dt_to, dt_to_prev))
            
        else:
            
            
            # RATES
            for per in self.cf_periods[self.gACCOUNT]:
                # print(per)
                pop   = dfana.loc[per,'c0'] + 10 * points
                podir = 1
                opp   = dfana.loc[per,'c0'] - 10 * points
                opdir = -1
                dfana.loc[per,'pop']   = pop
                dfana.loc[per,'podir'] = podir
                dfana.loc[per,'opp']   = opp
                dfana.loc[per,'opdir'] = opdir
            
            if None != dt_to_prev:
                print(dt_to_prev)

    
        # RATES
        for per in self.cf_periods[self.gACCOUNT]:
            #myhline = df.iloc[lendf-1].Pclose + ( myhlineclose - df.iloc[lendf-1].close ) / self.cf_symbols[self.gACCOUNT][sym]['points']
            #pc0popD
            dfana.loc[per,'ppop'] = (dfana.loc[per,'pop'] - dfana.loc[per,'c0']) / points + dfana.loc[per,'pc0']
            dfana.loc[per,'popp'] = (dfana.loc[per,'opp'] - dfana.loc[per,'c0']) / points + dfana.loc[per,'pc0']
            dfana.loc[per,'pc0popD'] = dfana.loc[per,'ppop'] - dfana.loc[per,'pc0']
            dfana.loc[per,'pc0oppD'] = dfana.loc[per,'popp'] - dfana.loc[per,'pc0']
            dfana.loc[per,'pid0popD'] = dfana.loc[per,'ppop'] - dfana.loc[per,'pid0']
            dfana.loc[per,'pid0oppD'] = dfana.loc[per,'popp'] - dfana.loc[per,'pid0']
    

        dfana.loc['SUMROW','c0']    = dfana['c0'].iloc[0:lenper].sum()/lenper
    
        per_name_str = 'ANA_XY'
        if 'NAME' in self.cf_periods:
            per_name_str = 'ANA_' + self.cf_periods['NAME']
        self.set_df_rates( dt_to, per_name_str, sym, dfana )
    
        #if self.gVerbose: print( dfana[['cnt','pc0','pcmax','pcm','pid0','pidmax','pidm','piddelta','piddir','pcdir','pdir','SUMCOL']] )
        #if self.gVerbose: print( dfana[['cnt','c0','pc0','pcmax','pcm','pid0','pidmax','pidm','piddelta','SUMCOL']] )
        #if self.gVerbose: print( list(dfana['SUMCOL']) )
        
    # END def trade_df_pid(sym):
    # =============================================================================


    # =============================================================================
    # def open_fig_all_periods_per_sym():
    #     
    # =============================================================================
    def open_fig_all_periods_per_sym( self ):
        
        self.g_fig_all_periods_per_sym = {}
        
        lenper = len(self.cf_periods[self.gACCOUNT])
        
        for sym in self.cf_symbols[self.gACCOUNT]: 
            #print(str(lenper) + ' ' + sym)
            width, height, nrows, ncols = _calc_subplot_rows_x_cols( lenper ) 
            ## TODO hack
            #nrows = 1
            #ncols = 1
            fig_sym = _mpf_figure_open(self.gShowFig,self.gTightLayout,width,height)
            self.g_fig_all_periods_per_sym[sym] = {}
            self.g_fig_all_periods_per_sym[sym]['fig_sym'] = fig_sym

            cnt_sym = 1

            # RATES
            for per in self.cf_periods[self.gACCOUNT]:
                # print(per)
                ax0 = fig_sym.add_subplot(nrows,ncols,cnt_sym)
                self.g_fig_all_periods_per_sym[sym][per] = ax0
                cnt_sym = cnt_sym+1
                ## TODO hack
                #break
                

    # END def open_fig_all_periods_per_sym():
    # =============================================================================

    # =============================================================================
    # def save_fig_all_periods_per_sym():
    #     
    # =============================================================================
    def save_fig_all_periods_per_sym( self, figure, sym, file_extension = '.png'):
        
        #_mpf_figure_show(self.gShowFig,self.gGlobalFig)

        if self.gSaveFig:
            dt_to    = self.gDt['dt_to']
        
            home_dir = ".\\" + self.gACCOUNT + "\\SYM\\" + sym
            os.makedirs(home_dir, exist_ok=True)
            filename_sym =  home_dir +  "\\" + str(dt_to.strftime("%Y%m%d_%H%M%S")) + file_extension
            _mpf_figure_save(figure, filename_sym)

    # END def save_fig_all_periods_per_sym():
    # =============================================================================

    # =============================================================================
    # def close_fig_all_periods_per_sym():
    #     
    # =============================================================================
    def close_fig_all_periods_per_sym(self):

        
        for sym in self.cf_symbols[self.gACCOUNT]: 
            fig_sym = self.g_fig_all_periods_per_sym[sym]['fig_sym']
            _mpf_figure_close(fig_sym)

        self.clear_ax_fig_all_periods_per_sym()

    # END def close_fig_all_periods_per_sym():
    # =============================================================================


    # =============================================================================
    # def clear_ax_fig_all_periods_per_sym():
    #     
    # =============================================================================
    def clear_ax_fig_all_periods_per_sym(self):
        
        for sym in self.cf_symbols[self.gACCOUNT]: 
            # print(sym)
            # RATES
            for per in self.cf_periods[self.gACCOUNT]:
                # print(per)
                ax0 = self.g_fig_all_periods_per_sym[sym][per]
                ax0.clear()
                ## TODO hack
                #break
                
                

    # END def clear_ax_fig_all_periods_per_sym():
    # =============================================================================
        



    # =============================================================================
    # def print_fig_all_periods_per_sym( self, sym ):
    #     
    # =============================================================================
    def print_fig_all_periods_per_sym( self, sym ):
    
        dt_to    = self.gDt['dt_to']
    
        if self.gGlobalFig and not self.gCrazyFigPattern: self.clear_ax_fig_all_periods_per_sym()
        if not self.gGlobalFig: self.open_fig_all_periods_per_sym()

        # print(sym)
        # op, dfbs = self.mt5_cnt_orders_and_positions( sym )
        # print( dfbs )

        fig_sym = self.g_fig_all_periods_per_sym[sym]['fig_sym']

        if True == self.gUsePid:
            dfana = self.get_df_rates( dt_to, 'ANA', sym )

        # RATES
        for per in self.cf_periods[self.gACCOUNT]:
            # print(per)
    
            df = self.get_df_rates( dt_to, per, sym )
            lendf    = len(df)
            if 0 >= lendf :
                #print("print_fig_all_periods_per_sym: df does not exists " + sym + " "  + per + " " + str(dt_to) + " " + str(lendf) )
                continue
            
            ax0 = self.g_fig_all_periods_per_sym[sym][per]
            filename =  per + '_' + sym + '.png'


            # TODO NORMalise
            if None != self.g_c0[sym]:

                c0 = df.iloc[lendf-1].close
                Pc0 =  int(df.iloc[lendf-1].Pclose - (c0-self.g_c0[sym]) / self.cf_symbols[self.gACCOUNT][sym]['points'])
                #print( Pc0, df.iloc[0].close, c0, self.g_c0[sym] )
                Pc0B  = None # Pc0 + 20
                Pc0B1 = None # Pc0 + 10
                Pc0S  = None # Pc0 - 10
                Pc0S1 = None # Pc0 - 20
                
                op, dfbs = self.mt5_cnt_orders_and_positions( sym )
                #print( dfbs )
                
                if 0 < dfbs.loc['POS_BUY', 'cnt'] and 0 == dfbs.loc['PEND_BUY', 'cnt']:
                    Pc0B  = +1 * dfbs.loc['POS_BUY', 'delta']
                    Pc0B1 = +2 * dfbs.loc['POS_BUY', 'delta']

                if 0 == dfbs.loc['POS_BUY', 'cnt'] and 0 < dfbs.loc['PEND_BUY', 'cnt']:
                    Pc0B  = +1 * dfbs.loc['PEND_BUY', 'delta']

                if 0 < dfbs.loc['POS_SELL', 'cnt'] and 0 == dfbs.loc['PEND_SELL', 'cnt']:
                    Pc0S  = +1 * dfbs.loc['POS_SELL', 'delta']
                    Pc0S1 = +2 * dfbs.loc['POS_SELL', 'delta']

                if 0 == dfbs.loc['POS_SELL', 'cnt'] and 0 < dfbs.loc['PEND_SELL', 'cnt']:
                    Pc0S  = +1 * dfbs.loc['PEND_SELL', 'delta']


                if None != Pc0:                    
                    df['Pc0'] = Pc0
                    key1 = 'Pc0'
                    _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading)
                
                if None != Pc0B: 
                    df['Pc0B'] = Pc0B
                    key1 = 'Pc0B'
                    _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)

                if None != Pc0B1: 
                    df['Pc0B1'] = Pc0B1
                    key1 = 'Pc0B1'
                    _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)

                if None != Pc0S: 
                    df['Pc0S'] = Pc0S
                    key1 = 'Pc0S'
                    _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)

                if None != Pc0S1: 
                    df['Pc0S1'] = Pc0S1
                    key1 = 'Pc0S1'
                    _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                
                #print( per, self.g_c0[sym], Pc0)
					
                _mpf_plot(df,type='candle',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'], style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #_mpf_plot(df,type='line',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'], style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                
                #_mpf_plot(df,type='wf',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #_mpf_plot(df,type='renko',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #_mpf_plot(df,type='ohlc',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  style="sas",  update_width_config=dict(ohlc_linewidth=1),wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                
                # key1 = 'pd'
                # #_mpf_plot(df,type='renko',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                # _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)

                key1 = 'ps'
                #_mpf_plot(df,type='renko',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)


            if True == self.gUseScalp:
                # display last 10 rows
                _start = -1* (self.KDtCount - self.gScalpOffset)
                _mpf_plot(df.iloc[_start:],type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                _mpf_plot(df.iloc[_start:],type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4))

            
            if True == self.gUsePid:
                
                # dtype = np.dtype([
                #     ('sec', '<u8'), ('vol', '<u8'), ('cnt', '<u8'), ('t1', '<i8'), ('t0', '<i8'),\
                #     ('pop', '<f8'), ('ppop', '<i8'), ('podir', '<i8'), ('opp', '<f8'), ('popp', '<f8'), ('opdir', '<i8'),\
                #     ('c1', '<f8'), ('c0', '<f8'), ('pc1', '<i8'), ('pc0', '<i8'),\
                #     ('pcmax', '<i8'), ('pcm', '<f8'),\
                #     ('pc0popD', '<i8'), ('pc0oppD', '<i8'),\
                #     ('pid1', '<i8'), ('pid0', '<i8'), ('pidmax', '<i8'), ('pidm', '<f8'),\
                #     ('pid0popD', '<i8'), ('pid0oppD', '<i8'),\
                #     ('piddelta', '<i8'), ('piddir', '<i8'), ('pcdir', '<i8'), ('pdir', '<i8')\
                # ])
   
                ppop = dfana.loc[per,'ppop']
                popp = dfana.loc[per,'popp']
                _mpf_plot(df,type='wf', hlines=[ppop,popp], ax=ax0, axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="sas",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                _mpf_plot(df,type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                    
                key0 = 'PID4MAXMIN2'
                key1 = 'PID4MAXMIN2_1'
                _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading)
                _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4))
    
                # =============================================================================
                #         
                #             # for key in self.cf_pid_params[self.gACCOUNT]:
                #             #     key0 = key + '_MAX_MIN_ALL_2'
                #             #     key1 = key + '_MAX_MIN_ALL_2_1'
                #             #     _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             key0 = 'PID1_MAX_MIN_ALL_2'
                #             key1 = 'PID1_MAX_MIN_ALL_2_1'
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             key0 = 'PID2_MAX_MIN_ALL_2'
                #             key1 = 'PID2_MAX_MIN_ALL_2_1'
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             key0 = 'PID3_MAX_MIN_ALL_2'
                #             key1 = 'PID3_MAX_MIN_ALL_2_1'
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             # key0 = 'PID4_MAX_MIN_ALL_2'
                #             # key1 = 'PID4_MAX_MIN_ALL_2_1'
                #             # _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=2),show_nontrading=self.gShowNonTrading)
                #             
                #             key0 = 'PID4MAX'
                #             _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                #  
                #             key0 = 'PID4MIN'
                #             _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                # 
                # =============================================================================
            
        self.save_fig_all_periods_per_sym(fig_sym, sym, file_extension = '_01.png')
        _mpf_figure_show()
    
        if not self.gGlobalFig: self.close_fig_all_periods_per_sym()
            
    # END def print_fig_all_periods_per_sym( self, sym ):
    # =============================================================================



    # =============================================================================
    # def single_period_plot( self, start_idx, end_idx, linewidth=1 ):
    #     
    # =============================================================================
    def single_period_plot( self, ax0, filename, dt_to, per, sym, start_idx, end_idx, linewidth=1 ):

        # df = gH.gDF['RATES']['2025-04-28 13:04:37.865628+00:00']['S900']['EURUSD']
        # Out[37]: 
        #                        DT                           DTC  ...  Pclose  Pc0
        # 0 2025-04-28 10:34:38.890 2025-04-28 10:49:37.384999936  ...   -12.0    0
        # 1 2025-04-28 10:49:37.385 2025-04-28 11:04:37.350000128  ...   -49.0    0
        # 2 2025-04-28 11:04:37.350 2025-04-28 11:19:37.240000000  ...   -94.0    0
        # 3 2025-04-28 11:19:37.240 2025-04-28 11:34:38.049999872  ...  -115.0    0
        # 4 2025-04-28 11:34:38.050 2025-04-28 11:49:37.452000000  ...   -44.0    0
        # 5 2025-04-28 11:49:37.452 2025-04-28 12:04:37.358000128  ...   -24.0    0
        # 6 2025-04-28 12:04:37.358 2025-04-28 12:19:39.680000000  ...   -88.0    0
        # 7 2025-04-28 12:19:39.680 2025-04-28 12:34:42.559000064  ...   -15.0    0
        # 8 2025-04-28 12:34:42.559 2025-04-28 12:49:37.859000064  ...    47.0    0
        # 9 2025-04-28 12:49:37.859 2025-04-28 13:04:37.865628000  ...    -2.0    0
        #                        
        # df[-2:]
        # Out[54]: 
        #                        DT                           DTC  ...  Pclose  Pc0
        # 8 2025-04-28 12:34:42.559 2025-04-28 12:49:37.859000064  ...    47.0    0
        # 9 2025-04-28 12:49:37.859 2025-04-28 13:04:37.865628000  ...    -2.0    0

        df = self.get_df_rates( dt_to, per, sym )
        if 0 < len(df) :
            df = df[start_idx:end_idx]
            #print( 'XYZ',df )
            _mpf_plot(df,type='candle',  
                        ax=ax0,
                        axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  
                        #style="sas",  
                        style="yahoo",  
                        #update_width_config=dict(ohlc_linewidth=linewidth,ohlc_ticksize=0.1),
                        update_width_config=dict(candle_linewidth=linewidth),
                        wf_params=dict(brick_size='atr',atr_length='total'),
                        pnf_params=dict(box_size='atr',atr_length='total'),
                        renko_params=dict(brick_size='atr',atr_length='total'),
                        show_nontrading=self.gShowNonTrading,
                        datetime_format=self.gDateFormat)

        return df

    # END def single_period_plot( self, start_idx, end_idx ):
    # =============================================================================

    # =============================================================================
    # def print_fig_all_periods_per_sym_NEW(( self, sym):
    #     
    # =============================================================================
    def print_fig_all_periods_per_sym_NEW( self, sym ):
    
        _start = time.time()

        dt_to    = self.gDt['dt_to']
    
        if self.gGlobalFig and not self.gCrazyFigPattern: 
            self.clear_ax_fig_all_periods_per_sym()
        if not self.gGlobalFig: 
            self.open_fig_all_periods_per_sym()


        # print(sym)
        # op, dfbs = self.mt5_cnt_orders_and_positions( sym )
        # print( dfbs )

        fig_sym = self.g_fig_all_periods_per_sym[sym]['fig_sym']

        if True == self.gUsePid:
            dfana = self.get_df_rates( dt_to, 'ANA', sym )

        # RATES
        for per in self.cf_periods[self.gACCOUNT]:
            # print(per)
    
            df = self.get_df_rates( dt_to, per, sym )
            lendf    = len(df)
            if 0 >= lendf :
                #print("print_fig_all_periods_per_sym: df does not exists " + sym + " "  + per + " " + str(dt_to) + " " + str(lendf) )
                continue
            
            ax0 = self.g_fig_all_periods_per_sym[sym][per]
            filename =  per + '_' + sym + '.png'


            # TODO NORMalise
            if None != self.g_c0[sym]:

                op, dfbs = self.mt5_cnt_orders_and_positions( sym )
                #print( dfbs )
                
                if dfbs.cnt.POS_BUY > 0:
                    c0 = dfbs.price.POS_BUY
                    Pc0 =  int((c0-self.g_c0[sym]) / self.cf_symbols[self.gACCOUNT][sym]['points'])
                    linecolor = 'b'
                elif dfbs.cnt.POS_SELL > 0:
                    c0 = dfbs.price.POS_SELL
                    Pc0 =  int((c0-self.g_c0[sym]) / self.cf_symbols[self.gACCOUNT][sym]['points'])
                    linecolor = 'r'
                else:    
                    c0 = df.iloc[lendf-1].close
                    Pc0 =  int(df.iloc[lendf-1].Pclose - (c0-self.g_c0[sym]) / self.cf_symbols[self.gACCOUNT][sym]['points'])
                    linecolor = 'g'

                #print( df.iloc[lendf-1].Pclose, Pc0, df.iloc[0].close, c0, self.g_c0[sym] )
                Pc0B  = None # Pc0 + 20
                Pc0B1 = None # Pc0 + 10
                Pc0S  = None # Pc0 - 10
                Pc0S1 = None # Pc0 - 20
                
                
                if 0 < dfbs.loc['POS_BUY', 'cnt'] and 0 == dfbs.loc['PEND_BUY', 'cnt']:
                    Pc0B  = +1 * dfbs.loc['POS_BUY', 'delta']
                    Pc0B1 = +2 * dfbs.loc['POS_BUY', 'delta']

                if 0 == dfbs.loc['POS_BUY', 'cnt'] and 0 < dfbs.loc['PEND_BUY', 'cnt']:
                    Pc0B  = +1 * dfbs.loc['PEND_BUY', 'delta']

                if 0 < dfbs.loc['POS_SELL', 'cnt'] and 0 == dfbs.loc['PEND_SELL', 'cnt']:
                    Pc0S  = +1 * dfbs.loc['POS_SELL', 'delta']
                    Pc0S1 = +2 * dfbs.loc['POS_SELL', 'delta']

                if 0 == dfbs.loc['POS_SELL', 'cnt'] and 0 < dfbs.loc['PEND_SELL', 'cnt']:
                    Pc0S  = +1 * dfbs.loc['PEND_SELL', 'delta']


                if None != Pc0:                    
                    df['Pc0'] = Pc0
                    df['Pc0C'] = df.iloc[lendf-1].Pclose
                    key1 = 'Pc0'
                    key2 = 'Pc0C'
                    _mpf_plot(df[-2:],type='candle',ax=ax0,axtitle=filename,columns=[key1,key1,key2,key2,'tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading, linecolor=linecolor)
                
                if None != Pc0B: 
                    df['Pc0B'] = Pc0B
                    key1 = 'Pc0B'
                    #_mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)

                if None != Pc0B1: 
                    df['Pc0B1'] = Pc0B1
                    key1 = 'Pc0B1'
                    #_mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)

                if None != Pc0S: 
                    df['Pc0S'] = Pc0S
                    key1 = 'Pc0S'
                    #_mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)

                if None != Pc0S1: 
                    df['Pc0S1'] = Pc0S1
                    key1 = 'Pc0S1'
                    #_mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="default",update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                
                #print( per, self.g_c0[sym], Pc0)
                
                ##_mpf_plot(df,type='candle',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'], style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #_mpf_plot(df,type='line',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'], style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                
                #_mpf_plot(df,type='wf',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #_mpf_plot(df,type='renko',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)

                #_mpf_plot(df,type='ohlc',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  style="sas",  update_width_config=dict(ohlc_linewidth=1),wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)



                if 'S3600' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'S3600', sym, -2, -1,  linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S900',  sym, -4, -1,  linewidth=4 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S300',  sym, -3, -1,  linewidth=2 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S60',   sym, -5, None,linewidth=1 )  

                elif 'S900' == per:

                    df1 = self.single_period_plot( ax0, filename, dt_to, 'S900',  sym, -2, -1,   linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'S300',  sym, -3, -1,   linewidth=4 )  
                    df3 = self.single_period_plot( ax0, filename, dt_to, 'S60',   sym, -5, -1,   linewidth=2 )  
                    df4 = self.single_period_plot( ax0, filename, dt_to, 'S15',   sym, -4, None, linewidth=1 )  
                    #print( df1, df2, df3, df4)

                elif 'S300' == per:

                    df1 = self.single_period_plot( ax0, filename, dt_to, 'S300',  sym, -2, -1,   linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'S60',   sym, -5, -1,   linewidth=4 )  
                    df3 = self.single_period_plot( ax0, filename, dt_to, 'S15',   sym, -4, -1,   linewidth=2 )  
                    df4 = self.single_period_plot( ax0, filename, dt_to, 'S5',    sym, -3, None, linewidth=1 )  
                    #print( df1, df2, df3, df4)

                elif 'S60' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'S60', sym, -2, -1,  linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S15', sym, -4, -1,  linewidth=4 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S5',  sym, -3, -1,  linewidth=2 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S1',  sym, -5, None,linewidth=1 )  


                elif 'T3600' == per:

                    # T3600
                    df1 = self.single_period_plot( ax0, filename, dt_to, 'T3600', sym, -2, -1,  linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'T900',  sym, -4, -1,  linewidth=4 )  
                    df3 = self.single_period_plot( ax0, filename, dt_to, 'T300',  sym, -3, -1,  linewidth=2 )  
                    df4 = self.single_period_plot( ax0, filename, dt_to, 'T60',   sym, -5, None,linewidth=1 )  
                    #print( '\nT3600\n', df1[['DT','DTC','pd']], '\n\nT900\n', df2[['DT','DTC','pd']], '\n\nT300\n', df3[['DT','DTC','pd']], '\n\nT60\n', df4[['DT','DTC','pd']])

                elif 'T900' == per:

                    df1 = self.single_period_plot( ax0, filename, dt_to, 'T900',  sym, -2, -1,   linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'T300',  sym, -3, -1,   linewidth=4 )  
                    df3 = self.single_period_plot( ax0, filename, dt_to, 'T60',   sym, -5, -1,   linewidth=2 )  
                    df4 = self.single_period_plot( ax0, filename, dt_to, 'T15',   sym, -4, None, linewidth=1 )  
                    #print( df1, df2, df3, df4)

                elif 'T300' == per:

                    # T300
                    df1 = self.single_period_plot( ax0, filename, dt_to, 'T300',  sym, -2, -1,   linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'T60',   sym, -5, -1,   linewidth=4 )  
                    df3 = self.single_period_plot( ax0, filename, dt_to, 'T15',   sym, -4, -1,   linewidth=2 )  
                    df4 = self.single_period_plot( ax0, filename, dt_to, 'T5',    sym, -3, None, linewidth=1 )  
                    #print( df1, df2, df3, df4)

                elif 'T60' == per:

                    # T60
                    self.single_period_plot( ax0, filename, dt_to, 'T60', sym, -2, -1,   linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'T15', sym, -4, -1,   linewidth=4 )  
                    self.single_period_plot( ax0, filename, dt_to, 'T5',  sym, -3, None, linewidth=1 )  
    

                elif 'S30' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'S30', sym, -2, -1,  linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S15', sym, -2, -1,  linewidth=4 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S5',  sym, -3, -1,  linewidth=2 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S1',  sym, -5, None,linewidth=1 )  

                elif 'S15' == per:

                    df1 = self.single_period_plot( ax0, filename, dt_to, 'S15',  sym, -2, -1,   linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'S5',   sym, -3, -1,   linewidth=4 )  
                    df3 = self.single_period_plot( ax0, filename, dt_to, 'S1',   sym, -5, None, linewidth=1 )  
                    #print( df1, df2, df3)

                elif 'S5' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'S5',  sym, -2, -1,  linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'S1',  sym, -5, None,linewidth=1 )  

                elif 'S1' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'S1',   sym, -5, None,linewidth=1 )  

                elif 'T30' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'T30',  sym, -2, -1,  linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'T15',  sym, -2, -1,  linewidth=4 )  
                    self.single_period_plot( ax0, filename, dt_to, 'T5',   sym, -3, -1,  linewidth=2 )  
                    self.single_period_plot( ax0, filename, dt_to, 'T1',   sym, -5, None,linewidth=1 )  

                elif 'T15' == per:

                    df1 = self.single_period_plot( ax0, filename, dt_to, 'T15',  sym, -2, -1,   linewidth=8 )  
                    df2 = self.single_period_plot( ax0, filename, dt_to, 'T5',    sym, -3, None, linewidth=1 )  
                    #print( df1, df2)

                elif 'T5' == per:

                    self.single_period_plot( ax0, filename, dt_to, 'T5',  sym, -2, -1,  linewidth=8 )  
                    self.single_period_plot( ax0, filename, dt_to, 'T5',  sym, -1, None,linewidth=1 )  

                elif 'T1' == per:
                    self.single_period_plot( ax0, filename, dt_to, 'T1',   sym, -5, None,linewidth=1 )  

                else:

                    _mpf_plot(df,type='candle',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  style="sas",  update_width_config=dict(ohlc_linewidth=1),wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)

                    
                
                # key1 = 'pd'
                # #_mpf_plot(df,type='renko',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                # _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)

                dfps = df[-5:]
                key1 = 'ps'
                #_mpf_plot(dfps,type='renko',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                ###_mpf_plot(dfps,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="sas", update_width_config=dict(ohlc_linewidth=10), wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)


            if True == self.gUseScalp:
                # display last 10 rows
                _start = -1* (self.KDtCount - self.gScalpOffset)
                _mpf_plot(df.iloc[_start:],type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                _mpf_plot(df.iloc[_start:],type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4))

            
            if True == self.gUsePid:
                
                # dtype = np.dtype([
                #     ('sec', '<u8'), ('vol', '<u8'), ('cnt', '<u8'), ('t1', '<i8'), ('t0', '<i8'),\
                #     ('pop', '<f8'), ('ppop', '<i8'), ('podir', '<i8'), ('opp', '<f8'), ('popp', '<f8'), ('opdir', '<i8'),\
                #     ('c1', '<f8'), ('c0', '<f8'), ('pc1', '<i8'), ('pc0', '<i8'),\
                #     ('pcmax', '<i8'), ('pcm', '<f8'),\
                #     ('pc0popD', '<i8'), ('pc0oppD', '<i8'),\
                #     ('pid1', '<i8'), ('pid0', '<i8'), ('pidmax', '<i8'), ('pidm', '<f8'),\
                #     ('pid0popD', '<i8'), ('pid0oppD', '<i8'),\
                #     ('piddelta', '<i8'), ('piddir', '<i8'), ('pcdir', '<i8'), ('pdir', '<i8')\
                # ])
   
                ppop = dfana.loc[per,'ppop']
                popp = dfana.loc[per,'popp']
                _mpf_plot(df,type='wf', hlines=[ppop,popp], ax=ax0, axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="sas",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                _mpf_plot(df,type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                    
                key0 = 'PID4MAXMIN2'
                key1 = 'PID4MAXMIN2_1'
                _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading)
                _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=1,ohlc_ticksize=0.4))
    
                # =============================================================================
                #         
                #             # for key in self.cf_pid_params[self.gACCOUNT]:
                #             #     key0 = key + '_MAX_MIN_ALL_2'
                #             #     key1 = key + '_MAX_MIN_ALL_2_1'
                #             #     _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             key0 = 'PID1_MAX_MIN_ALL_2'
                #             key1 = 'PID1_MAX_MIN_ALL_2_1'
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             key0 = 'PID2_MAX_MIN_ALL_2'
                #             key1 = 'PID2_MAX_MIN_ALL_2_1'
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             key0 = 'PID3_MAX_MIN_ALL_2'
                #             key1 = 'PID3_MAX_MIN_ALL_2_1'
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],update_width_config=dict(ohlc_linewidth=1),show_nontrading=self.gShowNonTrading)
                # 
                #             # key0 = 'PID4_MAX_MIN_ALL_2'
                #             # key1 = 'PID4_MAX_MIN_ALL_2_1'
                #             # _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=2),show_nontrading=self.gShowNonTrading)
                #             
                #             key0 = 'PID4MAX'
                #             _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                #  
                #             key0 = 'PID4MIN'
                #             _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                # 
                # =============================================================================
            
        self.save_fig_all_periods_per_sym(fig_sym, sym, file_extension = '_02.png')

        _startShow = time.time()
        _mpf_figure_show()
    
        if not self.gGlobalFig: self.close_fig_all_periods_per_sym()

        _deltamsShow = int((time.time()-_startShow)*1000)
        _deltams = int((time.time()-_start)*1000)

        print( " deltams(ALL): ", _deltams, " deltams(SHOW): ", _deltamsShow)        

            
    # END def print_fig_all_periods_per_sym_NEW( self, sym):
    # =============================================================================

    # =============================================================================
    # def print_past_entries_per_sym(self):
    #     
    # =============================================================================
    def print_past_entries_per_sym(self):
    
        # PERIODS
        for per in self.cf_periods[self.gACCOUNT]:
            
            # SYMBOLS
            for sym in self.cf_symbols[self.gACCOUNT]: 
    
                lkeys=list(self.gDF['RATES'].keys())
                len_d = len( self.gDF['RATES'] )
                start = len_d - 28
                if 0 > start:
                    start = 0
                cnt = start
            
                fig_sym = _mpf_figure_open(self.gShowFig,self.gTightLayout,32,20)
            
                df = self.get_df_rates(lkeys[(len_d-1)], per, sym )
                
                lendf = len(df)-1
                if 'TDs' in df.columns:
                    dt_from = df.iloc[lendf].DT + timedelta(seconds=(df.iloc[lendf].TDs))   
                else:
                    dt_from = df.iloc[lendf].DT
                home_dir = ".\\" + self.gACCOUNT + "\\" + per + "\\" + sym
                os.makedirs(home_dir, exist_ok=True)
                filename_sym =  home_dir +  "\\" + str(dt_from.strftime("%Y%m%d_%H%M%S.png"))
                
                cnt_sym = 1
                
                myhlineclose = 0.
                
                while cnt < len_d:
                    # print ( lkeys[cnt] )
                    # print ( self.gDF['RATES'][lkeys[cnt]][per][sym].iloc[9].DT )
                    # print ( self.gDF['RATES'][lkeys[cnt]][per][sym].iloc[9].TDs )
                    # print ( self.gDF['RATES'][lkeys[cnt]][per][sym] )
                    df = self.gDF['RATES'][lkeys[cnt]][per][sym]
                    lendf = len(df)
                    myhline = -42
                    if cnt == start:
                        myhline = df.iloc[lendf-1].Pclose
                        myhlineclose = df.iloc[lendf-1].close
                    else:
                        myhline = df.iloc[lendf-1].Pclose + ( myhlineclose - df.iloc[lendf-1].close ) / self.cf_symbols[self.gACCOUNT][sym]['points']
                        
                    
                    
                    if 'TDs' in df.columns:
                        dt_from_cnt = df.iloc[lendf-1].DT + timedelta(seconds=(df.iloc[lendf-1].TDs))   
                    else:
                        dt_from_cnt = df.iloc[lendf-9].DT
                    print(sym + str(dt_from_cnt.strftime("_%Y%m%d_%H%M%S_PER_")) + per + '_' + str(cnt))
                    ax0 = fig_sym.add_subplot(4,7,cnt_sym)
                    cnt_sym = cnt_sym + 1
                    filename =  str(dt_from_cnt.strftime("%H%M%S")) + '_' + per + '_' + sym
            
                    _mpf_plot(df,type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="sas",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                    _mpf_plot(df,type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                    key0 = 'PID4MAXMIN2'
                    key1 = 'PID4MAXMIN2_1'
                    #_mpf_plot(df,type='ohlc',hlines=[myhline],ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading)
    
                    # # orig keep        
                    # key0 = 'PID1_MAX_MIN_ALL_2'
                    # _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                    # key0 = 'PID1_MAX_MIN_P4_2'
                    # _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                    _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="starsandstripes",update_width_config=dict(ohlc_linewidth=3,ohlc_ticksize=0.4))
                    
                    cnt = cnt+1
                
                _mpf_figure_save (fig_sym,filename_sym)
                _mpf_figure_show ()
                _mpf_figure_close(fig_sym)
    
    # END def print_past_entries_per_sym():
    # =============================================================================


    # =============================================================================
    # def print_fig_all_periods_and_all_syms(self):
    #     
    # =============================================================================
    def print_fig_all_periods_and_all_syms(self):
        
        dt_to    = self.gDt['dt_to']
        
        # PERIODS
        for per in self.cf_periods[self.gACCOUNT]:
            
            fig_sym = _mpf_figure_open(self.gShowFig,self.gTightLayout,32,20)
            
            home_dir = ".\\" + self.gACCOUNT + "\\PER\\" + per
            os.makedirs(home_dir, exist_ok=True)
            filename_sym =  home_dir +  "\\" + str(dt_to.strftime("%Y%m%d_%H%M%S.png"))
            
            cnt_sym = 1
        
            # SYMBOLS
            for sym in self.cf_symbols[self.gACCOUNT]: 
                # print(sym)
                    
                print(sym + str(dt_to.strftime("_%Y%m%d_%H%M%S_PER_")) + per)
                df = self.gDF['RATES'][str(dt_to)][per][sym]
                df1 = self.gDF['RATES'][str(dt_to)]['T1'][sym]
                lendf    = len(df)
                if 0 >= lendf :
                    raise ValueError("print_fig_all_periods_per_sym: df does not exists " + sym + " "  + per + " " + str(dt_to) + " " + str(len) )
                
                # Original - keep
                # ax0 = fig_sym.add_subplot(28,4,cnt_sym)
                ax0 = fig_sym.add_subplot(4,7,cnt_sym)
                cnt_sym = cnt_sym + 1
                filename =  per + '_' + sym + '.png'
    
                # =============================================================================
                #             # Original - keep
                #             # ax1 = ax0
                #             # ap0 = mpf.make_addplot(df['PID1_MAX_MIN_P4_2_D_WF'],ax=ax0)#,ylabel='Bollinger Bands')    
                #             # _mpf_plot(df,type='candle',ax=ax1,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],savefig=filename,addplot=ap0)
                #             
                #             key0 = 'PID1_MAX_MIN_ALL_2'
                #             _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                #         
                #             key0 = 'PID1_MAX_MIN_P4_2'
                #             _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key0,key0,key0,key0,'tick_volume'])
                #         
                #             # key0 = 'PID1_MAX_MIN_ALL_2_D_WF'
                #             # key1 = 'PID1_MAX_MIN_ALL_2_D_WF1'
                #             # _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="yahoo")
                #     
                #             # key0 = 'PID1_MAX_MIN_P4_2_D_WF'
                #             # key1 = 'PID1_MAX_MIN_P4_2_D_WF1'
                #             # _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume']) # ,style="starsandstripes")
                #             
                #             # _mpf_plot(df,type='candle',ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'])
                #             _mpf_plot(df,type='renko',  ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                #             #_mpf_plot(df,type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="starsandstripes",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading)
                #             _mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="starsandstripes",update_width_config=dict(ohlc_linewidth=3,ohlc_ticksize=0.4))
                #             
                #             
                # =============================================================================
                _mpf_plot(df,type='candle', ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                _mpf_plot(df,type='ohlc',   ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  style="sas",  update_width_config=dict(ohlc_linewidth=1),wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                
                # _mpf_plot(df,type='line',   ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  style="sas",  update_width_config=dict(ohlc_linewidth=3),wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                
                # #_mpf_plot(df,type='wf',  ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="starsandstripes",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                # #_mpf_plot(df,type='renko',  ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="yahoo",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                # _mpf_plot(df,type='pnf',  ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'],style="sas",wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                # _mpf_plot(df1,type='line',   ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],  style="sas",  update_width_config=dict(ohlc_linewidth=1),wf_params=dict(brick_size='atr',atr_length='total'),pnf_params=dict(box_size='atr',atr_length='total'),renko_params=dict(brick_size='atr',atr_length='total'),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                
                #_mpf_plot(df,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #_mpf_plot(df1,type='line',ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading, datetime_format=self.gDateFormat)
                #print( df )
                
            _mpf_figure_save (fig_sym,filename_sym)
            _mpf_figure_show ()
            _mpf_figure_close(fig_sym)
                
    
    # END def print_fig_all_periods_and_all_syms(self):
    # =============================================================================

    # =============================================================================
    # def print_fig_all_periods_and_one_sym_and_all_times():
    #     
    # =============================================================================
    def print_fig_all_periods_and_one_sym_and_all_times(self):
    
        td_step = timedelta(hours=1)
        dt_to   = datetime.now(timezone.utc) + self.tdOffset + td_step
        dt_to   = dt_to - td_step
        dt_from = datetime(2020,11,18,0,tzinfo=timezone.utc) - td_step
    
        for sym in self.cf_symbols[self.gACCOUNT]: 
            # print(sym)
    
            # PERIODS
            for per in self.cf_periods[self.gACCOUNT]:
    
                fig_sym = _mpf_figure_open(self.gShowFig,self.gTightLayout,30,150)
                
                filename_sym =  dt_to.strftime("%Y%m%d_%H%M%S_") + sym + "_" + per + ".png"
                cnt_sym = 1
                td_step = timedelta(seconds=(self.cf_periods[self.gACCOUNT][per]['seconds']))
                #dt_from = dt_to - timedelta(seconds=((15*4+10)*self.cf_periods[self.gACCOUNT][per]['seconds']))
                dt_cnt  = dt_to - timedelta(seconds=((15*4+ 0)*self.cf_periods[self.gACCOUNT][per]['seconds']))
                if dt_cnt < dt_from:
                    dt_cnt = dt_from + 2*td_step
        
                while dt_to >= dt_cnt:
    
                    dt_cnt = dt_cnt + td_step
                        
                    if (15*4 < cnt_sym) : continue
        
                    print( dt_from)
                    print( dt_cnt )
                    print( dt_to  )
                    key = per + "_" + sym
                    print(str(cnt_sym) + "_" + key + " " + filename_sym)
                    
                    # copy range dt_from to dt_to to a npa (numpy array)
                    npa = self.mt5.copy_rates_range(sym, self.get_mt5_TIMEFRAME_from_String(per), (dt_from+self.tdOffset), (dt_cnt+self.tdOffset))
                    #npa = self.mt5.copy_rates_from(sym, get_mt5_TIMEFRAME_from_String(per), (dt_cnt+gTdOffset), (15*4+10))
                    
                    df = pd.DataFrame(npa)
                    print(df)
                    df = self.set_excel_func_to_df(df,self.cf_symbols[self.gACCOUNT][sym],sym,per)
                    self.gDF[key] = df
                    
                    df10 = df.iloc[cnt_sym:(cnt_sym+10)]
                    df09 = df.iloc[cnt_sym:(cnt_sym+9)]
            
                    ax0 = fig_sym.add_subplot(15,4,cnt_sym)
                    cnt_sym = cnt_sym + 1
                    # ax1 = ax0.twiny()
                    # ax2 = ax0.twinx()
                    filename =  per + '_' + sym + '.png'
        
                    # _mpf_plot(df10,type='ohlc',ax=ax1,axtitle=filename,columns=['PID1_MAX_MIN_P4_2_D_WF1','PID1_MAX_MIN_P4_2_D_WF1','PID1_MAX_MIN_P4_2_D_WF','PID1_MAX_MIN_P4_2_D_WF','tick_volume'],style="yahoo")
                    key1 = 'PID4_MAX_MIN_P4_2_D_WF1'
                    key0 = 'PID4_MAX_MIN_P4_2_D_WF'
                    _mpf_plot(df10,type='ohlc',ax=ax0,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="starsandstripes",update_width_config=dict(ohlc_linewidth=3,ohlc_ticksize=0.4))
                    
                    # ap0 = mpf.make_addplot(df10['PID1_MAX_MIN_P4_2_D_WF'],ax=ax0)#,ylabel='Bollinger Bands')    
                    # _mpf_plot(df10,type='candle',ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],savefig=filename,addplot=ap0)
                    
                    # _mpf_plot(df10,type='line',ax=ax0,axtitle=filename,columns=['Popen','Popen','Popen','Popen','tick_volume'])
                    _mpf_plot(df09,type='candle',ax=ax0,axtitle=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'])
                    _mpf_plot(df10,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Popen','Popen','tick_volume'],update_width_config=dict(ohlc_linewidth=3,ohlc_ticksize=0.4))
                    # _mpf_plot(df09,type='line',ax=ax0,axtitle=filename,columns=['Phigh','Phigh','Phigh','Phigh','tick_volume'])
                    # _mpf_plot(df09,type='line',ax=ax0,axtitle=filename,columns=['Plow','Plow','Plow','Plow','tick_volume'])
                    
                    # _mpf_plot(df10,type='ohlc',ax=ax0,axtitle=filename,columns=['Popen','Popen','Pclose','Pclose','tick_volume'])
                    
                    # _mpf_plot(df10,type='ohlc',ax=ax0,axtitle=filename,columns=['PID1_MAX_MIN_ALL_2_D_WF1','PID1_MAX_MIN_ALL_2_D_WF1','PID1_MAX_MIN_ALL_2_D_WF','PID1_MAX_MIN_ALL_2_D_WF','tick_volume'],style="yahoo")
                    # key1 = 'PID2_MAX_MIN_P4_2_D_WF1'
                    # key0 = 'PID2_MAX_MIN_P4_2_D_WF'
                    # _mpf_plot(df10,type='ohlc',ax=ax2,axtitle=filename,columns=[key1,key1,key0,key0,'tick_volume'],style="yahoo",update_width_config=dict(ohlc_linewidth=5,ohlc_ticksize=0.4))
                    # _mpf_plot(df10,type='ohlc',ax=ax1,axtitle=filename,columns=['PID1WF1','PID1WF1','PID1WF','PID1WF','tick_volume'],style="yahoo")
                    # _mpf_plot(df10,type='ohlc',ax=ax1,axtitle=filename,columns=['PID4WF1','PID4WF1','PID4WF','PID4WF','tick_volume'],savefig=filename)
                    # _mpf_plot(df10,type='candle',ax=ax0,volume=ax4,title=filename,columns=['Popen','Phigh','Plow','Pclose','tick_volume'],savefig=filename,addplot=ap0)
    
                
                _mpf_figure_close(fig_sym, filename_sym)

    # END def print_fig_all_periods_and_one_sym_and_all_times():
    # =============================================================================

    # =============================================================================
    # def get_mt5_TIMEFRAME_from_String(sPeriod):
    #     
    # =============================================================================
    def get_mt5_TIMEFRAME_from_String(self, sPeriod):
        # KsPERIOD = ['M1','M5','M15','H1']
        # KsPERIOD = [self.mt5.TIMEFRAME_M1,self.mt5.TIMEFRAME_M5,self.mt5.TIMEFRAME_M15,self.mt5.TIMEFRAME_H1]
        retVal = 0
        if 'M1' == sPeriod:
          retVal = self.mt5.TIMEFRAME_M1
        elif 'M5' == sPeriod:
          retVal = self.mt5.TIMEFRAME_M5
        elif 'M15' == sPeriod:
          retVal = self.mt5.TIMEFRAME_M15
        elif 'H1' == sPeriod:
          retVal = self.mt5.TIMEFRAME_H1
        else:
          print(" XXX ERROR mt5_TIMEFRAME_from_String unknown sPeriod " + sPeriod)
        return retVal
    
    # END def get_mt5_TIMEFRAME_from_String(sPeriod):
    # =============================================================================


    # =============================================================================
    # def clear_ticks( dt_from ):
    #     
    # =============================================================================
    def clear_ticks( self, dt_from ):
        for sym in self.cf_symbols[self.gACCOUNT]: 
            self.set_df( 'TICKS', sym, {} )
            
    # END def clear_ticks( dt_from ):
    # =============================================================================

    # =============================================================================
    #  def mt5_init( self ):
    #     
    # =============================================================================
    def mt5_init( self ):
    # =============================================================================

        ret = False   

        login    = self.cf_accounts[self.gACCOUNT]['login']
        password = self.cf_accounts[self.gACCOUNT]['password']
        server   = self.cf_accounts[self.gACCOUNT]['server']
        portable = bool(self.cf_accounts[self.gACCOUNT]['portable'])

        # TODO consolidate create CONFIG CLASS that reads path_mt5_bin and path_mt5_config
        dir_appdata =  os.getenv('APPDATA') 
        path_mt5 = dir_appdata +  "\\MetaTrader5_" + self.gACCOUNT
        path_mt5_bin = path_mt5 + "\\terminal64.exe"
        path_mt5_user =  os.getenv('USERNAME') + '@' + os.getenv('COMPUTERNAME')
        path_mt5_config = path_mt5 + "\\config\\cf_accounts_" + path_mt5_user + ".json"

        if (1000 > login) or  ( "your-password-here" == password ):
            raise ValueError( _sprintf("ERROR: algotrader.mt5_init.mt5.initialize - \
                                       please check and correct 'login/password' in config file [%s] in section [%s: login= , password= ]", \
                                       path_mt5_config,\
                                       self.gACCOUNT ) )
    
        if "RoboForex-ECN" != server:
            raise ValueError( _sprintf("ERROR: algotrader.mt5_init.mt5.initialize - \
                                       please set mt5 'server' in config file [%s] to [%s: server='RoboForex-ECN']", \
                                       path_mt5_config,\
                                       self.gACCOUNT ) )

        if True != portable:
            raise ValueError( _sprintf("ERROR: algotrader.mt5_init.mt5.initialize - \
                                       please set mt5 'portable' in config file [%s] to [%s: portable='True']", \
                                       path_mt5_config,\
                                       self.gACCOUNT ) )

        # connect to MetaTrader 5
        self.mt5.shutdown()
        ret = self.mt5.initialize( \
                path     = path_mt5_bin,\
                login    = login,\
                password = password,\
                server   = server,\
                portable = portable) 
        
        if not ret:
            print("initialize() failed")
            print()
            self.mt5.shutdown()
            raise ValueError( _sprintf("ERROR: algotrader.mt5_init.mt5.initialize FAILED - \
                                       please check and correct 'login/password' in config file [%s] in section [%s: login=%s , password=%s ] - \
                                       If problem persists afterwards, then please re-run 'python setup.py'.", \
                                       path_mt5_config,\
                                       self.gACCOUNT, login, password ) )
        
            

        else:
            # request connection status and parameters
            # TODO check that AccountInfo and TerminalInfo are as requested
            # AccountInfo(login=67008870, trade_mode=0, leverage=500, limit_orders=500, margin_so_mode=0, trade_allowed=True, trade_expert=True, margin_mode=0, currency_digits=2, fifo_close=False, balance=264.23, credit=0.0, profit=0.0, equity=264.23, margin=0.0, margin_free=264.23, margin_level=0.0, margin_so_call=60.0, margin_so_so=40.0, margin_initial=0.0, margin_maintenance=0.0, assets=0.0, liabilities=0.0, commission_blocked=0.0, name='Andre Howe', server='RoboForex-ECN', currency='USD', company='RoboForex Ltd')
            # TerminalInfo(community_account=False, community_connection=False, connected=True, dlls_allowed=True, trade_allowed=True, tradeapi_disabled=False, email_enabled=False, ftp_enabled=False, notifications_enabled=False, mqid=False, build=2755, maxbars=100000, codepage=0, ping_last=42214, community_balance=0.0, retransmission=0.0, company='MetaQuotes Software Corp.', name='MetaTrader 5', language='English', path='C:\\OneDrive\\rfx\\mt\\I7\\RF5D01', data_path='C:\\OneDrive\\rfx\\mt\\I7\\RF5D01', commondata_path='C:\\Users\\Andre\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common')
            # (500, 2755, '15 Jan 2021')
            if 1 < self.gVerbose:            
                print(self.mt5.account_info())
                print(self.mt5.terminal_info())
                # get data on MetaTrader 5 version
                print(self.mt5.version())
                print()

        return ret        
            
    # END  def mt5_init( self ):
    # =============================================================================



    # gAt0.mt5_fx_scalper('GBPJPY',0.01)
    # OrderCheckResult(retcode=10015, balance=0.0, equity=0.0, profit=0.0, margin=0.0, margin_free=0.0, margin_level=0.0, comment='Invalid price', request=TradeRequest(action=5, magic=456, order=0, symbol='GBPJPY', volume=0.02, price=143.399, stoplimit=0.0, sl=0.0, tp=0.0, deviation=0, type=5, type_filling=1, type_time=1, expiration=0, comment='SPO', position=0, position_by=0))
    #    retcode=10015
    #    balance=0.0
    #    equity=0.0
    #    profit=0.0
    #    margin=0.0
    #    margin_free=0.0
    #    margin_level=0.0
    #    comment=Invalid price
    #    request=TradeRequest(action=5, magic=456, order=0, symbol='GBPJPY', volume=0.02, price=143.399, stoplimit=0.0, sl=0.0, tp=0.0, deviation=0, type=5, type_filling=1, type_time=1, expiration=0, comment='SPO', position=0, position_by=0)
    #        requestBPO: action=5
    #        requestBPO: magic=456
    #        requestBPO: order=0
    #        requestBPO: symbol=GBPJPY
    #        requestBPO: volume=0.02
    #        requestBPO: price=143.399
    #        requestBPO: stoplimit=0.0
    #        requestBPO: sl=0.0
    #        requestBPO: tp=0.0
    #        requestBPO: deviation=0
    #        requestBPO: type=5
    #        requestBPO: type_filling=1
    #        requestBPO: type_time=1
    #        requestBPO: expiration=0
    #        requestBPO: comment=SPO
    #        requestBPO: position=0
    #        requestBPO: position_by=0
    #  XXX ERROR PENDING ORDERCHECK FAILED 
    
    #  mt5_fx_scalper[S03.04] - NO - buy position  - check volume of counter pending sell stop order ERR [0.010000] != [0.010000] - create new order at [143.399000]
    # Out[178]: (False, 'S03.04')
    
    # gAt0.mt5_fx_scalper('GBPJPY',0.01,50)
    #  mt5_fx_scalper[S03.04] - NO - buy position  - check volume of counter pending sell stop order ERR [0.010000] != [0.010000] - create new order at [143.374000]
    # Out[179]: (False, 'S03.04')
    
    # gAt0.mt5_fx_scalper('GBPJPY',0.01,50)
    # OrderCheckResult(retcode=10015, balance=0.0, equity=0.0, profit=0.0, margin=0.0, margin_free=0.0, margin_level=0.0, comment='Invalid price', request=TradeRequest(action=5, magic=123, order=0, symbol='GBPJPY', volume=0.02, price=143.323, stoplimit=0.0, sl=0.0, tp=0.0, deviation=0, type=4, type_filling=1, type_time=1, expiration=0, comment='BPO', position=0, position_by=0))
    #    retcode=10015
    #    balance=0.0
    #    equity=0.0
    #    profit=0.0
    #    margin=0.0
    #    margin_free=0.0
    #    margin_level=0.0
    #    comment=Invalid price
    #    request=TradeRequest(action=5, magic=123, order=0, symbol='GBPJPY', volume=0.02, price=143.323, stoplimit=0.0, sl=0.0, tp=0.0, deviation=0, type=4, type_filling=1, type_time=1, expiration=0, comment='BPO', position=0, position_by=0)
    #        requestBPO: action=5
    #        requestBPO: magic=123
    #        requestBPO: order=0
    #        requestBPO: symbol=GBPJPY
    #        requestBPO: volume=0.02
    #        requestBPO: price=143.323
    #        requestBPO: stoplimit=0.0
    #        requestBPO: sl=0.0
    #        requestBPO: tp=0.0
    #        requestBPO: deviation=0
    #        requestBPO: type=4
    #        requestBPO: type_filling=1
    #        requestBPO: type_time=1
    #        requestBPO: expiration=0
    #        requestBPO: comment=BPO
    #        requestBPO: position=0
    #        requestBPO: position_by=0
    #  XXX ERROR PENDING ORDERCHECK FAILED 
    
    #  mt5_fx_scalper[S04.04] - NO - sell position  - check volume of counter pending buy stop order ERR [0.010000] != [0.000000] - create new order at [143.323000]
    # Out[180]: (False, 'S04.04')
    
    # gAt0.mt5_fx_scalper('GBPJPY',0.01,-50)
    #  mt5_fx_scalper[S04.04] - NO - sell position  - check volume of counter pending buy stop order ERR [0.010000] != [0.000000] - create new order at [143.423000]
    # Out[181]: (False, 'S04.04')
    
    # gAt0.mt5_fx_scalper('GBPJPY',0.01,-50)
    #  mt5_fx_scalper[S04.02] - OK - sell position - check volume of counter pending buy stop order OK
    # Out[182]: (True, 'S04.02')
    
    # gAt0.mt5_fx_scalper('GBPJPY',0.01,-10)
    #  mt5_fx_scalper[S04.03]- OK - sell position - modify pending counter buy order [143.423000] -> [143.383000]
    # Out[183]: (False, 'S04.03')
    
    # gAt0.mt5_fx_scalper('GBPJPY',0.01,-10)
    #  mt5_fx_scalper[S04.02] - OK - sell position - check volume of counter pending buy stop order OK
    # Out[184]: (True, 'S04.02')


    #
    # test self.mt5 API
    #
    
    # misc
    # def mt5_fx_scalper(self, sym, vol, piddelta = None ):
    # def mt5_cnt_orders_and_positions( self, sym ):    
    # def mt5_test_functions(self, sym, vol):
    #
    # pending orders
    # def mt5_pending_order_first( self, sym, volume = 0.01, offsetpar = 20 ):
    # def mt5_pending_order_remove( self, sym ):
    # def mt5_pending_order_modify( self, sym, price, magic ):
    # def mt5_pending_order_raw(self, symbol, volume, price, order_type, comment, magic):    
    # 
    # positions    
    # def mt5_position_raw_order(self, order_type, symbol, volume, price, comment=None, ticket=None):    
    # def mt5_position_close(self, symbol, *, comment=None, ticket=None):    
    # def mt5_position_buy(self, symbol, volume, price=None, *, comment=None, ticket=None):    
    # def mt5_position_sell(self, symbol, volume, price=None, *, comment=None, ticket=None):    

    # =============================================================================
    #  def mt5_fx_scalper(self, sym, vol, piddelta = None ):
    #     
    # =============================================================================
    def mt5_fx_scalper(self, sym, vol, piddelta = None, offset_pend_order = None, tp_lvl = None ):
        
        
        dt_start     = datetime.now(timezone.utc) + self.tdOffset
        dt_start_str = str(dt_start.strftime("%Y%m%d_%H:%M:%S_"))  
        

        if None != offset_pend_order:
            self.offset = offset_pend_order
        
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )

        # sanity check
        # 
        # at0.mt5_cnt_orders_and_positions( 'GBPJPY' )
        # Out[26]: 
        # {'total': 0,
        #  'order_pend_buy': 0,
        #  'order_pend_buy_vol': 0,
        #  'order_pend_buy_price': 0,
        #  'order_pend_sell': 0,
        #  'order_pend_sell_vol': 0,
        #  'order_pend_sell_price': 0,
        #  'order_pos_buy': 0,
        #  'order_pos_buy_vol': 0,
        #  'order_pos_buy_price_max': 0,
        #  'order_pos_sell': 0,
        #  'order_pos_sell_vol': 0,
        #  'order_pos_sell_price_min': 0}        
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        
        # calculate offset, which is set in pending order


        #
        # mt5_fx_scalper state 1
        #   first pending order - create pending orders
        #
        state = None
        if ( 0      == orders['total'] ) :
            state =   dt_start_str + "S01.01"
            self.mt5_pending_order_first(sym, vol, self.offset)
            print( _sprintf(" mt5_fx_scalper[%s] - OK - mt5_first_pending_order create", state ))
            return True, state

        #
        # mt5_fx_scalper state 2
        #   first pending order - offset wrong
        #
        if ( 2      == orders['total'] ) and \
           ( 1      == orders['order_pend_buy'] ) and \
           ( vol    == orders['order_pend_buy_vol'] ) and \
           ( 1      == orders['order_pend_sell'] ) and \
           ( vol    == orders['order_pend_sell_vol'] ) :
            priceBPO = round(orders['order_pend_buy_price'],  digits)
            priceSPO = round(orders['order_pend_sell_price'], digits)
            offsetSet = int(round((priceBPO - priceSPO)/point,digits))
            
            # TODO for reverse pending offset start - make optional
            #if (2*self.offset) == abs(offsetSet):
            if (2*self.offset) == offsetSet:
                state =   dt_start_str + "S02.01"
                print( _sprintf(" mt5_fx_scalper[%s] - OK - mt5_first_pending_order offset check OK", state))
                return True, state
            else:
                state =   dt_start_str + "S02.02"
                print( _sprintf(" mt5_fx_scalper[%s] - NO - mt5_first_pending_order offset check ERR [%d] != [%d]  [%f] [%f]", state, (2*self.offset), offsetSet, priceBPO, priceSPO ))
                self.mt5_pending_order_remove(sym)
                return False, state
               
        #
        # mt5_fx_scalper state 3
        #   buy position
        #
        if ( 1      == orders['order_pos_buy'] ) :
        
            if None == piddelta:
                piddelta = abs( self.offset )
        
            #
            # state 3 - buy position
            #  3.1 check volume of open position
            #
            if ( vol  != orders['order_pos_buy_vol'] ) :
                state =   dt_start_str + "S03.01"
                print( _sprintf(" mt5_fx_scalper[%s] - NO - buy position - volume check ERR [%f] != [%f]", state, vol, orders['order_pos_buy_vol'] ))
                self.mt5_position_close(sym)
                self.mt5_pending_order_remove(sym)
                return False, state

            #
            # state 3 - buy position
            #  3.2 check volume of counter pending sell stop order
            #
            if ( 2      == orders['total'] ) and \
               ( 1      == orders['order_pos_buy'] ) and \
               ( vol    == orders['order_pos_buy_vol'] ) and \
               ( 1      == orders['order_pend_sell'] ) and \
               ( (2*vol)== orders['order_pend_sell_vol'] ) :
               
                priceBPO = orders['order_pos_buy_price_max']
                priceSPO = orders['order_pend_sell_price']
                offsetSet = abs(int(round((priceBPO - priceSPO)/point,digits)))
                if piddelta == offsetSet:
                    state =   dt_start_str + "S03.02"
                    if None != tp_lvl:
                        self.mt5_position_sltp_follow2( sym, tp_lvl, 0 )
                    print( _sprintf(" mt5_fx_scalper[%s] - OK - buy position - check volume of counter pending sell stop order OK" , state ))
                    return True, state
                else:
                    state =   dt_start_str + "S03.03"
                    priceSPOprev = priceSPO
                    priceSPO = round( (priceBPO-piddelta*point)    , digits )
                    ret = self.mt5_pending_order_modify( sym, 
                                               priceSPO, 
                                               456)
                    
                    if True == ret:
                        print( _sprintf(" mt5_fx_scalper[%s]- OK - buy position - modify pending counter sell order [%f] -> [%f]", state, priceSPOprev, priceSPO ))
                    else:
                        self.mt5_position_close(sym)
                        self.mt5_pending_order_remove(sym)
                        print( _sprintf(" mt5_fx_scalper[%s]- !!!ERR!!! - buy position - modify pending counter sell order [%f] -> [%f]", state, priceSPOprev, priceSPO  ))
                        
                    return False, state
               
            else:
                state =   dt_start_str + "S03.04"
                self.mt5_pending_order_remove(sym)

                priceBPO = orders['order_pos_buy_price_max']
                priceSPO = round( (priceBPO-piddelta*point)    , digits )
                
                if priceSPO < orders['order_pos_buy_price0']:
                    self.mt5_pending_order_raw( sym, 
                                           (2*vol), 
                                           priceSPO, 
                                           self.mt5.ORDER_TYPE_SELL_STOP, 
                                           "SPO", 
                                           456)
                    print( _sprintf(" mt5_fx_scalper[%s] - NO - buy position  - check volume of counter pending sell stop order ERR [%f] != [%f] - create new order at [%f]", state, vol, orders['order_pos_buy_vol'], priceSPO ))
                else:
                    self.mt5_position_close(sym)
                    print( _sprintf(" mt5_fx_scalper[%s] - !!!ERR!!! NO - buy position  - check volume of counter pending sell stop order ERR [%f] != [%f] - create new order at [%f]", state, vol, orders['order_pos_buy_vol'], priceSPO ))

                return False, state
                
        #
        # END of mt5_fx_scalper state 3
        #   buy position
        #
        

        #
        # mt5_fx_scalper state 4
        #   sell position
        #
        if ( 1      == orders['order_pos_sell'] ) :

            if None == piddelta:
                piddelta = -1 * abs( self.offset )
        
            #
            # state 4 - sell position
            #  4.1 check volume of open position
            #
            if ( vol  != orders['order_pos_sell_vol'] ) :
                state =   dt_start_str + "S04.01"
                print( _sprintf(" mt5_fx_scalper[%s] - NO - sell position - volume check ERR [%f] != [%f]", state, vol, orders['order_pos_sell_vol'] ))
                self.mt5_position_close(sym)
                self.mt5_pending_order_remove(sym)
                return False, state

            #
            # state 4 - sell position
            #  4.2 check volume of counter pending buy stop order
            #
            if ( 2      == orders['total'] ) and \
               ( 1      == orders['order_pos_sell'] ) and \
               ( vol    == orders['order_pos_sell_vol'] ) and \
               ( 1      == orders['order_pend_buy'] ) and \
               ( (2*vol)== orders['order_pend_buy_vol'] ) :
               
                priceSPO = orders['order_pos_sell_price_min']
                priceBPO = orders['order_pend_buy_price']
                offsetSet = abs(int(round((priceSPO - priceBPO)/point,digits)))
                if piddelta == offsetSet:
                    state =  dt_start_str + "S04.02"
                    if None != tp_lvl:
                        self.mt5_position_sltp_follow2( sym, tp_lvl, 0 )
                    print( _sprintf(" mt5_fx_scalper[%s] - OK - sell position - check volume of counter pending buy stop order OK" , state ))
                    return True, state
                else:
                    state =   dt_start_str + "S04.03"
                    priceBPOprev = priceBPO
                    priceBPO = round( (priceSPO+piddelta*point)    , digits )
                    ret = self.mt5_pending_order_modify( sym, 
                                               priceBPO, 
                                               123)
                    
                    if True == ret:
                        print( _sprintf(" mt5_fx_scalper[%s]- OK - sell position - modify pending counter buy order [%f] -> [%f]", state, priceBPOprev, priceBPO ))
                    else:
                        self.mt5_position_close(sym)
                        self.mt5_pending_order_remove(sym)
                        print( _sprintf(" mt5_fx_scalper[%s]- !!!ERR!!! - sell position - modify pending counter buy order [%f] -> [%f]", state, priceBPOprev, priceSPO ))
                    
                    return False, state
               
            else:
                state =   dt_start_str + "S04.04"
                self.mt5_pending_order_remove(sym)
                
                priceSPO = orders['order_pos_sell_price_min']
                priceBPO = round( (priceSPO+piddelta*point)    , digits )
                
                if priceBPO > orders['order_pos_sell_price0']:
                    self.mt5_pending_order_raw( sym, 
                                            (2*vol), 
                                            priceBPO, 
                                            self.mt5.ORDER_TYPE_BUY_STOP, 
                                            "BPO", 
                                            123)
                    print( _sprintf(" mt5_fx_scalper[%s] - NO - sell position  - check volume of counter pending buy stop order ERR [%f] != [%f] - create new order at [%f]", state, vol, orders['order_pos_buy_vol'], priceBPO ))
                else:
                    self.mt5_position_close(sym)
                    print( _sprintf(" mt5_fx_scalper[%s] - !!!ERR!!! NO - sell position  - check volume of counter pending buy stop order ERR [%f] != [%f] - create new order at [%f]", state, vol, orders['order_pos_buy_vol'], priceBPO ))

                return False, state
                
        #
        # END of mt5_fx_scalper state 4
        #   sell position
        #
    
        #
        # error state - should never come here
        #
        state =   dt_start_str + "S05.01"
        self.mt5_position_close(sym)
        self.mt5_pending_order_remove(sym)
        print( _sprintf(" mt5_fx_scalper[%s] - ERROR STATE", state) )
        return False, state
        
    #  def mt5_fx_scalper(self, sym, vol, piddelta = None ):
    # =============================================================================
        

    # =============================================================================
    #  def mt5_test_functions(self, sym, vol):
    #     
    # =============================================================================
    def mt5_test_functions(self, sym, vol):
        
        #sym_info = self.mt5.symbol_info (sym) 
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        
        
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        if ( 0 < orders['total'] ) :
            self.mt5_pending_order_remove(sym)
            self.mt5_position_close(sym)
    
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        if ( 0 < orders['total'] ) :
            print ( " test_mt5_functions - cleanup initial failed " ) 
            print()
            # TODO raise error here
            return
        
        #
        # 01) create first pending order
        #   mt5_first_pending_order
        #
        offsetpar = int(25)
        self.mt5_pending_order_first(sym, vol, offsetpar)
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        
        # calculate offset, which is set in pending order
        priceBPO = round(orders['order_pend_buy_price'],  digits)
        priceSPO = round(orders['order_pend_sell_price'], digits)
        offsetSet = int(round((priceBPO - priceSPO)/point,digits))
        if (2*self.offset) == offsetSet:
            print( " test_mt5_functions - OK - mt5_first_pending_order - offset" )        
        else:
            print( _sprintf(" test_mt5_functions - ERROR - mt5_first_pending_order - self.offset [%d] != [%d]  [%f] [%f]", (2*self.offset), offsetSet, priceBPO, priceSPO ))
            
        if ( 2      == orders['total'] ) and \
           ( 1      == orders['order_pend_buy'] ) and \
           ( vol    == orders['order_pend_buy_vol'] ) and \
           ( 1      == orders['order_pend_sell'] ) and \
           ( vol    == orders['order_pend_sell_vol'] ) :
            print( " test_mt5_functions - OK - mt5_first_pending_order" )        
            print()
        else:
            print( " test_mt5_functions - ERROR - mt5_first_pending_order" ) 
            # TODO raise error here
            return
        

        #
        # 02) double the volume of the first pending order
        #
        
        self.mt5_pending_order_raw( sym, 
                                   vol, 
                                   priceBPO, 
                                   self.mt5.ORDER_TYPE_BUY_STOP, 
                                   "BPO", 
                                   123)

        self.mt5_pending_order_raw( sym, 
                                   vol, 
                                   priceSPO, 
                                   self.mt5.ORDER_TYPE_SELL_STOP, 
                                   "SPO", 
                                   456)
        

        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        
        # calculate self.offset, which is set in pending order
        priceBPO = orders['order_pend_buy_price']
        priceSPO = orders['order_pend_sell_price']
        offsetSet = int(round((priceBPO - priceSPO)/point,digits))
        if (2*self.offset) == offsetSet:
            print( " test_mt5_functions - OK - mt5_first_pending_order - offset" )        
        else:
            print( _sprintf(" test_mt5_functions - ERROR - mt5_first_pending_order - offset [%d] != [%d]  [%f] [%f]", (2*self.offset), offsetSet, priceBPO, priceSPO ))
            
        if ( 4      == orders['total'] ) and \
           ( 2      == orders['order_pend_buy'] ) and \
           ( vol    == orders['order_pend_buy_vol'] ) and \
           ( 2      == orders['order_pend_sell'] ) and \
           ( vol    == orders['order_pend_sell_vol'] ) :
            print( " test_mt5_functions - OK - mt5_first_pending_order" )        
            print()
        else:
            print( orders )
            print( " test_mt5_functions - ERROR - mt5_first_pending_order" ) 
            self.mt5_pending_order_remove(sym)
            # TODO raise error here
            return

        #
        # 03) modify pending order
        #
        priceBPO = round( (priceBPO+self.offset*point)    , digits )
        priceSPO = round( (priceSPO-self.offset*point)    , digits )
        # def mt5_pending_order_modify( self, sym, price, magic ):
        self.mt5_pending_order_modify( sym, 
                                   priceBPO, 
                                   123)
        
        self.mt5_pending_order_modify( sym, 
                                   priceSPO, 
                                   456)
        
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        if ( 4        == orders['total'] ) and \
           ( 2        == orders['order_pend_buy'] ) and \
           ( vol      == orders['order_pend_buy_vol'] ) and \
           ( priceBPO == orders['order_pend_buy_price'] ) and \
           ( 2        == orders['order_pend_sell'] ) and \
           ( vol      == orders['order_pend_sell_vol'] ) and \
           ( priceSPO == orders['order_pend_sell_price'] ) :
            print( " test_mt5_functions - OK - mt5_pending_order_modify" )        
            print()
        else:
            print( orders )
            print( " test_mt5_functions - ERROR - mt5_pending_order_modify" ) 
            self.mt5_pending_order_remove(sym)
            # TODO raise error here
            return

        
        
        self.mt5_pending_order_remove(sym)
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        if ( 0 < orders['total'] ) :
            print ( " test_mt5_functions - cleanup mt5_first_pending_order failed " ) 
            print()
            # TODO raise error here
            return
        
    #  def mt5_test_functions(self, sym, vol):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_sell_limit( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    #     
    # =============================================================================
    def mt5_pending_order_sell_limit( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================
    
        #self.offset = int(offsetpar)

        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            raise ValueError( "ERROR mt5_pending_order_sell_limit->self.mt5_init()")

          
        # prepare the request structure 
        sym_info = self.mt5.symbol_info (sym) 
        if None is sym_info: 
            raise ValueError( sym, " ERROR mt5_pending_order_sell_limit->not found, can not call order_check()")
          
        # if the sym is unavailable in MarketWatch, add it 
        if not sym_info.visible: 
            print(sym, "is not visible, trying to switch on") 
            if not self.mt5.symbol_select(sym,True): 
                raise ValueError( sym, " ERROR mt5_pending_order_sell_limit->symbol_select({}}) failed, exit")

        # calculate the price            
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        if None == price:
            if None !=  self.g_c0[sym] :
                price = self.g_c0[sym]
            else:
                price    = round( (bid + (ask - bid ) / 2), digits )
        
        for cnt in range(number):
            # range goes from 0,.., number-1
            # volumea = volume + cnt*volume
            # volumea = (number-cnt)*volume
            volumea = volume
            so = startoffset*point
            of = cnt*offsetpar*point
            priceSLO = round( (price+so+of), digits )
            expiration = int((datetime.now(timezone.utc) + self.tdOffset ).timestamp()) +300
            self.mt5_pending_order_raw( sym, 
                                        volumea, 
                                        priceSLO, 
                                        self.mt5.ORDER_TYPE_SELL_LIMIT, 
                                        "SLO", 
                                        465,
                                        expiration=expiration)
    
        
        ret = False
        return ret
            
    # END  def mt5_pending_order_sell_limit( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_buy_limit( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    #     
    # =============================================================================
    def mt5_pending_order_buy_limit( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================
    
        #self.offset = int(offsetpar)

        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            raise ValueError( "ERROR mt5_pending_order_buy_limit->self.mt5_init()")

          
        # prepare the request structure 
        sym_info = self.mt5.symbol_info (sym) 
        if None is sym_info: 
            raise ValueError( sym, " ERROR mt5_pending_order_buy_limit->not found, can not call order_check()")
          
        # if the sym is unavailable in MarketWatch, add it 
        if not sym_info.visible: 
            print(sym, "is not visible, trying to switch on") 
            if not self.mt5.symbol_select(sym,True): 
                raise ValueError( sym, " ERROR mt5_pending_order_buy_limit->symbol_select({}}) failed, exit")

        # calculate the price            
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        if None == price:
            if None !=  self.g_c0[sym] :
                price = self.g_c0[sym]
            else:
                price    = round( (bid + (ask - bid ) / 2), digits )
        
        for cnt in range(number):
            # range goes from 0,.., number-1
            # volumea = volume + cnt*volume
            # volumea = (number-cnt)*volume
            volumea = volume
            so = startoffset*point
            of = cnt*offsetpar*point
            priceBLO = round( (price-so-of), digits )
            expiration = int((datetime.now(timezone.utc) + self.tdOffset ).timestamp()) +300
            self.mt5_pending_order_raw( sym, 
                                        volumea, 
                                        priceBLO, 
                                        self.mt5.ORDER_TYPE_BUY_LIMIT, 
                                        "BLO", 
                                        132,
                                        expiration=expiration)
    
        
        ret = False
        return ret
            
    # END  def mt5_pending_order_buy_limit( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================



    # =============================================================================
    #  def mt5_pending_order_sell_stop( self, sym, volume = 0.01, number = 20, offsetpar = 20, price = None ):
    #     
    # =============================================================================
    def mt5_pending_order_sell_stop( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================
    
        #self.offset = int(offsetpar)

        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            raise ValueError( "ERROR mt5_pending_order_sell_stop->self.mt5_init()")

          
        # prepare the request structure 
        sym_info = self.mt5.symbol_info (sym) 
        if None is sym_info: 
            raise ValueError( sym, " ERROR mt5_pending_order_sell_stop->not found, can not call order_check()")
          
        # if the sym is unavailable in MarketWatch, add it 
        if not sym_info.visible: 
            print(sym, "is not visible, trying to switch on") 
            if not self.mt5.symbol_select(sym,True): 
                raise ValueError( sym, " ERROR mt5_pending_order_sell_stop->symbol_select({}}) failed, exit")

        # calculate the price            
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        if None == price:
            if None !=  self.g_c0[sym] :
                price = self.g_c0[sym]
            else:
                price    = round( (bid + (ask - bid ) / 2), digits )
        
        for cnt in range(number):
            # range goes from 0,.., number-1
            # volumea = volume + cnt*volume
            # volumea = (number-cnt)*volume
            volumea = volume
            so = startoffset*point
            of = cnt*offsetpar*point
            priceSLO = round( (price-so-of), digits )
            self.mt5_pending_order_raw( sym, 
                                        volumea, 
                                        priceSLO, 
                                        self.mt5.ORDER_TYPE_SELL_STOP, 
                                        "SLO", 
                                        456)
    
        
        ret = False
        return ret
            
    # END  def mt5_pending_order_sell_stop( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_buy_stop( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    #     
    # =============================================================================
    def mt5_pending_order_buy_stop( self, sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = None ):
    # =============================================================================
    
        #self.offset = int(offsetpar)

        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            raise ValueError( "ERROR mt5_pending_order_buy_stop->self.mt5_init()")

          
        # prepare the request structure 
        sym_info = self.mt5.symbol_info (sym) 
        if None is sym_info: 
            raise ValueError( sym, " ERROR mt5_pending_order_buy_stop->not found, can not call order_check()")
          
        # if the sym is unavailable in MarketWatch, add it 
        if not sym_info.visible: 
            print(sym, "is not visible, trying to switch on") 
            if not self.mt5.symbol_select(sym,True): 
                raise ValueError( sym, " ERROR mt5_pending_order_buy_stop->symbol_select({}}) failed, exit")

        # calculate the price            
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        if None == price:
            if None !=  self.g_c0[sym] :
                price = self.g_c0[sym]
            else:
                price    = round( (bid + (ask - bid ) / 2), digits )
        
        for cnt in range(number):
            # range goes from 0,.., number-1
            # volumea = volume + cnt*volume
            # volumea = (number-cnt)*volume
            volumea = volume
            so = startoffset*point
            of = cnt*offsetpar*point
            priceBLO = round( (price+so+of), digits )
            self.mt5_pending_order_raw( sym, 
                                        volumea, 
                                        priceBLO, 
                                        self.mt5.ORDER_TYPE_BUY_STOP, 
                                        "BLO", 
                                        123)
    
        
        ret = False
        return ret
            
    # END  def mt5_pending_order_buy_stop( self, sym, volume = 0.01, startoffset= 50, number = 20, offsetpar = 20, price = None ):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_first( self, sym, volume = 0.01, offsetpar = 20 ):
    #     
    # =============================================================================
    def mt5_pending_order_first( self, sym, volume = 0.01, offsetpar = 20 ):
    # =============================================================================
    
        self.offset = int(offsetpar)

        # check if connection to MetaTrader 5 successful
        if not self.mt5_init():
            # TODO raise error here
            return
          
        # prepare the request structure 
        sym_info = self.mt5.symbol_info (sym) 
        if None is sym_info: 
            print(sym, "not found, can not call order_check()") 
            # TODO raise error here
            return
          
        # if the sym is unavailable in MarketWatch, add it 
        if not sym_info.visible: 
            print(sym, "is not visible, trying to switch on") 
            if not self.mt5.symbol_select(sym,True): 
                print("symbol_select({}}) failed, exit",sym) 
                # TODO raise error here
                return

        # calculate the price            
        point    = self.mt5.symbol_info (sym).point
        digits   = self.mt5.symbol_info (sym).digits
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        price    = round( (bid + (ask - bid ) / 2), digits )
        priceBPO = round( (price+self.offset*point)    , digits )
        priceSPO = round( (price-self.offset*point)    , digits )
        
        
        self.mt5_pending_order_raw( sym, 
                                   volume, 
                                   priceBPO, 
                                   self.mt5.ORDER_TYPE_BUY_STOP, 
                                   # TODO for reverse pending offset start - make optional
                                   #self.mt5.ORDER_TYPE_SELL_LIMIT, 
                                   "BPO", 
                                   123)

        self.mt5_pending_order_raw( sym, 
                                   volume, 
                                   priceSPO, 
                                   self.mt5.ORDER_TYPE_SELL_STOP, 
                                   # TODO for reverse pending offset start - make optional
                                   #self.mt5.ORDER_TYPE_BUY_LIMIT, 
                                   "SPO", 
                                   456)
        
        ret = False
        # sanity check
        # 
        # at0.mt5_cnt_orders_and_positions( 'GBPJPY' )
        # Out[26]: 
        # {'total': 0,
        #  'order_pend_buy': 0,
        #  'order_pend_buy_vol': 0,
        #  'order_pend_buy_price': 0,
        #  'order_pend_sell': 0,
        #  'order_pend_sell_vol': 0,
        #  'order_pend_sell_price': 0,
        #  'order_pos_buy': 0,
        #  'order_pos_buy_vol': 0,
        #  'order_pos_buy_price_max': 0,
        #  'order_pos_sell': 0,
        #  'order_pos_sell_vol': 0,
        #  'order_pos_sell_price_min': 0}        
        orders, dfbs = self.mt5_cnt_orders_and_positions( sym )
        if ( 2        == orders['total'] ) and \
           ( 1        == orders['order_pend_buy'] ) and \
           ( volume   == orders['order_pend_buy_vol'] ) and \
           ( priceBPO == orders['order_pend_buy_price'] ) and \
           ( 1        == orders['order_pend_sell'] ) and \
           ( volume   == orders['order_pend_sell_vol'] ) and \
           ( priceSPO == orders['order_pend_sell_price'] ) :
            ret = True
        else:
            ret = False
            # TODO raise error here
            print("XXX ERROR mt5_pending_order_first")
            print( orders )
            print()
        
        return ret
            
    # END  def mt5_pending_order_first( self, sym, volume = 0.01, offsetpar = 20 ):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_remove( self, sym, order_type = None ):
    #     
    #   remove pending orders
    # =============================================================================
    def mt5_pending_order_remove( self, sym, order_type = None ):
    # =============================================================================

        # display data on active orders on GBPUSD 
        orders=self.mt5.orders_get(symbol=sym) 
        if orders is None: 
            print(" mt5_pending_order_remove error code={}".format(self.mt5.last_error())) 
            # TODO raise error here
            return
        
        ret = False
        for order in orders:
            if None != order_type:
                if order.type != order_type:
                    continue
            if (self.mt5.ORDER_TYPE_BUY_STOP   == order.type) or \
               (self.mt5.ORDER_TYPE_SELL_STOP  == order.type) or \
               (self.mt5.ORDER_TYPE_BUY_LIMIT  == order.type) or \
               (self.mt5.ORDER_TYPE_SELL_LIMIT == order.type) :
                request = {
                  "action":    self.mt5.TRADE_ACTION_REMOVE,
                  "symbol":    sym,
                  "order":     order.ticket,
                  "type_time": self.mt5.ORDER_TIME_GTC,
                  "expiration": 0,
                }
                
                result = self.mt5.order_check(request) 
                if 0 == result.retcode:
                    result = self.mt5.order_send(request) 
                    if (self.mt5.TRADE_RETCODE_DONE == result.retcode) or (self.mt5.TRADE_RETCODE_PLACED == result.retcode): 
                        ret = True
                    else:
                        ret = False
                        print( result )
                        # TODO raise error here
                        print ( "ERROR remove pending order " )
                else:
                    ret = False
                    # TODO raise error here
                    print ( "ERROR remove pending order " )

        return ret
    
    # def mt5_pending_order_remove( self, sym, order_type = None ):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_modify( self, sym, price, magic ):
    #     
    #   modify pending orders
    # =============================================================================
    def mt5_pending_order_modify( self, sym, price, magic ):
    # =============================================================================

        # display data on active orders on GBPUSD 
        orders=self.mt5.orders_get(symbol=sym) 
        if orders is None: 
            print("error code={}".format(self.mt5.last_error())) 
            print ( "ERROR modify pending order does not exists" )
            print()
            # TODO raise error here
            return
        
        ret = False
        for order in orders:
            if (magic == order.magic) :
                request = {
                  "action":       self.mt5.TRADE_ACTION_MODIFY,
                  "symbol":       sym,
                  "price":        price,
                  "order":        order.ticket,
                  "type":         order.type,
                  "type_time":    self.mt5.ORDER_TIME_SPECIFIED,
                  "type_filling": self.mt5.ORDER_FILLING_IOC,
                  "expiration"  : int((datetime.now(timezone.utc) + self.tdOffset ).timestamp()) +3600
                }
                
                result = self.mt5.order_check(request) 
                if 0 == result.retcode:
                    result = self.mt5.order_send(request) 
                    if (self.mt5.TRADE_RETCODE_DONE == result.retcode) or (self.mt5.TRADE_RETCODE_PLACED == result.retcode): 
                        ret = True
                    else:
                        ret = False
                        print( order) 
                        print( result )
                        print ( "ERROR modify pending order send" )
                        print()
                        # TODO raise error here
                else:
                    ret = False
                    print( order) 
                    print( result )
                    print ( "ERROR modify pending order check" )
                    print()
                    # TODO raise error here
                    
        return ret

    # def mt5_pending_order_modify( self, sym, price, magic ):
    # =============================================================================


    # =============================================================================
    #  def mt5_cnt_orders_and_positions( self, sym ):
    #     
    #   cnt orders
    # =============================================================================
    def mt5_cnt_orders_and_positions( self, sym ):
    # =============================================================================
        # display data on active orders on GBPUSD 
        orders=self.mt5.orders_get(symbol=sym) 
        if orders is None: 
            print("error code={}".format(self.mt5.last_error())) 
            return None

        positions=self.mt5.positions_get(symbol=sym)
        if positions is None: 
            print("error code={}".format(self.mt5.last_error())) 
            return None
        
        
        # mt5 settings    
        points = self.mt5.symbol_info (sym).point
        digits = self.mt5.symbol_info (sym).digits
        
        
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
            if 1 < self.gVerbose: print( order )
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
            if 1 < self.gVerbose: print( position )
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
        dtype = np.dtype([('cnt', '<i8'), ('profit', '<i8'), ('sl', '<i8'), ('tp', '<i8'), ('delta', '<i8'), ('price', '<f8'),\
                          ('time', '<i8'),('ticket', '<i8') ])
                          
        npa = np.zeros(key_list_len, dtype=dtype)
        df =  pd.DataFrame(npa, index=key_list)
        gc0 = 0
        if None != self.g_c0[sym] :
            gc0 = self.g_c0[sym]
            
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
            df.loc['POS_BUY', 'time']   = retdict['order_pos_buy_time']
            df.loc['POS_BUY', 'ticket'] = retdict['order_pos_buy_ticket']
        
        if 0 < retdict['order_pend_buy']:
            df.loc['PEND_BUY', 'cnt']    = retdict['order_pend_buy']
            df.loc['PEND_BUY', 'delta']  = int( ( retdict['order_pend_buy_price'] - gc0 ) / points )
            df.loc['PEND_BUY', 'price']  = retdict['order_pend_buy_price']
            df.loc['PEND_BUY', 'time']   = retdict['order_pend_buy_time_msc']
            df.loc['PEND_BUY', 'ticket'] = retdict['order_pend_buy_ticket']

        cnt = 0
        delta = 0
        price = 0
        time  = 0        
        ask      = self.mt5.symbol_info_tick(sym).ask
        bid      = self.mt5.symbol_info_tick(sym).bid
        if 0.0 < ask and 0.0 < bid :
            cnt = 1
            price    = int(round( (bid + (ask - bid ) / 2), digits ))
            delta    = int(( price - gc0 ) / points )
            time     = int(self.mt5.symbol_info_tick(sym).time_msc)
        df.loc['c0', 'cnt']    = cnt
        df.loc['c0', 'delta']  = delta
        df.loc['c0', 'price']  = price
        df.loc['c0', 'time']   = time
        
        if 0 < retdict['order_pend_sell']:
            df.loc['PEND_SELL','cnt']    = retdict['order_pend_sell']
            df.loc['PEND_SELL','delta']  = int(( retdict['order_pend_sell_price'] - gc0 ) / points )
            df.loc['PEND_SELL','price']  = retdict['order_pend_sell_price']
            df.loc['PEND_SELL','time']   = retdict['order_pend_sell_time_msc']
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
            df.loc['POS_SELL', 'time']   = retdict['order_pos_sell_time']
            df.loc['POS_SELL', 'ticket'] = retdict['order_pos_sell_ticket']

        
        
        # self.set_df('DB',sym,df)    
        # print( df )
        
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

    #  def mt5_cnt_orders_and_positions( self, sym ):
    # =============================================================================


    # =============================================================================
    #  def mt5_pending_order_raw(self, symbol, volume, price, order_type, comment, magic):
    #     
    #   pending raw order
    # =============================================================================
    def mt5_pending_order_raw(self, symbol, volume, price, order_type, comment, magic, expiration = None):
    # =============================================================================
    
        # prepare the the first BPO (buy pending order) request
        requestBPO = {
            "action": self.mt5.TRADE_ACTION_PENDING,
            "symbol": symbol,
            "volume": volume,
            "type": order_type,
            "price": price,
            "deviation": 0,
            "magic": magic,
            "comment": comment,
            "type_time": self.mt5.ORDER_TIME_DAY,
            "type_filling": self.mt5.ORDER_FILLING_IOC,
        } 
        
        if None != expiration:
            requestBPO = {
                "action": self.mt5.TRADE_ACTION_PENDING,
                "symbol": symbol,
                "volume": volume,
                "type": order_type,
                "price": price,
                "deviation": 0,
                "magic": magic,
                "comment": comment,
                "type_time": self.mt5.ORDER_TIME_SPECIFIED,
                "expiration": expiration,
                "type_filling": self.mt5.ORDER_FILLING_IOC,
            } 
        
          
        # perform the check and display the resultBPO 'as is' 
        resultBPO = self.mt5.order_check(requestBPO) 
        
        if None == resultBPO:
            print(" XXX1 ERROR PENDING ORDERCHECK FAILED ") 
            print("mt5_pending_order_raw() failed, error code =",self.mt5.last_error()) 
            print(requestBPO)
            print("")
            # TODO raise error here
            return

        # sanity check        
        if (0 != resultBPO.retcode) : 
            print(resultBPO);
            # request the result as a dictionary and display it element by element 
            result_dict=resultBPO._asdict() 
            for field in result_dict.keys(): 
                print("   {}={}".format(field,result_dict[field])) 
                # if this is a trading request structure, display it element by element as well 
                if field=="request": 
                    traderequest_dict=result_dict[field]._asdict() 
                    for tradereq_filed in traderequest_dict: 
                        print("       requestBPO: {}={}".format(tradereq_filed,traderequest_dict[tradereq_filed])) 
            print(" XXX2 ERROR PENDING ORDERCHECK FAILED ") 
            print("")
            # TODO raise error here
            return
       
        # create buy and sell pending orders now
        resultBPO = self.mt5.order_send(requestBPO)  
        
        # sanity check        
        if (self.mt5.TRADE_RETCODE_DONE != resultBPO.retcode): 
            print(resultBPO) 
            # request the result as a dictionary and display it element by element 
            result_dict=resultBPO._asdict() 
            for field in result_dict.keys(): 
                print("   {}={}".format(field,result_dict[field])) 
                # if this is a trading request structure, display it element by element as well 
                if field=="request": 
                    traderequest_dict=result_dict[field]._asdict() 
                    for tradereq_filed in traderequest_dict: 
                        print("       traderequest: {}={}".format(tradereq_filed,traderequest_dict[tradereq_filed]))         

            print(" XXX ERROR PENDING ORDERSEND FAILED ") 
            print("")

    #  def mt5_pending_order_raw(self, symbol, volume, price, order_type, comment, magic):
    # =============================================================================



    # =============================================================================
    #  def mt5_position_raw_order(self, order_type, symbol, volume, price, comment=None, ticket=None):
    #     
    #   internal order send
    # =============================================================================
    def mt5_position_raw_order(self, order_type, symbol, volume, price, sl_points=0, tp_points=0, comment=None, ticket=None):
    # =============================================================================

        point=self.mt5.symbol_info(symbol).point
        
        tp = 0
        sl = 0
        
        if 0 < tp_points:
            if self.mt5.ORDER_TYPE_SELL == order_type:
                tp = price - tp_points*point
            if self.mt5.ORDER_TYPE_BUY == order_type:
                tp = price + tp_points*point

        if 0 < sl_points:
            if self.mt5.ORDER_TYPE_SELL == order_type:
                sl = price + sl_points*point
            if self.mt5.ORDER_TYPE_BUY == order_type:
                sl = price - sl_points*point
        
        order = {
          "action":    self.mt5.TRADE_ACTION_DEAL,
          "symbol":    symbol,
          "volume":    volume,
          "type":      order_type,
          "price":     price,
          "deviation": 10,
        }
        if 0 != tp or 0 != sl:
            order = {
              "action":    self.mt5.TRADE_ACTION_DEAL,
              "symbol":    symbol,
              "volume":    volume,
              "type":      order_type,
              "price":     price,
              "tp":        tp,
              "sl":        sl,
              "deviation": 10,
            }
        if comment is not None:
            order["comment"] = comment
        if ticket is not None:
            order["position"] = ticket
            
        result = self.mt5.order_check(order) 
        if 0 == result.retcode:
            return self.mt5.order_send(order)
        else:
            print( result.retcode )
            print(" error code={}".format(self.mt5.last_error())) 
            print( result )
            print( "" )
            return result
    
    #  def mt5_position_raw_order(self, order_type, symbol, volume, price, comment=None, ticket=None):
    # =============================================================================
    

    # =============================================================================
    #  def mt5_position_raw_sltp(self, ticket, symbol, sl=0, tp=0, magic=0, comment=None):
    #     
    #   internal order send
    # =============================================================================
    def mt5_position_raw_sltp(self, ticket, symbol, sl, tp, magic=0, comment=None):
    # =============================================================================

        order = {}
        if 0 != sl and 0 != tp:        
            order = {
              "action":    self.mt5.TRADE_ACTION_SLTP,
              "position":  ticket,
              "symbol":    symbol,
              "sl":        sl,
              "tp":        tp,
              "magic":     magic,
            }
        elif 0 != sl:        
            order = {
              "action":    self.mt5.TRADE_ACTION_SLTP,
              "position":  ticket,
              "symbol":    symbol,
              "sl":        sl,
              "magic":     magic,
            }
        elif 0 != tp:        
            order = {
              "action":    self.mt5.TRADE_ACTION_SLTP,
              "position":  ticket,
              "symbol":    symbol,
              "tp":        tp,
              "magic":     magic,
            }
            
        if comment is not None:
            order["comment"] = comment
          
        result = self.mt5.order_check(order) 
        if 0 == result.retcode:
            return self.mt5.order_send(order)
        else:
            print( result.retcode )
            print(" error code={}".format(self.mt5.last_error())) 
            print( result )
            print( "" )
            return result
    
    #  def mt5_position_raw_sltp(self, ticket, symbol, sl=0, tp=0, magic=0, comment=None):


    # =============================================================================
    #  def mt5_position_sltp_follow2(self, symbol):
    #     
    #   sltp follow profit
    # =============================================================================
    def mt5_position_sltp_follow2(self, symbol, tpoffset = 0, sloffset = 20 ):
    # =============================================================================

        # generic variables
        tried = 0
        done = 0
        points = self.mt5.symbol_info (symbol).point
        digits = self.mt5.symbol_info (symbol).digits
        

        # sltp api access variables
        sl = 0
        tp = 0
        ticket = 0
        magic  = 0


        positions=self.mt5.positions_get(symbol=symbol)
        if positions is None: 
            print("error code={}".format(self.mt5.last_error())) 
            return None

        '''
        # TradePosition(ticket=189164460, time=1611745214, time_msc=1611745214598, 
        time_update=1611745214, time_update_msc=1611745214598, 
        type=1, magic=456, identifier=189164460, reason=3, 
        volume=0.01, price_open=142.506, sl=0.0, tp=0.0, price_current=142.513, 
        swap=0.0, profit=-0.07, symbol='GBPJPY', comment='BPO', external_id='')
        '''
        
        
        for position in positions:
        
            sl     = 0
            tp     = 0
            magic  = 0
            pos_sl = round( position.sl, digits )
            pos_tp = round( position.tp, digits )
            pos_price_current = round( position.price_current, digits )
            pos_price_open    = round( position.price_open,    digits )
                
            if self.mt5.ORDER_TYPE_BUY == position.type:
                profitp = (pos_price_current-pos_price_open)/points
                #if 0 < tpoffset and ( 10  < profitp ) :
                if 0 < tpoffset and 0 == pos_tp :
                    tp = pos_price_current + tpoffset*points
                # if 0 < sloffset:    
                #    sl = pos_price_open - sloffset*points
                
                if( 500 < profitp ):
                    sl = pos_price_open + 300*points
                elif( 250 < profitp ):
                    sl = pos_price_open + 200*points
                elif( 200 < profitp ):
                    sl = pos_price_open + 150*points
                elif( 150 < profitp ):
                    sl = pos_price_open + 100*points
                elif( 100 < profitp ):
                    sl = pos_price_open + 50*points
                elif( 50 < profitp ):
                    sl = pos_price_open + 30*points
                elif( 30 < profitp ):
                    sl = pos_price_open + 10*points
                elif( 20 < profitp ):
                    sl = pos_price_open + 5*points
                elif( 10  < profitp ):
                    sl = pos_price_open + 2 *points
                    
                if 0 < pos_sl and pos_sl > sl:
                    sl = pos_sl

            if self.mt5.ORDER_TYPE_SELL == position.type:
                profitp = (pos_price_open-pos_price_current)/points
                #if 0 < tpoffset and ( 10  < profitp ) :
                if 0 < tpoffset and 0 == pos_tp :
                    tp = pos_price_current - tpoffset*points
                # if 0 < sloffset:    
                #    sl = pos_price_open + sloffset*points
                
                if( 500 < profitp ):
                    sl = pos_price_open - 300*points
                elif( 250 < profitp ):
                    sl = pos_price_open - 200*points
                elif( 200 < profitp ):
                    sl = pos_price_open - 150*points
                elif( 150 < profitp ):
                    sl = pos_price_open - 100*points
                elif( 100 < profitp ):
                    sl = pos_price_open - 50*points
                elif( 50 < profitp ):
                    sl = pos_price_open - 30*points
                elif( 30 < profitp ):
                    sl = pos_price_open - 10*points
                elif( 20 < profitp ):
                    sl = pos_price_open - 5*points
                elif( 10  < profitp ):
                    sl = pos_price_open - 2 *points
                    
                if 0 < pos_sl and pos_sl < sl:
                    sl = pos_sl

            sl = round( sl, digits )
            tp = round( tp, digits )
            
            if (pos_sl != sl) or (pos_tp != tp):
                for tries in range(10):
                    info = self.mt5.symbol_info_tick(symbol)
                    if info is None:
                        return None
                    r = self.mt5_position_raw_sltp(position.ticket, symbol, sl, tp, magic )
                    # check results
                    if r is None:
                        return None
                    if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                        if r.retcode == self.mt5.TRADE_RETCODE_DONE:
                            done += 1
                        break
    
    #  def mt5_position_sltp_follow2(self, symbol):
    # =============================================================================    


    # =============================================================================
    #  def mt5_position_sltp_follow_hedge(self, symbol):
    #     
    #   sltp follow profit
    # =============================================================================
    def mt5_position_sltp_follow_hedge(self, symbol):
    # =============================================================================

        # generic variables
        tried = 0
        done = 0
        points = self.mt5.symbol_info (symbol).point
        

        # sltp api access variables
        sl = 0
        tp = 0
        ticket = 0
        magic  = 0


        positions=self.mt5.positions_get(symbol=symbol)
        if positions is None: 
            print("error code={}".format(self.mt5.last_error())) 
            return None

        '''
        # TradePosition(ticket=189164460, time=1611745214, time_msc=1611745214598, 
        time_update=1611745214, time_update_msc=1611745214598, 
        type=1, magic=456, identifier=189164460, reason=3, 
        volume=0.01, price_open=142.506, sl=0.0, tp=0.0, price_current=142.513, 
        swap=0.0, profit=-0.07, symbol='GBPJPY', comment='BPO', external_id='')
        '''
        
        sl = 0
        tp = 0
        magic = 0
        
        for position in positions:
            if 0 == position.tp:
            #if 0 < position.profit:
                if self.mt5.ORDER_TYPE_BUY == position.type:
                    tp = position.price_open + 100*points
                    sl = position.price_open - 100*points

                if self.mt5.ORDER_TYPE_SELL == position.type:
                    tp = position.price_open - 100*points
                    sl = position.price_open + 100*points
                    
                for tries in range(10):
                    info = self.mt5.symbol_info_tick(symbol)
                    if info is None:
                        return None
                    r = self.mt5_position_raw_sltp(position.ticket, symbol, sl, tp, magic )
                    # check results
                    if r is None:
                        return None
                    if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                        if r.retcode == self.mt5.TRADE_RETCODE_DONE:
                            done += 1
                        break
    
    #  def mt5_position_sltp_follow_hedge(self, symbol):
    # =============================================================================    

    
    # =============================================================================
    #  def mt5_position_sltp_follow(self, symbol, sltp_counter):
    #     
    #   sltp follow profit
    # =============================================================================
    def mt5_position_sltp_follow(self, symbol, sltp_counter, order_type):
    # =============================================================================

        # generic variables
        tried = 0
        done = 0
        points = self.mt5.symbol_info (symbol).point
        

        # sltp api access variables
        sl = 0
        tp = 0
        ticket = 0
        magic  = 0

        #if pos.type == self.mt5.ORDER_TYPE_BUY or pos.type == self.mt5.ORDER_TYPE_SELL:
        mt5_orders, dfbs = self.mt5_cnt_orders_and_positions(symbol)
        
        if self.mt5.ORDER_TYPE_BUY == order_type:
            if 0 < mt5_orders['order_pos_buy']:
                ticket = mt5_orders['order_pos_buy_ticket']
                # if 10 < mt5_orders['order_pos_buy_profit']:
                #     if sltp_counter < mt5_orders['order_pos_buy_profit']:
                #         sl = mt5_orders['order_pos_buy_price_max'] + sltp_counter*points
                
                # SL
                if sltp_counter < mt5_orders['order_pos_buy_profit']:
                    sl = mt5_orders['order_pos_buy_price_max'] + sltp_counter*points
                # TP
                if 0 == mt5_orders['order_pos_buy_tp'] and 0 < mt5_orders['order_pos_buy_profit']:
                    tp = mt5_orders['order_pos_buy_price_max'] + 10*points
                    tp = mt5_orders['order_pos_buy_price0'] + 50*points
                if 0.0 != sl or 0.0 != tp:
                    print( 'SLTP BUY', sltp_counter,  mt5_orders['order_pos_buy_price_max'], sl, tp )
            
            
        elif  self.mt5.ORDER_TYPE_SELL == order_type:
            if 0 < mt5_orders['order_pos_sell']:
                ticket = mt5_orders['order_pos_sell_ticket']
                # if 10 < mt5_orders['order_pos_sell_profit']:
                #     if sltp_counter < mt5_orders['order_pos_sell_profit']:
                #         sl = mt5_orders['order_pos_sell_price_min'] - sltp_counter*points
                
                # SL
                if sltp_counter < mt5_orders['order_pos_sell_profit']:
                    sl = mt5_orders['order_pos_sell_price_min'] - sltp_counter*points
                # TP
                if 0 == mt5_orders['order_pos_sell_tp'] and 0 < mt5_orders['order_pos_sell_profit']:
                    tp = mt5_orders['order_pos_sell_price_min'] - 10*points
                    tp = mt5_orders['order_pos_sell_price0'] - 50*points
                if 0.0 != sl or 0.0 != tp:
                    print( 'SLTP SELL', sltp_counter,  mt5_orders['order_pos_sell_price_min'], sl, tp )



        # do the actual sltp modify
        if 0.0 != sl or 0.0 != tp:
            positions = self.mt5.positions_get(ticket=ticket)
            for pos in positions:
                # process only simple buy, sell
                if pos.type == self.mt5.ORDER_TYPE_BUY or pos.type == self.mt5.ORDER_TYPE_SELL:
                    tried += 1
                    for tries in range(10):
                        info = self.mt5.symbol_info_tick(symbol)
                        if info is None:
                            return None
                        r = self.mt5_position_raw_sltp(ticket, symbol, sl, tp, magic )
                        # check results
                        if r is None:
                            return None
                        if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                            if r.retcode == self.mt5.TRADE_RETCODE_DONE:
                                done += 1
                            break
        
        if done > 0:
            if done == tried:
                return True
            else:
                return "Partially"
        return False
    
    #  def mt5_position_sltp_follow(self, symbol, sltp_counter):
    # =============================================================================    


    # =============================================================================
    #  def mt5_position_reverse(self, symbol, comment=None):
    #     
    #   Reverse a position
    # =============================================================================
    def mt5_position_reverse(self, symbol, comment=None):
    # =============================================================================

        positions = self.mt5.positions_get(symbol=symbol)
    
        tried = 0
        done = 0
    
        for pos in positions:
            # process only simple buy, sell
            if pos.type == self.mt5.ORDER_TYPE_BUY or pos.type == self.mt5.ORDER_TYPE_SELL:
                tried += 1
                for tries in range(10):
                    info = self.mt5.symbol_info_tick(symbol)
                    if info is None:
                        return None
                    if pos.type == self.mt5.ORDER_TYPE_BUY:
                        r = self.mt5_position_raw_order(self.mt5.ORDER_TYPE_SELL, symbol, (2*pos.volume), info.bid, 0, 0, comment, None)
                    else:
                        r = self.mt5_position_raw_order(self.mt5.ORDER_TYPE_BUY, symbol, (2*pos.volume), info.ask, 0, 0, comment, None)
                    # check results
                    print( r, (2*pos.volume) )
                    if r is None:
                        return None
                    if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                        if r.retcode == self.mt5.TRADE_RETCODE_DONE:
                            done += 1
                        break
        
        if done > 0:
            if done == tried:
                return True
            else:
                return "Partially"
        return False
    
    #  def mt5_position_reverse(self, symbol, comment=None):
    # =============================================================================

    
    # =============================================================================
    #  def mt5_position_close(self, symbol, *, comment=None, ticket=None):
    #     
    #   Close all specific orders
    # =============================================================================
    def mt5_position_close(self, symbol, *, comment=None, ticket=None):
    # =============================================================================

        if ticket is not None:
            positions = self.mt5.positions_get(ticket=ticket)
        else:
            positions = self.mt5.positions_get(symbol=symbol)
    
        tried = 0
        done = 0
    
        for pos in positions:
            # process only simple buy, sell
            if pos.type == self.mt5.ORDER_TYPE_BUY or pos.type == self.mt5.ORDER_TYPE_SELL:
                tried += 1
                for tries in range(10):
                    info = self.mt5.symbol_info_tick(symbol)
                    if info is None:
                        return None
                    if pos.type == self.mt5.ORDER_TYPE_BUY:
                        r = self.mt5_position_raw_order(self.mt5.ORDER_TYPE_SELL, symbol, pos.volume, info.bid, 0, 0, comment, pos.ticket)
                    else:
                        r = self.mt5_position_raw_order(self.mt5.ORDER_TYPE_BUY, symbol, pos.volume, info.ask, 0, 0, comment, pos.ticket)
                    # check results
                    if r is None:
                        return None
                    if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                        if r.retcode == self.mt5.TRADE_RETCODE_DONE:
                            done += 1
                        break
        
        if done > 0:
            if done == tried:
                return True
            else:
                return "Partially"
        return False
    
    #  def mt5_position_close(self, symbol, *, comment=None, ticket=None):
    # =============================================================================
    

    # =============================================================================
    #  def mt5_position_buy(self, symbol, volume, price=None, *, comment=None, ticket=None):
    #     
    #   Buy order                
    # =============================================================================
    def mt5_position_buy(self, symbol, volume, price=None, *, comment=None, ticket=None):
    # =============================================================================
    
        # with direct call
        if price is not None:
            return self.mt5_position_raw_order(self.mt5.ORDER_TYPE_BUY, symbol, volume, price, 0, 0, comment, ticket)
        # no price, we try several times with current price
        for tries in range(10):
            info = self.mt5.symbol_info_tick(symbol)
            if info is None:
                return None
            r = self.mt5_position_raw_order(self.mt5.ORDER_TYPE_BUY, symbol, volume, info.ask, 0, 0, comment, ticket)
            if r is None:
                return None
            if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                break
        return r

    #  def mt5_position_buy(self, symbol, volume, price=None, *, comment=None, ticket=None):
    # =============================================================================

    # =============================================================================
    #  def mt5_position_sell(self, symbol, volume, price=None, *, comment=None, ticket=None):
    #     
    #   Sell order
    # =============================================================================
    def mt5_position_sell(self, symbol, volume, price=None, *, comment=None, ticket=None):
    # =============================================================================
    
        # with direct call
        if price is not None:
            return self.mt5_position_raw_order(self.mt5.ORDER_TYPE_SELL, symbol, volume, price, 0, 0, comment, ticket)
        # no price, we try several times with current price
        for tries in range(10):
            info = self.mt5.symbol_info_tick(symbol)
            if info is None:
                return None
            r = self.mt5_position_raw_order(self.mt5.ORDER_TYPE_SELL, symbol, volume, info.bid, 0, 0, comment, ticket)
            if r is None:
                return None
            if r.retcode != self.mt5.TRADE_RETCODE_REQUOTE and r.retcode != self.mt5.TRADE_RETCODE_PRICE_OFF:
                break
        return r

    #  def mt5_position_sell(self, symbol, volume, price=None, *, comment=None, ticket=None):
    # =============================================================================



    # =============================================================================
    #  def assemble_ana_key( self, dt_from, mplus, minus, dfpcmax, mplus_change  ):
    #     
    # =============================================================================
    def assemble_ana_key( self, dt_from, mplus, minus, dfpcmax, mplus_change  ):
    # =============================================================================

        
        mplus_change_str = "n"
        if True == mplus_change:
            mplus_change_str = "x"
                
                
        mplus_str = "ERR"
        if 1 == mplus and -1 == minus:
            mplus_str = "p"
            
        if -1 == mplus and 1 == minus:
            mplus_str = "m"
        
        
        ana_key_str = _sprintf("ANA_%04d_%s_%s_%s_%s",\
                        dfpcmax,
                        mplus_str,\
                        mplus_change_str,\
                        self.gACCOUNT,\
                        dt_from.strftime("%Y%m%d_%H%M%S"),\
                        )
         
        #print( ana_key_str )
        
        return ana_key_str
        
    # def assemble_ana_key( self, dt_from, mplus, minus, dfpcmax, mplus_change  ):
    # =============================================================================


    # =============================================================================
    #  def run_symbol( self, dt_from = None ):
    #     
    # =============================================================================
    def run_symbol( self, dt_from = None ):
    # =============================================================================

        if None == dt_from:
            dt_from = datetime.now(timezone.utc) + self.tdOffset


        sumsum    = 0
        sumdiff   = 0
        sumopdiff = 0

        
        if( True == self.mplus_hedge ):
            ssumopdiff, ssumdiff, ssumsum    = self.run_symbol_single( dt_from, 1, -1 )
            ssumopdiff2, ssumdiff2, ssumsum2 = self.run_symbol_single( dt_from, -1, 1 )
        elif ( 1 == self.mplus and -1 == self.minus ):
            ssumopdiff, ssumdiff, ssumsum    = self.run_symbol_single( dt_from, 1, -1 )
            ssumopdiff2, ssumdiff2, ssumsum2 = 0,0,0#self.run_symbol_single( dt_from, -1, 1 )
        elif ( -1 == self.mplus and 1 == self.minus ):
            ssumopdiff, ssumdiff, ssumsum     = 0,0,0#self.run_symbol_single( dt_from, 1, -1 )
            ssumopdiff2, ssumdiff2, ssumsum2  = self.run_symbol_single( dt_from, -1, 1 )
      
            
        sumsum    = sumsum    + ssumsum    + ssumsum2
        sumdiff   = sumdiff   + ssumdiff   + ssumdiff2
        sumopdiff = sumopdiff + ssumopdiff + ssumopdiff2
        
        delta = (sumopdiff+sumsum)
        if 0 != sumsum:
            if 0 > self.deltabreakminus:
                if self.deltabreakminus > delta:
                    # TODO set this object inactive
                    #   for now just limit the dt_to time to when the break occured
                    self.dt_to  = dt_from
                    self.active = False
            
            if 0 < self.deltabreakplus:
                if self.deltabreakplus < delta:
                    # TODO set this object inactive
                    #   for now just limit the dt_to time to when the break occured
                    self.dt_to  = dt_from
                    self.active = False
                
        pstr = _sprintf("%s  %s  MPLUS %6d %6d %6d   MINUS %6d %6d %6d   DELTA %6d",\
                        dt_from.strftime("%Y%m%d %H:%M:%S"), self.gSymbol, \
                        ssumopdiff, ssumdiff, ssumsum, ssumopdiff2, ssumdiff2, ssumsum2,\
                        delta,\
                        )
            
        if None!= self.verbose and 1 == self.verbose:               
            print( pstr )
        self.atlog.info( pstr )
                
        return sumopdiff, sumdiff, sumsum

    # def run_symbol( self, dt_from = None ):
    # =============================================================================


    # =============================================================================
    #  def run_symbol( self, symbol, dt_from = None, mplus = None, minus = None  ):
    #     
    # =============================================================================
    def run_symbol_single( self, dt_from, mplus, minus ):
    # =============================================================================
        
    
        symbol = self.gSymbol
    
        ana_key_str = self.assemble_ana_key( self.dt_from, mplus, minus, self.dfpcmax, self.mplus_change )
    
        
        sumopdiff = 0
        sumdiff   = 0
        sumsum    = 0

        
        # check if connection to MetaTrader 5 successful
        if self.mt5_init():

            start = time.time()
            
            if None != self.dfpcmax and 0 < self.dfpcmax:
                
                dfpcm = 0
                dfpcmax = self.dfpcmax
                dfc0 = self.get_price( symbol, dt_from, 1 )

            else:
            
                self.gDt['dt_to']   = dt_from
                self.gDt['dt_from'] = dt_from - self.dt_step
                dfc0, dfpcmax, dfpcm = self.get_pcm_and_price(symbol)
                dfpcmax = 2*dfpcmax
                if 20 > dfpcmax:
                    dfpcmax = 20
                
            
            end = time.time()
            dt_from_str =   str(dt_from.strftime("%Y%m%d_%H%M%S"))  
            if self.gVerbose: print( _sprintf("%s TOTAL TIME [%.2gs]\n", dt_from_str, (end-start)  ))

        else:
            
            raise ValueError( "self.mt5_init() ")
            
        # if self.mt5_init()


        # points = self.mt5.symbol_info (symbol).point
        # digits = self.mt5.symbol_info (symbol).digits
        # gH.mt5.symbol_info ('BTCUSD').point
        # Out[179]: 0.01
        # gH.mt5.symbol_info ('BTCUSD').digits
        # Out[180]: 2
        # but transfer to 
        # points = 1
        # digits = 0        
        points = self.cf_symbols[self.gACCOUNT][symbol]['points']
        digits = self.cf_symbols[self.gACCOUNT][symbol]['digits'] 
        

        # get the previous/last entry dfana_prev
        dfana_prev = self.get_df( ana_key_str, symbol )
        len_dfana_prev = len( dfana_prev )
        if 0 < len_dfana_prev:
            dfana_prev = dfana_prev.iloc[(len_dfana_prev-1)]

        # calc the newest entry dfana
        dfana = {}
            
        # create numpy array with len 1
        dtype = np.dtype([
            ('c0', '<f8'), ('pcmax', '<i8'), ('pcm', '<f8'),\
            ('sigpcm', '<i8'), ('pos',  '<f8'), ('pop', '<f8'), ('pob',  '<f8'),\
            ('sigbs',  '<i8'), ('optp', '<f8'), ('opp', '<f8'), ('opsl', '<f8'),\
            ('opdiff', '<i8'), ('diff', '<i8'), ('sum', '<i8'),\
            ('mplus', '<i8'), ('minus', '<i8')\
        ])
        npa = np.zeros(1, dtype=dtype)
        
        npa[0]['c0']        = round( dfc0, digits)
        npa[0]['pcmax']     = dfpcmax
        npa[0]['pcm']       = dfpcm

        pfactp = 1
        pfacsl = 1


        # set mplus and minus
        if 0 < len_dfana_prev:
    
            npa[0]['mplus'] = dfana_prev['mplus']
            npa[0]['minus'] = dfana_prev['minus']
                
        else:
            # set default startup value for first time
            npa[0]['mplus'] = mplus
            npa[0]['minus'] = minus
            

        if 0 < len_dfana_prev:
    
            npa[0]['sigpcm']    = dfana_prev['sigpcm']
            npa[0]['pos']       = dfana_prev['pos']
            npa[0]['pop']       = dfana_prev['pop']
            npa[0]['pob']       = dfana_prev['pob']
                
        else:
            # TODO change pending order here
            npa[0]['sigpcm']    = 1
            npa[0]['pos']       = round( (dfc0 - (int(dfpcmax)*points*pfacsl)), digits )
            npa[0]['pop']       = round(  dfc0, digits )
            npa[0]['pob']       = round( (dfc0 + (int(dfpcmax)*points*pfacsl)), digits )


        commission = 4 #* points

        if 0 < len_dfana_prev:

            if   (0 == dfana_prev.sigbs) and (0 != npa[0]['sigpcm']) and (npa[0]['c0'] > npa[0]['pob']):
                # either take the current pcmax from current row # TODO make this optional later
                dfpcmax_start = dfpcmax
                # or take the pcmax from where the sigpcm changed starting point 
                dfpcmax_start = int( abs( npa[0]['pos'] - npa[0]['pop'] ) / points )
                npa[0]['sigbs']     = npa[0]['mplus']
                dfpcmax_start       = abs(self.deltabreakplus)
                npa[0]['optp']      = dfc0 + npa[0]['mplus']*dfpcmax_start*points*pfactp
                npa[0]['opp']       = dfc0
                dfpcmax_start       = abs(self.deltabreakminus)
                npa[0]['opsl']      = dfc0 + npa[0]['minus']*dfpcmax_start*points*pfacsl
                npa[0]['diff']      = 0
                npa[0]['sum']       = dfana_prev['sum']

            elif (0 == dfana_prev.sigbs) and (0 != npa[0]['sigpcm']) and (npa[0]['c0'] < npa[0]['pos']):
                # either take the current pcmax from current row # TODO make this optional later
                dfpcmax_start = dfpcmax
                # or take the pcmax from where the sigpcm changed starting point 
                dfpcmax_start = int( abs( npa[0]['pos'] - npa[0]['pop'] ) / points )
                npa[0]['sigbs']     = npa[0]['minus']
                dfpcmax_start       = abs(self.deltabreakplus)
                npa[0]['optp']      = dfc0 + npa[0]['minus']*dfpcmax_start*points*pfactp
                npa[0]['opp']       = dfc0
                dfpcmax_start       = abs(self.deltabreakminus)
                npa[0]['opsl']      = dfc0 + npa[0]['mplus']*dfpcmax_start*points*pfacsl
                npa[0]['diff']      = 0
                npa[0]['sum']       = dfana_prev['sum']

            # TP
            elif (1 == dfana_prev.sigbs) and (npa[0]['c0'] > dfana_prev['optp']):
                npa[0]['sigbs']     = 2
                npa[0]['optp']      = dfana_prev['optp']
                npa[0]['opp']       = dfana_prev['opp']
                npa[0]['opsl']      = dfana_prev['opsl']
                npa[0]['diff']      = (npa[0]['c0'] - dfana_prev['opp'])/points - commission
                npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                npa[0]['sigpcm']    = 0

            elif (-1 == dfana_prev.sigbs) and (npa[0]['c0'] < dfana_prev['optp']):
                npa[0]['sigbs']     = -2
                npa[0]['optp']      = dfana_prev['optp']
                npa[0]['opp']       = dfana_prev['opp']
                npa[0]['opsl']      = dfana_prev['opsl']
                npa[0]['diff']      = (dfana_prev['opp'] - npa[0]['c0'])/points - commission
                npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                npa[0]['sigpcm']    = 0

            # SL
            elif (1 == dfana_prev.sigbs) and (npa[0]['c0'] < dfana_prev['opsl']):
                npa[0]['sigbs']     = 3
                npa[0]['optp']      = dfana_prev['optp']
                npa[0]['opp']       = dfana_prev['opp']
                npa[0]['opsl']      = dfana_prev['opsl']
                npa[0]['diff']      = (npa[0]['c0'] - dfana_prev['opp'])/points - commission
                npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                npa[0]['sigpcm']    = 0

            elif (-1 == dfana_prev.sigbs) and (npa[0]['c0'] > dfana_prev['opsl']):
                npa[0]['sigbs']     = -3
                npa[0]['optp']      = dfana_prev['optp']
                npa[0]['opp']       = dfana_prev['opp']
                npa[0]['opsl']      = dfana_prev['opsl']
                npa[0]['diff']      = (dfana_prev['opp'] - npa[0]['c0'])/points - commission
                npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                npa[0]['sigpcm']    = 0

            # RESET
            elif (2 == dfana_prev.sigbs) or (3 == dfana_prev.sigbs) or (-2 == dfana_prev.sigbs) or (-3 == dfana_prev.sigbs):
                npa[0]['sigbs']     = 0
                npa[0]['optp']      = 0
                npa[0]['opp']       = 0
                npa[0]['opsl']      = 0
                npa[0]['diff']      = 0
                npa[0]['sum']       = dfana_prev['sum']

            # ELSE copy the previous
            else:
                npa[0]['sigbs']     = dfana_prev['sigbs']
                npa[0]['optp']      = dfana_prev['optp']
                npa[0]['opp']       = dfana_prev['opp']
                npa[0]['opsl']      = dfana_prev['opsl']
                npa[0]['diff']      = 0
                npa[0]['sum']       = dfana_prev['sum']

            if 1 == npa[0]['sigbs']:
                npa[0]['opdiff']    = (npa[0]['c0'] - npa[0]['opp'])/points
            if -1 == npa[0]['sigbs']:
                npa[0]['opdiff']    = (npa[0]['opp'] - npa[0]['c0'])/points

                
        # if 0 < len_dfana_prev:


        # TODO change pending order here
        if (2 == npa[0]['sigbs']) or (3 == npa[0]['sigbs']) or (-2 == npa[0]['sigbs']) or (-3 == npa[0]['sigbs']):
            npa[0]['sigpcm']    = 1
            npa[0]['pos']       = round( (dfc0 - (int(dfpcmax)*points*pfacsl)), digits )
            npa[0]['pop']       = round(  dfc0, digits )
            npa[0]['pob']       = round( (dfc0 + (int(dfpcmax)*points*pfacsl)), digits )
            # if sumdiff and sumsum negativ then turn around
            if True == self.mplus_change:
                if (0 > npa[0]['diff']) and (0 > npa[0]['sum']):
                    #print("change")
                    npa[0]['mplus'] = -1 * npa[0]['mplus']
                    npa[0]['minus'] = -1 * npa[0]['minus']


        dfana =  pd.DataFrame(npa)
        
        # convert to itself (column) from epoch to datetime string 
        # df['time']=pd.to_datetime(df['time'], unit='s')
        dfana.insert(0,"DT",pd.to_datetime(dt_from))
        #dfsum.reset_index(level=0, inplace=True)
        dfana.set_index(['DT'],drop=True,inplace=True)
        
        # write result for symbol only
        self.append_df( ana_key_str, symbol, dfana )
        #
        #
        #
        sumopdiff  = sumopdiff  + npa[0]['opdiff']
        sumdiff    = sumdiff    + npa[0]['diff']
        sumsum     = sumsum     + npa[0]['sum']
        
        
        
        
        anastr = _sprintf("%s  %s  %9.05f  %4d  %+1.01f %4d  %9.05f  %9.05f  %9.05f %4d  %9.05f  %9.05f  %9.05f %5d %5d %5d %2d/%2d",\
                        dt_from.strftime("%Y%m%d %H:%M:%S"),\
                        symbol,\
                        dfc0,\
                        dfpcmax,\
                        dfpcm,\
                        npa[0]['sigpcm'],\
                        npa[0]['pos'],\
                        npa[0]['pop'],\
                        npa[0]['pob'],\
                        npa[0]['sigbs'],\
                        npa[0]['optp'],\
                        npa[0]['opp'],\
                        npa[0]['opsl'],\
                        npa[0]['opdiff'],\
                        npa[0]['diff'],\
                        npa[0]['sum'],\
                        npa[0]['mplus'],\
                        npa[0]['minus'],\
                        )
         
        if None!= self.verbose and 2 == self.verbose:               
            print( anastr )
        self.atlog.info( anastr )


        return sumopdiff, sumdiff, sumsum
        
            
    # END  def run_symbol( self, symbol, dt_from = None, mplus = None, minus = None, dfpcmax = None, mplus_change = None, verbose = None, gdt_from = None  ):
    # =============================================================================

    # =============================================================================
    #  def calcSMA( symbol, dt_from = None ):
    #     
    # =============================================================================
    def calcSMA( self, dt_from = None ):
    # =============================================================================
    
        gNPA = []
        gSMA10 = []
        gSMA100 = []
        gSMA1000 = []
        
            
        #global gtd_offset, gdt_to, gdt_from, gH, gNPA, gSMA10, gSMA100, gSMA1000
        gtd_offset= timedelta(hours=2)
        
        if None == dt_from:
            gdt_to = datetime.now(timezone.utc) + gtd_offset
        else:
            gdt_to = dt_from
            
        gdt_from = gdt_to - timedelta( hours=1 )
        
        gNPA     = self.mt5.copy_ticks_range( self.gSymbol, gdt_from, gdt_to , self.mt5.COPY_TICKS_ALL)

        
        digits   = self.cf_symbols[self.gACCOUNT][self.gSymbol]['digits'] 
        gPrice   = (gNPA['bid'] + gNPA['ask'])/2
        gSMA10   = self.talib.SMA( gPrice, timeperiod=300)
        gSMA100  = self.talib.SMA( gPrice, timeperiod=600)
        gSMA1000 = self.talib.SMA( gPrice, timeperiod=900)
        
        
        up_dn_str = "  "
        
        lennpa = len(gNPA)-1
        if 0 < lennpa:
            
            ask     = round( gNPA['ask'][lennpa], digits )
            bid     = round( gNPA['bid'][lennpa], digits )
            c0      = round( gPrice[lennpa], digits )
            sma10   = round( gSMA10[lennpa], digits )
            sma100  = round( gSMA100[lennpa], digits )
            sma1000 = round( gSMA1000[lennpa], digits ) 
        
            if ( sma100 > sma1000 ):
                up_dn_str = "u "
                if ( c0 > sma10 ) and ( sma10 > sma100 )  and ( sma100 > sma1000 ):
                    up_dn_str = "up"
                    
            if ( sma100 < sma1000 ):
                up_dn_str = "d "
                if ( c0 < sma10 ) and ( sma10 < sma100 )  and ( sma100 < sma1000 ):
                    up_dn_str = "dn"
                

            if c0 > self.up_dn_str_high:
                self.up_dn_str_high = c0
            if c0 < self.up_dn_str_low:
                self.up_dn_str_low = c0
        
            if "up" == up_dn_str or "dn" == up_dn_str:
                
                if "up" == up_dn_str and "up" != self.up_dn_str_prev:
                    self.up_dn_str_prev = "up"
                    str_ = _sprintf( "%s %s  %10.5f %10.5f %10.5f %10.5f  (%s)  ask:%10.5f bid:%10.5f   H:%10.5f L:%10.5f", 
                                    gdt_to.strftime("%Y%m%d %H:%M:%S"), self.gSymbol,
                                    c0, sma10, sma100, sma1000,
                                    up_dn_str,
                                    ask, bid,
                                    self.up_dn_str_high,self.up_dn_str_low)
                    print (  str_ )
                    self.up_dn_str_high = 0
                    self.up_dn_str_low  = 1000

                if "dn" == up_dn_str and "dn" != self.up_dn_str_prev:
                    self.up_dn_str_prev = "dn"
                    str_ = _sprintf( "%s %s  %10.5f %10.5f %10.5f %10.5f  (%s)  ask:%10.5f bid:%10.5f   H:%10.5f L:%10.5f", 
                                    gdt_to.strftime("%Y%m%d %H:%M:%S"), self.gSymbol, 
                                    c0, sma10, sma100, sma1000,
                                    up_dn_str,
                                    ask, bid,
                                    self.up_dn_str_high,self.up_dn_str_low)
                    print (  str_ )
                    self.up_dn_str_high = 0
                    self.up_dn_str_low  = 1000
        
        return up_dn_str   

    # END def calcSMA( symbol, dt_from = None ):
    # =============================================================================


    # =============================================================================
    #  def run_all( self, dt_from = None, symbols = None, use_pid = False, use_scalp = False, perarr=None, time_to_sleep = 1, screen = None ):
    #     
    # =============================================================================
    def run_all( self, dt_from = None, symbols = None, use_pid = False, use_scalp = False, perarr=None, time_to_sleep = 0, screen = None ):
    # =============================================================================
        
        if None != screen:
            self.screen = screen
    
        if None == dt_from:
            dt_from = datetime.now(timezone.utc) + self.tdOffset

        if None == symbols:
            symbols = self.cf_symbols_default

        self.set_use_pid(use_pid)
        self.set_use_scalp(use_scalp)
        
        #print()
        #print()
        #print()
        
        if None != self.screen:
            self.screen.addstr( (self.screen_first_row+0), self.screen_first_col, str(dt_from))
            #self.screen.addstr( (self.screen_first_row+1), self.screen_first_col, cfsymbols)
            tmpstr1 = "symbol peridx  c0             pcmax     pcm  pidmax    pidm  piddelta   sum    cnt1     cnta  sumsc"
            #          GBPJPY ANA_01  147.51500         38    -0.1       7    -0.2      -8      -2       0       4      21    
            tmpstr2 = "---------------------------------------------------------------------------------------------------"
            self.screen.addstr( (self.screen_first_ana_row-1), self.screen_first_col, tmpstr1)
            self.screen.addstr( (self.screen_first_ana_row-0), self.screen_first_col, tmpstr2)
            self.screen.refresh()
        #print(dt_from)
        #print( cfsymbols )

        if None != self.screen:
            self.screen.refresh()

        if None != perarr:
            self.perarr = perarr

        lenperarr = len(self.perarr)
        cnt = 1
        for per in self.perarr:

            per_idx_str = '0' + str(cnt)
            #cffile = 'cf_periods_' + per_idx_str +'.json'
            #self.set_cf_periods(cffile)
            self.set_cf_periods(None, per_idx_str, per)
            if None != self.screen:
                tmpstr1 = 'ANA_' + per_idx_str + ':  ' + str(list( self.cf_periods[self.gACCOUNT]))
                self.screen.addstr( (self.screen_first_ana_row+len(symbols)+1+cnt), self.screen_first_col, tmpstr1)
            cnt = cnt + 1
        
        cntsymrow = 1
        sumopdiff = 0
        sumdiff   = 0
        sumsum    = 0
        cntsumpos = 0
        cntsumneg = 0
        avgpcmax  = 0
        avgpcm    = 0
        cntpob    = 0
        cntpos    = 0
        cntopb    = 0
        cntops    = 0 
 

        
        for sym in symbols:
            
            if True == self.gUseRates:
                #
                # run main function
                #
                self.run_now(dt_from, sym)
    
                # =============================================================================
                # '''        
                # dt_from
                # Out[56]: datetime.datetime(2021, 3, 11, 15, 54, 39, 550947, tzinfo=datetime.timezone.utc)
                # 
                # str(dt_from)
                # Out[57]: '2021-03-11 15:54:39.550947+00:00'
                # 
                # self.gDF['SUM_ANA']['GBPJPY'].loc[str(dt_from)]
                # Out[58]: 
                #                                   peridx  ... SUMCOLSC
                # DT                                        ...         
                # 2021-03-11 15:54:39.550947+00:00  ANA_01  ...       49
                # 2021-03-11 15:54:39.550947+00:00  ANA_02  ...       49
                # 2021-03-11 15:54:39.550947+00:00  ANA_03  ...       49
                # 2021-03-11 15:54:39.550947+00:00  ANA_04  ...       49
                # 2021-03-11 15:54:39.550947+00:00  ANA_05  ...       48
                # 2021-03-11 15:54:39.550947+00:00  ANA_06  ...       42
                # 2021-03-11 15:54:39.550947+00:00  ANA_07  ...       42
                # 2021-03-11 15:54:39.550947+00:00  ANA_08  ...       39
                # 2021-03-11 15:54:39.550947+00:00  ANA_09  ...       34
                # 2021-03-11 15:54:39.550947+00:00  ANA_10  ...       34
                # 2021-03-11 15:54:39.550947+00:00  ANA_11  ...       40
                # 2021-03-11 15:54:39.550947+00:00  ANA_12  ...       40
                # 
                # [12 rows x 12 columns]
                # 
                # df = self.gDF['SUM_ANA']['GBPJPY'].loc[str(dt_from)]        
                #        
                # print(df.dtypes)
                # peridx       object
                # per          object
                # c0          float64
                # pcmax         int64
                # pcm         float64
                # pidmax        int64
                # pidm        float64
                # piddelta      int64
                # SUMCOL        int64
                # CNTA          int64
                # CNT1          int64
                # SUMCOLSC      int64
                # dtype: object
                #     
                # len(df)
                # Out[75]: 12  
                #        
                # df.iloc[11]
                # Out[73]: 
                # peridx                         ANA_12
                # per         ['T610', 'T987', 'T1597']
                # c0                            151.643
                # pcmax                             164
                # pcm                               0.6
                # pidmax                             55
                # pidm                              0.4
                # piddelta                          160
                # SUMCOL                              2
                # CNTA                                1
                # CNT1                                6
                # SUMCOLSC                           40
                # Name: 2021-03-11 15:54:39.550947+00:00, dtype: object        
                #   
                # list(df.iloc[11])
                # Out[92]: 
                # ['ANA_12',
                #  "['T610', 'T987', 'T1597']",
                #  151.643,
                #  164,
                #  0.6,
                #  55,
                #  0.4,
                #  160,
                #  2,
                #  1,
                #  6,
                #  40]        
                #
                # df[['pcmax','pcm','pidmax','pidm','piddelta','SUMCOL','CNTA','CNT1','SUMCOLSC']].iloc[11]
                # Out[89]: 
                # pcmax       164.0
                # pcm           0.6
                # pidmax       55.0
                # pidm          0.4
                # piddelta    160.0
                # SUMCOL        2.0
                # CNTA          1.0
                # CNT1          6.0
                # SUMCOLSC     40.0
                # Name: 2021-03-11 15:54:39.550947+00:00, dtype: float64
                # #
                # list(df[['pcmax','pcm','pidmax','pidm','piddelta','SUMCOL','CNTA','CNT1','SUMCOLSC']].iloc[11])
                # Out[90]: [164.0, 0.6, 55.0, 0.4, 160.0, 2.0, 1.0, 6.0, 40.0]
                # #
                # =============================================================================
                
                df = self.gDF['SUM_ANA'][sym].loc[str(dt_from)]
                
                lendf = len(df)
                if 1 > lendf:
                    raise(ValueError( "SUM_ANA does not exists" ))
                
                pcmaxstr = ''
                for cnt in range( lendf ):
                    pcmaxstr = pcmaxstr + ' ' + _sprintf("%4d", df['pcmax'].iloc[cnt])
    
                pcmstr = ''
                for cnt in range( lendf ):
                    pcmstr = pcmstr + ' ' + _sprintf("%+1.01f", df['pcm'].iloc[cnt])
    
                # sumpos = df['pcm'].gt(0.9).sum()
                # sumneg = df['pcm'].lt(-0.9).sum()
                # anacnt = int(sumpos - sumneg)
    
                dfc0    = df['c0'].iloc[lendf-1]
                dfpcmax = df['pcmax'].sum()/len(df)
                dfpcm   = df['pcm'].sum()/len(df)

            else:
                
                # check if connection to MetaTrader 5 successful
                if self.mt5_init():

                    start = time.time()

                    self.gDt['dt_count'] = self.KDtCount
                    self.gDt['dt_to'] = dt_from
                    self.gDt['dt_from'] = self.gDt['dt_to']  - timedelta(seconds=(3600)) # seconds=max_seconds*self.gDt['dt_count']))
                    dfc0, dfpcmax, dfpcm = self.get_pcm_and_price(sym)
                    dfpcmax = 2*dfpcmax
                    if 30 > dfpcmax:
                        dfpcmax = 30
                    dfpcmax = 100

#                    dfpcm = 0
#                    dfpcmax = 100
#                    dfc0 = self.get_price( sym, dt_from, 1 )
                    
                    
                    end = time.time()
                    dt_from_str =   str(dt_from.strftime("%Y%m%d_%H%M%S"))  
                    if self.gVerbose: print( _sprintf("%s TOTAL TIME [%.2gs]\n", dt_from_str, (end-start)  ))

                else:
                    
                    raise ValueError( "self.mt5_init() ")
                    
                # if self.mt5_init()
                    
            # if True == self.gUseRates

            # anastr = _sprintf("%s  %s  %9.05f  %4d  %4d  %+1.01f\t%s\t%s",\
                            # dt_from.strftime("%H:%M:%S"),\
                            # sym,\
                            # dfc0,\
                            # anacnt,\
                            # dfpcmax,\
                            # dfpcm,\
                            # pcmaxstr,\
                            # pcmstr,\
                            # )
            # if None != self.screen:
                # self.screen.addstr( (self.screen_first_ana_row+cntsymrow), self.screen_first_col, anastr)
                # self.screen.refresh()
            # print( anastr )
            cntsymrow = cntsymrow + 1



            #
            #
            #
            points = self.cf_symbols[self.gACCOUNT][sym]['points']
            digits = self.cf_symbols[self.gACCOUNT][sym]['digits'] 

            # get the previous/last entry dfana_prev
            dfana_prev = self.get_df( 'ANA', sym )
            len_dfana_prev = len( dfana_prev )
            if 0 < len_dfana_prev:
                dfana_prev = dfana_prev.iloc[(len_dfana_prev-1)]

            # calc the newest entry dfana
            dfana = {}
                
            # create numpy array with len 1
            dtype = np.dtype([
                ('c0', '<f8'), ('pcmax', '<i8'), ('pcm', '<f8'),\
                ('sigpcm', '<i8'), ('pos',  '<f8'), ('pop', '<f8'), ('pob',  '<f8'),\
                ('sigbs',  '<i8'), ('optp', '<f8'), ('opp', '<f8'), ('opsl', '<f8'),\
                ('opdiff', '<i8'), ('diff', '<i8'), ('sum', '<i8')\
            ])
            npa = np.zeros(1, dtype=dtype)
            
            npa[0]['c0']        = round( dfc0, digits)
            npa[0]['pcmax']     = dfpcmax
            npa[0]['pcm']       = dfpcm

            pfactp = 0.5
            pfacsl = 2
            #pfactp = 1
            #pfacsl = 4
            pfactp = 1
            pfacsl = 1

#            if 0 < len_dfana_prev:
#            
#                if (0 < dfpcm) and (0 > dfana_prev.pcm):
#                    npa[0]['sigpcm']    = 1
#                    npa[0]['pos']       = round( (dfc0 - (int(dfpcmax)*points*pfacsl)), digits )
#                    npa[0]['pop']       = round(  dfc0, digits )
#                    npa[0]['pob']       = round( (dfc0 + (int(dfpcmax)*points*pfacsl)), digits )
#
#                elif (0 > dfpcm) and (0 < dfana_prev.pcm):
#                    npa[0]['sigpcm']    = -1
#                    npa[0]['pos']       = round( (dfc0 - (int(dfpcmax)*points*pfacsl)), digits )
#                    npa[0]['pop']       = round(  dfc0, digits )
#                    npa[0]['pob']       = round( (dfc0 + (int(dfpcmax)*points*pfacsl)), digits )
#
#                else:
#                    npa[0]['sigpcm']    = dfana_prev['sigpcm']
#                    npa[0]['pos']       = dfana_prev['pos']
#                    npa[0]['pop']       = dfana_prev['pop']
#                    npa[0]['pob']       = dfana_prev['pob']


            if 0 < len_dfana_prev:
        
                npa[0]['sigpcm']    = dfana_prev['sigpcm']
                npa[0]['pos']       = dfana_prev['pos']
                npa[0]['pop']       = dfana_prev['pop']
                npa[0]['pob']       = dfana_prev['pob']
                    
            else:
                # TODO change pending order here
                npa[0]['sigpcm']    = 1
                npa[0]['pos']       = round( (dfc0 - (int(dfpcmax)*points*pfacsl)), digits )
                npa[0]['pop']       = round(  dfc0, digits )
                npa[0]['pob']       = round( (dfc0 + (int(dfpcmax)*points*pfacsl)), digits )



            if 0 < len_dfana_prev:

                if   (0 == dfana_prev.sigbs) and (0 != npa[0]['sigpcm']) and (npa[0]['c0'] > npa[0]['pob']):
                    # either take the current pcmax from current row # TODO make this optional later
                    dfpcmax_start = dfpcmax
                    # or take the pcmax from where the sigpcm changed starting point 
                    dfpcmax_start = int( abs( npa[0]['pos'] - npa[0]['pop'] ) / points )
                    npa[0]['sigbs']     = self.mplus
                    npa[0]['optp']      = dfc0 + self.mplus*dfpcmax_start*points*pfactp
                    npa[0]['opp']       = dfc0
                    npa[0]['opsl']      = dfc0 + self.minus*dfpcmax_start*points*pfacsl
                    npa[0]['diff']      = 0
                    npa[0]['sum']       = dfana_prev['sum']

                elif (0 == dfana_prev.sigbs) and (0 != npa[0]['sigpcm']) and (npa[0]['c0'] < npa[0]['pos']):
                    # either take the current pcmax from current row # TODO make this optional later
                    dfpcmax_start = dfpcmax
                    # or take the pcmax from where the sigpcm changed starting point 
                    dfpcmax_start = int( abs( npa[0]['pos'] - npa[0]['pop'] ) / points )
                    npa[0]['sigbs']     = self.minus
                    npa[0]['optp']      = dfc0 + self.minus*dfpcmax_start*points*pfactp
                    npa[0]['opp']       = dfc0
                    npa[0]['opsl']      = dfc0 + self.mplus*dfpcmax_start*points*pfacsl
                    npa[0]['diff']      = 0
                    npa[0]['sum']       = dfana_prev['sum']

                # TP
                elif (1 == dfana_prev.sigbs) and (npa[0]['c0'] > dfana_prev['optp']):
                    npa[0]['sigbs']     = 2
                    npa[0]['optp']      = dfana_prev['optp']
                    npa[0]['opp']       = dfana_prev['opp']
                    npa[0]['opsl']      = dfana_prev['opsl']
                    npa[0]['diff']      = (npa[0]['c0'] - dfana_prev['opp'])/points
                    npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                    # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                    npa[0]['sigpcm']    = 0

                elif (-1 == dfana_prev.sigbs) and (npa[0]['c0'] < dfana_prev['optp']):
                    npa[0]['sigbs']     = -2
                    npa[0]['optp']      = dfana_prev['optp']
                    npa[0]['opp']       = dfana_prev['opp']
                    npa[0]['opsl']      = dfana_prev['opsl']
                    npa[0]['diff']      = (dfana_prev['opp'] - npa[0]['c0'])/points
                    npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                    # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                    npa[0]['sigpcm']    = 0

                # SL
                elif (1 == dfana_prev.sigbs) and (npa[0]['c0'] < dfana_prev['opsl']):
                    npa[0]['sigbs']     = 3
                    npa[0]['optp']      = dfana_prev['optp']
                    npa[0]['opp']       = dfana_prev['opp']
                    npa[0]['opsl']      = dfana_prev['opsl']
                    npa[0]['diff']      = (npa[0]['c0'] - dfana_prev['opp'])/points
                    npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                    # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                    npa[0]['sigpcm']    = 0

                elif (-1 == dfana_prev.sigbs) and (npa[0]['c0'] > dfana_prev['opsl']):
                    npa[0]['sigbs']     = -3
                    npa[0]['optp']      = dfana_prev['optp']
                    npa[0]['opp']       = dfana_prev['opp']
                    npa[0]['opsl']      = dfana_prev['opsl']
                    npa[0]['diff']      = (dfana_prev['opp'] - npa[0]['c0'])/points
                    npa[0]['sum']       = npa[0]['diff'] + dfana_prev['sum']
                    # reset sigpcm that there is only one sigbs per single sigpcm - todo make optional
                    npa[0]['sigpcm']    = 0

                # RESET
                elif (2 == dfana_prev.sigbs) or (3 == dfana_prev.sigbs) or (-2 == dfana_prev.sigbs) or (-3 == dfana_prev.sigbs):
                    npa[0]['sigbs']     = 0
                    npa[0]['optp']      = 0
                    npa[0]['opp']       = 0
                    npa[0]['opsl']      = 0
                    npa[0]['diff']      = 0
                    npa[0]['sum']       = dfana_prev['sum']

                # ELSE copy the previous
                else:
                    npa[0]['sigbs']     = dfana_prev['sigbs']
                    npa[0]['optp']      = dfana_prev['optp']
                    npa[0]['opp']       = dfana_prev['opp']
                    npa[0]['opsl']      = dfana_prev['opsl']
                    npa[0]['diff']      = 0
                    npa[0]['sum']       = dfana_prev['sum']

                if 1 == npa[0]['sigbs']:
                    npa[0]['opdiff']    = (npa[0]['c0'] - npa[0]['opp'])/points
                if -1 == npa[0]['sigbs']:
                    npa[0]['opdiff']    = (npa[0]['opp'] - npa[0]['c0'])/points

                    
            # if 0 < len_dfana_prev:


            # TODO change pending order here
            if (2 == npa[0]['sigbs']) or (3 == npa[0]['sigbs']) or (-2 == npa[0]['sigbs']) or (-3 == npa[0]['sigbs']):
                npa[0]['sigpcm']    = 1
                npa[0]['pos']       = round( (dfc0 - (int(dfpcmax)*points*pfacsl)), digits )
                npa[0]['pop']       = round(  dfc0, digits )
                npa[0]['pob']       = round( (dfc0 + (int(dfpcmax)*points*pfacsl)), digits )


            dfana =  pd.DataFrame(npa)
            
            # convert to itself (column) from epoch to datetime string 
            # df['time']=pd.to_datetime(df['time'], unit='s')
            dfana.insert(0,"DT",pd.to_datetime(dt_from))
            #dfsum.reset_index(level=0, inplace=True)
            dfana.set_index(['DT'],drop=True,inplace=True)
            
            # write result for symbol only
            self.append_df( 'ANA', sym, dfana )
            #
            #
            #
            sumopdiff  = sumopdiff  + npa[0]['opdiff']
            sumdiff    = sumdiff    + npa[0]['diff']
            sumsum     = sumsum     + npa[0]['sum']
            if( 1  < npa[0]['sum'] ) :
                cntsumpos  = cntsumpos  + 1
            if( -1 > npa[0]['sum'] ) :
                cntsumneg  = cntsumneg  + 1
            avgpcmax  = avgpcmax + dfpcmax
            avgpcm    = avgpcm   + dfpcm
            if  1 == npa[0]['sigpcm']: cntpob = cntpob + 1
            if -1 == npa[0]['sigpcm']: cntpos = cntpos + 1
            if  1 == npa[0]['sigbs']:  cntopb = cntopb + 1
            if -1 == npa[0]['sigbs']:  cntops = cntops + 1
            
            anastr = _sprintf("%s  %s  %9.05f  %4d  %+1.01f %4d  %9.05f  %9.05f  %9.05f %4d  %9.05f  %9.05f  %9.05f %5d %5d %5d",\
                            dt_from.strftime("%Y%m%d %H:%M:%S"),\
                            sym,\
                            dfc0,\
                            dfpcmax,\
                            dfpcm,\
                            npa[0]['sigpcm'],\
                            npa[0]['pos'],\
                            npa[0]['pop'],\
                            npa[0]['pob'],\
                            npa[0]['sigbs'],\
                            npa[0]['optp'],\
                            npa[0]['opp'],\
                            npa[0]['opsl'],\
                            npa[0]['opdiff'],\
                            npa[0]['diff'],\
                            npa[0]['sum'],\
                            )
            if None != self.screen:
                self.screen.addstr( (self.screen_first_ana_row+cntsymrow), self.screen_first_col, anastr)
                self.screen.refresh()
            print( anastr )
            self.atlog.info( anastr )

            # # x-values
            # x = np.arange(lendf)
            
            # # y values
            # pcmax       = list( df['pcmax'] )
            # pcm         = list( df['pcm'] )
            # pidmax      = list( df['pidmax'] )
            # pidm        = list( df['pidm'] )
            # piddelta    = list( df['piddelta'] )
            # SUMCOL      = list( df['SUMCOL'] )
            # CNTA        = list( df['CNTA'] )
            # CNT1        = list( df['CNT1'] )
            # SUMCOLSC    = list( df['SUMCOLSC'] )
            
            # pcmax_med, pcmax_m, pcmax_cnt           = self.calc_median_m_cnt( df, 'pcmax' )
            # pcm_med, pcm_m, pcm_cnt                 = self.calc_median_m_cnt( df, 'pcm' )
            # pidmax_med, pidmax_m, pidmax_cnt        = self.calc_median_m_cnt( df, 'pidmax' )
            # pidm_med, pidm_m, pidm_cnt              = self.calc_median_m_cnt( df, 'pidm' )
            # piddelta_med, piddelta_m, piddelta_cnt  = self.calc_median_m_cnt( df, 'piddelta' )
            # SUMCOL_med, SUMCOL_m, SUMCOL_cnt        = self.calc_median_m_cnt( df, 'SUMCOL' )
            # CNTA_med, CNTA_m, CNTA_cnt              = self.calc_median_m_cnt( df, 'CNTA' )
            # CNT1_med, CNT1_m, CNT1_cnt              = self.calc_median_m_cnt( df, 'CNT1' )
            # SUMCOLSC_med, SUMCOLSC_m, SUMCOLSC_cnt  = self.calc_median_m_cnt( df, 'SUMCOLSC' )

        # for sym in symbols:
        
        
        lensym = len(symbols)
        avgpcmax  = avgpcmax / lensym
        avgpcm    = avgpcm   / lensym
        
        #anastr = _sprintf("%s  %s  %9.05f  %4d  %+1.01f %4d  %9.05f  %9.05f  %9.05f %4d  %9.05f  %9.05f  %9.05f %5d %5d %5d",\
                  #  08:00:00  USDJPY  109.37200    27  +0.3    0    0.00000    0.00000    0.00000    0    0.00000    0.00000    0.00000     0     0     0
                  #  08:00:00  SUM                                                                                                    0     0     0
#        anastr = _sprintf("%s  SUM(%2d)            %4d  %+1.01f %4d /%4d                            %4d /%4d                            %5d %5d %5d",\
#                        dt_from.strftime("%Y%m%d %H:%M:%S"),\
#                        lensym,\
#                        avgpcmax,\
#                        avgpcm,\
#                        cntpob,\
#                        cntpos,\
#                        cntopb,\
#                        cntops,\
#                        sumopdiff,\
#                        sumdiff,\
#                        sumsum,\
#                        )

        fuzzy_out = 0.0
        try:
            x1 = self.fuzzy_sim.input['x1'] = cntpob - cntpos
            x2 = self.fuzzy_sim.input['x2'] = cntsumpos - cntsumneg
            x3 = self.fuzzy_sim.input['x3'] = sumsum
            self.fuzzy_sim.compute()
            fuzzy_out = self.fuzzy_sim.output['y1']
            if 0.0 == self.fuzzy_prev:
                self.fuzzy_prev = -1
                
#            if ( -0.5 > fuzzy_out ) and ( 0.5 < self.fuzzy_prev):
#                self.fuzzy_prev = fuzzy_out
#                self.mplus = -1*self.mplus
#                self.minus = -1*self.minus
#                print( self.mplus, self.minus )
#    
#            if ( 0.5 < fuzzy_out ) and ( -0.5 > self.fuzzy_prev):
#                self.fuzzy_prev = fuzzy_out
#                self.mplus = -1*self.mplus
#                self.minus = -1*self.minus
#                print( self.mplus, self.minus )
            
        except Exception:
            print("fuzzy exception in user code:")
            print( _sprintf("    params: x1 %4d x2 %4d x3 %4d y1 %+1.02f", x1, x2, x3, fuzzy_out ) )
            print("-"*60)
            traceback.print_exc(file=sys.stdout)
            print("-"*60)
            fuzzy_out = -42
        
        except:
            print( "fuzzy exception: ", sys.exc_info())
            fuzzy_out = -42
            
        


        # anastr = _sprintf("%s  SUM(%2d)            %4d  %+1.01f %4d /%4d                            %4d /%4d      %4d /%4d   %4d /%4d    %5d %5d %5d  %+1.02f",\
        anastr = _sprintf("%s  SUM(%2d)            %4d  %+1.01f %4d /%4d                            %4d /%4d      %4d /%4d            %5d %5d %5d  %+1.02f",\
                        dt_from.strftime("%Y%m%d %H:%M:%S"),\
                        lensym,\
                        avgpcmax,\
                        avgpcm,\
                        cntpob,\
                        cntpos,\
                        cntopb,\
                        cntops,\
                        cntsumpos,\
                        cntsumneg,\
                        # self.mplus,\
                        # self.minus,\
                        sumopdiff,\
                        sumdiff,\
                        sumsum,\
                        fuzzy_out,\
                        )
                        
#        if None != self.screen:
#            self.screen.addstr( (self.screen_first_ana_row+cntsymrow), self.screen_first_col, anastr)
#            self.screen.refresh()
#        print( anastr )
#        self.atlog.info( anastr )
#        print( "----------------------------------------------------------------------------------------------------------------------------------------------" )
#        self.atlog.info( "----------------------------------------------------------------------------------------------------------------------------------------------" )
        

        if None != self.screen:
            self.screen.addstr( (self.screen_first_row+0), self.screen_first_col, str(dt_from))
            #self.screen.addstr( (self.screen_first_row+1), self.screen_first_col, cfsymbols)
            tmpstr1 = "symbol peridx  c0             pcmax     pcm  pidmax    pidm  piddelta   sum    cnt1     cnta  sumsc"
            #          GBPJPY ANA_01  147.51500         38    -0.1       7    -0.2      -8      -2       0       4      21    
            tmpstr2 = "---------------------------------------------------------------------------------------------------"
            self.screen.addstr( (self.screen_first_ana_row-1), self.screen_first_col, tmpstr1)
            self.screen.addstr( (self.screen_first_ana_row-0), self.screen_first_col, tmpstr2)
            self.screen.refresh()

        
        if 0 < time_to_sleep:
            time.sleep( time_to_sleep )

        if None != self.screen:
            self.screen = None
            
        # if 1000 < (sumsum + sumopdiff):
        #     print( _sprintf("!!! DONE !!! sumsum [%d] < 1000 ", (sumsum + sumopdiff)) )
            

            
    # END  def run_all( self, dt_from = None, symbols = None, use_pid = False, use_scalp = False, perarr=None, time_to_sleep = 1, screen = None ):
    # =============================================================================


    # =============================================================================
    #  def pickle_dump( self ):
    #     
    # =============================================================================
    def pickle_dump( self ):
    # =============================================================================

        import pickle
        pickle_file =  self.dt_start_str + '.pickle'
        with open(pickle_file, 'wb') as f: pickle.dump(self.gDF, f)
        print( 'Pickle dumped gH.gDF (self.gDF) to: ' + pickle_file )
        

    # END def pickle_dump( self ):
    # =============================================================================
    
    
    # =============================================================================
    #  def calc_median_m_cnt( self, df, key ):
    #     
    # =============================================================================
    def calc_median_m_cnt( self, df, key ):
    # =============================================================================
        
        median = 0
        m      = 0
        cnt    = 0

        # x-values
        x = np.arange(len(df))

        m = np.polyfit(x,list( df[key] ),1)[0]
        m = float("%.1f" % m)

        #median = df[key].median()
        #median = float("%.1f" % median)

        median = df[key].sum()/len(df)
        median = float("%.1f" % median)

        
        sumpos = df[key].gt(0).sum()
        sumneg = df[key].lt(0).sum()
        cnt = int(sumpos - sumneg)
        
        return median, m, cnt
        
    # END  def calc_median_m_cnt( self, df, key ):
    # =============================================================================


    # =============================================================================
    #      def calc_kalman_predictions( self, par_real_track ):
    #
    # =============================================================================
    def calc_kalman_predictions( self, par_real_track ):
    # =============================================================================
    
        # create KalmanFilter object
        dt       = self.gKalmanDt
        u        = self.gKalmanU
        std_acc  = self.gKalmanStdDevAcc # we assume that the standard deviation of the acceleration is 0.25 (m/s^2)
        std_meas = self.gKalmanStdDevMeas  # and standard deviation of the measurement is 1.2 (m)
        kf       = KalmanFilter(dt, u, std_acc, std_meas)
    
        #t = np.arange(0, 100, dt)
        ## Define a model track
        #par_real_track = 0.1*((t**2) - t)
        
        predictions = []
        for x in par_real_track:
            z = kf.H * x
            predictions.append(kf.predict()[0])
            kf.update(z.item(0))
        # for x in par_real_track:
        
        return predictions

    # END def calc_kalman_predictions( self, par_real_track ):
    # =============================================================================


    # =============================================================================
    #  def run_analyse( self, dt_from = None, sym = None ):
    #     
    # =============================================================================
    def run_analyse_kalman( self, dt_from = None, sym = None ):
    # =============================================================================
    
        # usage:
        # import sys
        # import algotrader as at
        # at0 = at.Algotrader()
        # at0.run_now()
        # at0.run_now(datetime(2021,1,15,17, tzinfo=timezone.utc))
        
        if None == dt_from:
            dt_from = datetime.now(timezone.utc) + self.tdOffset

        if None == sym:
            sym = self.cf_symbols_default
            
        # check if connection to MetaTrader 5 successful
        ret = None
        if not self.mt5_init():
            return None

        
        self.get_date_range(dt_from)
        # dt_from0 start of the day
        dt_from0 = self.gDt['dt_from']
        self.gDt['dt_from'] = self.gDt['dt_to']  - timedelta(seconds=self.gKalmanChartIntervalInSeconds)
        dt_from = self.gDt['dt_from']
        dt_to = self.gDt['dt_to']
        
        points = self.mt5.symbol_info (sym).point
        digits = self.mt5.symbol_info (sym).digits


        """
         pre proc and get the ticks / rates
        """
        
        gNpaPrice0   = None
        gNpaPrice    = None
        gNpaPriceAsk = None
        gNpaPriceBid = None
        gNPA         = None
        gRealSpread  = None
        gNPAoffset   = None
        gRealTrack   = None
        
        if True == self.gUseRates:
            gNPA = self.mt5.copy_rates_from_pos(sym,self.mt5.TIMEFRAME_M1, 0, self.gDt['dt_count'])
            gNpaPriceAsk = gNPA['close']
            gNpaPriceBid = gNPA['close']
            gNpaPrice    = gNPA['close']
            gRealSpread  = (gNpaPriceAsk - gNpaPriceBid)/points
            
        else:
        
            gNPA = self.mt5.copy_ticks_range(sym,dt_from, dt_to , self.mt5.COPY_TICKS_ALL)
            gNpaPriceAsk = gNPA['ask']
            gNpaPriceBid = gNPA['bid']
            gNpaPrice    = (gNpaPriceAsk + gNpaPriceBid)/2
            gRealSpread  = (gNpaPriceAsk - gNpaPriceBid)/points
            
        # if True == self.gUseRates:
        
        """
         do the kalman
        """
        
        #self.gNpa = gNPA
        #gNPAoffset = gNpaPrice[len(gNPA)-1] * np.ones(len(gNPA))
        # if None == gNpaPrice0[sym]:
        #     gNpaPrice0[sym] = gNpaPrice[0]
        # TODO do not remember the first ever price
        gNpaPrice0 = gNpaPrice[0]
            
        gNPAoffset = gNpaPrice0 * np.ones(len(gNPA))
        #t = np.arange(0, len(gNPA), 1)
        gRealTrack = (gNpaPrice - gNPAoffset)/points
        #gRealTrack = gNpaPrice

        # take algo system settings here        
        self.gKalmanDt         = 0.01
        self.gKalmanU          = 2
        self.gKalmanStdDevAcc  = 25
        self.gKalmanStdDevMeas = 1.2
        self.gKalmanChartIntervalInSeconds = 60
        gPredictions = self.calc_kalman_predictions(gRealTrack)

        self.gKalmanDt         = 0.1
        self.gKalmanU          = 2
        self.gKalmanStdDevAcc  = 2.5
        self.gKalmanStdDevMeas = 1.2
        self.gKalmanChartIntervalInSeconds = 60
        gPredictions1 = self.calc_kalman_predictions(gRealTrack)
        
        print( 'preds:  ', int(gPredictions1[-1]), int(gPredictions[-1]) )


        #"""
        # post proc
        #"""
        
        '''
        t0 = 0
        c0 = 0.0
        tnpa = self.mt5.copy_rates_from_pos(sym,self.mt5.TIMEFRAME_M1, 0, 1)
        if 0 < len(tnpa):
            t0 = tnpa['time'][0]
            c0 = tnpa['close'][0]
            #print( t0, c0, tnpa)
        price = round( (gNpaPriceAsk[-1] + gNpaPriceBid[-1]) / 2, 5 )

        tarr = np.squeeze(gPredictions)
        tarr = np.around( tarr )
        tarr1 = np.squeeze(gPredictions1)
        tarr1 = np.around( tarr1 )
        lent = 5
        x = np.arange(lent)
        y = tarr[-lent:]
        pcm = round(np.polyfit(x,y,1)[0],1)
        
        
        # 1 account info
        account_info=self.mt5.account_info()._asdict()
        
        # 2 deals of the day
        sum1 = 0.0
        deals=self.mt5.history_deals_get(dt_from0, dt_to, group=sym) 
        if len(deals)> 0:
            for cnt in range(0,len(deals)): 
                sum1 = sum1 +  deals[cnt][11]
            for cnt in range(0,len(deals)): 
                sum1 = sum1 +  deals[cnt][13]

                     
        # 3  num of pending orders   
        op, df = self.mt5_cnt_orders_and_positions( sym )                
        numpb = op['order_pend_buy']
        numps = op['order_pend_sell'] 

        # 4 vol of positions
        volb = op['order_pos_buy_vol']
        vols = op['order_pos_sell_vol'] 
        volstr = " 0.00"
        if 0.0 == vols and 0.0 < volb:
            volstr = _sprintf( "B%3.2f", volb)
        if 0.0 < vols and 0.0 == volb:
            volstr = _sprintf( "S%3.2f", vols)
        
        tstr = _sprintf(" %s  %s %0.5f %+0.1f  %s %+6.1f  %+6.1f  %+6.1f  %+6.1f   B%3d  S%3d", 
                        self.gACCOUNT, dt_to.strftime("%Y.%m.%d %H:%M:%S"),
                        price, pcm, volstr,
                        account_info['profit'], sum1, account_info['balance'], account_info['equity'],
                        numpb, numps
                        )
        #print( tstr )
        if 0 < self.verbose:
            print( tstr, tarr[-lent:], t0, c0  )
            self.atlogkalman.info(tstr)
        '''    
            
        # '''    
        # c0 = df.iloc[lendf-1].close
        # Pc0 =  int(df.iloc[lendf-1].Pclose - (c0-self.g_c0[sym]) / self.cf_symbols[self.gACCOUNT][sym]['points'])
        # #print( Pc0, df.iloc[0].close, c0, self.g_c0[sym] )
        # Pc0B  = None # Pc0 + 20
        # Pc0B1 = None # Pc0 + 10
        # Pc0S  = None # Pc0 - 10
        # Pc0S1 = None # Pc0 - 20
        
        # op, dfbs = self.mt5_cnt_orders_and_positions( sym )
        # # print( dfbs )
        
        # if 0 < dfbs.loc['POS_BUY', 'cnt'] and 0 == dfbs.loc['PEND_BUY', 'cnt']:
        #     Pc0B  = +1 * dfbs.loc['POS_BUY', 'delta']
        #     Pc0B1 = +2 * dfbs.loc['POS_BUY', 'delta']

        # if 0 == dfbs.loc['POS_BUY', 'cnt'] and 0 < dfbs.loc['PEND_BUY', 'cnt']:
        #     Pc0B  = +1 * dfbs.loc['PEND_BUY', 'delta']

        # if 0 < dfbs.loc['POS_SELL', 'cnt'] and 0 == dfbs.loc['PEND_SELL', 'cnt']:
        #     Pc0S  = +1 * dfbs.loc['POS_SELL', 'delta']
        #     Pc0S1 = +2 * dfbs.loc['POS_SELL', 'delta']

        # if 0 == dfbs.loc['POS_SELL', 'cnt'] and 0 < dfbs.loc['PEND_SELL', 'cnt']:
        #     Pc0S  = +1 * dfbs.loc['PEND_SELL', 'delta']


        #     df['Pc0'] = Pc0
        #     key1 = 'Pc0'
        #     _mpf_plot(df,type='line',ax=ax0,axtitle=filename,columns=[key1,key1,key1,key1,'tick_volume'],style="sas",update_width_config=dict(ohlc_linewidth=3),show_nontrading=self.gShowNonTrading)
        # '''    
            
        #
        # graphical proc-
        #

        '''
        ret = price, pcm, tstr
        import matplotlib.pyplot as plt
        import talib

        fig = plt.figure()
        gFontSize         = 10        
        gTitleStr = _sprintf("%s( %d - %s %s - dt:%0.2f/%d/%0.2f/%0.2f )",\
          self.gACCOUNT, len(gNPA), sym, dt_from.strftime("%Y.%m.%d %H:%M:%S"), self.gKalmanDt, self.gKalmanU, self.gKalmanStdDevAcc, self.gKalmanStdDevMeas )
        gLabelXstr        = "timeseries (n*dt)"
        gLabelYstr        = "out (digits)"            
        fig.suptitle(gTitleStr, fontsize=gFontSize)

        # if (33 + 10) < lencmp:
        #     upper, mid, lower = talib.BBANDS(np.squeeze(gRealTrack), 
	       #                       nbdevup=1, nbdevdn=1, timeperiod=33)
        #     for cnt in range(0,33,1):
	       #           mid[cnt] = 0
        #     plt.plot(upper, label="Upper band", linewidth=0.3)
        #     plt.plot(mid,   label='Middle band',linewidth=0.3)
        #     plt.plot(lower, label='Lower band', linewidth=0.3)
        
        self.gNpa = gRealTrack
        t = np.arange(0, len(gRealTrack), 1)
        plt.plot(t, tarr,  label='Predict1', color='b', linewidth=0.5)
        plt.plot(t, tarr1, label='Predict2', color='g', linewidth=0.5)
        linreg60 = talib.LINEARREG(np.squeeze(gRealTrack), 60)
        linreg120 = talib.LINEARREG(np.squeeze(gRealTrack), 120)
        linreg30 = talib.LINEARREG(np.squeeze(gRealTrack), 30)
        #plt.plot(linreg60, label="LINEARREG60", linewidth=0.3)
        #plt.plot(linreg120, label="LINEARREG120", linewidth=0.3)
        #plt.plot(linreg30, label="LINEARREG30", linewidth=0.3)
        
        plt.plot(t, gRealTrack, label='MeasBid', color='r',linewidth=1)
        # if False == gUseRates:
        #     plt.plot(t, gRealTrackAsk[sym], label='MeasAsk', color='b',linewidth=0.1)
        #     plt.plot(t, np.squeeze(gPredictionsAsk[sym]), label='PredAsk', color='b',linewidth=0.5)
        #     plt.plot(t, np.squeeze(gRealSpread[sym]), label='RealSpread', color='y',linewidth=0.1)
        #     plt.plot(t, np.squeeze(gPredSpread[sym]), label='PredSpread', color='y',linewidth=0.5)


        plt.xlabel( gLabelXstr, fontsize=gFontSize)
        plt.ylabel( gLabelYstr, fontsize=gFontSize)
        plt.legend()
        plt.show()
        '''
        
        

    
        return ret
            
    # END  def run_analyse_kalman( self, dt_from = None, sym = None ):
    # =============================================================================


    # =============================================================================
    #  def run_analyse( self, dt_from = None, sym = None ):
    #     
    # =============================================================================
    def run_analyse( self, dt_from = None, sym = None ):
    # =============================================================================
    
        # usage:
        # import sys
        # import algotrader as at
        # at0 = at.Algotrader()
        # at0.run_now()
        # at0.run_now(datetime(2021,1,15,17, tzinfo=timezone.utc))
        
        if None == dt_from:
            dt_from = datetime.now(timezone.utc) + self.tdOffset

        if None == sym:
            sym = self.cf_symbols_default
            
        # check if connection to MetaTrader 5 successful
        ret = None
        if self.mt5_init():
            self.get_date_range(dt_from)
            self.get_ticks_and_rates(sym)
            ret = self.analyse_df(sym)
    
        return ret
            
    # END  def run_analyse( self, dt_from = None, sym = None ):
    # =============================================================================


    # =============================================================================
    #  def run_now( self, dt_from = None, sym = None ):
    #     
    # =============================================================================
    def run_now( self, dt_from = None, sym = None ):
    # =============================================================================
    
        # usage:
        # import sys
        # import algotrader as at
        # at0 = at.Algotrader()
        # at0.run_now()
        # at0.run_now(datetime(2021,1,15,17, tzinfo=timezone.utc))
        
        if None == dt_from:
            dt_from = datetime.now(timezone.utc) + self.tdOffset

        if None == sym:
            sym = self.cf_symbols_default
            
        # check if connection to MetaTrader 5 successful
        if self.mt5_init():
            self.run_test( dt_from, sym )
            
    # END  def run_now( self, dt_from = None, sym = None ):
    # =============================================================================


    # =============================================================================
    # def run_test( self, dt_from, sym):
    #     
    # =============================================================================
    #import sys
    def run_test( self, dt_from, sym):
    # =============================================================================
    
        start = time.time()
        gVol = 0.1
    
        self.get_date_range(dt_from)
        self.get_ticks_and_rates(sym)
        dfana = self.analyse_df(sym)
        self.print_analyse_df( dfana )
        #self.get_ticks_and_rates2(sym)
    
        op, dfbs = self.mt5_cnt_orders_and_positions( sym )
        print( dfbs )
        
        bs_threshold = 20
        
        buy_or_sell = 'neutral'
        if 1*bs_threshold < dfana.PS.SUMROW and 1*bs_threshold < dfana.OC.SUMROW:
            buy_or_sell = 'buy'
        
        if -1*bs_threshold > dfana.PS.SUMROW and -1*bs_threshold > dfana.OC.SUMROW:
            buy_or_sell = 'sell'
        
        
        if 'buy' == buy_or_sell:
            if 1 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
                print(buy_or_sell, 'do nothing')    
            elif 0 == dfbs.cnt.POS_BUY and 1 == dfbs.cnt.POS_SELL:
                self.set_gc0()
                self.mt5_position_reverse( sym )
                self.mt5_pending_order_remove(sym)
                self.mt5_pending_order_sell_limit(\
                    sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = self.g_c0[sym])
            elif 0 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
                self.set_gc0()
                self.mt5_position_buy(sym, gVol)
                self.mt5_pending_order_remove(sym)
                self.mt5_pending_order_sell_limit(\
                    sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = self.g_c0[sym])
            else:
                self.set_gc0()
                self.mt5_position_close(sym)    
                self.mt5_position_buy(sym, gVol)
                self.mt5_pending_order_remove(sym)
                self.mt5_pending_order_sell_limit(\
                    sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = self.g_c0[sym])
        
        elif 'sell' == buy_or_sell:
            if 0 == dfbs.cnt.POS_BUY and 1 == dfbs.cnt.POS_SELL:
                print(buy_or_sell, 'do nothing')    
            elif 1 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
                self.set_gc0()
                self.mt5_position_reverse( sym )
                self.mt5_pending_order_remove(sym)
                self.mt5_pending_order_buy_limit(\
                    sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = self.g_c0[sym])
            elif 0 == dfbs.cnt.POS_BUY and 0 == dfbs.cnt.POS_SELL:
                self.set_gc0()
                self.mt5_position_sell(sym, gVol)
                self.mt5_pending_order_remove(sym)
                self.mt5_pending_order_buy_limit(\
                    sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = self.g_c0[sym])
            else:
                self.set_gc0()
                self.mt5_position_close(sym)    
                self.mt5_position_sell(sym, gVol)
                self.mt5_pending_order_remove(sym)
                self.mt5_pending_order_buy_limit(\
                    sym, volume = 0.01, startoffset= 10, number = 10, offsetpar = 2, price = self.g_c0[sym])
    
        elif 'neutral' == buy_or_sell:
            print(buy_or_sell, 'do nothing')    
    
        self.mt5_position_sltp_follow2( sym )

        endticks = time.time()
        
        if self.gShowFig or self.gSaveFig:
            #self.print_fig_all_periods_per_sym()
            self.print_fig_all_periods_per_sym_NEW()
            # self.print_fig_all_periods_and_all_syms()
            # self.print_past_entries_per_sym()
        else:
            if 1 < self.gVerbose: print( '... noop ...' )    
        
        # if 'RFX2' == self.gACCOUNT:
        #    
        #     if self.gShowFig or self.gSaveFig:
        #         self.print_fig_all_periods_per_sym()
        #         # self.print_fig_all_periods_and_all_syms()
        #         # self.print_past_entries_per_sym()
        #     else:
        #         if self.gVerbose: print( '... noop ...' )    
        # else:	
        #     self.print_fig_all_periods_per_sym()
        #     self.print_fig_all_periods_and_all_syms()
        #     self.print_past_entries_per_sym()
        #     ##self.print_fig_all_periods_and_one_sym_and_all_times()
    
            
        #write_pickle_raw( 'file.pickle', self.gDF )
        #clear_ticks(  dt_from )
    
        end = time.time()
        dt_from_str =   str(dt_from.strftime("%Y%m%d_%H%M%S"))  
        if self.gVerbose: print( _sprintf("%s TOTAL TIME [%.2gs %.2gs %.2gs]\n", dt_from_str, (end-start), (endticks-start), (end-endticks)   ))
        
        # sys.stdout.write("\r" + _sprintf("%s %s TOTAL TIME [%.2gs %.2gs %.2gs]", dt_from_str, gDebugStr, (end-start), (endticks-start), (end-endticks)   ) )
        # sys.stdout.flush()    
        #print(time.strftime("%I:%M:%S %p", time.localtime()))
            
    # END def run_test( self, dt_from, sym):
    # =============================================================================





# =============================================================================
#
# END algotrader.py
#
# =============================================================================

