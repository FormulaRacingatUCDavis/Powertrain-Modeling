function compoundPlanetaryDesign()
clc
close all

%% FIXED GEAR TEETH RANGES 
sun_teeth_range = 12:24;          % Sun gear teeth range
planet_gears.large = 40:50;       % Earth planet gear sizes
planet_gears.small = 22:26;       % Moon planet gear sizes

% Allowable gear ratio range
gear_ratio_range = [8, 13];       % Minimum and maximum overall gear ratios

% Physical constraints
min_motor_shaft = 0.60;           % inches
max_gearbox_OD = 5.25;            % inches
Np = 3;                           % Number of planets

% Load parameters 
input_torque = 40;                % N*m input torque
safety_factor = 1.0;              % Reduced safety factor for weight savings

% Material properties (4140 Steel source donalds doc)
material.yield_strength = 161000; % psi
material.hardness = 341;          % HB

DP_range = calculate_DP_limits(input_torque, material.yield_strength, safety_factor, max_gearbox_OD);          % Diametral Pitches to evaluate 

fprintf('=== FSAE Compound Planetary Gear Design ===\n');
fprintf('Gear Ratio Range: %.1f:1 to %.1f:1\n', gear_ratio_range);
fprintf('Input Torque: %d N*m, Safety Factor: %.1f\n', input_torque, safety_factor);
fprintf('Max Gearbox OD: %.2f inches\n\n', max_gearbox_OD);

%%  GENERATE AND ANALYZE COMBINATIONS 
all_valid_designs = [];

for DP = DP_range
    fprintf('Analyzing DP = %d...\n', DP);
    combinations = generate_gear_combinations(sun_teeth_range, planet_gears, gear_ratio_range, min_motor_shaft, max_gearbox_OD, DP, Np, input_torque, material, safety_factor);
    
    if ~isempty(combinations)
        all_valid_designs = [all_valid_designs; combinations];
    end
end

if ~isempty(all_valid_designs)
    all_DPs = [all_valid_designs.DP];
    DP_min_actual = min(all_DPs);
    DP_max_actual = max(all_DPs);

    % Optional: show corresponding overall ratios
    ratios_min_DP = [all_valid_designs([all_valid_designs.DP] == DP_min_actual).overall_ratio];
    ratios_max_DP = [all_valid_designs([all_valid_designs.DP] == DP_max_actual).overall_ratio];

    fprintf('\n=== DP LIMIT SUMMARY ===\n');
    fprintf('Min allowable DP: %d -> Ratios: %.2f to %.2f\n', DP_min_actual, min(ratios_min_DP), max(ratios_min_DP));
    fprintf('Max allowable DP: %d -> Ratios: %.2f to %.2f\n', DP_max_actual, min(ratios_max_DP), max(ratios_max_DP));
else
    fprintf('\nNo valid designs found to calculate DP range.\n');
end


%%  DISPLAY AND OUTPUT RESULTS 
display_results(all_valid_designs, gear_ratio_range);
output_to_csv(all_valid_designs, 'fsae_gear_combinations.csv');

end

%%   STRESS ANALYSIS 
function [is_strong, bending_safety] = check_strength_practical(combo, input_torque, material, safety_factor)
    
    % torque to in-lb (1 N*m = 8.85 lb*lb)
    torque_in_lb = input_torque * 8.85075;
    
    % Conservative torque per planet 
    torque_per_planet = torque_in_lb / 3;
    
    % pitch diameter of sun gear 
    pitch_dia_sun = combo.sun_teeth / combo.DP; % inches
    
    % Tangential force on sun gear
    tangential_force = (2 * torque_per_planet) / pitch_dia_sun;
    
    % Calculate face width based on circular pitch
    p_circ = pi / combo.DP;
    b_min = 2.55 * p_circ;
    b_max = 3.82 * p_circ;
    face_width = (b_min + b_max) / 2;  % Midpoint of recommended range 
    
    % Lewis form factor lookup from table for 20° pressure angle on the
    % textbook page 730 
    Y = get_lewis_form_factor(combo.sun_teeth);
    
    bending_stress = tangential_force * combo.DP / (face_width * Y);
    
    % Using the moderate allowable bending stress
    allowable_bending_stress_psi = 43511.4;  % 300 MPa
    
    % safety factor calculation
    bending_safety = allowable_bending_stress_psi / bending_stress;

    % service factor 
    service_factor = 1.25; 
    adjusted_safety = bending_safety / service_factor;
    
    is_strong = (adjusted_safety >= safety_factor);
    
    % Store calculated values for reporting
    %combo.face_width = face_width;
    combo.bending_safety = bending_safety;
    combo.adjusted_safety = adjusted_safety;
