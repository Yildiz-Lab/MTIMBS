function [data] = importbootv2
%this function finds an excel file with MT intensities and creates a
%non-scalar structure to load into the hillbootstrap function

%the excel file must have the concentrations as the top row of file,
%the exposure time in the second row, and
%each individual intensity measurement in the column beneath it
%prompt user to name the data set
data.name = input('Input MAP and MT pair: \n', 's');
%prompt user to find a excel file
[file, path] = uigetfile('.xlsx','Select MT Intensities xlsx');
%make the whole path
data_file_xlsx = fullfile(path, '/' ,file);
data.filepath = fileparts(data_file_xlsx);
%reading the excel file:
%read the different sheet names R1, R2, etc.
sht = sheetnames(data_file_xlsx);
for i=1:numel(sht) %save each sheet in the excel file
    %read the sheets one at a time, save each table in this structure
    inputdata(i).replicate = readmatrix(data_file_xlsx,'Sheet',sht(i));
end

%save the concentrations (must be top of the file)
%ALL REPLICATES MUST HAVE SAME CONCENTRATIONS POINTS
data(1).conc = inputdata(1).replicate(1,:);
%save the exposure times for each sheet
for i=1:numel(sht) %i loops over the replicates/sheets
    temp(i).exposure  = inputdata(i).replicate(2,:); %take the second row of the sheet
end 

%save intensities for each concentration
for n=1:numel(data.conc) %n loops over concentrations
    data(n).intensity=[]; %initialize intesity saving arrays
    for i=1:numel(sht) %i loops over the replicates/sheets
        %save raw values
        angry= rmmissing(inputdata(i).replicate([3:end],n)); 
        %the three makes us ignore the top elements:concentration and exposure time
        %rmmising removes the NaNs, n picks the concentration column
        angry = angry * temp(1).exposure(1)/temp(i).exposure(n); 
        %normalize intesntity based to first exposure time
        data(n).intensity = [data(n).intensity; angry];
        %append the normalized intensities to the total intensity set
        % data(n).intensity = [data(n).intensity; rmmissing(inputdata(i).replicate([3:end],n))];
    end
    %also remove the zeros
    data(n).intensity = nonzeros(data(n).intensity);   
end