import numpy as np
from classifier import svm, svm_2, svm_test
lambd = .01
X = np.random.rand(4,3)
Y = np.array([0,1,2,3])
    #np.array([[1,1],[0,0],[2,3]])
#Y = np.array([1,0,2])
beta, v = svm(X,Y,lambd)

#Y2 = np.array([1,-1])
#beta2, v2 = svm_2(X,Y2,lambd)


test_error = svm_test(X,Y,beta,v)
print(test_error)