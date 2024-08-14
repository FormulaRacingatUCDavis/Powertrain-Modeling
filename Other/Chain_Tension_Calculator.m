%Chain Tnesion Calculator

Power= 80; % Max Power Output by Motor in KW
RPM= 504*9; % Max Rpm of Motor 
Torque= 230; % Motor Torque in Nm
Diameter = 0.049; % Diameter of Drive Sprocket in m
Distance= 6.66; % Distance between center of the two sprockets (From CAD)

Power=Power*1000;
radius=Diameter/2;

%Tension = Power / (2*pi*RPM*radius*0.1667)
Lateral_Force= (2*Torque)/Diameter
Chain_slack= 0.02*Distance % 2% of distance between sprockets 
