clc; clear; close all;

%% FE8 Accumulator Low DOF Design Scripts
% 1. Parameter Estimation
%   a. Inlet Temperature 
%   b. Resistance Estimation 
%       i.   Board Conductivity
%       ii.  Radial Cell Conductivity
%       iii. Fin Convection Coefficient
%       iv.  Contact Resistances? (Later)
% 2. Input Characterization 
% 3. Dynamic Modeling
% 4. Metric

% Adding All Supplemental Work to Path
fdir = fileparts( which( 'PowertrainCoolingWrapper.m' ) );
diridx = strfind( fdir, filesep );
wdir = fdir(1:diridx(end)-1);

addpath( genpath( wdir ) )

clear fdir diridx wdir

rng('default') % For Reproducability in Development

%% Drive Cycle Processing
Request.TorqueScaling = 100 ./ 60 .* 0.9; % Percent of Total Torque During Endurance []

Data(1) = RequestImport( 'Cropped_FE6_Endurance_Stint_1.csv' );
Data(2) = RequestImport( 'Cropped_FE6_Endurance_Stint_2.csv' );

Request = RequestCalculations( Request, Data ); % See Local Functions

clear Data

%% Environment Characterization
Environment.Ambient = ...
    load('C:\Users\maxbo\Downloads\Driveline_Modeling_8-16-2020_4_17\Driveline Modeling\Environmental Studies\FontanaTempHist-2020-15-8_10_30.mat');

Environment.Surface = ...
    load('C:\Users\maxbo\Downloads\Driveline_Modeling_8-16-2020_4_17\Driveline Modeling\Environmental Studies\NearSurfaceTempModel-2020-15-8_10_41.mat');

Environment.Inlet.Height = 5; % Height of Inlet Centroid [in]
Environment.Outlet.Height = 3; % Height of Outlet Centroid [in]

Environment.Inlet.FlowRate = 20; % Linear Flow Velocity [m/s]
Environment.Outlet.FlowRate = .613; % Volumetric Flow Rate [m^3/s]

Environment = EnvironmentCalculations( Environment );

%% Material Properties
Material.Air = table( (250:50:450)', ... % Temperature [K]
                      [1.3947; 1.1614; 0.9950; 0.8711; 0.7740], ... % Density [kg/m^3]
                      [1.006;  1.007;  1.009;  1.014;  1.021 ], ... % Specific Heat Capcity [kJ/kg-K]
                      [159.6;  184.6;  208.2;  230.1;  250.2 ] .* 1E-7, ... % Dynamic Viscosity [N-s/m^2]
                      [22.3;   26.3;   30.0;   33.8;   37.3  ] .* 1E-3, ... % Thermal Conductivity [W/m-K]
                      [0.720;  0.707;  0.700;  0.690;  0.686 ], ... % Prandtl Number [ ]
                      'VariableNames', {'T','rho','cp','mu','k','Pr'} );
    % Source: T. L. Bergman, A. S. Lavine, "Fundamentals of Heat and Mass Transfer," 8th Ed.
                  
Material.Copper = table( 8.9 * (1000), ... % Density [g/cc -> kg/m^3]
                         0.385, ... % Specific Heat Capacity [kJ/kg-K]
                         385, ... % Thermal Conductivity [W/m-K]
                         'VariableNames', {'rho','cp','k'} ); 
    % Source: http://www.matweb.com/search/datasheet.aspx?matguid=25cdd9bd3ebb4941be91cb0bee4cc661

Material.Aluminum = table( 2.7 * (1000), ... % Density [g/cc -> kg/m^3]
                           0.896, ... % Specific Heat Capacity [kJ/kg-K]
                           167, ... % Thermal Conductivity [W/m-K]
                           'VariableNames', {'rho','cp','k'} );
    % Source: http://www.matweb.com/search/datasheet_print.aspx?matguid=1b8c06d0ca7c456694c7777d9e10be5b

