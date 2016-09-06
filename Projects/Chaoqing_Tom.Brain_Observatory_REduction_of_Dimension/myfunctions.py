###########################
#
# Section: Prepare ENV
#
# #########################

import numpy as np
import pandas as pd
import seaborn as sns
import scipy
import scipy.io
import sklearn
import random

import os
import sys
import pickle
# from IPython.display import display

import matplotlib
# matplotlib.use('Agg')
import matplotlib.pyplot as plt

from allensdk.core.brain_observatory_cache import BrainObservatoryCache
from allensdk.brain_observatory.drifting_gratings import DriftingGratings
from allensdk.brain_observatory.natural_movie import NaturalMovie
from allensdk.brain_observatory.static_gratings import StaticGratings
from allensdk.brain_observatory.natural_scenes import NaturalScenes
from allensdk.brain_observatory.locally_sparse_noise import LocallySparseNoise

drive_path = filter(os.path.exists,
                    ['/Volumes/Brain2016/BrainObservatory',
                     '/Users/nick/Study/Database_Works/CAM20151012/test/data/new-released/boc',
                     '/home/server/Study/Database_Works/CAM20151012/test/data/new-released/boc'])[0]

manifest_path = os.path.join(drive_path, 'manifest.json')
boc = BrainObservatoryCache(manifest_file=manifest_path)

#
pd.set_option('display.max_columns', 100)
pd.set_option('display.max_rows', 5)
# with pd.option_context('display.max_rows', 999, 'display.max_columns', 3):
#    print df

# sns.set_style('whitegrid')
# sns.set_palette("hls", 1)
# sns.reset_orig()





###########################
#
# Section: Functions
#
# #########################

## simple function
match = lambda a, b: [b.index(x) if x in b else None for x in a]
mean_std = (lambda x: (x.mean(), x.std()) if len(x) > 1 else (x, np.nan))
mean_std_max = (lambda x: (x.mean(), x.std(), x.max()) if len(x) > 1 else (x, np.nan, x))
find_key_from_value = lambda v, d: d.keys()[np.where(d.values()==v)[0]]

## estimate binary state of cell
def seperate_high_low(x, stdn=3):
    kde = scipy.stats.gaussian_kde(x, bw_method='scott')

    low_dff = scipy.optimize.fmin(lambda x: -kde(x), x0=0, disp=False)[0]
    half_dff = x[x < low_dff]
    # low_dff_std = np.sqrt((half_dff*half_dff).mean()-2*low_dff*(half_dff).mean())
    low_dff_std = np.concatenate((half_dff, 2 * low_dff - half_dff)).std()
    high_dff = x[x > low_dff + low_dff_std * stdn].mean()

    return low_dff, high_dff, low_dff_std, kde



def get_time_traces(data_set, cell_ids_example):
    index = np.argsort(data_set.get_cell_specimen_indices(cell_ids_example))
    timestamps, fluo = data_set.get_corrected_fluorescence_traces(cell_ids_example[index])
    timestamps, dff = data_set.get_dff_traces(cell_ids_example[index])

    return timestamps, dict(zip(cell_ids_example[index], fluo)), dict(zip(cell_ids_example[index], dff))


##
def get_stimulus_table(id):

    data_set = boc.get_ophys_experiment_data(id)

    def stimulus_table(stim):
        stimulus_table = data_set.get_stimulus_table(stimulus_name=stim)
        stimulus_table['stimulus_name'] = stim
        return stimulus_table

    stimulus_table = pd.concat([stimulus_table(stim) for stim in data_set.list_stimuli()]).sort_values('start')
    # bug fix: end must be at least larger 1 than start
    stimulus_table.end = np.maximum.reduce([stimulus_table.start+1, stimulus_table.end])
    stimulus_table['session_type'] = data_set.get_metadata()['session_type']
    stimulus_table['id'] = id
    return stimulus_table

