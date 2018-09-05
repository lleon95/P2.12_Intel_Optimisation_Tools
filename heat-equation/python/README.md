# Python implementation

The Python implementation utilizes NumPy and mpi4py for computation and
communication, as well as matplotlib for outputting images. The main program
is implemented in [heat.py](heat.py), and the whole program can be executed as

    mpirun -np xxx python heat.py


## Using Cython kernel

By default, the code uses pure NumPy for evaluating the time evolution
step. In addition, a Cython version for the main computational kernels
is provided in [evolve.pyx](evolve.pyx). The Cython kernels can be built
into Python extension in current directory with

    python setup.py build_ext --inplace

After building the Cython kernels main program can be executed as previously.
