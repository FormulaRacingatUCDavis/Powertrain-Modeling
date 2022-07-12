clear all 
SimplifiedColdPlateAnalysis
close figure 1

%% Water Parameters



%% Air Parameters 

AirInletTemp = 30+273; 

% Correlations 
LowMassFlowCorrelation = @(x) 4.02.*x + 23.3;
MedMassFlowCorrelation = @(x) 4.43*x + 22.1;
HiMassFlowCorrelation  = @(x) 4.89*x + 20.8;

%% Radiator Parameters 

AlThermalConductivity  = 237;
NoT = 8;

HeatTransfer    = WaterHeat;

%% Creating Vectors
                            %Geometries
RadiatorZ = linspace(0.1,0.3,10);   % Core length (from CAD)
RadiatorY = linspace (0.1,0.2,10);  % Core height (from CAD) IS of wide laterllly, length y car cordinate 

TubeOuterDiameter = [0.005 0.005 0.01  0.01 0.012 0.012 0.016 0.016 0.02 0.02];
TubeThickness     = [0.001 0.001 0.001 0.001 0.001 0.001 .002  0.002 .002  0.002];
TubeOuterRadius   = TubeOuterDiameter./2;
TubeInnerRadius   = TubeOuterRadius - TubeThickness;
TubeInnerDiameter = TubeInnerRadius.*2;
TubeInnerSurfArea = (2.*pi.*TubeInnerRadius.*RadiatorZ.*NoT); % Total
TubeOuterSurfArea = 2.*pi.*TubeOuterRadius.*RadiatorZ.*NoT;
InnerTubeCrossArea= pi.*TubeInnerRadius.^2;
RadiatorCrossArea =  RadiatorZ .*RadiatorY;
TubeSpacing       = RadiatorY./NoT;

TubeCondResistance= (log(TubeOuterRadius./TubeInnerRadius)./...
    (2.*pi.*AlThermalConductivity.*RadiatorZ.*NoT));

                            % Water Vectors 

WaterInletTemp  = [GraphWaterOutletTemp(1) GraphWaterOutletTemp(1) GraphWaterOutletTemp(2) GraphWaterOutletTemp(2) ...
    GraphWaterOutletTemp(3) GraphWaterOutletTemp(3) GraphWaterOutletTemp(4) GraphWaterOutletTemp(4) ...
    GraphWaterOutletTemp(5) GraphWaterOutletTemp(5)];
WaterOutletTemp = [WaterInletTempAnswer(1) WaterInletTempAnswer(1) ...
    WaterInletTempAnswer(2) WaterInletTempAnswer(2) WaterInletTempAnswer(3) WaterInletTempAnswer(3) ...
    WaterInletTempAnswer(4) WaterInletTempAnswer(4) WaterInletTempAnswer(5) WaterInletTempAnswer(5)];
WaterMeanTemp   = (WaterOutletTemp+WaterInletTemp)./2;

WaterMassFlow = [WaterMassFlow(1) WaterMassFlow(1) WaterMassFlow(2) WaterMassFlow(2)...
    WaterMassFlow(3) WaterMassFlow(3) WaterMassFlow(4) WaterMassFlow(4) ...
    WaterMassFlow(5) WaterMassFlow(5)];



WaterHeatCapacity        = zeros(1,length(WaterMeanTemp));
WaterDensity             = zeros(1,length(WaterMeanTemp));
WaterDynamicViscosity    = zeros(1,length(WaterMeanTemp));
WaterThermalConductivity = zeros(1,length(WaterMeanTemp));
AirSurfArea              = zeros(length(WaterMeanTemp), length(WaterMeanTemp));


for i = 1:length(WaterMeanTemp)
 
WaterHeatCapacity(i)= py.CoolProp.CoolProp.PropsSI('C','P',101325,'T',WaterMeanTemp(i),'Water');
WaterDensity(i)     = py.CoolProp.CoolProp.PropsSI('D','P',101325,'T',WaterMeanTemp(i),'Water'); 

WaterDynamicViscosity(i)    = py.CoolProp.CoolProp.PropsSI('V','P',101325,'T',WaterMeanTemp(i),'Water');
WaterThermalConductivity(i) = py.CoolProp.CoolProp.PropsSI('L','P',101325,'T',WaterMeanTemp(i),'Water');

end

