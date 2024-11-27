clear
clc
n = 0:4095 ;
yn = sin(2*pi/4096*n) ;
 
yn = round((yn+1)*2047); 
 
plot(n,yn);
 
fid = fopen('C:\Users\s.novikov\Documents\work\271124\rom_test_3.mi','wt');
fprintf(fid,'#File_format=Hex,\n#Address_depth=4096,\n#Data_width=12,');
 
for i = 1 : 4096
    if mod(i-1,1) == 0 
        fprintf(fid,'\n');
    end
    fprintf(fid,'%X,',yn(i));
end
