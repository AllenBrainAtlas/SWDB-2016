import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage.filters import gaussian_filter1d
import cobra_analysis

"""
Module to generate synthetic signals for validation
Author: Max Nolte
"""


def cont_random_model_one(n_cells, duration=1000, dt=0.01, coupling_factor=0.1, sigma=10):
    """
    Function to return an arry of correlated filtered Gaussian time series
    :return: n_cells x n_bins matrix of simulated time series for each cell
    """
    n_bins = int(duration/dt)
    activity_matrix = np.random.randn(n_cells, n_bins)
    corr_activity = np.random.randn(1, n_bins)
    activity_matrix += coupling_factor * corr_activity

    activity_matrix = activity_matrix / activity_matrix.std(axis=1)[:, None]

    activity_matrix = gaussian_filter1d(activity_matrix, sigma=sigma/dt)
    return activity_matrix.transpose()


def get_set_of_coupled_activity_matrices(n_cells, coupling_factors=np.linspace(0, 2, 10),
                                         duration=2000, dt=1.0):
    """
    Function to return a set of activity matrices with different coupling factors
    :param n_cells:
    :param coupling_factors:
    :param duration:
    :param dt:
    :return: activity_matrices: n_cells x n_bins x n_coupling factors, coupling factors
    """
    n_bins = int(duration / dt)
    activity_matrices = np.zeros((n_bins, n_cells, coupling_factors.size))
    for i, corr in enumerate(coupling_factors):
        activity_matrices[:, :, i] = cont_random_model_one(n_cells, duration=duration, dt=dt,
                                                           coupling_factor=corr)
    return activity_matrices, coupling_factors


def generate_poisson_spike_train(rate, t_start=0, t_stop=1000, dt=0.001, seed=0):
    """
    Generate homogeneous poisson spike train
    :param rate:
    :param t_start:
    :param t_stop:
    :param dt:
    :param seed:
    :return:
    """
    n_bins = int((t_stop - t_start)/dt)
    np.random.seed(seed)
    probs = np.random.rand(n_bins)
    return np.argwhere(probs <= rate/1000.0 * dt).flatten() * dt


def generate_poisson_spike_train_population(n_cells, rate, t_start=0, t_stop=1000,
                                            dt=0.001, seed=0, correlation=0):
    """
    Generate homogeneous poisson spike train population (correlated)
    :param n_cells:
    :param rate:
    :param t_start:
    :param t_stop:
    :param dt:
    :param seed:
    :param correlation:
    :return:
    """
    spikes_list = []
    cell_id_list = []
    if correlation == 0:
        for i in range(n_cells):
            spikes = generate_poisson_spike_train(rate, t_start=t_start, t_stop=t_stop,
                                                  dt=dt, seed=i+seed)
            spikes_list.append(spikes)
            cell_id_list.append(np.zeros(spikes.size, dtype=int) + i)
        return np.hstack(spikes_list), np.hstack(cell_id_list)
    else:
        return _generate_corr_poisson_spike_train_population(n_cells, rate, t_start=t_start,
                                    t_stop=t_stop, dt=dt, seed=seed, correlation=correlation)


def _generate_corr_poisson_spike_train_population(n_cells, rate, t_start=0, t_stop=1000,
                                                dt=0.001, seed=0, correlation=0.1):
    """
    internal methods to generate correlated Poisson spike trains
    :param n_cells:
    :param rate:
    :param t_start:
    :param t_stop:
    :param dt:
    :param seed:
    :param correlation:
    :return:
    """
    mother_train = generate_poisson_spike_train(rate/correlation, t_start=t_start,
                                                t_stop=t_stop, dt=dt, seed=seed)
    spikes_list = []
    cell_id_list = []
    np.random.seed(seed + 2050)
    for i in range(n_cells):
        n_spikes = generate_poisson_spike_train(rate, t_start=t_start, t_stop=t_stop,
                                                  dt=dt, seed=i + seed).size
        if n_spikes <= mother_train.size:
            spikes = mother_train[np.random.permutation(mother_train.size)[:n_spikes]]
        else:
            spikes = mother_train
        spikes = np.sort(spikes + 3.0 * np.random.randn(spikes.size))
        spikes[spikes < t_start] = t_start
        spikes[spikes > t_stop] = t_stop
        spikes_list.append(spikes)
        cell_id_list.append(np.zeros(spikes.size, dtype=int) + i)
    return np.hstack(spikes_list), np.hstack(cell_id_list)


def cont_random_model_one_heterogeneous(n_cells, duration=1000, dt=0.01, coupling_factor=0.5,
                                        sigma=10):
    """
    Function to return an arry of correlated filtered Gaussian time series
    :return: n_cells x n_bins matrix of simulated time series for each cell
    """
    n_bins = int(duration/dt)
    activity_matrix = np.random.randn(n_cells, n_bins)
    corr_activity = np.random.randn(1, n_bins)
    activity_matrix += (np.random.rand(n_cells)[:, None] * coupling_factor) * corr_activity

    activity_matrix = activity_matrix / activity_matrix.std(axis=1)[:, None]

    activity_matrix = gaussian_filter1d(activity_matrix, sigma=sigma/dt)
    return activity_matrix.transpose()


def plot_random_time_series_test():
    """
    Plot correlated time series for validation
    :return:
    """
    activity_matrices, coupling_factors = get_set_of_coupled_activity_matrices(10)
    fig, axs = plt.subplots(10, sharex=True)
    for i in range(activity_matrices.shape[-1]):
        axs[i].plot(activity_matrices[:, :, i])
        axs[i].set_title('Coupling factor = %.2f' % coupling_factors[i])
    axs[-1].set_xlabel('t (ms)')
    axs[0].set_ylabel('Signal strength')
    plt.show()


def plot_correlated_spikes_test():
    """
    Plot correlated spike trains for validation
    :return:
    """
    fig, axs = plt.subplots(5, sharex=True)
    for i, ax in enumerate(axs):
        spikes, cells = generate_poisson_spike_train_population(30, 6, correlation=i*0.05,
                                                                t_start=0, t_stop=1000)
        for j in range(30):
            bottom = np.ones(spikes[cells == j].size) * j
            top = bottom + 1
            ax.vlines(spikes[cells == j], bottom, top)
    plt.show()


def plot_correlated_spikes_shuffled_test():
    """
    Plot correlated but shuffled spike trains for validation
    :return:
    """
    fig, axs = plt.subplots(5, sharex=True)
    for i, ax in enumerate(axs):
        spikes, cells = generate_poisson_spike_train_population(30, 6, correlation=i*0.05,
                                                                t_start=0, t_stop=1000)
        spikes, cells = cobra_analysis.shuffle_spikes_homogenous(spikes, cells, 30, t_start=0,
                                                                 t_end=1000)
        for j in range(30):
            bottom = np.ones(spikes[cells == j].size) * j
            top = bottom + 1
            ax.vlines(spikes[cells == j], bottom, top)
    plt.show()


def run_signal_tests():
    """
    Test all synthetic data generation functions
    :return:
    """
    plot_random_time_series_test()
    plot_correlated_spikes_test()
    plot_correlated_spikes_shuffled_test()


if __name__ == "__main__":
    run_signal_tests()
