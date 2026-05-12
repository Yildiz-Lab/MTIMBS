function MTIMBS_ncolor_wrapper_v2026()

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
folder=uigetdir; %actually get folder from user


% Get all TIFF files in folder
files = dir(fullfile(folder, "*.tif"));
files = [files; dir(fullfile(folder, "*.tiff"))];  % include .tiff

% Preallocate
N = numel(files);
infoList = struct('name', cell(N,1), 'colors', cell(N,1));

for k = 1:N
    fname = fullfile(folder, files(k).name);
    % info = imfinfo(fname);           % imfinfo returns array for multi-page TIFF
    % Use first IFD for per-file channel count; adjust if you need all pages
    
    img = imread(fname);
    I = tiffreadVolume(fname); 
    %read the tif file as one big boy
    try
    info = imfinfo(fname);
    desc = info.ImageDescription;   % metadata string
    % Find 'channels=' and extract number
    tokens = regexp(desc, 'channels=(\d+)', 'tokens');
    number_channels = str2double(tokens{1}{1});
    tokens = regexp(desc, 'slices=(\d+)', 'tokens');
    slices = str2double(tokens{1}{1});
    catch
    number_channels = size(I,3);
    slices = 1;
    end

    infoList(k).name   = files(k).name;
    infoList(k).colors = number_channels;

end

% Convert to table for easy viewing
T = struct2table(infoList);
disp(T);






% %% Will go through all files in immediate subfolder for tifs
% dc = dir(fullfile(top_folder, '*.tif'));
% contents = dir(top_folder);
% 
% 
% %% Prepare Single color image folders for MTimbs
% 
% fname_w_path = fullfile(top_folder, dc(1).name); 
% %grabs the filename for the 3rd file in the folder (should be an
% %image)
% %make the 3 a 4 on macOS machines
% I = tiffreadVolume(fname_w_path); 
% %read the tif file as one big boy
% try
% info = imfinfo(fname_w_path);
% desc = info.ImageDescription;   % metadata string
% % Find 'channels=' and extract number
% tokens = regexp(desc, 'channels=(\d+)', 'tokens');
% number_channels = str2double(tokens{1}{1});
% tokens = regexp(desc, 'slices=(\d+)', 'tokens');
% slices = str2double(tokens{1}{1});
% catch
% number_channels = size(I,3);
% slices = 1;
% end
% %figure out the number of colors in the images
% 
if number_channels > 1
    winner = input("Which color do you want to base the MT locations off of? (1, 2, ...  num_channels)) \n");
else
    winner = 1;
end


%% Alternatively do a simple method of just above a certain threshold


% colors = cell(1,number_channels*length(dc)); %initialize array for number of colors
% 
% for f = 1:length(dc)
%     [~,fname,~] = fileparts(dc(f).name);
%     movie_folder = fullfile(top_folder, fname);
%     mkdir(movie_folder);
%     for i = 1:number_channels
%         % colors{i} = fullfile(top_folder,strcat('color',num2str(i))); 
%         colors{i + (f-1)*number_channels} = fullfile(movie_folder,strcat('color',num2str(mod(i-1,number_channels)+1))); 
%         %saving directory names of one color images
%     end
% end
% 
% if ~isfolder(colors{1}) %if the folders don't already exist
%     for i = 1:length(colors)
%        mkdir(colors{i}); 
%        %making the directory to save one color images
% 
%     end
% 
%     for f = 1:length(dc) %make the 3 a 4 on macOS machines
%         %this runs over each file
% 
%         fname_w_path = fullfile(top_folder, dc(f).name);
%         %grab each filename
%         I=tiffreadVolume(fname_w_path);
%         %read the multi-color tif image for each file
% 
%         for i = 1:number_channels %for each channel
%             for s = 1:slices
%                 imwrite(I(:,:,i+(s-1)*number_channels), fullfile(colors{i+(f-1)*number_channels}, strcat(num2str(s),'_',dc(f).name)));
%                 %save single color images, with same filename
%             end
%         end
%     end
% end
% 
% if isempty(dc)
%     error("There are no .tif files in this directory. Please verify this is the correct file location. \n")
% end
% 




%% Now we need to get the Excel file ready to save the MT Intensities
fprintf("Select the folder where you would like to save the Comp_MT_Intensity.xls \n");
save_location=uigetdir; %get save location from user
data_file_xlsx = fullfile(save_location ,'Comp_MT_Intensities.xlsx');

if ~isfile(data_file_xlsx) %if there is no existing excel file
    whole_data = [];
    writematrix([],data_file_xlsx); %write an emptu excel file
else %if there IS an existing excel file
    append_file = input("This file already exists. Would you like to append? (y/n) \n", 's');
    if append_file == 'y'
        for i=1:number_channels
              % sheetList = sheetnames(data_file_xlsx)
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

ridge_threshold = 0; %cheat to initialize with no initial ridge

for f = 1:N
    
    filename = fullfile(files(f).folder, files(f).name);

    info = imfinfo(filename);
    numPages = numel(info);
    if mod(numPages, number_channels) ~= 0, error('Pages not multiple of channels'); end
    slices = numPages / number_channels;
    
    % Build stack for slice s
    stack = zeros(info(1).Height, info(1).Width, number_channels, class(imread(filename,1)));
    
    for slice = 1:length(slices) %image if multiple acquisition.
    
    for c = 1:number_channels
        pageIdx = (slice-1)*number_channels + c;
        stack(:, :, c) = imread(filename, pageIdx);
    end

    % Run full intensity measurement on the chosen channel
    [corrected_intensities, ridge_threshold, savedmts, option_robust] = ...
        MTIMBS_competition(stack, winner, ridge_threshold, skip_NGMM);
    

    % Prepare intensity array: rows = number of MTs, cols = channels
    nMT = numel(corrected_intensities);
    intensity_array = zeros(nMT, number_channels);

    % Put winner results
    intensity_array(:, winner) = corrected_intensities;

    % If no MTs found, skip per-channel measurement and keep zeros
    if nMT > 0 && ~isempty(savedmts)
        % Process other channels using saved MT coords
        for i = 1:number_channels
            if i == winner, continue; end
            try
                [intensity_array(:, i), savedmts] = MTIMBSB(stack(:, :, i), savedmts, option_robust);
            catch ME
                % If the per-channel routine fails, fill with NaNs to flag it
                warning('MTIMBSB failed for file %s channel %d: %s', files(f).name, i, ME.message);
                intensity_array(:, i) = NaN(nMT,1);
            end
        end
    end

    % optionally export coordinates if any found
    if ~isempty(savedmts)
        export_MT_coord(savedmts, filename, winner);
    
    %append the newly measured MT intensities to the old data
    All_I = [All_I; intensity_array];

    % FORMAT/EXPORT XLSX FILE
    whole_data(4:size(All_I,1)+3,append_col,:) = All_I; 
    %add intensities at the end of excel file

    for i=1:number_channels
        writematrix(whole_data(:,:,i), data_file_xlsx,'UseExcel', 1,'Sheet',i);
        %rewrite the new excel file, with new intensities
    end
    
        fprintf('Processed file %d/%d: %s (MTs found: %d)\n', f, N, files(f).name, nMT);

    end

    fprintf('Total Number of MTs analyzed in this condition: %d\n', size(All_I,1));

    end

end


% compiled analysis goes here
% figure(616)
% histogram(AllI,floor(length(AllI)/8))


