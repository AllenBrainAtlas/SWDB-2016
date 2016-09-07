import numpy as np
from scipy.ndimage.filters import gaussian_filter1d


"""
Module to produce population coupling metric given spiketimes for each cell
Author: Madineh Sarvestani, Max Nolte
Sept 2016
"""


def pop_corr(activity_matrix):
    """
    main function for population coupling metric. input is timeseriesxncells.
    output is 1xn population metric.
    time series with variable coupling (time, n_cells) are the input
    Author: Madineh, Phil & Max

    :param activity_matrix: Time series per cell
    :return: pop_corr_array: Population coupling per cell
    """
    activity_matrix_mean_adj = activity_matrix - activity_matrix.mean(axis=0)

    n_cells = activity_matrix.shape[1]
    # preallocate one matrix for averages

    sum_mean_adj = activity_matrix_mean_adj.sum(axis=1)
    pop_corr_array = np.zeros((n_cells, 1))

    for i in range(n_cells):
        cell_excluded_sum_mean_adj = sum_mean_adj - activity_matrix_mean_adj[:, i]

        pop_corr_array[i] = np.sum(activity_matrix[:, i] * cell_excluded_sum_mean_adj) \
                            / activity_matrix[:, i].std()

    return pop_corr_array


def pop_corr_z_scored(activity_matrix):
    """
    return mean population coupling divided by sample standard deviation
    Author: Max

    :param activity_matrix: Time series per cell
    :return: pop_corr_array: Z-scored population coupling per cell
    """
    pop_array = pop_corr(activity_matrix)
    return (pop_array-pop_array.mean())/pop_array.std(ddof=1)