Material.Kapton = table( 0.8, ... % Thermal Conductivitiy [W/m-K]
                         'VariableNames', {'k'} );
    % Source: https://www.dupont.com/products/kapton-mt-plus.html
    
Material.Lucite = table( 0.2, ... % Thermal Conductivity [W/m-k]
                         'VariableNames', {'k'} );
    % Source: http://www.matweb.com/search/datasheet.aspx?bassnum=O1303&ckck=1
    
%% Accumulator Characterization
%%% Cell Characterization
Accumulator.Cell.Electrical.Configuration = '4p,28s,5p';

Accumulator.Cell.Electrical.Capacity  = 3 * (3600); % Cell Capacity [C]
    % Source: Sony VTC-6 Datasheet

%Accumulator.Cell.Electrical.Model = load('FE8_Battery_Analysis_VTC6_2020-08-14_19_16.mat');
    % Source: Cell Gaussian Process Model (Developed In-House by Conrad Rowling), Fit to Data from "MY-19 Cell Cycling" - Perin, 2019

Accumulator.Cell.Electrical.Model.IR = 0.02;
Accumulator.Cell.Electrical.Model.OCV = 3.6; % 3.416;

Accumulator.Cell.Dimensions.Form = 'Cylindrical'; % Cell Form Factor
Accumulator.Cell.Dimensions.Radius = 9.175 / (1000); % Cell Radius [m]
Accumulator.Cell.Dimensions.Length = 65.2 / (1000); % Cell Length [m]
Accumulator.Cell.Dimensions.Spacing = 20 / (1000); % Cell Spacing (Center-Center) [m]
 
Accumulator.Cell.Thermal.EntropyData = load( 'FormattedEntropyData.mat' ) ; % Percent of Heat from Entropic Processes []

Accumulator.Cell.Thermal.k_Radial = 0.2 .* (1 + 0.1*(rand(1)-0.5) ); % Radial Thermal Conductivity [W/m-K]
Accumulator.Cell.Thermal.k_Axial  = 30  .* (1 + 0.1*(rand(1)-0.5) ); % Axial Thermal Conductivity [W/m-K]
    % Source: "Thermal Conduction & Heat Generation Phenomena in Lion Cells" - Drake, 2014
    
Accumulator.Cell.Thermal.cp = 1.0 .* (1 + 0.2*(rand(1)-0.5) ); % Specific Heat Capacity [kJ/kg-K] 
    % Source: "Thermal Properties of Lithium Ion Battery & Components" - Maleki, et. al, 1998

Accumulator.Cell.Mass.m = 46.6 / (1000); % Cell Unit Mass [kg]

Accumulator = CellCalculations( Accumulator );

%%% Potting Characterization (Parker Lord Chemicals: SC252)
Accumulator.Potting.Mass.rho = 1.57 * (1000); % Potting Density [kg/m^3]
Accumulator.Potting.Thermal.cp = 1.596; % Specific Heat Capacity [kJ/kg-K]   

Accumulator.Potting.Dimensions.Volume = 0.000695 .* 5; % Potting Volume (CAD) [in^3 -> m^3]

Accumulator = PottingCalculations( Accumulator );

%%% Collector Characterization
Accumulator.Collector.Dimensions.Laminate = [1 2 3 2 4 2 3 2 1]; % Laminate Construction
    % 1 - Coverlay
    % 2 - Adhesive
    % 3 - Trace
    % 4 - Substrate

Accumulator.Collector.Dimensions.TraceDensity = 4 * (10.764) / (35.274); % [oz/ft^2 -> kg/m^2]

Accumulator.Collector.Dimensions.Thickness = [2 / (39370), ... % Coverlay Thickness
                   1 / (39370), ... % Adhesive Thickness
                   Accumulator.Collector.Dimensions.TraceDensity ./ Material.Copper.rho, ... % Trace Thickness
                   6 / (39370)]; % Substrate Thickness, [mils -> m]

