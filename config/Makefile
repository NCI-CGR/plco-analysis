## Cameron Palmer, 09 July 2020
## dispatch config check

export
include $(PROJECT_BASE_DIR)/Makefile.config

.DELETE_ON_ERROR:
.SECONDEXPANSION:
.PHONY: all check

all: check

## test set to run after completion
check: testing/Makefile
	$(MAKE) -C testing check

testing/Makefile: testing/Makefile.am testing/configure.ac
	cd testing && autoreconf -vi && ./configure && cd ../
