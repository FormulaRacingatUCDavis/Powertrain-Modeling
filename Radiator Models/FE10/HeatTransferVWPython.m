clear;

x                   = 0.13;  % Air mass flow rate
AirMassFlow         = x; % Air mass flow from CFD (kg/s)
WaterInletTemp      = 37.8 + 273.15;
AirInletTemp        = 45 + 273.15;
RelativeHumidity    = 82/100;


%% Radiator Parameters
for d = 1

RadiatorZ= 0.244348;       % Core length (from CAD)
RadiatorY = 0.15875;       % Core height (from CAD) IS of wide laterllly, length y car cordinate 
RadiatorX = 0.041402;      % Core width (from CAD)

    %Table 7.6 For Correlation%
C2 = 0.7; 

% Geometric Tube & Fin Parameters

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
LengthDiameterRatio     =  RadiatorZ./TubeInnerDiamter;   %Check if greater than 10 

%% Check Fan area
% FanArea = 0.006206439; % m^2
% TotalSurfArea = TotalSurfArea - FanArea;
% Check units
% Total radiator area = 60.13 in^2 ~ 0.038793471
% Total Fan area = 9.62 in^2 ~ 0.006206439
% Total Surface area from matlab ~ 0.9571???
% how to include this into it
% Some thickness overlap with fans area
% I dont think its smart to think like that

%Look at Figure 3.20 in Heat Transfer Text Book 7th Edition 
XAxis = FinLengthCorrected^(3/2).*(22/(237.*Ap))^(0.5);
LineNumber= FinRadiusCorrected/TubeOuterRadius; 

%% Fin States

SingleFinEfficiency  = 0.98; %From XAxis & LineNumber Figur 3.20
OverallFinEffeciency = 1 - ((NumberOfFins.*SingleFinSurfArea)./TotalSurfArea) ...
    .*(1 - SingleFinEfficiency);

%
end


%Guess Initial Outlet Temperatures for Air & Water 
AirOutletTemp   = AirInletTemp + 1;
%Iteration Set Up
Tolerance       = 0.01;
Counter         = 1;
DeltaTemp       = 1;
WaterMeanTemp   = 300;

% Initial water and air properties
for d = 1
    [WaterHeatCapacityRate] = WaterProperty(WaterMeanTemp);
    
    AirMeanTemp = (AirOutletTemp+AirInletTemp)/2;
    
    [AirHeatCapacity] = HumidAirProperty(AirMeanTemp,RelativeHumidity,AirMassFlow);
end



% Start of while loop

while DeltaTemp >= Tolerance
    Counter = Counter+1;
