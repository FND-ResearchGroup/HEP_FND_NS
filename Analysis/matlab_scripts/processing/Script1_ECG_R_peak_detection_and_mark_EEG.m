% R-peak detection and generate marker on the HEP
% INPUT: 
% - Need recording file (*.bdf) of the HEP experiment. There is serveral requirements: 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
% 	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
% 	-> The file contain the tiggers 5 (start heart block), 11 (middle of the recording), 12 (end of recording). 
% In addition, to be exectuded, the folder 'functions_needed' must be in the same path than the script.
% 
% OUTPUT: In the same folder as the input '*.bdf' file, you will find these files:
% - the Cartool marker file '*.mrk' (* is replace by the input bdf file name) which will permit the processing of the HEP data: 
% 	1: R-peak during heart beat block
% 	2: R-peak during sound block
% 	3: R-peak during Inter-stimulus rest period 
% 	4: R-peak during all other period (questions, evaluation, instruction)
% - A log text file which inform about which of the two ECG channel were the best 
%
% 	The R-peak detection is managed by LIBROW script
% 	(http://www.librow.com/articles/article-13)
%
% Author: Michael Mouthon, FND lab, University of Fribourg
%
% Versioning : modification pour généré la randomisation des conditions qui sera lu par
% 2.1 : Detection of R-peak on the full HEP length instead, 31.08.2023


%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories

%input EEG files
[file,path]=uigetfile('*.bdf', 'Select the EEG/ECG recording file of one participant','MultiSelect','off');

participantCode=inputdlg('Enter the participant code','Participant code');%participant code for the output file name

[data,NumChan,ChanLabels,SamplingRate,~,trigger]=open_bdf(strcat(path, file)); %open the recording file


%set the begining of the experiment to ignore the signal before the
%experiment start (part of signal where the patient is suceptible to move)
temp=find(trigger==5); %first trigger 5 is the beginning of the experiment
startData=temp(1);
endData=find(trigger==11); %pause
startData2=temp(6);
endData2=find(trigger==12); %end recording

%Public variable
BestECGchannel=1;

%% Detection of the R peak for over all data 

%Extraction of each ECG channel
EXG1=data(:,find(strcmp(ChanLabels, 'EXG1')==1))';
EXG2=data(:,find(strcmp(ChanLabels, 'EXG2')==1))';
EXG3=data(:,find(strcmp(ChanLabels, 'EXG3')==1))';
EXG4=data(:,find(strcmp(ChanLabels, 'EXG4')==1))';

ecg1=EXG1-EXG2;
ecg2=EXG3-EXG4;

%detection of the R peaks for all           
[peakPositionsECG1, ecg1Filtered,internalThreshold1]=RpeakDetectionPositionV2(ecg1,SamplingRate);
[peakPositionsECG2, ecg2Filtered,internalThreshold2]=RpeakDetectionPositionV2(ecg2,SamplingRate);

%store the Rpeak amplitude (number of peak can be different between ecg1 and ecg2)
for i=1:length(peakPositionsECG1)
    peakAmplitudeECG1(i)=ecg1Filtered(peakPositionsECG1(i));
end
for i=1:length(peakPositionsECG2)
    peakAmplitudeECG2(i)=ecg2Filtered(peakPositionsECG2(i));
end

   
%% Determine which is the best ECG channel between the Channel1 or Channel2

% To determine which of the ECG channel is the best, we are going to look at
% which of channel 1 or 2 give the mean highest amplitude for the R-peak. 
% We first need to clean the amplitudes value by two different way:
% First, the amplitude are compute on the high-pass filtred ecg signal to
% remove the drift in the signal
% Second, outlier values are detected by computing the Median Absolute
% Deviation (MAD). Values outside of the confidance interval median +/-
% 2*MAD are removed from the final mean. 
AmplitudesChannel1NEW=cleanOutliersWithMAD(peakAmplitudeECG1,2);
AmplitudesChannel2NEW=cleanOutliersWithMAD(peakAmplitudeECG2,2);

%Determination of the best ECG channel
if mean(AmplitudesChannel1NEW)>=mean(AmplitudesChannel2NEW)
    BestECGchannel=1; %Best channels is EXG1-EXG2
else 
    BestECGchannel=2; %Best channels is EXG3-EXG4
end

%% Writing markers files for the best ECG channel
% Writing the position of R-peak detected for the best ECG channel. Will be
% used in the data processing of the HEP task

%correction of the position because we ignore the signal before the
%start of the experiment
if BestECGchannel==1
    mask=(peakPositionsECG1>startData)&(peakPositionsECG1<endData2); %extract indices between the begining and the end of the recording  
    pos=peakPositionsECG1(mask);
else
    mask=(peakPositionsECG2>startData)&(peakPositionsECG2<endData2); %extract indices between the begining and the end of the recording  
    pos=peakPositionsECG2(mask);
end

% Write peak position into MRK file for the original files
% I remove the first and last peak  because detection on boarder by filtering
% (as used in the script) are sometime wrong
outputfile=strcat(path,file,'.mrk');
WriteMRK_HEPtask(pos(2:end-1),trigger,outputfile); %We remove the first and last R-peak to avoid EPOCH issues.




%% Writing results a log text file

%save log info for user
outputFinalfile=strcat(path,'logfile_',participantCode{1},'.txt');
output2 = fopen(outputFinalfile,'w');
fprintf(output2,'%s\t\t%s\r\n','Participant code:',participantCode{1}); %Participant code
fprintf(output2,'%s\t%i\r\n','Best ECG channel used for the detection:',BestECGchannel); 
fprintf(output2,'%s\t%i\r\n','Internal Threshold used in LIBROW R-peak detection script for ECG channel 1:',internalThreshold1);
fprintf(output2,'%s\t%i\r\n','Internal Threshold used in LIBROW R-peak detection script for ECG channel 2:',internalThreshold2);
fprintf(output2,'%s\t\t%s\r\n','Date of the processing:',string(datetime("now")));

fclose(output2);

