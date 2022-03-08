import numpy as np
import scipy.io as scio
import time
from algorithmInterface import algorithmthread
from threading import Event

if __name__ == '__main__':

    # Load necessary train data
    filepath = './ExperimentData/changmeirong/Block1/'
    data = scio.loadmat(filepath+'W.mat')
    w = data['W']
    data = scio.loadmat(filepath+'template.mat')
    template = data['template'][0][0]
    data = scio.loadmat(filepath+'ldaW.mat')
    ldaW = data['ldaW']

    # Load test data
    filepath = './ExperimentData/changmeirong/Block2/'
    data = scio.loadmat(filepath+'epochdata.mat')
    testdata = data['epochdata']

    # Analysis test data
    target_num = testdata.shape[3]
    trail_num = testdata.shape[2]

    datalocker = Event()
    dataRunner = algorithmthread(w,template,ldaW,datalocker)
    dataRunner.Daemon = True
    dataRunner.start()

    for target in range(target_num):
        for trail in range(trail_num):
            print('Current test target: {}, trail number: {}'.format(target+1, trail+1))
            currentdata = testdata[:,:,trail,target]
            if datalocker.is_set() == True:
                datalocker.clear()
            dataRunner.recvData(currentdata)
            datalocker.wait()
            #TODO: When in real online exp, the srate is 1000, it should be down sample before send out.
