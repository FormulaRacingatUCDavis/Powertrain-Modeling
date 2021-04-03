clc
close all
clear

muw = 1.05E-03;
mua = 1.81E-05;
cw = 4180;
ca = 1006;
kw = 0.59803;
ka = 0.02572;
k = 237;
rhow = 997;
rhoa = 1.225;
m = 21.3;

RadSize_Annular_FE8(Nplate, L, Ww, Hw, Sfin, t, Qw, mdota, Tiw, Tia)