function [DriveTorque, MotorSpeed] = RWDPowertrainOpenDiff( Throttle, WheelSpeed, ...
    DriveRatio, TorqueMap )
% Calculates drive torques from a simplified rear wheel drive single motor
% open differential powertrain model.
% 
% Inputs:
%   Throttle       - (n,1 numeric) Throttle Request        {%_T}     [ ]   
%   SpinRate      - (n,4 numeric) Wheel Spin Rate         {omega}   [rad/s]
%   DriveRatio    - (n,1 numeric) Final Drive Ratio       {G_{FDR}} [ ]
%   TorqueMap     - (n,1 struct)  Motor Torque Map
%       .Omega    - (m,k numeric) Motor Speed Lookup      {omega_m} [rad/s]
%       .Throttle - (m,k numeric) Throttle Request Lookup {%_T}     [ ]
%       .Torque   - (m,k numeric) Motor Torque Lookup     {tau_m}   [N-m]
% 
% Outputs:
%   DriveTorque   - (n,4 numeric) Drive Torques           {tau_D}   [N-m]
%
% Notes:
% 
%
% Author(s): 
% Blake Christierson (bechristierson@ucdavis.edu) [Sep 2018 - Jun 2021] 
%
% Last Updated: 01-Jun-2021

%% Test Case
if nargin == 0
    Throttle = 0.5; 
    WheelSpeed = 150.*ones(1,4);
    DriveRatio = 3.5;
    
    TorqueMap.Omega    = linspace(0,7000,50); % Motor Speed [rpm]
    TorqueMap.Throttle = linspace(0,1   ,10); % Throttle    [ ]
    
    [TorqueMap.Omega, TorqueMap.Throttle] = meshgrid( TorqueMap.Omega, TorqueMap.Throttle );
    
    Torque0 = 155;
    Omega0  = 3200;
    OmegaF  = 6000;
    
    TorqueClipping = @(Omega) Torque0 - Torque0 ./ (2*(OmegaF-Omega0)) .* ...
        (Omega - Omega0);
    
    TorqueMap.Torque = TorqueMap.Throttle .* 155;
    TorqueMap.Torque( TorqueMap.Torque > TorqueClipping(TorqueMap.Omega) ) = ...
        TorqueClipping( TorqueMap.Omega( TorqueMap.Torque > TorqueClipping(TorqueMap.Omega) ) );
    
    TorqueMap.Omega = TorqueMap.Omega .* 2*pi/60;
    
    [DriveTorque, MotorSpeed] = RWDPowertrainOpenDiff( Throttle, WheelSpeed, ...
        DriveRatio, TorqueMap ) %#ok<NOPRT>

    return
end

%% Computation
%%% Motor Speed (Open Differential)
MotorSpeed = mean( WheelSpeed(:,3:4), 2 ) .* DriveRatio;

%%% Motor Torque Lookup
MotorTorque = interp2( TorqueMap.Omega, TorqueMap.Throttle, TorqueMap.Torque, ...
    MotorSpeed, Throttle );

%%% Drive Torque (Open Differential)
DriveTorque = zeros( size( WheelSpeed ) );
DriveTorque(:,3:4) = MotorTorque .* DriveRatio / 2;

end

