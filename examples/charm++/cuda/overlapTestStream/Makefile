CHARMC=../../../../bin/charmc $(OPTS)

OBJS = overlapTest.o overlapTestCU.o

NVCC = /usr/local/cuda/bin/nvcc 
NVCC_FLAGS = -O3 -c -use_fast_math #-device-debug -deviceemu 
NVCC_INC = -I/usr/local/cuda/include 
CHARMINC = -I../../../../include
NVCC_LIBS = -L/usr/local/cuda/lib64 -lcuda -lcudart
all: overlapTest

overlapTest: $(OBJS)
	$(CHARMC) -language charm++ -o overlapTest $(OBJS) $(NVCC_LIBS) 

overlapTest.decl.h: overlapTest.ci
	$(CHARMC)  overlapTest.ci

clean:
	rm -f *.decl.h *.def.h conv-host *.o overlapTest charmrun

overlapTest.o: overlapTest.C overlapTest.decl.h
	$(CHARMC) -O3 -c overlapTest.C

overlapTestCU.o: overlapTest.cu
	$(NVCC) $(NVCC_FLAGS) $(NVCC_INC) $(CHARMINC) -o overlapTestCU.o overlapTest.cu

test: all
	./charmrun ./overlapTest +p2 2 8
