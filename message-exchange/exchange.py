from __future__ import print_function
from mpi4py import MPI
import numpy

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

# Simple message exchange using numpy arrays
n = 100000
data = numpy.zeros(n, int) + rank
buff = numpy.empty(n, int)

# TODO:
# Send and receive messages as defined in exercise
if rank == 0:

elif rank == 1:


print("Rank {0} received an array filled with {1}s.".format(rank, buff[0]))


# Simple message exchange of Python objects
meta = {'rank': rank}

# TODO:
# Send and receive messages as defined in exercise
if rank == 0:

elif rank == 1:


print("Rank {0} received a message from rank {1}.".format(rank, msg['rank']))

