from __future__ import print_function
from mpi4py import MPI
import numpy
from sys import stdout

comm = MPI.COMM_WORLD
myid = comm.Get_rank()
ntasks = comm.Get_size()

# Send and receive buffers
n = 10000000
data = numpy.zeros(n, int) + myid
buff = numpy.zeros(n, int)

# Message chain using Send and Recv

# Start measuring the time spent in communication
comm.barrier()
t0 = MPI.Wtime()

# TODO start
# Send and receive messages as defined in exercise

if myid < ntasks - 1:
    pass
    print("  Rank {0:d}: sent {1:d} elements to rank {2:d}.".format(myid, 
                                                                    len(data), 
                                                                    myid+1))
if myid > 0:
    pass
    print("  Rank {0:d}: received an array filled with {1:d}s.".format(myid, 
                                                                       buff[0]))

# TODO end

t1 = MPI.Wtime()
# ... wait for every rank to finish ...
stdout.flush()
comm.barrier()

if myid == 0:
    print("")
    print("Timings")
    print("Time elapsed in rank {0} {1:6.3f}".format(myid, t1 - t0))
stdout.flush()
comm.barrier()
if myid == ntasks - 1:
    print("Time elapsed in rank {0} {1:6.3f}".format(myid, t1 - t0))

