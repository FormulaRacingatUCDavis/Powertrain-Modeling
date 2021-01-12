tic
clc; clear; close all;

%% Powertrain COTS Analysis
% This script accesses the powertrain COTS catalogue Google Spreadsheet and
% then loops through various motor, controller, and cell combinations.

%% COTS Database Imports
[Cell, Controller, Motor] = SpreadsheetImport();

%% Constraints and Constants
Accumulator.Capacity  = 6.7 .* 1000; % Pack Energy Capacity [kWh -> Wh]
Accumulator.PowerPeak = 65  .* 1000; % Required Peak Power [kW -> W]

EnduranceActionLoad    = 22156741.88; % Constant from endurance, sum of Current^2 times each time step

Cell(1).Cp             = 0.902      ; % Lithium ion cell specific heat capacity [J/g-K]

%% Powertrain Configuration Sweeping
% Determine feasible voltage range for each Motor / Controller
% combination, then sweep these voltage ranges for every Cell, in order to
% find the Change in Temperature vs. Voltage for every Motor / Controller /
% Cell combination

Powertrain = struct( 'Motor'      , [] , ...
                     'Controller' , [] , ...
                     'Cell'       , [] , ...
                     'Accumulator', [] );
Powertrain( length(Motor), length(Controller), length(Cell) ).Motor = [];

for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            Cell(k).Cp = Cell(1).Cp; % Allocate Typical Li-Ion Cell Specific Heat Capacity
            
            Powertrain(i,j,k).Motor       = Motor(i);
            Powertrain(i,j,k).Controller  = Controller(j);
            Powertrain(i,j,k).Cell        = Cell(k);
            Powertrain(i,j,k).Accumulator = Accumulator;
            
            Powertrain(i,j,k).Flag = [];
            
            %%% Initial Compatibility Parsing 
            if AnyFieldNaN( Powertrain(i,j,k) )
                Powertrain(i,j,k).Flag = "(0) Insufficient Information";
                continue
            elseif Controller(j).Voltage < Accumulator.PowerPeak / Controller(j).CurrentMax
                Powertrain(i,j,k).Flag = "(1) Controller Peak Power Not Sufficient";
                continue
            elseif Motor(i).Voltage < Accumulator.PowerPeak / Motor(i).CurrentMax
                Powertrain(i,j,k).Flag = "(2) Motor Peak Power Not Sufficient";
                continue
            elseif (Controller(j).Voltage < Accumulator.PowerPeak / Motor(i).CurrentMax) || ...
                   (Motor(i).Voltage < Accumulator.PowerPeak / Controller(j).CurrentMax)
                Powertrain(i,j,k).Flag = "(3) Incompatible Motor & Controller Voltages";
                continue
            end

            %%% Define Compatible Voltage Range
            Powertrain(i,j,k).Accumulator.Voltage = ...
                round( Accumulator.PowerPeak / min( [Motor(i).CurrentMax, Controller(j).CurrentMax] ) ) : ...
                floor( min( [Motor(i).Voltage, Controller(j).Voltage] ) );
            
            %%% Calculate Accumulator Configuration & Metrics
            Powertrain(i,j,k).Accumulator.Series = ...
                round( Powertrain(i,j,k).Accumulator.Voltage ./ Cell(k).VoltageMax );
            
            Powertrain(i,j,k).Accumulator.Parallel = round( Accumulator.Capacity ./ ...
                (Powertrain(i,j,k).Accumulator.Series .* Cell(k).Capacity .* Cell(k).VoltageMax));
            
            Powertrain(i,j,k).Accumulator.Resistance = Powertrain(i,j,k).Accumulator.Series ./ ...
                Powertrain(i,j,k).Accumulator.Parallel .* Cell(k).Resistance;
            
            Powertrain(i,j,k).Accumulator.Mass = Powertrain(i,j,k).Accumulator.Series .* ...
                Powertrain(i,j,k).Accumulator.Parallel .* Cell(k).Mass ./ 1000;
            
            Powertrain(i,j,k).Accumulator.PowerPeak = Powertrain(i,j,k).Accumulator.Parallel .* ...
                Powertrain(i,j,k).Accumulator.Series .* Cell(k).CurrentMax .* Cell(k).VoltageMax;
            
            if Powertrain(i,j,k).Accumulator.PowerPeak < 0.9*Accumulator.PowerPeak 
                Powertrain(i,j,k).Flag = "(4) Cells Cannot Supply Sufficient Peak Power";
                continue
            end
            
            Powertrain(i,j,k).Temp = (10/6 .* 117.6./(floor(Powertrain(i,j,k).Accumulator.Voltage./...
                                      Powertrain(i,j,k).Cell.VoltageMax).*Powertrain(i,j,k).Cell.VoltageMax)).^2 .*...
                                     (Cell(k).Resistance .* Powertrain(i,j,k).Accumulator.Series ./ ...
                                      Powertrain(i,j,k).Accumulator.Parallel) .* EnduranceActionLoad ./ (Cell(k).Mass .*...
                                      Powertrain(i,j,k).Accumulator.Series .* Powertrain(i,j,k).Accumulator.Parallel .*...
                                      Cell(k).Cp);
            
            Powertrain(i,j,k).Capacity = Powertrain(i,j,k).Accumulator.Series .*...
                                         Powertrain(i,j,k).Accumulator.Parallel.*...
                                         Cell(k).VoltageMax .* Cell(k).Capacity ./ 1000;
        end
    end
