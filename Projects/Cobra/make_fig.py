#This script produces validation plots on synthetic data.

import synthetic_signals
import cobra_analysis
import numpy as np
import matplotlib.pyplot as plt

# This is for Illustrator
plt.rcParams["pdf.fonttype"] = 42

def main():
    """
    Create validation plots
    """
    # generate_spike_validation_figure
    generate_calcium_validation_figure()


def generate_spike_validation_figure():
    """
    Plot validations of stPR
    :return:
    """
    n_cells = 400 # use 2000 for plot
    t_start = 0
    t_stop = 100000
    fr = 20
    correlations = np.linspace(0.1, 0.95, 20)

    all_spikes = []
    all_cells = []
    for i, correlation in enumerate(correlations):
        print i
        spikes_i, cells_i = synthetic_signals.generate_poisson_spike_train_population(
            n_cells/correlations.size, fr, correlation=correlation, t_start=t_start, t_stop=t_stop,
            seed=1001 + i)
        all_spikes.append(spikes_i)
        all_cells.append(cells_i + n_cells/correlations.size * i)
    spikes = np.hstack(all_spikes)
    cells = np.hstack(all_cells)

    all_spikes_2 = []
    all_cells_2 = []
    for i, correlation in enumerate(correlations):
        print i
        spikes_i, cells_i = synthetic_signals.generate_poisson_spike_train_population(
            n_cells/correlations.size, fr, correlation=correlation, t_start=t_start,  t_stop=t_stop,
            seed=1001 + i + 252342)
        all_spikes_2.append(spikes_i)
        all_cells_2.append(cells_i + n_cells/correlations.size * i)
    spikes_2 = np.hstack(all_spikes_2)
    cells_2 = np.hstack(all_cells_2)


    all_spikes_3 = []
    all_cells_3 = []
    for i, correlation in enumerate(correlations[::-1]):
        print i
        spikes_i, cells_i = synthetic_signals.generate_poisson_spike_train_population(
            n_cells/correlations.size, fr, correlation=correlation, t_start=t_start,  t_stop=t_stop,
            seed=1001 + i + 8989)
        all_spikes_3.append(spikes_i)
        all_cells_3.append(cells_i + n_cells/correlations.size * i)
    spikes_3 = np.hstack(all_spikes_3)
    cells_3 = np.hstack(all_cells_3)
    cell_id_dict = dict(zip(np.unique(cells_3), np.random.permutation(np.unique(cells_3))))
    # cells_in_3_new = np.random.permutation(cells_in_3)
    # for i, cell_id in enumerate(cells_in_3):
    #     cells_3[cells_3 == cell_id] = cells_in_3_new[i]
    cells_3 = np.array([cell_id_dict[x] for x in cells_3])

    print "Generated spikes"

    spikes_shuffled, cells_shuffled = cobra_analysis.shuffle_spikes_okun(
        spikes, cells, n_cells, t_start, t_stop)

    spikes_shuffled_all, cells_shuffled_all = cobra_analysis.shuffle_spikes_homogenous(
        spikes, cells, n_cells, t_start, t_stop)

    pop_array_shuffled = cobra_analysis.pop_corr_spikes_shuffle_scored(spikes_shuffled,
                                                                       cells_shuffled, n_cells,
                                                                       t_start=t_start,
                                                                       t_end=t_stop)
    pop_array = cobra_analysis.pop_corr_spikes_shuffle_scored(spikes, cells, n_cells,
                                                              t_start=t_start,
                                                              t_end=t_stop)
    pop_array_2 = cobra_analysis.pop_corr_spikes_shuffle_scored(spikes_2, cells_2, n_cells,
                                                              t_start=t_start,
                                                              t_end=t_stop)
    pop_array_3 = cobra_analysis.pop_corr_spikes_shuffle_scored(spikes_3, cells_3, n_cells,
                                                               t_start=t_start,
                                                               t_end=t_stop)


    # Plot spike

    fig, axs = plt.subplots(3, 3)

    ax = axs[0, 0]
    ax.set_xlabel('t (ms)')
    ax.set_ylabel('Cells')
    ax.set_title('Pop. A - trial 1')
    for i, cell_id in enumerate(np.random.permutation(n_cells)[:50]):
        indices = cells == cell_id
        indices = np.logical_and(indices, spikes < 500)
        ax.vlines(spikes[indices], i + np.zeros(indices.sum()),
                  i + 1 + np.zeros(indices.sum()))

    ax = axs[0, 1]
    ax.set_xlabel('t (ms)')
    ax.set_ylabel('Cells')
    ax.set_title('Pop. A - trial 2')
    for i, cell_id in enumerate(np.random.permutation(n_cells)[:50]):
        indices = cells_2 == cell_id
        indices = np.logical_and(indices, spikes_2 < 500)
        ax.vlines(spikes_2[indices], i + np.zeros(indices.sum()),
                  i + 1 + np.zeros(indices.sum()))

    ax = axs[0, 2]
    ax.set_xlabel('t (ms)')
    ax.set_ylabel('Cells')
    ax.set_title('Pop. B')
    for i, cell_id in enumerate(np.random.permutation(n_cells)[:50]):
        indices = cells_3 == cell_id
        indices = np.logical_and(indices, spikes_3 < 500)
        ax.vlines(spikes_3[indices], i + np.zeros(indices.sum()),
                  i + 1 + np.zeros(indices.sum()))

    axs[1, 0].hist(pop_array, alpha=0.5, color='red', label='original A')
    axs[1, 0].hist(pop_array_shuffled, alpha=0.5, color='black', label='shuffled')
    axs[1, 0].legend(loc='upper left', frameon=False)

    pop_array_corrs = pop_array.reshape((correlations.size, pop_array.size/correlations.size))
    axs[1, 1].errorbar(correlations, pop_array_corrs.mean(axis=1),
                yerr=pop_array_corrs.std(axis=1, ddof=1)/np.sqrt(pop_array_corrs.shape[1]))
    axs[1, 1].set_xlabel('Input correlation')
    axs[1, 1].set_ylabel('stPR')

    axs[1, 2].hist(pop_array_3, alpha=0.5, color='red', label='original B')
    axs[1, 2].legend(loc='upper left', frameon=False)

    axs[2, 0].scatter(pop_array, pop_array_2)
    axs[2, 0].set_title('trial 1 vs. trial 2')
    axs[2, 0].set_xlabel('stPR')
    axs[2, 0].set_ylabel('stPR')

    axs[2, 1].scatter(pop_array, pop_array_shuffled)
    axs[2, 1].set_title('orig. vs. shuffled')
    axs[2, 1].set_xlabel('stPR')
    axs[2, 1].set_ylabel('stPR')

    axs[2, 2].scatter(pop_array, pop_array_3)
    axs[2, 2].set_title('pop. A vs. pop. B')
    axs[2, 2].set_xlabel('stPR')
    axs[2, 2].set_ylabel('stPR')


    plt.tight_layout()

    plt.savefig('figures/stPR_validation_example.pdf')

