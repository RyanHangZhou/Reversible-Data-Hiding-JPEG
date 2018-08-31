% ========================================================================
% USAGE: err_perctg = jpg_diff_blk(x, y, alpha)
% Compute difference of blocks
%
% Hang Zhou, April, 2015
% ========================================================================
function err_perctg = jpg_diff_blk(x, y, alpha)

jobj1 = jpeg_read(x);
jobj2 = jpeg_read(y);
img_qcoef1 = jobj1.coef_arrays{1};
img_qcoef2 = jobj2.coef_arrays{1};

[imgh, imgw] = size(img_qcoef1);
blkh = imgh/8; blkw = imgw/8;

totl = floor(blkh*blkw*(1-alpha));
indx = 0;
for row = 1:blkh
    for col = 1:blkw
        s1 = img_qcoef1(((row-1)*8+1):((row-1)*8+8),((col-1)*8+1):((col-1)*8+8));
        s2 = img_qcoef2(((row-1)*8+1):((row-1)*8+8),((col-1)*8+1):((col-1)*8+8));
        if(sum(abs(s1(:)-s2(:)))~=0)
            indx = indx + 1;
        end
    end
end

err_perctg = indx*1.0/totl;

end