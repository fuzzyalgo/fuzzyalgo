# -*- coding: utf-8 -*-
"""
Created on Thu Oct 24 13:58:14 2024

@author: André Howe 
"""

import json
import os
import math
import logging 
from datetime import datetime
from datetime import timezone
from datetime import timedelta



from AlgoUtils import sprintf 


class AlgoParams():
    def __init__(self):
        self.Void  = False

class LogLevels():
    def __init__(self):
        self.Void  = False
    
        
class AlgoConfig():
    def __init__(self,  account = 'Rf5D03',
                    symbols = ['EURUSD'],
                    periods = ['T60,S60'],
                    data_dir = '../../data',
                    cf_accounts_fn = '../../config/cf_accounts.json'): 
    
        # if cf_accounts_fn is absolute, then use it as is
        if True == os.path.isabs(cf_accounts_fn):
            self.cf_accounts_fn = cf_accounts_fn
        # if cf_accounts_fn is not absolute, then use the path of this script
        else:
            self.cf_accounts_fn = os.path.abspath(os.path.dirname(__file__)) + "/" + cf_accounts_fn

        if False == os.path.exists(self.cf_accounts_fn):
            raise Exception("AlgoConfig: cf_accounts_fn does not exists: " + self.cf_accounts_fn)
        with open(self.cf_accounts_fn, 'r') as f: self.cf_accounts = json.load(f)
        
        self.gACCOUNT = account
        # check here if configuration exists
        if not self.gACCOUNT in self.cf_accounts:
            raise Exception("AlgoConfig: self.gACCOUNT in self.cf_accounts does not exists: " + self.gACCOUNT)

        for key in self.cf_accounts:
            print( "acc", key )
            if 'symbols' in self.cf_accounts[key]:
                print( "    sym:", self.cf_accounts[key]['symbols'] )
            if 'periods' in self.cf_accounts[key]:
                print( "    per:", self.cf_accounts[key]['periods'] )
            if self.gACCOUNT == key:
                print ( "    -> active account" )
                print( "    server:", self.cf_accounts[key]['server'] )

        # debug print result for regression_test_key_array
        # cnt = 0
        # for key in self.regression_test_key_array:
        #     print( cnt, key )
        #     cnt = cnt +1
            
        
        self.AlgoParams = AlgoParams()
        self.AlgoParams.Void = True

        self.LogLevels = LogLevels()
        self.LogLevels.Void = True


        # set real home_path ${PATH} for this PC
        self.home_path = ''
        # https://stackoverflow.com/questions/1325581/how-do-i-check-if-im-running-on-windows-in-python
        if 'nt' == os.name:
            self.home_path = 'c:/Users/' + os.environ["USERNAME"]
            if 'G6' == os.environ["COMPUTERNAME"] :
                self.home_path = 'c:/code/'
                if False == os.path.exists( self.home_path ):
                    os.makedirs(self.home_path, exist_ok=True)         
        else:
            # Linux OS
            self.home_path = '/home/' + os.environ["USER"]

        self.data_dir = self.home_path +  '/code/'
        
        self.dbg_img_path = sprintf("%s/dbg/img/%s", self.data_dir, self.gACCOUNT);
        if False == os.path.exists( self.dbg_img_path ):
            os.makedirs(self.dbg_img_path, exist_ok=True)         
        #        
        # at logging
        #
        # winter time
        self.tdOffset= timedelta(hours=2)
        # summer time
        #self.tdOffset= timedelta(hours=3)        
        
        dt_start     = datetime.now(timezone.utc) + self.tdOffset
        self.dt_start_str = str(dt_start.strftime("%Y%m%d_%H%M%S"))  
        log_filename = self.dbg_img_path + "/" + self.dt_start_str + ".log"
        format_str = '%(asctime)s: %(message)s'
        #format_str = '%(message)s'
        # https://stackoverflow.com/questions/15199816/python-logging-multiple-files-using-the-same-logger
        # https://stackoverflow.com/questions/17035077/logging-to-multiple-log-files-from-different-classes-in-python
        #atlog.basicConfig(filename=log_filename, level=logging.DEBUG, format=format_str)
        self.set_logger( name = 'WGW2.0.X', filename = log_filename, level = logging.INFO, format = format_str, use_stdout = True )
        self.log = logging.getLogger('WGW2.0.X')
        

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
        

    def PrintBasicConfiguration(self):

        print( 'ACTIVE_CONFIG',   self.gACCOUNT, '\n', 
               'JSON', self.cf_accounts_fn, '\n' )


    def PrintConfigVars(self):
        # output self.ConfigVars
        print( 'self.cf_accounts:' )
        for _k,_v in self.cf_accounts.items():
            _str = sprintf( "    %50s  %s", _k, _v )
            print( _str )



if __name__ == "__main__":
    
    print ( "TEST AlgoConfig.py START" )
    print ( "-----------------------" )
    wc = AlgoConfig( 'RF5D03',
                    '../../config/cf_accounts.json')
    wc.PrintBasicConfiguration()
    wc.PrintConfigVars()
    print ( "---------------------" )
    print ( "TEST AlgoConfig.py END" )

