clc; clear; close all;

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 19);

% Specify sheet and range
opts.Sheet = "DATA formatted";
opts.DataRange = "A1:S425";

% Specify column names and types
opts.VariableNames = ["Var1", "Var2", "Time", "Speed", "Torque", "BatteryVoltage", "BatteryCurrent", "Var8", "MotorCurrent", "Var10", "Var11", "ControllerEfficiency", "Var13", "Var14", "Var15", "BatteryPower", "MotorPower", "TotalEfficiency", "MotorEfficiency"];
opts.SelectedVariableNames = ["Time", "Speed", "Torque", "BatteryVoltage", "BatteryCurrent", "MotorCurrent", "ControllerEfficiency", "BatteryPower", "MotorPower", "TotalEfficiency", "MotorEfficiency"];
opts.VariableTypes = ["char", "char", "double", "double", "double", "double", "double", "char", "double", "char", "char", "double", "char", "char", "char", "double", "double", "double", "double"];

% Specify variable properties
opts = setvaropts(opts, ["Var1", "Var2", "Var8", "Var10", "Var11", "Var13", "Var14", "Var15"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var2", "Var8", "Var10", "Var11", "Var13", "Var14", "Var15"], "EmptyFieldRule", "auto");

% Import the data
tbl = readtable("E:\Downloads\Zero800A_UCD (1).xls", opts, "UseExcel", false);

%% Convert to Output Type
Raw.Speed = tbl.Speed;
Raw.Torque = tbl.Torque;
Raw.BatteryVoltage = tbl.BatteryVoltage;
Raw.BatteryCurrent = tbl.BatteryCurrent;
Raw.MotorCurrent = tbl.MotorCurrent;
Raw.ControllerEfficiency = tbl.ControllerEfficiency;
Raw.BatteryPower = tbl.BatteryPower;
Raw.MotorPower = tbl.MotorPower;
Raw.TotalEfficiency = tbl.TotalEfficiency;
Raw.MotorEfficiency = tbl.MotorEfficiency;

%% Clear Temporary Variables
clear opts tbl

%% Normalize Battery Voltage
Norm.Speed = 100 ./ Raw.BatteryVoltage .* Raw.Speed;