CHARMC=../../../bin/charmc $(OPTS)

all: pgm

pgm:  speed.o
	$(CHARMC) speed.o  -o pgm -language charm++

speed.o : speed.C speed.h speed.ci
	$(CHARMC) -c speed.ci speed.C

test: pgm
	./charmrun +p4 ./pgm 8 $(TESTOPTS)

bgtest: pgm
	./charmrun +p4 ./pgm 8 +x2 +y2 +z1 $(TESTOPTS)

clean:
	rm -f conv-host pgm *.def.h *.decl.h *.o *~ charmrun charmrun.exe pgm.exe pgm.pdb pgm.ilk
