from __future__ import print_function
from mpi4py import MPI
import numpy

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

# Simple message exchange
meta = {'rank': rank}

if rank == 0:
    comm.send(meta, dest=1)
    msg = comm.recv(source=1)
elif rank == 1:
    msg = comm.recv(source=0)
    comm.send(meta, dest=0)
print("Rank {0} received a message from rank {1}.".format(rank, msg['rank']))

# Simple message exchange using numpy arrays
n = 100000
data = numpy.zeros(n, int) + rank
buff = numpy.empty(n, int)

if rank == 0:
    comm.Send(data, dest=1)
    comm.Recv(buff, source=1)
elif rank == 1:
    # One MPI tasks needs to start with send and the other one with
    # receive, otherwise the program dead locks with large message
    # sizes in most MPI implementations 
    comm.Recv(buff, source=0)
    comm.Send(data, dest=0)
print("Rank {0} received an array filled with {1}s.".format(rank, buff[0]))

