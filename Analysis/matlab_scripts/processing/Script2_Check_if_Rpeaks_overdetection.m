%script to fastely check if there is overdetection in R-peak by Librow
%algo. To be executed only after Script1_ECG_R_peak_detection_and_mark_EEG.m
%
% Input: Select the raw bdf file of one participant 
% Output: Text in the Matlab console which inform if the Librow detection
% has detect R-R distance shorter than 453ms which could be an
% overdetection. Then we manually inspected the signal to decide if there
% was a R-peak detection error (manual remove of the faulty marker). 

%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories

%input EEG files
[file,path]=uigetfile('*.bdf', 'Select the EEG/ECG recording file of one participant','MultiSelect','off');

MRK_file = fullfile(path,strcat(file, '.mrk')); % name of MRK file
 
mrk=open_mrk(MRK_file);
mrk=cell2mat(mrk);

problem=false;
disp(strcat('Check file:',' ',file,'.mrk')); 

for k=2:length(mrk)
    if mrk(k-1,3)==mrk(k,3)
        diff=mrk(k,1)-mrk(k-1,1);
        if diff<928 %928 TF corresponds at a RR distance of 453ms 
            disp(strcat('Problem TF=',num2str(mrk(k,1)), ' Trigger=',num2str(mrk(k,3))));
            problem=true;
        end
    end
end
if ~problem
    disp('No Problem');
end

