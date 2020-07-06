## Cameron Palmer, 21 May 2020
## Secondary entry point for chip cleaning; dispatches each ancestry separately

include $(PROJECT_BASE_DIR)/Makefile.config
export
STUDIES := $(sort $(foreach platform,$(PLATFORMS),$(firstword $(subst _, ,$(platform)))))

.PHONY: all clean $(CLEANED_ANCESTRY_NAMES)
.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
## Primary target of pipeline is: each of the seven harmonized GRAF ancestry groups
all: $(CLEANED_ANCESTRY_NAMES)
clean:
	rm -f *.o *.out core.*

## patterns:
##    output: {ANCESTRY} [recursive make run]
##    input:  {ANCESTRY}/Makefile
## Note: dispatches recursive make call to each ancestry; also handles creation of the ancestry makefile
$(CLEANED_ANCESTRY_NAMES): $$@/Makefile
	$(MAKE) -C $@

## patterns:
##    output: {ANCESTRY}/Makefile
##    input:  {ANCESTRY}/
## Note: the ancestry-specific makefiles trigger the creation of the ancestry directory itself if needed.
$(addsuffix /Makefile,$(CLEANED_ANCESTRY_NAMES)): | $$(dir $$@)
	echo -e "POPULATION_NAME := $(subst /Makefile,,$@)\ninclude ../Makefile.include" > $@

## patterns:
##    output: {ANCESTRY}/
$(addsuffix /,$(CLEANED_ANCESTRY_NAMES)):
	mkdir -p $@


## test set to run after completion
check: testing/Makefile
	$(MAKE) -C testing check

testing/Makefile: testing/Makefile.am testing/configure.ac
	cd testing && autoreconf -vi && ./configure && cd ../
