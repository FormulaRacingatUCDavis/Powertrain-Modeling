function compoundPlanetaryDesign()
    clc
    close all

    % FIXED GEAR TEETH RANGES 
    sun_teeth_range = 8:30;          % Sun gear teeth range
    planet_gears.large = 40:60;       % Earth planet gear sizes
    planet_gears.small = 20:40;       % Moon planet gear sizes

    % Allowable gear ratio range
    gear_ratio_range = [8, 13];       % Minimum and maximum overall gear ratios

    % Physical constraints
    min_motor_shaft = 0.60;           % inches
    max_gearbox_OD = 5.25;            % inches
    max_gearbox_width = 2.625;         % inches
    Np = 3;                           % Number of planets
    
    % Load parameters
    input_torque = 40;                % N*m input torque
    safety_factor = 1.5;              % Reduced safety factor for weight savings
    
    % Material properties (4140 Steel source donalds doc)
    material.yield_strength = 161000; % psi
    material.hardness = 341;          % HB
    
    % DP_range = calculate_DP_limits(input_torque, material.yield_strength, safety_factor, max_gearbox_OD);          % Diametral Pitches to evaluate 
    DP_range = [16, 20, 24, 32];
    
    fprintf('=== FSAE Compound Planetary Gear Design ===\n');
    fprintf('Gear Ratio Range: %.1f:1 to %.1f:1\n', gear_ratio_range);
    fprintf('Input Torque: %d N*m, Safety Factor: %.1f\n', input_torque, safety_factor);
    fprintf('Max Gearbox OD: %.2f inches\n\n', max_gearbox_OD);
    
    %  GENERATE AND ANALYZE COMBINATIONS 
    all_valid_designs = [];
    
    for DP = DP_range
        fprintf('Analyzing DP = %d...\n', DP);
        combinations = generate_gear_combinations(sun_teeth_range, planet_gears, gear_ratio_range, min_motor_shaft, max_gearbox_OD, max_gearbox_width, DP, Np, input_torque, material, safety_factor);
        
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
    
    
    %  DISPLAY AND OUTPUT RESULTS 
    display_results(all_valid_designs, gear_ratio_range);
    % output_to_csv(all_valid_designs, 'fsae_gear_combinations.csv');

end

%%  ALLOWABLE BENDING STRESS CALCULATION
function allowable_bending_stress = calculate_bending_stress(material, safety_factor)

    allowable_bending_stress_number = 77.3 * material.hardness + 12800; % Simplified formula from Shigley's 11th edition Figure 14-2
    allowable_bending_stress = allowable_bending_stress_number / safety_factor;
    
end

%%  ALLOWABLE CONTACT STRESS CALCULATION
function allowable_contact_stress = calculate_contact_stress(material, safety_factor)
    
    allowable_contact_stress_number = 322 * material.hardness + 29100; % Simplified formula from Shigley's 11th edition Figure 14-5
    allowable_contact_stress = allowable_contact_stress_number / safety_factor;

end

%%  FACE WIDTH CALCULATION
function [first_face_width, second_face_width] = calculate_face_width(input_torque, combo, material, safety_factor, Np)
    % Local variables (only important for stress calculations)
    service_factor = 1.5;
    C_elastic = 2300;

    % Get geometry factors
    first_speed_factor = combo.planet_large_teeth / combo.sun_teeth;
    second_speed_factor = combo.ring_teeth / combo.planet_small_teeth;

    J_sun = get_agma_J_factor(combo.sun_teeth, combo.planet_large_teeth);
    J_planet_small = get_agma_J_factor(combo.planet_small_teeth, combo.ring_teeth);
    I_sun = (cosd(20) * sind(20) * first_speed_factor) / (2 * (first_speed_factor + 1)); % Based on Shigley's 11th edition equations for I factor Equation 14-23
    I_planet_small = (cosd(20) * sind(20) * second_speed_factor) / (2 * (second_speed_factor - 1));

    % Get sun and earth pitch diameters
    sun_pitch_diameter = combo.sun_teeth / combo.DP;
    planet_large_pitch_diameter = combo.planet_large_teeth / combo.DP;
    planet_small_pitch_diameter = combo.planet_small_teeth / combo.DP;

    % Convert input torque from metric to imperial
    sun_torque_in_lb = input_torque * 8.85075;

    % Calculate tangential load on each gear tooth (Wt)
    tangential_load_1 = (2 * sun_torque_in_lb) / (sun_pitch_diameter * Np);
    tangential_load_2 = (tangential_load_1 / Np) * (planet_large_pitch_diameter / sun_pitch_diameter);

    % Get allowable bending and contact stresses based on hardness
    allowable_bending_stress = calculate_bending_stress(material, safety_factor);
    allowable_contact_stress = calculate_contact_stress(material, safety_factor);

    % Calculate face width using simplified AGMA bending and contact stress equations
    first_face_width_bending = (tangential_load_1 * combo.DP * service_factor) / (allowable_bending_stress * J_sun);
    first_face_width_contact = (service_factor * tangential_load_1 * C_elastic * C_elastic) / (sun_pitch_diameter * I_sun * allowable_contact_stress * allowable_contact_stress);
    second_face_width_bending = (tangential_load_2 * combo.DP * service_factor) / (allowable_bending_stress * J_planet_small);
    second_face_width_contact = (service_factor * tangential_load_2 * C_elastic * C_elastic) / (planet_small_pitch_diameter * I_planet_small * allowable_contact_stress * allowable_contact_stress);

    % Return the thickest face width for each stage
    first_face_width = max(first_face_width_bending, first_face_width_contact);
    second_face_width = max(second_face_width_bending, second_face_width_contact);
