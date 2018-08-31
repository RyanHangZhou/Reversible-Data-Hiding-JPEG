% ========================================================================
% USAGE: ext_msg = fun_extract(filename, sec_ffd_posi2, app_seg_len, slen)
% Message extraction
%
% Inputs
%       filename     -filename
%       sec_ffd_posi2-address of first AC appended data
%       app_seg_len  -actual length for segment
%       slen         -parameter for number embedded in each segment
%
% Outputs
%       ext_msg      -extracted data
%
% Hang Zhou, April, 2015
% ========================================================================
function ext_msg = fun_extract(filename, sec_ffd_posi2, app_seg_len, slen)

%% Read a JPEG image
pathname = 'images\embeded_images\';
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
[vsosbits, mk] = fun_dlt_soi(vsosbits');
vsosbits = vsosbits';
bef_len = length(vsosbits);

%% Acquire average length of each segment
mk1 = sec_ffd_posi2; mk2 = sec_ffd_posi2;
app_len_msg = bef_len - mk1 + 1;
app_seg_num = fix(app_len_msg/app_seg_len);

%% Select data to embed
for i = 1:app_seg_num*app_seg_len
    exst_msg(i) = vsosbits(mk1);
    mk1 = mk1 + 1;
end

qwidth = app_seg_len;
qheight = qwidth - slen;

%% Extract embedded data
for i = 1:app_seg_num
    ext_msg((i-1)*slen+1:i*slen) = exst_msg((i-1)*app_seg_len+qheight+1:i*app_seg_len);
    exst_msg((i-1)*app_seg_len+qheight+1:i*app_seg_len) = zeros(slen, 1);
end

%% Put back AC appended data to original bitstream
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
jencsosdata = fun_add_zero(jencsosdata);

%% Encrypt the quantization table
idxff = find(jhddata==255);
itmp = find(jhddata(idxff+1)==219);
locffdb = idxff(itmp);
vjqtbits = fun_gen_bits(jhddata(locffdb+5:locffdb+68));
vjqtbits = reshape(vjqtbits,8,length(vjqtbits)/8)';
jenhddata = jhddata;
jenhddata(locffdb+5:locffdb+68) = bi2de(fliplr(vjqtbits));

%% Combine JPEG head with compressed data
newim=[jenhddata;jencsosdata;255;217];

%% Store the image after data is extracted
fclose(fidorg);
pathname0 = 'images\extracted_images\';
full_name0 = fullfile(pathname0, filename);
fid = fopen(full_name0, 'w+');
fwrite(fid, uint8(newim), 'uint8');
fclose(fid);

end