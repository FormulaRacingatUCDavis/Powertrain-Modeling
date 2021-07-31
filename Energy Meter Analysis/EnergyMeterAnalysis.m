%% Endurance Energy Meter Data Analysis
% Blake Christierson
% 16 May 2020
%   This script was created as a demo as to some of the statistical 
%   operations that can be done to pseudorandom signals as well as the way 
%   of seeing how to characterize them. These methods are applied to the 
%   current and voltage traces from the FE6 endurance energy meter data 
%   from FSAE Lincoln 2019.

clc; clear; close all;

% Figure Interpreter
set(groot,'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

%% Data Import
Stint(1).Raw = StintImport('Endurance_stint_1.csv');
Stint(2).Raw = StintImport('Endurance_stint_2.csv');

Stint(1).Raw.Current = Stint(1).Raw.Current .* 10/6 .* 117.6/504 * 65/50;
Stint(2).Raw.Current = Stint(2).Raw.Current .* 10/6 .* 117.6/504 * 65/50;

Stint(1).Raw.Voltage = Stint(1).Raw.Voltage .* 504/117.6;
Stint(2).Raw.Voltage = Stint(2).Raw.Voltage .* 504/117.6;

% Raw Power Calculation [kW]


Stint(1).Raw.Power = Stint(1).Raw.Voltage.*Stint(1).Raw.Current./1000;
Stint(2).Raw.Power = Stint(2).Raw.Voltage.*Stint(2).Raw.Current./1000;

%% Initial Visualization
Figure(1) = figure('Name', 'Main Plotting');

subplot(2,3,1)
plot( Stint(1).Raw.Time, Stint(1).Raw.Voltage );
hold on

title( 'Stint 1 Voltage Trace' )
xlabel( 'Time, $t$ [$sec$]' )
ylabel( 'Voltage, $V(t)$ [$V$]' )
ylim([80 120]);

subplot(2,3,2)
plot( Stint(1).Raw.Time, Stint(1).Raw.Current );
hold on

title( 'Stint 1 Current Trace' )
xlabel( 'Time, $t$ [$sec$]' )
ylabel( 'Current, $I(t)$ [$A$]' )
ylim([-50 500]);

subplot(2,3,3)
plot( Stint(1).Raw.Time, Stint(1).Raw.Power );
hold on

title( 'Stint 1 Power Trace' )
xlabel( 'Time, $t$ [$sec$]' )
ylabel( 'Power, $P(t)$ [$kW$]' )
ylim([0 50]);

subplot(2,3,4)
plot( Stint(2).Raw.Time, Stint(2).Raw.Voltage );
hold on

title( 'Stint 2 Voltage Trace' )
xlabel( 'Time, $t$ [$sec$]' )
ylabel( 'Voltage, $V(t)$ [$V$]' )
ylim([80 120]);

subplot(2,3,5)
plot( Stint(2).Raw.Time, Stint(2).Raw.Current );
hold on

title( 'Stint 2 Current Trace' )
xlabel( 'Time, $t$ [$sec$]' )
ylabel( 'Current, $I(t)$ [$A$]' )
ylim([-50 500]);

subplot(2,3,6)
plot( Stint(2).Raw.Time, Stint(2).Raw.Power );
hold on

title( 'Stint 2 Power Trace' )
xlabel( 'Time, $t$ [$sec$]' )
ylabel( 'Power, $P(t)$ [$kW$]' )
ylim([0 50]);

%% Distribution Plotting
NBins = 100;

Figure(2) = figure('Name', 'Normalized Histogram Distributions');

subplot(1,3,1)
Stint(1).LevelTime.Voltage = NormalizedHistogram( Stint(1).Raw.Time, ...
    Stint(1).Raw.Voltage, linspace(80,120,NBins) );

hold on

Stint(2).LevelTime.Voltage = NormalizedHistogram( Stint(2).Raw.Time, ...
    Stint(2).Raw.Voltage, linspace(80,120,NBins) );

title( 'Voltage Histograms' )
xlabel( 'Voltage, $V(t)$ [$V$]' )
ylabel( 'Time, $t$ [$sec$]' )
legend( {'Stint 1', 'Stint 2'} )
xlim([80 120]); ylim([0 250]);

subplot(1,3,2)
Stint(1).LevelTime.Current = NormalizedHistogram( Stint(1).Raw.Time, ...
    Stint(1).Raw.Current, linspace(-20,500,NBins) );

hold on

Stint(2).LevelTime.Current = NormalizedHistogram( Stint(2).Raw.Time, ...
    Stint(2).Raw.Current, linspace(-20,500,NBins) );

title( 'Current Histograms' )
xlabel( 'Current, $I(t)$ [$A$]' )
ylabel( 'Time, $t$ [$sec$]' )
legend( {'Stint 1', 'Stint 2'} )
xlim([-20 500]); ylim([0 250]);

subplot(1,3,3)
Stint(1).LevelTime.Power = NormalizedHistogram( Stint(1).Raw.Time, ...
    Stint(1).Raw.Power, linspace(0,50,NBins) );

hold on

Stint(2).LevelTime.Power = NormalizedHistogram( Stint(2).Raw.Time, ...
    Stint(2).Raw.Power, linspace(0,50,NBins) );

title( 'Power Histograms' )
xlabel( 'Power, $P(t)$ [$kW$]' )
ylabel( 'Time, $t$ [$sec$]' )
legend( {'Stint 1', 'Stint 2'} )
xlim([0 50]); ylim([0 250]);

clear NBins

%% Duration Studies
CurrentLevel = linspace(-10,500,100);
PowerLevel = linspace(-2,60,50);

Figure(3) = figure('Name', 'Bivariate Histogram Distributions');

subplot(2,2,1)
hold on

Stint(1).Durations.Current = ...
    DrawDurations( Stint(1).Raw.Time, Stint(1).Raw.Current, CurrentLevel );

title( 'Stint 1 Current Draw Durations' )
xlabel( 'Current Level, $I(t)$ [$A$]' )
ylabel( 'Exceedance Duration, $t$ [$sec$]' )
xlim(CurrentLevel([1 end])); ylim([0 7.5]);

cb = colorbar;
cb.TickLabelInterpreter = 'latex';
cb.Label.String = 'Instances, $n$ [ ]';
cb.Label.Interpreter = 'latex';

ax = gca;
ax.CLim = [0 50];
zlim([0 50]);
    
subplot(2,2,2)
hold on

Stint(1).Durations.Power = ...
    DrawDurations( Stint(1).Raw.Time, Stint(1).Raw.Power, PowerLevel );

title( 'Stint 1 Power Draw Durations' )
xlabel( 'Power Level, $P(t)$ [$kW$]' )
ylabel( 'Exceedance Duration, $t$ [$sec$]' )
xlim(PowerLevel([1 end])); ylim([0 7.5]);

cb = colorbar;
cb.TickLabelInterpreter = 'latex';
cb.Label.String = 'Instances, $n$ [ ]';
cb.Label.Interpreter = 'latex';

subplot(2,2,3)
hold on

Stint(2).Durations.Current = ...
    DrawDurations( Stint(2).Raw.Time, Stint(2).Raw.Current, CurrentLevel );

title( 'Stint 2 Current Draw Durations' )
xlabel( 'Current Level, $I(t)$ [$A$]' )
ylabel( 'Exceedance Duration, $t$ [$sec$]' )
xlim(CurrentLevel([1 end])); ylim([0 7.5]);

cb = colorbar;
cb.TickLabelInterpreter = 'latex';
cb.Label.String = 'Instances, $n$ [ ]';
cb.Label.Interpreter = 'latex';

ax = gca;
ax.CLim = [0 50];
zlim([0 50]);

subplot(2,2,4)
hold on

Stint(2).Durations.Power = ...
    DrawDurations( Stint(2).Raw.Time, Stint(2).Raw.Power, PowerLevel );

title( 'Stint 2 Power Draw Durations' )
xlabel( 'Power Level, $P(t)$ [$kW$]' )
ylabel( 'Exceedance Duration, $t$ [$sec$]' )
xlim(PowerLevel([1 end])); ylim([0 7.5]);

cb = colorbar;
cb.TickLabelInterpreter = 'latex';
cb.Label.String = 'Instances, $n$ [ ]';
cb.Label.Interpreter = 'latex';

clear CurrentLevels PowerLevels

%% Local Functions
function [Data] = StintImport(filename, dataLines)
    if nargin < 2
        dataLines = [2, Inf];
    end

    % Setup the Import Options and import the data
    opts = delimitedTextImportOptions("NumVariables", 5);

    % Specify range and delimiter
    opts.DataLines = dataLines;
    opts.Delimiter = ",";

    % Specify column names and types
    opts.VariableNames = ["Time", "Voltage", "Current", "OverVoltage", "OverPower"];
    opts.VariableTypes = ["double", "double", "double", "string", "string"];

    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";

    % Specify variable properties
    opts = setvaropts(opts, ["OverVoltage", "OverPower"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["OverVoltage", "OverPower"], "EmptyFieldRule", "auto");

    % Import the data
    tbl = readtable(filename, opts);

    % Convert to output type
    Data.Time = tbl.Time;
    Data.Voltage = tbl.Voltage;
    Data.Current = tbl.Current;
    Data.OverVoltage = strcmpi(tbl.OverVoltage, "true");
    Data.OverPower = strcmpi(tbl.OverPower, "true");
end

function BinTime = NormalizedHistogram(Time, Data, Edges)
    Counts = histcounts(Data, Edges);
    BinTime = Counts * mean( diff(Time) );
    
    histogram('BinEdges', Edges, 'BinCounts', BinTime)
end

function Durations = DrawDurations(Time, Data, Level)
    % figure
    % plot( Time, Data, 'k:')
    % hold on
    
    X = [];
    for i = 1:length(Level)
        ExceedIdx = find( Data > Level(i) );
        % plot( Time(ExceedIdx), Data(ExceedIdx), 'b.' )
        
        if ~isempty(ExceedIdx)
            EndIdx = [ExceedIdx( (diff(ExceedIdx) - 1) > 0 ); ExceedIdx(end)];
            % plot( Time(EndIdx), Data(EndIdx), 'rx' )

            StartIdx = [ExceedIdx(1); ...
                ExceedIdx( circshift((diff(ExceedIdx) - 1) > 0, 1) )];
            % plot( Time(StartIdx), Data(StartIdx), 'ro' )
        else
            EndIdx = [];
            StartIdx = [];
        end
        
        Durations(i).Length = Time(EndIdx) - Time(StartIdx); %#ok<AGROW>
        Durations(i).Length = Durations(i).Length'; %#ok<AGROW>
        Durations(i).Level = Level(i); %#ok<AGROW>
        
        if isempty(X)
            X = Durations(i).Level.*ones(size(Durations(i).Length));
        else
            X = [X Durations(i).Level.*ones(size(Durations(i).Length))];
        end
    end
    
    histogram2( X, [Durations(:).Length], ...
        'DisplayStyle','tile','ShowEmptyBins','off', ...
        'XBinEdges', Level, 'YBinEdges', 0:0.1:7.5 );
end