end

%%   STRESS ANALYSIS 
%{
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
    tangential_load = (torque_in_lb * combo.DP) / combo.sun_teeth;
    allowable_bending_stress = material.yield_strength / safety_factor;
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
    ideal_face_width = (tangential_load * combo.DP) / (allowable_bending_stress * Y);
end
%}
%%  LEWIS FORM FACTOR LOOKUP 
%{
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
%}

%%  GEOMETRY FACTOR LOOKUP (FOR BENDING CONTACT STRESS)
function J = get_agma_J_factor(pinion_teeth, mating_teeth)
% Returns AGMA geometry factor J based on number of teeth for 20° pressure angle
% Values estimated from Shigley's 11th edition Figure 14-6

    % Define lookup table: rows = pinion teeth, columns = mating teeth
    pinion_table = [12, 15, 17, 20, 25, 30, 40, 50, 80, Inf]';
    mating_table = [17, 25, 35, 50, 85, 170, 1000];

    J_values = [
        0.21, 0.21, 0.21, 0.21, 0.21, 0.21, 0.21;   % 12
        0.245,0.245,0.245,0.245,0.245,0.245,0.245;  % 15
        0.28, 0.282,0.284,0.286,0.288,0.29, 0.29;   % 17
        0.32, 0.33, 0.34, 0.35, 0.36, 0.37, 0.375;  % 20
        0.35, 0.36, 0.375,0.388,0.40, 0.41, 0.42;   % 25
        0.37, 0.385,0.40, 0.415,0.43, 0.44, 0.45;   % 30
        0.40, 0.415,0.43, 0.445,0.46, 0.475,0.485;  % 40
        0.42, 0.435,0.45, 0.47, 0.485,0.50, 0.51;   % 50
        0.44, 0.46, 0.475,0.49, 0.51, 0.525,0.54;   % 80
        0.455,0.475,0.49, 0.51, 0.53, 0.545,0.56    % Inf
    ];

    % Validate inputs
    if isempty(pinion_teeth) || isempty(mating_teeth)
        J = NaN;
        return;
    end

    % Handle pinion_teeth beyond table bounds by clamping to [min, max]
    % Represent infinite as a very large number for interpolation purposes
    pinion_x = pinion_table;
    pinion_x_numeric = pinion_x;
    pinion_x_numeric(isinf(pinion_x)) = max(pinion_x_numeric(~isinf(pinion_x))) * 2;

    % Prepare mating table numeric (columns)
    mating_x = mating_table;

    % If mating_teeth exceeds largest column, allow extrapolation using last column
    % Similarly for pinion_teeth we allow interpolation/extrapolation across rows

    % Create gridded interpolant over pinion (rows) and mating (cols)
    [M_mat, P_mat] = meshgrid(mating_x, pinion_x_numeric);
    F = griddedInterpolant(P_mat, M_mat, J_values, 'linear', 'nearest');

    % For query, map infinite pinion_teeth to large numeric
    query_pinion = pinion_teeth;
    if isinf(query_pinion)
        query_pinion = pinion_x_numeric(end);
    end

    % Evaluate interpolant; this will linearly interpolate in both directions
    J = F(query_pinion, mating_teeth);

    % If result is NaN (outside convex hull), perform 1D interpolation fallback:
    if isnan(J)
        % First interpolate along pinion for nearest two mating columns
        % Clamp mating to table bounds for fallback
        mating_clamped = min(max(mating_teeth, mating_x(1)), mating_x(end));
        % Interpolate each column at query_pinion
        col_vals = zeros(1, numel(mating_x));
        for k = 1:numel(mating_x)
            col_vals(k) = interp1(pinion_x_numeric, J_values(:,k), query_pinion, 'linear', 'extrap');
        end
        % Then interpolate across mating
        J = interp1(mating_x, col_vals, mating_clamped, 'linear', 'extrap');
    end

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
    sun_volume = sun_area * combo.first_face_width;
    
    % Planet gears volume
    % earth
    planet_large_pitch_dia = combo.planet_large_teeth / DP;
    planet_large_root_dia = (combo.planet_large_teeth - 2.5) / DP;
    planet_large_area = pi * (planet_large_root_dia/2)^2;
    planet_large_volume = planet_large_area * combo.first_face_width * 3;  % 3 planets
    
    % moon 
    planet_small_pitch_dia = combo.planet_small_teeth / DP;
    planet_small_root_dia = (combo.planet_small_teeth - 2.5) / DP;
    planet_small_area = pi * (planet_small_root_dia/2)^2;
    planet_small_volume = planet_small_area * combo.second_face_width * 3;  % 3 planets
    
    % 3. Ring gear volume 
    ring_pitch_dia = combo.ring_teeth / DP;
    ring_OD = ring_pitch_dia;  % For internal gear
    ring_ID = ring_OD - (4/DP);  % Approximate internal diameter
    ring_area = pi * ((ring_OD/2)^2 - (ring_ID/2)^2);
    ring_volume = ring_area * (combo.second_face_width + 0.050);
    
    % Carrier volume (rough estimate based on diameter)
    carrier_dia = combo.carrier_dia;
    carrier_area = 0.3 * pi * (carrier_dia/2)^2;  % 30% solid material
    carrier_volume = carrier_area * combo.second_face_width;
    
    % Total volume and weight
    total_volume = sun_volume + planet_large_volume + planet_small_volume + ...
                   ring_volume + carrier_volume;
    
    weight = total_volume * steel_density;
