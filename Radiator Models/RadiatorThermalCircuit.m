function [WaterOutletTemp1, WaterOutletTemp2, NumberOfTransferUnits, Effectiveness,AttainableHeatTransferRate]....
     = RadiatorThermalCircuit(WaterInletTemp, AirInletTemp)

%% Radiator Parameters
RadiatorZ= 0.244348;       % Core length (from CAD)
RadiatorY = 0.15875;       % Core height (from CAD) IS of wide laterllly, length y car cordinate 
RadiatorX = 0.041402;      % Core width (from CAD)

    %Table 7.6 For Correlation%
C2 = 0.7; 

%% Geometric Tube & Fin Parameters

AluminumThermalConductivity  = 237;
            %Tuber Parameters%
NumberOfTubes    = 8;
TubeInnerRadius  = 0.0025;
TubeInnerDiamter = TubeInnerRadius.*2;
TubeOuterRadius  = 0.004064;
TubeOuterDiameter= TubeOuterRadius*2;
TubeThickness    = TubeOuterRadius - TubeInnerRadius;
 
TubeInnerSurfArea = (2.*pi.*TubeInnerRadius.*RadiatorZ);
TubeOuterSurfArea = 2.*pi.*TubeOuterRadius.*RadiatorZ;
TubeCrossArea     = TubeThickness.*(TubeOuterRadius-TubeInnerRadius);
InnerTubeCrossArea= pi.*TubeInnerRadius^2;

TubeSpacing = RadiatorY./NumberOfTubes; %%WHATS IS THIS 
            %Fin Parameters%
FinThickness = .0006;
FinSpacing   = .001587;
FinDiameter  = RadiatorY./NumberOfTubes;
FinRadius    = FinDiameter./2;
NumberOfFins = 211; %RadiatorZ./FinSpacing;
FinLength    =  FinRadius - TubeOuterRadius;

FinRadiusCorrected =  FinRadius  + (FinThickness./2);
FinLengthCorrected = FinLength + (FinThickness./2);
Ap                 = FinLengthCorrected.*FinThickness;

TopSingleFinSurfArea  = pi.*( (FinRadiusCorrected^2) - (TubeOuterRadius^2) ); 
SingleFinSurfArea  = TopSingleFinSurfArea.*2;
FinPerimeter = 2.*(2.*pi.*FinRadius + FinThickness);

TubeOuterExposedSurfArea = TubeOuterSurfArea -...
    (NumberOfFins.*2.*pi.*TubeOuterRadius.*FinThickness);

TotalSurfAreaOneTube = SingleFinSurfArea.*NumberOfFins + TubeOuterExposedSurfArea;
TotalSurfArea = TotalSurfAreaOneTube.*8;


%Look at Figure 3.20 in Heat Transfer Text Book 7th Edition 
XAxis = FinLengthCorrected^(3/2).*(22/(237.*Ap))^(0.5);
LineNumber= FinRadiusCorrected/TubeOuterRadius; 

%% Fin States

SingleFinEfficiency  = 0.98; %From XAxis & LineNumber Figur 3.20
OverallFinEffeciency = 1 - ((NumberOfFins.*SingleFinSurfArea)./TotalSurfArea) ...
    .*(1 - SingleFinEfficiency);



%% Computation: Goal is Finding Heat transfer Coeff (Correlations & Iteration)
%Guess Initial Outlet Temperatures for Air & Water 
AirOutletTemp   = AirInletTemp+1;
WaterOutletTemp =  WaterInletTemp +1;
%Iteration Set Up
Tolerance = 0.1;
Counter   = 1;
DeltaTemp = 1;

while DeltaTemp >= Tolerance
    Counter = Counter+1;
%% Fluid Parameters 
                        %Water%
WaterHeatCapacity        = 4180;                  % Water heat capacity (J/KgK)
WaterDensity             = 997;                         % Water density (kg/m3)
WaterDynamicViscosity    = 0.799e-3;  %Fluid Book Table A.1 30 degc 
WaterKinematicViscosity  = 0.802e-6;  %Fluid Book Table A.1 30 degC 
WaterThermalConductivity = .59803;   %From Previous script (unkown source)
WaterVolumetricFlow      = (8./60000);             % Water volumetric flow (L/min -> m3/s)

