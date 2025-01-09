import os
import random
import socket
import binascii
from time import sleep
from concurrent.futures import ThreadPoolExecutor
import sys


def port_to_16bin(port):

    decimal_port = bin(int(port)).replace("0b", "")

    str_port = str(decimal_port)
    str_port_len = len(str_port)
    str_port_len_diff = 16 - str_port_len
    i = 0
    if str_port_len_diff != 0:
        while i != str_port_len_diff:
            str_port = '0' + str_port
            i += 1
    return str_port


def bin_to_int(data):
    return int(data, 2)


def dec_to_bin(x):
    return int(bin(x)[2:])


def bin_to_string(data):
    input_string = int(data, 2)
    Total_bytes = (input_string.bit_length() + 7) // 8
    input_array = input_string.to_bytes(Total_bytes, "big")
    ASCII_value = input_array.decode()
    return ASCII_value



def fill_zero(data, length):
    data = str(data)
    while len(data) != length:
        data = '0' + data
    return data


def string_to_bin(data):
    return ''.join(['%08d'%int(bin(ord(i))[2:]) for i in data])


def make_message(Source_Port, Dest_port, Sequence_number, Acknowledgment_number
                 , CWR_ECE_URG_ACK_PSH_RST_SYN_FIN, Data):

    # new connection
    header_mesaage = TCP_header()

    # Change Source_Port
    Source_Port = fill_zero(dec_to_bin(Source_Port), 16)
    header_mesaage = Source_Port + header_mesaage[16:]

    # Change Dest_port
    Dest_port = fill_zero(dec_to_bin(Dest_port), 16)
    header_mesaage = header_mesaage[:16] + Dest_port + header_mesaage[32:]

    #change Sequence_number
    Sequence_number = fill_zero(dec_to_bin(int(Sequence_number)), 32)
    header_mesaage = header_mesaage[:32] + Sequence_number + header_mesaage[64:]


    # change Acknowledgment_number
    Acknowledgment_number = fill_zero(dec_to_bin(int(Acknowledgment_number)), 32)
    header_mesaage = header_mesaage[:64] + Acknowledgment_number + header_mesaage[96:]

    # change CWR_ECE_URG_ACK_PSH_RST_SYN_FIN
    header_mesaage = header_mesaage[:112] + CWR_ECE_URG_ACK_PSH_RST_SYN_FIN + header_mesaage[120:]

    # Change Data
    Data = string_to_bin(Data)
    header_mesaage = header_mesaage[:120] + Data

    # Chenge Data_length
    Header_length = int(len(Data) / 8)
    Header_length = dec_to_bin(int(Header_length))
    Header_length = fill_zero(Header_length, 10)
    header_mesaage = header_mesaage[:96] + Header_length + header_mesaage[106:]

    return header_mesaage, len(Data) / 8


def TCP_header_first(source_port, dest_port):

    Source_Port = port_to_16bin(source_port)  # 7000
    Dest_port = port_to_16bin(dest_port)  # 7001
    Sequence_number = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'
    Acknowledgment_number = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'
    Header_length = '0000' + '0000'
    Unused = '0000' + '0000'
    CWR_ECE_URG_ACK_PSH_RST_SYN_FIN = '0' + '0' + '0' + '0' + '0' + '0' + '0' + '0'
    Data = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'

    header_mesaage = Source_Port + Dest_port + Sequence_number + Acknowledgment_number \
                     + Header_length + Unused + CWR_ECE_URG_ACK_PSH_RST_SYN_FIN + Data
    return header_mesaage


def TCP_header():
    Source_Port = '0001' + '1011' + '0101' + '1001' # 7001
    Dest_port = '0001' + '1011' + '0101' + '1000' # 7000
    Sequence_number = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'
    Acknowledgment_number = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'
    Header_length = '0000' + '0000'
    Unused = '0000' + '0000'
    CWR_ECE_URG_ACK_PSH_RST_SYN_FIN = '0' + '0' + '0' + '0' + '0' + '0' + '0' + '0'
    Data = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'

    header_mesaage = Source_Port + Dest_port + Sequence_number + Acknowledgment_number \
                     + Header_length + Unused + CWR_ECE_URG_ACK_PSH_RST_SYN_FIN + Data
    return header_mesaage


def decode_TCP_header(header_mesaage):
    Source_Port =header_mesaage[0:16]
    Dest_port =header_mesaage[16:32]
    Sequence_number =header_mesaage[32:64]
    Acknowledgment_number =header_mesaage[64:96]
    Header_length =header_mesaage[96:106]
    Unused =header_mesaage[106:112]
    CWR_ECE_URG_ACK_PSH_RST_SYN_FIN =header_mesaage[112:120]
    Data = header_mesaage[120:]
    return Source_Port, Dest_port, Sequence_number, Acknowledgment_number, \
           Header_length, Unused, CWR_ECE_URG_ACK_PSH_RST_SYN_FIN, Data


