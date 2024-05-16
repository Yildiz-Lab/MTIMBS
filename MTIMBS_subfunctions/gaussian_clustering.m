function [idx,uidx,num_MT] = gaussian_clustering(x,y,manual_option)

%%Gaussian Micture Model to Separate MTs
%function takes an array of bright points (x,y) in an image from ridge 
%and clusters them into a number of MTs: the number of MTs needs to be defined by user

% JS Edit 220210, give user a catch in case they enter threshold values for
% MTs which would make the program error

% JS Edit 220210, enable ability for user to change the uniform prior
% condition by clicking close to the MTs they identify


%% GMM fitting scan params

maxMT = 15;
numsamples = 7;

%% Auto find MTs
% attempt to make more algorithmic to find optimal number of MTs by
% doing a sweep and finding best option

% if no third argument, just perform the gaussian clustering with uniform
% prior (default) and average over the listed params

% Warnings are suppressed from gmcluster > gmdistribution.fit > fitgmdist >
% gaussian_clustering related to convergence at high MTs
%  if you wish to not show these warnings, simply turn the warning to 'on' below

% w = struct(); w.identifier = 'stats:gmdistribution:FailedToConverge'; w.state = 'on';
% warning('on',w.identifier);

% gmm wants at least as many points as clusters. Hence, choose the minimum
% to make sure (which most of the time will be maxMT, but rare cases exist)
maxMT = min(maxMT, length(x)-1);

if nargin < 3
    % gm = fitgmdist([x,y],num_MT,'RegularizationValue',0.1);
    AICsum = zeros(1,maxMT-1);
    gmstore = cell(numsamples, maxMT);
    AICscores = nan(numsamples, maxMT);

    % do multiple samples to average over randomized priors
    for sample = 1:numsamples
        %and now do for a number of MTs we think might exist
        for iMT = 1:maxMT
            gmstore{sample,iMT} = fitgmdist([x,y],iMT,'RegularizationValue',0.1);
            AICscores(sample,iMT) = gmstore{sample,iMT}.AIC;
        end

        % process to get derivative
        AICderiv = AICscores(sample,2:end) - AICscores(sample,1:end-1);
        AICsum = AICsum + ( abs(AICderiv) < 50) ; %50 seems like a reasonable convergence param
    end

    tryMT = find( (AICsum > numsamples/2) ~= 0, 1, 'first');
    % edge case if nothing converges then just set it to the largest number
    % of scanning. It may not converge, but it shouldn't break
    if isempty(tryMT) 
        [~, tryMT] = min(AICsum);
    end
    
    fprintf("Optimal MT # " + num2str(tryMT) + "\n")
    num_MT = tryMT;

    [~, isample] = min(AICscores(:,tryMT));
    gm = gmstore{isample, tryMT};

% if specified, initialize the user clicking for gmm coordinate centers

%% User defined number of MTs (from 220418 version)

else
    
    %num_MT = input("How many MTs are in the image? \n"); %ask for how many MTs to make
    
    % find the object that corresponds to the threshold_ridge
    get(gca, 'Children');
    h = findobj('tag', 'threshold_ridge');

    % still testing whether endpoints are any improvement compared to just
    % choosing means

%     endpoints = click_for_coord(h, 2*num_MT);
% 
%     PComponents = [];
%     for j = 1:num_MT
%         ends = endpoints(2*j-1:2*j,:);
%         Mu(j,:) = mean(ends);
%         
%         dd = pdist2(ends(1,:), Mu(j,:));
%         if dd < 2
%             dd = 2;
%         end
%         Sigma(:,:,j) = [dd 1; 1 1]; % we just do 100 because these MTs are super long in one direction
%         PComponents = [PComponents, dd];
%             
%     end
    
    if manual_option == 'y'
        %means = click_for_coord(h, num_MT)
        means = click_for_coord_chatGPT(h);
        num_MT = size(means,1);
        
        PComponents = ones(num_MT);
        for j = 1:num_MT
            Mu(j,:) = means(j,:);
            Sigma(:,:,j) = [100 1; 1 1]; % we just do 100 because these MTs are super long in one direction
        end
  
        Mu;
        Sigma;
        PComponents = PComponents / sum(PComponents);
        
        S = struct('mu',Mu,'Sigma',Sigma,'ComponentProportion',PComponents);
        gm = fitgmdist([x,y],num_MT,'Start',S,'RegularizationValue',0.1);
        

    else
        proceed = 'n';
    
        while proceed ~= 'y'

            num_MT = input("How many MTs are in the image? \n"); %ask for how many MTs to make

            if length(num_MT) > 1
                idx = []; uidx = []; num_MT = [];
                return
            end
            % only do it if the user is sure they entered the correct number of MTs
            if num_MT < 25
                proceed = 'y';
            else
                fprintf("This is a large number of MTs! Are you sure you meant " +num2str(num_MT)+ " total MTs? \n")
                proceed = input("Proceed fitting " +num2str(num_MT)+ " MTs? (y/n) \n", 's');
            end

        end
        gm = fitgmdist([x,y],num_MT,'RegularizationValue',0.1);
    end
end

%% cluster according to the gmm model
idx = cluster(gm,[x,y]); %take the gaussians clusters made, and give them an index
uidx = unique(idx); %just to make sure it is right


%% combine clusters if they overlap by more than a couple points
% (which they should if they are actually the same MT and gmm just messed up)

% find potential conflict points near ends

% for n = max(uidx):-1:1
%     
%     conflict = 0;
%     
%     nmask = idx == n;
%     xmask = x(nmask)
%     ymask = y(nmask)
%     nends = [xmask([1:7,end-7:end]), ymask([1:7,end-7:end])];
%     
%     for m = n-1:-1:1
%         mmask = idx == m;
%         xmask = x(mmask); ymask = y(mmask);
%         mends = [xmask([1:7,end-7:end]), ymask([1:7,end-7:end])];
%         
%         % now check if these ends are critically close to another spot
%         % (within two pixels to account for diagonal)
%         
%         for i = size(nends,2)
%             for j = size(mends,2)
%                 if pdist2(nends(i,:), mends(j,:)) < 5
%                     conflict = 1;
%                     fprintf("There was a conflict between MT " + num2str(n) + " and MT " + num2str(m) + "\n")
%                 end
%             end
%         end
%     
%     end
%     
% end


end

