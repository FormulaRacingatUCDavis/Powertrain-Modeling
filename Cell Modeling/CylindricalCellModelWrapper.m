clc; clear; close all

Cell.Capacity = 3;  % [Ah]
Cell.IR = 0.0218;    % IR from MIT Data at 20% SOC, 40 degrees.  SOC / temperature dependency hasn't been implemented
Cell.k_Axial = 30;
Cell.k_Radial = 0.2;

Cell.Length = 65.2 / 1000;  % [mm -> m]
Cell.Radius = 9.175 / 1000; % [mm -> m]

Cell.Mass = 46.6 / 1000;   % [g -> kg]
Cell.Cp = 902;    % [J/kg-K]

Cell = CellCalculations(Cell);
%% Model Parameters
Model.CRate =  5;
Model.Time =   0:0.1:(60 * 60 / Model.CRate);
Model.Ohmic = (Model.CRate * Cell.Capacity)^2 * Cell.IR;
Model.Ohmic = timeseries(Model.Ohmic*ones(length(Model.Time),1), Model.Time);

%% Local Functions

function Cell = CellCalculations(Cell)
    Cell.R_Axial = 7 .* Cell.Length ./ ...
        ( 24*pi .* Cell.k_Axial .* Cell.Radius.^2 );
    
    Cell.R_Radial = 3 ./ ...
        ( 8 .* pi .* Cell.k_Radial .* Cell.Length);
end