'''
(*)~----------------------------------------------------------------------------------
 Pupil Chat.
 
 Written by TB 04/05/18
 tarryn.balsdon@ens.fr (or current academic email)
 
 Based on examples from pupil helpers.
----------------------------------------------------------------------------------~(*)
'''

"""
This code is linked to functions from Matlab script 'pupilChat.m'

Written for smooth, albeit simple, communication between matlab experiments and the pupil eye tracker.

Functions:
checkConnection(tcpAddress):    checks whether a connection with pupil can be established
                                returns connectionOk (boolean), the context handle, and the socket handle
checkTiming(socket):            checks the time taken to grab the time stamp from pupil
                                returns the duration (time from sending to receiving)
sendCommand(socket,inputStr):   sends a command to pupil, eg, 'R' (start recording), 'r' (stop recording, etc)
clockChange(socket, timeStampIn): sends a new timestamp to update the pupil clock
                                returns the timestamp pupil now has
getTime(socket):                returns the pupil timestamp
sendMessage(socket, myMessage): send an annotation to pupil
                                returns the pupil timestamp
closeConnection(socket, ctx):   closes the context and the socket
                                returns the last pupil timestamp
saveData(recFile, saveFilePrefix): takes the pupil data out of the msgpack and puts it in a
                                use-able format, saved as csv
                                
"""


import zmq
import msgpack
import time


def checkConnection(tcpAddress):

    ctx = zmq.Context()
    socket = zmq.Socket(ctx, zmq.REQ)
    socket.connect(tcpAddress)
    

    # set up a poller
    poller = zmq.Poller()
    poller.register(socket, zmq.POLLIN)
    
    socket.send_string('t')
    
    # check if sending/receiving will be successfull
    evts = poller.poll(1000)

    if not evts:
        connectionOK = False
        #this is a fatal error
        

    else:
        connectionOK = True
        # have to actually receive the str in order to continue
        t = socket.recv_string()
        
        poller.unregister(socket)

    return connectionOK, ctx, socket



def checkTiming(socket):

    tic = time.clock()
    
    socket.send_string('t')
    t = socket.recv_string()
    
    toc = time.clock()
    dur = toc - tic
    
    return dur

def sendCommand(socket,inputStr):
    
    socket.send_string(inputStr)
    socket.recv_string()

def clockChange(socket, timeStampIn):

    socket.send_string('T '+timeStampIn)
    socket.recv_string()
    
    socket.send_string('t')
    t = socket.recv_string()

    return t

def getTime(socket):
    
    socket.send_string('t')
    t = socket.recv_string()

    return t

def sendMessage(socket, myMessage):
    
    socket.send_string('t')
    pupilTime = socket.recv_string()
    
    notification = {'subject': 'annotation', 'label': myMessage, 'timestamp': pupilTime, 'duration':0,'source':'matlab','record': True}
    topic = 'notify.'+notification['subject']
    payload = msgpack.dumps(notification, use_bin_type=True)
    
    socket.send_string(topic, flags=zmq.SNDMORE)
    socket.send(payload)
    socket.recv_string()
    return pupilTime


def closeConnection(socket, ctx):

    socket.close()
    ctx.term()

    return socket, ctx

def saveData(recFile, saveFilePrefix):
    
    import numpy as np
    
    # this function gets the pupil data, pulls out essential information
    # and then saves 2 files: pupil data and gaze data.
    # there are two files because the timestamps don't necessarily match up
    
    pupilFile = recFile
    
    # import data
    with open(pupilFile, "rb") as f:
        data = msgpack.unpack(f, encoding='utf-8')

    # get what we want and save
    pupilPos = data.get('pupil_positions')
    gazePos = data.get('gaze_positions')

    # grab pupil data
    idPup = [d['id'] for d in pupilPos]
    timestampsPup = [d['timestamp'] for d in pupilPos]
    diameter = [d['diameter'] for d in pupilPos]
    confidencePup = [d['confidence'] for d in pupilPos]

    normPosPup = [d['norm_pos'] for d in pupilPos]
    xNormPosPup = [i[0] for i in normPosPup]
    yNormPosPup = [i[1] for i in normPosPup]


    if 'diameter_3d' in pupilPos[0]:
        diameter3d = [d['diameter_3d'] for d in pupilPos]
        modelConf = [d['model_confidence'] for d in pupilPos]
        pupDat = [idPup, timestampsPup, diameter, confidencePup, diameter3d, modelConf, xNormPosPup, yNormPosPup]
        pupDat = np.asarray(pupDat)
        pupDat = pupDat.transpose()
    
        myHeader = 'id,timestamp,diameter,confidence,3dDiameter,3dModelConfidence,xpos,ypos'


    else:
        pupDat = [idPup, timestampsPup, diameter, confidencePup, xNormPosPup, yNormPosPup]
        pupDat = np.asarray(pupDat)
        pupDat = pupDat.transpose()
    
        myHeader = 'id,timestamp,diameter,confidence,xpos,ypos'
    
    np.savetxt(saveFilePrefix+'_pupil.csv',pupDat,delimiter = ',',header = myHeader)
    
    # grab gaze data
    base = [d['base_data'] for d in gazePos]
    idGaz = [i[0]['id'] for i in base]
    
    timestampGaz = [d['timestamp'] for d in gazePos]
    normPosGaz = [d['norm_pos'] for d in gazePos]
    confidenceGaz = [d['confidence'] for d in gazePos]
    xNormPosGaz = [i[0] for i in normPosGaz]
    yNormPosGaz = [i[1] for i in normPosGaz]
    
    gazDat = [idGaz, timestampGaz,xNormPosGaz,yNormPosGaz,confidenceGaz]
    gazDat = np.asarray(gazDat)
    gazDat = gazDat.transpose()
    
    myHeader = 'id,timestamp,xpos,ypos,confidence'
    
    np.savetxt(saveFilePrefix+'_gaze.csv',gazDat,delimiter = ',',header = myHeader)
