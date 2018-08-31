% ========================================================================
% USAGE: [sec_ffd_posi, sec_ffd_posi2, avai_len, height_ini, width_ini] 
%        = fun_encrypt(key1, vsecbits, vsecbits2, pathname, filename, alpha)
% Encrytion of JPEG bitstream
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
function [sec_ffd_posi, sec_ffd_posi2, avai_len, height_ini, width_ini] = fun_encrypt(key1, vsecbits, vsecbits2, pathname, filename, alpha)

%% Read a JPEG image
full_name = fullfile(pathname, filename);
fidorg = fopen(full_name);
jpgdata = fread(fidorg);

%% Tackle JPEG header
locff = find(jpgdata==255);
% acquire header data
jhddata = fun_read_header(locff, jpgdata);
[height_ini, width_ini] = fun_read_sof_wh(locff, jpgdata);
height_ini = height_ini(1)*256 + height_ini(2);
width_ini = (width_ini(1))*256 + width_ini(2);
% APP0 resevations
% jpgdata = fun_read_left(locff, jpgdata); 

%% Acquire huffman table
% location of huffman table: FF C4
locc4 = find(jpgdata(locff+1, 1)==196);
if length(locc4)>1,
    % acquire huffman data
	jhuffdcdata = fun_read_dht(locff, jpgdata, fidorg, 1);
    % acquire huffman table of DC coefficients
	tdchufftbl = fun_huff_dctable(jhuffdcdata);
	jhuffacdata = fun_read_dht(locff, jpgdata, fidorg, 2);
	tachufftbl = fun_huff_actable(jhuffacdata);
else
    [jhuffdcdata, jhuffacdata] = fun_read_huff(locff, locc4, jpgdata, fidorg);
    % acquire huffman table of DC coefficients
	tdchufftbl = fun_huff_dctable(jhuffdcdata);
    % acquire huffman table of AC coefficients
	tachufftbl = fun_huff_actable(jhuffacdata);
end

%% Tackle JPEG data stream
% acquire compressed JPEG image data
jsosdata = fun_read_sos(locff, jpgdata, fidorg);
% remove additional 00 behind 255
jsosdataclr = fun_dlt_zero(jsosdata);
% transform the image data to bitstream
vsosbits = fun_gen_bits(jsosdataclr);
% length of original bistream
init_len = length(vsosbits);
% acquire number of blocks
[~, ~, pblkrow, pblkcol] = fun_jpg_size(jpgdata, locff);
pblknum = pblkrow*pblkcol;

%% Acquire position and appended data of each blocks
tmpi = 1;
tmppydcp = 1;
% tmppydcp: starting place of each DC bit
% tmppyacp: starting place of each AC bit
while tmpi<=pblknum,
    % vdcapplen: length of each DC appended bistream
    [tmppyacp, vdcapplen(tmpi, 1)] = fun_parse_dc(vsosbits, tdchufftbl, tmppydcp);
    % acquire each position of DC, namely, position of each block
    dc_posi(tmpi) = tmppydcp;
    % vaccodeidx{tmpi,1}: rows of all code words encoded by AC coefficients in tmpi-th block
    [tmppydcp, vaccodeidx{tmpi, 1}] = fun_parse_ac(vsosbits, tachufftbl, tmppyacp);
    tmpi = tmpi+1;
end
% store the 4097-th block address
dc_posi(tmpi) = tmppydcp;
aft_len = tmppydcp;
% number of additional bits at the end of bitstream
modn = init_len - aft_len + 1;

%% block shuffling
blk_chg = fun_blk_pseudo(pblknum, key1, alpha);

%% permute DC blocks in order
for i = 1:pblknum
    vdcapplen2(i,1) = vdcapplen(blk_chg(i), 1);
    vaccodeidx2{i,1} = vaccodeidx{blk_chg(i), 1};
end

% shuffle appha blocks
newstring = [];
for i = 1:floor(pblknum*alpha)
    newstring = [newstring'; vsosbits(dc_posi(blk_chg(i)):dc_posi(blk_chg(i)+1)-1)']';
