clear
clc
close all

% This model uses epsilon-NTU heat exchanger models for a SINGLE cross flow
% heat exchanger with CIRCULAR water channels with fins APPROXIMATED as
% anular. More work needs to be put into modeling of the multi pass aspect.
% The NTU seems to be far too low, which is what is leading to really low
% heat rejection.

% All equations reference the 165 heat transfer book, Fundementals of Heat
% and Mass Transfer, 7th edition. There is an article titled matecconf
% multipass crossflow in Drive under Literature/Powertrain/Cooling which
% will hopefully give more insight into modeling multipass radiators.

% Any questions message STEPHEN RIVEST on Slack

%% Define Givens
Tiw = 51;                   % Water inlet temperature
Tia = 30;                   % Air inlet temperature

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

Qw = 12./60000;             % Water volumetric flow (L/min -> m3/s)
mdotw = Qw.*rhow;           % Mass flow water (kg/s)
mdota = .15;                % Air mass flow from CFD (kg/s)
Qa = mdota./rhoa;           % Air volumetric flow (m3/s)

Cw = cw.*mdotw;             % Water heat capacity rate (J/sK)
Ca = ca.*mdota;             % Air heat capacity rate (J/sK)

% Calculate min/max heat capacity rate for all input Q
    % NOTE Cmin and Cmax will swap from at a critical Q which will appear
    % as a discontinuity in the plots
for i = 1:length(Cw)
   Cmin(i) =  min([Cw(i), Ca(i)]);      % Minimum heat capacity (J/sK)
   Cmax(i) = max([Cw(i), Ca(i)]);       % Maximum heat capacity (J/sK)
end

% These functions for Cmax/Cmin can only be used if Q is constant
% Cmax = max([Cw, Ca]);       % Maximum heat capacity rate (J/sK)
% Cmin = min([Cw, Ca]);       % Minimum heat capacity rate (J/sK)
Cr = Cmin./Cmax;            % Heat capacity rate ratio

%% Define Driven parameters
L = 0.244348;       % Core length (from CAD)
H = 0.15875;        % Core height (from CAD)
W = 0.041402;       % Core width (from CAD)
Di = .005;          % Water tube inner diameter (m)
Ri = Di./2;         % Water tube inner radius (m)
Do = 0.008128;      % Water tube outer didameter (m)
Ro = Do./2;         % Water tube outer radius (m)
tt = (Do - Di)/2;   % Water tube wall thickness (m)
tf = .00006;        % Fin thickness (m) PLACE HOLDER

Ntube = 8;          % Number of water tubes
Npass = 2;          % Number of passes per tube
Stube = H./Ntube;   % Spacing of water tubes (m)
PL = Stube./Do;     % Pitch of water tubes

Sfin = .001587;                         % Spacing of air fins
Nfin = L./Sfin;                         % Number of air fins
Nair = Nfin .* (Ntube+1);               % Number of air channels
Ha = Stube-Do;                          % Height of air channels
Wa = Sfin - tf;                         % Width of air channels
La = W;                                 % Length of air channels
Afin = Ha.*La - pi.* Di.^2./4;          % Area of one side of each fin
Df = sqrt(4.*Afin + Di.^2);             % Equiviland annular fin diameter (m)
Roc = Ro + tt/2;                        % Corrected annular find radius
Cb = (2.*Ri/m)./(Roc.^2 - Ri.^2);       % Fin constant

% Modified Bessel Functions
K1_Ri = besselk(1, m.*Ri);
I1_Roc = besseli(1, m.*Roc);
I1_Ri = besseli(1, m.* Ri);
K1_Roc = besselk(1, m.*Roc);
I0_Ri = besseli(0, m.*Ri);
K0_Ri = besselk(0, m.*Ri);

% Fin efficiency eq 3.96 (circular fin)
fin_effic = Cb .* (K1_Ri * I1_Roc - I1_Ri * K1_Roc) ./ (I0_Ri * K1_Roc + K0_Ri * I1_Roc);

