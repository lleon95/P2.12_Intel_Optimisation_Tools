! I/O routines for heat equation solver
module io
  use heat
  use mpi

contains

  ! Output routine, saves the temperature distribution as a png image
  ! Arguments:
  !   curr (type(field)): variable with the temperature data
  !   iter (integer): index of the time step
  subroutine write_field(curr, iter, parallel)

    use pngwriter
    implicit none
    type(field), intent(in) :: curr
    integer, intent(in) :: iter
    type(parallel_data), intent(in) :: parallel

    character(len=85) :: filename

    integer :: stat
    real(dp), dimension(:,:), allocatable, target :: full_data

    integer :: coords(2)
    integer :: ix, jy
    integer :: p, ierr

    if (parallel%rank == 0) then
       allocate(full_data(curr%nx_full, curr%ny_full))
       ! Copy rand #0 data to the global array
       full_data(1:curr%nx, 1:curr%ny) = curr%data(1:curr%nx, 1:curr%ny)

       ! Receive data from other ranks
       do p = 1, parallel%size - 1
          call mpi_cart_coords(parallel%comm, p, 2, coords, ierr)
          ix = coords(1) * curr%nx + 1
          jy = coords(2) * curr%ny + 1
          call mpi_recv(full_data(ix, jy), 1, parallel%subarraytype, p, 22, &
               & parallel%comm, MPI_STATUS_IGNORE, ierr)
       end do
       write(filename,'(A5,I4.4,A4,A)')  'heat_', iter, '.png'
       stat = save_png(full_data, curr%nx_full, curr%ny_full, filename)
       deallocate(full_data)
    else
       ! Send data
       call mpi_ssend(curr%data, 1, parallel%subarraytype, 0, 22, &
            & parallel%comm, ierr)
    end if

  end subroutine write_field


  ! Reads the temperature distribution from an input file
  ! Arguments:
  !   field0 (type(field)): field variable that will store the
  !                         read data
  !   filename (char): name of the input file
  ! Note that this version assumes the input data to be in C memory layout
  subroutine read_field(field0, filename, parallel)

    implicit none
    type(field), intent(out) :: field0
    character(len=85), intent(in) :: filename
    type(parallel_data), intent(out) :: parallel

    integer :: nx, ny, i, p, ierr
    character(len=2) :: dummy

    real(dp), dimension(:,:), allocatable :: full_data
    integer :: coords(2)
    integer :: ix, jy

    open(10, file=filename)
    ! Read the header
    read(10, *) dummy, nx, ny

    call parallel_setup(parallel, nx, ny)
    call set_field_dimensions(field0, nx, ny, parallel)

    ! The arrays for temperature field contain also a halo region
    allocate(field0%data(0:field0%nx+1, 0:field0%ny+1))

    if (parallel%rank == 0) then
       allocate(full_data(nx, ny))
       ! Read the data
       do i = 1, nx
          read(10, *) full_data(i, 1:ny)
       end do
       ! Copy own local part
       field0%data(1:field0%nx, 1:field0%ny) = full_data(1:field0%nx, 1:field0%ny)
       ! Send to other process
       do p=1, parallel%size - 1
          call mpi_cart_coords(parallel%comm, p, 2, coords, ierr)
          ix = coords(1) * field0%nx + 1
          jy = coords(2) * field0%ny + 1
          call mpi_send(full_data(ix, jy), 1, parallel%subarraytype, p, 44, &
               &   parallel%comm, ierr)
       end do
    else
       ! Receive data
       call mpi_recv(field0%data, 1, parallel%subarraytype, 0, 44, &
            &        parallel%comm, MPI_STATUS_IGNORE, ierr)
    end if

    ! Set the boundary values
    field0%data(1:field0%nx, 0) = field0%data(1:field0%nx, 1)
    field0%data(1:field0%nx, field0%ny+1) = field0%data(1:field0%nx, field0%ny)
    field0%data(0, 0:field0%ny+1) = field0%data(1, 0:field0%ny+1)
    field0%data(field0%nx+1, 0:field0%ny+1) = field0%data(field0%nx, 0:field0%ny+1)

    close(10)
    if (parallel%rank == 0) then
       deallocate(full_data)
    end if

  end subroutine read_field

  ! Write a restart checkpoint that contains field dimensions, current
  ! iteration number and temperature field.
  subroutine write_restart(temp, parallel, iter)
    implicit none

    type(field), intent(in) :: temp
    type(parallel_data), intent(in) :: parallel
    integer, intent(in) :: iter

    integer :: fp
    integer(kind=MPI_OFFSET_KIND) :: disp
    integer :: ierr

    call mpi_file_open(MPI_COMM_WORLD, "HEAT_RESTART.dat",  &
         & MPI_MODE_CREATE + MPI_MODE_WRONLY, &
         & MPI_INFO_NULL, fp, ierr)

    ! write the restart header by the rank#0
    if (parallel%rank == 0) then
       disp = 0
       call mpi_file_write_at(fp, disp, temp%nx_full, 1, MPI_INTEGER, MPI_STATUS_IGNORE, ierr)
       disp = disp + sizeof(temp%nx_full)
       call mpi_file_write_at(fp, disp, temp%ny_full, 1, MPI_INTEGER, MPI_STATUS_IGNORE, ierr)
       disp = disp + sizeof(temp%ny_full)
       call mpi_file_write_at(fp, disp, iter, 1, MPI_INTEGER, MPI_STATUS_IGNORE, ierr)
    end if

    ! For simplicity, skip three integers at the beginning of file in all tasks
    disp = 3 * sizeof(temp%nx_full)
    call mpi_file_set_view(fp, 0, MPI_DOUBLE_PRECISION, parallel%filetype, &
         & 'native', MPI_INFO_NULL, ierr);
    call mpi_file_write_at_all(fp, disp, temp%data, &
         & 1, parallel%restarttype, MPI_STATUS_IGNORE, ierr)

    call mpi_file_close(fp, ierr)

  end subroutine write_restart

  ! Read a restart checkpoint that contains field dimensions, current
  ! iteration number and temperature field.
  subroutine read_restart(temp, parallel, iter)
    implicit none

    type(field), intent(inout) :: temp
    type(parallel_data), intent(inout) :: parallel
    integer, intent(out) :: iter

    integer :: rows, cols
    integer :: fp
    integer(kind=MPI_OFFSET_KIND) :: disp
    integer :: ierr

    call mpi_file_open(MPI_COMM_WORLD, "HEAT_RESTART.dat", MPI_MODE_RDONLY, &
         & MPI_INFO_NULL, fp, ierr)

    ! read in the restart header (dimensions, number of preceding steps) by the
    ! rank#0 and broadcast it to other ranks
    if (parallel%rank == 0) then
       disp = 0
       call mpi_file_read_at(fp, disp, rows, 1, MPI_INTEGER, MPI_STATUS_IGNORE, ierr)
       disp = disp + sizeof(rows)
       call mpi_file_read_at(fp, disp, cols, 1, MPI_INTEGER, MPI_STATUS_IGNORE, ierr)
       disp = disp + sizeof(cols)
       call mpi_file_read_at(fp, disp, iter, 1, MPI_INTEGER, MPI_STATUS_IGNORE, ierr)
    end if
    call mpi_bcast(rows, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call mpi_bcast(cols, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call mpi_bcast(iter, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)

    ! set correct dimensions to MPI metadata
    call parallel_setup(parallel, rows, cols)
    ! set local dimensions and allocate memory for the data
    call set_field_dimensions(temp, rows, cols, parallel)
    allocate(temp%data(0:temp%nx+1, 0:temp%ny+1))
    temp%data(:,:) = 0.0

   ! read in restart data
    disp = 3*sizeof(rows)
    call mpi_file_set_view(fp, 0, MPI_DOUBLE_PRECISION, parallel%filetype, &
         & 'native', MPI_INFO_NULL, ierr);
    call mpi_file_read_at_all(fp, disp, temp%data, &
         & 1, parallel%restarttype, MPI_STATUS_IGNORE, ierr)

    call mpi_file_close(fp, ierr)

  end subroutine read_restart

end module io
