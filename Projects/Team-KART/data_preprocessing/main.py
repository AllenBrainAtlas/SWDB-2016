# WARNING! Be sure to change the line that reads the .csv file, below, should be line 47
# If it doesn't work, you'll need to make the path point to your copy of that file (which should be in this folder)

# We need to import these modules to get started
import numpy as np
import pandas as pd
import os
import sys
import h5py
import matplotlib.pyplot as plt
from allensdk.core.brain_observatory_cache import BrainObservatoryCache


# The dynamic brain database is on an external hard drive.
# drive_path = '/Volumes/Brain2016'
# if sys.platform.startswith('w'):
# 	drive_path= 'd:'

def BOC_init(stimuli_to_use={
			'drifting_gratings',
			'locally_sparse_noise',
			'spontaneous',
			'static_gratings'
		},
		selectivity_csv_filename='image_selectivity_dataframe.csv',
		areas={
			'VISp'
		},
		discard_nan={
			'selectivity_ns',
			'osi_sg',
			'osi_dg',
			'time_to_peak_ns',
			'time_to_peak_sg',
		}
):
	""""Returns a BrainObservatoryCache initialized using the data on the external harddrives provided by the Allen Institute
Example usage:
	boc, specimens_with_selectivity_S, VISp_cells_with_numbers = BOC_init()

Input:
stimuli_stimuli_to_use : Which stimuli we are interested in. By default, this is
	['drifting_gratings', 'locally_sparse_noise', 'spontaneous', 'static_gratings']

selectivity_csv_filename : The path (including filename) to the image_selectivity_data.csv file. By default, this is just 'image_selectivity_dataframe.csv', which assumes that the file is in the same directory as the script you are running.

areas : We will restrict our attention to the areas in this list. By default this is the list ['VISp'], because we are visual cortex chauvanists here at the Allen Institute.

discard_nana : One of the outputs of this function is a dataframe that's been filtered to discard rows that have NaN values in the columns specified here.

Output:
	boc : the BrainObservatoryCache object from AllenSDK, initialized using the data from the external harddrive.

	specimens_with_selectivity_S : A dataframe the includes the output of boc.get_cell_specimens as well as a column for the selectivity index S
		See Decoding Visual Inputs From Multiple Neurons in the Human Temporal Lobe, J. Neurophys 2007, by Quiroga et al.

	VISp_cells_with_numbers : a dataframe that filters specimens_with_selectivity_S by discarding rows with NaN values in the columns specified above.
"""
	# The dynamic brain database is on an external hard drive.
	drive_path = '/Volumes/Brain2016'
	if sys.platform.startswith('w'):
		drive_path = 'd:'
	manifest_path = os.path.join(drive_path, 'BrainObservatory/manifest.json')
	boc = BrainObservatoryCache(manifest_file=manifest_path)
	expt_containers = boc.get_experiment_containers()

	all_expts_df = pd.DataFrame(boc.get_ophys_experiments(stimuli=list(stimuli_to_use)))
	# this has headers:
	# age_days	cre_line	experiment_container_id	id	imaging_depth	session_type	targeted_structure

	specimens_df = pd.DataFrame(
		boc.get_cell_specimens(experiment_container_ids=all_expts_df.experiment_container_id.values))
	# this has headers:
	# area	cell_specimen_id	dsi_dg	experiment_container_id	imaging_depth	osi_dg	osi_sg	p_dg	p_ns	p_sg
	# pref_dir_dg	pref_image_ns	pref_ori_sg	pref_phase_sg	pref_sf_sg	pref_tf_dg	time_to_peak_ns	time_to_peak_sg
	# tld1_id	tld1_name	tld2_id	tld2_name	tlr1_id	tlr1_name

	# There's also a handy bit of data from Saskia, in the form of a measurement called S. See
	# Decoding Visual Inputs From Multiple Neurons in the Human Temporal Lobe, J. Neurophys 2007, by Quiroga et al


	selectivity_S_df = pd.read_csv(selectivity_csv_filename, index_col=0)
	selectivity_S_df = selectivity_S_df[['cell_specimen_id', 'selectivity_ns']]

	specimens_with_selectivity_S = specimens_df.merge(selectivity_S_df, how='outer', on='cell_specimen_id')

	# This is all cells in VISp that have a value for the specified parameters (i.e not NaN)
	VISp_cells_with_numbers = specimens_with_selectivity_S
	for area_name in areas:
		VISp_cells_with_numbers = VISp_cells_with_numbers[VISp_cells_with_numbers.area == area_name]
	for col_name in discard_nan:
		VISp_cells_with_numbers = VISp_cells_with_numbers[np.isnan(VISp_cells_with_numbers[col_name]) == False]

	return boc, specimens_with_selectivity_S, VISp_cells_with_numbers

