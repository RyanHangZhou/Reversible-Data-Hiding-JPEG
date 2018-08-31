% ========================================================================
% USAGE: [sec_ffd_posi, sec_ffd_posi2, avai_len, height_ini, width_ini] 
%        = fun_encrypt(key1, vsecbits, vsecbits2, pathname, filename, alpha)
% Direct decrypt image
%
% Inputs
%       key1         -scambling key for alpha bitstream
%       vsecbits     -encrption data for encrypting DC/AC huffman data
%       vsecbits2    -encrption data for encrypting AC appended data
%       pathname1    -pathname
%       filename     -filename
%       sec_ffd_posi2-address of first AC appended data
%       alpha        -parameter of reservation percentage
%       height       -image height
%       width        -image width
%
% Hang Zhou, April, 2015
% ========================================================================
function fun_decrypt(key1, vsecbits, vsecbits2, pathname1, filename, sec_ffd_posi2, alpha, height, width)

%% Read a JPEG image
pathname = 'images\embeded_images\';
full_name = fullfile(pathname, filename);
fidorg = fopen(full_name);
jpgdata = fread(fidorg);

%% Tackle JPEG header
locff = find(jpgdata==255);

%% Set size of decrypted image
% [height, width] = fun_read_sof_wh(locff, jpgdata);
% height = (hex2dec(num2str(height(1)))*256 + hex2dec(num2str(height(2))))*2;
% width = (hex2dec(num2str(width(1)))*256 + hex2dec(num2str(width(2))))*2;
jpgdata = fun_set_sof_wh(locff, jpgdata, height, width);

%% Acquire huffman table from image header
jhddata = fun_read_header(locff,jpgdata);
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

