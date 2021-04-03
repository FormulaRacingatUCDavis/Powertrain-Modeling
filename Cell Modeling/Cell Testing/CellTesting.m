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

% Import All Files for all Cells and Tests
for j = 1:NumLevels
    for k = 1:NumFiles
        myfilename = sprintf('cell%d_%d.csv', k, j);
        Temp = importfile(myfilename);
        %Check if the time field is missing anything 
        for i = 1:size(Temp.Time)
            if Temp.Time(i) == i
                printf("Skipped a time unit!")
            end
        end
       
        AvgCell(j).SoC = AvgCell(j).SoC + Temp.SoC; 
        AvgCell(j).Current = AvgCell(j).Current + Temp.Current;
        AvgCell(j).Voltage =  AvgCell(j).Voltage + Temp.Voltage;
        AvgCell(j).Temp1 = AvgCell(j).Temp1 + Temp.Temp1;
        AvgCell(j).Temp2 = AvgCell(j).Temp2 + Temp.Temp2;
        AvgCell(j).Temp3 = AvgCell(j).Temp3 + Temp.Temp3; 
        AvgCell(j).Temp4 = AvgCell(j).Temp4 + Temp.Temp4; 
        AvgCell(j).Temp5 = AvgCell(j).Temp5 + Temp.Temp5; 
        AvgCell(j).Temp6 = AvgCell(j).Temp6 + Temp.Temp6; 
        AvgCell(j).Temp7 = AvgCell(j).Temp7 + Temp.Temp7; 
        AvgCell(j).Temp8 = AvgCell(j).Temp8 + Temp.Temp8; 
        AvgCell(j).Temp9 = AvgCell(j).Temp9 + Temp.Temp9; 
        AvgCell(j).Temp10 = AvgCell(j).Temp10 + Temp.Temp10; 
        AvgCell(j).Temp11 = AvgCell(j).Temp11 + Temp.Temp11; 
        AvgCell(j).Temp12 = AvgCell(j).Temp12 + Temp.Temp12; 
        AvgCell(j).Temp13 = AvgCell(j).Temp13 + Temp.Temp13; 
        AvgCell(j).Temp14 = AvgCell(j).Temp14 + Temp.Temp14; 
        AvgCell(j).Temp15 = AvgCell(j).Temp15 + Temp.Temp15; 
        AvgCell(j).Temp16 = AvgCell(j).Temp16 + Temp.Temp16; 
        AvgCell(j).Temp17 = AvgCell(j).Temp17 + Temp.Temp17; 
        AvgCell(j).Temp18 = AvgCell(j).Temp18 + Temp.Temp18; 
        AvgCell(j).Temp19 = AvgCell(j).Temp19 + Temp.Temp19; 
        AvgCell(j).Temp20 = AvgCell(j).Temp20 + Temp.Temp20; 
        AvgCell(j).Temp21 = AvgCell(j).Temp21 + Temp.Temp21; 
        AvgCell(j).Temp22 = AvgCell(j).Temp22 + Temp.Temp22; 
        AvgCell(j).Temp23 = AvgCell(j).Temp23 + Temp.Temp23; 
        AvgCell(j).Temp24 = AvgCell(j).Temp24 + Temp.Temp24; 
        AvgCell(j).Temp25 = AvgCell(j).Temp25 + Temp.Temp25; 
        AvgCell(j).Temp26 = AvgCell(j).Temp26 + Temp.Temp26; 
        AvgCell(j).Temp27 = AvgCell(j).Temp27 + Temp.Temp27; 
        AvgCell(j).Temp28 = AvgCell(j).Temp28 + Temp.Temp28; 
        TimeSize = size(Temp1.Time);
        if TimeSize >= MaxTimeSize
            MaxTimeSize = TimeSize;
            if AvgCell(j).Time == Temp.Time 
                printf("Time Mismatch")
            end
            AvgCell(j).Time = Temp.Time;
        end   
    end
    
    AvgCell(j).SoC = AvgCell(j).SoC / NumFiles;
    AvgCell(j).Current = AvgCell(j).Current / NumFiles;
    AvgCell(j).Voltage =  AvgCell(j).Voltage / NumFiles;
    AvgCell(j).Temp1 = AvgCell(j).Temp1 / NumFiles;
    AvgCell(j).Temp2 = AvgCell(j).Temp2 / NumFiles;
    AvgCell(j).Temp3 = AvgCell(j).Temp3 / NumFiles;
    AvgCell(j).Temp4 = AvgCell(j).Temp4 / NumFiles;
    AvgCell(j).Temp5 = AvgCell(j).Temp5 / NumFiles;
    AvgCell(j).Temp6 = AvgCell(j).Temp6 / NumFiles;
    AvgCell(j).Temp7 = AvgCell(j).Temp7 / NumFiles;
    AvgCell(j).Temp8 = AvgCell(j).Temp8 / NumFiles;
    AvgCell(j).Temp9 = AvgCell(j).Temp9 / NumFiles;
    AvgCell(j).Temp10 = AvgCell(j).Temp10 / NumFiles;
    AvgCell(j).Temp11 = AvgCell(j).Temp11 / NumFiles;
    AvgCell(j).Temp12 = AvgCell(j).Temp12 / NumFiles;
    AvgCell(j).Temp13 = AvgCell(j).Temp13 / NumFiles;
    AvgCell(j).Temp14 = AvgCell(j).Temp14 / NumFiles;
    AvgCell(j).Temp15 = AvgCell(j).Temp15 / NumFiles;
    AvgCell(j).Temp16 = AvgCell(j).Temp16 / NumFiles;
    AvgCell(j).Temp17 = AvgCell(j).Temp17 / NumFiles;
    AvgCell(j).Temp18 = AvgCell(j).Temp18 / NumFiles;
    AvgCell(j).Temp19 = AvgCell(j).Temp19 / NumFiles;
    AvgCell(j).Temp20 = AvgCell(j).Temp20 / NumFiles;
    AvgCell(j).Temp21 = AvgCell(j).Temp21 / NumFiles;
    AvgCell(j).Temp22 = AvgCell(j).Temp22 / NumFiles;
    AvgCell(j).Temp23 = AvgCell(j).Temp23 / NumFiles;
    AvgCell(j).Temp24 = AvgCell(j).Temp24 / NumFiles;
    AvgCell(j).Temp25 = AvgCell(j).Temp25 / NumFiles;
    AvgCell(j).Temp26 = AvgCell(j).Temp26 / NumFiles;
    AvgCell(j).Temp27 = AvgCell(j).Temp27 / NumFiles;
    AvgCell(j).Temp28 = AvgCell(j).Temp28 / NumFiles;
    
    
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
