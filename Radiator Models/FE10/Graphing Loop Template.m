% Graphing code

% for air mass flow vs heat rejection, put this around code
% remember to comment out result section
for d = 1
x(1)=0.01;
i=1;
while x(i) < 1
 AirMassFlow     = x(i);

 HeatRejection(i)=-(AttainableHeatTransferRate+AttainableHeatTransferRate2nd(end));
AirHeatTransferCoeffM(i) = AirHeatTransferCoeff;
 tempx = x(i)+0.01;
 i = i + 1;
 x(i) = tempx;

clearvars -except x HeatRejection i AirHeatTransferCoeffM
end

plot(x(1:end-1),AirHeatTransferCoeffM)
title("AirHeatTransferCoeffM vs Air Mass Flow Rate")
xlabel("Air Mass Flow (kg/s)")
ylabel("AirHeatTransferCoeff")
end

% for air inlet temp vs air heat transfer coeff m 
for d = 1

x(1)=273.15;
i=1;
while x(i) < 400
    AirInletTemp   = x(i);   

    HeatRejection(i)=-(AttainableHeatTransferRate+AttainableHeatTransferRate2nd(end));
    AirHeatTransferCoeffM(i) = AirHeatTransferCoeff;
    tempx = x(i)+0.1;
    i = i + 1;
    x(i) = tempx;

clearvars -except x HeatRejection i AirHeatTransferCoeffM
end

    plot(x(1:end-1)-273.15,AirHeatTransferCoeffM)
    title("AirHeatTransferCoeffM vs Air Inlet Temp")
    xlabel("Air Inlet Temp (C)")
    ylabel("AirHeatTransferCoeff")
end

% for sensitivity
for d = 1
Intemp=35;
OutTemp(1)=Intemp;

i=1;

while i < 1200
    WaterInletTemp = OutTemp(i)+273.15;

HeatRejection(i)=-(AttainableHeatTransferRate+AttainableHeatTransferRate2nd(end));
AirHeatTransferCoeffM(i) = AirHeatTransferCoeff;
WaterTempInlet(i)=WaterInletTemp-273.15 ;

Q=500-HeatRejection(i);% W
Volume = 1.7/1000;% 
Density = 997; % kg/m3
Mass = Density*Volume;
c = 4179; %J/kgc


tempx=WaterOutletTemp2(end)-273.15;
TempDiff(i) = Q/(Mass*c);
i=i+1;
OutTemp(i) = WaterOutletTemp2(end)-273.15;


clearvars -except OutTemp i HeatRejection TempDiff AirHeatTransferCoeffM WaterTempInlet

end

%Watts = MassFlowRate*c*tempdiff;
% i=[1:length(OutTemp)];
% plot(i,OutTemp)
% title("Water Temperature Outlet vs Time")
% xlabel("Time (s)")
% ylabel("Water Temperature Outlet(C)")

% 
% i=[1:length(HeatRejection)];
% plot(i,HeatRejection)
% title("Heat Rejection vs Time")
% xlabel("Time (s)")
% ylabel("Heat Rejection(W)")



i=[1:length(WaterTempInlet)];
plot(i,WaterTempInlet)
title("WaterTempInlet vs Time")
xlabel("Time (s)")
ylabel("WaterTempInlet (C)")

end