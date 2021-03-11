%% Cell Testing
% Tucker Zischka
% 10 March 2021
% For Visualizing and fitting the data collected by the single cell heating
% test platform developed by the Electrical Sneior Design group

clc; clear; close all; 

%% Data Import
% Import data. Data should be stored inside of a 16 element, comma
% delimiated array. 

%% Calculations 
%Average calculations based on cell and test




%% Graphics
% Default Graph Properites
width = 3;     % Width in inches
height = 3;    % Height in inches
alw = 0.75;    % AxesLineWidth
fsz = 11;      % Fontsize
lw = 1.5;      % LineWidth
msz = 8;       % MarkerSize

%types of grpahs: 
% temperature vs time (Overlay with all cells of the same test)
% voltage vs time (Overlay with all cells of the same test)
% current vs time (Overlay with all cells of the same test)

% ==== TEMP VS TIME ====
figure(1);
pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties
plot(test1.time test1.temp.average); %<- Specify plot properites
xlim([timemin timemax]);
xlabel('Time');
ylabel('Temperature');
title('Cell Body Temperature');

hold on

% ==== VOLTAGE VS TIME ====
figure(2); 
pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties
plot(test1.time test1.voltage.average); %<- Specify plot properites
xlim([timemin timemax]);
xlabel('Time');
ylabel('Voltage');
title('Cell Voltage during Test');

hold on

% ==== CURRENT VS TIME ====
figure(3); 
pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties
plot(test1.time test1.current.average); %<- Specify plot properites
xlim([timemin timemax]);
xlabel('Time');
ylabel('Current');
title('Cell Current during Test');

hold on


