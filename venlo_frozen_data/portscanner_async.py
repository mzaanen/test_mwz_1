import threading
from queue import Queue
import time
import socket


def portscan(target_port_tuple):
    target, port = target_port_tuple
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        con = s.connect(target_port_tuple)
        with print_lock:
            print(f'OPEN: Target: {target}, port: {port}, Time taken:, {time.time() - startTime}) ')
        con.close()
    except:
        pass


# a print_lock is used to prevent "double" modification of shared variables this is used so that while one thread
# is using a variable others cannot access it Once it is done, the thread releases the print_lock.
# In order to use it, we want to specify a print_lock per thing you wish to print_lock.
print_lock = threading.Lock()

targets = ['mm.acc.monitdata.com',
           'meldman.nl',
           '217.100.7.58',     # spark office
           '77.166.79.77',     # arco thuis
           '83.163.193.215'
           ]


# The threader thread pulls a worker from a queue and processes it
def threader():
    while True:
        port = q.get()   # gets a worker from the queue
        portscan(port)   # Run the example job with the available worker in queue (thread)
        q.task_done()


q = Queue()  # Creating the queue and threader

# number of threads are we going to allow for
for x in range(30):
    t = threading.Thread(target=threader)
    t.daemon = True  # classifying as a daemon, so they it will die when the main dies
    t.start()        # begins, must come after daemon definition


startTime = time.time()

# A "worker' is the port number in this case
for host in targets:
    try:
        target = socket.gethostbyname(host)
    except Exception:
        target = host

    print(f'target: {target}')

    for port in range(1, 1000):
        q.put((target, port))

# wait till the thread terminates.
q.join()
print(f'Finished, Time taken:, {time.time() - startTime}) ')
