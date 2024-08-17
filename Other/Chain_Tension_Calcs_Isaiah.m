%Chain Tension Calculator

Power= 80; % Max Power Output by Motor in KW

Torque= 230; % Motor Torque in Nm
Diameter = 0.049; % Diameter of Drive Sprocket in m
Distance= 6.84; % Distance between center of the two sprockets (From CAD)

radius=Diameter/2;

%Tension = Power / (2*pi*RPM*radius*0.1667) True?
%Goal: Total Chain Tension = Working Load + Centrifugal Pull
    %Working Load = (HP x 33,000) / FPM
    %Centrifugal Pull = (Weight/ft chain*(FPM)^2)/115900

%Finding FPM = nteeth*Pitch*rpm
nteeth = 12; %teeth small sprocket *Change if nec*;
Pitch = .5*.0254; %Ansi 40 pitch is .5in, conv to cm;
RPM= 504*9; % Max Rpm of Motor/motor sprock
FPM = 12*(.5*.0254)*RPM
%Finding HP = KW/(.746*Motor Efficiency)
Motor_Efficiency = .93; %Note .96 max from Emrax
HP = Power/(.746*Motor_Efficiency); %conv W->HP
% Working Load
Working_Load = (HP*33000) / FPM
    %Note, can check with: Working_Load = (Chain bearing pressure)*(Bushing
    %Length)*(Pin Diam)

%FCentrifugal 
WChain = .42*4.44822; %lbf Ansi 40 chain conv to Netwons
FCentrifugal = (WChain*FPM^2)/115900

Chain_Tension = Working_Load + FCentrifugal
%Tension = WorkingLoad + FCentrifugal
Lateral_Force= (2*Torque)/Diameter
Chain_slack= 0.02*Distance % 2% of distance between sprockets