# -*- coding: utf-8 -*-
"""
Created on Mon Aug 29 21:28:20 2016
Use Saskia's analysis files to get info without importing the whole freakin dataset.
@author: ttruszko
511510855
"""
from __future__ import print_function
#this is the same old thing, getting the cell specimen ids from the ophys_experiment_data...
from allensdk.core.brain_observatory_cache import BrainObservatoryCache
exp_id= 510705057
#this is session ID
boc = BrainObservatoryCache()

data_set = boc.get_ophys_experiment_data(exp_id)
csids = data_set.get_cell_specimen_ids()

# In[] this is Saskia's example code. Works as is but it's better to use the open_h5_file function. 
import h5py
import pandas as pd
#this loads the response array and the peak dataframe from the analysis file

## edit this for Mac!! And for whatever session you want.
path = 'D:/BrainObservatory/ophys_analysis/510705057_three_session_B_analysis.h5'
f = h5py.File(path, 'r')
response = f['analysis']['response_ns'].value
f.close()

sweep_response = pd.read_hdf(path, 'analysis/sweep_response_ns')
mean_sweep_response=pd.read_hdf(path, 'analysis/mean_sweep_response_ns')

# In[] Initialization. 
drive_path = 'd:/'
import numpy as np
import pandas as pd
import os
import sys
import matplotlib.pyplot as plt
import allensdk
from allensdk.core.brain_observatory_cache import BrainObservatoryCache
manifest_path = os.path.join(drive_path,'BrainObservatory/manifest.json')
boc = BrainObservatoryCache(manifest_file=manifest_path)
session_data=pd.DataFrame(boc.get_ophys_experiments(experiment_container_ids=[511510855], session_types=['three_session_B']))
data_set = boc.get_ophys_experiment_data(ophys_experiment_id = session_data.id.values[0])
cell_specimen_ids = data_set.get_cell_specimen_ids()

# In[]
#find the row that matches the cell of interest
cells_of_interest=[517510587, 517513474, 517513783, 517511451]
cell_idx=[]
for id in cells_of_interest:
    cell_idx.append(np.where(cell_specimen_ids==id)[0][0])
print(cell_idx)


# In[] Code for using the Natural Scenes object in the sdk. 
#my_cell_sweeps = sweep_response[cell_idx]
#get the stim table for natural scenes
stim_table = data_set.get_stimulus_table('natural_scenes')

my_cell_mean_sweeps=mean_sweep_response[str(cell_idx[3])]
plt.hist(my_cell_mean_sweeps, bins=1000)
#plt.show()
plt.clf()
plt.hist(mean_sweep_response, bins=1000)
# In[] plot the fluorescence trace for a single image. 
ts,fluor=data_set.get_corrected_fluorescence_traces()
fluor.shape
plt.figure() 
plt.plot(fluor[cell_idx[0]])