end

%%  LEWIS FORM FACTOR LOOKUP 
function Y = get_lewis_form_factor(teeth)
% Returns Lewis form factor Y based on number of teeth for 20° pressure angle

    % the lookup table
    teeth_table = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24, 26, 28, 30, 34, 38, 43, 50, 60, 75, 100, 150, 300, 400];
    Y_table = [0.245, 0.261, 0.277, 0.290, 0.296, 0.303, 0.309, 0.314, 0.322, 0.328, 0.331, 0.337, 0.346, 0.353, 0.359, 0.371, 0.384, 0.397, 0.409, 0.422, 0.435, 0.447, 0.460, 0.472, 0.480];
    
    % Find exact match 
    exact_match = find(teeth_table == teeth, 1);
    if ~isempty(exact_match)
        Y = Y_table(exact_match);
        return;
    end
    
    % If teeth count is below minimum, use minimum value
    if teeth < min(teeth_table)
        Y = Y_table(1);
        return;
    end
    
    % If teeth count is above maximum, use maximum value
    if teeth > max(teeth_table)
        Y = Y_table(end);
        return;
    end
    Y = interp1(teeth_table, Y_table, teeth, 'linear');

end

%% WEIGHT ESTIMATE:
function weight = estimate_gearbox_weight(combo, DP)

    steel_density = 0.284;  % lb/in³
    
    % Calculate gear volumes (simplified as cylinders/rings)
    total_volume = 0;
    
    % Sun gear volume (cylinder)
    sun_pitch_dia = combo.sun_teeth / DP;
    sun_root_dia = (combo.sun_teeth - 2.5) / DP;  % Approximate root diameter
    sun_area = pi * (sun_root_dia/2)^2;
    sun_volume = sun_area * combo.face_width;
    
    % Planet gears volume
    % earth
    planet_large_pitch_dia = combo.planet_large_teeth / DP;
    planet_large_root_dia = (combo.planet_large_teeth - 2.5) / DP;
    planet_large_area = pi * (planet_large_root_dia/2)^2;
    planet_large_volume = planet_large_area * combo.face_width * 3;  % 3 planets
    
    % moon 
    planet_small_pitch_dia = combo.planet_small_teeth / DP;
    planet_small_root_dia = (combo.planet_small_teeth - 2.5) / DP;
    planet_small_area = pi * (planet_small_root_dia/2)^2;
    planet_small_volume = planet_small_area * combo.face_width * 3;  % 3 planets
    
    % 3. Ring gear volume 
    ring_pitch_dia = combo.ring_teeth / DP;
    ring_OD = ring_pitch_dia;  % For internal gear
    ring_ID = ring_OD - (4/DP);  % Approximate internal diameter
    ring_area = pi * ((ring_OD/2)^2 - (ring_ID/2)^2);
    ring_volume = ring_area * combo.face_width;
    
    % Carrier volume (rough estimate based on diameter)
    carrier_dia = combo.carrier_dia;
    carrier_area = 0.3 * pi * (carrier_dia/2)^2;  % 30% solid material
    carrier_volume = carrier_area * combo.face_width;
    
    % Total volume and weight
    total_volume = sun_volume + planet_large_volume + planet_small_volume + ...
                   ring_volume + carrier_volume;
    
    weight = total_volume * steel_density;
