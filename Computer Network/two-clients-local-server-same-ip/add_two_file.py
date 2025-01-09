# Python program to
# demonstrate merging
# of two files
import fileinput

data = data2 = ""

# Reading data from file1
with open('log1.txt') as fp:
    data = fp.read()

fp.close()
# Reading data from file2
with open('log2.txt') as fp:
    data2 = fp.read()

fp.close()
data += data2

with open('log3.txt', 'w') as fp:
    fp.write(data)

fileinput.close()