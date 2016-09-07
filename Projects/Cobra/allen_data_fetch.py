import numpy as np
import pandas as pd
import os

"""Module interacts with the allen sdk.
Philip Mardoum
Sept 2016"""

from allensdk.core.brain_observatory_cache import BrainObservatoryCache
from allensdk.brain_observatory.natural_movie import NaturalMovie
from allensdk.brain_observatory import stimulus_info

def get_boc(drive_path='/Volumes/Brain2016/'):
    """
    Grab BrainObservatoryCache
    :param drive_path:
    :return: boc
    """
    manifest_path = os.path.join(drive_path, 'BrainObservatory/manifest.json')
    boc = BrainObservatoryCache(manifest_file=manifest_path)
    return boc


def get_activity_matrix(container_id, session_idx, stim_type, units='all', trace_type='corrected'):
    """

    :param container_id: experiment container ID
    :param session_idx: either 0, 1, or 2
    :param stim_type:
    :param units: either 'all' or 'stable'.  Choose whether to filter for cells that are identified in all 3 sessions
    :return: activity_matrix
    """

    # get BrainObservatoryCache
    boc = get_boc()

    # get ophys experiments from requested experiment container
    expt_session_info = pd.DataFrame(boc.get_ophys_experiments(experiment_container_ids=[container_id]))
    print('Experiment container info:')
    print(boc.get_experiment_containers(ids=[container_id]))

    # Create list of 3 session IDs in exp container, in standard order.
    container_session_ids = [expt_session_info[expt_session_info['session_type'] == 'three_session_A']['id'].values[0],
                             expt_session_info[expt_session_info['session_type'] == 'three_session_B']['id'].values[0],
                             expt_session_info[expt_session_info['session_type'] == 'three_session_C']['id'].values[0]]

    stim_list = boc.get_ophys_experiment_data(ophys_experiment_id=container_session_ids[session_idx]).list_stimuli()
    if 'natural_movie_three' in stim_list:
        stim_list.append(unicode('natural_movie_three_2'))
    if stim_type not in stim_list:
        raise ValueError('Requested stim_type is not present in the stimulus names for requested session.')

    # -Create data_set object for each session, place them in a list
    # -Get specimen ids for each session, put arrays in list
    data_sets = []
    specimens_by_session = []
    for i in range(3):
        data_sets.append(boc.get_ophys_experiment_data(ophys_experiment_id=container_session_ids[i]))
        specimens_by_session.append(data_sets[i].get_cell_specimen_ids())
    specimens_by_session = np.array(specimens_by_session)

    # Find cell specimens present in all 3 sessions
    stable_specimen_ids = set(specimens_by_session[0]) & set(specimens_by_session[1]) & set(specimens_by_session[2])
    stable_specimen_ids = np.array(list(stable_specimen_ids))

    # After this point everything is specific to the session_idx chosen above...
    current_data_set = data_sets[session_idx]
    stable_specimen_indices = current_data_set.get_cell_specimen_indices(stable_specimen_ids)

    print('Stimuli in selected session:')
    print(current_data_set.list_stimuli())
    print('')
    if units == 'stable':
        print('Retrieving traces only for STABLE units')

    # get requested activity_matrix
    if stim_type == 'spontaneous':
        timestamps, traces = get_traces(units, current_data_set, stable_specimen_indices, trace_type) # line could be moved up
        stim_table = current_data_set.get_stimulus_table('spontaneous')
        activity_matrix = traces[:, stim_table.start[0]: stim_table.end[0]]

    elif stim_type == 'drifting_gratings':
    # Currently creates activity_matrix with traces only from the first of 3 drifing gratings blocks
        timestamps, traces = get_traces(units, current_data_set, stable_specimen_indices, trace_type)
        stim_table = current_data_set.get_stimulus_table('drifting_gratings')
        activity_matrix = traces[:, stim_table.start[0]: stim_table.end[199]]

    elif stim_type == 'natural_scenes':
    # Currently creates activity_matrix with traces only from the first of 3 natural scenes blocks
        timestamps, traces = get_traces(units, current_data_set, stable_specimen_indices, trace_type)
        stim_table = current_data_set.get_stimulus_table('natural_scenes')
        activity_matrix = traces[:, stim_table.start[0]: stim_table.end[1919]]

    elif stim_type[:13] == 'natural_movie':
        timestamps, traces = get_traces(units, current_data_set, stable_specimen_indices, trace_type)
        stim_table = current_data_set.get_stimulus_table(stim_type[:19]) # index to drop '_2' in 'natural_movie_three_2'

        if stim_type == 'natural_movie_three':
            # Since movie three is presented in two blocks, take only first block for now
            activity_matrix = traces[:, stim_table.start[0]: stim_table.end[17999]]
        elif stim_type == 'natural_movie_three_2':
            activity_matrix = traces[:, stim_table.start[18000]: stim_table.end.values[-1]]
        else:
            activity_matrix = traces[:, stim_table.start[0]: stim_table.end.values[-1]]

        # # The following only pulls first presentation of the movie...
        # nm = NaturalMovie(current_data_set, movie_name=stim_type)
        # sweep_response = nm.sweep_response
        #
        # if units == 'all':
        #     activity_matrix = np.zeros((sweep_response.shape[1], len(sweep_response.iloc[0, 0])))
        #     for i in range(sweep_response.shape[1]):
        #         activity_matrix[i, :] = sweep_response.iloc[0, i]
        # elif units == 'stable':
        #     activity_matrix = np.zeros((len(stable_specimen_indices), len(sweep_response.iloc[0, 0])))
        #     for i in range(len(stable_specimen_indices)):
        #         activity_matrix[i, :] = sweep_response.iloc[0, i]

    else:
        print('Failed to create activity matrix, or experiment type not available')

    activity_matrix = activity_matrix.T
    return activity_matrix


def get_traces(units, current_data_set, stable_specimen_indices, trace_type):
    # Get raw data
    if trace_type == 'corrected':
        timestamps, traces = current_data_set.get_corrected_fluorescence_traces()
    elif trace_type == 'dff':
        timestamps, traces = current_data_set.get_dff_traces()

    # Filter (or not) for units that are stable across all 3 sessions
    if units == 'all':
        pass
    elif units == 'stable':
        traces = traces[stable_specimen_indices, :]

    return (timestamps, traces)


def get_container_list():
    boc = get_boc()
    expt_cont_list = pd.DataFrame(boc.get_experiment_containers())
    return expt_cont_list


def split_activity_matrix(activity_matrix):
    split_point = activity_matrix.shape[0]//2
    half_1 = activity_matrix[:split_point, :]
    half_2 = activity_matrix[split_point:, :]
    return (half_1, half_2)


def test():
    activity_matrix = get_activity_matrix()
    print activity_matrix.shape
    print 'test successful'


if __name__ == "__main__":
    test()