end
   
%%  GEAR RATIO CALCULATIONS 
function [g_rp, g_ps] = calculate_gear_ratios(sun_teeth, ring_teeth, ...
    planet_large_teeth, planet_small_teeth)
g_rp = ring_teeth / planet_small_teeth;
g_ps = planet_large_teeth / sun_teeth;
end

function overall_ratio = calculate_overall_gear_ratio(g_rp, g_ps)
overall_ratio = g_rp * g_ps + 1;
end

%%  VALIDATION FUNCTION 
function [is_valid, overall_ratio] = valid_gear_combination(sun_teeth, ...
    ring_teeth, planet_large_teeth, planet_small_teeth, gear_ratio_range, ...
    min_motor_shaft, max_gearbox_OD, DP, Np)

% Calculate ratios
[g_rp, g_ps] = calculate_gear_ratios(sun_teeth, ring_teeth, ...
    planet_large_teeth, planet_small_teeth);
overall_ratio = calculate_overall_gear_ratio(g_rp, g_ps);

% Check ratio range
if overall_ratio < gear_ratio_range(1) || overall_ratio > gear_ratio_range(2)
    is_valid = false;
    return;
end

% Check motor input shaft size constraint
sun_realistic_ID = (sun_teeth - 2)/DP;
if min_motor_shaft > sun_realistic_ID
    is_valid = false;
    return;
end
                                       
% CORRECTED OD CALCULATIONS
% Ring gear OD (internal gear) - pitch diameter is the OD for internal gears
ring_OD = (ring_teeth + 2) / DP;

% First stage OD (sun + large planets) - add 2 addendums for gear tips
first_stage_OD = (sun_teeth + (2 * planet_large_teeth) + 2) / DP;

% The actual gearbox OD is the larger of ring OD or first stage OD
gearbox_OD = max(ring_OD, first_stage_OD);

if gearbox_OD > max_gearbox_OD
    is_valid = false;
    return;
end

