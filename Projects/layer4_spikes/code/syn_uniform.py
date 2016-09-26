from common import *
import sys
import numpy as np

def syn_uniform(N_syn, tar_gid, target_cell, sec_labels, d_cutoff, rand_t, d_f_dict):
  syn_list = []

  if (d_cutoff[0] >= d_cutoff[1]):
    sys.exit( 'Error: lower bound for synapse distribution is higher than the upper bound, d_cutoff = (%g, %g); exiting.' % (d_cutoff[0], d_cutoff[1]) )

  # Convert the list of labels to a string that can be used as a key in d_f_dict.
  sec_str = ' '.join( sorted(list(set(sec_labels))) )
  d_f_dict_tmp = d_f_dict['sec'][sec_str]

  # Here, an error could be replaced by an exception handling mechanism, such that
  # placement of synapses is avoided and the program continues to next steps.
  if (d_cutoff[0] >= d_f_dict_tmp['distribution_max_d']):
    sys.exit( 'Error: lower bound for synapse distribution is higher than the further available distance, %g >= %g; exiting.' % (d_cutoff[0], d_f_dict_tmp['distribution_max_d']) )

  # Find the largest distance that is accessible for synapse placement.
  d_max = np.minimum( d_cutoff[1], d_f_dict_tmp['distribution_max_d'] )

  tmp_d = d_f_dict_tmp['d_array']
  tmp_p = d_f_dict_tmp['d_distribution']
  ind = np.intersect1d( np.where(tmp_d >= d_cutoff[0]), np.where(tmp_d <= d_max) )
  tmp_d = tmp_d[ind]
  tmp_p = tmp_p[ind]

  # Compute the cumulative distribution.
  tmp_p_cum = np.zeros(tmp_p.size)
  tmp_p_cum[0] = tmp_p[0]
  for i in xrange(1, tmp_p.size):
    tmp_p_cum[i] = tmp_p_cum[i-1] + tmp_p[i]
  
  # Choose synaptic distances (from the soma) according to probability distribution tmp_p.
  syn_d_array = np.zeros(N_syn)
  for i in xrange(N_syn):
    tmp = rand_t.r.uniform(0.0, tmp_p_cum[-1])
    ind_tmp = np.where( tmp_p_cum >= tmp )[0][0] # Choose the first element satisfying this condition.
    syn_d_array[i] = tmp_d[ind_tmp]

  # Based on synaptic distances, choose sections and location within the section for placement of each synapse.
  ind1 = np.array([], dtype=np.int)
  for label in sec_labels:
    tmp_ind = np.where(cell_sec[tar_gid]['label'] == label)[0]
    ind1 = np.append(ind1, tmp_ind)
  sec_tmp = cell_sec[tar_gid]['sec'][ind1]
  d0_tmp = cell_sec[tar_gid]['d0'][ind1]
  d1_tmp = cell_sec[tar_gid]['d1'][ind1]
  for syn_d in syn_d_array:
    # The distance has been previously selected based on the desired probability distribution (such as
    # the distribution of distances within each section from the soma).  Because of that, now we can
    # simply choose any section (with equal probability) that is within this distance.
    ind = np.intersect1d( np.where( d0_tmp <= syn_d ), np.where( d1_tmp >= syn_d ) )
    ind_selected = int(rand_t.r.uniform(0, ind.size))
    sec = sec_tmp[ind][ind_selected]
    d0 = d0_tmp[ind][ind_selected]
    syn_x = np.maximum(0.0, (rand_t.r.uniform(syn_d - d_f_dict['delta_d'], syn_d) - d0)) / sec.L
    syn = h.Exp2Syn(syn_x, sec=sec)
    syn_list.append(syn)
 
  return syn_list

