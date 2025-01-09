import csv
from operator import itemgetter

reader = csv.reader(open("log3.txt"), delimiter="|")
f = open('log.txt', 'w')
# file = open("log.txt", "w")
buffer = []
for line in sorted(reader, key=itemgetter(4)):
    tmp = line[0] + '|' + line[1] + '|' + line[2] + '|' + line[3] + '|' + line[4]

    f.write(str(tmp))
    f.write('\n')
    # file.write(tmp)



f.close()

