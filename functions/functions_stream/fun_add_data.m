% ========================================================================
% USAGE: s4 = fun_add_data(s, s1, index)
% Insert s1 into s at the index-th address
%
% Inputs
%       s            -bitstream to be inserted
%       s1           -bitstream to insert
%       index        -address to insert
%
% Outputs
%       s4           -output bitstream
%
% Hang Zhou, April, 2015
% ========================================================================
function s4 = fun_add_data(s, s1, index)

s2 = s(1:index-1);
s3 = s(index:length(s));
s4 = [s2;s1;s3];

end
