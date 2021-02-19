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
Accumulator.Rejection = 1000;        % Maximum Possible Cooling [W]
Accumulator.Mass      = 36.7;        % Max allowable cell mass [kg]

EnduranceActionLoad   = 22156741.88; % Constant from endurance, sum of Current^2 times each time step
TempAmbient           = 25;
EnduranceTime         = 1943;

Cell(1).Cp            = 0.902      ; % Lithium ion cell specific heat capacity [J/g-K]
%% Powertrain Configuration Sweeping
% Determine feasible voltage range for each Motor / Controller
% combination, then sweep these voltage ranges for every Cell, in order to
% find the Change in Temperature vs. Voltage for every Motor / Controller /
% Cell combination

Powertrain = struct( 'Motor'       , [] , ...
                     'Controller'  , [] , ...
                     'Cell'        , [] , ...
                     'Accumulator' , [] );
Powertrain( length(Motor), length(Controller), length(Cell) ).Motor = [];

Flag = struct('Info'                , 0 , ...
              'ControllerPower'     , 0 , ...
              'MotorPower'          , 0 , ...
              'IncompatibleVoltage' , 0 , ...
              'CellsPower'          , 0 , ...
              'Heat'                , 0 , ...
              'Capacity'            , 0);
              

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
                Flag.Info = Flag.Info + 1;
                continue
            elseif Controller(j).Voltage < Accumulator.PowerPeak / Controller(j).CurrentMax
                Powertrain(i,j,k).Flag = "(1) Controller Peak Power Not Sufficient";
                Flag.ControllerPower = Flag.ControllerPower + 1;
                continue
            elseif Motor(i).Voltage < Accumulator.PowerPeak / Motor(i).CurrentMax
                Powertrain(i,j,k).Flag = "(2) Motor Peak Power Not Sufficient";
                Flag.MotorPower = Flag.MotorPower + 1;
                continue
            elseif (Controller(j).Voltage < Accumulator.PowerPeak / Motor(i).CurrentMax) || ...
                   (Motor(i).Voltage < Accumulator.PowerPeak / Controller(j).CurrentMax)
                Powertrain(i,j,k).Flag = "(3) Incompatible Motor & Controller Voltages";
                Flag.IncompatibleVoltage = Flag.IncompatibleVoltage + 1;
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
            
            Powertrain(i,j,k).Accumulator.Mass = Powertrain(i,j,k).Accumulator.Series .* ...    % Total Cell Mass [kg]
                Powertrain(i,j,k).Accumulator.Parallel .* Cell(k).Mass ./ 1000;
            
            Powertrain(i,j,k).Accumulator.PowerPeak = Powertrain(i,j,k).Accumulator.Parallel .* ...
                Powertrain(i,j,k).Accumulator.Series .* Cell(k).CurrentMax .* Cell(k).VoltageMax ./ 1000;
         
            %%% Calculate Voltage Swept Outputs
            Powertrain(i,j,k).Temp = (10/6 .* 117.6./(Powertrain(i,j,k).Accumulator.Series .*...
                                      Powertrain(i,j,k).Cell.VoltageMax) .*...
                                      Accumulator.PowerPeak / 50000).^2 .*...
                                     (Cell(k).Resistance .* Powertrain(i,j,k).Accumulator.Series ./ ...
                                      Powertrain(i,j,k).Accumulator.Parallel) .* EnduranceActionLoad ./...
                                     (Powertrain(i,j,k).Accumulator.Mass .* 1000 .* Cell(k).Cp);
            Powertrain(i,j,k).Rejection = (Powertrain(i,j,k).Temp + TempAmbient - 60) .* (Powertrain(i,j,k).Accumulator.Mass .*...
                                           1000 .* Cell(k).Cp) ./ EnduranceTime;
                                       
            Powertrain(i,j,k).Capacity = Powertrain(i,j,k).Accumulator.Series .* Powertrain(i,j,k).Accumulator.Parallel .*...
                                         Cell(k).VoltageMax .* Cell(k).Capacity ./ 1000;
                                       
            Powertrain(i,j,k).PowerPeak = min(Powertrain(i,j,k).Accumulator.PowerPeak , Controller(j).PowerPeak);
            Powertrain(i,j,k).PowerPeak = min(Powertrain(i,j,k).PowerPeak , Motor(k).PowerPeak);
            
            Powertrain(i,j,k).Mass = Powertrain(i,j,k).Accumulator.Mass + Motor(i).Mass + Controller(j).Mass;
            
            %%% Further filtering of specific Voltages
            Powertrain(i,j,k).Pass = Powertrain(i,j,k).Capacity  > Accumulator.Capacity/1000 &...    % Pack Capacity
                                     Powertrain(i,j,k).Rejection < Accumulator.Rejection &...   % Heat Rejection
                                     Powertrain(i,j,k).PowerPeak > Accumulator.PowerPeak/1000 &...  % Peak Power
                                     Powertrain(i,j,k).Accumulator.Mass < Accumulator.Mass;         % Cell Mass
            
            Powertrain(i,j,k).Rejection              = Powertrain(i,j,k).Rejection(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Capacity               = Powertrain(i,j,k).Capacity(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).PowerPeak              = Powertrain(i,j,k).PowerPeak(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Mass                   = Powertrain(i,j,k).Mass(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Accumulator.Mass       = Powertrain(i,j,k).Accumulator.Mass(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Accumulator.Voltage    = Powertrain(i,j,k).Accumulator.Voltage(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Accumulator.Series     = Powertrain(i,j,k).Accumulator.Series(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Accumulator.Parallel   = Powertrain(i,j,k).Accumulator.Parallel(Powertrain(i,j,k).Pass);
            Powertrain(i,j,k).Accumulator.Resistance = Powertrain(i,j,k).Accumulator.Resistance(Powertrain(i,j,k).Pass);
            
        end
    end
end

%% Plotting Stuff
Cells = [];
for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
        
        if isempty(Powertrain(i,j,k).Flag)
            Cells = unique([Cells,k]);
        end
        
        end
    end
end

for i = 1 : length(Motor)
    for j = 1 : length(Controller)
        for k = 1 : length(Cell)
            
            if isempty(Powertrain(i,j,k).Flag)
                Color = find(Cells == k);

                switch Color
                    case 1
                        Powertrain(i,j,k).Color = '#0072BD';    % Sky Blue
                    case 2
                        Powertrain(i,j,k).Color = '#D95319';    % Orange
                    case 3
                        Powertrain(i,j,k).Color = '#EDB120';    % Yellow
                    case 4
                        Powertrain(i,j,k).Color = '#7E2F8E';    % Purple
                    case 5
                        Powertrain(i,j,k).Color = '#77AC30';    % Green Apple
                    case 6
                        Powertrain(i,j,k).Color = '#4DBEEE';    % Baby Blue
                    case 7
                        Powertrain(i,j,k).Color = '#A2142F';    % Fuschia
                    case 8
                        Powertrain(i,j,k).Color = '#C60E0E';    % Red
                    case 9
                        Powertrain(i,j,k).Color = '#0A0C89';    % Cobalt Blue
                    case 10
                        Powertrain(i,j,k).Color = '#5E3509';    % Brown
                    case 11
                        Powertrain(i,j,k).Color = '#185604';    % Forest Green
                    case 12
                        Powertrain(i,j,k).Color = '#3BBA32';    % Green Screen
                    case 13
                        Powertrain(i,j,k).Color = '#121214';    % Black
                    case 14
                        Powertrain(i,j,k).Color = '#EE2ACA';    % Hot Pink
                    case 15
                        Powertrain(i,j,k).Color = '#29DEBF';
                    case 16
                        Powertrain(i,j,k).Color = '#1AFE1A';
                    case 17
                        Powertrain(i,j,k).Color = '#FBFF00';
                    case 18
                        Powertrain(i,j,k).Color = '#1A0447';
                    case 19
                        Powertrain(i,j,k).Color = '#470404';
                    case 20
                        Powertrain(i,j,k).Color = '#6F7485';
                end
                
            end
            
        end
    end
end

figure(1)
for p = 1:9
    
    a = tril(ones(3,3))';
    
    col = rem(p-1,3)+1;
    row = ceil(p/3);
    
    if a(p)
        ax(p) = subplot(3,3,p);

        labelx = []; labely = [];
        
        for i = 1 : length(Motor)
            for j = 1 : length(Controller)
                for k = 1 : length(Cell)

                    if isempty(Powertrain(i,j,k).Flag)
                        switch col
                            case 1
                                x = Powertrain(i,j,k).Rejection;
                                xlab = 'Required Heat Rejection [W]';
                            case 2
                                x = Powertrain(i,j,k).Mass;
                                xlab = 'Powertrain Mass [kg]';
                            case 3
                                x = Powertrain(i,j,k).PowerPeak;
                                xlab = 'Peak Power [kW]';
                        end

                        switch row
                            case 1
                                y = Powertrain(i,j,k).Mass;
                                ylab = 'Powertrain Mass [kg]';
                            case 2
                                y = Powertrain(i,j,k).PowerPeak;
                                ylab = 'Peak Power [kW]';
                            case 3
                                y = Powertrain(i,j,k).Capacity;
                                ylab = 'Capacity [kWh]';

                        end

                        s = scatter(x,y,'.','MarkerEdgeColor',Powertrain(i,j,k).Color);

                        s.DataTipTemplate.DataTipRows(end+1) = Powertrain(i,j,k).Motor.Model;
                        s.DataTipTemplate.DataTipRows(end+1) = Powertrain(i,j,k).Controller.Model;
                        s.DataTipTemplate.DataTipRows(end+1) = Powertrain(i,j,k).Cell.Model;

                        hold on

                        if col == 1 && isempty(labely)
                            ylabel(ylab);
                            labely = 1;
                        end
                        if row == 3 && isempty(labelx)
                            xlabel(xlab);
                            labelx = 1;
                        end

                    end

                end
            end
        end
    end
end

for i = 1:3
    linkaxes(ax(nonzeros((i:3:9) .* flip(a(:,4-i)'))) ,'x');
    linkaxes(ax(nonzeros((i*3-2:i*3)' .* a(:,i))) ,'y');
end

hold off

clear i j k A B x y p row col a
clear labelx labely xlab ylab
clear Motors Controllers Cells
clear Color Outline Marker
timeElapsed = toc;
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

        Controller(i-3).Voltage      = str2double(Spreadsheet.Controller{i,4 });

        Controller(i-3).CurrentCont  = str2double(Spreadsheet.Controller{i,8 });
        Controller(i-3).CurrentMax   = str2double(Spreadsheet.Controller{i,9 });
        
        Controller(i-3).PowerPeak    = str2double(Spreadsheet.Controller{i,13});

        Controller(i-3).Mass         = str2double(Spreadsheet.Controller{i,20});
    end
    
    % Allocate Motor Structure
    Motor = struct();
    Motor( size(Spreadsheet.Motor, 1) - 3 ).Model = [];
    for i = 4 : size(Spreadsheet.Motor, 1)
        Motor(i-3).Model        = Spreadsheet.Motor{i,1};
        Motor(i-3).Manufacturer = Spreadsheet.Motor{i,2};
        
        Motor(i-3).Voltage      = str2double(Spreadsheet.Motor{i,4 });
        
        Motor(i-3).CurrentCont  = str2double(Spreadsheet.Motor{i,5 });
        Motor(i-3).CurrentMax   = str2double(Spreadsheet.Motor{i,6 });
        
        Motor(i-3).PowerPeak    = str2double(Spreadsheet.Motor{i,10});
        
        Motor(i-3).Mass         = str2double(Spreadsheet.Motor{i,23});
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