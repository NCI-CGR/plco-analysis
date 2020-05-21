export
include ../Makefile.config
UNIQUE_PLATFORMS := $(filter-out Omni5,$(PLATFORMS))
.DELETE_ON_ERROR:
.SECONDEXPANSION:
.PHONY: all $(subst _,/,$(UNIQUE_PLATFORMS)) $(subst _,/,$(addsuffix /,$(UNIQUE_PLATFORMS)))
all: $(subst _,/,$(UNIQUE_PLATFORMS))
$(UNIQUE_PLATFORMS): $$@/Makefile
	$(MAKE) -C $@

$(addsuffix /Makefile,$(UNIQUE_PLATFORMS)): $$(dir $$@)
	echo -e "PROJECT_CODE := $(subst /Makefile,,$(subst _,/,$@))\n.DELETE_ON_ERROR:\ninclude ../Makefile.bgen_format" > $@

$(addsuffix /,$(UNIQUE_PLATFORMS)):
	mkdir -p $@