% Check sun gear shaft fit (minimum 0.625" bore)
sun_root_dia = (sun_teeth - 3) / DP; % Root diameter for full-depth teeth
min_shaft_dia = 0.625; % Motor shaft size
if sun_root_dia < min_shaft_dia
    is_valid = false;
    return;
end

% Assembly constraint
if mod(sun_teeth + ring_teeth, Np) ~= 0
    is_valid = false;
    return;
end

% Check that moon planets are smaller than earth planets
if planet_small_teeth >= planet_large_teeth
    is_valid = false;
    return;
end

% All checks passed
is_valid = true;
end

%%  COMBINATION GENERATOR 
function combinations = generate_gear_combinations(sun_teeth_range, ...
    planet_gears, gear_ratio_range, min_motor_shaft, max_gearbox_OD, DP, Np, input_torque, material, safety_factor)

combinations = [];
combination_count = 0;
strong_count = 0;

for sun_teeth = sun_teeth_range
    for planet_large_teeth = planet_gears.large
        for planet_small_teeth = planet_gears.small
            
            % Calculate ring teeth from geometric constraint
            ring_teeth = sun_teeth + planet_large_teeth + planet_small_teeth;
            
            % Check if combination is valid
            [is_valid, overall_ratio] = valid_gear_combination(...
                sun_teeth, ring_teeth, planet_large_teeth, planet_small_teeth, ...
                gear_ratio_range, min_motor_shaft, max_gearbox_OD, DP, Np);
            
            if is_valid
                combination_count = combination_count + 1;
                
                % Create combination structure
                combo = struct();
                combo.sun_teeth = sun_teeth;
                combo.ring_teeth = ring_teeth;
                combo.planet_large_teeth = planet_large_teeth;
                combo.planet_small_teeth = planet_small_teeth;
                combo.overall_ratio = overall_ratio;
                combo.DP = DP;
                
                % Calculate CORRECTED physical dimensions
                combo.ring_pitch_dia = ring_teeth / DP;
                combo.ring_OD = ring_teeth / DP; % For internal gear, pitch diameter = OD
                
                % First stage OD includes addendum (gear tips)
                combo.first_stage_OD = (sun_teeth + 2 * planet_large_teeth + 2) / DP;
                
                % Gearbox OD is the larger of ring OD or first stage OD
                combo.gearbox_OD = max(combo.ring_OD, combo.first_stage_OD);
                
                combo.carrier_dia = (sun_teeth + planet_large_teeth) / DP;
                
                % Check strength
                [combo.is_strong, combo.bending_safety] = ...
                    check_strength_practical(combo, input_torque, material, safety_factor);
                
                if combo.is_strong
% Calculate face_width here for weight estimation
    p_circ = pi / DP;
    b_min = 2.55 * p_circ;
    b_max = 3.82 * p_circ;
    combo.face_width = (b_min + b_max) / 2;
                    combo.weight = estimate_gearbox_weight(combo, DP);
                    strong_count = strong_count + 1;
                    combinations = [combinations; combo];
                end
            end
        end
    end
end

fprintf('  DP=%d: %d valid, %d strong enough\n', DP, combination_count, strong_count);
end

%% ENHANCED DISPLAY FOR DP COMPARISON 
function display_results(combinations, ~)
if isempty(combinations)
    fprintf('No valid combinations found.\n');
    return;
end

fprintf('\n=== VIABLE FSAE GEAR DESIGNS ===\n');
fprintf('Found %d designs that meet all constraints\n\n', length(combinations));

% Separate by DP for better comparison
DP16_designs = combinations([combinations.DP] == 16);
DP18_designs = combinations([combinations.DP] == 18);
DP20_designs = combinations([combinations.DP] == 20);
DP22_designs = combinations([combinations.DP] == 22);
DP24_designs = combinations([combinations.DP] == 24);

%% SHOW BEST DESIGNS FOR EACH DP
% Ideal gear ratio
ideal_gear_ratio = 10.5;

% DP 16 Designs
if ~isempty(DP16_designs)
    fprintf('========================== TOP DP 16 DESIGNS (STRONGEST) ==========================\n');
    
    % Convert DP16 to table
    n = length(DP16_designs);
    data_16DP = zeros(n, 9);
    for i = 1:n
        combo = DP16_designs(i);
        data_16DP(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                          combo.planet_small_teeth, combo.ring_teeth, ...
                          combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, combo.bending_safety, combo.weight];
    end
    
    % Sort by weight (lowest to highest)
    [~, sort_idx] = sort(data_16DP(:,9));  % Column 9 = weight
    data_16DP = data_16DP(sort_idx,:);
    DP16_designs_sorted = DP16_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_16DP, 1));
    T16 = array2table(data_16DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'Safety_Factor', 'Weight_lb'
    });
    disp(T16);
    
    % Show best DP16 design
    best_16DP = DP16_designs_sorted(1);
    fprintf('\nBEST DP 16 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_16DP.sun_teeth, best_16DP.planet_large_teeth, ...
        best_16DP.planet_small_teeth, best_16DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", Safety: %.1f\n', ...
        best_16DP.overall_ratio, best_16DP.ring_OD, best_16DP.first_stage_OD, best_16DP.bending_safety);
    fprintf('\n');
end