%% Fluid Parameters 
                              % Temperature Calcs % 
    HeatTransfer   = AirMassFlow.*AirHeatCapacity.*(AirOutletTemp(Counter-1) - AirInletTemp);
    WaterOutletTemp = HeatTransfer./WaterHeatCapacityRate + WaterInletTemp;
                     %Water%
    if size(WaterOutletTemp,1) == 1 
    WaterMeanTemp = (WaterOutletTemp + WaterInletTemp)/2;
    else
    WaterMeanTemp = (WaterOutletTemp1 + WaterInletTemp)/2;
    end
        
    [WaterHeatCapacityRate,WaterThermalConductivity,WaterReynoldsNumber,WaterPrandtlNumber,WaterMassFlow,WaterHeatCapacity] = WaterProperty(WaterMeanTemp);
    
                        %Air%
    AirMeanTemp = (AirOutletTemp(Counter-1)+AirInletTemp)/2;
    
    % Humid Air Cool Prop
    [AirHeatCapacity,AirThermalConductivity,AirReynoldsNumber,AirPrandtlNumber,AirHeatCapacityRate,AirDensity,AirFreeStreamVelocity] = HumidAirProperty(AirMeanTemp,RelativeHumidity,AirMassFlow);


    MinHeatCapacityRate   =  min([WaterHeatCapacityRate, AirHeatCapacityRate]);      % Minimum heat capacity (J/sK)
    MaxHeatCapacityRate   =  max([WaterHeatCapacityRate, AirHeatCapacityRate]);       % Maximum heat capacity (J/sK)
    HeatCapacityRatio     = MinHeatCapacityRate./MaxHeatCapacityRate; 

  
    %Decide the Coefficients for the Correlation from Table 7.5 
    %Chapter 7.6  
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
 %%                        %%Water Section Calculation%%
    
    RelativeRoughness   =  0.003; %From Engineering Toolbox 
    WaterFrictionFactor = (1./(-1.8.*log10(6.9./WaterReynoldsNumber+(RelativeRoughness/3.7)^1.11)))^2;
    
    WaterNusseltNumber  = ((WaterFrictionFactor/8).*(WaterReynoldsNumber-1000).*WaterPrandtlNumber)...
        ./(1+12.7.*sqrt(WaterFrictionFactor/8).*(WaterPrandtlNumber^(2/3)-1));
    
    WaterHeatTransferCoeff = (WaterNusseltNumber.*WaterThermalConductivity)./TubeInnerDiamter;
    
 %%                       %Air Section Calculation%
      
    HeatTransfer        = AirMassFlow.*AirHeatCapacity.*(AirOutletTemp(Counter-1) - AirInletTemp);
    HeatTransfer1Tube   =  HeatTransfer/NumberOfTubes;
    
 %Thermal Circuit From Water to Tuber Surface For one tube
                        %Individual Resistances%
    WaterConvResistance  = 1./(WaterHeatTransferCoeff.*TubeInnerSurfArea);

    TubeCondResistance   = (log(TubeOuterRadius./TubeInnerRadius)./...
    (2.*pi.*AluminumThermalConductivity.*RadiatorZ));
    
    EquivalentResistance = WaterConvResistance + TubeCondResistance;
    
 %Surface Calculation
    SurfaceTemp = HeatTransfer1Tube.*EquivalentResistance + WaterInletTemp;

    [SurfacePrandtl] = SurfaceAirProperty(SurfaceTemp,RelativeHumidity);
    
    AirNusseltNumber = C2*C1*(AirReynoldsNumber^m)*(AirPrandtlNumber^0.36).*...
        (AirPrandtlNumber/SurfacePrandtl)^0.25;
    
    AirHeatTransferCoeff = (AirNusseltNumber.*AirThermalConductivity)./TubeOuterDiameter;
    
%% Thermal Circuit Computation w/ New Heat Transfer Coeffs

   AnnularFinResistance = 1./(SingleFinEfficiency.*AirHeatTransferCoeff.*SingleFinSurfArea.*NumberOfFins);

   OuterTubeConvResistance = 1./(AirHeatTransferCoeff.*(TotalSurfAreaOneTube -...
    (NumberOfFins*SingleFinSurfArea))); 

   ParallelFinWallResistance = ((1./AnnularFinResistance) +(1./OuterTubeConvResistance)).^(-1); %1./... 
    %(OverallFinEffeciency.*HeatTransferCoeffAir.*TotalSurfArea);
                   %Thermal Cicuits%
   SingleTubeResistance = WaterConvResistance + TubeCondResistance + ParallelFinWallResistance;

   TotalResistance =  (8./SingleTubeResistance).^(-1); 
   
   WaterOutletTemp1(Counter) = AirInletTemp - (AirInletTemp-WaterInletTemp).*...
       exp(-1./(WaterMassFlow.*WaterHeatCapacity.*TotalResistance));
   
   AirOutletTemp(Counter) = SurfaceTemp - (SurfaceTemp-AirInletTemp).*...
       exp(-(pi*TubeOuterDiameter.*NumberOfTubes.*AirHeatTransferCoeff)./(AirDensity.*AirFreeStreamVelocity.*NumberOfTubes.*TubeSpacing.*AirHeatCapacity));

                        %Iteration Differance Cacl%
   AirTempDelta   = max(abs(AirOutletTemp(Counter-1)-AirOutletTemp(Counter)));
   WaterTempDelta = max(abs(WaterOutletTemp1(Counter-1)-WaterOutletTemp1(Counter)));
   
   DeltaTemp = max([AirTempDelta,WaterTempDelta]);

