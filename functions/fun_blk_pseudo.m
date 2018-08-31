% ========================================================================
% USAGE: blk_chg = fun_blk_pseudo(pblknum, key1, alpha)
% randomize alpha percentage of blocks and leave (1-alpha) sequentially
% connected
%
% Inputs
%       pblknum      -number of blocks
%       key1         -shuffling key
%       alpha        -percentage of shuffling
%
% Outputs
%       blk_chg      -cascaded blocks
%
% Hang Zhou, April, 2015
% ========================================================================
function blk_chg = fun_blk_pseudo(pblknum, key1, alpha)

for i = 1:pblknum
    blk_chg0(i) = i;
end
rand('state', key1);
temp_rand = randperm(numel(blk_chg0(2:length(blk_chg0)))); blk_chg=[blk_chg0(1)'; blk_chg0(temp_rand(2:floor(pblknum*alpha)))']';
for i = 1:pblknum
    if(isempty(find(blk_chg==i))==1)
        blk_chg = [blk_chg';i]';
    end
end

end