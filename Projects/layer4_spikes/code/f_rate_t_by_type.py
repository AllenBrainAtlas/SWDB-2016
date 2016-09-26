import numpy as np
import matplotlib.pyplot as plt
import math
import pickle

def f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name):
  bins = np.arange(bin_start, bin_stop+bin_size, bin_size)
  # Originally bins include both leftmost and rightmost bin edges.
  # Here we remove the rightmost edge to make the size consistent with that of f_rate computed below.
  t_f_rate = bins[:-1]


  f_rate_dict = {}
  f_rate_dict['t_f_rate'] = t_f_rate

  for f_name in f_list:
    f_rate_dict[f_name] = {}
    print 'Processing file %s.' % (f_name)
    data = np.genfromtxt(f_name, delimiter=' ')
    if (data.size == 0):
      t = np.array([])
      gids = np.array([])
    elif (data.size == 2):
      t = np.array([data[0]])
      gids = np.array([data[1]])
    else:
      t = data[:, 0]
      gids = data[:, 1]
    for type in gids_by_type:
      ind = np.where( np.in1d(gids, gids_by_type[type]) )[0] # np.in1d(A, B) produces a boolean array of length A.size, with True values where elements of A are in B.
      t1 = t[ind]
      f_rate = np.histogram(t1, bins)[0] # Here, np.histogram returns a tuple, where the first element is the histogram itself and the second is bins.
      f_rate_dict[f_name][type] = 1000.0 * f_rate / ( gids_by_type[type].size * bin_size ) # Convert to rate making sure the units are Hz (time is in ms).

      #plt.plot(t_f_rate, f_rate_dict[f_name][type])
      #plt.title('Type %s' % (type))
      #plt.show()

  # Obtain the average over all files.
  f_rate_dict['mean'] = {}
  for type in gids_by_type:
    f_rate_dict['mean'][type] = np.zeros(t_f_rate.size)
    for f_name in f_list:
      f_rate_dict['mean'][type] += f_rate_dict[f_name][type]
      #plt.plot(t_f_rate, f_rate_dict[f_name][type], c='gray')
    f_rate_dict['mean'][type] = f_rate_dict['mean'][type] / len(f_list)
    #plt.plot(t_f_rate, f_rate_dict['mean'][type])
    #plt.title('Type %s' % (type))
    #plt.show()

  f = open(out_f_name, 'w')
  pickle.dump(f_rate_dict, f)
  f.close()


def construct_gids_by_type_dict(cells_file):
  gids_by_type = {}
  f = open(cells_file, 'r')
  for i, line in enumerate(f):
    if (i > 0):
      tmp_l = line.split()
      gid = int(tmp_l[0])
      type = tmp_l[1]
      if (type not in gids_by_type.keys()):
        gids_by_type[type] = np.array([])
      else:
        gids_by_type[type] = np.append(gids_by_type[type], gid)
  f.close()
  return gids_by_type





sys_name = 'll2'
cells_file = 'build/%s.csv' % (sys_name)
bin_start = 0.0
bin_stop = 3000.0
bin_size = 20.0

gids_by_type = construct_gids_by_type_dict(cells_file)
'''
f_list = []
for stim_name in ['flash_2']: #'flash_1']:
  for i in xrange(0, 4):
    f_list.append('output_%s_%s_%d_sd278/spk.dat' % (sys_name, stim_name, i))
out_f_name = 'f_rate_t_by_type_%s_%s_sd278.pkl' % (sys_name, stim_name)
f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

f_list = []
for stim_name in ['8068', '108069', '130034', '163062', 'imk00895', 'imk01220', 'imk01261', 'imk01950', 'imk04208', 'pippin_Mex07_023']:
  for i in xrange(0, 10):
    f_list.append('output_%s_%s_%d/spk.dat' % (sys_name, stim_name, i))
out_f_name = 'f_rate_t_by_type_%s_img.pkl' % (sys_name)
f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)
'''
f_list = []
for i in xrange(0, 10):
#  f_list.append('output_%s_TouchOfEvil_frames_3600_to_3750_%d/spk.dat' % (sys_name, i))
#out_f_name = 'f_rate_t_by_type_%s_Protector2_frames_3050_to_3140.pkl' % (sys_name)
#f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)
  f_list = ['output_%s_TouchOfEvil_frames_3600_to_3750_%d_sd278/spk.dat' % (sys_name, i)]
  out_f_name = 'f_rate_t_by_type_%s_TouchOfEvil_frames_3600_to_3750_%d.pkl' % (sys_name, i)
  f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

