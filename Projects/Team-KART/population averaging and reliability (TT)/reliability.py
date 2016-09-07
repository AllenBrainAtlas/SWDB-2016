# -*- coding: utf-8 -*-
"""
Created on Fri Sep 02 16:11:22 2016
This script generates the reliability measure for every cell (# responses/# stim presentations).
Cutoff of 0.1 (5/50 responses) eliminated 75% of data, which is probably a problem. 

@author: ttruszko
"""
# In[]
# general initialization
from data_preprocessing import * 
boc, Selectivity_S_df, y = BOC_init(selectivity_csv_filename='C:\\Users\\ttruszko\\Documents\\GitHub\\SWDB-KART\\image_selectivity_dataframe.csv')    
import pandas as pd
# seaborn is a package to make the matplotlib figures nice.
import seaborn as sns
sns.set_context("notebook", font_scale=6.5,rc={"lines.linewidth": 6.5})

drive_path='d:'
manifest_path = os.path.join(drive_path,'BrainObservatory/manifest.json')
boc = BrainObservatoryCache(manifest_file=manifest_path)


# In[]
def open_h5_file_sessionID(session_id, drive_path, letter):
'''This script takes the session ID, the drive path and the Session letter and returns the data contained
in the h5 file for that session.
session_id can be gathered from get_session_id
drive_path = 'd' for windows, /volumes for mac
letter should be a string, 'A', 'B' or 'C' '''
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
# Get data from the h5 files

targeted_structures = boc.get_all_targeted_structures()     
expt_cont_list = pd.DataFrame(boc.get_experiment_containers())

all_raw_reliability=[]
for struct in targeted_structures:
    expt_cont_VISlist=expt_cont_list[expt_cont_list['targeted_structure']==struct]
    expt_cont_ids=expt_cont_VISlist['id'].unique()
    #print(expt_cont_VISlist)
    #print(expt_cont_ids)
    
    expcont_raw_reliability=[]
    for cont_id in expt_cont_ids:
        session_id, session_data = get_session_id(cont_id, 'B', boc=boc)
        print(session_id)
        response, _, _, _ = open_h5_file_sessionID(session_id, 'd:', 'B')

        raw_reliability=response[:,:,2] / 50

        #keep_reliability = raw_reliability > 0
        keep_reliability_5 = raw_reliability >= 0.1
        raw_reliability[~keep_reliability_5] = np.nan
        expcont_raw_reliability.append(raw_reliability)
        raw_reliability=[]
        keep_reliability_5=[]
    all_raw_reliability.append(expcont_raw_reliability)

# In[]
# take mean of all_raw_reliability 
mean_reliability_struct=[4, ]
for i in range(len(all_raw_reliability)):
    for j in range(len(all_raw_reliability[i])):
        mean_reliability_struct[i,j].append(np.nanmean(all_raw_reliability[i][j], axis=1))

# In[]
# calculate mean and sem of reliability across structures. 

area_mean_reliability = {}
mean_reliability = {}
area_sem_reliability = {}
for area in range(len(all_raw_reliability)):
    tmp=[]
    for expt in range(len(all_raw_reliability[area])):
        across_images_mean = np.nanmean(all_raw_reliability[area][expt], axis=1)
        tmp.append(across_images_mean)
        mean_reliability[targeted_structures[area]] = tmp
    area_mean_reliability[targeted_structures[area]] = np.nanmean(mean_reliability[targeted_structures[area]],axis=0)
    sem = np.std(mean_reliability[targeted_structures[area]],axis=0)/np.sqrt(len(mean_reliability[targeted_structures[area]]))    
    area_sem_reliability[targeted_structures[area]] = sem
# In[]
# plot the mean and sem of reliability across structures.
    
n_images = area_sem_reliability['VISl'].shape[0]
x_range = np.arange(0,n_images)
fig,ax=plt.subplots()
colors = ['r','g','b','purple']
for i,area in enumerate(targeted_structures):
    ax.errorbar(x=x_range,y=area_mean_reliability[area],yerr=area_sem_reliability[area],label=area)
ax.legend(loc='best', ncol=4)
ax.set_xlabel('Image Number')
ax.set_ylabel('Mean Reliability Across Populations')
ax.set_title('Mean Reliability over visual structures')
# In[]
#Plot a single experiment container mean across images, sorted from low to high.

fig, ax = plt.subplots(1, 1)
ax.plot(np.sort(np.nanmean(all_raw_reliability[0][0], axis=1)), 'o', markersize=20, color = 'steelblue')
ax.set_ylabel('Mean Reliability')
ax.set_xlabel('Images')
ax.set_title('Sorted Mean Reliability for one experiment container')

#reacquire a raw set of data - only necessary if you've already run the code to remove a portion of the data.
expt_cont_ids=[511510733] # choose a random container id.
for cont_id in expt_cont_ids:
    session_id, session_data = get_session_id(cont_id, 'B', boc=boc)
    print(session_id)
    response, _, _, _ = open_h5_file_sessionID(session_id, 'd:', 'B')
    raw_reliability=response[:,:,2] / 50

# plot a histogram of raw reliability        
plt.hist(raw_reliability[~np.isnan(raw_reliability)], bins=100)
plt.xlabel('Reliability')
plt.ylabel('Counts')
plt.axvline(x=0.1)
plt.title('Reliability per cell per image for one experiment container')

# In[]
# figure out how many presentations I ditched by using 0.1 cutoff

nan_fraction = {}
for area in range(len(all_raw_reliability)):
    tmp=[]
    for expt in range(len(all_raw_reliability[area])):
        nans = np.where(np.isnan(all_raw_reliability[area][expt])==True)[0].shape[0]
        total = all_raw_reliability[area][expt].shape[0]*all_raw_reliability[area][expt].shape[1]
        tmp.append(nans/float(total))
    nan_fraction[area] = np.mean(tmp)
  
