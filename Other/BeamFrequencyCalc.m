%%
clc; clear; close all;

m = 6.75;        % Motor Controller Mass [kg]
L = 28 * 0.0254; % Cross Member Length [in -> m]
E = 205 * 10^9;  % Young's Modulus of 4130 [Pa]
D = [0.5, 0.625, 0.75] * 0.0254;    % Tube Outer Diameter [in -> m]
t = [0.049, 0.058, 0.065] * 0.0254; % Tube Wall Thickness [in -> m]
[D,t] = meshgrid( D,t ); % Design Parameter Mesh
I = pi/64 * ( D.^4 - (D-2.*t).^4 ); % Bending Moment of Inertia [m^4]

%% Single Fixed-Fixed Beam, Central Point Load
k1 = (192*E*I) / (L^3); % Bending Stiffness [N/m]
w1 = 1/(2*pi) * sqrt( k1 / m ) % Bending Frequency [Hz] 

%% Four Fixed-Sliding Beams (Length limited to outside controller footprint)
L = 6.43 * 0.0254; % Length from node to controller footprint [in -> m]
k2 = 4*(6*E*I) / (L^3); % Bending Stiffness [N/m]
w2 = 1/(2*pi) * sqrt( k2 / m ) % Bending Frequency [Hz]