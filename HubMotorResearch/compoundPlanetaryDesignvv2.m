function compoundPlanetaryDesign()
clc
close all

%% FIXED GEAR TEETH RANGES 
sun_teeth_range = 12:18;          % Sun gear teeth range
planet_gears.large = 40:50;       % Earth planet gear sizes  
planet_gears.small = 22:26;       % Moon planet gear sizes

% Allowable gear ratio range
gear_ratio_range = [8, 13];       % Minimum and maximum overall gear ratios

% Physical constraints
max_ring_OD = 5.85;               % inches
Np = 3;                           % Number of planets

% Load parameters 
input_torque = 40;                % N*m input torque
safety_factor = 1.5;              % Reduced safety factor for weight savings

% Material properties (4140 Steel source donalds doc)
material.yield_strength = 161000; % psi
material.hardness = 341;          % HB

DP_range = calculate_DP_limits(input_torque, material.yield_strength, safety_factor, max_ring_OD);          % Diametral Pitches to evaluate 

fprintf('=== FSAE Compound Planetary Gear Design ===\n');
fprintf('Gear Ratio Range: %.1f:1 to %.1f:1\n', gear_ratio_range);
fprintf('Input Torque: %d N*m, Safety Factor: %.1f\n', input_torque, safety_factor);
fprintf('Max Ring OD: %.2f inches\n\n', max_ring_OD);

%%  GENERATE AND ANALYZE COMBINATIONS 
all_valid_designs = [];

for DP = DP_range
    fprintf('Analyzing DP = %d...\n', DP);
    combinations = generate_gear_combinations(sun_teeth_range, planet_gears, gear_ratio_range, max_ring_OD, DP, Np, input_torque, material, safety_factor);
    
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
    
    % torque to in-lb (1 N*m = 8.85 in-lb)
    torque_in_lb = input_torque * 8.85;
    
    % Conservative torque per planet 
    torque_per_planet = torque_in_lb / 3;
    
    % pitch diameter of sun gear 
    pitch_dia_sun = combo.sun_teeth / combo.DP; % inches
    
    % Tangential force on sun gear
    tangential_force = 2 * torque_per_planet / pitch_dia_sun;
    
    % Estimate face width based on DP 
    face_width = 0.5 + (20 - combo.DP) * 0.1; 
    
    % Lewis form factor lookup from table for 20° pressure angle on the
    % textbook page 730 
    Y = get_lewis_form_factor(combo.sun_teeth);
    
    bending_stress = tangential_force * combo.DP / (face_width * Y);
    
    % Safety factor
    bending_safety = material.yield_strength / bending_stress;
    
    % service factor 
    service_factor = 1.25; 
    adjusted_safety = bending_safety / service_factor;
    
    is_strong = (adjusted_safety >= safety_factor);
    
    % Store calculated values for reporting
    combo.face_width = face_width;
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
    max_ring_OD, DP, Np)

% Calculate ratios
[g_rp, g_ps] = calculate_gear_ratios(sun_teeth, ring_teeth, ...
    planet_large_teeth, planet_small_teeth);
overall_ratio = calculate_overall_gear_ratio(g_rp, g_ps);

% Check ratio range
if overall_ratio < gear_ratio_range(1) || overall_ratio > gear_ratio_range(2)
    is_valid = false;
    return;
end

% Check ring OD constraint
ring_OD = ring_teeth / DP + 2/DP;
if ring_OD > max_ring_OD
    is_valid = false;
    return;
end
% Check sun gear shaft fit (minimum 0.625" bore)
sun_root_dia = (sun_teeth - 2.5) / DP; % Root diameter for full-depth teeth
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
    planet_gears, gear_ratio_range, max_ring_OD, DP, Np, input_torque, material, safety_factor)

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
                gear_ratio_range, max_ring_OD, DP, Np);
            
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
                
                % Calculate physical dimensions
                combo.ring_pitch_dia = ring_teeth / DP;
                combo.ring_OD = combo.ring_pitch_dia + 2/DP;
                combo.carrier_dia = (sun_teeth + planet_large_teeth) / DP;
                
                % Check strength
                [combo.is_strong, combo.bending_safety] = ...
                    check_strength_practical(combo, input_torque, material, safety_factor);
                
                if combo.is_strong
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
DP20_designs = combinations([combinations.DP] == 20);
DP24_designs = combinations([combinations.DP] == 24);

fprintf('Breakdown by Tooth Size:\n');
fprintf('DP 16: %d designs (strongest, heaviest)\n', length(DP16_designs));
fprintf('DP 20: %d designs (balanced performance)\n', length(DP20_designs));
fprintf('DP 24: %d designs (lightest, most compact)\n\n', length(DP24_designs));

