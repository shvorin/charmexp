# NOTE: This is the basic Makefile template that includes the additional
#       Makefile.simulation makefile that is found in the location of the
#       current installation of POSE.
#
#	The Makefile.simulation set of rules allows the compilation of
#       a SINGLE simulation module. If multiple simulation modules are
#	desired, some "surgery" of Makefile.simulation (and this file)
#	will be required. 
#
# ***********************************************************************

CHARMBASE=../../..
CHARMBIN=$(CHARMBASE)/bin
CHARMINC=$(CHARMBASE)/include

CHARMC=$(CHARMBIN)/charmc -I$(CHARMINC)/pose $(OPTS)

# Default Location variables
# **************************
#POSE_ROOT=$(HOME)/charm/net-linux/lib

# Default module names
# - MAKE MODIFICATIONS HERE
# *************************
PGM_MODULE=PHOLD
PGM=phold
OTHER=
LIBS=-Lstdc++ -lm

# Simulation object definitions 
# *****************************
SIM_OBJECTS=Worker_sim.o $(PGM).o 

# EXECUTABLE GENERATION RULES 
# - DO NOT MODIFY
#****************************
base:	$(PGM)
	@echo "Simulation compiled."

pure:   $(PGM).pure
	@echo "Simulation (w purify) compiled."

proj:   $(PGM).proj
	@echo "Simulation (w projections log traces) compiled."

summary:    $(PGM).summary
	@echo "Simulation (w summary log traces) compiled."

$(PGM):	$(SIM_OBJECTS) 
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM) \
	-module pose -language charm++

$(PGM).prof:	$(SIM_OBJECTS) 
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM) \
	-module pose -language charm++ -pg

$(PGM).seq: seqobjs
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).seq \
	-DSEQUENTIAL_POSE=1 -module seqpose -language charm++

$(PGM).seq.proj:	$(SIM_OBJECTS) 
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).seq.proj \
	-module seqpose -language charm++ -tracemode projections

$(PGM).alt:	$(SIM_OBJECTS) 
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).alt \
	-module pose -language charm++

$(PGM).comm:	$(SIM_OBJECTS) 
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).comm \
	-lpose -language charm++ -module commlib

$(PGM).pure:	$(SIM_OBJECTS)
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).pure \
	-lpose -language charm++ -purify

$(PGM).proj:	$(SIM_OBJECTS)
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).proj \
	-module pose -language charm++ -tracemode projections

$(PGM).summary:	$(SIM_OBJECTS)
	$(CHARMC) $(SIM_OBJECTS) $(OTHER) $(LIBS) -o $(PGM).summary \
	-lpose -language charm++ -tracemode summary

# HOUSE-KEEPING RULES
# - DO NOT MODIFY
#********************

# clean removes everything
clean:	clear rm_logs ;

# clear removes only binaries and generated files
clear:
	rm -f charmrun conv-host *.o
	rm -f *.def.h *.decl.h
	rm -f $(PGM) $(PGM).pure $(PGM).proj $(PGM).summary
	rm -f gmon.out #*#
	rm -f core *~
	rm -f TAGS *.headers
	rm -f *_sim.*

# rm_logs removes projections/summary log traces
rm_logs:
	rm -f [^j]*.log *.sum [^j]*.sts
	rm -f *-bg.*.log *-bg.sts

# SIMULATION COMPILATION RULES
# - DO NOT MODIFY 
#*****************************
$(PGM).o : 	$(PGM).C $(PGM).h $(PGM_MODULE).def.h $(PGM_MODULE).decl.h
	$(CHARMC) -c -I$(CHARMINC) $(INCLUDES) $(LIBS) $(PGM).C

$(PGM_MODULE).def.h $(PGM_MODULE).decl.h : $(PGM).ci
	$(CHARMC) $(INCLUDES) $(LIBS) $(PGM).ci

Worker_sim.o :	Worker_sim.C Worker_sim.h Worker.def.h Worker.decl.h
	$(CHARMC) -c $(LIBS) $(INCLUDES) -I$(CHARMINC) Worker_sim.C

Worker.def.h Worker.decl.h : Worker_sim.ci
	$(CHARMC) $(INCLUDES) $(LIBS) Worker_sim.ci

Worker_sim.C Worker_sim.h Worker_sim.ci: Worker.C Worker.h Worker.ci 
	$(CHARMBIN)/etrans.pl Worker

seqobjs: seqtrans
	$(CHARMC) $(INCLUDES) $(LIBS) Worker_sim.ci
	$(CHARMC) -c $(LIBS) $(INCLUDES) -I$(CHARMINC) -DSEQUENTIAL_POSE=1 Worker_sim.C
	$(CHARMC) $(INCLUDES) $(LIBS) $(PGM).ci
	$(CHARMC) -c -I$(CHARMINC) $(INCLUDES) $(LIBS) -DSEQUENTIAL_POSE=1 $(PGM).C

seqtrans: Worker.C Worker.h Worker.ci
	$(CHARMBIN)/etrans.pl -s Worker

test: $(PGM)
	./phold  10 10 RANDOM RANDOM RANDOM -gm  50 100
