import start as start
import time

start_time = time.time()
start.run_simulation('config_sim_1_2.json')

print('***Simulation finished in %.2fs***'%(time.time()-start_time))
