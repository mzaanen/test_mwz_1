import pyfiglet
import sys
import socket
from datetime import datetime

ascii_banner = pyfiglet.figlet_format("PORT SCANNER")
print(ascii_banner)

# 'www.monitdata.com',
# 'www.parkeerdata.nl',
# 'www.meldman.nl',
# 'vtag.monitdata.com',
# '217.100.7.58',     # spark office
# '77.166.79.77',     # arco thuis
# '83.163.193.215',   # maarten thuis
# '213.127.28.234',   # marco thuis
# '84.84.133.69',  # wouter thuis
# # '212.123.236.180',   # VM productie Amsterdam



hosts = [
    'parkeerdata.acc.monitdata.com',  # alle .acc. draaien daar, dus hiermee ook b.v. vtag.acc.monitdata.com ge-port-scant
    'parkeerdata.nl',
]

max_no_ports = 1530

for idxh, host in enumerate(hosts):
    # Add Banner
    try:
        target = socket.gethostbyname(host)
    except Exception:
        target = host

    print("-" * 50)
    print(f"Scanning {idxh+1} nth Target: {host}, ip-address:{target}")
    print(f"Scanning started at: {datetime.now()}")
    print("-" * 50)

    try:
        # will scan ports between 1 to 65,535
        for port in range(1, max_no_ports):
            if port % 1 == 500:
                print(f"Port nr: {port} at {datetime.now()}")  #, end='\r')
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            socket.setdefaulttimeout(.05)

            # returns an error indicator
            result = s.connect_ex((target, port))
            if result == 0:
                if port == 22:
                    print(f"Port {port} is open, ssh enabled, set up public key authentication, disable password authentication")
                elif port in (80, 8000, 8080):
                    print(f"Port {port} is open, ssh enabled, does not introduce a larger attack surface on your server, because requests are generally served by the same software that runs on port 443")
                elif port == 443:
                    print(f"Port {port} is open, ssh enabled, https requests handling")
                elif port == 2376:
                    print(f"Port {port} is open, Docker stuff, TLS encrypted socket, most likely this is your CI servers 4243 port as a modification of the https 443 port")
                elif port == 5432:
                    print(f"Port {port} is open, PostgreSQL")
                else:
                    print(f"Port {port} is open, nothing to say about this one... probably bad news")
                s.close()
            # else:
            #     print("Port {} is closed".format(port))
        print(f'finished {target}\n\n')

    except KeyboardInterrupt:
        print(f"\n Exiting Program !!!! At port {port}")
        sys.exit()
    except socket.gaierror:
        print("\n Hostname Could Not Be Resolved !!!!")
        sys.exit()
    except socket.error:
        print("\nServer not responding !!!!")
        sys.exit()
    except Exception as e:
        print(f"Unexpected error. Port: {port}, err message: {sys.exc_info()[0]}")


