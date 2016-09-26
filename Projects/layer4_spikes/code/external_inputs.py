from common import *
import linecache
from syn_uniform import *
from con_src_tar import *
from build_all_d_distributions import *

import numpy as np

import matplotlib.pyplot as plt

ext_in_netstim_list = []
ext_in_vecstim_list = []
ext_in_train_vec_list = []
ext_in_vecstim = h.VecStim()


def external_inputs(ext_in_tar_cell_gid, ext_inp_path, tar_ext_inp_map, ext_inp_dict, t_stop, utils_obj):

  target = cells[ext_in_tar_cell_gid]
  target_type = cell_types[type_index(ext_in_tar_cell_gid)]

  mode = ext_inp_dict['mode']
  if (mode == 'file'):
    ext_inp_trial = ext_inp_dict['trial']
    t_shift = ext_inp_dict['t_shift']

    N_trials_in_file = ext_inp_dict['trials_in_file']
    f_train_line_pos = tar_ext_inp_map['src_gid'].values * N_trials_in_file + ext_inp_trial + 1 #Line number in file start from 1.

  elif (mode == 'random'):
    random_ISI = tar_ext_inp_map['random_ISI'].values

  presyn_type = tar_ext_inp_map['presyn_type'].values
  N_syn = tar_ext_inp_map['N_syn'].values

    
  # Create a dictionary with distributions of distances from the soma for all sections.  The dictionary
  # contains this information for ALL combinations of section labels ('basal', 'apical', etc.) that are
  # found for this cell given the inputs from the file.
  d_f_dict = {}
  if (target_type not in ['LIF_exc', 'LIF_inh']):
    all_sec_label_lists = []
    for src_type_tmp in presyn_type:
      all_sec_label_lists.append(utils_obj.description.data['syn_data_types'][target_type][src_type_tmp]['sec'])
    d_f_dict = build_all_d_distributions(all_sec_label_lists, ext_in_tar_cell_gid)

  # For each line in the input map file, establish the appropriate number of connections.
  for i_line in xrange(N_syn.size):
    src_obj_list = []

    # Read the spike times for the spike train (if mode == 'file').
    if (mode == 'file'):
      spike_t = [float(x) for x in linecache.getline(ext_inp_path, f_train_line_pos[i_line]).split()]

    elif (mode == 'random'): # Initiate random stream.
      rand_t = h.Randstream(ext_in_tar_cell_gid, len(common_rand_stream_dict[ext_in_tar_cell_gid]))
      rand_t.r.negexp(1.0)
      common_rand_stream_dict[ext_in_tar_cell_gid].append(rand_t)

    # Generate appropriate sources for each input.
    for j in xrange(N_syn[i_line]):

      if (mode == 'random'):
        dumNetStim = h.NetStim(.5)
        dumNetStim.noiseFromRandom(rand_t.r)
        dumNetStim.interval = random_ISI[i_line] # mean ISI (ms)
        dumNetStim.number = 5 + int(t_stop / random_ISI[i_line]) # Pad the number of events just a little bit, because otherwise, if random_ISI_file_t_shift > t_stop, no events are generated at all; the padding number would be the maximum number of events that may be generated within t-stop in that situation, but in most cases there will be fewer generated, as the event times are on average separated by delta_t = random_ISI_file_t_shift.
        dumNetStim.noise = 1.0
        dumNetStim.start = 0.0
        ext_in_netstim_list.append(dumNetStim)
        src_obj_list.append(dumNetStim)

      else:
        ext_in_train_vec = h.Vector()
        if (t_shift != 0.0):
          spike_t_current = [(x + t_shift) for x in spike_t if (x + t_shift >= 0.0)]
        else:
          spike_t_current = spike_t

        for x in spike_t_current:
          ext_in_train_vec.append(x)
        ext_in_train_vec_list.append(ext_in_train_vec)
        ext_in_vecstim = h.VecStim()
        ext_in_vecstim_list.append(ext_in_vecstim)
        ext_in_vecstim.play(ext_in_train_vec)
        src_obj_list.append(ext_in_vecstim)

    w_multiplier = 1.0

    con_src_tar(src_obj_list, presyn_type[i_line], ext_in_tar_cell_gid, target, 'external', utils_obj, d_f_dict, w_multiplier)

