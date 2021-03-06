#
# Tomas Nesrovnal, nesro@nesro.cz, Copyright 2013, 2014
# https://github.com/nesro/sparse-matrices
# 

#-------------------------------------------------------------------------------
# read configuration files
#-------------------------------------------------------------------------------

USERNAME=$(shell cat USERNAME.txt)

#-------------------------------------------------------------------------------

# make DEBUG=1 tests && make BIN=./tests/bin/test_kat_matrix valgrind

# make DEBUG=1 tests && nice -n 19 valgrind --leak-check=full --show-reachable=yes ./tests/bin/matrix_generator -n 512 -s 0.1 -i block,50,100,75,150,0.9,block,100,100,150,150,0.8,diagonal,200,200,300,300 -o /tmp/matrix2.mtx 2> >(while read l; do echo -e "\e[01;31m$l\e[0m" >&2; done)


OBJECTS=utils.o \
	mmio.o \
	mm_load.o \
	virtual_matrix.o \
	den_matrix.o \
	csr_matrix.o \
	qdt_matrix.o \
	kat_matrix.o \
	bsr_matrix.o \
	coo_matrix.o \
	vector.o

TESTS=test_utils.o \
	mulres_distance \
	matrix_generator \
	test_bsr_matrix \
	test_coo_matrix \
	test_den_matrix \
	test_qdt_matrix \
	test_kat_matrix \
	test_mat_vec \

BINARY=./main

CC=gcc
LD=gcc
MKDIR_P=mkdir -p
MAKE=make

CLIBS=-lm -fopenmp
CFLAGS=-std=c99 -Wall -pedantic -Werror

SOURCE_DIR=./src

SRC=./src
BUILD=./build

TEST_DIR=./tests
TEST_SRC=$(TEST_DIR)/src
TEST_BUILD=$(TEST_DIR)/build
TEST_BIN=$(TEST_DIR)/bin

CASSERTION=./cassertion

#-------------------------------------------------------------------------------

ifdef KAT_DENSE_TRESHOLD
	CFLAGS += _D_KAT_DENSE_TRESHOLD=$(KAT_DENSE_TRESHOLD)
endif

ifdef KAT_N
	CFLAGS += -D_KAT_N=$(KAT_N)
endif

ifdef PRECISION
	CFLAGS += -D_PRECISION=$(PRECISION)
endif

ifdef DIFF_TRESHOLD
	CFLAGS += -D_DIFF_TRESHOLD=$(DIFF_TRESHOLD)
endif

ifdef DEBUG
	CFLAGS += -Og -ggdb #-Wextra
else
	CFLAGS += -Ofast
endif

#-------------------------------------------------------------------------------

ifdef OMP_NUM_THREADS
	CFLAGS += -DOMP_NUM_THREADS=$(OMP_NUM_THREADS)
endif

# when FAKE, dense matix will be just one variable
ifdef FAKE
	CFLAGS += -D_FAKE=1
endif


ifdef OMP_THREADS
	CFLAGS += -DOMP_THREADS=$(OMP_THREADS)
endif

#-------------------------------------------------------------------------------

# set up GCC Optimalizations
#ifndef GCCOP
#	CFLAGS += -O0
#else ifeq (1, $(GCCOP))
#	CFLAGS += -O2
#else ifeq (2, $(GCCOP))
#	CFLAGS += -O3    
#else ifeq (3, $(GCCOP))
#	CFLAGS += -O3 -msse -msse2 -msse3 -msse4.2 -mfpmath=sse -ftree-vectorizer-verbose=5
#endif

#-------------------------------------------------------------------------------

all: build_dir $(OBJECTS) $(BINARY)

.PHONY: build_dir
build_dir:
	$(MKDIR_P) $(BUILD)

.PHONY: test_dirs
test_dirs:
	$(MKDIR_P) $(TEST_BUILD)
	$(MKDIR_P) $(TEST_BIN)

.PHONY: cassertion
cassertion: all tests
	./cassertion/cassertion.sh -c ./tests/cassertion_settings.txt

.PHONY: thesis
thesis:
	$(MAKE) -C thesis_cz all

.PHONY: run
run: all
	$(BINARY)

# make BIN=./main valgrind
.PHONY: valgrind
valgrind:
	./tests/scripts/valgrind.sh ${BIN}

# make BIN=./main allgrind
.PHONY: allgrind
allgrind: all tests valgrind

.PHONY: tests
tests: all test_dirs $(TESTS)

.PHONY: runtests
runtests: tests
	$(TEST_DIR)/run.sh $(TEST_SUITE)

