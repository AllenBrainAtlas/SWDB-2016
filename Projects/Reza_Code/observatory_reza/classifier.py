from __future__ import division
from cvxpy import *
import numpy as np

def svm(X,Y,lambd):
    n = X.shape[1];
    s = X.shape[0];
    m = (np.max(Y) + 1).astype(int);
    Y = Y.flatten()
    #YM = np.eye(m, m);
    #YM = YM[Y];
    #YM = YM.T;
    beta = Variable(n,m)
    v = Variable(1, m)
    f = X*beta + np.matrix(np.ones([s,1]))*v
    loss = 0
    for k in range(m):
        ind = range(k) + range(k+1,m)
        #ind = (np.concatenate((range(k),range(k+1,m))))
        loss = loss + sum(pos(1+max_entries(f[Y==k][:,ind],axis = 1)
                        - f[Y==k][:,k]))
        #loss = loss + pos(1+max_entries(X[i,:]*beta + v) - X[i,:]*beta[:,Y[i,0]] + v[Y[i,0]])

    #loss = sum_entries(pos(1 + max_entries((X*beta) + np.ones((s, 1)) * v, axis=1) )- diag((X * beta + np.ones((s, 1)) * v) * YM))
    reg = norm(beta, 1)
    #Parameter(sign="positive")
    prob = Problem(Minimize(loss / s + lambd * reg))
    prob.solve()
    return beta, v


def svm_2(X,Y,lambd):
    n = X.shape[1];
    s = X.shape[0];
    m = np.max(Y) + 1;
    beta = Variable(n)
    v = Variable()
    loss = sum_entries(pos(1 - mul_elemwise(Y, X * beta + v)))
    reg = norm(beta, 1)
    #Parameter(sign="positive")
    prob = Problem(Minimize(loss / s + lambd * reg))
    prob.solve()
    return beta, v

def svm_test(X,Y,beta,v):
    Y.shape = [len(Y),1]
    error = (np.sum(Y != np.argmax(X.dot(beta.value) + v.value, axis=1))/len(Y))
    return error

