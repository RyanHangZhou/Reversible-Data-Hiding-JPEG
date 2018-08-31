% ========================================================================
% USAGE: ex_prob_bits = fun_str_add(in_string, key, slen)
% Recover possible bitstream from Generator matrix
%
% Hang Zhou, April, 2015
% ========================================================================
function ex_prob_bits = fun_str_add(in_string, key, slen)

app_seg_len = length(in_string);
qwidth = app_seg_len;
qheight = qwidth - slen;
pseudostr_len_n = qheight*slen;
vsecbits_k = fun_stream_cipher(pseudostr_len_n, key)';
vsecbits_k = reshape(vsecbits_k, slen, qheight);

ex_gvse = [vsecbits_k, eye(slen)];
vsosbits2 = [in_string(1:length(in_string)-slen)'; zeros(slen,1)];

for i = 1:2^slen
    ex_prob_bits{i,1} = mod((vsosbits2' + (dec2bin(i-1, slen)*ex_gvse)), 2);
end

end