function [corrected_intensity, mean_intensity, min_background ] = off_color_measurement(bestline,image)
  
%% This function takes in an array of points and an image
% it records the average grayscale value of the image at those points,
% then subtracts out the background of the image. It translates the points
% to a few locations as an ad hoc correction to chromatic aberration and
% stage drift (channel offsets).

[m, n] = size(image);

%% Calculate Means for the MT
%Stepsize parameters for translating the MT to different locations
num_steps = 3; %how many 1 pixel steps in one dimension we want to test

lline = length(bestline(:,1)); %figure out how many pixels the line 
% needs to sum
mean_intensity = 0; %initialize parameter to store max mean intensity

for i = -1*num_steps:num_steps %go over the x steps
    
    new_line_x = bestline(:,1) + i;%create new x positions

    for j = -1*num_steps:num_steps %go over the y steps
       new_line_y = bestline(:,2) + j;% create new y positions
       include=[];
       rc = double(0); %initialize a variable to store the sum of pixel intensities
       

       % plot(new_line_x, new_line_y, 'LineWidth',2); %use this to plot the
       % lines
   
       for ll = 1:lline
           if (new_line_x(ll) > 0) && (new_line_x(ll) < m) && (new_line_y(ll) > 0) && (new_line_y(ll) < n)
               %only sum the points if the point is in the image
               rc = rc + double(image(new_line_x(ll), new_line_y(ll)));
               % actually sum the intensity values at each pixel on new line
               include = [include, ll]; %keep track of how long the line is  
           end

       end
        avg_intensity = rc/length(include);
        %averages intensity by 
        %length of line, not counting line outside the image
       if  avg_intensity > mean_intensity
           mean_intensity = avg_intensity; %update mean intensity 
           % if its greater than before
       end
    end
end


    
%% Do Background Subtraction
sp = 10; % how many pixels in any direction to move

% this table directs how to move the line for background measurement
% Change mod if you want more or less background measurement comparisons
mod = [sp 0; -sp 0; 0 sp; 0 -sp; sp sp; sp -sp; -sp sp; -sp -sp];

min_background = mean_intensity;
    
for k = 1:size(mod,1)
    
    % clear parameters
    a = double(0);
    toinclude = [];
    
    % make the shifted line
    xmod = bestline(:,1)+mod(k,1); 
    ymod = bestline(:,2)+mod(k,2);
    
    % get intensities only if within the box
    for j = size(xmod):-1:1
        if (xmod(j) > 0) && (xmod(j) < m) && (ymod(j) > 0) && (ymod(j) < n)
            a = a + double(image(xmod(j), ymod(j)));
            %running sum for background intensity
            toinclude = [toinclude, j];
        end
    end
    
    % calculate mean intensity for background and replace min if less than
    % current min
    if a / length(toinclude) < min_background
        min_background = a / length(toinclude); %average the background
    end
      
end
corrected_intensity = mean_intensity - min_background; 
end