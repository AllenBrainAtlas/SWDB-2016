import numpy as np
import h5py

f_in = 'output_ll1_g8_8_sd278_test500ms_no_con/v_out-cell-0.dat'
f_out = 'output_ll1_g8_8_sd278_test500ms_no_con/v_out-cell-0.h5'

series = np.genfromtxt(f_in, delimiter=' ')
dt = series[1, 0] - series[0, 0]
values = series[:, 1]
N = values.size

h5 = h5py.File(f_out,libver='latest')
h5.attrs['dt']=dt
h5.create_dataset('values',(N,),maxshape=(None,),chunks=True)
h5['values'][0:N] = values
h5.close()


