%%
clc; clear; close all;

%% Constants
a = 0.000244;
b = 1.073;
c = 1.744;
Offset = 268;

PowerPeak = 80; %[kW]
PackVoltage = 529; %[Vdc]
PeakPackCurrent = (ceil(PowerPeak*1000/PackVoltage));

%% PM100DZ Inputs
MotorCurrent = [0:1:PeakPackCurrent]; %[Arms]
PM100DZPowerLoss = a .* (PackVoltage.^b) .* (MotorCurrent.^c) + Offset; %[W]
PM100DZPowerLossMax = max(PM100DZPowerLoss(:));

%% CM200DZ Inputs
%CM200DZBusVoltage = [200:1:600]; %[Vdc]
%CM200DZMotorCurrent = [0:0.625:250]; %[Arms]
%CM200DZPowerLoss = a .* (CM200DZBusVoltage.^b) .* (CM200DZMotorCurrent.^c) + Offset; %[W]
%CM200DZPowerLossMax = max(CM200DZPowerLoss(:))

%% 2D Plotting

Figure(1) = figure('Name','PM100DZ Power Dissipation Curves'); 
PeakMotorCurrent = [0:1:MotorCurrent]; %[Arms]
plot(MotorCurrent, PM100DZPowerLoss);
title({'Cascadia Motion PM100DZ Inverter','Power Dissipation @ 529Vdc, 80kW Peak'});
xlabel( 'Motor Current, Arms' ); ylabel( 'Power Dissipation, W' );
set(gca,'xTick',0:20:200); set(gca,'yTick',0:100:2000);
grid on

%plot(CM200DZMotorCurrent, CM200DZPowerLoss)
%title({'Cascadia Motion Inverter','CM200DZ Power Loss'});
%xlabel( 'Motor Current, Arms' ); ylabel( 'Power Loss, W' );
%set(gca,'xTick',0:25:250); set(gca,'yTick',0:500:4000);
%grid on

%% 3D Plotting
% PM100DZ
% MotorCurrent2 = [0:1:200];
% BusVoltage = [0:1:600]; %[Vdc]
% [BusVoltage,MotorCurrent2] = meshgrid(BusVoltage,MotorCurrent2);
% PM100DZPowerLoss3D = a .* (BusVoltage.^b) .* (MotorCurrent2.^c) + Offset; %[W]
% Figure(3) = figure('Name', 'Cascadia Motion PM100DZ Power Loss');
% %subplot(1,2,1)
% h = surf(PM100DZPowerLoss3D);
% set(h,'LineStyle','none')
% colorbar
% %caxis([0 1500])
% 
% title({'Cascadia Motion PM100DZ Inverter','Power Dissipation',''});
% xlabel( 'Bus Voltage, Vdc' ); ylabel( 'Motor Current, Arms' ); zlabel ( 'Power Dissipation, W'); 
% xlim([0,601]); ylim([0,200]); zlim([0,2750]);
% set(gca,'xTick',0:100:600); set(gca,'yTick',0:25:200); set(gca,'zTick',0:500:2750);
% 
% % CM200DZ
% %[CM200DZBusVoltage,CM200DZMotorCurrent] = meshgrid(CM200DZBusVoltage,CM200DZMotorCurrent);
% %CM200DZPowerLoss3D = a .* (CM200DZBusVoltage.^b) .* (CM200DZMotorCurrent.^c) + Offset; %[W]
% %Figure(4) = figure('Name', 'Rhinehart CM200DZ Power Loss');
% %subplot(1,2,2)
% %h2 = surf(CM200DZPowerLoss3D);
% %set(h2,'LineStyle','none')
% %colorbar
% 
% %title({'Cascadia Motion Inverter','CM200DZ Power Loss',''});
% %xlabel( 'Bus Voltage, Vdc' ); ylabel( 'Motor Current, Arms' ); zlabel ( 'Power Loss, W'); 
% %xlim([0,501]); ylim([0,501]); zlim([0,4000]);
% %set(gca,'yTick',0:100:500); set(gca,'xTick',0:100:500); set(gca,'zTick',0:500:4000);
