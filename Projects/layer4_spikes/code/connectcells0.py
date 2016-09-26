from common import *
from syn_uniform import *
from con_src_tar import *
from build_all_d_distributions import *

import math

import matplotlib.pyplot as plt


def connectcells(con_path, cells_db, utils_obj):
  # Due to restrictions on the number of files that can be simultaneously open (while generating connections at the build stage), we lump multiple tar_gid
  # into one file; the parameter N_tar_gid_per_file specifies how many tar_gid are reserved for each file.
  N_tar_gid_per_file = 100

  progress_k = 0
  for tar_gid in cells:

    if (int(pc.id()) == 0):
      if ( progress_k % 10 == 0 ):
        tmp1 = 100.0 * progress_k / len(cells)
        print "Establishing connections; progress: %.5f percent." % (tmp1)

    progress_k += 1

    target = cells[tar_gid]
    target_type = cell_types[type_index(tar_gid)] 

    f_key_for_tar_gid = N_tar_gid_per_file * (tar_gid / N_tar_gid_per_file) # Note that integer division is used here.
    f_con_name = '%s/target_%d_%d.dat' % (con_path, f_key_for_tar_gid, f_key_for_tar_gid+N_tar_gid_per_file)
    f_con = open(f_con_name, 'r')
    src_gid_list = []
    src_type_list = []
    N_syn_list = []
    for line in f_con:
      tmp_l = line.split()
      if (len(tmp_l) > 0):
        if (int(tmp_l[0]) == tar_gid):
          src_gid = int(tmp_l[1])
          if ((src_gid < cell_displ[-1]) and (src_gid != tar_gid)): 
            src_gid_list.append(src_gid)
            N_syn_list.append(int(tmp_l[2]))
            # Define the presynaptic type; for simplicity, we combine cell types together into groups, so that each group is represented by one presynaptic type.
            src_type = cell_types[type_index(src_gid)]
            if ( src_type in ['Scnn1a', 'Rorb', 'Nr5a1', 'LIF_exc'] ):
              src_type_list.append('exc')
            elif ( src_type in ['PV1', 'PV2', 'LIF_inh'] ):
              src_type_list.append('inh')
    f_con.close()

    # Create a dictionary with distributions of distances from the soma for all sections.  The dictionary
    # contains this information for ALL combinations of section labels ('basal', 'apical', etc.) that are
    # found for this cell given the inputs from the file.
    d_f_dict = {}
    if (target_type not in ['LIF_exc', 'LIF_inh']):
      all_sec_label_lists = []
      for src_type_tmp in src_type_list:
        all_sec_label_lists.append(utils_obj.description.data['syn_data_types'][target_type][src_type_tmp]['sec'])
      d_f_dict = build_all_d_distributions(all_sec_label_lists, tar_gid)

    # Establish connections (potentially, with multiple synapses) for each pair of target and source cells.
    for i, src_gid in enumerate(src_gid_list):
      src_obj_list = [src_gid] * N_syn_list[i] # Here, the src_obj_list should simply be a list of identical elements (each being the src_gid), N_syn_list[i] in length.

      # Process tuning difference.
      delta_tuning = 0.0 # Assume no difference in tuning properties if tuning values are not specified.
      if ((cells_db.tuning[tar_gid] != 'None') and (cells_db.tuning[src_gid] != 'None')):
        # Compute difference in the tuning angle between target and source.  Keep track of orientation (not direction) and only of
        # the absolute value of the difference.
        # Since the difference should only matter within [0, 90] degrees, convert the result to that scale.
        delta_tuning = abs(abs(abs(180.0 - abs(float(cells_db.tuning[tar_gid]) - float(cells_db.tuning[src_gid])) % 360.0) - 90.0) - 90.0)
      w_multiplier = 1.0 #math.exp( -(delta_tuning / 50.0)**2 )

      con_src_tar(src_obj_list, src_type_list[i], tar_gid, target, 'internal', utils_obj, d_f_dict, w_multiplier)

