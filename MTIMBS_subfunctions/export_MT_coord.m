function export_MT_coord(savedmts, pathname, winner)
% JS Function 2024/05/30 output savedmts for later storage
%   Save a file of the same name as the file in the winner folder

M = zeros(0,size(savedmts{1},2));
N = size(savedmts{1},2);

% this isn't pretty but it works fine
for i = 1:length(savedmts)
    xy = savedmts{i};
    if size(xy,2) > 2
        for j = 1:size(xy,1)
            append_row = [i,xy(j,1),xy(j,2),round(xy(j,3),6)];
            % make sure to append in channel order
            % shift columns so we know which column is winner. Then we
            % shift the values back so they are ordered 1,2,3,...
            v = 4:N; v = v-3;
            vc = v([winner, 1:winner-1, winner+1:numel(v)]);
            append_row_part_2(vc) = round(xy(j,v+3),0);
            append_row = [append_row, append_row_part_2];
            M = [M; append_row];
        end
    else
        for j = 1:size(xy,1)
        M = [M; i,xy(j,1),xy(j,2)];
        end
    end
end

[path, file, ext] = fileparts(pathname);
writematrix(M,strcat(fullfile(path,file),'.txt'));

end

