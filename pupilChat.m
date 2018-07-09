% code for sending commands to pupil labs eye tracker
% requires python code "pupilChat.py"
% requires marker.png (for calibration) - easiest if on python code path
% requires psychtoolbox
% requires matlab 2014 or later (possibly even later)

% Written by TB 04/05/18
% tarryn.balsdon@ens.fr (or current academic email)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main function for calling subfunctions

% more information on input found below, alongside individual functions

% calls to pupilChat:

% 1. connected = pupilChat('Connect', tcpAddress, pyPupilPath)
%       Connects up to pupil. This must be called before any other
%       subfunction.
%       creates global variables socketPupil and contextPupil

% 2. [totalDur, pythonDur] = pupilChat('CheckTiming', [numChecks])
%       numChecks is optional, defaults to 100. 
%       returns the average total time to request a timestamp from pupil,
%       and the time taken on the python end.

% 3. calibrationComplete = pupilChat('Calibrate', file, [pix], [points], [window], [windowRect]);
%       for optional arguments, defaults to 150 pix, 9 point calibration,
%       with a full screen window.
%       Returns 1 if calibration completed, or 0 if calibration timed out
%       (30 seconds).

% 4. [recFile,timeGap] = pupilChat('StartRecording',[sendTime], [folder]);
%       Starts recording. Setting send time to true (default) will automatically
%       update the pupil clock to be the same as the matlab time. Adding a
%       folder will request the data be saved into that folder. 
%       Returns the name of the recording file (can be used later for
%       getting the raw data out) and a (rough) estimate of the gap in time
%       between the pupil clock and the matlab clock.

% 5. timeout = pupilChat('SendTime',[timein]);
%       sends a timestamp to update the pupil clock. Without the optional
%       argument, will send the current matlab time. 
%       Returns the time pupil now has.

% 6. timeout = pupilChat('Trigger', triggerName)
%       Sends an 'annotation' (similar to a trigger) to pupil, along with
%       the current matlab time.

% 7. timeDifference = pupilChat('TimeDifference')
%       returns the difference in time between the current matlab time and
%       the subsequent pupil time (+ processing time).

% 8. timeout = pupilChat('StopRecording')
%       returns the timestamp on pupil before stopping the recording
%       session.

% 9. disconnected = pupilChat('Disconnect')
%       this must be called if pupilChat('Connect') has been called. Best
%       to do so even if something errors out. Returns true once
%       disconnected, and clears the global variables created by
%       pupilChat('Connect')

% 10. pupilData = pupilChat('ConvertData', recFile, foOut)
%       gets the raw data from the python file and saves two csv files
%       based on the file stem foOut.
%       returns the raw pupil data as a matrix. 

function varargout = pupilChat(command,varargin);
%global contextPupil socketPupil

