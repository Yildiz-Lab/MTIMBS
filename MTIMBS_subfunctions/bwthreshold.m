function bwthreshold(tiffile)

I       = imread('cameraman.tif');
I = imread(tiffile);
% [m n] 	= size(I);

% % CS people will hate me, but hey...
% RwRdg = zeros(m*n);
% ClRdg = zeros(m*n);
% for j = 0:m-1
%     RwRdg(j*n+1:(j+1)*n) = (j+1)*ones(n,1);
%     ClRdg(j*n+1:(j+1)*n) = 1:n;
% end

figure(1); clf;
imagesc(I); hold on;
% plot(ClRdg,RwRdg,'k.');
%plot(ClRiv,RwRiv,'b.');
%plot(ClEdg,RwEdg,'c.');