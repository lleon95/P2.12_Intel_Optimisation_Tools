# Final Project: Advanced Optimization Techniques


Comments about the final project for the P2.12_seed Intel course.

Slides for the exam: https://docs.google.com/presentation/d/1apDs22xZgGGsq-k8EGKaitG8849hjpQ1RuLLe1lKah8/edit?usp=sharing

**Goal**: Analyze the [MPI heat equation C code](https://repository.prace-ri.eu/git/CodeVault/training-material/parallel-programming/MPI/-/tree/master/heat-equation/c) with the Intel tools:

- Intel Application Performance Snapshot (APS);
- Intel Advisor;
- Intel VTune

**Remark**: Intel DevCloud cluster:

* OS: Ubuntu 18.04
* Intel OneAPI: 2020 Beta 7
* Processor: Intel(R) Xeon(R) Gold 6128 CPU @ 3.40GHz
* RAM: 188 GB
* Vector ISA: AVX512

**Remark**: Since the `beta 06` versions of Intel Advisor and VTune do not work on our machines (due to C libraries being too recent), we had to work on Intel DevCloud. Users are only allowed to use two nodes per core on the DevCloud compute nodes. Moreover, in order to compile the full code the `libpng` library is necessary, therefore we had to install it on the compute nodes as follows:

- `qsub -l nodes=1:batch:ppn=2 -d . -I` (enter compute node interactively)
- `tar -xvf libpng-1.6.37.tar.xz` (in user home directory; tar file downloaded from [this site](https://sourceforge.net/projects/libpng/files/libpng16/1.6.37/))
- `cd libpng-1.6.37`
- `./configure --prefix=/home/u44098`
- `make check`
- `make install`

The Makefile had to be properly modified in order to include the path for the `libpng` header file during compilation, as well as the path for the `libpng` libraries during linking. Also, a conditional compilation flag was added to control the inclusion of the PNG writing process.

**Remark**: We will compile and run the code on DevCloud, but analyze the results on our local machines (especially because the GUI are not available on DevCloud).

**Remark**: We will collect performance data for the program run with both 1 and 2 MPI processes. This is because the 1 MPI process case will help us understand bottlenecks for the serial code, while the 2 MPI processes case will give us information about MPI communication bottlenecks.

**Remark**: In the `beta 07` version of Intel tools the `mpiicc` compiler has some bug: 

`/glob/development-tools/versions/oneapi/beta07/inteloneapi/mpi/2021.1-beta07//bin/mpiicc: 542: [: unexpected operator`


This repo contains the final assignment of the course Advance Optimisation 
Techniques using Intel OpenAPI tools.

## Reports

You can find the reports for:

* [Application Performance Snapshot (APS)](aps_advisor/README.md)
* [Intel Advisor](aps_advisor/README.md)
* [Intel VTune Profiler](vtune/README.md)

The source code and other resources to complete the task are placed in:

* [APS and Advisor](aps_advisor/)
* [VTune](vtune/)

## Students

- Antonio Sciarappa
- Irina Davydenkova
- Luis G. Leon-Vega

## Instructors

- Dr. Christopher Dahnken
- Dr. Fabio Baruffa 
- Dr. Giacomo Rossi 

Jun-July 2020
