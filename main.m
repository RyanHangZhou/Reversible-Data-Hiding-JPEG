% =========================================================================
% An example code for the algorithm proposed in
%
%   Zhenxing Qian, Hang Zhou, Xinpeng Zhang, Weiming Zhang.
%   "Separable Reversible Data Hiding in Encrypted JPEG Bitstreams", TDSC 2016.
%
%
% Written by Hang Zhou @ EEIS USTC
% April, 2015.
% =========================================================================

clc;clear;close all;
addpath(genpath(pwd));

%% Acquire image path
[filename, pathname] = uigetfile({'*.jpg', '(*.jpg)';}, 'open picture');
full_file = fullfile(pathname, filename);
disp(['Image selected: ', full_file])

%% Parameter setup
% scambling key for alpha bitstream
key1 = 12345; 

% encrpytion length for DC/AC huffman data
pseudostr_len = 20000;

% encrption data for encrypting DC/AC huffman data
vsecbits = fun_stream_cipher(pseudostr_len, 12345);
% Not encrption of DC/AC huffman data
% vsecbits = zeros(pseudostr_len, 1);

% encrpytion length for AC appended data
pseudostr2_len = 60000;

% encrption data for encrypting AC appended data
vsecbits2 = fun_stream_cipher(pseudostr2_len,49512);
% Not encrption of  AC appended data
% vsecbits2 = zeros(pseudostr2_len,1);

% length of embedded data
emb_msg_len = 3072;

% embedded data
in_bits_all = fun_stream_cipher(emb_msg_len, 12345);

% key for Q matrix in Generator matrix G
key3 = 12921;

% parameter of reservation percentage
alpha = 1/4;

% parameter for multiple of length
beta = 12;

% parameter for number embedded in each segment
slen = 1;

%% Encrpytion
[sec_ffd_posi, sec_ffd_posi2, avai_len, height, width] = fun_encrypt(key1, vsecbits, vsecbits2, pathname, filename, alpha);

%% Data embedding
pblknum = height*width/64;
% average length for segment
avrg_len = avai_len/floor(pblknum*(1-alpha));
% actual length for segment
app_seg_len = floor(avrg_len*beta);
disp(['actual length for segment: ', num2str(app_seg_len)])
% actual number of segments
num_seg = floor(avai_len/app_seg_len);
disp(['actual number of segments: ', num2str(num_seg)])
% actual embedding capacity
capacity = slen*num_seg;
disp(['actual embedding capacity: ', num2str(capacity)])
fun_embed(filename, in_bits_all, sec_ffd_posi2, key3, app_seg_len, slen);

%% Message extraction
ext_msg = fun_extract(filename, sec_ffd_posi2, app_seg_len, slen);

%% Image recovery & message extraction
fun_decrypt_msg(key1, vsecbits, vsecbits2, pathname, filename, sec_ffd_posi2, key3, app_seg_len, slen, alpha, height, width);
% fun_decrypt(key1, vsecbits, vsecbits2, pathname, filename, sec_ffd_posi2, alpha, height, width);

%% Verify the accuracy of extracted data
ext_msg = ext_msg';
in_bits_all = in_bits_all(1:length(ext_msg));
%ext_msg = ext_msg(1:length(in_bits_all));
ecc_err_dist = ext_msg - in_bits_all;
ecc_err_len = length(find(ecc_err_dist(:)~=0));
disp(['error length: ', num2str(ecc_err_len)])
