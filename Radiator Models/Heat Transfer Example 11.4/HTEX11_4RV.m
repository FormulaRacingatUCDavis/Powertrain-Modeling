%% Problem statement
%{
Consider the heat exchanger design of Example 11.3, that is, a finned-tube, cross-flow
heat exchanger with a gas-side overall heat transfer coefficient and area of 100 W/m2.K
and 40 m2, respectively. The water flow rate and inlet temperature remain at 1 kg/s and
35C. However, a change in operating conditions for the hot gas generator causes the
gases to now enter the heat exchanger with a flow rate of 1.5 kg/s and a temperature of
250C. What is the rate of heat transfer by the exchanger, and what are the gas and water
outlet temperatures?
%}

%Physical Characteristics of water from https://www.thermexcel.com/english/tables/eau_atm.htm

%Guess outlet water temperature and outlet air temperature

function HTEX11_4RV(Temperature_water, Temperature_air)

%% Define Given

U = 100;                % Overall heat transfer coefficient, W/m^2.K
A = 40;                 % Area of HX, m^2
mdot_water = 1;         % Water flow rate, kg/s
WaterInletTemp = 35+273;    % Inlet water temperature, K
mdot_gas = 1.5;         % Gas flow rate, kg/s
AirInletTemp = 250+273;     % Inlet gas temperature, K
Cp_h = 1000;            % Specific heat of gas, J/kg.K

%% Iteration to Calculate Heat Transfer Properties/Coefficients

%Assume outlet water temperature and guess air outlet temperature

WaterOutletTemp = Temperature_water+273;  % Outlet water temperature, K
AirOutletTemp = Temperature_air+273;     % Guess value similar to correct output to make finding mistakes easier, K

%Iteration setup

Tolerance = 0.1;
Counter   = 1;
DeltaTemp = 1;

while DeltaTemp >= Tolerance
    Counter = Counter+1;

    %Water Section Calculation
    
    WaterMeanTemp = (WaterOutletTemp(Counter-1) + WaterInletTemp)/2;
    Temperature_water = WaterMeanTemp;
    
    %% Water Specific Heat and Density Relationship to Temperature

    WaterTemperatureToCp = readmatrix('Physical Characteristics of Water.xlsx');
    
    x = WaterTemperatureToCp(:,1);
    
    y.CpWater = WaterTemperatureToCp(:,7);
    y.RhoWater = WaterTemperatureToCp(:,4);
    y.KinematicViscosityWater = WaterTemperatureToCp(:,11);
    y.DynamicViscosityWater = WaterTemperatureToCp(:,10);
    y.ThermalConductivityWater = WaterTemperatureToCp(:,12);

    WaterHeatCapacity = interp1(x, y.CpWater, Temperature_water)*1000;
    WaterDensity = interp1(x, y.RhoWater, Temperature_water);
    
    %{
    WaterDynamicViscosity = interp1(x, y.DynamicViscosityWater, Temperature_water);
    WaterThermalConductivity = interp1(x, y.ThermalConductivityWater, Temperature_water);
    WaterKinematicViscosity = interp1(x, y.KinematicViscosityWater, Temperature_water);
    %}    

    WaterHeatCapacityRate = mdot_water*WaterHeatCapacity;

    %Air Section Calculation
      
    AirMeanTemp = (AirOutletTemp(Counter-1)+AirInletTemp)/2;
    
    Temperature_air = AirMeanTemp;

    %% Air Specific Heat and Density Relationship to Temperature (from A.4 Fundamentals of Mass and Heat Transfer Textbook)
    
    AirTemperatureToCp = readmatrix('Physical Characteristics of Air.xlsx');
    
    x = AirTemperatureToCp(:,1);
    
    y.CpAir = AirTemperatureToCp(:,3);
    y.RhoAir = AirTemperatureToCp(:,2);
    y.KinematicViscosityAir = AirTemperatureToCp(:,6);
    y.DynamicViscosityAir = AirTemperatureToCp(:,5);
    y.ThermalConductivityAir = AirTemperatureToCp(:,4);

    AirHeatCapacity = interp1(x, y.CpAir, Temperature_air)*1000;
    AirDensity = interp1(x, y.RhoAir, Temperature_air);
    
    %{
    AirKinematicViscosity = interp1(x, y.KinematicViscosityAir, Temperature_air);       
    AirThermalConductivity = interp1(x, y.ThermalConductivityAir, Temperature_air);
    AirDynamicViscosity = interp1(x, y.DynamicViscosityAir, Temperature_air);
    AirPrandtlNumber = (AirDynamicViscosity*AirHeatCapacity)/AirThermalConductivity;
    %}

    AirHeatCapacityRate = mdot_gas*AirHeatCapacity;
    
    MinHeatCapacityRate = min([WaterHeatCapacityRate, AirHeatCapacityRate]);      % Minimum heat capacity (J/sK)
    MaxHeatCapacityRate = max([WaterHeatCapacityRate, AirHeatCapacityRate]);      % Maximum heat capacity (J/sK)
    HeatCapacityRatio = MinHeatCapacityRate./MaxHeatCapacityRate; 
    
    NTU = U*A./MinHeatCapacityRate;

    Effectiveness = 1 - exp((1./HeatCapacityRatio).* ...
        (NTU).^0.22.*(exp(-HeatCapacityRatio.*(NTU).^0.78)-1));
    
    MaxHeatTransfer = MinHeatCapacityRate.*(AirInletTemp - WaterInletTemp);
    AttainableHeatTransferRate = Effectiveness.*MaxHeatTransfer;
    
    AirOutletTemp(Counter) = (AirInletTemp - (AttainableHeatTransferRate ./ (AirHeatCapacityRate)));
    WaterOutletTemp(Counter) = (WaterInletTemp + (AttainableHeatTransferRate ./ (WaterHeatCapacityRate)));
    
    AirTempDelta   = max(abs(AirOutletTemp(Counter-1)-AirOutletTemp(Counter)));
    WaterTempDelta = max(abs(WaterOutletTemp(Counter-1)-WaterOutletTemp(Counter)));
   
    DeltaTemp = max([AirTempDelta,WaterTempDelta]);

end

fprintf('Number of Transfer Units (NTU): %3.2f \n', NTU)
fprintf('Heat Exchanger Effectivness: %2.1f %% \n', Effectiveness*100)
fprintf('Heat Rejection (W): %4.1f \n', AttainableHeatTransferRate)
fprintf('Water Outlet Temperature (C): %4.1f \n', WaterOutletTemp(end)-273)
fprintf('Air Outlet Temperature (C): %4.1f \n', AirOutletTemp(end)-273) 

end