end 


%Heat Transfer Calculations
for d = 1
%% Heat Trnasfer Calc 1st Pass(Going down, hot)

MaxHeatTransferCheck    = (WaterInletTemp - AirInletTemp)./TotalResistance;
MaxHeatTransfer         = MinHeatCapacityRate.*(WaterInletTemp - AirInletTemp);

UA = (TotalResistance) ^(-1);

NumberOfTransferUnits = UA./MinHeatCapacityRate;
Effectiveness = 1 - exp((1./HeatCapacityRatio).* ...
    (NumberOfTransferUnits).^0.22.*(exp(-HeatCapacityRatio.*(NumberOfTransferUnits).^0.78)-1));

AttainableHeatTransferRate = Effectiveness.*MaxHeatTransfer;

WaterOutletTemp1 = (WaterInletTemp - (AttainableHeatTransferRate ./  WaterHeatCapacityRate));
AirOutletTemp = (AirInletTemp + (AttainableHeatTransferRate ./ (AirHeatCapacityRate)));


%% Heat Transfer Calc 2nd Pass(going down, cold)

MaxHeatTransfer2nd  = MinHeatCapacityRate.*(WaterOutletTemp1 - AirOutletTemp);
AttainableHeatTransferRate2nd = Effectiveness.*MaxHeatTransfer2nd;


% Temperature Calculation Second Pass 
 WaterOutletTemp2 =( WaterOutletTemp1 - (AttainableHeatTransferRate2nd ./ (WaterHeatCapacityRate)));
 
 AirOutletTemp2 = (AirOutletTemp +  (AttainableHeatTransferRate2nd ./ (MaxHeatCapacityRate)));

end

% Result Section
for d = 1
fprintf('\nWater inlet Temp: %3.1f C \n', WaterInletTemp-273.15)
fprintf('Air inlet Temp: %3.1f C \n', AirInletTemp-273.15)
fprintf('Brooklyn, Michigan Average Humidity: %3.0f%% \n', RelativeHumidity*100)
fprintf('Number of Transfer Units (NTU): %3.2f \n', NumberOfTransferUnits)
fprintf('Heat Exchanger Effectiveness: %2.1f %% \n', Effectiveness*100)
fprintf('Fin Efficiency: %2.1f %% \n', SingleFinEfficiency*100)
fprintf('Total Heat Rejection(W): %4.1f \n', -(AttainableHeatTransferRate+AttainableHeatTransferRate2nd(end)))
fprintf('Water Outlet Temperature 1 (C): %4.1f \n', WaterOutletTemp1(end)-273)
fprintf('Air Outlet Temperature (C): %4.1f \n', AirOutletTemp-273)
fprintf('Water Outlet Temperature 2 (C): %4.1f \n', WaterOutletTemp2(end)-273)  
end

% Function for Humid Air(HA) and Water Properties

