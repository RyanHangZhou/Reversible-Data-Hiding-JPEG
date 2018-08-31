% ========================================================================
% USAGE: [coef_result, coef_arrays_result] = 
%        fun_blk_rcvr(pathname, filename_initial, fullname_result, in_str, dc_val)
% Acquire compressed data without 255
%
% Inputs
%       y            -compressed JPEG image data
%
% Outputs
%       y            -compressed JPEG image data without 255
%
% Hang Zhou, April, 2015
% ========================================================================
function [coef_result, coef_arrays_result] = fun_blk_rcvr(pathname, filename_initial, fullname_result, in_str, dc_val)

%% Read a JPEG image
full_name_initial = fullfile(pathname, filename_initial);

%% Parse the image
fidorg = fopen(full_name_initial);
jpgdata = fread(fidorg);

%% Tackle JPEG header
locff = find(jpgdata==255);

%% Set image width and height
height = 8;
width = 8;
jpgdata = fun_set_sof_wh(locff, jpgdata, height, width);
jhddata = fun_read_header(locff, jpgdata);

%% Tackle JPEG data stream
vnewsosbits = in_str;
modn = mod(length(vnewsosbits), 8);
t = [];
if(modn>0)
    for i = 1:8-modn
        t = [t';1]';
    end
end
vnewsosbits = [vnewsosbits'; t']';

%% Transform bits to bytes
tmpnewsosbits=reshape(vnewsosbits, 8, length(vnewsosbits)/8)';
x = fliplr(tmpnewsosbits);
jencsosdata = bi2de(fliplr(tmpnewsosbits));
jencsosdata = fun_add_zero(jencsosdata);

%% Encrypt the quantization table
idxff=find(jhddata==255);
itmp=find(jhddata(idxff+1)==219);
locffdb=idxff(itmp);
vjqtbits=fun_gen_bits(jhddata(locffdb+5:locffdb+68));
vjqtenbits = vjqtbits;
vjqtenbits=reshape(vjqtenbits,8,length(vjqtenbits)/8)';
jenhddata=jhddata;
jenhddata(locffdb+5:locffdb+68)=bi2de(fliplr(vjqtenbits));

%% Transform bits to bytes
newim=[jenhddata;jencsosdata;255;217];

%% generate recovered image from bitstream
fclose(fidorg);
fid = fopen(fullname_result, 'w+');
while fid==-1
    fid = fopen(fullname_result, 'w+');
end
fwrite(fid, uint8(newim), 'uint8');
while(fid==-1)
    fwrite(fid, uint8(newim), 'uint8');
end
fclose(fid);

jobj_result = jpeg_read(fullname_result);
% block DCT coefficients of recovered bitstream
coef_arrays_result = jobj_result.coef_arrays{1};
coef_arrays_result(1,1) = dc_val;
jobj_result.coef_arrays{1} = coef_arrays_result;
jpeg_write(jobj_result,fullname_result);
% coef_arrays_result
coef_dequant = dequantize(coef_arrays_result,jobj_result.quant_tables{1});
coef_ibdct = ibdct(coef_dequant,8);
coef_result = uint8(coef_ibdct+128);

end