def pop_corr_spikes(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    Returns NON-NORMALIZED population coupling array for spikes

    :return:
    """
    n_bins = int((t_end - t_start) / dt_conv)
    print n_bins
    print n_cells

    activity_matrix = np.zeros((n_bins, n_cells))

    fr_ms = np.zeros(n_cells)
    for i in range(n_cells):
        indices = cell_ids == i
        fr_ms[i] = np.sum(indices)/float((t_end - t_start))
        activity_matrix[:, i] = gaussian_filter_psth(spike_times[indices], t_start, t_end,
                                                     dt_conv, sigma_conv)

    activity_matrix_mean_adj = activity_matrix - fr_ms

    sum_mean_adj = activity_matrix_mean_adj.sum(axis=1)
    pop_corr_array = np.zeros((n_cells, 1))
    for i in range(n_cells):
        cell_excluded_sum_mean_adj = sum_mean_adj - activity_matrix_mean_adj[:, i]

        pop_corr_array[i] = np.sum(activity_matrix[:, i] * cell_excluded_sum_mean_adj) \
                            / (fr_ms[i] * (t_end - t_start))
    return pop_corr_array


def gaussian_filter_psth(spikes, t_start, t_end, dt, sigma_conv):
    """

    :param spikes:
    :param t_start:
    :param t_end:
    :param dt:
    :param sigma_conv:
    :return:
    """
    n_bins = int((t_end - t_start) / dt)
    bins = np.linspace(t_start, t_end, n_bins + 1)
    sigma = sigma_conv / dt
    return gaussian_filter1d(np.histogram(spikes, bins=bins)[0].astype(float), sigma=sigma)


def pop_corr_spikes_shuffled(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    Returns NON-NORMALIZED population coupling array for spikes

    :return:
    """
    spike_times, cell_ids = shuffle_spikes_okun(spike_times, cell_ids, n_cells, t_start, t_end)
    return pop_corr_spikes(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)


def pop_corr_spikes_z_scored(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    return population coupling devided by sample standard deviation
    :return:
    """
    pop_array = pop_corr_spikes(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)
    return (pop_array-pop_array.mean())/pop_array.std(ddof=1)


def pop_corr_spikes_shuffle_scored(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    pop_array = pop_corr_spikes(spike_times, cell_ids)
    return pop_array.mean() / pop_array.std(ddof=1)
    :return:
    """
    pop_array = pop_corr_spikes(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)
    shuffle_array = pop_corr_spikes_shuffled(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)
    return pop_array/np.median(shuffle_array)


def shuffle_spikes_homogenous(spike_times, cell_ids, n_cells, t_start, t_end):
    """
    Shuffling, keeping ISIs
    :return:
    """
    spike_times = spike_times.copy()
    cell_ids = cell_ids.copy()
    for i in range(n_cells):
        indices = cell_ids == i
        spikes_cell = np.sort(spike_times[indices])
        first_spike = t_start + (spikes_cell[0] - t_start + t_end - spikes_cell[-1])  * np.random.rand()
        spike_times[indices] = np.hstack([np.array([first_spike]), first_spike + np.cumsum(np.random.permutation(
            np.ediff1d(spikes_cell)))])
    return spike_times, cell_ids



def get_population_average(spike_times_all, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    Returns NON-NORMALIZED population coupling array for spikes, where the population is defined as all 10000 cells.

    :return:
    """

    #calculate the population average based on 10000 cells (in all_spike_times)
    n_cells_all=5000
    cell_ids_all = np.random.permutation(10000)[0:n_cells_all]
    #cell_ids_all = np.arange(n_cells_all)
    n_bins = int((t_end - t_start) / dt_conv)
    activity_matrix = np.zeros((n_bins, n_cells_all))

    fr_all_ms = np.zeros(n_cells_all)
    for i in range(n_cells_all):
        indices = cell_ids_all == i
        fr_all_ms[i] = np.sum(indices) / float((t_end - t_start))
        activity_matrix[:, i] = gaussian_filter_psth(spike_times_all[indices], t_start, t_end,
                                                     dt_conv, sigma_conv)
    activity_matrix_mean_adj = activity_matrix - fr_all_ms

    all_sum_mean_adj = activity_matrix_mean_adj.sum(axis=1)

    return all_sum_mean_adj


def pop_corr_spikes_all(spike_times_all, spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    Returns NON-NORMALIZED population coupling array for spikes, calculated using the 10000 cell population average

    :return:
    """
    n_bins = int((t_end - t_start) / dt_conv)
    activity_matrix = np.zeros((n_bins, n_cells))
    fr_ms = np.zeros(n_cells)
    for i in range(n_cells):
        indices = cell_ids == i
        fr_ms[i] = np.sum(indices)/float((t_end - t_start))
        activity_matrix[:, i] = gaussian_filter_psth(spike_times[indices], t_start, t_end,
                                                     dt_conv, sigma_conv)

    activity_matrix_mean_adj = activity_matrix - fr_ms

    sum_mean_adj = get_population_average(spike_times_all, t_start, t_end, sigma_conv=12 / np.sqrt(2),
                           dt_conv=1.0)
    pop_corr_array = np.zeros((n_cells, 1))
    for i in range(n_cells):
        cell_excluded_sum_mean_adj = sum_mean_adj - activity_matrix_mean_adj[:, i]

        pop_corr_array[i] = np.sum(activity_matrix[:, i] * cell_excluded_sum_mean_adj) \
                            / (fr_ms[i] * (t_end - t_start))
    return pop_corr_array


def pop_corr_spikes_shuffle_scored_all(spike_times_all, spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    pop_array = pop_corr_spikes(spike_times, cell_ids)
    return pop_array.mean() / pop_array.std(ddof=1)
    :return:
    """
    pop_array = pop_corr_spikes_all(spike_times_all,spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)
    shuffle_array = pop_corr_spikes_shuffled(spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)
    return pop_array/np.median(shuffle_array)



def pop_corr_spikes_z_scored_all(spike_times_all, spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    return population coupling devided by sample standard deviation
    :return:
    """
    pop_array = pop_corr_spikes_all(spike_times_all, spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)

    return (pop_array-pop_array.mean())/pop_array.std(ddof=1)

def pop_corr_spikes_shuffled_all(spike_times_all, spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=12/np.sqrt(2),
                    dt_conv=1.0):
    """
    Returns NON-NORMALIZED population coupling array for spikes

    :return:
    """
    spike_times, cell_ids = shuffle_spikes_okun(spike_times, cell_ids, n_cells, t_start, t_end)

    return pop_corr_spikes_all(spike_times_all, spike_times, cell_ids, n_cells, t_start, t_end, sigma_conv=sigma_conv,
                    dt_conv=dt_conv)


def shuffle_spikes_okun(spike_times, cell_ids, n_cells, t_start, t_end):
    """
    Shuffling, keep mean FR per cells, and keep population rate
    :return:
    """
    spike_times = spike_times.copy()
    return spike_times[np.random.permutation(spike_times.size)], cell_ids


