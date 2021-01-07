clc; clear; close all;

%% Desired Pack Characteristics
Pack.V = (1:600);    % Pack Voltage [V]
Pack.E = 6.7;    % Pack Energy Capacity [kWh]

%% Cell Characteristics
x = GetGoogleSpreadsheet('1Cy-lqsHlInxsQ2TkO2ET7gU_Vj2Gqh1zKu5qQbk8rKk')
x = (x(17:end,:));
for i = 1:length(x)
Cell(i) = struct('Name',x(i,1), 'V',str2double(x(i,6)), 'Ah',str2double(x(i,7)), 'ContD',str2double(x(i,8)),...
    'MaxD',str2double(x(i,9)), 'IR',str2double(x(i,10)), 'm',str2double(x(i,21)));
end
clear i; clear x;

%% Pack Calculations
Accum.S = floor(Pack.V ./ Cell.V);   % Cells in series required to reach desired Voltage
Accum.P = round(Pack.E ./ (Accum.S .* Cell.V .* Cell.Cap) .* 1000); % Cells in parallel required to reach desired Capacity

Accum.IR = Cell.IR .* Accum.S ./ Accum.P; % Total pack Internal Resistance [ohms]
Accum.C = Cell.Cp .* Cell.m .* Accum.S .* Accum.P;   % Total cell heat capacity [J/K]

%% Endurance Import
Import = load('FE6Endurance.mat');
Endurance = Import.FE6Endurance;
Endurance(:,3) = Endurance(:,3) .* 100 ./ 60;
clear Import;

%% Heat Generation Calculations
Heatgen = (117.6 ./ Pack.V).^2 .* sum((Endurance(2:end,3)).^2 .* (Endurance(2:end,1) - Endurance(1:end-1,1))) .* Accum.IR;

Tdelt = Heatgen ./ Accum.C;

%% Filtering Stuff



%% Plotting Stuff
figure(1)
for i = 1:length(Cell.Name)
plot(Pack.V,Tdelt(i,:))
hold on
end
hold off
%% Local Functions

function result = GetGoogleSpreadsheet(DOCID)
% result = GetGoogleSpreadsheet(DOCID)
% Download a google spreadsheet as csv and import into a Matlab cell array.
%
% [DOCID] see the value after 'key=' in your spreadsheet's url
%           e.g. '0AmQ013fj5234gSXFAWLK1REgwRW02hsd3c'
%
% [result] cell array of the the values in the spreadsheet
%
% IMPORTANT: The spreadsheet must be shared with the "anyone with the link" option
%
% This has no error handling and has not been extensively tested.
% Please report issues on Matlab FX.
%
% DM, Jan 2013
%


loginURL = 'https://www.google.com'; 
csvURL = ['https://docs.google.com/spreadsheet/ccc?key=' DOCID '&output=csv&pref=2'];

%Step 1: go to google.com to collect some cookies
cookieManager = java.net.CookieManager([], java.net.CookiePolicy.ACCEPT_ALL);
java.net.CookieHandler.setDefault(cookieManager);
handler = sun.net.www.protocol.https.Handler;
connection = java.net.URL([],loginURL,handler).openConnection();
connection.getInputStream();

%Step 2: go to the spreadsheet export url and download the csv
connection2 = java.net.URL([],csvURL,handler).openConnection();
result = connection2.getInputStream();
result = char(readstream(result));

%Step 3: convert the csv to a cell array
result = parseCsv(result);

end

function data = parseCsv(data)
% splits data into individual lines
data = textscan(data,'%s','whitespace','\n');
data = data{1};
for ii=1:length(data)
   %for each line, split the string into its comma-delimited units
   %the '%q' format deals with the "quoting" convention appropriately.
   tmp = textscan(data{ii},'%q','delimiter',',');
   data(ii,1:length(tmp{1})) = tmp{1};
end

end

function out = readstream(inStream)
%READSTREAM Read all bytes from stream to uint8
%From: http://stackoverflow.com/a/1323535

import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;
byteStream = java.io.ByteArrayOutputStream();
isc = InterruptibleStreamCopier.getInterruptibleStreamCopier();
isc.copyStream(inStream, byteStream);
inStream.close();
byteStream.close();
out = typecast(byteStream.toByteArray', 'uint8'); 

end