switch command
    case 'Connect'
        
        % call function pupilChatConnect
        if nargin < 3
            error('\n\n Not enough inputs given, connection requires tcp address and pyPupil path as input arguments\n')
        end
        
        varargout{1} = pupilChatConnect(varargin{1},varargin{2});
        
        
    case 'CheckTiming'
        % call function checkPupilTiming
        if nargin == 2
            [varargout{1}, varargout{2}] = checkPupilTiming(varargin{1});
        else
            [varargout{1}, varargout{2}] = checkPupilTiming;
        end
        
    case 'Calibrate'
        % call function manualPupilCalib
        switch nargin
            case 1
                error('\n\nOne must input the path and file name of the marker image as an argument to call for calibration\n');
            case 2
                varargout{1} = manualPupilCalib(varargin{1});
            case 3
                varargout{1} = manualPupilCalib(varargin{1},varargin{2});
            case 4
                varargout{1} = manualPupilCalib(varargin{1},varargin{2},varargin{3});
            case 5
                error('\n\nOne must input the window rect along with the window handle\n');
            case 6
                varargout{1} = manualPupilCalib(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5});
            otherwise
                error('\n\n too many input arguments\n')
        end
        
    case 'StartRecording'
        % call function startPupilRecording
        switch nargin
            case 1
                [varargout{1}, varargout{2}] = startPupilRecording;
            case 2
                [varargout{1}, varargout{2}] = startPupilRecording(varargin{1});
            case 3
                [varargout{1}, varargout{2}] = startPupilRecording(varargin{1}, varargin{2});
            otherwise
                error('\n\n too many input arguments\n')
        end
        
    case 'SendTime'
        % call function sendPupilTime
        if nargin == 1
            varargout{1} = sendPupilTime;
        elseif nargin == 2
            varargout{1} = sendPupilTime(varargin{1});
        else
            error('\n\n too many input arguments\n')
        end
        
        
    case 'Trigger'
        % call function sendPupilAnnotation
        if nargin == 2
            varargout{1} = sendPupilAnnotation(varargin{1});
        else
            error('\n\nInvalid number of input arguments\n')
        end
        
    case 'TimeDifference'
        % call function checkPupilTimeDif
        if nargin == 1
            varargout{1} = checkPupilTimeDif;
        else
            error('\n\n too many input arguments\n')
        end
        
    case 'StopRecording'
        % call function stopPupilRecording
        if nargin == 1
            varargout{1} = stopPupilRecording;
        else
            error('\n\n too many input arguments\n')
        end
        
    case 'Disconnect'
        % call function pupilChatDisconnect
        if nargin == 1
            varargout{1} = pupilChatDisconnect;
        else
            error('\n\n too many input arguments\n')
        end
        
    case 'ConvertData'
        % call function convertPupilData
        if nargin == 3
            varargout{1} = convertPupilData(varargin{1}, varargin{2});
        else
            error('\n\nInvalid number of input arguments\n')
        end
        
    otherwise
        error('\n\nunrecognised command sent to pupilChat\n\n')
end

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pupilChatConnect
% connected = pupilChatConnect(tcpAddress, pyPupilPath);

% checks and then establishes connection to pupil

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% tcpAddress    - the address of the pupil: 
%                   e.g. 'tcp://127.0.0.1:50020' (the default local address)
% pyPupilPath   - the full path to the python pupil functions
%                   e.g. 'me/Documents/MATLAB/PupilFunctions' (doesn't have
%                   to be in matlab)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% connected     - true if connection was successfully established
%               - false if not - error message printed.

% global vars created:
% contextPupil  - the python context the socket belongs to - needed for
%               closing the connection.
% socketPupil   - the python socket object used to chat to pupil

function connected = pupilChatConnect(tcpAddress, pyPupilPath);
global contextPupil socketPupil

% set up tcp address as a global variable, so that it only needs to be
% entered once

% establish python chat

% check python version - 3.6 is best, above 3 is necessary
pyvers = pyversion;
if str2double(pyvers)<3
    fprintf(['\n\nMatlab recognising python version ' pyvers '\nPython version 3 and later required\nuse pyversion to change python version upon restarting Matlab\n\n']);
    connected = false;
    return
end

% add the path to the python functions
try
    insert(py.sys.path,int32(0),pyPupilPath)
catch thisError
    connected = false;
    fprintf('\n\nFailed to insert python path\n')
    rethrow(thisError)
end

% check connection
connectionInfo = py.pupilChat.checkConnection(tcpAddress);

% connectionInfo is a python tuple containing:
% 1. logical - true, connection established. False, connection not established
% 2. the context object of the socket
% 3. the socket object for chatting to pupil.

connectionOK = connectionInfo{1};

try
assert(connectionOK,'Was unable to establish connection to Pupil. Check the tcp Address and the physical connections');
catch thisErr
    fprintf('\n\nWas unable to establish connection to Pupil. Check the tcp Address and the physical connections\n');
    fprintf('\n\nFATAL ERROR!!! \n\n now you have to force quit...')
    Screen('CloseAll') % in case there is an open screen stopping us from seeing the error
    rethrow(thisErr)
end
% continue if the connection was established

% make the socket global to pass in future

contextPupil = connectionInfo{2};
socketPupil = connectionInfo{3};

fprintf('\n\nConnection with pupil established\n');

