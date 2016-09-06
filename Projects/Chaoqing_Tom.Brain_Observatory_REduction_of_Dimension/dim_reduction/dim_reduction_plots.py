# -*- coding: utf-8 -*-
"""
Created on Tue Sep  6 16:14:56 2016

@author: tom
"""

import matplotlib.pyplot as plt
import numpy as np

def plot_all(df_expts, colorby, method):
    vals = df_expts[colorby].unique()
    colorlist = plt.cm.rainbow(np.linspace(0,1,len(vals)))
    metric = lambda ev: ev[3]

    for i, val in enumerate(vals):
        dfsub = df_expts[df_expts[colorby]==val]
        x = dfsub[method[0]].apply(metric)
        y = dfsub[method[1]].apply(metric)
        plt.plot(x,y, color=colorlist[i], linestyle='None', marker='o', label=val)
    plt.plot([0,1],[0,1])
    plt.xlim([0,1]);
    plt.ylim([0,1]);
    plt.xlabel(method[0]+' VAF')
    plt.ylabel(method[1]+' VAF')
    plt.legend(loc=4)
    
def plotall_1d(all_mean, matTrans, timex, ax=0, colorByOri=True):
    plt.figure(figsize=(10,3))
    
    
    ori_list = all_mean.orientation.unique()
    tf_list = all_mean.temporal_frequency.unique()

    if colorByOri:
        colorso = np.tile(plt.cm.rainbow(np.linspace(0,1,len(ori_list)/2)),(2,1))
    else:
        colorso = plt.cm.rainbow(np.linspace(0,1,len(ori_list)))
        
    colorsf = plt.cm.rainbow(np.linspace(0,1,len(tf_list)))
    
    tlength = np.count_nonzero(timex>=0)

    for i, ori in enumerate(ori_list):
        for j, tf in enumerate(tf_list):
            idx = all_mean[(all_mean.orientation==ori) & (all_mean.temporal_frequency==tf)]['i']
            if idx.values.size==1:
                idx = idx.values[0]
                
                plt.subplot(121)
                plt.plot(timex,
                     matTrans[idx*tlength + range(tlength), ax],
                     color=colorso[i])
                plt.title('by orientation')
                
                plt.subplot(122)
                plt.plot(timex,
                     matTrans[idx*tlength + range(tlength), ax],
                     color=colorsf[j])
                
                plt.title('by tf')
    return

def plotall_2d(all_mean, matTrans, timex, ax=[0,1], colorByOri=True):
    plt.figure(figsize=(10,5))
    
    
    ori_list = all_mean.orientation.unique()
    tf_list = all_mean.temporal_frequency.unique()

    if colorByOri:
        colorso = np.tile(plt.cm.rainbow(np.linspace(0,1,len(ori_list)/2)),(2,1))
    else:
        colorso = plt.cm.rainbow(np.linspace(0,1,len(ori_list)))
    
    colorsf = plt.cm.rainbow(np.linspace(0,1,len(tf_list)))
    
    tlength = np.count_nonzero(timex>=0)

    for i, ori in enumerate(ori_list):
        for j, tf in enumerate(tf_list):
            idx = all_mean[(all_mean.orientation==ori) & (all_mean.temporal_frequency==tf)]['i']
            if idx.values.size==1:
                idx = idx.values[0]
                
                plt.subplot(121)
                plt.plot(matTrans[idx*tlength + range(tlength), ax[0]],
                     matTrans[idx*tlength + range(tlength), ax[1]],
                     color=colorso[i])
                plt.title('by orientation')
                
                plt.subplot(122)
                plt.plot(matTrans[idx*tlength + range(tlength), ax[0]],
                     matTrans[idx*tlength + range(tlength), ax[1]],
                     color=colorsf[j])
                
                plt.title('by tf')
    return