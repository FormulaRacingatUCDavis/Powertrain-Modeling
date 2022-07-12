% AirFreeStreamVelocity = linspace(1,15,100);
% AirInletTemp          = linspace(25+273,40+273,100);

[AirFreeStreamVelocity, AirInletTemp] = meshgrid(linspace(1,15,20), linspace(25+273,40+273,20));
[~ , WaterInletTemp] = meshgrid(linspace(1,15,20), linspace(60+273,80+273,20  ));
[WaterMassFlow ,~] = meshgrid(linspace(0.06,0.2,20), linspace(1,15,20 ));
 
HeatTransfer = zeros(length(AirInletTemp),length(AirFreeStreamVelocity),length(WaterInletTemp), length(WaterMassFlow));
RadiatorPressDrop = zeros(length(AirInletTemp),length(AirFreeStreamVelocity),length(WaterInletTemp), length(WaterMassFlow));
WaterOutletTemp = zeros(length(AirInletTemp),length(AirFreeStreamVelocity),length(WaterInletTemp), length(WaterMassFlow));
TotalPressureDrop = zeros(length(WaterMassFlow), length(WaterInletTemp));
for a = 1:length(WaterInletTemp)
    for i = 1:length(AirFreeStreamVelocity)
        for t = 1:length(AirInletTemp)
            for c = 1:length(WaterMassFlow)
       

        [ ~, WaterOutletTemp(a,t,i,c), ~,~, HeatTransfer(a,t,i,c), RadiatorPressDrop(a,t,i,c)] = RadiatorThermalCircuitReqHT(WaterInletTemp(a,1),AirInletTemp(t,1),AirFreeStreamVelocity(1,i), WaterMassFlow(1,c) );
        x = [a,t,i,c];
        
       disp(x)
       
       TotalPressureDrop(c,a) = SystemPressureDropConstTemp(WaterMassFlow(1,c), WaterInletTemp(a,1));
            end 
        end
    end
end 
%% Indexing Values into 4D Heat Tranfer Matrix into Cells
    %Indexing Water Inlet Temp and Water Mas Flow Rate with Air Velocity
    %Constant and Air Temperature Constant
HTAirVeloXAirInletTempConst = cell(length(AirFreeStreamVelocity),length(AirInletTemp));
index = zeros(size(HTAirVeloXAirInletTempConst));
    for y1 = 1:length(AirInletTemp)
        for x1 = 1:length(AirFreeStreamVelocity)
            for y2 = 1:length(WaterInletTemp)
                for x2 = 1:length(WaterMassFlow)
                    
                index(x2,y2) = sub2ind(size(HeatTransfer),y2,y1,x1,x2);
                end
            end
                
            HTAirVeloXAirInletTempConst{x1, y1} = HeatTransfer(index);
        end
    end
    
HTWaterMassFlowXWaterInletTempConst = cell(length(WaterMassFlow),length(WaterInletTemp));
index = zeros(size(HTWaterMassFlowXWaterInletTempConst));
for y2 = 1:length(WaterInletTemp)
    for x2 = 1:length(WaterMassFlow)
        for y1 = 1:length(AirInletTemp)
            for x1 = 1:length(AirFreeStreamVelocity)
                index(x1,y1) = sub2ind(size(HeatTransfer),y2,y1,x1,x2);
            end
        end
        HTWaterMassFlowXWaterInletTempConst{x2, y2} = HeatTransfer(index);
    end
end

        


%% Retrieving Loactions of Values of Interest

% With Respect to Air Velocity 
 AirFreeStreamVelocityReferance = [1, 5, 10, 15];
 AirFreeStreamVelocityPlot      = zeros(1,length(AirFreeStreamVelocityReferance));
 LocationAirVelo                = zeros(1,length(AirFreeStreamVelocityReferance));
 
 for i = 1:length(AirFreeStreamVelocityReferance)
    [value, LocationAirVelo(i)] = min(abs(AirFreeStreamVelocity(1,:) - AirFreeStreamVelocityReferance(i)));    %// linear index of closest entry
    AirFreeStreamVelocityPlot(i) = AirFreeStreamVelocity(1,LocationAirVelo(i));
 end 
