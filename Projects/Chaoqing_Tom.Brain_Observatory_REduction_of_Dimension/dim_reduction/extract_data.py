# -*- coding: utf-8 -*-
"""
Created on Tue Sep  6 15:25:36 2016

@author: tom
"""
import pandas as pd
import numpy as np

def extract_data_sg(boc, expt_container_id, selectcells=None):
    """
    Extract and organize single-trial and trial-averaged traces
    For static gratings stimulus
    
    Returns
    -------
    all_mean: DataFrame
        organized trial-averaged response with trial information
    matAll: array-like
        matrix of concatenated single-trial responses
    matAvg: array-like
        matrix of concatenated trial-averaged responses 
    ndAvg
        ndArray of averages for all trial conditions
    """
    #stimulus-type-specific parameters
    interlength = 7
    sweeplength = 7
    tlength = interlength + sweeplength
    typeStim = 'static_gratings'
    typeSession = 'three_session_B'
    
    expt_session_frame = pd.DataFrame(boc.get_ophys_experiments(experiment_container_ids=[expt_container_id]))
    session_id = expt_session_frame[expt_session_frame.session_type==typeSession].id.values[0]  
    data_set = boc.get_ophys_experiment_data(ophys_experiment_id = session_id)  
    stim_table = data_set.get_stimulus_table(typeStim)
    
    #tricks to re-sort cell list
    cell_ids_example = None
    if selectcells is not None:
        cell_specimens_df = pd.DataFrame(boc.get_cell_specimens())
        cell_ids_example = [cell for cell in selectcells if cell_specimens_df[cell_specimens_df.cell_specimen_id==cell].p_dg.values[0]<0.05]
        index = np.argsort(data_set.get_cell_specimen_indices(cell_ids_example))
        cell_ids_example = np.array(cell_ids_example)[index]
    
    #construct combined dataframe of stim_table and sweep responses
    time, dff = data_set.get_dff_traces(cell_ids_example)
    timetrial = time[range(tlength)]
    N = dff.shape[0]
    sweep_response = pd.DataFrame(index=stim_table.index.values, columns=np.arange(N).astype(str))
    for i in range(stim_table.shape[0]):
        for j in range(N):
            sweep_response.at[i,str(j)] = 100*dff[
                j, stim_table.at[i,'start'] + range(tlength)]
    df_all = pd.concat([sweep_response, stim_table], axis=1)
    
    #construct matrix of concatenated single-trial responses
    matAll = np.column_stack([np.concatenate([df_all.iat[i,j] for i in range(df_all.shape[0])]) 
                           for j in range(N)])

    #construct dataframe and matrix of trial-averaged responses for all trial conditions
    all_mean = df_all.groupby(['orientation','spatial_frequency']).apply(lambda x: np.sum(x, axis=0)/len(x))
    all_mean['i'] = range(all_mean.shape[0])
    matAvg = np.column_stack([np.concatenate([all_mean.iat[i,j] for i in range(all_mean.shape[0])]) 
                           for j in range(N)])

    #construct ndArray of averages for all trial conditions, using multi-indexing
    df_multi = all_mean.set_index(['orientation','spatial_frequency']) #cell, tf, ori, time
    ndAvg = np.stack([np.stack([np.stack([df_multi.at[(i1,i2),str(j)] 
                                          for i1 in np.unique(df_multi.index.get_level_values(0))],0)
                                for i2 in np.unique(df_multi.index.get_level_values(1))],0)
                      for j in range(N)],0)
    
    return all_mean, matAll, matAvg, ndAvg

