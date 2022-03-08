import numpy as np
from scipy import signal
from scipy.io import loadmat
import shelve
from contextlib import closing

def preprocess(raweeg,fs,idx_fb):
    """
    数据进行预处理
    @param raweeg: (n_chans,samples,blocks)
    @param fs: 采样率
    @param idx_fb:子带索引
    @return: 滤波后的数据data2
    """
    fs = fs/2
    passband = [6.0,14.0,22.0,30.0,38.0,46.0,54.0,62.0,70.0,78.0]
    stopband = [4.0, 10.0, 16.0, 24.0, 32.0, 40.0, 48.0, 56.0, 64.0, 72.0]
    #cut 50Hz
    wn = [49.5/fs, 50.5/fs]
    b50, a50 = signal.cheby1(4,0.1,wn,btype=r'bandstop')
    data1 = signal.filtfilt(b50, a50, raweeg, axis=1)

    #bandpass
    w1 = [passband[idx_fb]/fs, 90.0/fs]
    sos_system = signal.cheby1(4, 0.7, w1, btype=r'bandpass', output='sos')
    data2 = signal.sosfilt(sos_system, raweeg, axis=1)

    """
    wp = [passband[idx_fb] / 500, 90.0 / 500]
    ws = [stopband[idx_fb] / 500, 100.0 / 500]
    gpass = 3
    gstop = 40
    N, wn = signal.cheb1ord(wp, ws, gpass=gpass, gstop=gstop)
    # 采样率1000时，rp=0.9
    sos_system = signal.cheby1(N, rp=0.9, Wn=wn, btype='bandpass', output='sos')
    data2 = signal.sosfilt(sos_system, raweeg, axis=1)
    """

    return data2

class TRCA():

    def __init__(self,fs,num_fbs,num_targs):
        self.fs = fs
        self.num_fbs = num_fbs
        self.num_targs = num_targs

    def trca(self,X):
        """
        获取TRCA滤波器
        @param X: EEG训练数据
        @return: 滤波器w
        """

        # zero means
        values_mean = X.mean(axis=1, keepdims=True)
        # Xin_std = Xin.std(axis=1, ddof=1, keepdims=True)
        X = (X- values_mean)  # /Xin_std

        n_chans = X.shape[0]
        n_trial = X.shape[2]
        S = np.zeros((n_chans, n_chans))

        for trial_i in range(n_trial):
            for trial_j in range(n_trial):
                x_i = X[:, :, trial_i]
                x_j = X[:, :, trial_j]
                S = S + np.dot(x_i, x_j.T)
        X1 = X.reshape([n_chans, -1])
        X1 = X1 - np.mean(X1, axis=1).reshape((n_chans, 1))
        Q = np.dot(X1, X1.T)

        # TRCA eigenvalue algorithm
        [W, V] = np.linalg.eig(np.linalg.solve(Q, S))

        return V[:, 0]

    def train_trca(self,traineeg):
        """
        获取各个子带各个频率对应的滤波器和模板信号
        @param traineeg: EEG训练数据 (chans,samples,targs,blocks)
        @return: 各个子带各个频率对应的滤波器和模板信号
        """
        chans = traineeg.shape[0]
        samples = traineeg.shape[1]
        targs = traineeg.shape[2]

        templates = np.zeros([targs, self.num_fbs, chans, samples])
        wn = np.zeros([self.num_fbs, targs, chans])

        for targ_i in range(targs):
            eeg_temp = traineeg[:, :, targ_i, :]
            for fb_i in range(self.num_fbs):
                eeg_temp = preprocess(eeg_temp, self.fs, fb_i)
                templates[targ_i, fb_i, :, :] = np.mean(eeg_temp, axis=2)
                w_tmp = self.trca(eeg_temp)
                wn[fb_i, targ_i, :] = w_tmp[None, :]

        return templates,wn


if __name__ == "__main__":
    """
    读取训练数据，并获得模板和滤波器
    """
    startT = 0.3
    endT = 2.1
    # endT = 1
    interval = 0.12
    # fs = 250
    fs = 1000
    len_delay_s = 0.14
    len_shift_s = 0.5
    len_stim_s = 0

    """
    #raweegname = 'G:/Code/meijie/Test/TRCA/S1.mat'
    raweegname = 'D:/graduated design/TRCA/S1.mat'
    rawdata = loadmat(raweegname)
    rawdata = np.array(rawdata['data'], np.float32)
    # chs = [PZ:48, PO5:54, PO3:55, POz:56, PO4:57, PO6:58, O1:61, Oz:62, O2:63]
    raweeg1 = rawdata[47, :, :, :][None, :, :, :]
    raweeg2 = rawdata[53:58, :, :, :]
    raweeg3 = rawdata[60:63, :, :, :]
    raweeg = np.concatenate((raweeg1, raweeg2), axis=0)
    raweeg = np.concatenate((raweeg, raweeg3), axis=0)
    traindata = raweeg[:,:,:,0:5]
    """


    raweegname = 'G:/Code/system/dw-mat/zyr0823.mat'
    rawdata = loadmat(raweegname)
    rawdata = np.array(rawdata['epochdata'], np.float32)
    # traindata = raweeg
    # traindata = rawdata[:,:,:,0:4]
    traineeg1 = rawdata[:, :, :, 1:2]
    traineeg2 = rawdata[:, :, :, 2:5]
    traindata = np.concatenate((traineeg1, traineeg2), axis=3)
    # traindata = traineeg1


    num_fbs = 7
    targs = 40
    chans = traindata.shape[0]

    n = int((endT-startT)/interval + 1)
    W = np.zeros([n, num_fbs, targs, chans])
    Template = {}

    classifier = TRCA(fs, num_fbs=7, num_targs=40)


    datalength = int(len_stim_s*fs)

    for i in range(n):
        len_stim_s = round((i*0.12 + 0.3), 2)
        datalength = int(len_stim_s*fs)
        # traineeg = traindata[:,int(0.64*fs):int(0.64*fs)+datalength,:,:]
        traineeg = traindata[:, :datalength, :, :]
        templates, wn = classifier.train_trca(traineeg)
        W[i, :, :, :] = wn
        Template[str(round((0.3+i*0.12), 2))] = templates



    # 保存templates和wn
    # with closing(shelve.open('G:/Code/meijie/Test/WandTemplate/dynamicW/S1', 'c')) as shelf:
    #     shelf['ints'] = W
    # with closing(shelve.open('G:/Code/meijie/Test/WandTemplate/dynamicTemplate/S1','c')) as shelf:
    #     shelf['ints'] = Template

    with closing(shelve.open('G:/Code/system/40_Stim_System/dynamicW/zyr0823', 'c')) as shelf:
        shelf['ints'] = W
    with closing(shelve.open('G:/Code/system/40_Stim_System/dynamicTemplate/zyr0823', 'c')) as shelf:
        shelf['ints'] = Template

