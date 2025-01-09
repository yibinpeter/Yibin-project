import binascii
import socket
import time
from time import sleep
import sys
import random
import logging

logging.basicConfig(filename="log2.txt", level=logging.DEBUG,
                    format="%(message)s | %(asctime)s", filemode="w")


with open(sys.argv[6], 'r') as f:
    file_content = f.read() # Read whole file in the file_content string


def divide_985(list):
    for i in range(0, len(list), 985):
        yield list[i:i+985]


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


def dec_to_bin(x):
    return int(bin(x)[2:])

def bin_to_int(data):
    return int(data, 2)

def fill_zero(data, length):
    data = str(data)
    while len(data) != length:
        data = '0' + data
    return data

def string_to_bin(data):
    return ''.join(['%08d'%int(bin(ord(i))[2:]) for i in data])

def bin_to_string(data):
    n = int(data, 2)
    return binascii.unhexlify('%x' % n)


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
    Sequence_number = fill_zero(dec_to_bin(Sequence_number), 32)
    header_mesaage = header_mesaage[:32] + Sequence_number + header_mesaage[64:]

    # change Acknowledgment_number
    Acknowledgment_number = fill_zero(dec_to_bin(Acknowledgment_number), 32)
    header_mesaage = header_mesaage[:64] + Acknowledgment_number + header_mesaage[96:]

    # change CWR_ECE_URG_ACK_PSH_RST_SYN_FIN
    header_mesaage = header_mesaage[:112] + CWR_ECE_URG_ACK_PSH_RST_SYN_FIN + header_mesaage[120:]

    # Change Data
    Data = string_to_bin(Data)
    # Data = Data.encode('utf-8')
    header_mesaage = header_mesaage[:120] + str(Data)
    # print(header_mesaage)
    # print(len(header_mesaage))

    # Chenge Data_length
    Header_length = int(len(Data) / 8)
    # print(Header_length)
    Header_length = dec_to_bin(int(Header_length))
    # print(Header_length)
    Header_length = fill_zero(Header_length, 10)
    header_mesaage = header_mesaage[:96] + Header_length + header_mesaage[106:]

    return header_mesaage, len(Data) / 8

def connect(host, header_mesaage):
    Source_Port, Dest_port, Sequence_number, \
    Acknowledgment_number,Header_length, Unused, \
    CWR_ECE_URG_ACK_PSH_RST_SYN_FIN,Data = decode_TCP_header(header_mesaage)

    Source_Port = int(Source_Port, 2)
    Dest_port = int(Dest_port, 2)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.bind((host, Source_Port))


    #assign sys to 1
    header_mesaage = header_mesaage[:118] + '1' + header_mesaage[119:]

    # log packet message
    log_str = str(Source_Port) + " | " + str(Dest_port) + " | " + 'SYN' + ' | '+ str(len(header_mesaage))
    logging.debug(log_str)
    # send packet to server
    client_socket.sendto(header_mesaage.encode(), (host, Dest_port))

    # recive Ack
    while True:
        header_mesaage, addr = client_socket.recvfrom(1024)


        Source_Port, Dest_port, Sequence_number, \
        Acknowledgment_number, Header_length, Unused, \
        CWR_ECE_URG_ACK_PSH_RST_SYN_FIN, Data = decode_TCP_header(header_mesaage)
        # check if recv packet is ack
        if CWR_ECE_URG_ACK_PSH_RST_SYN_FIN.decode()[3] == '1':
            sp = bin_to_int(Source_Port)
            dp = bin_to_int(Dest_port)
            log_str = str(sp) + " | " + str(dp) + " | " + 'ACK' + ' | ' + str(len(header_mesaage))
            logging.debug(log_str)  # log packet information
            print('recive Ack from server')
            break


    # send Ack
    sp = bin_to_int(Dest_port)
    dp = bin_to_int(Source_Port)
    Dest_port = int(Source_Port, 2)
    header_mesaage = TCP_header_first(sp, dp)
    header_mesaage = header_mesaage[:115] + '1' + header_mesaage[116:]
    client_socket.sendto(header_mesaage.encode(), (host, Dest_port))
    log_str = str(sp) + " | " + str(dp) + " | " + 'ACK' + ' | ' + str(len(header_mesaage))
    logging.debug(log_str)  # log packt information
    return client_socket, int(Data,2)


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
    Source_Port = '0001' + '1011' + '0101' + '1000' # 5000
    Dest_port = '0001' + '1011' + '0101' + '1001' # 7001
    Sequence_number = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'
    Acknowledgment_number = '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000' + '0000'
    Header_length = '0000' + '0000' # 15
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








