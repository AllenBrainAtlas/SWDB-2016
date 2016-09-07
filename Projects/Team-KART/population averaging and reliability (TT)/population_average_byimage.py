# -*- coding: utf-8 -*-
"""
Created on Wed Aug 31 16:12:32 2016

@author: ttruszko

This script will generate the analysis needed for generating the population response figure.

figure=average response of a whole experiment container to each image.
Repeat for each area.

generate average pop response for overlay.
"""

# In[]
# general initialization
from data_preprocessing import * 
boc, Selectivity_S_df, y = BOC_init(selectivity_csv_filename='C:\\Users\\ttruszko\\Documents\\GitHub\\SWDB-KART\\image_selectivity_dataframe.csv')    
import pandas as pd

# In[]
# new function to get h5 file data
def open_h5_file_sessionID(session_id, drive_path, letter):
    #session_id, session_data = get_session_id(exp_container_id, letter)
    path = drive_path + '/BrainObservatory/ophys_analysis/' + str(session_id) + '_three_session_B_analysis.h5'
    print(path)    
    f = h5py.File(path, 'r')
    response = f['analysis']['response_ns'].value
    f.close()
    mean_sweep_response=pd.read_hdf(path, 'analysis/mean_sweep_response_ns')
    sweep_response = pd.read_hdf(path, 'analysis/sweep_response_ns')
    stim_table_ns = pd.read_hdf(path, 'analysis/stim_table_ns')
    return(response, mean_sweep_response, sweep_response, stim_table_ns)
    
# In[]
# generate and save mean population response for each expt container for each image
    
targeted_structures = boc.get_all_targeted_structures()
#targeted_structure=targeted_structures[3]     
expt_cont_list = pd.DataFrame(boc.get_experiment_containers())
#expt_cont_ids=[511511015, 511510733]
mean_bystructure=[]
for struct in targeted_structures:
    expt_cont_VISlist=expt_cont_list[expt_cont_list['targeted_structure']==struct]
    expt_cont_ids=expt_cont_VISlist['id'].unique()
    mean_by_container=[]    
    for cont_id in expt_cont_ids:
        session_id, session_data=get_session_id(cont_id, 'B', boc=boc)
        response, mean_sweep_response, sweep_response, stim_table_ns = open_h5_file_sessionID(session_id, 'd:', 'B') 
        
        mean_sweep_response_nd = mean_sweep_response.values 
        mean_perstim=[] 
        img_ids = sorted(stim_table_ns['frame'].unique())
        
        for stim_num in img_ids:
            img_idx=stim_table_ns['frame']==stim_num
            all_img_data=mean_sweep_response[img_idx]
            small_mean=all_img_data.mean()
            big_mean=small_mean.mean()
            mean_perstim.append(big_mean)
        print('container id: ', cont_id)
        mean_by_container.append(mean_perstim)    
    mean_bystructure.append(mean_by_container)

# save 
list_of_dicts = [{'area':area, 'list_of_arrays':np.asarray(tuple(A))} for area, A in zip(targeted_structures, mean_bystructure)]
np.save('mean_of_mean_population', list_of_dicts)
# In[]
#testing area 

# In[]
#make a plot for each structure

import matplotlib.pyplot as plt
plt.rcParams.update({'font.size': 30})  
tuple_list = [(i, j) for i in range(2) for j in range(2)]
idx=[0, 1, 2, 3]
fig, axes = plt.subplots(2,2)
#axes.set_yticks([])
#axes.yaxis.set_ticklabels([])
for t, d, i in zip(tuple_list, list_of_dicts, idx):
    traces=d['list_of_arrays'].T
    axes[t[0], t[1]].plot(traces + 2 * np.arange(traces.shape[1]).reshape(1,traces.shape[1]), color='g', linewidth=2)
    axes[t[0], t[1]].set(ylabel = 'Pop Mean Sweep Response', xlabel='Image Number', title=d['area'])
    axes[t[0], t[1]].plot(grand_mean[i] + -2, color='k', linewidth=5)
    axes[t[0], t[1]].axvline(x=31)
    axes[t[0], t[1]].set_yticks([])

plt.suptitle('Mean of Mean Population Response')
  
# In[]
# Remove one experiment that is really variable from VISal

#popmean_corrected_VISal = list_of_dicts{'area'='VISal', 'list_of_arrays'=[0,1,2,3,4,5,6,7,9,10,11,12,13,14,15,16]}  
test=list_of_dicts[area == 'VISal']
VISal_array=test['list_of_arrays']
VISal_list_corrected= np.delete(VISal_array, 8, 0)

test['list_of_arrays']=VISal_list_corrected
list_of_dicts[0]['list_of_arrays']=VISal_list_corrected

# In[]
# Generate mean of each structure to get a sense of images liked/disliked
grand_mean=[]
for i in range(len(list_of_dicts)):
    grand_mean.append(np.mean(list_of_dicts[i]['list_of_arrays'], axis=0))

# In[]
# locate images that a structure really cares about
image_w_popresponse=[]
for i in range(len(grand_mean)):
    image_locs= grand_mean[i] # > np.mean(grand_mean[i], axis=1)
    #image_w_popresponse.append()
# In[]
# Gather info about variability. 

# replicate for loop above:
targeted_structures = boc.get_all_targeted_structures()
#targeted_structure=targeted_structures[3]     
expt_cont_list = pd.DataFrame(boc.get_experiment_containers())
#expt_cont_ids=[511511015, 511510733]

#mean_bystructure=[]
all_sorted_img_responses=[]
all_bycell_mean=[]
for struct in targeted_structures:
    expt_cont_VISlist=expt_cont_list[expt_cont_list['targeted_structure']==struct]
    expt_cont_ids=expt_cont_VISlist['id'].unique()
    
    mean_by_container=[] 
    sorted_img_responses=[]
    cell_means_byimage=[]
    for cont_id in expt_cont_ids:
        session_id, session_data=get_session_id(cont_id, 'B', boc=boc)
        _, mean_sweep_response, _, stim_table_ns = open_h5_file_sessionID(session_id, 'd:', 'B') 
        
        mean_sweep_response_nd = mean_sweep_response.values 
        #mean_perstim=[] 
        img_responses=[]
        bycell_mean=[]  
        all_img_data=[]
        img_ids = sorted(stim_table_ns['frame'].unique())
        
        for stim_num in img_ids:
            img_idx=stim_table_ns['frame']==stim_num
            all_img_data=mean_sweep_response[img_idx]
            img_responses.append(all_img_data)
            bycell_mean.append(np.mean(all_img_data, axis=0).tolist())
            #bycell_mean[img_idx]=np.mean(all_img_data, axis=0)
            #bycell_mean
            all_img_data.append(mean_sweep_response[img_idx])
            #print('stim num: ', stim_num)
        print('container id: ', cont_id)
        sorted_img_responses.append(img_responses)
        cell_means_byimage.append(bycell_mean)
                
        #mean_by_container.append(mean_perstim)    
    all_sorted_img_responses.append(sorted_img_responses)
    all_bycell_mean.append(cell_means_byimage)
    #mean_bystructure.append(mean_by_container)

#save. But this saves it in a weird format that kinda sucks. 
raw_population_MSR = [{'area':area, 'SortedImgReponses':np.asarray(tuple(A)), 'mean_bycell_perimg':np.asarray(tuple(B))} for area, A, B in zip(targeted_structures, all_sorted_img_responses, all_bycell_mean)]
np.save('raw_population_MSR.csv', raw_population_MSR)    
#do some statistics