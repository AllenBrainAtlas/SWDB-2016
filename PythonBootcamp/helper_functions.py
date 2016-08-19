import numpy as np

def spike_generator(ntrials,t=5,refractory_period=0.01,peak_prob=0.1):
    t = np.arange(0,t,0.025)
    p = peak_prob*np.sin(2*np.pi*t)+peak_prob
    
    all_trials = []
    for trial in range(ntrials):
        spike_times = []
        last_spike = 0
        for ii in range(len(t)):
            spike = np.random.choice([0,1],p=[1-p[ii],p[ii]])
            if spike == 1 and t[ii] > last_spike + refractory_period:
                spike_times.append(t[ii])
                last_spike = t[ii]
        all_trials.append(spike_times)
            
    return all_trials

def flatten_list(in_list):
    out_list = []
    for i in range(len(in_list)):
        for entry in in_list[i]:
            out_list.append(entry)
    return out_list