WaterMassFlow         = WaterVolumetricFlow.*WaterDensity;                   %Mass flow water (kg/s)
WaterHeatCapacityRate = WaterHeatCapacity.*WaterMassFlow;  % Water heat capacity rate (J/sK)
WaterPrandtleNumber   = (WaterHeatCapacity * WaterDynamicViscosity) ./ WaterThermalConductivity;   
WaterVelocity         = WaterVolumetricFlow./(InnerTubeCrossArea.*NumberOfTubes); 
LengthDiameterRatio   =  RadiatorZ./TubeInnerDiamter; %Check if greater than 10 

                                %Air%
AirHeatCapacity = 1006;                  % Air heat capacity (J/KgK)
AirConductivity = .02572;                % Air thermal conductivity (W/mK)
AirDensity      = 1.225;               % Air density (kg/m3)
AirDynamicViscosity = 18.08E-6;

AirMassFlow     = 0.15; % Air mass flow from CFD (kg/s)

AirVolumetricFlow     = AirMassFlow./AirDensity; % Air volumetric flow (m3/s)
AirFreeStreamVelocity = AirVolumetricFlow ./ (RadiatorZ*RadiatorY);
AirMaxVelocity        = (TubeSpacing/(TubeSpacing-TubeOuterDiameter))*AirFreeStreamVelocity;
AirHeatCapacityRate   = AirHeatCapacity.*AirMassFlow; 

for i = 1:length(WaterHeatCapacityRate)
   MinHeatCapacityRate(i) =  min([WaterHeatCapacityRate(i), AirHeatCapacityRate(i)]);      % Minimum heat capacity (J/sK)
   MaxHeatCapacityRate(i) = max([WaterHeatCapacityRate(i), AirHeatCapacityRate(i)]);       % Maximum heat capacity (J/sK)
end

HeatCapacityRatio = MinHeatCapacityRate./MaxHeatCapacityRate; 


%% Computation: Finding Heat transfer Coeff (Correlations & Iteration)
%Guess Initial Outlet Temperatures for Air & Water 
AirOutletTemp   = 36+273;
WaterOutletTemp = 59+273;
%Iteration Set Up
Tolerance = 0.1;
Counter   = 1;
DeltaTemp = 1;

while DeltaTemp >= Tolerance
    Counter = Counter+1;
                        %Water Section Calculation%
    WaterMeanTemp = (WaterOutletTemp(Counter-1) + WaterInletTemp)/2;
    
    WaterReynoldsNumber = (WaterDensity.*WaterVelocity.*TubeInnerDiamter)./WaterDynamicViscosity;
    WaterPrandtlNumber  = (WaterHeatCapacity.*WaterDynamicViscosity)./WaterThermalConductivity;
    RelativeRoughness   =  0.003; %From Engineering Toolbox 
    WaterFrictionFactor = (1./(-1.8.*log10(6.9./WaterReynoldsNumber+(RelativeRoughness/3.7)^1.11)))^2;
    
    WaterNusseltNumber  = ((WaterFrictionFactor/8).*(WaterReynoldsNumber-1000).*WaterPrandtlNumber)...
        ./(1+12.7.*sqrt(WaterFrictionFactor/8).*(WaterPrandtlNumber^(2/3)-1));
    
    WaterHeatTransferCoeff = (WaterNusseltNumber.*WaterThermalConductivity)./TubeInnerDiamter;
    
                        %Aire Section Calculation%
    AirReynoldsNumber = (AirDensity*AirMaxVelocity*TubeOuterDiameter)/AirDynamicViscosity;
