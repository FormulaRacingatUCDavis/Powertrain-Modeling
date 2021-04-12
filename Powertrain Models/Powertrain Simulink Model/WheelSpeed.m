function [InputTorque, SpinAcc] = WheelSpeed( SpinRate,DriveTorque, ...
    BrakeTorque, TractiveForce, EffRadius, Inertia, Damping, DifferentialEffec )

%% WheelSpeed - Wheel Torque Balance & Spin Acceleration
% Calculates brake or drive torque required for steady state applications
% or the spin acceleration for transient applications.
% 
% Inputs:
%   SpinRate      - (n,1 numeric) Wheel Spin Rate       {omega} [rad/s]
%   DriveTorque   - (n,1 numeric) Drive Torque          {tau_D} [N-m]
%   BrakeTorque   - (n,1 numeric) Brake Torque          {tau_B} [N-m]
%   TractiveForce - (n,1 numeric) Tractive Force        {F_x}   [N]
%   EffRadius     - (n,1 numeric) Tire Effective Radius {r_e}   [m]
%   Inertia       - (n,1 numeric) Spin Inertia          {I_s}   [kg-m^2]
%   Damping       - (n,1 numeric) Spin Damping          {b_s}   [N-m-s/rad]
% 
% Outputs:
%   InputTorque - (n,1 numeric) Axle Input Torque      {tau_{D|B}} [N-m]
%   SpinAcc     - (n,1 numeric) Tire Spin Acceleration {omega_dot} [rad/s^2]
%
% Notes:
%   Steady state computation will be enacted if BrakeTorque or DriveTorque
%   arguments are left empty.
%
% Author(s): 
% Blake Christierson (bechristierson@ucdavis.edu) [Sep 2018 - Jun 2021] 
%Joseph Sanchez (jomsanchez@ucdavis.edu) [Sep 2020 - June 2022]
% Last Updated: 10-Apr-2021

%%% Test Cases
if nargin == 0
    %%% Test Inputs
    SpinRate = 80*ones(1,4); 
    
    DriveTorque = 20*ones(1,4); 
    BrakeTorque = 0*ones(1,4); 
    
    TractiveForce = 300*ones(1,4);
    EffRadius     = 0.19;
    
    Inertia = 1;
    Damping = 1;
    DifferentialEffec = 1; 
 
    [InputTorque, SpinAcc] = WheelSpeed( SpinRate, DriveTorque, BrakeTorque, ...
        TractiveForce, EffRadius, Inertia, Damping, DifferentialEffec);

    fprintf('Executing WheelSpeed() Test Case: \n');
    for i = 1:numel(SpinAcc)
        fprintf('   Instance %i: \n', i);
        fprintf('      omega_dot = %5.2f [rad/s^2] \n', SpinAcc(i));

    end
    
     return;   
end

n = numel(SpinRate);
SpinAcc = zeros(1,n);

for i = 1:n

SpinAcc(1:i) = (DifferentialEffec*DriveTorque(1:i) - ...
    TractiveForce(1:i)*EffRadius - BrakeTorque(1:i) - ...
    SpinRate(1:i)*Damping).*(1/Inertia);

end

InputTorque = 1;

end
