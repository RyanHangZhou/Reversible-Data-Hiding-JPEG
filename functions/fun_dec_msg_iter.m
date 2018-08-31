% ========================================================================
% USAGE: img_qcoef2 = fun_dec_msg_iter(pblknum, blk_chg, huf_posi_xor, tmppydcp, sec_ffd_posi2, key3, ...
%    vsosbits, vsecbits2, tdchufftbl, tachufftbl, vdcapplen, vaccodeidx, app_seg_len, slen, ...
%    pathname_result, filename, dc_str2, blkw, blkh, img_quanttbl, pow, img_qcoef2, iter, alpha)
% Iteratively decrypt image blocks
%
% Hang Zhou, April, 2015
% ========================================================================
function img_qcoef2 = fun_dec_msg_iter(pblknum, blk_chg, huf_posi_xor, tmppydcp, sec_ffd_posi2, key3, ...
    vsosbits, vsecbits2, tdchufftbl, tachufftbl, vdcapplen, vaccodeidx, app_seg_len, slen, ...
    pathname_result, filename, dc_str2, blkw, blkh, img_quanttbl, pow, img_qcoef2, iter, alpha)

tmpdp = huf_posi_xor;
dc_indx = huf_posi_xor;
tmp_app = tmppydcp;
tmp_acapp = sec_ffd_posi2;
% parameter for telling number of blocks that are fetched
count_i = 0;
% length of AC appended data of all blocks
acpaa_tal = 0;
temp_str = [];
% subscript of key
sec_t = 1;
lineblk = 1;
% parameter for recording length of bitstream lineblk = 1
temp_strp = [];
temp_strp_max = 300;
for i = 1:temp_strp_max
    % initialization, cannot be 0
    temp_strp(i) = 1;
end
for i = 1:pblknum*floor(1-alpha)
    every_block_indx(i) = 0;
