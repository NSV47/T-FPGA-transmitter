clear
clc
n = 0:4095 ;
yn = sin(2*pi/4096*n) ;
 
yn = round((yn+1)*2047); 
 
plot(n,yn);
 
fid = fopen('C:\Users\s.novikov\Documents\work\271124\rom_test_1.coe','wt');
fprintf(fid,'memory_initialization_radix = 10;\nmemory_initialization_vector = ');
 
for i = 1 : 4096
    if mod(i-1,12) == 0 
        fprintf(fid,'\n');
    end
    fprintf(fid,'%4d,',yn(i));
end
