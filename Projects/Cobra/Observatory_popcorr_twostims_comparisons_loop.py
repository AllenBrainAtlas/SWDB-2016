#given condition constraints (mouse, stim_type, stim_id, etc), compare the population coupling ofcalcium respponses of
# the same cell to one stim type vs. another. Make a scatter plot of the pop coupling of stim 1 vs stim 2 and calculate
# the rsquared metric.

# this is similar to Observatory_popcorr_twostims_comparisons.py excep that it loops over all mice and cre_lines
# this function is called by the notebook  Obvservatory_popcorrs_all.ipynb

import numpy as np
import matplotlib.pyplot as plt
import pickle
import pylab
import seaborn as sns
sns.set(style="white")

#our modules
import cobra_analysis
import allen_data_fetch

"""
Module to compare population coupling in Ca data during two different visual stim, looped across areas and cre_lines.
Makes a scatter plot of the pop coupling of stim 1 vs stim 2 and calculates
the rsquared metric. Higher rsquared means population coupling is more invariant to visual stim type.

Author: Madineh Sarvestani
Sept 2016
"""


def pc_values(activity_matrix_1, activity_matrix_2):
    """
    Takes activity_matrix for two conditions and outputs z-scored population correlation
    """
    pc_zscored1 = cobra_analysis.pop_corr_z_scored(activity_matrix_1)
    pc_zscored2 = cobra_analysis.pop_corr_z_scored(activity_matrix_2)

    return pc_zscored1, pc_zscored2


def plot_hists(filename, pc_zscored_stim1, pc_zscored_stim2):
    """
    Plots histograms for each condition, given population coupling metrics
    """

    fig, axs = plt.subplots(1, 2, figsize=(10, 5))
    axs = axs.ravel()


    axs[0].hist(pc_zscored_stim1)
    axs[0].set_ylabel('Count')
    axs[0].set_title('Stim1 PC_zscored ')
    plt.tick_params(axis='y',which='both', top='off')
    axs[0].get_yaxis().set_ticks([])


    axs[1].hist(pc_zscored_stim2)
    axs[1].set_ylabel('Count')
    axs[1].set_title('Stim2 PC_zscored')
    plt.tick_params(axis='y',which='both', top='off')
    axs[1].get_yaxis().set_ticks([])

    plt.tight_layout()

    #pylab.savefig(filename+'.png')

    return




def plot_scatters(filename, pc_zscored_stim1, pc_zscored_stim2,
                  title_str):

    x1=pc_zscored_stim1
    x2=pc_zscored_stim2
    xlabel_str='1st Stim'
    ylabel_str='2nd Stim'

    fig = sns.jointplot(x1, x2)
    x0, x1 = fig.ax_joint.get_xlim()
    y0, y1 = fig.ax_joint.get_ylim()
    lims = [max(x0, y0), min(x1, y1)]
    fig.ax_joint.plot(lims, lims, ':k')

    fig.set_axis_labels(xlabel_str, ylabel_str)
    plt.subplots_adjust(top=0.9)
    fig.fig.suptitle(title_str)  # can also get the figure from plt.gcf()


    #pylab.savefig(filename+'.png')

    return

# Polynomial Regression to get rsquared
def get_rsquared(x, y):
    results = {}

    coeffs = np.polyfit(x, y, 1)

     # Polynomial Coefficients
    results['polynomial'] = coeffs.tolist()

    # r-squared
    p = np.poly1d(coeffs)
    # fit values, and mean
    yhat = p(x)                         # or [p(z) for z in x]
    ybar = np.sum(y)/len(y)          # or sum(y)/len(y)
    ssreg = np.sum((yhat-ybar)**2)   # or sum([ (yihat - ybar)**2 for yihat in yhat])
    sstot = np.sum((y - ybar)**2)    # or sum([ (yi - ybar)**2 for yi in y])
    results['determination'] = ssreg / sstot
    rsquared=(ssreg/sstot)

    return rsquared

def get_container_list(structure_id,cre_line):
    container_list = allen_data_fetch.get_container_list()

    container_list_filt = container_list[(container_list['targeted_structure'] == structure_id) &
                                     (container_list['cre_line'] == cre_line)]


    return container_list_filt


def get_plots (container_id, session_idx1, stim_type1, session_idx2, stim_type2):


    # output plots
    # 1)distribution of pop corrs for stim 1 and 2
    # 2)scatter plots for pop_corr zscored  stim1 vs stim2


    activity_matrix_1= allen_data_fetch.get_activity_matrix(
        container_id, session_idx1, stim_type1, units='all')

    activity_matrix_2 = allen_data_fetch.get_activity_matrix(
        container_id, session_idx2, stim_type2, units='all')


    pc_zscored1,pc_zscored2 = pc_values(activity_matrix_1, activity_matrix_2)

    filename1 = str(container_id) + '_' + str(session_idx1) + '_' + stim_type1 + 'vs_' + stim_type2 + '_hists'
    filename2 = str(container_id)+ '_' + str(session_idx1) + '_' + stim_type1 + 'vs_' + stim_type2 + '_pc_zscored_local'

    #plot_hists(filename1, pc_zscored1, pc_zscored2)


    title_str='Pop Coupling Stim 1 vs Stim 2'
    plot_scatters(filename2, pc_zscored1, pc_zscored2,
                  title_str)

    #get rsqaured value
    pc_zscored1=np.reshape(pc_zscored1,(len(pc_zscored1,)))
    pc_zscored2=np.reshape(pc_zscored2,(len(pc_zscored2,)))
    rsquared = get_rsquared(pc_zscored1, pc_zscored2)

    # uncomment to pickle data
    #fileObject = open(filename2, 'wb')
    #pickle.dump([pc_zscored1, pc_zscored2], fileObject)
    #fileObject.close()

    return rsquared



#define the conditions (stim type, etc) here:
# loop over cre-lines and ares

def get_rsquared_structure(structure_id, creline_id, session_idx1, stim_type1, stim_type2):


    #alywas use session
    session_idx2 = session_idx1

    # session_0 stim_types
    'drifting_gratings', 'natural_movie_one', 'natural_movie_three', 'spontaneous'

    # sesion_1 stim_stypes
    'natural_images', 'natural_movie_one', 'spontaneous'

    # session_2_stim_types
    'natural_movie_one', 'natural_movie_two', 'spontaneous'



    all_rsquared_vals = []
    all_container_ids = []
    container_list_filt = get_container_list(structure_id,creline_id)

    #print 'length of container is ' + str(len(container_list_filt['id'].values))

    if len(container_list_filt['id'].values)!=0:
    #else:
        # loop over all containers (mice)

        for i in np.arange(len(container_list_filt['id'].values)):

            container_id = container_list_filt['id'].values[i]

            rsquared=get_plots (container_id, session_idx1, stim_type1, session_idx2, stim_type2)
            all_container_ids.append(container_id)
            all_rsquared_vals.append(rsquared)

    return all_rsquared_vals

