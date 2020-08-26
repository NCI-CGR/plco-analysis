.PHONY: all
.DELETE_ON_ERROR:

SRC := annotate_frequency.cc annotate_rsids_from_linker.cc combine_categorical_runs.cc merge_files_for_globus.cc
OUT := $(subst .cc,.out,$(SRC))
GCC := g++
CXXFLAGS := -Wall -O2
LDFLAGS := -lz -lbz2

QSUB_JOB_MONITOR_DIR := qsub_job_monitor
JOB_MONITOR_DIRS := $(QSUB_JOB_MONITOR_DIR)
LIB_FILEINTERFACE := fileinterface/libfileinterface.a

SUBDIR_TARGETS := $(LIB_FILEINTERFACE) $(foreach dir,$(JOB_MONITOR_DIRS),$(dir)/$(dir).out)

all: $(OUT) $(SUBDIR_TARGETS)

%.out: %.o $(LIB_FILEINTERFACE)
	$(GCC) -o $@ $^ $(LDFLAGS)

%.o: %.cc
	$(GCC) $(CXXFLAGS) -I$(FILEINTERFACE_DIR) -o $@ -c $<

$(SUBDIR_TARGETS):
	cd $(dir $@) && ./configure --prefix=$(shell pwd) $(if $(filter %/$(LIB_FILEINTERFACE),$@),,--with-boost=/home/palmercd/Development/stage) && cd ..
	$(MAKE) -C $(dir $@)
