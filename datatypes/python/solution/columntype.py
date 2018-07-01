from __future__ import print_function
from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

if size != 2:
    raise RuntimeError("Please run with two MPI tasks")

data = np.zeros((8,8), int)
if rank == 0:
    for i in range(8):
        data[i,:] = np.arange(1, 9) + (i+1) * 10

if rank == 0:
    print("Original data:")
    print(data)

# Create the custom datatype
# Note: Python integers are 64 bits
columntype = MPI.INT64_T.Create_vector(8, 1, 8)
columntype.Commit()

# mpi4py requires that the input and output buffers are contiguous 
# in memory. Thus, in order to send/receive from second column we need
# to create a contiguous view starting from the second element in memory
# which can be accomplished by flattening the array into 1d with ravel
if rank == 0:
    comm.Send((data.ravel()[1:], 1, columntype), dest=1)
elif rank == 1:
    comm.Recv((data.ravel()[1:], 1, columntype), source=0)

if rank == 1:
    print("Received data:")
    print(data)
