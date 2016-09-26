from common import *
import numpy as np
import math
from utils import Utils

def mkcells(cells_db, utils_obj):

  gid_list = range(rank, cell_displ[-1], nhost) 

  for gid in gid_list:
    #print rank, gid
    if (int(pc.id()) == 0):
      if ( gid % 5 == 0 ):
        print "Instantiating cells; progress: %.5f percent." % (100.0 * gid / cell_displ[-1])

    tmp_type = cells_db.type[gid]
    tmp_morph = cells_db.morphology[gid]
    tmp_par_fname = cells_db.cell_par[gid]

    if (tmp_type in ['LIF_exc']):
      cells[gid] = h.LIF_pyramid_1()
    elif (tmp_type in ['LIF_inh']):
      cells[gid] = h.LIF_interneuron_1()
    else:
      cell = h.cell()
      cells[gid]=cell
      utils_obj.generate_morphology(cell, tmp_morph)
      utils_obj.load_cell_parameters(cell, tmp_par_fname)

    h.register(gid, cells[gid])

    # Create numpy arays with sections and distances from the soma for each section (closest and furthest distances).
    # Do this for all cells that have morphologies.
    if (tmp_morph != 'None'):
      print tmp_morph
      sec_list = h.SectionList()
      sec_label = []
      for sec in cells[gid].somatic:
        sec_list.append()
        sec_label.append('somatic')
      for sec in cells[gid].axonal:
        sec_list.append()
        sec_label.append('axonal')
      for sec in cells[gid].basal:
        sec_list.append()
        sec_label.append('basal')
      for sec in cells[gid].apical:
        sec_list.append()
        sec_label.append('apical')

      # Use soma as a reference point to measure distances.
      h('access ' + cells[gid].hname() + '.soma[0]')
      h.distance()

      tmp_sec = []
      tmp_dist0 = []
      tmp_dist1 = []
      delta_d = 1.0 # Discretize distances from soma with this level of granularity, for purposes of creating a distribution over these distances.
      d_array = np.arange(delta_d, 10.0 + delta_d, delta_d) # Start with this size and add elements if necessary.
      d_distribution = np.zeros( d_array.size ) # Element 0 corresponds to d from 0 to delta_d, element 1  to d from delta_d to 2 delta_d, and so on.
      d_dict = { 'somatic': { 'd_distribution': d_distribution, 'd_array': d_array }, 'axonal': { 'd_distribution': d_distribution, 'd_array': d_array }, 'basal': { 'd_distribution': d_distribution, 'd_array': d_array }, 'apical': { 'd_distribution': d_distribution, 'd_array': d_array } }
      for i_sec, sec in enumerate(sec_list):
        label = sec_label[i_sec]
        tmp_sec.append(sec)
        d0 = h.distance(0)
        d1 = h.distance(1)
        tmp_dist0.append(d0)
        tmp_dist1.append(d1)
        if (d1 > d_dict[label]['d_array'][-1]):
          d_add = np.arange(d_dict[label]['d_array'][-1]+delta_d, d1+delta_d, delta_d)
          d_dict[label]['d_array'] = np.append( d_dict[label]['d_array'], d_add )
          d_dict[label]['d_distribution'] = np.append( d_dict[label]['d_distribution'], np.zeros(d_add.size) )
        ind = np.intersect1d( np.where(d_dict[label]['d_array'] >= d0), np.where(d_dict[label]['d_array'] <= d1) )
        d_dict[label]['d_distribution'][ind] += 1.0 # We could make it more sophisticated and take into account the amount of overlap between the [d0, d1] interval and the elements of d_array that are on the borders of that interval; but, with delta_d being small enough, this seems unnecessary.

      cell_sec[gid] = {}
      cell_sec[gid]['sec'] = np.array(tmp_sec)
      cell_sec[gid]['d0'] = np.array(tmp_dist0)
      cell_sec[gid]['d1'] = np.array(tmp_dist1)
      cell_sec[gid]['label'] = np.array(sec_label)
      cell_sec[gid]['delta_d'] = delta_d
      cell_sec[gid]['d_f'] = {}
      for label in d_dict.keys():
        cell_sec[gid]['d_f'][label] = {}
        cell_sec[gid]['d_f'][label]['d_array'] = np.array(d_dict[label]['d_array'])
        cell_sec[gid]['d_f'][label]['d_distribution'] = np.array(d_dict[label]['d_distribution'])


  # Prepare the dictionary for which each member is to become a list of random streams for a specific cell.
  for gid in cells:
    common_rand_stream_dict[gid] = []

