# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import io
import os


# =============================================================================
# def _sprintf( fmt, *args):
#     
# =============================================================================
def _sprintf( fmt, *args):
    
    buf = io.StringIO()
    buf.write(fmt % args)
    return buf.getvalue()

# END def _sprintf( fmt, *args):
# =============================================================================

import pickle
import _pickle as cPickle
import bz2
import gzip
import lzma
# https://medium.com/better-programming/load-fast-load-big-with-compressed-pickles-5f311584507e
# https://docs.python.org/3/library/gzip.html
# https://docs.python.org/3/library/lzma.html


# =============================================================================
# 
# # https://www.quora.com/How-can-I-store-dictionaries-in-Python
# #    https://docs.python.org/3/library/pickle.html
# 
# import pickle
# with open('20201224_190000_ticks_gap.pickle', 'wb') as f: pickle.dump(self.gDF, f)
#
# 
# 
# with open('RFX2/PICKLE/20201231_175900.pickle', 'rb') as f: self.gDF = pickle.load(f) 
# 
# # pickle - saving 
# with open('data.pickle', 'wb') as f: 
#     pickle.dump(self.gDF, f)
# 
# # pickle - loading
# with open('data.pickle', 'rb') as f: 
#     saved_data_pickle = pickle.load(f)
# 
# # https://pypi.org/project/sqlitedict/
# # pip install -U sqlitedict
# # import sqlitedict 
# 
# # help(sqlitedict)
# from sqlitedict import SqliteDict
# with SqliteDict('./data.sqlite') as mydict:
#     mydict['01'] = saved_data_pickle
#     mydict.commit()
# 
# with SqliteDict('./data.sqlite') as mydict:
#     print(  mydict['01'] )
# 
#     
# =============================================================================

def write_pickle( dt_from, data, account ):
    home_dir = ".\\" + account + "\\PICKLE"
    os.makedirs(home_dir, exist_ok=True)
    filename_pickle =  home_dir +  "\\" + str(dt_from.strftime("%Y%m%d_%H%M%S.pickle"))
    print( filename_pickle )
    write_pickle_raw( filename_pickle, data )
    
    home_dir = ".\\" + account + "\\PICKLEBZ2"
    os.makedirs(home_dir, exist_ok=True)
    filename_pickle =  home_dir +  "\\" + str(dt_from.strftime("%Y%m%d_%H%M%S.pickle"))
    print( filename_pickle )
    write_pickle_bz2( filename_pickle, data )
    
    home_dir = ".\\" + account + "\\PICKLEBGZIP"
    os.makedirs(home_dir, exist_ok=True)
    filename_pickle =  home_dir +  "\\" + str(dt_from.strftime("%Y%m%d_%H%M%S.pickle"))
    print( filename_pickle )
    write_pickle_gzip( filename_pickle, data )
    
    home_dir = ".\\" + account + "\\PICKLEBLZMA"
    os.makedirs(home_dir, exist_ok=True)
    filename_pickle =  home_dir +  "\\" + str(dt_from.strftime("%Y%m%d_%H%M%S.pickle"))
    print( filename_pickle )
    write_pickle_lzma( filename_pickle, data )


def write_pickle_raw( filename_pickle, data ):
    with open(filename_pickle, 'wb') as f: 
        pickle.dump(data, f)

def read_pickle_raw( filename_pickle ):
    data = {}
    with open(filename_pickle, 'rb') as f: 
        data = pickle.load(f) 
    return data

def write_pickle_bz2( filename_pickle, data ):
    with bz2.BZ2File(filename_pickle, 'wb') as f: 
        cPickle.dump(data, f)

def read_pickle_bz2( filename_pickle ):
    data = {}
    with bz2.BZ2File(filename_pickle, 'rb') as f:
        data = cPickle.load(f)
    return data

def write_pickle_gzip( filename_pickle, data ):
    with gzip.open(filename_pickle, 'wb') as f:
        pickle.dump(data, f)

def read_pickle_gzip( filename_pickle ):
    data = {}
    with gzip.open(filename_pickle, 'rb') as f:
        data = pickle.load(f) 
    return data

def write_pickle_lzma( filename_pickle, data ):
    with lzma.open(filename_pickle, "wb") as f:
        pickle.dump(data, f)

def read_pickle_lzma( filename_pickle ):
    data = {}
    with lzma.open(filename_pickle, 'rb') as f:
        data = pickle.load(f) 
    return data


# =============================================================================
# def time_delta_to_msc( time_delta ):
#     
# =============================================================================
def time_delta_to_msc( time_delta ):
    # https://markhneedham.com/blog/2015/07/28/python-difference-between-two-datetimes-in-milliseconds/    
    return ( (time_delta.days * 86400000) + (time_delta.seconds * 1000) + (time_delta.microseconds / 1000) ) 
# END: def time_delta_to_msc( time_delta )
# =============================================================================


