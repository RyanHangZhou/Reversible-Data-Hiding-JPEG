% ========================================================================
% USAGE: y = fun_read_dht(a, z, f, num)
% Acquire DHT segment of JPEG header
%
% Inputs
%       a            -location of huffman table
%       z            -JPEG data
%       f            -fid of JPEG data
%       num          -selection number
%
% Outputs
%       y            -binary of JPEG header
%
% Hang Zhou, April, 2015
% ========================================================================
function y = fun_read_dht(a, z, f, num)

b = find(z(a+1,1)==196);
b = b(num, 1);
c = a(b, 1);
d = z((c+2), 1)*16*16+z((c+3), 1);
status = fseek(f, c-1, 'bof');
y = fread(f, d+2, 'uint8');
end

