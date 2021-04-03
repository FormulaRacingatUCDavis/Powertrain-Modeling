clc; clear; close all;
%% Drivetrain Statics
% For calculating the forces on the sprocket and two differential mounting
% brackets.

motorTorque = 230; % Max motor torque, in N*m
chainPitch = 0.0127; % Chain pitch in meter, 12.7mm (0.5in) for ANSI 40 chain
motorSprocketTeeth = 12;

sprocketToDriveSideBracket = 0.0344932; % in meters
driveSideBracketToSupportSideBracket = 0.140; % in meters

motorSprocketPD = chainPitch/sind(180/motorSprocketTeeth) % calculates pitch diameter of the motor sprocket
sprocketForce = motorTorque/(motorSprocketPD/2) % equivalent to tension in the chain
supportSideForce = -1*sprocketForce*sprocketToDriveSideBracket/driveSideBracketToSupportSideBracket % Force on the support side bracket
driveSideForce = sprocketForce+supportSideForce % Force on the drive side bracket

%Shear Calcs
BoltDiameter = 0.005; % in meters
CrossSectionalArea=(pi*0.25)*(BoltDiameter^2); % in meters^2
BoltShearStrength = 580; % in MPa
AllowableShearForce = BoltShearStrength*1000*1000*CrossSectionalArea % in Newtons



