Two dimensional heat equation
=============================
This folder contains a code which solves two dimensional heat equation
with MPI parallelization. The code features non-blocking point-to-point 
communication, user defined datatypes, collective communication, 
and parallel I/O with MPI I/O.

Heat (or diffusion) equation is

<!-- Equation
\frac{\partial u}{\partial t} = \alpha \nabla^2 u
--> 
![img](http://quicklatex.com/cache3/d2/ql_b3f6b8bdc3a8862c73c5a97862afb9d2_l3.png)

where **u(x, y, t)** is the temperature field that varies in space and time,
and α is thermal diffusivity constant. The two dimensional Laplacian can be
discretized with finite differences as

<!-- Equation
\begin{align*}
\nabla^2 u  &= \frac{u(i-1,j)-2u(i,j)+u(i+1,j)}{(\Delta x)^2} \\
 &+ \frac{u(i,j-1)-2u(i,j)+u(i,j+1)}{(\Delta y)^2}
\end{align*}
--> 
![img](http://quicklatex.com/cache3/2d/ql_59f49ed64dbbe76704e0679b8ad7c22d_l3.png)

Given an initial condition (u(t=0) = u0) one can follow the time dependence of
the temperature field with explicit time evolution method:

<!-- Equation
u^{m+1}(i,j) = u^m(i,j) + \Delta t \alpha \nabla^2 u^m(i,j) 
--> 
![img](http://quicklatex.com/cache3/9e/ql_9eb7ce5f3d5eccd6cfc1ff5638bf199e_l3.png)

Note: Algorithm is stable only when

<!-- Equation
\Delta t < \frac{1}{2 \alpha} \frac{(\Delta x \Delta y)^2}{(\Delta x)^2 (\Delta y)^2}
-->
![img](http://quicklatex.com/cache3/d1/ql_0e7107049c9183d11dbb1e81174280d1_l3.png)

The two dimensional grid is decomposed along both dimensions, and the
communication of boundary data is overlapped with computation. Restart files
are written and read with MPI I/O.

Compilation instructions
------------------------
For building and running the example one needs to have the
[libpng](http://www.libpng.org/pub/png/libpng.html) library installed. In
addition, working MPI environment is required.

Move to proper subfolder (C) and modify the top of the **Makefile**
according to your environment (proper compiler commands and compiler flags).
Code can be build simple with **make**

How to run
----------
The number of MPI ranks has to be a factor of the grid dimension (default 
dimension is 2000). The default initial temperature field is a disk. Initial
temperature field can be read also from a file, the provided **bottle.dat** 
illustrates what happens to a cold soda bottle in sauna.


 * Running with defaults: mpirun -np 4 ./heat_mpi
 * Initial field from a file: mpirun -np 4 ./heat_mpi bottle.dat
 * Initial field from a file, given number of time steps:
   mpirun -np 4 ./heat_mpi bottle.dat 1000
 * Defauls pattern with given dimensions and time steps:
   mpirun -np 4 ./heat_mpi 800 800 1000

  The program produces a series of heat_XXXX.png files which show the
  time development of the temperature field

