%% Cell Testing
% Tucker Zischka
% 10 March 2021
% For Visualizing and fitting the data collected by the single cell heating
% test platform developed by the Electrical Sneior Design group

clc; clear; close all; 

%% Data Import
% Import data. Data should be stored inside of a 16 element, comma
% delimiated array. 

AvgCell = struct('Time', 0, 'SoC', 0, 'Current', 0, 'Voltage', 0, 'Temp1', 0, 'Temp2', 0, 'Temp3', 0, 'Temp4', 0,'Temp5', 0,'Temp6', 0,'Temp7', 0,'Temp8', 0,'Temp9', 0,'Temp10', 0,'Temp11', 0,'Temp12', 0,'Temp13', 0,'Temp14', 0,'Temp15', 0,'Temp16', 0,'Temp17', 0,'Temp18', 0,'Temp19', 0,'Temp20', 0,'Temp21', 0,'Temp22', 0,'Temp23', 0,'Temp24', 0,'Temp25', 0,'Temp26', 0,'Temp27', 0,'Temp28', 0); 
NumLevels = 1; 
NumFiles = 3; 

for j = 1:NumLevels
    for k = 1:NumFiles
        myfilename = sprintf('cell%d.csv', k);
        Temp = importfile(myfilename);
        %Check if the time field is missing anything
        AvgCell.SoC = AvgCell.SoC + Temp.SoC; 
        AvgCell.Current = AvgCell.Current + Temp.Current;
        AvgCell.Voltage =  AvgCell.Voltage + Temp.Voltage;
        AvgCell.Temp1 = AvgCell.Temp1 + Temp.Temp1;
        AvgCell.Temp2 = AvgCell.Temp2 + Temp.Temp2;
        AvgCell.Temp3 = AvgCell.Temp3 + Temp.Temp3; 
        AvgCell.Temp4 = AvgCell.Temp4 + Temp.Temp4; 
        AvgCell.Temp5 = AvgCell.Temp5 + Temp.Temp5; 
        AvgCell.Temp6 = AvgCell.Temp6 + Temp.Temp6; 
        AvgCell.Temp7 = AvgCell.Temp7 + Temp.Temp7; 
        AvgCell.Temp8 = AvgCell.Temp8 + Temp.Temp8; 
        AvgCell.Temp9 = AvgCell.Temp9 + Temp.Temp9; 
        AvgCell.Temp10 = AvgCell.Temp10 + Temp.Temp10; 
        AvgCell.Temp11 = AvgCell.Temp11 + Temp.Temp11; 
        AvgCell.Temp12 = AvgCell.Temp12 + Temp.Temp12; 
        AvgCell.Temp13 = AvgCell.Temp13 + Temp.Temp13; 
        AvgCell.Temp14 = AvgCell.Temp14 + Temp.Temp14; 
        AvgCell.Temp15 = AvgCell.Temp15 + Temp.Temp15; 
        AvgCell.Temp16 = AvgCell.Temp16 + Temp.Temp16; 
        AvgCell.Temp17 = AvgCell.Temp17 + Temp.Temp17; 
        AvgCell.Temp18 = AvgCell.Temp18 + Temp.Temp18; 
        AvgCell.Temp19 = AvgCell.Temp19 + Temp.Temp19; 
        AvgCell.Temp20 = AvgCell.Temp20 + Temp.Temp20; 
        AvgCell.Temp21 = AvgCell.Temp21 + Temp.Temp21; 
        AvgCell.Temp22 = AvgCell.Temp22 + Temp.Temp22; 
        AvgCell.Temp23 = AvgCell.Temp23 + Temp.Temp23; 
        AvgCell.Temp24 = AvgCell.Temp24 + Temp.Temp24; 
        AvgCell.Temp25 = AvgCell.Temp25 + Temp.Temp25; 
        AvgCell.Temp26 = AvgCell.Temp26 + Temp.Temp26; 
        AvgCell.Temp27 = AvgCell.Temp27 + Temp.Temp27; 
        AvgCell.Temp28 = AvgCell.Temp28 + Temp.Temp28; 
        
        
    end
    AvgCell.SoC = AvgCell.SoC / NumFiles;
    AvgCell.Current = AvgCell.Current / NumFiles;
    AvgCell.Voltage =  AvgCell.Voltage / NumFiles;
    AvgCell.Temp1 = AvgCell.Temp1 / NumFiles;
    AvgCell.Temp2 = AvgCell.Temp2 / NumFiles;
    AvgCell.Temp3 = AvgCell.Temp3 / NumFiles;
    AvgCell.Temp4 = AvgCell.Temp4 / NumFiles;
    AvgCell.Temp5 = AvgCell.Temp5 / NumFiles;
    AvgCell.Temp6 = AvgCell.Temp6 / NumFiles;
    AvgCell.Temp7 = AvgCell.Temp7 / NumFiles;
    AvgCell.Temp8 = AvgCell.Temp8 / NumFiles;
    AvgCell.Temp9 = AvgCell.Temp9 / NumFiles;
    AvgCell.Temp10 = AvgCell.Temp10 / NumFiles;
    AvgCell.Temp11 = AvgCell.Temp11 / NumFiles;
    AvgCell.Temp12 = AvgCell.Temp12 / NumFiles;
    AvgCell.Temp13 = AvgCell.Temp13 / NumFiles;
    AvgCell.Temp14 = AvgCell.Temp14 / NumFiles;
    AvgCell.Temp15 = AvgCell.Temp15 / NumFiles;
    AvgCell.Temp16 = AvgCell.Temp16 / NumFiles;
    AvgCell.Temp17 = AvgCell.Temp17 / NumFiles;
    AvgCell.Temp18 = AvgCell.Temp18 / NumFiles;
    AvgCell.Temp19 = AvgCell.Temp19 / NumFiles;
    AvgCell.Temp20 = AvgCell.Temp20 / NumFiles;
    AvgCell.Temp21 = AvgCell.Temp21 / NumFiles;
    AvgCell.Temp22 = AvgCell.Temp22 / NumFiles;
    AvgCell.Temp23 = AvgCell.Temp23 / NumFiles;
    AvgCell.Temp24 = AvgCell.Temp24 / NumFiles;
    AvgCell.Temp25 = AvgCell.Temp25 / NumFiles;
    AvgCell.Temp26 = AvgCell.Temp26 / NumFiles;
    AvgCell.Temp27 = AvgCell.Temp27 / NumFiles;
    AvgCell.Temp28 = AvgCell.Temp28 / NumFiles;
end
    



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
