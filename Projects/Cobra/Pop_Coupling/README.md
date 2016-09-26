"# Pop_Coupling" 
This repo contains a few files (and a jupyter nontoebook) to setup Okun et al.'s raster marginalized model (Okun et al. 2012, 2015), which is used as a generative model to create a raster of neural responses constrained by two or three properties of the observed raster of neural response. The main goal is to determine whether a raster generated from a model constrained by the three conditions below can produce similar pairwise correlations as the original raster (Fig. 2B and 2D of Okun et al. 2015).

Okun et al. 2012:  https://www.ncbi.nlm.nih.gov/pubmed/23197704
Okun et al. 2015:  https://www.ncbi.nlm.nih.gov/pubmed/25849776

It then applies the algorithm to spikes extracted from Calcium imaging data from Session B (for Cux2-CreERT2;Camk2a-tTA;Ai93 cre line, depth of 275 (L4) of primary visual cortex of mouse) of the Allen Brain Observatory dataset: 
http://observatory.brain-map.org/visualcoding/
Spike extraction was done by Anatoly Buchin using modified code from Thomas Deneux (I think).

The generated raster is constrained by the following parameters of original raster:
1) the same mean firing rate for each cell as the original raster (row marginal)
2) the generated raster has the same overall population rate as the original raster (column marginal, up to a permutation)
3) the generated raster has the same population coupling for each cell as the original raster (up to max error of N_cels)
Note that it's not always possible to generate such a raster. In this case, an error message is given.

Once the raster is generated,  the pairwise correlation coefficients are calculated, and plotted for the original raster and the generated raster.The main goal here is to determine whether these pairwise correlations are similar. If they are, this means that the three constraints used to generate the raster also capture pairwise correlations. This is because the model generated data doesn't have access to the pairwise correlations, apriori. So if this generated data can capture pairwise correlations, it means that the imposed constraints (firing rate, population rate, population coupling) implicitly impose pairwise correlations. Another way of sayign this is that population coupling contains pairwise correlation data.

Files:
Pairiwse_prediction_notebook2.ipynb : main notebook that calls everything else and produces plots. Reasonably commented
synthetic_signals.py : generates fake population of spikes with particular coupling, called by Pairiwse_prediction_notebook2.ipynb)
Okun_shuffle.py : python implementation of row/column marginal preserving raster shuffling as in Okun et al. 2012, based on M. Okun's matlab code
generate_RMM.py : python impelementation of raster marginazlied model, based on M. Okun's matlab code. also includes a few functions for calculating pairwise corr coefficients and plotting matrices. 
raster.mat : raster used to demo M Okun's matlab code. I think it's real data from mouse visual cortex (?). Firing rates are high. 10 cells, ~5 minutes.
observatory_raster. mat: raster of extracted caclium spikes from Allen Brain Observatory data (see above): 242 cells, ~64 minutes.


