# cite: https://www.geeksforgeeks.org/how-to-write-to-an-html-file-in-python/
# https://www.youtube.com/watch?v=4lEyj3sdL7I&t=341s
# https://www.youtube.com/watch?v=jZ0nuzaehjY&t=310s


import binascii
import socket
import time
import sys


# binary_string = binascii.unhexlify(hex_string)


def getdomain(data):
    Length_Question = int(binascii.hexlify(data[4:6]).decode("utf-8"), base=16)
    Length_Answear = int(binascii.hexlify(data[6:8]).decode("utf-8"), base=16)
    Length_Author = int(binascii.hexlify(data[8:10]).decode("utf-8"), base=16)
    Length_Addi = int(binascii.hexlify(data[10:12]).decode("utf-8"), base=16)

    return data[12:],Length_Question,Length_Answear,Length_Author,Length_Addi


def getqueries(data, Length):
    Map=[]
    while Length != 0:
        temp = []
        #Name
        Length1 = int(binascii.hexlify(data[0:1]).decode("utf-8"), base=16)
        string1 = data[1:1+Length1]
        Length2 = int(binascii.hexlify(data[1+Length1:2+Length1]).decode("utf-8"), base=16)
        string2 = data[2+Length1 : 2+Length1+Length2]
        Name = string1.decode() + '.' + string2.decode()
        data = data[3+Length1+Length2:]

        #Type
        Type = get_type(data[0:2])
        data = data[2:]

        #Class
        Class = data[0:2]
        data = data[2:]

        temp.append({'Name':Name})
        temp.append({'Type':Type})
        temp.append({'Class':Class})
        Map.append(temp)
        Length = Length - 1
    return data,Map

def get_type(question_type):
    qt = ''
    if question_type == b'\x00\x01':
        qt = 'A'
    if question_type == b'\x00\x02':
        qt = 'NS'
    if question_type == b'\x00\x1c':
        qt = 'AAAA'
    # if question_type == b'\x00\x01':
    #     qt = 'CNAM'
    # if question_type == b'\x00\x01':
    #     qt = 'MX'
    return qt


def getAuthor(data,Length):
    Map = []
    while Length != 0:
        temp = []
        Name = data[0:2]
        Type = get_type(data[2:4])
        TTL = data[6:10]
        Data_length =int(binascii.hexlify(data[10:12]).decode("utf-8"), base=16)
        Server =data[12:12+Data_length]
        data=data[12+Data_length:]

        temp.append({'Name':Name})
        temp.append({'Type':Type})
        temp.append({'TTL':TTL})
        temp.append({'Data_length':Data_length})
        temp.append({'Server':Server})
        Map.append(temp)
        Length = Length -1
    return data,Map

def getAddi(data,Length):
    Map = []
    while Length != 0:
        temp =[]
        Name = data[0:2]
        Type = get_type(data[2:4])
        TTL = data[6:10]
        Data_length =int(binascii.hexlify(data[10:12]).decode("utf-8"), base=16)
        Address =data[12:12+Data_length]
        string = ''
        if Type == 'A':
            for i in Address:
                string += str(i)
                string += '.'
            Address = string[:-1]
        data=data[12+Data_length:]

        temp.append({'Name':Name})
        temp.append({'Type':Type})
        temp.append({'TTL':TTL})
        temp.append({'Data_length':Data_length})
        temp.append({'Address':Address})
        Map.append(temp)
        Length = Length - 1
    return data,Map



def getAnswear(data,Length):
    Map = []
    while Length != 0:
        temp =[]
        Name = data[0:2]
        Type = get_type(data[2:4])
        TTL = data[6:10]
        Data_length =int(binascii.hexlify(data[10:12]).decode("utf-8"), base=16)
        Address =data[12:12+Data_length]
        string = ''
        if Type == 'A':
            for i in Address:
                string += str(i)
                string += '.'
            Address = string[:-1]
        data=data[12+Data_length:]

        temp.append({'Name':Name})
        temp.append({'Type':Type})
        temp.append({'TTL':TTL})
        temp.append({'Data_length':Data_length})
        temp.append({'Address':Address})
        Map.append(temp)
        Length = Length - 1
    return data,Map

# three different Ip
domain_str = sys.argv[1]

# HOST = "91.245.229.1"  # The server's hostname or IP address
# HOST = "169.237.229.88"  # The server's hostname or IP address
# HOST = "136.159.85.15"  # The server's hostname or IP address

PORT = 53  # The port used by the server
server_addr = (HOST, PORT)
client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

#convert domain_name to hex
domain_name = domain_str
temp = domain_name.split('.')
temp1_length = "{:02x}".format(len(temp[0]))
temp2_length = "{:02x}".format(len(temp[1]))
temp1 = binascii.hexlify(temp[0].encode()).decode("utf-8")
temp2 = binascii.hexlify(temp[1].encode()).decode("utf-8")
domain_name_hex = temp1_length + temp1+temp2_length +temp2 + '00'
question = domain_name_hex + '0001' + '0001'
message = 'FF0001000001000000000000' + question

client_socket.sendto(binascii.unhexlify(message), server_addr)
data, _ = client_socket.recvfrom(1024)

#message return from DNS server
return_response = binascii.hexlify(data).decode("utf-8")


#find domain name, type of DNS, the length of queriers part
data, Length_Question, Length_Answear, Length_Author, Length_Addi = getdomain(data)
data, queries_map = getqueries(data, Length_Question)
data, answear_map = getAnswear(data, Length_Answear)
Type = answear_map[0][1]
IP = answear_map[0][-1]




target_host = IP['Address']

target_port = 80  # create a socket object
client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# connect the client
client.connect((target_host, target_port))

# send some data
star = time.time()
request = "GET / HTTP/1.1\r\nHost:tmz.com\r\n\r\n"
client.send(request.encode())


# receive some data
response = client.recv(4096)
http_response = repr(response)
end = time.time()

print('Domain: ', queries_map[0][0]['Name'])
print('HTTP Server IP address :', IP['Address'])
print('RTT of Http:', end - star)

# Creating an HTML file
Func = open("first.html", "w")

# Adding input data to the HTML file
Func.write(http_response)

# Saving the data into the HTML file
Func.close()




# ID = '1111111100000000'
# QR = '0'
# Opcode = '0000'
# AA = '0'
# TC ='0'
# RD = '1'
# RA = '0'
# Z ='000'
# RCODE ='0000'
# QDCOUNT ='0000000000000001'
# ANCOUNT ='0000000000000000'
# NSCOUNT ='0000000000000000'
# ARCOUNT ='0000000000000000'
#
# message = ID + QR + Opcode + AA + TC + RD +RA + Z + RCODE + QDCOUNT + \
#           ANCOUNT + NSCOUNT + ARCOUNT

# HOST = "192.168.1.116"  # The server's hostname or IP address
# PORT = 8000  # The port used by the server
# server_addr = ("192.168.1.116", 8000)
#
# client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
#
# for i in range(10):
#     client_socket.sendto(("ping %s" % i ).encode(),server_addr)




# with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
#     s.connect((HOST, PORT))
#     s.sendall(b"Hello, world")
#     data = s.recv(1024)
#
# print(f"Received {data!r}")`