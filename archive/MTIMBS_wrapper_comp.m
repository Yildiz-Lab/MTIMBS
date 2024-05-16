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
% if isempty(dc)
%     fprintf("There are no .tif files in this directory. Trying subfolders... \n")

    color1save = fullfile(top_folder, 'color 1');
    color2save = fullfile(top_folder, 'color 2');
      
    winner = input("Which color is the winner, i.e. which color do you want to base the MT locations off of? (1 or 2) \n", 's')-48;
    colors = {color1save, color2save};
    
    if ~isfolder(color1save)

        mkdir(color1save);
        mkdir(color2save);
        
        for i = 4:length(contents)

%             dc = dir(fullfile(strcat(top_folder, '/', contents(i).name), '*.tif'))
%             fname = dc.name;
%             fpath = dc.folder;
            fname_w_path = fullfile(top_folder, contents(i).name);
    
            I = tiffreadVolume(fname_w_path);
            array_size = size(I,3);
            if array_size == 2
                    %crop_area = [1 1 size(I,1) size(I,2)];
                    I1 = I(:,:,1);
                    I2 = I(:,:,2);
                    
                    %c1fname = fullfile(color1save, contents(i).name)
                   % c2fname = fullfile(color2save, contents(i).name);
                    
                    imwrite(I1, fullfile(color1save, contents(i).name));
                    imwrite(I2, fullfile(color2save, contents(i).name));
                    
                  
             else
                    %I = imcrop(I,crop_area);
                  imwrite(I, fullfile(color1save, fname)) 
             end

          end
       end
       if isempty(dc)
            error("There are no .tif files in this directory. Please verify this is the correct file location.")
       end


%     else
%         fprintf("Cropped Images Folder already exists! \n")
%     end
    winnerfolder = colors{winner}
    dc1 = dir(fullfile(winnerfolder, '*.tif'));
    dc2 = dir(fullfile(colors{2/winner}, '*.tif'));
    
    

%savedir = fullfile(top_folder, '/','IM_processed');
% FOR TXT FILE
%data_file = fullfile(top_folder, '/','MT_Intensities.txt');
%writematrix([],data_file);

save_location=uigetdir;
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
    %append_col_2 = 
else
    append_col = [];
end

if isempty(append_col)
    append_col = size(whole_data,2)+1;
    exposure_time = input("Enter an Exposure Time for winning Channel: \n");
    exposure_time_2 = input("Enter an Exposure Time for other channel: \n");
    whole_data(1,append_col) = concentration;
    whole_data(2,append_col) = exposure_time;
    whole_data(1,append_col+1) = concentration;
    whole_data(2,append_col+1) = exposure_time_2;
    whole_data(3,append_col) = winner;
    whole_data(3,append_col+1) = mod(winner,2)+1;
    AllI = [];
    AllI2 = [];
else
    append_col = append_col(1);
    fprintf("This concentration already exists. Appending to existing with exposure time " + num2str(whole_data(2,append_col)) + " ms \n");
    AllI = whole_data(4:end,append_col);
    AllI = AllI(AllI > 0)';
    AllI2 = whole_data(4:end,append_col+1);
    AllI2 = AllI2(AllI2 > 0)';
end

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
    fname1 = dc1(f).name;
    fpath1 = dc1(f).folder;
    fname_w_path_1 = strcat(fpath1, '/', fname1);
    fname2 = dc2(f).name;
    fpath2 = dc2(f).folder;
    fname_w_path_2 = strcat(fpath2, '/', fname2);
    % now run the intensity_measurement
    [corrected_intensities, ridge_threshold, savedmts] = MTIMBS_competition(fname_w_path_1, ridge_threshold);
%     savedmts
    corrected_intensities_loser = []; %just in case the previous was skipped then at least we initialize the empty to append
    if ~isempty(corrected_intensities)
        [corrected_intensities_loser] = MTIMBSS(fname_w_path_2, savedmts);
    end
    AllI = [AllI, corrected_intensities];
    AllI2 = [AllI2, corrected_intensities_loser];
    % sort option will save in increasing order
    %AllI = sort(AllI);
    
    % FOR TXT FILE
    %writematrix(AllI, data_file);
    % FOR XLSX FILE
    % can modify AllI or AllI' to have rows or cols respectively
%     writematrix(AllI', data_file_xlsx);
    
    % FORMAT/EXPORT XLSX FILE
    whole_data(4:length(AllI)+3,append_col) = AllI';
    whole_data(4:length(AllI2)+3,append_col+1) = AllI2';
    writematrix(whole_data, data_file_xlsx);
    
    fprintf("Total Number of MTs analyzed in this condition: " + num2str(length(AllI)) + "\n") 
end

% compiled analysis goes here
% figure(616)
% histogram(AllI,floor(length(AllI)/8))

end