host = sys.argv[2]
client_port = 5000

server_port = sys.argv[4]
file = sys.argv[6]
# creat first message
header_mesaage = TCP_header_first(client_port, server_port)
# handshake
client_socket, new_port = connect(host, header_mesaage)


Seq = random.randint(0, 10000)
Ack = 1



index = 0
send_buffer = list(divide_985(file_content))
send_buffer_size = sys.getsizeof(send_buffer)

packet_loss_observed = 0

file_trans_start = time.time()

Timeout_Interval = 0.5

while True:
    print('')

    if index == len(send_buffer):  # emd of the packet send
        data = ''
        send_message, Seq_message_length = make_message(client_port, new_port, Seq, Ack, '00000001', data)
        sp = client_port
        dp = new_port
        log_str = str(sp) + " | " + str(dp) + " | " + 'FIN' + ' | ' + str(len(send_message))
        logging.debug(log_str)  # log packet information

        file_trans_end = time.time()
        time_take = file_trans_end - file_trans_start
        print('it takes', time_take,'second to send the file')
        total_band_width = send_buffer_size/time_take
        print('total bandwidth is : ', total_band_width, 'bytes per second')
        print('Packet loss observed for ', file, ' is ', packet_loss_observed)
        client_socket.sendto(send_message.encode(), (host, int(new_port)))  # send FIN packet
        break

    send_message, Seq_message_length = make_message(client_port, new_port, Seq, Ack, '00000000', send_buffer[index])

    # set time out
    client_socket.settimeout(Timeout_Interval)

    # send message
    print('Seq: ', Seq, '  Ack: ', Ack)
    start = time.time()
    client_socket.sendto(send_message.encode(), (host, int(new_port)))
    Seq = Seq + int(Seq_message_length)

    Source_Port, Dest_port, Sequence_number, \
    Acknowledgment_number, Header_length, Unused, \
    CWR_ECE_URG_ACK_PSH_RST_SYN_FIN, Data = decode_TCP_header(send_message)



    sp = bin_to_int(Source_Port)
    dp = bin_to_int(Dest_port)
    log_str = str(sp) + " | " + str(dp) + " | " + 'DATA' + ' | ' + str(len(send_message))
    logging.debug(log_str)  #log packet information



    index = index + 1
    # try to recv ACK from server
    while True:
        try:
            message, addr = client_socket.recvfrom(10240)

            end = time.time()
            Sample_RTT = end - start
            if index == 1:  # intitalize Timeout interval
                Estimate_RTT = Sample_RTT
                Dev_RTT = (Sample_RTT / 2)
                Timeout_Interval = (Sample_RTT + (4 * Dev_RTT))


            Estimate_RTT = (1-0.125) * Estimate_RTT + 0.125 * Sample_RTT
            Dev_RTT = (1-0.25) * Dev_RTT + 0.25 * abs(Estimate_RTT - Sample_RTT)
            Timeout_Interval = (Sample_RTT + (4 * Dev_RTT))



            Source_Port, Dest_port, Sequence_number, \
            Acknowledgment_number, Header_length, Unused, \
            CWR_ECE_URG_ACK_PSH_RST_SYN_FIN, Data = decode_TCP_header(message.decode())

            sp = bin_to_int(Source_Port)
            dp = bin_to_int(Dest_port)
            log_str = str(sp) + " | " + str(dp) + " | " + 'ACK' + ' | ' + str(len(message))
            logging.debug(log_str)  # log packet information

            print('Seq: ', bin_to_int(Sequence_number))
            print('Ack: ', bin_to_int(Acknowledgment_number))
            if CWR_ECE_URG_ACK_PSH_RST_SYN_FIN[3] == '1':
                print('recive Ack')
                # Change Seq
                break

        except socket.timeout:
            # timeout, resend the packet
            print(f'Timeout occurd, resending')
            packet_loss_observed = packet_loss_observed + 1
            client_socket.sendto(send_message.encode(), (host, int(new_port)))

            sp = bin_to_int(Source_Port)
            dp = bin_to_int(Dest_port)
            log_str = str(sp) + " | " + str(dp) + " | " + 'DATA' + ' | ' + str(len(send_message))
            logging.debug(log_str)  # log packet information

f.close()





