function MTIMBS_ncolor_wrapper()

%% Authors: Jon Fernandes and Joseph Slivka and Parnika Kant!
% Last Updated: 2024/5/30
%% Description:

% Run intensity_measurement function for all files in a folder
% this function also dives into the subfolders of that folder and makes new
% folders replicating the original folder structure
% Now has the capacity to handle multicolor images
% Requires the functions MTIMBS_competition for the primary color 
% and MTIMBSB for the secondary colors

% add paths
addpath(fullfile(cd,'MTIMBS_subfunctions'))
addpath(fullfile(cd,'analysis_codes'))

%% Prompt User to open the folder with images
fprintf("Please chose a folder of images to analyze \n");
fprintf("Tif files should be saved as: Blue -> Green -> Red \n");
top_folder=uigetdir; %actually get folder from user

%% Will go through all files in immediate subfolder for tifs
dc = dir(fullfile(top_folder, '*.tif'));
contents = dir(top_folder);


%% Prepare Single color image folders for MTimbs

fname_w_path = fullfile(top_folder, dc(1).name); 
%grabs the filename for the 3rd file in the folder (should be an
%image)
%make the 3 a 4 on macOS machines
I = tiffreadVolume(fname_w_path); 
%read the tif file as one big boy
number_channels = size(I,3);      
%figure out the number of colors in the images

if number_channels > 1
    winner = input("Which color do you want to base the MT locations off of? (1, 2, ...  num_channels)) \n");
else
    winner = 1;
end

colors = cell(1,number_channels); %initialize array for number of colors

for i = 1:length(colors)
        colors{i} = fullfile(top_folder,strcat('color',num2str(i))); 
        %saving directory names of one color images
end

if ~isfolder(colors{1}) %if the folders don't already exist
    for i = 1:length(colors)
       mkdir(colors{i}); 
       %making the directory to save one color images
    end

    for f = 1:length(dc) %make the 3 a 4 on macOS machines
        %this runs over each file

        fname_w_path = fullfile(top_folder, dc(f).name);
        %grab each filename
        I=tiffreadVolume(fname_w_path);
        %read the multi-color tif image for each file

        for i = 1:number_channels %for each channel
            imwrite(I(:,:,i), fullfile(colors{i}, dc(f).name));
            %save single color images, with same filename
        end
    end
end

if isempty(dc)
    error("There are no .tif files in this directory. Please verify this is the correct file location. \n")
end

%% Now we need to get the Excel file ready to save the MT Intensities
fprintf("Select the folder where you would like to save the Comp_MT_Intensity.xls \n");
save_location=uigetdir; %get save location from user
data_file_xlsx = fullfile(save_location, '/' ,'Comp_MT_Intensities.xlsx');

if ~isfile(data_file_xlsx) %if there is no existing excel file
    whole_data = [];
    writematrix([],data_file_xlsx); %write an emptu excel file
else %if there IS an existing excel file
    append_file = input("This file already exists. Would you like to append? (y/n) \n", 's');
    if append_file == 'y'
        for i=1:number_channels
            whole_data(:,:,i) = readmatrix(data_file_xlsx,'UseExcel', 1,'Sheet',i); 
            %load in the existing MT measurements
        end
    else
        fprintf("Guess you don't want to append to your excel file \n");
        return
    end
end

concentration = zeros(1,number_channels); %initialize array to save conc values
for i=1:number_channels
   concentration(i) = input(strcat("Enter the concentration for color ", num2str(i), " in nM \n"));
   %prompt user for concs of each color
end

if ~isempty(whole_data)
    mask = ones(1,size(whole_data,2)); %make an array to help find where concs line up
    for i=1:number_channels
        new_mask = whole_data(1,:,i) == concentration(i); 
        mask = mask.*new_mask;
        %find if concs line up with current intensities file
        %the array will have a 1 in the column where concs match up,
        %elsewwise 0
    end
    
    [append_col] = find(mask == 1); %figure out what column has matching concs
else %if there was no intensities measured
    append_col = []; %the column variable is left empty
end


