import numpy as np
import shelve
from contextlib import closing


def load_WandTemplate(wpath, templatepath):
    '''

    :param wpath:
    :param templatepath:
    :return:
    '''

    with closing(shelve.open(wpath, 'r')) as shelf:
        W = shelf['ints']

    with closing(shelve.open(templatepath, 'r')) as shelf:
        Template = shelf['ints']

    return W, Template

def compute_WTemplate(W, Template, num_fbs, num_targs):
    '''

    :param W:
    :param Template:
    :param num_fbs:
    :param num_targs:
    :return:
    '''
    interval = 0.12
    startT = 0.3
    endT = 2.1
    n = int((endT - startT)/interval + 1)
    WTemplate = {}
    sWTemplate = {}
    for i in range(n):
        t_str = str(round(startT + i * interval, 2))
        for fb_i in range(num_fbs):
            for targ_i in range(num_targs):
                wtemplate = W[i, fb_i, :, :].dot(Template[t_str][targ_i, fb_i, :, :])
                WTemplate[t_str + str(fb_i) + str(targ_i)] = wtemplate
                # TODO check swTemplate is right?
                sWTemplate[t_str + str(fb_i) + str(targ_i)] = np.sqrt((wtemplate**2).sum())

    return WTemplate, sWTemplate

def clearpertestdata():

    pretestdata = {'0': np.array([0]), '1': np.array([0]), '2': np.array([0]), '3': np.array([0]), '4': np.array([0])}
    zi = {'0': np.zeros([4, 9, 2]), '1': np.zeros([4, 9, 2]), '2': np.zeros([4, 9, 2]), '3': np.zeros([4, 9, 2]), '4': np.zeros([4, 9, 2])}

    return pretestdata, zi


def ITR(n, p, t):
    if p == 1:
       itr = np.log2(n) * 60 / t
    else:
        itr = (np.log2(n) + p*np.log2(p) + (1-p)*np.log2((1-p)/(n-1))) * 60 / t

    return itr
