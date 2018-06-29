program exchange
  use mpi
  implicit none
  integer, parameter :: size = 100000
  integer :: rc, myid, ntasks, count
  integer :: status(MPI_STATUS_SIZE)
  integer :: message(size)
  integer :: receiveBuffer(size)

  call mpi_init(rc)
  call mpi_comm_rank(MPI_COMM_WORLD, myid, rc)
  call mpi_comm_size(MPI_COMM_WORLD, ntasks, rc)

  message = myid

  ! Send and receive as defined in the assignment
  if ( myid == 0 ) then
     call mpi_send(message, size, MPI_INTEGER, 1, &
          1, MPI_COMM_WORLD, rc)
     call mpi_recv(receiveBuffer, size, MPI_INTEGER, 1,  &
          2, MPI_COMM_WORLD, status, rc)
     write(*,'(A10,I3,A10,I3)') 'Rank: ', myid, &
          ' received ', receiveBuffer(1)
  else if (myid == 1) then
      ! One MPI tasks needs to start with send and the other one with
      ! receive, otherwise the program dead locks with large message
      ! sizes in most MPI implementations 
     call mpi_recv(receiveBuffer, size, MPI_INTEGER, 0,  &
          1, MPI_COMM_WORLD, status, rc)
     call mpi_send(message, size, MPI_INTEGER, 0, &
          2, MPI_COMM_WORLD, rc)
     write(*,'(A10,I3,A10,I3)') 'Rank: ', myid, &
          ' received ', receiveBuffer(1)
  end if

  call mpi_finalize(rc)

end program exchange
