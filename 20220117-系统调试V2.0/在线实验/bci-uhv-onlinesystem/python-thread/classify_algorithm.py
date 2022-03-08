import numpy as np
from scipy.signal import sosfilt, cheby1
import socket
import heapq


def preprocess(raweeg, idx_fb, zi=None):
    '''
    filter , fs = 1000
    :param raweeg: ndarray(chans, sample, trials)
    :param idx_fb: filter fb_i
    :param zi:
    :return:
    '''

    passband = [6.0, 14.0, 22.0, 30.0, 38.0, 46.0, 54.0, 62.0, 70.0, 78.0]
    wn = [passband[idx_fb]/500, 90.0/500]
    sos_system = cheby1(4, 0.7, wn, btype='bandpass', output='sos')
    y, zf = sosfilt(sos_system, raweeg, axis=1, zi=zi)

    return y, zf

def compute_corr2(X1, X2, X22, X11):
    '''

    :param X1: (xx, xx)
    :param X2: (xx, xx)
    :param X22: the square of X2
    :param X11: the square of X1
    :return: r
    '''

    a = (X1*X2).sum()
    b = X11*X22
    r = a/b
    return r

class Algorithm():

    settingfiles = {'0': '1', '1': '2', '2': '3', '3': '4', '4': '5', '5': '6', '6': '7', '7': '8', '8': '9',
                    '9': '0', '10': 'Q', '11': 'W', '12': 'E', '13': 'R', '14': 'T', '15': 'Y', '16': 'U', '17': 'I',
                    '18': 'O', '19': 'P', '20': 'A', '21': 'S', '22': 'D', '23': 'F', '24': 'G', '25': 'H', '26': 'J',
                    '27': 'K', '28': 'L', '29': ' ', '30': '<', '31': 'Z', '32': 'X', '33': 'C', '34': 'V', '35': 'B',
                    '36': 'N', '37': 'M', '38': ',', '39': '.'}

    def __init__(self, W, WTemplate, sWTemplate, fbs, targs, client_addr, server_addr):
        self.W = W
        self.WTemplate = WTemplate
        self.sWTemplate = sWTemplate
        self.fb_coefs = (np.array([[1, 2, 3, 4, 5]]))**(-1.25)+0.25
        self.fbs = fbs
        self.flag1 = 1
        self.targs = targs
        self.client_addr = client_addr
        self.server_addr = server_addr
        self.sock_client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock_client.bind(self.client_addr)


    def test_trca(self, testeeg, datalength, zi, pretestdata):
        '''

        :param testeeg:
        :param w: (n,fbs, chans, chans)
        :param fbs:
        :return:
        '''
        w_i = round((datalength-0.3)/0.12)
        r = np.zeros([5, 40])
        zii = zi.copy()
        pretestdata1 = pretestdata.copy()

        ww = self.W[w_i, :, :, :]
        for fb_i in range(self.fbs):
            str_fbi = str(fb_i)
            testdata, zf = preprocess(testeeg, fb_i, zi=zi[str_fbi])
            if testeeg.shape[1] != 300:
                testdata = np.concatenate((pretestdata[str_fbi], testdata), axis=1)
            zii[str_fbi] = zf
            pretestdata1[str_fbi] = testdata
            w = ww[fb_i, :, :]
            test_i = np.matmul(w, testdata)
            X11 = np.sqrt((test_i**2).sum())

            for targ_i in range(self.targs):
                str_wtemplate = ''.join([str(datalength), str_fbi, str(targ_i)])
                rr2 = self.WTemplate[str_wtemplate]
                srr2 = self.sWTemplate[str_wtemplate]
                r[fb_i, targ_i] = compute_corr2(test_i, rr2, srr2, X11)

        rho = np.matmul(self.fb_coefs, r)
        results = np.argmax(rho)

        return zii, pretestdata1, rho, results

    def resultDecide(self, rho, results, datalength):

        costh0 = 0.00166 * (rho.sum() - 40 * np.log(np.exp(rho).sum()))
        maxx = np.array(heapq.nlargest(2, rho[0, :]))
        costhq = -(maxx[0] - maxx[1])

        if costhq < costh0 or datalength > 2:
            self.flag1 = 1
            result = results
            sendresult = self.settingfiles[str(result)]
            print('Epoch result:{}, length as:{}'.format(sendresult, datalength))
            self.sock_client.sendto(bytes(str(sendresult), 'utf8'), self.server_addr)

        else:
            self.flag1 = 0

        return self.flag1




