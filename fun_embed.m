% ========================================================================
% USAGE: fun_embed(filename, in_bits_all, sec_ffd_posi2, key3, app_seg_len, slen)
% Data embedding in JPEG bitstream
%
% Inputs
%       filename     -filename
%       in_bits_all  -embedded data
%       sec_ffd_posi2-address of first AC appended data
%       key3         -key for Q matrix in Generator matrix G
%       app_seg_len  -actual length for segment
%       slen         -parameter for number embedded in each segment
%
% Hang Zhou, April, 2015
% ========================================================================
function fun_embed(filename, in_bits_all, sec_ffd_posi2, key3, app_seg_len, slen)

%% Read a JPEG image
pathname = 'images\encrypted_images\';
full_name = fullfile(pathname, filename);
fidorg = fopen(full_name);
jpgdata = fread(fidorg);

%% Tackle JPEG header
locff = find(jpgdata==255);
jhddata = fun_read_header(locff, jpgdata);

%% Tackle JPEG data stream
jsosdata = fun_read_sos(locff, jpgdata, fidorg);
jsosdataclr = fun_dlt_zero(jsosdata);
vsosbits = fun_gen_bits(jsosdataclr);
% remove EOI: FF D9 and return the subscript
[vsosbits, mk] = fun_dlt_soi(vsosbits');
vsosbits = vsosbits';
bef_len = length(vsosbits);

%% Acquire average length of each segment
mk1 = sec_ffd_posi2;
mk2 = sec_ffd_posi2;
app_len_msg = bef_len - mk1 + 1;
app_seg_num = fix(app_len_msg/app_seg_len);

%% Distribute embedded data
for i = 1:app_seg_num*app_seg_len
    exst_msg(i) = vsosbits(mk1);
    mk1 = mk1 + 1;
end

%% Compress embedded data
% redundacy regions are embedded with 0s
in_bits_all = [in_bits_all;zeros((slen*app_seg_num-length(in_bits_all)),1)];
qwidth = app_seg_len;
qheight = qwidth - slen;
pseudostr_len_n = qheight*slen;
vsecbits_k = fun_stream_cipher(pseudostr_len_n,key3)';
vsecbits_k = reshape(vsecbits_k, slen, qheight)';
gvse = [eye(qheight), vsecbits_k];

for i = 1:app_seg_num
    msg = exst_msg((i-1)*app_seg_len+1:i*app_seg_len)';
    % shortened data
    msg2(1:qheight) = mod(gvse*msg, 2);
    % embedded data
    msg2(qheight+1:qwidth) = in_bits_all((i-1)*slen+1:i*slen)';
    exst_msg((i-1)*app_seg_len+1:i*app_seg_len) = msg2';
end

%% Embed data
for i = 1:app_seg_num*app_seg_len
    vsosbits(mk2) = exst_msg(i);
    mk2 = mk2 + 1;
end

%% Insert EOI at the end of alpha blocks
data_ffd9 = [1;1;1;1;1;1;1;1; 1;1;0;1;1;0;0;1];
vsosbits = fun_add_data(vsosbits', data_ffd9, mk);

%% Transform bits to bytes
tmpnewsosbits = reshape(vsosbits, 8, length(vsosbits)/8)';
jencsosdata = bi2de(fliplr(tmpnewsosbits));
% Add 00 at each FF in the bistream
jencsosdata = fun_add_zero(jencsosdata);

%% Encrypt the quantization table
idxff = find(jhddata==255);
itmp = find(jhddata(idxff+1)==219);
locffdb = idxff(itmp);
vjqtbits = fun_gen_bits(jhddata(locffdb+5:locffdb+68));
vjqtbits = reshape(vjqtbits, 8, length(vjqtbits)/8)';
jenhddata = jhddata;
jenhddata(locffdb+5:locffdb+68) = bi2de(fliplr(vjqtbits));

%% Combine JPEG head with compressed data
newim = [jenhddata; jencsosdata; 255; 217];

%% Store the generated image
fclose(fidorg);
pathname0 = 'images\embeded_images\';
full_name0 = fullfile(pathname0, filename);
fid=fopen(full_name0, 'w+');
fwrite(fid,uint8(newim),'uint8');
fclose(fid);

end