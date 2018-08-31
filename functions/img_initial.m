% ========================================================================
% USAGE: img = img_initial(in_img, qtbl)
% Decode JPEG image to spatial image
%
% Hang Zhou, April, 2015
% ========================================================================
function img = img_initial(in_img, qtbl)

img_coef = dequantize(in_img, qtbl);
img_idct = ibdct(img_coef, 8);
img = uint8(img_idct + 128);

end