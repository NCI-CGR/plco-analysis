include $(PROJECT_BASE_DIR)/Makefile.config
export
STUDIES := $(foreach platform,$(PLATFORMS),$(firstword $(subst _, ,$(platform))))

.PHONY: all clean $(CLEANED_ANCESTRY_NAMES) $(addsuffix /,$(CLEANED_ANCESTRY_NAMES))
.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
all: $(CLEANED_ANCESTRY_NAMES)
clean:
	rm -f *.o *.out core.*

$(CLEANED_ANCESTRY_NAMES): $$@/Makefile
	$(MAKE) -C $@

$(addsuffix /Makefile,$(CLEANED_ANCESTRY_NAMES)): | $$(dir $$@)
	echo -e "POPULATION_NAME := $(subst /Makefile,,$@)\ninclude ../Makefile.include" > $@

$(addsuffix /,$(CLEANED_ANCESTRY_NAMES)):
	mkdir -p $@
