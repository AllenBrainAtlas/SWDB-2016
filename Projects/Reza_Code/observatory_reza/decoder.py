from __future__ import division
import classifier as clss
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from array_utility import permute_columns

def cros_validate(number_lambd,X_train,Y_train,X_test,Y_test,X_shuffle_train,Y_shuffle_train):
    lambda_vals = np.logspace(-4, -1, number_lambd)
    test_error = np.zeros(number_lambd)
    train_error = np.zeros(number_lambd)

    for j, lambd in enumerate(lambda_vals):
        beta, v = clss.svm(X_train, Y_train, lambd)
        test_error[j] = clss.svm_test(X_test, Y_test, beta, v)
        train_error[j] = clss.svm_test(X_train, Y_train, beta, v)

    shuffle_test_error = np.zeros(number_lambd)
    shuffle_train_error = np.zeros(number_lambd)

    for j, lambd in enumerate(lambda_vals):
        beta2, v2 = clss.svm(X_shuffle_train, Y_shuffle_train, lambd)
        shuffle_test_error[j] = clss.svm_test(X_test, Y_test, beta2, v2)
        shuffle_train_error[j] = clss.svm_test(X_shuffle_train, Y_shuffle_train, beta2, v2)
    return test_error, shuffle_test_error


def svm_decoder(X_original,Y_original,fr,dg):
    X_shuffle = np.zeros(X_original.shape)
    X_original.shape
    fr_shuffle = np.zeros(X_original.shape)
    Y_shuffle = Y_original.copy()

    # Shuffle
    for ci, on in enumerate(dg.stim_table.orientation.unique()):
        for di, tf in enumerate(dg.stim_table['temporal_frequency'].unique()):
            unique_index = dg.stim_table[
                (dg.stim_table.orientation == on) & (dg.stim_table['temporal_frequency'] == tf)].index
            X_shuffle[unique_index], ixi, ixj = permute_columns(X_original[unique_index])
            fr_shuffle[unique_index]= (fr[unique_index])[ixi,ixj]
    number_trials = 100;
    number_cells = 50;
    number_test = 30;
    number_lambd = 4;
    number_of_repeats = 25;
    shuffle_vector = []
    original_vector = []
    fr_shuffle_vector = []
    fr_vector = []

    for nr in range(number_of_repeats):
        print(nr)
        cell_ind = np.random.choice(X_original.shape[1], number_cells, replace=False);
        trial_ind = np.random.choice(len(Y_original), number_trials, replace=False);
        test_ind = np.random.choice(len(Y_original), number_test, replace=False);
        X_train = X_original[trial_ind, :][:, cell_ind];
        Y_train = Y_original[trial_ind];
        X_test = X_original[test_ind, :][:, cell_ind];
        Y_test = Y_original[test_ind];
        X_shuffle_train = X_shuffle[trial_ind, :][:, cell_ind]
        Y_shuffle_train = Y_shuffle[trial_ind]
        fr_train = fr[trial_ind, :][:, cell_ind];
        fr_test = fr[test_ind, :][:, cell_ind];
        fr_shuffle_train = fr_shuffle[trial_ind, :][:, cell_ind]
        ot,st = cros_validate(number_lambd, X_train, Y_train, X_test, Y_test, X_shuffle_train, Y_shuffle_train)
        fr_ot, fr_st = cros_validate(number_lambd, fr_train, Y_train, fr_test, Y_test, fr_shuffle_train, Y_shuffle_train)
        original_vector = original_vector + [1-ot.min()]
        shuffle_vector =  shuffle_vector+   [1-st.min()]
        fr_vector = fr_vector+ [1-fr_ot.min()]
        fr_shuffle_vector = fr_shuffle_vector +  [1-fr_st.min()]


    plt.figure()
    plt.boxplot([original_vector, shuffle_vector, fr_vector, fr_shuffle_vector])
    plt.xticks(np.arange(4) + 1, ('simultaneous (Ca)', 'shuffled (Ca)', 'simultaneous (f. rate)', 'shuffled_fr (f. rate)'))
    plt.ylim((0, 1))
    plt.ylabel('Decoder Performance')
    plt.show()


