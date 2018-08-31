% ========================================================================
% USAGE: psnr = jpeg_fxpsnr(x, y)
% Compute PSNR of two JPEG images
%
% Inputs
%       x            -input image 1
%       y            -input image 2
%
% Outputs
%       psnr         -PSNR
%
% Hang Zhou, April, 2015
% ========================================================================
function psnr = jpeg_fxpsnr(x, y)

jobj1 = jpeg_read(x);
jobj2 = jpeg_read(y);
img_qcoef1 = jobj1.coef_arrays{1};
img_qcoef2 = jobj2.coef_arrays{1};
img_quant_tbl1 = jobj1.quant_tables{1};
img_quant_tbl2 = jobj2.quant_tables{1};
img1 = img_initial(img_qcoef1, img_quant_tbl1);
img2 = img_initial(img_qcoef2, img_quant_tbl2);
img1 = double(img1);
img2 = double(img2);
MSE = mean(mean((img1-img2).^2));
psnr = 10*log10(255^2/MSE);

end