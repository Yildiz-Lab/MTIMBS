function corrected_intensities = MTIMBSB(filename, savedmts)

%% Authors: Jon Fernandes and Joseph Slivka and Parnika Kant!
%  UpDate: May 8, 2024

% Description: Take a tif image and find the intensity of labeled MTs
    % subtracted by background. This is a streamlined version of MTIMBS
    % since the user has already selected MT positions to analyze. This
    % function requires the off_color_measurement function rather than
    % intensity measurment in order to do the translational scanning to
    % account for channel offset

% Parameters:
    % filename: name of file (including .tif) wishing to be analyzed
    % savedmts: cell variable containing the locations to measure

% Returns:
    % corrected_intensities: array of size num_MT with background
    % subtraction
    % _params.txt: (.txt file) array of user set parameters
    % filename.fig: (.fig file) plot results of MT


image = imread(filename); %read in image intensities
image = transpose(image); %for some reason it's read in backwards

for i = length(savedmts):-1:1 %for each MT, do background subtraction
   
    % [corrected_intensities(i), mean_intensities(i), background_intensities(i) ] = off_color_measurement(savedmts{i},image);
    [A,~,~] = off_color_measurement(savedmts{i},image);
    corrected_intensities(i)= A;
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
    
end


