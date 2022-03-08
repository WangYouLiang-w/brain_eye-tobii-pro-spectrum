from dataServer import dataserver_thread
import numpy as np
import scipy.io as scio
from scipy.signal import resample
import time
from algorithmInterface import algorithmthread
from threading import Event

if __name__ == '__main__':
    # load data
    filepath = './ExperimentData/gaorunyuan-0407/block2/'
    # 获得空间滤波器
    data = scio.loadmat(filepath+'W.mat')
    w = data['W']

    # 获得模板信号
    data = scio.loadmat(filepath+'template.mat')
    template = data['template'][0][0]

    # 获得LDA分类器
    data = scio.loadmat(filepath+'ldaW_4.mat')
    ldaW = data['ldaW']

    flagstop = False
    device_type = 'Neuracle'
    n_chan = 9
    hostname = '127.0.0.1'
    port = 8712
    srate = 1000
    time_buffer = 1.5 # second
    epochlength = int(srate*0.54)
    delay = int(srate*0.14)
     
    addloop = 4

    datalocker = Event()
    # initial the classfier

    # 数据处理的线程
    dataRunner = algorithmthread(w,template,ldaW,datalocker,addloop)  
    dataRunner.Daemon = True
    dataRunner.start()

    # 数据获取的线程
    thread_data_server = dataserver_thread(threadName='data_server', device=device_type, n_chan=n_chan,
                                           hostname=hostname, port= port,srate=srate,t_buffer=time_buffer)
    thread_data_server.Daemon = True
    notconnect = thread_data_server.connect()
    if notconnect:
        raise TypeError("Can't connect recorder, Please open the hostport ")
    else:
        thread_data_server.start()
        print('Data server connected')

   # 主线程是判别标签，截取数据 
    #try:
        while not flagstop:
            nUpdate = thread_data_server.get_bufferNupdate()
            if nUpdate > int(0.3*srate)-1:
                data = thread_data_server.get_bufferData()
                eventline = data[-1,:]      # N_chan+1 最后一行是标签行（没出现的时候都是0，出现标签对应位置置1
                triggerPos = np.nonzero(eventline)[0]  # 找到非零元素的索引
                if triggerPos.shape[0] <= 1:          
                    thread_data_server.set_bufferNupdate(0)
                    continue
                else:
                    currentTriggerPos = triggerPos[-2]
                    if data[:,currentTriggerPos+1:].shape[1]>=epochlength:
                        cutdata = data[:-1,currentTriggerPos+1:]
                        epochdata = cutdata[:,delay-1:epochlength-1]
                        #np.savetxt('data{}.out'.format(eventline[currentTriggerPos]),epochdata)
                        if datalocker.is_set() == True:
                            datalocker.clear()
                        epochdata = resample(epochdata,100,axis=1)
                        dataRunner.recvData(epochdata.T)
                        print('Trigger name: {}, shape as: {}'.format(eventline[currentTriggerPos],epochdata.shape))
                        datalocker.wait()
                        thread_data_server.set_bufferNupdate(0)
                    else:
                        thread_data_server.set_bufferNupdate(0)
                        continue

    #except Exception as e:
        #print(e)

    thread_data_server.stop()
