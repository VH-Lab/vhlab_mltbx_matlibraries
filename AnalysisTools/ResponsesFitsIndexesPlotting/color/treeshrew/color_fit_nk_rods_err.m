function [err,fitr]=color_fit_nk_rodserr(p,Lc,Sc,Rc,data)
%  COLOR_FIT_NK_ERR Color_fit function helper function for fitting
%
%   ERR=COLOR_FIT_NK_ERR(P,DATA)
%   P = [L S LC0 SC0] 
%   returns mean squared error of 
%   ABS(L*LC./(abs(LC)+Lc0)+S*SC./(abs(SC)+Sc0)) with data 
%  

c0Int = [0.1 0.5];
lc0=c0Int(1)+diff(c0Int)/(1+abs(p(4)));
sc0=c0Int(1)+diff(c0Int)/(1+abs(p(5)));
rc0=c0Int(1)+diff(c0Int)/(1+abs(p(6)));
NInt = [1 5];
lcN=NInt(1)+diff(NInt)/(1+abs(p(7)));
scN=NInt(1)+diff(NInt)/(1+abs(p(8)));
rcN=NInt(1)+diff(NInt)/(1+abs(p(9)));

fitr=abs(p(1)*naka_rushton_func(Lc,lc0,lcN)+p(2)*naka_rushton_func(Sc,sc0,scN)+p(3)*naka_rushton_func(Rc,rc0,rcN));
err=0;
d = (data-fitr);
err=err+sum(sum(d.*d));
