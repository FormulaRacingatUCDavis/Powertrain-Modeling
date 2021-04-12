clc; clear; close all;  

%% 

%Output:
%
%Author(s):
%Joseph Sanchez (jomsanchez@ucdavis.edu) [Feburary 2021 - Present] 

%% Vehicle Parameters 
    
Parameter.TrackWidth = 48*(25.4 / 1000);
Parameter.Length = 60/39.3700787;
Parameter.Mass = 600 / 2.20462262;
Parameter.PercentFront = 0.47;
Parameter.b = Parameter.Length * Parameter.PercentFront;

Parameter.Radius.Effective = 20.6097;
Parameter.Radius.Rotor = 1; %Change 
Parameter.WheelInertia = 1; %Change 

Parameter.DifferentialEffeciency = 1;%Change 
Parameter.BrakePreload = 1;%Change
Parameter.DrivePreload = 5;%Change
Parameter.AxleDampening = 1; %Change





%Structrue of Parameters 

%% Tire Model Filt Pathing

%Directory.Tool = fileparts( matlab.desktop.editor.getActiveFilename );

%Path = strfind( Directory.Tool,'GitHub' ) + 5; %Will Count up to GitHub 'G' add 5 for 'itHub'

%Directory.Folder = [Directory.Tool(1:max(Path)), '\Tire-Modeling'];

%Directory.Data      = [Directory.Folder, '\Data'];
%Directory.Model     = [Directory.Folder, '\Models'];
%Directory.Media     = [Directory.Folder, '\Media'];
%Directory.Main      = [Directory.Folder, '\TireModelingFittingMain.m'];
%Directory.Resources = [Directory.Folder, '\MATLAB-Resources'];

%Directory.FRUCDTire = [Directory.Model, '\FRUCDTire.m'];

%addpath( genpath( Directory.Tool      ) );
%addpath( genpath( Directory.Data      ) );
%addpath( genpath( Directory.Resources ) );
%addpath( genpath( Directory.Model ) );
%addpath( genpath( Directory.Media ) );
%addpath( genpath( Directory.Main ) );
%addpath( genpath( Directory.FRUCDTire ) );


%% Run The Model 

Out = sim('PowetrainModel.slx');
Out1 = sim('DifferentialModel.m');



