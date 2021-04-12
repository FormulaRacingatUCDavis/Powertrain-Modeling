function [DriveTorque, DeltaTorque] = DifferentialModel(SpinRate, AxleTorque, BrakePreload, DrivePreload )
%% DifferentialModel - Drive Torque and Delta Torque Calculations 
% Estimates the diffrential's drive torque and delta torque from the
% spin rate, axle torque, and a set of parameters. To avoid differential
% algebaric equations the relaxtion technique was applied to delta torque.
%
% Inputs:
%   AxleTorque          - (1,1 numeric) Axle Drive Torquw                   {tau_A}   [Nm]
%   SpinRate            - (n,1 numeric) Rear Wheel Spin Rate                {omega}   [rad/s]
%   BrakePreload        - (1,1 numeric) Brake Torque Preload                {tau_B}   [Nm]
%   DrivePreload        - (1,1 numeric) Drive Torque Preload                {tau_D}   [Nm]
%   RampRadius          - (1,1 numeric) Ramp Radius                         {r_o}     [m]
%   DriveRampAngle      - (1,1 numeric) Drive Ramp Angle                    {sigma_D} [deg]
%   BrakeRampAngle      - (1,1 numeric) Brake Ramp Angle                    {sigma_B} [deg]
%   ClutchOuterRadius   - (1,1 numeric) Clutch Pack Outer Radius            {r_o}     [m] 
%   ClutchInnerRadius   - (1,1 numeric) Clutch Pack Inner Radius            {r_i}     [m]
%   ClutchCoeffFriction - (1,1 numeric) Clutch Pack Coefficient of Friction {mu_c}    []
%   NumbFrictionSurface - (1,1 numeric) Number of Friction Surfaces         {N}       []
% State: 
%   DeltaSpinRate - (1,1 numeric) Delta of Rear SpinRates {Delta*omega} [rad/s]
%
% Output:
%   DriveTorque - (1,1 numeric) Drive Torque        {tau_D}     [Nm]
%   DeltaTorque - (n,1 numeric) Differential Torque {Delta*tau} [Nm]

%Note:
%delT = (Ta/rramp) *.cot(sigma_d)).*(2/3 * ((ro^3 - ri ^3) / (ro^2-ro^2))(mu_c *N)*(abs(DeltaOmega)*tanh(4abs(DeltaOmega)
%Is not implemented. 

%Author(s):
%Joseph Sanchez (jomsanchez@ucdavis.edu)

%Last Updates: 4-Apr-2021

%%% Test Case 

if nargin == 0 
    SpinRate     = 10*ones(1,4);
    AxleTorque   = 15;
    BrakePreload = 1;
    DrivePreload = 5; 

    [DriveTorque, DeltaTorque] = DifferentialModel(SpinRate, AxleTorque,...
        BrakePreload, DrivePreload );
    
        fprintf('Executing WheelSpeed() Test Case: \n');
        for i = 1:numel(DriveTorque)
            fprintf('   Instance %i: \n', i);
            fprintf('      DriveTorque = %5.2f [Nm] \n', DriveTorque(i));
            
        end 
        
            return;
end 
%% Differential Spin Rate
DeltaSpinRate = SpinRate(3) - SpinRate(4);

%% Differential Torque 
DriveTorque = zeros(1,4);

if (AxleTorque > BrakePreload) && (AxleTorque < DrivePreload) %Is Locked 
    DeltaTorque = ( AxleTorque*0.5)*(tanh(100*DeltaSpinRate)); %Insert delT here once obtained parameter values   
else 
    DeltaTorque = ( AxleTorque*0.5)*(tanh(4*DeltaSpinRate));   
end

DriveTorque(3) = 0.5*AxleTorque - sign(DeltaSpinRate)*DeltaTorque; 
DriveTorque(4) = 0.5*AxleTorque + sign(DeltaSpinRate)*DeltaTorque;


end