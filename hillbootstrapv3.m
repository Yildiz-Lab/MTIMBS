function [] = hillbootstrapv2(save_path)
%This function takes MT intensity data, fits it to a Hill equation, and
%prints a plot from a data structure containing MT intensities
%requires the importbootstrapreplicates function to import data

data = importbootv2;

hill_fit = @(b,x)  b(1).*x.^(b(3))./(b(2)+x.^(b(3))); 
%hill function, n=1 b(1)=max b(2)=Kd b(3)=Hill coefficient
b0 = [10000, 100, 1]; %initial parameter guesses
lb=[0,0,0];%set lower bounds for parameters
ub=[50000,5000,4];%set upper bounds for parameters
%Make a loop to do the fit many times

Nloops = 200; %number of times to loop fitting
kd = zeros(Nloops,1); %preallocate an array to store kd values
Emax = zeros(Nloops,1); %preallocate an array to store saturation values
hillco = zeros(Nloops,1); %preallocate an array to store cooperativity values

conc_data = [data.conc]'; %make array of concentrations
intensity_data = zeros(length(conc_data),1); %preallocate array for intensities
std_error_data = zeros(length(conc_data),1); %preallocate array for errors
plot_name = data(1).name; %save the title for the plot
% save_path = data(1).filepath; %save location to save the plot


for n=1:length(conc_data) %loop through conc.s to get intensity/error
        intensity_data(n) = mean(data(n).intensity);
        %get the average sampled intensity at nth concentration
        std_error_data(n) = std(data(n).intensity)/sqrt(length(data(n).intensity));
        %get the error at nth concentration
end

conc_with_zero = [conc_data; 0]; %add the 0 concentration point
intensity_data(end+1) = 0; %add the 0 concentration point
std_error_data(end+1) = 0; %add the 0 concentration point

for i=1:Nloops %do the fit, Nloops times
    meantensity = zeros(length(conc_data),1);
    %preallocate array for storing sampled means
    for n=1:length(conc_data) %loop through conc.s to get mean intensity 
        sample = datasample(data(n).intensity,length(data(n).intensity));
        %sample intensity (with replacement) at a single concentration
        meantensity(n) = mean(sample);
        %get the average sampled intensity at nth concentration
    end 
    meantensity(end+1)=0;
    B = lsqcurvefit(hill_fit, b0, conc_with_zero, meantensity,lb,ub); %do the fit
    kd(i) = B(2); %store the Kd fitted value
    Emax(i) = B(1); %store the Emax fitted value
    hillco(i) = B(3); %store the cooperativity fitted value

end

%plot the fit with my pretty plotting function
%there's a lot going on there, read the function
prettykdplot(Emax, kd, hillco, conc_with_zero, hill_fit, intensity_data, std_error_data, plot_name, save_path);

end