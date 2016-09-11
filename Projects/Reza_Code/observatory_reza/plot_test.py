import matplotlib.pyplot as plt
import numpy as np
a = np.array([1,2,3])/5.
b = np.array([2,3,4])/5.
plt.figure()
plt.boxplot([a,b])
plt.xticks(np.arange(2)+1,('a','b'))
plt.ylim((0,1))
plt.ylabel('Test Error Rate')
plt.show()

original_vector = np.array([1,2])
shuffle_vector  = np.array([2,3])
fr_vector       = np.array([4,5])
fr_shuffle_vector = np.array([6,7])
t = np.array([0,1])
plt.figure()
plt.plot(t,original_vector,t,shuffle_vector,'r--',t,fr_vector,'k',t,fr_shuffle_vector)
plt.legend(['Sim (Ca)','Shuf (Ca)','Sim (FR)','Shuf (FR)'])
    #plt.ylim((0, 1))
    #plt.ylabel('Test Error Rate')
plt.show()