end
% append EOI: (FF D9) at the end of shuffled data
newstring = [newstring';1;1;1;1;1;1;1;1;1;1;0;1;1;0;0;1]';

for i = floor(pblknum*alpha)+1:pblknum
    newstring = [newstring'; vsosbits(dc_posi(blk_chg(i)):dc_posi(blk_chg(i)+1)-1)']';
end

if(modn~=0)
    for i = 1:modn
        t(i) = 1;
    end
    
    newstring = [newstring';t']';
end

%% recombination of bitstream
vnewsosbits = newstring;
tmpsp = 1;
tmpdp = 1;
tmpi = 1;
blk_idx = 1;
% storage of alpha blocks bitstream
bef_stream = [];
% storage of huffman bitstream
dcac_huf = [];
% storage of DC appended bitstream 
dc_app = [];
% storage of AC appended bitstream 
ac_app = [];

while blk_idx<=pblknum,
    if(blk_idx == floor(pblknum*alpha)+1)
        tmpdp = tmpdp + 16;
    end
    % huffman bitstream of DC encoded data
    dc1 = vnewsosbits(tmpdp:tmpdp+tdchufftbl(vdcapplen2(tmpi,1)+1, 1)-1);
    tmpdp = tmpdp+tdchufftbl(vdcapplen2(tmpi, 1)+1, 1);
    % appended bitstream of DC encoded data
    dc2 = vnewsosbits(tmpdp:tmpdp+vdcapplen2(tmpi, 1)-1);
    if(blk_idx<=floor(pblknum*alpha))
        bef_stream = [bef_stream'; dc1';dc2']';
    else
        dcac_huf = [dcac_huf';dc1']';
        dc_app = [dc_app';dc2']';
    end
    tmpsp = tmpsp+vdcapplen2(tmpi, 1);
    tmpdp = tmpdp+vdcapplen2(tmpi, 1);
    tmpj = 1;
    while tmpj<=length(vaccodeidx2{tmpi, 1}),
        % length of appended bitstream encoded by AC coefficients
        tmp_acapp_len = tachufftbl(vaccodeidx2{tmpi, 1}(tmpj, 1), 3)-tachufftbl(vaccodeidx2{tmpi, 1}(tmpj, 1), 4);
        % huffman bitstream encoded by AC coefficients
        ac1 = vnewsosbits(tmpdp:tmpdp+tachufftbl(vaccodeidx2{tmpi, 1}(tmpj, 1), 4)-1);
        tmpdp = tmpdp+tachufftbl(vaccodeidx2{tmpi, 1}(tmpj, 1), 4);
%         if(blk_idx<=floor(pblknum*alpha))
%             ac2 = zeros(1, tmp_acapp_len);
%         else
            % appended bitstream encoded by AC coefficients
            ac2 = vnewsosbits(tmpdp:tmpdp+tmp_acapp_len-1);
%         end
        if(blk_idx<=floor(pblknum*alpha))
            bef_stream = [bef_stream'; ac1';ac2']';
        else
            dcac_huf = [dcac_huf';ac1']';
            ac_app = [ac_app';ac2']';
        end
        tmpsp = tmpsp+tmp_acapp_len;
        tmpdp = tmpdp+tmp_acapp_len;
        tmpj = tmpj+1;
    end
    tmpi = tmpi+1;
    blk_idx = blk_idx + 1;
end

%% Encryption
pseudostr_len = length(vsecbits);
if(pseudostr_len>length(dcac_huf))
    error('Pseudo stream exceeds the boundary of huffman length.')
end
dcac_huf_back = dcac_huf(pseudostr_len+1:length(dcac_huf));
dcac_huf = [xor(vsecbits',dcac_huf(1:pseudostr_len))';dcac_huf_back']';
pseudostr2_len = length(vsecbits2);
if(pseudostr2_len<=length(ac_app))
    ac_app_back2 = ac_app(pseudostr2_len+1:length(ac_app));
    ac_app = [xor(vsecbits2',ac_app(1:pseudostr2_len))';ac_app_back2']';
else
    ac_app = xor(vsecbits2(1:length(ac_app))', ac_app);
end

vnewsosbits2 = [dcac_huf';dc_app';ac_app']';
% address of first DC appended data
sec_ffd_posi = length(dcac_huf)+length(bef_stream)+1;
% address of first AC appended data
sec_ffd_posi2 = sec_ffd_posi + length(dc_app);
if(modn==0)
    t = [];
end
vnewsosbits3 = [bef_stream';1;1;1;1;1;1;1;1;1;1;0;1;1;0;0;1;vnewsosbits2';t'];
% length of available embeded data
avai_len = length(vnewsosbits) - 16 - sec_ffd_posi2 + 1;

%% Transform bits to bytes
% reshape bitstream into lines with each one consisted of 8 bits
tmpnewsosbits = reshape(vnewsosbits3, 8, length(vnewsosbits3)/8)';
% transform to decimal digits
jencsosdata = bi2de(fliplr(tmpnewsosbits));
% append 00 after each FF
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

%% Set image size
locff = find(newim==255);

beta = sqrt(1/alpha);
if(beta==floor(beta))
    height = height_ini/beta;
    width = width_ini/beta;
else
    tmp = 1/alpha;
    if(floor(tmp)==tmp)
        fix_beta = floor(beta);
        while((tmp/fix_beta)~=floor(tmp/fix_beta))
            fix_beta = fix_beta + 1;
        end
        height = height_ini/fix_beta;
        width = height_ini*width_ini*alpha/height;
    else
        height = height_ini/2;
        width = width_ini/2;
    end
    
end

newim = fun_set_sof_wh(locff, newim, height, width);

%% Generate encrypted JPEG image
fclose(fidorg);
pathname0 = 'images\encrypted_images\';
full_name0 = fullfile(pathname0, filename);
fid = fopen(full_name0, 'w+');
fwrite(fid, uint8(newim), 'uint8');
fclose(fid);

end