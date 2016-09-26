from common import *
from syn_uniform import *

# Function for establishing connections; it is assumed that all connections are of the same type and project to the same target cell;
# ideally, this implies connections from one source to one target cell, with an arbitrary number of synapses.
def con_src_tar(src_obj_list, src_type, tar_gid, target, external_flag, utils_obj, d_f_dict, w_multiplier):
  target_type = cell_types[type_index(tar_gid)]
  N_syn = len(src_obj_list)
  syn_data_types_tmp = utils_obj.description.data['syn_data_types'][target_type][src_type]

  # Process the weight separately here to avoid many identical multiplications, as we modify the weight using w_multiplier.
  syn_weight = syn_data_types_tmp['w'] * w_multiplier

  tar_obj_list = []
  syn_weight_list = []
  # For LIF neurons, use the cell as the target object and assign positive or negative weights for excitatory and inhibitory neurons, respectively.
  if ( target_type in ['LIF_exc', 'LIF_inh'] ):
    # Use a single synapse that combines weights from all synapses assigned to this connection.
    tar_obj_list.append(target.ac)
    if (syn_data_types_tmp['e'] < -55.0) :
      syn_weight_list.append(-1.0 * N_syn * syn_weight)
    else:
      syn_weight_list.append(N_syn * syn_weight)

  # For biophysically detailed neuronal models, distribute synapses on the dendritic tree of the target neuron.
  else:
    sec_labels = syn_data_types_tmp['sec']
    dcutoff = syn_data_types_tmp['dcutoff']
    rand_t = h.Randstream(tar_gid, len(common_rand_stream_dict[tar_gid]))
    dumSynList = syn_uniform(N_syn, tar_gid, target, sec_labels, dcutoff, rand_t, d_f_dict)
    common_rand_stream_dict[tar_gid].append(rand_t)
    
    for j in xrange(N_syn):
      common_syn_list.append(dumSynList[j])
      dumSynList[j].e = syn_data_types_tmp['e']
      dumSynList[j].tau1 = syn_data_types_tmp['tau1']
      dumSynList[j].tau2 = syn_data_types_tmp['tau2']

      tar_obj_list.append(dumSynList[j])
      # Currently we use identical synaptic weights for all synapses in a connection between a pair of cells,
      # but in principle each synapse could have its own weight. 
      syn_weight_list.append(syn_weight)  # Mean synaptic conductance in uS (for Exp2Syn).


  # Establish connections.
  for j in xrange(len(tar_obj_list)): # Use len(tar_obj_list) here to make sure that for LIF neurons we use 1 synapse instead of N_syn synapses.

    if (external_flag == 'external'):
      nc = h.NetCon(src_obj_list[j], tar_obj_list[j])
    else:
      # Here, src_obj_list should be the list of source gids.
      nc = pc.gid_connect(src_obj_list[j], tar_obj_list[j])

    nc.weight[0] = syn_weight_list[j]
    nc.delay = syn_data_types_tmp['delay']

    common_nc_list.append(nc)

