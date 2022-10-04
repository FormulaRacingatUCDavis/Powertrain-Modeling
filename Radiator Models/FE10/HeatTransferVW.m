function [HeatTransferRate] = HeatTransferVW(WaterOutletTemp,AirOutletTemp, mdot_water, speed)
    %AirInletTemp should be temp of location in celcius
    if nargin == 0
        WaterOutletTemp = 25;
        AirOutletTemp = 35;
        mdot_water = 0.2;
        speed = 20;
    end
    RadiatorZ= 0.244348;       % Core length (from CAD)
    RadiatorY = 0.15875;       % Core height (from CAD) IS of wide laterllly, length y car cordinate 
    RadiatorX = 0.041402;      % Core width (from CAD)
    FinThickness = .0006;      % Fin Thickness 
    
    TiR  = 0.0025;             % Tube Inner Radius
    ToR  = 0.004064;           % Tube Outer Radius all of these are meters
    
    AirInletTemp = 30 + 273;
    WaterInletTemp = 45 + 273;
    CoeffAir = 50;
    CoeffWater = 1630;
    Fins = 211;
   % WaterOutletTemp = WaterInletTemp + 5;      % Final Temperature of Water
    %AirOutletTemp = AirInletTemp + 5;          % Final Temperature of Air
    
    %CoeffRadiator = 205;
    CoeffRadiator = 237;
    nf = 0.98;
    
    Area = (RadiatorX./2) .* (RadiatorY ./ 8);
    RadiusFin = sqrt(Area ./ (pi));
    RadiusCorrected = RadiusFin + FinThickness/2; %meters
    deltaTemp = WaterOutletTemp - WaterInletTemp;
    
    FinArea = 2*(pi*(RadiusCorrected^2 - ToR^2)); %units are meters^2
    BaseArea = (RadiatorZ-(FinThickness.*Fins)).*(RadiatorY./8);
    TotalArea = FinArea*Fins + BaseArea;
    SurfaceEff = 1 - (Fins*FinArea/TotalArea)*(1-nf);
    
    RConv = 1/(2*pi*TiR*CoeffWater*RadiatorZ);
    RCond = log(ToR/TiR)/(2*pi*RadiatorZ*CoeffRadiator);
    RFins = (SurfaceEff*CoeffAir*TotalArea)^-1;
    RTotal = RConv + RCond + RFins; %Units are (Watts/Kelvin)^-1
    disp(RTotal);
    
    TotalResistance = RTotal./8;
    UA = 1/TotalResistance;
    U = UA/TotalArea;
    A = TotalArea;
    
BaseLength = RadiatorZ-(FinThickness.*Fins);
%L = RadiusFin - ToR;

Tolerance = 0.1;
Counter   = 1;
DeltaTemp = 1;

WaterOutletTemp = WaterOutletTemp + 273;
AirOutletTemp = AirOutletTemp + 273;

while DeltaTemp >= Tolerance
    Counter = Counter+1;

    %Water Section Calculation
    
    WaterMeanTemp = (WaterOutletTemp(Counter-1) + WaterInletTemp)/2;
    GuessOutletTempWater = WaterMeanTemp;
    
    %% Water Specific Heat and Density Relationship to Temperature

    WaterTemperatureToCp = readmatrix('Physical Characteristics of Water.xlsx');
    
    x = WaterTemperatureToCp(:,1);
    
    y.CpWater = WaterTemperatureToCp(:,7);
    y.RhoWater = WaterTemperatureToCp(:,4);
    y.KinematicViscosityWater = WaterTemperatureToCp(:,11);
    y.DynamicViscosityWater = WaterTemperatureToCp(:,10);
    y.ThermalConductivityWater = WaterTemperatureToCp(:,12);

    WaterHeatCapacity = interp1(x, y.CpWater, GuessOutletTempWater)*1000;
    WaterDensity = interp1(x, y.RhoWater, GuessOutletTempWater);
    
    %{
    WaterDynamicViscosity = interp1(x, y.DynamicViscosityWater, Temperature_water);
    WaterThermalConductivity = interp1(x, y.ThermalConductivityWater, Temperature_water);
    WaterKinematicViscosity = interp1(x, y.KinematicViscosityWater, Temperature_water);
    %}    
    
    WaterHeatCapacityRate = mdot_water*WaterHeatCapacity;

    %Air Section Calculation
      
    AirMeanTemp = (AirOutletTemp(Counter-1)+AirInletTemp)/2;
    
    GuessOutletTempAir = AirMeanTemp;

    %% Air Specific Heat and Density Relationship to Temperature (from A.4 Fundamentals of Mass and Heat Transfer Textbook)
    
    AirTemperatureToCp = readmatrix('Physical Characteristics of Air.xlsx');
    
    x = AirTemperatureToCp(:,1);
    
    y.CpAir = AirTemperatureToCp(:,3);
    y.RhoAir = AirTemperatureToCp(:,2);
    y.KinematicViscosityAir = AirTemperatureToCp(:,6);
    y.DynamicViscosityAir = AirTemperatureToCp(:,5);
    y.ThermalConductivityAir = AirTemperatureToCp(:,4);

    AirHeatCapacity = interp1(x, y.CpAir, GuessOutletTempAir)*1000;
    AirDensity = interp1(x, y.RhoAir, GuessOutletTempAir);
    
    %{
    AirKinematicViscosity = interp1(x, y.KinematicViscosityAir, Temperature_air);       
    AirThermalConductivity = interp1(x, y.ThermalConductivityAir, Temperature_air);
    AirDynamicViscosity = interp1(x, y.DynamicViscosityAir, Temperature_air);
    AirPrandtlNumber = (AirDynamicViscosity*AirHeatCapacity)/AirThermalConductivity;
    %}
    
    mdot_gas = speed*AirDensity*BaseLength*RadiatorY+0.1;
    %mdot_gas = speed*AirDensity*RadiatorY*RadiatorZ;
    %mdot_gas = speed*1.27*2*BaseLength*L;
    %mdot_gas = 0.001
    %mdot_gas = 10
    
    AirHeatCapacityRate = mdot_gas*AirHeatCapacity;
    MinHeatCapacity = min([WaterHeatCapacity,AirHeatCapacity]);
    MinHeatCapacityRate = min([WaterHeatCapacityRate, AirHeatCapacityRate]);      % Minimum heat capacity (J/sK)
    MaxHeatCapacityRate = max([WaterHeatCapacityRate, AirHeatCapacityRate]);      % Maximum heat capacity (J/sK)
    HeatCapacityRatio = MinHeatCapacityRate./MaxHeatCapacityRate; 
    
    NTU = UA./MinHeatCapacityRate;
