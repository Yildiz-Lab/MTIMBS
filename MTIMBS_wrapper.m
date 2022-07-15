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
top_folder=uigetdir;
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

% FOR XLSX FILE
data_file_xlsx = fullfile(top_folder, '/' ,'MT_Intensities.xlsx');

if isfile(data_file_xlsx)
    overwrite_file = input("This file already exists. Would you like to overwrite? (y/n) \n", 's');
    if overwrite_file == 'n'
        return
    else
        delete(data_file_xlsx)
    end
end
writematrix([],data_file_xlsx);

% suppress warnings from gmcluster > gmdistribution.fit > fitgmdist >
% gaussian_clustering related to convergence at high MTs
%  if you wish to not show these warnings, simply turn the warning to 'on' below

w = struct(); w.identifier = 'stats:gmdistribution:FailedToConverge'; w.state = 'on';
warning('off',w.identifier);

%mkdir(savedir)

AllI = [];
ridge_threshold = 0; %cheat to initialize with no initial ridge
for f = 1:length(dc)
    fname = dc(f).name;
    fpath = dc(f).folder;
    fname_w_path = strcat(fpath, '/', fname);
    
    % now run the intensity_measurement
    [corrected_intensities, ridge_threshold] = MTIMBS(fname_w_path, ridge_threshold);
    AllI = [AllI, corrected_intensities];
    
    % sort option will save in increasing order
    AllI = sort(AllI);
    
    % FOR TXT FILE
    %writematrix(AllI, data_file);
    % FOR XLSX FILE
    % can modify AllI or AllI' to have rows or cols respectively
    writematrix(AllI', data_file_xlsx);

end

% compiled analysis goes here
% figure(616)
% histogram(AllI,floor(length(AllI)/8))

end


