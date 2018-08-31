% ========================================================================
% USAGE: res_block_dc = fun_comp_seqblk(every_block, temp_dchufapp, temp_achuf, temp_acnum, temp_acapp_indx, gblkstr, cc, pathname_result, filename, dc_val, pblknum, slen, alpha)
% Recover blocks
%
% Inputs
%       posi         -concrete address of blocks, such as 3 4 5 10...
%       every_block  -store possible AC appended data
%       temp_dchufapp-DC huffman & appended code word
%       temp_achuf   -AC huffman code word
%       temp_acnum   -numaber of segments of AC huffman data
%       temp_acapp_indx -each huffman length of segment
%       bw           -number of processed
%       gblkstr      -address of block before processing
%       cc           -number of loops
%
% Hang Zhou, April, 2015
% ========================================================================
function res_block_dc = fun_comp_seqblk(every_block, temp_dchufapp, temp_achuf, temp_acnum, temp_acapp_indx, gblkstr, cc, pathname_result, filename, dc_val, pblknum, slen, alpha)

fname = 'proba_img';
go = 'a';
for i = 1:2^slen
    feaPath = fullfile(pathname_result, [fname go num2str(i) '.jpg']);
    rr = [];
    rr = [rr';temp_dchufapp']';
    for kk = 1:temp_acnum
        if(kk==1)
            rr = [rr';temp_achuf{cc+1,kk}';every_block{gblkstr+cc-floor(pblknum*alpha), i}(1:temp_acapp_indx(cc+1,kk))']';
        else
            rr = [rr';temp_achuf{cc+1,kk}';every_block{gblkstr+cc-floor(pblknum*alpha), i}(temp_acapp_indx(cc+1,kk-1)+1:temp_acapp_indx(cc+1,kk))']';
        end
    end
    [~, res_block_dc{i}] = fun_blk_rcvr(pathname_result, filename, feaPath, rr, dc_val);
end

end