## Cameron Palmer, 09 July 2020
## dispatch config check

export
include $(PROJECT_BASE_DIR)/Makefile.config

.DELETE_ON_ERROR:
.SECONDEXPANSION:
.PHONY: all check

all: check

## test set to run after completion
check: testing/Makefile.success
	$(MAKE) -C testing check

testing/Makefile.success: testing/Makefile.am testing/configure.ac
	$(call log_handler,$(subst .success,,$@),cd testing && autoreconf -vi && ./configure && cd ../)
