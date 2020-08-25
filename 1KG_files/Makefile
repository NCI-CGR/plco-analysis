include $(PROJECT_BASE_DIR)/Makefile.config

.PHONY: all clean
all: $(addsuffix .success,$(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS)))

$(addsuffix .success,$(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS))):
	$(call log_handler,$(subst .success,,$@),wget $(KG_DOWNLOAD_SITE)/$(notdir $(subst .success,,$@)))

clean:
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX),$(CHRS))
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX).success,$(CHRS))
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX).fail,$(CHRS))
