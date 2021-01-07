clc; clear; close all;

%% Desired Pack Characteristics
Pack.V = (1:600);    % Pack Voltage [V]
Pack.E = 6.7;    % Pack Energy Capacity [kWh]

%% Cell Characteristics
Cell.m = 126;  % Cell mass [g]
Cell.Cp = 0.902;    % Cell Specific Heat Capacity [J/g-K]

Cell.V = 4.2;    % Max Cell Voltage [V]
Cell.Cap = 6.6;    % Cell Capacity [Ah]
Cell.IR = 0.0015;   % Cell Internal Resistance [ohms]

%% Pack Calculations
Accum.S = floor(Pack.V ./ Cell.V);   % Cells in series required to reach desired Voltage
Accum.P = round(Pack.E ./ (Accum.S .* Cell.V .* Cell.Cap) .* 1000); % Cells in parallel required to reach desired Capacity

Accum.IR = Cell.IR .* Accum.S ./ Accum.P; % Total pack Internal Resistance [ohms]
Accum.C = Cell.m .* Accum.S .* Accum.P;   % Total cell heat capacity [J/K]

%% Endurance Import
Import = load('FE6Endurance.mat');
Endurance = Import.FE6Endurance;
Endurance(:,3) = Endurance(:,3) .* 100 ./ 60;
clear Import;

%% Heat Generation Calculations
Heatgen = (117.6 ./ Pack.V).^2 .* sum((Endurance(2:end,3)).^2 .* (Endurance(2:end,1) - Endurance(1:end-1,1))) .* Accum.IR;

Tdelt = Heatgen ./ Accum.C;

%% Local Functions
function Cell = importfile(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [8, Inf];
end

% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 28);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["DesiredPackCharacteristics", "VarName2", "VarName3", "VarName4", "VarName5", "Notes", "Calculatedfor20SOCat40CifDataisAvailable", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17", "VarName18", "VarName19", "VarName20", "VarName21", "VarName22", "VarName23", "VarName24", "VarName25", "VarName26", "VarName27", "VarName28"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["DesiredPackCharacteristics", "VarName2", "VarName3", "VarName4", "VarName5", "Notes", "Calculatedfor20SOCat40CifDataisAvailable", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17", "VarName18", "VarName19", "VarName20", "VarName21", "VarName22", "VarName23", "VarName24", "VarName25", "VarName26", "VarName27", "VarName28"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["DesiredPackCharacteristics", "VarName2", "VarName3", "VarName4", "VarName5", "Notes", "Calculatedfor20SOCat40CifDataisAvailable", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17", "VarName18", "VarName19", "VarName20", "VarName21", "VarName22", "VarName23", "VarName24", "VarName25", "VarName26", "VarName27", "VarName28"], "EmptyFieldRule", "auto");

% Import the data
Table = readmatrix(filename, opts);
Cell.Name = Table(:,1);
Cell.V = str2double(Table(:,6));
Cell.Cap = str2double(Table(:,7));
Cell.ContD = str2double(Table(:,8));
Cell.MaxD = str2double(Table(:,9));
Cell.IR = str2double(Table(:,10)) .* 1000;  % Cell Internal Resistance [mOhms -> Ohms]
end
