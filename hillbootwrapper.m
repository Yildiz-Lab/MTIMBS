function [] = hillbootwrapper 
% This function is used to call as many hill bootstraps as you want to
% quickly analyze data and save figures in the specified folder. 

keep_going = 'y';
save_location = uigetdir(pwd,'Select location to save Hill Plot Files');
while keep_going == 'y'
    hillbootstrapv3(save_location);
    keep_going = input("Continue Hill Plotting? (y/n) \n", 's');
end