%% SHOW BEST DESIGNS FOR EACH DP
% DP 16 Designs
if ~isempty(DP16_designs)
    fprintf('=== TOP DP 16 DESIGNS (STRONGEST) ===\n');
    
    % Convert DP16 to table
    data_16DP = [];
    for i = 1:length(DP16_designs)
        combo = DP16_designs(i);
        data_16DP = [data_16DP; ...
            combo.sun_teeth, combo.planet_large_teeth, combo.planet_small_teeth, ...
            combo.ring_teeth, combo.overall_ratio, combo.ring_OD, combo.bending_safety];
    end
    
    % Sort by safety factor
    [~, sort_idx] = sort(data_16DP(:,7), 'descend');
    data_16DP = data_16DP(sort_idx, :);
    DP16_designs_sorted = DP16_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_16DP, 1));
    T16 = array2table(data_16DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'Safety_Factor'
    });
    disp(T16);
    
    % Show best DP16 design
    best_16DP = DP16_designs_sorted(1);
    fprintf('\nBEST DP 16 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_16DP.sun_teeth, best_16DP.planet_large_teeth, ...
        best_16DP.planet_small_teeth, best_16DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", Safety: %.1f\n', ...
        best_16DP.overall_ratio, best_16DP.ring_OD, best_16DP.bending_safety);
end

% DP 20 Designs
if ~isempty(DP20_designs)
    fprintf('\n=== TOP DP 20 DESIGNS (BALANCED) ===\n');
    
    % Convert DP20 to table
    data_20DP = [];
    for i = 1:length(DP20_designs)
        combo = DP20_designs(i);
        data_20DP = [data_20DP; ...
            combo.sun_teeth, combo.planet_large_teeth, combo.planet_small_teeth, ...
            combo.ring_teeth, combo.overall_ratio, combo.ring_OD, combo.bending_safety];
    end
    
    % Sort by safety factor
    [~, sort_idx] = sort(data_20DP(:,7), 'descend');
    data_20DP = data_20DP(sort_idx, :);
    DP20_designs_sorted = DP20_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_20DP, 1));
    T20 = array2table(data_20DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'Safety_Factor'
    });
    disp(T20);
    
    % Show best DP20 design
    best_20DP = DP20_designs_sorted(1);
    fprintf('\nBEST DP 20 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_20DP.sun_teeth, best_20DP.planet_large_teeth, ...
        best_20DP.planet_small_teeth, best_20DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", Safety: %.1f\n', ...
        best_20DP.overall_ratio, best_20DP.ring_OD, best_20DP.bending_safety);
end

% DP 24 Designs
if ~isempty(DP24_designs)
    fprintf('\n=== TOP DP 24 DESIGNS (COMPACT) ===\n');
    
    % Convert DP24 to table
    data_24DP = [];
    for i = 1:length(DP24_designs)
        combo = DP24_designs(i);
        data_24DP = [data_24DP; ...
            combo.sun_teeth, combo.planet_large_teeth, combo.planet_small_teeth, ...
            combo.ring_teeth, combo.overall_ratio, combo.ring_OD, combo.bending_safety];
    end
    
    % Sort by safety factor
    [~, sort_idx] = sort(data_24DP(:,7), 'descend');
    data_24DP = data_24DP(sort_idx, :);
    DP24_designs_sorted = DP24_designs(sort_idx);
    
    % Show top 5 designs
    num_to_show = min(5, size(data_24DP, 1));
    T24 = array2table(data_24DP(1:num_to_show,:), 'VariableNames', {
        'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'Safety_Factor'
    });
    disp(T24);
    
    % Show best DP24 design
    best_24DP = DP24_designs_sorted(1);
    fprintf('\nBEST DP 24 DESIGN:\n');
    fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
        best_24DP.sun_teeth, best_24DP.planet_large_teeth, ...
        best_24DP.planet_small_teeth, best_24DP.ring_teeth);
    fprintf('Ratio: %.2f:1, Ring OD: %.2f", Safety: %.1f\n', ...
        best_24DP.overall_ratio, best_24DP.ring_OD, best_24DP.bending_safety);
end



end
%% ==================== DP LIMIT CALCULATOR ====================
function DP_range = calculate_DP_limits(torque_Nm, yield_strength, safety, max_ring_OD)
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
    min_DP = min_ring_teeth / (max_ring_OD - 2/16); % Conservative estimate
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
           'Overall_Ratio', 'DP', 'Ring_Pitch_Dia', 'Ring_OD', 'Carrier_Dia', ...
           'Safety_Factor'};
data = [];

for i = 1:length(combinations)
    combo = combinations(i);
    data = [data; ...
        combo.sun_teeth, combo.planet_large_teeth, combo.planet_small_teeth, ...
        combo.ring_teeth, combo.overall_ratio, combo.DP, combo.ring_pitch_dia, ...
        combo.ring_OD, combo.carrier_dia, combo.bending_safety];
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
