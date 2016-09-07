Madineh Sarvestani, Max Nolte, Philip Mardoum
Code for final project, Summer Workshop on the Dynamic Brain (Allen Institute/UW)
Friday Harbor 2016

This repo contains scripts and jupiter notebooks to analyze the population coupling of simultaneously imaged cell responses in the mouse visual cortex (Allen Brain Observatory data) and simulated cell responses from a model of mouse L4 visual cortex (part of Allen Institute Mindscope).

The population coupling metric and analysis are based on the ‘soloist/chorister’ paper from Harris/Carandini labs:

Okun et al. Diverse coupling of neurons to populations in sensory cortex. Nature 2015 521(7553):511-515.

Some scripts/modules are only called through notebooks and some are called from the script.

We split the analysis/files into four components. Best idea is to start with the notebooks in each category.

0. Core algorithm files that calculate population coupling metric given input spikes:
cobra_analysis.py


1. Files dealing with synthetic data to validate the algorithm implementation:
analysis_test.py
analysis_validation_figures.py
synthetic_signals.py
synthetic_sim.ipynb
make_fig.py



2. Files dealing with extraction and analysis of observatory data:
allen_data_fetch.py
demo_allen_data_fetch.ipynb
data_extraction_test.ipynb
Observatory_popcorr_twostims_comparisons_loop.py
Observatory_popcorr_twostims_comparisons.py
Observatory_popcorrs_all.ipynb
observatory_scatter_figs.ipynb



3. Files dealing with extraction and analysis of L4 model data:
L4model_extraction_copy.py
L4_popcorr_twostims_comparisons.py
L4_popcorr_twohalfs_comparisons.py
L4model_popcorr_ipynb
