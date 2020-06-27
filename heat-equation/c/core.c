/* Main solver routines for heat equation solver */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <mpi.h>

#include "heat.h"

/* Exchange the boundary values */
void exchange_init(field *temperature, parallel_data *parallel)
{
    int ind, width;
    width = temperature->ny + 2;
    // Send to the up, receive from down
    ind = idx(1, 0, width);
    MPI_Isend(&temperature->data[ind], 1, parallel->rowtype,
              parallel->nup, 11, parallel->comm, &parallel->requests[0]);
    ind = idx(temperature->nx + 1, 0, width);
    MPI_Irecv(&temperature->data[ind], 1, parallel->rowtype, 
              parallel->ndown, 11, parallel->comm, &parallel->requests[1]);
    // Send to the down, receive from up
    ind = idx(temperature->nx, 0, width);
    MPI_Isend(&temperature->data[ind], 1, parallel->rowtype, 
              parallel->ndown, 12, parallel->comm, &parallel->requests[2]);
    ind = idx(0, 0, width);
    MPI_Irecv(&temperature->data[ind], 1, parallel->rowtype,
              parallel->nup, 12, parallel->comm, &parallel->requests[3]);
    // Send to the left, receive from right
    ind = idx(0, 1, width);
    MPI_Isend(&temperature->data[ind], 1, parallel->columntype,
              parallel->nleft, 13, parallel->comm, &parallel->requests[4]); 
    ind = idx(0, temperature->ny + 1, width);
    MPI_Irecv(&temperature->data[ind], 1, parallel->columntype, 
              parallel->nright, 13, parallel->comm, &parallel->requests[5]); 
    // Send to the right, receive from left
    ind = idx(0, temperature->ny, width);
    MPI_Isend(&temperature->data[ind], 1, parallel->columntype,
              parallel->nright, 14, parallel->comm, &parallel->requests[7]);
    ind = 0;
    MPI_Irecv(&temperature->data[ind], 1, parallel->columntype,
              parallel->nleft, 14, parallel->comm, &parallel->requests[6]);

}

/* complete the non-blocking communication */
void exchange_finalize(parallel_data *parallel)
{
    MPI_Waitall(8, &parallel->requests[0], MPI_STATUSES_IGNORE);
}