Accumulator = CollectorResistanceCalculations( Accumulator, Material ); % See Local Functions

%%% Fin Characterization
Accumulator.Fin.Dimensions.Height = 0.25 * (0.0254); % Fin Height [in -> m]
Accumulator.Fin.Dimensions.Base = 0.1 * (0.0254); % Base Thickness[in -> m]
Accumulator.Fin.Dimensions.Thick = 0.1 * (0.0254); % Fin Thickness [in -> m]
Accumulator.Fin.Dimensions.Spacing = 0.15 * (0.0254); % Fin Spacing [in -> m]
    % Source: HeatSinkUSA.com

Accumulator.Fin.Dimensions.Width = 5.1 * (0.0254); % Heat Sink Width (z) [in -> m]
Accumulator.Fin.Dimensions.Length = 16.44 * (0.0254); % Fin Length (x) [in -> m]
    % Source: Pack CAD
    
Accumulator.Fin.Thermal.k = 200; %Fin Thermal Conductivity [W/m-K]
Accumulator.Fin.Thermal.cp = 0.9; %Specific Heat Capacity [kJ/kg-K]
    % Source: Matweb, for Aluminum 6063-T6
    
Accumulator = AccumulatorFinCalculations( Accumulator ); % See Local Functions

%% Motor Characterization
Motor.Dimensions.A = 367792.9E-6; % Surface Area [mm^2 -> m^2]

Motor.Dimensions.Length = 0.07; % Axial Length of Motor [m]
Motor.Dimensions.Radii = [0.085 0.092 0.1005 0.107]; % % Radii of Thermal Path [m]

Motor.Mass.m = 17.2; % Total Mass (w/o Potting) [kg]

Motor.Electrical.Efficiency = 85 / 100; % Motor Efficiency [ ]

Motor.Thermal.cp = 900 / (1000); % Specfic Heat Capacity (w/ Potting) [kJ/kg-K]

Motor.Thermal.eps = 0.8; % Surface Emissivity (Anodized Aluminum) {0.77-0.9) [ ]
Motor.Thermal.sigma = 5.6704E-8; % Stefan-Boltzmann Constant [W/m^2-K^4]

Motor.Thermal.k = [0.4, 50, 167]; % Radial Conductivities to Shell [W/m-K]
Motor.Thermal.h = 10; % Convective Heat Transfer Coefficient [W/m^2-K]

Motor = MotorCalculations( Motor );

%% Controller Characterization
Controller.Electrical.Efficiency = 89 / 100; % Controller Efficiency [ ]
% 896 J/kg-K
% 753 J/kg-K

% .0022 * 96 
% 2.2932
Controller.Thermal.Cp = 2.2932 * 896 + 753 * .0022 * 96;


%% Chassis Characterization
Chassis.Dimensions.Volume = 0.15; % Volume of Air in Rear Chassis [m^3]
Chassis.Dimensions.Area = 2.21; % Surface Area of Rear Chassis
Chassis.Dimensions.Thickness = 0.875 * (0.0254); % Laminate Thickness [in -> m]

Chassis.Thermal.k = 0.1;
Chassis.Thermal.cp = 0.1;

%% Storing Everything in Parameter Structure (Only for User-Defined MATLAB Functions)
Fields = fieldnames( Material );
for i = 1 : numel( Fields )
    Parameter.Material.(Fields{i}) = Material.(Fields{i}){:,:};
end

Parameter.Accumulator = Accumulator;
Parameter.Motor = Motor;
Parameter.Controller = Controller;

clear Fields i
%% Local Functions
%%% Request Calculations
function [Data] = RequestImport(filename, dataLines)
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