connected = true;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% checkPupilTiming
% [totalDur, pythonDur] = checkPupilTiming(numChecks);

% checks the timing to return a call to pupil from matlab
% includes the time it took for python to send and receive a time string
% from pupil

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% numChecks     - the number of calls to make before returning the average
%               defaults to 100

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% totalDur      - the average total duration of return trip to pupil from matlab
% pythonDur     - the average duration on the python end: from sending a
%               timestamp request to receiving the timestamp back

function [totalDur, pythonDur] = checkPupilTiming(numChecks);
global socketPupil

if nargin < 1
    numChecks = 100;
end

totalDurs = zeros(1,numChecks);
pythonDurs = zeros(1,numChecks);

for check = 1:numChecks
    
    tic
    pythonDurs(check) = py.pupilChat.checkTiming(socketPupil);
    
    totalDurs(check) = toc;
    
end

totalDur = mean(totalDurs);
pythonDur = mean(pythonDurs);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% manualPupilCalib
% calibrationComplete = manualPupilCalib(file, pix, points, window, windowRect);

% performs manual calibration. Markers are presented (locations in random
% order). Once pupil recognises fixation (a high tone) a button must be
% pressed to continue. If 30 seconds goes by without continuing to the next
% marker location, the code times out, and calibration is cancelled.

% calibration must be set to manual in the pupil labs app!!!
% sound from pupil labs must be turned on.

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% file      - the path and file name of the marker image
% pix       - the size of the marker to be presented, in pix
%           defaults to 150
% points    - number of calibration markers to present: accepts 1, 5, 9, 13
%           defaults to 9
% window    - the window object - or will open a new full screen window
% windowRect - the dimensions of the window, e.g. [0,0,1950,800];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% totalDur      - the average total duration of return trip to pupil from matlab
% pythonDur     - the average duration on the python end: from sending a
%               timestamp request to receiving the timestamp back

function calibrationComplete = manualPupilCalib(file, pix, points, window, windowRect);
global socketPupil

calibrationComplete = 0;

if nargin < 2
    pix = 150;
end
if nargin <3
    points = 9;
end
if nargin < 4
    % open a screen
    Screen('Preference', 'SkipSyncTests', 1);
    screenNo = max(Screen('Screens'));
    white = WhiteIndex(screenNo);
    % switch out for dummy testing:
    %[window, windowRect] = Screen('OpenWindow', screenNo, white,[0,500;0,500],[],[],0);
    [window, windowRect] = Screen('OpenWindow', screenNo, white,[],[],[],0);
    Screen('FillRect', window, white, windowRect); % clear screen
    Screen('Flip', window);
    
    ListenChar(0); % just in case - don't want to write keypresses anywhere
    
end

border = 50; % pixels between edge of screen and start of marker

% calibration placement
[xCentre, yCentre] = RectCenter(windowRect);

% just the top left hand corner placement of the image is defined, the rest is filled
% in when drawing
switch points
    case 9
        locs = [border,border;...
            xCentre-(pix/2), border;...
            windowRect(3)-(pix)-border, border;...
            border,yCentre-(pix/2);...
            xCentre-(pix/2), yCentre-(pix/2);...
            windowRect(3)-(pix)-border, yCentre-(pix/2);...
            border,windowRect(4)-(pix)-border;...
            xCentre-(pix/2), windowRect(4)-(pix)-border;...
            windowRect(3)-(pix)-border, windowRect(4)-(pix)-border];
    case 5
        locs = [border,border;...
            windowRect(3)-(pix)-border, border;...
            xCentre-(pix/2), yCentre-(pix/2);...
            border,windowRect(4)-(pix)-border;...
            windowRect(3)-(pix)-border, windowRect(4)-(pix)-border];
    case 1
        locs = [xCentre-(pix/2), yCentre-(pix/2)];
    case 13
        locs = [border,border;...
            xCentre-(pix/2), border;...
            windowRect(3)-(pix)-border, border;...
            xCentre-(pix/2), (yCentre/2)-(pix/2);...
            border,yCentre-(pix/2);...
            (xCentre/2)-(pix/2),yCentre-(pix/2);...
            xCentre-(pix/2), yCentre-(pix/2);...
            (xCentre/2*3)-(pix/2),yCentre-(pix/2);...
            windowRect(3)-(pix)-border, yCentre-(pix/2);...
            xCentre-(pix/2), (yCentre/2*3)-(pix/2);...
            border,windowRect(4)-(pix)-border;...
            xCentre-(pix/2), windowRect(4)-(pix)-border;...
            windowRect(3)-(pix)-border, windowRect(4)-(pix)-border];
    otherwise
        locs = [border,border;...
            xCentre-(pix/2), border;...
            windowRect(3)-(pix)-border, border;...
            border,yCentre-(pix/2);...
            xCentre-(pix/2), yCentre-(pix/2);...
            windowRect(3)-(pix)-border, yCentre-(pix/2);...
            border,windowRect(4)-(pix)-border;...
            xCentre-(pix/2), windowRect(4)-(pix)-border;...
            windowRect(3)-(pix)-border, windowRect(4)-(pix)-border];
