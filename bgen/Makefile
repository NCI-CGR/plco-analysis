export
include ../Makefile.config
UNIQUE_PLATFORMS := $(sort $(subst _,/,$(filter-out Omni5,$(PLATFORMS))))

.DELETE_ON_ERROR:
.SECONDEXPANSION:
.PHONY: all $(UNIQUE_PLATFORMS) $(addsuffix /,$(UNIQUE_PLATFORMS))
all: $(UNIQUE_PLATFORMS)
$(UNIQUE_PLATFORMS): $$@/Makefile
	$(MAKE) -C $@

$(addsuffix /Makefile,$(UNIQUE_PLATFORMS)): | $$(dir $$@)
	echo -e "PROJECT_CODE := $(subst /Makefile,,$@)\n.DELETE_ON_ERROR:\ninclude ../Makefile.bgen_format" > $@

$(addsuffix /,$(UNIQUE_PLATFORMS)):
	mkdir -p $@
