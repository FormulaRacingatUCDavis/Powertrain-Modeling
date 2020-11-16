clc; clear; close all;

% Zukauskas Pack Estimation
% Blake Christierson
% bechristierson@ucdavis.edu
% 6-17-2020

%% Import Graphs
Fan.Data = SanAceImport('San Ace 9HVA0812P1G001.csv');
f.Data = FrictionFactorImport('Zukauskas Friction Factor.csv');

%% Geometry & Inlet Setup
D = 0.018; % Diameter of Cells [m]
S = 0.020; % Pitch of Cells [m]

Nl = 20; % Longitudinal Rows of Cells [ ]
Nt = 5; % Transverse Rows of Cells [ ]

rho = 1.225; % Density of Air [kg/m^3]
mu = 1.85508 *10^-5; % Vicosity of Air [kg/m-s]

A = pi * (0.080/2)^2; % Inlet Area of Fan [m^2]
v = Fan.Data.Vdot ./ A; % Inlet Velocity of Air [m/s]

Pt = S/D; % Pitch to Diameter Ratio [ ]

%% Flow Calculations
vMax = S ./ (S-D) .* v; % Maximum Velocity [ ]

Re = rho .* vMax .* D ./ mu; % Reynold's Number

f.Lookup = FrictionFactorLookup( f.Data, Re, Pt );

dp = Nl .* (rho .* vMax.^2 ./ 2) .* f.Lookup; % Form Drag

%% Plotting
plot( Fan.Data.Vdot, Fan.Data.P, 'k' )
hold on
plot( Fan.Data.Vdot, dp, 'r' )

xlabel( 'Volumetric Flow Rate [m^3/s]' )
ylabel( 'Pressure Drop [Pa]' )

%% Local Functions
function [Data] = SanAceImport(filename, dataLines)
if nargin < 2
    dataLines = [1, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Var1", "Pa", "m3s"];
opts.SelectedVariableNames = ["Pa", "m3s"];
opts.VariableTypes = ["string", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Var1", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Var1", "EmptyFieldRule", "auto");

% Import the data
tbl = readtable(filename, opts);

%% Convert to output type
Data.P = tbl.Pa;
Data.Vdot = tbl.m3s;
end

function Data = FrictionFactorImport(filename, dataLines)
    if nargin < 2
        dataLines = [3, Inf];
    end

    % Setup the Import Options and import the data
    opts = delimitedTextImportOptions("NumVariables", 17);

    % Specify range and delimiter
    opts.DataLines = dataLines;
    opts.Delimiter = ",";

    % Specify column names and types
    opts.VariableNames = ["Var1", "Var2", "Var3", "Var4", "Var5", "Var6", ...
        "Var7", "Var8", "Var9", ...
        "Re1_25", "f1_25", "Re1_5", "f1_5", "Re2", "f2", "Re2_5", "f2_5"];
    opts.SelectedVariableNames = ["Re1_25", "f1_25", "Re1_5", "f1_5", ...
        "Re2", "f2", "Re2_5", "f2_5"];
    opts.VariableTypes = ["string", "string", "string", "string", ...
        "string", "string", "string", "string", "string", ...
        "double", "double", "double", "double", "double", "double", "double", "double"];

    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";

    % Specify variable properties
    opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var4", "Var5", "Var6", ...
        "Var7", "Var8", "Var9"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var4", "Var5", "Var6", ...
        "Var7", "Var8", "Var9"], "EmptyFieldRule", "auto");

    % Import the data
    tbl = readtable(filename, opts);

    % Convert to output type
    Data(1).Re = tbl.Re1_25( ~isnan(tbl.Re1_25) )';
    Data(1).f = tbl.f1_25( ~isnan(tbl.Re1_25) )';
    Data(1).Pt = 1.25 .* ones( size(Data(1).Re) );
    
    Data(2).Re = tbl.Re1_5( ~isnan(tbl.Re1_5) )';
    Data(2).f = tbl.f1_5( ~isnan(tbl.Re1_5) )';
    Data(2).Pt = 1.5 .* ones( size(Data(2).Re) );
    
    Data(3).Re = tbl.Re2( ~isnan(tbl.Re2) )';
    Data(3).f = tbl.f2( ~isnan(tbl.Re2) )';
    Data(3).Pt = 2 .* ones( size(Data(3).Re) );
    
    Data(4).Re = tbl.Re2_5( ~isnan(tbl.Re2_5) )';
    Data(4).f = tbl.f2_5( ~isnan(tbl.Re2_5) )';
    Data(4).Pt = 2.5 .* ones( size(Data(4).Re) );   
end

function f = FrictionFactorLookup(Data, Re, Pt)
    fp = zeros( length(Data), length(Re) );
    
    for i = 1 : length( Data )
       fp(i,:) = interp1( Data(i).Re, Data(i).f, Re , 'linear', 'extrap' ); 
    end
    
    if min([Data.Pt]) <= Pt && Pt <= max([Data.Pt])
        f = interp1( unique([Data.Pt]), fp, Pt, 'linear' );
    else
        f = interp1( unique([Data.Pt]), fp, Pt, 'pchip', 'extrap' );
    end
    f = f.';
end

function Nu = ZukauskasCorrelation( Re, Pr, Prs, Nl )
    % Constant Evaluation
    C1 = zeros( size(Re) );
    m = zeros( size(Re) );
    
    C1( 10 < Re & Re < 10^2) = 0.9;
    m( 10 < Re & Re < 10^2) = 0.4;
    
    C1( 10^2 <= Re & Re < 10^3) = 0.683;
    m( 10^2 <= Re & Re < 10^3) = 0.466;
    
    C1( 10^3 <= Re & Re < 2*10^5) = 0.35 .* (2/sqrt(3))^(1/5) ;
    m( 10^3 <= Re & Re < 2*10^5) = 0.6;
    
    C1( 2*10^5 <= Re & Re < 2*10^6) = 0.22 ;
    m( 2*10^5 <= Re & Re < 2*10^6) = 0.84;
    
    C2 = interp1( [1:9,20:30], ...
        [0.64 0.76 0.84 0.89 0.92 0.95 0.97 0.98 0.99, ones( size(20:30) )], ...
        Nl, 'pchip' );
    
    Nu = C1 .* C2 .* Re.^m .* Pr.^(0.36) .* (Pr./Prs).^(1/4);
end
