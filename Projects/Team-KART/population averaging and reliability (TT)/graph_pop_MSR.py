# -*- coding: utf-8 -*-
"""
Created on Fri Sep 02 11:38:24 2016
Make plots and do stats on population mean sweep response data

@author: ttruszko
"""

# In[]
# general initialization
from data_preprocessing import * 
boc, Selectivity_S_df, y = BOC_init(selectivity_csv_filename='C:\\Users\\ttruszko\\Documents\\GitHub\\SWDB-KART\\image_selectivity_dataframe.csv')    
import pandas as pd
#f = open('C:\\Users\\ttruszko\\raw_population_MSR.csv', 'r')
#f.read()

# In[]
# make a graph of variability