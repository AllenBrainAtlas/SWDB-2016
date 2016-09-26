from common import *
import numpy as np

def build_all_d_distributions(all_sec_label_lists, gid):
  d_f_dict = {}
  delta_d = cell_sec[gid]['delta_d']
  d_f_dict['delta_d'] = delta_d
  d_f_dict['sec'] = {}


  unique_sec_label_str = []
  for sec_label_list in all_sec_label_lists:
    tmp_str = ' '.join( sorted(list(set(sec_label_list))) ) # Make sure the entries are unique, sort the list, and turn in into a string, where entries are separated by spaces.  With this transformation, one can use these data as keys in a dictionary.
    if tmp_str not in unique_sec_label_str:
      unique_sec_label_str.append(tmp_str)

  for sec_labels in unique_sec_label_str:
    d_f_dict['sec'][sec_labels] = {}

    N_max = 0
    label_max = ''
    for label in sec_labels.split(' '):
      N_tmp = cell_sec[gid]['d_f'][label]['d_array'].size
      if (N_tmp > N_max):
        N_max = N_tmp
        label_max = label

    tmp_d_array = cell_sec[gid]['d_f'][label_max]['d_array']
    d_f_dict['sec'][sec_labels]['d_array'] = tmp_d_array

    tmp_array = np.zeros(N_max)
    for label in sec_labels.split(' '):
      N_tmp = cell_sec[gid]['d_f'][label]['d_array'].size
      tmp_array = tmp_array + np.append( cell_sec[gid]['d_f'][label]['d_distribution'], np.zeros(N_max - N_tmp) )

    d_f_dict['sec'][sec_labels]['d_distribution'] = tmp_array
    # Compute the largest distance at which the distribution is non-zero.
    d_f_dict['sec'][sec_labels]['distribution_max_d'] = tmp_d_array[np.where( tmp_array > 0.0 )[0]][-1]

  return d_f_dict

