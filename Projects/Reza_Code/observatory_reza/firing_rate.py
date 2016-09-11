drive_path = 'e:/'
import pandas as pd
import os
import numpy as np
from allensdk.core.brain_observatory_cache import BrainObservatoryCache
from allensdk.brain_observatory.static_gratings import StaticGratings
manifest_path = os.path.join(drive_path,'BrainObservatory/manifest.json')
print('rhftgrfrfg')
boc = BrainObservatoryCache(manifest_file=manifest_path)
# Pick an experiment container (:)--
experiment_container_v1_cux2 = boc.get_experiment_containers(targeted_structures=['VISp'],cre_lines=['Cux2-CreERT2'],imaging_depths=[275]);
#experiment_container_v1_cux2 = boc.get_experiment_containers(targeted_structures=['VISp'],cre_lines=['Cux2-CreERT2']);

# choose an animal
animal_number=0;
experiment_container_id = experiment_container_v1_cux2[animal_number]['id'];
experiment_information = boc.get_ophys_experiments(experiment_container_ids=[experiment_container_id]);
cell_specimen = boc.get_cell_specimens(experiment_container_ids=[experiment_container_id]);

#choose session ession B
session_id = experiment_information[1]['id']
data_set = boc.get_ophys_experiment_data(ophys_experiment_id= session_id)

# Get DG
from allensdk.brain_observatory.drifting_gratings import DriftingGratings
dg = DriftingGratings(data_set=data_set)

df = pd.read_csv('C:/Users/RezaEghbali/Dropbox/Reza_Code/anatoly_code/all_spikes_binary_file.csv')
del df['Unnamed: 0']
mat = df.values

fr = np.zeros((dg.stim_table.shape[0],df.shape[1]))
for i in range(len(dg.stim_table)):
    fr[i,:] = np.sum(mat[range(dg.stim_table.start[i],dg.stim_table.end[i]),:],axis = 0)

