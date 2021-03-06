# Generated automatically from Makefile.in by configure.
ALL: default
##### User configurable options #####

MPIR_HOME   = 
CC          = ../../../../bin/ampiCC
CLINKER     = ../../../../bin/ampiCC
CCC         = 
CCLINKER    = $(CCC)
F77         = :
FLINKER     = :
OPTFLAGS    = 
MAKE        = make

# mpiboot and mpiunboot are used to execute any steps that must
# be executed before and after running programs.
MPIBOOT     = 
MPIUNBOOT   = 

### End User configurable options ###

SHELL = /bin/sh

PROFLIB =
CFLAGS  = $(OPTFLAGS) 
CCFLAGS = $(CFLAGS)
FFLAGS = $(OPTFLAGS)
# Use LIBS to add any special libraries for C programs
LIBS = 
# Use FLIBS to add any special libraries for Fortran programs
FLIBS = 
TESTDIRS = pt2pt coll topol env context profile 
SUBDIRS = pt2pt coll topol env context profile  

default: subdirs
	@echo "Type \"make testing\" to compile and run tests"

subdirs:
	@for dir in $(SUBDIRS) ;\
		do \
			echo " " ;\
			echo Making in directory $$dir ;\
			if [ -d $$dir -a -s $$dir/Makefile ] ; then \
			    (cd $$dir; $(MAKE)) ; fi ;\
		done

linktest:
	@for dir in $(SUBDIRS) ;\
		do \
			echo " " ;\
			echo Making linktest in directory $$dir ;\
			if [ -d $$dir -a -s $$dir/Makefile ] ; then \
			    (cd $$dir; $(MAKE) linktest) ; fi ;\
		done

# Make sure that everything works (don't run the tests if mpirun fails
# for some reason).  We use runtests to handle finding and setting the mpirun
# environment (only the pt2pt test has this option).  runtest exits with 1 if
# the test fails, which will cause the Make to exit.
runtest:
	if [ "$(MPITEST_IGNORE_RUNTEST)" != yes ] ; then \
	(cd pt2pt && ./runtests $(TESTARGS) -check ) ; fi

#
# This also cleans the files after the testing to keep the
# total size down.  You can use TESTARGS to pass arguments to the
# test program; for example, 
# make TESTARGS="-echo"
# to run in "echo" mode (show what scripts are doing)
# The tests are run in "small" mode (build one executable at a time) to
# reduce the amount of disk space that is used.
# The make clean is directed into dev null to keep the testing as 
# quiet as possible.
# We export the MPITEST_STOPTEST environment variable to allow the
# user to set an alternate file to be used to abort the tests; this
# is especially useful for automated tests.
testing: runtest
	@rm -f summary.xml
	@echo "<?xml version='1.0' ?>" > summary.xml
	@echo '<?xml-stylesheet href="er.xsl" type="text/xsl" ?>' >> summary.xml
	@echo '<MPITESTRESULTS>' >> summary.xml
	@echo "<DATE>`date`</DATE>" >> summary.xml
	@echo "<MPISOURCE></MPISOURCE>" >> summary.xml
	@-for dir in $(TESTDIRS) ;\
		do \
			echo " " ;\
			if [ ! -d $$dir -o ! -s $$dir/Makefile ] ; then \
				continue ; fi ; \
			echo Making testing in directory $$dir ;\
			(export MPITEST_STOPTEST ; cd $$dir ; $(MAKE) testing TESTARGS="-small -summaryfile=../summary.xml $(TESTARGS)" ; \
	                 $(MAKE) clean > /dev/null 2>&1 ) ;\
			echo End of testing in directory $$dir ;\
		done
	@-if [ "MPICH" = "MPICH" ] ; then \
	    echo "Running tests in directory command" ; \
	    (cd command && ./runtests -summaryfile=../summary.xml ) ;\
	    echo "End of testing in directory command" ; \
	fi
	@echo '</MPITESTRESULTS>' >> summary.xml

#
# These tests require that the boot and unboot steps are programs, not
# programs with arguments.
boot-mpi:
	@if [ ! -x "${MPIBOOT}" ] ; then \
	  echo "Could not find the MPI boot program" ; \
	  echo "You may need to install MPICH before running the test suite"; \
	fi
	${MPIBOOT}
unboot-mpi:
	@if [ -x "${MPIUNBOOT}" ] ; then \
	    ${MPIUNBOOT} ; \
	fi

# It is important to have the - in the make testing step to ensure that
# the unboot is executed even if the tests fail
testing-boot:
	@-if [ -n "${MPIBOOT}" ] ; then \
	    ${MAKE} boot-mpi ; fi
	-${MAKE} testing
	@-if [ -n "${MPIUNBOOT}" ] ; then \
	    ${MAKE} unboot-mpi ; fi
#
# This is a version of testing, but it saves the "diff" files in the top 
# level directory
testing_save: runtest
	@-for dir in $(TESTDIRS) ;\
		do \
			echo " " ;\
			if [ ! -d $$dir -o ! -s $$dir/Makefile ] ; then \
				continue ; fi ; \
			echo Making testing in directory $$dir ;\
			(cd $$dir; $(MAKE) testing TESTARGS="-small $(TESTARGS)" ; \
	                 if [ -s $$dir.diff ] ; then cp $$dir.diff .. ; fi ; \
	    		 $(MAKE) clean > /dev/null 2>&1 ) ;\
			echo End of testing in directory $$dir ;\
		done

clean:
	@-rm -f test.log testing.log *.diff sendchar.sun4 sendchar.freebsd \
		sendshort.sun4 sendshort.freebsd *.o \
		sendvector.sun4 sendvector.freebsd \
		sendstruct.sun4 sendstruct.freebsd \
	        sendchar sendshort sendvector sendstruct
	@-rm -f work.pc work.pcl
	@for dir in $(SUBDIRS) ;\
		do \
			echo " " ;\
			if [ ! -d $$dir -o ! -s $$dir/Makefile ] ; then \
			    continue ; fi ; \
			echo Making clean in directory $$dir ;\
			(cd $$dir; $(MAKE) clean) ;\
		done

distclean:
	@-for dir in ${SUBDIRS} command ; do \
	    (rm -f $$dir/Makefile $$dir/runtests ) ; \
	done
	-rm -f config.log Makefile command/runtests
