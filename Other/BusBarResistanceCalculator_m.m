%Resistances of an Accumulator 
%   Written by Tucker Zischka
%   8/2/2020
% This will help to solve for resistance in the busbar/bolted joints of the
% accumulator 
%% Parameters

T = 45; %torque
D = 12; %nominal bolt diameter [mm]

a = 50;% Width of bus bar [mm]
b = 10;% thickness of bus bar [mm]
l = 70;% length of overlap [mm] 
n = 1;% # of bolts across width
N = 2;% # of bolts in line; 
d = 14;% diameter of bolted holes

k = .20; %Nut Factor
p = 17.24;% Resistivity [ohm*m]  Cu : 17.24 microOhms for 100% IACS Copper

%CurveFit for pressure vs resistance Plot
xdata = [3.38, 5.40, 7.70, 10.94, 16.05, 27.44, 60]; 
ydata = [6000.00, 5000.00, 4000.00, 3000.00, 2000.00, 1000.00, 557.58];
[fitresult, gof]= createFit(xdata, ydata);

%CurveFit for overlap ratio vs resistance ratio
xdata1 = [00.5526, 00.5921, 00.6578, 0.7631, .8947, 1.184, 1.697, 3.697, 10];
ydata1 = [02.00, 01.80, 01.60, 1.4, 1.2, 1, .8, .6, .52];
[fitresult1, gof1] = createFit1(xdata1, ydata1);


%% Equations

F = N.*n.*T./(k.*D);    % Force of the joint
P = F./(a.*l);    % Pressure on the joint
Y = fitresult((P.*1000)); % Contact resistance factor <<(multiply by 1000 so we can go from kN/mm^2 to N/mm^2)

e = fitresult1(l/b); % resistance ratio

R_contact = Y./(a.*l)./(10^(6));                  %Unit Conversion appeneded to end
R_spreading = e.*p.*l./((a-n.*d).*b)./(10^(6));   %Unit Conversion appeneded to end

eff = e.*a./(a - n.*d) + Y.*b./(l.^(2).*p); %Effeciency equation
fprintf('Effeciency: %d \n',eff);           %This is how much more resistance this joint is compared to a regular copper bar w/o joint  [Resitance of regular bus bar * eff = Joint resistance ]

R_joint = R_contact + R_spreading;
fprintf('Joint Resistance: %d [in ohms]\n', R_joint); 

%% Add in Dependencies
function [fitresult, gof] = createFit(xdata, ydata)
%% Fit: 'pressure2resistance'.
[xData, yData] = prepareCurveData( xdata, ydata );

% Set up fittype and options.
ft = fittype( 'rat31' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.128014399720173 0.999080394761361 0.171121066356432 0.032600820530528 0.56119979270966];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'pressure2resistance' );
h = plot( fitresult, xData, yData );
legend( h, 'ydata vs. xdata', 'pressure2resistance', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'xdata', 'Interpreter', 'none' );
ylabel( 'ydata', 'Interpreter', 'none' );
grid on
end

function [fitresult1, gof] = createFit1(xdata1, ydata1)
%% Fit: 'OverlapRatio'.
[xData, yData] = prepareCurveData( xdata1, ydata1 );

% Set up fittype and options.
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [1.66519273539987 -0.974586368223178 -0.488933168285813];

% Fit model to data.
[fitresult1, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'OverlapRatio' );
h = plot(fitresult1, xData, yData );
legend( h, 'ydata1 vs. xdata1', 'OverlapRatio', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'xdata1', 'Interpreter', 'none' );
ylabel( 'ydata1', 'Interpreter', 'none' );
grid on
end
