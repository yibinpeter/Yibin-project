import binascii
import socket
from time import sleep
import sys

domain_str = sys.argv[1]
# domain_name = 'youtube.com'
# domain_name = 'facebook.com'
#domain_name = 'tmz.com'
# domain_name = 'nytimes.com'
# domain_name = 'cnn.com'

temp = domain_str.split('.')
temp1_length = "{:02x}".format(len(temp[0]))
temp2_length = "{:02x}".format(len(temp[1]))
temp1 = binascii.hexlify(temp[0].encode()).decode("utf-8")
temp2 = binascii.hexlify(temp[1].encode()).decode("utf-8")
domain_name_hex = temp1_length + temp1+temp2_length +temp2 + '00'

question = domain_name_hex + '0001' + '0001'
message = 'FF0001000001000000000000' + question

total_send = "192.168.1.122" + '@' +message

client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_add = (("192.168.1.122", 9000))

client_socket.sendto(total_send.encode(), server_add)

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

server_socket.bind(("192.168.1.122", 7000))
while True:
    sleep(1)
    server_response,addr = server_socket.recvfrom(1024)
    if server_response != '':
        break
temp = str(server_response).split('@')

print('Domain:', domain_str )
print('Root server IP address:',temp[1])
print('TLD server IP address:',temp[2])
print('Authoritative server IP address:',temp[3])
print('HTTP Server IP address:',temp[4][:-1])



