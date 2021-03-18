## Cameron Palmer, 09 July 2020
## dispatch config check

export
include $(MAKEFILE_CONFIG_LOCATION)

.DELETE_ON_ERROR:
.SECONDEXPANSION:
.PHONY: all check

all: check

## test set to run after completion
check: testing/Makefile$(TRACKING_SUCCESS_SUFFIX)
	$(MAKE) -C testing check

testing/Makefile$(TRACKING_SUCCESS_SUFFIX): testing/Makefile.am testing/configure.ac
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),cd testing && autoreconf -vi && ./configure && cd ../)