function Request = RequestCalculations( Request, Data )
    dt = Data(1).Time(2) - Data(1).Time(1);

    %%% Concatenating Data Series with Driver Change Period
    Request.Raw.Time = [ linspace( 0, 0.99*dt, 10)'; Data(1).Time + dt ; ... % First Stint
                       (Data(1).Time(end) + 2*dt : dt : Data(1).Time(end) + 2*dt + 3*60)'; ... % Driver Switch (Turned Off, Not Recorded)
                       Data(2).Time + Data(1).Time(end) + 3*dt + 3*60 ]; % Second Stint, Raw Time [s]

    Request.Raw.Voltage = [ Data(1).Voltage(1) .* ones(10, 1); Data(1).Voltage; ... % First Stint
                          ones( size( (Data(1).Time(end) + dt : dt : Data(1).Time(end) + dt + 3*60)' ) ) .* Data(1).Voltage(end); ... % Driver Switch (Turned Off, Not Recorded)
                          Data(2).Voltage ]; % Second Stint, Raw Voltage [V] 

    Request.Raw.Current = [ zeros(10,1); Data(1).Current; ... % First Stint
                          zeros( size( (Data(1).Time(end) + dt : dt : Data(1).Time(end) + dt + 3*60)' ) ); ... % Driver Switch (Turned Off, Not Recorded)
                          Data(2).Current ]; % Second Stint, Raw Current [A]

    Request.Raw.OverVoltage = [ zeros(10,1); Data(1).OverVoltage; ... % First Stint
                              zeros( size( (Data(1).Time(end) + dt : dt : Data(1).Time(end) + dt + 3*60)' ) ); ... % Driver Switch (Turned Off, Not Recorded)
                              Data(2).OverVoltage ]; % Second Stint, Over Voltage Fault [ ]

    Request.Raw.OverPower = [ zeros(10,1); Data(1).OverPower; ... % First Stint
                            zeros( size( (Data(1).Time(end) + dt : dt : Data(1).Time(end) + dt + 3*60)' ) ); ... % Driver Switch (Turned Off, Not Recorded)
                            Data(2).OverPower ]; % Second Stint, Over Power Fault [ ]

    Request.Raw.Power = Request.Raw.Voltage .* Request.Raw.Current; % Raw Power [W]

    %%% Scaling Current
    Request.Scaled = Request.Raw;
    Request.Scaled.Current = Request.Raw.Current .* Request.TorqueScaling; % Scaled Current [A]
    
    %%% Simulation Input
    Request.Input.Current = timeseries( Request.Scaled.Current, Request.Scaled.Time );
    
end

%%% Environment Calculations
function [Environment] = EnvironmentCalculations( Environment )
    % Reducing Structure Heirarchy
    Environment.Ambient = Environment.Ambient.TempDist;
    Environment.Surface = Environment.Surface.Model;
    
    % Sampling Ambient Distribution
    Environment.Temp = (random( Environment.Ambient ) - 32) .* 5/9; % Ambient Temperature Sample [F -> C]
    
    % Scaling Using Surface Data
    Environment.Surface.Form = eval( Environment.Surface.Form ); % Convert String to Anonymous Function
    
    Environment.Surface.Scale = @(z) Environment.Surface.Form( Environment.Surface.Beta, z ) ./ ...
        Environment.Surface.Form( Environment.Surface.Beta, 60 );
    
    Environment.Inlet.Temp = Environment.Temp .* ...
        Environment.Surface.Scale( Environment.Inlet.Height );
    
    Environment.Outlet.Temp = Environment.Temp .* ...
        Environment.Surface.Scale( Environment.Outlet.Height );
end

%%% Accumulator Calculations
function Accumulator = CellCalculations( Accumulator )
    %%% Electrical Calculations
    % Accumulator.Cell.Electrical.Model = Accumulator.Cell.Electrical.Model.RESULTS;
    
    % Cell Configuration Calculations
    Accumulator.Cell.Electrical.NCells = eval( strrep( strrep( strrep( Accumulator.Cell.Electrical.Configuration(1:end-1), 'p', '*' ), 's', '*' ), ',', '' ) );
    
    Config = strsplit( Accumulator.Cell.Electrical.Configuration, ',' );
    
    Accumulator.Cell.Electrical.NParallel = 1;
    Accumulator.Cell.Electrical.NSeries = 1;
    
    for i = 1:numel(Config)
        if strcmpi( Config{i}(end), 'p' )
            Accumulator.Cell.Electrical.NParallel = Accumulator.Cell.Electrical.NParallel * str2double(Config{i}(1:end-1));
        else
            Accumulator.Cell.Electrical.NSeries = Accumulator.Cell.Electrical.NSeries * str2double(Config{i}(1:end-1));
        end
    end
    
    %%% Thermal Calculations
    Accumulator.Cell.Thermal.EntropyData = Accumulator.Cell.Thermal.EntropyData.EntropyData;
    
    Accumulator.Cell.Thermal.R_Axial = 7 .* Accumulator.Cell.Dimensions.Length ./ ...
        ( 24*pi .* Accumulator.Cell.Thermal.k_Axial .* Accumulator.Cell.Dimensions.Radius.^2 );
    
    Accumulator.Cell.Thermal.R_Radial = 3 ./ ...
        ( 8 .* pi .* Accumulator.Cell.Thermal.k_Radial .* Accumulator.Cell.Dimensions.Length);
end

function Accumulator = PottingCalculations( Accumulator )
    Accumulator.Potting.Mass.m = Accumulator.Potting.Mass.rho .* Accumulator.Potting.Dimensions.Volume;
end

function Accumulator = CollectorResistanceCalculations( Accumulator, Material )
    Accumulator.Collector.Thermal.Resistance = 0;
    for i = 1 : length( Accumulator.Collector.Dimensions.Laminate )
        switch Accumulator.Collector.Dimensions.Laminate(i)
            case 1
                Accumulator.Collector.Thermal.Resistance = Accumulator.Collector.Thermal.Resistance + ...
                    Accumulator.Collector.Dimensions.Thickness(1) / Material.Kapton.k;  
            case 2
                Accumulator.Collector.Thermal.Resistance = Accumulator.Collector.Thermal.Resistance + ...
                    Accumulator.Collector.Dimensions.Thickness(2) / Material.Lucite.k;
            case 3
                Accumulator.Collector.Thermal.Resistance = Accumulator.Collector.Thermal.Resistance + ...
                    Accumulator.Collector.Dimensions.Thickness(3) / Material.Copper.k;
            case 4
                Accumulator.Collector.Thermal.Resistance = Accumulator.Collector.Thermal.Resistance + ...
                    Accumulator.Collector.Dimensions.Thickness(4) / Material.Kapton.k;
        end
    end
    Accumulator.Collector.Thermal.Resistance 
end

function Accumulator = AccumulatorFinCalculations( Accumulator )
    Accumulator.Fin.Dimensions.N = ( Accumulator.Fin.Dimensions.Width + Accumulator.Fin.Dimensions.Spacing )...
        ./ ( Accumulator.Fin.Dimensions.Spacing + Accumulator.Fin.Dimensions.Thick);
    
    Accumulator.Fin.Dimensions.Abase = Accumulator.Fin.Dimensions.Spacing .* Accumulator.Fin.Dimensions.Length ...
        .* Accumulator.Fin.Dimensions.N;
    
    Accumulator.Fin.Dimensions.Afin = 2* ( Accumulator.Fin.Dimensions.Length .* Accumulator.Fin.Dimensions.Height );
end

%%% Motor Calculations
function Motor = MotorCalculations( Motor )
    Motor.Thermal.R_Radial = 0;
    for i = 1 : numel( Motor.Thermal.k )
       Motor.Thermal.R_Radial = Motor.Thermal.R_Radial + ...
           log( Motor.Dimensions.Radii(i+1) ./ Motor.Dimensions.Radii(i) ) ./ ...
           (2*pi .* Motor.Thermal.k(i) .* Motor.Dimensions.Length );
    end
end

%%% Controller Calculations
function Controller = ControllerCalculations( Controller )

end