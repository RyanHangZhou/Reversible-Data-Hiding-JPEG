
function val = fun_smooth(img)
%Æ½»¬º¯Êý

[height, width] = size(img);

val = 0;
for i = 1:height
    for j = 1:width-1
        val = val + abs(img(i, j)-img(i, j+1));
    end
end

end