if isempty(append_col)%i.e. when there were no prior measured intensities,
    %This will make a new column

    exposure_time = zeros(1,number_channels); %initialize array to save exposure values
    for i=1:number_channels
        exposure_time(i) = input(strcat("Enter the exposure time for color ", num2str(i), " in ms \n"));
        %prompt user for exposures of each color
    end

    append_col = size(whole_data,2)+1; %find last column, add one more
 
    whole_data(1,append_col,:) = concentration; %save the array of concs in correct column
    whole_data(2,append_col,:) = exposure_time; %save the array of exposures
    whole_data(3,append_col,:) = zeros(1,number_channels); %initialize array of zeros to denote the winning color
    whole_data(3,append_col,winner) = 1; %mark the winning color with a 1

    All_I = zeros(0,number_channels); %initialize arrays to save intensity numbers

else %when there are prior measured intensities
    append_col = append_col(1); %figure out which column we will work with
    fprintf("This concentration already exists. Appending to existing with exposure time " + num2str(whole_data(2,append_col)) + " ms \n");
    All_I = whole_data(4:end,append_col,:); %save all the already existing values in that column
    All_I = All_I(All_I(:,winner) ~= 0,:);  %ignore all the zeroes in that column (based on winner channel)
end


fprintf("TO EXIT: If at any point you would like to quit, press 'ctrl + c' to exit \n")

skip_NGMM = input("Turn off automated number of gaussian estimation? (y/n) \n",'s');

%% Joseph's fancy math stuff
% suppress warnings from gmcluster > gmdistribution.fit > fitgmdist >
% gaussian_clustering related to convergence at high MTs
%  if you wish to not show these warnings, simply turn the warning to 'on' below

w = struct(); w.identifier = 'stats:gmdistribution:FailedToConverge'; w.state = 'on';
warning('off',w.identifier);

%mkdir(savedir)
dc_name = cell(1,number_channels);

%% Now we're ready to do the measurements

for i = 1:number_channels
    dc_name{i} = dir(fullfile(colors{i}, '*.tif'));
end

ridge_threshold = 0; %cheat to initialize with no initial ridge

for f = 1:length(dc_name{1}) %gonna loop over all the files
    
    fname_w_path = cell(1,number_channels);

    for i = 1:number_channels
        fname_w_path{i} = fullfile(dc_name{i}(f).folder,dc_name{i}(f).name);
        %get all filenames
    end

    %% Now run the intensity measurement
    [corrected_intensities, ridge_threshold, savedmts] = MTIMBS_competition(fname_w_path{winner}, ridge_threshold, skip_NGMM);

    %collect the intensity values
    %collect the ridge threshold (to initialize next image)
    %collect the saved_MTs positions, to feed to other color images
    if ~isempty(savedmts)
    export_MT_coord(savedmts,fname_w_path{winner});
    

    intensity_array = zeros(length(corrected_intensities),number_channels); 
    %make a matrix as long as corrected intensites, wide as num_channels
    intensity_array(:,winner) = corrected_intensities; 
    %save the intensities MTimbs just found

    for i=1:number_channels %do MTimbs on all the channels
        if ~isempty(corrected_intensities) %if you didnt skip the image
            if i~=winner %for the channels you didnt skip
               [intensity_array(:,i)] = MTIMBSB(fname_w_path{i}, savedmts);
               %passing MTimbs the saved MTs locations and different color
               %images, saves the array of MT intensities that comes out
               %
               %I need to edit the MTIMBSS to do the translational search  
            end
        else %if you did skip the image
            intensity_array(:,i) = zeros(length(corrected_intensities),number_channels);
            %this stops the code from breaking if there is no saved MTs in
            %the previous image (i.e. skipped image)
        end
    end
    All_I = [All_I; intensity_array];
    %append the newly measured MT intensities to the old data

  
    % FORMAT/EXPORT XLSX FILE
    whole_data(4:size(All_I,1)+3,append_col,:) = All_I; 
    %add intensities at the end of excel file

    for i=1:number_channels
        writematrix(whole_data(:,:,i), data_file_xlsx,'UseExcel', 1,'Sheet',i);
        %rewrite the new excel file, with new intensities
    end
    
    end
       
    fprintf("Total Number of MTs analyzed in this condition: " + num2str(size(All_I,1)) + "\n") 
    %remind the user how many MTs have already been analyzed
  
end

% compiled analysis goes here
% figure(616)
% histogram(AllI,floor(length(AllI)/8))


