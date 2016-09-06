from sklearn.preprocessing import StandardScaler
import numpy as np


def pca(X, ndims=3):
	"""Runs PCA on provided data, X, and returns the projection onto ndims principal components.
This function assumes X has data series in columns.
This function also returns the covariance matrix of the data (scaled to zero norm and unit variance), as well as the eigen vectors and values of that matrix.

Input:
	X : ndarray with data series in columns (e.g. one neuron's calcium trace (or DF/F) per column)
	ndims : the number of dimensions to project down to. Default is 3 for fancy 3d scatter plots.
Output:
	Y : Projected, scaled data.
	cov_mat : Covariance matrix of the scaled data
	eig_pairs : a list of tuples. Each tuple is of the form (eigen value, eigen vector), and they are sorted high to low"""
	original_dims = X.shape[1];
	if ndims > original_dims:
		ndims = original_dims
	#TODO Check what this scaler is actually doing; it might be scaling columns independently
	X_std = StandardScaler().fit_transform(X)
	cov_mat = np.cov(X.T)
	eig_vals, eig_vecs = np.linalg.eig(cov_mat)
	eig_pairs = [(np.abs(eig_vals[i]), eig_vecs[:, i]) for i in range(len(eig_vals))]
	eig_pairs.sort(key=lambda x: x[0], reverse=True)
	W = np.hstack((eig_pairs[i][1].reshape(original_dims,1) for i in range(ndims)))
	Y = X_std.dot(W)
	return Y, cov_mat, eig_pairs
