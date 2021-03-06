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
subplot(4,1,1)
plot( Q14023.Raw.SOC , Q14023.Raw.Volts );
set(gca, 'XDir', 'reverse');

subplot(4,1,2)
plot( Q14023.Raw.SOC , Q14023.Raw.Amps );
set(gca, 'XDir', 'reverse');

subplot(4,1,3)
plot( Q14023.Raw.Times, Q14023.Raw.Amps);

%% Internal Resistance

% Get the voltage sag for each sample
Q14023.IR.Sag = diff(Q14023.Raw.Volts); 

% 
% Q14023.IR.Sag2 = Q14023.IR.Sag;
% Q14023.IR.Sag2(1:500) = [];
% 
% % Remove all voltage sags not at current interruptions 
% [Q14023.IR.Sag2, Q14023.IR.Times2] = mink(Q14023.IR.Sag2, 14);
% [Q14023.IR.Times2,Q14023.IR.Order2] = sort(Q14023.IR.Times2);
% Q14023.IR.Sag2 = Q14023.IR.Sag2(Q14023.IR.Order2,:);


%disregard initial noise
Q14023.IR.dAmp = diff(Q14023.Raw.Amps); 
Q14023.IR.Times = Q14023.Raw.Times; Q14023.Raw.SOC(1) = []; % since the other two are diff() they loose their first entry
Q14023.IR.dT = diff(Q14023.IR.Times); % to see time steps 

[Q14023.IR.Sag, Q14023.IR.dAmp, Q14023.IR.SOC] = cleanCompare(Q14023.IR.Sag, Q14023.IR.dAmp, Q14023.Raw.SOC);

Q14023.IR.Resistance = -Q14023.IR.Sag./Q14023.IR.dAmp;
windowsize = 300;  % since each step is around ~1/10th of a second -> this smooths it at 30sec steps
b = 1/windowsize*ones(1,windowsize - 1);
Q14023.IR.Resistance = filter(b, 1, Q14023.IR.Resistance);

subplot(4,1,4)
plot(Q14023.IR.SOC,Q14023.IR.Resistance);
set(gca, 'XDir', 'reverse');











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

function [DATA1, DATA2, Time] = cleanCompare(data1, data2, time)
    data1(1:500) = [];
    data2(1:500) = [];
    time(1:500) = [];
    
    filter = zeros(length(data1), 1);
    for i = 1:length(data1)
    if (data1(i) ~= 0) && (data2(i) ~= 0)
        filter(i) = 1;
    end      
    end
    
    data1 = data1 .* filter;
    data2 = data2 .* filter;
    time = time .* filter;
    DATA1 = data1(data1~=0);
    DATA2 = data2(data2~=0);
    Time = time(time ~= 0);
end