end
% for recording subscripts of each blocks
gblkstr = floor(pblknum*alpha)+1;
% recording correct bitstream of leftover
last_str = [];
% record last known length
acpaa_mod2 = 0;
blk_useblk = blk_chg(1:floor(pblknum*alpha));
for i = floor(pblknum*alpha)+1:pblknum
    count_i = count_i + 1;
    part_block = [];
    dc11 = vsosbits(tmpdp:tmpdp+tdchufftbl(vdcapplen(i,1)+1, 1)-1);
    app11 = vsosbits(tmp_app:tmp_app+vdcapplen(i, 1)-1);
    tmpdp = tmpdp+tdchufftbl(vdcapplen(i,1)+1,1);
    tmp_app = tmp_app+vdcapplen(i, 1);
    part_block = [part_block'; dc11'; app11']';
    dc_indx = dc_indx + tdchufftbl(vdcapplen(i,1)+1, 1) + vdcapplen(i, 1);
    % total length of each AC appended data of each blocks
    tmp_acapp_tal = 0;
    for k = 1:length(vaccodeidx{i})
        ac22 = [];
        app22 = [];
        tmp_acapp_len=tachufftbl(vaccodeidx{i,1}(k,1),3)-tachufftbl(vaccodeidx{i,1}(k,1),4);
        ac22 = vsosbits(tmpdp:tmpdp+tachufftbl(vaccodeidx{i,1}(k,1),4)-1);
        tmpdp=tmpdp+tachufftbl(vaccodeidx{i,1}(k,1),4);
        app22 = vsosbits(tmp_acapp:tmp_acapp+tmp_acapp_len-1);
        part_block = [part_block';ac22';app22']';
        dc_indx = dc_indx + tmp_acapp_len + tachufftbl(vaccodeidx{i,1}(k,1),4);
        tmp_acapp = tmp_acapp+tmp_acapp_len;
        tmp_acapp_tal = tmp_acapp_tal + tmp_acapp_len;
        temp_str = [temp_str'; app22']';
        temp_achuf{count_i, k} = ac22;
        temp_acapp_indx(count_i,k) = tmp_acapp_tal;
    end
    temp_strp(count_i) = tmp_acapp_tal;
    temp_acnum(count_i) = length(vaccodeidx{i});
    temp_dchufapp{count_i,1} = [dc11';app11']';
    acpaa_tal = acpaa_tal + tmp_acapp_tal;
    % count number of fetched block of each loop
    if(count_i >= lineblk)
        t1 = 0;
        for jk = 1:lineblk
            t1 = t1 + temp_strp(jk);
        end
        t1 = t1 - acpaa_mod2;
        t_fix = floor(t1/app_seg_len);
        t_mod = mod(t1, app_seg_len);
        
        if(t_mod~=0 || temp_strp(1)==0)
            if(count_i==lineblk)
                if(i~=pblknum)
                    continue;
                end
            end
            t2 = 0;
            for jf = 1:count_i
                t2 = t2 + temp_strp(jf);
            end
            t2 = t2 - acpaa_mod2;
            if(acpaa_mod2==0 && t2==0)
                continue;
            end
            t2_fix = floor(t2/app_seg_len);
            if((t2_fix-1-t_fix)<0)
                if(i~=pblknum)
                    continue;
                end
            end           
        end
        
        temp_strp2(1) = 0;
        temp_strp2(2) = temp_strp(1);
        for b = 2:count_i
            temp_strp2(b+1) = temp_strp(b)+temp_strp2(b);
        end
        tmp_nxt_posi = temp_strp2(count_i) + 1;
        t3 = 0;
        for jh = 1:count_i
            t3 = t3 + temp_strp(jh);
        end
        t3 = t3 - acpaa_mod2;
        acpaa_div = floor(t3/app_seg_len);
        pblk_indx = 0;
        if(i==pblknum && acpaa_div==0)
            acpaa_div = 1;
            pblk_indx = 1;
        end
        % recover 'acpaa_div' number of segments
        if(pblk_indx==0)
            in_string = temp_str(1:app_seg_len);
            sec_s = vsecbits2(sec_t:sec_t+app_seg_len-1);
            ex_prob_bits = fun_str_add(in_string, key3, slen);
            sec_t = sec_t + app_seg_len;
            if(i==pblknum)
                last_bits = temp_str(app_seg_len+1:length(temp_str));
                sec_slast = vsecbits2(sec_t:sec_t+length(last_bits)-1);
                xor_lastbits = xor(last_bits, sec_slast');
            end
            for ns = 1:2^slen
                ex_prob_all{ns, 1} = xor(ex_prob_bits{ns, 1}, sec_s');
                if(i==pblknum)
                    ex_prob_all{ns,1} = [ex_prob_all{ns, 1}'; xor_lastbits']';
                end
            end
        else
            in_string = temp_str;
            sec_s = vsecbits2(sec_t:sec_t+length(in_string)-1);
            for ns = 1:2^slen
                ex_prob_all{ns, 1} = xor(in_string, sec_s');
            end
            sec_t = sec_t + length(in_string);
        end
        % acquire multiple circumstance of each blocks
        if(isempty(last_str)==1)
            for z = 0:count_i-1
                if(z==0)
                    for ns = 1:2^slen
                        every_block{gblkstr+z-floor(pblknum*alpha), ns} = ex_prob_all{ns, 1}(1:temp_strp2(z+2));
                    end
                elseif(z==count_i-1)
                    for ns = 1:2^slen
                        every_block{gblkstr+z-floor(pblknum*alpha), ns} = ex_prob_all{ns, 1}(temp_strp2(z+1)+1:length(ex_prob_all{ns, 1}));
                    end
                else
                    for ns = 1:2^slen
                        every_block{gblkstr+z-floor(pblknum*alpha), ns} = ex_prob_all{ns, 1}(temp_strp2(z+1)+1:temp_strp2(z+2));
                    end
                end
            end
        else
            for z = 0:count_i-1
                if(z==0)
                    for ns = 1:2^slen
                        every_block{gblkstr+z-floor(pblknum*alpha), ns} = [last_str';ex_prob_all{ns, 1}(1:temp_strp2(z+2)-length(last_str))']';
                    end
                elseif(z==count_i-1)
                    for ns = 1:2^slen
                        every_block{gblkstr+z-floor(pblknum*alpha), ns} = ex_prob_all{ns, 1}(temp_strp2(z+1)+1-length(last_str):length(ex_prob_all{ns, 1}));
                    end
                else
                    for ns = 1:2^slen
                        every_block{gblkstr+z-floor(pblknum*alpha),ns} = ex_prob_all{ns,1}(temp_strp2(z+1)+1-length(last_str):temp_strp2(z+2)-length(last_str));
                    end
                end
            end
        end
        if(pblk_indx==0)
            temp_strlineblk = 0;
            bw = 1;
            while(temp_strlineblk-acpaa_mod2<=app_seg_len)
                temp_strlineblk = temp_strlineblk + temp_strp(bw);
                bw = bw + 1;
            end
            temp_strlineblk = temp_strlineblk - temp_strp(bw-1);
            bw = bw - 1;
            bw = bw - (lineblk+1);
            if(i==pblknum)
                bw = bw + 1;
            end
            tmp_blk = [];
        else
            bw = pblknum - gblkstr;
        end
        for cc = 0:bw
            if(gblkstr+cc>pblknum)
                continue;
            end
            % address of processed block
            tmp_blk(cc+1) = blk_chg(gblkstr+cc);
            blk_useblk = [blk_useblk'; blk_chg(gblkstr+cc)]';
            res_block = fun_comp_seqblk(every_block, temp_dchufapp{cc+1,1}, temp_achuf, temp_acnum(cc+1), ...
                temp_acapp_indx, gblkstr, cc, pathname_result, filename, dc_str2(gblkstr+cc), pblknum, slen, alpha);
            rowb = ceil(blk_chg(gblkstr+cc)/blkw);
            colb = mod(blk_chg(gblkstr+cc), blkw);
            if(colb==0)
                colb = blkw;
            end
            for ir = 1:2^slen
                img_qcoef2{ir}(((rowb-1)*8+1):((rowb-1)*8+8),((colb-1)*8+1):((colb-1)*8+8)) = res_block{ir};
            end
        end
        % compute block effect
        blk_val = fun_blk_tol(img_qcoef2, blk_useblk, tmp_blk, img_quanttbl, blkw, blkh, slen, pow, iter);
        tmp_min = find(blk_val == min(blk_val));
        tmp_min = tmp_min(1);
        for ir = 1:2^slen
            if(ir~=tmp_min)
                img_qcoef2{ir} = img_qcoef2{tmp_min};
            end
        end
        temp_str_tmp = [last_str';ex_prob_all{tmp_min,1}']';
        if(i==pblknum)
            break;
        end
        % not used
        last_strk=temp_str(temp_strlineblk+1-acpaa_mod2:acpaa_div*app_seg_len);
        % A: certain value
        last_str = temp_str_tmp(tmp_nxt_posi:length(temp_str_tmp));
        if(isempty(last_strk)==1)
            last_str = [];
        end
        temp_slen  = length(temp_str) - acpaa_div*app_seg_len;
        % B: fetched data but uncertain
        temp_str = temp_str(length(temp_str) - temp_slen+1:length(temp_str));
        
        % if the former segment has not fully parsed yet
        if(count_i>lineblk)
            for r = 1:count_i-(lineblk+bw)
                temp_strp(r) = temp_strp(lineblk+bw+r);
                temp_acnum(r) = temp_acnum(lineblk+bw+r);
                temp_dchufapp{r,1} = temp_dchufapp{lineblk+bw+r,1};
                for rr = 1:temp_acnum(r)
                    temp_achuf{r, rr} = temp_achuf{lineblk+bw+r, rr};
                    temp_acapp_indx(r, rr) = temp_acapp_indx(lineblk+bw+r, rr);
                end
            end
            for r = count_i-(lineblk+bw)+1:temp_strp_max
                temp_strp(r) = 1;
            end
        end
        
        gblkstr = gblkstr + (lineblk + bw);
        count_i = count_i - (lineblk + bw);
        acpaa_mod2 = length(last_str);
    end
end

end