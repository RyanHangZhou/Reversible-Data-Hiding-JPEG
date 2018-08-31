% ========================================================================
% USAGE: y = fun_read_sos(a, z, f)
% Acquire compressed JPEG image data
%
% Inputs
%       a            -marks (255)
%       z            -binarized input data
%       f            -fid
%
% Outputs
%       y            -compressed JPEG image data
%
% Hang Zhou, April, 2015
% ========================================================================
function y = fun_read_sos(a, z, f)

b = find(z(a+1)==218);
c = a(b, 1);
d = z((c+2), 1)*16*16+z((c+3), 1);
e = find(z(a+1)==217);
g = a(e, 1)-c(1, 1)-d(1, 1)-2;
status = fseek(f, c+d+1, 'bof');
y = fread(f,g,'uint8');

end

