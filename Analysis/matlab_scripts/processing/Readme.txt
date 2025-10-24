This folder contains the script used during the preparation of the processing of the EEG/ECG file. 
- Script1_ECG_R_peak_detection_and_mark_EEG.m : R-peak automatic detection based on the ECG and generates a marker file used during EEG Epoching
- Script2_Check_if_Rpeaks_overdetection.m: The marker file generated at previous step are visually inspected to check the accuracy of the automatic detection. This script helps to find the potential overdetections. 
- Script3_Generate_separate_ECG_file.m: Generate a separate file for the ECG recording. 

For more details on each script, please look at the comments at the top.
The data shared on the repository www.doi.org/10.5281/zenodo.15010968 already include the output of these three scripts (don't need to run them again).
Then, the EEG and ECG data were processed using EEGpal tool (https://github.com/DePrettoM/EEGpal).

Michaël Mouthon - 19.09.2025