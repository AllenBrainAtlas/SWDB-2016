

import os
import numpy as np
import matplotlib.pyplot as plt
import pickle
import pylab
import seaborn as sns
sns.set(style="white")

import L4model_extraction_copy as getL4
import cobra_analysis



"""
Module to compare population coupling in L4 model data during two different visual stim.

Author: Madineh Sarvestani
Sept 2016
"""


def pc_values(spiketimes, spiketimes_all, indices_cont, time_start, time_end):

    """
    Calculates different population coupling metrics
    Inputs are the spiketimestamps and cell indices for stim 1 and stim 2
    Outputs are raw pop coupling vector, pop coupling vector based on shuffled spikes, shuffle normalized pop corr vector
    and z-scored normalized pop corr vector for each stim
    """

    pc= cobra_analysis.pop_corr_spikes(spiketimes, indices_cont,len(np.unique(indices_cont)), time_start,
                                                                        time_end)
    pc_zscored = cobra_analysis.pop_corr_spikes_z_scored(spiketimes, indices_cont,len(np.unique(indices_cont)), time_start,
                                                                            time_end)
    pc_shuffled = cobra_analysis.pop_corr_spikes_shuffled(spiketimes, indices_cont,len(np.unique(indices_cont)), time_start,
                                                                            time_end)
    pc_shufflescored = cobra_analysis.pop_corr_spikes_shuffle_scored(spiketimes, indices_cont,
                                                                            len(np.unique(indices_cont)), time_start,
                                                                            time_end)

    # population average is defined using global (10k) cells
    pc2 = cobra_analysis.pop_corr_spikes_all(spiketimes_all, spiketimes, indices_cont,
                                                  len(np.unique(indices_cont)), time_start, time_end)

    pc_zscored2 = cobra_analysis.pop_corr_spikes_z_scored_all(spiketimes_all, spiketimes, indices_cont,
                                                              len(np.unique(indices_cont)), time_start,
                                                              time_end)

    pc_shuffled2= cobra_analysis.pop_corr_spikes_shuffled_all(spiketimes_all, spiketimes, indices_cont,
                                                  len(np.unique(indices_cont)), time_start, time_end)


    pc_shufflescored2= cobra_analysis.pop_corr_spikes_shuffle_scored_all(spiketimes_all, spiketimes, indices_cont,
                                                  len(np.unique(indices_cont)), time_start, time_end)



    return pc, pc_zscored, pc_shuffled, pc_shufflescored, pc2, pc_zscored2, pc_shuffled2, pc_shufflescored2


def plot_hists(filename, pc_stim1, pc_stim2, pc_shuffled_stim1, pc_shuffled_stim2, pc_zscored_stim1, pc_zscored_stim2, pc_shufflescored_stim1, pc_shufflescored_stim2):
    """
    Produces side-by-side histograms of population coupling for each stim
    Inputs are population coupling matrices for each condition
    Outputs are histogram plots, uncomment print line to save the image.
    """
    fig, axs = plt.subplots(4, 2, figsize=(10, 5))
    axs = axs.ravel()


    axs[0].hist(pc_stim1)
    axs[0].set_ylabel('Count')
    axs[0].set_title('Stim1 PC')
    plt.tick_params(axis='y',which='both', top='off')
    axs[0].get_yaxis().set_ticks([])


    axs[2].hist(pc_zscored_stim1)
    axs[2].set_ylabel('Count')
    axs[2].set_title('Stim1 PC_zscored ')
    plt.tick_params(axis='y',which='both', top='off')
    axs[2].get_yaxis().set_ticks([])


    axs[4].hist(pc_shufflescored_stim1)
    axs[4].set_ylabel('Count')
    axs[4].set_title('Stim1 PC_shuffscored')
    plt.tick_params(axis='y',which='both', top='off')
    axs[4].get_yaxis().set_ticks([])


    axs[6].hist(pc_shuffled_stim1)
    axs[6].set_ylabel('Count')
    axs[6].set_xlabel('Pop Coupling')
    axs[6].set_title('Stim1 PC_shuffled')
    plt.tick_params(axis='y',which='both', top='off')
    axs[6].get_yaxis().set_ticks([])


    axs[1].hist(pc_stim2)
    axs[1].set_ylabel('Count')
    axs[1].set_title('Stim2 PC')
    plt.tick_params(axis='y',which='both', top='off')
    axs[1].get_yaxis().set_ticks([])



    axs[3].hist(pc_zscored_stim2)
    axs[3].set_ylabel('Count')
    axs[3].set_title('Stim2 PC_zscored')
    plt.tick_params(axis='y',which='both', top='off')
    axs[3].get_yaxis().set_ticks([])

    axs[5].hist(pc_shufflescored_stim2)
    axs[5].set_ylabel('Count')
    axs[5].set_title('Stim2 PC_shuffscored ')
    plt.tick_params(axis='y',which='both', top='off')
    axs[5].get_yaxis().set_ticks([])


    axs[7].hist(pc_shuffled_stim2)
    axs[7].set_xlabel('Pop Coupling')
    axs[7].set_ylabel('Count')
    axs[7].set_title('Stim1 PC_shuffled')
    plt.tick_params(axis='y',which='both', top='off')
    axs[7].get_yaxis().set_ticks([])


    plt.tight_layout()
    #pylab.savefig(filename+'.png')

    return




