% test pupil functions

% you will need to edit these:

tcpAddress = 'tcp://127.0.0.1:50020';
pyPupilPath = '/Users/.../Documents/.../Pupil';
markerFile = '/Users/.../Documents/MATLAB/marker.png';
recFolder = '/Users/.../Documents/Pupil/000/';
outStem = '/Users/.../Documents/Pupil/000/test';
            
try
    % set up window
    Screen('Preference', 'SkipSyncTests', 1);
    screenNo = max(Screen('Screens'));
    white = WhiteIndex(screenNo);
    % switch out for dummy testing:
    [window, windowRect] = Screen('OpenWindow', screenNo, white,[0,500;0,500],[],[],0);
    %[window, windowRect] = Screen('OpenWindow', screenNo, white,[],[],[],0);
    Screen('FillRect', window, white, windowRect); % clear screen
    Screen('Flip', window);
    
    ListenChar(0);
    
    % connect pupil
    
    connected = pupilChat('Connect', tcpAddress, pyPupilPath);
    
    % check timing
    
    [totalDur, pythonDur] = pupilChat('CheckTiming');
    
    % run calibration
    
    calibrationComplete = pupilChat('Calibrate', markerFile, 140, 5    , window, windowRect);
    
    % start recording
    
    [recFile,timeGap] = pupilChat('StartRecording',1, recFolder);
    
    WaitSecs(1);
    
    % send time again, to check whether the function works
    timeout2 = pupilChat('SendTime');
    
    % send start trigger
    startRecTrigTime = pupilChat('Trigger', 'StartRec');
    
    
    % check the time difference
    timeDifference = pupilChat('TimeDifference');
    
    % stop recording
    
    stopRecTime = pupilChat('StopRecording');
    
    % disconnect
    disconnected = pupilChat('Disconnect');
    
    % convert Data
    pupilData = pupilChat('ConvertData', recFile, outStem);
    
    
    Screen('CloseAll')
    ListenChar(1);
    
catch thisErr
    Screen('CloseAll')
    ListenChar(1);
    rethrow(thisErr)     
end
