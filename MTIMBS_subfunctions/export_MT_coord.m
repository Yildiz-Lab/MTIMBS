function export_MT_coord(savedmts, pathname)
% JS Function 2024/05/30 output savedmts for later storage
%   Save a file of the same name as the file in the winner folder

M = zeros(0,3);

% this isn't pretty but it works fine
for i = 1:length(savedmts)
    xy = savedmts{i};
    for j = 1:size(xy,1)
    M = [M; i,xy(j,1),xy(j,2)];
    end
end

[path, file, ext] = fileparts(pathname);
writematrix(M,strcat(fullfile(path,file),'.txt'));

end