%Decide the Coefficients for the Correlation from Table 7.5 
      if AirReynoldsNumber < 10^2
        C1 = 0.8;
        m  = 0.4;
     elseif AirReynoldsNumber < 10^3 && AirReynoldsNumber > 10^2
        C1 = 1;
        m  = 1;
     elseif  AirReynoldsNumber > 10^3 && AirReynoldsNumber < 2e5
        C1 = 0.27;
        m  = 0.63;
     else 
        C1 = 0.021;
        m  = 0.84; 
      end
      
    HeatTransfer      = AirMassFlow.*AirHeatCapacity.*(AirOutletTemp(Counter-1) - AirInletTemp);
    HeatTransfer1Tube =  HeatTransfer/NumberOfTubes;
    
%Thermal Circuit From Water to Tuber Surface For one tube
                        %Individual Resistances%
    WaterConvResistance  = 1./(WaterHeatTransferCoeff.*TubeInnerSurfArea);

    TubeCondResistance   = (log(TubeOuterRadius./TubeInnerRadius)./...
    (2.*pi.*AluminumThermalConductivity.*RadiatorZ));
    
    EquivalentResistance = WaterConvResistance + TubeCondResistance;
    
    SurfaceTemp = HeatTransfer1Tube.*EquivalentResistance + WaterInletTemp;
    
    SurfaceViscosity    = 20.03e-6;
    SurfaceConductivity = 0.02887;
    SurfaceHeatCapacity = 1008;
    
    SurfacePrandtl  = (SurfaceViscosity*SurfaceHeatCapacity)/SurfaceConductivity;
    AirPrandtlNumber= (AirDynamicViscosity*AirHeatCapacity)/AirConductivity;
    AirReynoldsNumber = 2926;
    AirNusseltNumber = C2*C1*(AirReynoldsNumber^m)*(AirPrandtlNumber^0.36).*...
        (AirPrandtlNumber/SurfacePrandtl)^0.25;
    
    AirHeatTransferCoeff = (AirNusseltNumber.*AirConductivity)./TubeOuterDiameter;
    
%Finding Total Thermal Resistance with New Heat Transfer Coeffs

   AnnularFinResistance = 1./(SingleFinEfficiency.*AirHeatTransferCoeff.*SingleFinSurfArea.*NumberOfFins);

   OuterTubeConvResistance = 1./(AirHeatTransferCoeff.*(TotalSurfAreaOneTube -...
    (NumberOfFins*SingleFinSurfArea))); 

   ParallelFinWallResistance = ((1./AnnularFinResistance) +(1./OuterTubeConvResistance)).^(-1); %1./... 
    %(OverallFinEffeciency.*HeatTransferCoeffAir.*TotalSurfArea);
                   %Thermal Cicuits%
   SingleTubeResistance = WaterConvResistance + TubeCondResistance + ParallelFinWallResistance;

   TotalResistance =  (8./SingleTubeResistance).^(-1); 
   
   WaterOutletTemp(Counter) = AirInletTemp - (AirInletTemp-WaterInletTemp).*...
       exp(-1./(WaterMassFlow.*WaterHeatCapacity.*TotalResistance));
   
   AirOutletTemp(Counter) = SurfaceTemp - (SurfaceTemp-AirInletTemp).*...
       exp(-(pi*TubeOuterDiameter.*NumberOfTubes.*AirHeatTransferCoeff)./(AirDensity.*AirFreeStreamVelocity.*NumberOfTubes.*TubeSpacing.*AirHeatCapacity));

                        %Iteration Differance Cacl%
   AirTempDelta   = max(abs(AirOutletTemp(Counter-1)-AirOutletTemp(Counter)));
   WaterTempDelta = max(abs(WaterOutletTemp(Counter-1)-WaterOutletTemp(Counter)));
   
   DeltaTemp = max([AirTempDelta,WaterTempDelta]);

end 
   %% Heat Trnasfer Calc 1st Pass

MaxHeatTransferCheck  = (WaterInletTemp - AirInletTemp)./TotalResistance;
MaxHeatTransfer = MinHeatCapacityRate.*(WaterInletTemp - AirInletTemp);

UA = (TotalResistance) ^(-1);

NumberOfTransferUnits = UA./MinHeatCapacityRate;
Effectiveness = 1 - exp((1./HeatCapacityRatio).* ...
    (NumberOfTransferUnits).^0.22.*(exp(-HeatCapacityRatio.*(NumberOfTransferUnits).^0.78)-1));

