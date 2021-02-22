clc; clear; close all;



%% Filtering Parameters
Parameter.VRange =    [450:600];
Parameter.Capacity =   6700;
Parameter.PeakPower =  65000;
Parameter.Resistance = 100;
Parameter.Mass =       36.7 .* 1000;
Parameter.CellCount =  750;
PassPercentage =       2/3;

%% Data Import
Import = string(table2cell(readtable('Melasta_Cells.csv')));

Cell.Model = Import(:,1);
Cell.VoltageNominal =      str2double(regexprep(Import(:,4), '.$', '', 'lineanchors'));
Cell.VoltageMax =          str2double(regexprep(Import(:,5), '.$', '', 'lineanchors'));
Cell.Parameter.Capacity =            str2double(Import(:,6))/1000;
Cell.DischargeContinuous = str2double(Import(:,3)) .* Cell.Parameter.Capacity;
Cell.DischargeMax =        str2double(Import(:,7));
Cell.Parameter.Mass =                str2double(extractBefore(Import(:,8), '±'));
Cell.Impedance =           str2double(extractBefore(Import(:,9), '±'));
Cell.Material =            Import(:,14);
clear Import;

%% Accumulator Configs / Voltage Range Sweep
Cell.Pack.Series =               round(Parameter.VRange ./ Cell.VoltageMax);
Cell.Pack.Parallel =             round(Parameter.Capacity ./ (Cell.Pack.Series .* Cell.Parameter.Capacity .* Cell.VoltageNominal));
Cell.Pack.Voltage =              Cell.VoltageMax .* Cell.Pack.Series;
Cell.Pack.Capacity =   Cell.Pack.Series .* Cell.Pack.Parallel .* Cell.VoltageNominal .* Cell.Parameter.Capacity;
Cell.Pack.PeakPower =  Cell.Pack.Series .* Cell.Pack.Parallel .* Cell.VoltageMax .* Cell.DischargeMax;
Cell.Pack.Resistance = Cell.Impedance .* Cell.Pack.Series ./ Cell.Pack.Parallel;
Cell.Pack.Mass =       Cell.Parameter.Mass .* Cell.Pack.Series .* Cell.Pack.Parallel;
Cell.Pack.Flag =                 ones(size(Cell.Pack.Series));
Cell.Pack.CellCount =  Cell.Pack.Series .* Cell.Pack.Parallel;

%% Data Flagging / Filtering
Cell.Pack.Capacity(Cell.Pack.Capacity < Parameter.Capacity) =       NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.Capacity)) =  0;
Cell.Pack.PeakPower(Cell.Pack.PeakPower < Parameter.PeakPower) =    NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.PeakPower)) = 0;
Cell.Pack.Resistance(Cell.Pack.Resistance > Parameter.Resistance) = NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.PeakPower)) = 0;
Cell.Pack.Mass(Cell.Pack.Mass > Parameter.Mass) =                   NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.Mass)) =      0;
Cell.Pack.Parameter.CellCount(Cell.Pack.CellCount > Parameter.CellCount) =    NaN;
    Cell.Pack.Flag(isnan(Cell.Pack.CellCount)) = 0;
    
Cell.Performance = sum(Cell.Pack.Flag');

i = find(Cell.Performance>length(Parameter.VRange)*PassPercentage);

