

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
Module to compare population coupling in Ca data during two different visual stim.
Makes a scatter plot of the pop coupling of stim 1 vs stim 2 and calculates
the rsquared metric. Higher rsquared means population coupling is more invariant to visual stim type.

Author: Madineh Sarvestani
Sept 2016
"""


def pc_values(activity_matrix_1, activity_matrix_2):
    """
    Calculates population coupling
    Inputs are the activity_matrix (spike timestamps across time) for stim 1 and stim 2
    Outputs are population coupling, zscored
    """

    # population average is defined using local cell
    pc_zscored1 = cobra_analysis.pop_corr_z_scored(activity_matrix_1)
    pc_zscored2 = cobra_analysis.pop_corr_z_scored(activity_matrix_2)

    return pc_zscored1, pc_zscored2


def plot_hists(filename, pc_zscored_stim1, pc_zscored_stim2):
    """
    Produces side-by-side histograms of population coupling for each stim
    Inputs are population coupling matrices for each condition
    Outputs are histogram plots, uncomment print line to save the image.
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
    """
    Plots scatter given population coupling for two conditions
    Inputs are: Pop coupling_condition 1, Pop coupling_condition 2, title string for plot
    Outputs is a single scatter plot, uncomment print line to save the image.
    """


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


    #uncomment to save file
    #pylab.savefig(filename+'.png')

    return

def get_rsquared(x, y):
    """
    Polynomial regression to get rsquared from scatter plot of pop_corr 1 (stim 1) vs. pop_corr 2.
    Inputs are two population coupling vectors of equal length.
    Output is rsquared value.
    """

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

def get_plots (structure_id, cre_line, session_idx1, stim_type1, session_idx2, stim_type2,ind):
    """
    Main function that gets the observatory data given constraints, and call other functions that take care of extact-
    ing the data, calculating population correlations for each condition, calculating rsquared value, and producing plots.
    Inputs are structure_id (e.g. VISp), cre_line (e.g. Rorb-IRES2-Cre), session_idx1 and session_idx1 (e.g. 0, 1, or 2 which correspond
    to session A, B, or C),  and stim_type1 and stim_type2(e.g. drifting_gratings), ind (index of particular container
    id in the subset of container_ids that match given constraints).

    Output is rsquared value and the histogram and scatter plots.
    Uncomment lines to save data to pickle file.
    """


    container_list = allen_data_fetch.get_container_list()

    container_list_filt = container_list[(container_list['targeted_structure'] == structure_id) &
                                         (container_list['cre_line'] == cre_line)]


    #print container_list_filt

    container_id = container_list_filt['id'].values[ind]

    activity_matrix_1= allen_data_fetch.get_activity_matrix(
        container_id, session_idx1, stim_type1, units='all')

    activity_matrix_2 = allen_data_fetch.get_activity_matrix(
        container_id, session_idx2, stim_type2, units='all')


    pc_zscored1,pc_zscored2 = pc_values(activity_matrix_1, activity_matrix_2)

    filename1 = str(container_id) + '_' + str(session_idx1) + '_' + stim_type1 + 'vs_' + stim_type2 + '_hists'
    filename2 = str(container_id)+ '_' + str(session_idx1) + '_' + stim_type1 + 'vs_' + stim_type2 + '_pc_zscored_local'
    print 'filename is ' + filename2

    plot_hists(filename1, pc_zscored1, pc_zscored2)


    title_str='Pop Coupling Stim 1 vs Stim 2'
    plot_scatters(filename2, pc_zscored1, pc_zscored2,
                  title_str)

    #get rsqaured value
    pc_zscored1=np.reshape(pc_zscored1,(len(pc_zscored1,)))
    pc_zscored2=np.reshape(pc_zscored2,(len(pc_zscored2,)))

    rsquared = get_rsquared(pc_zscored1, pc_zscored2)

    # Uncomment below to pickle
    #fileObject = open(filename2, 'wb')
    #pickle.dump([pc_zscored1, pc_zscored2], fileObject)
    #fileObject.close()

    # call to extract data
    #with open('objs.pickle') as f:  # Python 3: open(..., 'rb')
        #obj0, obj1, obj2 = pickle.load(f)


    return rsquared



#Provide constraints
structure_id='VISp'
cre_line = 'Rorb-IRES2-Cre'
session_idx1=0
session_idx2=0
stim_type1='spontaneous' #choose from 'spontaneous', 'drifting_gratings', 'natural_scenes', or 'natural_movie_one'
stim_type2= 'natural_movie_three_2'
ind=1 #choose from all container_ids that match above constraints

rsquared=get_plots (structure_id, cre_line, session_idx1, stim_type1, session_idx2, stim_type2,ind)

print rsquared #this is for validation and testing