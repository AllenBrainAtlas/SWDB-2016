###########################
#
# Section: Prepare env
#
# #########################
## load package

from myfunctions import *

## cache
# for exp in experiment_ids:
#     exp_id = exp['id']
#     p = extract_feature(exp_id, stimulus_name=['drifting_gratings','static_gratings'], cache=False)
#     # pickle.dump(p, open('data/features-%d-gratings.pkl' % exp_id, "wb"))
#
#     print('%d done.'%exp_id)
##

experiment_id = int(sys.argv[1])
meta_data = boc.get_ophys_experiments(ids=[experiment_id])[0]

experiment_container_id = meta_data['experiment_container_id']
print("experiment %d with container id %d as an example." % (experiment_id, experiment_container_id))

data_set = boc.get_ophys_experiment_data(experiment_id)

# feature = pickle.load(open('data/features-%d-gratings.pkl' % experiment_id, "rb"))
feature = extract_feature(experiment_id, stimulus_name=['drifting_gratings','static_gratings'], cache=False)
pickle.dump(feature, open('data/features-%d-gratings.pkl' % experiment_id, "wb"))
#feature = pickle.load(open('data/features-%d-gratings.pkl' % experiment_id, "rb"))

##
print '\n'.join([var + '= feature["' + var + '"]' for var in feature.keys()])

metrics_names = feature["metrics_names"]
start_end = feature["start_end"]
speed_names = feature["speed_names"]
metrics = feature["metrics"]
stimulus_table = feature["stimulus_table"]
base_metrics = feature["base_metrics"]
base_metrics_names = feature["base_metrics_names"]
cell_ids = feature["cell_ids"]
speed = feature["speed"]

responsive_trail = (metrics[:, :, metrics_names['high_dff_max_ratio']] > 6) & \
                   (metrics[:, :, metrics_names['high_dff_frames_ratio']] > 0.15)
responsive_trail_count = responsive_trail.sum(axis=1)

##
scipy.io.savemat('data/features-%d-gratings.mat' % experiment_id,
                 {'start_end':np.array(start_end), 'responsive_bool':responsive_trail})
##
cell_specimens_df = pd.DataFrame(boc.get_cell_specimens())
good_cell = np.array(cell_ids.keys())[np.argsort(cell_ids.values())][
               responsive_trail_count > 5]
#good_cell = [cell for cell in good_cell if cell_specimens_df[cell_specimens_df.cell_specimen_id==cell].p_dg.values[0]<0.05]
##
np.savetxt('data/exp-%d_cell_id_subset.dat' % experiment_id, good_cell, fmt='%d')
##
np.savetxt('data/exp-%d_responsive_bool.dat' % experiment_id, responsive_trail, fmt='%d')
stimulus_table.to_csv('data/exp-%d_stimulus_table.dat' % experiment_id)
np.savetxt('data/exp-%d_cell_id.dat' % experiment_id, np.array(cell_ids.keys())[np.argsort(cell_ids.values())],
           fmt='%d')
##