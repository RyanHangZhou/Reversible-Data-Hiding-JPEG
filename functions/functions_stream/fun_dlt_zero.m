% ========================================================================
% USAGE: y = fun_dlt_zero(y)
% Acquire compressed data without 255
%
% Inputs
%       y            -compressed JPEG image data
%
% Outputs
%       y            -compressed JPEG image data without 255
%
% Hang Zhou, April, 2015
% ========================================================================
function y = fun_dlt_zero(y)

a = find(y==255);
[m, ~] = size(a);
i = 0;
for j=1:m
       y(a(j, 1)+1-i)=[];    
          i = i+1; 
end
  
end

