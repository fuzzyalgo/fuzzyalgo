# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

#   Create a figure that is reference counted  
#     https://stackoverflow.com/questions/16334588/create-a-figure-that-is-reference-counted/16337909#16337909
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
from pandas.plotting import register_matplotlib_converters
register_matplotlib_converters()
import mplfinance as mpf
from algotrader._utils import _sprintf


# =============================================================================
# def _mpf_figure_open(gShowFig=True,gTightLayout=True,x_size=None,y_size=None):
#     
# =============================================================================
def _mpf_figure_open(gShowFig=True,gTightLayout=True,x_size=None,y_size=None):
    
    figure = None
    
    if x_size is not None:
        #figure = mpf.figure(figsize=(x_size,y_size),tight_layout=self.gTightLayout)
        if gShowFig:
            figure = plt.figure(figsize=(x_size,y_size),tight_layout=gTightLayout)
        else:    
            # if we only want to save the figure
            figure = Figure(figsize=(x_size,y_size),tight_layout=gTightLayout)
    else:
        figure = Figure()
        
    # canvas = FigureCanvas(figure)
    
    return figure
# END def _mpf_figure_open(gShowFig=True,gTightLayout=True,x_size=None,y_size=None):
# =============================================================================

# =============================================================================
# def _mpf_figure_show(gShowFig=True,gGlobalFig=False):
#     
# =============================================================================
def _mpf_figure_show(gShowFig=True,gGlobalFig=False):
    
    if gShowFig:
        #mpf.show()
        if gGlobalFig: plt.show(False)
        if not gGlobalFig: plt.show()
    
# END def _mpf_figure_show(gShowFig=True,gGlobalFig=False):
# =============================================================================

# =============================================================================
# def _mpf_figure_save(figure, figure_filename = None):
#     
# =============================================================================
def _mpf_figure_save(figure, figure_filename = None):

    if figure_filename is not None:
        # figure
        figure.savefig(figure_filename)
    else:    
        # TODO create better random filename here
        figure.savefig("fig_sym.png")
    
# END def _mpf_figure_save(figure, figure_filename = None):
# =============================================================================

# =============================================================================
# def _mpf_figure_close(figure):
#     
# =============================================================================
def _mpf_figure_close(figure):
    
    figure.clf()
    figure.clear()
    plt.close(figure)
    
# END def _mpf_figure_close(figure):
# =============================================================================

# =============================================================================
# def _mpf_plot(data,**args):
#     
# =============================================================================
def _mpf_plot(data,**args):

    mpf.plot(data,**args)    
    
# END def _mpf_plot(data,**args):
# =============================================================================


# =============================================================================
# def _calc_subplot_rows_x_cols( num_of_plots ):
#     
# =============================================================================
def _calc_subplot_rows_x_cols( num_of_plots ):

    # https://matplotlib.org/3.3.3/api/_as_gen/matplotlib.pyplot.figure.html
    #  
    # figsize(float, float), default: rcParams["figure.figsize"] (default: [6.4, 4.8])
    # width, height in inches.
    width  = height = 0
    width  = 16
    height = 10
    
    # https://matplotlib.org/3.3.3/api/_as_gen/matplotlib.figure.Figure.html#matplotlib.figure.Figure.add_subplot
    nrows  = ncols = 0
    nrows  = 4
    ncols  = 4

    if 1 > num_of_plots:
        raise ValueError( _sprintf("ERROR: num_of_plots[%d] too small - fix calc_subplot_rows_x_cols ", num_of_plots, nrows, ncols) )
    
    if 4 >= num_of_plots:
        ncols  = num_of_plots
        nrows  = 1
        if 4 == num_of_plots:
            ncols  = 2
            nrows  = 2
    else:
        ncols  = 4
        nrows  = int(num_of_plots / 4)
    
    if num_of_plots != (nrows*ncols):
        raise ValueError( _sprintf("ERROR: num_of_plots[%d] != nrows[%d] x ncols[%d] - fix calc_subplot_rows_x_cols ", num_of_plots, nrows, ncols) )

    return width, height, nrows, ncols

# def _calc_subplot_rows_x_cols( num_of_plots ):
# =============================================================================

    
