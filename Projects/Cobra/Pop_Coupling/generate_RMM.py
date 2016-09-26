import synthetic_signals
import Okun_Shuffle
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

"""
Module to generate a raster of neural responses (T timebins X N cells) that match either two or three constrains
of the original neural raster:
1) firing rate of each cell is preserved
2) the overall population rate for all cells is preserved (up to a column re-shifting)
3) the coupling of each cell to the population is preserved

The generative model (raster marginalized model) is based off of Okun et al 2012 and 2015
The code is implemented from Michael Okun's matlab code.

Author: Madineh Sarvestani, modified from Michael Okun's code written in Matlab
Sept 2016
"""

def get_constraints(raster):
    """

    :param raster:
    :return:

    """

    n_cells = np.shape(raster)[1]
    n_T = np.shape(raster)[0]

    s = np.sum(raster, axis=0)  # firing_rate of each cell
    prd, temp = np.histogram(np.sum(raster, axis=1),
                             bins=np.arange(n_cells + 2))  # prd is population rate prd = histc(sum(raster), 0:N);
    ccpr = np.inner(np.sum(raster, axis=1), raster.T)


    constraints=[s,prd,ccpr]

    # check that sum(s) == sum((0:length(rd)-1).*rd)
    if (np.sum(s) != np.sum(np.arange(len(prd)) * prd)):
        print "Something is wrong, firing rate and population rate don't add up together"

    if (np.sum(prd * (np.arange(len(prd)) ** 2))) != np.sum(ccpr):
        print "Something is wrong, population firing rate doesn't add up"


    return constraints



def Ryser(ss,prd):
    n_cells = len(ss)
    n_T = sum(prd)

    if len(prd) < n_cells + 1:
        prd = np.append([prd], [np.zeros((1, n_cells + 1 - len(prd)))])

    Rc = np.cumsum(prd[::-1][0:-1])
    Rc = Rc[::-1]
    Rc = np.append([Rc], [np.zeros((1, n_cells - len(Rc)))])

    # Rc must dominate s, which is both required and sufficient for A to exist.
    if (np.cumsum(Rc) - np.cumsum(ss) < 0).any():  # this checks to see if the Rc curve ever falls below the ss curve
        Anew = []
        return

    # First we build matrix with the required column sums, with 1s in their topmost positions. Columns with more 1s are to
    #  the left.
    Anew = np.zeros((n_cells, n_T))

    for i in np.arange(len(prd), 1, -1):
        # I'm doing things this way because python understand an index of 0:-1 as all values instead of no values
        ind1 = np.sum(prd[i:])
        ind2 = np.sum(prd[i - 1:])
        if ind2 > ind1:
            Anew[:i - 1, ind1:ind2] = 1

    for r in np.arange(n_cells, 1, -1):  # for r = n:-1:2
        d = ss[r - 1] - np.sum(Anew[r - 1, :])
        rdC, temp = np.histogram(np.sum(Anew[:r, :], 0), bins=np.arange(r + 2))
        for j in np.arange(r - 1, 0, -1):  # j = r-1:-1:1
            if (rdC[j] >= d):
                Anew[j - 1, np.sum(rdC[j:]) - d: np.sum(rdC[j:])] = 0
                Anew[r - 1, np.sum(rdC[j:]) - d: np.sum(rdC[j:])] = 1
                break
            else:
                Anew[j - 1, np.sum(rdC[j + 1:]): np.sum(rdC[j:])] = 0
                Anew[r - 1, np.sum(rdC[j + 1:]): np.sum(rdC[j:])] = 1
                d = d - rdC[j]

    assert (np.sum(abs(np.sum(Anew, axis=1) - ss.T))) == 0, "Row marginals don't match!"
    rdA, temp = np.histogram(np.sum(Anew, axis=0), bins=np.arange(n_cells + 2))
    assert (np.sum(abs(prd - rdA))) == 0, "Column marginals don't match!"

    return Anew


def get_RMM_raster(raster):

    """

    :param raster:
    :return:
    """

    constraints = get_constraints(raster)
    s = constraints[0]
    prd = constraints[1]
    ccpr = constraints[2]

    ss = np.sort(s)[::-1]
    px = np.argsort(s)[::-1]
    px = px.argsort()  # now px is the permutation that takes ss to s (so ss(px) gives you original s)

    Anew = Ryser(ss, prd)

    if Anew.size == 0:
        return

    Anew = Anew[px, :].T
    Anew = Okun_Shuffle.kshuffle(Anew)

    return Anew


