drive_path = '/Volumes/Brain2016'

import os
import numpy as np
import pandas as pd


"""
Function to export spike series for a subset of cells in the L4 simulation data
The data is in a separate structure than the observatory data/allen SDK.
Madineh Sarvestani
Sept 2016
"""


def is_empty(any_structure):
    if any_structure:
        print('Structure is not empty.')
        return False
    else:
        print('Structure is empty.')
        return True

def split_at(s, c, n):
    words = s.split(c)
    return words[n]

def get_cells(system):
    # Read in cell properties (this is independent of everything except mouse id).
    output_path_cells = 'layer4_spikes/build/%s.csv' % (system)
    cells_file = os.path.join(drive_path, output_path_cells)
    cells_db = pd.read_csv(cells_file, sep=' ')
    # cells_db.head(n=10)

    # get the cell types so we can exclude GLIF cells
    cell_types = np.unique(cells_db['type'].values)
    # print 'Cell types: ', cell_types

    # Now exclude LIF cells
    biophyscells_db = cells_db[
        (cells_db['type'] == 'Nr5a1') | (cells_db['type'] == 'PV1') | (cells_db['type'] == 'PV2') |
        (cells_db['type'] == 'Rorb') | (cells_db['type'] == 'Scnn1a')]
    cell_types = np.unique(biophyscells_db['type'].values)
    # print 'Cell types: ', cell_types
    return cell_types, cells_db

def get_allstimids(system, stim_type):
    # look through the folder, and pick out all the filenames, extract stim id from those
    stimtype_path = os.path.join(drive_path, 'layer4_spikes/simulations_%s/%s/' % (system, stim_type))
    dirlist = [item for item in os.listdir(stimtype_path) if os.path.isdir(os.path.join(stimtype_path, item))]
    # print dirlist
    # later i need to include a check to make sure directory starts with 'output'

    all_stim_ids = []
    for i_d, dirname in enumerate(dirlist):
        # extract the stim_id from filename(filenames are 'output_systemname_stimulusname_trial_synapticfile_recurrent)
        all_stim_ids.append(split_at(dirname, '_', 2))

    return all_stim_ids




