% Script to look at the interbeat time (R-R distance)
%
% INPUT:  
% - Need recording an file (*.mrk) 
% 
% OUTPUT
% - Excel file Interpeak_distance.xlsx with one sheet per HEART condition, one sheet per SOUND condition, one sheet with all the data and one sheet with the summary (mean, std, median, MAD, RMSSD).  
%
% Modification of 18.12.2024
% Add the computation of the Root Mean Square of Successive Differences (RMSSD)

%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories


%input EEG folder
path=uigetdir(cd, 'Select folder which contains the mrk files');

%outputpile
[outputFile, outputPath] = uiputfile(strcat(path,'\Interpeak_distance_HEP.xlsx'),'Select the output file');

%look for files
files=dir(fullfile(path,'**','*.mrk'));

%initialisation
outputALL=cell(size(files,1),3000); %We create a matrix with all values on one line
outputHEART=cell(size(files,1),1500);
outputSOUND=cell(size(files,1),1500);

SummaryOutput=cell(size(files,1),18); %We create a sheet summarizing this variability: mean, std, median, MAD, RMSSD

for i=1:size(files,1)
    %load EEG Data
    file=fullfile(files(i).folder,files(i).name);
    disp(file);
    [MRKevents]=open_mrk(file); %open the recording file
  
    
    %% Compute the distance between R-peaks
    
    countHEART=1;
    countSOUND=1;
    outputALL{i,1}=files(i).name; outputHEART{i,1}=files(i).name; outputSOUND{i,1}=files(i).name; %save filename
    
    for k=2:size(MRKevents,1)     
        if and (MRKevents{k,3}==1,MRKevents{k-1,3}==1) %HEART
            countHEART=countHEART+1;            
            outputHEART{i,countHEART}= (MRKevents{k,1}-MRKevents{k-1,1})*(1000/2048); %compute the distance between stim and nextR R-peak, and convert in ms 
        end
        
        if and (MRKevents{k,3}==2,MRKevents{k-1,3}==2) %SOUND
            countSOUND=countSOUND+1;            
            outputSOUND{i,countSOUND}= (MRKevents{k,1}-MRKevents{k-1,1})*(1000/2048); %compute the distance between stim and nextR R-peak, and convert in ms 
        end
    end
    
    outputALL(i,2:countHEART+countSOUND-1)=num2cell(horzcat(outputHEART{i,2:countHEART},outputSOUND{i,2:countSOUND}));
    
    %compute summary
    SummaryOutput{i,1}=files(i).name;
    %HEART    
    vecValues=cell2mat(outputHEART(i,2:end)); %put everything into a vector
    SummaryOutput{i,2}=mean(vecValues); %mean
    SummaryOutput{i,3}=std(vecValues); %std
    SummaryOutput{i,4}=median(vecValues); %median
    SummaryOutput{i,5}=mad(vecValues,1)*1.4826; %mad
    SummaryOutput{i,6}=computeRMSSD(vecValues); %compute RMSSD
    clear vecValues;
    
    %SOUND    
    vecValues=cell2mat(outputSOUND(i,2:end)); %put everything into a vector
    SummaryOutput{i,8}=mean(vecValues); %mean
    SummaryOutput{i,9}=std(vecValues); %std
    SummaryOutput{i,10}=median(vecValues); %median
    SummaryOutput{i,11}=mad(vecValues,1)*1.4826; %mad
    SummaryOutput{i,12}=computeRMSSD(vecValues); %compute RMSSD
    clear vecValues;
    
    %ALL    
    vecValues=cell2mat(outputALL(i,2:end)); %put everything into a vector
    SummaryOutput{i,14}=mean(vecValues); %mean
    SummaryOutput{i,15}=std(vecValues); %std
    SummaryOutput{i,16}=median(vecValues); %median
    SummaryOutput{i,17}=mad(vecValues,1)*1.4826; %mad
    SummaryOutput{i,18}=computeRMSSD(vecValues); %compute RMSSD
    clear vecValues;
    

end

%save output file
headerOutput=cell(1,1500); 
headerOutput{1,1}='filenames'; headerOutput{1,2}='Interpeak distance of the heart for HEART condition(in ms)';
writecell([headerOutput;outputHEART],fullfile(outputPath,outputFile),'Sheet','HEART_condition');

headerOutput=cell(1,1500); 
headerOutput{1,1}='filenames'; headerOutput{1,2}='Interpeak distance of the heart for SOUND condition(in ms)';
writecell([headerOutput;outputSOUND],fullfile(outputPath,outputFile),'Sheet','SOUND_condition');

headerOutput=cell(1,3000); 
headerOutput{1,1}='filenames'; headerOutput{1,2}='Interpeak distance of the heart for ALL conditions(in ms)';
writecell([headerOutput;outputALL],fullfile(outputPath,outputFile),'Sheet','ALL_conditions');

%save summary file
headerSummary=cell(1,15);
headerSummary{1,1}='filenames';headerSummary{1,2}='Mean_HEART';headerSummary{1,3}='Std_HEART';headerSummary{1,4}='Median_HEART';headerSummary{1,5}='MAD_HEART'; headerSummary{1,6}='RMSSD_HEART';
headerSummary{1,8}='Mean_SOUND';headerSummary{1,9}='Std_SOUND';headerSummary{1,10}='Median_SOUND';headerSummary{1,11}='MAD_SOUND';headerSummary{1,12}='RMSSD_SOUND';
headerSummary{1,14}='Mean_ALL';headerSummary{1,15}='Std_ALL';headerSummary{1,16}='Median_ALL';headerSummary{1,17}='MAD_ALL';headerSummary{1,18}='RMSSD_ALL';
writecell([headerSummary;SummaryOutput],fullfile(outputPath,outputFile),'Sheet','Average values');
