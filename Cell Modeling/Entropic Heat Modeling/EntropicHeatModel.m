clc; clear; close all;

%% Entropic Heat Model
% Max Boyken, Blake Christierson
% 7 August 2020

% Data Taken From: "Effect of Entropy Change of Lithium Intercalation in 
% Cathodes and Anodes on Lion Battery Thermal Management" - Viswanathan,
% 2009

%% Load Data & Manipulate
load( 'Data.mat')
Data = table2array( Data );
Data( Data < 0 ) = 0;

Data = [Data; Data(41:end,:)];
Data(61:end,1) = 10;

DataSegment = Data(61:end,3);
DataSegment( DataSegment > 10 ) = 10;

Data(61:end,3) = DataSegment;

Fit = FitModel( Data(:,1), Data(:,2), Data(:,3) );

save( 'EntropicHeatModel.mat', 'Fit' );

%% Local Functions
function FitResult = FitModel(CRate, SOC, PerEntropy)

[xData, yData, zData] = prepareSurfaceData( CRate, SOC, PerEntropy );

% Set up fittype and options.
ft = 'cubicinterp';

% Fit model to data.
FitResult = fit( [xData, yData], zData, ft, 'Normalize', 'on' );
end



