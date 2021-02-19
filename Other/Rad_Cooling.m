% Changable are staggered and commented to the right



%Water Tube Parameters
Num_of_Tubes= 33; %number of water Tubes
Tube_H= .001562; %Height of tubes, m
Tube_W= .0246; %Tube Width, m
Rad_L=  .4572;  %Rad Length, m

%Fin Specs 
Fin_Dist= .001587; %fin to fin distance, m
Fin_H= .01188;    %Fin Height, m
Fin_W= .02461;  %Fin Width, m
Num_Rows_Fins= 32; %Number of rows of fins
Num_of_AirPassages= Num_Rows_Fins*(Rad_L/Fin_Dist);

%Fin and Water Area Calcs
Coolant_SA= Num_of_Tubes*(2*(Tube_H*Rad_L)+2*(Tube_W*Rad_L));
Air_SA= Num_of_AirPassages*(2*(Fin_Dist*Fin_H)+2*(Fin_H*Fin_W));

%Hc Calculations
T_WaterIn=50;    % deg C, for study only 
T_WaterOut=190;%deg C, for study only
T_AirIn=40;
AminC= Tube_W*Tube_H;
WPC=2*(Tube_W+Tube_H);
DhC=4*AminC/WPC;

Water_Volumetric_Flow= .0002;%Coolant Volumetric Flow, m^3/sec
v_Water=Water_Volumetric_Flow/(Num_of_Tubes*AminC);
rho_Water=1015.57;                                          % Density water, kg/m^3 
meu_Water=.000744082;                                       % Viscosity water, Pa/s   
ReynoldsC= rho_Water*v_Water*DhC/meu_Water;

C_Water=3681.92;                                            % Specific Heat Water, J/kg*K
k_Water=.415098;                                            % Thermal Conductivity Water, W/M*K
Prandtl_Water= C_Water*meu_Water/k_Water;

Nusselt_Water=.023*(ReynoldsC^.8)*(Prandtl_Water^(1/3));
Hc=Nusselt_Water*k_Water/DhC;

%Ha Calcs
Air_Volumetric_Flow=1.10860; %m^3/s
AminA=Fin_H*Fin_Dist;
WPA= 2*(Fin_Dist+8*Fin_Dist);
DhA= 4*AminA/WPA;
rho_A= 1.13731;                                             %Air Density, kg/m^3
meu_Air=.00001912;                                          %Air viscosity, Pa*s
Air_Velocity=4.4704; %Air flow m/s
ReynoldsA= rho_A*Air_Velocity*DhA/meu_Air;

C_Air=1004.16;                                              %Specific Heat Air, J/kg*K
k_Air=.0266355;                                             %Thermal Conductivity Air, W/M*K



%UA Calcs
mdot_Air= Air_Volumetric_Flow*rho_A;
mdot_Water=Water_Volumetric_Flow*rho_Water;

Thermal_Cap_Rate_Air=mdot_Air*C_Air;
Thermal_Cap_Rate_Water=mdot_Water*C_Water;

C_Ratio=Thermal_Cap_Rate_Air/Thermal_Cap_Rate_Water;
C_min=Thermal_Cap_Rate_Air; %Since Ca<Cw
C_max=Thermal_Cap_Rate_Water;

ITD= T_WaterOut-T_AirIn;
q_current=70729; %BTU/min or J/S of heat transfer, determined from experiment
epsilon_Current=q_current/(ITD*C_min);

Ntu=log(1-(log(1-epsilon_Current)*-1*C_min/C_max))*-1/C_Ratio;

UA=C_min*Ntu; % W/m^2 K

NfHa=(1/Air_SA)/((1/UA)-(1/(Coolant_SA*Hc)));



%Water Tube Parameters, New 
Num_of_Tubes_New= 24;                                        %Number of water tubes    
Tube_H_New= .005;                                            %Height of each tube, Meters
Tube_W_New= .0254;                                           %Tube Width, Meters .0254
Rad_L_New=.25;                                               %Rad Length, Meters 

%Fin Specs, New  
Fin_Dist_New=.002;                                           %Fin to fin distance, Meters 
Fin_H_New= .008;                                             %Fin Height, Meters
Fin_W_New= .0254;                                            %Fin Width, Meters
Num_Rows_Fins_New= Num_of_Tubes_New-2;                       %Number of rows of fins
Num_of_AirPassages_New= Num_Rows_Fins_New*(Rad_L_New./Fin_Dist_New);

                                         

%Fin and Water Area Calculations, New
Coolant_SA_New= Num_of_Tubes_New*(2*(Tube_H_New*Rad_L_New)+2*(Tube_W_New*Rad_L_New));
Air_SA_New= Num_of_AirPassages_New.*(2.*(Fin_Dist_New.*Fin_H_New)+2.*(Fin_H_New.*Fin_W_New));

UA_New= (1./(Hc.*Coolant_SA_New)+1./(NfHa.*Air_SA_New)).^-1;

Volumetric_Flow_Water_New=.00003;                         %m^3/s of water flow  
Volumetric_Flow_Air_New=.2;                                  %m^3/s of air flow
mdot_Water_New=Volumetric_Flow_Water_New*rho_Water;          %kg/s of water flow
mdot_Air_New=Volumetric_Flow_Air_New*rho_A;                  %kg/s of air flow
C_min_New=mdot_Air_New*C_Air;
C_max_New=mdot_Water_New*C_Water;
Ntu_New=UA_New./C_min_New;

C_Ratio_New=C_min_New./C_max_New;

Epsilon_New= 1-exp(-1.*(C_max_New.*(1-exp(-1.*C_Ratio_New.*Ntu_New))./C_min_New));

Desired_Temp_Water=55;                                      % Water temperature inlet, Deg C
Air_Temp_In=43;                                             % Air temperature inlet, Deg C
Temp_Dif=Desired_Temp_Water-Air_Temp_In;                    % Water vs air delta.
heat=Epsilon_New.*C_min_New.*Temp_Dif                       % Heat rejected, W


%Rad_Air_Inlet=linspace(0,55,100);
%Delta=Desired_Temp_Water-Rad_Air_Inlet;
%Heat_Reject=Epsilon_New.*C_min_New.*Delta;
%figure(1)
%plot(Rad_L_New,heat)
%xlabel('Radiator Length, Meters')
%ylabel('Heat rejected, W')
%title('Radiator, variable length 6in by 1in w/ .002meters fin spacing, 25deg C delta,1.47e-5 m^3/s water flow, .17585 m^3/s airflow')




%Area= Thermal_Load/(UA*Temp_Dif)





