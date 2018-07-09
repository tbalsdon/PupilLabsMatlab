# PupilLabsMatlab
Code for connecting Matlab, python and pupil labs

created by Tarryn Balsdon 04/05/18

This code creates a basic connection between Matlab and the Pupil Labs eye-tracker (via python). It is set up to allow minimal installations and messing around, but is not very functional. (Improvements welcome).

Dependencies:
You will need to install pupil-capture from the pupil labs website: https://pupil-labs.com/
You will also need python-3, with the following libraries: numpy, zmq, and msgpack

The code will work on Matlab 2014 or later (tested on 2016 and 2017) with psychtoolbox

You will also need a png of the calibration marker (from the pupil labs website) if you wish to run a calibration.

The basic functions allow one to set up a connection with pupil labs, calibrate, record/stop recording, query pupil labs timestamps, change pupil labs timestamps, and send annotations. There is also a function to get the saved data out of the python object into a sensible format for reading in matlab (or csv).

Matlab will freeze if the code is run without the device plugged in, pupil capture open, and the correct tcp address. However, it will close any open windows and type a warning before doing so. (any suggestions for getting around this are welcome).
