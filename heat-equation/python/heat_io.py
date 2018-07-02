from __future__ import print_function
import numpy as np
from mpi4py import MPI
from parallel import Parallel

try:
    import h5py
    use_hdf5 = True
except ImportError:
    use_hdf5 = False

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# Set the colormap
plt.rcParams['image.cmap'] = 'BrBG'

def write_field(field, parallel, step):

    nx, ny = [i - 2 for i in field.shape]
    nx_full = parallel.dims[0] * nx
    ny_full = parallel.dims[1] * ny
    if parallel.rank == 0:
        field_full = np.zeros((nx_full, ny_full), float)
        field_full[:nx, :ny] = field[1:-1, 1:-1]
        # Receive data from other ranks
        for p in range(1, parallel.size):
            coords = parallel.comm.Get_coords(p)
            idx = coords[0] * nx * ny_full + coords[1] * ny
            parallel.comm.Recv((field_full.ravel()[idx:], 1, 
                                parallel.subarraytype), source=p)
        # Write out the data
        plt.figure()
        plt.gca().clear()
        plt.imshow(field_full)
        plt.axis('off')
        plt.savefig('heat_{0:04d}.png'.format(step))
    else:
        # Send the data
        parallel.comm.Ssend((field, 1, parallel.subarraytype), dest=0)

def read_field(filename):

    # Read the initial temperature field from file
    rank = MPI.COMM_WORLD.Get_rank()
    if rank == 0:
        with open(filename) as f:
            line = f.readline().split()
            shape = [int(n) for n in line[1:3]]
    else:
        shape = None
    nx, ny = MPI.COMM_WORLD.bcast(shape, root=0)

    parallel = Parallel(nx, ny)
    nx_local = nx / parallel.dims[0]
    ny_local = ny / parallel.dims[1]

    field = np.zeros((nx_local + 2, ny_local + 2), dtype=float)
    if parallel.rank == 0:
        field_full = np.loadtxt(filename)
        field[1:-1, 1:-1] = field_full[:nx_local, :ny_local]
        # Send the data to other ranks
        for p in range(1, parallel.size):
            coords = parallel.comm.Get_coords(p)
            idx = coords[0] * nx_local * ny + coords[1] * ny_local
            parallel.comm.Send((field_full.ravel()[idx:], 1, 
                                parallel.subarraytype), dest=p)
    else:
        parallel.comm.Recv((field, 1, parallel.subarraytype),
                           source=0)
        # fo = np.empty((nx_local, ny_local), dtype=float)
        # parallel.comm.Recv(fo, source=0)
        # import pickle
        # pickle.dump(fo, open('fo_f{0}.pckl'.format(parallel.rank), 'w'))

    # Set the boundary values
    field[0, :] = field[1, :]
    field[-1, :] = field[-2, :]
    field[:, 0] = field[:, 1]
    field[:,-1] = field[:,-2]


    field0 = field.copy()
    return field, field0, parallel

def write_restart(field, parallel, iter):

    nx, ny = [i - 2 for i in field.shape]
    nx_full = parallel.dims[0] * nx
    ny_full = parallel.dims[1] * ny

    mode = MPI.MODE_CREATE | MPI.MODE_WRONLY
    fh = MPI.File.Open(parallel.comm, "HEAT_RESTART.dat", mode) 
    if parallel.rank == 0:
        fh.Write(np.array((nx_full, ny_full, iter)))
    disp = 3 * 8 # Python ints are 8 bytes
    fh.Set_view(disp, MPI.DOUBLE, parallel.filetype)
    fh.Write_all((field, 1, parallel.restarttype))
    fh.Close()

def read_restart():

    mode = MPI.MODE_RDONLY
    fh = MPI.File.Open(MPI.COMM_WORLD, "HEAT_RESTART.dat", mode) 
    buf = np.zeros(3, int)
    fh.Read_all(buf)
    nx, ny, iter = buf[0], buf[1], buf[2]

    parallel = Parallel(nx, ny)
    nx_local = nx / parallel.dims[0]
    ny_local = ny / parallel.dims[1]

    if parallel.rank == 0:
        print("Restarting from iteration ", iter) 

    field = np.zeros((nx_local + 2, ny_local + 2), dtype=float)

    disp = 3 * 8 # Python ints are 8 bytes
    fh.Set_view(disp, MPI.DOUBLE, parallel.filetype)
    fh.Read_all((field, 1, parallel.restarttype))
    fh.Close()

    field0 = field.copy()
    return field, field0, parallel, iter
