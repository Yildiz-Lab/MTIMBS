function [] = kdfit(conc_data,intensity_data,error,titletext)
%This function takes MT intensity data, fits it to a Hill equation, and
%prints a plot
%Using the experimental error, it also estimates the error in the Kd value

hill_fit = @(b,x)  b(1).*x./(b(2)+x); %hill function, n=1 b(1)=max b(2)=Kd
b0 = [max(intensity_data); 100]; %initial parameter guesses

%Make a loop to do the fit many times

Nloops = 200; %number of times to loop
kd = zeros(Nloops,1); %preallocate an array to store kd values
Emax = zeros(Nloops,1); %preallocate an array to store saturation values

for i=1:Nloops
    rand_intensity = normrnd(intensity_data,error); 
    %create an array of values randomly sampled from a gaussian of same std
    %of experimental data
    B = lsqcurvefit(hill_fit, b0, conc_data, rand_intensity); %do the fit 
    kd(i) = B(2); %store the Kd fitted value
    Emax(i) = B(1); %store the Emax fitted value
end

A = [median(Emax);median(kd)];
% B = lsqcurvefit(hill_fit,b0, conc_data, intensity_data); %do the fit 

%Drawing The plot
clf; %clear figure
subplot(1,2,1)
Xaxis = linspace(min(conc_data), max(conc_data));  % Axis
errorbar(conc_data, intensity_data,error, 'bp')
hold on
plot(Xaxis, hill_fit(A,Xaxis), '-r')
hold off
grid
xlabel('Concentration (nM)')
ylabel('Intensity (AU)')
title(titletext)
legend(sprintf('Kd= %f +/- %fnM', median(kd), std(kd)), 'Location','SE')
subplot(1,2,2)
histogram(kd)
title('Kd Histogram')

end