AttainableHeatTransferRate = Effectiveness.*MaxHeatTransfer;

WaterOutletTemp1 = (WaterInletTemp - (AttainableHeatTransferRate ./  WaterHeatCapacityRate));
AirOutletTemp = (AirInletTemp + (AttainableHeatTransferRate ./ (AirHeatCapacityRate)));


%% Heat Transfer Calc 2nd Pass

MaxHeatTransfer2nd  = MinHeatCapacityRate.*(WaterOutletTemp1 - AirOutletTemp);
AttainableHeatTransferRate2nd = Effectiveness.*MaxHeatTransfer2nd;


% Temperature Calculation Second Pass 
 WaterOutletTemp2 =( WaterOutletTemp1 - (AttainableHeatTransferRate2nd ./ (WaterHeatCapacityRate)));
 
 AirOutletTemp2 = (AirOutletTemp +  (AttainableHeatTransferRate2nd ./ (MaxHeatCapacityRate)));


% fprintf('Number of Transfer Units (NTU): %3.2f \n', NumberOfTransferUnits)
% fprintf('Heat Exchanger Effectivness: %2.1f %% \n', Effectiveness*100)
% fprintf('Fin Efficiency: %2.1f %% \n', SingleFinEfficiency*100)
% fprintf('Total Heat Rejection(W): %4.1f \n', AttainableHeatTransferRate+AttainableHeatTransferRate2nd)
% fprintf('Water Outlet Temperature 1 (C): %4.1f \n', WaterOutletTemp1-273)
% fprintf('Air Outlet Temperature (C): %4.1f \n', AirOutletTemp-273)
% fprintf('Water Outlet Temperature 2 (C): %4.1f \n', WaterOutletTemp2-273)  
%    

%%                      TEST CASE                                        %%
if nargin == 0    
    WaterInletTemp = 60+273;
    AirInletTemp   = 35+273;
%% Fluid Parameters 
                        %Water%
WaterHeatCapacity        = 4180;                  % Water heat capacity (J/KgK)
WaterDensity             = 997;                         % Water density (kg/m3)
WaterDynamicViscosity    = 0.799e-3;  %Fluid Book Table A.1 30 degc 
WaterKinematicViscosity  = 0.802e-6;  %Fluid Book Table A.1 30 degC 
WaterThermalConductivity = .59803;   %From Previous script (unkown source)
WaterVolumetricFlow      = (8./60000);             % Water volumetric flow (L/min -> m3/s)

WaterMassFlow         = WaterVolumetricFlow.*WaterDensity;                   %Mass flow water (kg/s)
WaterHeatCapacityRate = WaterHeatCapacity.*WaterMassFlow;  % Water heat capacity rate (J/sK)
WaterPrandtleNumber   = (WaterHeatCapacity * WaterDynamicViscosity) ./ WaterThermalConductivity;   
WaterVelocity         = WaterVolumetricFlow./(InnerTubeCrossArea.*NumberOfTubes); 
LengthDiameterRatio   =  RadiatorZ./TubeInnerDiamter; %Check if greater than 10 

                                %Air%
AirHeatCapacity = 1006;                  % Air heat capacity (J/KgK)
AirConductivity = .02572;                % Air thermal conductivity (W/mK)
AirDensity      = 1.225;               % Air density (kg/m3)
AirDynamicViscosity = 18.08E-6;

AirMassFlow     = AirDensity*AirFreeStreamVelocity*RadiatorZ*RadiatorY; % Air mass flow from CFD (kg/s)

% AirVolumetricFlow     = AirMassFlow./AirDensity; % Air volumetric flow (m3/s)
% AirFreeStreamVelocity = AirVolumetricFlow ./ (RadiatorZ*RadiatorY);
AirMaxVelocity        = (TubeSpacing/(TubeSpacing-TubeOuterDiameter))*AirFreeStreamVelocity;
AirHeatCapacityRate   = AirHeatCapacity.*AirMassFlow; 