% With Respect to Air Inlet Temp
 AirInletTempReferance = [298, 303, 308, 313]';
 AirInletTempPlot      = zeros(1,length(AirInletTempReferance));
 AirInletTempLocation  = zeros(1,length(AirInletTempReferance));
 
 for i = 1:length(AirInletTempReferance)
    [value, AirInletTempLocation(i)] = min(abs(AirInletTemp(:,1) - AirInletTempReferance(i)));    
    AirInletTempPlot(i) = AirInletTemp(AirInletTempLocation(i),1);
 end 
 
 % With Respect to Water Mass Flow 
 WaterMassFlowReferance = [0.063, 0.0944, 0.126, 0.145, 0.158, 0.189];
 WaterMassFlowPlot      = zeros(1,length(WaterMassFlowReferance));
 WaterMassFlowLocation  = zeros(1,length(WaterMassFlowReferance));
 
 for i = 1:length(WaterMassFlowReferance)
    [value, WaterMassFlowLocation(i)] = min(abs(WaterMassFlow(1,:) - WaterMassFlowReferance(i)));    
    WaterMassFlowPlot(i) = WaterMassFlow(1,WaterMassFlowLocation(i));
 end
 
 % With Respect to Water Inlet Temp
 
 WaterInletTempReferance = [333, 338, 343, 348, 353];
 WaterInletTempPlot      = zeros(1,length(WaterInletTempReferance));
 WaterInletTempLocation  = zeros(1,length(WaterInletTempReferance));
 
 for i = 1:length(WaterInletTempReferance)
     [value, WaterInletTempLocation(i)] = min(abs(WaterInletTemp(:,1) - WaterInletTempReferance(i)));
     WaterInletTempPlot(i) = WaterInletTemp(WaterInletTempLocation(i),1);
 end
 
 
 %% Plotting Projections of 4-D Matrix
 
 %With Respect to Free Stream Air Velocity and Air Inlet Temperature
 figure('Name','Constant Air Velocity & Temperature ');
 tiledlayout(length(LocationAirVelo)-2 , length(AirInletTempLocation))
 
 for x1 = 1:length(LocationAirVelo)
     for y1 = 1:length(AirInletTempLocation)      
         if x1 == 3 && y1 == 1
             figure
              tiledlayout(length(LocationAirVelo)-2 , length(AirInletTempLocation))
               nexttile 
              surf(WaterMassFlow, WaterInletTemp-273,HTAirVeloXAirInletTempConst{x1, y1})
              xlabel('Water Mass Flow (kg/s)')
              ylabel('Water Inlet Temperature (deg C)')
              zlabel('Heat Transfer (W)')
              title('Inlet Air Speed and Temperature of')
              subtitle([num2str(AirFreeStreamVelocity(1,LocationAirVelo(x1))), 'm/s & ', ...
             num2str(AirInletTemp(AirInletTempLocation(y1),1)-273),' deg C'])
         elseif x1 > 3
              nexttile 
              surf(WaterMassFlow, WaterInletTemp-273,HTAirVeloXAirInletTempConst{x1, y1})
              xlabel('Water Mass Flow (kg/s)')
              ylabel('Water Inlet Temperature (deg C)')
              zlabel('Heat Transfer (W)')
              title('Inlet Air Speed and Temperature of')
             subtitle([num2str(AirFreeStreamVelocity(1,LocationAirVelo(x1))), 'm/s & ', ...
             num2str(AirInletTemp(AirInletTempLocation(y1),1)-273),' deg C'])
         else 
             nexttile 
             surf(WaterMassFlow, WaterInletTemp-273,HTAirVeloXAirInletTempConst{x1, y1})
             xlabel('Water Mass Flow (kg/s)')
             ylabel('Water Inlet Temperature (deg C)')
             zlabel('Heat Transfer (W)')
             title('Inlet Air Speed and Temperature of')
             subtitle([num2str(AirFreeStreamVelocity(1,LocationAirVelo(x1))), 'm/s & ', ...
              num2str(AirInletTemp(AirInletTempLocation(y1),1)-273),' deg C'])
         end
     end
 end
 
 % With Respect to Water Mass Flow and Water Inlet Temperature
 figure('Name','Constant Water Mass Flow & Inlet Temperature '); 
tiledlayout(length(WaterMassFlowLocation)-3, length(WaterInletTempLocation))
for x2 = 1:length(WaterMassFlowLocation)
    for y2 = 1:length(WaterInletTempLocation)
        if x2 == 4 && y2 == 1 
            figure('Name','Constant Water Mass Flow & Inlet Temperature ') 
            tiledlayout(length(WaterMassFlowLocation)-3, length(WaterInletTempLocation))
            nexttile
            surf(AirFreeStreamVelocity,AirInletTemp - 273, HTWaterMassFlowXWaterInletTempConst{x2,y2})
            xlabel('Air Inlet Velocity')
            ylabel('Air Inlet Temperature')
            zlabel('Heat Transfer (W)')
            title('Inlet Water Flow and Temperature of')
            subtitle([num2str(WaterMassFlow(1,WaterMassFlowLocation(x2))),'kg/s & '...
                num2str(WaterInletTemp(WaterInletTempLocation(y2),1)-273), ' deg C'])
        elseif x2 > 4 
            nexttile
            surf(AirFreeStreamVelocity,AirInletTemp - 273, HTWaterMassFlowXWaterInletTempConst{x2,y2})
            xlabel('Air Inlet Velocity')
            ylabel('Air Inlet Temperature')
            zlabel('Heat Transfer (W)')
            title('Inlet Water Flow and Temperature of')
            subtitle([num2str(WaterMassFlow(1,WaterMassFlowLocation(x2))),'kg/s & '...
                num2str(WaterInletTemp(WaterInletTempLocation(y2),1)-273), ' deg C'])
        else 
             nexttile
            surf(AirFreeStreamVelocity,AirInletTemp, HTWaterMassFlowXWaterInletTempConst{x2,y2})
            xlabel('Air Inlet Velocity')
            ylabel('Air Inlet Temperature')
            zlabel('Heat Transfer (W)')
            title('Inlet Water Flow and Temperature of')
            subtitle([num2str(WaterMassFlow(1,WaterMassFlowLocation(x2))),'kg/s & '...
                num2str(WaterInletTemp(WaterInletTempLocation(y2),1)-273), ' deg C'])
        end
    end
end

figure ('Name','System Pressure Drop')
surf(WaterMassFlow, WaterInletTemp - 273, TotalPressureDrop)
xlabel('Water Mass Flow kg/s')
ylabel('Water Inlet Temperature deg C')
zlabel('Pressure Drop')
title('System Pressure Drop 1-D')


            