import socket

import nmap3

host = '213.127.28.234'
host = '127.0.0.1'
host = '83.163.193.215'
try:
    target = socket.gethostbyname(host)
except Exception:
    target = host


nmap = nmap3.Nmap()
os_results = nmap.nmap_dns_brute_script("www.parkeerdata.nl")
print(f'jj, {os_results}')