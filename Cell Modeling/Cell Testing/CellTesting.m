%% Cell Testing
% Tucker Zischka
% 10 March 2021
% For Visualizing and fitting the data collected by the single cell heating
% test platform developed by the Electrical Sneior Design group

clc; clear; close all; 

%% Data Import
% Import data. Data should be stored inside of a 16 element, comma
% delimiated array. 
AvgCell

for j = 1:numlevels
    for k = 1:numfiles
        myfilename = sprintf('cell%d.csv', k);
        Temp = importfile(myfilename);
    end
end
Cell1 = importfile("C:\Users\tuckr\OneDrive\Desktop\Example Output.csv"); 
    



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
%plot(test1.time test1.temp.average); %<- Specify plot properites
%xlim([timemin timemax]);
xlabel('Time');
ylabel('Temperature');
title('Cell Body Temperature');

hold on

% ==== VOLTAGE VS TIME ====
figure(2); 
pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties
%plot(test1.time test1.voltage.average); %<- Specify plot properites
%xlim([timemin timemax]);
xlabel('Time');
ylabel('Voltage');
title('Cell Voltage during Test');

hold on

% ==== CURRENT VS TIME ====
figure(3); 
pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties
%plot(test1.time test1.current.average); %<- Specify plot properites
%xlim([timemin timemax]);
xlabel('Time');
ylabel('Current');
title('Cell Current during Test');

hold on


%% Functions

%Single File Import Function
function [Data] = importfile(filename, dataLines)
%% Input handling
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 32, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Time", "SoC", "Current", "Voltage", "Temp1", "Temp2", "Temp3", "Temp4", "Temp5", "Temp6", "Temp7", "Temp8", "Temp9", "Temp10", "Temp11", "Temp12", "Temp13", "Temp14", "Temp15", "Temp16", "Temp17", "Temp18", "Temp19", "Temp20", "Temp21", "Temp22", "Temp23", "Temp24", "Temp25", "Temp26", "Temp27", "Temp28"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ImportErrorRule = "omitrow";
opts.MissingRule = "omitrow";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
tbl = readtable(filename, opts);

%% Convert to output type
Data.Time = tbl.Time;
Data.SoC = tbl.SoC;
Data.Current = tbl.Current;
Data.Voltage = tbl.Voltage;
Data.Temp1 = tbl.Temp1;
Data.Temp2 = tbl.Temp2;
Data.Temp3 = tbl.Temp3;
Data.Temp4 = tbl.Temp4;
Data.Temp5 = tbl.Temp5;
Data.Temp6 = tbl.Temp6;
Data.Temp7 = tbl.Temp7;
Data.Temp8 = tbl.Temp8;
Data.Temp9 = tbl.Temp9;
Data.Temp10 = tbl.Temp10;
Data.Temp11 = tbl.Temp11;
Data.Temp12 = tbl.Temp12;
Data.Temp13 = tbl.Temp13;
Data.Temp14 = tbl.Temp14;
Data.Temp15 = tbl.Temp15;
Data.Temp16 = tbl.Temp16;
Data.Temp17 = tbl.Temp17;
Data.Temp18 = tbl.Temp18;
Data.Temp19 = tbl.Temp19;
Data.Temp20 = tbl.Temp20;
Data.Temp21 = tbl.Temp21;
Data.Temp22 = tbl.Temp22;
Data.Temp23 = tbl.Temp23;
Data.Temp24 = tbl.Temp24;
Data.Temp25 = tbl.Temp25;
Data.Temp26 = tbl.Temp26;
Data.Temp27 = tbl.Temp27;
Data.Temp28 = tbl.Temp28;
end
