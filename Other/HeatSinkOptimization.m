clc; clear; close all;
%% Coefficient Calculations
% Air Properties
Air.rho = 0.9950;
Air.mu = 208.2E-7;
Air.k = 30E-3;
Air.Pr = 0.7;
Air.v = 20;

% Metal Properties 
Al.rho = 2700;
Al.k = 200;

% Heat Sink Geometry
W = 0.275; % Width (Z-Axis) Fixed by MC
L = 0.232; % Length (X-Axis) Fixed by MC
Param.N = 24:30; % Number of Fins [10, 35]
Param.P = linspace(0.5,2,11); % Param.P = Calc.T/Calc.S [0.5 2]
Param.H = linspace(0.005,0.025,25); % Fin Height [ <0.020 ]
Param.b = linspace(0.005,0.015,25); % Base Thickness 
[Param.N, Param.P, Param.H, Param.b] = ...
    ndgrid( Param.N, Param.P, Param.H, Param.b );
Calc.S = W ./ (Param.N+1 + Param.N.*Param.P); % Fin Spacing [ >0.005 ] 
Calc.T = Calc.S.*Param.P; % Fin Thickness
Calc.Abase = L.*W - L.*Param.N.*Calc.T; 
Calc.Afin = L.*Calc.T + 2.*L.*Param.H; % Per Fin
Calc.V = L.*W.*Param.b + L.*Param.N.*Calc.T.*Param.H; 

% Heat Sink Calculations
Calc.Re = Air.rho .* Air.v .* Calc.S.^2 ./ ( Air.mu .* L );
Calc.Nu = ( 1 ./ ( Calc.Re .* Air.Pr ./ 2 ).^3 + ...
    1 ./ ( 0.664 .* sqrt(Calc.Re) .* Air.Pr.^(0.33) .* sqrt( 1 + 3.65./sqrt(Calc.Re) ) ).^3 ).^(-0.33); 
Calc.h = Calc.Nu .* Air.k ./ Calc.S;
Calc.m = sqrt( 2 .* Calc.h ./ (Al.k .* Calc.T) );
Calc.eta = tanh( Calc.m .* Param.H ) ./ (Calc.m .* Param.H);
Calc.Rconv = 1 ./ ( Calc.h .* ( Calc.Abase + Param.N .* Calc.eta .* Calc.Afin ) );
Coef.R = Calc.Rconv + Param.b ./ ( Al.k .* W .* L );
Coef.C = Al.rho .* Calc.V .* 896 + 753 .* .0022 .* 96;

%% 1st Order Response
Coef.E = 0.500E3;
Coef.Tinf = 35;
t = 0:0.1:2000;
dt = t(2) - t(1);
Temp = zeros( [size(Param.N), length(t)] );
Temp(:,:,:,:,1) = Coef.Tinf;
for i = 1 : length(t) - 1
    Temp(:,:,:,:,i+1) = Temp(:,:,:,:,i) + ...
        dt ./ Coef.C .* (Coef.E - (Temp(:,:,:,:,i) - Coef.Tinf)./Coef.R); 
end
% plot( t, Temp )
Results.tau = Coef.R .* Coef.C; % [ >500 ]
Results.Tss = Temp(:,:,:,:,end); % Min 
Results.m = Calc.V .* Al.rho;
%% Design Filtering
Check.Spacing = Calc.S > 0.005;
Check.Area = Calc.Abase > 0 & Calc.Afin > 0;
Check.tau = Results.tau > 50;
Check.Tss = Results.Tss < 150;
Filtered.tau = Results.tau( Check.Spacing & Check.Area & Check.tau & Check.Tss );
Filtered.Tss = Results.Tss( Check.Spacing & Check.Area & Check.tau & Check.Tss );
Filtered.m = Results.m( Check.Spacing & Check.Area & Check.tau & Check.Tss );
Filtered.R = Coef.R( Check.Spacing & Check.Area & Check.tau & Check.Tss );
Filtered.C = Coef.C( Check.Spacing & Check.Area & Check.tau & Check.Tss );
Params = fields( Param );
for i = 1 : numel( Params )
    Filtered.(Params{i}) = Param.(Params{i})( Check.Spacing & Check.Area & Check.tau & Check.Tss );
end
%% Plotting
p = numel( fields( Param ) );
figure( 'Name', 'Steady State Temperature' )
for i = 1 : (p - 1)^2
    [j(1), j(2)] = ind2sub( [p-1, p-1], i );
    if j(1) >= j(2)
        subplot( p-1, p-1, sub2ind( [p-1, p-1], j(2), j(1) ) )
        scatter3( Filtered.(Params{j(2)}), Filtered.(Params{j(1)+1}), Filtered.Tss, ...
            20, Filtered.Tss, 'filled' );
        h = colorbar;
        ylabel( h, 'Tss [C]' )
        set(gca,'clim',[60 110])
        xlabel( Params{j(2)} )
        ylabel( Params{j(1)+1} )
    end
end
figure( 'Name', 'Time Constant' )
for i = 1 : (p - 1)^2
    [j(1), j(2)] = ind2sub( [p-1, p-1], i );
    if j(1) >= j(2)
        subplot( p-1, p-1, sub2ind( [p-1, p-1], j(2), j(1) ) )
        scatter3( Filtered.(Params{j(2)}), Filtered.(Params{j(1)+1}), Filtered.tau, ...
            20, Filtered.tau, 'filled' );
        h = colorbar;
        ylabel( h, 'tau [s]' )
        set(gca,'clim',[350 600])
        xlabel( Params{j(2)} )
        ylabel( Params{j(1)+1} )
    end
end
figure( 'Name', 'Mass' )
for i = 1 : (p - 1)^2
    [j(1), j(2)] = ind2sub( [p-1, p-1], i );
    if j(1) >= j(2)
        subplot( p-1, p-1, sub2ind( [p-1, p-1], j(2), j(1) ) )
        scatter3( Filtered.(Params{j(2)}), Filtered.(Params{j(1)+1}), Filtered.m, ...
            20, Filtered.m, 'filled' );
        h = colorbar;
        ylabel( h, 'm [kg]' )
        set(gca,'clim',[1.5 6])
        xlabel( Params{j(2)} )
        ylabel( Params{j(1)+1} )
    end
end