%NTU = 1
        
    Effectiveness = 1 - exp((1./HeatCapacityRatio).* ...
        (NTU).^0.22.*(exp(-HeatCapacityRatio.*(NTU).^0.78)-1));
    
    MaxHeatTransfer = MinHeatCapacityRate.*(WaterInletTemp - AirInletTemp);
    AttainableHeatTransferRate = Effectiveness.*MaxHeatTransfer;
    
    AirOutletTemp(Counter) = (AirInletTemp + (AttainableHeatTransferRate ./ (AirHeatCapacityRate)));
    WaterOutletTemp(Counter) = (WaterInletTemp - (AttainableHeatTransferRate ./ (WaterHeatCapacityRate)));
    
    AirTempDelta   = max(abs(AirOutletTemp(Counter-1)-AirOutletTemp(Counter)));
    WaterTempDelta = max(abs(WaterOutletTemp(Counter-1)-WaterOutletTemp(Counter)));
   
    DeltaTemp = max([AirTempDelta,WaterTempDelta]);

end

%% Pass 2 %%

MaxHeatTransfer2 = MinHeatCapacityRate.*(WaterOutletTemp(end) - AirOutletTemp(end));
AttainableHeatTransferRate2 = Effectiveness.*MaxHeatTransfer2;

AirOutletTemp2 = (AirOutletTemp(end)...
    + (AttainableHeatTransferRate2 ./ (AirHeatCapacityRate)));

WaterOutletTemp2 = (WaterOutletTemp(end)...
    - (AttainableHeatTransferRate2 ./ (WaterHeatCapacityRate)));

TiD = 2*TiR;
    WaterDynamicViscosity = 1.0016*(10^-3);
    WaterVelocity = mdot_water/((TiR^2)*pi*8*WaterDensity);
    WaterReynoldsNumber = (WaterDensity.*WaterVelocity.*TiD)./WaterDynamicViscosity;
    RelativeRoughness   =  0.003; %From Engineering Toolbox 
    WaterFrictionFactor = (1./(-1.8.*log10(6.9./WaterReynoldsNumber+(RelativeRoughness/3.7)^1.11)))^2;
    RadiatorPressDrop = WaterFrictionFactor.*(8*RadiatorZ./TiD).*...
    (WaterDensity.*(WaterVelocity.^2))./2;   

fprintf('Number of Iterations: %3.2f \n', Counter)
fprintf('Number of Transfer Units (NTU): %3.2f \n', NTU)
fprintf('Heat Exchanger Effectiveness: %2.1f %% \n', Effectiveness*100)
fprintf('Heat Rejection Pass 1 (W): %4.1f \n', AttainableHeatTransferRate)
fprintf('Heat Rejection Pass 2 (W): %4.1f \n', AttainableHeatTransferRate2)
fprintf('Total Heat Rejection (W): %4.1f \n', AttainableHeatTransferRate + AttainableHeatTransferRate2)
fprintf('Water Outlet Temperature Pass 1 (C): %4.1f \n', WaterOutletTemp(end)-273)
fprintf('Air Outlet Temperature Pass 1 (C): %4.1f \n', AirOutletTemp(end)-273)
fprintf('Water Outlet Temperature Pass 2 (C): %4.1f \n', WaterOutletTemp2-273)
fprintf('Air Outlet Temperature Pass 2 (C): %4.1f \n', AirOutletTemp2-273)
fprintf('Water Temperature Difference (C): %4.1f \n', WaterOutletTemp2-WaterInletTemp)
fprintf('Air Temperature Difference (C): %4.1f \n', AirOutletTemp2-AirInletTemp)
fprintf('Pressure Drop (Pa): %4.1f \n', RadiatorPressDrop)
end