def svm_decoder_dsi(X_original,Y_original,fr,dg,dsi):
    X_shuffle = np.zeros(X_original.shape)
    fr_shuffle = np.zeros(X_original.shape)
    Y_shuffle = Y_original.copy()
    # Shuffle
    for ci, on in enumerate(dg.stim_table.orientation.unique()):
        for di, tf in enumerate(dg.stim_table['temporal_frequency'].unique()):
            unique_index = dg.stim_table[
                (dg.stim_table.orientation == on) & (dg.stim_table['temporal_frequency'] == tf)].index
            X_shuffle[unique_index], ixi, ixj = permute_columns(X_original[unique_index])
            fr_shuffle[unique_index]= (fr[unique_index])[ixi,ixj]
    number_trials = 100;
    number_cells = 50;
    number_test = 30;
    number_lambd = 3;
    number_of_repeats = 30;
    range_of_num = range(2,55,1)
    shuffle_vector = []
    original_vector = []
    fr_shuffle_vector = []
    fr_vector = []



    for bc,nb in enumerate(range_of_num):
        ot_sum = 0;
        st_sum = 0;
        fr_sum = 0;
        fr_st_sum = 0;
        cell_ind = (np.argsort(dsi.flatten()))[-nb - 1:-1]
        for nr in range(number_of_repeats):
            print(nb, ':', nr)
            trial_ind = np.random.choice(len(Y_original), number_trials, replace=False);
            test_ind = np.random.choice(len(Y_original), number_test, replace=False);
            X_train = X_original[trial_ind, :][:, cell_ind];
            Y_train = Y_original[trial_ind];
            print('should be 8:  ', len(np.unique(Y_train)))
            X_test = X_original[test_ind, :][:, cell_ind];
            Y_test = Y_original[test_ind];
            X_shuffle_train = X_shuffle[trial_ind, :][:, cell_ind]
            Y_shuffle_train = Y_shuffle[trial_ind]
            fr_train = fr[trial_ind, :][:, cell_ind];
            fr_test = fr[test_ind, :][:, cell_ind];
            fr_shuffle_train = fr_shuffle[trial_ind, :][:, cell_ind]
            ot,st = cros_validate(number_lambd, X_train, Y_train, X_test, Y_test, X_shuffle_train, Y_shuffle_train)
            fr_ot, fr_st = cros_validate(number_lambd, fr_train, Y_train, fr_test, Y_test, fr_shuffle_train, Y_shuffle_train)
            ot_sum += ot.min()
            st_sum += st.min()
            fr_sum += fr_ot.min()
            fr_st_sum += fr_st.min()
        original_vector = original_vector + [1-(ot_sum/number_of_repeats)]
        shuffle_vector =  shuffle_vector+   [1-(st_sum/number_of_repeats)]
        fr_vector = fr_vector+ [1-(fr_sum/number_of_repeats)]
        fr_shuffle_vector = fr_shuffle_vector +  [1-(fr_st_sum/number_of_repeats)]
    t = range_of_num
    plt.figure()
    plt.plot(t, original_vector, t, shuffle_vector, 'r--', t, fr_vector, 'k', t, fr_shuffle_vector)
    plt.legend(['Sim (Ca)', 'Shuf (Ca)', 'Sim (FR)', 'Shuf (FR)'])
    plt.show()


def fisher_information(mu,C):
    fi = 0;
    for i in range(len(C)):
       fi += np.dot(np.dot(mu[i] - mu[i-1],np.linalg.pinv(C[i])),mu[i] - mu[i-1])
    return fi

def fisher_analysis(X,dg):
    X_shuffle = np.zeros(X.shape)
    # Shuffle
    mu = [];
    C = [];
    C2 = [];
    fisher_info = 0
    fisher_info_shuffle = 0
    for di, tf in enumerate([dg.stim_table['temporal_frequency'].unique()[0]]):
        for ci, on in enumerate(dg.stim_table.orientation.unique()):
            unique_index = dg.stim_table[
                (dg.stim_table.orientation == on) & (dg.stim_table['temporal_frequency'] == tf)].index
            X_shuffle[unique_index], ixi, ixj = permute_columns(X[unique_index])
            mu = mu + [(X[unique_index]).mean(axis=0)]
            print(mu[0].shape)
            temp_X = X[unique_index];
            temp_X_shuffle = X_shuffle[unique_index];
            C  = C + [np.cov(temp_X.T)]
            C2 = C2 + [np.cov(temp_X_shuffle.T)]
        print(fisher_information(mu, C))
        fisher_info +=fisher_information(mu, C)
        fisher_info_shuffle +=fisher_information(mu, C2)

    return fisher_info, fisher_info_shuffle
