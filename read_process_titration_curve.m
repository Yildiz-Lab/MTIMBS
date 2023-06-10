function read_process_titration_curve(current_folder)
% Run this function and select an xlsx file written by MTIMBS to be able to
% quickly fit a curve

if nargin < 1
    current_folder = [];
end

if ~isempty(current_folder)
    [filename,path] = uigetfile('*.xlsx','Select a file to compile as titration curve',current_folder);
else
    [filename,path] = uigetfile('*.xlsx');
end

statsfile = fullfile(path, '/', filename);
titration_data = readmatrix(statsfile);

% process appropriately
concentrations = titration_data(1,:);
exposure_time = titration_data(2,:);
Intensities = titration_data(3:end,:);

cellI = cell(1,size(Intensities,2));
compiled_data = zeros(2,length(concentrations));

for i = 1:size(Intensities,2)
    I = Intensities(:,i);
    I = I(I > 0); %get rid of zeros
    I = I(~isnan(I));
    % can add in removing outliers here automatically...
    I = I*exposure_time(i)/100; %normalized exposure time
    cellI{i} = I;
    compiled_data(1,i) = median(I);
    compiled_data(2,i) = std(I)/sqrt(length(I));
end

concentrations
compiled_data

end
