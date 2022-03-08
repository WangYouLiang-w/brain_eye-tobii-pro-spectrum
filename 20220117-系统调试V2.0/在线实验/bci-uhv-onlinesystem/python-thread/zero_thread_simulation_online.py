import numpy as np
import time
from classify_algorithm import Algorithm
from scipy.io import loadmat
import socket
from initial_compute import load_WandTemplate, compute_WTemplate, clearpertestdata, ITR



if __name__ == "__main__":

    raweegname = 'G:/Code/system/dw-mat/zyr0823.mat'
    rawdata = loadmat(raweegname)
    rawdata = np.array(rawdata['epochdata'], np.float32)
    raweeg = rawdata

    testdata = raweeg[:, :, :, 0]

    fs = 1000
    num_fbs = 5
    num_targs = 40
    trial_num = testdata.shape[2]
    count = 0
    ts = 0
    t_result = 0
    interval = 0.12
    wpath = 'G:/Code/system/40_Stim_System/dynamicW/zyr0823'
    templatepath = 'G:/Code/system/40_Stim_System/dynamicTemplate/zyr0823'
    W, Template = load_WandTemplate(wpath, templatepath)
    WTemplate, sWTemplate = compute_WTemplate(W, Template, num_fbs, num_targs)
    client_ip = socket.gethostbyname(socket.gethostname())
    client_addr = (client_ip, 40008)
    server_addr = ('192.168.213.93', 40007)

    algorithm = Algorithm(W, WTemplate, sWTemplate, num_fbs, num_targs, client_addr, server_addr)
    pretestdata = {'0': np.array([0]), '1': np.array([0]), '2': np.array([0]), '3': np.array([0]), '4': np.array([0])}
    zi = {'0': np.zeros([4, 9, 2]), '1': np.zeros([4, 9, 2]), '2': np.zeros([4, 9, 2]), '3': np.zeros([4, 9, 2]), '4': np.zeros([4, 9, 2])}

    for trial in range(trial_num):
        print('Current test trial number: {}'.format(trial + 1))

        datalength = int(0.3*fs)

        t_begin = time.perf_counter()
        testeeg = testdata[:, :datalength, trial]
        timelength = 0.3
        pretestdata, zi = clearpertestdata()
        zi, pretestdata, rho, result = algorithm.test_trca(testeeg, timelength, zi, pretestdata)
        flag = algorithm.resultDecide(rho, result, timelength)

        if flag == 1:
            print('耗时：{}'.format(time.perf_counter() - t_begin))
        else:
            while not(flag):
                perdata = int(interval * fs)
                currentdata = testdata[:, datalength:datalength + perdata, trial]
                timelength = round((timelength + interval), 2)
                #print(timelength)
                zi, pretestdata, rho, result = algorithm.test_trca(currentdata, timelength, zi, pretestdata)
                flag = algorithm.resultDecide(rho, result, timelength)
                datalength = datalength + perdata

            print('耗时：{}'.format(time.perf_counter() - t_begin))

        print(timelength)
        ts = ts + timelength
        if result == trial:
            count = count + 1
        else:
            print('The result is wrong!')

    acc = count/trial_num
    T = ts/trial_num + 1
    itr = ITR(trial_num, acc, T)
    print('Accuracy:{0}, ITR:{1}, T:{2}'.format(acc, itr, T-1))
