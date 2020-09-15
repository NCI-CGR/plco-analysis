include $(PROJECT_BASE_DIR)/Makefile.config

.PHONY: all clean
all: $(addsuffix $(TRACKING_SUCCESS_SUFFIX),$(KG_MANIFEST) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).md5sum,$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi.md5sum,$(CHRS)))

$(addsuffix $(TRACKING_SUCCESS_SUFFIX),$(KG_MANIFEST) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS))):
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),wget $(KG_DOWNLOAD_SITE)/$(notdir $(subst $(TRACKING_SUCCESS_SUFFIX),,$@)))

$(addsuffix .md5sum$(TRACKING_SUCCESS_SUFFIX),$(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX),$(CHRS)) $(patsubst %,$(KG_GENOTYPES_PREFIX)%$(KG_GENOTYPES_SUFFIX).tbi,$(CHRS))): $(KG_MANIFEST)$(TRACKING_SUCCESS_SUFFIX)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk '$$1 ~ /$(notdir $(subst .md5sum$(TRACKING_SUCCESS_SUFFIX),,$@))$$/ {print $$3"  "$$1}' $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

clean:
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX),$(CHRS))
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX)$(TRACKING_SUCCESS_SUFFIX),$(CHRS))
	rm -f $(patsubst %,$(1KG_GENOTYPES_PREFIX)%$(1KG_GENOTYPES_SUFFIX)$(TRACKING_FAIL_SUFFIX),$(CHRS))
	rm -f $(KG_MANIFEST)

## test set to run after completion
check: testing/Makefile$(TRACKING_SUCCESS_SUFFIX)
	$(MAKE) -C testing check

testing/Makefile$(TRACKING_SUCCESS_SUFFIX): testing/Makefile.am testing/configure.ac
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),cd testing && autoreconf -vi && ./configure && cd ../)
