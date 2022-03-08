from test_dataServer import dataserver_thread
import numpy as np
import time
from classify_algorithm import Algorithm
import socket
from initial_compute import load_WandTemplate, compute_WTemplate, clearpertestdata, ITR


if __name__ == "__main__":
    

    flagstop = False
    srate = 1000
    time_buffer = 3
    delay = 140
    num_fbs = 5
    num_targs = 40
    trigger = 255
    interval = 0.12
    perdatalength = int(interval * srate)
    count = 0
    trial_length = 0

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

    thread_data_server = dataserver_thread(time_buffer=time_buffer)
    thread_data_server.Daemon = True
    notconnect = thread_data_server.connect_tcp()
     
    if notconnect:
        raise TypeError("Can't connect recoder, Please open the hostport")
    else:
        thread_data_server.start_acq()
        thread_data_server.start()
        print('Data server connected')
        get_buffer_data = thread_data_server.get_buffer_data

        while not flagstop:
            epoch_length = 440
            t1 = time.perf_counter()
            bufferdata = get_buffer_data()

            evt_value_buff = bufferdata[-1, :]
            evt_latency = np.nonzero(evt_value_buff)[0]

            if evt_latency.shape[0] >= 1:
                t_begin = time.perf_counter()
                evt_value = evt_value_buff[evt_latency]
                currentTriggerPos = int(evt_latency[-1])
                currentTriggerType = int(evt_value[-1])
                cutdata = bufferdata[:-1, currentTriggerPos + 1:]
                if cutdata.shape[1] >= epoch_length and trigger != currentTriggerType:
                    trigger = currentTriggerType
                    epochdata = cutdata[:, delay:epoch_length]
                    timelength = 0.3
                    pretestdata, zi = clearpertestdata()
                    zi, pretestdata, rho, result = algorithm.test_trca(epochdata, timelength, zi, pretestdata)
                    flag = algorithm.resultDecide(rho, result, timelength)
                    while not(flag):
                        currentepoch_length = epoch_length + perdatalength
                        while 1:
                            newbufferdata = get_buffer_data()
                            new_evt_value_buff = newbufferdata[-1, :]
                            new_evt_latency = np.nonzero(new_evt_value_buff)[0]
                            currentTriggerPos1 = int(new_evt_latency[-1])
                            newcutdata = newbufferdata[:-1, currentTriggerPos1 + 1:]

                            if newcutdata.shape[1] >= currentepoch_length:
                                break
                            else:
                                continue
                        new_evt_value = new_evt_value_buff[new_evt_latency]
                        currentTriggerType = int(new_evt_value[-1])
                        epochdata = newcutdata[:, epoch_length:currentepoch_length]
                        epoch_length = currentepoch_length
                        timelength = round((timelength + interval), 2)
                        #print(timelength)
                        zi, pretestdata, rho, result = algorithm.test_trca(epochdata, timelength, zi, pretestdata)
                        flag = algorithm.resultDecide(rho, result, timelength)

                    if result + 1 == currentTriggerType:
                        count = count + 1

                    print('Trigger name:{}'.format(currentTriggerType))
                    print('耗时{}s'.format(time.perf_counter() - t_begin))

                else:
                    if trigger == 40:
                        break

        acc = count / 40
        mean_trial_length = trial_length/40
        itr = ITR(40, acc, mean_trial_length + 1)
        print('Online Acc:{0}, T:{1}s, ITR:{2}'.format(acc, mean_trial_length, itr))

