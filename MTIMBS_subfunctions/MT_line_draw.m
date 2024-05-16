function [bestline] = MT_line_draw(xt, yt, m, n)

%%Making the Splines over MTs

% Need to sort the points into the shortest line.
% Want to do neirest neighbor search to draw lines

ind_to_check = [1, length(xt), find(yt==min(yt),1), find(yt==max(yt),1)];
%try starting the line connection from top, bottom, left, right
%those numbers are the x-indeces related to those points

    min_distance = 50000.0*(m + n);

    if length(ind_to_check) < 2
        bestline = [xt, yt];
    else

        for ii = ind_to_check %run through top, bottom, left, right

            if length(xt) > 1
                [Xtord, Ytord] = points2contour(xt, yt, ii, 'cw'); %do the line tracing
            else % if too short, just return the single point. Don't attempt to do points2contour
                Xtord = xt;   Ytord = yt; 
            end

            distance = sum(sqrt((Xtord(2:end) - Xtord(1:end-1)).^2 + (Ytord(2:end) - Ytord(1:end-1)).^2));
            %check out how long the line drawn was

            if distance < min_distance %only use the shortest/best line
                min_distance = distance;
                % need to make parametric so interp doesn't freak
                t = 1:length(Xtord);
                lint = linspace(1,size(xt,1),round(4*min_distance,0));

                xchk = interp1(t, Xtord, lint);     ychk = interp1(t, Ytord, lint);
                bestline = unique(horzcat(transpose(round(xchk,0)), transpose(round(ychk,0))),'rows','stable');

            end
        end
        
    end

    end
    
    
    
    