/* Update the temperature values using five-point stencil */
void evolve_interior(field *curr, field *prev, double a, double dt)
{
    int i, j, i_small, j_small;
    int ic, iu, id, il, ir, igc; // indexes for center, up, down, left, right
    int width;
    width = curr->ny + 2;
    double dx2, dy2;
  
  	// FIXME
  	const int blocksize = 64;
    const int row_width = 2000;
  
    const int paddedblocksize = blocksize + 2;
  
    double cash_friendly_block[3 * paddedblocksize] __attribute__ ((aligned (64)));
    double cash_friendly_tinyblock[3][paddedblocksize] __attribute__ ((aligned (64)));

    double *cache[3];
    cache[0] = (double *)_mm_malloc(row_width * sizeof(double), 64);
    cache[1] = (double *)_mm_malloc(row_width * sizeof(double), 64);
    cache[2] = (double *)_mm_malloc(row_width * sizeof(double), 64);

    /* Determine the temperature field at next time step
     * As we have fixed boundary conditions, the outermost gridpoints
     * are not updated. */
    dx2 = 1. / (prev->dx * prev->dx);
    dy2 = 1. / (prev->dy * prev->dy);
    //let's access in blocks
  
    ssize_t stop_condition = ((curr->ny - 2) & (-blocksize)) + 2; // total_steps - (total_steps % 8)
    //printf("curr->ny: %3.6f stop_condition: %3.6f\n", curr->ny, stop_condition);
    
    double adt = a * dt;
    for (i = 2; i < curr->nx; i++) {

        memcpy(cache[0], &prev->data[idx(i-1, 0, width)], curr->ny * sizeof(double));
        memcpy(cache[1], &prev->data[idx(i, 0, width)], curr->ny * sizeof(double));
        memcpy(cache[2], &prev->data[idx(i+1, 0, width)], curr->ny * sizeof(double));


        for (j = 2; j < stop_condition; j+=blocksize) {
          //first copy into the block
          
            memcpy(&cash_friendly_block[0], &cache[0][j-1], paddedblocksize * sizeof(double));
            memcpy(&cash_friendly_block[paddedblocksize], &cache[1][j-1], paddedblocksize * sizeof(double));
            memcpy(&cash_friendly_block[2 * paddedblocksize], &cache[2][j-1], paddedblocksize * sizeof(double));
            
            for(j_small=0; j_small < blocksize; j_small++) {
              ic = (paddedblocksize + 1) + j_small; // row: 10
              iu = (2 * paddedblocksize + 1) + j_small;
              id = 1 + j_small;
              ir = (paddedblocksize + 2) + j_small;
              il = (paddedblocksize) + j_small;
              igc = idx(i, j + j_small, width);
              
                curr->data[igc] = cash_friendly_block[ic] + adt *
                            ((cash_friendly_block[iu] -
                                2.0 * cash_friendly_block[ic] +
                                cash_friendly_block[id]) * dx2 +
                            (cash_friendly_block[ir] -
                                2.0 * cash_friendly_block[ic] +
                                cash_friendly_block[il]) * dy2);
            }
          
        }
        
        size_t remainder = curr->ny + 1 - stop_condition;
        memcpy(cash_friendly_tinyblock[0], &prev->data[idx(i-1, stop_condition - 1, width)], remainder);
        memcpy(cash_friendly_tinyblock[1], &prev->data[idx(i, stop_condition - 1, width)], remainder);
        memcpy(cash_friendly_tinyblock[2], &prev->data[idx(i+1, stop_condition - 1, width)], remainder);
      
        for(j = stop_condition; j < curr->ny; ++j) {
            igc = idx(i, j + j_small, width);
            curr->data[igc] = cash_friendly_tinyblock[1][j] + adt *
                               ((cash_friendly_tinyblock[2][j] -
                                 2.0 * cash_friendly_tinyblock[1][j] +
                                 cash_friendly_tinyblock[0][j]) * dx2 +
                                (cash_friendly_tinyblock[1][j+1] -
                                 2.0 * cash_friendly_tinyblock[1][j] +
                                 cash_friendly_tinyblock[1][j-1]) * dy2);
        }
    }

    _mm_free(cache[0]);
    _mm_free(cache[1]);
    _mm_free(cache[2]);
}
/* Update the temperature values using five-point stencil */
/* update only the border-dependent regions of the field */
void evolve_edges(field *curr, field *prev, double a, double dt)
{
    int i, j;
    int ic, iu, id, il, ir; // indexes for center, up, down, left, right
    int width;
    width = curr->ny + 2;
    double dx2, dy2;

    /* Determine the temperature field at next time step
     * As we have fixed boundary conditions, the outermost gridpoints
     * are not updated. */
    dx2 = prev->dx * prev->dx;
    dy2 = prev->dy * prev->dy;
    i = 1;
    for (j = 1; j < curr->ny + 1; j++) {
        ic = idx(i, j, width);
        iu = idx(i+1, j, width);
        id = idx(i-1, j, width);
        ir = idx(i, j+1, width);
        il = idx(i, j-1, width);
        curr->data[ic] = prev->data[ic] + a * dt *
                           ((prev->data[iu] -
                             2.0 * prev->data[ic] +
                             prev->data[id]) / dx2 +
                            (prev->data[ir] -
                             2.0 * prev->data[ic] +
                             prev->data[il]) / dy2);
    }
    i = curr -> nx;
    for (j = 1; j < curr->ny + 1; j++) {
        ic = idx(i, j, width);
        iu = idx(i+1, j, width);
        id = idx(i-1, j, width);
        ir = idx(i, j+1, width);
        il = idx(i, j-1, width);
        curr->data[ic] = prev->data[ic] + a * dt *
                           ((prev->data[iu] -
                             2.0 * prev->data[ic] +
                             prev->data[id]) / dx2 +
                            (prev->data[ir] -
                             2.0 * prev->data[ic] +
                             prev->data[il]) / dy2);
    }
    j = 1;
    for (i = 1; i < curr->nx + 1; i++) {
        ic = idx(i, j, width);
        iu = idx(i+1, j, width);
        id = idx(i-1, j, width);
        ir = idx(i, j+1, width);
        il = idx(i, j-1, width);
        curr->data[ic] = prev->data[ic] + a * dt *
                           ((prev->data[iu] -
                             2.0 * prev->data[ic] +
                             prev->data[id]) / dx2 +
                            (prev->data[ir] -
                             2.0 * prev->data[ic] +
                             prev->data[il]) / dy2);
    }
    j = curr -> ny;
    for (i = 1; i < curr->nx + 1; i++) {
        ic = idx(i, j, width);
        iu = idx(i+1, j, width);
        id = idx(i-1, j, width);
        ir = idx(i, j+1, width);
        il = idx(i, j-1, width);
        curr->data[ic] = prev->data[ic] + a * dt *
                           ((prev->data[iu] -
                             2.0 * prev->data[ic] +
                             prev->data[id]) / dx2 +
                            (prev->data[ir] -
                             2.0 * prev->data[ic] +
                             prev->data[il]) / dy2);
    }
}
