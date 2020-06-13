# --------------------------------------------------
#  Custom targets
#  Added by: Luis G. Leon-Vega
#  -------------------------------------------------

# Controls for Intel compiler
ifeq ("$(origin USE_INTEL)", "command line")
  BUILD_INTEL = $(USE_INTEL)
endif
# Set default to compile with Intel
ifndef BUILD_INTEL
  BUILD_INTEL = 1
endif

# Controls for PNG linking
ifeq ("$(origin USE_PNG)", "command line")
  LINK_PNG = $(USE_PNG)
endif
# Set default to compile with Intel
ifndef LINK_PNG
  LINK_PNG = 0
endif

ifeq ("$(BUILD_INTEL)", "1")
  CC=mpiicc
  CCFLAGS=-g -O2 -Wall -xCORE-AVX512 -qopt-zmm-usage=high
else
  CC=mpicc
  CCFLAGS=-O3 -Wall 
endif

ifeq ("$(LINK_PNG)", "1")
  LIBS=-lpng -lm
  CCFLAGS+= -DWITH_PNG
else
  LIBS=-lm
endif

EXE=heat_mpi
OBJS=core.o setup.o utilities.o io.o main.o
OBJS_PNG=pngwriter.o
EXECUTER=mpirun
ADVPRJ = ./adv-ver:0

all: $(EXE)

pngwriter.o: pngwriter.c pngwriter.h
core.o: core.c heat.h
utilities.o: utilities.c heat.h
setup.o: setup.c heat.h
io.o: io.c heat.h
main.o: main.c heat.h

$(OBJS_PNG): C_COMPILER := $(CC)
$(OBJS): C_COMPILER := $(CC)

$(EXE): $(OBJS) $(OBJS_PNG)
	$(CC) $(CCFLAGS) $(OBJS) $(OBJS_PNG) -o $@ $(LDFLAGS) $(LIBS)

%.o: %.c
	$(C_COMPILER) $(CCFLAGS) -c $< -o $@

survey:
	$(EXECUTER) -n 1 -gtool "advixe-cl -collect survey --no-auto-finalize -project-dir $(ADVPRJ)" ./$(EXE)

roofline:
	$(EXECUTER) -n 1 -gtool "advixe-cl -collect survey --no-auto-finalize -project-dir $(ADVPRJ)" ./$(EXE)
	$(RM) HEAT_RESTART.dat
	$(EXECUTER) -n 1 -gtool "advixe-cl -collect tripcounts -flop --no-auto-finalize -project-dir $(ADVPRJ)" ./$(EXE)

help:
	$(info --- Targets ---)
	$(info   help: shows this)
	$(info   all: builds the executable)
	$(info   survey: runs the survey)
	$(info   roofline: collects all the data needed for the Advisor)
	$(info --- Modifiers ---)
	$(info   USE_INTEL={0,1}: Enable the compilation with Intel Compiler [default])
	$(info   USE_PNG={0,1}: Link the PNG library and enable the plotting. Disabled by default)
	$(info Example: make USE_INTEL=0 USE_PNG=1)

.PHONY: all help clean
clean:
	$(RM) $(EXE) a.out *.o *.png *~