def extract_data_dg(boc, expt_container_id, selectcells=None):
    """
    Extract and organize single-trial and trial-averaged traces
    For drifting gratings stimulus
    
    Returns
    -------
    all_mean: DataFrame
        organized trial-averaged response with trial information
    matAll: array-like
        matrix of concatenated single-trial responses
    matAvg: array-like
        matrix of concatenated trial-averaged responses 
    ndAvg
        ndArray of averages for all trial conditions
    """
    #stimulus-type-specific parameters
    interlength = 30
    sweeplength = 60
    tlength = interlength + sweeplength
    typeStim = 'drifting_gratings'
    typeSession = 'three_session_A'
    
    expt_session_frame = pd.DataFrame(boc.get_ophys_experiments(experiment_container_ids=[expt_container_id]))
    session_id = expt_session_frame[expt_session_frame.session_type==typeSession].id.values[0]  
    data_set = boc.get_ophys_experiment_data(ophys_experiment_id = session_id)  
    stim_table = data_set.get_stimulus_table(typeStim)
    
    #tricks to re-sort cell list
    cell_ids_example = None
    if selectcells is not None:
        cell_specimens_df = pd.DataFrame(boc.get_cell_specimens())
        cell_ids_example = [cell for cell in selectcells if cell_specimens_df[cell_specimens_df.cell_specimen_id==cell].p_dg.values[0]<0.05]
        index = np.argsort(data_set.get_cell_specimen_indices(cell_ids_example))
        cell_ids_example = np.array(cell_ids_example)[index]
    
    #construct combined dataframe of stim_table and sweep responses
    time, dff = data_set.get_dff_traces(cell_ids_example)
    timetrial = time[range(tlength)]
    N = dff.shape[0]
    sweep_response = pd.DataFrame(index=stim_table.index.values, columns=np.arange(N).astype(str))
    for i in range(stim_table.shape[0]):
        for j in range(N):
            sweep_response.at[i,str(j)] = 100*dff[
                j, stim_table.at[i,'start'] + range(tlength)]
    df_all = pd.concat([sweep_response, stim_table], axis=1)
    
    #construct matrix of concatenated single-trial responses
    matAll = np.column_stack([np.concatenate([df_all.iat[i,j] for i in range(df_all.shape[0])]) 
                           for j in range(N)])

    #construct dataframe and matrix of trial-averaged responses for all trial conditions
    all_mean = df_all.groupby(['orientation','temporal_frequency']).apply(lambda x: np.sum(x, axis=0)/len(x))
    all_mean = all_mean[all_mean.temporal_frequency != 0] #cut static grating 
    all_mean['i'] = range(all_mean.shape[0])
    matAvg = np.column_stack([np.concatenate([all_mean.iat[i,j] for i in range(all_mean.shape[0])]) 
                           for j in range(N)])

    #construct ndArray of averages for all trial conditions, using multi-indexing
    df_multi = all_mean.set_index(['orientation','temporal_frequency'])
    ndAvg = np.stack([np.stack([np.stack([df_multi.at[(i1,i2),str(j)] 
                                          for i1 in np.unique(df_multi.index.get_level_values(0))],0)
                                for i2 in np.unique(df_multi.index.get_level_values(1))],0)
                      for j in range(N)],0)
    
    return all_mean, matAll, matAvg, ndAvg
    
def extract_data_ns(boc, expt_container_id, selectcells=None):
    """
    Extract and organize single-trial and trial-averaged traces
    For natural scenes stimulus
    
    Returns
    -------
    all_mean: DataFrame
        organized trial-averaged response with trial information
    matAll: array-like
        matrix of concatenated single-trial responses
    matAvg: array-like
        matrix of concatenated trial-averaged responses 
    ndAvg
        ndArray of averages for all trial conditions
    """
    #stimulus-type-specific parameters
    interlength = 7
    sweeplength = 7
    tlength = interlength + sweeplength
    typeStim = 'natural_scenes'
    typeSession = 'three_session_B'
    
    expt_session_frame = pd.DataFrame(boc.get_ophys_experiments(experiment_container_ids=[expt_container_id]))
    session_id = expt_session_frame[expt_session_frame.session_type==typeSession].id.values[0]  
    data_set = boc.get_ophys_experiment_data(ophys_experiment_id = session_id)  
    stim_table = data_set.get_stimulus_table(typeStim)
    
    #tricks to re-sort cell list
    cell_ids_example = None
    if selectcells is not None:
        cell_specimens_df = pd.DataFrame(boc.get_cell_specimens())
        cell_ids_example = [cell for cell in selectcells if cell_specimens_df[cell_specimens_df.cell_specimen_id==cell].p_dg.values[0]<0.05]
        index = np.argsort(data_set.get_cell_specimen_indices(cell_ids_example))
        cell_ids_example = np.array(cell_ids_example)[index]
    
    #construct combined dataframe of stim_table and sweep responses
    time, dff = data_set.get_dff_traces(cell_ids_example)
    timetrial = time[range(tlength)]
    N = dff.shape[0]
    sweep_response = pd.DataFrame(index=stim_table.index.values, columns=np.arange(N).astype(str))
    for i in range(stim_table.shape[0]):
        for j in range(N):
            sweep_response.at[i,str(j)] = 100*dff[
                j, stim_table.at[i,'start'] + range(tlength)]
    df_all = pd.concat([sweep_response, stim_table], axis=1)
    
    #construct matrix of concatenated single-trial responses
    matAll = np.column_stack([np.concatenate([df_all.iat[i,j] for i in range(df_all.shape[0])]) 
                           for j in range(N)])

    #construct dataframe and matrix of trial-averaged responses for all trial conditions
    all_mean = df_all.groupby([ 'frame']).apply(lambda x: np.sum(x, axis=0)/len(x))
    all_mean['i'] = range(all_mean.shape[0])
    matAvg = np.column_stack([np.concatenate([all_mean.iat[i,j] for i in range(all_mean.shape[0])]) 
                           for j in range(N)])

    #construct ndArray of averages for all trial conditions, using multi-indexing
    ndAvg = np.stack([np.stack([all_mean.iat[i1,j] for i1 in range(len(all_mean.frame.unique()))],0)
                      for j in range(N)],0)
    
    return all_mean, matAll, matAvg, ndAvg