##
def extract_feature(exp_id,
                    cell_ids = None,
                    stimulus_name=None,
                    include_interval=False,
                    cache=True, path='data/'):

    if cache==True and os.path.exists('features-%d.pkl' % exp_id):
        return pickle.load(open(path+'features-%d.pkl' % exp_id, "rb" ))

    data_set = boc.get_ophys_experiment_data(exp_id)
    dff = data_set.get_dff_traces()[1]
    fluo = data_set.get_corrected_fluorescence_traces()[1]
    speed = data_set.get_running_speed()[1]

    cell_ids_all = data_set.get_cell_specimen_ids()
    if not cell_ids:
        cell_ids = cell_ids_all
    else:
        cell_ids_index = match(cell_ids, cell_ids_all.tolist())

        if any(map(np.isnan, cell_ids_index)):
            raise ValueError('some cell_ids not in this experiment.')

        dff = dff[cell_ids_index]
        fluo = fluo[cell_ids_index]

    stimulus_table = get_stimulus_table(exp_id)

    if include_interval:
        start_end = np.concatenate((np.array([0, min(dff.shape[1], fluo.shape[1])]),
                                    stimulus_table.start.values,
                                    stimulus_table.end.values))
        start_end = np.sort(np.unique(start_end))
        start_end = zip(start_end[:-1],start_end[1:])
    else:
        start_end= zip(stimulus_table.start.values, stimulus_table.end.values)

    if stimulus_name:
        stimulus_table = stimulus_table[np.in1d(stimulus_table.stimulus_name,stimulus_name)]

        if include_interval:
            start_select = np.unique(np.concatenate((stimulus_table.start.values,
                                                     stimulus_table.end.values)))
        else:
            start_select = stimulus_table.start.values

        start_end = filter(lambda (start,end): start in start_select, start_end)

    base_metrics_names = ['low_dff', 'high_dff', 'low_dff_std']
    metrics_names = ['high_dff_frames', 'high_dff_frames_ratio',
                     'low_dff_mean', 'low_dff_std',
                     'high_dff_mean', 'high_dff_std', 'high_dff_max',
                     'fluo_mean','fluo_std', 'high_dff_max_ratio'
                     ]

    speed_names = ['speed_mean', 'speed_std', 'speed_max']

    base_metrics = np.empty((len(cell_ids), len(base_metrics_names)))
    base_metrics.fill(np.nan)
    metrics = np.empty((len(cell_ids), len(start_end), len(metrics_names)))
    metrics.fill(np.nan)

    for i in range(len(cell_ids)):
        base_metrics[i] = seperate_high_low(dff[i])[:-1]
        low_dff, high_dff, low_dff_std = base_metrics[i]
        for j, (starti,endi) in enumerate(start_end):
            dff_single = dff[i][starti:endi]
            fluo_single = fluo[i][starti:endi]

            high_index = dff_single>low_dff+low_dff_std*3

            metrics_single = metrics[i, j]

            metrics_single[0] = high_index.sum() # high_dff frames
            metrics_single[1] = metrics_single[0]/len(high_index) # high_dff frames ratio

            if metrics_single[1] != 1:
                # mean low_dff, std low_dff
                metrics_single[2:4] = mean_std(dff_single[~high_index])
            if metrics_single[0] != 0:
                # mean high_dff, std high_dff, maximal high_dff
                metrics_single[4:7] = mean_std_max(dff_single[high_index])
                metrics_single[7:9] = mean_std(fluo_single)
                metrics_single[9] =  (metrics_single[6]-low_dff)/low_dff_std

    running_speed = np.array([mean_std_max(speed[starti:endi]) for (starti, endi) in start_end])

    features = {'base_metrics_names': dict(zip(base_metrics_names, range(len(base_metrics_names)))),
                'base_metrics': base_metrics,

                'stimulus_table': stimulus_table,

                'cell_ids': dict(zip(cell_ids, range(len(cell_ids)))),
                'start_end': start_end,
                'metrics_names': dict(zip(metrics_names, range(len(metrics_names)))),
                'metrics': metrics,

                'speed_names': dict(zip(speed_names, range(len(speed_names)))),
                'speed': running_speed
                }

    if not stimulus_name and not cell_ids:
        pickle.dump(features, open(path+'features-%d.pkl' % exp_id, "wb"))

    return features