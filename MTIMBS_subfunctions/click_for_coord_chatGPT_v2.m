function points = click_for_coord_chatGPT_v2(handle, xycenters)
    % Click a number of points and press Enter to exit
    % 2024/09/11 (made by chatGPT)
    
    % Initialize variables
    points = xycenters; % Start with pre-existing points if provided
    
    % If there are any pre-existing points, plot them
    if ~isempty(points)
        scatter(xycenters(:, 1), xycenters(:, 2), 'w', 'filled', 'tag', 'selected_centers');
    end
    
    % Set up the mouse click callback
    set(gcf, 'WindowButtonDownFcn', @mouseClickCallback);
    
    % Set up a key press callback to stop on Enter key press
    set(gcf, 'KeyPressFcn', @keyPressCallback);
    
    % Wait for the Enter key to be pressed
    disp('Left-click on points. Press Enter when finished.');
    
    % Pause the script until we resume it by pressing Enter
    uiwait(gcf);  % Wait for user input (specifically pressing Enter)
    
    % Mouse click callback function to collect points
    function mouseClickCallback(~, ~)
        % Get the mouse click location
        pt = get(gca, 'CurrentPoint');
        x = round(pt(1, 1)); % X coordinate of the click
        y = round(pt(1, 2)); % Y coordinate of the click
        
        % Plot the clicked point
        scatter(x, y, 'w', 'filled', 'tag', 'selected_centers');
        
        % Store the clicked coordinates
        points = [points; x, y];
    end
    
    % Key press callback function to detect Enter key
    function keyPressCallback(~, event)
        if strcmp(event.Key, 'return')
            % If Enter is pressed, reset callbacks and exit point collection
            set(gcf, 'WindowButtonDownFcn', '');
            set(gcf, 'KeyPressFcn', '');
            delete(findobj('tag', 'selected_centers')); % Clear the markers
            
            % Resume the script and exit the function
            disp('Point collection finished.');
            uiresume(gcf);  % Resume after waiting
            commandwindow;  % Bring the focus to the command line
        end
    end
end
