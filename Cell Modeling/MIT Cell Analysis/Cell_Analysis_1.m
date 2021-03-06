%% MIT Data Analysis
% Max Boyken
% 16 May 2020

clc; clear; close all;

% Figure Interpreter
set(groot, 'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

%% Data Import
Q14023.Raw = importfile('MIT Motorsports Cell Data 2019\Cell 1\30Q_1_40_23.15_1_20181014T161749Z.csv');

% Calculate SOC with Coulomb Counting
Q14023.Raw.SOC = 100 - cumsum([0; diff(Q14023.Raw.Times)].*Q14023.Raw.Amps./10800.*100);

%% Initial Visualization
subplot(3,1,1)
plot( Q14023.Raw.SOC , Q14023.Raw.Volts );
set(gca, 'XDir', 'reverse');

subplot(3,1,2)
plot( Q14023.Raw.SOC , Q14023.Raw.Amps );
set(gca, 'XDir', 'reverse');

%% Peaks
str.st = (0:999)'/1000;
str.s1 = randn(1000,1);
str.s2 = sin(2*pi*20*str.st);

T = struct2table(str);
T.st = seconds(T.st);
TT = table2timetable(T,'RowTimes','st');


%% Internal Resistance

% Get the voltage sag for each sample
Q14023.IR.Sag = diff(Q14023.Raw.Volts);
Q14023.IR.Sag(1:500) = [];                  %disregard initial noise
Q14023.IR.dAmp = diff(Q14023.Raw.Amps);
Q14023.IR.dAmp(1:500) = []; 

filter  = zeros(length(Q14023.IR.Sag),1);

%compare where each is non - zero
for i = 1:length(Q14023.IR.dAmp)
    if (Q14023.IR.dAmp(i) ~= 0) && (Q14023.IR.Sag(i) ~= 0)
        filter(i) = 1;
    end      
end

%Removing Data
Q14023.IR.Sag = Q14023.IR.Sag.*-filter;
Q14023.IR.dAmp = Q14023.IR.dAmp.*filter;
%Removing Zeros
%Q14023.IR.Sag = Q14023.IR.Sag(Q14023.IR.Sag~=0);
%Q14023.IR.dAmp = Q14023.IR.dAmp(Q14023.IR.dAmp~=0);
%Caluclating Resistance
Q14023.IR.Resistance = Q14023.IR.Sag./Q14023.IR.dAmp;


% Remove all voltage sags not at current interruptions 
%[Q14023.IR.Sag, Q14023.IR.Times] = mink(Q14023.IR.Sag, 14);
%[Q14023.IR.Times,Q14023.IR.Order] = sort(Q14023.IR.Times);
% Q14023.IR.Sag = Q14023.IR.Sag(Q14023.IR.Order,:);






%% Local Functions
function [Data] = importfile(filename, dataLines)
    if nargin < 2
        dataLines = [7, Inf];
    end

    opts = delimitedTextImportOptions("NumVariables", 6);

    % Specify range and delimiter
    opts.DataLines = dataLines;
    opts.Delimiter = ",";

    % Specify column names and types
    opts.VariableNames = ["Times", "Volts", "Amps", "Var4", "Var5", "Var6"];
    opts.SelectedVariableNames = ["Times", "Volts", "Amps"];
    opts.VariableTypes = ["double", "double", "double", "string", "string", "string"];

    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";

    % Specify variable properties
    opts = setvaropts(opts, ["Var4", "Var5", "Var6"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var4", "Var5", "Var6"], "EmptyFieldRule", "auto");

    % Import the data
    Q14023 = readtable(filename, opts);
    
    % Convert to output type
    Data.Times = Q14023.Times;
    Data.Volts = Q14023.Volts;
    Data.Amps = Q14023.Amps;
end