# -*- coding: utf-8 -*-
"""
Created on Tue Sep  6 13:08:46 2016

@author: tom chartrand
"""
from dPCA import dPCA
import numpy as np
import sklearn.decomposition as deco

def factor_analysis(mat, nmax):
    """
    Perform dimensionality reduction with factor analysis.
    Since Factor Analysis cannot be performed iteratively, finds distinct 
    decompositions for n_components in (1 to nmax)
    
    Parameters
    ----------
    mat : array-like, shape (T, N)
        Matrix representing activity at T times of N cells
        
    nmax : int > 0
        Maximum number of components to find
        
    
    Returns
    -------
    dict containing
    'obj': Instance of scikit-learn object with decomposition methods
    'ev': array
        explained variance by decompositions with 1 to nmax components
    'trans':  array-like, shape (T, nmax)
        Activity mat 'decoded' into reduced dimensional space
    'enc': array-like, shape (nmax, N)
        'Encoding' matrix of each component in terms of N original variables
    """
    mat = mat - mat.mean(axis=0, keepdims=True)
    totVar = np.sum(np.square(mat))
    expVar = np.zeros(nmax)
    for ni in range(nmax):
        dec = deco.FactorAnalysis(ni+1).fit(mat)
        matReduced = dec.transform(mat)
        matRcons = np.dot(matReduced,dec.components_)
        expVar[ni] = 1 - np.sum(np.square(mat - matRcons))/totVar
    return {'obj':dec, 'ev':expVar, 'trans':matReduced, 'enc':dec.components_}

def pc_analysis(mat, nmax):
    """
    Perform dimensionality reduction with PCA
    
    Parameters
    ----------
    mat : array-like, shape (T, N)
        Matrix representing activity at T times of N cells
        
    nmax : int > 0
        Maximum number of components to find
        
    
    Returns
    -------
    dict containing
    'obj': Instance of scikit-learn object with decomposition methods
    'ev': array
        explained variance by decompositions with 1 to nmax components
    'trans':  array-like, shape (T, nmax)
        Activity mat 'decoded' into reduced dimensional space
    'enc': array-like, shape (nmax, N)
        'Encoding' matrix of each component in terms of N original variables
    """
    dec = deco.PCA(nmax, whiten=False).fit(mat)
    ev = np.cumsum(dec.explained_variance_ratio_)
    return {'obj':dec, 'ev':ev, 'trans':dec.transform(mat), 'enc':dec.components_}

def dpc_analysis(mat, nmax):
    """
    Perform dimensionality reduction with dPCA
    
    Parameters
    ----------
    mat : array-like, shape (N, C, T) or (N, C1, C2, T)
        ndarray representing activity at T times of N cells under C trial conditions
        (or C1 instances of condition 1, C2 of condition 2)
        
    nmax : int > 0
        Maximum number of components to find
        
    
    Returns
    -------
    dict containing
    'obj': Instance of dPCA (scikit-learn-like) object with decomposition methods
    'ev': array
        explained variance by decompositions with 1 to nmax components
    'trans':  array-like, shape (T, nmax)
        Activity mat 'decoded' into reduced dimensional space
    'enc': array-like, shape (nmax, N)
        'Encoding' matrix of each component in terms of N original variables
    """
    if len(mat.shape) == 2:
        combinedParams = {'c': ['c', 'ct'] }
        dec = dPCA(labels='ct', n_components=nmax, join=combinedParams).fit(mat)
    else:
        combinedParams = {'f': ['f', 'ft'] , 'o': ['o', 'ot'], 'fo': ['fo', 'fot']}
        dec = dPCA(labels='fot', n_components=nmax, join=combinedParams).fit(mat)
                
    V = np.hstack(dec.P.values())
    W = np.hstack(dec.D.values())

    # flipping axes such that all encoders have more positive values
    toFlip = np.nonzero(np.sum(V, axis=0)<0)
    W[:, toFlip] = -W[:, toFlip]
    V[:, toFlip] = -V[:, toFlip]

    X = mat.reshape((mat.shape[0],-1))
    X -= np.mean(X, axis=1, keepdims=True)
    totalVar = np.sum(np.square(X))

    Z = np.dot(W.T,X)
    explVar = [1 - np.sum(np.square(X - np.outer(V[:,i],Z[i,:])))/totalVar for i in range(W.shape[1])]
    order = np.argsort(explVar)[::-1]
    explVar = np.array(explVar)[order[:nmax]]

    W = W[:,order[:nmax]]
    V = V[:,order[:nmax]]
    Z = np.dot(W.T,X)
    cumVar = [1 - np.sum(np.square(X - np.dot(V[:,:i+1],Z[:i+1,:])))/totalVar for i in range(W.shape[1])]
    return {'obj':dec, 'ev':cumVar, 'trans':Z.T, 'enc':W}