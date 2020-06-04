include $(PROJECT_BASE_DIR)/Makefile.config

.PHONY: all clean
all: $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS))

$(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS)):
	wget $(KG_DOWNLOAD_SITE)/$(notdir $@)

clean:
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX),$(CHRS))
