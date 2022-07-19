function [tempx, tempy, ridge_threshold] = threshold_loop(x,y,image,pthresh)

%%THRESHOLD LOOP
%this function take in an array of points determined by the ridge function
%and accepts an input from the use. the function loops over all points in
%the array and removes them if they are below the threshold
%it then asks the user if it did a good job and can stop looping

if nargin < 4
    pthresh = 0;
end

loop_thresh = 'n'; %initialize the loop
while loop_thresh == 'n' %while loop isn't broken
    
    if pthresh > 0
        fprintf("Attempting previous threshold value \n")
        ridge_threshold = pthresh;
        pthresh = 0; %set it so we can break this if statement
    else
        
        %% Option to try and predict threshold values JS Edit 2022/07/19
        debx = [];
        for k = 1:size(x)
            debx = [debx, image(x(k),y(k))];
        end
        
         % Option to plot histogram of intensities for the ridge points
%         figure(8)
%         hh = histogram(debx, 'NumBins', 35);
%         fit(hh.BinEdges(1:end-1)' + hh.BinWidth'/2, hh.Values', 'gauss1')
        
        frac_elim = mean(mean(image)) / mean(debx);
        
        background_estimate = mean(mean(image)) - mean(debx) * length(debx)/size(image,1)/size(image,2);
        bc = 1 + power(background_estimate / mean(debx), 3.5);
        %this correction shifts to deal with high background, low
        %intensity. The choice of the power is subjective
        
        A = sort(debx); A = A(round(frac_elim*length(A),0):end);
        
        try_thresh_mod = bc*double(A(1)); % for high noisy background, lots of ridgepoints means we want to take these out
        try_thresh_modd = mean(debx) - 1.21*std(double(debx)); % for low background, we may just need to remove some extra ridge points
        try_thresh = max(try_thresh_mod, try_thresh_modd);
        
        fprintf("Good Ridge Thresholds \n") %dialogue box asking for input
        fprintf("Try Threshold " + num2str(ceil(try_thresh/5)*5) + "\n")
        ridge_threshold = input('Input an Intensity Threshold: '); %get threshold from user
    end
    
    % option to exit will come if the input is not a number
    if length(ridge_threshold) > 1
        tempx = []; tempy = []; ridge_threshold = [];
        return
    end
    
    tempx = x; %load in x coordinates
    tempy = y; %load in y coordinates
    %%Threshold and show.
    % threshold out "ridges" that are too small
    % rudimentary threshold method
    for j = size(x):-1:1 %look at all the coordinates
        if image(x(j),y(j)) < ridge_threshold %check the intensity at the image and see if it beats the threshold
            tempx(j)=[]; tempy(j)=[]; %if intensity is too low, remove point from image
        end
    end
    
    figure(1);
    plot(tempx,tempy,'r.',"tag","threshold_ridge"); %plot the thresholded points as red
    
    %% To make it so that one can delete individual points by point and click
    % JS Edit 220309
    get(gca, 'Children');
    h = findobj('tag', 'threshold_ridge');
    
    % JS fix error 220418 where can't back out if no points found
    if isempty(h)
        fprintf("No ridge points found, lower your input value \n")
        loop_thresh = 'n';
    else
    
    coord = [0,0]; %filler to enter the while loop
    disp("Remove unwanted points by clicking. Press Enter once done.")
    while ~isempty(coord)
        coord = click_for_coord(h,1);
        % if selected remove from threshold
        if ~isempty(coord)
            dist = pdist2([tempx,tempy],coord);      %distance between your selection and all points
            [~, minIdx] = min(dist);            % index of minimum distance to points
            tempx(minIdx) = []; tempy(minIdx) = [];
            delete(findobj("tag","threshold_ridge")); %get rid of the old threshold points
            
            % replot and find again
            plot(tempx,tempy,'r.',"tag","threshold_ridge"); %plot the thresholded points as red
            get(gca, 'Children');
            h = findobj('tag', 'threshold_ridge');
            
            if isempty(h) % fix 220418 to avoid deleting all points
                coord = []; % exit out of the loop
            end
        end
    end
    
    %%
    loop_thresh = input('Use this threshold (y) or try again (n)? (y/n) \n','s'); %ask if the threshold was good
    %1 says try a new threshold, 0 says the threshold worked and break
    %the loop
    if loop_thresh == 'n' %if we didnt break the loop
        delete(findobj("tag","threshold_ridge")); %get rid of the old threshold points
    elseif loop_thresh == 'x'
        tempx = []; tempy = []; ridge_threshold = [];
        return
    end
    
    end % of if not empty
    
end
