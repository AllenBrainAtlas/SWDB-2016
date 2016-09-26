import numpy as np
import matplotlib.pyplot as plt

#for grating_id_start in [7, 8]:
#  for grating_id in xrange(grating_id_start, 240, 30):
#    f_list = []
#    for i in xrange(0, 10):
#      f_list.append('output_ll1_g%d_%d/tot_f_rate.dat' % (grating_id, i))
   
for k1 in [278]: #[0]:
  for k2 in xrange(8, 240, 30): #[0]:
    f_list = []
    for i in xrange(0, 5): #xrange(0, 10):
      f_list.append('output_ll2_g%d_%d_sd%d/tot_f_rate.dat' % (k2, i, k1))
      #f_list.append('output_g8_%d_sd_190_all/tot_f_rate.dat' % (i))
   
    gids = np.array([])
    f_rate_mean = np.array([])
    for f_name in f_list:
      print 'Processing data from file %s' % (f_name)
      data = np.genfromtxt(f_name, delimiter=' ')
      if (gids.size == 0):
        gids = data[:, 0]
        f_rate_mean = np.zeros(gids.size)
      f_rate = data[:, 1]
      f_rate_mean = f_rate_mean + f_rate
      plt.plot(gids, f_rate)
   
    f_rate_mean = f_rate_mean / (1.0 * len(f_list))
    plt.plot(gids, f_rate_mean, '-o', linewidth=3)
   
    plt.ylim(bottom=0.0)
    plt.xlabel('gid')
    plt.ylabel('Firing rate (Hz)')
    #plt.legend()
    plt.show()

    plt.hist(f_rate_mean[0:8500], bins=np.arange(-0.1, 50.0, 0.1))
    plt.xlabel('Firing rate (Hz)')
    plt.ylabel('Number of cells')
    plt.title('Distribution of firing rates over cells')
    plt.show()
   
    # Get a running average of f_rate_mean; here, we use a solution from http://stackoverflow.com/questions/13728392/moving-average-or-running-mean,
    # under "Efficient solution".
    N_r = 100
    cumsum = np.cumsum(np.insert(f_rate_mean, 0, 0)) 
    f_rate_mean_r_av = (cumsum[N_r:] - cumsum[:-N_r]) / (1.0 * N_r)
   
    plt.plot(gids[(N_r-1):], f_rate_mean_r_av)
    plt.ylim(bottom=0.0)
    plt.xlabel('gid')
    plt.ylabel('Firing rate (Hz)')
    plt.title('Running average of the firing rate, N_r = %d' % (N_r))
    plt.show()
  
