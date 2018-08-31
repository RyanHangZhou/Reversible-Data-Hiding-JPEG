% ========================================================================
% USAGE: [ldc, cdc] = fun_read_huff(a, b, z, f)
% Acquire huffman table
%
% Hang Zhou, April, 2015
% ========================================================================
function [ldc, cdc] = fun_read_huff(a, b, z, f)

c = a(b,1);
d = z((c+2), 1)*16*16+z((c+3), 1);
status = fseek(f, c-1, 'bof');
y = fread(f, d+2, 'uint8');

dc0p = 5;
cn0 = sum(y(6:21, 1));
ldc = y(6:21+cn0, 1);
ldc = [255; 196; floor((length(ldc)+3)/256); mod((length(ldc)+3), 256);y(dc0p, 1);ldc];

dc1p = dc0p+17+cn0;
cn1 = sum(y(dc1p+1:dc1p+16, 1));
cdc = y(dc1p+1:dc1p+16+cn1, 1);
cdc = [255; 196; floor((length(cdc)+3)/256); mod((length(cdc)+3), 256); y(dc1p, 1); cdc];

end

