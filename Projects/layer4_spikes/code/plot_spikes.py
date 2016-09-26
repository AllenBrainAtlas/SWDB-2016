import numpy as np
import matplotlib.pyplot as plt

#for grating_id in xrange(8, 240, 30):
#    stim_name = 'g%d' % (grating_id)
#    for i in xrange(0, 2):
#        base_dir = 'output_ll1_g%d_%d_cn2/' % (grating_id, i)
#for stim_name in ['spont']:
#    for i in xrange(0, 20):
#for stim_name in ['8068']: #, '108069', '130034', '163062', 'imk00895', 'imk01220', 'imk01261', 'imk01950', 'imk04208', 'pippin_Mex07_023']:
#for stim_name in ['Protector2_frames_3050_to_3140']:

#for stim_name in ['flash_1']:
for stim_name in ['spont']:
    for i in xrange(8, 9):
    #i = 1
    #for syn_data_id in [228] + range(254, 267):
        syn_data_id = 278
        #base_dir = 'output_ll1_%s_%d_sd%d_test500ms/' % (stim_name, i, syn_data_id)
        base_dir = 'output_ll2_%s_%d_sd%d/' % (stim_name, i, syn_data_id) 

#for base_dir in ['output_ll1_g8_0/', 'output_ll1_g8_0_cn2/']:
        filename = 'spk.dat'
        full_f_name = base_dir + filename
        print 'Processing file %s.' % (full_f_name)
        series = np.genfromtxt(full_f_name, delimiter=' ')

        if (series.size > 2):
          plt.scatter(series[:, 0], series[:, 1], s=1, c='k')
          plt.title('%s' % (base_dir))
          plt.show()


