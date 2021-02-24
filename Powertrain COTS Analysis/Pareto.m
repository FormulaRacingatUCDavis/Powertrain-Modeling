clc; clear; close all;

%% Filtering Parameters
Parameter.VRange =    [450:600];
Parameter.Capacity =   6700;
Parameter.PeakPower =  65000;
Parameter.Resistance = 125;
Parameter.Mass =       38;
Parameter.CellCount =  750;
PassPercentage =       2/3;

EnduranceActionLoad   = 22156741.88;
TempAmbient = 35;
EnduranceTime = 1943;

%% Data Import
Import = string(table2cell(readtable('Melasta_Cells.csv', 'PreserveVariableNames', true)));

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
Cell.Pack.CellCount(Cell.Pack.CellCount > Parameter.CellCount) =    NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.CellCount)) =  false;
Cell.Pack.CellCount(Cell.Pack.CellCount < 150) =    NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.CellCount)) =  false;

%% Pareto Plotting

for i = 1:size(Cell.Parameter.Model,1)
    p = scatter3(Cell.Pack.Mass(i,Cell.Pack.Flag(i,:)) , Cell.Pack.Rejection(i,Cell.Pack.Flag(i,:)) , Parameter.VRange(Cell.Pack.Flag(i,:)) , '.');
    
    p.DataTipTemplate.DataTipRows(end+1) = Cell.Parameter.Model(i);
    
    hold on
end

title('Accumulator Heat Requirement vs. Mass')
ylabel('Heat Rejection Required [W]')
ylim([0 1000])
xlabel('Cell Mass [kg]')
xlim([20 40])
hold off