end

% load the image
marker = imread(file);

% add alpha 
marker(:,:,4) = ones(size(marker,1),size(marker,2));
  
% make texture
tex = Screen('MakeTexture', window, marker);

% we're going to present in random order cos I say so
order = randperm(size(locs,1));
    
% tell pupil to go on calibration
py.pupilChat.sendCommand(socketPupil,'C');

escape = 0;
calib = 1;


while calib <= size(locs,1) && ~escape
    
    Screen('DrawTexture', window, tex, [0,0,size(marker,1),size(marker,2)], [locs(order(calib),:),locs(order(calib),:)+pix]);
    Screen('Flip',window);
    
    % wait for kb input (any for now...)
    n = GetSecs;
    [secs, keyCode] = KbWait([],2,n+30); % if no input for 30 seconds then gives up
    
    if sum(keyCode) == 0
        escape = 1;
    else
        calib = calib + 1;
    end
    
end

Screen('Flip',window);

py.pupilChat.sendCommand(socketPupil,'c'); 

if ~escape
    
    calibrationComplete = 1;
    
end

if nargin < 4
    % close the screen
    Screen('CloseAll');
    
end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% startPupilRecording
% [recFile,timeGap] = startPupilRecording(sendTime, folder);

% Starts recording, with optional time checking. Recodings saved in desired
% folder, if given, otherwise, to pupil default recordings folder. If no
% folder is given, the function will still attempt to get the name of the
% folder of the saved recordings, this may not work on a non-mac.

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% sendTime      - logical - true to send the matlab time to pupil, false to
%               leave pupil to its own time
% folder        - The path to the folder recordings will be saved to. Pupil
%               will create a folder within this folder with numerical ordering of the
%               recordings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% recFile       - the name of the recording file 
% timeGap       - the time it took to send pupil the matlab time and
%               return. This will be an overestimation of the potential gap between
%               matlab and pupil timestamps. If time change is not
%               requested, this will return 0.


function [recFile,timeGap] = startPupilRecording(sendTime, folder);
global socketPupil

if nargin < 1
    sendTime = true;
end

% to find the recording file
if nargin < 2
    % assume default recording settings
    % not sure if this will work on anything other than a mac.
    % safest to input recordings folder.
    folderTree = cd;
    thesePaths = strfind(folderTree, filesep);
    folder = folderTree(1:thesePaths(3));
    
    date = datestr(now, 'yyyy_mm_dd');
    
    folder = [folder 'recordings' filesep date filesep];
    
    startRecCommand = 'R';
    
else
    
    startRecCommand = ['R ' folder];
    
end


files = dir(folder);
numFiles = sum([files(:).isdir]);
fileNum = numFiles - 3; % this may be specific to mac
if isempty(files)
    recFile = [];
elseif fileNum<10
    recFile = [folder '00' num2str(fileNum) filesep 'pupil_data']; %there are two dud listings, and we are going to make a new one
elseif fileNum<100
    recFile = [folder '0' num2str(fileNum) filesep 'pupil_data'];