for i = 1:length(WaterHeatCapacityRate)
   MinHeatCapacityRate(i) =  min([WaterHeatCapacityRate(i), AirHeatCapacityRate(i)]);      % Minimum heat capacity (J/sK)
   MaxHeatCapacityRate(i) = max([WaterHeatCapacityRate(i), AirHeatCapacityRate(i)]);       % Maximum heat capacity (J/sK)
end

HeatCapacityRatio = MinHeatCapacityRate./MaxHeatCapacityRate; 


%% Computation: Finding Heat transfer Coeff (Correlations & Iteration)
%Guess Initial Outlet Temperatures for Air & Water 
AirOutletTemp   = 36+273;
WaterOutletTemp = 59+273;
%Iteration Set Up
Tolerance = 0.1;
Counter   = 1;
DeltaTemp = 1;

while DeltaTemp >= Tolerance
    Counter = Counter+1;
                        %Water Section Calculation%
    WaterMeanTemp = (WaterOutletTemp(Counter-1) + WaterInletTemp)/2;
    
    WaterReynoldsNumber = (WaterDensity.*WaterVelocity.*TubeInnerDiamter)./WaterDynamicViscosity;
    WaterPrandtlNumber  = (WaterHeatCapacity.*WaterDynamicViscosity)./WaterThermalConductivity;
    RelativeRoughness   =  0.003; %From Engineering Toolbox 
    WaterFrictionFactor = (1./(-1.8.*log10(6.9./WaterReynoldsNumber+(RelativeRoughness/3.7)^1.11)))^2;
    
    WaterNusseltNumber  = ((WaterFrictionFactor/8).*(WaterReynoldsNumber-1000).*WaterPrandtlNumber)...
        ./(1+12.7.*sqrt(WaterFrictionFactor/8).*(WaterPrandtlNumber^(2/3)-1));
    
    WaterHeatTransferCoeff = (WaterNusseltNumber.*WaterThermalConductivity)./TubeInnerDiamter;
    
                        %Aire Section Calculation%
    AirReynoldsNumber = (AirDensity*AirMaxVelocity*TubeOuterDiameter)/AirDynamicViscosity;
%Decide the Coefficients for the Correlation from Table 7.5 
      if AirReynoldsNumber < 10^2
        C1 = 0.8;
        m  = 0.4;
     elseif AirReynoldsNumber < 10^3 && AirReynoldsNumber > 10^2
        C1 = 1;
        m  = 1;
     elseif  AirReynoldsNumber > 10^3 && AirReynoldsNumber < 2e5
        C1 = 0.27;
        m  = 0.63;
     else 
        C1 = 0.021;
        m  = 0.84; 
      end
      
    HeatTransfer      = AirMassFlow.*AirHeatCapacity.*(AirOutletTemp(Counter-1) - AirInletTemp);
    HeatTransfer1Tube =  HeatTransfer/NumberOfTubes;
    
%Thermal Circuit From Water to Tuber Surface For one tube
                        %Individual Resistances%
    WaterConvResistance  = 1./(WaterHeatTransferCoeff.*TubeInnerSurfArea);

    TubeCondResistance   = (log(TubeOuterRadius./TubeInnerRadius)./...
    (2.*pi.*AluminumThermalConductivity.*RadiatorZ));
    
    EquivalentResistance = WaterConvResistance + TubeCondResistance;
    
    SurfaceTemp = HeatTransfer1Tube.*EquivalentResistance + WaterInletTemp;
    
    SurfaceViscosity    = 20.03e-6;
    SurfaceConductivity = 0.02887;
    SurfaceHeatCapacity = 1008;
    
    SurfacePrandtl  = (SurfaceViscosity*SurfaceHeatCapacity)/SurfaceConductivity;
    AirPrandtlNumber= (AirDynamicViscosity*AirHeatCapacity)/AirConductivity;
    AirReynoldsNumber = 2926;
    AirNusseltNumber = C2*C1*(AirReynoldsNumber^m)*(AirPrandtlNumber^0.36).*...
        (AirPrandtlNumber/SurfacePrandtl)^0.25;
    
    AirHeatTransferCoeff = (AirNusseltNumber.*AirConductivity)./TubeOuterDiameter;
    
