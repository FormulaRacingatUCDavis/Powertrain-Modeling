clc;
%% TargetedCOTSAnalysis
% This script will serve as a supplement to the COTS Analsysis script,
% using the powertrain structure and design constraints produced in the 
% former script in order to perform calculations not necessary for the
% general plotting, but nonetheless important for cell choice

% Accumulator.Voltage = [100:600];
% for k = 1 : length(Cell)
%     
%     if AnyFieldNaN( Cell(k) )
%         Cell(k).Flag = "(0) Insufficient Information";
%         Flag.Info = Flag.Info + 1;
%         continue
%     end
%     
%     Cell(k).Series = round(Accumulator.Voltage ./ Cell(k).VoltageMax);
%     Cell(k).Parallel = round( Accumulator.Capacity ./ (Cell(k).Series .*...
%                               Cell(k).Capacity .* Cell(k).VoltageMax));
%     Cell(k).MassAccumulator = Cell(k).Series .* Cell(k).Parallel .* Cell(k).Mass ./ 1000;  % [kg]
%     Cell(k).ResistanceAccumulator = Cell(k).Resistance .* Cell(k).Series ./ Cell(k).Parallel;
%     
%     
% end
% 
% for k = 1 : length(Cell)
% 
%     if isempty(Powertrain(i,j,k).Flag)
% 
%         % Percent of total desired power available within cooling
%         % constraints before throttling occurs
%         Cell(k).PowerAvail = ((Cell(k).MassAccumulator .* Cell(k).Cp .* 1000 .*...
%                                        (60 - TempAmbient) + 0 .* EnduranceTime) ./...
%                                       ((117.6 ./ (Cell(k).Series .*... 
%                                         Cell(k).VoltageMax)).^2 .* Cell(k).ResistanceAccumulator .*...
%                                         EnduranceActionLoad)).^(1/2) ./ (10/6) ./ (Accumulator.PowerPeak/50000);
%     end
% 
% end

for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)

            if isempty(Powertrain(i,j,k).Flag)
                
                % Percent of total desired power available within cooling
                % constraints before throttling occurs
                Powertrain(i,j,k).PowerAvail = ((Powertrain(i,j,k).Accumulator.Mass .* 1000 .* Cell(k).Cp .*...
                                              (60 - TempAmbient) + Accumulator.Rejection .* EnduranceTime) ./...
                                              (Powertrain(i,j,k).Accumulator.Resistance .*...
                                               EnduranceActionLoad)).^(1/2) ./ (10/6) ./ (Accumulator.PowerPeak/50000) .* ...
                                              (Powertrain(i,j,k).Accumulator.Series .* Powertrain(i,j,k).Cell.VoltageMax ./ 117.6) .*...
                                               Accumulator.PowerPeak ./ 1000;
%                 Powertrain(i,j,k).PowerAvail = Powertrain(i,j,k).PowerAvail ./ (10/6) ./ (Accumulator.PowerPeak/50000) ./...
%                                                (117.6 ./ (Powertrain(i,j,k).Accumulator.Series .* Powertrain(i,j,k).Cell.VoltageMax));
            end
            
        end
    end
end

figure(2)
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                p = scatter(Powertrain(i,j,k).Accumulator.Voltage,...
                             Powertrain(i,j,k).PowerAvail,...
                             '.','MarkerEdgeColor', Powertrain(i,j,k).Color);
                
                p.DataTipTemplate.DataTipRows(end+1) = Powertrain(i,j,k).Cell.Model;
                p.DataTipTemplate.DataTipRows(end+1) = Powertrain(i,j,k).Cell.Manufacturer;
                
                hold on
            end
        
        end
    end
end

title('Power Usable Without Thermal Attenuation Occurring')
xlabel('Voltage')
xlim([0 600])
ylabel('Powertrain Mass [kg]')
ylabel('Usable Power [kW]')
hold off

%% Local Functions
function Flag = AnyFieldNaN( Structure )
    Fields = fieldnames( Structure );
    
    Flag = false;
    for f = 1:length(Fields)
        if ~isempty( Structure.(Fields{f}) )
            
               if any( isnan( Structure.(Fields{f}) ) )
                   Flag = true;
                   return
               end

        end
    end
end