.PHONY: all
.DELETE_ON_ERROR:

SRC := annotate_frequency.cc annotate_rsids_from_linker.cc combine_categorical_runs.cc merge_files_for_globus.cc
OUT := $(subst .cc,.out,$(SRC))
GCC := g++
CXXFLAGS := -Wall -O2
LDFLAGS := -lz -lbz2

FILEINTERFACE_DIR := fileinterface
LIB_FILEINTERFACE := fileinterface/libfileinterface.a

all:  $(OUT)

%.out: %.o $(LIB_FILEINTERFACE)
	$(GCC) -o $@ $^ $(LDFLAGS)

%.o: %.cc
	$(GCC) $(CXXFLAGS) -I$(FILEINTERFACE_DIR) -o $@ -c $<

$(LIB_FILEINTERFACE):
	$(MAKE) -C $(FILEINTERFACE_DIR)
