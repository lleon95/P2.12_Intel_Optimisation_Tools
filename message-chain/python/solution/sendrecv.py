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

# Message chain using Sendrecv

# Start measuring the time spent in communication
comm.barrier()
t0 = MPI.Wtime()

tgt = myid + 1
src = myid - 1
if myid > 0 and myid < ntasks -1:  # middle of chain; send and receive
    comm.Sendrecv(data, dest=tgt, sendtag=tgt, 
                  recvbuf=buff, source=src, recvtag=myid)
    print("  Rank {0}: sent {1} elements to myid {2}.".format(myid, len(data), tgt))
    print("  Rank {0}: received a message from myid {1}.".format(myid, src))
    print("  Rank {0}: received an array filled with {1}s.".format(myid, buff[0]))
elif myid == 0:          # start of chain; only send
    comm.Send(data, dest=tgt, tag=tgt)
    print("  Rank {0}: sent {1} elements to myid {2}.".format(myid, 
                                                            len(data), tgt))
elif myid == ntasks - 1: # end of chain; only receive
    comm.Recv(buff, source=src, tag=myid)
    print("  Rank {0}: received a message from myid {1}.".format(myid, src))
    print("  Rank {1}: received an array filled with {1}s.".format(myid, buff[0]))


t1 = MPI.Wtime()
# ... wait for every myid to finish ...
stdout.flush()
comm.barrier()

if myid == 0:
    print("")
    print("Timings")
    print("Time elapsed in myid {0} {1:6.3f}".format(myid, t1 - t0))
stdout.flush()
comm.barrier()
if myid == ntasks - 1:
    print("Time elapsed in myid {0} {1:6.3f}".format(myid, t1 - t0))

