% function plot_channel_intensity_vs_kappa()
% % Minimal: read CSV and scatter columns 5..end vs column 4 (kappa)
% % Usage: plot_channels_vs_kappa('data.csv')
% csvfile = '/Users/slivka/Documents/MATLAB/MTIMBS curvature sensing test/100nM map7 tau pelA low power r1_1/100nM map7 tau pelA low power r1_1_MMStack_3-Pos_000_001.ome.txt'
% csvfile = '/Users/slivka/Documents/MATLAB/MTIMBS curvature sensing test/100nM map7 tau pelA low power r1_1/100nM map7 tau pelA low power r1_1_MMStack_3-Pos_001_000.ome.txt'
% M = readmatrix(csvfile);           % simple reader
% k = M(:,4);
% C = M(:,5:end); 
% % C = C./max(M(:,5:end),[],'omitnan'); %relative intensity
% C = C./mean(C,1,'omitnan');
% n = size(C,2);
% figure; hold on;
% cols = lines(max(1,n));
% for i = 1:n
%     scatter(k, C(:,i), 20, cols(i,:), 'filled');
% end
% xlabel('kappa (col 4)'); ylabel('intensity (channels)');
% legend(arrayfun(@(i) sprintf('channel %d', i), 1:n, 'UniformOutput', false));
% title('Channels vs kappa');
% axis tight; box on;
% end

function plot_channel_intensity_vs_kappa(csvfile, colorByMT)
% plot_channels_vs_kappa  Scatter columns 5..end vs col4 (kappa).
% Optionally color points by column 1 values.
% Usage:
%   plot_channels_vs_kappa('data.csv')               % default: color by channel
%   plot_channels_vs_kappa('data.csv', true)         % color by column 1
if nargin<2
    colorByMT = false;
end

% csvfile = '/Users/slivka/Documents/MATLAB/MTIMBS curvature sensing test/100nM map7 tau pelA low power r1_1/100nM map7 tau pelA low power r1_1_MMStack_3-Pos_000_001.ome.txt'

M = readmatrix(csvfile);
k = M(:,4);
C = M(:,5:end);

uid = unique(M(:,1));
for i = 1:length(uid)
    idx = find(M(:,1) == uid(i));
    C(idx,:) = C(idx,:)./mean(C(idx,:),1,'omitnan');
end

% C = C./max(M(:,5:end),[],'omitnan'); %relative intensity
% C = C./mean(C,1,'omitnan');
n = size(C,2);

figure; hold on;
if colorByMT
    colvar = M(:,1);                   % color variable from column 1
    for i=1:n
        scatter(k, C(:,i), 20, colvar, 'filled');
    end
    colormap(jet); colorbar;
else
    cols = lines(max(1,n));
    for i=1:n
        scatter(k, C(:,i), 20, cols(i,:), 'filled');
    end
end

xlabel('kappa (col 4)'); ylabel('intensity (channels)');
legend(arrayfun(@(i) sprintf('channel %d', i), 1:n, 'UniformOutput', false));
title('Channels vs kappa');
axis tight; box on; hold off;
end