def get_series(system, stim_type, stim_id, trial_nums,
               subset_cell_ids, include_recurrent):


    # iterate across all trials of one grating type (g7) and all trials of the grating of orthogonal orientation
    # orientaiton jumps by 30 in this notoation (and each jump is 45 degrees, so add 60 to get the orthogonal orienation, all trials)


    #setup the option to grab all gratings
    if stim_id == 'all':
        all_stim_names = get_allstimids(system,stim_type)
    else:
        all_stim_names=stim_id

    series = np.array([])
    last_timestamp = 0
    count = 0


    for i_s, stim_name in enumerate(np.unique(all_stim_names)):
        all_series_list = []
        all_cell_ids_list = []
        for i_t, trial in enumerate(trial_nums):
            if include_recurrent == 0:
                print 'not using any connections'
                output_path = 'layer4_spikes/simulations_%s/%s/output_%s_%s_%d_sd278_LGN_only_no_con/' % (
                system, stim_type, system,
                stim_name, trial)
            else:
                output_path = 'layer4_spikes/simulations_%s/%s/output_%s_%s_%d_sd278/' % (system, stim_type, system,
                                                                                          stim_name, trial)

            # Read in spikes.
            spk_fname = os.path.join(drive_path, output_path, 'spk.dat')
            series = np.genfromtxt(spk_fname, delimiter=' ')  # series[:,0] are timepoints, series[:,1] are cell ids

            # how to append spike series arrays given that their times are different
            new_timestamps = series[:, 0] + last_timestamp + 1000  # leave 1 second between experiments
            last_timestamp = new_timestamps[-1] #time of last-spike from last trials

            all_series_list.append(new_timestamps)
            all_cell_ids_list.append(series[:, 1])
            # all_series[]

    all_spiketimestamps=np.hstack(all_series_list)
    all_cellids=np.hstack(all_cell_ids_list)

    series = np.vstack((all_spiketimestamps, all_cellids)).T

    cell_types, cells_db = get_cells(system)

    # Find the index of these biophysical cells, and pull out their spike times
    bp_spiketimes = np.array([])
    bp_indices = np.array([])
    for i_type, tmp_type in enumerate(cell_types):
        gids = cells_db[cells_db['type'] == tmp_type]['index'].values  # 'Global IDs', or gids of the neurons of this type.
        # Use a numpy trick to find indices of all elements (here, neuron IDs from 'series') that belong to the array 'gids'.
        # True/False mask
        tf_mask = np.in1d(series[:, 1], gids)
        # then series[tf_mask, 0] is the neuron-id and series[tf_mask, 1] is the spike time for all biophysical neurons
        bp_spiketimes = np.append(bp_spiketimes, series[tf_mask, 0])
        bp_indices = np.append(bp_indices, series[tf_mask, 1])

    # Now select a random subset of 100 cells from the indices


    if subset_cell_ids == 'all':
        ncells = 100000
        #unique_indices = np.unique(bp_indices)
        #subset_cell_ids = np.array([])
       # subset_cell_ids = unique_indices[np.random.permutation(len(unique_indices))[1:ncells]]
        subset_cell_ids = np.arange(ncells)
        subset_cell_ids = subset_cell_ids.astype(int)  # turn it into an int so the array can be used to index another array


    else:
        ncells=len(subset_cell_ids)


    # now get all spikes for each of these 100 cells (figure out how to do this using list comprehension)
    subset_bp_spiketimes = []
    subset_bp_nonspiking_indices = []
    subset_bp_indices=[]
    subset_bp_frates=[]
    for i, id1 in enumerate(subset_cell_ids):
        # find all instances of each cell id
        tmpinds = np.flatnonzero(bp_indices == id1)

        subset_bp_spiketimes= np.hstack((subset_bp_spiketimes , bp_spiketimes[tmpinds]))
        subset_bp_indices = np.hstack((subset_bp_indices, bp_indices[tmpinds]))

        subset_bp_spiketimes=subset_bp_spiketimes.astype(int)
        subset_bp_indices=subset_bp_indices.astype(int)


    # make sure all the cells are presented

    firing_ids = np.unique(subset_cell_ids)
    cell_ids = np.unique(subset_bp_indices)


    # so now i want to access the spikes from these 100 cells, and I want to create a matrix that has time on the 0th dimens
    # ion and ncells on the 1st dimension. First I need to sort all of the spikes according to the index.
    #sorted_indices = subset_bp_indices.argsort()
    sorted_indices = np.argsort(subset_bp_indices)
    spiketimes = subset_bp_spiketimes[sorted_indices]
    indices = subset_bp_indices[sorted_indices]

    firing_rate = len(spiketimes) / (ncells * 2.5)
    print(firing_rate)

    # #now plot the raster to check this out
    #fig, axs = plt.subplots(1)
    #plt.scatter(spiketimes, indices, s=5, lw=0)
    #plt.xlabel('Time (ms)')
    #plt.ylabel('Neuron ID')
    #plt.show()

    return spiketimes, indices,  bp_spiketimes


def send_output(system, stim_type, stim_id, trial_nums,
               subset_cell_ids, include_recurrent):
    '''
    System is the name of the mouse
    :param system:
    :param stim_type:
    :param stim_id:
    :param trial_nums:
    :param include_recurrent:
    :return:
    '''

    spiketimes, indices, spiketimes_all = get_series(system, stim_type, stim_id, trial_nums,
               subset_cell_ids, include_recurrent)

    return spiketimes,indices, spiketimes_all

#debug here

# system = 'll1'
# stim_type = 'gratings'
# stim_id = 'g7'
# trial_id = 0
# ncells = 10
#
# subset_cell_ids = np.random.permutation(10000)[0:ncells]
# subset_cell_ids = subset_cell_ids.astype(int)  # turn it into an int
# #
# spiketimes, indices = send_output(system,stim_type,stim_id,trial_id,subset_cell_ids)
# print(np.unique(indices))

#fig, axs = plt.subplots(1)
#plt.scatter(spiketimes, indices, s=5, lw=0)
#plt.xlabel('Time (ms)')
#plt.ylabel('Neuron ID')
#plt.show()