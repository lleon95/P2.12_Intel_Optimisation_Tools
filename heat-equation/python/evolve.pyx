# cython: profile=True

import numpy as np
cimport numpy as cnp

import cython

# Time evolution for the inner part of the grid
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cpdef evolve_inner(cnp.ndarray[cnp.double_t, ndim=2]u,
           cnp.ndarray[cnp.double_t, ndim=2]u_previous,
           double a, double dt, double dx2, double dy2):
    """Explicit time evolution.
       u:            new temperature field
       u_previous:   previous field
       a:            diffusion constant
       dt:           time step. """

    cdef int nx = u.shape[0] - 2
    cdef int ny = u.shape[1] - 2

    cdef int i,j

    # Multiplication is more efficient than division
    cdef double dx2inv = 1. / dx2
    cdef double dy2inv = 1. / dy2

    for i in range(2, nx):
        for j in range(2, ny):
            u[i, j] = u_previous[i, j] + a * dt * ( \
             (u_previous[i+1, j] - 2*u_previous[i, j] + \
              u_previous[i-1, j]) * dx2inv + \
             (u_previous[i, j+1] - 2*u_previous[i, j] + \
                 u_previous[i, j-1]) * dy2inv )

# Time evolution for the edges  of the grid
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cpdef evolve_edges(cnp.ndarray[cnp.double_t, ndim=2]u,
           cnp.ndarray[cnp.double_t, ndim=2]u_previous,
           double a, double dt, double dx2, double dy2):
    """Explicit time evolution.
       u:            new temperature field
       u_previous:   previous field
       a:            diffusion constant
       dt:           time step
       dx2:          grid spacing squared, i.e. dx^2
       dy2:            -- "" --          , i.e. dy^2"""

    cdef int nx = u.shape[0] - 2
    cdef int ny = u.shape[1] - 2

    cdef int i,j

    # Multiplication is more efficient than division
    cdef double dx2inv = 1. / dx2
    cdef double dy2inv = 1. / dy2

    j = 1
    for i in range(1, nx+1):
        u[i, j] = u_previous[i, j] + a * dt * ( \
         (u_previous[i+1, j] - 2*u_previous[i, j] + \
          u_previous[i-1, j]) * dx2inv + \
         (u_previous[i, j+1] - 2*u_previous[i, j] + \
          u_previous[i, j-1]) * dy2inv )

    j = ny
    for i in range(1, nx+1):
        u[i, j] = u_previous[i, j] + a * dt * ( \
         (u_previous[i+1, j] - 2*u_previous[i, j] + \
          u_previous[i-1, j]) * dx2inv + \
         (u_previous[i, j+1] - 2*u_previous[i, j] + \
          u_previous[i, j-1]) * dy2inv )

    i = 1
    for j in range(1, ny+1):
        u[i, j] = u_previous[i, j] + a * dt * ( \
         (u_previous[i+1, j] - 2*u_previous[i, j] + \
          u_previous[i-1, j]) * dx2inv + \
         (u_previous[i, j+1] - 2*u_previous[i, j] + \
          u_previous[i, j-1]) * dy2inv )

    i = nx
    for j in range(1, ny+1):
        u[i, j] = u_previous[i, j] + a * dt * ( \
         (u_previous[i+1, j] - 2*u_previous[i, j] + \
          u_previous[i-1, j]) * dx2inv + \
         (u_previous[i, j+1] - 2*u_previous[i, j] + \
          u_previous[i, j-1]) * dy2inv )