% DP 18 Designs
if ~isempty(DP18_designs)
    fprintf('========================== TOP DP 18 DESIGNS (STRONGEST) ==========================\n');
    
    % Convert DP18 to table
    n = length(DP18_designs);
    data_18DP = zeros(n, 9);
    for i = 1:n
        combo = DP18_designs(i);
        data_18DP(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                          combo.planet_small_teeth, combo.ring_teeth, ...
                          combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, combo.bending_safety, combo.weight];
    end
    
    % Sort by weight (lowest to highest)
    [~, sort_idx] = sort(data_18DP(:,9));  % Column 9 = weight
    data_18DP = data_18DP(sort_idx,:);
    DP18_designs_sorted = DP18_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_18DP, 1));
    T18 = array2table(data_18DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'Safety_Factor', 'Weight_lb'
    });
    disp(T18);
    
    % Show best DP18 design
    best_18DP = DP18_designs_sorted(1);
    fprintf('\nBEST DP 18 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_18DP.sun_teeth, best_18DP.planet_large_teeth, ...
        best_18DP.planet_small_teeth, best_18DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", Safety: %.1f\n', ...
        best_18DP.overall_ratio, best_18DP.ring_OD, best_18DP.first_stage_OD, best_18DP.bending_safety);
    fprintf('\n');
end

% DP 20 Designs
if ~isempty(DP20_designs)
    fprintf('========================== TOP DP 20 DESIGNS (STRONGEST) ==========================\n');
    
    % Convert DP20 to table
    n = length(DP20_designs);
    data_20DP = zeros(n, 9);
    for i = 1:n
        combo = DP20_designs(i);
        data_20DP(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                          combo.planet_small_teeth, combo.ring_teeth, ...
                          combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, combo.bending_safety, combo.weight];
    end
    
    % Sort by weight (lowest to highest)
    [~, sort_idx] = sort(data_20DP(:,9));  % Column 9 = weight
    data_20DP = data_20DP(sort_idx,:);
    DP20_designs_sorted = DP20_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_20DP, 1));
    T20 = array2table(data_20DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'Safety_Factor', 'Weight_lb'
    });
    disp(T20);
    
    % Show best DP20 design
    best_20DP = DP20_designs_sorted(1);
    fprintf('\nBEST DP 20 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_20DP.sun_teeth, best_20DP.planet_large_teeth, ...
        best_20DP.planet_small_teeth, best_20DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", Safety: %.1f\n', ...
        best_20DP.overall_ratio, best_20DP.ring_OD, best_20DP.first_stage_OD, best_20DP.bending_safety);
    fprintf('\n');
end

% DP 22 Designs
if ~isempty(DP22_designs)
    fprintf('========================== TOP DP 22 DESIGNS (STRONGEST) ==========================\n');
    
    % Convert DP22 to table
    n = length(DP22_designs);
    data_22DP = zeros(n, 9);
    for i = 1:n
        combo = DP22_designs(i);
        data_22DP(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                          combo.planet_small_teeth, combo.ring_teeth, ...
                          combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, combo.bending_safety, combo.weight];
    end
    
    % Sort by weight (lowest to highest)
    [~, sort_idx] = sort(data_22DP(:,9));  % Column 9 = weight
    data_22DP = data_22DP(sort_idx,:);
    DP22_designs_sorted = DP22_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_22DP, 1));
    T22 = array2table(data_22DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'Safety_Factor','Weight_lb' 
    });
    disp(T22);
    
    % Show best DP22 design
    best_22DP = DP22_designs_sorted(1);
    fprintf('\nBEST DP 22 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_22DP.sun_teeth, best_22DP.planet_large_teeth, ...
        best_22DP.planet_small_teeth, best_22DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", Safety: %.1f\n', ...
        best_22DP.overall_ratio, best_22DP.ring_OD, best_22DP.first_stage_OD, best_22DP.bending_safety);
    fprintf('\n');
end

