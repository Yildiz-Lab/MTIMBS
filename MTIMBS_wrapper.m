function AllI = MTIMBS_wrapper(crop_area)

%% Description:

% crop area (optional): [x y width height] where x and y are measured as if the image
% is in the first quadrant from the lower left corner. Default: no crop
% whole image

% Run intensity_measurement function for all files in a folder
% this function also dives into the subfolders of that folder and makes new
% folders replicating the original folder structure

% set for cropping option directly from 307 scope
%rectangle = [200 200 260 230];

%% Prompt User to open the folder
top_folder=uigetdir(pwd,'Select folder of images or containing subfolders of images to crop');
%cd(top_folder);
%dc = dir('*.tif');

%% Will go through all files in immediate subfolder for tifs
dc = dir(fullfile(top_folder, '*.tif'));
contents = dir(top_folder);


%% If in b307 format, go through and make cropped images folder
if isempty(dc)
    fprintf("There are no .tif files in this directory. Trying subfolders... \n")

    croppedsave = strcat(top_folder, '/', 'CroppedImages');

    if ~isfolder(croppedsave)

        mkdir(croppedsave);

        for i = 3:length(contents)

            dc = dir(fullfile(strcat(top_folder, '/', contents(i).name), '*.tif'));
            if ~isempty(dc)
                fname = dc.name;
                fpath = dc.folder;
                fname_w_path = strcat(fpath, '/', fname);
    
                I = imread(fname_w_path);
                if nargin < 1
                    crop_area = [1 1 size(I,1) size(I,2)];
                end
                I = imcrop(I,crop_area);
                imwrite(I, strcat(croppedsave,'/',fname));
            end
        end
        if isempty(dc)
            error("There are no .tif files in this directory. Please verify this is the correct file location.")
        end


    else
        fprintf("Cropped Images Folder already exists! \n")
    end

    dc = dir(fullfile(croppedsave, '*.tif'));
    
    
end

%savedir = fullfile(top_folder, '/','IM_processed');
% FOR TXT FILE
%data_file = fullfile(top_folder, '/','MT_Intensities.txt');
%writematrix([],data_file);

save_location=uigetdir(pwd,'Select location to save MT Intensities xlsx');
data_file_xlsx = fullfile(save_location, '/' ,'MT_Intensities.xlsx');
if ~isfile(data_file_xlsx)
    whole_data = [];
    writematrix([],data_file_xlsx);
else
    append_file = input("This file already exists. Would you like to append? (y/n) \n", 's');
    if append_file == 'y'
        whole_data = readmatrix(data_file_xlsx);
    else
        return
    end
end

concentration = input("Enter the concentration in nM \n");
if ~isempty(whole_data)
    append_col = find(whole_data(1,:) == concentration);
else
    append_col = [];
end

if isempty(append_col)
    append_col = size(whole_data,2)+1;
    exposure_time = input("Enter an Exposure Time: \n");
    whole_data(1,append_col) = concentration;
    whole_data(2,append_col) = exposure_time;
    AllI = [];
else
    fprintf("This concentration already exists. Appending to existing with exposure time " + num2str(whole_data(2,append_col)) + " ms \n");
    AllI = whole_data(3:end,append_col);
    AllI = AllI(AllI > 0)';
end

fprintf("TO EXIT: If at any point you would like to quit, press 'ctrl + c' to exit \n")

skip_NGMM = input("Turn off automated number of gaussian estimation? (y/n) \n",'s');

% % FOR XLSX FILE
% data_file_xlsx = fullfile(top_folder, '/' ,'MT_Intensities.xlsx');
% 
% if isfile(data_file_xlsx)
%     overwrite_file = input("This file already exists. Would you like to overwrite? (y/n) \n", 's');
%     if overwrite_file == 'n'
%         return
%     else
%         delete(data_file_xlsx)
%     end
% end
% writematrix([],data_file_xlsx);

% suppress warnings from gmcluster > gmdistribution.fit > fitgmdist >
% gaussian_clustering related to convergence at high MTs
%  if you wish to not show these warnings, simply turn the warning to 'on' below

w = struct(); w.identifier = 'stats:gmdistribution:FailedToConverge'; w.state = 'on';
warning('off',w.identifier);

%mkdir(savedir)

ridge_threshold = 0; %cheat to initialize with no initial ridge
for f = 1:length(dc)
    fname = dc(f).name;
    fpath = dc(f).folder;
    fname_w_path = strcat(fpath, '/', fname);
    
    % now run the intensity_measurement
    [corrected_intensities, ridge_threshold] = MTIMBS(fname_w_path, ridge_threshold, skip_NGMM);
    AllI = [AllI, corrected_intensities];
    
    % sort option will save in increasing order
    AllI = sort(AllI);
    
    % FOR TXT FILE
    %writematrix(AllI, data_file);
    % FOR XLSX FILE
    % can modify AllI or AllI' to have rows or cols respectively
%     writematrix(AllI', data_file_xlsx);
    
    % FORMAT/EXPORT XLSX FILE
    whole_data(3:length(AllI)+2,append_col) = AllI';
    try
        writematrix(whole_data, data_file_xlsx);
    catch
        input('please close open MT_intensities file and then press enter');
        writematrix(whole_data, data_file_xlsx);
    end
    
    fprintf("Total Number of MTs analyzed in this condition: " + num2str(length(AllI)) + "\n") 
end

% compiled analysis goes here
% figure(616)
% histogram(AllI,floor(length(AllI)/8))

end


