% ========================================================================
% USAGE: z = fun_set_sof_wh(a, z, height, width)
% set image size at SOF (Start Of Frame)
%
% Inputs
%       a            -marks
%       z            -input bitstream
%       height       -image height
%       width        -image width
%
% Outputs
%       z            -output bitstream
%
% Hang Zhou, April, 2015
% ========================================================================
function z = fun_set_sof_wh(a, z, height, width)

b = find(z(a+1)==192);
b = b(length(b),1);
c = a(b,1);

% transform image size to hex data each with 2 bytes
h1 = fix(height/256);
h2 = height - h1*256;

w1 = fix(width/256);
w2 = width - w1*256;

% embed image size
z(c+5, 1) = h1;
z(c+6, 1) = h2;
z(c+7, 1) = w1;
z(c+8, 1) = w2;

end