import mne
import numpy
import scipy.signal as sig
from sklearn.cross_decomposition import CCA

def cca(X,Y):
    """
    Canonical Correlation Analysis
    :param X: Test data, matrix shape = n*m
    :param Y: Template data, matrix shape = n*k
    :return: Canonical Correlation Coefficient.
    
    Reference: canoncorr in matlab
    https://github.com/stochasticresearch/depmeas/blob/master/python/rdc.py
    
    Version v0.1 original 2019/09/19
    Author: MEI Jie
    """
    n,p1 = X.shape
    n,p2 = Y.shape

    # Center the variables
    meanX = X.mean(axis=0)
    meanY = Y.mean(axis=0)
    X = X-meanX[numpy.newaxis,:]
    Y = Y-meanY[numpy.newaxis,:] #BoradCast Here

    # QR decomposition
    Qx,Rx = numpy.linalg.qr(X)
    Qy,Ry = numpy.linalg.qr(Y)

    rankX = numpy.linalg.matrix_rank(Rx)
    if rankX==0:
        raise Exception('Rank of X is 0, Check the data.')
    elif rankX < p1:
        Qx = Qx[:,:rankX]
        Rx = Rx[:rankX,:rankX]

    rankY = numpy.linalg.matrix_rank(Ry)
    if rankY == 0:
        raise Exception('Rank of Y is 0, Check the data.')
    elif rankY < p2:
        Qy = Qy[:,:rankY]
        Qx = Ry[:rankY, :rankY]

    d = min(rankX, rankY)
    U,r,V = numpy.linalg.svd(numpy.dot(Qx.T,Qy))
    r = numpy.clip(r,0,1)
    return r

class FBCCA:
    '''
    The input of the FBCCA_kernel class should be (channel,samples)
    '''
    multiplicateTime = 5
    targetTemplate = dict()
    # Fusion Coefficient
    a = numpy.power(numpy.array(range(1,11)),-1.25)

    def __init__(self, rawdata, filterPrevalue,targetFrequence,Fs,subBandNum,channelnum):
        self.rawdata = rawdata
        self.filterPrevalue = filterPrevalue #This should be a dict struct
        self.targetFrequence = targetFrequence
        self.Fs = Fs
        self.subBandNum = subBandNum
        self.targetNum = targetFrequence.shape[0]
        self.channelNum = channelnum

    def getTemplate(self):
        datalength = self.rawdata.shape[1]
        t = numpy.arange(0, datalength, 1)
        t = t/self.Fs
        t = t.reshape(1, t.shape[0])
        for i in range(0, self.targetFrequence.shape[0]):
            testFreq = self.targetFrequence[i]*numpy.arange(1, FBCCA.multiplicateTime+1, 1)
            FBCCA.targetTemplate[i] = numpy.vstack((numpy.sin(2*numpy.pi*(numpy.dot(testFreq.reshape(testFreq.shape[0], 1), t))),
                                                   numpy.cos(2*numpy.pi*(numpy.dot(testFreq.reshape(testFreq.shape[0], 1), t)))))

    def filtProcess(self,subband):
        #filtervalue = self.filterPrevalue[subband]
        f_b50 = self.filterPrevalue[0, 0]['f_b50'][0]
        f_a50 = self.filterPrevalue[0, 0]['f_a50'][0]
        notchdata = sig.filtfilt(f_b50, f_a50, self.rawdata)
        f_b = self.filterPrevalue[0, 0]['f_b'][0][subband][0]
        f_a = self.filterPrevalue[0, 0]['f_a'][0][subband][0]
        filtdata = sig.filtfilt(f_b, f_a, notchdata)
        return filtdata
    
    def FBCCA_kernel(self):
        R = numpy.zeros((self.targetNum, self.subBandNum))
        for subband in range(0, self.subBandNum):
            filterdata = FBCCA.filtProcess(self, subband)
            for target in range(0, self.targetNum):

                template = FBCCA.targetTemplate[target].T
                # cca = CCA(n_components=self.channelNum, scale=True)
                # x_scores, y_scores = cca.fit_transform(filterdata.T, template)
                # R[target, subband] = numpy.corrcoef(x_scores.T, y_scores.T)[0,1]
                r = cca(filterdata.T,template)
                R[target, subband] = r[0]
        # Get suitable Fusion Coefficient
        fusionCoeff = FBCCA.a[0:self.subBandNum]
        self.result = numpy.argmax(numpy.dot(R, fusionCoeff))
        return self.result            