%% Tackle JPEG data bitstream
jsosdata = fun_read_sos(locff, jpgdata, fidorg);
jsosdataclr = fun_dlt_zero(jsosdata);
vsosbits = fun_gen_bits(jsosdataclr);
% vsosbits = fun_dlt_soi(vsosbits')';
bef_len = length(vsosbits) - 16;
[~, ~, pblkrow, pblkcol] = fun_jpg_size(jpgdata, locff);
pblknum = pblkrow*pblkcol;

%% Acquire appended data from alpha blocks
tmpi=1;
tmppydcp=1; 
while tmpi<=floor(pblknum*alpha),
    [tmppyacp, vdcapplen(tmpi, 1)] = fun_parse_dc(vsosbits, tdchufftbl, tmppydcp); 
    dc_posi(tmpi) = tmppydcp;
    [tmppydcp, vaccodeidx{tmpi,1}] = fun_parse_ac(vsosbits, tachufftbl, tmppyacp); 
    tmpi = tmpi+1;
end

%% Decode the encrypted data using key
% decrypt DC/AC huffman data
vsosbits = [vsosbits(1:tmppydcp-1) vsosbits(tmppydcp+16:length(vsosbits))];
pseudostr_len = length(vsecbits);
% DC/AC huffman encryption address
huf_posi_xor = tmppydcp;
dcac_middle = vsosbits(huf_posi_xor+pseudostr_len:sec_ffd_posi2-1);
dcac_huf_xor = xor(vsecbits', vsosbits(huf_posi_xor:huf_posi_xor+pseudostr_len-1));

% decrypt AC appended data
pseudostr2_len = length(vsecbits2);
% AC appended data encryption address
huf_posi2_xor = sec_ffd_posi2;
% dcac_back = vsosbits(huf_posi2_xor+pseudostr2_len:length(vsosbits));
% dcac_huf_xor2 = xor(vsecbits2',vsosbits(huf_posi2_xor:huf_posi2_xor+pseudostr2_len-1));
% vsosbits = [vsosbits(1:huf_posi_xor-1)';dcac_huf_xor';dcac_middle';dcac_huf_xor2';dcac_back']';

ac_app = vsosbits(huf_posi2_xor:length(vsosbits));
if(pseudostr2_len<=length(ac_app))
    dcac_back = vsosbits(huf_posi2_xor+pseudostr2_len:length(vsosbits));
    dcac_huf_xor2 = xor(vsecbits2',vsosbits(huf_posi2_xor:huf_posi2_xor+pseudostr2_len-1));
    vsosbits = [vsosbits(1:huf_posi_xor-1)';dcac_huf_xor';dcac_middle';dcac_huf_xor2';dcac_back']';
else
    dcac_huf_xor2 = xor(vsecbits2(1:length(ac_app))', ac_app);
    vsosbits = [vsosbits(1:huf_posi_xor-1)';dcac_huf_xor';dcac_middle';dcac_huf_xor2']';
end


%% Acquire appended data from (1-alpha) blocks
while tmpi<=pblknum,
    [tmppyacp,vdcapplen(tmpi, 1)] = fun_parse_dc2(vsosbits, tdchufftbl, tmppydcp);
    [tmppydcp,vaccodeidx{tmpi, 1}] = fun_parse_ac2(vsosbits, tachufftbl, tmppyacp);
    tmpi = tmpi+1;
end

%% Combine corresponding appended bits with huffman bits
three_quaters_stream = [];
tmpdp = huf_posi_xor;
dc_indx = huf_posi_xor;
tmp_app = tmppydcp;
tmp_acapp = sec_ffd_posi2;
for i = floor(pblknum*alpha)+1:pblknum
    dc_posi(i) = dc_indx;
    part_block = [];
    dc11 = vsosbits(tmpdp:tmpdp+tdchufftbl(vdcapplen(i,1)+1, 1)-1);
    app11 = vsosbits(tmp_app:tmp_app+vdcapplen(i, 1)-1);
    tmpdp = tmpdp+tdchufftbl(vdcapplen(i, 1)+1, 1);
    tmp_app = tmp_app+vdcapplen(i, 1);
    part_block = [part_block'; dc11'; app11']';
    dc_indx = dc_indx + tdchufftbl(vdcapplen(i,1)+1, 1) + vdcapplen(i, 1);

    for k = 1:length(vaccodeidx{i})
        ac22 = [];
        app22 = [];
        tmp_acapp_len = tachufftbl(vaccodeidx{i, 1}(k, 1), 3)-tachufftbl(vaccodeidx{i, 1}(k, 1), 4);
        ac22 = vsosbits(tmpdp:tmpdp+tachufftbl(vaccodeidx{i,1}(k, 1), 4)-1);
        tmpdp = tmpdp+tachufftbl(vaccodeidx{i, 1}(k, 1), 4);
        app22 = vsosbits(tmp_acapp:tmp_acapp+tmp_acapp_len-1);
        part_block = [part_block'; ac22'; app22']';
        dc_indx = dc_indx + tmp_acapp_len + tachufftbl(vaccodeidx{i, 1}(k, 1), 4);
        tmp_acapp = tmp_acapp+tmp_acapp_len;
    end
    three_quaters_stream = [three_quaters_stream';part_block']';
end
dc_posi(pblknum+1) = dc_indx;
vsosbits_recomb = [vsosbits(1:huf_posi_xor-1)';three_quaters_stream']';

%% Fill of code word
aft_len = length(vsosbits_recomb);
modn = bef_len - aft_len;
t = [];
for i = 1:modn
    t(i) = 1;
end
vsosbits_recomb = [vsosbits_recomb';t']';

%% Reshuffle of shuffled bitstream
blk_chg = fun_blk_pseudo(pblknum, key1, alpha);

newstring2 = [];
for i = 1:pblknum
    newstring2 = [newstring2'; vsosbits_recomb(dc_posi(find(blk_chg==i)):dc_posi(find(blk_chg==i)+1)-1)']';
end
newstring2 = [newstring2';t'];

%% Transform bits to bytes
tmpnewsosbits = reshape(newstring2, 8, length(newstring2)/8)';
jencsosdata = bi2de(fliplr(tmpnewsosbits));
jencsosdata = fun_add_zero(jencsosdata);

%% Encrypt the quantization table
idxff = find(jhddata==255);
itmp = find(jhddata(idxff+1)==219);
locffdb = idxff(itmp);
vjqtbits = fun_gen_bits(jhddata(locffdb+5:locffdb+68));
vjqtbits = reshape(vjqtbits, 8, length(vjqtbits)/8)';
jenhddata = jhddata;
jenhddata(locffdb+5:locffdb+68) = bi2de(fliplr(vjqtbits));

%% Combine JPEG header with compressed data
newim=[jenhddata; jencsosdata; 255; 217];

%% Generate decrypted JPEG image
fclose(fidorg);
pathname0 = 'images\decrypted_images\';
full_name0 = fullfile(pathname0, filename);
fid = fopen(full_name0, 'w+');
fwrite(fid, uint8(newim), 'uint8');
fclose(fid);

%% Compute PSNR
full_name1 = fullfile(pathname1, filename);
% image before encryption
jpeg1 = full_name1;
% image after decryption
jpeg2 = full_name0;
PSNR = jpeg_fxpsnr(jpeg1, jpeg2);

end