def get_cRMM_raster(raster):
    """
    :param raster:
    :return:
    """

    constraints = get_constraints(raster)
    s = constraints[0]
    prd = constraints[1]
    ccpr = constraints[2]

    n_cells = len(s)
    n_T = sum(prd)

    RMM_raster = get_RMM_raster(raster)
    cRMM_raster=RMM_raster.copy()

    prevStep = np.inf
    problemCounter = 0

    while True:
        if problemCounter > n_cells:
            print "cRMM: failed..."

        PR = np.sum(cRMM_raster, 1)
        ip = np.inner(PR, cRMM_raster.T)
        assert (problemCounter > 0 or prevStep > np.sum(abs(ip - ccpr))), "Something went wrong"
        prevStep = np.sum(abs(ip - ccpr))
        poor = np.flatnonzero(ccpr > ip + n_cells / 4)
        rich = np.flatnonzero(ccpr < ip - n_cells / 4)
        if (np.size(poor) == 0 or np.size(rich) == 0):
            break

        rich = rich[np.random.permutation(len(rich))[0]]
        poor = poor[np.random.permutation(len(poor))]

        for i in np.arange(len(poor) + 1):
            tempvar = cRMM_raster[:, poor[i]] * np.logical_not(cRMM_raster[:, rich])
            if tempvar.any():
                break

        if i == len(poor):
            problemCounter = problemCounter + 1
            continue

        poor = poor[i]  # pick a useful unit
        others = [x for x in np.arange(n_cells) if x not in np.array([poor, rich])]  # all other units

        shiftRows = np.ceil(np.min([ccpr[poor] - ip[poor], ip[rich] - ccpr[rich]]) / n_cells)

        loseValues = (np.sum(cRMM_raster[:, others], axis=1) + 1) * np.logical_not(cRMM_raster[:, rich]) * cRMM_raster[:, poor]
        gainValues = (np.sum(cRMM_raster[:, others], axis=1) + 1) * cRMM_raster[:, rich] * np.logical_not(cRMM_raster[:, poor])

        cutValue = np.min(loseValues[np.flatnonzero(loseValues > 0)])

        losePositions = np.where((loseValues > 0) & (loseValues <= cutValue))[0]
        gainPositions = np.flatnonzero(gainValues > cutValue)

        if np.size(gainPositions) == 0:
            problemCounter = problemCounter + 1
            continue

        shiftRows = np.min([shiftRows, len(losePositions), len(gainPositions)])

        losePositions = losePositions[np.random.permutation(len(losePositions))]
        gainPositions = gainPositions[np.random.permutation(len(gainPositions))]
        losePositions = losePositions[:shiftRows + 1]
        gainPositions = gainPositions[:shiftRows + 1]

        cRMM_raster[losePositions, rich] = 1
        cRMM_raster[losePositions, poor] = 0
        cRMM_raster[gainPositions, rich] = 0
        cRMM_raster[gainPositions, poor] = 1


    return RMM_raster, cRMM_raster


def check_constraints(raster,raster_model):
    """
    :param raster:
    :return:

    """

    constraints = get_constraints(raster)
    s = constraints[0]
    prd = constraints[1]
    ccpr = constraints[2]

    constraints = get_constraints(raster_model)
    s_model = constraints[0]
    prd_model = constraints[1]
    ccpr_model = constraints[2]

    n_cells=len(s)

    if (raster_model.ravel()[np.flatnonzero(raster)].all() != 1 and
            np.array_equal(s, s_model) and
            np.array_equal(np.sum(prd), np.sum(prd_model)) and
                len(np.argwhere(abs(ccpr - ccpr_model) > n_cells)) < 1):

        constraints_met=3
        print "All three constraints match."
        #print "the mean firing rate is " + np.str(np.mean(s) / (t_end / 1000))
       # print "the mean coupling to the pouplation is " + np.str(np.mean(ccpr))

    elif (raster_model.ravel()[np.flatnonzero(raster)].all() != 1 and
              np.array_equal(s, s_model) and
              np.array_equal(np.sum(prd), np.sum(prd_model))):
        constraints_met=2
        print "Only the first two constraints match (firing rate and population rate)."
        #print abs(ccpr_model - ccpr)

    else:
        constraints_met=0
        print " The first two constraints don't even match."
        #print abs(ccpr_model - ccpr)


    return constraints_met


def get_pairwise(raster_data, raster_model,sortby=1):
    """
    calculate pairwise pearson correlation coefficient matrices for the observed data raster of neuronal responses and
    for the generated RMM model raster of neuronal response.
    if the optional sortby variable is non-zero, sort the rows of the resulting pairwise  matrix by each neuron's coupling
    to population (ccpr).

    :param raster_data: binary raster (times x ncells) of neuronal responses for the data
    :param raster_model: binary raster (times x ncells) of model generated responses based on constraints to data
    :param sortby: default is 1, sorts rows of pairwise matrices by neuron's coupling to population
    :return: pairwise_data/model (ncells x ncells matrix of pairwise correlation coefficients), optionally sorted by ccpr
    """
    pairwise_data=np.corrcoef(raster_data,rowvar=0)
    pairwise_model=np.corrcoef(raster_model,rowvar=0)

    #unless we're specifically asked not to sort by ccpr, sort by ccpr
    if sortby!=0:
        constraints = get_constraints(raster_data)
        ccpr = constraints[2]
        ind=np.argsort(ccpr)[::-1]
        pairwise_data_sort=pairwise_data[ind][:,ind]

        constraints2 = get_constraints(raster_model)
        ccpr_model = constraints2[2]
        ind2 = np.argsort(ccpr_model)[::-1]
        #I'm not sure whether Okun et al. sorted the model generated pairwise matrix by the population coupling of the
        #data or the model. Here I'm doing data.
        pairwise_model_sort = pairwise_model[ind][:,ind]

    else:
        print "not sorting by ccpr"
        pairwise_data_sort = pairwise_data
        pairwise_model_sort = pairwise_model

    return pairwise_data_sort, pairwise_model_sort


