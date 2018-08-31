% ========================================================================
% USAGE: [m, n, blkm, blkn] = fun_jpg_size(z, a)
% Acquire size of JPEG image
%
% Inputs
%       z            -JPEG data
%       a            -marks
%
% Outputs
%       m            -image height
%       m            -image width
%       blkm         -number of vertical blocks
%       blkn         -number of horizontal blocks
%
% Hang Zhou, April, 2015
% ========================================================================
function [m, n, blkm, blkn] = fun_jpg_size(z, a)

b = find(z(a+1, 1)==192);
c = a(b, 1);
m = z((c+5), 1)*16*16+z((c+6), 1);
n = z((c+7), 1)*16*16+z((c+8), 1);
blkm = ceil(m/8);
blkn = ceil(n/8);

end