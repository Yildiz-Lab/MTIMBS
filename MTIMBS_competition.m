function [corrected_intensities, ridge_threshold, savedmts] = MTIMBS_competition(filename, previous_ridge_threshold, skip_NGMM)

%% Authors: Jon Fernandes and Joseph Slivka
%  Date: Feb 10, 2022

% Description: Take tif image and find average intensity of labeled MTs
    % subtracted by background

% Parameters:
    % filename: name of file (including .tif) wishing to be analyzed
    % ridge_threshold: (float) parameter to throw out all values
    % of ridge lower than ridge_threshold to categorize points
    % num_MT: (int) number of MTs seen on the image

% Returns:
    % multiple saved files in subdirectory /name
    % corrected_intensities: (.txt file) array of size num_MT with background
    % subtraction
    % _params.txt: (.txt file) array of user set parameters
    % filename.fig: (.fig file) plot results of MT

savedmts = {};
ridge_threshold = previous_ridge_threshold;
%this is just in case the user wants to cancel immediately
% then it won't error
%% Load and Get Ridges
[x,y] = Ridge(filename); %do ridge function to pick out all the peak points
title(filename, 'Interpreter', 'none')

image = imread(filename); %read in image intensities
image = transpose(image); %for some reason it's read in backwards+
[m, n] = size(image); %going to need to know the bounds of the image

%IS THE IMAGE WORTH DOING?
escape = input("Analyze this image? (y/n) \n",'s');
if escape == 'n' || escape == 'x'
    corrected_intensities = [];
    return
end
disp("If you want to skip image analysis at any time, press x")
%do the thresholding: eliminate what should be background, needs user input
[x, y, ridge_threshold] = threshold_loop(x,y,image,previous_ridge_threshold);
%removes the low intensity points and returns the good threshold used
if isempty(x)
    corrected_intensities = [];
    return
end


%% Gaussian Mixture Model to seperate MTs

xycenters = []; % to store centers for later use

% a loop here to give user the option to try a couple more times. Since the
% gmm has a random aspect to it, about 40% of misfits can be corrected just
% by running a second or third time.

% user given the option to skip
if skip_NGMM == 'n'
    gmopt = input("Attempt Gaussian Fitting? (y/n) \n",'s');
    attempts = 0;
    attempt_gm = 'y';
    manual_option = 'n';
else
    attempts = 2;
    gmopt = 'n';
    attempt_gm = 'y';
end

% gmopt = input("Attempt Gaussian Fitting? (y/n) \n",'s');
% attempts = 0;
% attempt_gm = 'y';
% manual_option = 'n';
if gmopt == 'n'
    manual_option = 'y';
    disp("Manually set the centers of the MTs")
end

while attempt_gm == 'y'

attempts = attempts + 1; % a running tracker just to ask for the manual option after a second fail

% Ask about a manual setting of the centers to break the uniform prior
% initialization
if attempts > 2
    if skip_NGMM == 'n'
        manual_option = input("Try manually setting the centers of the MTs? (y/n) \n", 's');
    else
        manual_option = 'y';
    end
end

% select which gaussian_clustering method will run
if manual_option == 'y'
    [idx, uidx, num_MT, xycenters] = gaussian_clustering(x,y,manual_option,xycenters);
elseif manual_option == 'x'
    corrected_intensities = [];
    return
elseif attempts > 1
    [idx, uidx, num_MT, xycenters] = gaussian_clustering(x,y,attempts);
else
    [idx, uidx, num_MT, xycenters] = gaussian_clustering(x,y);
end
%makes arrays idx and iudx to index what points belong to what MTs
%also returns the number of MTs iputted by user

if isempty(idx)
    corrected_intensities = [];
    return
end

attempt_gm = 'n';

% storage arrays
mean_intensities = zeros(1,max(idx));
background_intensities = zeros(1,max(idx));
corrected_intensities = zeros(1,max(idx));
cmap = parula(max(idx)); %pretty color map for plotting

for i = length(uidx):-1:1 %for each MT, do background subtraction
    legend() 
    
    %% Use those thresholded ridge points to make a linear interpolation
    xt = x(idx==uidx(i)); %make array of MT points to pass to line-drawer
    yt = y(idx==uidx(i)); %make array of MT points to pass to line-drawer
    
    bestline = MT_line_draw(xt, yt, m, n);
    savedmts= [savedmts; bestline];
    %draws a line over the MT and saves in a cell array
    %reports the points under the line as bestline
   
    plot(bestline(:,1), bestline(:,2), 's', 'MarkerFaceColor', cmap(i,:), "DisplayName", "MT "+num2str(i), 'tag', 'bestline')
    %show us the points that are picked out by the line
   
    [corrected_intensities(i), mean_intensities(i), background_intensities(i) ] = intensity_measurement(bestline,image);
    %Measure the intensity for a fitted MT, records them in the storage
    %arrays