'''
f_list = []
for grating_id in xrange(6, 240, 30):
  for i in xrange(0, 5):
    f_list.append('output_g%d_%d/spk.dat' % (grating_id, i))
out_f_name = 'f_rate_t_by_type_gratings_tf_1Hz.pkl'
f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

f_list = []
for grating_id in xrange(7, 240, 30):
  for i in xrange(0, 10):
    f_list.append('output_%s_g%d_%d/spk.dat' % (sys_name, grating_id, i))
out_f_name = 'f_rate_t_by_type_%s_g_tf_2Hz.pkl' % (sys_name)
f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

f_list = []
for grating_id in [8]: #xrange(8, 240, 30):
  for i in xrange(0, 10):
#    f_list.append('output_%s_g%d_%d_sd278/spk.dat' % (sys_name, grating_id, i))
#out_f_name = 'f_rate_t_by_type_%s_g8_sd278.pkl' % (sys_name) #'f_rate_t_by_type_%s_g_tf_4Hz.pkl' % (sys_name)
#f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)
    f_list = ['output_%s_g%d_%d_sd278/spk.dat' % (sys_name, grating_id, i)]
    out_f_name = 'f_rate_t_by_type_%s_g%d_%d_sd278.pkl' % (sys_name, grating_id, i) #'f_rate_t_by_type_%s_g_tf_4Hz.pkl' % (sys_name)
    f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

f_list = []
for grating_id in xrange(9, 240, 30):
  for i in xrange(0, 5):
    f_list.append('output_g%d_%d/spk.dat' % (grating_id, i))
out_f_name = 'f_rate_t_by_type_gratings_tf_8Hz.pkl'
f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

f_list = []
for i in xrange(0, 20):
  f_list.append('output_%s_spont_%d_sd278/spk.dat' % (sys_name, i))
out_f_name = 'f_rate_t_by_type_%s_spont_sd278.pkl' % (sys_name)
f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)
'''

for stim_name in ['flash_1']:
#for stim_name in ['spont']:
  trial = 1
  #for sd in []: #[277, 278, 279]: #xrange(277, 280):
  sd = 278
  for trial in []: #xrange(0, 10):
    f_list = ['output_%s_%s_%d_sd%d/spk.dat' % (sys_name, stim_name, trial, sd)]
    out_f_name = 'f_rate_t_by_type_%s_%s_%d_sd%d.pkl' % (sys_name, stim_name, trial, sd)
    f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

#f_list = ['output_ll1_spont_1/spk.dat']
#out_f_name = 'f_rate_t_by_type_ll1_spont_1.pkl'
#f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)

#f_list = ['output_lr1_g8_8_sd287_test500ms_cn0/spk.dat']
#out_f_name = 'f_rate_t_by_type_lr1_g8_8_sd287_test500ms_cn0.pkl'
#f_rate_t_by_type(gids_by_type, bin_start, bin_stop, bin_size, f_list, out_f_name)





combined_dict = {}
av_by_type = {}
std_by_type = {}
f_name_list = []

#for stim_name in ['spont']:
for stim_name in ['flash_1']:
  #trial = 1
  #for sd in []: #[254] + range(278, 279):
  sd = 278
  for trial in []: #xrange(0, 10):
    f_name_list.append('f_rate_t_by_type_%s_%s_%d_sd%d.pkl' % (sys_name, stim_name, trial, sd))

#for grating_id in [8]:
#  for i in [5]: #xrange(0, 10):
#   f_name_list.append('f_rate_t_by_type_%s_g%d_%d_sd278.pkl' % (sys_name, grating_id, i))