def plot_pairwise(pairwise_data,pairwise_model,titlestr="Pairwise Corr Coeffs for Model (LT) and Data (UT)"):
    """
    :param pairwise_data: pairwise correlation coefficient matrix of observations (possibly sorted by each cell's
     coupling)
    :param pairwise_model: pairwise correlation coefficient matrix of model generated data(possibly sorted by each
     cell's coupling)
    :return: plots a single matrix with the pairwise data values on upper triangle and model values on lower
    """

    # now create a combined matrix that has the data on the upper diagonal and the model on the lower diagonal
    combined_pairwise = np.zeros_like(pairwise_data)
    n_cells = np.shape(pairwise_data)[0]
    ind_upper = np.triu_indices(n_cells, 1)
    ind_lower = np.tril_indices(n_cells, -1)
    combined_pairwise[ind_upper] = pairwise_data[ind_upper]
    combined_pairwise[ind_lower] = pairwise_model[ind_lower]

    # combined raster
    mask = np.zeros_like(pairwise_data, dtype=np.bool)
    mask[np.diag_indices_from(mask)] = True
    cmap = sns.diverging_palette(220, 10, as_cmap=True)  # Generate a custom diverging colormap

    f3, ax3 = plt.subplots(figsize=(7, 5))
    # Draw the heatmap with the mask and correct aspect ratio
    sns.heatmap(combined_pairwise, mask=mask, cmap=cmap,
                square=True, xticklabels=5, yticklabels=5,
                linewidths=.5, cbar_kws={"shrink": .5}, ax=ax3)
    plt.title(titlestr)
    plt.xlabel("cell no.")
    plt.ylabel("cell no.")

    plt.show()

    return


# #test script
# # 1) get raster by creating a synthetic spike train
# t_start=0
# t_end = 5000 #in microseconds
# n_cells = 50
# firing_rate= 20 # in spikes per second
# spike_times, cell_ids = synthetic_signals.generate_poisson_spike_train_population(n_cells, firing_rate,
#                                                                               correlation=5 * 0.08,
#                                                                               t_start=t_start,
#                                                                               t_stop=t_end,
#                                                                               seed=1 + 1000)
#
# #now make a binned (1 ms) and binarized raster to use for the shuffling
# raster_original = Okun_Shuffle.make_raster(spike_times, cell_ids, n_cells, t_start,t_end, dt_conv=1.0)
# raster=raster_original.copy()
#
# #2) load Okun's raster
# t_end = 5*60*1000 # in ms
# import h5py
# f = h5py.File('raster.mat','r')
# variables = f.items()
# for var in variables:
#     name = var[0]
#     data = var[1]
#     if type(data) is h5py.Dataset:
#         raster_big = data.value
#
# raster = raster_big[:,:]
#
# #generate a new raster from model
# raster_model = get_cRMM_raster(raster)
# constraints_met = check_constraints(raster,raster_model)
#
# #if constraints_met== 3:
# pairwise_data,pairwise_model = get_pairwise(raster,raster_model,sortby=1)
#
# plot_pairwise(pairwise_data,pairwise_model)
#
#
# #now plot!
# # Generate a mask for the upper triangle
# mask = np.zeros_like(pairwise_data, dtype=np.bool)
# mask[np.triu_indices_from(mask)] = True
# cmap = sns.diverging_palette(220, 10, as_cmap=True) # Generate a custom diverging colormap
#
#
# # Set up the matplotlib figure
# f1, ax = plt.subplots(figsize=(7, 5))
# # Draw the heatmap with the mask and correct aspect ratio
# sns.heatmap(pairwise_data, mask=mask, cmap=cmap, vmin=-0, vmax=0.3,
#             square=True, xticklabels=5, yticklabels=5,
#             linewidths=.5, cbar_kws={"shrink": .5}, ax=ax)
# plt.title("Data Raster Pairwise Corr Matrix")
# plt.xlabel("cell no.")
# plt.ylabel("cell no.")
#
# #second raster
# f2, ax2 = plt.subplots(figsize=(7, 5))
# # Draw the heatmap with the mask and correct aspect ratio
# sns.heatmap(pairwise_model, mask=mask, cmap=cmap, vmin=-0, vmax=0.3,
#             square=True, xticklabels=5, yticklabels=5,
#             linewidths=.5, cbar_kws={"shrink": .5}, ax=ax2)
# plt.title("Model Raster Pairwise Corr Matrix")
# plt.xlabel("cell no.")
# plt.ylabel("cell no.")
#
# plt.show()