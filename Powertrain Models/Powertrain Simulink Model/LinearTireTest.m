function [Fx, Fy] = LinearTireTest(Kappa, Alpha, Vc)

Kxk = 1000;
Kya = 1000;

Fx = Kxk .* Kappa; 

Fy = Kya .* Alpha;

Vc = Vc .*1; 

end 
