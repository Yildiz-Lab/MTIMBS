function [corrected_intensity, mean_intensity, min_background ] = intensity_measurement(bestline,image)
  
%% This function takes in an array of points and an image
% it records the average grayscale value of the image at those points,
% then subtracts out the background of the image

[m, n] = size(image);

%% Calculate Means for the MT
rc = double(0); %this needs to be a double or else memory leak problems
%running total of intensity of a MT

lline = length(bestline(:,1));
for ll = 1:length(bestline(:,1))
   rc = rc + double(image(bestline(ll,1), bestline(ll,2)));
end

mean_intensity = rc / lline; %averages intensity by length of line
    
%% Do Background Subtraction
sp = 10; % how many pixels in any direction to move

% this table directs how to move the line for background measurement
% Change mod if you want more or less background measurement comparisons
mod = [sp 0; -sp 0; 0 sp; 0 -sp; sp sp; sp -sp; -sp sp; -sp -sp];

min_background = double(mean_intensity);
    
for k = 1:size(mod,1)
    
    % clear parameters
    a = double(0);
    background_intensity = [];
    toinclude = [];
    
    % make the shifted line
    xmod = bestline(:,1)+mod(k,1); 
    ymod = bestline(:,2)+mod(k,2);
    
    % get intensities only if within the box
    for j = size(xmod):-1:1
        if (xmod(j) > 0) && (xmod(j) < m) && (ymod(j) > 0) && (ymod(j) < n)
            a = a + double(image(xmod(j), ymod(j)));
            %running sum for background intensity
            background_intensity = [background_intensity, image(xmod(j),ymod(j))];
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