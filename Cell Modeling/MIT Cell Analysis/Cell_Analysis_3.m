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
plot(Q14023.Raw.Times, Q14023.Raw.Amps);



%% Internal Resistance

% Get the voltage sag for each sample
Q14023.IR.dV = diff(Q14023.Raw.Volts); 
Q14023.IR.dI = diff(Q14023.Raw.Amps);


% 
[IR, Times] = peakFilter(Q14023.IR.dI,Q14023.Raw.Volts, Q14023.Raw.Times);

subplot(4,1,4)
plot(Times, IR)




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

function [IR, Time] = peakFilter(di, v, time)
    time(1:501) = [];
    di(1:500) = [];
    v(1:500) = [];
    v(length(v)-1) =[];
    
    temp1 = di(di~=0);
    avgI = mean(temp1);
    Vselect = zeros(length(v), 1);
    dI = zeros(length(v), 1);
    dV = zeros(length(v),1);
    filter = zeros(length(v), 1);
    
    di(1:4) = 0;
    for i = 4:length(di)
        if (di(i) <= (100*avgI))
            di(i) = 0;
        elseif (di(i) > (100*avgI)) && (3 < i < length(di)-4)
            for j = -3:3
                Vselect(i + j) = v(i+j);
            end
        end
    end
    
    k = 4;
    while k  < length(di)
        sumdI = 0;
        if (di(k) ~= 0)
            filter(k) = 1; 
            for j = -3:3 
                nextdI = di(k + j);
                sumdI = sumdI + nextdI;
            end
            dV(k) = Vselect(k -3) - Vselect(k +4);
            dI(k) = sumdI;
            k = k + 3;
        end
        k = k + 1;
    end
    
    time = time.*filter;
    Time = time(time~=0);
    dV = dV(dV~=0);
    dI = dI(dI~=0);
    IR = dV./dI;
end