end
   
%%  GEAR RATIO CALCULATIONS 
function overall_ratio = calculate_gear_ratio(sun_teeth, ring_teeth, ...
    planet_large_teeth, planet_small_teeth)

    % Calculate overall gear ratio from sun to carrier (fixed ring)
    stage_2_gear_ratio = ring_teeth / planet_small_teeth;
    stage_1_gear_ratio = planet_large_teeth / sun_teeth;
    overall_ratio = stage_2_gear_ratio * stage_1_gear_ratio + 1;
end

%%  VALIDATION FUNCTION 
function [is_valid, overall_ratio] = valid_gear_combination(gear_ratio_range, ...
        min_motor_shaft, max_gearbox_OD, max_gearbox_width, Np, combo)
    
    % Calculate ratios
    overall_ratio = calculate_gear_ratio(combo.sun_teeth, combo.ring_teeth, ...
        combo.planet_large_teeth, combo.planet_small_teeth);

    % Check ratio range
    if overall_ratio < gear_ratio_range(1) || overall_ratio > gear_ratio_range(2)
        is_valid = false;
        return;
    end
    
    % Check motor input shaft size constraint
    sun_realistic_ID = (combo.sun_teeth - 2)/combo.DP;
    if min_motor_shaft > sun_realistic_ID
        is_valid = false;
        return;
    end
                                           
    % CORRECTED OD CALCULATIONS
    % Ring gear OD (internal gear) - pitch diameter is the OD for internal gears
    ring_OD = (combo.ring_teeth + 2) / combo.DP;
    
    % First stage OD (sun + large planets) - add 2 addendums for gear tips
    first_stage_OD = (combo.sun_teeth + (2 * combo.planet_large_teeth) + 2) / combo.DP;
    
    % The actual gearbox OD is the larger of ring OD or first stage OD
    gearbox_OD = max(ring_OD, first_stage_OD);
    
    if gearbox_OD > max_gearbox_OD
        is_valid = false;
        return;
    end

    % Check gearbox width
    if (combo.first_face_width + combo.second_face_width > max_gearbox_width)
        is_valid = false;
        return;
    end
    
    % Check sun gear shaft fit (minimum 0.625" bore)
    sun_root_dia = (combo.sun_teeth - 3) / combo.DP; % Root diameter for full-depth teeth
    min_shaft_dia = 0.625; % Motor shaft size
    if sun_root_dia < min_shaft_dia
        is_valid = false;
        return;
    end
    
    % Assembly constraint
    if mod(combo.sun_teeth + combo.ring_teeth, Np) ~= 0
        is_valid = false;
        return;
    end
    
    % Check that moon planets are smaller than earth planets
    if combo.planet_small_teeth >= combo.planet_large_teeth
        is_valid = false;
        return;
    end
    
    % All checks passed
    is_valid = true;
end

%%  COMBINATION GENERATOR 
function combinations = generate_gear_combinations(sun_teeth_range, ...
    planet_gears, gear_ratio_range, min_motor_shaft, max_gearbox_OD, max_gearbox_width, DP, Np, input_torque, material, safety_factor)

    combinations = [];
    combination_count = 0;
    % strong_count = 0;
    
    % Old nested for loops are not optimized for speed
    %{
    for sun_teeth = sun_teeth_range
        for planet_large_teeth = planet_gears.large
            for planet_small_teeth = planet_gears.small
                
                % Calculate ring teeth from geometric constraint
                ring_teeth = sun_teeth + planet_large_teeth + planet_small_teeth;
                
                % Check if combination is valid
                [is_valid, overall_ratio] = valid_gear_combination(...
                    sun_teeth, ring_teeth, planet_large_teeth, planet_small_teeth, ...
                    gear_ratio_range, min_motor_shaft, max_gearbox_OD, max_gearbox_width, DP, Np, combo);
                
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
                    
                    % Calculate ideal face width
                    [combo.sun_face_width, combo.allowable_bending_stress] = ...
                        calculate_face_width(input_torque, combo, material, safety_factor, Np);
                    
                    % Estimate weight of gearbox
                    combo.weight = estimate_gearbox_weight(combo, DP);
                    strong_count = strong_count + 1;
                    combinations = [combinations; combo];
    
                end
            end
        end
    end
    %}

    % Vectorize nested loops: generate all combinations using ndgrid and iterate linearly 
    [S, PL, PS] = ndgrid(sun_teeth_range, planet_gears.large, planet_gears.small);
    S = S(:); PL = PL(:); PS = PS(:);
    for idx = 1:numel(S)
        sun_teeth = S(idx);
        planet_large_teeth = PL(idx);
        planet_small_teeth = PS(idx);
        
        % Calculate ring teeth from geometric constraint
        ring_teeth = sun_teeth + planet_large_teeth + planet_small_teeth;
        
        % Pre-create combination structure (before validity check)
        combo = struct();
        combo.sun_teeth = sun_teeth;
        combo.ring_teeth = ring_teeth;
        combo.planet_large_teeth = planet_large_teeth;
        combo.planet_small_teeth = planet_small_teeth;
        combo.DP = DP;
        
        % Calculate CORRECTED physical dimensions (needed for validity checks that may use them)
        combo.ring_pitch_dia = ring_teeth / DP;
        combo.ring_OD = ring_teeth / DP; % For internal gear, pitch diameter = OD
        combo.first_stage_OD = (sun_teeth + 2 * planet_large_teeth + 2) / DP;
        combo.gearbox_OD = max(combo.ring_OD, combo.first_stage_OD);
        combo.carrier_dia = (sun_teeth + planet_large_teeth) / DP;

         % Calculate ideal face width
         [combo.first_face_width, combo.second_face_width] = ...
             calculate_face_width(input_torque, combo, material, safety_factor, Np);
        
        % Check if combination is valid
        [is_valid, overall_ratio] = valid_gear_combination(gear_ratio_range, min_motor_shaft, max_gearbox_OD, max_gearbox_width, Np, combo);
        
        if ~is_valid
            continue;
        end
        
        combination_count = combination_count + 1;
        
        % Fill remaining fields now that combination is valid
        combo.overall_ratio = overall_ratio;
        combo.DP = DP;
        
        % Estimate weight of gearbox
        combo.weight = estimate_gearbox_weight(combo, DP);
        combinations = [combinations; combo];
    end

    fprintf('  DP=%d: %d valid\n', DP, combination_count);
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
    DP32_designs = combinations([combinations.DP] == 32);
    
    %% SHOW BEST DESIGNS FOR EACH DP
    
    % DP 16 Designs
    if ~isempty(DP16_designs)
        fprintf('========================== TOP DP 16 DESIGNS (BEST BALANCED) ==========================\n');

        % Convert to data array
        n = length(DP16_designs);
        data_array = zeros(n, 10);
        for i = 1:n
            combo = DP16_designs(i);
            data_array(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                              combo.planet_small_teeth, combo.ring_teeth, ...
                              combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, ...
                              combo.first_face_width, combo.second_face_width, combo.weight];
        end

        % Apply weighted scoring (this does ALL the sorting)
        [sorted_data, DP16_designs_sorted, scores_16] = apply_weighted_scoring(data_array, DP16_designs, 10.5);

        % Add scores to the sorted data (now 10 columns)
        final_data = [sorted_data, scores_16];

        % Show top 5 balanced designs
        num_to_show = min(10, size(final_data, 1));
        T16 = array2table(final_data(1:num_to_show,:), 'VariableNames', {
            'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'First Face Width', 'Second Face Width', 'Weight_lb', 'Score'
        });
        disp(T16);

        % Show best balanced DP16 design
        best_16DP = DP16_designs_sorted(1);
        fprintf('BEST BALANCED DP 16 DESIGN:\n');
        fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
            best_16DP.sun_teeth, best_16DP.planet_large_teeth, ...
            best_16DP.planet_small_teeth, best_16DP.ring_teeth);
        fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", First Face Width: %.2f, Second Face Width: %.2f, Weight: %.2f lb, Score: %.3f\n', ...
            best_16DP.overall_ratio, best_16DP.ring_OD, best_16DP.first_stage_OD, ...
            best_16DP.first_face_width, best_16DP.second_face_width, best_16DP.weight, scores_16(1));
        fprintf('\n\n');
    end
    
    % DP 20 Designs 
    if ~isempty(DP20_designs)
        fprintf('========================== TOP DP 20 DESIGNS (BEST BALANCED) ==========================\n');
        
        % Convert to data array
        n = length(DP20_designs);
        data_array = zeros(n, 10);
        for i = 1:n
            combo = DP20_designs(i);
            data_array(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                              combo.planet_small_teeth, combo.ring_teeth, ...
                              combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, ...
                              combo.first_face_width, combo.second_face_width, combo.weight];
        end
        
        % Apply weighted scoring (this does ALL the sorting)
        [sorted_data, DP20_designs_sorted, scores_20] = apply_weighted_scoring(data_array, DP20_designs, 10.5);
        
        % Add scores to the sorted data (now 10 columns)
        final_data = [sorted_data, scores_20];
        
        % Show top 5 balanced designs
        num_to_show = min(10, size(final_data, 1));
        T20 = array2table(final_data(1:num_to_show,:), 'VariableNames', {
            'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'First Face Width', 'Second Face Width', 'Weight_lb', 'Score'
        });
        disp(T20);
        
        % Show best balanced DP20 design
        best_20DP = DP20_designs_sorted(1);
        fprintf('BEST BALANCED DP 20 DESIGN:\n');
        fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
            best_20DP.sun_teeth, best_20DP.planet_large_teeth, ...
            best_20DP.planet_small_teeth, best_20DP.ring_teeth);
        fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", First Face Width: %.2f, Second Face Width: %.2f, Weight: %.2f lb, Score: %.3f\n', ...
            best_20DP.overall_ratio, best_20DP.ring_OD, best_20DP.first_stage_OD, ...
            best_20DP.first_face_width, best_20DP.second_face_width, best_20DP.weight, scores_20(1));
        fprintf('\n\n');
    end
    
    % DP 24 Designs
    if ~isempty(DP24_designs)
        fprintf('========================== TOP DP 24 DESIGNS (BEST BALANCED) ==========================\n');

        % Convert to data array
        n = length(DP24_designs);
        data_array = zeros(n, 10);
        for i = 1:n
            combo = DP24_designs(i);
            data_array(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                              combo.planet_small_teeth, combo.ring_teeth, ...
                              combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, ...
                              combo.first_face_width, combo.second_face_width, combo.weight];
        end

        % Apply weighted scoring (this does ALL the sorting)
        [sorted_data, DP24_designs_sorted, scores_24] = apply_weighted_scoring(data_array, DP24_designs, 10.5);

        % Add scores to the sorted data (now 10 columns)
        final_data = [sorted_data, scores_24];

        % Show top 5 balanced designs
        num_to_show = min(10, size(final_data, 1));
        T24 = array2table(final_data(1:num_to_show,:), 'VariableNames', {
            'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'First Face Width', 'Second Face Width', 'Weight_lb', 'Score'
        });
        disp(T24);

        % Show best balanced DP24 design
        best_24DP = DP24_designs_sorted(1);
        fprintf('BEST BALANCED DP 24 DESIGN:\n');
        fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
            best_24DP.sun_teeth, best_24DP.planet_large_teeth, ...
            best_24DP.planet_small_teeth, best_24DP.ring_teeth);
        fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", First Face Width: %.2f, Second Face Width: %.2f, Weight: %.2f lb, Score: %.3f\n', ...
            best_24DP.overall_ratio, best_24DP.ring_OD, best_24DP.first_stage_OD, ...
            best_24DP.first_face_width, best_24DP.second_face_width, best_24DP.weight, scores_24(1));
        fprintf('\n\n');
    end

    % DP 32 Designs
    if ~isempty(DP32_designs)
        fprintf('========================== TOP DP 32 DESIGNS (BEST BALANCED) ==========================\n');

        % Convert to data array
        n = length(DP32_designs);
        data_array = zeros(n, 10);
        for i = 1:n
            combo = DP32_designs(i);
            data_array(i,:) = [combo.sun_teeth, combo.planet_large_teeth, ...
                              combo.planet_small_teeth, combo.ring_teeth, ...
                              combo.overall_ratio, combo.ring_OD, combo.first_stage_OD, ...
                              combo.first_face_width, combo.second_face_width, combo.weight];
        end

        % Apply weighted scoring (this does ALL the sorting)
        [sorted_data, DP32_designs_sorted, scores_32] = apply_weighted_scoring(data_array, DP32_designs, 10.5);

        % Add scores to the sorted data (now 10 columns)
        final_data = [sorted_data, scores_32];

        % Show top 5 balanced designs
        num_to_show = min(10, size(final_data, 1));
        T32 = array2table(final_data(1:num_to_show,:), 'VariableNames', {
            'Sun', 'Earth', 'Moon', 'Ring', 'Ratio', 'Ring_OD', 'First_Stage_OD', 'First Face Width', 'Second Face Width', 'Weight_lb', 'Score'
        });
        disp(T32);

        % Show best balanced DP32 design
        best_32DP = DP32_designs_sorted(1);
        fprintf('BEST BALANCED DP 32 DESIGN:\n');
        fprintf('Sun: %d, Earth: %d, Moon: %d, Ring: %d\n', ...
            best_32DP.sun_teeth, best_32DP.planet_large_teeth, ...
            best_32DP.planet_small_teeth, best_32DP.ring_teeth);
        fprintf('Ratio: %.2f:1, Ring OD: %.2f", First Stage OD: %.2f", First Face Width: %.2f, Second Face Width: %.2f, Weight: %.2f lb, Score: %.3f\n', ...
            best_32DP.overall_ratio, best_32DP.ring_OD, best_32DP.first_stage_OD, ...
            best_32DP.first_face_width, best_32DP.second_face_width, best_32DP.weight, scores_32(1));
        fprintf('\n\n');
    end
