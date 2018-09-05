## Simple message exchange

a) Write a simple program where two processes send and receive a
message to/from each other using `MPI_Send` and `MPI_Recv`. The message
content is an integer array, where each element is initialized to the
rank of the process. After receiving a message, each process should
print out the rank of the process and the first element in the
received array. You may start from scratch or use as a starting point
the skeleton code found in [exchange.c](exchange.c), 
[exchange.F90](exchange.F90) or [exchange.py](exchange.py)

b) Increase the message size to 100,000, recompile and run. It is very likely
that the program will dead lock, try to figure out reason for this, and
how to resolve it.