end

%% Plotting Stuff
Motors = [];
Controllers = [];
Cells = [];
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
        
        if isempty(Powertrain(i,j,k).Flag)
        Motors = [Motors,i];
        Controllers = [Controllers,j];
        Cells = [Cells,k];
        end
        
        end
    end
end
Motors = unique(Motors);
Controllers = unique(Controllers);
Cells = unique(Cells);

for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                Color = find(Cells == k);
                Marker = find(Controllers == j);

                switch Color
                    case 1
                        Powertrain(i,j,k).Color = 'r';
                    case 2
                        Powertrain(i,j,k).Color = 'g';
                    case 3
                        Powertrain(i,j,k).Color = 'b';
                    case 4
                        Powertrain(i,j,k).Color = 'y';
                    case 5
                        Powertrain(i,j,k).Color = 'c';
                    case 6
                        Powertrain(i,j,k).Color = 'm';
                end
                
                switch Marker
                    case 1
                        Powertrain(i,j,k).Marker = 'o';
                    case 2
                        Powertrain(i,j,k).Marker = '+';
                    case 3
                        Powertrain(i,j,k).Marker = '*';
                    case 4
                        Powertrain(i,j,k).Marker = '.';
                    case 5
                        Powertrain(i,j,k).Marker = 'x';
                    case 6
                        Powertrain(i,j,k).Marker = 'square';
                    case 7
                        Powertrain(i,j,k).Marker = 'diamond';
                    case 8
                        Powertrain(i,j,k).Marker = 'pentagram';
                    case 9
                        Powertrain(i,j,k).Marker = 'hexagram';
                    case 10
                        Powertrain(i,j,k).Marker = '^';
                    case 11
                        Powertrain(i,j,k).Marker = 'v';
                    case 12
                        Powertrain(i,j,k).Marker = '>';
                    case 13
                        Powertrain(i,j,k).Marker = '<';
                end
            end
            
        end
    end
end

figure(1)
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                    plot(Powertrain(i,j,k).Accumulator.Voltage,Powertrain(i,j,k).Temp,...
                    'Color',Powertrain(i,j,k).Color,'Marker',Powertrain(i,j,k).Marker);
                hold on
            end
            
        end
    end
end

title('Temperature Change of Cell Over Voltage Range')
xlim([100,600]);
xlabel('Powertrain Voltage [V]')
ylim([0,100]);
ylabel('Endurance Temperature Change [C]')
legend('bro','bruh')

figure(2)
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                plot(Powertrain(i,j,k).Accumulator.Voltage,Powertrain(i,j,k).Accumulator.Mass);
                hold on
            end
            
        end
    end
end

title('Cell Mass Over Voltage Range')
xlim([100,600]);
xlabel('Powertrain Voltage [V]')
ylim([0,100]);
ylabel('Cell Mass [kg]')

figure(3)
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                plot(Powertrain(i,j,k).Accumulator.Voltage,Powertrain(i,j,k).Accumulator.Mass +...
                     Powertrain(i,j,k).Motor.Mass + Powertrain(i,j,k).Controller.Mass);
                hold on
            end
            
        end
    end
