clc; clear; close all;

%% Parameters
m  = 270  ; % Vehicle Mass [kg]
pf = 0.5  ; % Percent Static Front Distribution [ ]
h  = 0.267; % C.G. Height [m]
L  = 1.625; % Wheelbase [m]
g  = 9.81 ; % Gravitational Acceleration [m/s^2]

Fx = @(Fz) -( 2.793.*Fz - 0.0008166.*Fz.^2 ); % Perfect Braking Tire Model

b = L*pf;

%% System Dynamics
v0 = [50, 30, 30, 30];
vf = [10, 10, 10, 10];

% Solve Algebraic System for Constant Deceleration
a = fzero( @(a) 2 * ( Fx( ( (m*g*b-m*a*h)/L ) / 2 ) + Fx( ( m*g - (m*g*b-m*a*h)/L ) / 2 ) ) / m - a, 0 );

% Normal Forces
Fzf = ( (m*g*b-m*a*h)/L );
Fzr = m*g - Fzf;

% Braking Forces
Fxf = 2*Fx(Fzf/2);
Fxr = 2*Fx(Fzr/2);

%% Braking Energy
t = (vf-v0)./a  ; % Time of Braking Event [s]
d = (v0+vf).*t/2; % Braking Distance [m]
Ef = abs(Fxf) .* d; % Front Braking Energy [J]
Er = abs(Fxr) .* d; % Rear Braking Energy [J]

Erg = sum(Er)*13 / 3.6e6 % Regenerative Energy Available on Rear Axle [kWh]