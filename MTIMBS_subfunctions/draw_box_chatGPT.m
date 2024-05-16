function [initialPress, release] = draw_box_chatGPT(fhandle)
    % ChatGPT stitched code to draw a box on a figure and get coordinates
    % This is then adapted to erase points within the box

    % Initialize variables
    initialPress = []; % to store the initial press coordinates
    release = []; % to store the release coordinates
%     lastMousePressTime = -inf; % to store the time of the last mouse press

    % Set up the mouse button callbacks
    set(gcf, 'WindowButtonDownFcn', @mousePressCallback);
    set(gcf, 'WindowButtonUpFcn', @mouseReleaseCallback);
        % Set up the KeyPressFcn and KeyReleaseFcn callbacks
    set(gcf, 'KeyPressFcn', @keyPressCallback);
    set(gcf, 'KeyReleaseFcn', @keyReleaseCallback);
    
    % Initialize the dashed line handle
    dashedLineHandle = plot([NaN, NaN], [NaN, NaN], '--', 'Color', 'white', 'LineWidth', 4);

    % Next thing
    isSpacePressed = false;
    
    % Wait for the initialPress to begin
%     disp('Hold down the mouse button and draw a box. Release the button when finished.');
    while isempty(initialPress)
        % Check if Enter key is pressed
        if isSpacePressed
            % Return empty arrays for initialPress and release
            initialPress = [];
            release = [];
            return;
        end       
        pause(0.01)

        
    end
    
    % Wait for the mouse button to be released
    while isempty(release) % Loop until the button is released
        
        % Check if Enter key is pressed
        if isSpacePressed
            % Return empty arrays for initialPress and release
            initialPress = [];
            release = [];
            return;
        end
        
        % Get the current mouse position
        pt = get(gca, 'CurrentPoint');
        x = pt(1, 1);
        y = pt(1, 2);

        % Update the dashed line coordinates
        set(dashedLineHandle, 'XData', [initialPress(1), x, x, initialPress(1), initialPress(1)]);
        set(dashedLineHandle, 'YData', [initialPress(2), initialPress(2), y, y, initialPress(2)]);
%         dashedLineHandle = plot([initialPress(1), x, x, initialPress(1), initialPress(1)], [initialPress(2), initialPress(2), y, y, initialPress(2)], '--', 'Color', 'white', 'LineWidth', 4);
        
        % Refresh the figure
        drawnow;
        
        pause(0.01);
    end

    % Display the initial press and release coordinates
%     disp('Initial Press Coordinates:');
%     disp(initialPress);
%     disp('Release Coordinates:');
%     disp(release);

    % Reset the mouse button callbacks
    set(gcf, 'WindowButtonDownFcn', '');
    set(gcf, 'WindowButtonUpFcn', '');
    set(gcf, 'KeyPressFcn', '');
    set(gcf, 'KeyReleaseFcn', '');
    
    % Remove the dashed line from the figure
    delete(dashedLineHandle);

    % Mouse press callback function
    function mousePressCallback(src, ~)
        % Get the initial press coordinates
        pt = get(gca, 'CurrentPoint');
        x = pt(1, 1);
        y = pt(1, 2);

        % Store the initial press coordinates
        initialPress = [x, y];
    end

    % Mouse release callback function
    function mouseReleaseCallback(src, ~)
        % Get the release coordinates
        pt = get(gca, 'CurrentPoint');
        x = pt(1, 1);
        y = pt(1, 2);

        % Store the release coordinates
        release = [x, y];
    end

    % Key press callback function
    function keyPressCallback(src, event)
        if strcmp(event.Key, 'return')
            isSpacePressed = true;
        end
    end

    % Key release callback function
    function keyReleaseCallback(src, event)
        if strcmp(event.Key, 'return')
            isSpacePressed = false;
        end
    end
end