% DP 24 Designs
if ~isempty(DP24_designs)
    fprintf('========================== TOP DP 24 DESIGNS (STRONGEST) ==========================\n');
    
    % Convert DP24 to table
    n = length(DP24_designs);
    data_24DP = zeros(n, 9);
    for i = 1:n
        combo = DP24_designs(i);
        data_24DP(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                          combo.planet_small_teeth, combo.ring_teeth, ...
                          combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, combo.bending_safety, combo.weight];
    end
    
    % Sort by weight (lowest to highest)
    [~, sort_idx] = sort(data_24DP(:,9));  % Column 9 = weight
    data_24DP = data_24DP(sort_idx,:);
    DP24_designs_sorted = DP24_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_24DP, 1));
    T24 = array2table(data_24DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'Safety_Factor', 'Weight_lb'
    });
    disp(T24);
    
    % Show best DP24 design
    best_24DP = DP24_designs_sorted(1);
    fprintf('\nBEST DP 24 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_24DP.sun_teeth, best_24DP.planet_large_teeth, ...
        best_24DP.planet_small_teeth, best_24DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", Safety: %.1f\n', ...
        best_24DP.overall_ratio, best_24DP.ring_OD, best_24DP.first_stage_OD, best_24DP.bending_safety);
    fprintf('\n');
end

end
%% ==================== DP LIMIT CALCULATOR ====================
function DP_range = calculate_DP_limits(torque_Nm, yield_strength, safety, max_gearbox_OD)
% Calculate min and max DP based on physical limits
    
    fprintf('Calculating tooth size limits...\n');
    
    % 1. MAX DP: Finest pitch that can handle 40 Nm torque
    % Based on bending stress of smallest sun gear (12 teeth)
    torque_inlb = torque_Nm * 8.85;
    torque_per_planet = torque_inlb / 3;
    Y_min = 0.245; % Lewis factor for 12 teeth
    min_face_width = 0.4; % inches (practical minimum)
    
    allowable_stress = yield_strength / safety;
    max_DP = (allowable_stress * Y_min * min_face_width * 12) / (2 * torque_per_planet);
    max_DP = floor(min(max_DP, 32)); % Cap at DP 32 (very fine)
    
    % 2. MIN DP: Coarsest pitch that fits 12 teeth in ring constraint
    % Ring must have at least 12+40+22=74 teeth and fit in 5.85" OD
    min_ring_teeth = 74;
    min_DP = min_ring_teeth / (max_gearbox_OD - 2/16); % Conservative estimate
    min_DP = ceil(max(min_DP, 12)); % At least DP 12
    
    % 3. Get standard DP values in range
    all_DP = [12, 14, 16, 18, 20, 22, 24, 26, 28, 32];
    DP_range = all_DP(all_DP >= min_DP & all_DP <= max_DP);
    
    % If no standards in range, use calculated limits
    if isempty(DP_range)
        DP_range = [min_DP, max_DP];
    end
    
    fprintf('Tooth size limits: DP %.1f to %.1f\n', min_DP, max_DP);
    fprintf('Testing DP values: ');
    fprintf('%d ', DP_range);
    fprintf('\n');
end
%% ==================== CSV OUTPUT ====================
function output_to_csv(combinations, filename)
if isempty(combinations)
    fprintf('No data to write to CSV.\n');
    return;
end

headers = {'Sun_Teeth', 'Earth_Teeth', 'Moon_Teeth', 'Ring_Teeth', ...
           'Overall_Ratio', 'DP', 'Ring_Pitch_Dia', 'Ring_OD', 'First_Stage_OD', 'Carrier_Dia', ...
           'Safety_Factor'};
data = [];

for i = 1:length(combinations)
    combo = combinations(i);
    data = [data; ...
        combo.sun_teeth, combo.planet_large_teeth, combo.planet_small_teeth, ...
        combo.ring_teeth, combo.overall_ratio, combo.DP, combo.ring_pitch_dia, ...
        combo.ring_OD, combo.first_stage_OD, combo.carrier_dia, combo.bending_safety];
end

% Sort by safety factor (most robust first)
[~, sort_idx] = sort(data(:,10), 'descend');
data = data(sort_idx, :);

T = array2table(data, 'VariableNames', headers);
writetable(T, filename);

% Show file location
current_folder = pwd;
full_path = fullfile(current_folder, filename);
fprintf('Results written to: %s\n', full_path);
end
