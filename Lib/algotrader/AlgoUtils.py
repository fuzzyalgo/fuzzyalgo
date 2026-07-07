# -*- coding: utf-8 -*-
"""
Created on Sat, Jul 26, 2025  7:09:41 PM

@author: André Howe 
"""

import io
def sprintf(fmt, *args):
    buf = io.StringIO()
    buf.write(fmt % args)    
    return buf.getvalue()

