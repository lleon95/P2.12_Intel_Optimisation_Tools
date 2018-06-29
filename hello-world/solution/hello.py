from __future__ import print_function
from mpi4py import MPI

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

if rank == 0:
    print("In total there are {0} tasks".format(size))

print("Hello from", rank)