def client_handler(new_port, client_ID, port_target,packet_loss_percentage,round_trip_jitter, file_path):
    Seq = 1
    Ack = 1
    data_buffer=[]



    new_client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    host = sys.argv[2]
    new_client_socket.bind((host, new_port))
    print('new_client_connected!')

    while True:

        message, addr = new_client_socket.recvfrom(10240)

        Source_Port, Dest_port, Sequence_number, \
        Acknowledgment_number, Header_length, Unused, \
        CWR_ECE_URG_ACK_PSH_RST_SYN_FIN, Data = decode_TCP_header(message.decode())

        # if recv FIN message, disconnect
        if CWR_ECE_URG_ACK_PSH_RST_SYN_FIN[-1] == '1':
            break

        Ack = Ack + int(len(Data) / 8)
        sender_seq =  bin_to_int(Sequence_number) + int(len(Data) / 8)
        sender_ack = bin_to_int(Acknowledgment_number)
        print('Seq: ', sender_seq)
        print('Ack: ', sender_ack)



        bin_Data = bin_to_string(Data)



        # check drop or not
        random_chance = random.randint(0, 100)
        print('random_chance',random_chance)
        if random_chance < packet_loss_percentage: # 10
            continue



        #check Ack drop or not
        random_Ack = round(random.uniform(0, 1), 2)
        print('random_Ack',random_Ack)
        if random_Ack > round_trip_jitter: # 0.5
            sleep(random_Ack)

        # send ACK for Data packet
        send_message, Seq_message_length = make_message(new_port, port_target, Seq, Ack, '00010000', 'here is server')
        new_client_socket.sendto(send_message.encode(), (host, port_target))

        data_buffer.append(bin_Data)

        print('sendAck')
        print('')

    # write to the file
    file = open(file_path, "w")
    i = 0

    while i < len(data_buffer):
        file.write(data_buffer[i])
        i = i+1


    file.close()
    print("finish")



def start_M_UDP_server(host, port_self, packet_loss_percentage, round_trip_jitter):


    executor = ThreadPoolExecutor(max_workers=5)
    client_ID = 0
    new_port = 7002

    while True:
        new_port = new_port + 1

        client_socket, client_addr, error, Source_Port, file_path = accept(host, port_self, new_port,
                                                                packet_loss_percentage,round_trip_jitter)
        while error == 'error':
            client_socket.close()
            client_socket, client_addr, error, Source_Port = accept(host, port_self, new_port)
        executor.submit(client_handler, new_port, client_ID, Source_Port, packet_loss_percentage,round_trip_jitter, file_path)
        client_socket.close()
        client_ID = client_ID + 1



def create_dir(dirName):
    directory = './' + dirName
    filename = output_file
    file_path = os.path.join(directory, filename)
    if not os.path.isdir(directory):
        os.mkdir(directory)
    print("dirctory created, ", dirName)
    return file_path




def accept(host, port_self, new_port, packet_loss_percentage, round_trip_jitter):
    # 3 way handshake
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server_socket.bind((host, port_self))

    while True:
        header_mesaage, addr = server_socket.recvfrom(10240)

        Source_Port, Dest_port, Sequence_number, \
        Acknowledgment_number, Header_length, Unused, \
        CWR_ECE_URG_ACK_PSH_RST_SYN_FIN,Data = decode_TCP_header(header_mesaage.decode())
        Source_Port = int(Source_Port, 2)

        if CWR_ECE_URG_ACK_PSH_RST_SYN_FIN[6] != '1':
            error = 'error'
            return server_socket, addr, error
        print("the source_port is:", Source_Port)
        print('recive sys from server')

        # set ack to 1
        header_mesaage = TCP_header_first(port_self, Source_Port)
        header_mesaage = header_mesaage[:115] + '1' + header_mesaage[116:]
        Data = str(dec_to_bin(new_port))
        while len(Data) != 32:
            Data = '0' + Data
        header_mesaage = header_mesaage[:120] + Data
        server_socket.sendto(header_mesaage.encode(), (host, Source_Port))
        break

    while True:
        header_mesaage, addr = server_socket.recvfrom(10240)

        Source_Port, Dest_port, Sequence_number, \
        Acknowledgment_number, Header_length, Unused, \
        CWR_ECE_URG_ACK_PSH_RST_SYN_FIN,Data = decode_TCP_header(header_mesaage.decode())

        if CWR_ECE_URG_ACK_PSH_RST_SYN_FIN[3] != '1':
            error = 'error'
            return server_socket, addr, error
        print("client_port is: ", Source_Port)
        print('recive Ack from client')
        break


    Source_Port = int(Source_Port, 2)
    error = 'True'

    file_path = create_dir(str(Source_Port))

    return server_socket, addr, error, Source_Port , file_path









host = sys.argv[2]
port_self = int(sys.argv[4])
packet_loss_percentage = int(sys.argv[6])
round_trip_jitter = float(sys.argv[8])
output_file = sys.argv[10]

start_M_UDP_server(host, port_self, packet_loss_percentage, round_trip_jitter)