.PHONY: clean
clean:
	find . -type f -and \( -name "*.o" -or -name "*~" -or -name "valgrind_*" \) -delete
	rm -fr \
		$(BINARY) \
		$(BUILD) \
		$(TEST_BUILD) \
		$(TEST_BIN) \
		./cachegrind* \
		./*.png \
		./*.html \
		./queue*sh.e \
		./queue*sh.o \
		./queue*sh.pe \
		./queue*sh.po
	$(MAKE) -C thesis_cz clean

.PHONY: fullclean
fullclean: clean
	find . -type f -and \( -name "*.html" -or -name "*.html" \) -delete
	rm -fr ./*.png
	rm -fr ./res_from_star/*
	rm -fr *.star.sh

#-------------------------------------------------------------------------------

$(BINARY): $(OBJECTS) ./main.o
	$(LD) $(CFLAGS) $(addprefix $(BUILD)/, main.o) \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(BINARY) $(CLIBS)

#-------------------------------------------------------------------------------

#TODO: header files from some list
main.o: $(SOURCE_DIR)/main.c $(SOURCE_DIR)/utils.h $(SOURCE_DIR)/csr_matrix.h \
$(SOURCE_DIR)/vector.h $(SOURCE_DIR)/coo_matrix.h $(SOURCE_DIR)/den_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

utils.o: $(SOURCE_DIR)/utils.c $(SOURCE_DIR)/utils.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

mm_load.o: $(SOURCE_DIR)/mm_load.c $(SOURCE_DIR)/mm_load.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

virtual_matrix.o: $(SOURCE_DIR)/virtual_matrix.c $(SOURCE_DIR)/virtual_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

csr_matrix.o: $(SOURCE_DIR)/csr_matrix.c $(SOURCE_DIR)/csr_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)
	
bsr_matrix.o: $(SOURCE_DIR)/bsr_matrix.c $(SOURCE_DIR)/bsr_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

qdt_matrix.o: $(SOURCE_DIR)/qdt_matrix.c $(SOURCE_DIR)/qdt_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

kat_matrix.o: $(SOURCE_DIR)/kat_matrix.c $(SOURCE_DIR)/kat_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

mmio.o: $(SOURCE_DIR)/mmio.c $(SOURCE_DIR)/mmio.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

coo_matrix.o: $(SOURCE_DIR)/coo_matrix.c $(SOURCE_DIR)/coo_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

den_matrix.o: $(SOURCE_DIR)/den_matrix.c $(SOURCE_DIR)/den_matrix.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

vector.o: $(SOURCE_DIR)/vector.c $(SOURCE_DIR)/vector.h
	$(CC) $(CFLAGS) -c -o $(BUILD)/$@ $< $(CLIBS)

#-------------------------------------------------------------------------------
# test helpers and standalone binaries

matrix_generator: $(TEST_SRC)/matrix_generator.c
	$(CC) $(CFLAGS) -o $(TEST_BIN)/$@ $< $(CLIBS)

mulres_distance: mulres_distance.o $(OBJECTS)
	$(LD) $(CFLAGS) $(TEST_BUILD)/mulres_distance.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)

mulres_distance.o: $(TEST_SRC)/mulres_distance.c $(SRC)/virtual_matrix.h \
$(SRC)/den_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)

test_utils.o: $(TEST_SRC)/test_utils.c $(TEST_SRC)/test_utils.h \
$(CASSERTION)/cassertion.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)

#-------------------------------------------------------------------------------
# cassertion test suites

test_coo_matrix: test_coo_matrix.o
	$(LD) $(CFLAGS) $(TEST_BUILD)/test_utils.o $(TEST_BUILD)/test_coo_matrix.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)
	
test_coo_matrix.o: $(TEST_SRC)/test_coo_matrix.c $(CASSERTION)/cassertion.h \
$(SRC)/virtual_matrix.h $(SRC)/coo_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)
	
	
test_bsr_matrix: test_bsr_matrix.o
	$(LD) $(CFLAGS) $(TEST_BUILD)/test_utils.o $(TEST_BUILD)/test_bsr_matrix.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)
	
test_bsr_matrix.o: $(TEST_SRC)/test_bsr_matrix.c $(CASSERTION)/cassertion.h \
$(SRC)/virtual_matrix.h $(SRC)/bsr_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)


test_den_matrix: test_den_matrix.o
	$(LD) $(CFLAGS) $(TEST_BUILD)/test_utils.o $(TEST_BUILD)/test_den_matrix.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)
	
test_den_matrix.o: $(TEST_SRC)/test_den_matrix.c $(CASSERTION)/cassertion.h \
$(SRC)/virtual_matrix.h $(SRC)/den_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)


test_qdt_matrix: test_qdt_matrix.o
	$(LD) $(CFLAGS) $(TEST_BUILD)/test_utils.o $(TEST_BUILD)/test_qdt_matrix.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)

test_qdt_matrix.o: $(TEST_SRC)/test_qdt_matrix.c $(CASSERTION)/cassertion.h \
$(SRC)/virtual_matrix.h $(SRC)/qdt_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)


test_kat_matrix: test_kat_matrix.o
	$(LD) $(CFLAGS) $(TEST_BUILD)/test_utils.o $(TEST_BUILD)/test_kat_matrix.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)

test_kat_matrix.o: $(TEST_SRC)/test_kat_matrix.c $(CASSERTION)/cassertion.h \
$(SRC)/virtual_matrix.h $(SRC)/kat_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)


test_mat_vec: test_mat_vec.o
	$(LD) $(CFLAGS) $(TEST_BUILD)/test_utils.o $(TEST_BUILD)/test_mat_vec.o \
	$(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)

test_mat_vec.o: $(TEST_SRC)/test_mat_vec.c $(CASSERTION)/cassertion.h \
$(SRC)/virtual_matrix.h $(SRC)/bsr_matrix.h $(SRC)/coo_matrix.h \
 $(SRC)/csr_matrix.h $(SRC)/den_matrix.h $(SRC)/kat_matrix.h
	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)

#-------------------------------------------------------------------------------
# Some unrelated stuff. Mostly just for FIT CTU
#-------------------------------------------------------------------------------

# Tunel for licencing Wolram Mathematica. It can visualize .mtx files.
matunel:
	ssh $(USERNAME)@fray1.fit.cvut.cz -L 16286:leibniz.feld.cvut.cz:16286

#-------------------------------------------------------------------------------
# STAR.fit.cvut.cz helpers

# Deploy files from local to STAR
star-deploy: clean
	rsync -ave ssh ./* --delete $(USERNAME)@star.fit.cvut.cz:/mnt/data/$(USERNAME)/sparse-matrices

# Run the job
star-run:
	./tests/scripts/star.sh

star-create-jobs:
	./tests/graphs/measure_program/create_jobs.sh

# Watch the job list
star-watch:
	watch -n 1 qstat

# Remove all your jobs
star-remove:
	qstat | grep $(USERNAME) | cut -d ' ' -f2 | xargs qdel
	killall create_jobs.sh
#	ps auxc | grep nesrotom | grep create_jobs.sh | awk '{ print $1 }' | xargs kill

# Show results
star-results:
	cat /mnt/data/$(USERNAME)/sparse-matrices/*.sh.*

# Clean results
star-clean:
	rm /mnt/data/$(USERNAME)/sparse-matrices/*.sh.* \
		/mnt/data/$(USERNAME)/sparse-matrices/_*.sh \
		/mnt/data/$(USERNAME)/sparse-matrices/log_*.txt \
		/mnt/data/$(USERNAME)/sparse-matrices/resvec_*.mtx \
		/mnt/data/$(USERNAME)/sparse-matrices/core \
		/mnt/data/$(USERNAME)/sparse-matrices/nohup.out

#-------------------------------------------------------------------------------

deploy: fullclean
	rsync -ave ssh --delete ../eiaapp $(USERNAME)@star.fit.cvut.cz:/home/$(USERNAME)/

qrun:
	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/csr_mmm_mvm.sh
#	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/queue_12c_1slots_per_host_job.sh

qmmmrep:
	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/kkIllrepeat.sh

qrunmmm:
	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/yaycsrmmm.sh

qrunmvm:
	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/yaycsrmvm.sh
	
qruncg:
	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/cachegrind.sh

qeia:
	/opt/bin/qrun.sh 12c 1 1slots_per_host ./star/eia.sh

graph:
	./gnuplot.sh

watch:
	watch -n 1 qstat

qdelall:
	qstat | grep nesrotom | cut -d ' ' -f2 | xargs qdel

qdelres:
	rm -f /mnt/data/nesrotom/*

qres:
	cat /mnt/data/nesrotom/*

#------------------------------------------------------------------------------

gp-local:
	./tests/eia/eia.sh $(METHOD) $(START) $(STEP) $(MAX) $(THREADS)

gp-star:
	./tests/eia/star.sh $(METHOD) $(START) $(STEP) $(MAX) $(THREADS)

#------------------------------------------------------------------------------

# ---
#
#test_quadtree: all test_quadtree.o
#	$(LD) $(CFLAGS) $(TEST_BUILD)/test_quadtree.o $(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)
#
#test_quadtree.o: $(TEST_SRC)/test_quadtree.c $(TEST_SRC)/test_framework.h $(SRC)/qt_matrix.h
#	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)
#
## ---
#
#utils_test: all utils_test.o
#	$(LD) $(CFLAGS) $(TEST_BUILD)/utils_test.o $(addprefix $(BUILD)/, $(OBJECTS)) -o $(TEST_BIN)/$@ $(CLIBS)
#
#utils_test.o: $(TEST_SRC)/utils_test.c $(TEST_SRC)/test_framework.h $(SRC)/utils.h
#	$(CC) $(CFLAGS) -c -o $(TEST_BUILD)/$@ $< $(CLIBS)


