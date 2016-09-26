import numpy as np
import sympy
from scipy.ndimage.filters import gaussian_filter1d
import matplotlib.pyplot as plt

import synthetic_signals
#import L4model_extraction_copy as getL4

"""
Module to produce a shuffled activity matrix (N cells x T timebins) using Kshuffling in Okun et al 2015
Author: Madineh Sarvestani, modified from Michael Okun's code written in Matlab
Sept 2016
"""



def make_raster(spike_times, cell_ids, n_cells, t_start,t_end, dt_conv=1.0):

    # Currently, the population corr analysis module requires continuous cell indices, so here we
    # change the index to make it continuous. This doesn't change anything important.
    indices_cont = np.zeros_like(cell_ids, dtype=int)
    for i_f, index in enumerate(np.unique(cell_ids)):
        indices_cont[cell_ids == index] = i_f


    # First we'll reshape and binarize the activity matrix (1 ms bins) to form a binary raster of time-by-N dimensions
    # then we'll use code below to shuffle
    n_bins = int((t_end - t_start) / dt_conv)
    binary_activity_matrix = np.zeros((n_bins, n_cells))
    bins = np.linspace(t_start, t_end, n_bins + 1)

    for i in range(n_cells):
        indices = indices_cont == i
        temp_hist = np.histogram(spike_times[indices], bins=bins)[0].astype(float)
        binary_activity_matrix[np.argwhere(temp_hist), i] = 1

    return binary_activity_matrix


def kshuffle(A):
    """
    A function for shuffling a (binned and binarized) raster of neural responses.
    At the limit a uniform sample from a distribution subject to the constraints on the mean firing rate and population
    rate distribution of the original data (See Okun et al. 2012 for discussion).

    Input: A - a 0/1 matrix of time-by-N dimensions (N=no. of spike trains)
    Output: A - the same matrix shuffled
    The function performs what is called "spike exchange across neurons"
    shuffling.

    This shuffling should preserve the total number of spikes for each neuron (row marginals,aka sum across rows), and
    it should also preserve the total population rate (column marginals, aka sum across columns). So a good test of the
    shuffling is to check that the row and column marginals post-shuffling match those pre-shuffling.

    :param raster:
    :return:
    """

    N = np.shape(A)[1]  # number of cells
    for i in np.arange(10 * sympy.binomial(N, 2)):  # go through all permuations

        A= A.copy()

        c = np.random.permutation(N)[0:2]  # randomly select two columns (two cells)
        I = np.zeros_like(A[:, c[0]])
        I[np.where(A[:, c[0]] + A[:, c[1]] == 1)] = 1  # find where the cell's dont fire (or not-fire) together

        cA = A[np.argwhere(I == 1), [c[0], c[1]]]
        i01 = np.argwhere(np.asarray(cA[:, 0]) == 0)
        i10 = np.argwhere(np.asarray(cA[:, 0]) == 1)

        toFlip = np.ceil(np.min([len(i01), len(i10)]) / 2.0)  # number of 0s and 1s to flip

        i01 = i01[np.random.permutation(len(i01))]
        i01 = i01[0:toFlip]
        i10 = i10[np.random.permutation(len(i10))]
        i10 = i10[0:toFlip]

        # now to the flip
        cA[i01, 0] = True
        cA[i01, 1] = False
        cA[i10, 0] = False
        cA[i10, 1] = True

        A[np.argwhere(I == 1), [c[0], c[1]]] = cA
    return A


