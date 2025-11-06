%% Clean up
clearvars; close all; clc;

%% Motor & vehicle parameters 
M_torque = 220;             % [N·m] max motor torque (torque cap)
Power    = 80;              % [kW] motor power (constant-power region)
KMV      = 12;              % [RPM/V] motor speed constant
Max_V    = 504;             % [V] max DC link voltage
M_RPM    = KMV * Max_V;     % [RPM] motor max speed (no-load)
initial_v = 0;              % [m/s] initial vehicle speed

tire_diameter_in = 16;      % [in] tire diameter
FDR               = 2.91;   % final drive ratio
eta_drivetrain    = 0.92;    
m_kg              = 280;     

%% Derived geometry
tire_radius_m = (tire_diameter_in * 0.0254) / 2;    % [m]

%% Torque & power maps vs RPM 
RPM    = 0:M_RPM;                                        % [RPM], includes 0
Torque = 9.549297 * (Power*1000) ./ max(RPM, 1);         % [N·m]
Torque = min(Torque, M_torque);                          % clamp to max torque
PowerMV = (Torque .* RPM) / 9.549297;                    % [W] = T[Nm]*RPM / 9.5493

%% RPM-limited (no-load) top speed
wheel_RPM_max    = M_RPM / FDR;
wheel_omega_max  = wheel_RPM_max * 2*pi/60;              % [rad/s]
v_max_mps        = wheel_omega_max * tire_radius_m;      % [m/s]
v_max_kmh        = v_max_mps * 3.6;
v_max_mph        = v_max_mps * 2.23694;
fprintf('RPM-limited vmax (no resistances): %.1f km/h (%.1f mph)\n', v_max_kmh, v_max_mph);

%% Speed ramp integration (ignore rolling resistance, aero, and losses)
dt   = 0.01;               % [s] integration step
tEnd = 60;                 % [s] simulate up to this time (or until RPM limit)
N    = ceil(tEnd/dt) + 1;

t = zeros(N,1);
v = zeros(N,1);            % [m/s]
v(1) = initial_v;

for k = 1:N-1
    % Current motor RPM from current vehicle speed
    wheel_omega = v(k) / tire_radius_m;                        % [rad/s]
    motor_RPM   = (wheel_omega * 60/(2*pi)) * FDR;             % [RPM]

    % Stop at RPM limit
    if motor_RPM >= M_RPM
        t = t(1:k); v = v(1:k);
        break
    end

    % Available motor torque at this RPM 
    Tm = interp1(RPM, Torque, motor_RPM, 'linear', 'extrap'); 
    if Tm < 0, Tm = 0; end

    % Wheel traction force 
    Twheel = Tm * FDR * eta_drivetrain;                       
    F_trac = Twheel / tire_radius_m;                          

    % Acceleration and integration
    a = F_trac / m_kg;                                         
    v(k+1) = v(k) + a*dt;
    t(k+1) = t(k) + dt;

    % Early stop if velocity change becomes negligible
    if k > 200 && abs(v(k+1)-v(k)) < 1e-6
        t = t(1:k+1); v = v(1:k+1);
        break
    end
end

%% Plot: Speed ramp (km/h vs s)
figure(2); clf
plot(t, v*3.6, 'LineWidth', 2); grid on
xlabel('Time [s]'); ylabel('Speed [km/h]');
title('Speed Curve (Motor)');

%% Plot: Motor torque & power vs RPM
figure(1); clf
yyaxis left
plot(RPM, Torque, 'b', 'LineWidth', 2);
ylabel('Torque [N·m]');
ylim([0, M_torque*1.05]);

yyaxis right
plot(RPM, PowerMV/1000, 'r', 'LineWidth', 2);
ylabel('Power [kW]');
ylim([0, Power*1.05]);

grid on
title('Motor Torque and Power vs RPM');
xlabel('RPM');
legend('Torque','Power','Location','best');
