/* Utility functions for heat equation solver
 *   NOTE: This file does not need to be edited! */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <mpi.h>
#include <xmmintrin.h>
#include "heat.h"

/* Utility routine for allocating a two dimensional array */
double *malloc_2d(int nx, int ny)
{
    double *array;

    array = (double *) _mm_malloc(nx * ny * sizeof(double), 16);

    return array;
}

/* Utility routine for deallocating a two dimensional array */
void free_2d(double *array)
{
    _mm_free(array);
}


/* Copy data on temperature1 into temperature2 */
void copy_field(field *temperature1, field *temperature2)
{
    assert(temperature1->nx == temperature2->nx);
    assert(temperature1->ny == temperature2->ny);
	__assume_aligned(temperature1->data, 16);
	__assume_aligned(temperature2->data, 16);
    memcpy(temperature2->data, temperature1->data,
           (temperature1->nx + 2) * (temperature1->ny + 2) * sizeof(double));
}

/* Swap the data of fields temperature1 and temperature2 */
void swap_fields(field *temperature1, field *temperature2)
{
    double *tmp;
    tmp = temperature1->data;
    temperature1->data = temperature2->data;
    temperature2->data = tmp;
}

/* Allocate memory for a temperature field and initialise it to zero */
void allocate_field(field *temperature)
{
    // Allocate also ghost layers
    temperature->data =
        malloc_2d(temperature->nx + 2, temperature->ny + 2);

    // Initialize to zero
	__assume_aligned(temperature->data, 16);
    memset(temperature->data, 0.0,
           (temperature->nx + 2) * (temperature->ny + 2) * sizeof(double));
}
 
