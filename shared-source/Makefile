.PHONY: all
.DELETE_ON_ERROR:

SRC := annotate_frequency.cc annotate_rsids_from_linker.cc merge_files_for_globus.cc
OUT := $(subst .cc,.out,$(SRC))
AR := ar
CC := gcc
CPP := cpp
CXX := g++
CXXCPP := g++ -E
LD := ld -m elf_x86_64
OBJDUMP := objdump
RANLIB := ranlib
STRIP := strip

LOCAL_CXXFLAGS := -Wall -O2
LOCAL_LIBFLAGS := -lz -lbz2

QSUB_JOB_MONITOR_DIR := qsub_job_monitor
JOB_MONITOR_DIRS := $(QSUB_JOB_MONITOR_DIR)
LIB_FILEINTERFACE := fileinterface/libfileinterface.a

SUBDIR_TARGETS := fileinterface $(JOB_MONITOR_DIRS)

#$(foreach dir,$(JOB_MONITOR_DIRS),$(dir)/$(dir).out)

.PHONY: $(SUBDIR_TARGETS)
all: $(OUT) $(SUBDIR_TARGETS)

%.out: %.o $(LIB_FILEINTERFACE)
	$(CXX) -L/home/palmercd/Development/stage/lib -o $@ $^ $(LOCAL_LIBFLAGS)

%.o: %.cc
	$(CXX) $(LOCAL_CXXFLAGS) -I$(dir $(LIB_FILEINTERFACE)) -I/home/palmercd/Development/stage/include -o $@ -c $<

$(SUBDIR_TARGETS):
	cd $@ && ./configure --prefix=$(shell pwd)/$@ --with-boost=/home/palmercd/Development/stage && cd ..
	$(MAKE) -C $@
