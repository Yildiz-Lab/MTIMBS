function [] = prettykdplot(Emax, kd, hillco, conc_with_zero, hill_fit, intensity_data, std_error_data, plot_name, save_path)
%this function takes input from the hill equation fitting and makes a plot
%the plot is very pretty, by my very professional standards
%also saves it as an svg file for import into illustrator
%Written by Jon Fernandes
%Last Updated: 1/31/24

%make summary statistics to plot
A = [median(Emax);median(kd); median(hillco)];
%make strings to pring in the legend
kd_string = sprintf(['K_D= %0.1f ' char(177) ' %0.2fnM \n'], median(kd), std(kd));
hillco_string = sprintf(['n=%0.3f ' char(177) ' %0.2f'],  median(hillco), std(hillco));
    
%Drawing The plot
clf; %clear figure
hold on; %get ready to do everything to the figure
Xaxis = linspace(min(conc_with_zero), max(conc_with_zero));  %Make X-Axis

hP = plot(Xaxis, hill_fit(A,Xaxis));%handle for the fitted plot
set(hP                            , ...
  'LineWidth'       , 1.5         , ...%Thickness of Fit lines 
  'Color'           , 'r'         , ...%Color of Fit line
  'LineStyle'       , "-"      );%"--" = dashed line "-" = solid line

hE = errorbar(conc_with_zero, intensity_data, std_error_data); %handle for errorbars
set(hE                            , ...%changing the properties of the ebars
  'LineWidth'       , 1        , ...%Thickness of Errorbar lines 
  'Color'           , [.2 .2 .2]  , ...%Color of Errorbar lines
  'LineStyle'       , "none"      , ...%remove lines between errorbars
  'Marker'          , 'o'         , ...%shape of middle dot
  'MarkerSize'      , 6           , ...%size of middle dot
  'MarkerEdgeColor' , [.2 .2 .2]  , ...%color of middle dot outline
  'MarkerFaceColor' , [.7 .7 .7]  );%fill collor of middle dot

hXlabel = xlabel('Concentration (nM)'); %handle for X axis
hYlabel = ylabel('Intensity (AU)'); %handle for Y axis
hTitle = title(plot_name); %handle for title
hLegend = legend( ... %handle for legend
  [hE, hP],  ... %two objects in the legend
  'Data (\mu \pm S.E.)' , ...
  'Hill Equation Fit'   , ...
  'LineWidth', 0.5      , ...
  'location', 'SE' );
hLegend.Title.String = [kd_string,  hillco_string]; %use a legend title for stats
set(gca, 'FontSize', 8); %set all font size to 8 
set([hXlabel, hYlabel, hLegend], 'FontSize', 12); %set axis titles & legend size to 10
set(hTitle, 'FontSize', 12); %make the Font a bit bigger for Title


set(gca, ...
  'Box'         , 'off'     , ...%remove axis outline
  'TickDir'     , 'out'     , ...%point tickmarks away from graph
  'TickLength'  , [.01 .01] , ...%size of tickmarks
  'XMinorTick'  , 'off'      , ...%use little ticks
  'YMinorTick'  , 'off'      , ...%use little ticks
  'YGrid'       , 'off'     , ...%horizontal grid
  'XColor'      , 'k'       , ...%axis color
  'YColor'      , 'k'       , ...%axis color
  'LineWidth'   , 1.5         ); %axis thickness

%moving position of the axis labels
xh = get(gca,'xlabel'); % handle to the xlabel object
px = get(xh,'position'); % get the current position property
px(2) = 1.3*px(2) ;       % increase the vertical distance 
set(xh,'position',px)    % set the new position
yl = get(gca,'ylabel'); % handle to the ylabel object
pyl = get(yl,'position'); % get the current position property
pyl(1) = 1.4*pyl(1) ;       % increase the horizontal distance, 
set(yl,'position',pyl)    % set the new position

set(findall(gcf,'-property','FontName'),'FontName','Myriad Pro') %set all fonts
set(gcf, 'PaperPositionMode', 'auto');%use paperposition mode to preserve aspect ratio
%this makes it so that the figure it makes is the same size as your figure
%window

hold off %done making the plot

final_file_name = [save_path, '\', plot_name];
saveas(gcf, final_file_name); %save as .fig
print(gcf,'-vector','-dsvg',[final_file_name,'.svg']) % svg saving
print(gcf,'-vector','-dpdf',[final_file_name,'.pdf']) % pdf saving