% ========================================================================
% USAGE: y = fun_read_header(a, z)
% Acquire JPEG header and transform it to hex
%
% Inputs
%       a            -mark
%       z            -JPEG data
%
% Outputs
%       y            -binary of JPEG header
%
% Hang Zhou, April, 2015
% ========================================================================
function y = fun_read_header(a, z)

b = find(z(a+1)==218);
b = b(length(b), 1);
% mark of 255
c = a(b, 1); 
% mark of each mark
d = z((c+2), 1)*16*16+z((c+3), 1);
% binary of JPEG header
y = z(1:c+1+d, 1);
end