def plot_scatters(filename, pc_stim1, pc_stim2, pc_zscored_stim1, pc_zscored_stim2, pc_shufflescored_stim1, pc_shufflescored_stim2,
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


    #pylab.savefig(filename+'.png')

    return

def firing_rates(spiketimes1, indices1, spiketimes2, indices2):
    """
    Calculates firing rate of all cells under stimulus 1 and stimulus 2
    Inputs are: Spiketime and cell indices vector for each stimulus
    Outputs is firing rate vector for stim 1 and 2
    """

    #get total time
    time_start=max(min(spiketimes1),min(spiketimes2))
    time_end=min(max(spiketimes1),max(spiketimes2))
    total_time=float((time_end-time_start)/1000) # in seconds

    fr1=[]
    fr2=[]
    for i,ind in enumerate(np.unique(indices1)):
        fr1.append(len(np.argwhere(ind==indices1))/total_time)

    for i,ind in enumerate(np.unique(indices2)):
        fr2.append(len(np.argwhere(ind==indices2))/total_time)

    return fr1, fr2


def plot_firing(filename,pc_zscored1, spiketimes1, indices1, pc_zscored2, spiketimes2, indices2):
    """
    Plots firing rate vs. population coupling (z-scored) for both stimulus 1 and stimulus 2
    Inputs are: filename for the plot, and for each stim: pop coupling vector, spiketimes vector, and cell_indices vector
    Outputs is a side-by-side scatter plot for stim 1 and stim2 , uncomment print line to save the image.
    """
    #plot firing rate vs pc for stim 1 and stim 2

    fr1, fr2 = firing_rates(spiketimes1, indices1, spiketimes2, indices2)

    fig, axs = plt.subplots(1, 2, figsize=(10, 5))
    axs = axs.ravel()
    axs[0].scatter(fr1, pc_zscored1)
    axs[0].set_ylabel('Pop Coupling')
    axs[0].set_title('Firing Rate (1/s), Condition 1')

    axs[1].scatter(fr2, pc_zscored2)
    axs[1].set_ylabel('Pop Coupling')
    axs[1].set_title('Firing Rate (1/s), Condition 2')

    #pylab.savefig(filename+'.png')

    return


def get_plots(system,stim_type1, stim_type2, stim_id1, stim_id2,trial_id1, trial_id2, subset_cells_ids,include_recurrent):

    """
    Main function that calls other modules and functions to produce final plots

    # output plots
    # 1)distribution of three pop corrs for stim 1 and 2
    # 2)scatter plots for pop_corr zscored  stim1 vs stim2 coupled to lcoal
    # 3)scatter plots for pop_corr zscored stim1 vs stim2 coupled to global
    """


    filename1=system+'_'+stim_type1+'_'+stim_id1+'vs_'+stim_type2+'_'+stim_id2+'_hists'
    filename2=system+'_'+stim_type1+'_'+stim_id1+'vs_'+stim_type2+'_'+stim_id2+'_pc_zscored_local'
    filename4=system+'_'+stim_type1+'_'+stim_id1+'vs_'+stim_type2+'_'+stim_id2+'_firingrate'

    #get the spiketimes and indices for the first half (trials 0-4)
    spiketimes1, indices1,spiketimes1_all = getL4.send_output(system,
                                              stim_type1,
                                              stim_id1,
                                              trial_id1,
                                              subset_cell_ids,
                                              include_recurrent)

    #get the index of all cells that fired at least one spike
    stim1_firing_cells=np.unique(indices1)

    #get the spiketimes and indices for the second half (trials 5-9)
    trial_id2 = trial_id1
    spiketimes2, indices2,spiketimes2_all = getL4.send_output(system,
                                              stim_type2,
                                              stim_id2,
                                              trial_id2,
                                              subset_cell_ids,
                                              include_recurrent)

    # find the cells that fire under both stimuli
    stim1_firing_cells = np.unique(indices1)
    stim2_firing_cells = np.unique(indices2)

    both_stims_firing_cells = np.intersect1d(stim1_firing_cells, stim2_firing_cells)

    spiketimes1, indices1,spiketimes1_all = getL4.send_output(system,
                                              stim_type1,
                                              stim_id1,
                                              trial_id1,
                                              both_stims_firing_cells,
                                                include_recurrent)

    #get the index of all cells that fired at least one spike
    stim1_firing_cells=np.unique(indices1)

    #get the spiketimes and indices for the second half (trials 5-9)
    spiketimes2, indices2,spiketimes2_all = getL4.send_output(system,
                                              stim_type2,
                                              stim_id2,
                                              trial_id2,
                                              both_stims_firing_cells,
                                              include_recurrent)


    # max's population correlation analysis requires continuous spike indices, so make them continuous here

    # do it for the first stim
    indices_cont1 = np.zeros_like(indices1, dtype=int)
    for i_f, index in enumerate(np.unique(indices1)):
        indices_cont1[indices1 == index] = i_f

    # do it for the second stim
    indices_cont2 = np.zeros_like(indices2, dtype=int)
    for i_f, index in enumerate(np.unique(indices2)):
        indices_cont2[indices2 == index] = i_f


    #now get the various metrics of population coupling over a particular time_window
    time_start=max(min(spiketimes1),min(spiketimes2))
    time_end=min(max(spiketimes1),max(spiketimes2))

    pc1, pc_zscored1, pc_shuffled1, pc_shufflescored1, pc1_all, pc_zscored1_all, pc_shuffled1_all, pc_shufflescored1_all \
        = pc_values(spiketimes1, spiketimes1_all, indices_cont1, time_start, time_end)

    pc2, pc_zscored2, pc_shuffled2, pc_shufflescored2, pc2_all, pc_zscored2_all, pc_shuffled2_all, pc_shufflescored2_all \
        = pc_values(spiketimes2, spiketimes2_all, indices_cont2, time_start, time_end)


    #plot the histograms
    #plot_hists(filename1, pc1, pc2, pc_shuffled1, pc_shuffled2, pc_zscored1, pc_zscored2,
               #pc_shufflescored1, pc_shufflescored2)

    #plot local pairwise scatters for population average defined as local
    plot_scatters(filename2, pc1, pc2, pc_zscored1, pc_zscored2, pc_shufflescored1,
                      pc_shufflescored2,'PC (z-scored) Local Neighborhood')

    #plot pairwaise popcorr scatterts for population defined as global
    #plot_scatters(filename3, pc1_all, pc2_all, pc_zscored1_all, pc_zscored2_all, pc_shufflescored1_all,
                  #pc_shufflescored2_all, 'PC (z_scored) Global Neighborhood')

    plot_firing(filename4, pc_zscored1, spiketimes1, indices1, pc_zscored2, spiketimes2, indices2)



    # save data
    #fileObject = open(filename2, 'wb')
    #pickle.dump([pc_zscored1, pc_zscored2], fileObject)
    #fileObject.close()

    return



#define the conditions (stim type, etc) here:
include_recurrent=1 #don't shut down the cortex
ncells=500 #define random subset of cells, up to 9999. If you want all cells, run 'all'.
subset_cell_ids = np.random.permutation(10000)[0:ncells]

system='ll2'

stim_type1='gratings'
stim_id1= 'g7'
trial_id1= [0,1,2,3,4, 5, 6, 7, 8, 9]

stim_type2='natural_movies'
stim_id2= 'TouchOfEvil_frames_1530_to_1680'
trial_id2= [0,1,2,3,4, 5, 6, 7, 8, 9]


get_plots(system,stim_type1, stim_type2, stim_id1, stim_id2, trial_id1, trial_id2, subset_cell_ids,include_recurrent)
