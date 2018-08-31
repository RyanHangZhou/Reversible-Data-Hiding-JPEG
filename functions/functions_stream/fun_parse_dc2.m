% ========================================================================
% USAGE: [k, cat] = fun_parse_dc2(y, z, w)
% Parse DC stream
%
% Inputs
%       y            -compressed JPEG image data
%       z            -DC code table
%       w            -starting place of DC bits
%
% Outputs
%       k            -starting place of AC bits
%       cat          -appended length of each AC bits
%
% Hang Zhou, April, 2015
% ========================================================================
function [k, cat] = fun_parse_dc2(y, z, w)

table = z;
[p, ~] = size(table);
y1 = [];
x1 = [];
i=1;
d=2;
tmp = ones(p, 1);
w = w-1;
pp = 0;
while pp<1,
    % match y(i) to that of the d-th bit in the table
    tmp = tmp.*[table(:, d)==y(w+i)]; % tmp is a vector of 0 and 1 with 1 indicate a match
    if sum(tmp)==1,  % narrow down to one symbol, find it
        d = 2;          % reset pointer to columns of table.
        kkt = 0;
        for kk = 1:length(tmp)
            if(tmp(kk)==1), kkt=kk;end
        end
        cat = kkt-1;
        tmp = ones(p, 1);
        if cat==length(table)-1, i = i+1; end % Because the comparison ends in last but one column,but still a 0 is left
        if(cat ~=0)
            x1 = y(w+i+1:w+i+cat);
            pp = pp+1;
        else
            pp = pp+1;
        end
        i = i+cat;
    else
        d = d+1;
    end
    i=i+1;
end
k=i+w-cat;