# -*- coding: utf-8 -*-
"""
Created on Fri Apr  2 13:02:43 2021

@author: Andre
"""


# https://nitratine.net/blog/post/how-to-get-mouse-clicks-with-python/
# https://pypi.org/project/pynput/
# https://pynput.readthedocs.io/en/latest/keyboard.html#monitoring-the-keyboard


from pynput import keyboard
from pynput import mouse
import logging
import sys


class _Pyinput():
    
    def __init__(self, algo_trader_handle, dt_from = None, symbols = None, sym = None, vol = 0.01):
    
        self.gH = algo_trader_handle
        self.dt_from = dt_from
        
        if None == symbols:
            self.symbols = self.gH.cf_symbols_all
        else:            
            self.symbols = symbols

        if None == sym:
            self.sym = self.gH.cf_symbols_default
        else:            
            self.sym = sym
            
        self.vol = vol
        
        logging.basicConfig(filename="pyinput_log.txt", level=logging.DEBUG, format='%(asctime)s: %(message)s')

        # # Collect events until released
        # with keyboard.Listener(
        #         on_press=on_press,
        #         on_release=on_release) as keyboard_listener:
        #     keyboard_listener.join()
    
        # ...or, in a non-blocking fashion:
        self.keyboard_listener = keyboard.Listener(
            on_press    = self.on_press,
            on_release  = self.on_release)
        self.keyboard_listener.start()


        print('START keyboard and mouse listener')
        
        # Collect events until released
        with mouse.Listener(
                on_move    =self.on_move,
                on_click   =self.on_click,
                on_scroll  =self.on_scroll) as self.mouse_listener:
            self.mouse_listener.join()
        
        # # ...or, in a non-blocking fashion:
        # mouse_listener = mouse.Listener(
        #     on_move=on_move,
        #     on_click=on_click,
        #     on_scroll=on_scroll)
        # mouse_listener.start()
            
        print('STOP keyboard and mouse listener - Executed')
        



    #
    # test mt5 API
    #
    
    # misc
    # def mt5_fx_scalper(self, sym, vol, piddelta = None ):
    # def mt5_cnt_orders_and_positions( self, sym ):    
    # def mt5_test_functions(self, sym, vol):
    #
    # pending orders
    # def mt5_pending_order_first( self, sym, volume = 0.01, offset = 20 ):
    # def mt5_pending_order_remove( self, sym ):
    # def mt5_pending_order_modify( self, sym, price, magic ):
    # def mt5_pending_order_raw(self, symbol, volume, price, order_type, comment, magic):    
    # 
    # positions    
    # def mt5_position_raw_order(self, order_type, symbol, volume, price, comment=None, ticket=None):    
    # def mt5_position_close(self, symbol, *, comment=None, ticket=None):    
    # def mt5_position_buy(self, symbol, volume, price=None, *, comment=None, ticket=None):    
    # def mt5_position_sell(self, symbol, volume, price=None, *, comment=None, ticket=None):    


    #
    # keyboard listener
    #  https://pynput.readthedocs.io/en/latest/keyboard.html#monitoring-the-keyboard
    #
    def on_press(self, key):
        try:
            logging.info('alphanumeric key {0} pressed'.format(key.char))
    
            # fx scalper        
            # def mt5_fx_scalper(self, sym, vol, piddelta = None ):
            if ('f' == key.char) or ('F' == key.char):
                print('[f] key {0} pressed'.format(key.char))
                self.gH.mt5_fx_scalper( self.sym, self.vol)
    
            # cnt orders and positions
            # def mt5_cnt_orders_and_positions( self, sym ):    
            if ('n' == key.char) or ('N' == key.char):
                print('[n] key {0} pressed'.format(key.char))
                orders = self.gH.mt5_cnt_orders_and_positions( self.sym )
                print( orders )
            
            # def mt5_test_functions(self, sym, vol):
            if ('t' == key.char) or ('T' == key.char):
                print('[t] key {0} pressed'.format(key.char))
                self.gH.mt5_test_functions( self.sym, self.vol)
    
            # run_now
            if ('r' == key.char) or ('R' == key.char):
                print('[r] key {0} pressed'.format(key.char))
                #  def run_all( self, dt_from = None, symbols = None, 
                #       use_pid = False, use_scalp = False, perarr=None, 
                #       time_to_sleep = 1, screen = None ):
                self.gH.run_all(self.dt_from, self.symbols)
    
            # first pending order
            # def mt5_pending_order_first( self, sym, volume = 0.01, offset = 20 ):
            if ('p' == key.char) or ('P' == key.char):
                print('[p] key {0} pressed'.format(key.char))
                self.gH.mt5_pending_order_first( self.sym, self.vol)
    
            # remove pending order            
            # def mt5_pending_order_remove( self, sym ):
            if ('x' == key.char) or ('X' == key.char):
                print('[x] key {0} pressed'.format(key.char))
                self.gH.mt5_pending_order_remove( self.sym )
    
            # buy position
            # def mt5_position_buy(self, symbol, volume, price=None, *, comment=None, ticket=None):    
            if ('b' == key.char) or ('B' == key.char):
                print('[b] key {0} pressed'.format(key.char))
                self.gH.mt5_position_buy( self.sym, self.vol )
    
            # sell position 
            # def mt5_position_sell(self, symbol, volume, price=None, *, comment=None, ticket=None):    
            if ('s' == key.char) or ('S' == key.char):
                print('[s] key {0} pressed'.format(key.char))
                self.gH.mt5_position_sell( self.sym, self.vol )
    
            # close positions
            # def mt5_position_close(self, symbol, *, comment=None, ticket=None):    
            if ('c' == key.char) or ('C' == key.char):
                print('[c] key {0} pressed'.format(key.char))
                self.gH.mt5_position_close( self.sym )
    
    
            # helper        
            if ('h' == key.char) or ('H' == key.char):
                print('[h] key {0} pressed'.format(key.char))
                print( 'f  -> FX SCA gH.mt5_fx_scalper( gSym, gVol)' )
                print( 'n  -> COUNT  gH.mt5_cnt_orders_and_positions( gSym )' )
                print( 't  -> TEST   gH.mt5_test_functions( gSym, gVol)  ')
                print( 'r  -> RUN    gH.run_now() ')
                print( 'p  -> FIRST  gH.mt5_pending_order_first( gSym, gVol) ')
                print( 'x  -> REMOVE gH.mt5_test_functions( gSym, gVol) ')
                print( 'b  -> BUY    gH.mt5_position_buy( gSym, gVol ) ')
                print( 's  -> SELL   gH.mt5_position_sell( gSym, gVol ) ')
                print( 'c  -> CLOSE  gH.mt5_position_close( gSym ) ')
                print()
    
                
        except AttributeError:
            logging.info('special key {0} pressed'.format(key))
            if keyboard.Key.space == key:
                print('SPACE {0} pressed'.format(key))
            if keyboard.Key.up == key:
                print('UP  {0} pressed'.format(key))
            if keyboard.Key.down == key:
                print('DOWN {0} pressed'.format(key))
            if keyboard.Key.left == key:
                print('LEFT {0} pressed'.format(key))
            if keyboard.Key.right == key:
                print('RIGHT {0} pressed'.format(key))
        
        except:
            print( "Exception: ", sys.exc_info())

        
    def on_release(self, key):
        logging.info('{0} released'.format(key))
        if keyboard.Key.esc == key:
            print( "STOP keyboard and mouse listener" )
            self.keyboard_listener.stop()
            self.mouse_listener.stop()
        
        # if key == keyboard.Key.esc:
        #     # Stop listener
        #     return False
    


    #
    # mouse listener
    #  https://pynput.readthedocs.io/en/latest/mouse.html#monitoring-the-mouse
    #
    
    
    def on_move(self, x, y):
        logging.info("Mouse moved to ({0}, {1})".format(x, y))
    
    def on_click(self, x, y, button, pressed):
        if pressed:
            logging.info('Mouse clicked at ({0}, {1}) with {2}'.format(x, y, button))
            # if mouse.Button.left == button:
            #     mouse_listener.stop()
    
    def on_scroll(self, x, y, dx, dy):
        logging.info('Mouse scrolled at ({0}, {1})({2}, {3})'.format(x, y, dx, dy))

