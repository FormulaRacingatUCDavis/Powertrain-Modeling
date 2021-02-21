clc
clear
close all

%% Define Inputs
Qw = 12;                                % Water volumetric flow (liters per min)
Qw = Qw./60000;                         % Water volumetric flow (m3/s)

Tia = 35;                               % Air inlet temp (C)
mdota = .085;               % Mass flow air (kg/s)

% Number of Radiators
Nrad = 2;

% Driving parameters
Nplate = 18;                % Number of water channels
L = .4572;                  % Length of water channels (m) KYLE
Ww = .0246;                 % Water channel width (m) KYLE
Hw = .001562;               % Water channel height(m) KYLE
Sfin = .001587;             % Air fin spacing (m)
t = 150E-6;                 % Fin and microchannel wall thickness (m)

%% Define Givens
muw = 1.0518E-3;            % Water dynamic viscoticy (N*s/m2)
mua = 18.08E-6;             % Air dynamic viscoticy (N*s/m2)
cw = 4180;                  % Water heat capacity (J/KgK)
ca = 1006;                  % Air heat capacity (J/KgK)
kw = .59803;                % Water thermal conductivity (W/mK)
ka = .02572;                % Air thermal conductivity (W/mK)
k = 237;                    % Aluminum thermal conductivity (W/mK)
rhow = 997;                 % Water density (kg/m3)
rhoa = 1.225;               % Air density (kg/m3)
m = 21.3;                   % Aluminum

mdotw = Qw.*rhow;           % Mass flow water (kg/s)

Cmax = ca.*mdota;            % Minimum heat capacity (J/sK)
Cmin = cw.*mdotw;            % Maximum heat capacity (J/sK)
Cr = Cmin./Cmax;             % Heat capacity ratio
Cw = cw.*mdotw;              % Water heat capacity (J/sK)
Ca = ca.*mdota;              % Air heat capacity (J/sK)

%% Steady State Heat Generation Computation
maxstep = 1000;             % Maximum step stopping criteria
res = 1;                    % Residual initialization
i = 1;                      % Counter initialization

qgen = 2600./Nrad;          % Powertrain heat production per rad(W)
Tc(1) = 35;                 % Cold side temperature initial condition
Th(1) = 35;                 % Hot side temperature initial condition

while res > 1E-4
    Th(i) = qgen./Cw + Tc(i);       % Radiator hot side temp (C)
    [qatn(i), epsilon(i), NTU(i), H, W, A, Ua, Cmin] = RadSize(Nplate, L, Ww, Hw, Sfin, t, Qw, mdota, Th(i), Tia);
    Tc(i+1) = -qatn(i)./Cw +Th(i);
    res = abs(Tc(i)-Tc(i+1));
    i = i+1;
    if i == maxstep
        break
    end
end
Th(i) = qgen./Cw + Tc(i);           % Radiator hot side temp (C)

figure
hold on
plot([1:1:i], Tc)
plot([1:1:i], Th)
xlabel('Time (s)')
ylabel('Temperature (C)')
legend('Cold Temp','Hot Temp')
title('Waterloop Steady State Heat Production')

fprintf('Final Hot Side Temperature: %3.2f \n', Th(end))
fprintf('Final Cold Side Temperature: %3.2f \n', Tc(end))