function[WaterHeatCapacityRate,WaterThermalConductivity,WaterReynoldsNumber,WaterPrandtlNumber,WaterMassFlow,WaterHeatCapacity] = WaterProperty(WaterMeanTemp)
    WaterHeatCapacity         = py.CoolProp.CoolProp.PropsSI('C','P',101325,'T',WaterMeanTemp,'Water');
    WaterDensity              = py.CoolProp.CoolProp.PropsSI('D','P',101325,'T',WaterMeanTemp,'Water'); 
    WaterDynamicViscosity     = py.CoolProp.CoolProp.PropsSI('V','P',101325,'T',WaterMeanTemp,'Water');
    WaterThermalConductivity  = py.CoolProp.CoolProp.PropsSI('L','P',101325,'T',WaterMeanTemp,'Water');
    
    WaterPrandtlNumber  = (WaterHeatCapacity.*WaterDynamicViscosity)./WaterThermalConductivity;
      
    %WaterKinematicViscosity = 0.802e-6;  %Fluid Book Table A.1 30 degC 
    WaterVolumetricFlow     = (8./60000);             % Water volumetric flow (L/min -> m3/s)
    WaterMassFlow           = WaterVolumetricFlow.*WaterDensity;                   %Mass flow water (kg/s)
    WaterHeatCapacityRate   = WaterHeatCapacity.*WaterMassFlow;  % Water heat capacity rate (J/sK)
    InnerTubeCrossArea      = 1.963495408493621e-05;
    NumberOfTubes           = 8;    
    TubeInnerDiamter        = 0.005;
    WaterVelocity           = WaterVolumetricFlow./(InnerTubeCrossArea.*NumberOfTubes); 
    %LengthDiameterRatio     =  RadiatorZ./TubeInnerDiamter;   %Check if greater than 10 
    WaterReynoldsNumber     = (WaterDensity.*WaterVelocity.*TubeInnerDiamter)./WaterDynamicViscosity;
  
end

function[AirHeatCapacity,AirThermalConductivity,AirReynoldsNumber,AirPrandtlNumber,AirHeatCapacityRate,AirDensity,AirFreeStreamVelocity] = HumidAirProperty(AirMeanTemp,RelativeHumidity,AirMassFlow)
    % Humid Air Cool Prop
    AirHeatCapacity         = py.CoolProp.HumidAirProp.HAPropsSI('C','P',101325,'R',RelativeHumidity,'T',AirMeanTemp);
    AirThermalConductivity  = py.CoolProp.HumidAirProp.HAPropsSI('K','P',101325,'R',RelativeHumidity,'T',AirMeanTemp);
    AirDynamicViscosity     = py.CoolProp.HumidAirProp.HAPropsSI('M','P',101325,'R',RelativeHumidity,'T',AirMeanTemp);
    AirDensity              = (py.CoolProp.HumidAirProp.HAPropsSI('Vha','P',101325,'R',RelativeHumidity,'T',AirMeanTemp))^-1;
    AirPrandtlNumber        = (AirDynamicViscosity*AirHeatCapacity)/AirThermalConductivity;
  
    % Extra added
    RadiatorZ               = 0.244348; 
    RadiatorY               = 0.15875;
    NumberOfTubes           = 8;
    TubeSpacing             = RadiatorY./NumberOfTubes;
    TubeOuterDiameter       = 0.004064*2;
    %AirMassFlow           = x; % Air mass flow from CFD (kg/s)
    AirVolumetricFlow     = AirMassFlow./AirDensity; % Air volumetric flow (m3/s)
    AirFreeStreamVelocity = AirVolumetricFlow ./ (RadiatorZ*RadiatorY);
    AirMaxVelocity        = (TubeSpacing/(TubeSpacing-TubeOuterDiameter))*AirFreeStreamVelocity;
    AirHeatCapacityRate   = AirHeatCapacity.*AirMassFlow; 
    AirReynoldsNumber     = (AirDensity*AirMaxVelocity*TubeOuterDiameter)/AirDynamicViscosity;
end

function[SurfacePrandtl] = SurfaceAirProperty(SurfaceTemp,RelativeHumidity)
    SurfaceHeatCapacity         = py.CoolProp.HumidAirProp.HAPropsSI('C','P',101325,'R',RelativeHumidity,'T',SurfaceTemp);
    SurfaceThermalConductivity  = py.CoolProp.HumidAirProp.HAPropsSI('K','P',101325,'R',RelativeHumidity,'T',SurfaceTemp);
    SurfaceDynamicViscosity     = py.CoolProp.HumidAirProp.HAPropsSI('M','P',101325,'R',RelativeHumidity,'T',SurfaceTemp);
    SurfacePrandtl              = (SurfaceDynamicViscosity*SurfaceHeatCapacity)/SurfaceThermalConductivity;
end
