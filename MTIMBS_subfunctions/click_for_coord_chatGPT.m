function points = click_for_coord_chatGPT(handle)
% Click a number of points and press enter to exit
% 2023/05/21 (made by chatGPT) edited slightly by Joseph

% Initialize variables
points = []; % to store the clicked points

% Set up the mouse click callback
set(gcf, 'WindowButtonDownFcn', @mouseClickCallback);

% Wait for the Enter key to be pressed
disp('Left-click on points. Press Enter when finished.');
dummy=input('');

% Display the coordinates of the clicked points
% disp('Clicked coordinates:');
% disp(points);

% Reset the mouse click callback
set(gcf, 'WindowButtonDownFcn', '');

% Mouse click callback function
function mouseClickCallback(src, ~)
    % Get the mouse click location
    pt = get(gca, 'CurrentPoint');
    x = round(pt(1, 1));
    y = round(pt(1, 2));
    
    % Plot the clicked point
    scatter(x, y, 'w', 'filled', 'tag', 'selected_centers');
    
    % Store the coordinates
    points = [points; x, y];

end

delete(findobj('tag','selected_centers'));

end