def get_sweep_responses_ns(expt_ids,analysis_directory = "BrainObservatory/ophys_analysis/", session = "B"):
	"""Reads cell sweep response from the h5 files on the external harddrive
Input:
	expt_ids : list of experiments to get responses for.

Output:
	sweep_responses : a dictionary with experiment ids as keys and sweep responses as values
	mean_sweep_responses : same as above, but with mean sweep responses."""
	# The dynamic brain database is on an external hard drive.
	drive_path = '/Volumes/Brain2016'
	sweep_responses = {}
	mean_sweep_responses = {}
	if sys.platform.startswith('w'):
		drive_path = 'd:'
	for e_id in expt_ids:
		path = os.path.join(drive_path,analysis_directory,str(e_id) + '_three_session_' + session + '_analysis.h5')
		# f = h5py.File(path)
		sweep_responses[e_id] = pd.read_hdf(path, 'analysis/sweep_response_ns')
		mean_sweep_responses[e_id] = pd.read_hdf((path, 'analysis/mean_sweep_responses_ns'))
	return sweep_responses, mean_sweep_responses

def get_container_id(cell_specimen_id, selectivity_S_df=None):
    """This function takes a cell specimen id and returns the experiment container it is in"""
    if selectivity_S_df == None:
        _,selectivity_S_df,_ = BOC_init()
    cell_record=selectivity_S_df.loc[selectivity_S_df['cell_specimen_id']==cell_specimen_id]
    exp_container_id=cell_record.iloc[0]['experiment_container_id']
    return(exp_container_id)

def get_session_id(exp_container_id, letter, boc=None):
    """This function takes a container id and returns the session id for letter = A,B, or C.""" 
    if boc is None:
        boc,_,_ = BOC_init()
    sessiontype=['three_session_'+str(letter)]
    session_data=pd.DataFrame(boc.get_ophys_experiments(experiment_container_ids=[exp_container_id], session_types=sessiontype))
    session_id=session_data['id'][0]
    return(session_id, session_data)
    
def open_h5_file(cell_specimen_id, drive_path, letter):
    exp_container_id = get_container_id(cell_specimen_id)
    session_id, session_data = get_session_id(exp_container_id, letter)
    path = drive_path + '/BrainObservatory/ophys_analysis/' + str(session_id) + '_three_session_B_analysis.h5'
    f = h5py.File(path, 'r')
    response = f['analysis']['response_ns'].value
    f.close()
    mean_sweep_response=pd.read_hdf(path, 'analysis/mean_sweep_response_ns')
    sweep_response = pd.read_hdf(path, 'analysis/sweep_response_ns')
    stim_table_ns = pd.read_hdf(path, 'analysis/stim_table_ns')
    return(response, mean_sweep_response, sweep_response, exp_container_id, session_id, session_data, stim_table_ns)



def hist_single_cell(cell_specimen_id, drive_path, letter, bins, boc=None):
    if boc==None:
        boc,_,_ = BOC_init()    
    response, mean_sweep_response, sweep_response, exp_container_id, session_id, session_data = open_h5_file(cell_specimen_id, drive_path, letter)
    data_set = boc.get_ophys_experiment_data(ophys_experiment_id = session_data.id.values[0])
    cell_specimen_ids = data_set.get_cell_specimen_ids()    
    cell_idx=np.where(cell_specimen_ids==cell_specimen_id)[0][0]
    cell_series = mean_sweep_response.iloc[:, cell_idx]     
    plt.hist(cell_series, bins=bins)