end

%% ==================== DP LIMIT CALCULATOR ====================
%{
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
%}

%% ==================== CSV OUTPUT ====================
%{
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
%}

%% SORT BY NORMALIZED VALUES 
function [sorted_data, sorted_designs, combined_scores] = apply_weighted_scoring(data, designs, ideal_ratio)
    % Extract columns
    weights = data(:,9);  % Column 9 = weight
    ratios = data(:,5);   % Column 5 = gear ratio
    
    % Normalize both metrics to 0-1 scale (higher is better)
    if max(weights) == min(weights)
        normalized_weights = zeros(size(weights));  % All weights are equal
    else
        normalized_weights = (weights - min(weights)) / (max(weights) - min(weights));
    end
    
    ratio_deviations = abs(ratios - ideal_ratio);
    if max(ratio_deviations) == min(ratio_deviations)
        normalized_ratios = zeros(size(ratio_deviations));  % All ratios are equal
    else
        normalized_ratios = (ratio_deviations - min(ratio_deviations)) / (max(ratio_deviations) - min(ratio_deviations));
    end
    
    % Apply weighting factors
    weight_factor = 0.65;    % 65% importance on weight
    ratio_factor = 0.35;     % 35% importance on ratio proximity
    
    % Calculate combined score (higher is better)
    combined_scores = 1 - ((weight_factor * normalized_weights) + (ratio_factor * normalized_ratios));
    
    % Sort by combined score (highest first = best)
    [sorted_scores, sort_idx] = sort(combined_scores, 'descend');
    sorted_data = data(sort_idx,:);
    sorted_designs = designs(sort_idx);
    combined_scores = sorted_scores;  % Return the sorted scores
end