## Cameron Palmer, 19 May 2020
## Primary entry point for PLCO analysis pipeline
## 
include Makefile.config
export
.SECONDEXPANSION:
.PHONY: all $(SUPPORTED_METHODS) bgen meta metal meta-analysis metaanalysis cleaned-chips-by-ancestry ancestry relatedness ldsc 1KG_files fastgwa-grm ldscores plotting flat-dosages globus
all: meta

plotting: #$(SUPPORTED_METHODS) meta
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.plotting


## meta-analysis targets
##   this understands EXCLUDE_{METHOD} parameters to restrict the meta to certain analyses over others
META_ALIASES := meta-analysis metaanalysis metal meta
$(META_ALIASES): ##$(SUPPORTED_METHODS)
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.metal

$(addsuffix -saige,$(META_ALIASES)):
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.metal EXCLUDE_BOLTLMM=1 EXCLUDE_FASTGWA=1

$(addsuffix -fastgwa,$(META_ALIASES)):
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.metal EXCLUDE_BOLTLMM=1 EXCLUDE_SAIGE=1

$(addsuffix -boltlmm,$(META_ALIASES)):
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.metal EXCLUDE_FASTGWA=1 EXCLUDE_SAIGE=1


fastgwa: fastgwa-grm

$(SUPPORTED_METHODS): #cleaned-chips-by-ancestry ldsc
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

ldscores: ##$(SUPPORTED_METHODS) meta
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.$@


globus: # meta
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.$@

## TESTING CONTROLLERS

.PHONY: check bgen-check relatedness-check ancestry-check cleaned-chips-by-ancestry-check fastgwa-check boltlmm-check fastgwa-grm-check ldscores-check saige-check config-check meta-check

check: bgen-check relatedness-check ancestry-check cleaned-chips-by-ancestry-check fastgwa-check boltlmm-check fastgwa-grm-check ldscores-check saige-check config-check meta-check

bgen-check:
	$(MAKE) -C $(BGEN_OUTPUT_DIR) check FILTERED_DOSAGE_DATA=$(FILTERED_IMPUTED_INPUT_DIR)

relatedness-check:
	$(MAKE) -C $(RELATEDNESS_OUTPUT_DIR) check

ancestry-check:
	$(MAKE) -C $(ANCESTRY_OUTPUT_DIR) check

cleaned-chips-by-ancestry-check:
	$(MAKE) -C $(CLEANED_CHIP_OUTPUT_DIR) check

boltlmm-check: config-check
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.check $@ CONFIG_DIR=$(CONFIG_INPUT_DIR) CHIP_DIR=$(CLEANED_CHIP_OUTPUT_DIR) IMPUTED_DIR=$(BGEN_OUTPUT_DIR) RESULTS_DIR=$(RESULT_OUTPUT_DIR) MINIMUM_SUBJECTS=$(BOLTLMM_MINIMUM_VALID_SUBJECT_COUNT)

fastgwa-check: config-check
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.check $@ CONFIG_DIR=$(CONFIG_INPUT_DIR) CHIP_DIR=$(CLEANED_CHIP_OUTPUT_DIR) IMPUTED_DIR=$(BGEN_OUTPUT_DIR) RESULTS_DIR=$(RESULT_OUTPUT_DIR) MINIMUM_SUBJECTS=$(FASTGWA_MINIMUM_VALID_SUBJECT_COUNT)

saige-check: config-check
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.check $@ CONFIG_DIR=$(CONFIG_INPUT_DIR) CHIP_DIR=$(CLEANED_CHIP_OUTPUT_DIR) IMPUTED_DIR=$(BGEN_OUTPUT_DIR) RESULTS_DIR=$(RESULT_OUTPUT_DIR) MINIMUM_SUBJECTS=$(SAIGE_MINIMUM_VALID_SUBJECT_COUNT) MINIMUM_CASES=$(MINIMUM_VALID_CASE_COUNT)

config-check:
	$(MAKE) -C $(CONFIG_INPUT_DIR) PHENOTYPE_FILE=$(PHENOTYPE_FILENAME)

meta-check:
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.check $@ CONFIG_DIR=$(CONFIG_INPUT_DIR) RESULTS_DIR=$(RESULT_OUTPUT_DIR)





## CLEANING INTERMEDIATES

bgen-secondary-clean:
	$(MAKE) -C $(BGEN_OUTPUT_DIR) secondary-clean

$(addsuffix -secondary-clean,$(SUPPORTED_METHODS)):
	$(MAKE) -C $(SHARED_MAKEFILES) -f Makefile.$(subst -secondary-clean,,$@) secondary-clean

