import json
import os
from os import path, makedirs

Nnodes = 5
ppn = 24
Ncores = Nnodes * ppn

system_name = 'll2' #'ll2'
cell_db_path = 'build/%s.csv' % (system_name)
con_path = 'build/%s_connections'  % (system_name)

update_tw_trial_id = 'yes'
use_vis_stim_path_only = 'no'

vis_map = 'build/ll2_inputs_from_LGN.csv'
tw_map = 'tw_data/ll2_tw_build/mapping_2_tw_src.csv'

for syn_data_id in [278]: #[278]: #xrange(254, 255):
  syn_data_file = 'syn_data_%d.json' % (syn_data_id)

#  tstop = 1000.0 #500.0
#  tw_trial_id = 0 #1 #0
#  stim_name = 'spont'
##for stim_name in ['spont']:
#  for trial in xrange(0, 20): #[1]: #xrange(0, 20):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/spont_LGN_spk.dat'
#    vis_t_shift = 0.0
#    vis_trials_in_file = 50

#  tstop = 3000.0
#  tw_trial_id = 100
#  for grating_id in xrange(7, 240, 30): #[8]: #xrange(8, 240, 30):
#  #grating_id = 8
#   for trial in xrange(0, 10): #[8]: #xrange(2, 10): #[8]: #xrange(0, 10):
#    jobname = '%s_g%d_%d_sd%d' % (system_name, grating_id, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/grating_%d_LGN_spk.dat' % (grating_id)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 10

#  tstop = 3000.0 #500.0
#  tw_trial_id = 180 #68 #1 #188 #180
#  for grating_id in xrange(8, 240, 30): #[8]: #xrange(8, 240, 30):
#  #grating_id = 8
#   for trial in xrange(0, 10): #[8]: #xrange(2, 10): #[8]: #xrange(0, 10):
#    jobname = '%s_g%d_%d_sd%d' % (system_name, grating_id, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/grating_%d_LGN_spk.dat' % (grating_id)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 10

#  # Contrast 30 %.
#  # For now, use the same tw trials as for the "normal" (80 % contrast) movie.
#  tstop = 3000.0
#  tw_trial_id = 180
#  for grating_id in xrange(8, 240, 30):
#   for trial in xrange(0, 10):
#    jobname = '%s_g%d_%d_ctr30_sd%d' % (system_name, grating_id, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output2/grating_%d_ctr30_LGN_spk.dat' % (grating_id)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 10

#  # Contrast 10 %.
#  # For now, use the same tw trials as for the "normal" (80 % contrast) movie.
#  tstop = 3000.0
#  tw_trial_id = 180
#  for grating_id in xrange(8, 240, 30):
#   for trial in xrange(0, 10):
#    jobname = '%s_g%d_%d_ctr10_sd%d' % (system_name, grating_id, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output2/grating_%d_ctr10_LGN_spk.dat' % (grating_id)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 10


#  tstop = 3000.0
#  tw_trial_id = 260
#  for grating_id in xrange(9, 240, 30): #[8]: #xrange(8, 240, 30):
#  #grating_id = 8
#   for trial in xrange(0, 10): #[8]: #xrange(2, 10): #[8]: #xrange(0, 10):
#    jobname = '%s_g%d_%d_sd%d' % (system_name, grating_id, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/grating_%d_LGN_spk.dat' % (grating_id)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 10

#  tstop = 3000.0 #500.0 #3000.0
#  tw_trial_id = 340 #1 #340
#  stim_name = 'flash_1'
##for stim_name in ['flash_1']:
#  for trial in xrange(0, 10): #[1]: #xrange(0, 10):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20

#  tstop = 1500.0
#  tw_trial_id = 350
#  stim_name = 'flash_2'
#  for trial in xrange(0, 10):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20

#  tstop = 5000.0
#  tw_trial_id = 500
#  for stim_name in ['TouchOfEvil_frames_1530_to_1680', 'TouchOfEvil_frames_3600_to_3750', 'TouchOfEvil_frames_5550_to_5700']:
#   for trial in xrange(0, 10):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output2/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20

# Scrambled sequence of frames.
# For now, use the same tw trials as for the non-scrambled movies.
  tstop = 5000.0
  tw_trial_id = 510
  for stim_name in ['TouchOfEvil_frames_3600_to_3750_scrbl_t']:
   for trial in xrange(0, 10):
    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output2/%s_LGN_spk.dat' % (stim_name)
    vis_t_shift = 0.0
    vis_trials_in_file = 20

## Scrambled pixels in each frame.
## For now, use the same tw trials as for the non-scrambled movies.
#  tstop = 5000.0
#  tw_trial_id = 510
#  for stim_name in ['TouchOfEvil_frames_3600_to_3750_scrbl_xy']:
#   for trial in xrange(0, 10):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output2/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20