WaterVelocity        = WaterMassFlow./(WaterDensity.*InnerTubeCrossArea);
WaterPrandtlNumber   = (WaterHeatCapacity.*WaterDynamicViscosity)./WaterThermalConductivity;
WaterReynoldsNumber  = (WaterDensity.*WaterVelocity.*TubeInnerDiameter)./WaterDynamicViscosity;

RelativeRoughness   =  0.003; %From Engineering Toolbox 
WaterFrictionFactor = (1./(-1.8.*log10(6.9./WaterReynoldsNumber+...
    (RelativeRoughness/3.7)^1.11))).^2;   
WaterNusseltNumber  = ((WaterFrictionFactor/8).*(WaterReynoldsNumber-1000).*WaterPrandtlNumber)...
        ./(1+12.7.*sqrt(WaterFrictionFactor/8).*(WaterPrandtlNumber.^(2/3)-1));

WaterHeatTransferCoeff = (WaterNusseltNumber.*WaterThermalConductivity)./TubeInnerDiameter;

                            %Surface Temperature for Zaukahkaus 
WaterConvResistance    = 1./(WaterHeatTransferCoeff.*TubeInnerSurfArea);
EquivalentResistance   = WaterConvResistance + TubeCondResistance;
SurfaceTemp            = HeatTransfer.*EquivalentResistance + WaterInletTemp;

SurfaceHeatCapacity  = zeros(1,length(SurfaceTemp));
SurfaceConductivity  = zeros(1,length(SurfaceTemp));
SurfaceViscosity     = zeros(1,length(SurfaceTemp));


for i = 1:length(SurfaceTemp)
SurfaceHeatCapacity(i)  = py.CoolProp.CoolProp.PropsSI('C','P',101325,'T',SurfaceTemp(i),'Air');
SurfaceConductivity(i)  = py.CoolProp.CoolProp.PropsSI('L','P',101325,'T',SurfaceTemp(i),'Air');
SurfaceViscosity(i)     = py.CoolProp.CoolProp.PropsSI('V','P',101325,'T',SurfaceTemp(i),'Air');
end 

SurfacePrandtl       = (SurfaceViscosity.*SurfaceHeatCapacity)./SurfaceConductivity;
                            % Air Vectors
AirHeatCapacity     = py.CoolProp.CoolProp.PropsSI('C','P',101325,'T',AirInletTemp,'Air');
AirConductivity     = py.CoolProp.CoolProp.PropsSI('L','P',101325,'T',AirInletTemp,'Air');
AirDynamicViscosity = py.CoolProp.CoolProp.PropsSI('V','P',101325,'T',AirInletTemp,'Air');
AirDensity          = py.CoolProp.CoolProp.PropsSI('D','P',101325,'T',AirInletTemp,'Air');
                            
AirVelocity = linspace(5,15,10);

AirMassFlow   = RadiatorCrossArea.*AirDensity.*AirVelocity;
AirOutletTemp = (AirInletTemp + (HeatTransfer ./ (AirMassFlow.*AirHeatCapacity)));
AirMeanTemp   = (AirOutletTemp + AirInletTemp)/2;
AirMaxVelocity= (TubeSpacing/(TubeSpacing-TubeOuterDiameter))*AirVelocity;

                        % Iteration for Outler Temperature
Tolerance = 0.1;
Counter   = 1;
DeltaTemp = 1;
i = 1;

AirInletTempAnswer = zeros(1,length(WaterMeanTemp));
AirMeanTempAnswer  = zeros(1,length(WaterMeanTemp));
while i <= length(WaterMeanTemp)

    while DeltaTemp >= Tolerance
        Counter = Counter+1;
        AirHeatCapacity        = py.CoolProp.CoolProp.PropsSI('C','P',101325,'T',AirMeanTemp(i),'Air');
        AirOutletTemp(Counter) = AirInletTemp + HeatTransfer/(AirMassFlow(i).*AirHeatCapacity);
        AirMeanTemp(i) = (AirOutletTemp(Counter) + AirInletTemp)./2;

        DeltaTemp = abs(WaterInletTemp(Counter) - WaterInletTemp(Counter-1));
    end 
    AirInletTempAnswer(i) = WaterInletTemp(Counter);
    AirMeanTempAnswer(i)  = AirMeanTemp(i);
    i = i+1;
    DeltaTemp = 1;
    Counter =1; 
end
AirHeatCapacity     = zeros(1,length(AirMeanTempAnswer));
AirConductivity     = zeros(1,length(AirMeanTempAnswer));
AirDynamicViscosity = zeros(1,length(AirMeanTempAnswer));
AirDensity          = zeros(1,length(AirMeanTempAnswer));