end

title('Powertrain Mass Over Voltage Range')
xlim([100,600]);
xlabel('Powertrain Voltage [V]')
ylim([50,150]);
ylabel('Mass [kg]')

figure(4)
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                plot(Powertrain(i,j,k).Accumulator.Voltage , Powertrain(i,j,k).Accumulator.Mass ./...
                    (1000 .* Powertrain(i,j,k).Accumulator.Resistance));
                hold on
            end
            
        end
    end
end

title('Cell Mass / Resistance Ratio Over Voltage Range')
xlim([100,600]);
xlabel('Powertrain Voltage [V]')
ylim([0,10]);
ylabel('g / Ohm')

figure(5)
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                plot(Powertrain(i,j,k).Accumulator.Voltage , Powertrain(i,j,k).Capacity);
                hold on
            end
            
        end
    end
end

title('Accumulator Capacity Over Voltage Range')
xlim([100,600]);
xlabel('Powertrain Voltage [V]')
ylim([0,10]);
ylabel('Capacity [kWh]')

clear i j k A B
timeElapsed = toc
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
        Cell(i-7).Model        = Spreadsheet.Cell{i,1};
        Cell(i-7).Manufacturer = Spreadsheet.Cell{i,2};
        Cell(i-7).Chemistry    = Spreadsheet.Cell{i,3};
        Cell(i-7).Geometry     = Spreadsheet.Cell{i,4};

        Cell(i-7).VoltageNom   = str2double(Spreadsheet.Cell{i,5 });
        Cell(i-7).VoltageMax   = str2double(Spreadsheet.Cell{i,6 });

        Cell(i-7).Capacity     = str2double(Spreadsheet.Cell{i,7 });

        Cell(i-7).CurrentCont  = str2double(Spreadsheet.Cell{i,8 });
        Cell(i-7).CurrentMax   = str2double(Spreadsheet.Cell{i,9 });

        Cell(i-7).Resistance   = str2double(Spreadsheet.Cell{i,10}) ./ 1000; % Internal resistance [mOhms -> Ohms]

        Cell(i-7).Mass         = str2double(Spreadsheet.Cell{i,21});

        Cell(i-7).Cost         = str2double(Spreadsheet.Cell{i,27});
    end
    
    % Allocate Controller Structure
    Controller = struct();
    Controller( size(Spreadsheet.Controller, 1) - 3 ).Model = [];
    for i = 4 : size(Spreadsheet.Controller, 1)
        Controller(i-3).Model        = Spreadsheet.Controller{i,1};
        Controller(i-3).Manufacturer = Spreadsheet.Controller{i,2};

        Controller(i-3).Voltage      = str2double(Spreadsheet.Controller{i,5 });

        Controller(i-3).CurrentCont  = str2double(Spreadsheet.Controller{i,7 });
        Controller(i-3).CurrentMax   = str2double(Spreadsheet.Controller{i,8 });

        Controller(i-3).Mass         = str2double(Spreadsheet.Controller{i,20});
    end
    
    % Allocate Controller Structure
    Motor = struct();
    Motor( size(Spreadsheet.Motor, 1) - 3 ).Model = [];
    for i = 4 : size(Spreadsheet.Motor, 1)
        Motor(i-3).Model        = Spreadsheet.Motor{i,1};
        Motor(i-3).Manufacturer = Spreadsheet.Motor{i,2};
        
        Motor(i-3).Voltage      = str2double(Spreadsheet.Motor{i,5 });
        
        Motor(i-3).CurrentCont  = str2double(Spreadsheet.Motor{i,6 });
        Motor(i-3).CurrentMax   = str2double(Spreadsheet.Motor{i,7 });
        
        Motor(i-3).Mass         = str2double(Spreadsheet.Motor{i,24});
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

function Flag = AnyFieldNaN( Structure )
    Fields = fieldnames( Structure );
    
    Flag = false;
    for f = 1:length(Fields)
        if ~isempty( Structure.(Fields{f}) )
            SubFields = fieldnames( Structure.(Fields{f}) );

            for sf = 1:length(SubFields)
               if any( isnan( Structure.(Fields{f}).(SubFields{sf}) ) )
                   Flag = true;
                   return
               end
            end
        end
    end
end