% ========================================================================
% USAGE: fun_decrypt_msg(key1, vsecbits, vsecbits2, pathname1, filename, 
%             sec_ffd_posi2, key3, app_seg_len, slen, alpha, height, width)
% Image recovery and data extraction
%
% Inputs
%       key1         -scambling key for alpha bitstream
%       vsecbits     -encrption data for encrypting DC/AC huffman data
%       vsecbits2    -encrption data for encrypting AC appended data
%       pathname     -pathname
%       filename     -filename
%       alpha        -parameter of reservation percentage
%
% Outputs
%       sec_ffd_posi -address of first DC appended data
%       sec_ffd_posi2-address of first AC appended data
%       avai_len     -length of available embeded data
%       height_ini   -original image height
%       width_ini    -original image width
%
% Hang Zhou, April, 2015
% ========================================================================
function fun_decrypt_msg(key1, vsecbits, vsecbits2, pathname1, filename, sec_ffd_posi2, key3, app_seg_len, slen, alpha, height, width)

%% Recover reference image
fun_decrypt(key1, vsecbits, vsecbits2, pathname1, filename, sec_ffd_posi2, alpha, height, width);

%% Acquire DC coefficients from directly recovered image
pow = 1;
pathname_result = 'images\decrypted_images\';
full_name = fullfile(pathname_result, filename);
jobj_initial = jpeg_read(full_name);
img_qcoef1 = jobj_initial.coef_arrays{1};
img_quanttbl = jobj_initial.quant_tables{1};
for i = 1:2^slen
    img_qcoef2{i} = img_qcoef1;
end

[imgh, imgw] = size(img_qcoef1);
blkh = imgh/8; 
blkw = imgw/8;
indx = 1;
for row = 1:blkh
    for col = 1:blkw
        dc_str(indx) = img_qcoef1((row-1)*8+1, (col-1)*8+1);
        indx = indx + 1;
    end
end

%% Parse image from extracted_image or embedded image
% 'extracted_image' is an alternative
pathname = 'images\embeded_images\';
full_name2 = fullfile(pathname, filename);
fidorg = fopen(full_name2);
jpgdata = fread(fidorg);

%% Tackle JPEG header
locff=find(jpgdata==255);

%% Set image size
jpgdata = fun_set_sof_wh(locff, jpgdata, height, width);

%% Acquire huffman table
locc4 = find(jpgdata(locff+1, 1)==196);
if length(locc4)>1,
	jhuffdcdata = fun_read_dht(locff, jpgdata, fidorg, 1);
	tdchufftbl = fun_huff_dctable(jhuffdcdata);
	jhuffacdata = fun_read_dht(locff, jpgdata, fidorg, 2);
	tachufftbl = fun_huff_actable(jhuffacdata);
else
    [jhuffdcdata,jhuffacdata] = fun_read_huff(locff, locc4, jpgdata, fidorg);
	tdchufftbl = fun_huff_dctable(jhuffdcdata);
	tachufftbl = fun_huff_actable(jhuffacdata);
end

%% Tackle JPEG data stream
jsosdata = fun_read_sos(locff, jpgdata, fidorg);
jsosdataclr = fun_dlt_zero(jsosdata);
vsosbits = fun_gen_bits(jsosdataclr);
% vsosbits = fun_dlt_soi(vsosbits')';
[~, ~, pblkrow, pblkcol] = fun_jpg_size(jpgdata, locff);
pblknum = pblkrow*pblkcol;

%% Shuffle blocks & DC coefficients
blk_chg = fun_blk_pseudo(pblknum, key1, alpha);
for i = 1:pblknum
    dc_str2(i) = dc_str(blk_chg(i));
end

%% Acquire appended data of alpha blocks
tmpi = 1;
tmppydcp = 1; 
while tmpi<=floor(pblknum*alpha),
    [tmppyacp, vdcapplen(tmpi, 1)] = fun_parse_dc(vsosbits, tdchufftbl, tmppydcp); 
    [tmppydcp, vaccodeidx{tmpi, 1}] = fun_parse_ac(vsosbits, tachufftbl, tmppyacp); 
    tmpi = tmpi+1;
end

%% Dicrypt with keys
% decrpyt DC/AC huffman data
vsosbits = [vsosbits(1:tmppydcp-1) vsosbits(tmppydcp+16:length(vsosbits))];
pseudostr_len = length(vsecbits);
% address of DC/AC huffman data encrytion
huf_posi_xor = tmppydcp;
dcac_middle = vsosbits(huf_posi_xor+pseudostr_len:sec_ffd_posi2-1);
dcac_huf_xor = xor(vsecbits',vsosbits(huf_posi_xor:huf_posi_xor+pseudostr_len-1));

% decrpyt AC appended data
vsecbits2 = [vsecbits2;zeros(1,500000)']; % ensure enough length of bitstream
% address of AC appended data encrytion
huf_posi2_xor = sec_ffd_posi2;
dcac_huf_xor2 = vsosbits(huf_posi2_xor:length(vsosbits));% do not encrypt (encrypt it during recovery)
vsosbits = [vsosbits(1:huf_posi_xor-1)';dcac_huf_xor';dcac_middle';dcac_huf_xor2']';

%% Acquire appended data from (1-alpha) blocks
while tmpi<=pblknum,
    [tmppyacp, vdcapplen(tmpi, 1)] = fun_parse_dc2(vsosbits, tdchufftbl, tmppydcp);
    [tmppydcp, vaccodeidx{tmpi, 1}] = fun_parse_ac2(vsosbits, tachufftbl, tmppyacp);
    tmpi = tmpi+1;
end

%% Combine corresponding appended bits with huffman data
img_qcoef_dif = 1;
iter_time = 0;
while(img_qcoef_dif ~= 0)
    img_qcoef22 = fun_dec_msg_iter(pblknum, blk_chg, huf_posi_xor, tmppydcp, sec_ffd_posi2, key3, vsosbits, vsecbits2, ...
        tdchufftbl, tachufftbl, vdcapplen, vaccodeidx, app_seg_len, slen, pathname_result, filename, dc_str2, ...
        blkw, blkh, img_quanttbl, pow, img_qcoef2, i, alpha);
    img_qcoef_dif = sum(sum(abs(img_qcoef22{1}-img_qcoef2{1})));
    disp([num2str(iter_time), '-th iteration, L2 distance of adjacent images: ', num2str(img_qcoef_dif)])
    img_qcoef2 = img_qcoef22;
    iter_time = iter_time + 1;
    if(iter_time>=4)
        break;
    end
end

%% recover the image
jobj_result = jobj_initial;
jobj_result.coef_arrays{1} = img_qcoef2{1};
re_img = 'ReImg.jpg';
full_name_reimg = fullfile(pathname_result, re_img);
jpeg_write(jobj_result, full_name_reimg);

%% Compute PSNR
% original image
jpeg11 = fullfile(pathname1, filename);
% recovered image
jpeg22 = full_name_reimg;
PSNRf = jpeg_fxpsnr(jpeg11, jpeg22);
disp(['PSNR: ',sprintf('%.4f', PSNRf)])
err_perctg = jpg_diff_blk(jpeg11, jpeg22, alpha);
disp(['error rate: ',sprintf('%.4f', err_perctg)])

end