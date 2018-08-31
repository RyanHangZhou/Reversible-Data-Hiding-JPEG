% ========================================================================
% USAGE: s = fun_stream_cipher(len, key)
% Create binarized encryption bitstream with specific key
%
% Inputs
%       len          -length set for created encryption bitstream
%       key          -key
%
% Outputs
%       s            -encryption bitstream
%
% Hang Zhou, April, 2015
% ========================================================================
function s = fun_stream_cipher(len, key)

rand('state', key);
s = double(rand(len, 1)>0.5);