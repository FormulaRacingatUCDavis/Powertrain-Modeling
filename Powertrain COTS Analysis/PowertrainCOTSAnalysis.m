clc; clear; close all;

%% Powertrain COTS Analysis
% This script accesses the powertrain COTS catalogue Google Spreadsheet and
% then loops through various motor, controller, and cell combinations.

%% COTS Database Imports
[Cell, Controller, Motor] = SpreadsheetImport();

%% Desired Accumulator Characteristics
% Generate accumulator performance requirements based on the power demand
% and 
Pack(1,1,1).Capacity = 1;

Pack = struct();
for i = 1 : length(Cell)
    for j = 1 : length(Controller)
        for k = 1 : length(Motor)
            
            Pack(i,j,k).Capacity = Pack(1,1,1).Capacity;
            
            %%% Compatibility Checks (Motor / Controller Compat)
            if Controller.Voltage.Max < Motor.Voltage.Min || Controller.Voltage.Min > Motor.Voltage.Max
               Pack(i,j,k).Flag = 'Controller & Motor Voltages Not Compatible';
               return
            end
            
            Pack.Power.Cont = 1;
            Pack.Power.Max  = 1;
            
            
            Pack.Energy
        end
    end
end

Pack.V = (1:600);    % Pack Voltage [V]
Pack.E = 6.7;    % Pack Energy Capacity [kWh]



%% Pack Calculations
Accum.S = floor(Pack.V ./ Cell.V);   % Cells in series required to reach desired Voltage
Accum.P = round(Pack.E ./ (Accum.S .* Cell.V .* Cell.Cap) .* 1000); % Cells in parallel required to reach desired Capacity

Accum.IR = Cell.IR .* Accum.S ./ Accum.P; % Total pack Internal Resistance [ohms]
Accum.C = Cell.Cp .* Cell.m .* Accum.S .* Accum.P;   % Total cell heat capacity [J/K]


%% Filtering Stuff



%% Plotting Stuff
figure(1)
for i = 1:length(Cell.Name)
plot(Pack.V,Tdelt(i,:))
hold on
end
hold off

%% Local Functions   
function [Cell, Controller, Motor] = SpreadsheetImport()
    % Import Spreadsheets
    Spreadsheet.Cell = GetGoogleSpreadsheet( ...
        '1yw_K_Wh0mPWjYlOh-KRkUNIrC4Pn1hJrKmpQw7_VwTg', 'Accumulator Cell' );
    
    Spreadsheet.Controller = GetGoogleSpreadsheet( ...
        '1yw_K_Wh0mPWjYlOh-KRkUNIrC4Pn1hJrKmpQw7_VwTg', 'Motor Controller' );
    
    Spreadsheet.Motor = GetGoogleSpreadsheet( ...
        '1yw_K_Wh0mPWjYlOh-KRkUNIrC4Pn1hJrKmpQw7_VwTg', 'Motor' );
    
    % Allocate Cell Structure
    Cell = struct();
    Cell( size(Spreadsheet.Cell, 1) - 7 ).Model = [];
    for i = 8 : size(Spreadsheet.Cell, 1)
       Cell(i-7).Model        = Spreadsheet.Cell(i,1);
       Cell(i-7).Manufacturer = Spreadsheet.Cell(i,2);
       Cell(i-7).Chemistry    = Spreadsheet.Cell(i,3);
       Cell(i-7).Geometry     = Spreadsheet.Cell(i,4);
       
       Cell(i-7).Voltage.Nom  = str2double(Spreadsheet.Cell{i,5 });
       Cell(i-7).Voltage.Max  = str2double(Spreadsheet.Cell{i,6 });
       
       Cell(i-7).Capacity     = str2double(Spreadsheet.Cell{i,7 });
       
       Cell(i-7).Current.Cont = str2double(Spreadsheet.Cell{i,8 });
       Cell(i-7).Current.Max  = str2double(Spreadsheet.Cell{i,9 });
       
       Cell(i-7).Resistance   = str2double(Spreadsheet.Cell{i,10});
       
       Cell(i-7).Mass         = str2double(Spreadsheet.Cell{i,21});
       
       Cell(i-7).Cost         = str2double(Spreadsheet.Cell{i,27});
    end
    
    % Allocate Controller Structure
    Controller = struct();
    Controller( size(Spreadsheet.Controller, 1) - 7 ).Model = [];
    for i = 8 : size(Spreadsheet.Controller, 1)
      
    end
    
    % Allocate Controller Structure
    Motor = struct();
    Motor( size(Spreadsheet.Motor, 1) - 7 ).Model = [];
    for i = 8 : size(Spreadsheet.Motor, 1)
      
    end
    
    %%% Local Spreadsheet Import Function
    function Spreadsheet = GetGoogleSpreadsheet(WorkbookID, SheetName)
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

        % https://docs.google.com/spreadsheets/d/{key}/gviz/tq?tqx=out:csv&sheet={sheet_name}

        LoginURL = 'https://www.google.com'; 
        CSVURL = ['https://docs.google.com/spreadsheets/d/', WorkbookID                , ...
                  '/gviz/tq?tqx=out:csv&sheet='            , strrep(SheetName,' ','+') ];

        %Step 1: Go to google.com to collect some cookies
        CookieManager = java.net.CookieManager([], java.net.CookiePolicy.ACCEPT_ALL);
        java.net.CookieHandler.setDefault(CookieManager);
        Handler = sun.net.www.protocol.https.Handler;
        Connection = java.net.URL([],LoginURL,Handler).openConnection();
        Connection.getInputStream();

        %Step 2: Go to the spreadsheet export url and download the csv
        Connection2 = java.net.URL([],CSVURL,Handler).openConnection();
        Spreadsheet = Connection2.getInputStream();
        Spreadsheet = char(ReadStream(Spreadsheet));

        %Step 3: Convert the csv to a cell array
        Spreadsheet = ParseCSV(Spreadsheet);

        % Local Functions
        function out = ReadStream(inStream)
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

        function data = ParseCSV(data)
        % Splits data into individual lines
            data = textscan(data,'%s','whitespace','\n');
            data = data{1};
            for ii=1:length(data)
               % For each line, split the string into its comma-delimited units
               % The '%q' format deals with the "quoting" convention appropriately.
               tmp = textscan(data{ii},'%q','delimiter',',');
               data(ii,1:length(tmp{1})) = tmp{1};
            end
        end
    end
end

