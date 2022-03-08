import scipy.io as scio
import numpy as np 
from CCA.FBCCA import FBCCA

Srate = 250
subBandNum = 7
channels = np.array([48, 54, 55, 56, 57, 58, 61, 62, 63])
channels = channels-1
cuelen = 0.5
stilen = 1
delay = 0.14
dataName = 'S02.mat'
filterModelName = 'filterModel.mat'
data = scio.loadmat(dataName)
eegdata = data['data']
data = scio.loadmat(filterModelName)
filterdata = data['filterModel']
numChannel = eegdata.shape[0]
numTrial = eegdata.shape[3]
# targetFrequence = np.linspace(8.6, 15.8, 37)
# otherFreq = [8.0,8.2,8.4]
# targetFrequence = np.hstack((targetFrequence, otherFreq))
targetFrequence = [8,9,10,11,12,13,14,15,8.20000000000000,9.20000000000000,10.2000000000000,11.2000000000000,12.2000000000000,13.2000000000000,14.2000000000000,15.2000000000000,8.40000000000000,9.40000000000000,10.4000000000000,11.4000000000000,12.4000000000000,13.4000000000000,14.4000000000000,15.4000000000000,8.60000000000000,9.60000000000000,10.6000000000000,11.6000000000000,12.6000000000000,13.6000000000000,14.6000000000000,15.6000000000000,8.80000000000000,9.80000000000000,10.8000000000000,11.8000000000000,12.8000000000000,13.8000000000000,14.8000000000000,15.8000000000000]
targetFrequence = np.array(targetFrequence)
rightCount = 0
for trial in range(0, numTrial):
    rawdata = eegdata[channels][:, int((cuelen+delay)*Srate+1)-1:int((cuelen+stilen+delay)*Srate), trial, 5]
    # New a object
    predictor = FBCCA(rawdata, filterdata, targetFrequence, Srate, subBandNum, rawdata.shape[0])
    predictor.getTemplate()
    result = predictor.FBCCA_kernel()
    if trial == result:
        rightCount += 1
overallresult = rightCount/numTrial
print(overallresult)
