% ========================================================================
% USAGE: blk_val = fun_blk_tol(img_qcoef2, blk_useblk, tmp_blk, img_quanttbl, blkw, blkh, slen, pow, iter)
% Compute block effects of each possible blocks
%
% Inputs
%       img_qcoef2   -input '2^slen' number of dct images
%       blk_useblk   -certained blocks including alpha blocks
%       tmp_blk      -address of block currently
%       img_quanttbl -quantization table
%       blkw         -number of blocks on the horizontal direction
%       blkh         -number of blocks on the vertical direction
%       pow          -power of block effect
%       iter         -iteration times
%
% Hang Zhou, April, 2015
% ========================================================================
function blk_val = fun_blk_tol(img_qcoef2, blk_useblk, tmp_blk, img_quanttbl, blkw, blkh, slen, pow, iter)

for i = 2^slen
    blk_val(i) = 0;
end
len = length(tmp_blk);
for i = 1:len
    rowb = ceil(tmp_blk(i)/blkw);
    colb = mod(tmp_blk(i), blkw);
    if(colb==0)
        colb = blkw;
    end
    for j = 1:2^slen
        coef_result{j} = fun_blkrcvr(img_qcoef2{j}(((rowb-1)*8+1):((rowb-1)*8+8),((colb-1)*8+1):((colb-1)*8+8)), img_quanttbl);
    end
    if(isempty(find(blk_useblk==((rowb-2)*blkw+colb)))==0 || iter~=1)%up
        if(rowb>1)
            temp = fun_blkrcvr(img_qcoef2{1}(((rowb-2)*8+1):((rowb-2)*8+8),((colb-1)*8+1):((colb-1)*8+8)), img_quanttbl);
            for j=1:8
                for k = 1:2^slen
                    blk_val(k) = blk_val(k) + (abs(double(coef_result{k}(1, j)) - double(temp(8, j))))^pow;
                end
            end
        end
    end
    if(isempty(find(blk_useblk==(rowb*blkw+colb)))==0 || iter~=1)%down
        if(rowb<blkh)
            temp = fun_blkrcvr(img_qcoef2{1}((rowb*8+1):(rowb*8+8),((colb-1)*8+1):((colb-1)*8+8)), img_quanttbl);
            for j=1:8
                for k = 1:2^slen
                    blk_val(k) = blk_val(k) + (abs(double(coef_result{k}(8, j)) - double(temp(1, j))))^pow;
                end
            end
        end
    end
    if(isempty(find(blk_useblk==((rowb-1)*blkw+colb+1)))==0 || iter~=1)%right
        if(colb<blkw)
            temp = fun_blkrcvr(img_qcoef2{1}(((rowb-1)*8+1):((rowb-1)*8+8),(colb*8+1):(colb*8+8)), img_quanttbl);
            for j=1:8
                for k = 1:2^slen
                    blk_val(k) = blk_val(k) + (abs(double(coef_result{k}(j, 8)) - double(temp(j, 1))))^pow;
                end
            end
        end
    end
    if(isempty(find(blk_useblk==((rowb-1)*blkw+colb-1)))==0 || iter~=1)%left
        if(colb>1)
            temp = fun_blkrcvr(img_qcoef2{1}(((rowb-1)*8+1):((rowb-1)*8+8),((colb-2)*8+1):((colb-2)*8+8)), img_quanttbl);
            for j=1:8
                for k = 1:2^slen
                    blk_val(k) = blk_val(k) + (abs(double(coef_result{k}(j, 1)) - double(temp(j, 8))))^pow;
                end
            end
        end
    end
    
end



end

function coef_result = fun_blkrcvr(coef_arrays_result, img_quanttbl)

coef_dequant = dequantize(coef_arrays_result,img_quanttbl);
coef_ibdct = ibdct(coef_dequant,8);
coef_result = uint8(coef_ibdct+128);
end