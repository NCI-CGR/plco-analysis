## Cameron Palmer, 21 May 2020
## convert post-imputation-QC MIS files to nonredundant subject bgen 1.2 for downstream analysis

export
include $(PROJECT_BASE_DIR)/Makefile.config

UNIQUE_PLATFORMS := $(subst _,/,$(filter-out Omni5,$(PLATFORMS)))

.DELETE_ON_ERROR:
.SECONDEXPANSION:
.PHONY: all $(UNIQUE_PLATFORMS) check secondary-clean $(addsuffix -secondary-clean,$(UNIQUE_PLATFORMS))
## all targets are: each platform, without Omni5 because it has no non-redundant subjects
all: $(UNIQUE_PLATFORMS) $(addsuffix /Makefile,$(UNIQUE_PLATFORMS))

## phony platform recursive target controls creation of platform's makefile
$(UNIQUE_PLATFORMS): $$@/Makefile
	$(MAKE) -C $@

## create recursive makefile per platform, triggering creation of directory if needed
$(addsuffix /Makefile,$(UNIQUE_PLATFORMS)): | $$(dir $$@)
	echo -e "PROJECT_CODE := $(subst /Makefile,,$@)\n.DELETE_ON_ERROR:\ninclude $(BGEN_OUTPUT_DIR)/Makefile.bgen_format" > $@

## create platform directory if needed
$(addsuffix /,$(UNIQUE_PLATFORMS)):
	mkdir -p $@

## test set to run after completion
check: testing/Makefile
	$(MAKE) -C testing check

testing/Makefile: testing/Makefile.am testing/configure.ac
	cd testing && autoreconf -vi && ./configure && cd ../

secondary-clean: $(addsuffix -secondary-clean,$(UNIQUE_PLATFORMS))

$(addsuffix -secondary-clean,$(UNIQUE_PLATFORMS)): #$$(subst -secondary-clean,/Makefile,$$@) | $$(dir $$@)
	$(MAKE) -C $(subst -secondary-clean,,$@) secondary-clean
