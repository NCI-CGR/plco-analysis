## Cameron Palmer, 19 May 2020
## Primary entry point for PLCO analysis pipeline
## 
include Makefile.config
export
.PHONY: all $(SUPPORTED_METHODS) bgen meta metal meta-analysis metaanalysis cleaned-chips-by-ancestry ancestry relatedness ldsc 1KG_files fastgwa-grm ldscores plotting
all: meta

plotting:
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.plotting

meta-analysis metaanalysis metal meta: $(SUPPORTED_METHODS)
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.metal

fastgwa: fastgwa-grm

$(SUPPORTED_METHODS): cleaned-chips-by-ancestry ldsc bgen
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.$@

bgen:
	$(MAKE) -C $(BGEN_OUTPUT_DIR)

fastgwa-grm: cleaned-chips-by-ancestry
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.fastgwa.grm

cleaned-chips-by-ancestry: ancestry
	$(MAKE) -C $(CLEANED_CHIP_OUTPUT_DIR)

ancestry: relatedness
	$(MAKE) -C $(ANCESTRY_OUTPUT_DIR)

relatedness:
	$(MAKE) -C $(RELATEDNESS_OUTPUT_DIR)

ldsc: 1KG_files
	$(MAKE) -C $(LDSC_OUTPUT_DIR)

1KG_files:
	$(MAKE) -C $(KG_REFERENCE_INPUT_DIR)

ldscores:
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.$@


## TESTING CONTROLLERS

.PHONY: check bgen-check relatedness-check ancestry-check cleaned-chips-by-ancestry-check

check: bgen-check relatedness-check ancestry-check cleaned-chips-by-ancestry-check

bgen-check: bgen
	$(MAKE) -C $(BGEN_OUTPUT_DIR) check

relatedness-check: relatedness
	$(MAKE) -C $(RELATEDNESS_OUTPUT_DIR) check

ancestry-check: ancestry
	$(MAKE) -C $(ANCESTRY_OUTPUT_DIR) check

cleaned-chips-by-ancestry-check: cleaned-chips-by-ancestry
	$(MAKE) -C $(CLEANED_CHIP_OUTPUT_DIR) check