for i = 1:length(AirMeanTempAnswer)
  AirHeatCapacity(i)     = py.CoolProp.CoolProp.PropsSI('C','P',101325,'T',AirMeanTempAnswer(i),'Air');
  AirConductivity(i)     = py.CoolProp.CoolProp.PropsSI('L','P',101325,'T',AirMeanTempAnswer(i),'Air');
  AirDynamicViscosity(i) = py.CoolProp.CoolProp.PropsSI('V','P',101325,'T',AirMeanTempAnswer(i),'Air');
  AirDensity(i)          = py.CoolProp.CoolProp.PropsSI('D','P',101325,'T',AirMeanTempAnswer(i),'Air');  
end 

 AirPrandtlNumber = (AirDynamicViscosity.*AirHeatCapacity)./AirConductivity;
 AirReynoldsNumber = zeros(1:length(WaterMassFlow));
for i = 1:length(WaterMassFlow)
    
    if WaterMassFlow(i) < 0.1385977
        AirHeatTransferCoeff = LowMassFlowCorrelation(AirVelocity);
        
    elseif (WaterMassFlow(i) > 0.1385977) && (WaterMassFlow(i) < 0.3477542)
        AirHeatTransferCoeff = (WaterMassFlow(i)-0.1385977)/...
            (0.3477542- 0.1385977).*(MedMassFlowCorrelation(AirVelocity) -...
            LowMassFlowCorrelation(AirVelocity)) + LowMassFlowCorrelation(AirVelocity);
        
    elseif (WaterMassFlow(i) > 0.3477542) && (WaterMassFlow(i) < 0.5115514)
      AirHeatTransferCoeff = (WaterMassFlow(i)-0.1385977)/...
            (0.3477542- 0.1385977).*(HiMassFlowCorrelation(AirVelocity) -...
            MedMassFlowCorrelation(AirVelocity)) + MedMassFlowCorrelation(AirVelocity);
    end

%% Step 1 & Step 2
WaterHeatCapacityRate = WaterMassFlow(i).*WaterHeatCapacity;
AirHeatCapacityRate   = RadiatorCrossArea.*AirDensity.*AirVelocity.*AirHeatCapacity;



MinHeatCapacityRate =  min([WaterHeatCapacityRate, AirHeatCapacityRate]);      % Minimum heat capacity (J/sK)
MaxHeatCapacityRate =  max([WaterHeatCapacityRate, AirHeatCapacityRate]);       % Maximum heat capacity (J/sK)
HeatCapacityRatio = MinHeatCapacityRate./MaxHeatCapacityRate; 


Effectiveness = (WaterHeatCapacityRate.*(WaterInletTemp-WaterOutletTemp))...
    ./(MinHeatCapacityRate.*(WaterInletTemp - AirInletTemp));

MaxHeatTransfer = HeatTransfer./Effectiveness;
%% Step 3
NTU = -(1./HeatCapacityRatio).*log(HeatCapacityRatio.*log(1-Effectiveness)+1);

OverAllSurfEfficieny = HeatTransfer./MaxHeatTransfer;
%% Step 4 & 5
AirSurfArea(i,:) = (-NTU.*MinHeatCapacityRate.*TubeInnerSurfArea.*WaterHeatTransferCoeff)...
    ./(AirHeatTransferCoeff.*OverAllSurfEfficieny.*...
    (NTU.*MinHeatCapacityRate + ...
    NTU.*MinHeatCapacityRate.*WaterHeatTransferCoeff.*TubeInnerSurfArea.*TubeCondResistance ...
    - WaterHeatTransferCoeff.*TubeInnerSurfArea));

end

GraphWaterMassFlow = [WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' WaterMassFlow' ];
GraphAirVelocity   = [AirVelocity; AirVelocity; AirVelocity; AirVelocity; AirVelocity; AirVelocity; AirVelocity; AirVelocity; AirVelocity; AirVelocity;];
for i = 1:numel(AirSurfArea)
    if AirSurfArea(i) < 0
        AirSurfArea(i) = NaN;
    else
        AirSurfArea(i) = AirSurfArea(i);
    end
end

surf(GraphWaterMassFlow,GraphAirVelocity,AirSurfArea)
zlabel('Heat Exchanger Surface Area Expose to Air (m^2)')
ylabel('Air Velocity (m/s)')
xlabel('Water Mass Flow Rate kg/s')
    

