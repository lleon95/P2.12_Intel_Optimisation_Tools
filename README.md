# Parallel programming with MPI

This repository contains various exercises and examples on parallel programming with message passing interface (MPI).

A working MPI installation is needed for building the code. Simple cases can
be built and run as:

 - mpicc -o exe exercise.c ; mpirun -np xxx ./exe (C)
 - mpif90 -o exe exercise.c ; mpirun -np xxx ./exe (Fortran)
 - mpirun -np xxx python program.py (Python)

where mpicc/mpif90/mpirun should be replaced by the correct commands for
the particular computer platform. For more complex cases a Makefile is
provided.

## Exercises

 - [Hello world](hello-world) Simplest possible MPI program (C, Fortran and 
   Python versions). Level: **basic**
 - [Message exchange](message-exchange) Simple point-to-point communication 
   (C, Fortran and Python versions). Level: **basic**
 - [Message chain](message-chain) Point-to-point communication in one
   dimensional aperiodic chain. (C, Fortran and Python versions). 
   Level: **intermediate**
 - [Collective communciation](collectives) Basic collective communication
   patterns (C, Fortran and Python versions). Level: **basic/intermediate**
 - [Parallel I/O](parallel-io) Simple parallel I/O using Posix calls and 
   MPI I/O (C and Fortran versions). Level: **basic/intermediate**
 - [User defined datatypes](datatypes) Communication of non-uniform data using
   user defined datatypes (C, Fortran and Python versions). 
   Level: **intermediate/advanced**

## Examples
 - [Heat equation](heat-equation) A two dimensional heat equation solver which
 is parallelized with MPI. The code features non-blocking point-to-point
 communication, user defined datatypes, and parallel I/O with MPI I/O
 (C, Fortran and Python versions). Level: **advanced** 

## How to contribute

Any contributions (new exercises and examples, bug fixes, improvements etc.) are
warmly welcome. In order to contribute, please follow the standard
Gitlab workflow:

1. Fork the project into your personal space
2. Create a feature branch
3. Work on your contributions
4. Push the commit(s) to your fork
5. Submit a merge request to the master branch

As a quality assurance, the merge request is reviewed by PRACE staff before it is accepted into main branch.
