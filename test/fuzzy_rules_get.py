
# https://towardsdatascience.com/machine-learning-with-fuzzy-logic-52c85b46bfe4

import pandas as pd
import skfuzzy as fuzz
import numpy as np
from skfuzzy import control as ctrl
import matplotlib.pyplot as plt

# try to replace this with other forecast weather
# from ipynb.fs.full.weather_data_preprocess import data, train_data, test_data

# https://keras.io/examples/timeseries/timeseries_weather_forecasting/#prediction
#  git archives:
#   https://github.com/keras-team/keras-io/blob/master/examples/timeseries/timeseries_weather_forecasting.py
#   https://colab.research.google.com/github/keras-team/keras-io/blob/master/examples/timeseries/ipynb/timeseries_weather_forecasting.ipynb
#  weather data:
#   https://www.bgc-jena.mpg.de/wetter/
#     https://storage.googleapis.com/tensorflow/tf-keras-datasets/jena_climate_2009_2016.csv.zip
#



#"""
#    installation of additional modules:
#
#    (base) C:\Users\G6>conda activate fuzzyalgo-py38
#    (fuzzyalgo-py38) C:\Users\G6>pip install tensorflow
#
#"""

import tensorflow as tf
from tensorflow import keras

from zipfile import ZipFile
import os

# download weather forecast zip file and extract it if it does not exists yet:
if not os.path.exists("jena_climate_2009_2016.csv.zip"):
    uri = "https://storage.googleapis.com/tensorflow/tf-keras-datasets/jena_climate_2009_2016.csv.zip"
    zip_path = keras.utils.get_file(origin=uri, fname="jena_climate_2009_2016.csv.zip")
    zip_file = ZipFile(zip_path)
    zip_file.extractall()
    csv_path = "jena_climate_2009_2016.csv"
    csv_path = "gNpa.csv"

df = pd.read_csv(csv_path)

print( df )


class Fuzzify(object):
    def __init__(self, data_series, data_step = 0.1 ):
        """Create a triangular membership function with a data series and its max, min and median"""
        
        self.data       = data_series   
        self.low        = self.data.min()
        self.high       = self.data.max()
        self.mid        = np.median(np.arange(self.low, self.high, data_step))   
        self.universe   = np.arange (np.floor(self.low), np.ceil(self.high), data_step)
        self.trimf_lowE = fuzz.trimf(self.universe, [ self.low, self.low,  self.mid])
        self.trimf_low  = fuzz.trimf(self.universe, [ self.low, (self.low+self.mid)/2, self.mid])
        self.trimf_mid  = fuzz.trimf(self.universe, [ self.low, self.mid,  self.high])
        self.trimf_high = fuzz.trimf(self.universe, [ self.mid, (self.mid+self.high)/2, self.high])
        self.trimf_highE= fuzz.trimf(self.universe, [ self.mid, self.high, self.high])

        #self.trimf_low  = fuzz.trimf(self.universe, [ self.low, self.low,  self.high])
        #self.trimf_mid  = fuzz.trimf(self.universe, [ self.low, self.mid,  self.high])
        #self.trimf_high = fuzz.trimf(self.universe, [ self.low, self.high, self.high])

        
    def get_universe(self):
        return self.universe
        
    def get_membership(self):
        """Assign fuzzy membership to each observation in the data series and return a dataframe of the result"""
        
        new_df = pd.DataFrame(self.data)
        new_df['-2'] = fuzz.interp_membership(self.universe, self.trimf_lowE, self.data)
        new_df['-1']  = fuzz.interp_membership(self.universe, self.trimf_low,  self.data)
        new_df['0']  = fuzz.interp_membership(self.universe, self.trimf_mid,  self.data)
        new_df['+1'] = fuzz.interp_membership(self.universe, self.trimf_high, self.data)
        new_df['+2']= fuzz.interp_membership(self.universe, self.trimf_highE,self.data)
        new_df['membership'] = new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1)
        # for np ->  new_df.loc[:, ['-2','-1', '0', '+1', '+2']].idxmax(axis = 1).to_numpy().astype(np.float64)
        new_df['degree'] = new_df.loc[:, ['-2', '-1', '0', '+1', '+2']].max(axis = 1)
        # for np ->  new_df.loc[:, ['-2', '-1', '0', '+1', '+2']].max(axis = 1).to_numpy()
        return new_df

    def get_membership2(self):
        """Assign fuzzy membership to each observation in the data series and return a dataframe of the result"""
        
        new_df = pd.DataFrame(self.data)
        new_df['N2'] = fuzz.interp_membership(self.universe, self.trimf_lowE, self.data)
        new_df['N1']  = fuzz.interp_membership(self.universe, self.trimf_low,  self.data)
        new_df['Z0']  = fuzz.interp_membership(self.universe, self.trimf_mid,  self.data)
        new_df['P1'] = fuzz.interp_membership(self.universe, self.trimf_high, self.data)
        new_df['P2']= fuzz.interp_membership(self.universe, self.trimf_highE,self.data)
        new_df['membership'] = new_df.loc[:, ['N2','N1', 'Z0', 'P1', 'P2']].idxmax(axis = 1)
        new_df['degree'] = new_df.loc[:, ['N2', 'N1', 'Z0', 'P1', 'P2']].max(axis = 1)
        return new_df
        

