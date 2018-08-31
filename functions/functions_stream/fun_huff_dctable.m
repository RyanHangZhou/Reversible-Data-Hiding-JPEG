% ========================================================================
% USAGE: [dctable, dctablegui] = fun_huff_dctable(y)
% Acquire DC huffman table of JPEG header and rank them by "cat"
%
% Inputs
%       y            -binary of JPEG header
%
% Outputs
%       dctable      -DC huffman table
%       dctablegui   -DC huffman table and original data
%
% Hang Zhou, April, 2015
% ========================================================================
function [dctable, dctablegui] = fun_huff_dctable(y)

bit = y(6:21, 1);
% total number of codon of DC huffman
dchuffnum = sum(bit);
dccat = y(22:22+dchuffnum-1, 1);

q = 1;           
for l = 1:16
    i = bit(l,1);
    while(i)>0
        i = i-1;
        % dccl records length of each huffman for DC
        dccl(q, 1) = l;
        q = q+1;
    end
end
dccl(q,1) = 0;

code = 0;
si = dccl(1, 1);
p = 1;

while(dccl(p, 1))>0
    while(dccl(p, 1))==si
        % dccode records corresponding binarized size
        dccode(p,1) = code;
        p = p+1;
        code = code+1;
    end
    code = bitshift(code, 1);
    si = si+1;
end
dccl(q) = [];

% transform into binary and save into dctable
for l = 1:dchuffnum
    for p = 1:dccl(l, 1)
        dctable(l, p) = rem(dccode(l, 1), 2);
        dccode(l, 1) = fix(dccode(l, 1)/2);        
        p = p+1;
    end
    dctable(l, :) = fliplr(dctable(l, :));
    l = l+1;
end
dctable = [dccat dccl dctable];
dctable = sortrows(dctable, 1); 
dctablegui = dctable;
dctable(:, 1) = [];
end