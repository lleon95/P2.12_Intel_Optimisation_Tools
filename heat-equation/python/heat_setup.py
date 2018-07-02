import numpy as np
import sys
from os.path import isfile

from parallel import Parallel
from heat_io import read_restart, read_field

def initialize():

    timesteps = 500        # Number of time-steps to evolve system
    nx = 1000
    ny = 1000

    if isfile('HEAT_RESTART.dat'):
        field, field0, parallel, iter0 = read_restart()
    else:
        if len(sys.argv) == 2:
            filename = sys.argv[1]
            field, field0, parallel = read_field(filename)
        elif len(sys.argv) == 3:
            filename = sys.argv[1]
            timesteps = int(sys.argv[2])
            field, field0, parallel = read_field(filename)
        elif len(sys.argv) == 4:
            nx = int(sys.argv[1])
            ny = int(sys.argv[2])
            timesteps = int(sys.argv[3])
            field, field0, parallel = generate_field(nx, ny)
        else:
            field, field0, parallel = generate_field(nx, ny)

        iter0 = 0

    return field, field0, parallel, iter0, timesteps

def generate_field(nx, ny):

    parallel = Parallel(nx, ny)
    nx_local = nx / parallel.dims[0]
    ny_local = ny / parallel.dims[1]

    field = np.zeros((nx_local + 2, ny_local + 2), dtype=float)

    # Square of the disk radius
    radius2 = (nx / 6.0)**2
 
    X, Y = np.meshgrid(np.arange(nx_local + 2), np.arange(ny_local + 2), 
                       indexing='ij')
    ds2 = (X + parallel.coords[0] * nx_local - nx / 2.0 )**2 + \
          (Y + parallel.coords[1] * ny_local - ny / 2.0 )**2
    field[:] = np.where(ds2 < radius2, 5.0, 65.0)

    # Boundaries
    if parallel.coords[0] == 0:
        field[0,:] = 85.0
    if parallel.coords[0] ==  parallel.dims[0] - 1:
        field[-1,:] = 5.0
    if parallel.coords[1] == 0:
        field[:,0] = 20.0
    if parallel.coords[1] ==  parallel.dims[1] - 1:
        field[:,-1] = 70.0

    field0 = field.copy()

    return field, field0, parallel
