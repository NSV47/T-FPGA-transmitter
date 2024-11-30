import os
import sys

res = ''

if len(sys.argv)<2 :
	print("Not enough arguments, need file with data name param")
filename = sys.argv[1]
print(filename)

def read_txt_file(filename):
    output = ""  # инициализация результирующего текста
    with open(filename, 'r') as f:
        for line in f:
            output = output + line.replace(',\n', '\n') # strip() # rstrip(",\n")
    f.close()
    return output
    
def write_txt_file(input):
    with open('1.mi', 'w') as file:
        file.write(input)  # перезапись файла
    
res = read_txt_file(filename)
write_txt_file(res)