else
    recFile = [folder num2str(fileNum) filesep 'pupil_data'];
end  

% start recording
py.pupilChat.sendCommand(socketPupil, startRecCommand);

if sendTime
    n = GetSecs;
    pupilTime = py.pupilChat.clockChange(socketPupil,num2str(n));
    timeGap = GetSecs - n;
else
    timeGap = 0;
end
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sendPupilTime
% timeout = sendPupilTime(timein);

% Sends time to pupil, where the pupil clock is updated to this time

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% timein        - the time to send to pupil defaults to current matlab time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% timeout       - the time of the pupil clock after a time check

function timeout = sendPupilTime(timein);
global socketPupil

if nargin < 1
    
    n = GetSecs;
    pupilTime = py.pupilChat.clockChange(socketPupil,num2str(n));
    timeout = str2double(char(pupilTime));
    
else
    
    pupilTime = py.pupilChat.clockChange(socketPupil,num2str(timein));
    timeout = str2double(char(pupilTime));
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sendPupilAnnotation
% timeout = sendPupilAnnotation(annotationStr);

% Sends annotation to pupil. This is a form of trigger, but saving
% alongside data seems unavailable.

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% annotationStr  - the message to send to pupil (a time stamp is added)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% timeout       - the time of the pupil clock checked before sending the
%               annotation, and recorded as the time of the annotation (matlab time
%               included in annotation string).


function timeout = sendPupilAnnotation(annotationStr);
global socketPupil


n = GetSecs;
message = ['matTime:' num2str(n) '. ' annotationStr];
timeout = py.pupilChat.sendMessage(socketPupil, message);
timeout = str2double(char(timeout));


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% checkPupilTimeDif
% timeDif = checkPupilTimeDif();

% Grabs matlab time, grabs pupil clock time, returns pupil time - matlab time

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% timedif   - the time on the pupil clock minus the time on the matlab
%           clock (matlab time is grabed first, so there is a bias for this to be
%           positive).

function timeDif = checkPupilTimeDif();
global socketPupil

n = GetSecs;
pupilTime = py.pupilChat.getTime(socketPupil);

pupilTime = str2double(char(pupilTime));
timeDif = pupilTime - n;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% stotPupilRecording
% [timeOut] = stopPupilRecording();

% Stops pupil recording, returns the time stamp queried right before
% recording finished

% requires socketPupil - global variable defined in pupilChatConnect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% timeOut       - pupil time right before recording stop command sent

function [timeOut] = stopPupilRecording();
global socketPupil

% query pupil time
pupilTime = py.pupilChat.getTime(socketPupil);
timeOut = str2double(char(pupilTime));

% send command to stop recording
py.pupilChat.sendCommand(socketPupil, 'r');
    
end

function disconnected = pupilChatDisconnect();
global contextPupil socketPupil

% disconnect

outInfo = py.pupilChat.closeConnection(socketPupil, contextPupil);

% check if disconnected?

disconnected = true;

% clear the global variables

clear socketPupil contextPupil

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convertPupilData
% pupilData = convertPupilData(recFile, fileOut);

% takes the pupil raw data, grabs certain information, saves it in a csv,
% and returns matlab arrays.

% doesn't *currently* grab annotations...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% recFile       - The full file path and file name of the pupil raw data,
%               this can be obtained from the startPupilRecording function
% foOut       - The full folder path and file 'prefix' of the csv out files - two files
%               are generated based on the raw data and the data converted by pupil to
%               world gaze position, one named 'folder/prefix_pupil.csv' and the other
%               'folder/prefix_gaze.csv' for the raw and the world gaze position data
%               respectively.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT
% pupilData     - a matlab array of the raw pupil data from that saved in
%               'folder/prefix_pupil.csv'


function pupilData = convertPupilData(recFile, foOut);

% in case python is still writing the file...
%WaitSecs(0.2);
while ~(exist(foOut, 'file') == 2)
end

py.pupilChat.saveData(recFile, foOut)

pupilData = csvread([foOut '_pupil.csv'],1,0);

end