#so now i need code that'll take the raster and shuffled raster and give me poplation correlations!
def pop_corr_spikes(raster,shuffled_raster,t_start,t_end):
    """
    Returns distribution of population correlations for input raster and input shuffled raster. Also returns
    the population correlations normalized to the median of the input shuffled raster!

    :return:
    """
    n_cells=np.shape(raster)[1]
    n_bins=np.shape(raster)[0]
    total_time=t_end-t_start
    bins = np.linspace(t_start, t_end, n_bins + 1)

    #start with the raster, whch we'll smooth with a gaussian
    sigma_conv = 12 / np.sqrt(2)
    dt_conv = 1 #ms
    sigma = sigma_conv / dt_conv

    activity_matrix = np.zeros((n_bins, n_cells))
    shuffled_activity_matrix = np.zeros((n_bins, n_cells))

    #remove the firing rate for each cell
    fr_ms = np.zeros(n_cells)
    shuffled_fr_ms=np.zeros(n_cells)
    for i in range(n_cells):
        fr_ms[i] = len(np.argwhere(raster[:,i]==1))/float((total_time))
        shuffled_fr_ms[i] = len(np.argwhere(shuffled_raster[:,i]==1))/float((total_time))

        activity_matrix[:, i] = gaussian_filter1d(np.histogram(bins[np.where(raster[:,i])], bins=bins)[0].astype(float), sigma=sigma)
        shuffled_activity_matrix[:, i] = gaussian_filter1d(np.histogram(bins[np.where(shuffled_raster[:, i])], bins=bins)[0].astype(float),
                                              sigma=sigma)

    activity_matrix_mean_adj = activity_matrix - fr_ms
    shuffled_activity_matrix_mean_adj = shuffled_activity_matrix - shuffled_fr_ms

    sum_mean_adj = activity_matrix_mean_adj.sum(axis=1)
    shuffled_sum_mean_adj = shuffled_activity_matrix_mean_adj.sum(axis=1)

    pop_corr_array = np.zeros((n_cells, 1))
    shuffled_pop_corr_array = np.zeros((n_cells, 1))
    for i in range(n_cells):
        cell_excluded_sum_mean_adj = sum_mean_adj - activity_matrix_mean_adj[:, i]
        shuffled_cell_excluded_sum_mean_adj = shuffled_sum_mean_adj - shuffled_activity_matrix_mean_adj[:, i]

        pop_corr_array[i] = np.sum(activity_matrix[:, i] * cell_excluded_sum_mean_adj) \
                            / (fr_ms[i] * (t_end - t_start))

        shuffled_pop_corr_array[i] = np.sum(shuffled_activity_matrix[:, i] * shuffled_cell_excluded_sum_mean_adj) \
                            / (shuffled_fr_ms[i] * (t_end - t_start))



    #now normalize the pop_corr_array to the median of the shuffled_pop_corr_array
    med_shuffled_popcorr = np.median(shuffled_pop_corr_array[~np.isnan(shuffled_pop_corr_array)])
    print med_shuffled_popcorr
    pop_corr_array_shuffle_scored = pop_corr_array/ med_shuffled_popcorr
    shuffled_pop_corr_array_shuffle_scored = shuffled_pop_corr_array / med_shuffled_popcorr

    return pop_corr_array, shuffled_pop_corr_array, pop_corr_array_shuffle_scored, shuffled_pop_corr_array_shuffle_scored

def plot_hists(pop_corr_array, shuffled_pop_corr_array, pop_corr_array_shuffle_scored, shuffled_pop_corr_array_shuffle_scored):
    """
    Plots the distribution of the raw and shuffle scored population correlation array, and population correlation array of shuffled spikes

    :return:
    """
    # plot the histograms
    fig, axs = plt.subplots(2, 2, figsize=(10, 5))
    axs = axs.ravel()

    axs[0].hist(pop_corr_array)
    axs[0].set_ylabel('Count')
    axs[0].set_title('Pop Corr')
    plt.tick_params(axis='y', which='both', top='off')
    axs[0].get_yaxis().set_ticks([])

    axs[1].hist(shuffled_pop_corr_array)
    axs[1].set_ylabel('Count')
    axs[1].set_title('Pop Corr of Shuffled Spikes')
    plt.tick_params(axis='y', which='both', top='off')
    axs[1].get_yaxis().set_ticks([])


    axs[2].hist(pop_corr_array_shuffle_scored)
    axs[2].set_ylabel('Count')
    axs[2].set_title('Pop Corr Shuffle Scored ')
    plt.tick_params(axis='y', which='both', top='off')
    axs[2].get_yaxis().set_ticks([])

    axs[3].hist(shuffled_pop_corr_array_shuffle_scored)
    axs[3].set_ylabel('Count')
    axs[3].set_title('Shuffled Pop Corr Shuffle Scored ')
    plt.tick_params(axis='y', which='both', top='off')
    axs[3].get_yaxis().set_ticks([])

    #now plot both on the same axis
    fig = plt.subplots(1, 1, figsize=(10, 5))
    plt.hist(pop_corr_array_shuffle_scored, alpha=0.5,color = 'red', label='Pop Corr (shuffle normed) Data')
    plt.hist(shuffled_pop_corr_array_shuffle_scored, alpha=0.5, color = 'black', label='Pop Corr (shuffle normed) Shuffled Data')
    plt.legend(loc='upper right')

    plt.tight_layout()
    plt.show()

    return