%Finding Total Thermal Resistance with New Heat Transfer Coeffs

   AnnularFinResistance = 1./(SingleFinEfficiency.*AirHeatTransferCoeff.*SingleFinSurfArea.*NumberOfFins);

   OuterTubeConvResistance = 1./(AirHeatTransferCoeff.*(TotalSurfAreaOneTube -...
    (NumberOfFins*SingleFinSurfArea))); 

   ParallelFinWallResistance = ((1./AnnularFinResistance) +(1./OuterTubeConvResistance)).^(-1); %1./... 
    %(OverallFinEffeciency.*HeatTransferCoeffAir.*TotalSurfArea);
                   %Thermal Cicuits%
   SingleTubeResistance = WaterConvResistance + TubeCondResistance + ParallelFinWallResistance;

   TotalResistance =  (8./SingleTubeResistance).^(-1); 
   
   WaterOutletTemp(Counter) = AirInletTemp - (AirInletTemp-WaterInletTemp).*...
       exp(-1./(WaterMassFlow.*WaterHeatCapacity.*TotalResistance));
   
   AirOutletTemp(Counter) = SurfaceTemp - (SurfaceTemp-AirInletTemp).*...
       exp(-(pi*TubeOuterDiameter.*NumberOfTubes.*AirHeatTransferCoeff)./(AirDensity.*AirFreeStreamVelocity.*NumberOfTubes.*TubeSpacing.*AirHeatCapacity));

                        %Iteration Differance Cacl%
   AirTempDelta   = max(abs(AirOutletTemp(Counter-1)-AirOutletTemp(Counter)));
   WaterTempDelta = max(abs(WaterOutletTemp(Counter-1)-WaterOutletTemp(Counter)));
   
   DeltaTemp = max([AirTempDelta,WaterTempDelta]);

end 
   %% Heat Trnasfer Calc 1st Pass

MaxHeatTransferCheck  = (WaterInletTemp - AirInletTemp)./TotalResistance;
MaxHeatTransfer = MinHeatCapacityRate.*(WaterInletTemp - AirInletTemp);

UA = (TotalResistance) ^(-1);

NumberOfTransferUnits = UA./MinHeatCapacityRate;
Effectiveness = 1 - exp((1./HeatCapacityRatio).* ...
    (NumberOfTransferUnits).^0.22.*(exp(-HeatCapacityRatio.*(NumberOfTransferUnits).^0.78)-1));

AttainableHeatTransferRate = Effectiveness.*MaxHeatTransfer;

WaterOutletTemp1 = (WaterInletTemp - (AttainableHeatTransferRate ./  WaterHeatCapacityRate));
AirOutletTemp = (AirInletTemp + (AttainableHeatTransferRate ./ (AirHeatCapacityRate)));




%% Heat Transfer Calc 2nd Pass

MaxHeatTransfer2nd  = MinHeatCapacityRate.*(WaterOutletTemp1 - AirOutletTemp);
AttainableHeatTransferRate2nd = Effectiveness.*MaxHeatTransfer2nd;


% Temperature Calculation Second Pass 
 WaterOutletTemp2 =( WaterOutletTemp1 - (AttainableHeatTransferRate2nd ./ (WaterHeatCapacityRate)));
 
 AirOutletTemp2 = (AirOutletTemp +  (AttainableHeatTransferRate2nd ./ (MaxHeatCapacityRate)));


fprintf('Number of Transfer Units (NTU): %3.2f \n', NumberOfTransferUnits)
fprintf('Heat Exchanger Effectivness: %2.1f %% \n', Effectiveness*100)
fprintf('Fin Efficiency: %2.1f %% \n', SingleFinEfficiency*100)
fprintf('Heat Rejection (W): %4.1f \n', AttainableHeatTransferRate)
fprintf('Water Outlet Temperature 1 (C): %4.1f \n', WaterOutletTemp1-273)
fprintf('Air Outlet Temperature (C): %4.1f \n', AirOutletTemp-273)
fprintf('Water Outlet Temperature 2 (C): %4.1f \n', WaterOutletTemp2-273)  
   
   
   return;
end


end


