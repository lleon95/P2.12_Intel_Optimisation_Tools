! Field metadata for heat equation solver
module heat
  use iso_fortran_env, only : REAL64
  implicit none

  integer, parameter :: dp = REAL64
  real(dp), parameter :: DX = 0.01, DY = 0.01  ! Fixed grid spacing

  type :: field
     integer :: nx          ! local dimension of the field
     integer :: ny
     integer :: nx_full     ! global dimension of the field
     integer :: ny_full
     real(dp) :: dx
     real(dp) :: dy
     real(dp), dimension(:,:), allocatable :: data
  end type field

  type :: parallel_data
     integer :: size
     integer :: rank
     integer :: nup, ndown, nleft, nright  ! Ranks of neighbouring MPI tasks
     integer :: comm
     integer :: requests(8)                ! Non-blocking communication handles
     integer :: rowtype                    ! MPI Datatype for communication of 
                                           ! rows
     integer :: columntype                 ! MPI Datatype for communication of 
                                           ! columns
     integer :: subarraytype               ! MPI Datatype for text I/O
     integer :: restarttype                ! MPI Datatype for restart I/O
     integer :: filetype                   ! MPI Datatype for file view in
                                           ! restart I/O

  end type parallel_data

contains
  ! Initialize the field type metadata
  ! Arguments:
  !   field0 (type(field)): input field
  !   nx, ny, dx, dy: field dimensions and spatial step size
  subroutine set_field_dimensions(field0, nx, ny, parallel)
    implicit none

    type(field), intent(out) :: field0
    integer, intent(in) :: nx, ny
    type(parallel_data), intent(in) :: parallel

    integer :: nx_local, ny_local

    integer, dimension(2) :: dims, coords
    logical :: periods(2)
    integer :: ierr

    call mpi_cart_get(parallel%comm, 2, dims, periods, coords, ierr)

    nx_local = nx / dims(1)
    ny_local = ny / dims(2)

    field0%dx = DX
    field0%dy = DY
    field0%nx = nx_local
    field0%ny = ny_local
    field0%nx_full = nx
    field0%ny_full = ny

  end subroutine set_field_dimensions

  subroutine parallel_setup(parallel, nx, ny)
    use mpi

    implicit none

    type(parallel_data), intent(out) :: parallel
    integer, intent(in), optional :: nx, ny

    integer :: nx_local, ny_local
    integer :: world_size
    integer :: dims(2) = (/0, 0/)
    logical :: periods(2) = (/.false., .false./)
    integer :: coords(2)
    integer, dimension(2) :: sizes, subsizes, offsets

    integer :: ierr

    call mpi_comm_size(MPI_COMM_WORLD, world_size, ierr)

    ! Set grid dimensions
    call mpi_dims_create(world_size, 2, dims, ierr)
    nx_local = nx / dims(1)
    ny_local = ny / dims(2)

    ! Ensure that the grid is divisible to the MPI tasks
    if (nx_local * dims(1) /= nx) then
       write(*,*) 'Cannot divide grid evenly to processors in x-direction', &
            & nx_local, dims(1), nx
       call mpi_abort(MPI_COMM_WORLD, -2, ierr)
    end if
    if (ny_local * dims(2) /= ny) then
       write(*,*) 'Cannot divide grid evenly to processors in y-direction', &
            & ny_local, dims(2), ny
       call mpi_abort(MPI_COMM_WORLD, -2, ierr)
    end if


    ! Create cartesian communicator
    call mpi_cart_create(MPI_COMM_WORLD, 2, dims, periods, .true., parallel%comm, ierr)
    call mpi_cart_shift(parallel%comm, 0, 1, parallel%nup, parallel%ndown, ierr)
    call mpi_cart_shift(parallel%comm, 1, 1, parallel%nleft, &
         & parallel%nright, ierr)

    call mpi_comm_size(parallel%comm, parallel%size, ierr)
    call mpi_comm_rank(parallel%comm, parallel%rank, ierr)

    if (parallel%rank == 0) then
       write(*,'(A, I3, A3, I3)') 'Using domain decomposition', dims(1), 'x', & 
         & dims(2)
       write(*,'(A, I5, A3, I5)') 'Local domain size', nx_local,  'x', ny_local
    end if

    ! Create datatypes for halo exchange
    call mpi_type_vector(ny_local + 2, 1, nx_local + 2, MPI_DOUBLE_PRECISION, &
         & parallel%rowtype, ierr)
    call mpi_type_contiguous(nx_local + 2, MPI_DOUBLE_PRECISION, &
         & parallel%columntype, ierr)
    call mpi_type_commit(parallel%rowtype, ierr)
    call mpi_type_commit(parallel%columntype, ierr)

    ! Create datatype for subblock needed in I/O
    !   Rank 0 uses datatype for receiving data into full array while
    !   other ranks use datatype for sending the inner part of array
    sizes(1) = nx_local + 2
    sizes(2) = ny_local + 2
    subsizes(1) = nx_local
    subsizes(2) = ny_local
    offsets(1) = 1
    offsets(2) = 1
    if (parallel%rank == 0) then
       sizes(1) = nx
       sizes(2) = ny
       offsets(1) = 0
       offsets(2) = 0
    end if
    call mpi_type_create_subarray(2, sizes, subsizes, offsets, &
         & MPI_ORDER_FORTRAN, MPI_DOUBLE_PRECISION, parallel%subarraytype, &
         & ierr)
    call mpi_type_commit(parallel%subarraytype, ierr)

    ! Create datatypes for restart I/O
    ! For boundary ranks also the ghost layer (boundary condition) 
    ! is written 

    call mpi_cart_coords(parallel%comm, parallel%rank, 2, coords, ierr);
    sizes(1) = nx + 2
    sizes(2) = ny + 2
    offsets(1) = 1 + coords(1) * nx_local
    offsets(2) = 1 + coords(2) * ny_local
    if (coords(1) == 0) then
       offsets(1) = offsets(1) - 1
       subsizes(1) = subsizes(1) + 1
    end if
    if (coords(1) == dims(1) - 1) then 
       subsizes(1) = subsizes(1) + 1;
    end if
    if (coords(2) == 0) then
       offsets(2) = offsets(2) - 1
       subsizes(2) = subsizes(2) + 1
    end if 
    if (coords(2) == dims(2) - 1) then
       subsizes(2) = subsizes(2) + 1
    end if

    call mpi_type_create_subarray(2, sizes, subsizes, offsets, & 
         & MPI_ORDER_FORTRAN, MPI_DOUBLE_PRECISION, parallel%filetype, ierr)
    call mpi_type_commit(parallel%filetype, ierr)

    sizes(1) = nx_local + 2
    sizes(2) = ny_local + 2
    offsets(1) = 1
    offsets(2) = 1
    if (coords(1) == 0) then
       offsets(1) = 0
    end if
    if (coords(2) == 0) then
       offsets(2) = 0
    end if

    call mpi_type_create_subarray(2, sizes, subsizes, offsets, &
         & MPI_ORDER_FORTRAN, MPI_DOUBLE_PRECISION, parallel%restarttype, ierr)
    call mpi_type_commit(parallel%restarttype, ierr)

  end subroutine parallel_setup

end module heat
