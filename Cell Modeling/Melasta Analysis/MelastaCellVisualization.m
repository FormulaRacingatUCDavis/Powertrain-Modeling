clc; clear; close all;

%% Melasta Cell Data Visualization
load('MelastaDischargeData.mat')

Color = {[0 0 1], [0   0   0.8]; ...
         [0 1 0], [0   0.8 0  ]; ...
         [1 0 1], [0.8 0   0.8]; ...
         [1 0 0], [0.8 0   0  ]};

figure
subplot(1,2,1)
for i = 1:size(Capacity,2)
    for j = 1:size(Capacity,3)
        plot( Capacity(:,i,j), Voltage(:,i,j), 'Color', Color{i,j} )
        hold on;
    end
end

title(  'Discharge Curves', 'Interpreter', 'latex' )
xlabel( 'Capacity [$mAh$]', 'Interpreter', 'latex' )
ylabel( 'Internal Resistance [$m \Omega$]', 'Interpreter', 'latex' )

legend();

subplot(1,2,2)
for i = 1:size(Capacity,2)
    for j = 1:size(Capacity,3)
        plot( Capacity(:,i,j), NegTemp(:,i,j), 'Color', Color{i,j}, 'LineStyle', '--'  )
        hold on;
        
        plot( Capacity(:,i,j), PosTemp(:,i,j), 'Color', Color{i,j}, 'LineStyle', ':' )
        plot( Capacity(:,i,j), CellTemp(:,i,j), 'Color', Color{i,j} )
    end
end

%% Coulomb Counting & Internal Resistance Estimation
m = 127;
SHC = 0.902; % 

Time = NaN( size( Capacity ) );
Time(1,:,:) = 0;

figure
for i = 1:size(Capacity,2)
    for j = 1:size(Capacity,3)
        for k = 2:max(find(~isnan(Capacity(:,i,j))))
            Time(k,i,j) = Time(k-1,i,j) + 3.6*(Capacity(k,i,j) - Capacity(k-1,i,j)) / abs(Current(k,i,j));
            
            Resistance(k,i,j) = ( CellTemp(k,i,j) - CellTemp(1,i,j) ) * m * SHC ./ ...
                trapz( Time(1:k,i,j), Current(1:k,i,j).^2);            
        end
        
        plot( Capacity(:,i,j), Resistance(:,i,j) .* 1000, 'Color', Color{i,j} )
        hold on;
    end
end

xlabel( 'Capacity [$mAh$]', 'Interpreter', 'latex' )
ylabel( 'Internal Resistance [$m \Omega$]', 'Interpreter', 'latex' )
ylim([0 20])