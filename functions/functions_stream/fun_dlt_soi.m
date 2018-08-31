% ========================================================================
% USAGE: [a, m] = fun_dlt_soi(a)
% Acquire compressed data without 255
%
% Inputs
%       a            -compressed JPEG image data
%
% Outputs
%       y            -compressed JPEG image data without 255
%       m            -address of subscript of mark after 255
%
% Hang Zhou, April, 2015
% ========================================================================
function [a, m] = fun_dlt_soi(a)

s = [1;0;1;0; 1;1;1;1;1;1;1;1; 1;1;0;1; 1;0;0;1];
for i = 1:length(a)-19
    if(a(i:i+19)==s)
        m = i + 4;
        for k = i+4:length(a)-16
            a(k) = a(k+16);
        end
        break;
    end
end
a = a(1:length(a)-16);

end