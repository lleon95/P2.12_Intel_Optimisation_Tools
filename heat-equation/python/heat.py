from __future__ import print_function
import numpy as np
import time

from heat_setup import initialize
from evolve import evolve_inner, evolve_edges
from exchange import exchange_init, exchange_finalize
from heat_io import write_field, write_restart


# Basic parameters
a = 0.5                # Diffusion constant
image_interval = 100   # Write frequency for png files
restart_interval= 200  # Write frequency for restart files

# Grid spacings
dx = 0.01
dy = 0.01
dx2 = dx**2
dy2 = dy**2

# For stability, this is the largest interval possible
# for the size of the time-step:
dt = dx2*dy2 / ( 2*a*(dx2+dy2) )

def main():
    # Initialize
    field, field0, parallel, iter0, timesteps = initialize()

    write_field(field, parallel, iter0)
    t0 = time.time()
    for iter in range(iter0, iter0 + timesteps):
        exchange_init(field0, parallel)
        evolve_inner(field, field0, a, dt, dx2, dy2)
        exchange_finalize(parallel)
        evolve_edges(field, field0, a, dt, dx2, dy2)
        if iter % image_interval == 0:
            write_field(field, parallel, iter)
        if iter % restart_interval == 0:
            write_restart(field, parallel, iter)
        field, field0 = field0, field

    t1 = time.time()
    if parallel.rank == 0:
        print("Running time: {0}".format(t1-t0))

if __name__ == '__main__':
    main()