for i in [0]: #xrange(0, 10):
   f_name_list.append('f_rate_t_by_type_%s_TouchOfEvil_frames_3600_to_3750_%d.pkl' % (sys_name, i))

#f_name_list.append('f_rate_t_by_type_rr1_flash_1_1_sd282_test500ms.pkl')

#f_name_list.append('f_rate_t_by_type_ll2_flash_1_sd278.pkl')

#f_name_list.append('f_rate_t_by_type_ll1_flash_1_1_sd249_test500ms.pkl')

#f_name_list.append('f_rate_t_by_type_ll1_flashes.pkl')
#f_name_list.append('../8-network-start/f_rate_t_by_type_flashes_sd_190.pkl')

#f_name_list.append('f_rate_t_by_type_ll1_spont.pkl')
#f_name_list.append('f_rate_t_by_type_ll1_spont_1.pkl')

#f_name_list.append('f_rate_t_by_type_ll2_spont_sd278.pkl')
#f_name_list.append('f_rate_t_by_type_ll2_flash_1_sd278.pkl')
#f_name_list.append('f_rate_t_by_type_ll2_flash_2_sd278.pkl')

#for stim_name in ['spont', 'flashes', 'Protector2_frames_3050_to_3140', 'g_tf_2Hz', 'g_tf_4Hz']:
#  f_name_list.append('f_rate_t_by_type_%s_%s.pkl' % (sys_name, stim_name))

#f_name_list.append('f_rate_t_by_type_ll1_sd254_1tr_g_tf_4Hz.pkl')
#f_name_list.append('f_rate_t_by_type_ll1_sd254_2tr_g_tf_4Hz.pkl')

#f_name_list.append('f_rate_t_by_type_ll1_g8_8_sd254_test500ms.pkl')
#f_name_list.append('f_rate_t_by_type_ll1_g8_8_sd278_test500ms.pkl')
#f_name_list.append('f_rate_t_by_type_rr1_g8_8_sd282_cn0_test500ms.pkl')
#f_name_list.append('f_rate_t_by_type_rl1_g8_8_sd285_test500ms.pkl')
#f_name_list.append('f_rate_t_by_type_lr1_g8_8_sd287_test500ms_cn0.pkl')

#f_name_list.append('f_rate_t_by_type_ll1_g8_sd278.pkl')

for f_name in f_name_list:
  f = open(f_name, 'r')
  combined_dict[f_name] = pickle.load(f)

  av_by_type[f_name] = {}
  std_by_type[f_name] = {}
  # Make sure that we use the appropriate time window for computing the average and standard deviation; do not
  # include the first several hundred milliseconds (for equilibration purposes).
  if ('spont' in f_name):
    t_av_start = 500.0
    t_av_stop = 1000.0
  elif ('img' in f_name):
    t_av_start = 500.0
    t_av_stop = 1250.0
  else:
    t_av_start = 0.0 #500.0
    t_av_stop = 500.0 #3000.0
  ind = np.intersect1d( np.where( combined_dict[f_name]['t_f_rate'] > t_av_start ), np.where( combined_dict[f_name]['t_f_rate'] < t_av_stop ) )
  for type in gids_by_type:
    av_by_type[f_name][type] = combined_dict[f_name]['mean'][type][ind].mean()
    std_by_type[f_name][type] = combined_dict[f_name]['mean'][type][ind].std()

  f.close()

for type in gids_by_type:
  print '\n%s' % (type)
  for f_name in f_name_list:
    print '%s: %g +/- %g Hz' % (f_name, av_by_type[f_name][type], std_by_type[f_name][type])

for type in gids_by_type: 
  for f_name in f_name_list:
    plt.plot(combined_dict[f_name]['t_f_rate'], combined_dict[f_name]['mean'][type], label=f_name)
  plt.xlabel('t (ms)')
  plt.ylabel('Mean firing rate (Hz)')
  plt.legend()
  plt.title('Type %s' % (type))
  #plt.xlim((0.0, 1500.0))
  plt.show()


