%% MIT Data Analysis
% Max Boyken
% 16 May 2020
%This script seeks to find the Internal Resistance of 18650 cells using the
%current interrupt method.  Using this method, at certain time intervals
%current is swiftly increased for a short period of time.  The voltage sag
%during this "current interrupt" can be measured, and, when divided by the
%change in current during the interrupt, will give Internal Resistance.

clc; clear; close all;

% Figure Interpreter
set(groot, 'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

%% Data Import
Cell.Raw = importfile('VTC6_1_60_23.15_1_20181022T215109Z.csv');

% Calculate SOC with Coulomb Counting
Cell.Raw.SOC = 100 - cumsum([0; diff(Cell.Raw.Times)].*Cell.Raw.Amps./10800.*100);

%% Initial Visualization
subplot(3,1,1)
plot( Cell.Raw.SOC , Cell.Raw.Volts );
set(gca, 'XDir', 'reverse');
xlabel( 'SOC' );
xlim([0,100]);
ylabel( 'Voltage, $v(t)$ $[V]$');

subplot(3,1,2)
plot( Cell.Raw.SOC , Cell.Raw.Amps );
set(gca, 'XDir', 'reverse');
xlabel( 'SOC' );
xlim([0,100]);
ylabel( 'Current, $i(t)$ $[A]$');

%% Internal Resistance Calculations

[Cell.IR.dVolts, locs] = findpeaks(-Cell.Raw.Volts, 'MinPeakProminence', 0.005);     %Voltage Sag
Cell.IR.dVolts = -Cell.IR.dVolts;
Cell.IR.dVolts = Cell.Raw.Volts(locs - 10) - Cell.IR.dVolts;  %SHOULD BE CHANGED, locs-10 estimates pre-sag volts

[Cell.IR.dAmps, locs] = findpeaks(Cell.Raw.Amps, 'MinPeakProminence', 0.005);           %Current interrupt
Cell.IR.dAmps = Cell.IR.dAmps - Cell.Raw.Amps(locs - 10);                             %SHOULD BE CHANGED

Cell.IR.Resistance = Cell.IR.dVolts ./ Cell.IR.dAmps;                                 %Internal resistance

subplot(3,1,3)
plot( Cell.Raw.SOC(locs) , Cell.IR.Resistance);
set(gca, 'Xdir', 'reverse');
xlabel( 'SOC' );
xlim([0,100]);
ylabel( 'Internal Resitance, $[\Omega]$');
ylim([0,0.03]);

%% Ohmic Heating Calculations
Cell.Q = (Cell.Raw.Amps(locs)).^2.*Cell.IR.Resistance


%% tidying
clear('locs');

%% Local Functions
function [Data] = importfile(filename, dataLines)
    if nargin < 2
        dataLines = [7, Inf];
    end

    opts = delimitedTextImportOptions("NumVariables", 3);

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

    % Import the data
    Cell = readtable(filename, opts);
    
    % Convert to output type
    Data.Times = Cell.Times;
    Data.Volts = Cell.Volts;
    Data.Amps = Cell.Amps;
end