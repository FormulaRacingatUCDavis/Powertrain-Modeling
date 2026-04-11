%% EXPLICIT VARIABLES %%

% Universal variables
g = 9.80665;

% Car geometric properties
m = linspace(100, 500, 100);
h_cg = linspace(0.05, 1, 100);
t = 1.2;

% Aero properties
C_l = 3.215;
ro = 1.165;
A = 0.9237;
v = 20;

% Initial friction coefficient between tires and ground
mu_0 = 1.2;

% Find aero downforce
Fz_aero = calculate_aero(C_l, ro, A, v);

% Call the optimization function to compute the lateral acceleration
[grid_m, grid_h_cg] = meshgrid(m, h_cg);
optimized_a_y = optimize_lateral_acceleration(grid_m, grid_h_cg, t, g, mu_0, Fz_aero);

% Plot on a surface
surf(grid_m, grid_h_cg, optimized_a_y);
title('Optimized Lateral Acceleration Surface');
xlabel('Mass (kg)');
ylabel('Center of Gravity Height (m)');
zlabel('Lateral Acceleration (m/s^2)');
colorbar;

%% FRICTION COEFFICIENT CALCULATION %%
function mu = calculate_mu(Fz, mu_0)

    x = Fz ./ 1324;
    tol = 1e-12;                 
    x(x < tol) = tol;           % prevent negative/zero base for fractional negative power
    mu = mu_0 .* (x .^ (-0.2));

end

%% AERO DOWNFORCE CALCULATION %%
function Fz_aero = calculate_aero(C_l, ro, A, v)

    Fz_aero = 0.5 * ro * A * C_l * v.^2;
    
end 

%% LATERAL ACCELERATION FUNCTION %%
function a_y = optimize_lateral_acceleration(m, h_cg, t, g, mu_0, Fz_aero)
    % Optimize lateral acceleration via iterative equilibrium of tire loads
    % Inputs can be vectors: m, h_cg, Fz_aero (same size). Returns a_y same size.
    
    size_m = size(m);

    % Ensure inputs are column vectors for consistent elementwise ops
    m = m(:);
    h_cg = h_cg(:);
    
    % Initialize variables
    a_yo = zeros(size(m));      % initial guess (vector)
    error = ones(size(m));
    
    tol = 1e-3;
    maxIter = 1000;
    iter = 0;
    
    while any(error > tol) && iter < maxIter
        % Find weight transfer from current a_yo (elementwise)
        del_Fz = (m .* a_yo .* h_cg) ./ t;
    
        % Find tire normal forces (elementwise)
        Fz_r = (0.5 .* m .* g) + del_Fz + (Fz_aero./2);
        Fz_l = (0.5 .* m .* g) - del_Fz + (Fz_aero./2);
    
        % Find tire friction coefficients (vectorized)
        mu_r = calculate_mu(Fz_r, mu_0);
        mu_l = calculate_mu(Fz_l, mu_0);
    
        % Find lateral forces of each tire
        Fy_r = mu_r .* Fz_r;
        Fy_l = mu_l .* Fz_l;
    
        % Sum for lateral forces on the entire body
        Fy_body = Fy_r + Fy_l;
    
        % Use lateral force to find body a_y, calculate error, and update a_yo
        a_y_new = Fy_body ./ m;
        error = abs(a_y_new - a_yo);
        a_yo = max(a_y_new, 0);

        iter = iter + 1;

    end

    a_y = reshape(a_yo, size_m); % return same shape (column) as inputs were normalized to
end