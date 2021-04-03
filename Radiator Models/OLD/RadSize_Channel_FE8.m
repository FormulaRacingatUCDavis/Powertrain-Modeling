function [qatn, epsilon, NTU, H, W, A, Ua, Cmin] = RadSize(Nplate, L, Ww, Hw, Sfin, t, Qw, mdota, Tiw, Tia)
%RadSize Determines radiator heat rejection using NTU method

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

mdotw = Qw.*rhow;            % Mass flow water (kg/s)
% mdota = Qa.*rhoa;            % Mass flow air (kg/s)
Qa = mdota./rhoa;

Cw = cw.*mdotw;             % Water heat capacity (J/sK)
Ca = ca.*mdota;             % Air heat capacity (J/sK)
for i = 1:length(Cw)
   Cmin(i) =  min([Cw(i), Ca(i)]);      % Minimum heat capacity (J/sK)
   Cmax(i) = max([Cw(i), Ca(i)]);       % Maximum heat capacity (J/sK)
end
% Cmax = max([Cw, Ca]);       % Maximum heat capacity (J/sK)
% Cmin = min([Cw, Ca]);       % Minimum heat capacity (J/sK)
Cr = Cmin./Cmax;            % Heat capacity ratio

%% Define Driven parameters
Splate = 8*(Sfin-2*t) + Hw + 2*t;   % Water channel spacing (m) (from air AR = 8)
Nfin = L./Sfin;                     % Number of fins
Nair = Nfin.*Nplate;                % Number of air channels
Ha = Splate-(Hw+2*t);               % Air fin height(m)
Wa = Sfin-(2*t);                    % Air fin width (m)
La = Ww + 2*t;                      % Air channel length (m)

%% Geometric Calculations
% Radiator Dimensions
H = (Nplate-1).*(Splate) + Ha;  % Height of one radiator (m)
W = La;                         % Width of one radiator (m) (Same as air channel length)
A = L.*Nplate.*Splate;          % Cross section of one radiator (m2)

% Water Channels
Acsw = Ww.*Hw;                  % Water cross sectional area (m2)
Pw = 2.*Ww+2.*Hw;               % Water cross section perimeter (m)
Dhw = 4.*Acsw./(Pw);            % Water hydraulic diameter (m)
Aw = 2*Ww.*L.*Nplate;           % Water area of conduction (m2)

% Air Channels
Acsa = Ha.*Wa;                  % Air cross sectional area (m2)
Pa = 2.*Wa+2.*Ha;               % Air cross sectional perimeter (m)
Dha = 4.*Acsa./Pa;              % Air hydraulic dameter (m)
Aa = Pa.*La.*Nair;              % Air area of conduction (m2)

% Fluid Velocities
Uw = Qw./(Acsw.*Nplate);        % Water velocity
Ua = Qa./(Acsa.*Nplate.*Nfin);  % Air velocity

% Fluid Reynolds numbers
Rew = rhow.*Uw.*Dhw./muw;
Rea = rhoa.*Ua.*Dha./mua;

%% Heat Transfer Coefficients
% Assume water is laminar and fully developed
% Assume air is laminar and fully developed

% Water Heat Transfer Coefficient
% Assume W/H = infinity
Nuw = (8.23+7.54)./2;               % Water Nuselt number
hw = kw.*Nuw./Dhw;                  % Water convective heat transfer coefficient

% Air Heat Transfer Coefficient
% Assume W/H = 8
Nua = (6.49+5.60)./2;               % Air Nuselt number
ha = ka.*Nua./Dha;                  % Air convective heat transfer coefficient

%% Required Heat Rejection
% Calculate fin efficiency 
Lf = (Splate-(Hw-2*t))/2;           % Effective fin length
Wf = Ww+2*t;                        % Fin width
Af = 2*(Wf*Lf);                     % Fin area
fin_effic = tanh(m*Lf)/(m*Lf);      % Fin efficiencty

%% Form Relationships for Parameters
% Find Overall Heat Transfer Coefficient
Rw = t/(k*Aw);                  % Wall conduction resistance
Rc = 1./(fin_effic*ha.*Aa);     % Cold convection resistance
Rh = 1./(hw.*Aw);               % Hot convection resistance
UA = 1./(Rc+Rh+Rw);          % Overall heat transfer coefficnent * area

% Number of Transfer Units
NTU = UA./Cmin;

% Attainable heat exchanger effectivness
epsilon = 1 - exp((1./Cr).*(NTU).^.22.*(exp(-Cr.*(NTU).^.78)-1));

% Attainable heat rejection
qatn = epsilon.*Cmin.*(Tiw - Tia);
end