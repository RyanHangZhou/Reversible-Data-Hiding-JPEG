% ========================================================================
% USAGE: [height, width] = fun_read_sof_wh(a, z)
% Acquire size of JPEG image
%
% Inputs
%       a            -mark
%       z            -JPEG data
%
% Outputs
%       height        -height
%       width         -width
%
% Hang Zhou, April, 2015
% ========================================================================
function [height, width] = fun_read_sof_wh(a, z)

b=find(z(a+1)==192);
b=b(length(b),1);
c=a(b,1);
height = z(c+5:c+6, 1);
width = z(c+7:c+8, 1);
end