def generate_calcium_validation_figure():

    matrices, corrs = synthetic_signals.get_set_of_coupled_activity_matrices(20, coupling_factors=np.linspace(0,2,10),
                                                           duration=100000)
    activity_matrix = matrices.reshape((matrices.shape[0], matrices.shape[1] * matrices.shape[-1]))
    pop_array = cobra_analysis.pop_corr_z_scored(activity_matrix)



    matrices, corrs = synthetic_signals.get_set_of_coupled_activity_matrices(20,
                                                                             coupling_factors=np.linspace(
                                                                                 0, 2, 10),
                                                                             duration=100000)

    activity_matrix_2 = matrices.reshape((matrices.shape[0], matrices.shape[1] * matrices.shape[-1]))
    pop_array_2 = cobra_analysis.pop_corr_z_scored(activity_matrix_2)

    matrices, corrs = synthetic_signals.get_set_of_coupled_activity_matrices(20,
                                                                             coupling_factors=np.linspace(
                                                                                 0, 2, 10),
                                                                             duration=100000)


    activity_matrix_2 = matrices.reshape((matrices.shape[0], matrices.shape[1] * matrices.shape[-1]))
    pop_array_2 = cobra_analysis.pop_corr_z_scored(activity_matrix_2)

    fig, axs = plt.subplots(2)
    axs[0].scatter(pop_array, pop_array_2)
    axs[0].scatter(pop_array, pop_array_2[np.random.permutation(20*corrs.size)])
    plt.show()


if __name__ == "__main__":
    main()