%% Geometric Calculations
% Water Channels
Acsw = pi.*Ri.^2;               % Water cross sectional area (m2)
Pw = pi.*Di;                    % Water cross section perimeter (m)
Dhw = 4.*Acsw./(Pw);            % Water hydraulic diameter (m)
Aw = Pw.*L.*Ntube;              % Water area of conduction (m2)

% Air Channels
Acsa = Ha.*Wa;                  % Air cross sectional area (m2)
Pa = 2.*Wa+2.*Ha;               % Air cross sectional perimeter (m)
Dha = 4.*Acsa./Pa;              % Air hydraulic dameter (m)
Aa = Pa.*La.*Nair;              % Air area of conduction (m2)

% Fluid Velocities
Uinf = Qa ./ (L*W);             % Freestream air velocity
Uw = Qw./(Acsw.*Ntube);         % Water velocity
Ua = Qa./(Acsa.*Ntube.*Nfin);   % Air velocity
Uamax = Stube/(Stube-Do)*Uinf;  % Maximum air velocity (at tube choke)

% Fluid Reynolds numbers
Rew = rhow.*Uw.*Dhw./muw;       % Water Reynolds number
Rea = rhoa.*Uamax.*Dha./mua;    % Air Reynolds number

% Water friction factor
fw = .790 * log(Rew - 1.64).^(-2);
fa = .19;       % ESTIMATED FROM FIGURE 7.14 USING PL ~ 2.5 PROBABLY NOT NEEDED

%% Heat Transfer Coefficients
% Assume water is turbulent and fully developed
% Assume air is laminar and fully developed

% Water Heat Transfer Coefficient
% Prandtle number of water using Gnielinski correlation EQ 8.62
Prw = cw * muw ./ kw;               
% Nusselt number of water
Nuw = ((fw/8)*(Rew - 1000) * Prw) ./ (1+12.7*(fw/8)^.5 * (Prw^(2/3) - 1));
% Water convective heat transfer coefficient
hw = kw.*Nuw./Dhw;

% Air Heat Transfer Coefficient
% Zukauskas correlation EQ 7.58 assuming WHICH IS SUS Pr ~ Prs
Pra = ca * mua ./ ka;               % Prandtle number of air
m_a = .4;                           % Constant from table 7.5
C1 = .10;                           % Constant for Rea 10-10^2 from table 7.5
C2 = .80;                           % Correction factor for 2 rows of tubes from table 7.6
Nua = C1*C2*Rea.^m_a*Pra.^.36;      % Air Nuselt number EQ 7.58
ha = ka.*Nua./Dha;                  % Air convective heat transfer coefficient

%% Form Relationships for Parameters
% Find Overall Heat Transfer Coefficient
Rw = tt/(k*Aw);                 % Wall conduction resistance (K/W)
Rc = 1./(fin_effic*ha.*Aa);     % Cold side (air) convection resistance (K/W)
Rh = 1./(hw.*Aw);               % Hot side (water) convection resistance (K/W)

% Overall heat transfer coefficnent eq 11.1a
UA = 1/(Rc+Rh+Rw);

% Number of Transfer Units (NTU) eq 11.24
NTU = UA./(Cmin); %<======================= THIS NUMBER IS WAY TOO LOW!!!!

% APPROXIMATION INCOMING REMOVE BC ITS BS
% NTU = 1;

% Heat exchanger effectivness eq 11.32 (both fluids unmixed, cross flow)
epsilon = 1 - exp((1./Cr).*(NTU).^.22.*(exp(-Cr.*(NTU).^.78)-1));

% Attainable heat rejection eq 11.22
qatn = epsilon.*Cmin.*(Tiw - Tia);

%% Display Results
fprintf('Number of Transfer Units (NTU): %3.2f \n', NTU)
fprintf('Heat Exchanger Effectivness: %2.1f %% \n', epsilon*100)
fprintf('Fin Efficiency: %2.1f %% \n', fin_effic*100)
fprintf('Heat Rejection (W): %4.1f \n', qatn)