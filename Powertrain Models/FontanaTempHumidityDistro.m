
%% Instrumentation & Measurement
% Air Temperature - Three platinum resistance thermometers housed 
% in fan aspirated solar radiation shields combines active and passive aspiration 
% to minimize the effects of radiation. 1.5 meters above the ground surface.

% USCRN stations are equipped with three independent thermometers are used to 
% compute 5-minute averages using two-second readings from each thermometer. 
% Measurements are then used to derive hourly temperature value.

% Met One Instruments 076B 7308: Radiation Error < 5% under max solar 
% radiation of 1116 W per m2

% Relative Humidity - capacitive thin-film polymer humidity sensor
% HMP7: Relative Humidity accuracy up to ±0.8 %RH
clc; clear; close all;

TemperatureData = readtable("Fontana Temperature Distribution.xlsx", 'PreserveVariableNames', true);
TempDataArray = table2array(TemperatureData);
TempData = TempDataArray(:);

%%

%% Temperature Analysis
SigmaT = std(TempData);
MuTemp = mean(TempData);
OneSigmaT = TempData + SigmaT; TwoSigmaT = TempData + (2*SigmaT); 

Nbins=50; 
Figure(1) = figure('Name', 'Temperature');

TempHist = histfit(TempData,Nbins,'normal');
TempDist = fitdist(TempData,'normal');


set(TempHist(1),'facecolor',[0 0.4470 0.7410]); set(TempHist(2),'color',[0.4660 0.75 0.1880])
hold on
NormalizedTemp2 = histfit(OneSigmaT, Nbins,'normal')
set(NormalizedTemp2(1),'facecolor',[1 0.85 0.5]); set(NormalizedTemp2(2),'color',[1 0.2 0.2])

%grid("on")
title({'Fontana Maximum Temperature Distribution', 'in June (1999-2019)'})
xlim([60,125])
xlabel('Temperature (F)')
ylabel('Frequency')
set(gca,'xTick',60:5:120)
legend('Max Temp Data','Normalized','+1Sigma','Normalized +1Sigma','Location', 'northwest')
legend("boxoff")


%% Humidity Analysis

HumidityData = ImportHumidity("HumidityData2010-2019.xlsx");
Figure(2) = figure('Name', 'Humidity'); 

SigmaH = std(HumidityData);
OneSigmaH = HumidityData + SigmaH; TwoSigmaH = HumidityData + (2*SigmaH); 

HumidityHist = histfit(HumidityData, Nbins,'normal');
HumidityDist = fitdist(HumidityData,'normal');
set(HumidityHist(1),'facecolor',[0 0.4470 0.7410]); set(HumidityHist(2),'color',[0.4660 0.75 0.1880])
hold on
NormalizedHumid2 = histfit(OneSigmaH, Nbins,'normal');
set(NormalizedHumid2(1),'facecolor',[1 0.85 0.5]); set(NormalizedHumid2(2),'color',[1 0.2 0.2])

%grid("on")
title({'Fontana Maximum Humidity Distribution in June','9AM-3PM (2010-2019)'})
xlim([0,140])
xlabel('Humidity (\%)')
ylabel('Frequency')
set(gca,'xTick',0:10:100)
legend('Max Humidity Data','Normalized','+1Sigma','Normalized +1Sigma','Location', 'northwest')
legend("boxoff")

%% Local Functions
function HumidityData = ImportHumidity(workbookFile, sheetName, dataLines)
   
    % If no sheet is specified, read first sheet
    if nargin == 1 || isempty(sheetName)
        sheetName = 1;
    end
    
    % If row start and end points are not specified, define defaults
    if nargin <= 2
        dataLines = [2, 8365];
    end
    
    %%% Setup the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 2);
    
    % Specify sheet and range
    opts.Sheet = sheetName;
    opts.DataRange = "A" + dataLines(1, 1) + ":B" + dataLines(1, 2);
    
    % Specify column names and types
    opts.PreserveVariableNames = true;
    opts.VariableNames = ["DATE", "HourlyRelativeHumidity"];
    opts.VariableTypes = ["string", "double"];
    
    % Specify variable properties
    opts = setvaropts(opts, "DATE", "WhitespaceRule", "preserve");
    opts = setvaropts(opts, "DATE", "EmptyFieldRule", "auto");
    
    % Import the data
    HumidityData2010_2019 = readtable(workbookFile, opts, "UseExcel", false);
    
    for idx = 2:size(dataLines, 1)
        opts.DataRange = "A" + dataLines(idx, 1) + ":B" + dataLines(idx, 2);
        tb = readtable(workbookFile, opts, "UseExcel", false);
        HumidityData2010_2019 = [HumidityData2010_2019; tb]; %#ok<AGROW>
    end
    
    %%% Convert to output type
    DATE = HumidityData2010_2019.DATE;
    HourlyRelativeHumidity = HumidityData2010_2019.HourlyRelativeHumidity;
    
    %%% Time Conversion
    
    Date(length(DATE)).Year = 0; 
    
    for i=1:length(DATE)
        
    Datechar = char(DATE(i)); 
    Date(i).Year = str2double(Datechar(1:4)); 
    Date(i).Month = str2double(Datechar(6:7));
    Date(i).Day = str2double(Datechar(9:10));
    Date(i).Hour = str2double(Datechar(12:13));
    Date(i).Minute = str2double(Datechar(14:15));
    Date(i).Second = str2double(Datechar(17:18));
 
    end
    
    %%% Time Filtering
    
    ValidIdx = 9<=[Date(:).Hour]&[Date(:).Hour]<=15;
    
    X = HourlyRelativeHumidity(ValidIdx);
    HumidityData = X(:); HumidityData(isnan(HumidityData)) = [];
    %endturn
 end