import pickle
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import gridspec
import json

# Check coordinates of the source to find the one close to (0, 0).  Use it
# for illustration of the dynamics of traveling waves near the center of the system.
'''
f = open('tw_data/ll1_tw_build/tw_src_0/sources.pkl', 'r')
#f = open('tw_data/ll2_tw_build/2_tw_src/sources.pkl', 'r')
src_dict = pickle.load(f)
f.close()

# Sources coordinates.
x_src = []
y_src = []
for src_id in src_dict:
  x_src.append(src_dict[src_id]['x'])
  y_src.append(src_dict[src_id]['y'])
x_src = np.array(x_src)
y_src = np.array(y_src)

ind = np.intersect1d(np.where(np.abs(x_src) < 15.0), np.where(np.abs(y_src) < 15.0))
print ind, x_src[ind], y_src[ind]

plt.scatter(x_src[ind], y_src[ind]); plt.show()
'''

# From the procedure above, we identify the id of the source that we would use for illustration.
src_id = 2782 #ll1.
#src_id = 552 #ll2.

results_path = 'simulations_ll1'

# Extract the information about the location of the spike file and the background traveling wave data.
#job_name = 'll1_Protector2_frames_3050_to_3140_5_sd278'
job_name = 'll1_8068_2_sd278'

#t_vis_stim = [500.0, 3000.0]
t_vis_stim = [500.0, 1000.0]

f_config = open('%s/config_%s.json' % (results_path, job_name), 'r')
config = json.load(f_config)
f_config.close()
out_dir = config['biophys'][0]['output_dir']
tw_id = [x for x in config['ext_inputs_dir'] if ('tw_data' in x)][0].split('_')[-2]
tstop = float(config['run']['tstop'])

# Read spikes.
series = np.genfromtxt('%s/%s/spk.dat' % (results_path, out_dir), delimiter=' ')

# Plot spikes and the background traveling wave.
if (series.size > 2):

    #fig, axes = plt.subplots(2, 1)
    fig = plt.figure()
    gs = gridspec.GridSpec(3, 1, height_ratios=[5, 0.2, 1], hspace=0.05)
    ax1 = plt.subplot(gs[0])
    ax2 = plt.subplot(gs[1])
    ax3 = plt.subplot(gs[2])

    ax1.scatter(series[:, 0], series[:, 1], s=1, c='k')
    ax1.set_ylabel('Neuron ID')
    #ax1.set_ylim(bottom=0)
    ax1.set_ylim([0, 10000])

    f = open('tw_data/ll1_tw_build/tw_src_0/f_rates_%s.pkl' % (tw_id), 'r')
    tw_data = pickle.load(f)
    f.close()
    ax3.plot(tw_data['t'], tw_data['cells'][src_id])
    ax3.set_ylabel('Bkg. activity (arb. u.)')

    ax3.set_xlabel('Time (ms)')
    ax1.set_xlim((0, tstop))
    ax2.set_xlim((0, tstop))
    ax3.set_xlim((0, tstop))

    ax2.axis('off')

    ax3.spines['right'].set_visible(False)
    ax3.spines['top'].set_visible(False)
    ax3.yaxis.set_ticks_position('left')
    ax3.xaxis.set_ticks_position('bottom')

    ax1.set_xticklabels([])

    # Image duration.
    ax2.hlines(0.0, t_vis_stim[0], t_vis_stim[1], linewidth=10, color='c')

    fig.suptitle('%s/%s' % (results_path, out_dir), fontsize=18)
    plt.show()


