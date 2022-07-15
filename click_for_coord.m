

function coordinateSelected = click_for_coord(hObj, num_clicks)
%  FIND NEAREST (X,Y,Z) COORDINATE TO MOUSE CLICK
% Inputs:
%  hObj : the handles of the data that is trying to be fit
%  num_clicks : total number of clicks before the end of the function.
%  Default if only want one point is set this to one.
% OUTPUT
%  coordinateSelected: the (x,y) coordinate closest to that of your click
%  that belongs to hObj.Data

% Adapted from:
% https://www.mathworks.com/matlabcentral/answers/125687-update-vector-values-and-return-to-the-program#answer_133304


button = 1; % left mouse click
pts = [];

for i = 1:num_clicks   % read ginputs up to the num_clicks specified
    [x,y,button] = ginput(1);
    pts = [pts; x y];
end

% get coordinates of the object that we want to minimize distance to
x = hObj.XData;  y = hObj.YData; 
coordinates = [x(:),y(:)];     % matrix of your input coordinates

coordinateSelected = zeros(num_clicks,2);

for i = 1:num_clicks
    if isempty(pts)
        coordinateSelected = [];
        return
    end
    dist = pdist2(pts(i,:),coordinates);      %distance between your selection and all points
    [~, minIdx] = min(dist);            % index of minimum distance to points
    coordinateSelected(i,:) = coordinates(minIdx,:); %the selected coordinate
end

end