end

% remove NaN's which sometimes happens if aggregates or points are
% recognized by ridge but not the gaussian clustering algorithm (which we
% want)
corrected_intensities = corrected_intensities(~isnan(corrected_intensities));

[dir, name, ~] = fileparts(filename);
if ~isempty(dir)
    dir = strcat(dir, '/');
end

user_stop = input("Do these MTs look correct? (y/n) \n", 's');

% try
% 
% if user_stop == 'y'
%     return

if user_stop == 'x'
    corrected_intensities = [];
    savedmts={};
    return
    
elseif user_stop == 'n'
    
    delete(findobj("tag","bestline"))
    corrected_intensities = [];
    savedmts={};
    if manual_option ~= 'y'
        attempt_gm = input("Attempt GM fit again? (y/n) \n", 's');
    else
        attempt_gm = 'y';
    % option to erase centers or not
        if ~isempty(xycenters)
            centersoption = input("Choose whether you would like to: \n 'q' manually reset all centers \n 'w' add to existing centers \n 'e' erase some centers then add \n 'n' abandon this image \n",'s');
            if centersoption == 'x' || centersoption == 'n'
                corrected_intensities = [];
                savedmts={};
                return
                
            elseif centersoption == 'e' %copied directly from threshold deletion
                % Plot the clicked point
                tempx = xycenters(:,1); tempy = xycenters(:,2); % CHECK THIS!!!
                scatter(tempx, tempy, 'w', 'filled', 'tag', 'selected_centers');
                coord = [0,0]; %filler to enter the while loop
                disp("Remove unwanted points by clicking or drag to remove points in region. Press Enter once done.")
                while ~isempty(coord)
                    %coord = click_for_coord(h,1);
                    [initialPress, release] = draw_box_chatGPT();
                    if isempty(initialPress)
                        coord = [];
                    else
                        coord(1,1:2) = initialPress;
                        coord(2,1:2) = release;
                        if pdist2(initialPress,release) < 4
                            coord = initialPress;
                        end
                    end

                    % if selected remove from threshold
                    if ~isempty(coord)
                        if size(coord,1) > 1
                            xv = [coord(1,1), coord(2,1), coord(2,1), coord(1,1), coord(1,1)];
                            yv = [coord(1,2), coord(1,2), coord(2,2), coord(2,2), coord(1,1)];
                            in = inpolygon(tempx,tempy,xv,yv);
                            tempx(in) = []; tempy(in) = [];
                        else % for single point and click which right now isn't an option
                            dist = pdist2([tempx,tempy],coord);      %distance between your selection and all points
                            [~, minIdx] = min(dist);            % index of minimum distance to points
                            tempx(minIdx) = []; tempy(minIdx) = [];
                        end
                        delete(findobj('tag','selected_centers')); %get rid of the old centers

                        % replot and find again
                        scatter(tempx,tempy,'w', 'filled', 'tag','selected_centers'); %plot the centers
                        get(gca, 'Children');
                        h = findobj('tag','selected_centers');

                        if isempty(h) % fix 220418 to avoid deleting all points
                            coord = []; % exit out of the loop
                        end
                    end
                end
                xycenters = [tempx, tempy];
                delete(findobj('tag','selected_centers'));
                
            elseif centersoption == 'w'
                xycenters = xycenters;
                
            else
                xycenters = [];
            end
        end
    end
end
    
    % an unnecessary if statement, but necessary if we want to only save
    % the broken cases. When we want to save both, we'll put this at the
    % end of the statement
    
%     if attempt_gm == 'n'
%         % check if directory exists and make one if not to save analysis
%         % FOR DEBUGGING PURPOSES
%         if ~exist(strcat(dir, name), 'dir')
%            mkdir(strcat(dir, name)) 
%         end
%         strcat(dir,name,'/',name,'.fig')
%         savefig(figure(1), strcat(dir,name,'/',name,'.fig'))
%         writematrix([ridge_threshold, num_MT], strcat(dir, name, '/_params.txt'))
%         imwrite(transpose(image), strcat(dir, name, '/',name, '.tif'))
%         return
%     end
% catch
%     fprintf("Sorry, I didn't understand your response, let's try again")
%     delete(findobj("tag","bestline"))
%     corrected_intensities = [];
%     savedmts={};
%     attempt_gm = 'y';
% end

end % of while loop

%% in the end, save figure for reference later and clear

% if ~exist(strcat(dir, name), 'dir')
%    mkdir(strcat(dir, name)) 
% end
% strcat(dir,name,'/',name,'.fig')
%savefig(figure(1), strcat(dir,name,'_fixed.fig'))
%writematrix([ridge_threshold, num_MT], strcat(dir, name, '_params_fixed.txt'))
% imwrite(transpose(image), strcat(dir, name, '/',name, '.tif'))
% return
    
end


