#!/usr/bin/env python

from myfunctions import *

import sys

for exp in boc.get_ophys_experiments(
        stimuli=['drifting_gratings', 'static_gratings'],
        targeted_structures=['VISp'],
        imaging_depths=[175]):
    exp_id = exp['id']
    p = extract_feature(exp_id, stimulus_name=['drifting_gratings', 'static_gratings'], cache=False)
    pickle.dump(p, open('data/features-%d-gratings.pkl' % exp_id, "wb"))

    print('%d done.' % exp_id)


# for exp_id in sys.argv[1:]:
#     print('%s start...' % exp_id)
#     try:
#         p = extract_feature(int(exp_id))
#         print('%s is done.' % exp_id)
#     except:
#         print('%s failed.' % exp_id)