# take index 1,2&5
'''
    df.columns
    Out[46]: 
    Index(['Date Time', 'p (mbar)', 'T (degC)', 'Tpot (K)', 'Tdew (degC)',
           'rh (%)', 'VPmax (mbar)', 'VPact (mbar)', 'VPdef (mbar)', 'sh (g/kg)',
           'H2OC (mmol/mol)', 'rho (g/m**3)', 'wv (m/s)', 'max. wv (m/s)',
           'wd (deg)'],
          dtype='object')

    df.columns[0]
    Out[47]: 'Date Time'

    df.columns[1]
    Out[48]: 'p (mbar)'

    df.columns[2]
    Out[49]: 'T (degC)'

    df.columns[5]
    Out[50]: 'rh (%)'
'''

train_data = pd.DataFrame()

# TODO make me optional
#
# either 
#

if csv_path == "jena_climate_2009_2016.csv":
    idx_arr = [1,5,2]
    idx_arr = [1,2,12]
    for idx in idx_arr:
        train_data[df.columns[idx]] = df[df.columns[idx]]

#
# or
#
period = 3600
in1_idx = 'oc'
in2_idx = 'hl'
out_idx = 'priced'


in1 = in1_idx + '_' + str(period)
in2 = in2_idx + '_' + str(period)
out = out_idx + '_' + str(period)
if csv_path == "gNpa.csv":
    idx_arr = [in1,in2,out]
    for idx in idx_arr:
        train_data[idx] = df[idx]

         

humidity_object = Fuzzify( train_data.iloc[:,0] )
fuzzified_humidity = humidity_object.get_membership()
print( fuzzified_humidity ) 

temperature_object = Fuzzify( train_data.iloc[:,1] )
fuzzified_temperature = temperature_object.get_membership()
print( fuzzified_temperature )

heat_object = Fuzzify( train_data.iloc[:,2] )
fuzzified_heat = heat_object.get_membership()
print( fuzzified_heat )


def get_rule(train_data, *arg):
    """ return the final fuzzy rule given any number of input data columns"""
    
    rule_df = train_data.copy()
    rule_df['degree'] = np.ones(train_data.shape[0])
    for col in rule_df.columns[:-1]:
        idx = train_data.columns.get_loc(col)
        print( 'col: ', col, " idx: ", idx )
        print( arg[idx]['membership'] )
        print( arg[idx] )
        rule_df[col] = arg[idx]['membership']
        rule_df['degree'] *=  arg[idx]['degree']
    final_rule = rule_df.groupby(list(rule_df.columns[:-2])).max()
    final_rule = final_rule.reset_index()
    return final_rule
    
final_rule = get_rule(train_data, fuzzified_humidity, fuzzified_temperature, fuzzified_heat)



'''

""" return the final fuzzy rule given any number of input data columns"""

rule_df = train_data.copy()
rule_df['degree'] = np.ones(train_data.shape[0])
for col in rule_df.columns[:-1]:
    idx = train_data.columns.get_loc(col)
    rule_df[col] = arg[idx]['membership']
    
    rule_df['degree'] *=  fuzzified_humidity[idx]['degree']
    rule_df['degree'] *=  fuzzified_temperature[idx]['degree']
    rule_df['degree'] *=  fuzzified_heat[idx]['degree']
    
    #rule_df['degree'] *=  arg[idx]['degree']
final_rule = rule_df.groupby(list(rule_df.columns[:-2])).max()
final_rule = final_rule.reset_index()
'''


print( final_rule )

