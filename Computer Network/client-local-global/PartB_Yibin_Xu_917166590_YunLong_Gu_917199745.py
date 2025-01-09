import socket



import binascii
import time
from time import sleep
import socket

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





def call_server(ROOT_server, message):
    # ROOT
    start = time.time()
    ROOT_server = "198.41.0.4"  # The server's hostname or IP address
    PORT = 53  # The port used by the server
    server_addr = (ROOT_server, PORT)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.sendto(binascii.unhexlify(message), server_addr)
    data, _ = client_socket.recvfrom(1024)
    end = time.time()

    data, Length_Question,Length_Answear,Length_Author,Length_Addi = getdomain(data)
    data, root_queries_map = getqueries(data,Length_Question)
    data, root_author_map = getAuthor(data,Length_Author)
    data, root_addi_map = getAddi(data,Length_Addi)
    print('ROOT RTT:', end - start)


    # TLP
    start = time.time()
    TLP_server = root_addi_map[0][-1]['Address']  # The server's hostname or IP address
    PORT = 53  # The port used by the server
    server_addr = (TLP_server, PORT)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.sendto(binascii.unhexlify(message), server_addr)
    data, _ = client_socket.recvfrom(1024)
    end = time.time()

    data, Length_Question,Length_Answear,Length_Author,Length_Addi = getdomain(data)
    data, TLP_queries_map = getqueries(data,Length_Question)
    data, TLP_author_map = getAuthor(data,Length_Author)
    data, TLP_addi_map = getAddi(data,Length_Addi)
    print('TLP RTT:', end - start)

    # Addi
    start = time.time()
    # Addi_server = TLP_addi_map[-1][-1]['Address']  # The server's hostname or IP address

    x = 0
    while x < 5:
        type_connection = TLP_addi_map[x][1]['Type']
        if type_connection == 'A':
            Addi_server = TLP_addi_map[x][-1]['Address']
            break
        x += 1

    PORT = 53  # The port used by the server
    server_addr = (Addi_server, PORT)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.sendto(binascii.unhexlify(message), server_addr)
    data, _ = client_socket.recvfrom(1024)
    end = time.time()

    data, Length_Question,Length_Answear,Length_Author,Length_Addi = getdomain(data)
    data, Addi_queries_map = getqueries(data,Length_Question)
    data, Addi_answear_map = getAnswear(data,Length_Answear)
    print('Addi RTT:', end - start)
    return Addi_queries_map[0][0]['Name'],ROOT_server, TLP_server, Addi_server,Addi_answear_map[0][-1]['Address']




server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_socket.bind(("192.168.1.122", 9000))


print("Waiting for connection")

client_msg = server_socket.recv(1024)

input_address = str(client_msg.decode()).split('@')

Domain, ROOT_server, TLP_server, Addi_server, HTTP = call_server(input_address[0],input_address[1])

return_value = str(Domain) + '@' + str(ROOT_server) + '@' + str(TLP_server) + '@' +str(Addi_server) + '@'+str(HTTP)


# print('return_IP', return_IP)
server_add = (("192.168.1.122", 7000))
server_socket.sendto(return_value.encode(), server_add)

#