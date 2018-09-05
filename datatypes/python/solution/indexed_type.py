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
counts = np.arange(4, dtype=int) + 1
displacements = np.arange(4, dtype=int) * (1 + 2 * data.itemsize)
indexedtype = MPI.INT64_T.Create_indexed(counts, displacements)
indexedtype.Commit()

if rank == 0:
    comm.Send((data, 1, indexedtype), dest=1)
elif rank == 1:
    comm.Recv((data, 1, indexedtype), source=0)

if rank == 1:
    print("Received data:")
    print(data)