# test code

# #create a synthetic spike train
# t_start=0
# t_end = 1000 #in mseconds
# n_cells = 10
# spike_times, cell_ids = synthetic_signals.generate_poisson_spike_train_population(n_cells, 100,
#                                                                               correlation=2 * 0.08,
#                                                                               t_start=t_start,
#                                                                               t_stop=t_end,
#                                                                               seed=1 + 1000)
#
#
# #now make a binned (1 ms) and binarized raster to use for the shuffling
# raster = make_raster(spike_times, cell_ids, n_cells, t_start,t_end, dt_conv=1.0)
#
# raster_original=raster.copy()
#
# # now shuffle it
# shuffled_raster = kshuffle(raster)
#
# # now check to see if the shuffling is correct by checking the row and column marginals
# if  (shuffled_raster.ravel()[np.flatnonzero(raster)].all() != 1 and
#      np.sum(shuffled_raster, axis=0).all() == np.sum(raster_original, axis=0).all() and
#      np.sum(shuffled_raster, axis=1).all() == np.sum(raster_original, axis=1).all()):
#
#     print 'Rasters are not identical &  both marginals match, the shuffling is right!'
#
# # now get the pop corr array, the shuffled pop corr array, and the shuffle scored pop corr array and plot their dist
# pop_corr_array, shuffled_pop_corr_array, pop_corr_array_shuffle_scored, shuffled_pop_corr_array_shuffle_scored\
#     = pop_corr_spikes(raster,shuffled_raster,t_start,t_end)
#
# #now plot hists
# plot_hists(pop_corr_array, shuffled_pop_corr_array, pop_corr_array_shuffle_scored, shuffled_pop_corr_array_shuffle_scored)
# # now try it on L4 model data



# #define the conditions (stim type, etc) here:
# include_recurrent=1 #don't shut down the cortex
# n_cells=200 #define random subset of cells, up to 9999. If you want all cells, run 'all'.
# subset_cell_ids = np.random.permutation(10000)[0:n_cells]
# trial_id1= [0,1]
# system='ll1'
# stim_type='gratings'
# stim_id= 'g7'
#
# spike_times, cell_ids, spiketimes_all = getL4.send_output(system,stim_type, stim_id,trial_id1,subset_cell_ids,include_recurrent)
# t_start = max(min(spike_times), min(spike_times))
# t_end = min(max(spike_times), max(spike_times))
#
# #now make a binned (1 ms) and binarized raster to use for the shuffling
# raster = make_raster(spike_times, cell_ids, n_cells, t_start,t_end, dt_conv=1.0)
# raster_original = raster.copy()
#
# # now shuffle it
# shuffled_raster = kshuffle(raster)
# print 'the shuffling is slow, but finally done'
#
# # now check to see if the shuffling is correct by checking the row and column marginals
# if  (shuffled_raster.ravel()[np.flatnonzero(raster)].all() != 1 and
#      np.sum(shuffled_raster, axis=0).all() == np.sum(raster_original, axis=0).all() and
#      np.sum(shuffled_raster, axis=1).all() == np.sum(raster_original, axis=1).all()):
#
#     print 'Rasters are not identical &  both marginals match, the shuffling is right!'
#
# # now get the pop corr array, the shuffled pop corr array, and the shuffle scored pop corr array and plot their dist
# pop_corr_array, shuffled_pop_corr_array, pop_corr_array_shuffle_scored, shuffled_pop_corr_array_shuffle_scored\
#     = pop_corr_spikes(raster,shuffled_raster,t_start,t_end)
#
# #now plot hists
# #get rid of nans arising from cells which never spiked
# plot_hists(pop_corr_array[~np.isnan(pop_corr_array)],
#            shuffled_pop_corr_array[~np.isnan(shuffled_pop_corr_array)],
#            pop_corr_array_shuffle_scored[~np.isnan(pop_corr_array_shuffle_scored)],
#            shuffled_pop_corr_array_shuffle_scored[~np.isnan(shuffled_pop_corr_array_shuffle_scored)])