#  tstop = 1250.0 #350.0 #1250.0
#  tw_trial_id = 360
#  for stim_name in ['img011_BR', 'img019_BT', 'img024_BT', 'img049_BT', 'img057_BR', 'img062_VH', 'img069_VH', 'img071_VH', 'img090_VH', 'img101_VH']:
#   for trial in xrange(0, 10):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20

#  tstop = 3000.0
#  tw_trial_id = 360
#  for imseq_id in xrange(0, 100):
#   stim_name  = 'imseq_%d' % (imseq_id)
#   for trial in xrange(0, 1):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20

#  tstop = 3000.0
#  tw_trial_id = 460
#  for stim_name in ['Wbar_v50pixps_vert', 'Wbar_v50pixps_hor', 'Bbar_v50pixps_vert', 'Bbar_v50pixps_hor']:
#   for trial in xrange(0, 10):
#    jobname = '%s_%s_%d_sd%d' % (system_name, stim_name, trial, syn_data_id)
#    vis_stim_path = '/data/mat/antona/network/14-simulations/6-LGN_firing_rates_and_spikes/LGN_spike_trains/output3/%s_LGN_spk.dat' % (stim_name)
#    vis_t_shift = 0.0
#    vis_trials_in_file = 20


    workdir = 'output_' + jobname
    startfile = 'run_' + jobname + '.py'
    configname = 'config_' + jobname + '.json'
    qsub_file_name = 'qsub_' + jobname + '.qsub'

    vis_dict = { 'mode': 'file', 'map': vis_map, 'trial': trial, 't_shift': vis_t_shift, 'trials_in_file': vis_trials_in_file }

    tw_stim_path = 'tw_data/%s_tw_build/2_tw_src/%d_spk.dat' % (system_name, tw_trial_id)
    tw_t_shift = 0.0
    tw_trials_in_file = 1
    tw_current_trial_within_file = 0 # This is different than tw_trial_id (the latter refers to the file name).
    tw_dict = { 'mode': 'file', 'map': tw_map, 'trial': tw_current_trial_within_file, 't_shift': tw_t_shift, 'trials_in_file': tw_trials_in_file }
    if (update_tw_trial_id == 'yes'):
      tw_trial_id += 1 # Increase the ID of the traveling wave for the next grating/trial combination.

    if not path.exists(workdir):
      makedirs(workdir)

    f = open(startfile, 'w')
    f.write('import start as start\n')
    f.write('\n')
    f.write('start.run_simulation(\'' + ('%s' % (configname)) + '\')\n')
    f.write('\n')
    f.write('\n')
    f.close()

    f_config = open('config_standard.json', 'r')
    config = json.load(f_config)
    f_config.close()

    config['manifest'][2]['spec'] = cell_db_path
    config['connections'] = con_path
    config['biophys'][0]['model_file'][0] = configname
    config['biophys'][0]['output_dir'] = workdir

    if (use_vis_stim_path_only == 'yes'):
      config['ext_inputs'] = { vis_stim_path: vis_dict }
    else:
      config['ext_inputs'] = { vis_stim_path: vis_dict, tw_stim_path: tw_dict }

    config['run']['tstop'] = tstop
    config['cell_data_tracking']['SEClamp_insert_cell_gid_step'] = 200
    config['cell_data_tracking']['SEClamp_insert'] = 'yes'
    config['cell_data_tracking']['SEClamp_insert_first_cell'] = 2
    config['cell_data_tracking']['do_save_t_series'] = 'yes'
    config['syn_data_file'] = syn_data_file
    #del config['connections'] # Remove this for the case without any recurrent connections.

    f_config = open(configname, 'w')
    f_config.write(json.dumps(config, indent=2))
    f_config.close()


    f_out = open(qsub_file_name, 'w')

    f_out.write('#PBS -q mindscope\n')
    f_out.write('#PBS -l walltime=12:00:00\n')
    f_out.write('#PBS -l nodes=' + str(Nnodes) + ':ppn=' + str(ppn) + '\n')
    f_out.write('#PBS -N ' + jobname + '\n')
    f_out.write('#PBS -r n\n')
    f_out.write('#PBS -j oe\n')
    f_out.write('#PBS -o ' + workdir + '/' + jobname + '.out\n')
    f_out.write('#PBS -m a\n')
    f_out.write('cd $PBS_O_WORKDIR\n')
    f_out.write('\n')
    f_out.write('export LD_PRELOAD=/usr/lib64/libstdc++.so.6\n')
    f_out.write('export PATH=/shared/utils.x86_64/hydra-3.0.4/bin/:$PATH\n')
    f_out.write('\n')
    f_out.write('mpiexec -np ' + str(Ncores) + ' nrniv -mpi ' + startfile + ' > ' + workdir + '/log.txt\n')

    f_out.close


