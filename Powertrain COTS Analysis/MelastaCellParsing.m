clc; clear; close all;

%% Filtering Parameters
Parameter.VRange =    [450:600];
Parameter.Capacity =   6700;
Parameter.PeakPower =  65000;
Parameter.Resistance = 200;
Parameter.Mass =       40;
Parameter.CellCount =  200;
PassPercentage =       1/2;

EnduranceActionLoad   = 22156741.88;
TempAmbient = 35;
EnduranceTime = 1943;

%% Data Import
Import = string(table2cell(readtable('Melasta_Cells.csv', 'PreserveVariableNames', true)));
Import(str2double(Import(:,6)) > 7700,:) = [];
Import(str2double(Import(:,6)) < 7000,:) = [];

Cell.Parameter.Model =               Import(:,1);
Cell.Parameter.VoltageNominal =      str2double(regexprep(Import(:,4), '.$', '', 'lineanchors'));
Cell.Parameter.VoltageMax =          str2double(regexprep(Import(:,5), '.$', '', 'lineanchors'));
Cell.Parameter.Capacity =            str2double(Import(:,6))/1000;
Cell.Parameter.DischargeContinuous = str2double(Import(:,3)) .* Cell.Parameter.Capacity;
Cell.Parameter.DischargeMax =        str2double(Import(:,7));
Cell.Parameter.Mass =                str2double(extractBefore(Import(:,8), '±'));
Cell.Parameter.Impedance =           str2double(extractBefore(Import(:,9), '±'));
Cell.Parameter.Material =            Import(:,14);
clear Import;

%% Accumulator Configs / Voltage Range Sweep
Cell.Pack.Series =     round(Parameter.VRange ./ Cell.Parameter.VoltageMax);
Cell.Pack.Parallel =   round(Parameter.Capacity ./ (Cell.Pack.Series .* Cell.Parameter.Capacity .* Cell.Parameter.VoltageNominal));
Cell.Pack.Voltage =    Cell.Parameter.VoltageMax .* Cell.Pack.Series;
Cell.Pack.Capacity =   Cell.Pack.Series .* Cell.Pack.Parallel .* Cell.Parameter.VoltageNominal .* Cell.Parameter.Capacity;
Cell.Pack.PeakPower =  Cell.Pack.Series .* Cell.Pack.Parallel .* Cell.Parameter.VoltageMax .* Cell.Parameter.DischargeMax;
Cell.Pack.Resistance = Cell.Parameter.Impedance .* Cell.Pack.Series ./ Cell.Pack.Parallel;
Cell.Pack.Mass =       Cell.Parameter.Mass .* Cell.Pack.Series .* Cell.Pack.Parallel ./ 1000;
Cell.Pack.Flag =       true(size(Cell.Pack.Series));
Cell.Pack.CellCount =  Cell.Pack.Series .* Cell.Pack.Parallel;

Cell.Pack.Temp =      (10/6 .* 117.6./(Cell.Pack.Series .* Cell.Parameter.VoltageMax) .* Cell.Pack.PeakPower / 50000).^2 .*...
                      (Cell.Parameter.Impedance ./ 1000 .* Cell.Pack.Series ./ Cell.Pack.Parallel) .* EnduranceActionLoad ./...
                      (Cell.Pack.Mass .* 1000 .* 0.902);

Cell.Pack.Rejection = (Cell.Pack.Temp + TempAmbient - 60) .* (Cell.Pack.Mass .* 1000 .* 0.902) ./ EnduranceTime;

%% Data Flagging / Filtering
Cell.Pack.Capacity(Cell.Pack.Capacity < Parameter.Capacity) =       NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.Capacity)) =   false;
Cell.Pack.PeakPower(Cell.Pack.PeakPower < Parameter.PeakPower) =    NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.PeakPower)) =  false;
Cell.Pack.Resistance(Cell.Pack.Resistance > Parameter.Resistance) = NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.Resistance)) = false;
Cell.Pack.Mass(Cell.Pack.Mass > Parameter.Mass) =                   NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.Mass)) =       false;
Cell.Pack.CellCount(Cell.Pack.CellCount < Parameter.CellCount) =    NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.CellCount)) =  false;
    
Cell.Performance = sum(Cell.Pack.Flag');

i = find(Cell.Performance>length(Parameter.VRange)*PassPercentage);
%% Data Export and Spacing
Import = string(table2cell(readtable('Melasta_Cells.csv', 'PreserveVariableNames', true)));

Final = Cell.Parameter.Model(i,:);
Final(:,5) = Cell.Parameter.VoltageNominal(i,:);
Final(:,6) = Cell.Parameter.VoltageMax(i,:);
Final(:,7) = Cell.Parameter.Capacity(i,:);
Final(:,8) = Cell.Parameter.DischargeContinuous(i,:);
Final(:,9) = Cell.Parameter.DischargeMax(i,:);
Final(:,10) = 2 .* Cell.Parameter.Impedance(i,:);
Final(:,14) = str2double(extractBefore(Import(i,10), '±'));
Final(:,15) = str2double(extractBefore(Import(i,11), '±'));
Final(:,16) = str2double(extractBefore(Import(i,12), '±'));
Final(:,17) = Cell.Parameter.Mass(i,:);

writematrix(Final,'Desktop\PossibleMelasta.csv')

% %% Pareto Plotting
% 
% for i = 1:size(Cell.Parameter.Model,1)
%     p = scatter3(Cell.Pack.Mass(i,Cell.Pack.Flag(i,:)) , Cell.Pack.Rejection(i,Cell.Pack.Flag(i,:)) , Parameter.VRange(Cell.Pack.Flag(i,:)) , '.');
%     
%     p.DataTipTemplate.DataTipRows(end+1) = Cell.Parameter.Model(i);
%     
%     hold on
% end
% 
% title('Accumulator Heat Requirement vs. Mass')
% ylabel('Heat Rejection Required [W]')
% ylim([0 1000])
% xlabel('Cell Mass [kg]')
% xlim([20 40])
% hold off