import synthetic_signals
import cobra_analysis
import numpy as np
import matplotlib.pyplot as plt

"""
Test module to validate analysis methods and synthetic signals
Author: Max Nolte
Sept 2016
"""


def main():
    """
    Run several test funtions to validate.
    """

    # # Test homogeneously correlated data
    # Test continuous data analysis
    test_one()
    # Test spike train data analysis
    test_two()

    # # Test heterogeneously correlated data
    # Test cont. heterogeneous
    test_three()
    # Test spike trains bimodal
    test_four()


def test_one():
    """
    Test continous data analyis
    :return:
    """
    n_strengths = 10
    activity_matrices, coupling_factors = synthetic_signals.\
        get_set_of_coupled_activity_matrices(n_strengths)
    fig, axs = plt.subplots(n_strengths, sharex=True)
    mean_pcp = np.zeros(n_strengths)
    std_pcp = np.zeros(n_strengths)
    for i in range(activity_matrices.shape[-1]):
        axs[i].plot(activity_matrices[:, :, i])
        axs[i].set_title('Coupling factor = %.2f' % coupling_factors[i])
        pop_array = cobra_analysis.pop_corr(activity_matrices[:, :, i])
        mean_pcp[i] = pop_array.mean()
        std_pcp[i] = pop_array.std(ddof=1)

    axs[-1].set_xlabel('t (ms)')
    axs[0].set_ylabel('Signal strength')

    fig, ax = plt.subplots()
    ax.errorbar(np.arange(10), mean_pcp/std_pcp, yerr=np.ones(n_strengths))
    plt.show()


def test_two():
    """
    Test spike train data analysis
    :return:
    """

    n_strengths = 10
    mean_pcp = np.zeros((n_strengths, 3))
    std_pcp = np.zeros((n_strengths, 3))
    t_end = 10000
    n_cells = 100

    fig, axs = plt.subplots(n_strengths, sharex=True)

    for i in range(n_strengths):
        print "Computing correlation = %.2f" % (i * 0.05)
        spikes, cells = synthetic_signals.generate_poisson_spike_train_population(n_cells, 100,
                                                                                correlation=i*0.08,
                                                                                t_start=0,
                                                                                t_stop=t_end,
                                                                                seed=i+1000)
        for j in range(n_cells):
            bottom = np.ones(spikes[cells == j].size) * j
            top = bottom + 1
            axs[i].vlines(spikes[cells == j], bottom, top)

        pop_array = cobra_analysis.pop_corr_spikes_shuffle_scored(spikes, cells, n_cells, t_start=0,
                                                                                  t_end=t_end)
        mean_pcp[i, 0] = pop_array.mean()
        std_pcp[i, 0] = pop_array.std(ddof=1)
        pop_array = cobra_analysis.pop_corr_spikes_z_scored(spikes, cells, n_cells, t_start=0,
                                                                  t_end=t_end)
        mean_pcp[i, 1] = pop_array.mean()
        std_pcp[i, 1] = pop_array.std(ddof=1)

        pop_array = cobra_analysis.pop_corr_spikes(spikes, cells, n_cells, t_start=0,
                                                            t_end=t_end)
        mean_pcp[i, 2] = pop_array.mean()
        std_pcp[i, 2] = pop_array.std(ddof=1)
    plt.show()

    std_pcp /= np.sqrt(n_cells)
    fig, axs = plt.subplots(3)
    labels = ["shuffle", "z", "none"]
    for i in range(3):
        ax = axs[i]
        ax.errorbar(np.arange(10) * 0.08, mean_pcp[:, i], yerr=std_pcp[:, i], label=labels[i])
        ax.legend(frameon=False, loc='upper left')
        ax.set_xlabel('Correlation')
        ax.set_ylabel('stPC')
    plt.show()


def test_three():
    """

    :return:
    """
    activity_matrix = synthetic_signals.cont_random_model_one_heterogeneous(300, duration=1000,
                                                                            dt=0.1,
                                                                            coupling_factor=0.5,
                                                                            sigma=5)
    pop_array = cobra_analysis.pop_corr_z_scored(activity_matrix)
    fig, ax = plt.subplots()
    ax.hist(pop_array, bins=25)
    plt.show()

def test_four():
    """

    :return:
    """
    n_cells = 1000
    spikes_1, cells_1 = synthetic_signals.generate_poisson_spike_train_population(n_cells/2, 100,
                                                                              correlation=0.1,
                                                                              t_start=0,
                                                                              t_stop=1000,
                                                                              seed=1001)
    spikes_2, cells_2 = synthetic_signals.generate_poisson_spike_train_population(n_cells/2, 100,
                                                                              correlation=0.5,
                                                                              t_start=0,
                                                                              t_stop=1000,
                                                                              seed=1000)
    spikes = np.hstack([spikes_1, spikes_2])
    cells = np.hstack([cells_1, cells_2+n_cells/2])
    pop_array = cobra_analysis.pop_corr_spikes_shuffle_scored(spikes, cells, n_cells, t_start=0,
                                               t_end=1000)
    fig, ax = plt.subplots()
    ax.hist(pop_array, bins=20)

    plt.show()

if __name__ == "__main__":
    main()



