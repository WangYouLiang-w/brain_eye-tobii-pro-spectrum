import numpy as np


a = np.array([[1, 2, 3, 4], [5, 6, 7, 8]])
b = np.array([[10, 9, 8, 7], [9, 6, 5, 4]])
aa = (a**2).sum()


zi = {'0': np.zeros([4, 9, 2]), '1': np.zeros([4, 9, 2]), '2': np.zeros([4, 9, 2]), '3': np.zeros([4, 9, 2]), '4': np.zeros([4, 9, 2])}

zii = zi.copy()
zii['1'] = np.ones([4, 9, 2])
print(zii['1'])
